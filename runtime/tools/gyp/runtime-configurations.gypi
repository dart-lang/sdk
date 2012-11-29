# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_debug_optimization_level%': '2',
    # If we have not set dart_io_support to 1 in Dart's all.gypi or common.gypi,
    # then do not build the native libraries supporting  dart:io.
    'dart_io_support%': 0,
    # Intel VTune related variables.
    'dart_vtune_support%': 0,
    'dart_vtune_root%': '/opt/intel/vtune_amplifier_xe',
  },

  'configurations': {
    'Dart_ia32_Base': {
      'variables': {
        'dart_vtune_lib_dir': '<(dart_vtune_root)/lib32',
      }
    },

    'Dart_x64_Base': {
      'variables': {
        'dart_vtune_lib_dir': '<(dart_vtune_root)/lib64',
      }
    },
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
        'conditions': [
          ['OS=="linux" and dart_vtune_support == 1', {
            'ldflags': ['-L<(dart_vtune_root)/lib32'],
          }]
        ],
      },

      'Dart_x64_Base': {
        'abstract': 1,
        'xcode_settings': {
          'ARCHS': [ 'x86_64' ],
        },
        'conditions': [
          ['OS=="linux" and dart_vtune_support == 1', {
            'ldflags': ['-L<(dart_vtune_root)/lib64'],
          }]
        ],
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
