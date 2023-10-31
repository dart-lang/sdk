// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/expect.dart';
import 'common/test_helper.dart';

Future setupFiles() async {
  final dir = await io.Directory.systemTemp.createTemp('file_service');
  var writingFile;
  var readingFile;

  void closeDown() {
    if (writingFile != null) {
      writingFile.closeSync();
    }
    if (readingFile != null) {
      readingFile.closeSync();
    }
    dir.deleteSync(recursive: true);
  }

  Future<ServiceExtensionResponse> cleanup(ignored_a, ignored_b) {
    closeDown();
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignored_a, ignored_b) async {
    try {
      final filePath = dir.path + io.Platform.pathSeparator + "file";
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
      final writeTemp = dir.path + io.Platform.pathSeparator + "other_file";
      final utilFile = io.File(writeTemp);
      await utilFile.writeAsString('foobar');
      final readTemp = io.File(writeTemp);
      final result = await readTemp.readAsString();
      Expect.equals(result, 'foobar');
    } catch (e) {
      closeDown();
      throw e;
    }
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    try {
      await service.callServiceExtension('ext.dart.io.setup',
          isolateId: isolateId);
      final result = await service.getOpenFiles(isolateId);
      expect(result.files.length, 2);

      final writing = await service.getOpenFileById(
        isolateId,
        result.files[0].id,
      );
      expect(writing.readBytes, 0);
      expect(writing.readCount, 0);
      expect(writing.writeCount, 3);
      expect(writing.writeBytes, 3);
      expect(writing.lastWriteTime.millisecondsSinceEpoch, greaterThan(0));
      expect(writing.lastReadTime.millisecondsSinceEpoch, 0);

      final reading = await service.getOpenFileById(
        isolateId,
        result.files[1].id,
      );

      expect(reading.readBytes, 5);
      expect(reading.readCount, 5);
      expect(reading.writeCount, 0);
      expect(reading.writeBytes, 0);
      expect(reading.lastWriteTime.millisecondsSinceEpoch, 0);
      expect(reading.lastReadTime.millisecondsSinceEpoch, greaterThan(0));
    } finally {
      await service.callServiceExtension(
        'ext.dart.io.cleanup',
        isolateId: isolateId,
      );
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'file_service_test.dart',
      testeeBefore: setupFiles,
    );
