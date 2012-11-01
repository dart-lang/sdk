# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_debug_optimization_level%': '2',
  },
  'target_defaults': {
    'configurations': {
      'Dart_Debug': {
        'msvs_settings': {
          'VCCLCompilerTool': {
            'Optimization': '<(dart_debug_optimization_level)',
            'BasicRuntimeChecks': '0',  # disable /RTC1 when compiling /O2
            'DebugInformationFormat': '3',
            'ExceptionHandling': '0',
            'RuntimeTypeInfo': 'false',
            'OmitFramePointers': 'false',
            'RuntimeLibrary': '1',  # /MTd - Multi-threaded, static (debug)
          },
          'VCLinkerTool': {
            'LinkIncremental': '2',
            'GenerateDebugInformation': 'true',
            'StackReserveSize': '2097152',
          },
        },
      },

      'Dart_Release': {
        'msvs_settings': {
          'VCCLCompilerTool': {
            'Optimization': '2',
            'InlineFunctionExpansion': '2',
            'EnableIntrinsicFunctions': 'true',
            'FavorSizeOrSpeed': '0',
            'ExceptionHandling': '0',
            'RuntimeTypeInfo': 'false',
            'OmitFramePointers': 'false',
            'StringPooling': 'true',
            'RuntimeLibrary': '0',  # /MT - Multi-threaded, static
          },
          'VCLinkerTool': {
            'LinkIncremental': '1',
            'GenerateDebugInformation': 'true',
            'OptimizeReferences': '2',
            'EnableCOMDATFolding': '2',
            'StackReserveSize': '2097152',
          },
        },
      },
    },
    'defines': [
      '_HAS_EXCEPTIONS=0',  # disable C++ exceptions use in C++ std. libs.
    ],
  },
}
