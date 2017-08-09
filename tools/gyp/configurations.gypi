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
      ['"<(target_arch)"=="armv6"', { 'dart_target_arch': 'ARMV6', }],
      ['"<(target_arch)"=="armv5te"', { 'dart_target_arch': 'ARMV5TE', }],
      ['"<(target_arch)"=="arm64"', { 'dart_target_arch': 'ARM64', }],
      ['"<(target_arch)"=="simarm"', { 'dart_target_arch': 'SIMARM', }],
      ['"<(target_arch)"=="simarmv6"', { 'dart_target_arch': 'SIMARMV6', }],
      ['"<(target_arch)"=="simarmv5te"', { 'dart_target_arch': 'SIMARMV5TE', }],
      ['"<(target_arch)"=="simarm64"', { 'dart_target_arch': 'SIMARM64', }],
      ['"<(target_arch)"=="simdbc"', { 'dart_target_arch': 'SIMDBC', }],
      ['"<(target_arch)"=="simdbc64"', { 'dart_target_arch': 'SIMDBC64', }],
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

      'Dart_simarmv6_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
          'TARGET_ARCH_ARM_6',
        ]
      },

      'Dart_simarmv5te_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
          'TARGET_ARCH_ARM_5TE',
        ]
      },

      'Dart_arm_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
        ],
      },

      'Dart_armv6_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
          'TARGET_ARCH_ARM_6',
        ],
      },

      'Dart_armv5te_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_ARM',
          'TARGET_ARCH_ARM_5TE',
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

      'Dart_simdbc_Base': {
        'abstract': 1,
        'defines': [
          'TARGET_ARCH_DBC',
          'USING_SIMULATOR',
        ]
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

      'Dart_Product' : {
        'abstract': 1,
        'defines' : [
          'NDEBUG',
          'PRODUCT',
        ]
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

      'ProductIA32': {
        'inherit_from': [
          'Dart_Base', 'Dart_ia32_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_ia32_Base',
          'Dart_<(dart_target_os)_Product',
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

      'ProductX64': {
        'inherit_from': [
          'Dart_Base', 'Dart_x64_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_x64_Base',
          'Dart_<(dart_target_os)_Product',
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

      'ProductSIMARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarm_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarm_Base',
          'Dart_<(dart_target_os)_Product',
        ],
      },

      'DebugSIMARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarmv6_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarmv6_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarmv6_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarmv6_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'ProductSIMARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarmv6_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarmv6_Base',
          'Dart_<(dart_target_os)_Product',
        ],
      },

      'DebugSIMARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarmv5te_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarmv5te_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarmv5te_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarmv5te_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'ProductSIMARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarmv5te_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarmv5te_Base',
          'Dart_<(dart_target_os)_Product',
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

      'ProductSIMARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simarm64_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simarm64_Base',
          'Dart_<(dart_target_os)_Product',
        ],
      },

      'DebugSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simdbc_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simdbc_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'ProductSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simdbc_Base',
          'Dart_<(dart_target_os)_Product',
        ],
      },

      'DebugSIMDBC64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Debug',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simdbc64_Base',
          'Dart_<(dart_target_os)_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseSIMDBC64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Release',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simdbc64_Base',
          'Dart_<(dart_target_os)_Release',
        ],
      },

      'ProductSIMDBC64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Product',
          'Dart_<(dart_target_os)_Base',
          'Dart_<(dart_target_os)_simdbc64_Base',
          'Dart_<(dart_target_os)_Product',
        ],
      },

      # Special Linux-only targets to enable SIMDBC cross compilation for
      # non-Android ARM devices.
      'DebugXARMSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_xarm_Base',
          'Dart_Linux_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseXARMSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_xarm_Base',
          'Dart_Linux_Release',
        ],
      },

      'ProductXARMSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_xarm_Base',
          'Dart_Linux_Product',
        ],
      },

      # ARM hardware configurations are only for Linux and Android.
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

      'ProductXARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_xarm_Base',
          'Dart_Linux_Product',
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

      'ProductARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_arm_Base',
          'Dart_Linux_Product',
        ],
      },

      'DebugXARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv6_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_xarmv6_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseXARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv6_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_xarmv6_Base',
          'Dart_Linux_Release',
        ],
      },

      'ProductXARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv6_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_xarmv6_Base',
          'Dart_Linux_Product',
        ],
      },

      'DebugARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv6_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_armv6_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv6_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_armv6_Base',
          'Dart_Linux_Release',
        ],
      },

      'ProductARMV6': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv6_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_armv6_Base',
          'Dart_Linux_Product',
        ],
      },

      'DebugXARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv5te_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_xarmv5te_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseXARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv5te_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_xarmv5te_Base',
          'Dart_Linux_Release',
        ],
      },

      'ProductXARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv5te_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_xarmv5te_Base',
          'Dart_Linux_Product',
        ],
      },

      'DebugARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv5te_Base', 'Dart_Debug',
          'Dart_Linux_Base',
          'Dart_Linux_armv5te_Base',
          'Dart_Linux_Debug',
        ],
      },

      'ReleaseARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv5te_Base', 'Dart_Release',
          'Dart_Linux_Base',
          'Dart_Linux_armv5te_Base',
          'Dart_Linux_Release',
        ],
      },

      'ProductARMV5TE': {
        'inherit_from': [
          'Dart_Base', 'Dart_armv5te_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_armv5te_Base',
          'Dart_Linux_Product',
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

      'ProductXARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_xarm64_Base',
          'Dart_Linux_Product',
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

      'ProductARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Product',
          'Dart_Linux_Base',
          'Dart_Linux_arm64_Base',
          'Dart_Linux_Product',
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

      'ProductAndroidIA32': {
        'inherit_from': [
          'Dart_Base', 'Dart_ia32_Base', 'Dart_Product',
          'Dart_Android_Base',
          'Dart_Android_ia32_Base',
          'Dart_Android_Product',
        ],
      },

      'DebugAndroidX64': {
        'inherit_from': [
          'Dart_Base', 'Dart_x64_Base', 'Dart_Debug',
          'Dart_Android_Base',
          'Dart_Android_x64_Base',
          'Dart_Android_Debug',
        ],
      },

      'ReleaseAndroidX64': {
        'inherit_from': [
          'Dart_Base', 'Dart_x64_Base', 'Dart_Release',
          'Dart_Android_Base',
          'Dart_Android_x64_Base',
          'Dart_Android_Release',
        ],
      },

      'ProductAndroidX64': {
        'inherit_from': [
          'Dart_Base', 'Dart_x64_Base', 'Dart_Product',
          'Dart_Android_Base',
          'Dart_Android_x64_Base',
          'Dart_Android_Product',
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

      'ProductAndroidARM': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm_Base', 'Dart_Product',
          'Dart_Android_Base',
          'Dart_Android_arm_Base',
          'Dart_Android_Product',
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

      'ProductAndroidARM64': {
        'inherit_from': [
          'Dart_Base', 'Dart_arm64_Base', 'Dart_Product',
          'Dart_Android_Base',
          'Dart_Android_arm64_Base',
          'Dart_Android_Product',
        ],
      },

      'DebugAndroidSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Debug',
          'Dart_Android_Base',
          # Default SIMDBC on Android targets arm.
          'Dart_Android_arm_Base',
          'Dart_Android_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseAndroidSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Release',
          'Dart_Android_Base',
          # Default SIMDBC on Android targets arm.
          'Dart_Android_arm_Base',
          'Dart_Android_Release',
        ],
      },

      'ProductAndroidSIMDBC': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Product',
          'Dart_Android_Base',
          # Default SIMDBC on Android targets arm.
          'Dart_Android_arm_Base',
          'Dart_Android_Product',
        ],
      },

      'DebugAndroidSIMDBC64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Debug',
          'Dart_Android_Base',
          # Default SIMDBC on Android targets arm64.
          'Dart_Android_arm64_Base',
          'Dart_Android_Debug',
        ],
        'defines': [
          'DEBUG',
        ],
      },

      'ReleaseAndroidSIMDBC64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Release',
          'Dart_Android_Base',
          # Default SIMDBC on Android targets arm64.
          'Dart_Android_arm64_Base',
          'Dart_Android_Release',
        ],
      },

      'ProductAndroidSIMDBC64': {
        'inherit_from': [
          'Dart_Base', 'Dart_simdbc_Base', 'Dart_Product',
          'Dart_Android_Base',
          # Default SIMDBC on Android targets arm64.
          'Dart_Android_arm64_Base',
          'Dart_Android_Product',
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
