// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.utils.file_pool;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pool/pool.dart';
import 'package:stack_trace/stack_trace.dart';

import '../utils.dart';

/// Manages a pool of files that are opened for reading to cope with maximum
/// file descriptor limits.
///
/// If a file cannot be opened because too many files are already open, this
/// will defer the open until a previously opened file is closed and then try
/// again. If this doesn't succeed after a certain amount of time, the open
/// will fail and the original "too many files" exception will be thrown.
class FilePool {
  /// The underlying pool.
  ///
  /// The maximum number of allocated descriptors is based on empirical tests
  /// that indicate that beyond 32, additional file reads don't provide
  /// substantial additional throughput.
  final Pool _pool = new Pool(32, timeout: new Duration(seconds: 60));

  /// Opens the file at [path] for reading.
  ///
  /// When the returned stream is listened to, if there are too many files
  /// open, this will wait for a previously opened file to be closed and then
  /// try again.
  Stream<List<int>> openRead(String path) {
    return futureStream(_pool.request().then((resource) {
      return Chain.track(new File(path).openRead()).transform(
          new StreamTransformer.fromHandlers(handleDone: (sink) {
        sink.close();
        resource.release();
      }));
    }));
  }

  /// Reads [path] as a string using [encoding].
  ///
  /// If there are too many files open and the read fails, this will wait for
  /// a previously opened file to be closed and then try again.
  Future<String> readAsString(String path, Encoding encoding) {
    return _readAsBytes(path).then(encoding.decode);
  }

  /// Reads [path] as a list of bytes, using [openRead] to retry if there are
  /// failures.
  Future<List<int>> _readAsBytes(String path) {
    var completer = new Completer<List<int>>();
    var builder = new BytesBuilder();

    openRead(path).listen(builder.add, onDone: () {
      completer.complete(builder.takeBytes());
    }, onError: completer.completeError, cancelOnError: true);

    return completer.future;
  }
}
