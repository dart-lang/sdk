// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// A very simple macro that annotates functions (or getters) with no arguments
/// and adds a print statement to the top of them.
class SimpleMacro implements MethodDefinitionMacro {
  final int? x;
  final int? y;

  SimpleMacro([this.x, this.y]);

  SimpleMacro.named({this.x, this.y});

  @override
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    if (method.namedParameters
        .followedBy(method.positionalParameters)
        .isNotEmpty) {
      throw ArgumentError(
          'This macro can only be run on functions with no arguments!');
    }

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
    if (!(await staticReturnType.isExactly(classType))) {
      throw StateError(
          'The return type should not be exactly equal to the class type');
    }
    if (!(await staticReturnType.isSubtypeOf(classType))) {
      throw StateError(
          'The return type should be a subtype of the class type!');
    }

    // Test the type declaration resolver
    var parentClass =
        await builder.declarationOf(classType) as ClassDeclaration;

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
}
