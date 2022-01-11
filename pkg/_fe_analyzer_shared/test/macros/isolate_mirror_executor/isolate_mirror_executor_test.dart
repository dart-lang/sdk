// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/isolate_mirrors_executor/isolate_mirrors_executor.dart'
    as mirrorExecutor;

import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  late MacroExecutor executor;

  setUp(() async {
    executor = await mirrorExecutor.start();
  });

  tearDown(() {
    executor.close();
  });

  test('can load macros and create instances', () async {
    var clazzId = await executor.loadMacro(
        // Tests run from the root of the repo.
        File('pkg/_fe_analyzer_shared/test/macros/simple_macro.dart')
            .absolute
            .uri,
        'SimpleMacro');
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
