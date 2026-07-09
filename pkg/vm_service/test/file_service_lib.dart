// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'common/expect.dart';
import 'common/test_helper.dart';

Future setupFiles() async {
  final dir = await io.Directory.systemTemp.createTemp('file_service');
  late io.RandomAccessFile writingFile;
  late io.RandomAccessFile readingFile;

  void closeDown() {
    writingFile.closeSync();
    readingFile.closeSync();
    dir.deleteSync(recursive: true);
  }

  Future<ServiceExtensionResponse> cleanup(ignoredA, ignoredB) {
    closeDown();
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignoredA, ignoredB) async {
    try {
      final filePath = '${dir.path}${io.Platform.pathSeparator}file';
      final f = io.File(filePath);
      writingFile = await f.open(mode: io.FileMode.write);
      await writingFile.writeByte(42);
      await writingFile.writeByte(42);
      await writingFile.writeByte(42);

      final file = io.File.fromUri(io.Platform.script);
      readingFile = await file.open();
      await readingFile.readByte();
      await readingFile.readByte();
      await readingFile.readByte();
      await readingFile.readByte();
      await readingFile.readByte();

      // The utility functions should close the files after them, so we
      // don't expect the calls below to result in open files.
      final writeTemp = '${dir.path}${io.Platform.pathSeparator}other_file';
      final utilFile = io.File(writeTemp);
      await utilFile.writeAsString('foobar');
      final readTemp = io.File(writeTemp);
      final result = await readTemp.readAsString();
      Expect.equals(result, 'foobar');
    } catch (e) {
      closeDown();
      rethrow;
    }
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: setupFiles);
}
