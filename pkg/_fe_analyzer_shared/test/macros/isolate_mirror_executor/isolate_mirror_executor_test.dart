// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/isolate_mirrors_executor/isolate_mirrors_executor.dart';

import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  late MacroExecutor executor;

  setUp(() async {
    executor = await IsolateMirrorMacroExecutor.start();
  });

  tearDown(() {
    executor.close();
  });

  test('can load macros and create instances', () async {
    var clazzId = await executor.loadMacro(
        // Tests run from the root of the repo.
        File('pkg/_fe_analyzer_shared/test/macros/isolate_mirror_executor/simple_macro.dart')
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
        _FunctionDeclaration(
          isAbstract: false,
          isExternal: false,
          isGetter: false,
          isSetter: false,
          name: 'foo',
          namedParameters: [],
          positionalParameters: [],
          returnType:
              _TypeAnnotation(Code.fromString('String'), isNullable: false),
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

class _FunctionDeclaration implements FunctionDeclaration {
  @override
  final bool isAbstract;

  @override
  final bool isExternal;

  @override
  final bool isGetter;

  @override
  final bool isSetter;

  @override
  final String name;

  @override
  final Iterable<ParameterDeclaration> namedParameters;

  @override
  final Iterable<ParameterDeclaration> positionalParameters;

  @override
  final TypeAnnotation returnType;

  @override
  final Iterable<TypeParameterDeclaration> typeParameters;

  _FunctionDeclaration({
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isSetter,
    required this.name,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });
}

class _TypeAnnotation implements TypeAnnotation {
  @override
  final Code code;

  @override
  final bool isNullable;

  _TypeAnnotation(this.code, {required this.isNullable});
}

extension _ on Code {
  StringBuffer debugString([StringBuffer? buffer]) {
    buffer ??= StringBuffer();
    for (var part in parts) {
      if (part is Code) {
        part.debugString(buffer);
      } else {
        buffer.write(part.toString());
      }
    }
    return buffer;
  }
}
