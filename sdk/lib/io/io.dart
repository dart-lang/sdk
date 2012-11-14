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
#library('dart:io');

#import('dart:crypto');
#import('dart:isolate');
#import('dart:math');
#import('dart:uri');
#import('dart:utf');
#import('dart:scalarlist');

#source('base64.dart');
#source('buffer_list.dart');
#source('chunked_stream.dart');
#source('common.dart');
#source('directory.dart');
#source('directory_impl.dart');
#source('eventhandler.dart');
#source('file.dart');
#source('file_impl.dart');
#source('http.dart');
#source('http_impl.dart');
#source('http_parser.dart');
#source('http_session.dart');
#source('http_utils.dart');
#source('input_stream.dart');
#source('list_stream.dart');
#source('list_stream_impl.dart');
#source('mime_multipart_parser.dart');
#source('output_stream.dart');
#source('path.dart');
#source('path_impl.dart');
#source('platform.dart');
#source('platform_impl.dart');
#source('process.dart');
#source('socket.dart');
#source('socket_stream_impl.dart');
#source('stdio.dart');
#source('stream_util.dart');
#source('string_stream.dart');
#source('timer_impl.dart');
#source('tls_socket.dart');
#source('websocket.dart');
#source('websocket_impl.dart');
