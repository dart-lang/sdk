// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_test_helper;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/elements.dart'
    show ClassElement, LibraryElement, TypedefElement;
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;
import 'compiler_helper.dart' as mock;
import 'compiler_helper.dart' show CompileMode;
import 'memory_compiler.dart' as memory;
import 'kernel/compiler_helper.dart' as dill;

export 'compiler_helper.dart' show CompileMode;

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

class TypeEnvironment {
  final Compiler compiler;
  final bool testBackendWorld;

  Resolution get resolution => compiler.resolution;

  static Future<TypeEnvironment> create(String source,
      {CompileMode compileMode: CompileMode.mock,
      bool useDillCompiler: false,
      bool expectNoErrors: false,
      bool expectNoWarningsOrErrors: false,
      bool stopAfterTypeInference: false,
      String mainSource,
      bool testBackendWorld: false,
      List<String> options: const <String>[],
      Map<String, String> fieldTypeMap: const <String, String>{}}) async {
    Uri uri;
    Compiler compiler;
    if (mainSource != null) {
      stopAfterTypeInference = true;
    }
    if (testBackendWorld) {
      stopAfterTypeInference = true;
      assert(mainSource != null);
    }
    if (mainSource == null) {
      source = '''import 'dart:async';
                  main() {}
                  $source''';
    } else {
      source = '$mainSource\n$source';
    }
    memory.DiagnosticCollector collector;
    if (compileMode == CompileMode.kernel) {
      collector = new memory.DiagnosticCollector();
      uri = Uri.parse('memory:main.dart');
      compiler = await dill.compileWithDill(
          entryPoint: uri,
          memorySourceFiles: {'main.dart': source},
          diagnosticHandler: collector,
          options: stopAfterTypeInference
              ? ([Flags.disableTypeInference]..addAll(options))
              : ([
                  Flags.disableTypeInference,
                  Flags.analyzeAll,
                  Flags.analyzeOnly
                ]..addAll(options)),
          beforeRun: (Compiler compiler) {
            compiler.stopAfterTypeInference = stopAfterTypeInference;
          });
    } else {
      if (compileMode == CompileMode.mock) {
        uri = new Uri(scheme: 'source');
        mock.MockCompiler mockCompiler = mock.mockCompilerFor(source, uri,
            analyzeAll: !stopAfterTypeInference,
            analyzeOnly: !stopAfterTypeInference);
        mockCompiler.diagnosticHandler =
            mock.createHandler(mockCompiler, source);
        collector = mockCompiler.diagnosticCollector;
        compiler = mockCompiler;
        compiler.stopAfterTypeInference = stopAfterTypeInference;
        await compiler.run(uri);
      } else {
        collector = new memory.DiagnosticCollector();
        uri = Uri.parse('memory:main.dart');
        memory.CompilationResult result = await memory.runCompiler(
            entryPoint: uri,
            memorySourceFiles: {'main.dart': source},
            diagnosticHandler: collector,
            options: stopAfterTypeInference
                ? ([Flags.useOldFrontend]..addAll(options))
                : ([Flags.useOldFrontend, Flags.analyzeAll, Flags.analyzeOnly]
                  ..addAll(options)),
            beforeRun: (compiler) {
              compiler.stopAfterTypeInference = stopAfterTypeInference;
            });
        compiler = result.compiler;
      }
    }
    if (expectNoErrors || expectNoWarningsOrErrors) {
      var errors = collector.errors;
      Expect.isTrue(errors.isEmpty, 'Unexpected errors: ${errors}');
    }
    if (expectNoWarningsOrErrors) {
      var warnings = collector.warnings;
      Expect.isTrue(warnings.isEmpty, 'Unexpected warnings: ${warnings}');
    }
    return new TypeEnvironment._(compiler, testBackendWorld: testBackendWorld);
  }

  TypeEnvironment._(Compiler this.compiler, {this.testBackendWorld: false});

  ElementEnvironment get elementEnvironment {
    if (testBackendWorld) {
      return compiler.backendClosedWorldForTesting.elementEnvironment;
    } else {
      return compiler.frontendStrategy.elementEnvironment;
    }
  }

  CommonElements get commonElements {
    if (testBackendWorld) {
      return compiler.backendClosedWorldForTesting.commonElements;
    } else {
      return compiler.frontendStrategy.commonElements;
    }
  }

  DartTypes get types {
    if (resolution != null) {
      return resolution.types;
    } else {
      if (testBackendWorld) {
        return compiler.backendClosedWorldForTesting.dartTypes;
      } else {
        KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
        return frontendStrategy.elementMap.types;
      }
    }
  }

  Entity getElement(String name) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    dynamic element = elementEnvironment.lookupLibraryMember(mainLibrary, name);
    element ??= elementEnvironment.lookupClass(mainLibrary, name);
    element ??=
        elementEnvironment.lookupClass(commonElements.coreLibrary, name);
    if (element == null && mainLibrary is LibraryElement) {
      element = mainLibrary.find(name);
    }
    Expect.isNotNull(element, "No element named '$name' found.");
    if (element is ClassElement) {
      element.ensureResolved(compiler.resolution);
    } else if (element is TypedefElement) {
      element.computeType(compiler.resolution);
    }
    return element;
  }

  ClassEntity getClass(String name) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    ClassEntity element = elementEnvironment.lookupClass(mainLibrary, name);
    Expect.isNotNull(element, "No class named '$name' found.");
    if (element is ClassElement) {
      element.ensureResolved(compiler.resolution);
    }
    return element;
  }

  DartType getElementType(String name) {
    dynamic element = getElement(name);
    if (element is FieldEntity) {
      return elementEnvironment.getFieldType(element);
    } else if (element is FunctionEntity) {
      return elementEnvironment.getFunctionType(element);
    } else if (element is ClassEntity) {
      return elementEnvironment.getThisType(element);
    } else {
      /// ignore: undefined_method
      return element.computeType(compiler.resolution);
    }
  }

  DartType operator [](String name) {
    if (name == 'dynamic') {
      if (resolution != null) {
        return const ResolutionDynamicType();
      } else {
        return const DynamicType();
      }
    }
    if (name == 'void') {
      if (resolution != null) {
        return const ResolutionVoidType();
      } else {
        return const VoidType();
      }
    }
    return getElementType(name);
  }

  MemberEntity _getMember(String name, [ClassEntity cls]) {
    if (cls != null) {
      return elementEnvironment.lookupLocalClassMember(cls, name);
    } else {
      LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
      return elementEnvironment.lookupLibraryMember(mainLibrary, name);
    }
  }

  DartType getMemberType(String name, [ClassEntity cls]) {
    MemberEntity member = _getMember(name, cls);
    if (member is FieldEntity) {
      return elementEnvironment.getFieldType(member);
    } else if (member is FunctionEntity) {
      return elementEnvironment.getFunctionType(member);
    }
    throw 'Unexpected member: $member';
  }

  DartType getClosureType(String name, [ClassEntity cls]) {
    if (testBackendWorld) {
      throw new UnsupportedError(
          "getClosureType not supported for backend testing.");
    }
    MemberEntity member = _getMember(name, cls);
    DartType type;
    compiler.resolutionWorldBuilder
        .forEachLocalFunction((MemberEntity m, Local local) {
      if (member == m) {
        type ??= elementEnvironment.getLocalFunctionType(local);
      }
    });
    return type;
  }

  DartType getFieldType(String name) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    FieldEntity field =
        elementEnvironment.lookupLibraryMember(mainLibrary, name);
    Expect.isNotNull(field);
    return elementEnvironment.getFieldType(field);
  }

  bool isSubtype(DartType T, DartType S) {
    return types.isSubtype(T, S);
  }

  bool isMoreSpecific(ResolutionDartType T, ResolutionDartType S) {
    return (types as Types).isMoreSpecific(T, S);
  }

  ResolutionDartType computeLeastUpperBound(
      ResolutionDartType T, ResolutionDartType S) {
    return (types as Types).computeLeastUpperBound(T, S);
  }

  ResolutionDartType flatten(ResolutionDartType T) {
    return (types as Types).flatten(T);
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
    if (testBackendWorld) {
      return compiler.backendClosedWorldForTesting;
    } else {
      return compiler.resolutionWorldBuilder.closedWorldForTesting;
    }
  }
}

/// Data used to create a function type either as method declaration or a
/// typedef declaration.
class FunctionTypeData {
  final String returnType;
  final String name;
  final String parameters;

  const FunctionTypeData(this.returnType, this.name, this.parameters);

  String toString() => '$returnType $name$parameters';
}

/// Return source code that declares the function types in [dataList] as
/// method declarations of the form:
///
///     $returnType $name$parameters => null;
String createMethods(List<FunctionTypeData> dataList,
    {String additionalData: '', String prefix: ''}) {
  StringBuffer sb = new StringBuffer();
  for (FunctionTypeData data in dataList) {
    sb.writeln(
        '${data.returnType} $prefix${data.name}${data.parameters} => null;');
  }
  sb.write(additionalData);
  return sb.toString();
}

/// Return source code that declares the function types in [dataList] as
/// typedefs of the form:
///
///     typedef fx = $returnType Function$parameters;
///     fx $name;
///
/// where a field using the typedef is add to make the type accessible by name.
String createTypedefs(List<FunctionTypeData> dataList,
    {String additionalData: '', String prefix: ''}) {
  StringBuffer sb = new StringBuffer();
  for (int index = 0; index < dataList.length; index++) {
    FunctionTypeData data = dataList[index];
    sb.writeln(
        'typedef f$index = ${data.returnType} Function${data.parameters};');
  }
  for (int index = 0; index < dataList.length; index++) {
    FunctionTypeData data = dataList[index];
    sb.writeln('f$index $prefix${data.name};');
  }
  sb.write(additionalData);
  return sb.toString();
}
