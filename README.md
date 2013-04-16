tms-tools
==

tms-tools is a suite of libraries and scripts to extract data from TMS as one
CSV files per database table. That's it really.

At the end of it all TMS is a MS-SQL database and, in 2013, it still feels like
and epic struggle just to get the raw data out of TMS itself so that is
principally what these tools deal with.

Quite a lot of this functionality can be accomplished from the TMS or MS-SQL
applications themselves but that involves running a Windows machine and pressing
a lot of buttons. This code is designed to be part of an otherwise automated
system for working with your data.

There is no attempt to interpret the data or the reconcile the twisty maze of
relationships between the many tables in TMS. That is left as an exercise to the
reader.

The tools
--

Check the `bin` directory for a complete list of tools but broadly speaking it
breaks down like this:

### A Perl module

`TMS.pm` handles the database connections (by handing it all of to the amazing
[DBI]() and [DBD::ODBC]() Perl modules), the endless nightmare of encoding
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
work so instead the path to `/usr/local/lib/libtdsodbc.so` is hardcoded in our
TMS.pm wrapper. Good times._ 

### Perl modules

Next you'll need to install a bunch of Perl modules. Get a cup of coffee.

* Bundle::CPAN

* DBD::ODBC

* Text::CSV_XS

* Config::Simple

* Log::Dispatch

* JSON::XS

_Soon I will write a proper `BUILD.pl` so that this can be installed from a
single command._

Config file
--

	[prod]
	host=YOUR_TMS_HOST_NAME
	port=1433
	db=YOUR_TMS_DATABASE_NAME
	user=YOUR_TMS_USERNAME
	pswd=YOUR_TMS_PASSWORD

Testing the connection
--

You should see something like this:

	$> ./bin/dump_tms.pl -c tms.cfg -t -v -b prod

	connecting to the prod database CHTMS
	fetching tables
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'
	Connection to TMS is: GO!

Caveats
--

* Some of you might be thinking: _Perl???_ Yes, Perl. It's not perfect and there
is a list of known-known problems that need to be addressed (see below). On the
other hand it works unlike most of the other options which fail somewhere in the
toxic soup of Windows networking, the ODBC and ANSI-92 standards, OMGWTF-MS-SQL
and UTF-8 encoding Hell.

Future work
--

* Making this work on a Windows machine.

See also
--
