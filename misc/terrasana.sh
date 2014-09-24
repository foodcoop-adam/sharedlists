#!/bin/sh
#
# Generate (Apache) Redirect line for Terrasana product by EAN
#   get EAN codes from their product list
#

EAN=$1

JSON=`curl -H 'Accept: application/json, text/javascript, */*' \
     -e 'http://terrasana.nl/nl/doorzoek-product.aspx' \
     -H 'Content-Type: application/json' \
     -H 'Accept: application/json' \
     -d '{datacollection_id: "cf6f00e9-6405-4998-959d-dc90463fb4ed",
          name:"",ingredients:"", ean:"'${EAN}'", brand:"", filterDietInfo:"",
          sort:"Name", page:1, pagesize:1}' \
     -s -S \
     http://terrasana.nl/DataService.aspx/GetProducts`

json_get() {
  python -c 'import sys,json,urllib; d=json.load(sys.stdin)["d"][0]; print urllib.quote(d["'"$1"'"].encode("utf-8"));'
}

ID=`echo "$JSON" | json_get ProductNumber | sed 's/\.//g'`
URL=http://terrasana.nl/_data/nl/`echo "$JSON" | json_get DrillDownUrl`
IMG=http://terrasana.nl/`echo "$JSON" | json_get ThumbnailUrl`

if [ -z "$ID" ]; then
  echo "No product info for EAN=${EAN}" 1>&2
  exit 1
fi

echo "Redirect /${ID} ${URL}"
