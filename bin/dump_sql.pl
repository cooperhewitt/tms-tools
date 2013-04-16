#!/usr/bin/env perl

use lib qw '.';

# Note: I am punting on logging right now. It feels like
# part of a larger decision about whether or not to make
# TMS.pm an actual object with object methods or what. It
# also feels like a yak... (20120720/straup)

use strict;
use TMS;
use Data::Dumper;

use English;
use Getopt::Std;
use Config::Simple;

{
    &main();
    exit;
}

sub main {

    my %opts = ();

    getopts('c:b:s:o:H:h', \%opts);

    if ($opts{'h'}){
	&usage();
	exit();
    }

    my $config_file = $opts{'c'};
    my $cfg = Config::Simple->new($config_file);

    my $branch = $opts{'b'};

    if (! -f $opts{'s'}){
	print "SQL file not found\n";
	exit();
    }

    my $dbh = TMS::dbh($cfg, $branch);

    my $sql_file = $opts{'s'};
    my $sql = undef;

    {
	local $/;
	undef $/;

	open my $fh, $sql_file;
	$sql = <$fh>;
	close $fh;
    }

    # Try to tease out the headers; this is probably fraught with
    # error conditions hence the cant_parse flag (20120720/straup)

    # Also, array reference blah blah blah undef below blah blah
    # perl blah blah blah ... blah blah blah perl (20120720/straup)

    my $headers = [];
    my $cant_parse = 0;

    if ($opts{'H'}){
	$headers = [ split(",", $opts{'H'}) ];
    }
    
    elsif ($sql =~ /^SELECT([\w\s\n\.,-]+)FROM.*/mi){

	$cant_parse = 0;

	my @lines = split("\n", $1);

	foreach my $ln (@lines){

	    $ln =~ s/^\s//g;
	    $ln =~ s/\s$//g;

	    if (! $ln){
		next;
	    }

	    if ($ln =~ /^(?:[a-z]+\.)?([^,]+),?/i){

		my $h = $1;
		$h =~ s/^\s+//;
		$h =~ s/\s+$//;

		push @$headers, $h;
	    }

	    else {
		print "WTF... $ln";
		$cant_parse = 1;
	    }
	}
    }

    if ($cant_parse){
	$headers = undef;
    }

    my $sth = $dbh->prepare($sql);
    $sth->execute();

    if ($sth->err){
	die $sth->err;
    }

    TMS::sth2csv($sth, $opts{'o'}, $headers);
    exit();

}

sub usage {

    print <<END
usage: $PROGRAM_NAME -c <config> -b <branch> -s <sql input> -o <csv output>

-c path to your TMS (database) config file
-b which TMS database (or branch) to use; valid options are 'dev' and 'prod'
-s path to the file containing the SQL you want to run
-o path to the (CSV) file you want to write the results of your SQL query to
-H force output headers (a comma-separated list)
-h print this message

END

}
