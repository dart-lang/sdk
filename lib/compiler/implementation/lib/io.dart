// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a copy of the VM's dart:io library. This API is not usable
// when running inside a web browser. Nevertheless, Leg provides a
// mock version of the dart:io library so that it can statically
// analyze programs that use dart:io.

// TODO(ahe): Separate API from implementation details.

#library("io");
#import("dart:coreimpl");
#import("dart:isolate");
// TODO(ahe): Should Leg support this library?
// #import("dart:nativewrappers");
#import("dart:uri");
#source('../../../../runtime/bin/buffer_list.dart');
#source('../../../../runtime/bin/common.dart');
#source('../../../../runtime/bin/chunked_stream.dart');
#source('../../../../runtime/bin/directory.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/directory_impl.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/eventhandler.dart');
#source('../../../../runtime/bin/file.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/file_impl.dart');
#source('../../../../runtime/bin/http.dart');
#source('../../../../runtime/bin/http_impl.dart');
#source('../../../../runtime/bin/http_parser.dart');
#source('../../../../runtime/bin/http_utils.dart');
#source('../../../../runtime/bin/input_stream.dart');
#source('../../../../runtime/bin/list_stream.dart');
#source('../../../../runtime/bin/list_stream_impl.dart');
#source('../../../../runtime/bin/output_stream.dart');
#source('../../../../runtime/bin/stream_util.dart');
#source('../../../../runtime/bin/string_stream.dart');
#source('../../../../runtime/bin/platform.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/platform_impl.dart');
#source('../../../../runtime/bin/process.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/process_impl.dart');
#source('../../../../runtime/bin/socket.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/socket_impl.dart');
#source('../../../../runtime/bin/socket_stream.dart');
#source('../../../../runtime/bin/socket_stream_impl.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/stdio.dart');
#source('../../../../runtime/bin/timer.dart');
#source('../../../../runtime/bin/timer_impl.dart');
#source('../../../../runtime/bin/websocket.dart');
#source('../../../../runtime/bin/websocket_impl.dart');

class _File {
  factory File(arg) {
    throw new UnsupportedOperationException('new File($arg)');
  }
}

class _Platform {
  static int numberOfProcessors() {
    throw new UnsupportedOperationException('_Platform.numberOfProcessors()');
  }

  static String pathSeparator() {
    throw new UnsupportedOperationException('_Platform.pathSeparator()');
  }

  static String operatingSystem() {
    throw new UnsupportedOperationException('_Platform.operatingSystem()');
  }

  static String localHostname() {
    throw new UnsupportedOperationException('_Platform.localHostname()');
  }

  static Map<String, String> environment() {
    throw new UnsupportedOperationException('_Platform.environment()');
  }
}

class _Directory {
  factory Directory(arg) {
    throw new UnsupportedOperationException('new Directory($arg)');
  }

  factory Directory.current() {
    throw new UnsupportedOperationException('new Directory.current()');
  }
}

class _Process {
  factory Process.start(String executable,
                        List<String> arguments,
                        [ProcessOptions options]) {
    var msg = 'new Process.start($executable, $arguments, $options)';
    throw new UnsupportedOperationException(msg);
  }

  factory Process.run(String executable,
                      List<String> arguments,
                      ProcessOptions options,
                      void callback(int exit, String out, String err)) {
    var msg = 'new Process.run($executable, $arguments, $options, $callback)';
    throw new UnsupportedOperationException(msg);
  }
}

class _ServerSocket {
  factory ServerSocket(String bindAddress, int port, int backlog) {
    throw new UnsupportedOperationException(
        'new ServerSocket($bindAddress, $port, $backlog)');
  }
}

class _Socket {
  factory Socket(String host, int port) {
    throw new UnsupportedOperationException('new Socket($host, $port)');
  }
}

class _EventHandler {
  factory _EventHandler() {
    throw new UnsupportedOperationException('new _EventHandler()');
  }

  static void _start() {
    throw new UnsupportedOperationException('_EventHandler._start()');
  }

  static _sendData(int id, ReceivePort receivePort, int data) {
    var msg = '_EventHandler._sendData($id, $receivePort, $data)';
    throw new UnsupportedOperationException(msg);
  }

  static _EventHandler get _eventHandler() {
    throw new UnsupportedOperationException('_EventHandler._eventhandler');
  }

  static void set _eventHandler(_EventHandler e) {
    throw new UnsupportedOperationException('_EventHandler._eventhandler = $e');
  }
}

final InputStream stdin = null;

final OutputStream stdout = null;

final OutputStream stderr = null;
