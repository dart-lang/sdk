# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'arm_cross_libc%': '/opt/codesourcery/arm-2009q1/arm-none-linux-gnueabi/libc',
    'dart_debug_optimization_level%': '2',
  },
  'target_defaults': {
    'configurations': {
      'Dart_Base': {
        'cflags': [
          '-Werror',
          '<@(common_gcc_warning_flags)',
          '-Wnon-virtual-dtor',
          '-Wvla',
          '-Wno-conversion-null',
          # TODO(v8-team): Fix V8 build.
          #'-Woverloaded-virtual',
          '-g3',
          '-ggdb3',
          # TODO(iposva): Figure out if we need to pass anything else.
          #'-ansi',
          '-fno-rtti',
          '-fno-exceptions',
          '-fPIC',
          '-fvisibility=hidden',
          '-fvisibility-inlines-hidden',
        ],
        'ldflags': [
          '-rdynamic',
          '-Wl,-rpath,<(PRODUCT_DIR)/lib.target',
        ],
      },

      'Dart_ia32_Base': {
        'cflags': [ '-m32', ],
        'ldflags': [ '-m32', ],
      },

      'Dart_x64_Base': {
        'cflags': [ '-m64', ],
        'ldflags': [ '-m64', ],
      },

      'Dart_simarm_Base': {
        'cflags': [ '-O3', '-m32', ],
        'ldflags': [ '-m32', ],
      },

      'Dart_arm_Base': {
        'cflags': [
          '-march=armv7-a',
          '-mfpu=vfp',
          '-mfloat-abi=softfp',
          '-fno-strict-overflow',
        ],
        'ldflags': [
          '-Wl,-rpath=<(arm_cross_libc)/usr/lib',
        ],
      },

      'Dart_Debug': {
        'cflags': [ '-O<(dart_debug_optimization_level)' ],
      },

      'Dart_Release': {
        'cflags': [ '-O3', ],
      },
    },
  },
}
