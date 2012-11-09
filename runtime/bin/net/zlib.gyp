# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is a modified copy of src/third_party/zlib/zlib.gyp from Chromium.
# Revision 165464 (this should agree with "nss_rev" in DEPS).
{
  # Added by Dart. All Dart comments refer to the following block or line.
  'includes': [
    '../../tools/gyp/runtime-configurations.gypi',
    '../../tools/gyp/nss_configurations.gypi',
  ],
  'variables': {
    # Added by Dart.
    'zlib_path': '../../../third_party/zlib',
    'conditions': [
      [ 'OS=="none"', {
        # Because we have a patched zlib, we cannot use the system libz.
        # TODO(pvalchev): OpenBSD is purposefully left out, as the system
        # zlib brings up an incompatibility that breaks rendering.
        'use_system_zlib%': 1,
      }, {
        'use_system_zlib%': 0,
      }],
    ],
    'use_system_minizip%': 0,
  },
  # Added by Dart.  We do not indent, so diffs with the original are clearer.
  'conditions': [[ 'in_dartium==0', {
  'targets': [
    {
      'target_name': 'zlib_dart',
      'type': 'static_library',
      'conditions': [
        ['use_system_zlib==0', {
          # Changed by Dart: '<(zlib_directory)/' added to all paths.
          'sources': [
            '<(zlib_path)/adler32.c',
            '<(zlib_path)/compress.c',
            '<(zlib_path)/crc32.c',
            '<(zlib_path)/crc32.h',
            '<(zlib_path)/deflate.c',
            '<(zlib_path)/deflate.h',
            '<(zlib_path)/gzio.c',
            '<(zlib_path)/infback.c',
            '<(zlib_path)/inffast.c',
            '<(zlib_path)/inffast.h',
            '<(zlib_path)/inffixed.h',
            '<(zlib_path)/inflate.c',
            '<(zlib_path)/inflate.h',
            '<(zlib_path)/inftrees.c',
            '<(zlib_path)/inftrees.h',
            '<(zlib_path)/mozzconf.h',
            '<(zlib_path)/trees.c',
            '<(zlib_path)/trees.h',
            '<(zlib_path)/uncompr.c',
            '<(zlib_path)/zconf.h',
            '<(zlib_path)/zlib.h',
            '<(zlib_path)/zutil.c',
            '<(zlib_path)/zutil.h',
          ],
          'include_dirs': [
            '<(zlib_path)/.',
          ],
          'direct_dependent_settings': {
            'include_dirs': [
              '<(zlib_path)/.',
            ],
          },
          'conditions': [
            ['OS!="win"', {
              'product_name': 'chrome_zlib',
            }], ['OS=="android"', {
              'toolsets': ['target', 'host'],
            }],
          ],
        }, {
          'direct_dependent_settings': {
            'defines': [
              'USE_SYSTEM_ZLIB',
            ],
          },
          'defines': [
            'USE_SYSTEM_ZLIB',
          ],
          'link_settings': {
            'libraries': [
              '-lz',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'minizip_dart',
      'type': 'static_library',
      'conditions': [
        ['use_system_minizip==0', {
          'sources': [
            '<(zlib_path)/contrib/minizip/ioapi.c',
            '<(zlib_path)/contrib/minizip/ioapi.h',
            '<(zlib_path)/contrib/minizip/iowin32.c',
            '<(zlib_path)/contrib/minizip/iowin32.h',
            '<(zlib_path)/contrib/minizip/unzip.c',
            '<(zlib_path)/contrib/minizip/unzip.h',
            '<(zlib_path)/contrib/minizip/zip.c',
            '<(zlib_path)/contrib/minizip/zip.h',
          ],
          'include_dirs': [
            '<(zlib_path)/.',
            '<(zlib_path)/../..',
          ],
          'direct_dependent_settings': {
            'include_dirs': [
              '<(zlib_path)/.',
            ],
          },
          'conditions': [
            ['OS!="win"', {
              'sources!': [
                '<(zlib_path)/contrib/minizip/iowin32.c'
              ],
            }],
            ['OS=="android"', {
              'toolsets': ['target', 'host'],
            }],
          ],
        }, {
          'direct_dependent_settings': {
            'defines': [
              'USE_SYSTEM_MINIZIP',
            ],
          },
          'defines': [
            'USE_SYSTEM_MINIZIP',
          ],
          'link_settings': {
            'libraries': [
              '-lminizip',
            ],
          },
        }],
        ['OS=="mac" or OS=="ios" or os_bsd==1 or OS=="android"', {
          # Mac, Android and the BSDs don't have fopen64, ftello64, or
          # fseeko64. We use fopen, ftell, and fseek instead on these
          # systems.
          'defines': [
            'USE_FILE32API'
          ],
        }],
        ['clang==1', {
          'xcode_settings': {
            'WARNING_CFLAGS': [
              # zlib uses `if ((a == b))` for some reason.
              '-Wno-parentheses-equality',
            ],
          },
          'cflags': [
            '-Wno-parentheses-equality',
          ],
        }],
      ],
    }
  ],
  }]],
}
