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
  });
}
