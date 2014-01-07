old=$1
new=$2
echo git checkout-index -a -f --prefix=$new/
echo rm -rf $old
echo sh $new/dart/web_editor/create_manifest.sh \> live.appcache
echo sed -e "'s/$old/$new/'" -i.$old index.html
