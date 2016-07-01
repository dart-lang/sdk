# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Definitions for building standalone Dart binaries to run on Fuchsia.

{
  'variables': {
    'fuchsia_tools': '<(PRODUCT_DIR)/../../third_party/fuchsia_tools/',
  },  # variables
  'target_defaults': {
    'configurations': {
      'Dart_Fuchsia_Base': {
        'abstract': 1,
        'cflags': [
          '-Werror',
          '<@(common_gcc_warning_flags)',
          '-Wnon-virtual-dtor',
          '-Wvla',
          '-Woverloaded-virtual',
          '-g3',
          '-ggdb3',
          '-fno-rtti',
          '-fno-exceptions',
          '-fstack-protector',
          '-Wa,--noexecstack',
        ],
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags!': [
              '-pthread',  # Not supported by Android toolchain.
            ],
          }],
        ],
      },
      'Dart_Fuchsia_Debug': {
        'abstract': 1,
        'defines': [
          'DEBUG',
        ],
        'cflags': [
          '-fno-omit-frame-pointer',
        ],
      },
      'Dart_Fuchsia_Release': {
        'abstract': 1,
        'defines': [
          'NDEBUG',
        ],
        'cflags!': [
          '-O2',
          '-Os',
        ],
        'cflags': [
          '-fno-omit-frame-pointer',
          '-fdata-sections',
          '-ffunction-sections',
          '-O3',
        ],
      },
      'Dart_Fuchsia_Product': {
        'abstract': 1,
        'defines': [
          'NDEBUG',
          'PRODUCT',
        ],
        'cflags!': [
          '-O2',
          '-Os',
        ],
        'cflags': [
          '-fdata-sections',
          '-ffunction-sections',
          '-O3',
        ],
      },
      'Dart_Fuchsia_x64_Base': {
        'abstract': 1,
        'variables': {
          'fuchsia_sysroot': '<(fuchsia_tools)/sysroot/x86_64',
          'fuchsia_include': '<(fuchsia_sysroot)/usr/include',
          'fuchsia_lib': '<(fuchsia_sysroot)/usr/lib',
        },
        'target_conditions': [
          ['_toolset=="target"', {
            'defines': [
              'TARGET_OS_FUCHSIA',
            ],
            'cflags': [
              '--sysroot=<(fuchsia_sysroot)',
              '-I<(fuchsia_include)',
              '-fno-threadsafe-statics',
            ],
            'ldflags': [
              'x64', '>(_type)', 'target',
              '-nostdlib',
              '-T<(fuchsia_sysroot)/usr/user.ld',
              '-L<(fuchsia_lib)',
              '-Wl,-z,noexecstack',
              '-Wl,-z,now',
              '-Wl,-z,relro',
              '<(fuchsia_lib)/crt1.o',
              '<(fuchsia_lib)/crti.o',
            ],
            'ldflags!': [
              '-pthread',
            ],
          }],
          ['_toolset=="host"', {
            'cflags': [ '-pthread' ],
            'ldflags': [ '-pthread' ],
          }],
        ],
      },
      'Dart_Fuchsia_arm64_Base': {
        'abstract': 1,
        'variables': {
          'fuchsia_sysroot': '<(fuchsia_tools)/sysroot/arm64',
          'fuchsia_include': '<(fuchsia_sysroot)/usr/include',
          'fuchsia_lib': '<(fuchsia_sysroot)/usr/lib',
        },
        'target_conditions': [
          ['_toolset=="target"', {
            'defines': [
              'TARGET_OS_FUCHSIA',
            ],
            'cflags': [
              '--sysroot=<(fuchsia_sysroot)',
              '-I<(fuchsia_include)',
              '-fno-threadsafe-statics',
            ],
            'ldflags': [
              'arm64', '>(_type)', 'target',
              '-nostdlib',
              '-L<(fuchsia_lib)',
              '-Wl,-z,noexecstack',
              '-Wl,-z,now',
              '-Wl,-z,relro',
            ],
            'ldflags!': [
              '-pthread',
            ],
          }],
          ['_toolset=="host"', {
            'cflags': [ '-pthread' ],
            'ldflags': [ '-pthread' ],
          }],
        ],
      },  # Dart_Fuchsia_arm64_Base
    },  # configurations
  },  # target_defaults
}
