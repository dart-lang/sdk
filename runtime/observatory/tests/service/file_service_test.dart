// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future setupFiles() async {
  var dir = await io.Directory.systemTemp.createTemp('file_service');
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
    var result = JSON.encode({'type': 'foobar'});
    return new Future.value(new ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignored_a, ignored_b) async {
    try {
      var filePath = dir.path + io.Platform.pathSeparator + "file";
      var f = new io.File(filePath);
      writingFile = await f.open(mode: io.FileMode.WRITE);
      await writingFile.writeByte(42);
      await writingFile.writeByte(42);
      await writingFile.writeByte(42);

      var file = new io.File.fromUri(io.Platform.script);
      readingFile = await file.open();
      await readingFile.readByte();
      await readingFile.readByte();
      await readingFile.readByte();
      await readingFile.readByte();
      await readingFile.readByte();

      // The utility functions should close the files after them, so we
      // don't expect the calls below to result in open files.
      var writeTemp = dir.path + io.Platform.pathSeparator + "other_file";
      var utilFile = new io.File(writeTemp);
      await utilFile.writeAsString('foobar');
      var readTemp = new io.File(writeTemp);
      var result = await readTemp.readAsString();
      expect(result, equals('foobar'));
    } catch (e) {
      closeDown();
      throw e;
    }
    var result = JSON.encode({'type': 'foobar'});
    return new Future.value(new ServiceExtensionResponse.result(result));
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
}

var fileTests = [
  (Isolate isolate) async {
    await isolate.invokeRpcNoUpgrade('ext.dart.io.setup', {});
    try {
      var result =
          await isolate.invokeRpcNoUpgrade('ext.dart.io.getOpenFiles', {});
      expect(result['type'], equals('_openfiles'));

      expect(result['data'].length, equals(2));
      var writing = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getFileByID', {'id': result['data'][0]['id']});

      expect(writing['totalRead'], equals(0));
      expect(writing['readCount'], equals(0));
      expect(writing['writeCount'], equals(3));
      expect(writing['totalWritten'], equals(3));
      expect(writing['lastWrite'], greaterThan(0));
      expect(writing['lastRead'], equals(0));

      var reading = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getFileByID', {'id': result['data'][1]['id']});

      expect(reading['totalRead'], equals(5));
      expect(reading['readCount'], equals(5));
      expect(reading['writeCount'], equals(0));
      expect(reading['totalWritten'], equals(0));
      expect(reading['lastWrite'], equals(0));
      expect(reading['lastRead'], greaterThan(0));
    } finally {
      await isolate.invokeRpcNoUpgrade('ext.dart.io.cleanup', {});
    }
  },
];

main(args) async => runIsolateTests(args, fileTests, testeeBefore: setupFiles);
