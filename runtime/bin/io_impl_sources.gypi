# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains some C++ sources for the dart:io library.  The other
# implementation files are in builtin_impl_sources.gypi.
{
  'sources': [
    'common.cc',
    'crypto.cc',
    'crypto_android.cc',
    'crypto_linux.cc',
    'crypto_macos.cc',
    'crypto_win.cc',
    'eventhandler.cc',
    'eventhandler.h',
    'eventhandler_android.cc',
    'eventhandler_linux.cc',
    'eventhandler_linux.h',
    'eventhandler_macos.cc',
    'eventhandler_macos.h',
    'eventhandler_win.cc',
    'eventhandler_win.h',
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
    'socket.cc',
    'socket.h',
    'socket_android.cc',
    'socket_linux.cc',
    'socket_macos.cc',
    'socket_win.cc',
  ],
}
