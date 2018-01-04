// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:compiler/src/js_backend/runtime_types.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/ssa/builder.dart' as ast;
import 'package:compiler/src/universe/world_builder.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, computeAstRtiNeed, computeKernelRtiNeed,
        args: args);
  });
}

/// Compute RTI need data for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data.
void computeAstRtiNeed(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false, bool forBackend}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new RtiNeedAstComputer(compiler.reporter, actualMap, resolvedAst, compiler)
        .run();
  });
}

abstract class ComputeValueMixin<T> {
  Compiler get compiler;

  ResolutionWorldBuilder get resolutionWorldBuilder =>
      compiler.resolutionWorldBuilder;
  RuntimeTypesNeedBuilderImpl get rtiNeedBuilder =>
      compiler.frontendStrategy.runtimeTypesNeedBuilderForTesting;
  RuntimeTypesNeed get rtiNeed => compiler.backendClosedWorldForTesting.rtiNeed;

  MemberEntity getFrontendMember(MemberEntity member);
  Local getFrontendClosure(MemberEntity member);

  String getMemberValue(MemberEntity backendMember) {
    MemberEntity frontendMember = getFrontendMember(backendMember);
    Local frontendClosure = getFrontendClosure(backendMember);

    StringBuffer sb = new StringBuffer();
    String comma = '';

    void findChecks(String prefix, Entity entity, Set<DartType> checks) {
      Set<DartType> types = new Set<DartType>();
      FindTypeVisitor finder = new FindTypeVisitor(entity);
      for (DartType type in checks) {
        if (type.accept(finder, null)) {
          types.add(type);
        }
      }
      List<String> list = types.map((t) => t.toString()).toList()..sort();
      if (list.isNotEmpty) {
        sb.write('${comma}$prefix=[${list.join('')}]');
        comma = ',';
      }
    }

    if (backendMember is ConstructorEntity &&
        backendMember.isGenerativeConstructor) {
      ClassEntity backendClass = backendMember.enclosingClass;
      if (rtiNeed.classNeedsRti(backendClass)) {
        sb.write('${comma}classNeedsRti');
        comma = ',';
      }
      ClassEntity frontendClass = frontendMember?.enclosingClass;
      Iterable<String> dependencies;
      if (rtiNeedBuilder.rtiDependencies.containsKey(frontendClass)) {
        dependencies = rtiNeedBuilder.rtiDependencies[frontendClass]
            .map((d) => d.name)
            .toList()
              ..sort();
      }
      if (dependencies != null && dependencies.isNotEmpty) {
        sb.write('${comma}deps=[${dependencies.join(',')}]');
        comma = ',';
      }
      if (rtiNeedBuilder.classesUsingTypeVariableExpression
          .contains(frontendClass)) {
        sb.write('${comma}exp');
        comma = ',';
      }
      if (rtiNeedBuilder.classesUsingTypeVariableTests
          .contains(frontendClass)) {
        sb.write('${comma}test');
        comma = ',';
      }
      findChecks('explicit', frontendClass, rtiNeedBuilder.isChecks);
      findChecks('implicit', frontendClass, rtiNeedBuilder.implicitIsChecks);
    }
    if (backendMember is FunctionEntity) {
      if (rtiNeed.methodNeedsRti(backendMember)) {
        sb.write('${comma}methodNeedsRti');
        comma = ',';
      }
      if (frontendClosure != null &&
          rtiNeed.localFunctionNeedsRti(frontendClosure)) {
        sb.write('${comma}methodNeedsRti');
        comma = ',';
      }
      findChecks('explicit', frontendMember, rtiNeedBuilder.isChecks);
      findChecks('implicit', frontendMember, rtiNeedBuilder.implicitIsChecks);
    }
    return sb.toString();
  }
}

/// Visitor that determines whether a type refers to [entity].
class FindTypeVisitor extends BaseDartTypeVisitor<bool, Null> {
  final Entity entity;

  FindTypeVisitor(this.entity);

  bool visitTypes(List<DartType> types) {
    for (DartType type in types) {
      if (type.accept(this, null)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitType(DartType type, _) => false;

  @override
  bool visitInterfaceType(InterfaceType type, _) {
    if (type.element == entity) return true;
    return visitTypes(type.typeArguments);
  }

  @override
  bool visitFunctionType(FunctionType type, _) {
    if (type.returnType.accept(this, null)) return true;
    if (visitTypes(type.typeVariables)) return true;
    if (visitTypes(type.parameterTypes)) return true;
    if (visitTypes(type.optionalParameterTypes)) return true;
    if (visitTypes(type.namedParameterTypes)) return true;
    return false;
  }

  @override
  bool visitTypeVariableType(TypeVariableType type, _) {
    return type.element.typeDeclaration == entity;
  }
}

/// AST visitor for computing inlining data for a member.
class RtiNeedAstComputer extends AstDataExtractor
    with ComputeValueMixin<ast.Node> {
  final Compiler compiler;

  RtiNeedAstComputer(DiagnosticReporter reporter, Map<Id, ActualData> actualMap,
      ResolvedAst resolvedAst, this.compiler)
      : super(reporter, actualMap, resolvedAst);

  @override
  MemberEntity getFrontendMember(MemberEntity member) {
    return member;
  }

  @override
  Local getFrontendClosure(MemberEntity member) {
    if (member is SynthesizedCallMethodElementX) return member.expression;
    return null;
  }

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

/// Compute RTI need data for [member] from the new frontend.
///
/// Fills [actualMap] with the data.
void computeKernelRtiNeed(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false, bool forBackend}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  new RtiNeedIrComputer(
          compiler.reporter,
          actualMap,
          elementMap,
          member,
          compiler,
          backendStrategy.closureDataLookup as ClosureDataLookup<ir.Node>)
      .run(definition.node);
}

/// AST visitor for computing inference data for a member.
class RtiNeedIrComputer extends IrDataExtractor
    with ComputeValueMixin<ir.Node> {
  final KernelToElementMapForBuilding _elementMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;
  final Compiler compiler;

  RtiNeedIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap,
      this._elementMap,
      MemberEntity member,
      this.compiler,
      this._closureDataLookup)
      : super(reporter, actualMap);

  @override
  MemberEntity getFrontendMember(MemberEntity backendMember) {
    ElementEnvironment elementEnvironment = compiler
        .resolutionWorldBuilder.closedWorldForTesting.elementEnvironment;
    LibraryEntity frontendLibrary =
        elementEnvironment.lookupLibrary(backendMember.library.canonicalUri);
    if (backendMember.enclosingClass != null) {
      if (backendMember.enclosingClass.isClosure) return null;
      ClassEntity frontendClass = elementEnvironment.lookupClass(
          frontendLibrary, backendMember.enclosingClass.name);
      if (backendMember is ConstructorEntity) {
        return elementEnvironment.lookupConstructor(
            frontendClass, backendMember.name);
      } else {
        return elementEnvironment.lookupClassMember(
            frontendClass, backendMember.name,
            setter: backendMember.isSetter);
      }
    }
    return elementEnvironment.lookupLibraryMember(
        frontendLibrary, backendMember.name,
        setter: backendMember.isSetter);
  }

  @override
  Local getFrontendClosure(MemberEntity member) => null;

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
