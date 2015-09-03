# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_debug_optimization_level%': '2',
  },
  'target_defaults': {
    'configurations': {
      'Dart_OpenBSD_Base': {
        'abstract': 1,
        'defines': [
          '_FORTIFY_SOURCE=2',
        ],
        'cflags': [
          '-Werror',
          '<@(common_gcc_warning_flags)',
          '-Wnon-virtual-dtor',
          '-Wvla',
          '-Wno-conversion-null',
          '-Woverloaded-virtual',
          '-g3',
          '-ggdb3',
          # TODO(iposva): Figure out if we need to pass anything else.
          #'-ansi',
          '-fno-rtti',
          '-fno-exceptions',
          # '-fvisibility=hidden',
          # '-fvisibility-inlines-hidden',
          '-fstack-protector',
        ],
        'ldflags': [
          '-Wa,--noexecstack',
          '-Wl,-z,now',
          '-Wl,-z,relro',
        ],
      },

      'Dart_OpenBSD_ia32_Base': {
        'abstract': 1,
        'cflags': [ '-m32', '-msse2', '-mfpmath=sse' ],
        'ldflags': [ '-m32', ],
        'conditions': [
          ['c_frame_pointers==1', {
            'cflags': [
              # Clang on Linux will still omit frame pointers from leaf
              # functions unless told otherwise:
              # (note this flag only works on recent GCC versions.)
              '-mno-omit-leaf-frame-pointer',
            ],
          }],
        ],
      },

      'Dart_OpenBSD_x64_Base': {
        'abstract': 1,
        'cflags': [ '-m64', '-msse2' ],
        'ldflags': [ '-m64', ],
        'conditions': [
          ['c_frame_pointers==1', {
            'cflags': [
              # Clang on Linux will still omit frame pointers from leaf
              # functions unless told otherwise:
              # (note this flag only works on recent GCC versions.)
              '-mno-omit-leaf-frame-pointer',
            ],
          }],
        ],
      },

      'Dart_OpenBSD_simarm_Base': {
        'abstract': 1,
        'cflags': [ '-O3', '-m32', '-msse2' ],
        'ldflags': [ '-m32', ],
      },

      'Dart_OpenBSD_simarmv5te_Base': {
        'abstract': 1,
        'cflags': [ '-O3', '-m32', '-msse2' ],
        'ldflags': [ '-m32', ],
      },

      'Dart_OpenBSD_simarm64_Base': {
        'abstract': 1,
        'cflags': [ '-O3', '-m64', '-msse2' ],
        'ldflags': [ '-m64', ],
      },

      # ARM cross-build
      'Dart_OpenBSD_xarm_Base': {
        'abstract': 1,
        'target_conditions': [
        ['_toolset=="target"', {
          'cflags': [
            '-marm',
            '-mfpu=vfp',
            '-Wno-psabi', # suppresses va_list warning
            '-fno-strict-overflow',
          ],
        }],
        ['_toolset=="host"', {
          'cflags': ['-m32', '-msse2'],
          'ldflags': ['-m32'],
        }]]
      },

      # ARM native build
      'Dart_OpenBSD_arm_Base': {
        'abstract': 1,
        'cflags': [
          '-marm',
          '-mfpu=vfp',
          '-Wno-psabi', # suppresses va_list warning
          '-fno-strict-overflow',
        ],
      },

      # ARMv5 cross-build
      'Dart_OpenBSD_xarmv5te_Base': {
        'abstract': 1,
        'target_conditions': [
        ['_toolset=="target"', {
          'cflags': [
            '-mthumb',
            '-mlong-calls',
            '-march=armv5te',
            '-mfloat-abi=soft',
            '-Wno-psabi', # suppresses va_list warning
            '-fno-strict-overflow',
          ],
        }],
        ['_toolset=="host"', {
          'cflags': ['-m32', '-msse2'],
          'ldflags': ['-m32'],
        }]]
      },

      # ARMv5 native build
      'Dart_OpenBSD_armv5te_Base': {
        'abstract': 1,
        'cflags': [
          '-mthumb',
          '-mlong-calls',
          '-march=armv5te',
          '-mfloat-abi=soft',
          '-Wno-psabi', # suppresses va_list warning
          '-fno-strict-overflow',
        ],
      },

      # ARM64 cross-build
      'Dart_OpenBSD_xarm64_Base': {
        'abstract': 1,
        'target_conditions': [
        ['_toolset=="target"', {
          'cflags': [ '-O3', ],
        }],
        ['_toolset=="host"', {
          'cflags': ['-O3', '-m64', '-msse2'],
          'ldflags': ['-m64'],
        }]]
      },

      # ARM64 native build
      'Dart_OpenBSD_arm64_Base': {
        'abstract': 1,
        'cflags': [ '-O3', ],
      },

      'Dart_OpenBSD_simmips_Base': {
        'abstract': 1,
        'cflags': [ '-O3', '-m32', '-msse2' ],
        'ldflags': [ '-m32', ],
      },

      # MIPS cross-build
      'Dart_OpenBSD_xmips_Base': {
        'abstract': 1,
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '-EL',
              '-march=mips32',
              '-mhard-float',
              '-fno-strict-overflow',
            ],
            'ldflags': [
              '-EL',
            ],
          }],
          ['_toolset=="host"',{
            'cflags': [ '-O3', '-m32', '-msse2' ],
            'ldflags': [ '-m32' ],
        }]]
      },

      # MIPS native build
      'Dart_OpenBSD_mips_Base': {
        'abstract': 1,
        'cflags': [
          '-march=mips32',
          '-mhard-float',
          '-fno-strict-overflow',
        ],
      },

      'Dart_OpenBSD_Debug': {
        'abstract': 1,
        'conditions': [
          ['c_frame_pointers==1', {
            'cflags': [
              '-fno-omit-frame-pointer',
            ],
            'defines': [
              'NATIVE_CODE_HAS_FRAME_POINTERS'
            ],
          }],
        ],
        'cflags': [
          '-O<(dart_debug_optimization_level)',
        ],
      },

      'Dart_OpenBSD_Release': {
        'abstract': 1,
        'conditions': [
          ['c_frame_pointers==1', {
            'cflags': [
              '-fno-omit-frame-pointer',
            ],
            'defines': [
              'NATIVE_CODE_HAS_FRAME_POINTERS'
            ],
          }],
        ],
        'cflags': [
          '-O3',
        ],
      },
    },
  },
}
