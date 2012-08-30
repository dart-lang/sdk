# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_debug_optimization_level%': '2',
  },
  'target_defaults': {
    'configurations': {

      'Dart_Base': {
        'xcode_settings': {
          'GCC_WARN_HIDDEN_VIRTUAL_FUNCTIONS': 'YES', # -Woverloaded-virtual
        },
      },

      'Dart_Debug': {
        'abstract': 1,
        'defines': [
          'DEBUG',
        ],
      },

      'Debug': {
        'defines': [
          'DEBUG',
        ],
      },

      'Dart_ia32_Base': {
        'xcode_settings': {
          'ARCHS': [ 'i386' ],
        },
      },

      'Dart_x64_Base': {
        'xcode_settings': {
          'ARCHS': [ 'x86_64' ],
        },
      },

      'Dart_simarm_Base': {
        'xcode_settings': {
          'ARCHS': [ 'i386' ],
          'GCC_OPTIMIZATION_LEVEL': '3',
        },
      },

      'Dart_Debug': {
        'xcode_settings': {
          'GCC_OPTIMIZATION_LEVEL': '<(dart_debug_optimization_level)',
        },
      },

      'Dart_Release': {
        'xcode_settings': {
          'GCC_OPTIMIZATION_LEVEL': '3',
        },
      },
    },
  },
}
