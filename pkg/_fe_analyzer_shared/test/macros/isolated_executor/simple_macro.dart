// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// A very simple macro that augments any declaration it is given, usually
/// adding print statements and inlining values from the declaration object
/// for comparision with expected values in tests.
///
/// When applied to [MethodDeclaration]s there is some extra work that happens
/// to validate the introspection APIs work as expected.
class SimpleMacro
    implements
        ClassDeclarationsMacro,
        ClassDefinitionMacro,
        ConstructorDeclarationsMacro,
        ConstructorDefinitionMacro,
        FieldDeclarationsMacro,
        FieldDefinitionMacro,
        FunctionDeclarationsMacro,
        FunctionDefinitionMacro,
        MethodDeclarationsMacro,
        MethodDefinitionMacro,
        VariableDeclarationsMacro,
        VariableDefinitionMacro {
  final int? x;
  final int? y;

  SimpleMacro([this.x, this.y]);

  SimpleMacro.named({this.x, this.y});

  @override
  FutureOr<void> buildDeclarationsForClass(
      ClassDeclaration clazz, ClassMemberDeclarationBuilder builder) async {
    var fields = await builder.fieldsOf(clazz);
    builder.declareInClass(DeclarationCode.fromParts([
      'static const List<String> fieldNames = [',
      for (var field in fields) "'${field.name}',",
      '];',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor,
      ClassMemberDeclarationBuilder builder) {
    if (constructor.positionalParameters.isNotEmpty ||
        constructor.namedParameters.isNotEmpty) {
      throw new UnsupportedError(
          'Can only run on constructors with no parameters!');
    }
    builder.declareInClass(
        DeclarationCode.fromString('factory ${constructor.definingClass.name}'
            '.${constructor.name}Delegate() => '
            '${constructor.definingClass.name}.${constructor.name}();'));
  }

  @override
  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder) {
    if (function.positionalParameters.isNotEmpty ||
        function.namedParameters.isNotEmpty) {
      throw new UnsupportedError(
          'Can only run on functions with no parameters!');
    }
    builder.declareInLibrary(DeclarationCode.fromParts([
      function.returnType,
      ' delegate${function.name.capitalize()}() => ${function.name}();',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForMethod(
      MethodDeclaration method, ClassMemberDeclarationBuilder builder) {
    if (method.positionalParameters.isNotEmpty ||
        method.namedParameters.isNotEmpty) {
      throw new UnsupportedError('Can only run on method with no parameters!');
    }
    builder.declareInLibrary(DeclarationCode.fromParts([
      method.returnType,
      ' delegateMember${method.name.capitalize()}() => ${method.name}();',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForVariable(
      VariableDeclaration variable, DeclarationBuilder builder) {
    builder.declareInLibrary(DeclarationCode.fromParts([
      variable.type,
      ' get delegate${variable.name.capitalize()} => ${variable.name};',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForField(
      FieldDeclaration field, ClassMemberDeclarationBuilder builder) {
    builder.declareInClass(DeclarationCode.fromParts([
      field.type,
      ' get delegate${field.name.capitalize()} => ${field.name};',
    ]));
  }

  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, ClassDefinitionBuilder builder) async {
    // Apply ourself to all our members
    var fields = (await builder.fieldsOf(clazz));
    for (var field in fields) {
      await buildDefinitionForField(
          field, await builder.buildField(field.name));
    }
    var methods = (await builder.methodsOf(clazz));
    for (var method in methods) {
      await buildDefinitionForMethod(
          method, await builder.buildMethod(method.name));
    }
    var constructors = (await builder.constructorsOf(clazz));
    for (var constructor in constructors) {
      await buildDefinitionForConstructor(
          constructor, await builder.buildConstructor(constructor.name));
    }
  }

  @override
  Future<void> buildDefinitionForConstructor(ConstructorDeclaration constructor,
      ConstructorDefinitionBuilder builder) async {
    var clazz = await builder.declarationOf(
            await builder.resolve(constructor.definingClass) as NamedStaticType)
        as ClassDeclaration;
    var fields = (await builder.fieldsOf(clazz));

    builder.augment(
      body: _buildFunctionAugmentation(constructor),
      initializers: [
        for (var field in fields)
          // TODO: Compare against actual `int` type.
          if (field.isFinal &&
              (field.type as NamedTypeAnnotation).name == 'int')
            Code.fromString('${field.name} = ${x!}'),
      ],
    );
  }

  @override
  Future<void> buildDefinitionForField(
          FieldDeclaration field, VariableDefinitionBuilder builder) async =>
      buildDefinitionForVariable(field, builder);

  @override
  Future<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder) async {
    builder.augment(_buildFunctionAugmentation(function));
  }

  @override
  Future<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    await buildDefinitionForFunction(method, builder);

    // Test the type resolver and static type interfaces
    var staticReturnType = await builder.resolve(method.returnType);
    if (!(await staticReturnType.isExactly(staticReturnType))) {
      throw StateError('The return type should be exactly equal to itself!');
    }
    if (!(await staticReturnType.isSubtypeOf(staticReturnType))) {
      throw StateError('The return type should be a subtype of itself!');
    }
    var classType =
        await builder.resolve(method.definingClass) as NamedStaticType;
    if (await staticReturnType.isExactly(classType)) {
      throw StateError(
          'The return type should not be exactly equal to the class type');
    }
    if (await staticReturnType.isSubtypeOf(classType)) {
      throw StateError(
          'The return type should not be a subtype of the class type!');
    }

    // Test the type declaration resolver
    var parentClass =
        await builder.declarationOf(classType) as ClassDeclaration;
    // Should be able to find ourself in the methods of the parent class.
    (await builder.methodsOf(parentClass))
        .singleWhere((m) => m.name == method.name);

    // Test the class introspector
    var superClass = (await builder.superclassOf(parentClass))!;
    var interfaces = (await builder.interfacesOf(parentClass));
    var mixins = (await builder.mixinsOf(parentClass));
    var fields = (await builder.fieldsOf(parentClass));
    var methods = (await builder.methodsOf(parentClass));
    var constructors = (await builder.constructorsOf(parentClass));

    builder.augment(FunctionBodyCode.fromParts([
      '''{
      print('x: $x, y: $y');
      print('parentClass: ${parentClass.name}');
      print('superClass: ${superClass.name}');''',
      for (var interface in interfaces)
        "\n      print('interface: ${interface.name}');",
      for (var mixin in mixins) "\n      print('mixin: ${mixin.name}');",
      for (var field in fields) "\n      print('field: ${field.name}');",
      for (var method in methods) "\n      print('method: ${method.name}');",
      for (var constructor in constructors)
        "\n      print('constructor: ${constructor.name}');",
      '''
\n      return augment super();
    }''',
    ]));
  }

  @override
  Future<void> buildDefinitionForVariable(
      VariableDeclaration variable, VariableDefinitionBuilder builder) async {
    var definingClass =
        variable is FieldDeclaration ? variable.definingClass.name : '';
    builder.augment(
      getter: DeclarationCode.fromParts([
        variable.type,
        ' get ',
        variable.name,
        ''' {
          print('parentClass: $definingClass');
          print('isExternal: ${variable.isExternal}');
          print('isFinal: ${variable.isFinal}');
          print('isLate: ${variable.isLate}');
          return augment super;
        }''',
      ]),
      setter: DeclarationCode.fromParts(
          ['set (', variable.type, ' value) { augment super(value); }']),
      initializer: variable.initializer,
    );
  }
}

FunctionBodyCode _buildFunctionAugmentation(FunctionDeclaration function) =>
    FunctionBodyCode.fromParts([
      '{\n',
      if (function is MethodDeclaration)
        "print('definingClass: ${function.definingClass.name}');\n",
      if (function is ConstructorDeclaration)
        "print('isFactory: ${function.isFactory}');\n",
      '''
      print('isAbstract: ${function.isAbstract}');
      print('isExternal: ${function.isExternal}');
      print('isGetter: ${function.isGetter}');
      print('isSetter: ${function.isSetter}');
      print('returnType: ''',
      function.returnType,
      "');\n",
      for (var param in function.positionalParameters) ...[
        "print('positionalParam: ",
        param.type,
        ' ${param.name}',
        if (param.defaultValue != null) ...[' = ', param.defaultValue!],
        "');\n",
      ],
      for (var param in function.namedParameters) ...[
        "print('namedParam: ",
        param.type,
        ' ${param.name}',
        if (param.defaultValue != null) ...[' = ', param.defaultValue!],
        "');\n",
      ],
      for (var param in function.typeParameters) ...[
        "print('typeParam: ${param.name} ",
        if (param.bounds != null) param.bounds!,
        "');\n",
      ],
      '''
      return augment super();
    }''',
    ]);

extension _ on String {
  String capitalize() => '${this[0].toUpperCase()}${this.substring(1)}';
}
