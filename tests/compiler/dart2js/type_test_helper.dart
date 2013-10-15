// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_test_helper;

import 'dart:async';
import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';
import "parser_helper.dart" show SourceString;
import "compiler_helper.dart";

GenericType instantiate(TypeDeclarationElement element,
                        List<DartType> arguments) {
  if (element.isClass()) {
    return new InterfaceType(element, new Link<DartType>.fromList(arguments));
  } else {
    assert(element.isTypedef());
    return new TypedefType(element, new Link<DartType>.fromList(arguments));
  }
}

class TypeEnvironment {
  final MockCompiler compiler;

  static Future<TypeEnvironment> create(String source) {
    var uri = new Uri(scheme: 'source');
    MockCompiler compiler = compilerFor('''
        main() {}
        $source''',
        uri,
        analyzeAll: true,
        analyzeOnly: true);
    return compiler.runCompiler(uri).then((_) {
      return new TypeEnvironment._(compiler);
    });
  }

  TypeEnvironment._(MockCompiler this.compiler);

  Element getElement(String name) {
    var element = findElement(compiler, name);
    Expect.isNotNull(element);
    if (element.isClass()) {
      element.ensureResolved(compiler);
    } else if (element.isTypedef()) {
      element.computeType(compiler);
    }
    return element;
  }

  DartType getElementType(String name) {
    return getElement(name).computeType(compiler);
  }

  DartType operator[] (String name) {
    if (name == 'dynamic') return compiler.types.dynamicType;
    if (name == 'void') return compiler.types.voidType;
    return getElementType(name);
  }

  DartType getMemberType(ClassElement element, String name) {
    Element member = element.localLookup(sourceString(name));
    return member.computeType(compiler);
  }

  bool isSubtype(DartType T, DartType S) {
    return compiler.types.isSubtype(T, S);
  }

  bool isMoreSpecific(DartType T, DartType S) {
    return compiler.types.isMoreSpecific(T, S);
  }

  SourceString sourceString(String name) => new SourceString(name);

  FunctionType functionType(DartType returnType,
                            List<DartType> parameters,
                            {List<DartType> optionalParameter,
                             Map<String,DartType> namedParameters}) {
    Link<DartType> parameterTypes =
        new Link<DartType>.fromList(parameters);
    Link<DartType> optionalParameterTypes = optionalParameter != null
        ? new Link<DartType>.fromList(optionalParameter)
        : const Link<DartType>();
    var namedParameterNames = new LinkBuilder<SourceString>();
    var namedParameterTypes = new LinkBuilder<DartType>();
    if (namedParameters != null) {
      namedParameters.forEach((String name, DartType type) {
        namedParameterNames.addLast(sourceString(name));
        namedParameterTypes.addLast(type);
      });
    }
    FunctionType type = new FunctionType(
        compiler.functionClass,
        returnType, parameterTypes, optionalParameterTypes,
        namedParameterNames.toLink(), namedParameterTypes.toLink());
  }
}
