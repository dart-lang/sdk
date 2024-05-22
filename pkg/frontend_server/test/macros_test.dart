// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:frontend_server/compute_kernel.dart';
import 'package:macros/src/bootstrap.dart';
import 'package:macros/src/executor/serialization.dart';
import 'package:test/test.dart';

void main() async {
  group('basic macro', timeout: new Timeout(new Duration(minutes: 2)), () {
    late File productPlatformDill;
    late Directory tempDir;
    late Uri testMacroUri;
    late File packageConfig;
    late File bootstrapDillFile;

    setUp(() async {
      productPlatformDill = new File('${Platform.resolvedExecutable}/../../'
          'lib/_internal/vm_platform_strong_product.dill');
      Directory systemTempDir = Directory.systemTemp;
      tempDir = systemTempDir.createTempSync('frontendServerTest');
      testMacroUri = Uri.parse('package:test_macro/test_macro.dart');
      String bootstrapContent = bootstrapMacroIsolate(
        {
          testMacroUri.toString(): {
            'TestMacro': [''],
          },
        },
        SerializationMode.byteData,
      );
      File bootstrapFile = new File('${tempDir.path}/bootstrap.dart')
        ..writeAsStringSync(bootstrapContent);
      packageConfig = new File('${tempDir.path}/.dart_tool/package_config.json')
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
        "name": "macros",
        "rootUri": "${Platform.script.resolve('../../macros')}",
        "packageUri": "lib/"
      },
      {
        "name": "_macros",
        "rootUri": "${Platform.script.resolve('../../_macros')}",
        "packageUri": "lib/"
      },
      {
        "name": "meta",
        "rootUri": "${Platform.script.resolve('../../meta')}",
        "packageUri": "lib/"
      }
    ]
  }
  ''');
      File testMacroFile = new File('${tempDir.path}/lib/test_macro.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:macros/macros.dart';

macro class TestMacro implements ClassDeclarationsMacro {
  const TestMacro();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromString('int get x => 0;'));
  }
}
''');

      bootstrapDillFile = new File('${tempDir.path}/bootstrap.dart.dill');
      ComputeKernelResult bootstrapResult = await computeKernel([
        '--enable-experiment=macros',
        '--no-summary',
        '--no-summary-only',
        '--target=vm',
        '--dart-sdk-summary=${productPlatformDill.uri}',
        '--output=${bootstrapDillFile.path}',
        '--source=${bootstrapFile.uri}',
        '--source=${testMacroFile.uri}',
        '--packages-file=${packageConfig.uri}',
      ]);
      expect(bootstrapResult.succeeded, true);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    for (bool useIncrementalCompiler in [true, false]) {
      test(
          'can be compiled and applied'
          '${useIncrementalCompiler ? ' with incremental compiler' : ''}',
          () async {
        File applyTestMacroFile =
            new File('${tempDir.path}/lib/apply_test_macro.dart')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
import 'package:test_macro/test_macro.dart';

@TestMacro()
class TestClass{}

void main() {
  // Use the declaration created by the macro, so the compile will fail if the
  // macro application fails.
  print(TestClass().x);
}
''');
        File applyTestMacroDill =
            new File('${tempDir.path}/apply_test_macro.dart.dill');
        ComputeKernelResult applyTestMacroResult = await computeKernel([
          if (useIncrementalCompiler) '--use-incremental-compiler',
          '--enable-experiment=macros',
          '--no-summary',
          '--no-summary-only',
          '--target=vm',
          '--dart-sdk-summary=${productPlatformDill.uri}',
          '--output=${applyTestMacroDill.path}',
          '--source=${applyTestMacroFile.uri}',
          '--packages-file=${packageConfig.uri}',
          '--enable-experiment=macros',
          '--precompiled-macro',
          '${bootstrapDillFile.uri};$testMacroUri',
          '--macro-serialization-mode=bytedata',
        ]);
        expect(applyTestMacroResult.succeeded, true);
      });
    }
  });
}
