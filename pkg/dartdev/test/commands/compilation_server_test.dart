// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/resident_frontend_constants.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('compilation-server', () {
    late TestProject p;
    final compilationServerStartRegExp = RegExp(
      r'The Resident Frontend Compiler is listening at ([a-zA-Z0-9:/=_\-\.\[\]]+)\n'
      '\nRun dart compilation-server shutdown to terminate the process.',
    );
    final compilationServerShutdownRegExp = RegExp(
      r'The Resident Frontend Compiler instance at ([a-zA-Z0-9:/=_\-\.\[\]]+) was successfully shutdown.',
    );

    tearDown(() async => await p.dispose());

    test('shutdown issued with no server running', () async {
      p = project();
      final serverInfoFile = path.join(p.dirPath, 'info');
      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$serverInfoOption=$serverInfoFile',
      ]);

      expect(result.stdout, contains('No server instance running'));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test('run and shutdown', () async {
      p = project(mainSrc: 'void main() {}');
      final serverInfoFile = path.join(p.dirPath, 'info');
      final runResult = await p.run([
        'run',
        '--$serverInfoOption=$serverInfoFile',
        p.relativeFilePath,
      ]);

      expect(runResult.stdout, matches(compilationServerStartRegExp));
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$serverInfoOption=$serverInfoFile',
      ]);

      expect(result.stdout, matches(compilationServerShutdownRegExp));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test('start and shutdown', () async {
      p = project(mainSrc: 'void main() {}');
      final serverInfoFile = path.join(p.dirPath, 'info');
      final runResult = await p.run([
        'compilation-server',
        'start',
        '--$serverInfoOption=$serverInfoFile',
        p.relativeFilePath,
      ]);

      expect(runResult.stdout, matches(compilationServerStartRegExp));
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$serverInfoOption=$serverInfoFile',
      ]);

      expect(result.stdout, matches(compilationServerShutdownRegExp));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });
  }, timeout: longTimeout);
}
