// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:expect/expect.dart';

Future<void> runTest(int length) async {
  final Uint8List bytes = Uint8List(length);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = i;
  }
  final digest = sha1.convert(bytes);

  final Process proc = await Process.start(
    Platform.executable,
    <String>[Platform.script.toFilePath(), 'receiver'],
    runInShell: true,
  );

  proc.stdin.add(bytes);
  final result = proc.stdout.transform(utf8.decoder).join();
  proc.stderr.transform(utf8.decoder).listen((data) {
    stdout.write('stderr> $data');
  });

  await proc.stdin.flush();
  await proc.stdin.close();

  Expect.equals(0, await proc.exitCode);
  Expect.equals('got(${bytes.length},${digest})\n', await result);
}

void main(List<String> arguments) async {
  if (arguments.length == 1 && arguments.first == 'receiver') {
    // Read [stdin] and respond with `got(bytes,sha1digest)`.
    var gotBytes = 0;
    late Digest digest;
    final sha1Sink = sha1
        .startChunkedConversion(ChunkedConversionSink.withCallback((result) {
      digest = result.first;
    }));

    await stdin.listen((chunk) {
      gotBytes += chunk.length;
      sha1Sink.add(chunk);
    }).asFuture();
    sha1Sink.close();
    stdout.writeln('got($gotBytes,$digest)');
    await stdout.flush();
    return;
  }

  for (var mul in [1, 2, 4, 8]) {
    runTest(1437 * mul);
  }

  // kBufferSize in runtime/bin/eventhandler_win.cc
  const overlappedIoBufferSize = 64 * 1024;
  runTest(overlappedIoBufferSize);
  runTest(overlappedIoBufferSize - 1);
  runTest(overlappedIoBufferSize + 1);
}
