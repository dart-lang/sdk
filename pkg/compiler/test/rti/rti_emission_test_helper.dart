// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/runtime_types.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/program_lookup.dart';

main(List<String> args) {
  runTests(args);
}

runTests(List<String> args, [int? shardIndex]) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve('emission'));
    await checkTests(dataDir, const RtiEmissionDataComputer(),
        args: args,
        shardIndex: shardIndex ?? 0,
        shards: shardIndex != null ? 4 : 1);
  });
}

class Tags {
  static const String isChecks = 'checks';
  static const String indirectInstance = 'indirectInstance';
  static const String directInstance = 'instance';
  static const String onlyForRti = 'onlyForRti';
  static const String onlyForConstructor = 'onlyForConstructor';
  static const String checkedInstance = 'checkedInstance';
  static const String typeArgument = 'typeArgument';
  static const String checkedTypeArgument = 'checkedTypeArgument';
  static const String typeLiteral = 'typeLiteral';
  static const String functionType = 'functionType';
}

mixin ComputeValueMixin {
  Compiler get compiler;
  late final ProgramLookup lookup = ProgramLookup(backendStrategy);

  JsBackendStrategy get backendStrategy => compiler.backendStrategy;

  RuntimeTypesImpl get checksBuilder =>
      backendStrategy.rtiChecksBuilderForTesting as RuntimeTypesImpl;

  String getClassValue(ClassEntity element) {
    Class? cls = lookup.getClass(element);
    Features features = Features();
    if (cls != null) {
      features.addElement(Tags.isChecks);
      for (StubMethod stub in cls.isChecks) {
        features.addElement(Tags.isChecks, stub.name!.key);
      }
      if (cls.functionTypeIndex != null) {
        features.add(Tags.functionType);
      }
      if (cls.onlyForRti) {
        features.add(Tags.onlyForRti);
      }
      if (cls.onlyForConstructor) {
        features.add(Tags.onlyForConstructor);
      }
    }
    ClassUse? classUse = checksBuilder.classUseMapForTesting![element];
    if (classUse != null) {
      if (classUse.directInstance) {
        features.add(Tags.directInstance);
      } else if (classUse.instance) {
        features.add(Tags.indirectInstance);
      }

      if (classUse.checkedInstance) {
        features.add(Tags.checkedInstance);
      }
      if (classUse.typeArgument) {
        features.add(Tags.typeArgument);
      }
      if (classUse.checkedTypeArgument) {
        features.add(Tags.checkedTypeArgument);
      }
      if (classUse.typeLiteral) {
        features.add(Tags.typeLiteral);
      }
    }
    return features.getText();
  }

  String? getMemberValue(MemberEntity member) {
    if (member.enclosingClass != null && member.enclosingClass!.isClosure) {
      return getClassValue(member.enclosingClass!);
    }
    return null;
  }
}

class RtiEmissionDataComputer extends DataComputer<String> {
  const RtiEmissionDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose = false}) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    RtiEmissionIrComputer(compiler.reporter, actualMap, elementMap, compiler,
            closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  void computeClassData(
      Compiler compiler, ClassEntity cls, Map<Id, ActualData<String>> actualMap,
      {bool verbose = false}) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    JsToElementMap elementMap = closedWorld.elementMap;
    RtiEmissionIrComputer(compiler.reporter, actualMap, elementMap, compiler,
            closedWorld.closureDataLookup)
        .computeForClass(elementMap.getClassDefinition(cls).node as ir.Class);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class RtiEmissionIrComputer extends IrDataExtractor<String>
    with ComputeValueMixin {
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;
  @override
  final Compiler compiler;

  RtiEmissionIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      this.compiler,
      this._closureDataLookup)
      : super(reporter, actualMap);

  @override
  String computeClassValue(Id id, ir.Class node) {
    return getClassValue(_elementMap.getClass(node));
  }

  @override
  String? computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String? computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info =
          _closureDataLookup.getClosureInfo(node as ir.LocalFunction);
      return getMemberValue(info.callMethod!);
    }
    return null;
  }
}
