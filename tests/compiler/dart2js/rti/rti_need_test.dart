// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/commandline_options.dart';
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
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/ssa/builder.dart' as ast;
import 'package:compiler/src/universe/world_builder.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/check_helpers.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(
        dataDir, computeAstRtiMemberNeed, computeKernelRtiMemberNeed,
        computeClassDataFromAst: computeAstRtiClassNeed,
        computeClassDataFromKernel: computeKernelRtiClassNeed,
        args: args,
        options: [Flags.strongMode]);
  });
}

/// Compute RTI need data for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data.
void computeAstRtiMemberNeed(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  compiler.reporter.withCurrentElement(member.implementation, () {
    new RtiMemberNeedAstComputer(
            compiler.reporter, actualMap, resolvedAst, compiler)
        .run();
  });
}

/// Compute RTI need data for [cls] from the old frontend.
///
/// Fills [actualMap] with the data.
void computeAstRtiClassNeed(
    Compiler compiler, ClassEntity cls, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  new RtiClassNeedAstComputer(compiler, actualMap).computeClassValue(cls);
}

abstract class ComputeValueMixin<T> {
  Compiler get compiler;

  ResolutionWorldBuilder get resolutionWorldBuilder =>
      compiler.resolutionWorldBuilder;
  RuntimeTypesNeedBuilderImpl get rtiNeedBuilder =>
      compiler.frontendStrategy.runtimeTypesNeedBuilderForTesting;
  RuntimeTypesNeed get rtiNeed => compiler.backendClosedWorldForTesting.rtiNeed;
  RuntimeTypesChecks get rtiChecks =>
      compiler.backend.emitter.typeTestRegistry.rtiChecks;
  TypeChecks get requiredChecks =>
      // TODO(johnniwinther): This should have been
      //   rtiChecks.requiredChecks;
      // but it is incomplete and extended? by this:
      compiler.backend.emitter.typeTestRegistry.requiredChecks;
  ClassEntity getFrontendClass(ClassEntity cls);
  MemberEntity getFrontendMember(MemberEntity member);
  Local getFrontendClosure(MemberEntity member);

  String findChecks(StringBuffer sb, String comma, String prefix, Entity entity,
      Set<DartType> checks) {
    Set<DartType> types = new Set<DartType>();
    FindTypeVisitor finder = new FindTypeVisitor(entity);
    for (DartType type in checks) {
      if (type.accept(finder, null)) {
        types.add(type);
      }
    }
    List<String> list = types.map(typeToString).toList()..sort();
    if (list.isNotEmpty) {
      sb.write('${comma}$prefix=[${list.join(',')}]');
      comma = ',';
    }
    return comma;
  }

  String findDependencies(StringBuffer sb, String comma, Entity entity) {
    Iterable<String> dependencies;
    if (rtiNeedBuilder.typeVariableTests.typeArgumentDependencies
        .containsKey(entity)) {
      dependencies = rtiNeedBuilder
          .typeVariableTests.typeArgumentDependencies[entity]
          .map((d) => d.name)
          .toList()
            ..sort();
    }
    if (dependencies != null && dependencies.isNotEmpty) {
      sb.write('${comma}deps=[${dependencies.join(',')}]');
      comma = ',';
    }
    return comma;
  }

  String getClassValue(ClassEntity backendClass) {
    StringBuffer sb = new StringBuffer();
    String comma = '';

    if (rtiNeed.classNeedsTypeArguments(backendClass)) {
      sb.write('${comma}needsArgs');
      comma = ',';
    }
    ClassEntity frontendClass = getFrontendClass(backendClass);
    comma = findDependencies(sb, comma, frontendClass);
    if (rtiNeedBuilder.classesUsingTypeVariableLiterals
        .contains(frontendClass)) {
      sb.write('${comma}exp');
      comma = ',';
    }
    if (rtiNeedBuilder.typeVariableTests.directClassTests
        .contains(frontendClass)) {
      sb.write('${comma}test');
      comma = ',';
    } else if (rtiNeedBuilder.typeVariableTests.classTests
        .contains(frontendClass)) {
      sb.write('${comma}indirectTest');
    }
    comma = findChecks(sb, comma, 'explicit', frontendClass,
        rtiNeedBuilder.typeVariableTests.isChecks);
    comma = findChecks(
        sb, comma, 'implicit', frontendClass, rtiNeedBuilder.implicitIsChecks);
    if (rtiChecks.getRequiredArgumentClasses().contains(backendClass)) {
      sb.write('${comma}required');
      comma = ',';
    }
    Iterable<TypeCheck> checks = requiredChecks[backendClass];
    if (checks.isNotEmpty) {
      sb.write('${comma}checks=[${checks.map((c) => c.cls.name).join(',')}]');
    }
    return sb.toString();
  }

  String getMemberValue(MemberEntity backendMember) {
    MemberEntity frontendMember = getFrontendMember(backendMember);
    Local frontendClosure = getFrontendClosure(backendMember);

    StringBuffer sb = new StringBuffer();
    String comma = '';

    if (backendMember is FunctionEntity) {
      if (rtiNeed.methodNeedsTypeArguments(backendMember)) {
        sb.write('${comma}needsArgs');
        comma = ',';
      }
      if (rtiNeed.methodNeedsSignature(backendMember)) {
        sb.write('${comma}needsSignature');
        comma = ',';
      }
      if (frontendClosure != null) {
        if (frontendClosure is LocalFunctionElement &&
            rtiNeed.localFunctionNeedsSignature(frontendClosure)) {
          sb.write('${comma}needsSignature');
          comma = ',';
        }
        if (rtiNeedBuilder.localFunctionsUsingTypeVariableLiterals
            .contains(frontendClosure)) {
          sb.write('${comma}exp');
          comma = ',';
        }
        comma = findChecks(sb, comma, 'explicit', frontendClosure,
            rtiNeedBuilder.typeVariableTests.isChecks);
      } else if (frontendMember != null) {
        if (rtiNeedBuilder.methodsUsingTypeVariableLiterals
            .contains(frontendMember)) {
          sb.write('${comma}exp');
          comma = ',';
        }
        comma = findDependencies(sb, comma, frontendMember);
        comma = findChecks(sb, comma, 'explicit', frontendMember,
            rtiNeedBuilder.typeVariableTests.isChecks);
        comma = findChecks(sb, comma, 'implicit', frontendMember,
            rtiNeedBuilder.implicitIsChecks);
      }
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

abstract class AstMixin implements ComputeValueMixin<ast.Node> {
  @override
  ClassEntity getFrontendClass(ClassEntity cls) {
    return cls;
  }

  @override
  MemberEntity getFrontendMember(MemberEntity member) {
    return member;
  }

  @override
  Local getFrontendClosure(MemberEntity member) {
    if (member is SynthesizedCallMethodElementX) return member.expression;
    return null;
  }
}

class RtiClassNeedAstComputer extends DataRegistry
    with ComputeValueMixin<ast.Node>, AstMixin {
  final Compiler compiler;
  final Map<Id, ActualData> actualMap;

  RtiClassNeedAstComputer(this.compiler, this.actualMap);

  DiagnosticReporter get reporter => compiler.reporter;

  void computeClassValue(covariant ClassElement cls) {
    Id id = new ClassId(cls.name);
    registerValue(cls.sourcePosition, id, getClassValue(cls), cls);
  }
}

/// AST visitor for computing inlining data for a member.
class RtiMemberNeedAstComputer extends AstDataExtractor
    with ComputeValueMixin<ast.Node>, AstMixin {
  final Compiler compiler;

  RtiMemberNeedAstComputer(DiagnosticReporter reporter,
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

/// Compute RTI need data for [member] from the new frontend.
///
/// Fills [actualMap] with the data.
void computeKernelRtiMemberNeed(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  new RtiMemberNeedIrComputer(
          compiler.reporter,
          actualMap,
          elementMap,
          member,
          compiler,
          backendStrategy.closureDataLookup as ClosureDataLookup<ir.Node>)
      .run(definition.node);
}

/// Compute RTI need data for [cls] from the new frontend.
///
/// Fills [actualMap] with the data.
void computeKernelRtiClassNeed(
    Compiler compiler, ClassEntity cls, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  new RtiClassNeedIrComputer(compiler, elementMap, actualMap)
      .computeClassValue(cls);
}

abstract class IrMixin implements ComputeValueMixin<ir.Node> {
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
  ClassEntity getFrontendClass(ClassEntity backendClass) {
    if (backendClass.isClosure) return null;
    ElementEnvironment elementEnvironment = compiler
        .resolutionWorldBuilder.closedWorldForTesting.elementEnvironment;
    LibraryEntity frontendLibrary =
        elementEnvironment.lookupLibrary(backendClass.library.canonicalUri);
    return elementEnvironment.lookupClass(frontendLibrary, backendClass.name);
  }

  @override
  Local getFrontendClosure(MemberEntity member) {
    KernelBackendStrategy backendStrategy = compiler.backendStrategy;
    ir.Node node = backendStrategy.elementMap.getMemberDefinition(member).node;
    if (node is ir.FunctionDeclaration || node is ir.FunctionExpression) {
      KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
      KernelToElementMapForImpact frontendElementMap =
          frontendStrategy.elementMap;
      return frontendElementMap.getLocalFunction(node);
    }
    return null;
  }
}

class RtiClassNeedIrComputer extends DataRegistry
    with ComputeValueMixin<ir.Node>, IrMixin {
  final Compiler compiler;
  final KernelToElementMapForBuilding _elementMap;
  final Map<Id, ActualData> actualMap;

  RtiClassNeedIrComputer(this.compiler, this._elementMap, this.actualMap);

  DiagnosticReporter get reporter => compiler.reporter;

  void computeClassValue(ClassEntity cls) {
    Id id = new ClassId(cls.name);
    ir.TreeNode node = _elementMap.getClassDefinition(cls).node;
    registerValue(
        computeSourceSpanFromTreeNode(node), id, getClassValue(cls), cls);
  }
}

/// AST visitor for computing inference data for a member.
class RtiMemberNeedIrComputer extends IrDataExtractor
    with ComputeValueMixin<ir.Node>, IrMixin {
  final KernelToElementMapForBuilding _elementMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;
  final Compiler compiler;

  RtiMemberNeedIrComputer(
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
