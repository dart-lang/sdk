# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Sources that patch the library "dart:_collection-dev".

{
  'sources': [
    'collection_dev_patch.dart',
    # The above file needs to be first as it imports required libraries.
    'symbol_patch.dart',
  ],
}
