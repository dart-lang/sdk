// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/ssa/builder.dart' as ast;
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/program_lookup.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('emission'));
    await checkTests(
        dataDir, computeAstRtiMemberEmission, computeKernelRtiMemberEmission,
        computeClassDataFromAst: computeAstRtiClassEmission,
        computeClassDataFromKernel: computeKernelRtiClassEmission,
        args: args,
        options: [
          Flags.strongMode
        ],
        skipForKernel: [
          // TODO(johnniwinther): Fix this. It triggers a crash in the ssa
          // builder.
          'runtime_type.dart',
        ]);
  });
}

class Tags {
  static const String isChecks = 'checks';
}

void computeAstRtiMemberEmission(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new RtiMemberEmissionAstComputer(
            compiler.reporter, actualMap, resolvedAst, compiler)
        .run();
  });
}

void computeAstRtiClassEmission(
    Compiler compiler, ClassEntity cls, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  new RtiClassEmissionAstComputer(compiler, actualMap).computeClassValue(cls);
}

abstract class ComputeValueMixin<T> {
  Compiler get compiler;
  ProgramLookup lookup;

  String getClassValue(ClassEntity element) {
    lookup ??= new ProgramLookup(compiler);
    Class cls = lookup.getClass(element);
    Features features = new Features();
    if (cls != null) {
      features.addElement(Tags.isChecks);
      for (StubMethod stub in cls.isChecks) {
        features.addElement(Tags.isChecks, stub.name.key);
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

class RtiClassEmissionAstComputer extends DataRegistry
    with ComputeValueMixin<ast.Node> {
  final Compiler compiler;
  final Map<Id, ActualData> actualMap;

  RtiClassEmissionAstComputer(this.compiler, this.actualMap);

  DiagnosticReporter get reporter => compiler.reporter;

  void computeClassValue(covariant ClassElement cls) {
    Id id = new ClassId(cls.name);
    registerValue(cls.sourcePosition, id, getClassValue(cls), cls);
  }
}

class RtiMemberEmissionAstComputer extends AstDataExtractor
    with ComputeValueMixin<ast.Node> {
  final Compiler compiler;

  RtiMemberEmissionAstComputer(DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap, ResolvedAst resolvedAst, this.compiler)
      : super(reporter, actualMap, resolvedAst);

  @override
  String computeElementValue(Id id, AstElement element) {
    if (element.isParameter) {
      return null;
    } else if (element.isLocal && element.isFunction) {
      LocalFunctionElement localFunction = element;
      return getMemberValue(localFunction.callMethod);
    } else {
      MemberElement member = element.declaration;
      return getMemberValue(member);
    }
  }

  @override
  String computeNodeValue(Id id, ast.Node node, [AstElement element]) {
    if (element != null && element.isLocal && element.isFunction) {
      return computeElementValue(id, element);
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
