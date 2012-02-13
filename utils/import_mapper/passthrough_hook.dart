// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A trivial identity import hook that generates an import map that maps all
 * imports to their original import string.
 */
#library('passthrough_hook');

#import('import_mapper.dart');

void main() {
  printImportMap((context, name) => name);
}
