package TMS;
use base qw (Exporter);

use strict;

use DBI;
use DBD::ODBC;

use English;
use Encode;
use Text::CSV_XS;

sub dbh {

    my $cfg = shift;
    my $branch = shift;

    my $host = $cfg->param("$branch.host");
    my $port = $cfg->param("$branch.port");

    my $db = $cfg->param("$branch.db");
    my $user = $cfg->param("$branch.user");
    my $pswd = $cfg->param("$branch.pswd");

    # See this? It's relevant. The 'dev' TMS database server requires
    # that you pass in the port number. The 'prod' database on the
    # other hand will freak out and die if you do. So don't. Unless
    # you're talking to the 'dev' database. Yeah. Good times.
    # (20120720/straup)

    my $dsn = undef;

    # Why this? Because it was the only way to make it work under OS X.
    # Conveniently it totally doesn't work on Ubuntu. Because... puppies?
    # (20121005/straup)

    if ($OSNAME eq 'darwin'){
	$dsn = "dbi:ODBC:DRIVER={/usr/local/lib/libtdsodbc.so};Server=$host;DATABASE=$db;";
    }

    elsif ($OSNAME eq 'linux'){
	$dsn = "dbi:ODBC:DRIVER=FreeTDS;Server=$host;DATABASE=$db;charset=UTF-8;";

	# Because... because... because... ponies?
	# But really it's because of some hair-brained default
	# in the packaging system (I think?) or somewhere. Guh.
	# (20121005/straup)

	$ENV{'TDSVER'} = '7.1';
    }

    else {
	warn "Unknown operating system ($OSNAME)... HALP!";
	return undef;
    }

    if ($port){
	$dsn .= "PORT=$port;";
    }

    # $log->info("connecting to $host as $user ($dsn)");

    my $dbh = DBI->connect($dsn, $user, $pswd);

    if (! $dbh){
	return 0;
    }

    # http://code.activestate.com/lists/perl-win32-database/2185/
    # http://www.nntp.perl.org/group/perl.dbi.users/2011/06/msg35868.html

    # You know what's fucking awesome? If you call this then the subsequent
    # SQL statement to get the list of table names fails. Because... well,
    # I have no fucking clue. So instead we'll just hard-coded 2147483647
    # below. (20120718/straup)

    if (0){
	my $sql = 'SELECT @@TEXTSIZE';
	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my $row = $sth->fetchrow_arrayref();
	my $read_len = $row->[0];
    }

    # See above; do not set this to POSIX::MAX_LONG, trust me...

    my $read_len = 2147483647;

    $dbh->{'LongTruncOk'} = 0;
    $dbh->{'LongReadLen'} = $read_len;

    $dbh->{'HandleError'} = sub{
	
    };

    $dbh->{'PrintError'} = 1;
    $dbh->{'TraceLevel'} = 0;

    return $dbh;
}

sub sth2csv {

    my $sth = shift;
    my $csv_file = shift;
    my $headers = shift;

    open my $fh, ">:encoding(utf8)", $csv_file;

    my $csv = Text::CSV_XS->new();
    $csv->eol ("\n");

    if (($headers) && (ref($headers) eq 'ARRAY')){
	$csv->print($fh, $headers);
    }

    my $i = 0;

    while (1){

	my $row = $sth->fetchrow_arrayref();

	if ((! $row) && (! $sth->err)){
	    last;
	}

	elsif ($sth->err){
	    # $log->warning("skip line $i");
	}

	else {

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

return 1;
