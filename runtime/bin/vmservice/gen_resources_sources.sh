# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#!/bin/sh


PACKAGES="analyzer_experimental args barback browser csslib custom_element"
PACKAGES="$PACKAGES html_import logging mdv meta mutation_observer"
PACKAGES="$PACKAGES observe path polymer polymer_expressions shadow_dom"
PACKAGES="$PACKAGES source_maps stack_trace unmodifiable_collection utf yaml"
TP_PACKAGES="html5lib"
FIND_PARAM="-not -iwholename *.svn* -not -name .gitignore -type f"
echo "# for details. All rights reserved. Use of this source code is governed by a"
echo "# BSD-style license that can be found in the LICENSE file."
echo ""
echo "# This file contains all sources for the Resources table."
echo "{"
echo "  'sources': ["
echo "#  VM Service backend sources"
for i in *.dart
do
echo "    'vmservice/$i',"
done
echo "#  VM Service client sources"
for i in `find client $FIND_PARAM`
do
echo "    'vmservice/$i',"
done
echo "#  Package sources"
for p in $PACKAGES
do
for i in `find ../../../pkg/$p/lib $FIND_PARAM`
do
j=`echo $i | sed "s;\.\./\.\./\.\./pkg/$p/lib/;;"`
echo "    '<(PRODUCT_DIR)/packages/$p/$j',"
done
done
echo "#  Third party package sources"
for p in $TP_PACKAGES
do
for i in `find ../../../pkg/third_party/$p/lib -type f -name "*"`
do
j=`echo $i | sed "s;\.\./\.\./\.\./pkg/third_party/$p/lib/;;"`
echo "    '<(PRODUCT_DIR)/packages/$p/$j',"
done
done
echo "  ],"
echo "}"

