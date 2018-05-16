// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/runtime_types.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/program_lookup.dart';

main(List<String> args) {
  asyncTest(() async {
    cacheRtiDataForTesting = true;
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('emission'));
    await checkTests(
      dataDir,
      computeKernelRtiMemberEmission,
      computeClassDataFromKernel: computeKernelRtiClassEmission,
      args: args,
      skipForStrong: [
        // Dart 1 semantics:
        'call.dart',
        'call_typed.dart',
        'call_typed_generic.dart',
        'function_subtype_call2.dart',
        'function_type_argument.dart',
        'map_literal_checked.dart',
        // TODO(johnniwinther): Optimize local function type signature need.
        'subtype_named_args.dart',
      ],
    );
  });
}

class Tags {
  static const String isChecks = 'checks';
  static const String instance = 'instance';
  static const String checkedInstance = 'checkedInstance';
  static const String typeArgument = 'typeArgument';
  static const String checkedTypeArgument = 'checkedTypeArgument';
  static const String functionType = 'functionType';
}

abstract class ComputeValueMixin<T> {
  Compiler get compiler;
  ProgramLookup lookup;

  RuntimeTypesImpl get checksBuilder =>
      compiler.backend.rtiChecksBuilderForTesting;

  String getClassValue(ClassEntity element) {
    lookup ??= new ProgramLookup(compiler);
    Class cls = lookup.getClass(element);
    Features features = new Features();
    if (cls != null) {
      features.addElement(Tags.isChecks);
      for (StubMethod stub in cls.isChecks) {
        features.addElement(Tags.isChecks, stub.name.key);
      }
      if (cls.functionTypeIndex != null) {
        features.add(Tags.functionType);
      }
    }
    ClassUse classUse = checksBuilder.classUseMapForTesting[element];
    if (classUse != null) {
      if (classUse.instance) {
        features.add(Tags.instance);
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
    }
    return features.getText();
  }

  String getMemberValue(MemberEntity member) {
    if (member.enclosingClass != null && member.enclosingClass.isClosure) {
      return getClassValue(member.enclosingClass);
    }
    return null;
  }
}

void computeKernelRtiMemberEmission(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  new RtiMemberEmissionIrComputer(
          compiler.reporter,
          actualMap,
          elementMap,
          member,
          compiler,
          backendStrategy.closureDataLookup as ClosureDataLookup<ir.Node>)
      .run(definition.node);
}

void computeKernelRtiClassEmission(
    Compiler compiler, ClassEntity cls, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  new RtiClassEmissionIrComputer(compiler, elementMap, actualMap)
      .computeClassValue(cls);
}

class RtiClassEmissionIrComputer extends DataRegistry
    with ComputeValueMixin<ir.Node> {
  final Compiler compiler;
  final KernelToElementMapForBuilding _elementMap;
  final Map<Id, ActualData> actualMap;

  RtiClassEmissionIrComputer(this.compiler, this._elementMap, this.actualMap);

  DiagnosticReporter get reporter => compiler.reporter;

  void computeClassValue(ClassEntity cls) {
    Id id = new ClassId(cls.name);
    ir.TreeNode node = _elementMap.getClassDefinition(cls).node;
    registerValue(
        computeSourceSpanFromTreeNode(node), id, getClassValue(cls), cls);
  }
}

class RtiMemberEmissionIrComputer extends IrDataExtractor
    with ComputeValueMixin<ir.Node> {
  final KernelToElementMapForBuilding _elementMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;
  final Compiler compiler;

  RtiMemberEmissionIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap,
      this._elementMap,
      MemberEntity member,
      this.compiler,
      this._closureDataLookup)
      : super(reporter, actualMap);

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
