#!/bin/bash
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Deploy step for try.dartlang.org. Usage:
#
#   bash deploy.sh OLD NEW
#
# Where OLD and NEW are unique prefixes, for example, a short git commit hash.
# OLD is the existing prefix that should be replaced by NEW.

old=$1
new=$2
echo git checkout-index -a -f --prefix=$new/
echo rm -rf $old
echo sh $new/dart/web_editor/create_manifest.sh \> live.appcache
echo sed -e "'s/$old/$new/'" -i.$old index.html
