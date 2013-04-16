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

    $log->info("connecting to the $branch database $db");

    my $dbh = TMS::dbh($cfg, $branch);

    my $sql = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'";
    $log->debug($sql);

    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my $row = $sth->fetchrow_arrayref();

    if ($row){
	$log->info("Connection to TMS is: GO!");
    }

    else {
	$log->info("Connection to TMS is: SAD.");
    }

    $log->info("done");
    return 1;
    
}

sub usage {

    print <<END
usage: $PROGRAM_NAME -c <config> -b <branch>

-c path to your TMS (database) config file
-b which TMS database (or branch) to use; valid options are 'dev' and 'prod'
-v enable verbose logging
-h print this message

END

}
