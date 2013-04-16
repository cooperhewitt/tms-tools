#!/usr/bin/env perl
use strict;

use lib '.';

use TMS;

use FileHandle;
use File::Path qw(make_path);
use File::Spec;
use File::Basename;

use DBI;
use DBD::ODBC;
use Data::Dumper;

use Text::CSV_XS;
use JSON::XS;

use Encode qw(from_to);
use English;

use Getopt::Std;
use Config::Simple;
use Log::Dispatch;

{
    &main();
    exit();
}

sub main {

    my %opts = ();

    getopts('c:b:T:vht', \%opts);

    if ($opts{'h'}){
	&usage();
	exit();
    }

    my $config_file = $opts{'c'};
    my $branch = $opts{'b'};

    my $cfg = Config::Simple->new($config_file);

    my $log_level = ($opts{'v'}) ? 'debug' : 'info';

    my $log = Log::Dispatch->new(
	outputs => [
	    [ 'Screen', min_level => $log_level ],
	],
	callbacks => sub {
	    my %p = @_; return $p{'message'} . "\n";
	}
    );

    my $db = $cfg->param("$branch.db");

    my $whoami = File::Spec->rel2abs($PROGRAM_NAME);
    my $bin_root = File::Basename::dirname($whoami);

    my $tms_root = File::Basename::dirname($bin_root);
    my $dump_root = File::Spec->catfile($tms_root, "dump");

    my $dump_dest = File::Spec->catfile($dump_root, "tables-$db");

    $log->info("will write dump files to $dump_dest");

    #

    my @tables = ();

    if (my $tables = $opts{'T'}){

	@tables = map {

	    $_ =~ s/^\s+//;
	    $_ =~ s/\s+$//;
	    $_;

	} split(",", $tables);

	$log->info("dump only: " . join(", ", @tables));
    }

    my $filter_tables = (scalar(@tables)) ? 1 : 0;

    #

    $log->info("connecting to the $branch database $db");

    my $dbh = TMS::dbh($cfg, $branch);

    $log->info("fetching tables");

    my $sql = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'";
    $log->debug($sql);

    my $sth = $dbh->prepare($sql);
    $sth->execute();

    if ($opts{'t'}){

	my $row = $sth->fetchrow_arrayref();

	if ($row){
	    $log->info("Connection to TMS is: GO!");
	}

	else {
	    $log->info("Connection to TMS is: SAD.");
	}

	return;
    }

    my $rows = $sth->fetchall_arrayref();

    my %tables = ();

    foreach my $row (@$rows){

	my $schema = $row->[1];
	my $table = $row->[2];

	$tables{$table} = {
	    'database' => $db,
	    'schema' => $schema,
	    'fields' => [],
	}

    }

    $log->info("fetching column names...");

    foreach my $table (keys %tables){

	my $sql = "SELECT * FROM INFORMATION_SCHEMA.Columns where TABLE_NAME = '$table'";
	$log->debug($sql);

	my $sth = $dbh->prepare($sql);
	$sth->execute();
    
	my $rows = $sth->fetchall_arrayref();
	my @fields = ();

	foreach my $r (@$rows){

	    my %details = (
		'name' => $r->[3],
		'type' => $r->[7],
		'encoding' => $r->[16],
		'collation' => $r->[19]
		);

	    push @fields, \%details;
	}

	$tables{$table}->{'fields'} = \@fields;
    }

    if (! -d $dump_dest){
	$log->info("making $dump_dest...");
	make_path($dump_dest);
    }

    my $tables_path = File::Spec->catfile($dump_dest, "tables.json");
    $log->info("dumping table schemas to $tables_path");

    my $encoder = JSON::XS->new();
    $encoder->pretty();

    my $fh = FileHandle->new();
    $fh->open($tables_path, "w");
    binmode $fh, ":utf8";

    $fh->write($encoder->encode(\%tables));
    $fh->close();

    #

    my $tables_root = File::Spec->catdir($dump_dest, "tables");
    my $names_path = File::Spec->catfile($dump_dest, "tables.md");

    my $names_fh = FileHandle->new();
    $names_fh->open($names_path, "w");
    binmode $names_fh, ":utf8";
    
    $names_fh->print("tables\n");
    $names_fh->print("==\n\n");

    foreach my $table (sort keys %tables){

	$names_fh->print("* " . $table . "\n\n");
	
	my $table_path = File::Spec->catfile($tables_root, $table . ".md");

	my $table_fh = FileHandle->new();
	$table_fh->open($table_path, "w");
	binmode $table_fh, ":utf8";
	
	$table_fh->print("$table\n");
	$table_fh->print("==\n\n");

	my @fields = ();

	foreach my $f (@{$tables{$table}->{'fields'}}){
	    push @fields, $f->{'name'};
	}

	foreach my $field (sort @fields){
	    $table_fh->print("* " . $field . "\n\n");
	}

	$table_fh->close();
    }

    $names_fh->close();

    #

    foreach my $table (keys %tables){

	if (($filter_tables) && (! grep($_ eq $table, @tables))){
	    $log->info("skip $table\n");
	    next;
	}

	my $csv_path = File::Spec->catfile($dump_dest, "$table.csv");
	$log->info("dumping $table to $csv_path");

	open my $fh, ">:encoding(utf8)", $csv_path;

	my $csv = Text::CSV_XS->new();
	$csv->eol ("\n");

	my $fields = $tables{$table}->{'fields'};

	my @header = ();

	foreach my $details (@$fields){

		# SysTimeStamp drinks all the CSV's milkshake
		# (20120809/straup)
	
	    if ($details->{'name'} eq 'SysTimeStamp'){
			next;
	    }

	    # Yes... you are seeing this. Apparently 'External'
	    # is a reserved word in MSSQL or something equally
	    # inane (20120823/straup)

	    if (($table eq 'Locations') && ($details->{'name'} eq 'External')){
			next;
	    }

	    push @header, $details->{'name'};
	}
	
	$csv->print ($fh, \@header);

	my $ok_fields = join(",", @header);
	my $sql = "SELECT $ok_fields FROM $db.dbo.$table";
	$log->debug($sql);

	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my $i = 0;

	while (1){

	    my $row = $sth->fetchrow_arrayref();

	    if ((! $row) && (! $sth->err)){
		$log->debug("no data and no erors, stopping");
		last;
	    }

	    elsif ($sth->err){
		$log->warning("skip line $i");
	    }

	    else {

		$log->debug("processing line $i for $table");

		# Potentially overkill but then again if it works
		# and makes the squigglies go away then who cares
		# (20120718/straup)

		my @clean = ();

		foreach my $r (@$row){
		    push @clean, Encode::decode('utf8', $r);
		}

		$csv->print($fh, \@clean);
	    }
	    
	    $i++;
	}

    }

    $log->info("done");
    return 1;
    
}

sub usage {

    print <<END
usage: $PROGRAM_NAME -c <config> -b <branch>

-c path to your TMS (database) config file
-b which TMS database (or branch) to use; valid options are 'dev' and 'prod'
-T limit dumps to a specific comma-separated list of tables (optional)
-v enable verbose logging
-t test the connection to the TMS server and then exit
-h print this message

END

}
