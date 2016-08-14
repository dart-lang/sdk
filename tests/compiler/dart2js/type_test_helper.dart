// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_test_helper;

import 'dart:async';
import 'package:expect/expect.dart';
import 'compiler_helper.dart' as mock;
import 'memory_compiler.dart' as memory;
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/compiler.dart'
    show Compiler;
import 'package:compiler/src/elements/elements.dart'
    show Element,
         MemberElement,
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

  Resolution get resolution => compiler.resolution;

  static Future<TypeEnvironment> create(
      String source, {bool useMockCompiler: true,
                      bool expectNoErrors: false,
                      bool expectNoWarningsOrErrors: false,
                      bool stopAfterTypeInference: false,
                      String mainSource}) {
    Uri uri;
    Compiler compiler;
    bool stopAfterTypeInference = mainSource != null;
    if (mainSource == null) {
      source = '''import 'dart:async';
                  main() {}
                  $source''';
    } else {
      source = '$mainSource\n$source';
    }
    memory.DiagnosticCollector collector;
    if (useMockCompiler) {
      uri = new Uri(scheme: 'source');
      mock.MockCompiler mockCompiler = mock.compilerFor(
          source,
          uri,
          analyzeAll: !stopAfterTypeInference,
          analyzeOnly: !stopAfterTypeInference);
      mockCompiler.diagnosticHandler = mock.createHandler(mockCompiler, source);
      collector = mockCompiler.diagnosticCollector;
      compiler = mockCompiler;
    } else {
      collector = new memory.DiagnosticCollector();
      uri = Uri.parse('memory:main.dart');
      compiler = memory.compilerFor(
          entryPoint: uri,
          memorySourceFiles: {'main.dart': source},
          diagnosticHandler: collector,
          options: stopAfterTypeInference
              ? [] : [Flags.analyzeAll, Flags.analyzeOnly]);
    }
    compiler.stopAfterTypeInference = stopAfterTypeInference;
    return compiler.run(uri).then((_) {
      if (expectNoErrors || expectNoWarningsOrErrors) {
        var errors = collector.errors;
        Expect.isTrue(errors.isEmpty,
            'Unexpected errors: ${errors}');
      }
      if (expectNoWarningsOrErrors) {
        var warnings = collector.warnings;
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
      element.ensureResolved(compiler.resolution);
    } else if (element.isTypedef) {
      element.computeType(compiler.resolution);
    }
    return element;
  }

  DartType getElementType(String name) {
    var element = getElement(name);
    return element.computeType(compiler.resolution);
  }

  DartType operator[] (String name) {
    if (name == 'dynamic') return const DynamicType();
    if (name == 'void') return const VoidType();
    return getElementType(name);
  }

  DartType getMemberType(ClassElement element, String name) {
    MemberElement member = element.localLookup(name);
    return member.computeType(compiler.resolution);
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

  DartType flatten(DartType T) {
    return compiler.types.flatten(T);
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
