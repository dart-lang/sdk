// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:frontend_server/compute_kernel.dart';
import 'package:test/test.dart';

Directory tmp = Directory.systemTemp.createTempSync('ddc_worker_test');
File file(String path) => File.fromUri(tmp.uri.resolve(path));
String _resolvePath(String executableRelativePath) {
  return Uri.file(Platform.resolvedExecutable)
      .resolve(executableRelativePath)
      .toFilePath();
}

void main() {
  group('DDC: Macros', () {
    late File testMacroDart;
    late File bootstrapDillFileVm;
    late File bootstrapDillFileDdc;
    late Uri testMacroUri;
    late File packageConfig;
    late List<String> executableArgs;

    final applyTestMacroDart = file('apply_test_macro.dart');
    final testMacroJS = file('test_macro.js');
    final testMacroSummary = file('test_macro.dill');
    final applyTestMacroJS = file('apply_test_macro.js');

    setUp(() async {
      // Write a simple test macro and supporting package config.
      testMacroDart = file('lib/test_macro.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class TestMacro implements ClassDeclarationsMacro {
  const TestMacro();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromString('int get x => 0;'));
  }
}
''');
      packageConfig = file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "test_macro",
        "rootUri": "../",
        "packageUri": "lib/"
      },
      {
        "name": "_fe_analyzer_shared",
        "rootUri": "${Platform.script.resolve('../../../_fe_analyzer_shared')}",
        "packageUri": "lib/"
      },
      {
        "name": "meta",
        "rootUri": "${Platform.script.resolve('../../../meta')}",
        "packageUri": "lib/"
      }
    ]
  }
  ''');

      // Write the macro entrypoint, the "bootstrap" file.
      testMacroUri = Uri.parse('package:test_macro/test_macro.dart');
      var bootstrapContent = bootstrapMacroIsolate(
        {
          testMacroUri.toString(): {
            'TestMacro': [''],
          },
        },
        SerializationMode.byteData,
      );
      var bootstrapFile = file('bootstrap.dart')
        ..writeAsStringSync(bootstrapContent);

      // Compile the macro to vm dill to be run by the CFE.
      var productPlatformDill = File(_resolvePath('../'
          'lib/_internal/vm_platform_strong_product.dill'));
      var ddcPlatformDill = File(_resolvePath('../'
          'lib/_internal/ddc_outline.dill'));
      bootstrapDillFileVm = file('bootstrap.dart.dill');
      var bootstrapResult = await computeKernel([
        '--enable-experiment=macros',
        '--no-summary',
        '--no-summary-only',
        '--target=vm',
        '--dart-sdk-summary=${productPlatformDill.uri}',
        '--output=${bootstrapDillFileVm.path}',
        '--source=${bootstrapFile.uri}',
        '--source=${testMacroDart.uri}',
        '--packages-file=${packageConfig.uri}',
      ]);
      expect(bootstrapResult.succeeded, true);

      // Compile the macro to ddc dill for the ddc build.
      bootstrapDillFileDdc = file('bootstrap_ddc.dart.dill');
      var bootstrapResultDdc = await computeKernel([
        '--enable-experiment=macros',
        '--target=ddc',
        '--dart-sdk-summary=${ddcPlatformDill.uri}',
        '--output=${bootstrapDillFileDdc.path}',
        '--source=${bootstrapFile.uri}',
        '--source=${testMacroDart.uri}',
        '--packages-file=${packageConfig.uri}',
      ]);
      expect(bootstrapResultDdc.succeeded, true);

      // Write source that applies the macro.
      // TODO(davidmorgan): the `api` import should not be needed, but without
      // it the macro application does nothing: `computeMacroDeclarations` in
      // `source_loader.dart` does nothing because
      // `lookupLibraryBuilder(macroLibraryUri)` returns null. Fix.
      applyTestMacroDart.writeAsStringSync('''
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:test_macro/test_macro.dart';

@TestMacro()
class TestClass{}

void main() {
  // Use the declaration created by the macro, so the compile will fail if the
  // macro application fails.
  print(TestClass().x);
}
''');

      executableArgs = [
        '--enable-experiment=macros',
        _resolvePath('../../gen/dartdevc.dart.snapshot'),
        '--enable-experiment=macros',
        '--sound-null-safety',
        '--dart-sdk-summary',
        _resolvePath('../../ddc_outline.dill'),
        '--enable-experiment=macros',
        '--packages=${packageConfig.uri}',
      ];
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('compile in basic mode', () {
      var result = Process.runSync(Platform.executable, [
        ...executableArgs,
        '--no-source-map',
        '-o',
        testMacroJS.path,
        testMacroDart.path,
      ]);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(testMacroJS.existsSync(), isTrue);
      expect(testMacroSummary.existsSync(), isTrue);

      result = Process.runSync(Platform.executable, [
        ...executableArgs,
        '--precompiled-macro',
        '${bootstrapDillFileVm.path};$testMacroUri',
        '--no-source-map',
        '--no-summarize',
        '-s',
        testMacroSummary.path,
        '-s',
        bootstrapDillFileDdc.path,
        '-o',
        applyTestMacroJS.path,
        applyTestMacroDart.path,
      ]);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(applyTestMacroJS.existsSync(), isTrue);
    });
  });
}
