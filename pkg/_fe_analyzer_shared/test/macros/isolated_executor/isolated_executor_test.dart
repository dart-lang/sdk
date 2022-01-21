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
  late Directory tmpDir;
  late File simpleMacroFile;

  setUpAll(() {
    // We support running from either the root of the SDK or the package root.
    simpleMacroFile = File(
        'pkg/_fe_analyzer_shared/test/macros/isolated_executor/simple_macro.dart');
    if (!simpleMacroFile.existsSync()) {
      simpleMacroFile = File('test/macros/isolated_executor/simple_macro.dart');
    }
  });

  setUp(() async {
    executor = await isolatedExecutor.start();
    tmpDir = Directory.systemTemp.createTempSync('isolated_executor_test');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    executor.close();
  });

  test('can load and run macros', () async {
    var macroUri = simpleMacroFile.absolute.uri;
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
        isAbstract: false,
        isExternal: false,
        type: stringType,
        definingClass: myClassType);
    var myInterface = ClassDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: myInterfaceType.name,
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
        typeParameters: [],
        interfaces: [],
        isAbstract: false,
        isExternal: false,
        mixins: [],
        superclass: null);
    var mySuperclass = ClassDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: mySuperclassType.name,
        typeParameters: [],
        interfaces: [],
        isAbstract: false,
        isExternal: false,
        mixins: [],
        superclass: null);

    var myClassStaticType = TestNamedStaticType(
        'package:my_package/my_package.dart', myClassType.name, []);

    var definitionResult = await executor.executeDefinitionsPhase(
        instanceId,
        MethodDeclarationImpl(
          id: RemoteInstance.uniqueId,
          definingClass: myClassType,
          isAbstract: false,
          isExternal: false,
          isGetter: false,
          isSetter: false,
          name: 'foo',
          namedParameters: [],
          positionalParameters: [],
          returnType: stringType,
          typeParameters: [],
        ),
        TestTypeResolver({
          stringType: TestNamedStaticType('dart:core', stringType.name, []),
          myClassType: myClassStaticType,
        }),
        TestClassIntrospector(
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
        ),
        TestTypeDeclarationResolver({myClassStaticType: myClass}));
    expect(definitionResult.augmentations, hasLength(1));
    expect(definitionResult.augmentations.first.debugString().toString(),
        equalsIgnoringWhitespace('''
          augment class MyClass {
            augment String foo() {
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
          }'''));
  });
}
