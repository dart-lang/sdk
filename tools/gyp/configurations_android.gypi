# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Definitions for building standalone Dart binaries to run on Android.
# This is mostly excerpted from:
# http://src.chromium.org/viewvc/chrome/trunk/src/build/common.gypi

{
  'variables': {
    # Location of Android NDK.
    'variables': {
      'variables': {
        'android_ndk_root%': '<!(/bin/echo -n $ANDROID_NDK_ROOT)',

        # Switch between different build types, currently only '0' is
        # supported.
        'android_build_type%': 0,
      },
      'android_ndk_root%': '<(android_ndk_root)',
      'android_ndk_sysroot': '<(android_ndk_root)/platforms/android-9/arch-<(android_target_arch)',
      'android_build_type%': '<(android_build_type)',
    },
    'android_ndk_root%': '<(android_ndk_root)',
    'android_ndk_sysroot': '<(android_ndk_sysroot)',
    'android_ndk_include': '<(android_ndk_sysroot)/usr/include',
    'android_ndk_lib': '<(android_ndk_sysroot)/usr/lib',
    # Enable to use the system stlport, otherwise statically
    # link the NDK one?
    'use_system_stlport%': '<(android_build_type)',
    'android_stlport_library': 'stlport_static',
    # Copy it out one scope.
    'android_build_type%': '<(android_build_type)',

    'OS': 'android',
    'android_target_arch' : 'x86',
  },  # variables
  'target_defaults': {
    'defines': [
      'ANDROID',
    ],
    'configurations': {
      'Release': {
        'cflags!': [
          '-O2',
          '-Os',
        ],
        'cflags': [
          '-fdata-sections',
          '-ffunction-sections',
          '-fomit-frame-pointer',
          '-O3',
        ],
      },  # Release
    },  # configurations
    'cflags': [ '-Wno-abi', '-Wall', '-W', '-Wno-unused-parameter',
                '-Wnon-virtual-dtor', '-fno-rtti', '-fno-exceptions', ],
    'target_conditions': [
      ['_toolset=="target"', {
        'cflags!': [
          '-pthread',  # Not supported by Android toolchain.
        ],
        'cflags': [
          '-U__linux__',  # Don't allow toolchain to claim -D__linux__
          '-ffunction-sections',
          '-funwind-tables',
          '-fstack-protector',
          '-fno-short-enums',
          '-finline-limit=64',
          '-Wa,--noexecstack',
          # Note: This include is in cflags to ensure that it comes after
          # all of the includes.
          '-I<(android_ndk_include)',
        ],
        'defines': [
          'ANDROID',
          'USE_STLPORT=1',
          '_STLP_USE_PTR_SPECIALIZATIONS=1',
          '_STLP_NO_CSTD_FUNCTION_IMPORTS=1',
          'HAVE_OFF64_T',
          'HAVE_SYS_UIO_H',
        ],
        'ldflags!': [
          '-pthread',  # Not supported by Android toolchain.
        ],
        'ldflags': [
          '-nostdlib',
          '-Wl,--no-undefined',
          # Don't export symbols from statically linked libraries.
          '-Wl,--exclude-libs=ALL',
        ],
        'libraries!': [
            '-lrt',  # librt is built into Bionic.
            # Not supported by Android toolchain.
            # Where do these come from?  Can't find references in
            # any Chromium gyp or gypi file.  Maybe they come from
            # gyp itself?
            '-lpthread', '-lnss3', '-lnssutil3', '-lsmime3', '-lplds4', '-lplc4', '-lnspr4',
          ],
          'libraries': [
            '-l<(android_stlport_library)',
            # Manually link the libgcc.a that the cross compiler uses.
            # this picks up compiler-dependent math intrinsics.
            '<!(${ANDROID_TOOLCHAIN}/*-gcc -print-libgcc-file-name)',
            '-lc',
            '-ldl',
            '-lstdc++',
            '-lm',
        ],
        'conditions': [
          ['android_build_type==0', {
            'ldflags': [
              '-Wl,-rpath-link=<(android_ndk_lib)',
              '-L<(android_ndk_lib)',
            ],
          }],
          ['target_arch == "arm"', {
            'ldflags': [
              # Enable identical code folding to reduce size.
              '-Wl,--icf=safe',
            ],
          }],
          ['target_arch=="arm" and armv7==1', {
            'cflags': [
              '-march=armv7-a',
              '-mtune=cortex-a8',
              '-mfpu=vfp3',
            ],
          }],
          # NOTE: The stlport header include paths below are specified in
          # cflags rather than include_dirs because they need to come
          # after include_dirs. Think of them like system headers, but
          # don't use '-isystem' because the arm-linux-androideabi-4.4.3
          # toolchain (circa Gingerbread) will exhibit strange errors.
          # The include ordering here is important; change with caution.
          ['use_system_stlport==0', {
            'cflags': [
              '-I<(android_ndk_root)/sources/cxx-stl/stlport/stlport',
            ],
            'conditions': [
              ['target_arch=="arm" and armv7==1', {
                'ldflags': [
                  '-L<(android_ndk_root)/sources/cxx-stl/stlport/libs/armeabi-v7a',
                ],
              }],
              ['target_arch=="arm" and armv7==0', {
                'ldflags': [
                  '-L<(android_ndk_root)/sources/cxx-stl/stlport/libs/armeabi',
                ],
              }],
              ['target_arch=="ia32"', {
                'ldflags': [
                  '-L<(android_ndk_root)/sources/cxx-stl/stlport/libs/x86',
                ],
              }],
            ],
          }],
          ['target_arch=="ia32"', {
            # The x86 toolchain currently has problems with stack-protector.
            'cflags!': [
              '-fstack-protector',
            ],
            'cflags': [
              '-fno-stack-protector',
            ],
          }],
        ],
        'target_conditions': [
          ['_type=="executable"', {
            'ldflags': [
              '-Bdynamic',
              '-Wl,-dynamic-linker,/system/bin/linker',
              '-Wl,--gc-sections',
              '-Wl,-z,nocopyreloc',
              # crtbegin_dynamic.o should be the last item in ldflags.
              '<(android_ndk_lib)/crtbegin_dynamic.o',
            ],
            'libraries': [
              # crtend_android.o needs to be the last item in libraries.
              # Do not add any libraries after this!
              '<(android_ndk_lib)/crtend_android.o',
            ],
          }],
          ['_type=="shared_library"', {
            'ldflags': [
              '-Wl,-shared,-Bsymbolic',
            ],
          }],
        ],
      }],  # _toolset=="target"
      # Settings for building host targets using the system toolchain.
      ['_toolset=="host"', {
        'cflags': [ '-m32', '-pthread' ],
        'ldflags': [ '-m32', '-pthread' ],
        'ldflags!': [
          '-Wl,-z,noexecstack',
          '-Wl,--gc-sections',
          '-Wl,-O1',
          '-Wl,--as-needed',
        ],
      }],
    ],  # target_conditions
  },  # target_defaults
}
