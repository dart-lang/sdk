// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

void main() {
  group('DTD Snapshot Resolution', () {
    test('getDTDSnapshotDirInfo returns non-empty snapshot directory', () {
      final (snapshotDir, :runFromBuildRoot) = getDTDSnapshotDirInfo();
      expect(snapshotDir, isNotEmpty);
      expect(Directory(snapshotDir).existsSync(), isTrue);
      expect(runFromBuildRoot, isA<bool>());
    });

    test('getDTDSnapshotDir returns non-empty path', () {
      final snapshotDir = getDTDSnapshotDir();
      expect(snapshotDir, isNotEmpty);
      expect(Directory(snapshotDir).existsSync(), isTrue);
    });

    test('startDtd launches DTD without locking current directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('dtd_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
      final origDir = Directory.current;
      try {
        Directory.current = tempDir;
        final dtdInfo = await startDtd(machineMode: false, printDtdUri: false);
        expect(dtdInfo, isNotNull);
        expect(dtdInfo!.localUri.scheme, 'ws');
        expect(dtdInfo.secret, isNotNull);
        expect(dtdInfo.secret, isNotEmpty);
      } finally {
        Directory.current = origDir;
      }
      // On Windows, throws PathAccessException (errno = 32) if a DTD process
      // inherited tempDir as its working directory. The in-process AOT isolate
      // path is exercised by pkg/dartdev TestProject tests on Windows.
      tempDir.deleteSync(recursive: true);
    });
  });
}
