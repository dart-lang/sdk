// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:test/test.dart';

// Reuse some test infrastructure.
import 'frontend_server_test.dart';

void main() async {
  group('full compiler tests', () {
    final Uri platformKernel =
        computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
    final Uri sdkRoot = computePlatformBinariesLocation();

    late Directory tempDir;
    late File mainFile;
    late File packageConfigFile;
    late File nativeAssetsYamlFile;
    late File dillFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('frontendServerTest');

      mainFile = new File('${tempDir.path}/a.dart');
      await mainFile.create(recursive: true);
      await mainFile.writeAsString('''
void main() {
  print(42);
}
''');

      packageConfigFile =
          new File('${tempDir.path}/.dart_tool/package_config.json');
      await packageConfigFile.create(recursive: true);
      await packageConfigFile.writeAsString(jsonEncode({
        "configVersion": 2,
        "packages": [],
      }));

      nativeAssetsYamlFile =
          new File('${tempDir.path}/.dart_tool/native_assets.yaml');
      await nativeAssetsYamlFile.create(recursive: true);
      await nativeAssetsYamlFile.writeAsString(jsonEncode({
        'format-version': [1, 0, 0],
        'native-assets': {
          new Abi.current().toString(): {
            mainFile.uri.toString(): ['executable'],
          },
        },
      }));

      // Other setup.
      dillFile = new File('${tempDir.path}/app.dill');
    });

    tearDown(() async {
      return await tempDir.delete(recursive: true);
    });

    group('--incremental', () {
      Future<void> testPassInNativeAssetsAtStartup({
        List<String> additionalStartupArguments = const [],
      }) async {
        final FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(<String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${platformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--native-assets=${nativeAssetsYamlFile.path}',
        ]);

        frontendServer.compile(mainFile.path);

        int count = 0;
        frontendServer.listen((Result compiledResult) async {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          switch (count) {
            case 0:
              expect(await dillFile.exists(), equals(true));
              expect(result.filename, dillFile.path);
              expect(result.errorsCount, 0);
              count += 1;
              frontendServer.accept();
              frontendServer.reset();

              final Component component =
                  loadComponentFromBinary(dillFile.path);
              final Library? nativeAssetsLibrary =
                  _findNativeAssetsLibrary(component);
              expect(nativeAssetsLibrary, isNotNull);

              final Library firstLib = component.libraries.first;
              expect(firstLib.importUri != _nativeAssetsLibraryUri, true);
              expect(nativeAssetsLibrary!.nonNullable, firstLib.nonNullable);
              expect(nativeAssetsLibrary.nonNullableByDefaultCompiledMode,
                  firstLib.nonNullableByDefaultCompiledMode);

              await mainFile.writeAsString('''
void main() {
  print(1337);
}
''');

              frontendServer.recompile(mainFile.uri);
              break;
            case 1:
              expect(await dillFile.exists(), equals(true));
              expect(result.filename, dillFile.path);
              expect(result.errorsCount, 0);
              frontendServer.accept();
              frontendServer.quit();

              final Component component =
                  loadComponentFromBinary(dillFile.path);
              final Library? nativeAssetsLibrary =
                  _findNativeAssetsLibrary(component);
              expect(nativeAssetsLibrary, isNotNull);

              break;
          }
        });
        expect(await result, 0);
        frontendServer.close();
      }

      test('pass in native assets at startup', () async {
        await testPassInNativeAssetsAtStartup();
      });

      test('--no-sound-null-safety', () async {
        await testPassInNativeAssetsAtStartup(additionalStartupArguments: [
          '--no-sound-null-safety',
        ]);
      });

      test('--incremental-serialization', () async {
        await testPassInNativeAssetsAtStartup(additionalStartupArguments: [
          '--incremental-serialization',
        ]);
      });

      test('set native assets later', () async {
        final FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(<String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${platformKernel.path}',
          '--output-dill=${dillFile.path}',
        ]);

        frontendServer.compile(mainFile.path);

        int count = 0;
        frontendServer.listen((Result compiledResult) async {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          switch (count) {
            case 0:
              expect(await dillFile.exists(), equals(true));
              expect(result.filename, dillFile.path);
              expect(result.errorsCount, 0);
              count += 1;
              frontendServer.accept();
              frontendServer.reset();

              final Component component =
                  loadComponentFromBinary(dillFile.path);
              final Library? nativeAssetsLibrary =
                  _findNativeAssetsLibrary(component);
              expect(nativeAssetsLibrary, isNull);

              frontendServer.setNativeAssets(uri: nativeAssetsYamlFile.uri);
              frontendServer.recompile(mainFile.uri);
              break;
            case 1:
              expect(await dillFile.exists(), equals(true));
              expect(result.filename, dillFile.path);
              expect(result.errorsCount, 0);
              count += 1;
              frontendServer.accept();

              final Component component =
                  loadComponentFromBinary(dillFile.path);
              final Library? nativeAssetsLibrary =
                  _findNativeAssetsLibrary(component);
              expect(nativeAssetsLibrary, isNotNull);

              frontendServer.compileNativeAssetsOnly();
              break;
            case 2:
              expect(await dillFile.exists(), equals(true));
              expect(result.filename, dillFile.path);
              expect(result.errorsCount, 0);
              count += 1;

              final Component component =
                  loadComponentFromBinary(dillFile.path);
              final Library? nativeAssetsLibrary =
                  _findNativeAssetsLibrary(component);
              expect(nativeAssetsLibrary, isNotNull);

              frontendServer.quit();
          }
        });
        expect(await result, 0);
        frontendServer.close();
      });

      Future<void> testInitializeFromDill({
        bool passNativeAssetsOnFirstStartup = false,
        bool passNativeAssetsOnSecondStartup = false,
      }) async {
        {
          final FrontendServer frontendServer = new FrontendServer();
          Future<int> frontendServerResult = frontendServer.open(<String>[
            '--sdk-root=${sdkRoot.toFilePath()}',
            '--incremental',
            '--platform=${platformKernel.path}',
            '--output-dill=${dillFile.path}',
            if (passNativeAssetsOnFirstStartup)
              '--native-assets=${nativeAssetsYamlFile.path}',
          ]);

          frontendServer.compile(mainFile.path);

          final Result compiledResult =
              await frontendServer.receivedResults.stream.first;
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          expect(await dillFile.exists(), equals(true));
          expect(result.filename, dillFile.path);
          expect(result.errorsCount, 0);

          frontendServer.accept();
          frontendServer.quit();

          final Component component = loadComponentFromBinary(dillFile.path);
          final Library? nativeAssetsLibrary =
              _findNativeAssetsLibrary(component);
          expect(nativeAssetsLibrary,
              passNativeAssetsOnFirstStartup ? isNotNull : isNull);

          expect(await frontendServerResult, 0);
          frontendServer.close();
        }

        {
          final FrontendServer frontendServer = new FrontendServer();
          Future<int> frontendServerResult = frontendServer.open(<String>[
            '--sdk-root=${sdkRoot.toFilePath()}',
            '--incremental',
            '--platform=${platformKernel.path}',
            '--output-dill=${dillFile.path}',
            '--initialize-from-dill=${dillFile.path}',
            if (passNativeAssetsOnSecondStartup)
              '--native-assets=${nativeAssetsYamlFile.path}',
          ]);

          frontendServer.compile(mainFile.path);

          final Result compiledResult =
              await frontendServer.receivedResults.stream.first;
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          expect(await dillFile.exists(), equals(true));
          expect(result.filename, dillFile.path);
          expect(result.errorsCount, 0);

          frontendServer.accept();
          frontendServer.quit();

          final Component component = loadComponentFromBinary(dillFile.path);
          final Library? nativeAssetsLibrary =
              _findNativeAssetsLibrary(component);
          expect(nativeAssetsLibrary,
              passNativeAssetsOnSecondStartup ? isNotNull : isNull);

          expect(await frontendServerResult, 0);
          frontendServer.close();
        }
      }

      test('--initialize-from-dill embed native-assets', () async {
        // This should forget the native assets, the incremental compiler
        // should be seen as an optimization, _not_ as a thing that keeps
        // state intentionally.
        await testInitializeFromDill(passNativeAssetsOnFirstStartup: true);
      });

      test('--initialize-from-dill second start with --native-assets',
          () async {
        await testInitializeFromDill(passNativeAssetsOnSecondStartup: true);
      });

      test('--initialize-from-dill replace --native-assets', () async {
        // This should forget the native assets from the first invocation.
        await testInitializeFromDill(
          passNativeAssetsOnFirstStartup: true,
          passNativeAssetsOnSecondStartup: true,
        );
      });
    });

    group('--aot --tfa', () {
      test('pass in native assets at startup', () async {
        final FrontendServer frontendServer = new FrontendServer();
        Future<int> frontendServerResult = frontendServer.open(<String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--platform=${platformKernel.path}',
          '--aot',
          '--tfa',
          '--output-dill=${dillFile.path}',
          '--native-assets=${nativeAssetsYamlFile.path}',
          mainFile.path
        ]);

        expect(await frontendServerResult, 0);
        frontendServer.close();

        expect(await dillFile.exists(), equals(true));
        final Component component = loadComponentFromBinary(dillFile.path);
        final Library? nativeAssetsLibrary =
            _findNativeAssetsLibrary(component);
        expect(nativeAssetsLibrary, isNotNull);
      });

      test('pass in native assets only at startup', () async {
        final FrontendServer frontendServer = new FrontendServer();
        Future<int> frontendServerResult = frontendServer.open(<String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--platform=${platformKernel.path}',
          '--aot',
          '--tfa',
          '--output-dill=${dillFile.path}',
          '--native-assets=${nativeAssetsYamlFile.path}',
          '--native-assets-only',
        ]);

        expect(await frontendServerResult, 0);
        frontendServer.close();

        expect(await dillFile.exists(), equals(true));
        final Component component = loadComponentFromBinary(dillFile.path);
        final Library? nativeAssetsLibrary =
            _findNativeAssetsLibrary(component);
        expect(nativeAssetsLibrary, isNotNull);
      });
    });
  });
}

final Uri _nativeAssetsLibraryUri = Uri.parse('vm:ffi:native-assets');

Library? _findNativeAssetsLibrary(Component component) {
  for (final Library library in component.libraries) {
    if (library.importUri == _nativeAssetsLibraryUri) {
      return library;
    }
  }
  return null;
}
