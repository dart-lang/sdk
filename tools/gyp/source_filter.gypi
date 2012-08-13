# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'target_defaults': {
    'conditions': [
      ['OS!="android"', {'sources/': [['exclude', '_android\\.(cc|h)$']]}],
      ['OS!="linux"', {'sources/': [['exclude', '_linux\\.(cc|h)$']]}],
      ['OS!="mac"', {'sources/': [['exclude', '_macos\\.(cc|h)$']]}],
      ['OS!="win"', {'sources/': [['exclude', '_win\\.(cc|h)$']]}],
      ['OS=="win"', {'sources/': [['exclude', '_posix\\.(cc|h)$']]}],
    ],
  },
}
