 # Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'sources': [
    # collection_patch.dart needs to be the first dart file because it contains
    # imports.
    'collection_patch.dart',
    'compact_hash.dart',
    'linked_hash_map.cc',
  ],
}
