# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is included to modify the configurations to build third-party
# code from Mozilla's NSS and NSPR libraries, modified by the Chromium project.
# This code is C code, not C++, and is not warning-free, so we need to remove
# C++-specific flags, and add flags to supress the warnings in the code.
# This file is included from gyp files in the runtime/bin/net directory.
{
  'variables': {
    # Used by third_party/nss, which is from Chromium.
    # When the NSS and related libraries gyp files are processed in
    # Dartium, do not override the settings from Dartium.  The targets will
    # not be built.
    'os_posix%': 1,
    'os_bsd%': 0,
    'chromeos%': 0,
    'clang%': 0,
  },
  'target_defaults': {
    'cflags': [
      '-Wno-unused-variable',
      '-Wno-unused-but-set-variable',
      '-Wno-missing-field-initializers',
      '-Wno-uninitialized',
      '-Wno-sign-compare',
      '-Wno-empty-body',
      '-Wno-type-limits',
      '-Wno-pointer-to-int-cast',
      '-UHAVE_CVAR_BUILT_ON_SEM',
    ],
    # Removes these flags from the list cflags.
    'cflags!': [
      # NSS code from upstream mozilla builds with warnings,
      # so we must allow warnings without failing.
      '-Werror',
      '-Wall',
      '-ansi',
      # Not supported for C, only for C++.
      '-Wnon-virtual-dtor',
      '-Wno-conversion-null',
      '-fno-rtti',
      '-fvisibility-inlines-hidden',
      '-Woverloaded-virtual',
    ],
    'configurations': {
      'Dart_Base': {
        'xcode_settings': {
          'WARNING_CFLAGS!': [
            '-Wall',
            '-Wextra',
          ],
        },
      },
      # Dart_Debug and Dart_Release are merged after Dart_Base, so we can
      # override the 'ansi' and '-Werror' flags set at the global level in
      # tools/gyp/configurations_xcode.gypi.
      'Dart_Debug': {
        'xcode_settings': {
          # Remove 'ansi' setting.
          'GCC_C_LANGUAGE_STANDARD': 'c99',
          'GCC_TREAT_WARNINGS_AS_ERRORS': 'NO', # -Werror off
        },
      },
      'Dart_Release': {
        'xcode_settings': {
          # Remove 'ansi' setting.
          'GCC_C_LANGUAGE_STANDARD': 'c99',
          'GCC_TREAT_WARNINGS_AS_ERRORS': 'NO', # -Werror off
        },
      },
    },
  },
}
