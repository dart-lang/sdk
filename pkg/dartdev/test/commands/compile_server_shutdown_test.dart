// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/resident_frontend_constants.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('shutdown', () {
    late TestProject p;

    tearDown(() async => await p.dispose());

    test('shutdown issued with no server running', () async {
      p = project();
      final serverInfoFile = path.join(p.dirPath, 'info');
      final result = await p.run([
        'compiler-server-shutdown',
        '--$serverInfoOption=$serverInfoFile',
      ]);

      expect(result.stdout, contains('No server instance running'));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test('shutdown', () async {
      p = project(mainSrc: 'void main() {}');
      final serverInfoFile = path.join(p.dirPath, 'info');
      final runResult = await p.run([
        'run',
        '--$serverInfoOption=$serverInfoFile',
        p.relativeFilePath,
      ]);

      expect(runResult.stdout, isNotEmpty);
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compiler-server-shutdown',
        '--$serverInfoOption=$serverInfoFile',
      ]);

      expect(result.stdout, contains('Server instance shutdown'));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });
  }, timeout: longTimeout);
}
