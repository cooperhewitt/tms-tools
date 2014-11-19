Database tools
--

### connect_tms.pl

	$>./connect_tms.pl -h
	usage: ./connect_tms.pl -c <config> -b <branch>

	-c path to your TMS (database) config file
	-b which TMS database (or branch) to use
	-v enable verbose logging
	-h print this message

### dump_tms.pl

	$>./dump_tms.pl  -h
	usage: ./dump_tms.pl -c <config> -b <branch>

	-c path to your TMS (database) config file
	-b which TMS database (or branch) to use
	-T limit dumps to a specific comma-separated list of tables (optional)
	-v enable verbose logging
	-t test the connection to the TMS server and then exit
	-h print this message

This script will export all or a user-defined list of tables in a TMS database
as individual CSV files. Names of the CSV files correspond to their database
table name.

Additionally, the script will generate both a JSON and Markdown file containing
the list of all the tables in a database and the metadata about the individual
columns (data type, length, etc.).

This should probably be in a separate script as it runs whether you're exporting
one table or all of them but it just hasn't happened yet.

### dump_sql.pl

	$>./dump_sql.pl -h
	usage: ./dump_sql.pl -c <config> -b <branch> -s <sql input> -o <csv output>

	-c path to your TMS (database) config file
	-b which TMS database (or branch) to use; valid options are 'dev' and 'prod'
	-s path to the file containing the SQL you want to run
	-o path to the (CSV) file you want to write the results of your SQL query to
	-H force output headers (a comma-separated list)
	-h print this message

## Data (CSV) tools

### csv-dump-row.py

	$>./csv-dump-row.py -h
	Usage: python csv-dump-row.py --options

	Options:
	  -h, --help       show this help message and exit
	  --csv=CSV        The CSV file you want to investigate
	  --column=COLUMN  The column name for the row you want to dump
	  --value=VALUE    The value of the column for the row you want to dump

### csv-inspector.py

	$>./csv-inspector.py -h
	Usage: python csv-inspector.py --options

	Options:
	  -h, --help       show this help message and exit
	  --csv=CSV        The path to the CSV filter you want to investigate
	  --column=COLUMN  The column to dump a list of unique values (and counts) for
	  --filter=FILTER  Only generate a count for columns with this value

## ElasticSearch tools

### index-elasticsearch.py

	# ./index-elasticsearch.py /path/to/csv/folder
	
This script takes every TMS table exported by dump_tms.pl and indexes it in an [Elasticsearch](http://www.elasticsearch.org/) instance.

Every TMS table csv gets will get its own index, prefixed with `tms-`. For example, `MediaRelated.csv` gets dumped into the index `tms-mediarelated` (note lowercase and removal of .csv)

Your instance TMS may contain sensitive data. **If you don't want sensitive data going in to Elasticsearch** you will need to modify the code suppress indexing of the sensitive file/field at [around line 95](https://github.com/cooperhewitt/tms-tools/blob/master/bin/index-elasticsearch.py#L95-L99).

_Requires the [elasticsearch](https://pypi.python.org/pypi/elasticsearch/) Python library._
