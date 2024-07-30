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

    test('shutdown issued with no server running', () async {
      p = project();
      final serverInfoFile = path.join(p.dirPath, 'info');
      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$residentCompilerInfoFileOption=$serverInfoFile',
      ]);

      expect(
        result.stdout,
        contains('No resident frontend compiler instance running'),
      );
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test(
        'when a compiler cannot receive a shutdown request due to a connection error',
        () async {
      // When this occurs, the info file associated with the running compiler
      // should be deleted, and the shutdown command should appear to have
      // succeeded, because there's nothing actionable the user can do to fix
      // the connection error.
      p = project(mainSrc: 'void main() {}');
      // Create a [serverInfoFile] with an invalid port to guarantee that a
      // connection will not be established.
      final serverInfoFile = path.join(p.dirPath, 'info');
      File(serverInfoFile).writeAsStringSync('address:127.0.0.1 port:-12 ');
      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$residentCompilerInfoFileOption=$serverInfoFile',
      ]);

      expect(result.stdout, matches(compilationServerShutdownRegExp));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test('run and shutdown', () async {
      p = project(mainSrc: 'void main() {}');
      final serverInfoFile = path.join(p.dirPath, 'info');
      final runResult = await p.run([
        'run',
        '--resident',
        '--$residentCompilerInfoFileOption=$serverInfoFile',
        p.relativeFilePath,
      ]);

      expect(runResult.stdout, matches(compilationServerStartRegExp));
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$residentCompilerInfoFileOption=$serverInfoFile',
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
        '--$residentCompilerInfoFileOption=$serverInfoFile',
      ]);

      expect(runResult.stdout, matches(compilationServerStartRegExp));
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$residentCompilerInfoFileOption=$serverInfoFile',
      ]);

      expect(result.stdout, matches(compilationServerShutdownRegExp));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test(
        'start and shutdown when using legacy --resident-server-info-file option',
        () async {
      p = project(mainSrc: 'void main() {}');
      final serverInfoFile = path.join(p.dirPath, 'info');
      final runResult = await p.run([
        'compilation-server',
        'start',
        '--resident-server-info-file=$serverInfoFile',
      ]);

      expect(runResult.stdout, matches(compilationServerStartRegExp));
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--resident-server-info-file=$serverInfoFile',
      ]);

      expect(result.stdout, matches(compilationServerShutdownRegExp));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });

    test(
        'start and shutdown when passing a relative path to --resident-compiler-info-file',
        () async {
      p = project(mainSrc: 'void main() {}');
      final serverInfoFile = path.join(p.dirPath, 'info');
      final runResult = await p.run([
        'compilation-server',
        'start',
        '--$residentCompilerInfoFileOption',
        path.relative(serverInfoFile, from: p.dirPath),
      ]);

      expect(runResult.stdout, matches(compilationServerStartRegExp));
      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), true);

      final result = await p.run([
        'compilation-server',
        'shutdown',
        '--$residentCompilerInfoFileOption',
        path.relative(serverInfoFile, from: p.dirPath),
      ]);

      expect(result.stdout, matches(compilationServerShutdownRegExp));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(serverInfoFile).existsSync(), false);
    });
  }, timeout: longTimeout);
}
