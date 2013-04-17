tms-tools
==

tms-tools is a suite of libraries and scripts to extract data from TMS as CSV
files. Each database table is dumped as a separate CSV file. That's it really.

At the end of it all TMS is a MS-SQL database and, in 2013, it still feels like
an epic struggle just to get the raw data out of TMS so that single task is
principally what these tools deal with.

Quite a lot of this functionality can be accomplished from the TMS or MS-SQL
applications themselves but that involves running a Windows machine and pressing
a lot of buttons. This code is designed to be part of an otherwise automated
system for working with your data.

There is no attempt to interpret the data or the reconcile the twisty maze of
relationships between the many tables in TMS. That is left as an exercise to the
reader. This is not a one-button magic pony. This is code that _works for us_ today. It
has issues. If you choose to use it you will probably discover new issues. Yay,
adventure!

**We are making this code available because we're all in the TMS soup together and
maybe the work we've done so far can help others and going forward we can try to
make things a little better, together.**

The tools
--

Check the `bin` directory for a complete list of tools but broadly speaking it
breaks down like this:

### A Perl module

`TMS.pm` handles the database connections (by handing everything off to the
`DBI` and `DBD::ODBC` Perl modules), the endless nightmare of encoding 
issues and converting database rows in to CSV files.

### A bunch of Perl scripts

These are the tools for performing specifc TMS related tasks: testing the
connection to the database; exporting one or more tables; running an arbitrary
SQL command and exporting the results as a CSV file.

### A bunch of Python scripts

These are the tools for doing things with the CSV files: dumping the data for a
particular column or listing database tables with a particular column.

Setup and install
--

### ODBC and FreeTDS

First you'll need to install a bunch of ODBC/TDS stuff to be able to talk to the
TMS/MSSQL database.

On a Mac:

	$> brew install freetds unixodb

On Ubuntu:

	$> apt-get install freetds-dev freetds-bin unixodbc unixodbc-dev tdsodbc

Further on Ubuntu you need to edit `/etc/odbcinst.ini` to look like this:

	[FreeTDS]
	Description = TDS driver (Sybase/MS SQL)
	Driver = /usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
	Setup = /usr/lib/x86_64-linux-gnu/odbc/libtdsS.so
	CPTimeout =
	CPReuse =
	FileUsage = 1

_You don't need to do this on a Mac because I could never figure out how to make it
work so instead the path to `/usr/local/lib/libtdsodbc.so` is hardcoded in the
TMS.pm module. Good times._ 

### Perl modules

Next you'll need to install a bunch of Perl modules. Get a cup of coffee.

* [Bundle::CPAN](http://search.cpan.org/dist/Bundle-CPAN)

* [DBI](http://search.cpan.org/dist/DBI)

* [DBD::ODBC](http://search.cpan.org/dist/DBD-ODBC)

* [Text::CSV_XS](http://search.cpan.org/dist/Text-CSV_XS)

* [Config::Simple](http://search.cpan.org/dist/Config-Simple)

* [Log::Dispatch](http://search.cpan.org/dist/Log-Dispatch)

* [JSON::XS](http://search.cpan.org/dist/JSON-XS)

_Some day I will write a proper `BUILD.pl` so that this can be installed from a
single command._

Config file
--

Database configurations are stored in a plain vanilla `ini` style config
file. Configurations are grouped by database clusters or "branches". Like this: 

	[prod]
	host=YOUR_TMS_DATABASE_HOSTNAME
	port=YOUR_TMS_DATABASE_PORT
	db=YOUR_TMS_DATABASE_NAME
	user=YOUR_TMS_DATABASE_USERNAME
	pswd=YOUR_TMS_DATABASE_PASSWORD

I don't really know why I called them branches but I also haven't gotten around
to renaming them. You need to define all the properties in a branch since
there's often little overlap between TMS installations. You might connect to one
database using an IP address where another is only listening for connections on one
of those weird Windows networking addresses that contains a backslash.

Testing the connection
--

To test a database connection you can use the `connect_tms.pl` script. You
should see something like this: 

	$> ./bin/connect_tms.pl -c tms.cfg -v -b prod

	connecting to the prod database <DATABASE>
	fetching tables
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'
	Connection to TMS is: GO!

Caveats (and other known knowns)
--

### Perl

Some of you might be thinking: _Perl???_ Yes, Perl.

It's not perfect and there still problems that need to be addressed (see
below). On the other hand it works unlike most of the other options which fail
somewhere in the toxic soup of Windows networking, the ODBC and ANSI-92
standards, OMGWTF-MS-SQL and general-purpose Hell that is character encoding.

For example the `pyodbc` Python module silently converts all data from UTF-8 to
UTF-16. But only on a 64-bit Macintosh. Because ... Unix?

### The LongReadLen problem

As of this writing one of the most pressing problems that we need to solve is
how address the DBI.pm `LongReadLen` problem, under Ubuntu.

Specifically: Sometimes the database schema in TMS (or MS-SQL, it's not clear who is
responsible) will say that the maximum length for certain text fields is
... -1. This has a couple of interesting side-effects:

Unless you set DBI.pm 's `LongTruncOk` flag then any data longer than 80 bytes
will silently be truncated. This is a problem for both object descriptions and
keyword fields, in TMS, that are abused for passing around institutional
narratives. I'm pretty sure that this is an ANSI SQL-92 thing but I can't say
for certain. Either way... WTF?

On the other hand if you unset the value then you need to explicitly say how big
a text field _might_ be because if the DBI code encounters something longer it
promptly blows its brains out. As if that weren't bad enough, the only number
that doesn't trigger this error is ... 2GB.

_If you're bored try setting `LongReadLen` to be the value of `POSIX::MAX_LONG`
but please don't complain or blame me when it all goes horribly wrong._

But only if you're doing your exports on a Mac. If you try to do the same thing,
with exactly the same code, on a Linux machine then you don't get past the first
row before Perl runs out of memory.

Not so good.

### MS-SQL's inability to do LIMIT, OFFSET

Seriously, just look at the kind of insane hoop-jumping required to query for a
fixed set of rows from a user-defined starting point. This means that we create a
database query handler for _all_ the rows in  a table at once rather than
iterating over the entire set in small batches.

This is mostly annoying but becomes problematic when we get to the...

### Mystery meat

There are still some rows that trigger fatal exceptions. It is still difficult
to know which row is failing or why because we still aren't counting row numbers
during exports. And even then there's the LIMIT, OFFSET problem described above.

These errors are few and far between enough that our code notes the error and
moves on but better tracking and debugging for these cases is definitely on the
TO DO list.

Future work
--

* Making this work on a Windows machine.

* Tools for importing CSV files in to [ElasticSearch](http://www.elasticsearch.org/) and tools for inspecting
  the data. ElasticSearch's ability to do schema-less indexing of heterogenous
  documents makes it a perfect tool for spelunking through the mass of stuff in
  a TMS database.

License
--
