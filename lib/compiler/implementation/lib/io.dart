// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a copy of the VM's dart:io library. This API is not usable
// when running inside a web browser. Nevertheless, Leg provides a
// mock version of the dart:io library so that it can statically
// analyze programs that use dart:io.

// TODO(ahe): Separate API from implementation details.

/**
 * The IO library is used for Dart server applications,
 * which run on a stand-alone Dart VM from the command line.
 * *This library does not work in browser based applications.*
 *
 * This library allows you to work with files, directories,
 * sockets, processes, HTTP servers and clients, and more.
 */
#library("dart:io");
#import("dart:coreimpl");
#import("dart:math");
#import("dart:isolate");
// TODO(ahe): Should Leg support this library?
// #import("dart:nativewrappers");
#import("dart:uri");
#import("dart:crypto");
#import("dart:utf");
#source('../../../../runtime/bin/buffer_list.dart');
// Uses native keyword.
//#source('../../../../runtime/bin/common.dart');
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
#source('../../../../runtime/bin/path.dart');
#source('../../../../runtime/bin/path_impl.dart');
#source('../../../../runtime/bin/platform.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/platform_impl.dart');
#source('../../../../runtime/bin/process.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/process_impl.dart');
#source('../../../../runtime/bin/socket.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/socket_impl.dart');
#source('../../../../runtime/bin/socket_stream_impl.dart');
// Uses native keyword.
// #source('../../../../runtime/bin/stdio.dart');
#source('../../../../runtime/bin/stream_util.dart');
#source('../../../../runtime/bin/string_stream.dart');
#source('../../../../runtime/bin/timer_impl.dart');
#source('../../../../runtime/bin/websocket.dart');
#source('../../../../runtime/bin/websocket_impl.dart');

/**
  * An [OSError] object holds information about an error from the
  * operating system.
  */
class OSError {
  /** Constant used to indicate that no OS error code is available. */
  static const int noErrorCode = -1;

  /** Creates an OSError object from a message and an errorCode. */
  const OSError([String this.message = "", int this.errorCode = noErrorCode]);

  /** Converts an OSError object to a string representation. */
  String toString() {
    throw new UnsupportedError('OSError.toString');
  }

  /**
    * Error message supplied by the operating system. null if no message is
    * associated with the error.
    */
  final String message;

  /**
    * Error code supplied by the operating system. Will have the value
    * [noErrorCode] if there is no error code associated with the error.
    */
  final int errorCode;
}

List _ensureFastAndSerializableBuffer(List buffer, int offset, int bytes) {
  throw new UnsupportedError('_ensureFastAndSerializableBuffer');
}

class _File {
  factory _File(arg) {
    throw new UnsupportedError('new File($arg)');
  }

  factory _File.fromPath(arg) {
    throw new UnsupportedError('new File.fromPath($arg)');
  }
}

class _Platform {
  static int get numberOfProcessors {
    throw new UnsupportedError('_Platform.numberOfProcessors');
  }

  static String get pathSeparator {
    throw new UnsupportedError('_Platform.pathSeparator');
  }

  static String get operatingSystem {
    throw new UnsupportedError('_Platform.operatingSystem');
  }

  static String get localHostname {
    throw new UnsupportedError('_Platform.localHostname');
  }

  static Map<String, String> get environment {
    throw new UnsupportedError('_Platform.environment');
  }
}

class _Directory {
  factory _Directory(arg) {
    throw new UnsupportedError('new Directory($arg)');
  }

  factory _Directory.fromPath(arg) {
    throw new UnsupportedError('new Directory.fromPath($arg)');
  }

  factory _Directory.current() {
    throw new UnsupportedError('new Directory.current()');
  }
}

class _DirectoryLister {
}

void _exit(int exitCode) {
  throw new UnsupportedError("exit($exitCode)");
}

class _Process {
  static Future<Process> start(String executable,
                               List<String> arguments,
                               [ProcessOptions options]) {
    var msg = 'Process.start($executable, $arguments, $options)';
    throw new UnsupportedError(msg);
  }

  static Future<ProcessResult> run(String executable,
                                   List<String> arguments,
                                   [ProcessOptions options]) {
    var msg = 'Process.run($executable, $arguments, $options)';
    throw new UnsupportedError(msg);
  }
}

class _ServerSocket {
  factory _ServerSocket(String bindAddress, int port, int backlog) {
    throw new UnsupportedError(
        'new ServerSocket($bindAddress, $port, $backlog)');
  }
}

class _Socket {
  factory _Socket(String host, int port) {
    throw new UnsupportedError('new Socket($host, $port)');
  }
}

class _EventHandler {
  factory _EventHandler() {
    throw new UnsupportedError('new _EventHandler()');
  }

  static void _start() {
    throw new UnsupportedError('_EventHandler._start()');
  }

  static _sendData(int id, ReceivePort receivePort, int data) {
    var msg = '_EventHandler._sendData($id, $receivePort, $data)';
    throw new UnsupportedError(msg);
  }

  static _EventHandler get _eventHandler {
    throw new UnsupportedError('_EventHandler._eventhandler');
  }

  static void set _eventHandler(_EventHandler e) {
    throw new UnsupportedError('_EventHandler._eventhandler = $e');
  }
}

const InputStream stdin = null;

const OutputStream stdout = null;

const OutputStream stderr = null;
