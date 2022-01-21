// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';
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
    var stringType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'String',
        isNullable: false,
        typeArguments: const []);

    var myInterfaceType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'MyInterface',
        isNullable: false,
        typeArguments: const []);
    var myMixinType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'MyMixin',
        isNullable: false,
        typeArguments: const []);
    var mySuperclassType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'MySuperclass',
        isNullable: false,
        typeArguments: const []);
    var myClassType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'MyClass',
        isNullable: false,
        typeArguments: const []);

    var myClass = ClassDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: myClassType.name,
        type: myClassType,
        typeParameters: [],
        interfaces: [myInterfaceType],
        isAbstract: false,
        isExternal: false,
        mixins: [myMixinType],
        superclass: mySuperclassType);
    var myConstructor = ConstructorDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: 'myConstructor',
        isAbstract: false,
        isExternal: false,
        isGetter: false,
        isSetter: false,
        namedParameters: [],
        positionalParameters: [],
        returnType: myClassType,
        typeParameters: [],
        definingClass: myClassType,
        isFactory: false);
    var myField = FieldDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: 'myField',
        initializer: null,
        isExternal: false,
        isFinal: false,
        isLate: false,
        type: stringType,
        definingClass: myClassType);
    var myInterface = ClassDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: myInterfaceType.name,
        type: myInterfaceType,
        typeParameters: [],
        interfaces: [],
        isAbstract: false,
        isExternal: false,
        mixins: [],
        superclass: null);
    var myMethod = MethodDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: 'myMethod',
        isAbstract: false,
        isExternal: false,
        isGetter: false,
        isSetter: false,
        namedParameters: [],
        positionalParameters: [],
        returnType: stringType,
        typeParameters: [],
        definingClass: myClassType);
    var myMixin = ClassDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: myMixinType.name,
        type: myMixinType,
        typeParameters: [],
        interfaces: [],
        isAbstract: false,
        isExternal: false,
        mixins: [],
        superclass: null);
    var mySuperclass = ClassDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: mySuperclassType.name,
        type: mySuperclassType,
        typeParameters: [],
        interfaces: [],
        isAbstract: false,
        isExternal: false,
        mixins: [],
        superclass: null);

    var myClassStaticType = TestNamedStaticType(
        'package:my_package/my_package.dart', myClassType.name, []);

    var testTypeResolver = TestTypeResolver({
      stringType: TestNamedStaticType('dart:core', stringType.name, []),
      myClassType: myClassStaticType,
    });
    var testClassIntrospector = TestClassIntrospector(
      constructors: {
        myClass: [myConstructor],
      },
      fields: {
        myClass: [myField],
      },
      interfaces: {
        myClass: [myInterface],
      },
      methods: {
        myClass: [myMethod],
      },
      mixins: {
        myClass: [myMixin],
      },
      superclass: {
        myClass: mySuperclass,
      },
    );
    var testTypeDeclarationResolver =
        TestTypeDeclarationResolver({myClassStaticType: myClass});

    group('in the declaration phase', () {
      test('on methods', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId, myMethod, testTypeResolver, testClassIntrospector);
        expect(
            result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace(
                'String delegateMemberMyMethod() => myMethod();'));
      });

      test('on constructors', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId, myConstructor, testTypeResolver, testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
              augment class MyClass {
                factory MyClass.myConstructorDelegate() => MyClass.myConstructor();
              }'''));
      });

      test('on fields', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId, myField, testTypeResolver, testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
              augment class MyClass {
                String get delegateMyField => myField;
              }'''));
      });

      test('on classes', () async {
        var result = await executor.executeDeclarationsPhase(
            instanceId, myClass, testTypeResolver, testClassIntrospector);
        expect(result.augmentations.single.debugString().toString(),
            equalsIgnoringWhitespace('''
              augment class MyClass {
                static const List<String> fieldNames = ['myField',];
              }'''));
      });
    });

    group('in the definition phase', () {
      test('on methods', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            myMethod,
            testTypeResolver,
            testClassIntrospector,
            testTypeDeclarationResolver);
        expect(definitionResult.augmentations, hasLength(2));
        var augmentationStrings = definitionResult.augmentations
            .map((a) => a.debugString().toString())
            .toList();
        expect(augmentationStrings, unorderedEquals(methodDefinitionMatchers));
      });

      test('on constructors', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            myConstructor,
            testTypeResolver,
            testClassIntrospector,
            testTypeDeclarationResolver);
        expect(definitionResult.augmentations, hasLength(1));
        expect(definitionResult.augmentations.first.debugString().toString(),
            constructorDefinitionMatcher);
      });

      test('on fields', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            myField,
            testTypeResolver,
            testClassIntrospector,
            testTypeDeclarationResolver);
        expect(definitionResult.augmentations, hasLength(1));
        expect(definitionResult.augmentations.first.debugString().toString(),
            fieldDefinitionMatcher);
      });

      test('on classes', () async {
        var definitionResult = await executor.executeDefinitionsPhase(
            instanceId,
            myClass,
            testTypeResolver,
            testClassIntrospector,
            testTypeDeclarationResolver);
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
  augment set (String value) {
    augment super(value);
  }
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
