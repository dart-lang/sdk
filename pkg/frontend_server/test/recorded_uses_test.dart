// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'frontend_server_test.dart';

extension FrontendServerRecordedUses on FrontendServer {
  void setRecordedUses({required Uri uri}) {
    outputParser.expectSources = true;
    inputStreamController.add('recorded-uses $uri\n'.codeUnits);
  }
}

void main() async {
  group('recorded-uses tests', () {
    final Uri platformKernel = computePlatformBinariesLocation().resolve(
      'vm_platform.dill',
    );
    final Uri sdkRoot = computePlatformBinariesLocation();

    late Directory tempDir;
    late File mainFile;
    late File fooFile;
    late File metaFile;
    late File recordedUsesFile;
    late File dillFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('frontendServerTest');

      metaFile = new File('${tempDir.path}/meta/lib/meta.dart');
      await metaFile.create(recursive: true);
      await metaFile.writeAsString('''
library meta;

class RecordUse {
  const RecordUse();
}
''');

      fooFile = new File('${tempDir.path}/foo/lib/foo.dart');
      await fooFile.create(recursive: true);
      await fooFile.writeAsString('''
import 'package:meta/meta.dart';

class Foo {
  @RecordUse()
  static void bar() {
    print(42);
  }
}
''');

      mainFile = new File('${tempDir.path}/a.dart');
      await mainFile.create(recursive: true);
      await mainFile.writeAsString('''
import 'package:foo/foo.dart';

void main() {
  Foo.bar();
}
''');

      final File packageConfigFile = new File(
        '${tempDir.path}/.dart_tool/package_config.json',
      );
      await packageConfigFile.create(recursive: true);
      await packageConfigFile.writeAsString(
        jsonEncode({
          "configVersion": 2,
          "packages": [
            {
              "name": "meta",
              "rootUri": "../meta",
              "packageUri": "lib/",
              "languageVersion": "3.0",
            },
            {
              "name": "foo",
              "rootUri": "../foo",
              "packageUri": "lib/",
              "languageVersion": "3.0",
            },
          ],
        }),
      );

      recordedUsesFile = new File('${tempDir.path}/recorded_uses.json');
      dillFile = new File('${tempDir.path}/app.dill');
    });

    tearDown(() async {
      return await tempDir.delete(recursive: true);
    });

    test('recorded-uses in AOT mode', () async {
      final FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(<String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--platform=${platformKernel.path}',
        '--packages=${tempDir.path}/.dart_tool/package_config.json',
        '--output-dill=${dillFile.path}',
        '--aot',
        '--tfa',
        '--recorded-uses=${recordedUsesFile.path}',
        '--enable-experiment=record-use',
      ]);

      frontendServer.compile(mainFile.path);

      final Completer<void> completer = new Completer<void>();
      frontendServer.listen((Result compiledResult) async {
        CompilationResult result = new CompilationResult.parse(
          compiledResult.status,
        );
        expect(await dillFile.exists(), equals(true));
        expect(result.filename, dillFile.path);
        expect(result.errorsCount, 0);

        expect(await recordedUsesFile.exists(), equals(true));
        final String contents = await recordedUsesFile.readAsString();
        expect(contents, contains('bar'));

        frontendServer.quit();
        completer.complete();
      });

      await completer.future;
      expect(await result, 0);
      frontendServer.close();
    });

    test('recorded-uses fails in JIT mode', () async {
      final FrontendServer frontendServer = new FrontendServer();
      // JIT mode (no --aot)
      Future<int> result = frontendServer.open(<String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--platform=${platformKernel.path}',
        '--packages=${tempDir.path}/.dart_tool/package_config.json',
        '--output-dill=${dillFile.path}',
        '--recorded-uses=${recordedUsesFile.path}',
        '--enable-experiment=record-use',
      ]);

      // In JIT mode, it should error out during argument parsing in compile()
      // or at startup. If it errors at startup, result will complete with 0
      // (because starter catches and prints usage/error).

      // We still try to compile to see if it triggers the error.
      frontendServer.compile(mainFile.path);

      // Give it a moment to process.
      await new Future.delayed(const Duration(milliseconds: 100));

      // Quit and close to ensure starter returns.
      frontendServer.quit();
      frontendServer.close();

      expect(await result.timeout(const Duration(seconds: 10)), 0);
    });
  });
}
