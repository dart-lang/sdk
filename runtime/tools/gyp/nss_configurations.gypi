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
    # Include the built-in set of root certificate authorities.
    'exclude_nss_root_certs': 0,
    'os_posix%': 1,
    'os_bsd%': 0,
    'chromeos%': 0,
    'clang%': 0,
  },
  'target_defaults': {
    'cflags': [
      '-w',
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
          'WARNING_CFLAGS': [
            '-w',
          ],
          'WARNING_CFLAGS!': [
            '-Wall',
            '-Wextra',
          ],
        },
      },
      # Dart_Macos_Debug and Dart_Macos_Release are merged after
      # Dart_Macos_Base, so we can override the 'ansi' and '-Werror' flags set
      # at the global level in tools/gyp/configurations_xcode.gypi.
      'Dart_Macos_Debug': {
        'abstract': 1,
        'xcode_settings': {
          # Remove 'ansi' setting.
          'GCC_C_LANGUAGE_STANDARD': 'c99',
          'GCC_TREAT_WARNINGS_AS_ERRORS': 'NO', # -Werror off
        },
      },
      'Dart_Macos_Release': {
        'abstract': 1,
        'xcode_settings': {
          # Remove 'ansi' setting.
          'GCC_C_LANGUAGE_STANDARD': 'c99',
          'GCC_TREAT_WARNINGS_AS_ERRORS': 'NO', # -Werror off
        },
      },
      # When being built for Android nss expects __linux__ to be defined.
      'Dart_Android_Base': {
        'target_conditions': [
          ['_toolset=="host"', {
            'defines!': [
              'ANDROID',
            ],
            # Define __linux__ on Android build for NSS.
            'defines': [
              '__linux__',
            ],
            'cflags!': [
              '-U__linux__',
            ],
          }],
          ['_toolset=="target"', {
            'defines': [
              '__linux__',
              'CHECK_FORK_GETPID',  # Android does not provide pthread_atfork.
              '__USE_LARGEFILE64',
            ],
            # Define __linux__ on Android build for NSS.
            'cflags!': [
              '-U__linux__',
            ],
          }]
        ],
      },
    },
  },
}
