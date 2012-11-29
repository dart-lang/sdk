// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The IO library is used for Dart server applications,
 * which run on a stand-alone Dart VM from the command line.
 * *This library does not work in browser based applications.*
 *
 * This library allows you to work with files, directories,
 * sockets, processes, HTTP servers and clients, and more.
 */
library dart_io;

import 'dart:crypto';
import 'dart:isolate';
import 'dart:math';
import 'dart:uri';
import 'dart:utf';
import 'dart:scalarlist';

part 'base64.dart';
part 'buffer_list.dart';
part 'chunked_stream.dart';
part 'common.dart';
part 'directory.dart';
part 'directory_impl.dart';
part 'eventhandler.dart';
part 'file.dart';
part 'file_impl.dart';
part 'http.dart';
part 'http_impl.dart';
part 'http_parser.dart';
part 'http_session.dart';
part 'http_utils.dart';
part 'input_stream.dart';
part 'list_stream.dart';
part 'list_stream_impl.dart';
part 'mime_multipart_parser.dart';
part 'output_stream.dart';
part 'path.dart';
part 'path_impl.dart';
part 'platform.dart';
part 'platform_impl.dart';
part 'process.dart';
part 'socket.dart';
part 'socket_stream_impl.dart';
part 'stdio.dart';
part 'stream_util.dart';
part 'string_stream.dart';
part 'timer_impl.dart';
part 'secure_socket.dart';
part 'secure_server_socket.dart';
part 'websocket.dart';
part 'websocket_impl.dart';
