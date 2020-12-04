// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:expect/expect.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

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

var fileTests = <IsolateTest>[
  (Isolate isolate) async {
    await isolate.invokeRpcNoUpgrade('ext.dart.io.setup', {});
    try {
      final result =
          await isolate.invokeRpcNoUpgrade('ext.dart.io.getOpenFiles', {});
      expect(result['type'], equals('OpenFileList'));
      expect(result['files'].length, equals(2));
      final writing = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getOpenFileById', {'id': result['files'][0]['id']});

      expect(writing['readBytes'], equals(0));
      expect(writing['readCount'], equals(0));
      expect(writing['writeCount'], equals(3));
      expect(writing['writeBytes'], equals(3));
      expect(writing['lastWriteTime'], greaterThan(0));
      expect(writing['lastReadTime'], equals(0));

      final reading = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getOpenFileById', {'id': result['files'][1]['id']});

      expect(reading['readBytes'], equals(5));
      expect(reading['readCount'], equals(5));
      expect(reading['writeCount'], equals(0));
      expect(reading['writeBytes'], equals(0));
      expect(reading['lastWriteTime'], equals(0));
      expect(reading['lastReadTime'], greaterThan(0));
    } finally {
      await isolate.invokeRpcNoUpgrade('ext.dart.io.cleanup', {});
    }
  },
];

main(args) async => runIsolateTests(args, fileTests, testeeBefore: setupFiles);
