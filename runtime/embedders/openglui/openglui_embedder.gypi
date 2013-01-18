# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
              'DART_SHARED_LIB',
              '__ANDROID__'
            ],
            'sources': [
              '../../include/dart_api.h',
              '../../include/dart_debugger_api.h',
              '../../vm/dart_api_impl.cc',
              '../../vm/debugger_api_impl.cc',
              '../../vm/version.h',
              '../../../third_party/android_tools/ndk/sources/android/native_app_glue/android_native_app_glue.h',
              '../../../third_party/android_tools/ndk/sources/android/native_app_glue/android_native_app_glue.c',
              'android/android_graphics_handler.cc',
              'android/android_graphics_handler.h',
              'android/android_input_handler.h',
              'android/android_resource.h',
              'android/android_sound_handler.cc',
              'android/android_sound_handler.h',
              'android/eventloop.cc',
              'android/eventloop.h',
              'android/log.h',
              'android/main.cc',
              'android/support_android.cc',
              'common/context.h',
              'common/dart_host.cc',
              'common/dart_host.h',
              'common/events.h',
              'common/extension.cc',
              'common/extension.h',
              'common/gl_graphics_handler.cc',
              'common/gl_graphics_handler.h',
              'common/graphics_handler.h',
              'common/input_handler.cc',
              'common/input_handler.h',
              'common/isized.h',
              'common/life_cycle_handler.h',
              'common/log.h',
              'common/opengl.h',
              'common/resource.h',
              'common/sample.h',
              'common/sound_handler.cc',
              'common/sound_handler.h',
              'common/timer.cc',
              'common/timer.h',
              'common/types.h',
              'common/vm_glue.cc',
              'common/vm_glue.h',
              '<(version_cc_file)',
            ],
            'link_settings': {
              'libraries': [ '-llog', '-lc', '-landroid', '-lEGL', '-lGLESv2', '-lOpenSLES', '-landroid' ],
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
    ],
    ['OS=="mac" or OS=="linux"',
      {
        'targets': [
          {
            'target_name': 'emulator_embedder',
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
              'common/context.h',
              'common/dart_host.cc',
              'common/dart_host.h',
              'common/events.h',
              'common/extension.cc',
              'common/extension.h',
              'common/gl_graphics_handler.cc',
              'common/gl_graphics_handler.h',
              'common/graphics_handler.h',
              'common/input_handler.cc',
              'common/input_handler.h',
              'common/isized.h',
              'common/life_cycle_handler.h',
              'common/log.h',
              'common/opengl.h',
              'common/resource.h',
              'common/sample.h',
              'common/sound_handler.cc',
              'common/sound_handler.h',
              'common/timer.cc',
              'common/timer.h',
              'common/types.h',
              'common/vm_glue.cc',
              'common/vm_glue.h',
              'emulator/emulator_embedder.cc',
              'emulator/emulator_embedder.h',
              'emulator/emulator_graphics_handler.cc',
              'emulator/emulator_graphics_handler.h',
              'emulator/emulator_resource.h',
              '<(version_cc_file)',
            ],
            'conditions': [
              ['OS=="mac"', {
                'xcode_settings' : {
                  'OTHER_LDFLAGS': [ '-framework OpenGL', '-framework GLUT', '-L /usr/X11/lib' ]
                },
              }],
            ]
          },
        ],
      },
    ],
  ],
}

