// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/isolate_mirrors_executor/isolate_mirrors_executor.dart'
    as mirrorExecutor;

import 'package:test/test.dart';

import '../util.dart';

void main() {
  late MacroExecutor executor;
  late File simpleMacroFile;

  setUpAll(() {
    // We support running from either the root of the SDK or the package root.
    simpleMacroFile = File(
        'pkg/_fe_analyzer_shared/test/macros/isolate_mirror_executor/simple_macro.dart');
    if (!simpleMacroFile.existsSync()) {
      simpleMacroFile =
          File('test/macros/isolate_mirror_executor/simple_macro.dart');
    }
  });

  setUp(() async {
    executor = await mirrorExecutor.start();
  });

  tearDown(() {
    executor.close();
  });

  test('can load macros and create instances', () async {
    var clazzId =
        await executor.loadMacro(simpleMacroFile.absolute.uri, 'SimpleMacro');
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

    var returnType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'String',
        isNullable: false,
        typeArguments: const []);
    var definitionResult = await executor.executeDefinitionsPhase(
        instanceId,
        FunctionDeclarationImpl(
          id: RemoteInstance.uniqueId,
          isAbstract: false,
          isExternal: false,
          isGetter: false,
          isSetter: false,
          name: 'foo',
          namedParameters: [],
          positionalParameters: [],
          returnType: returnType,
          typeParameters: [],
        ),
        TestTypeResolver(
            {returnType: TestNamedStaticType('dart:core', 'String', [])}),
        FakeClassIntrospector(),
        FakeTypeDeclarationResolver());
    expect(definitionResult.augmentations, hasLength(1));
    expect(definitionResult.augmentations.first.debugString().toString(),
        equalsIgnoringWhitespace('''
            augment String foo() {
              print('x: 1, y: 2');
              return augment super();
            }'''));
  });
}
