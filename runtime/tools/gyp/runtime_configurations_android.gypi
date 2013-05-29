# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Definitions for building Chrome with Dart on Android.
# This is mostly excerpted from:
# http://src.chromium.org/viewvc/chrome/trunk/src/build/common.gypi

{
  'variables': {
    'dart_io_support': 0,
  },
  'target_defaults': {
    'cflags': [
      '-Wno-abi',
      '-Wall',
      '-W',
      '-Wno-unused-parameter',
      '-Wnon-virtual-dtor',
      '-fno-rtti',
      '-fno-exceptions',
    ],
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
      }],  # _toolset=="target"
    ],  # target_conditions
  },  # target_defaults
}
