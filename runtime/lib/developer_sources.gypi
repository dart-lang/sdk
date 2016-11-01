# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Sources visible via dart:developer library.

{
  'sources': [
    'developer.cc',
    # developer.dart needs to be the first dart file because it contains
    # imports.
    'developer.dart',
    'profiler.cc',
    'profiler.dart',
    'timeline.cc',
    'timeline.dart',
  ],
}

