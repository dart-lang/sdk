# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'common_gcc_warning_flags': [
      '-Wall',
      '-Wextra', # Also known as -W.
      '-Wno-unused-parameter',
    ],

    # Default value.  This may be overridden in a containing project gyp.
    'target_arch%': 'ia32',

    'conditions': [
      ['"<(target_arch)"=="ia32"', { 'dart_target_arch': 'IA32', }],
      ['"<(target_arch)"=="x64"', { 'dart_target_arch': 'X64', }],
      ['"<(target_arch)"=="arm"', { 'dart_target_arch': 'ARM', }],
      ['"<(target_arch)"=="arm64"', { 'dart_target_arch': 'ARM64', }],
      ['"<(target_arch)"=="simarm"', { 'dart_target_arch': 'SIMARM', }],
      ['"<(target_arch)"=="simarm64"', { 'dart_target_arch': 'SIMARM64', }],
      ['"<(target_arch)"=="mips"', { 'dart_target_arch': 'MIPS', }],
      ['"<(target_arch)"=="simmips"', { 'dart_target_arch': 'SIMMIPS', }],
      [ 'OS=="linux"', { 'dart_target_os': 'Linux', } ],
      [ 'OS=="mac"', { 'dart_target_os': 'Macos', } ],
      [ 'OS=="win"', { 'dart_target_os': 'Win', } ],
      # The OS is set to "android" only when we are building Dartium+Clank. We
      # use 'chrome_target_os' so that Release and Debug configurations inherit
      # from Android configurations when OS=="android". If OS is not set to
      # Android, then Release and Debug inherit from the usual configurations.
      [ 'OS=="android"', { 'chrome_target_os': 'Android',},
                         { 'chrome_target_os': '',}],
    ],
  },
  'includes': [
    'configurations_android.gypi',
    'configurations_make.gypi',
    'configurations_xcode.gypi',
    'configurations_msvs.gypi',
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

      'Dart_simarm64_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM64',
        ]
      },

      'Dart_arm64_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM64',
        ],
      },

      'Dart_simmips_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_MIPS',
        ]
      },

      'Dart_mips_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_MIPS',
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


      # Configurations
      'DebugIA32': {
        'inherit_from': [
          'Dart_Base', 'Dart_ia32_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_ia32_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
      },

      'ReleaseIA32': {
        'inherit_from': [
          'Dart_Base', 'Dart_ia32_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_ia32_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'DebugX64': {
        'inherit_from': [
          'Dart_Base', 'Dart_x64_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_x64_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
      },

      'ReleaseX64': {
        'inherit_from': [
          'Dart_Base', 'Dart_x64_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_x64_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'DebugSIMARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarm_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarm_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarm_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarm_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'DebugSIMARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarm64_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarm64_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarm64_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarm64_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'DebugSIMMIPS': {
        'inherit_from': [
          'Dart_Base', 'Dart_simmips_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simmips_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMMIPS': {
        'inherit_from': [
          'Dart_Base', 'Dart_simmips_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simmips_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },


      # ARM and MIPS hardware configurations are only for Linux and Android.
      'DebugXARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_xarm_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseXARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_xarm_Base',
          'Dart_Linux_Release',
        ],
      },

      'DebugARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_arm_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_arm_Base',
          'Dart_Linux_Release',
        ],
      },

      'DebugXARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_xarm64_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseXARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_xarm64_Base',
          'Dart_Linux_Release',
        ],
      },

      'DebugARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_arm64_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_arm64_Base',
          'Dart_Linux_Release',
        ],
      },

      'DebugXMIPS': {
        'inherit_from': [
          'Dart_Base', 'Dart_mips_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_xmips_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseXMIPS': {
        'inherit_from': [
          'Dart_Base', 'Dart_mips_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_xmips_Base',
          'Dart_Linux_Release',
        ],
      },

      'DebugMIPS': {
        'inherit_from': [
          'Dart_Base', 'Dart_mips_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_mips_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseMIPS': {
        'inherit_from': [
          'Dart_Base', 'Dart_mips_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_mips_Base',
          'Dart_Linux_Release',
        ],
      },

      # Android configurations. The configuration names explicitly include
      # 'Android' because we are cross-building from Linux, and, when building
      # the standalone VM, we cannot inspect the gyp built-in 'OS' variable to
      # figure out that we are building for Android. Since we have not re-run
      # gyp, it will still be 'linux'.
      'DebugAndroidIA32': {
        'inherit_from': [
          'Dart_Base', 'Dart_ia32_Base', 'Dart_Debug',
          'Dart_Android_Base',
          'Dart_Android_ia32_Base',
          'Dart_Android_Debug',
        ],
      },

      'ReleaseAndroidIA32': {
        'inherit_from': [
          'Dart_Base', 'Dart_ia32_Base', 'Dart_Release',
          'Dart_Android_Base',
          'Dart_Android_ia32_Base',
          'Dart_Android_Release',
        ],
      },

      'DebugAndroidARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Debug',
          'Dart_Android_Base',
          'Dart_Android_arm_Base',
          'Dart_Android_Debug',
        ],
      },

      'ReleaseAndroidARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Release',
          'Dart_Android_Base',
          'Dart_Android_arm_Base',
          'Dart_Android_Release',
        ],
      },

      'DebugAndroidARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Debug',
          'Dart_Android_Base',
          'Dart_Android_arm64_Base',
          'Dart_Android_Debug',
        ],
      },

      'ReleaseAndroidARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Release',
          'Dart_Android_Base',
          'Dart_Android_arm64_Base',
          'Dart_Android_Release',
        ],
      },

      # These targets assume that target_arch is passed in explicitly
      # by the containing project (e.g., chromium).
      'Debug': {
        'inherit_from': ['Debug<(chrome_target_os)<(dart_target_arch)']
      },

      'Release': {
        'inherit_from': ['Release<(chrome_target_os)<(dart_target_arch)']
      },

      'conditions': [
        # On Windows ninja generator has hardcorded configuration naming
        # patterns and it expects that x64 configurations are named smth_x64.
        # This is a workaround for the crash that these expectations cause.
        [ 'OS=="win" and GENERATOR=="ninja"', {
          'DebugX64_x64': {
            'inherit_from': [ 'DebugX64' ]
          },

          'ReleaseX64_x64': {
            'inherit_from': [ 'ReleaseX64' ]
          },
        }],
      ],
    },
  },
}
