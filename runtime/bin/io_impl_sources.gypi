# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains some C++ sources for the dart:io library.  The other
# implementation files are in builtin_impl_sources.gypi.
{
  'sources': [
    'eventhandler.cc',
    'eventhandler.h',
    'eventhandler_android.cc',
    'eventhandler_linux.cc',
    'eventhandler_linux.h',
    'eventhandler_macos.cc',
    'eventhandler_macos.h',
    'eventhandler_win.cc',
    'eventhandler_win.h',
    'file_system_watcher.cc',
    'file_system_watcher.h',
    'file_system_watcher_android.cc',
    'file_system_watcher_linux.cc',
    'file_system_watcher_macos.cc',
    'file_system_watcher_win.cc',
    'filter.cc',
    'filter.h',
    'filter_unsupported.cc',
    'io_service.cc',
    'io_service.h',
    'io_service_no_ssl.cc',
    'io_service_no_ssl.h',
    'io_service_unsupported.cc',
    'platform.cc',
    'platform.h',
    'platform_android.cc',
    'platform_linux.cc',
    'platform_macos.cc',
    'platform_win.cc',
    'process.cc',
    'process.h',
    'process_android.cc',
    'process_linux.cc',
    'process_macos.cc',
    'process_win.cc',
    '../../third_party/root_certificates/root_certificates.cc',
    'secure_socket.cc',
    'secure_socket.h',
    'secure_socket_unsupported.cc',
    'socket.cc',
    'socket.h',
    'socket_android.cc',
    'socket_linux.cc',
    'socket_macos.cc',
    'socket_win.cc',
    'stdio.cc',
    'stdio.h',
    'stdio_android.cc',
    'stdio_linux.cc',
    'stdio_macos.cc',
    'stdio_win.cc',
  ],
  'conditions': [
    ['dart_io_support==1', {
      'conditions': [
        ['dart_io_secure_socket==1', {
          'sources!' : [
            'io_service_no_ssl.cc',
            'io_service_no_ssl.h',
            'secure_socket_unsupported.cc',
          ],
        }, {  # else dart_io_secure_socket == 0
          'sources!' : [
            '../../third_party/root_certificates/root_certificates.cc',
            'io_service.cc',
            'io_service.h',
            'secure_socket.cc',
            'secure_socket.h',
          ],
        }],
      ],
      'sources!' : [
        'filter_unsupported.cc',
        'io_service_unsupported.cc',
      ],
    },{  # else dart_io_support == 0
      'sources!' : [
        'filter.cc',
        'filter.h',
        'io_service.cc',
        'io_service.h',
        'io_service_no_ssl.cc',
        'io_service_no_ssl.h',
        '../../third_party/root_certificates/root_certificates.cc',
        'secure_socket.cc',
        'secure_socket.h',
      ],
    }],
  ],
}
