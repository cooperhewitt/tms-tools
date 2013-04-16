#!/usr/bin/env python

# this is just a dumb little helper tool
# it is not a pony (20120808/straup)

# TODO: regexp based column queries

import os
import os.path
import sys
import csv

def dump_values(reader, column):

    fieldnames = ['foo', 'count']

    # TODO: write to a file
    writer = csv.writer(sys.stdout)

    values = {}

    for row in reader:

        v = row[column]

        if v:
            v = v.strip()

        if values.get(v, False):
            values[v] += 1
        else:
            values[v] = 1

    for k, v in values.items():
        writer.writerow((k, v))

def filter_values(reader, column, value):

    # TODO: write to a file
    writer = csv.DictWriter(sys.stdout, reader.fieldnames)

    for row in reader:

        if row[column] != value:
            continue

        writer.writerow(row)

if __name__ == '__main__':

    import optparse

    parser = optparse.OptionParser(usage="python csv-inspector.py --options")

    parser.add_option('--csv', dest='csv',
                        help='The path to your tables.json file',
                        action='store')

    parser.add_option('--column', dest='column',
                        help='List tables with this column',
                        action='store')

    parser.add_option('--filter', dest='filter',
                        help='...',
                        action='store')

    options, args = parser.parse_args()

    if not os.path.exists(options.csv):
        print "invalid CSV argument"
        sys.exit()

    fh = open(options.csv, 'U')
    reader = csv.DictReader(fh)

    if options.column and options.filter:
        filter_values(reader, options.column, options.filter)
        
    elif options.column:
        dump_values(reader, options.column)

    else:
        pass

    sys.exit()
