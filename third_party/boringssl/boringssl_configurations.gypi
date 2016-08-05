# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is included to modify the configurations to build third-party
# code from BoringSSL.
{
  'target_defaults': {
    'conditions': [
      ['OS == "linux" or OS == "android"', {
        'cflags_c': [
          '-std=c99',
        ],
        'defines': [
          '_XOPEN_SOURCE=700',
        ],
      }],
    ],
    # Removes these flags from the list cflags.
    'cflags!': [
      '-ansi',
      # Not supported for C, only for C++.
      '-Wnon-virtual-dtor',
      '-Wno-conversion-null',
      '-fno-rtti',
      '-fvisibility-inlines-hidden',
      '-Woverloaded-virtual',
    ],
  },
}
