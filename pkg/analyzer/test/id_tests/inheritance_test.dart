// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) {
  Directory dataDir = Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/inheritance/data'));
  return runTests<String>(
    dataDir,
    args: args,
    createUriForFileName: createUriForFileName,
    onFailure: onFailure,
    runTest:
        runTestFor(const _InheritanceDataComputer(), [analyzerDefaultConfig]),
  );
}

String supertypeToString(InterfaceType type) {
  var sb = StringBuffer();
  sb.write(type.element3.name3);
  if (type.typeArguments.isNotEmpty) {
    sb.write('<');
    var comma = '';
    for (var typeArgument in type.typeArguments) {
      sb.write(comma);
      sb.write(typeArgument.getDisplayString());
      comma = ', ';
    }
    sb.write('>');
  }
  return sb.toString();
}

class _InheritanceDataComputer extends DataComputer<String> {
  const _InheritanceDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(TestConfig config, TestingData testingData, Id id,
      List<AnalysisError> errors) {
    return errors.map((e) => e.errorCode).join(',');
  }

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    _InheritanceDataExtractor(unit.declaredFragment!.source.uri, actualMap)
        .run(unit);
  }
}

class _InheritanceDataExtractor extends AstDataExtractor<String> {
  final inheritance = InheritanceManager3();

  _InheritanceDataExtractor(super.uri, super.actualMap);

  @override
  String? computeElementValue(Id id, Element2 element) {
    return null;
  }

  @override
  void computeForClass(Declaration node, Id? id) {
    super.computeForClass(node, id);
    if (node is ClassDeclaration) {
      var element = node.declaredFragment!.element;

      void registerMember(
          MemberId id, int offset, Object object, DartType type) {
        registerValue(uri, offset, id, type.getDisplayString(), object);
      }

      var interface = inheritance.getInterface2(element);
      for (var name in interface.map2.keys) {
        var executable = interface.map2[name]!;

        var enclosingClass = executable.enclosingElement2 as InterfaceElement2;
        if (enclosingClass is ClassElement2 &&
            enclosingClass.isDartCoreObject) {
          continue;
        }

        var id = MemberId.internal(
          name.name,
          className: element.name3,
        );

        var offset = enclosingClass == element
            ? executable.firstFragment.nameOffset2
            : element.firstFragment.nameOffset2;
        offset ??= -1;

        DartType type;
        if (executable is MethodElement2) {
          type = executable.type;
        } else if (executable is GetterElement) {
          type = executable.returnType;
        } else if (executable is SetterElement) {
          type = executable.formalParameters.first.type;
        } else {
          throw UnimplementedError('(${executable.runtimeType}) $executable');
        }

        registerMember(id, offset, executable, type);
      }
    }
  }

  @override
  String? computeNodeValue(Id id, AstNode node) {
    if (node is ClassDeclaration) {
      var cls = node.declaredFragment!.element;
      var supertypes = <String>[];
      supertypes.add(supertypeToString(cls.thisType));
      for (var supertype in cls.allSupertypes) {
        supertypes.add(supertypeToString(supertype));
      }
      supertypes.sort();
      return supertypes.join(',');
    }
    return null;
  }
}
