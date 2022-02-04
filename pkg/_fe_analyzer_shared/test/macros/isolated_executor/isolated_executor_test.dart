// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/isolated_executor/isolated_executor.dart'
    as isolatedExecutor;

import 'package:test/test.dart';

import '../util.dart';

void main() {
  late MacroExecutor executor;
  late File kernelOutputFile;
  final macroName = 'SimpleMacro';
  late MacroInstanceIdentifier instanceId;
  late Uri macroUri;
  late File simpleMacroFile;
  late Directory tmpDir;

  setUpAll(() async {
    // We support running from either the root of the SDK or the package root.
    simpleMacroFile = File(
        'pkg/_fe_analyzer_shared/test/macros/isolated_executor/simple_macro.dart');
    if (!simpleMacroFile.existsSync()) {
      simpleMacroFile = File('test/macros/isolated_executor/simple_macro.dart');
    }
    executor = await isolatedExecutor.start();
    tmpDir = Directory.systemTemp.createTempSync('isolated_executor_test');
    macroUri = simpleMacroFile.absolute.uri;

    var bootstrapContent = bootstrapMacroIsolate({
      macroUri.toString(): {
        macroName: ['', 'named']
      }
    });
    var bootstrapFile = File(tmpDir.uri.resolve('main.dart').toFilePath())
      ..writeAsStringSync(bootstrapContent);
    kernelOutputFile = File(tmpDir.uri.resolve('main.dart.dill').toFilePath());
    var buildSnapshotResult = await Process.run(Platform.resolvedExecutable, [
      '--snapshot=${kernelOutputFile.uri.toFilePath()}',
      '--snapshot-kind=kernel',
      '--packages=${(await Isolate.packageConfig)!}',
      bootstrapFile.uri.toFilePath(),
    ]);
    expect(buildSnapshotResult.exitCode, 0,
        reason: 'stdout: ${buildSnapshotResult.stdout}\n'
            'stderr: ${buildSnapshotResult.stderr}');

    var clazzId = await executor.loadMacro(macroUri, macroName,
        precompiledKernelUri: kernelOutputFile.uri);
    expect(clazzId, isNotNull, reason: 'Can load a macro.');

    instanceId =
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
  });

  tearDownAll(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    executor.close();
  });

  group('run macros', () {
    group('in the types phase', () {
      test('on functions', () async {
        var result =
            await executor.executeTypesPhase(instanceId, Fixtures.myFunction);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedByMyFunction {}'));
      });

      test('on methods', () async {
        var result =
            await executor.executeTypesPhase(instanceId, Fixtures.myMethod);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedByMyMethod {}'));
      });

      test('on getters', () async {
        var result = await executor.executeTypesPhase(
          instanceId,
          Fixtures.myVariableGetter,
        );
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedByMyVariableGetter {}'));
      });

      test('on setters', () async {
        var result = await executor.executeTypesPhase(
          instanceId,
          Fixtures.myVariableSetter,
        );
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedByMyVariableSetter {}'));
      });

      test('on variables', () async {
        var result = await executor.executeTypesPhase(
          instanceId,
          Fixtures.myVariable,
        );
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedBy_myVariable {}'));
      });

      test('on constructors', () async {
        var result = await executor.executeTypesPhase(
            instanceId, Fixtures.myConstructor);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedByMyConstructor {}'));
      });

      test('on fields', () async {
        var result =
            await executor.executeTypesPhase(instanceId, Fixtures.myField);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('class GeneratedByMyField {}'));
      });

      test('on classes', () async {
        var result =
            await executor.executeTypesPhase(instanceId, Fixtures.myClass);
        expect(
            result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace(
                'class MyClassBuilder implements Builder<MyClass> {}'));
      });
    });

    group('in the declaration phase', () {
      test('on functions', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myFunction,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(
            result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace(
                'String delegateMyFunction() => myFunction();'));
      });

      test('on methods', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myMethod,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(
            result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace(
                'String delegateMemberMyMethod() => myMethod();'));
      });

      test('on constructors', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myConstructor,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
              augment class MyClass {
                factory MyClass.myConstructorDelegate() => MyClass.myConstructor();
              }'''));
      });

      test('on getters', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myVariableGetter,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
                String get delegateMyVariable => myVariable;'''));
      });

      test('on setters', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myVariableSetter,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
                void set delegateMyVariable(String value) => myVariable = value;'''));
      });

      test('on variables', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myVariable,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
                String get delegate_myVariable => _myVariable;'''));
      });

      test('on fields', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myField,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
              augment class MyClass {
                String get delegateMyField => myField;
              }'''));
      });

      test('on classes', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId,
            Fixtures.myClass,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
              augment class MyClass {
                static const List<String> fieldNames = ['myField',];
              }'''));
      });
    });

    group('in the definition phase', () {
      test('on functions', () async {
        var result = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myFunction,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
                augment String myFunction() {
                  print('isAbstract: false');
                  print('isExternal: false');
                  print('isGetter: false');
                  print('isSetter: false');
                  print('returnType: String');
                  return augment super();
                }'''));
      });

      test('on methods', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myMethod,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(definitionResult.augmentations, hasLength(2));
        var augmentationStrings = definitionResult.augmentations
            .map((a) => a.debugString().toString())
            .toList();
        expect(augmentationStrings, unorderedEquals(methodDefinitionMatchers));
      });

      test('on constructors', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myConstructor,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(definitionResult.augmentations, hasLength(1));
        expect(definitionResult.augmentations.first.debugString().toString(),
            constructorDefinitionMatcher);
      });

      test('on getters', () async {
        var result = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myVariableGetter,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
                augment String myVariable() {
                  print('isAbstract: false');
                  print('isExternal: false');
                  print('isGetter: true');
                  print('isSetter: false');
                  print('returnType: String');
                  return augment super;
                }'''));
      });

      test('on setters', () async {
        var result = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myVariableSetter,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
                augment void myVariable(String value, ) {
                  print('isAbstract: false');
                  print('isExternal: false');
                  print('isGetter: false');
                  print('isSetter: true');
                  print('returnType: void');
                  print('positionalParam: String value');
                  return augment super = value;
                }'''));
      });

      test('on variables', () async {
        var result = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myVariable,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(
            result.augmentations.map((a) => a.debugString().toString()),
            unorderedEquals([
              equalsIgnoringWhitespace('''
                augment String get _myVariable {
                  print('parentClass: ');
                  print('isExternal: false');
                  print('isFinal: true');
                  print('isLate: false');
                  return augment super;
                }'''),
              equalsIgnoringWhitespace('''
                augment set _myVariable(String value) {
                  augment super = value;
                }'''),
              equalsIgnoringWhitespace('''
                augment final String _myVariable = 'new initial value' + augment super;
                '''),
            ]));
      });

      test('on fields', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myField,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        expect(definitionResult.augmentations, hasLength(1));
        expect(definitionResult.augmentations.first.debugString().toString(),
            fieldDefinitionMatcher);
      });

      test('on classes', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            Fixtures.myClass,
            Fixtures.testTypeResolver,
            Fixtures.testClassIntrospector,
            Fixtures.testTypeDeclarationResolver);
        var augmentationStrings = definitionResult.augmentations
            .map((a) => a.debugString().toString())
            .toList();
        expect(
            augmentationStrings,
            unorderedEquals([
              ...methodDefinitionMatchers,
              constructorDefinitionMatcher,
              fieldDefinitionMatcher
            ]));
      });
    });
  });
}

final constructorDefinitionMatcher = equalsIgnoringWhitespace('''
augment class MyClass {
  augment MyClass.myConstructor() {
    print('definingClass: MyClass');
    print('isFactory: false');
    print('isAbstract: false');
    print('isExternal: false');
    print('isGetter: false');
    print('isSetter: false');
    print('returnType: MyClass');
    return augment super();
  }
}''');

final fieldDefinitionMatcher = equalsIgnoringWhitespace('''
augment class MyClass {
  augment String get myField {
    print('parentClass: MyClass');
    print('isExternal: false');
    print('isFinal: false');
    print('isLate: false');
    return augment super;
  }
  augment set myField(String value) {
    augment super = value;
  }
  augment String myField = \'new initial value\' + augment super;
}''');

final methodDefinitionMatchers = [
  equalsIgnoringWhitespace('''
    augment class MyClass {
      augment String myMethod() {
        print('definingClass: MyClass');
        print('isAbstract: false');
        print('isExternal: false');
        print('isGetter: false');
        print('isSetter: false');
        print('returnType: String');
        return augment super();
      }
    }
    '''),
  equalsIgnoringWhitespace('''
    augment class MyClass {
      augment String myMethod() {
        print('x: 1, y: 2');
        print('parentClass: MyClass');
        print('superClass: MySuperclass');
        print('interface: MyInterface');
        print('mixin: MyMixin');
        print('field: myField');
        print('method: myMethod');
        print('constructor: myConstructor');
        return augment super();
      }
    }'''),
];
