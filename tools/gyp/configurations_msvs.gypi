# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_debug_optimization_level%': '2',
  },
  'target_defaults': {
    'configurations': {
      'Dart_Win_Base': {
        'abstract': 1,
        'defines': [
          '_HAS_EXCEPTIONS=0',  # disable C++ exceptions use in C++ std. libs.
        ],
      },
      'Dart_Win_ia32_Base': {
        'abstract': 1,
      },
      'Dart_Win_x64_Base': {
        'abstract': 1,
        'msvs_configuration_platform': 'x64',
      },
      'Dart_Win_simarm_Base': {
        'abstract': 1,
      },
      'Dart_Win_simarm64_Base': {
        'abstract': 1,
      },
      'Dart_Win_simmips_Base': {
        'abstract': 1,
      },
      'Dart_Win_Debug': {
        'abstract': 1,
        'msvs_settings': {
          'VCCLCompilerTool': {
            'Optimization': '<(dart_debug_optimization_level)',
            'BasicRuntimeChecks': '0',  # disable /RTC1 when compiling /O2
            'DebugInformationFormat': '3',
            'ExceptionHandling': '0',
            'RuntimeTypeInfo': 'false',
            # Uncomment the following line and pass --profile-vm to enable
            # profiling of C++ code within Observatory.
            # 'OmitFramePointers': 'false',
            'RuntimeLibrary': '1',  # /MTd - Multi-threaded, static (debug)
          },
          'VCLinkerTool': {
            'LinkIncremental': '2',
            'GenerateDebugInformation': 'true',
            'StackReserveSize': '2097152',
            'AdditionalDependencies': [
              'advapi32.lib',
              'shell32.lib',
              'dbghelp.lib',
            ],
          },
        },
        # C4351 warns MSVC follows the C++ specification regarding array
        # initialization in member initializers.  Code that expects the
        # specified behavior should silence this warning.
        'msvs_disabled_warnings': [4351],
      },

      'Dart_Win_Release': {
        'abstract': 1,
        'msvs_settings': {
          'VCCLCompilerTool': {
            'Optimization': '2',
            'InlineFunctionExpansion': '2',
            'EnableIntrinsicFunctions': 'true',
            'FavorSizeOrSpeed': '0',
            'ExceptionHandling': '0',
            'RuntimeTypeInfo': 'false',
            # Uncomment the following line and pass --profile-vm to enable
            # profiling of C++ code within Observatory.
            # 'OmitFramePointers': 'false',
            'StringPooling': 'true',
            'RuntimeLibrary': '0',  # /MT - Multi-threaded, static
          },
          'VCLinkerTool': {
            'LinkIncremental': '1',
            'GenerateDebugInformation': 'true',
            'OptimizeReferences': '2',
            'EnableCOMDATFolding': '2',
            'StackReserveSize': '2097152',
            'AdditionalDependencies': [
              'advapi32.lib',
              'shell32.lib',
              'dbghelp.lib',
            ],
          },
        },
        # C4351 warns MSVC follows the C++ specification regarding array
        # initialization in member initializers.  Code that expects the
        # specified behavior should silence this warning.
        'msvs_disabled_warnings': [4351],
      },
    },
  },
}
