// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/isolated_executor/isolated_executor.dart'
    as isolatedExecutor;

import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  late MacroExecutor executor;
  late Directory tmpDir;

  setUp(() async {
    executor = await isolatedExecutor.start();
    tmpDir = Directory.systemTemp.createTempSync('isolated_executor_test');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    executor.close();
  });

  test('can load macros and create instances', () async {
    // Tests run from the root of the repo.
    var macroUri = File('pkg/_fe_analyzer_shared/test/macros/simple_macro.dart')
        .absolute
        .uri;
    var macroName = 'SimpleMacro';

    var bootstrapContent =
        bootstrapMacroIsolate(macroUri.toString(), macroName, ['', 'named']);
    var bootstrapFile = File(tmpDir.uri.resolve('main.dart').toFilePath())
      ..writeAsStringSync(bootstrapContent);
    var kernelOutputFile =
        File(tmpDir.uri.resolve('main.dart.dill').toFilePath());
    var result = await Process.run(Platform.resolvedExecutable, [
      '--snapshot=${kernelOutputFile.uri.toFilePath()}',
      '--snapshot-kind=kernel',
      '--packages=${(await Isolate.packageConfig)!}',
      bootstrapFile.uri.toFilePath(),
    ]);
    expect(result.exitCode, 0,
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');

    var clazzId = await executor.loadMacro(macroUri, macroName,
        precompiledKernelUri: kernelOutputFile.uri);
    expect(clazzId, isNotNull, reason: 'Can load a macro.');

    var instanceId =
        await executor.instantiateMacro(clazzId, '', Arguments([], {}));
    expect(instanceId, isNotNull,
        reason: 'Can create an instance with no arguments.');

    instanceId =
        await executor.instantiateMacro(clazzId, '', Arguments([1, 2], {}));
    expect(instanceId, isNotNull,
        reason: 'Can create an instance with positional arguments.');

    instanceId = await executor.instantiateMacro(
        clazzId, 'named', Arguments([], {'x': 1, 'y': 2}));
    expect(instanceId, isNotNull,
        reason: 'Can create an instance with named arguments.');

    var definitionResult = await executor.executeDefinitionsPhase(
        instanceId,
        FunctionDeclarationImpl(
          isAbstract: false,
          isExternal: false,
          isGetter: false,
          isSetter: false,
          name: 'foo',
          namedParameters: [],
          positionalParameters: [],
          returnType: NamedTypeAnnotationImpl(
              name: 'String', isNullable: false, typeArguments: const []),
          typeParameters: [],
        ),
        _FakeTypeResolver(),
        _FakeClassIntrospector(),
        _FakeTypeDeclarationResolver());
    expect(definitionResult.augmentations, hasLength(1));
    expect(definitionResult.augmentations.first.debugString().toString(),
        equalsIgnoringWhitespace('''
            augment String foo() {
              print('x: 1, y: 2');
              return augment super();
            }'''));
  });
}

class _FakeClassIntrospector with Fake implements ClassIntrospector {}

class _FakeTypeResolver with Fake implements TypeResolver {}

class _FakeTypeDeclarationResolver
    with Fake
    implements TypeDeclarationResolver {}

extension _ on Code {
  StringBuffer debugString([StringBuffer? buffer]) {
    buffer ??= StringBuffer();
    for (var part in parts) {
      if (part is Code) {
        part.debugString(buffer);
      } else if (part is TypeAnnotation) {
        part.code.debugString(buffer);
      } else {
        buffer.write(part.toString());
      }
    }
    return buffer;
  }
}
