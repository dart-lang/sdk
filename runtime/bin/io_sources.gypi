# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all sources for the dart:io library.
{
  'sources': [
    # The io.dart file needs to be the first source file. It contains
    # the library and import directives for the dart:io library. The
    # dart:io library is created by concatenating the files listed here
    # in the order they are listed.
    'io.dart',

    'base64.dart',
    'buffer_list.dart',
    'chunked_stream.dart',
    'common.dart',
    'directory.dart',
    'directory_impl.dart',
    'eventhandler.dart',
    'file.dart',
    'file_impl.dart',
    'http.dart',
    'http_impl.dart',
    'http_parser.dart',
    'http_session.dart',
    'http_utils.dart',
    'input_stream.dart',
    'list_stream.dart',
    'list_stream_impl.dart',
    'mime_multipart_parser.dart',
    'output_stream.dart',
    'path.dart',
    'path_impl.dart',
    'platform.dart',
    'platform_impl.dart',
    'process.dart',
    'process_impl.dart',
    'socket.dart',
    'socket_impl.dart',
    'socket_stream_impl.dart',
    'stdio.dart',
    'stream_util.dart',
    'string_stream.dart',
    'timer_impl.dart',
    'websocket.dart',
    'websocket_impl.dart',
  ],
}
