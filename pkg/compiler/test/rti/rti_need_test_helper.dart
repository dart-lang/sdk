// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/js_backend/runtime_types_resolution.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/resolution_world_builder.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/check_helpers.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  runTests(args);
}

runTests(List<String> args, [int? shardIndex]) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const RtiNeedDataComputer(),
        args: args,
        shardIndex: shardIndex ?? 0,
        shards: shardIndex != null ? 4 : 1);
  });
}

class Tags {
  static const String needsTypeArguments = 'needsArgs';
  static const String needsSignature = 'needsSignature';
  static const String dependencies = 'deps';
  static const String explicitTypeCheck = 'explicit';
  static const String implicitTypeCheck = 'implicit';
  static const String typeArgumentTest = 'test';
  static const String typeLiteral = 'exp';
  static const String selectors = 'selectors';
  static const String instantiationsNeedTypeArguments = 'needsInst';
}

mixin ComputeValueMixin {
  Compiler get compiler;

  KernelFrontendStrategy get frontendStrategy => compiler.frontendStrategy;
  ResolutionWorldBuilder get resolutionWorldBuilder =>
      compiler.resolutionWorldBuilderForTesting!;
  RuntimeTypesNeedBuilderImpl get rtiNeedBuilder =>
      frontendStrategy.runtimeTypesNeedBuilderForTesting
          as RuntimeTypesNeedBuilderImpl;
  RuntimeTypesNeedImpl get rtiNeed =>
      compiler.backendClosedWorldForTesting!.rtiNeed as RuntimeTypesNeedImpl;
  ClassEntity? getFrontendClass(ClassEntity cls);
  MemberEntity? getFrontendMember(MemberEntity member);
  Local? getFrontendClosure(MemberEntity member);

  void findChecks(
      Features features, String key, Entity? entity, Set<DartType> checks) {
    Set<DartType> types = Set<DartType>();
    FindTypeVisitor finder = FindTypeVisitor(entity);
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

  void findDependencies(Features features, Entity? entity) {
    Iterable<Entity> dependencies = entity == null
        ? const []
        : rtiNeedBuilder.typeVariableTestsForTesting!
            .getTypeArgumentDependencies(entity);
    if (dependencies.isNotEmpty) {
      List<String> names = dependencies.map((Entity d) {
        if (d is MemberEntity && d.enclosingClass != null) {
          return '${d.enclosingClass!.name}.${d.name}';
        }
        return d.name!;
      }).toList()
        ..sort();
      features[Tags.dependencies] = '[${names.join(',')}]';
    }
  }

  String getClassValue(ClassEntity backendClass) {
    Features features = Features();

    if (rtiNeed.classNeedsTypeArguments(backendClass)) {
      features.add(Tags.needsTypeArguments);
    }
    ClassEntity? frontendClass = getFrontendClass(backendClass);
    findDependencies(features, frontendClass);
    if (rtiNeedBuilder.classesUsingTypeVariableLiterals
        .contains(frontendClass)) {
      features.add(Tags.typeLiteral);
    }
    if (rtiNeedBuilder.typeVariableTestsForTesting!.classTestsForTesting
        .contains(frontendClass)) {
      features.add(Tags.typeArgumentTest);
    }
    findChecks(features, Tags.explicitTypeCheck, frontendClass,
        rtiNeedBuilder.typeVariableTestsForTesting!.explicitIsChecks);
    findChecks(features, Tags.implicitTypeCheck, frontendClass,
        rtiNeedBuilder.typeVariableTestsForTesting!.implicitIsChecks);
    return features.getText();
  }

  String getMemberValue(MemberEntity backendMember) {
    MemberEntity? frontendMember = getFrontendMember(backendMember);
    Local? frontendClosure = getFrontendClosure(backendMember);

    Features features = Features();

    if (backendMember is FunctionEntity) {
      if (rtiNeed.methodNeedsTypeArguments(backendMember)) {
        features.add(Tags.needsTypeArguments);
      }
      if (rtiNeed.methodNeedsSignature(backendMember)) {
        features.add(Tags.needsSignature);
      }

      void addFrontendData(Entity entity) {
        findDependencies(features, entity);
        if (rtiNeedBuilder.typeVariableTestsForTesting!.methodTestsForTesting
            .contains(entity)) {
          features.add(Tags.typeArgumentTest);
        }
        findChecks(features, Tags.explicitTypeCheck, entity,
            rtiNeedBuilder.typeVariableTestsForTesting!.explicitIsChecks);
        findChecks(features, Tags.implicitTypeCheck, entity,
            rtiNeedBuilder.typeVariableTestsForTesting!.implicitIsChecks);
        rtiNeedBuilder.selectorsNeedingTypeArgumentsForTesting
            ?.forEach((Selector selector, Set<Entity> targets) {
          if (targets.contains(entity)) {
            features.addElement(Tags.selectors, selector);
          }
        });
        rtiNeedBuilder
            .instantiatedEntitiesNeedingTypeArgumentsForTesting[entity]
            ?.forEach((GenericInstantiation instantiation) {
          features.addElement(
              Tags.instantiationsNeedTypeArguments, instantiation.shortText);
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
class FindTypeVisitor extends DartTypeVisitor<bool, Null> {
  final Entity? entity;

  FindTypeVisitor(this.entity);

  bool check(DartType type) => visit(type, null);

  bool checkList(List<DartType> types) {
    for (DartType type in types) {
      if (check(type)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitLegacyType(LegacyType type, _) => visit(type.baseType, _);

  @override
  bool visitNullableType(NullableType type, _) => visit(type.baseType, _);

  @override
  bool visitNeverType(NeverType type, _) => false;

  @override
  bool visitVoidType(VoidType type, _) => false;

  @override
  bool visitTypeVariableType(TypeVariableType type, _) =>
      type.element.typeDeclaration == entity;

  @override
  bool visitFunctionTypeVariable(FunctionTypeVariable type, _) => false;

  @override
  bool visitFunctionType(FunctionType type, _) =>
      type.returnType.accept(this, null) ||
      checkList(type.typeVariables) ||
      checkList(type.parameterTypes) ||
      checkList(type.optionalParameterTypes) ||
      checkList(type.namedParameterTypes);

  @override
  bool visitInterfaceType(InterfaceType type, _) =>
      type.element == entity || checkList(type.typeArguments);

  @override
  bool visitRecordType(RecordType type, _) => throw UnimplementedError();

  @override
  bool visitDynamicType(DynamicType type, _) => false;

  @override
  bool visitErasedType(ErasedType type, _) => false;

  @override
  bool visitAnyType(AnyType type, _) => false;

  @override
  bool visitFutureOrType(FutureOrType type, _) => check(type.typeArgument);
}

class RtiNeedDataComputer extends DataComputer<String> {
  const RtiNeedDataComputer();

  /// Compute RTI need data for [member] from the new frontend.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose = false}) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    RtiNeedIrComputer(compiler.reporter, actualMap, elementMap, compiler,
            closedWorld.closureDataLookup)
        .run(definition.node);
  }

  /// Compute RTI need data for [cls] from the new frontend.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeClassData(
      Compiler compiler, ClassEntity cls, Map<Id, ActualData<String>> actualMap,
      {bool verbose = false}) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    JsToElementMap elementMap = closedWorld.elementMap;
    RtiNeedIrComputer(compiler.reporter, actualMap, elementMap, compiler,
            closedWorld.closureDataLookup)
        .computeForClass(elementMap.getClassDefinition(cls).node as ir.Class);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

mixin IrMixin implements ComputeValueMixin {
  @override
  MemberEntity? getFrontendMember(MemberEntity backendMember) {
    ElementEnvironment elementEnvironment =
        compiler.frontendClosedWorldForTesting!.elementEnvironment;
    LibraryEntity frontendLibrary =
        elementEnvironment.lookupLibrary(backendMember.library.canonicalUri)!;
    if (backendMember.enclosingClass != null) {
      if (backendMember.enclosingClass!.isClosure) return null;
      ClassEntity frontendClass = elementEnvironment.lookupClass(
          frontendLibrary, backendMember.enclosingClass!.name)!;
      if (backendMember is ConstructorEntity) {
        return elementEnvironment.lookupConstructor(
            frontendClass, backendMember.name!);
      } else {
        return elementEnvironment.lookupClassMember(
            frontendClass,
            Name(backendMember.name!, frontendClass.library.canonicalUri,
                isSetter: backendMember.isSetter));
      }
    }
    return elementEnvironment.lookupLibraryMember(
        frontendLibrary, backendMember.name!,
        setter: backendMember.isSetter);
  }

  @override
  ClassEntity? getFrontendClass(ClassEntity backendClass) {
    if (backendClass.isClosure) return null;
    ElementEnvironment elementEnvironment =
        compiler.frontendClosedWorldForTesting!.elementEnvironment;
    LibraryEntity frontendLibrary =
        elementEnvironment.lookupLibrary(backendClass.library.canonicalUri)!;
    return elementEnvironment.lookupClass(frontendLibrary, backendClass.name);
  }

  @override
  Local? getFrontendClosure(MemberEntity member) {
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    ir.Node node = closedWorld.elementMap.getMemberDefinition(member).node;
    if (node is ir.FunctionDeclaration || node is ir.FunctionExpression) {
      KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
      KernelToElementMap frontendElementMap = frontendStrategy.elementMap;
      return frontendElementMap.getLocalFunction(node as ir.LocalFunction);
    }
    return null;
  }
}

class RtiClassNeedIrComputer
    with
        DataRegistry<String>,
        ComputeValueMixin,
        IrMixin,
        IrDataRegistryMixin<String> {
  @override
  final Compiler compiler;
  final JsToElementMap _elementMap;
  @override
  final Map<Id, ActualData<String>> actualMap;

  RtiClassNeedIrComputer(this.compiler, this._elementMap, this.actualMap);

  @override
  DiagnosticReporter get reporter => compiler.reporter;

  void computeClassValue(ClassEntity cls) {
    Id id = ClassId(cls.name);
    final node = _elementMap.getClassDefinition(cls).node as ir.TreeNode;
    ir.TreeNode nodeWithOffset = computeTreeNodeWithOffset(node)!;
    registerValue(nodeWithOffset.location!.file, nodeWithOffset.fileOffset, id,
        getClassValue(cls), cls);
  }
}

/// AST visitor for computing inference data for a member.
class RtiNeedIrComputer extends IrDataExtractor<String>
    with ComputeValueMixin, IrMixin {
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;
  @override
  final Compiler compiler;

  RtiNeedIrComputer(
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
  String computeMemberValue(Id id, ir.Member node) {
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
