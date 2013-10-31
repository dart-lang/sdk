// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * File, socket, HTTP, and other I/O support for server applications.
 *
 * The IO library is used for Dart server applications,
 * which run on a stand-alone Dart VM from the command line.
 * *This library does not work in browser based applications.*
 *
 * This library allows you to work with files, directories,
 * sockets, processes, HTTP servers and clients, and more.
 */
library dart.io;

import 'dart:async';
import 'dart:_collection-dev';
import 'dart:collection' show LinkedHashSet,
                              LinkedList,
                              LinkedListEntry;
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

part 'bytes_builder.dart';
part 'common.dart';
part 'crypto.dart';
part 'data_transformer.dart';
part 'directory.dart';
part 'directory_impl.dart';
part 'eventhandler.dart';
part 'file.dart';
part 'file_impl.dart';
part 'file_system_entity.dart';
part 'http.dart';
part 'http_date.dart';
part 'http_headers.dart';
part 'http_impl.dart';
part 'http_parser.dart';
part 'http_session.dart';
part 'io_sink.dart';
part 'io_service.dart';
part 'link.dart';
part 'platform.dart';
part 'platform_impl.dart';
part 'process.dart';
part 'socket.dart';
part 'stdio.dart';
part 'string_transformer.dart';
part 'timer_impl.dart';
part 'secure_socket.dart';
part 'secure_server_socket.dart';
part 'websocket.dart';
part 'websocket_impl.dart';
