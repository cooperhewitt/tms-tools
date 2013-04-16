#!/usr/bin/env python

if __name__ == '__main__':

    import csv
    import optparse
    import os.path
    import pprint 
    import sys

    parser = optparse.OptionParser(usage="python csv-dump-row.py --options")

    parser.add_option('--csv', dest='csv',
                        help='The path to your tables.json file',
                        action='store')

    parser.add_option('--column', dest='column',
                        help='List tables with this column',
                        action='store')

    parser.add_option('--value', dest='value',
                        help='...',
                        action='store')

    options, args = parser.parse_args()

    if not os.path.exists(options.csv):
        print "invalid CSV argument"
        sys.exit()

    fh = open(options.csv, 'U')
    reader = csv.DictReader(fh)

    for row in reader:

        if not row.has_key(options.column):
            print "invalid column"
            sys.exit()

        if row[options.column] == options.value:
            
            print pprint.pformat(row)
            break

    sys.exit()
