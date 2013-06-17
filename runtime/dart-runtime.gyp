# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'tools/gyp/runtime-configurations.gypi',
    'vm/vm.gypi',
    'bin/bin.gypi',
    'third_party/double-conversion/src/double-conversion.gypi',
    'third_party/jscre/jscre.gypi',
  ],
  'variables': {
    # TODO(zra): LIB_DIR is not defined by the ninja generator on Windows.
    # Also, LIB_DIR is not toolset specific on Mac. If we want to do a ninja
    # build on Windows, or cross-compile on Mac, we'll have to find some other
    # way of getting generated source files into toolset specific locations.
    'gen_source_dir': '<(LIB_DIR)',
    'version_in_cc_file': 'vm/version_in.cc',
    'version_cc_file': '<(gen_source_dir)/version.cc',

    # Disable the OpenGLUI embedder by default on desktop OSes.  Note,
    # to build this on the desktop, you need GLUT installed.
    'enable_openglui%': 0,
    'libdart_deps': ['libdart_lib_withcore', 'libdart_lib', 'libdart_vm',
                     'libjscre', 'libdouble_conversion',],
  },
  'conditions': [
    ['OS=="android" or enable_openglui==1', {
        'includes': [
          'embedders/openglui/openglui_embedder.gypi',
        ],
      },
    ],
  ],
  'targets': [
    {
      'target_name': 'libdart',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdouble_conversion',
        'generate_version_cc_file',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_debugger_api.h',
        'include/dart_mirrors_api.h',
        'include/dart_native_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
        'vm/mirrors_api_impl.cc',
        'vm/native_api_impl.cc',
        'vm/version.h',
        '<(version_cc_file)',
      ],
      'defines': [
        # The only effect of DART_SHARED_LIB is to export the Dart API entries.
        'DART_SHARED_LIB',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'include',
        ],
      },
    },
    {
      'target_name': 'generate_version_cc_file',
      'type': 'none',
      'toolsets':['target','host'],
      'dependencies': [
        'libdart_dependency_helper.target#target',
        'libdart_dependency_helper.host#host',
      ],
      'actions': [
        {
          'action_name': 'generate_version_cc',
          'inputs': [
            '../tools/make_version.py',
            '../tools/utils.py',
            '../tools/version.dart',
            '../tools/release/version.dart',
            '../tools/VERSION',
            '<(version_in_cc_file)',
            # Depend on libdart_dependency_helper to track the libraries it
            # depends on.
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)libdart_dependency_helper.target<(EXECUTABLE_SUFFIX)',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)libdart_dependency_helper.host<(EXECUTABLE_SUFFIX)',
          ],
          'outputs': [
            '<(version_cc_file)',
          ],
          'action': [
            'python',
            '-u', # Make standard I/O unbuffered.
            '../tools/make_version.py',
            '--output', '<(version_cc_file)',
            '--input', '<(version_in_cc_file)',
          ],
        },
      ],
    },
    {
      'target_name': 'libdart_dependency_helper.target',
      'type': 'executable',
      'toolsets':['target'],
      # The dependencies here are the union of the dependencies of libdart and
      # libdart_withcore.
      'dependencies': ['<@(libdart_deps)'],
      'sources': [
        'vm/libdart_dependency_helper.cc',
      ],
    },
    {
      'target_name': 'libdart_dependency_helper.host',
      'type': 'executable',
      'toolsets':['host'],
      # The dependencies here are the union of the dependencies of libdart and
      # libdart_withcore.
      'dependencies': ['<@(libdart_deps)'],
      'sources': [
        'vm/libdart_dependency_helper.cc',
      ],
    },
    {
      'target_name': 'runtime_packages',
      'type': 'none',
      'dependencies': [
        '../pkg/pkg.gyp:pkg_packages',
      ],
    },
  ],
}
