// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const String program1 = '''
class A {
  final int i;
  const A(this.i);
}
void main() {
  final a = A(1);
}
''';

const String program2Valid = '''
class A {
  final int i;
  const A(this.i);
}
void main() {
  final a = A(2);
}
''';

const String program2Error = '''
class A {
  const A();
}
void main() {
  final a = A();
}
''';

String _resolvePath(String executableRelativePath) {
  return Uri.file(
    Platform.resolvedExecutable,
  ).resolve(executableRelativePath).toFilePath();
}

Future<void> main() async {
  group('hot reload flags', () {
    late Directory tmp;
    late File outputJs;
    late File deltaDill;
    late File lastAcceptedDill;
    setUp(() {
      File file(String path) => File.fromUri(tmp.uri.resolve(path));

      tmp = Directory.systemTemp.createTempSync('hot_reload_flags_test');
      outputJs = file('output.js');
      deltaDill = file('delta.dill');
      lastAcceptedDill = file('lastAccepted.dill');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    void runDDC(
      List<String> flags,
      String programSource, {
      String? expectError,
    }) async {
      final sdkPath = p.dirname(Platform.executable);
      final dartAotRuntime = p.absolute(
        sdkPath,
        Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
      );
      final snapshotName = _resolvePath('snapshots/dartdevc_aot.dart.snapshot');
      final outlinePath = _resolvePath('../lib/_internal/ddc_outline.dill');

      final sourceFile = File.fromUri(tmp.uri.resolve('main.dart'));
      sourceFile.writeAsStringSync(programSource);

      final args = <String>[
        snapshotName,
        '--dart-sdk-summary',
        outlinePath,
        '-o',
        outputJs.path,
        ...flags,
        sourceFile.path,
      ];

      final process = Process.runSync(dartAotRuntime, args);
      if (expectError != null) {
        expect(process.exitCode, isNonNegative);
        expect(process.stderr, contains(expectError));
      } else {
        if (process.exitCode != 0) {
          print(process.stdout);
          print(process.stderr);
        }
        expect(process.exitCode, 0);
      }
    }

    test('providing no flag skips inspector', () {
      runDDC(const [], program1);
      expect(outputJs.existsSync(), isTrue);
      expect(outputJs.statSync().size, isNonNegative);
    });

    test('providing only delta output flag does not error', () {
      runDDC(['--reload-delta-kernel=${deltaDill.path}'], program1);
      expect(deltaDill.existsSync(), isTrue);
      expect(deltaDill.statSync().size, isNonNegative);
      expect(outputJs.existsSync(), isTrue);
      expect(outputJs.statSync().size, isNonNegative);
    });

    test(
      'providing delta output and last accepted input flag valid change',
      () {
        runDDC(['--reload-delta-kernel=${lastAcceptedDill.path}'], program1);
        expect(lastAcceptedDill.existsSync(), isTrue);
        expect(lastAcceptedDill.statSync().size, isNonNegative);

        runDDC([
          '--reload-last-accepted-kernel=${lastAcceptedDill.path}',
          '--reload-delta-kernel=${deltaDill.path}',
        ], program2Valid);
        expect(lastAcceptedDill.existsSync(), isTrue);
        expect(lastAcceptedDill.statSync().size, isNonNegative);
        expect(deltaDill.existsSync(), isTrue);
        expect(deltaDill.statSync().size, isNonNegative);
        expect(outputJs.existsSync(), isTrue);
        expect(outputJs.statSync().size, isNonNegative);
      },
    );

    test(
      'providing delta output and last accepted input flag invalid change',
      () {
        runDDC(['--reload-delta-kernel=${lastAcceptedDill.path}'], program1);
        runDDC(
          [
            '--reload-last-accepted-kernel=${lastAcceptedDill.path}',
            '--reload-delta-kernel=${deltaDill.path}',
          ],
          program2Error,
          expectError: 'Const class cannot remove fields',
        );
        expect(lastAcceptedDill.existsSync(), isTrue);
        expect(lastAcceptedDill.statSync().size, isNonNegative);
        expect(deltaDill.existsSync(), isFalse);
      },
    );
  });
}
