#!/usr/bin/env python

# This script dumps every TMS table export from a specified directory and puts it into Elasticsearch.
# To use: ./index-elasticsearch.py /path/to/csv/folder

# Requires the elasticsearch Python library, available on pip.

# Every TMS table csv gets will get its own index, prefixed with "tms-".
# For example, MediaRelated.csv gets dumped into the index "tms-mediarelated" (note lowercase and removal of .csv)

# TMS can contain sensitive data. If you don't want that going in to Elasticsearch, suppress indexing of the sensitive
# file/field at the appropriate step in this process (commented below).

# I've left it to Elasticsearch to come up with the type for every field, but have also given
# every field a raw property for unanalyzed string-based querying (see create_index()). Elasticsearch sometimes
# guesses types incorrectly (e.g. it treats our accession numbers as dates, not strings), so in those cases
# you can query on the "raw" field for unanalyzed string matching. 
# see: http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/mapping-intro.html

import csv
import os
import os.path
import sys
from elasticsearch import Elasticsearch

es = Elasticsearch()

def reset_index(idx):
	try:
		es.indices.delete(index=idx)
		print('delete index %s' % idx)
	except:
		print('no index named ' + idx)

def create_index(idx):
	params = {
		# create raw field for every property just in case
		'mappings': {
			'_default_': {
				'_all': {
					'fields': {
						'raw': {
							'type': 'string',
							'index': 'not_analyzed'
						}
					}
				}
			}
		}
	}

	es.indices.create(index=idx, body=params)
	print('create index %s' % idx)

def main():
	print("let's dump tms into elasticsearch!")

	dump_dir = sys.argv[1]

	for root, dirs, files in os.walk(dump_dir):
		for f in files:

			if '.bak' in f or not '.csv' in f:
				continue

			# If you want to intentionally ignore any specific files, do that here.
			# e.g.
			# --------
			# if 'Objects.csv' in f:
			#	continue

			print("processing %s" % f)

			typ = f.replace('.csv','').lower()
			idx = 'tms-' + typ
			
			reset_index(idx)
			create_index(idx)

			table_path = os.path.join(dump_dir, f)
			table = open(table_path, 'rU')

			try:
				table_reader = csv.DictReader(table)
				id=0

				for row in table_reader:
					for prop in row:
						# Elasticsearch would rather you pass null than empty strings, especially for dates.
						# I had trouble implementing ignore_malformed in the mappings, so this is the next best solution.
						# see http://stackoverflow.com/questions/15924632/empty-string-in-elasticsearch-date-field
						if row[prop]=='':
							row[prop] = None

						# If you want to intentionally not index any fields, do that here.
						# e.g.
						# ---------
						# if prop == 'ID':
						#	del row[prop]
						
					es.index(index=idx, doc_type=typ, id=id, body=row)
					id+=1
					
			finally:
				table.close()

	print("done")


if __name__ == '__main__':
	main()