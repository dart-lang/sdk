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
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/js_backend/runtime_types.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/check_helpers.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  runTests(args);
}

runTests(List<String> args, [int shardIndex]) {
  cacheRtiDataForTesting = true;
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, computeKernelRtiMemberNeed,
        computeClassDataFromKernel: computeKernelRtiClassNeed,
        options: [],
        skipForKernel: [
          'runtime_type_closure_equals2.dart',
        ],
        skipForStrong: [
          'map_literal_checked.dart',
          // TODO(johnniwinther): Optimize local function type signature need.
          'subtype_named_args.dart',
          'subtype_named_args1.dart',
        ],
        args: args,
        testOmit: true,
        shardIndex: shardIndex ?? 0,
        shards: shardIndex != null ? 2 : 1);
  });
}

class Tags {
  static const String needsTypeArguments = 'needsArgs';
  static const String needsSignature = 'needsSignature';
  static const String dependencies = 'deps';
  static const String explicitTypeCheck = 'explicit';
  static const String implicitTypeCheck = 'implicit';
  static const String directTypeArgumentTest = 'direct';
  static const String indirectTypeArgumentTest = 'indirect';
  static const String typeLiteral = 'exp';
  static const String selectors = 'selectors';
  static const String instantiationsNeedTypeArguments = 'needsInst';
}

abstract class ComputeValueMixin<T> {
  Compiler get compiler;

  ResolutionWorldBuilder get resolutionWorldBuilder =>
      compiler.resolutionWorldBuilder;
  RuntimeTypesNeedBuilderImpl get rtiNeedBuilder =>
      compiler.frontendStrategy.runtimeTypesNeedBuilderForTesting;
  RuntimeTypesNeedImpl get rtiNeed =>
      compiler.backendClosedWorldForTesting.rtiNeed;
  ClassEntity getFrontendClass(ClassEntity cls);
  MemberEntity getFrontendMember(MemberEntity member);
  Local getFrontendClosure(MemberEntity member);

  void findChecks(
      Features features, String key, Entity entity, Set<DartType> checks) {
    Set<DartType> types = new Set<DartType>();
    FindTypeVisitor finder = new FindTypeVisitor(entity);
    for (DartType type in checks) {
      if (type.accept(finder, null)) {
        types.add(type);
      }
    }
    List<String> list = types.map(typeToString).toList()..sort();
    if (list.isNotEmpty) {
      features[key] = '[${list.join(',')}]';
    }
  }

  void findDependencies(Features features, Entity entity) {
    Iterable<Entity> dependencies = rtiNeedBuilder.typeVariableTestsForTesting
        .getTypeArgumentDependencies(entity);
    if (dependencies.isNotEmpty) {
      List<String> names = dependencies.map((Entity d) {
        if (d is MemberEntity && d.enclosingClass != null) {
          return '${d.enclosingClass.name}.${d.name}';
        }
        return d.name;
      }).toList()
        ..sort();
      features[Tags.dependencies] = '[${names.join(',')}]';
    }
  }

  String getClassValue(ClassEntity backendClass) {
    Features features = new Features();

    if (rtiNeed.classNeedsTypeArguments(backendClass)) {
      features.add(Tags.needsTypeArguments);
    }
    ClassEntity frontendClass = getFrontendClass(backendClass);
    findDependencies(features, frontendClass);
    if (rtiNeedBuilder.classesUsingTypeVariableLiterals
        .contains(frontendClass)) {
      features.add(Tags.typeLiteral);
    }
    if (rtiNeedBuilder.typeVariableTestsForTesting.directClassTestsForTesting
        .contains(frontendClass)) {
      features.add(Tags.directTypeArgumentTest);
    } else if (rtiNeedBuilder.typeVariableTestsForTesting.classTestsForTesting
        .contains(frontendClass)) {
      features.add(Tags.indirectTypeArgumentTest);
    }
    findChecks(features, Tags.explicitTypeCheck, frontendClass,
        rtiNeedBuilder.typeVariableTestsForTesting.explicitIsChecks);
    findChecks(features, Tags.implicitTypeCheck, frontendClass,
        rtiNeedBuilder.typeVariableTestsForTesting.implicitIsChecks);
    return features.getText();
  }

  String getMemberValue(MemberEntity backendMember) {
    MemberEntity frontendMember = getFrontendMember(backendMember);
    Local frontendClosure = getFrontendClosure(backendMember);

    Features features = new Features();

    if (backendMember is FunctionEntity) {
      if (rtiNeed.methodNeedsTypeArguments(backendMember)) {
        features.add(Tags.needsTypeArguments);
      }
      if (rtiNeed.methodNeedsSignature(backendMember)) {
        features.add(Tags.needsSignature);
      }

      void addFrontendData(Entity entity) {
        findDependencies(features, entity);
        if (rtiNeedBuilder
            .typeVariableTestsForTesting.directMethodTestsForTesting
            .contains(entity)) {
          features.add(Tags.directTypeArgumentTest);
        } else if (rtiNeedBuilder
            .typeVariableTestsForTesting.methodTestsForTesting
            .contains(entity)) {
          features.add(Tags.indirectTypeArgumentTest);
        }
        findChecks(features, Tags.explicitTypeCheck, entity,
            rtiNeedBuilder.typeVariableTestsForTesting.explicitIsChecks);
        findChecks(features, Tags.implicitTypeCheck, entity,
            rtiNeedBuilder.typeVariableTestsForTesting.implicitIsChecks);
        rtiNeedBuilder.selectorsNeedingTypeArgumentsForTesting
            ?.forEach((Selector selector, Set<Entity> targets) {
          if (targets.contains(entity)) {
            features.addElement(Tags.selectors, selector);
          }
        });
        rtiNeedBuilder.instantiationsNeedingTypeArgumentsForTesting?.forEach(
            (GenericInstantiation instantiation, Set<Entity> targets) {
          if (targets.contains(entity)) {
            features.addElement(
                Tags.instantiationsNeedTypeArguments, instantiation.shortText);
          }
        });
      }

      if (frontendClosure != null) {
        addFrontendData(frontendClosure);
        if (rtiNeedBuilder.localFunctionsUsingTypeVariableLiterals
            .contains(frontendClosure)) {
          features.add(Tags.typeLiteral);
        }
      } else if (frontendMember != null) {
        addFrontendData(frontendMember);
        if (rtiNeedBuilder.methodsUsingTypeVariableLiterals
            .contains(frontendMember)) {
          features.add(Tags.typeLiteral);
        }
      }
    }
    return features.getText();
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

  @override
  bool visitFutureOrType(FutureOrType type, _) {
    return type.typeArgument.accept(this, null);
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
