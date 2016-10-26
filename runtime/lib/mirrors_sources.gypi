# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Implementation sources.

{
  'sources': [
    'mirrors.cc',
    'mirrors.h',
    # mirrors_patch.dart needs to be the first dart file because it contains
    # imports.
    'mirrors_patch.dart',
    'mirrors_impl.dart',
    'mirror_reference.dart',
  ],
}
