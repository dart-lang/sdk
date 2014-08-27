// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_test_helper;

import 'dart:async';
import 'package:expect/expect.dart';
import 'compiler_helper.dart' as mock;
import 'memory_compiler.dart' as memory;
import 'package:compiler/implementation/dart_types.dart';
import 'package:compiler/implementation/dart2jslib.dart'
    show Compiler;
import 'package:compiler/implementation/elements/elements.dart'
    show Element,
         TypeDeclarationElement,
         ClassElement;

GenericType instantiate(TypeDeclarationElement element,
                        List<DartType> arguments) {
  if (element.isClass) {
    return new InterfaceType(element, arguments);
  } else {
    assert(element.isTypedef);
    return new TypedefType(element, arguments);
  }
}

class TypeEnvironment {
  final Compiler compiler;

  static Future<TypeEnvironment> create(
      String source, {bool useMockCompiler: true,
                      bool expectNoErrors: false,
                      bool expectNoWarningsOrErrors: false,
                      bool stopAfterTypeInference: false,
                      String mainSource}) {
    Uri uri;
    Function getErrors;
    Function getWarnings;
    Compiler compiler;
    bool stopAfterTypeInference = mainSource != null;
    if (mainSource == null) {
      source = 'main() {}\n$source';
    } else {
      source = '$mainSource\n$source';
    }
    if (useMockCompiler) {
      uri = new Uri(scheme: 'source');
      mock.MockCompiler mockCompiler = mock.compilerFor(
          source,
          uri,
          analyzeAll: !stopAfterTypeInference,
          analyzeOnly: !stopAfterTypeInference);
      getErrors = () => mockCompiler.errors;
      getWarnings = () => mockCompiler.warnings;
      compiler = mockCompiler;
    } else {
      memory.DiagnosticCollector collector = new memory.DiagnosticCollector();
      uri = Uri.parse('memory:main.dart');
      compiler = memory.compilerFor(
          {'main.dart': source},
          diagnosticHandler: collector,
          options: stopAfterTypeInference 
              ? [] : ['--analyze-all', '--analyze-only']);
      getErrors = () => collector.errors;
      getWarnings = () => collector.warnings;
    }
    compiler.stopAfterTypeInference = stopAfterTypeInference;
    return compiler.runCompiler(uri).then((_) {
      if (expectNoErrors || expectNoWarningsOrErrors) {
        var errors = getErrors();
        Expect.isTrue(errors.isEmpty,
            'Unexpected errors: ${errors}');
      }
      if (expectNoWarningsOrErrors) {
        var warnings = getWarnings();
        Expect.isTrue(warnings.isEmpty,
            'Unexpected warnings: ${warnings}');
      }
      return new TypeEnvironment._(compiler);
    });
  }

  TypeEnvironment._(Compiler this.compiler);

  Element getElement(String name) {
    var element = compiler.mainApp.find(name);
    Expect.isNotNull(element);
    if (element.isClass) {
      element.ensureResolved(compiler);
    } else if (element.isTypedef) {
      element.computeType(compiler);
    }
    return element;
  }

  DartType getElementType(String name) {
    return getElement(name).computeType(compiler);
  }

  DartType operator[] (String name) {
    if (name == 'dynamic') return const DynamicType();
    if (name == 'void') return const VoidType();
    return getElementType(name);
  }

  DartType getMemberType(ClassElement element, String name) {
    Element member = element.localLookup(name);
    return member.computeType(compiler);
  }

  bool isSubtype(DartType T, DartType S) {
    return compiler.types.isSubtype(T, S);
  }

  bool isMoreSpecific(DartType T, DartType S) {
    return compiler.types.isMoreSpecific(T, S);
  }

  DartType computeLeastUpperBound(DartType T, DartType S) {
    return compiler.types.computeLeastUpperBound(T, S);
  }

  FunctionType functionType(DartType returnType,
                            List<DartType> parameters,
                            {List<DartType> optionalParameters:
                                 const <DartType>[],
                             Map<String,DartType> namedParameters}) {
    List<String> namedParameterNames = <String>[];
    List<DartType> namedParameterTypes = <DartType>[];
    if (namedParameters != null) {
      namedParameters.forEach((String name, DartType type) {
        namedParameterNames.add(name);
        namedParameterTypes.add(type);
      });
    }
    return new FunctionType.synthesized(
        returnType, parameters, optionalParameters,
        namedParameterNames, namedParameterTypes);
  }
}
