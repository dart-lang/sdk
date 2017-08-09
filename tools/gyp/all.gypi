# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# A set of variables needed to build some of the Chrome based subparts of the
# Dart project. This is in no way a complete list of variables being defined
# by Chrome, but just the minimally needed subset.
{
  'variables': {
    'library': 'static_library',
    'component': 'static_library',
    'target_arch': 'ia32',
    # Flag that tells us whether to build native support for dart:io.
    'dart_io_support': 1,
    # Flag that tells us whether this is an ASAN build.
    'asan%': 0,
    # Flag that tells us whether this is a MSAN build.
    'msan%': 0,
    # Flag that teslls us whether this is a TSAN build.
    'tsan%': 0,
  },
  'conditions': [
    [ 'OS=="linux"', {
      'target_defaults': {
        'ldflags': [ '-pthread', ],
      },
    }],
    [ 'OS=="win"', {
      'target_defaults': {
        'msvs_cygwin_dirs': ['<(DEPTH)/third_party/cygwin'],
      },
      'includes': [
        'msvs.gypi',
      ],
    }],
    [ 'OS=="mac"', {
      'includes': [
        'xcode.gypi',
      ],
    }],
  ],
  'includes': [
    'configurations.gypi',
  ],
}
