// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformations based on type flow analysis.

import 'dart:core' hide Type;

import 'package:front_end/src/api_prototype/static_weak_references.dart'
    show StaticWeakReferences;
import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/ast.dart' as ast show Statement;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClosedWorldClassHierarchy;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:vm/metadata/direct_call.dart';
import 'package:vm/metadata/inferred_type.dart';
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/metadata/table_selector.dart';
import 'package:vm/metadata/unboxing_info.dart';
import 'package:vm/metadata/unreachable.dart';
import 'package:vm/transformations/devirtualization.dart' show Devirtualization;
import 'package:vm/transformations/pragma.dart';

import 'analysis.dart';
import 'calls.dart';
import 'finalizable_types.dart';
import 'protobuf_handler.dart' show ProtobufHandler;
import 'rta.dart' show RapidTypeAnalysis;
import 'signature_shaking.dart';
import 'summary.dart';
import 'table_selector_assigner.dart';
import 'types.dart';
import 'unboxing_info.dart';
import 'utils.dart';

const bool kDumpClassHierarchy =
    const bool.fromEnvironment('global.type.flow.dump.class.hierarchy');

/// Whole-program type flow analysis and transformation.
/// Assumes strong mode and closed world.
Component transformComponent(
    Target target, CoreTypes coreTypes, Component component,
    {PragmaAnnotationParser? matcher,
    bool treeShakeSignatures = true,
    bool treeShakeWriteOnlyFields = true,
    bool treeShakeProtobufs = false,
    bool useRapidTypeAnalysis = true}) {
  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  final hierarchy = new ClassHierarchy(component, coreTypes,
          onAmbiguousSupertypes: ignoreAmbiguousSupertypes)
      as ClosedWorldClassHierarchy;
  final types = new TypeEnvironment(coreTypes, hierarchy);
  final libraryIndex = new LibraryIndex.all(component);
  final genericInterfacesInfo =
      new GenericInterfacesInfoImpl(coreTypes, hierarchy);
  final protobufHandler = treeShakeProtobufs
      ? ProtobufHandler.forComponent(component, coreTypes)
      : null;

  Statistics.reset();

  CleanupAnnotations(coreTypes, libraryIndex, protobufHandler)
      .visitComponent(component);

  Stopwatch? rtaStopWatch;
  RapidTypeAnalysis? rta;
  if (useRapidTypeAnalysis) {
    // Rapid type analysis (RTA) is used to quickly calculate
    // the set of allocated classes to make the subsequent
    // type flow analysis converge much faster.
    rtaStopWatch = new Stopwatch()..start();
    final protobufHandlerRta = treeShakeProtobufs
        ? ProtobufHandler.forComponent(component, coreTypes)
        : null;
    rta = RapidTypeAnalysis(component, coreTypes, target, hierarchy,
        libraryIndex, protobufHandlerRta);
    rtaStopWatch.stop();
  }

  final analysisStopWatch = new Stopwatch()..start();

  MoveFieldInitializers().transformComponent(component);

  final typeFlowAnalysis = new TypeFlowAnalysis(
      target,
      component,
      coreTypes,
      hierarchy,
      genericInterfacesInfo,
      types,
      libraryIndex,
      protobufHandler,
      matcher);

  Procedure? main = component.mainMethod;

  // `main` can be null, roots can also come from @pragma("vm:entry-point").
  if (main != null) {
    final Selector mainSelector = new DirectSelector(main);
    typeFlowAnalysis.addRawCall(mainSelector);
  }

  if (useRapidTypeAnalysis) {
    for (Class c in rta!.allocatedClasses) {
      typeFlowAnalysis.addAllocatedClass(c);
    }
  }

  typeFlowAnalysis.process();

  analysisStopWatch.stop();

  if (kDumpClassHierarchy) {
    debugPrint(typeFlowAnalysis.hierarchyCache);
  }

  final transformsStopWatch = new Stopwatch()..start();

  final treeShaker = new TreeShaker(
      component, typeFlowAnalysis, coreTypes, hierarchy,
      treeShakeWriteOnlyFields: treeShakeWriteOnlyFields);
  treeShaker.transformComponent(component);

  new TFADevirtualization(
          component, typeFlowAnalysis, hierarchy, treeShaker.fieldMorpher)
      .visitComponent(component);

  final tableSelectorAssigner = new TableSelectorAssigner(component);

  if (treeShakeSignatures) {
    final signatureShaker =
        new SignatureShaker(typeFlowAnalysis, tableSelectorAssigner);
    signatureShaker.transformComponent(component);
  }

  final unboxingInfo = new UnboxingInfoManager(typeFlowAnalysis)
    ..analyzeComponent(component, typeFlowAnalysis, tableSelectorAssigner);

  new AnnotateKernel(component, typeFlowAnalysis, hierarchy,
          treeShaker.fieldMorpher, tableSelectorAssigner, unboxingInfo)
      .visitComponent(component);

  transformsStopWatch.stop();

  if (useRapidTypeAnalysis) {
    statPrint("RTA took ${rtaStopWatch!.elapsedMilliseconds}ms");
  }
  statPrint("TF analysis took ${analysisStopWatch.elapsedMilliseconds}ms");
  statPrint("TF transforms took ${transformsStopWatch.elapsedMilliseconds}ms");

  Statistics.print("TFA statistics");

  return component;
}

// Move instance field initializers with possible side-effects
// into constructors. This makes fields self-contained and
// simplifies tree-shaking of fields.
class MoveFieldInitializers {
  void transformComponent(Component component) {
    for (Library library in component.libraries) {
      for (Class cls in library.classes) {
        transformClass(cls);
      }
    }
  }

  void transformClass(Class cls) {
    if (cls.fields.isEmpty) return;

    // Collect instance fields with non-trivial initializers.
    // Those will be moved into constructors.
    final List<Field> fields = [
      for (Field f in cls.fields)
        if (!f.isStatic &&
            !f.isLate &&
            f.initializer != null &&
            mayHaveSideEffects(f.initializer!))
          f
    ];
    if (fields.isEmpty) return;

    // Collect non-redirecting constructors.
    final List<Constructor> constructors = [
      for (Constructor c in cls.constructors)
        if (!_isRedirectingConstructor(c)) c
    ];

    // Move field initializers to constructors.
    // Clone AST for all constructors except the first.
    bool isFirst = true;
    for (Constructor c in constructors) {
      // Avoid duplicate FieldInitializers in the constructor initializer list.
      final Set<Field> initializedFields = {
        for (Initializer init in c.initializers)
          if (init is FieldInitializer) init.field
      };
      final List<Initializer> newInitializers = [];
      for (Field f in fields) {
        Expression initExpr = f.initializer!;
        if (!isFirst) {
          initExpr = CloneVisitorNotMembers().clone(initExpr);
        }
        final Initializer newInit = initializedFields.contains(f)
            ? LocalInitializer(VariableDeclaration(null,
                initializer: initExpr, isSynthesized: true))
            : FieldInitializer(f, initExpr);
        newInit.parent = c;
        newInitializers.add(newInit);
      }
      newInitializers.addAll(c.initializers);
      c.initializers = newInitializers;
      isFirst = false;
    }

    // Cleanup field initializers.
    for (Field f in fields) {
      f.initializer = null;
    }
  }

  bool _isRedirectingConstructor(Constructor c) =>
      c.initializers.last is RedirectingInitializer;
}

// Pass which removes all annotations except @pragma on variables, members,
// classes and libraries.
// May also keep @TagNumber which is used by protobuf handler.
class CleanupAnnotations extends RecursiveVisitor {
  final Class pragmaClass;
  final ProtobufHandler? protobufHandler;

  CleanupAnnotations(
      CoreTypes coreTypes, LibraryIndex index, this.protobufHandler)
      : pragmaClass = coreTypes.pragmaClass;

  @override
  defaultNode(Node node) {
    if (node is Annotatable && node.annotations.isNotEmpty) {
      _cleanupAnnotations(node, node.annotations);
    }
    super.defaultNode(node);
  }

  void _cleanupAnnotations(Node node, List<Expression> annotations) {
    if (node is VariableDeclaration ||
        node is Member ||
        node is Class ||
        node is Library) {
      annotations.removeWhere((a) => !_keepAnnotation(a));
    } else {
      annotations.clear();
    }
  }

  bool _keepAnnotation(Expression annotation) {
    if (annotation is ConstantExpression) {
      final constant = annotation.constant;
      if (constant is InstanceConstant) {
        final cls = constant.classNode;
        return (cls == pragmaClass) ||
            (protobufHandler != null &&
                protobufHandler!.usesAnnotationClass(cls));
      }
    }
    return false;
  }
}

/// Devirtualization based on results of type flow analysis.
class TFADevirtualization extends Devirtualization {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final FieldMorpher fieldMorpher;

  TFADevirtualization(Component component, this._typeFlowAnalysis,
      ClassHierarchy hierarchy, this.fieldMorpher)
      : super(_typeFlowAnalysis.environment.coreTypes, component, hierarchy);

  @override
  DirectCallMetadata? getDirectCall(TreeNode node, Member? interfaceTarget,
      {bool setter = false}) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if (callSite != null) {
      final Member? singleTarget = fieldMorpher
          .getMorphedMember(callSite.monomorphicTarget, isSetter: setter);
      if (singleTarget != null) {
        return new DirectCallMetadata(
            singleTarget, callSite.isNullableReceiver);
      }
    }
    return null;
  }
}

/// Annotates kernel AST with metadata using results of type flow analysis.
class AnnotateKernel extends RecursiveVisitor {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final ClassHierarchy hierarchy;
  final FieldMorpher fieldMorpher;
  final DirectCallMetadataRepository _directCallMetadataRepository;
  final InferredTypeMetadataRepository _inferredTypeMetadata;
  final InferredArgTypeMetadataRepository _inferredArgTypeMetadata;
  final UnreachableNodeMetadataRepository _unreachableNodeMetadata;
  final ProcedureAttributesMetadataRepository _procedureAttributesMetadata;
  final TableSelectorMetadataRepository _tableSelectorMetadata;
  final TableSelectorAssigner _tableSelectorAssigner;
  final UnboxingInfoMetadataRepository _unboxingInfoMetadata;
  final UnboxingInfoManager _unboxingInfo;
  final Class _intClass;
  late final Constant _nullConstant = NullConstant();

  AnnotateKernel(Component component, this._typeFlowAnalysis, this.hierarchy,
      this.fieldMorpher, this._tableSelectorAssigner, this._unboxingInfo)
      : _directCallMetadataRepository =
            component.metadata[DirectCallMetadataRepository.repositoryTag]
                as DirectCallMetadataRepository,
        _inferredTypeMetadata = InferredTypeMetadataRepository(),
        _inferredArgTypeMetadata = InferredArgTypeMetadataRepository(),
        _unreachableNodeMetadata = UnreachableNodeMetadataRepository(),
        _procedureAttributesMetadata = ProcedureAttributesMetadataRepository(),
        _tableSelectorMetadata = TableSelectorMetadataRepository(),
        _unboxingInfoMetadata = UnboxingInfoMetadataRepository(),
        _intClass = _typeFlowAnalysis.environment.coreTypes.intClass {
    component.addMetadataRepository(_inferredTypeMetadata);
    component.addMetadataRepository(_inferredArgTypeMetadata);
    component.addMetadataRepository(_unreachableNodeMetadata);
    component.addMetadataRepository(_procedureAttributesMetadata);
    component.addMetadataRepository(_tableSelectorMetadata);
    component.addMetadataRepository(_unboxingInfoMetadata);
  }

  // Query whether a call site was marked as a direct call by the analysis.
  bool _callSiteUsesDirectCall(TreeNode node) {
    return _directCallMetadataRepository.mapping.containsKey(node);
  }

  InferredType? _convertType(Type type,
      {bool skipCheck = false, bool receiverNotInt = false}) {
    Class? concreteClass;
    Constant? constantValue;
    bool isInt = false;

    final nullable = type is NullableType;
    if (nullable) {
      type = type.baseType;
    }

    if (nullable && type == emptyType) {
      concreteClass =
          _typeFlowAnalysis.environment.coreTypes.deprecatedNullClass;
      constantValue = _nullConstant;
    } else {
      concreteClass = type.getConcreteClass(_typeFlowAnalysis.hierarchyCache);

      if (concreteClass == null) {
        isInt = type.isSubtypeOf(_typeFlowAnalysis.hierarchyCache, _intClass);
      }

      if (type is ConcreteType && !nullable) {
        constantValue = type.constant;
      }
    }

    List<DartType?>? typeArgs;
    if (type is ConcreteType && type.typeArgs != null) {
      typeArgs = type.typeArgs!
          .take(type.numImmediateTypeArgs)
          .map((t) =>
              t is UnknownType ? null : (t as RuntimeType).representedType)
          .toList();
    }

    if (concreteClass != null ||
        !nullable ||
        isInt ||
        constantValue != null ||
        skipCheck ||
        receiverNotInt) {
      return new InferredType(concreteClass, nullable, isInt, constantValue,
          exactTypeArguments: typeArgs,
          skipCheck: skipCheck,
          receiverNotInt: receiverNotInt);
    }

    return null;
  }

  void _setInferredType(TreeNode node, Type type,
      {bool skipCheck = false, bool receiverNotInt = false}) {
    final inferredType = _convertType(type,
        skipCheck: skipCheck, receiverNotInt: receiverNotInt);
    if (inferredType != null) {
      _inferredTypeMetadata.mapping[node] = inferredType;
    }
  }

  void _setInferredArgType(TreeNode node, Type type, {bool skipCheck = false}) {
    final inferredType = _convertType(type, skipCheck: skipCheck);
    if (inferredType != null) {
      _inferredArgTypeMetadata.mapping[node] = inferredType;
    }
  }

  void _setUnreachable(TreeNode node) {
    _unreachableNodeMetadata.mapping[node] = const UnreachableNode();
  }

  void _annotateCallSite(TreeNode node, Member? interfaceTarget) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if (callSite == null) return;
    if (!callSite.isReachable) {
      _setUnreachable(node);
      return;
    }

    final bool markSkipCheck = !callSite.useCheckedEntry &&
        (node is InstanceInvocation ||
            node is DynamicInvocation ||
            node is EqualsCall ||
            node is InstanceSet ||
            node is DynamicSet);

    bool markReceiverNotInt = false;

    if (!callSite.receiverMayBeInt) {
      // No information is needed for static calls.
      if (node is! StaticInvocation &&
          node is! StaticSet &&
          node is! StaticGet &&
          node is! StaticTearOff) {
        // The compiler uses another heuristic in addition to the call-site
        // annotation: if the call-site is non-dynamic and the interface target does
        // not exist in the parent chain of _Smi (int is used as an approximation
        // here), then the receiver cannot be _Smi. This heuristic covers most
        // cases, so we skip these to avoid showering the AST with annotations.
        if (interfaceTarget == null ||
            hierarchy.isSubtypeOf(_intClass, interfaceTarget.enclosingClass!)) {
          markReceiverNotInt = true;
        }
      }
    }

    // If the call is not marked as 'isResultUsed', the 'resultType' will
    // not be observed (i.e., it will always be EmptyType). This is the
    // case even if the result actually might be used but is not used by
    // the summary, e.g. if the result is an argument to a closure call.
    // Therefore, we need to pass in nullableAnyType as the
    // inferred result type here (since we don't know what it actually
    // is).
    final Type resultType =
        callSite.isResultUsed ? callSite.resultType : nullableAnyType;

    if (markSkipCheck || markReceiverNotInt || callSite.isResultUsed) {
      _setInferredType(node, resultType,
          skipCheck: markSkipCheck, receiverNotInt: markReceiverNotInt);
    }

    // Tell the table selector assigner about the callsite.
    final Selector selector = callSite.selector;
    if (selector is InterfaceSelector && !_callSiteUsesDirectCall(node)) {
      if (node is InstanceGet || node is InstanceTearOff) {
        _tableSelectorAssigner.registerGetterCall(
            selector.member, callSite.isNullableReceiver);
      } else {
        assert(node is InstanceInvocation ||
            node is EqualsCall ||
            node is InstanceSet);
        _tableSelectorAssigner.registerMethodOrSetterCall(
            selector.member, callSite.isNullableReceiver);
      }
    }
  }

  void _annotateMember(Member member) {
    if (_typeFlowAnalysis.isMemberUsed(member)) {
      if (member is Field) {
        _setInferredType(member, _typeFlowAnalysis.fieldType(member)!);
      } else {
        Args<Type> argTypes = _typeFlowAnalysis.argumentTypes(member)!;
        final uncheckedParameters =
            _typeFlowAnalysis.uncheckedParameters(member);

        final int firstParamIndex =
            numTypeParams(member) + (hasReceiverArg(member) ? 1 : 0);

        final positionalParams = member.function!.positionalParameters;
        assert(argTypes.positionalCount ==
            firstParamIndex + positionalParams.length);

        for (int i = 0; i < positionalParams.length; i++) {
          _setInferredArgType(
              positionalParams[i], argTypes.values[firstParamIndex + i],
              skipCheck: uncheckedParameters!.contains(positionalParams[i]));
        }

        // TODO(dartbug.com/32292): make sure parameters are sorted in kernel
        // AST and iterate parameters in parallel, without lookup.
        final names = argTypes.names;
        for (int i = 0; i < names.length; i++) {
          final param = findNamedParameter(member.function!, names[i])!;
          _setInferredArgType(param,
              argTypes.values[firstParamIndex + positionalParams.length + i],
              skipCheck: uncheckedParameters!.contains(param));
        }

        // TODO(alexmarkov): figure out how to pass receiver type.
      }

      final unboxingInfoMetadata =
          _unboxingInfo.getUnboxingInfoOfMember(member);
      if (unboxingInfoMetadata != null && !unboxingInfoMetadata.isFullyBoxed) {
        _unboxingInfoMetadata.mapping[member] = unboxingInfoMetadata;
      }
    } else {
      if (!member.isAbstract &&
          !fieldMorpher.isExtraMemberWithReachableBody(member)) {
        _setUnreachable(member);
      }

      if (member is! Field) {
        final unboxingInfoMetadata =
            _unboxingInfo.getUnboxingInfoOfMember(member);
        if (unboxingInfoMetadata != null) {
          // Check for partitions that only have abstract methods should be marked as boxed.
          if (unboxingInfoMetadata.returnInfo == UnboxingType.kUnknown) {
            unboxingInfoMetadata.returnInfo = UnboxingType.kBoxed;
          }
          for (int i = 0; i < unboxingInfoMetadata.argsInfo.length; i++) {
            if (unboxingInfoMetadata.argsInfo[i] == UnboxingType.kUnknown) {
              unboxingInfoMetadata.argsInfo[i] = UnboxingType.kBoxed;
            }
          }
          if (!unboxingInfoMetadata.isFullyBoxed) {
            _unboxingInfoMetadata.mapping[member] = unboxingInfoMetadata;
          }
        }
      }
    }

    // We need to attach ProcedureAttributesMetadata to all members, even
    // unreachable ones, since an unreachable member could still be used as an
    // interface target, and table dispatch calls need selector IDs for all
    // interface targets.
    if (member.isInstanceMember) {
      final original = fieldMorpher.getOriginalMember(member)!;
      final attrs = new ProcedureAttributesMetadata(
          methodOrSetterCalledDynamically:
              _typeFlowAnalysis.isCalledDynamically(original),
          getterCalledDynamically:
              _typeFlowAnalysis.isGetterCalledDynamically(original),
          hasThisUses: _typeFlowAnalysis.isCalledViaThis(original),
          hasNonThisUses: _typeFlowAnalysis.isCalledNotViaThis(original),
          hasTearOffUses: _typeFlowAnalysis.isTearOffTaken(original),
          methodOrSetterSelectorId:
              _tableSelectorAssigner.methodOrSetterSelectorId(member),
          getterSelectorId: _tableSelectorAssigner.getterSelectorId(member));
      _procedureAttributesMetadata.mapping[member] = attrs;
    }
  }

  @override
  visitConstructor(Constructor node) {
    _annotateMember(node);
    super.visitConstructor(node);
  }

  @override
  visitProcedure(Procedure node) {
    _annotateMember(node);
    super.visitProcedure(node);
  }

  @override
  visitField(Field node) {
    _annotateMember(node);
    super.visitField(node);
  }

  @override
  visitInstanceInvocation(InstanceInvocation node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitInstanceInvocation(node);
  }

  @override
  visitDynamicInvocation(DynamicInvocation node) {
    _annotateCallSite(node, null);
    super.visitDynamicInvocation(node);
  }

  @override
  visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    _annotateCallSite(node, null);
    super.visitLocalFunctionInvocation(node);
  }

  @override
  visitFunctionInvocation(FunctionInvocation node) {
    _annotateCallSite(node, null);
    super.visitFunctionInvocation(node);
  }

  @override
  visitEqualsCall(EqualsCall node) {
    _annotateCallSite(node, null);
    super.visitEqualsCall(node);
  }

  @override
  visitInstanceGet(InstanceGet node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitInstanceGet(node);
  }

  @override
  visitInstanceTearOff(InstanceTearOff node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitInstanceTearOff(node);
  }

  @override
  visitFunctionTearOff(FunctionTearOff node) {
    _annotateCallSite(node, null);
    super.visitFunctionTearOff(node);
  }

  @override
  visitDynamicGet(DynamicGet node) {
    _annotateCallSite(node, null);
    super.visitDynamicGet(node);
  }

  @override
  visitInstanceSet(InstanceSet node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitInstanceSet(node);
  }

  @override
  visitDynamicSet(DynamicSet node) {
    _annotateCallSite(node, null);
    super.visitDynamicSet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitSuperMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitSuperPropertyGet(node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    _annotateCallSite(node, node.interfaceTarget);
    super.visitSuperPropertySet(node);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    _annotateCallSite(node, node.target);
    super.visitStaticInvocation(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    _annotateCallSite(node, node.target);
    super.visitStaticGet(node);
  }

  @override
  visitStaticSet(StaticSet node) {
    _annotateCallSite(node, node.target);
    super.visitStaticSet(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    final inferredType = _typeFlowAnalysis.capturedVariableType(node);
    if (inferredType != null) {
      _setInferredType(node, inferredType);
    }
    super.visitVariableDeclaration(node);
  }

  @override
  visitComponent(Component node) {
    super.visitComponent(node);
    _tableSelectorMetadata.mapping[node] = _tableSelectorAssigner.metadata;
  }
}

/// Tree shaking based on results of type flow analysis (TFA).
///
/// TFA provides information about allocated classes and reachable member
/// bodies. However, it is not enough to perform tree shaking in one pass:
/// we need to figure out which classes, members and typedefs are used
/// in types, interface targets and annotations.
///
/// So, tree shaking is performed in 2 passes:
///
/// * Pass 1 visits declarations of classes and members, and dives deep into
///   bodies of reachable members. It collects sets of used classes, members
///   and typedefs. Also, while visiting bodies of reachable members, it
///   transforms unreachable calls into 'throw' expressions.
///
/// * Pass 2 removes unused classes and members, and replaces bodies of
///   used but unreachable members.
///
class TreeShaker {
  final TypeFlowAnalysis typeFlowAnalysis;
  final bool treeShakeWriteOnlyFields;
  final Set<Library> _usedLibraries = new Set<Library>();
  final Set<Class> _usedClasses = new Set<Class>();
  final Set<Class> _classesUsedInType = new Set<Class>();
  final Set<Member> _usedMembers = new Set<Member>();
  final Set<Extension> _usedExtensions = new Set<Extension>();
  final Set<ExtensionTypeDeclaration> _usedExtensionTypeDeclarations =
      new Set<ExtensionTypeDeclaration>();
  final Set<Typedef> _usedTypedefs = new Set<Typedef>();
  final FinalizableTypes _finalizableTypes;
  late final FieldMorpher fieldMorpher;
  late final _TreeShakerTypeVisitor typeVisitor;
  late final _TreeShakerConstantVisitor constantVisitor;
  late final _TreeShakerPass1 _pass1;
  late final _TreeShakerPass2 _pass2;

  TreeShaker(
    Component component,
    this.typeFlowAnalysis,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy, {
    this.treeShakeWriteOnlyFields = true,
  }) : _finalizableTypes = new FinalizableTypes(
            coreTypes, typeFlowAnalysis.libraryIndex, hierarchy) {
    fieldMorpher = new FieldMorpher(this);
    typeVisitor = new _TreeShakerTypeVisitor(this);
    constantVisitor = new _TreeShakerConstantVisitor(this, typeVisitor);
    _pass1 = new _TreeShakerPass1(this);
    _pass2 = new _TreeShakerPass2(this);
  }

  transformComponent(Component component) {
    _pass1.transformComponent(component);
    _pass2.transformComponent(component);
  }

  bool isLibraryUsed(Library l) => _usedLibraries.contains(l);
  bool isClassReferencedFromNativeCode(Class c) =>
      typeFlowAnalysis.nativeCodeOracle.isClassReferencedFromNativeCode(c);
  bool isClassUsed(Class c) => _usedClasses.contains(c);
  bool isClassUsedInType(Class c) => _classesUsedInType.contains(c);
  bool isClassAllocated(Class c) => typeFlowAnalysis.isClassAllocated(c);
  bool isMemberUsed(Member m) => _usedMembers.contains(m);
  bool isExtensionUsed(Extension e) => _usedExtensions.contains(e);
  bool isExtensionTypeDeclarationUsed(ExtensionTypeDeclaration e) =>
      _usedExtensionTypeDeclarations.contains(e);
  bool isMemberBodyReachable(Member m) =>
      typeFlowAnalysis.isMemberUsed(m) ||
      fieldMorpher.isExtraMemberWithReachableBody(m);
  bool isFieldInitializerReachable(Field f) =>
      typeFlowAnalysis.isFieldInitializerUsed(f);
  bool isFieldGetterReachable(Field f) => typeFlowAnalysis.isFieldGetterUsed(f);
  bool isFieldSetterReachable(Field f) => typeFlowAnalysis.isFieldSetterUsed(f);
  bool isMemberReferencedFromNativeCode(Member m) =>
      typeFlowAnalysis.nativeCodeOracle.isMemberReferencedFromNativeCode(m);
  bool isFieldFinalizable(Field f) => _finalizableTypes.isFieldFinalizable(f);
  bool isTypedefUsed(Typedef t) => _usedTypedefs.contains(t);

  bool retainField(Field f) =>
      isMemberBodyReachable(f) &&
          (!treeShakeWriteOnlyFields ||
              isFieldGetterReachable(f) ||
              (!f.isStatic &&
                  f.initializer != null &&
                  isFieldInitializerReachable(f) &&
                  mayHaveSideEffects(f.initializer!)) ||
              (f.isLate && f.isFinal) ||
              isFieldFinalizable(f)) ||
      isMemberReferencedFromNativeCode(f);

  void addClassUsedInType(Class c) {
    if (_classesUsedInType.add(c)) {
      if (kPrintDebug) {
        debugPrint('Class ${c.name} used in type');
      }
      _usedClasses.add(c);
      _usedLibraries.add(c.enclosingLibrary);
      visitIterable(c.supers, typeVisitor);
      _pass1.transformTypeParameterList(c.typeParameters, c);
      _pass1.transformExpressionList(c.annotations, c);
      // Preserve NSM forwarders. They are overlooked by TFA / tree shaker
      // as they are abstract and don't have a body.
      for (Procedure p in c.procedures) {
        if (p.isAbstract && p.isNoSuchMethodForwarder) {
          addUsedMember(p);
        }
      }
    }
  }

  void addUsedMember(Member m) {
    if (_usedMembers.add(m)) {
      final enclosingClass = m.enclosingClass;
      if (enclosingClass != null) {
        if (kPrintDebug) {
          debugPrint('Member $m from class ${enclosingClass.name} is used');
        }
        _usedClasses.add(enclosingClass);
      }
      _usedLibraries.add(m.enclosingLibrary);

      FunctionNode? func = null;
      if (m is Field) {
        m.type.accept(typeVisitor);
      } else if (m is Procedure) {
        func = m.function;
        if (m.concreteForwardingStubTarget != null) {
          m.stubTarget = fieldMorpher.adjustInstanceCallTarget(
              m.concreteForwardingStubTarget,
              isSetter: m.isSetter);
          addUsedMember(m.concreteForwardingStubTarget!);
        }
        if (m.abstractForwardingStubTarget != null) {
          m.stubTarget = fieldMorpher.adjustInstanceCallTarget(
              m.abstractForwardingStubTarget,
              isSetter: m.isSetter);
          addUsedMember(m.abstractForwardingStubTarget!);
        }
        if (m.memberSignatureOrigin != null) {
          m.stubTarget = fieldMorpher.adjustInstanceCallTarget(
              m.memberSignatureOrigin,
              isSetter: m.isSetter);
          addUsedMember(m.memberSignatureOrigin!);
        }
      } else if (m is Constructor) {
        func = m.function;
      } else {
        throw 'Unexpected member ${m.runtimeType}: $m';
      }

      if (func != null) {
        _pass1.transformTypeParameterList(func.typeParameters, func);
        addUsedParameters(func.positionalParameters);
        addUsedParameters(func.namedParameters);
        func.returnType.accept(typeVisitor);
      }

      _pass1.transformExpressionList(m.annotations, m);

      // If the member is kept alive we need to keep the extension alive.
      if (m.isExtensionMember) {
        // The AST should have exactly one [Extension] for [m].
        final extension = m.enclosingLibrary.extensions.firstWhere((extension) {
          return extension.members
              .any((descriptor) => descriptor.member.asMember == m);
        });

        // Ensure we retain the [Extension] itself (though members might be
        // shaken)
        addUsedExtension(extension);
      }

      // If the member is kept alive we need to keep the extension type
      // declaration alive to maintain consistency of the AST.
      if (m.isExtensionTypeMember) {
        // The AST should have exactly one [ExtensionTypeDeclaration] for [m].
        final extensionTypeDeclaration = m
            .enclosingLibrary.extensionTypeDeclarations
            .firstWhere((extensionTypeDeclaration) {
          return extensionTypeDeclaration.members
              .any((descriptor) => descriptor.member.asMember == m);
        });

        // Ensure we retain the [ExtensionTypeDeclaration] itself (though
        // members might be shaken)
        addUsedExtensionTypeDeclaration(extensionTypeDeclaration);
      }
    }
  }

  void addUsedParameters(List<VariableDeclaration> params) {
    for (var param in params) {
      // Do not visit initializer (default value) of a parameter as it is
      // going to be removed during pass 2.
      _pass1.transformExpressionList(param.annotations, param);
      param.type.accept(typeVisitor);
    }
  }

  void addUsedExtension(Extension node) {
    if (_usedExtensions.add(node)) {
      node.annotations = const <Expression>[];
      _pass1.transformTypeParameterList(node.typeParameters, node);
      node.onType.accept(typeVisitor);
    }
  }

  void addUsedExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (_usedExtensionTypeDeclarations.add(node)) {
      node.annotations = const <Expression>[];
      _pass1.transformTypeParameterList(node.typeParameters, node);
      node.declaredRepresentationType.accept(typeVisitor);
      visitList(node.implements, typeVisitor);
    }
  }

  void addUsedTypedef(Typedef typedef) {
    if (_usedTypedefs.add(typedef)) {
      _usedLibraries.add(typedef.enclosingLibrary);
      typedef.annotations = const <Expression>[];
      _pass1.transformTypeParameterList(typedef.typeParameters, typedef);
      typedef.type?.accept(typeVisitor);
    }
  }
}

class FieldMorpher {
  final TreeShaker shaker;
  final Set<Member> _extraMembersWithReachableBody = <Member>{};
  final Map<Field, Member> _gettersForRemovedFields = <Field, Member>{};
  final Map<Field, Member> _settersForRemovedFields = <Field, Member>{};
  final Map<Member, Field> _removedFields = <Member, Field>{};

  FieldMorpher(this.shaker);

  Member _createAccessorForRemovedField(Field field, bool isSetter) {
    assert(!field.isStatic);
    assert(!shaker.retainField(field));
    Procedure accessor;
    if (isSetter) {
      final isAbstract = !shaker.isFieldSetterReachable(field);
      final parameter = new VariableDeclaration('value',
          type: field.type, isSynthesized: true)
        ..isCovariantByDeclaration = field.isCovariantByDeclaration
        ..isCovariantByClass = field.isCovariantByClass
        ..fileOffset = field.fileOffset;
      accessor = new Procedure(
          field.name,
          ProcedureKind.Setter,
          new FunctionNode(null,
              positionalParameters: [parameter], returnType: const VoidType())
            ..fileOffset = field.fileOffset,
          isAbstract: isAbstract,
          fileUri: field.fileUri);
      if (!isAbstract) {
        _extraMembersWithReachableBody.add(accessor);
      }
    } else {
      accessor = new Procedure(field.name, ProcedureKind.Getter,
          new FunctionNode(null, returnType: field.type),
          isAbstract: true, fileUri: field.fileUri);
    }
    accessor.fileOffset = field.fileOffset;
    field.enclosingClass!.addProcedure(accessor);
    _removedFields[accessor] = field;
    shaker.addUsedMember(accessor);
    return accessor;
  }

  /// Return a replacement for an instance call target.
  /// If necessary, creates a getter or setter as a replacement if target is a
  /// field which is going to be removed by the tree shaker.
  /// This method is used during tree shaker pass 1.
  Member? adjustInstanceCallTarget(Member? target, {bool isSetter = false}) {
    if (target is Field && !shaker.retainField(target)) {
      final targets =
          isSetter ? _settersForRemovedFields : _gettersForRemovedFields;
      return targets[target] ??=
          _createAccessorForRemovedField(target, isSetter);
    }
    return target;
  }

  bool isExtraMemberWithReachableBody(Member member) =>
      _extraMembersWithReachableBody.contains(member);

  /// Return a member which replaced [target] in instance calls.
  /// This method can be used after tree shaking to discover replacement.
  Member? getMorphedMember(Member? target, {bool isSetter = false}) {
    if (target is! Field) {
      return target;
    }
    final targets =
        isSetter ? _settersForRemovedFields : _gettersForRemovedFields;
    return targets[target] ?? target;
  }

  /// Return original member which was replaced by [target] in instance calls.
  /// This method can be used after tree shaking.
  Member? getOriginalMember(Member? target) {
    if (target == null) {
      return null;
    }
    return _removedFields[target] ?? target;
  }
}

/// Visits Dart types and collects all classes and typedefs used in types.
/// This visitor is used during pass 1 of tree shaking. It is a separate
/// visitor because [Transformer] does not provide a way to traverse types.
class _TreeShakerTypeVisitor extends RecursiveVisitor {
  final TreeShaker shaker;

  _TreeShakerTypeVisitor(this.shaker);

  @override
  visitInterfaceType(InterfaceType node) {
    shaker.addClassUsedInType(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitSupertype(Supertype node) {
    shaker.addClassUsedInType(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitTypedefType(TypedefType node) {
    shaker.addUsedTypedef(node.typedefNode);
    node.visitChildren(this);
  }

  @override
  visitTypeParameterType(TypeParameterType node) {
    final declaration = node.parameter.declaration;
    if (declaration is Class) {
      shaker.addClassUsedInType(declaration);
    }
    node.visitChildren(this);
  }
}

/// The first pass of [TreeShaker].
/// Visits all classes, members and bodies of reachable members.
/// Collects all used classes, members and types, and
/// transforms unreachable calls into 'throw' expressions.
class _TreeShakerPass1 extends RemovingTransformer {
  final TreeShaker shaker;
  final FieldMorpher fieldMorpher;
  final TypeEnvironment environment;

  StaticTypeContext? _staticTypeContext;
  Member? _currentMember;

  StaticTypeContext get staticTypeContext =>
      _staticTypeContext ??= StaticTypeContext(currentMember, environment);

  Member get currentMember => _currentMember!;
  set currentMember(Member? m) {
    _currentMember = m;
    _staticTypeContext = null;
  }

  _TreeShakerPass1(this.shaker)
      : fieldMorpher = shaker.fieldMorpher,
        environment = shaker.typeFlowAnalysis.environment;

  void transformComponent(Component component) {
    component.transformOrRemoveChildren(this);
  }

  bool _isUnreachable(TreeNode node) {
    final callSite = shaker.typeFlowAnalysis.callSite(node);
    return (callSite != null) && !callSite.isReachable;
  }

  List<Expression> _flattenArguments(Arguments arguments,
      {Expression? receiver}) {
    final args = <Expression>[];
    if (receiver != null) {
      args.add(receiver);
    }
    args.addAll(arguments.positional);
    args.addAll(arguments.named.map((a) => a.value));
    return args;
  }

  bool _isThrowExpression(Expression expr) {
    for (;;) {
      if (expr is Let) {
        expr = expr.body;
      } else if (expr is BlockExpression) {
        expr = expr.value;
      } else {
        break;
      }
    }
    return expr is Throw;
  }

  Expression _evaluateArguments(List<Expression> args, Expression result) {
    final List<ast.Statement> statements = <ast.Statement>[];
    for (var arg in args) {
      if (mayHaveSideEffects(arg)) {
        if (arg is BlockExpression && !mayHaveSideEffects(arg.value)) {
          statements.add(arg.body);
        } else {
          statements.add(ExpressionStatement(arg));
        }
      }
    }
    if (statements.isEmpty) {
      return result;
    }
    // Merge nested BlockExpression nodes.
    Expression value = result;
    if (result is BlockExpression) {
      statements.addAll(result.body.statements);
      value = result.value;
    }
    return BlockExpression(Block(statements), value);
  }

  Expression _makeUnreachableCall(List<Expression> args) {
    Expression node;
    final int last = args.indexWhere(_isThrowExpression);
    if (last >= 0) {
      // One of the arguments is a Throw expression.
      // Ignore the rest of the arguments.
      node = args[last];
      args = args.sublist(0, last);
      Statistics.throwExpressionsPruned++;
    } else {
      node = Throw(StringLiteral(
          'Attempt to execute code removed by Dart AOT compiler (TFA)'));
    }
    Statistics.callsDropped++;
    return _evaluateArguments(args, node);
  }

  TreeNode _makeUnreachableInitializer(List<Expression> args) {
    return new LocalInitializer(new VariableDeclaration(null,
        initializer: _makeUnreachableCall(args), isSynthesized: true));
  }

  NarrowNotNull? _getNullTest(TreeNode node) =>
      shaker.typeFlowAnalysis.nullTest(node);

  TreeNode _visitAssertNode(TreeNode node, TreeNode? removalSentinel) {
    if (kRemoveAsserts) {
      return removalSentinel!;
    } else {
      node.transformOrRemoveChildren(this);
      return node;
    }
  }

  @override
  DartType visitDartType(DartType node, DartType? removalSentinel) {
    node.accept(shaker.typeVisitor);
    return node;
  }

  @override
  Supertype visitSupertype(Supertype node, Supertype? removalSentinel) {
    node.accept(shaker.typeVisitor);
    return node;
  }

  @override
  TreeNode visitTypedef(Typedef node, TreeNode? removalSentinel) {
    return node; // Do not go deeper.
  }

  @override
  TreeNode visitExtension(Extension node, TreeNode? removalSentinel) {
    // The extension can be considered a weak node, we'll only retain it if
    // normal code references any of it's members.
    return node;
  }

  @override
  TreeNode visitExtensionTypeDeclaration(
      ExtensionTypeDeclaration node, TreeNode? removalSentinel) {
    // The extension type declaration can be considered a weak node, we'll only
    // retain it if normal code references any of it's members.
    return node;
  }

  @override
  TreeNode visitClass(Class node, TreeNode? removalSentinel) {
    if (shaker.isClassAllocated(node) ||
        shaker.isClassReferencedFromNativeCode(node)) {
      shaker.addClassUsedInType(node);
    }
    transformConstructorList(node.constructors, node);
    transformProcedureList(node.procedures, node);
    transformFieldList(node.fields, node);
    return node;
  }

  @override
  TreeNode defaultMember(Member node, TreeNode? removalSentinel) {
    currentMember = node;
    if (shaker.isMemberBodyReachable(node)) {
      if (kPrintTrace) {
        tracePrint("Visiting $node");
      }
      shaker.addUsedMember(node);
      node.transformOrRemoveChildren(this);
    } else if (shaker.isMemberReferencedFromNativeCode(node)) {
      // Preserve members referenced from native code to satisfy lookups, even
      // if they are not reachable. An instance member could be added via
      // native code entry point but still unreachable if no instances of
      // its enclosing class are allocated.
      shaker.addUsedMember(node);
    }
    currentMember = null;
    return node;
  }

  @override
  TreeNode visitField(Field node, TreeNode? removalSentinel) {
    currentMember = node;
    if (shaker.retainField(node)) {
      if (kPrintTrace) {
        tracePrint("Visiting $node");
      }
      shaker.addUsedMember(node);
      if (node.initializer != null) {
        if (shaker.isFieldInitializerReachable(node)) {
          node.transformOrRemoveChildren(this);
        } else {
          node.initializer = _makeUnreachableCall([])..parent = node;
        }
      }
    } else if (shaker.isFieldSetterReachable(node) && !node.isStatic) {
      // Make sure setter is created to replace the field even if field is not
      // used as an instance call target.
      fieldMorpher.adjustInstanceCallTarget(node, isSetter: true);
    }
    currentMember = null;
    return node;
  }

  @override
  TreeNode visitLoadLibrary(LoadLibrary node, TreeNode? removalSentinel) {
    shaker._usedLibraries.add(node.import.targetLibrary);
    return node;
  }

  @override
  TreeNode visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, TreeNode? removalSentinel) {
    shaker._usedLibraries.add(node.import.targetLibrary);
    return node;
  }

  @override
  TreeNode visitInstanceInvocation(
      InstanceInvocation node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(
          _flattenArguments(node.arguments, receiver: node.receiver));
    }
    node.interfaceTarget = fieldMorpher
        .adjustInstanceCallTarget(node.interfaceTarget) as Procedure;
    shaker.addUsedMember(node.interfaceTarget);
    return node;
  }

  @override
  TreeNode visitDynamicInvocation(
      DynamicInvocation node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(
          _flattenArguments(node.arguments, receiver: node.receiver));
    }
    return node;
  }

  @override
  TreeNode visitLocalFunctionInvocation(
      LocalFunctionInvocation node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    }
    return node;
  }

  @override
  TreeNode visitFunctionInvocation(
      FunctionInvocation node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(
          _flattenArguments(node.arguments, receiver: node.receiver));
    }
    return node;
  }

  @override
  TreeNode visitEqualsCall(EqualsCall node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.left, node.right]);
    }
    node.interfaceTarget = fieldMorpher
        .adjustInstanceCallTarget(node.interfaceTarget) as Procedure;
    shaker.addUsedMember(node.interfaceTarget);
    return node;
  }

  @override
  TreeNode visitEqualsNull(EqualsNull node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.expression]);
    }
    final nullTest = _getNullTest(node)!;
    if (nullTest.isAlwaysNull || nullTest.isAlwaysNotNull) {
      return _evaluateArguments([node.expression],
          BoolLiteral(nullTest.isAlwaysNull)..fileOffset = node.fileOffset);
    }
    return node;
  }

  @override
  TreeNode visitInstanceGet(InstanceGet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver]);
    } else {
      node.interfaceTarget =
          fieldMorpher.adjustInstanceCallTarget(node.interfaceTarget)!;
      shaker.addUsedMember(node.interfaceTarget);
      return node;
    }
  }

  @override
  TreeNode visitInstanceTearOff(
      InstanceTearOff node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver]);
    } else {
      node.interfaceTarget = fieldMorpher
          .adjustInstanceCallTarget(node.interfaceTarget) as Procedure;
      shaker.addUsedMember(node.interfaceTarget);
      return node;
    }
  }

  @override
  TreeNode visitDynamicGet(DynamicGet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver]);
    } else {
      return node;
    }
  }

  @override
  TreeNode visitFunctionTearOff(
      FunctionTearOff node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver]);
    } else {
      return node;
    }
  }

  @override
  TreeNode visitInstanceSet(InstanceSet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver, node.value]);
    } else {
      node.interfaceTarget = fieldMorpher
          .adjustInstanceCallTarget(node.interfaceTarget, isSetter: true)!;
      shaker.addUsedMember(node.interfaceTarget);
      return node;
    }
  }

  @override
  TreeNode visitDynamicSet(DynamicSet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver, node.value]);
    } else {
      return node;
    }
  }

  @override
  TreeNode visitSuperMethodInvocation(
      SuperMethodInvocation node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    } else {
      node.interfaceTarget = fieldMorpher
          .adjustInstanceCallTarget(node.interfaceTarget) as Procedure;
      shaker.addUsedMember(node.interfaceTarget);
      return node;
    }
  }

  @override
  TreeNode visitSuperPropertyGet(
      SuperPropertyGet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([]);
    } else {
      node.interfaceTarget =
          fieldMorpher.adjustInstanceCallTarget(node.interfaceTarget)!;
      shaker.addUsedMember(node.interfaceTarget);
      return node;
    }
  }

  @override
  TreeNode visitSuperPropertySet(
      SuperPropertySet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.value]);
    } else {
      node.interfaceTarget = fieldMorpher
          .adjustInstanceCallTarget(node.interfaceTarget, isSetter: true)!;
      shaker.addUsedMember(node.interfaceTarget);
      return node;
    }
  }

  @override
  TreeNode visitStaticInvocation(
      StaticInvocation node, TreeNode? removalSentinel) {
    if (StaticWeakReferences.isWeakReference(node)) {
      final target = StaticWeakReferences.getWeakReferenceTarget(node);
      if (shaker.isMemberBodyReachable(target)) {
        return transform(StaticWeakReferences.getWeakReferenceArgument(node));
      }
      return NullLiteral()..fileOffset = node.fileOffset;
    }
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    }

    final target = node.target;
    assert(shaker.isMemberBodyReachable(target),
        "Member body is not reachable: $target");

    return node;
  }

  @override
  TreeNode visitStaticGet(StaticGet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([]);
    } else {
      if (!shaker.isMemberBodyReachable(node.target)) {
        throw '${node.runtimeType} "$node" uses unreachable member '
            '${node.target} at ${node.location}';
      }
      return node;
    }
  }

  @override
  Constant visitConstant(Constant node, Constant? removalSentinel) {
    shaker.constantVisitor.analyzeConstant(node);
    return node;
  }

  @override
  TreeNode visitStaticSet(StaticSet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.value]);
    } else {
      final target = node.target;
      assert(shaker.isMemberBodyReachable(target),
          "Target should be reachable: $node");
      if (target is Field && !shaker.retainField(target)) {
        return node.value;
      }
      return node;
    }
  }

  @override
  TreeNode visitConstructorInvocation(
      ConstructorInvocation node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    } else {
      if (!shaker.isMemberBodyReachable(node.target)) {
        throw '${node.runtimeType} "$node" uses unreachable member '
            '${node.target} at ${node.location}';
      }
      return node;
    }
  }

  @override
  TreeNode visitRedirectingInitializer(
      RedirectingInitializer node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableInitializer(_flattenArguments(node.arguments));
    } else {
      assert(shaker.isMemberBodyReachable(node.target),
          "Target should be reachable: ${node.target}");
      return node;
    }
  }

  @override
  TreeNode visitSuperInitializer(
      SuperInitializer node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableInitializer(_flattenArguments(node.arguments));
    } else {
      // Can't assert that node.target is used due to partial mixin resolution.
      return node;
    }
  }

  @override
  TreeNode visitFieldInitializer(
      FieldInitializer node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableInitializer([node.value]);
    } else {
      final field = node.field;
      assert(shaker.isMemberBodyReachable(field),
          "Field should be reachable: ${field}");
      if (!shaker.retainField(field)) {
        if (mayHaveSideEffects(node.value)) {
          return LocalInitializer(VariableDeclaration(null,
              initializer: node.value, isSynthesized: true));
        } else {
          return removalSentinel!;
        }
      }
      return node;
    }
  }

  @override
  TreeNode visitAssertStatement(
      AssertStatement node, TreeNode? removalSentinel) {
    return _visitAssertNode(node, removalSentinel);
  }

  @override
  TreeNode visitAssertBlock(AssertBlock node, TreeNode? removalSentinel) {
    return _visitAssertNode(node, removalSentinel);
  }

  @override
  TreeNode visitAssertInitializer(
      AssertInitializer node, TreeNode? removalSentinel) {
    return _visitAssertNode(node, removalSentinel);
  }

  // Expression is an extended bool literal if it is
  //  - a BoolLiteral
  //  - a BlockExpression with a BoolLiteral value.
  bool _isExtendedBoolLiteral(Expression expr) =>
      expr is BoolLiteral ||
      (expr is BlockExpression && expr.value is BoolLiteral);

  // Returns value of an extended bool literal.
  bool _getExtendedBoolLiteralValue(Expression expr) => (expr is BoolLiteral)
      ? expr.value
      : ((expr as BlockExpression).value as BoolLiteral).value;

  // Returns Block corresponding to the given extended bool literal,
  // or null if the expression is a simple bool literal.
  Block? _getExtendedBoolLiteralBlock(Expression expr) =>
      (expr is BoolLiteral) ? null : (expr as BlockExpression).body;

  @override
  TreeNode visitIfStatement(IfStatement node, TreeNode? removalSentinel) {
    final condition = transform(node.condition);
    if (_isExtendedBoolLiteral(condition)) {
      final bool conditionValue = _getExtendedBoolLiteralValue(condition);
      final Block? conditionBlock = _getExtendedBoolLiteralBlock(condition);
      ast.Statement? body;
      if (conditionValue) {
        body = transform(node.then);
      } else {
        if (node.otherwise != null) {
          body = transformOrRemoveStatement(node.otherwise!);
        }
      }
      if (conditionBlock != null) {
        if (body != null) {
          conditionBlock.addStatement(body);
        }
        return conditionBlock;
      } else {
        return body ?? EmptyStatement();
      }
    }
    node.condition = condition..parent = node;
    node.then = transform(node.then)..parent = node;
    if (node.otherwise != null) {
      node.otherwise = transformOrRemoveStatement(node.otherwise!);
      node.otherwise?.parent = node;
    }
    return node;
  }

  @override
  visitConditionalExpression(
      ConditionalExpression node, TreeNode? removalSentinel) {
    final condition = transform(node.condition);
    if (_isExtendedBoolLiteral(condition)) {
      final bool value = _getExtendedBoolLiteralValue(condition);
      final Expression expr = transform(value ? node.then : node.otherwise);
      Expression result;
      if (condition is BlockExpression) {
        condition.value = expr;
        expr.parent = condition;
        result = condition;
      } else {
        result = expr;
      }
      if (node.staticType != result.getStaticType(staticTypeContext)) {
        return StaticInvocation(
            unsafeCast,
            Arguments([result],
                types: [visitDartType(node.staticType, cannotRemoveSentinel)]))
          ..fileOffset = node.fileOffset;
      } else {
        return result;
      }
    }
    node.condition = condition..parent = node;
    node.then = transform(node.then)..parent = node;
    node.otherwise = transform(node.otherwise)..parent = node;
    node.staticType = visitDartType(node.staticType, cannotRemoveSentinel);
    return node;
  }

  @override
  TreeNode visitNot(Not node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final operand = node.operand;
    if (_isExtendedBoolLiteral(operand)) {
      final bool value = _getExtendedBoolLiteralValue(operand);
      if (operand is BlockExpression) {
        (operand.value as BoolLiteral).value = !value;
      } else {
        (operand as BoolLiteral).value = !value;
      }
      return operand;
    }
    return node;
  }

  @override
  TreeNode visitLogicalExpression(
      LogicalExpression node, TreeNode? removalSentinel) {
    final left = transform(node.left);
    final operatorEnum = node.operatorEnum;
    if (_isExtendedBoolLiteral(left)) {
      final leftValue = _getExtendedBoolLiteralValue(left);
      if (leftValue && operatorEnum == LogicalExpressionOperator.OR) {
        return left;
      } else if (!leftValue && operatorEnum == LogicalExpressionOperator.AND) {
        return left;
      }
    }
    final right = transform(node.right);
    // Without sound null safety arguments of logical expression
    // are implicitly checked for null, so transform the node only
    // if using sound null safety or it evaluates to a bool literal.
    if (_isExtendedBoolLiteral(left) &&
        (shaker.typeFlowAnalysis.target.flags.soundNullSafety ||
            _isExtendedBoolLiteral(right))) {
      return _evaluateArguments([left], right);
    }
    node.left = left..parent = node;
    node.right = right..parent = node;
    return node;
  }

  @override
  TreeNode visitIsExpression(IsExpression node, TreeNode? removalSentinel) {
    TypeCheck? check = shaker.typeFlowAnalysis.isTest(node);
    if (check != null && (check.alwaysFail || check.alwaysPass)) {
      final operand = transform(node.operand);
      final result = BoolLiteral(!check.alwaysFail)
        ..fileOffset = node.fileOffset;
      return _evaluateArguments([operand], result);
    }
    node.transformOrRemoveChildren(this);
    return node;
  }

  @override
  TreeNode visitAsExpression(AsExpression node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    TypeCheck? check = shaker.typeFlowAnalysis.explicitCast(node);
    if (check != null && check.alwaysPass) {
      return StaticInvocation(
          unsafeCast, Arguments([node.operand], types: [node.type]))
        ..fileOffset = node.fileOffset;
    }
    return node;
  }

  @override
  TreeNode visitNullCheck(NullCheck node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final nullTest = _getNullTest(node)!;
    if (nullTest.isAlwaysNotNull) {
      return StaticInvocation(
          unsafeCast,
          Arguments([node.operand],
              types: [node.getStaticType(staticTypeContext)]))
        ..fileOffset = node.fileOffset;
    }
    return node;
  }

  late final Procedure unsafeCast = shaker
      .typeFlowAnalysis.environment.coreTypes.index
      .getTopLevelProcedure('dart:_internal', 'unsafeCast');
}

/// The second pass of [TreeShaker]. It is called after set of used
/// classes, members and typedefs is determined during the first pass.
/// This pass visits classes and members and removes unused classes and members.
/// Bodies of unreachable but used members are replaced with 'throw'
/// expressions. This pass does not dive deeper than member level.
class _TreeShakerPass2 extends RemovingTransformer {
  final TreeShaker shaker;

  _TreeShakerPass2(this.shaker);

  void transformComponent(Component component) {
    component.transformOrRemoveChildren(this);
    for (Source source in component.uriToSource.values) {
      source.constantCoverageConstructors?.removeWhere((Reference reference) {
        Member node = reference.asMember;
        return !shaker.isMemberUsed(node);
      });
    }
  }

  final _libraryExportDeps = <Library, Set<Library>>{};
  final _additionalDeps = <Library>{};

  // Returns set of export dependencies of given library.
  Set<Library> getLibraryExportDeps(Library node) =>
      _libraryExportDeps[node] ??= calculateLibraryExportDeps(node);

  Set<Library> calculateLibraryExportDeps(Library node) {
    final processed = <Library>{};
    final worklist = <Library>[];
    final deps = <Library>{};
    worklist.add(node);
    processed.add(node);
    while (worklist.isNotEmpty) {
      final lib = worklist.removeLast();
      for (final dep in lib.dependencies) {
        if (!dep.isExport) {
          continue;
        }
        final targetLibrary = dep.targetLibrary;
        if (processed.add(targetLibrary)) {
          if (shaker.isLibraryUsed(targetLibrary)) {
            deps.add(targetLibrary);
          } else {
            worklist.add(targetLibrary);
          }
        }
      }
    }
    return deps;
  }

  @override
  TreeNode visitLibrary(Library node, TreeNode? removalSentinel) {
    if (!shaker.isLibraryUsed(node) && node.importUri.scheme != 'dart') {
      return removalSentinel!;
    }
    _additionalDeps.clear();
    node.transformOrRemoveChildren(this);
    // The transformer API does not iterate over `Library.additionalExports`,
    // so we manually delete the references to shaken nodes.
    node.additionalExports.removeWhere((Reference reference) {
      final node = reference.node;
      if (node is Class) {
        return !shaker.isClassUsed(node);
      } else if (node is Typedef) {
        return !shaker.isTypedefUsed(node);
      } else if (node is Extension) {
        return !shaker.isExtensionUsed(node);
      } else if (node is ExtensionTypeDeclaration) {
        return !shaker.isExtensionTypeDeclarationUsed(node);
      } else {
        return !shaker.isMemberUsed(node as Member);
      }
    });
    // Add transitive export dependencies of the removed imported libraries.
    // This is needed to maintain connected library graph
    // which is critical for calculation of the deferred loading units.
    if (_additionalDeps.isNotEmpty) {
      for (final dep in node.dependencies) {
        _additionalDeps.remove(dep.targetLibrary);
      }
      for (final lib in _additionalDeps) {
        node.addDependency(LibraryDependency.import(lib));
      }
      _additionalDeps.clear();
    }
    return node;
  }

  @override
  TreeNode visitLibraryDependency(
      LibraryDependency node, TreeNode? removalSentinel) {
    final targetLibrary = node.targetLibrary;
    if (!shaker.isLibraryUsed(targetLibrary)) {
      _additionalDeps.addAll(getLibraryExportDeps(targetLibrary));
      return removalSentinel!;
    }
    return node;
  }

  @override
  TreeNode visitTypedef(Typedef node, TreeNode? removalSentinel) {
    return shaker.isTypedefUsed(node) ? node : removalSentinel!;
  }

  @override
  TreeNode visitClass(Class node, TreeNode? removalSentinel) {
    if (!shaker.isClassUsed(node)) {
      debugPrint('Dropped class ${node.name}');
      // Ensure that kernel file writer will not be able to
      // write a dangling reference to the deleted class.
      assert(
          node.reference.node == node,
          "Trying to remove canonical name from reference on $node which has "
          "been repurposed for ${node.reference.node}.");
      node.reference.canonicalName?.unbind();
      Statistics.classesDropped++;
      return removalSentinel!; // Remove the class.
    }

    if (!shaker.isClassUsedInType(node)) {
      debugPrint('Dropped supers from class ${node.name}');
      // The class is only a namespace for static members.  Remove its
      // hierarchy information.   This is mandatory, since these references
      // might otherwise become dangling.
      node.supertype = shaker
          .typeFlowAnalysis.environment.coreTypes.objectClass.asRawSupertype;
      node.implementedTypes.clear();
      node.typeParameters.clear();
      node.isAbstract = true;
      node.isEnum = false;
      // Mixin applications cannot have static members.
      assert(node.mixedInType == null);
      node.annotations = const <Expression>[];
    }

    if (!shaker.isClassAllocated(node)) {
      debugPrint('Class ${node.name} converted to abstract');
      node.isAbstract = true;
      node.isEnum = false;
    }

    node.transformOrRemoveChildren(this);

    return node;
  }

  @override
  TreeNode defaultMember(Member node, TreeNode? removalSentinel) {
    if (!shaker.isMemberUsed(node)) {
      // Ensure that kernel file writer will not be able to
      // write a dangling reference to the deleted member.
      if (node is Field) {
        assert(
            node.fieldReference.node == node,
            "Trying to remove canonical name from field reference on $node "
            "which has been repurposed for ${node.fieldReference.node}.");
        node.fieldReference.canonicalName?.unbind();
        assert(
            node.getterReference.node == node,
            "Trying to remove canonical name from getter reference on $node "
            "which has been repurposed for ${node.getterReference.node}.");
        node.getterReference.canonicalName?.unbind();
        if (node.hasSetter) {
          assert(
              node.setterReference!.node == node,
              "Trying to remove canonical name from reference on $node which "
              "has been repurposed for ${node.setterReference!.node}.");
          node.setterReference!.canonicalName?.unbind();
        }
      } else {
        assert(
            node.reference.node == node,
            "Trying to remove canonical name from reference on $node which has "
            "been repurposed for ${node.reference.node}.");
        node.reference.canonicalName?.unbind();
      }
      Statistics.membersDropped++;
      return removalSentinel!;
    }

    if (!shaker.isMemberBodyReachable(node)) {
      if (node is Procedure) {
        // Remove body of unused member.
        if (!node.isStatic && node.enclosingClass!.isAbstract) {
          node.isAbstract = true;
          node.function.body = null;
        } else {
          // If the enclosing class is not abstract, the method should still
          // have a body even if it can never be called.
          _makeUnreachableBody(node.function);
        }
        _removeDefaultValuesOfParameters(node.function);
        node.function.asyncMarker = AsyncMarker.Sync;
        switch (node.stubKind) {
          case ProcedureStubKind.Regular:
          case ProcedureStubKind.NoSuchMethodForwarder:
            break;
          case ProcedureStubKind.MemberSignature:
          case ProcedureStubKind.AbstractForwardingStub:
          case ProcedureStubKind.ConcreteForwardingStub:
          case ProcedureStubKind.AbstractMixinStub:
          case ProcedureStubKind.ConcreteMixinStub:
            // Make the stub look like a regular procedure so the stub target
            // isn't expected to be non-null, for instance by the verifier.
            node.stubKind = ProcedureStubKind.Regular;
            node.stubTarget = null;
            break;
        }
        Statistics.methodBodiesDropped++;
      } else if (node is Field) {
        node.initializer = null;
        Statistics.fieldInitializersDropped++;
      } else if (node is Constructor) {
        _makeUnreachableBody(node.function);
        _removeDefaultValuesOfParameters(node.function);
        node.initializers = const <Initializer>[];
        Statistics.constructorBodiesDropped++;
      } else {
        throw 'Unexpected member ${node.runtimeType}: $node';
      }
    }

    return node;
  }

  @override
  TreeNode visitExtension(Extension node, TreeNode? removalSentinel) {
    if (shaker.isExtensionUsed(node)) {
      int writeIndex = 0;
      for (int i = 0; i < node.members.length; ++i) {
        final ExtensionMemberDescriptor descriptor = node.members[i];

        // To avoid depending on the order in which members and extensions are
        // visited during the transformation, we handle both cases: either the
        // member was already removed or it will be removed later.
        final Reference memberReference = descriptor.member;
        final bool isBound = memberReference.node != null;
        if (isBound && shaker.isMemberUsed(memberReference.asMember)) {
          node.members[writeIndex++] = descriptor;
        }
      }
      node.members.length = writeIndex;

      // We only retain the extension if at least one member is retained.
      assert(node.members.isNotEmpty);
      return node;
    }
    return removalSentinel!;
  }

  @override
  TreeNode visitExtensionTypeDeclaration(
      ExtensionTypeDeclaration node, TreeNode? removalSentinel) {
    if (shaker.isExtensionTypeDeclarationUsed(node)) {
      int writeIndex = 0;
      for (int i = 0; i < node.members.length; ++i) {
        final ExtensionTypeMemberDescriptor descriptor = node.members[i];

        // To avoid depending on the order in which members and extension type
        // declarations are visited during the transformation, we handle both
        // cases: either the member was already removed or it will be removed
        // later.
        final Reference memberReference = descriptor.member;
        final bool isBound = memberReference.node != null;
        if (isBound && shaker.isMemberUsed(memberReference.asMember)) {
          node.members[writeIndex++] = descriptor;
        }
      }
      node.members.length = writeIndex;

      // We only retain the extension type declaration if at least one member is
      // retained.
      assert(node.members.isNotEmpty);
      return node;
    }
    return removalSentinel!;
  }

  void _makeUnreachableBody(FunctionNode function) {
    if (function.body != null) {
      function.body = new ExpressionStatement(new Throw(new StringLiteral(
          "Attempt to execute method removed by Dart AOT compiler (TFA)")))
        ..parent = function;
    }
  }

  void _removeDefaultValuesOfParameters(FunctionNode function) {
    for (var p in function.positionalParameters) {
      p.initializer = null;
    }
    for (var p in function.namedParameters) {
      p.initializer = null;
    }
  }

  @override
  TreeNode defaultTreeNode(TreeNode node, TreeNode? removalSentinel) {
    return node; // Do not traverse into other nodes.
  }
}

class _TreeShakerConstantVisitor extends ConstantVisitor<Null> {
  final TreeShaker shaker;
  final _TreeShakerTypeVisitor typeVisitor;
  final Set<Constant> constants = new Set<Constant>();
  final Set<InstanceConstant> instanceConstants = new Set<InstanceConstant>();

  _TreeShakerConstantVisitor(this.shaker, this.typeVisitor);

  analyzeConstant(Constant constant) {
    if (constants.add(constant)) {
      constant.accept(this);
    }
  }

  @override
  defaultConstant(Constant constant) {
    throw 'There is no support for constant "$constant" in TFA yet!';
  }

  @override
  visitNullConstant(NullConstant constant) {}

  @override
  visitBoolConstant(BoolConstant constant) {}

  @override
  visitIntConstant(IntConstant constant) {}

  @override
  visitDoubleConstant(DoubleConstant constant) {}

  @override
  visitSetConstant(SetConstant constant) {
    for (final entry in constant.entries) {
      analyzeConstant(entry);
    }
  }

  @override
  visitStringConstant(StringConstant constant) {}

  @override
  visitSymbolConstant(SymbolConstant constant) {
    final libraryRef = constant.libraryReference;
    if (libraryRef != null) {
      shaker._usedLibraries.add(libraryRef.asLibrary);
    }
    // The Symbol class and it's _name field are always retained.
  }

  @override
  visitMapConstant(MapConstant constant) {
    for (final entry in constant.entries) {
      analyzeConstant(entry.key);
      analyzeConstant(entry.value);
    }
  }

  @override
  visitListConstant(ListConstant constant) {
    for (final Constant entry in constant.entries) {
      analyzeConstant(entry);
    }
  }

  @override
  visitRecordConstant(RecordConstant constant) {
    for (var value in constant.positional) {
      analyzeConstant(value);
    }
    for (var value in constant.named.values) {
      analyzeConstant(value);
    }
  }

  @override
  visitInstanceConstant(InstanceConstant constant) {
    instanceConstants.add(constant);
    shaker.addClassUsedInType(constant.classNode);
    visitList(constant.typeArguments, typeVisitor);
    constant.fieldValues.forEach((Reference fieldRef, Constant value) {
      if (!shaker.retainField(fieldRef.asField)) {
        throw 'Constant $constant references field ${fieldRef.asField} '
            'which is not retained';
      }
      analyzeConstant(value);
    });
  }

  @override
  visitStaticTearOffConstant(StaticTearOffConstant constant) {
    shaker.addUsedMember(constant.target);
  }

  @override
  visitConstructorTearOffConstant(ConstructorTearOffConstant constant) {
    shaker.addUsedMember(constant.target);
  }

  @override
  visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant constant) {
    shaker.addUsedMember(constant.target);
  }

  @override
  visitInstantiationConstant(InstantiationConstant constant) {
    analyzeConstant(constant.tearOffConstant);
  }

  @override
  visitTypeLiteralConstant(TypeLiteralConstant constant) {
    constant.type.accept(typeVisitor);
  }
}
