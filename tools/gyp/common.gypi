# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# A set of variables needed to build some of the Chrome based subparts of the
# Dash project (e.g. V8). This is in no way a complete list of variables being
# defined by Chrome, but just the minimally needed subset.

# Note: this file is similar to all.gypi, but is used when running gyp
# from subproject directories.  This is deprecated, but still supported.
{
  'variables': {
    'library': 'static_library',
    'component': 'static_library',
    'host_arch': 'ia32',
    'target_arch': 'ia32',
    'v8_location': '<(DEPTH)/../third_party/v8',
  },
  'conditions': [
    [ 'OS=="linux"', {
      'target_defaults': {
        'ldflags': [ '-pthread', ],
      },
    }],
    [ 'OS=="win"', {
      'target_defaults': {
        'msvs_cygwin_dirs': ['<(DEPTH)/../third_party/cygwin'],
      },
    }],
  ],
  'includes': [
    'xcode.gypi',
    'configurations.gypi',
    'source_filter.gypi',
  ],
}
