# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Definitions for building standalone Dart binaries to run on Android.
# This is mostly excerpted from:
# http://src.chromium.org/viewvc/chrome/trunk/src/build/common.gypi

{
  'variables': {
    'android_ndk_root': '<(PRODUCT_DIR)/../../third_party/android_tools/ndk',
  },  # variables
  'target_defaults': {
    'configurations': {
      # It is very important to get the order of the linker arguments correct.
      # Therefore, we put them all in the architecture specific configurations,
      # even though there are many flags in common, to avoid splitting them
      # between two configurations and possibly accidentally mixing up the
      # order.
      'Dart_Android_Base': {
        'abstract': 1,
        'cflags': [ '-Wno-abi', '-Wall', '-W', '-Wno-unused-parameter',
                    '-Wnon-virtual-dtor', '-fno-rtti', '-fno-exceptions',],
        'target_conditions': [
          ['_toolset=="target"', {
            'defines': [
              'ANDROID',
              'USE_STLPORT=1',
              '__GNU_SOURCE=1',
              '_STLP_USE_PTR_SPECIALIZATIONS=1',
              'HAVE_OFF64_T',
              'HAVE_SYS_UIO_H',
            ],
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
            ],
          }],
        ],
      },
      'Dart_Android_Debug': {
        'abstract': 1,
        'defines': [
          'DEBUG',
        ],
        'conditions': [
          ['c_frame_pointers==1', {
            'cflags': [
              '-fno-omit-frame-pointer',
            ],
            'defines': [
              'PROFILE_NATIVE_CODE'
            ],
          }],
        ],
      },
      'Dart_Android_Release': {
        'abstract': 1,
        'defines': [
          'NDEBUG',
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
        'conditions': [
          ['c_frame_pointers==1', {
            'cflags': [
              '-fno-omit-frame-pointer',
            ],
            'defines': [
              'PROFILE_NATIVE_CODE'
            ],
          }],
        ],
      },
      'Dart_Android_ia32_Base': {
        'abstract': 1,
        'variables': {
          'android_sysroot': '<(android_ndk_root)/platforms/android-14/arch-x86',
          'android_ndk_include': '<(android_sysroot)/usr/include',
          'android_ndk_lib': '<(android_sysroot)/usr/lib',
        },
        'target_conditions': [
          ['_toolset=="target"', {
            # The x86 toolchain currently has problems with stack-protector.
            'cflags!': [
              '-fstack-protector',
            ],
            'cflags': [
              '--sysroot=<(android_sysroot)',
              '-I<(android_ndk_include)',
              '-I<(android_ndk_root)/sources/cxx-stl/stlport/stlport',
              '-fno-stack-protector',
            ],
            'target_conditions': [
              ['_type=="executable"', {
                'ldflags!': ['-Wl,--exclude-libs=ALL,-shared',],
              }],
              ['_type=="shared_library"', {
                'ldflags': ['-Wl,-shared,-Bsymbolic',],
              }],
            ],
            'ldflags': [
              'ia32', '>(_type)', 'target',
              '-nostdlib',
              '-Wl,--no-undefined',
              # Don't export symbols from statically linked libraries.
              '-Wl,--exclude-libs=ALL',
              '-Wl,-rpath-link=<(android_ndk_lib)',
              '-L<(android_ndk_lib)',
              # NOTE: The stlport header include paths below are specified in
              # cflags rather than include_dirs because they need to come
              # after include_dirs. Think of them like system headers, but
              # don't use '-isystem' because the arm-linux-androideabi-4.4.3
              # toolchain (circa Gingerbread) will exhibit strange errors.
              # The include ordering here is important; change with caution.
              '-L<(android_ndk_root)/sources/cxx-stl/stlport/libs/x86',
              '-z',
              'muldefs',
              '-Bdynamic',
              '-Wl,-dynamic-linker,/system/bin/linker',
              '-Wl,--gc-sections',
              '-Wl,-z,nocopyreloc',
              # crtbegin_dynamic.o should be the last item in ldflags.
              '<(android_ndk_lib)/crtbegin_dynamic.o',
            ],
            'ldflags!': [
              '-pthread',  # Not supported by Android toolchain.
            ],
          }],
          ['_toolset=="host"', {
            'cflags': [ '-m32', '-pthread' ],
            'ldflags': [ '-m32', '-pthread' ],
          }],
        ],
      },
      'Dart_Android_arm_Base': {
        'abstract': 1,
        'variables': {
          'android_sysroot': '<(android_ndk_root)/platforms/android-14/arch-arm',
          'android_ndk_include': '<(android_sysroot)/usr/include',
          'android_ndk_lib': '<(android_sysroot)/usr/lib',
        },
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '--sysroot=<(android_sysroot)',
              '-I<(android_ndk_include)',
              '-I<(android_ndk_root)/sources/cxx-stl/stlport/stlport',
              '-march=armv7-a',
              '-mtune=cortex-a8',
              '-mfpu=vfp3',
              '-mfloat-abi=softfp',
            ],
            'target_conditions': [
              ['_type=="executable"', {
                'ldflags!': ['-Wl,--exclude-libs=ALL,-shared',],
              }],
              ['_type=="shared_library"', {
                'ldflags': ['-Wl,-shared,-Bsymbolic',],
              }],
            ],
            'ldflags': [
              'arm', '>(_type)', 'target',
              '-nostdlib',
              '-Wl,--no-undefined',
              # Don't export symbols from statically linked libraries.
              '-Wl,--exclude-libs=ALL',
              '-Wl,-rpath-link=<(android_ndk_lib)',
              '-L<(android_ndk_lib)',
              # Enable identical code folding to reduce size.
              '-Wl,--icf=safe',
              '-L<(android_ndk_root)/sources/cxx-stl/stlport/libs/armeabi-v7a',
              '-z',
              'muldefs',
              '-Bdynamic',
              '-Wl,-dynamic-linker,/system/bin/linker',
              '-Wl,--gc-sections',
              '-Wl,-z,nocopyreloc',
              # crtbegin_dynamic.o should be the last item in ldflags.
              '<(android_ndk_lib)/crtbegin_dynamic.o',
            ],
            'ldflags!': [
              '-pthread',  # Not supported by Android toolchain.
            ],
          }],
          ['_toolset=="host"', {
            'cflags': [ '-m32', '-pthread' ],
            'ldflags': [ '-m32', '-pthread' ],
          }],
        ],
      },  # Dart_Android_arm_Base
      'Dart_Android_arm64_Base': {
        'abstract': 1,
        'variables': {
          'android_sysroot': '<(android_ndk_root)/platforms/android-L/arch-arm64',
          'android_ndk_include': '<(android_sysroot)/usr/include',
          'android_ndk_lib': '<(android_sysroot)/usr/lib',
        },
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '-fPIE',
              '--sysroot=<(android_sysroot)',
              '-I<(android_ndk_include)',
              '-I<(android_ndk_root)/sources/cxx-stl/stlport/stlport',
            ],
            'target_conditions': [
              ['_type=="executable"', {
                'ldflags!': ['-Wl,--exclude-libs=ALL,-shared',],
              }],
              ['_type=="shared_library"', {
                'ldflags': ['-Wl,-shared,-Bsymbolic',],
              }],
            ],
            'ldflags': [
              'arm64', '>(_type)', 'target',
              '-nostdlib',
              '-Wl,--no-undefined',
              # Don't export symbols from statically linked libraries.
              '-Wl,--exclude-libs=ALL',
              '-Wl,-rpath-link=<(android_ndk_lib)',
              '-L<(android_ndk_lib)',
              '-L<(android_ndk_root)/sources/cxx-stl/stlport/libs/arm64-v8a',
              '-z',
              'muldefs',
              '-Bdynamic',
              '-pie',
              '-Wl,-dynamic-linker,/system/bin/linker64',
              '-Wl,--gc-sections',
              '-Wl,-z,nocopyreloc',
              # crtbegin_dynamic.o should be the last item in ldflags.
              '<(android_ndk_lib)/crtbegin_dynamic.o',
            ],
            'ldflags!': [
              '-pthread',  # Not supported by Android toolchain.
            ],
          }],
          ['_toolset=="host"', {
            'ldflags': [ '-pthread' ],
          }],
        ],
      },  # Dart_Android_arm64_Base
    },  # configurations
  },  # target_defaults
}
