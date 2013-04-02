# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  # TODO(gram) : figure out how to make this be autoconfigured. 
  # I've tried a bunch of things with no success yet.
  'variables': {
    'skia_build_flag' : '--release',
    'skia_libs_location_android': '-Lthird_party/skia/trunk/out/config/android-x86/Release/obj.target/gyp', 
    'skia_libs_location_desktop': '-Lthird_party/skia/trunk/out/Release', 
  },
  'conditions': [
    ['OS=="android"',
      {
        'targets': [
          {
            # Dart shared library for Android.
            'target_name': 'android_embedder',
            'type': 'shared_library',
            'dependencies': [
              'skia-android',
              'libdart_lib_withcore',
              'libdart_vm',
              'libjscre',
              'libdouble_conversion',
              'generate_version_cc_file',
            ],
            'include_dirs': [
              '../..',
              '../../../third_party/android_tools/ndk/sources/android/native_app_glue',
              '../../../third_party/skia/trunk/include',
              '../../../third_party/skia/trunk/include/config',
              '../../../third_party/skia/trunk/include/core',
              '../../../third_party/skia/trunk/include/gpu',
              '../../../third_party/skia/trunk/include/lazy',
              '../../../third_party/skia/trunk/include/utils',
            ],
            'defines': [
              'DART_SHARED_LIB',
              '__ANDROID__',
              'SK_BUILD_FOR_ANDROID',
              'SK_BUILD_FOR_ANDROID_NDK',
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
              'common/canvas_context.cc',
              'common/canvas_context.h',
              'common/canvas_state.cc',
              'common/canvas_state.h',
              'common/context.h',
              'common/dart_host.cc',
              'common/dart_host.h',
              'common/events.h',
              'common/extension.cc',
              'common/extension.h',
              'common/graphics_handler.cc',
              'common/graphics_handler.h',
              'common/image_cache.cc',
              'common/image_cache.h',
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
              'common/support.h',
              'common/timer.cc',
              'common/timer.h',
              'common/types.h',
              'common/vm_glue.cc',
              'common/vm_glue.h',
              '<(version_cc_file)',
            ],
            'link_settings': {
              'ldflags': [
                # The libraries we need should all be in
                # Lthird_party/skia/trunk/out/config/android-x86/Debug but
                # As I (gram) want to avoid patching the Skia gyp files to build
                # real libraries we'll just point to the location of the 'thin'
                # libraries used by the Skia build for now.
                # TODO(gram): We need to support debug vs release modes.
                '<(skia_libs_location_android)',
                '-z',
                'muldefs',
              ],
              'ldflags!': [
                '-Wl,--exclude-libs=ALL,-shared',
              ],
              'libraries': [
                '-Wl,--start-group',
                '-lexpat',
                '-lfreetype',
                '-lgif',
                '-ljpeg',
                '-lpng',
                '-lskia_core',
                '-lskia_effects',
                '-lskia_gr',
                '-lskia_images',
                '-lskia_opts',
                '-lskia_pdf',
                '-lskia_ports',
                '-lskia_sfnt',
                '-lskia_skgr',
                '-lskia_utils',
                '-lskia_views',
                '-lskia_xml',
                '-lzlib',
                '-Wl,--end-group',
                '-llog',
                '-lc',
                '-lz',
                '-landroid',
                '-lEGL',
                '-lGLESv2',
                '-lOpenSLES',
                '-landroid',
              ],
            },
          },
          {
            'target_name': 'skia-android',
            'type': 'none',
            'actions': [
              {
                'action_name': 'build_skia',
                'inputs': [
                  'build_skia.sh'
                ],
                'outputs': [
                  'dummy' # To force re-execution every time.
                ],
                # For now we drive the build from a shell
                # script, to get us going. Eventually we will
                # want to either fork Skia or incorporate its 
                # gclient settings into ours, and include its 
                # gyp files within ours, so that it gets built
                # as part of our tree.
                'action': [
                  'embedders/openglui/build_skia.sh',
                  '--android',
                  '<(skia_build_flag)',
                  '..'
                ],
                'message': 'Building Skia.'
              }
            ]
          }
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
              'skia-desktop',
              'libdart_lib_withcore',
              'libdart_vm',
              'libjscre',
              'libdouble_conversion',
              'generate_version_cc_file',
            ],
            'include_dirs': [
              '../..',
              '/usr/X11/include',
              '../../../third_party/skia/trunk/include',
              '../../../third_party/skia/trunk/include/config',
              '../../../third_party/skia/trunk/include/core',
              '../../../third_party/skia/trunk/include/gpu',
              '../../../third_party/skia/trunk/include/lazy',
              '../../../third_party/skia/trunk/include/utils',
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
              'common/canvas_context.cc',
              'common/canvas_context.h',
              'common/canvas_state.cc',
              'common/canvas_state.h',
              'common/context.h',
              'common/dart_host.cc',
              'common/dart_host.h',
              'common/events.h',
              'common/extension.cc',
              'common/extension.h',
              'common/graphics_handler.cc',
              'common/graphics_handler.h',
              'common/image_cache.cc',
              'common/image_cache.h',
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
              'common/support.h',
              'common/support.h',
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
            'link_settings': {
              'ldflags': [
                '-Wall',
                '<(skia_libs_location_desktop)',
                '-Wl,--start-group',
                '-lskia_core',
                '-lskia_effects',
                '-lskia_gr',
                '-lskia_images',
                '-lskia_opts',
                '-lskia_opts_ssse3',
                '-lskia_ports',
                '-lskia_sfnt',
                '-lskia_skgr',
                '-lskia_utils',
                '-Wl,--end-group',
                '-lfreetype',
              ],
              'libraries': [
                '-lGL',
                '-lglut',
                '-lGLU',
                '-lm'
              ],
            },
            'conditions': [
              ['OS=="mac"', {
                'xcode_settings' : {
                  'OTHER_LDFLAGS': [ '-framework OpenGL', '-framework GLUT', '-L /usr/X11/lib' ]
                },
              }],
            ]
          },
          {
            'target_name': 'skia-desktop',
            'type': 'none',
            'actions': [
              {
                'action_name': 'build_skia',
                'inputs': [
                  'build_skia.sh'
                ],
                'outputs': [
                  'dummy' # To force re-execution every time.
                ],
                'action': [
                  'embedders/openglui/build_skia.sh',
                  '<(skia_build_flag)',
                  '..'
                ],
                'message': 'Building Skia.'
              }
            ]
          }
        ],
      },
    ],
  ],
}

