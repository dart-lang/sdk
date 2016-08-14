# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is a modified copy of
# https://chromium.googlesource.com/chromium/src/third_party/zlib/zlib.gyp
# at revision c3d0a6190f2f8c924a05ab6cc97b8f975bddd33f.
{
  # Added by Dart. All Dart comments refer to the following block or line.
  'includes': [
    '../tools/gyp/runtime-configurations.gypi',
    '../tools/gyp/nss_configurations.gypi',
  ],
  'variables': {
    # Added by Dart.
    'zlib_path': '../../third_party/zlib',
  },
  # Added by Dart.  We do not indent, so diffs with the original are clearer.
  'targets': [
    {
      'target_name': 'zlib_dart',  # Added by Dart (the _dart postfix)
      'type': 'static_library',
      # Added by Dart (the original only has this on android).
      'toolsets':['host','target'],
      # Changed by Dart: '<(zlib_directory)/' added to all paths.
      'sources': [
        '<(zlib_path)/adler32.c',
        '<(zlib_path)/compress.c',
        '<(zlib_path)/crc32.c',
        '<(zlib_path)/crc32.h',
        '<(zlib_path)/deflate.c',
        '<(zlib_path)/deflate.h',
        '<(zlib_path)/gzclose.c',
        '<(zlib_path)/gzguts.h',
        '<(zlib_path)/gzlib.c',
        '<(zlib_path)/gzread.c',
        '<(zlib_path)/gzwrite.c',
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
    },
  ],
}
