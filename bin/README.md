### Database tools

connect_tms.pl
--

dump_tms.pl
--

This script will export all or a user-defined list of tables in a TMS database
as individual CSV files. Names of the CSV files correspond to their database
table name.

Additionally, the script will generate both a JSON and Markdown file containing
the list of all the tables in a database and the metadata about the individual
columns (data type, length, etc.).

This should probably be in a separate script as it runs whether you're exporting
one table or all of them but it just hasn't happened yet.

dump_sql.pl
--

### Data (CSV) tools

csv-dump-row.py
--

csv-inspector.py
--

