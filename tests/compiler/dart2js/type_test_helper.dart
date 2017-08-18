// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_test_helper;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/elements.dart'
    show Element, MemberElement, ClassElement, LibraryElement, TypedefElement;
import 'package:compiler/src/world.dart' show ClosedWorld;
import 'compiler_helper.dart' as mock;
import 'memory_compiler.dart' as memory;
import 'kernel/compiler_helper.dart' as dill;

DartType instantiate(Entity element, List<DartType> arguments) {
  if (element is ClassElement) {
    return new ResolutionInterfaceType(element, arguments);
  } else if (element is ClassEntity) {
    return new InterfaceType(element, arguments);
  } else {
    assert(element is TypedefElement);
    return new ResolutionTypedefType(element, arguments);
  }
}

enum CompileMode { mock, memory, dill }

class TypeEnvironment {
  final Compiler compiler;

  Resolution get resolution => compiler.resolution;

  Types get types => resolution.types;

  static Future<TypeEnvironment> create(String source,
      {CompileMode compileMode: CompileMode.mock,
      bool useDillCompiler: false,
      bool expectNoErrors: false,
      bool expectNoWarningsOrErrors: false,
      bool stopAfterTypeInference: false,
      String mainSource}) async {
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
    if (compileMode == CompileMode.dill) {
      collector = new memory.DiagnosticCollector();
      uri = Uri.parse('memory:main.dart');
      compiler = await dill.compileWithDill(
          entryPoint: uri,
          memorySourceFiles: {'main.dart': source},
          diagnosticHandler: collector,
          options: stopAfterTypeInference
              ? [Flags.disableTypeInference]
              : [
                  Flags.disableTypeInference,
                  Flags.analyzeAll,
                  Flags.analyzeOnly
                ],
          beforeRun: (Compiler compiler) {
            compiler.stopAfterTypeInference = stopAfterTypeInference;
          });
    } else {
      if (compileMode == CompileMode.mock) {
        uri = new Uri(scheme: 'source');
        mock.MockCompiler mockCompiler = mock.compilerFor(source, uri,
            analyzeAll: !stopAfterTypeInference,
            analyzeOnly: !stopAfterTypeInference);
        mockCompiler.diagnosticHandler =
            mock.createHandler(mockCompiler, source);
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
                ? []
                : [Flags.analyzeAll, Flags.analyzeOnly]);
      }
      compiler.stopAfterTypeInference = stopAfterTypeInference;
      await compiler.run(uri);
    }
    if (expectNoErrors || expectNoWarningsOrErrors) {
      var errors = collector.errors;
      Expect.isTrue(errors.isEmpty, 'Unexpected errors: ${errors}');
    }
    if (expectNoWarningsOrErrors) {
      var warnings = collector.warnings;
      Expect.isTrue(warnings.isEmpty, 'Unexpected warnings: ${warnings}');
    }
    return new TypeEnvironment._(compiler);
  }

  TypeEnvironment._(Compiler this.compiler);

  Element getElement(String name) {
    LibraryElement mainApp =
        compiler.frontendStrategy.elementEnvironment.mainLibrary;
    dynamic element = mainApp.find(name);
    Expect.isNotNull(element);
    if (element.isClass) {
      element.ensureResolved(compiler.resolution);
    } else if (element.isTypedef) {
      element.computeType(compiler.resolution);
    }
    return element;
  }

  ClassEntity getClass(String name) {
    LibraryEntity mainLibrary =
        compiler.frontendStrategy.elementEnvironment.mainLibrary;
    ClassEntity element = compiler.frontendStrategy.elementEnvironment
        .lookupClass(mainLibrary, name);
    Expect.isNotNull(element);
    if (element is ClassElement) {
      element.ensureResolved(compiler.resolution);
    }
    return element;
  }

  ResolutionDartType getElementType(String name) {
    dynamic element = getElement(name);
    return element.computeType(compiler.resolution);
  }

  ResolutionDartType operator [](String name) {
    if (name == 'dynamic') return const ResolutionDynamicType();
    if (name == 'void') return const ResolutionVoidType();
    return getElementType(name);
  }

  ResolutionDartType getMemberType(ClassElement element, String name) {
    MemberElement member = element.localLookup(name);
    return member.computeType(compiler.resolution);
  }

  bool isSubtype(ResolutionDartType T, ResolutionDartType S) {
    return types.isSubtype(T, S);
  }

  bool isMoreSpecific(ResolutionDartType T, ResolutionDartType S) {
    return types.isMoreSpecific(T, S);
  }

  ResolutionDartType computeLeastUpperBound(
      ResolutionDartType T, ResolutionDartType S) {
    return types.computeLeastUpperBound(T, S);
  }

  ResolutionDartType flatten(ResolutionDartType T) {
    return types.flatten(T);
  }

  ResolutionFunctionType functionType(
      ResolutionDartType returnType, List<ResolutionDartType> parameters,
      {List<ResolutionDartType> optionalParameters:
          const <ResolutionDartType>[],
      Map<String, ResolutionDartType> namedParameters}) {
    List<String> namedParameterNames = <String>[];
    List<ResolutionDartType> namedParameterTypes = <ResolutionDartType>[];
    if (namedParameters != null) {
      namedParameters.forEach((String name, ResolutionDartType type) {
        namedParameterNames.add(name);
        namedParameterTypes.add(type);
      });
    }
    return new ResolutionFunctionType.synthesized(returnType, parameters,
        optionalParameters, namedParameterNames, namedParameterTypes);
  }

  ClosedWorld get closedWorld {
    return compiler.resolutionWorldBuilder.closedWorldForTesting;
  }
}
