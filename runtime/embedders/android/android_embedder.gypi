# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'conditions': [
    ['OS=="android"',
      {
        'targets': [
          {
            # Dart shared library for Android.
            'target_name': 'android_embedder',
            'type': 'shared_library',
            'dependencies': [
              'libdart_lib_withcore',
              'libdart_vm',
              'libjscre',
              'libdouble_conversion',
              'generate_version_cc_file',
            ],
            'include_dirs': [
              '../..'
            ],
            'defines': [
              'DART_SHARED_LIB'
            ],
            'sources': [
              '../../include/dart_api.h',
              '../../include/dart_debugger_api.h',
              '../../vm/dart_api_impl.cc',
              '../../vm/debugger_api_impl.cc',
              '../../vm/version.h',
              'support_android.cc',
              '<(version_cc_file)',
            ],
            'link_settings': {
              'libraries': [ '-llog', '-lc' ],
              'ldflags': [
                '-z', 'muldefs'
              ],
              'ldflags!': [
                '-Wl,--exclude-libs=ALL',
              ],
            },
          },
        ],
      },
    ]
  ],
}

