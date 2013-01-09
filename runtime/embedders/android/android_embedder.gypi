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
              '../..',
              '../../../third_party/android_tools/ndk/sources/android/native_app_glue',
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
              'activity_handler.h',
              'android_extension.cc',
              'android_extension.h',
              'context.h',
              'dart_host.cc',
              'dart_host.h',
              'eventloop.cc',
              'eventloop.h',
              'graphics.cc',
              'graphics.h',
              'input_handler.h',
              'input_service.cc',
              'input_service.h',
              'log.h',
              'main.cc',
              'resource.h',
              'sound_service.cc',
              'sound_service.h',
              'support_android.cc',
              'timer.cc',
              'timer.h',
              'types.h',
              'vm_glue.cc',
              'vm_glue.h',
              '<(version_cc_file)',
            ],
            'link_settings': {
              'libraries': [ '-llog', '-lc', '-landroid', '-lEGL', '-lGLESv2', '-lOpenSLES' ],
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

