# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'common_gcc_warning_flags': [
      '-Wall',
      '-Wextra', # Also known as -W.
      '-Wno-unused-parameter',
      # TODO(v8-team): Fix V8 build.
      #'-Wold-style-cast',
    ],

    # Default value.  This may be overridden in a containing project gyp.
    'target_arch%': 'ia32',

    # Don't use separate host toolset for compiling V8.
    'want_separate_host_toolset': 0,

  'conditions': [
    ['"<(target_arch)"=="ia32"', { 'dart_target_arch': 'IA32', }],
    ['"<(target_arch)"=="x64"', { 'dart_target_arch': 'X64', }],
    ['"<(target_arch)"=="arm"', { 'dart_target_arch': 'ARM', }],
    ['"<(target_arch)"=="simarm"', { 'dart_target_arch': 'SIMARM', }],
  ],
  },
  'conditions': [
    [ 'OS=="linux"', { 'includes': [ 'configurations_make.gypi', ], } ],
    [ 'OS=="mac"', { 'includes': [ 'configurations_xcode.gypi', ], } ],
    [ 'OS=="win"', { 'includes': [ 'configurations_msvs.gypi', ], } ],
  ],
  'target_defaults': {
    'default_configuration': 'DebugIA32',
    'configurations': {
      'Dart_Base': {
        'abstract': 1,
      },

      'Dart_ia32_Base': {
        'abstract': 1,
      },

      'Dart_x64_Base': {
        'abstract': 1,
      },

      'Dart_simarm_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
        ]
      },

      'Dart_arm_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
        ],
      },

      'Dart_Debug': {
        'abstract': 1,
      },

      'Dart_Release': {
        'abstract': 1,
        'defines': [
          'NDEBUG',
        ],
      },

      'DebugIA32': {
        'inherit_from': ['Dart_Base', 'Dart_ia32_Base', 'Dart_Debug'],
      },

      'ReleaseIA32': {
        'inherit_from': ['Dart_Base', 'Dart_ia32_Base', 'Dart_Release'],
      },

      'DebugX64': {
        'inherit_from': ['Dart_Base', 'Dart_x64_Base', 'Dart_Debug'],
      },

      'ReleaseX64': {
        'inherit_from': ['Dart_Base', 'Dart_x64_Base', 'Dart_Release'],
      },

      'DebugSIMARM': {
        # Should not inherit from Dart_Debug because Dart_simarm_Base defines
        # the optimization level to be -O3, as the simulator runs too slow
        # otherwise.
        'inherit_from': ['Dart_Base', 'Dart_simarm_Base'],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMARM': {
        # Should not inherit from Dart_Release (see DebugSIMARM).
        'inherit_from': ['Dart_Base', 'Dart_simarm_Base'],
        'defines': [
          'NDEBUG',
        ],
      },

      'DebugARM': {
        'inherit_from': ['Dart_Base', 'Dart_arm_Base', 'Dart_Debug'],
      },

      'ReleaseARM': {
        'inherit_from': ['Dart_Base', 'Dart_arm_Base', 'Dart_Release'],
      },

      # These targets assume that target_arch is passed in explicitly
      # by the containing project (e.g., chromium).
      'Debug': {
        'inherit_from': ['Debug<(dart_target_arch)']
      },

      'Release': {
        'inherit_from': ['Release<(dart_target_arch)']
      },
    },
  },
}
