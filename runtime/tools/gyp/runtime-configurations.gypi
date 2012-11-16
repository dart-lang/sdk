# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_debug_optimization_level%': '2',
    # If we have not set dart_io_support to 1 in Dart's all.gypi or common.gypi,
    # then do not build the native libraries supporting  dart:io.
    'dart_io_support%': 0,
  },

  'target_defaults': {
    'configurations': {

      'Dart_Base': {
        'abstract': 1,
        'xcode_settings': {
          'GCC_WARN_HIDDEN_VIRTUAL_FUNCTIONS': 'YES', # -Woverloaded-virtual
        },
      },

      'Dart_Debug': {
        'abstract': 1,
        'defines': [
          'DEBUG',
        ],
        'xcode_settings': {
          'GCC_OPTIMIZATION_LEVEL': '<(dart_debug_optimization_level)',
        },
      },

      'Debug': {
        'defines': [
          'DEBUG',
        ],
      },

      'Dart_ia32_Base': {
        'abstract': 1,
        'xcode_settings': {
          'ARCHS': [ 'i386' ],
        },
      },

      'Dart_x64_Base': {
        'abstract': 1,
        'xcode_settings': {
          'ARCHS': [ 'x86_64' ],
        },
      },

      'Dart_simarm_Base': {
        'abstract': 1,
        'xcode_settings': {
          'ARCHS': [ 'i386' ],
          'GCC_OPTIMIZATION_LEVEL': '3',
        },
      },

      'Dart_Release': {
        'abstract': 1,
        'xcode_settings': {
          'GCC_OPTIMIZATION_LEVEL': '3',
        },
      },
    },
  },
}
