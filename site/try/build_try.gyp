# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE

{
  'variables' : {
    'script_suffix%': '',
  },
  'conditions' : [
    ['OS=="win"', {
      'variables' : {
        'script_suffix': '.bat',
      },
    }],
  ],
  'targets': [
    {
      'target_name': 'try_site',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../create_sdk.gyp:create_sdk_internal',
        '../../pkg/pkg.gyp:pkg_packages',
      ],
      'variables': {
        'try_dart_static_files': [
          'index.html',
          'dartlang-style.css',
          'line_numbers.css',
          'iframe.html',
          'iframe.js',
          'dart-icon.png', # iOS icon.
          'dart-iphone5.png', # iPhone 5 splash screen.
          'dart-icon-196px.png', # Android icon.
          'try-dart-screenshot.png', # Google+ screen shot.
          'favicon.ico',

          '<(SHARED_INTERMEDIATE_DIR)/leap.dart.js',
          '<(SHARED_INTERMEDIATE_DIR)/compiler_isolate.dart.js',
          '<(SHARED_INTERMEDIATE_DIR)/sdk.json',
        ],
        'try_dart_hosted_package_directories': [
          # These packages are uploaded to Try Dart and can be used in code
          # there.
          '../../pkg/analyzer/lib',
          '../../third_party/pkg/collection/lib',
          '../../third_party/pkg/crypto/lib',
          '../../third_party/pkg/args/lib',
          '../../third_party/pkg/http/lib',
          '../../third_party/pkg/http_parser/lib',
          '../../third_party/pkg/intl/lib',
          '../../third_party/pkg/logging/lib',
          '../../third_party/pkg/path/lib',
          '../../third_party/pkg/stack_trace/lib',
          '../../third_party/pkg/string_scanner/lib',
          '../../third_party/pkg/unittest/lib',
          '../../third_party/pkg/yaml/lib',
        ],
      },
      'actions': [
        {
          'action_name': 'sdk_json',
          'message': 'Creating sdk.json',
          'inputs': [

            # Depending on this file ensures that the SDK is built before this
            # action is executed.
            '<(PRODUCT_DIR)/dart-sdk/README',

            # This dependency is redundant for now, as this directory is
            # implicitly part of the dependencies for dart-sdk/README.
            'build_sdk_json.dart',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/sdk.json',
          ],
          'action': [

            '<(PRODUCT_DIR)/dart-sdk/bin/'
            '<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',

            '--package-root=<(PRODUCT_DIR)/packages/',
            'build_sdk_json.dart',
            '<(SHARED_INTERMEDIATE_DIR)/sdk.json',
          ],
        },
        {
          'action_name': 'compile',
          'message': 'Creating leap.dart.js',
          'inputs': [
            # Depending on this file ensures that the SDK is built before this
            # action is executed.
            '<(PRODUCT_DIR)/dart-sdk/README',

            # Ensure the packages directory is built first.
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',

            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "src"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/leap.dart.js',
          ],
          'action': [
            '<(PRODUCT_DIR)/dart-sdk/bin/dart2js<(script_suffix)',
            '-p<(PRODUCT_DIR)/packages/',
            '-Denable_ir=false',
            '--show-package-warnings',
            'src/leap.dart',
            '-o<(SHARED_INTERMEDIATE_DIR)/leap.dart.js',
          ],
        },
        {
          'action_name': 'compile_isolate',
          'message': 'Creating compiler_isolate.dart.js',
          'inputs': [
            # Depending on this file ensures that the SDK is built before this
            # action is executed.
            '<(PRODUCT_DIR)/dart-sdk/README',

            # Ensure the packages directory is built first.
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',

            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "src"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/compiler_isolate.dart.js',
          ],
          'action': [
            '<(PRODUCT_DIR)/dart-sdk/bin/dart2js<(script_suffix)',
            '-p<(PRODUCT_DIR)/packages/',
            '-Denable_ir=false',
            '--show-package-warnings',
            '--trust-type-annotations',
            'src/compiler_isolate.dart',
            '-o<(SHARED_INTERMEDIATE_DIR)/compiler_isolate.dart.js',
          ],
        },
        {
          'action_name': 'ssl_appcache',
          'message': 'Creating ssl.appcache',
          'inputs': [
            'add_time_stamp.py',
            'ssl.appcache',
            '<@(try_dart_static_files)',
            'build_try.gyp', # If the list of files changed.
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/ssl.appcache',
          ],
          # Try Dart! uses AppCache. Cached files are only validated when the
          # manifest changes (not its timestamp, but its actual contents).
          'action': [
            'python',
            'add_time_stamp.py',
            'ssl.appcache',
            '<(SHARED_INTERMEDIATE_DIR)/ssl.appcache',
          ],
        },
        {
          'action_name': 'make_pkg_packages',
          'inputs': [
            '../../tools/make_links.py',
            '<@(try_dart_hosted_package_directories)',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/try_dartlang_org_packages.stamp',
            '<(PRODUCT_DIR)/try_dartlang_org/packages'
          ],
          'action': [
            'python', '../../tools/make_links.py',
            '--timestamp_file=<(SHARED_INTERMEDIATE_DIR)'
            '/try_dartlang_org_packages.stamp',
            '<(PRODUCT_DIR)/try_dartlang_org/packages',
            '<@(_inputs)',
          ],
        },
      ],
      'copies': [
        {
          # Destination directory.
          'destination': '<(PRODUCT_DIR)/try_dartlang_org/',
          # List of files to be copied (creates implicit build dependencies).
          'files': [
            'app.yaml',
            '<@(try_dart_static_files)',
            '<(SHARED_INTERMEDIATE_DIR)/ssl.appcache',
          ],
        },
      ],
    },
  ],
}
