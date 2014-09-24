#!/bin/sh
#
# UNSPSC (United Nations Standard Products and Services Code)
# is a taxonomy that could be used to classify articles.
# http://www.unspsc.org/
#
# There is a PDF download, from which we can parse the tree.
#
SRC="UNSPSC English v15_1101.pdf"
DST=`echo "$SRC"|sed 's/\.pdf/\.txt/i'`

pdftotext -layout "$SRC"
cat "$DST" | grep -v '\(UNSPSC Codeset\|v15.1101\|Page [0-9]\+ of [0-9]\+\|Commodity\s*Commodity Title\)' >"$DST.new" && \
  mv "$DST.new" "$DST"

# to split into csv
#sed 's/^[^0-9]\+\([0-9]\+\)\s*\(.*\)$/\1,\2/p;d'
