#!/bin/sh
#
# Generate RewriteRule for Mattison product id
#
#   Try all products ids, e.g. using something like:
#
#     for i in `seq 1100 3220`; do
#       printf 'MT%04d\n' $i;
#     done
#     for i in `seq 0 20`; do
#       printf 'RAW%03d\n' $i;
#     done
#

ID=$1

JSON=`curl -H 'Accept: application/json, text/javascript, */*' \
     -e 'http://www.mattison.nl/' \
     -H 'Accept: application/json' \
     -d 'val='"${ID}" \
     -s -S \
     http://www.mattisson.nl/services/searchContent.php`

json_get() {
  python -c 'import sys,json,urllib; d=json.load(sys.stdin)["products"][0]; print urllib.quote(d["'"$1"'"].encode("utf-8"));'
}
json_check() {
  python -c 'import sys,json,urllib; d=json.load(sys.stdin); len(d["products"]) > 0 and sys.exit(1);'
}

if [ -z "$JSON" ] || echo "$JSON" | json_check; then
  echo "No product info for ID=${ID}" 1>&2
  exit 1
fi

URL=http://mattisson.nl`echo "$JSON" | json_get urladdress`
IMG=http://mattisson.nl`echo "$JSON" | json_get image`

echo "RewriteRule ^${ID}$ ${URL}"
