// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library type_test_helper;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/kelements.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/world.dart' show JClosedWorld, KClosedWorld;
import 'memory_compiler.dart' as memory;

extension DartTypeHelpers on DartType {
  T withoutNullabilityAs<T extends DartType>() => withoutNullability as T;
}

DartType instantiate(
    DartTypes dartTypes, ClassEntity element, List<DartType> arguments) {
  return dartTypes.interfaceType(element, arguments);
}

class TypeEnvironment {
  final Compiler compiler;
  final bool testBackendWorld;

  static Future<TypeEnvironment> create(String source,
      {bool expectNoErrors: false,
      bool expectNoWarningsOrErrors: false,
      bool testBackendWorld: false,
      List<String> options: const <String>[],
      Map<String, String> fieldTypeMap: const <String, String>{}}) async {
    memory.DiagnosticCollector collector = new memory.DiagnosticCollector();
    Uri uri = Uri.parse('memory:main.dart');
    memory.CompilationResult result = await memory.runCompiler(
        entryPoint: uri,
        memorySourceFiles: {'main.dart': source},
        options: [Flags.disableTypeInference]..addAll(options),
        diagnosticHandler: collector,
        beforeRun: (compiler) {
          compiler.stopAfterTypeInference = true;
        });
    Compiler compiler = result.compiler;
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

  DartType legacyWrap(DartType type) {
    return options.useLegacySubtyping ? types.legacyType(type) : type;
  }

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

  CompilerOptions get options => compiler.options;

  DartTypes get types {
    if (testBackendWorld) {
      return compiler.backendClosedWorldForTesting.dartTypes;
    } else {
      KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
      return frontendStrategy.elementMap.types;
    }
  }

  Entity getElement(String name) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    dynamic element = elementEnvironment.lookupLibraryMember(mainLibrary, name);
    element ??= elementEnvironment.lookupClass(mainLibrary, name);
    element ??=
        elementEnvironment.lookupClass(commonElements.coreLibrary, name);
    Expect.isNotNull(element, "No element named '$name' found.");
    return element;
  }

  ClassEntity getClass(String name) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    ClassEntity element = elementEnvironment.lookupClass(mainLibrary, name);
    Expect.isNotNull(element, "No class named '$name' found.");
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
      throw 'Unexpected element $element';
    }
  }

  DartType operator [](String name) {
    if (name == 'dynamic') {
      return types.dynamicType();
    }
    if (name == 'void') {
      return types.voidType();
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
    throw 'Unexpected member: $member for ${name}, cls=$cls';
  }

  DartType getClosureType(String name, [ClassEntity cls]) {
    if (testBackendWorld) {
      throw new UnsupportedError(
          "getClosureType not supported for backend testing.");
    }
    MemberEntity member = _getMember(name, cls);
    DartType type;

    for (KLocalFunction local
        in compiler.frontendClosedWorldForTesting.localFunctions) {
      if (local.memberContext == member) {
        type ??= elementEnvironment.getLocalFunctionType(local);
      }
    }
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

  bool isPotentialSubtype(DartType T, DartType S) {
    return types.isPotentialSubtype(T, S);
  }

  JClosedWorld get jClosedWorld {
    assert(testBackendWorld);
    return compiler.backendClosedWorldForTesting;
  }

  KClosedWorld get kClosedWorld {
    assert(!testBackendWorld);
    return compiler.frontendClosedWorldForTesting;
  }

  String printType(DartType type) => type.toStructuredText(types, options);

  List<String> printTypes(List<DartType> types) =>
      types.map(printType).toList();

  DartType instantiate(ClassEntity element, List<DartType> arguments) =>
      types.interfaceType(element, arguments.map(legacyWrap).toList());
}

/// Data used to create a function type either as method declaration or a
/// typedef declaration.
class FunctionTypeData {
  final String returnType;
  final String name;
  final String parameters;

  const FunctionTypeData(this.returnType, this.name, this.parameters);

  @override
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

/// Return source code that uses the function types in [dataList].
String createUses(List<FunctionTypeData> dataList, {String prefix: ''}) {
  StringBuffer sb = new StringBuffer();
  for (int index = 0; index < dataList.length; index++) {
    FunctionTypeData data = dataList[index];
    sb.writeln('$prefix${data.name};');
  }
  return sb.toString();
}
