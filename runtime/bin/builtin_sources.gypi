# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all sources (vm and tests) for the dart virtual machine.
# Unit test files need to have a '_test' suffix appended to the name.
{
  'sources': [
    #
    # Dart sources.
    #
    'builtin.dart',
    'buffer_list.dart',
    'directory.dart',
    'directory_impl.dart',
    'eventhandler.dart',
    'file.dart',
    'file_impl.dart',
    'input_stream.dart',
    'output_stream.dart',
    'string_stream.dart',
    'platform.dart',
    'platform_impl.dart',
    'process.dart',
    'process_impl.dart',
    'socket.dart',
    'socket_impl.dart',
    'socket_stream.dart',
    'timer.dart',
    'timer_impl.dart',
    #
    # C++ sources.
    #
    'dartutils.cc',
    'dartutils.h',
    'directory.cc',
    'directory.h',
    'directory_posix.cc',
    'directory_win.cc',
    'eventhandler.cc',
    'eventhandler.h',
    'eventhandler_linux.cc',
    'eventhandler_linux.h',
    'eventhandler_macos.cc',
    'eventhandler_macos.h',
    'eventhandler_win.cc',
    'eventhandler_win.h',
    'file.cc',
    'file.h',
    'file_linux.cc',
    'file_macos.cc',
    'file_win.cc',
    'file_test.cc',
    'fdutils.h',
    'fdutils_linux.cc',
    'fdutils_macos.cc',
    'globals.h',
    'platform.cc',
    'platform.h',
    'platform_linux.cc',
    'platform_macos.cc',
    'platform_win.cc',
    'process.cc',
    'process.h',
    'process_linux.cc',
    'process_macos.cc',
    'process_win.cc',
    'socket.cc',
    'socket.h',
    'socket_linux.cc',
    'socket_macos.cc',
    'socket_win.cc',
    'set.h',
    'set_test.cc',
  ],
}
