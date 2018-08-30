// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformations based on type flow analysis.
library vm.transformations.type_flow.transformer;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/type_environment.dart';

import 'analysis.dart';
import 'native_code.dart';
import 'calls.dart';
import 'summary_collector.dart';
import 'types.dart';
import 'utils.dart';
import '../devirtualization.dart' show Devirtualization;
import '../../metadata/direct_call.dart';
import '../../metadata/inferred_type.dart';
import '../../metadata/unreachable.dart';

const bool kDumpAllSummaries =
    const bool.fromEnvironment('global.type.flow.dump.all.summaries');
const bool kDumpClassHierarchy =
    const bool.fromEnvironment('global.type.flow.dump.class.hierarchy');

/// Whole-program type flow analysis and transformation.
/// Assumes strong mode and closed world.
Component transformComponent(
    CoreTypes coreTypes, Component component, List<String> entryPoints,
    [PragmaAnnotationParser matcher]) {
  if ((entryPoints == null) || entryPoints.isEmpty) {
    throw 'Error: unable to perform global type flow analysis without entry points.';
  }

  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  final hierarchy = new ClassHierarchy(component,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  final types = new TypeEnvironment(coreTypes, hierarchy, strongMode: true);
  final libraryIndex = new LibraryIndex.all(component);

  if (kDumpAllSummaries) {
    Statistics.reset();
    new CreateAllSummariesVisitor(types).visitComponent(component);
    Statistics.print("All summaries statistics");
  }

  Statistics.reset();
  final analysisStopWatch = new Stopwatch()..start();

  final typeFlowAnalysis = new TypeFlowAnalysis(
      component, coreTypes, hierarchy, types, libraryIndex,
      entryPointsJSONFiles: entryPoints, matcher: matcher);

  Procedure main = component.mainMethod;
  final Selector mainSelector = new DirectSelector(main);
  typeFlowAnalysis.addRawCall(mainSelector);
  typeFlowAnalysis.process();

  analysisStopWatch.stop();

  if (kDumpClassHierarchy) {
    debugPrint(typeFlowAnalysis.hierarchyCache);
  }

  final transformsStopWatch = new Stopwatch()..start();

  new TreeShaker(component, typeFlowAnalysis).transformComponent(component);

  new TFADevirtualization(component, typeFlowAnalysis)
      .visitComponent(component);

  new AnnotateKernel(component, typeFlowAnalysis).visitComponent(component);

  transformsStopWatch.stop();

  statPrint("TF analysis took ${analysisStopWatch.elapsedMilliseconds}ms");
  statPrint("TF transforms took ${transformsStopWatch.elapsedMilliseconds}ms");

  Statistics.print("TFA statistics");

  return component;
}

/// Devirtualization based on results of type flow analysis.
class TFADevirtualization extends Devirtualization {
  final TypeFlowAnalysis _typeFlowAnalysis;

  TFADevirtualization(Component component, this._typeFlowAnalysis)
      : super(_typeFlowAnalysis.environment.coreTypes, component,
            _typeFlowAnalysis.environment.hierarchy);

  @override
  DirectCallMetadata getDirectCall(TreeNode node, Member interfaceTarget,
      {bool setter = false}) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if (callSite != null) {
      final Member singleTarget = callSite.monomorphicTarget;
      if (singleTarget != null) {
        return new DirectCallMetadata(
            singleTarget, callSite.isNullableReceiver);
      }
    }
    return null;
  }
}

/// Annotates kernel AST with metadata using results of type flow analysis.
class AnnotateKernel extends RecursiveVisitor<Null> {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final InferredTypeMetadataRepository _inferredTypeMetadata;
  final UnreachableNodeMetadataRepository _unreachableNodeMetadata;
  final DartType _intType;

  AnnotateKernel(Component component, this._typeFlowAnalysis)
      : _inferredTypeMetadata = new InferredTypeMetadataRepository(),
        _unreachableNodeMetadata = new UnreachableNodeMetadataRepository(),
        _intType = _typeFlowAnalysis.environment.intType {
    component.addMetadataRepository(_inferredTypeMetadata);
    component.addMetadataRepository(_unreachableNodeMetadata);
  }

  InferredType _convertType(Type type) {
    assertx(type != null);

    Class concreteClass;
    bool isInt = false;

    final nullable = type is NullableType;
    if (nullable) {
      type = (type as NullableType).baseType;
    }

    if (nullable && type == const EmptyType()) {
      concreteClass = _typeFlowAnalysis.environment.coreTypes.nullClass;
    } else {
      concreteClass = type.getConcreteClass(_typeFlowAnalysis.hierarchyCache);

      if (concreteClass == null) {
        isInt = type.isSubtypeOf(_typeFlowAnalysis.hierarchyCache, _intType);
      }
    }

    if ((concreteClass != null) || !nullable || isInt) {
      return new InferredType(concreteClass, nullable, isInt);
    }

    return null;
  }

  void _setInferredType(TreeNode node, Type type) {
    final inferredType = _convertType(type);
    if (inferredType != null) {
      _inferredTypeMetadata.mapping[node] = inferredType;
    }
  }

  void _setUnreachable(TreeNode node) {
    _unreachableNodeMetadata.mapping[node] = const UnreachableNode();
  }

  void _annotateCallSite(TreeNode node) {
    final callSite = _typeFlowAnalysis.callSite(node);
    if (callSite != null) {
      if (callSite.isReachable) {
        if (callSite.isResultUsed) {
          _setInferredType(node, callSite.resultType);
        }
      } else {
        _setUnreachable(node);
      }
    }
  }

  void _annotateMember(Member member) {
    if (_typeFlowAnalysis.isMemberUsed(member)) {
      if (member is Field) {
        _setInferredType(member, _typeFlowAnalysis.fieldType(member));
      } else {
        Args<Type> argTypes = _typeFlowAnalysis.argumentTypes(member);
        assertx(argTypes != null);

        final int firstParamIndex = hasReceiverArg(member) ? 1 : 0;

        final positionalParams = member.function.positionalParameters;
        assertx(argTypes.positionalCount ==
            firstParamIndex + positionalParams.length);

        for (int i = 0; i < positionalParams.length; i++) {
          _setInferredType(
              positionalParams[i], argTypes.values[firstParamIndex + i]);
        }

        // TODO(dartbug.com/32292): make sure parameters are sorted in kernel
        // AST and iterate parameters in parallel, without lookup.
        final names = argTypes.names;
        for (int i = 0; i < names.length; i++) {
          final param = findNamedParameter(member.function, names[i]);
          assertx(param != null);
          _setInferredType(param,
              argTypes.values[firstParamIndex + positionalParams.length + i]);
        }

        // TODO(alexmarkov): figure out how to pass receiver type.
      }
    } else if (!member.isAbstract) {
      _setUnreachable(member);
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
  visitMethodInvocation(MethodInvocation node) {
    _annotateCallSite(node);
    super.visitMethodInvocation(node);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    _annotateCallSite(node);
    super.visitPropertyGet(node);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    _annotateCallSite(node);
    super.visitDirectMethodInvocation(node);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    _annotateCallSite(node);
    super.visitDirectPropertyGet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _annotateCallSite(node);
    super.visitSuperMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _annotateCallSite(node);
    super.visitSuperPropertyGet(node);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    _annotateCallSite(node);
    super.visitStaticInvocation(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    _annotateCallSite(node);
    super.visitStaticGet(node);
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
  final Set<Class> _usedClasses = new Set<Class>();
  final Set<Class> _classesUsedInType = new Set<Class>();
  final Set<Member> _usedMembers = new Set<Member>();
  final Set<Typedef> _usedTypedefs = new Set<Typedef>();
  _TreeShakerTypeVisitor typeVisitor;
  _TreeShakerConstantVisitor constantVisitor;
  _TreeShakerPass1 _pass1;
  _TreeShakerPass2 _pass2;

  TreeShaker(Component component, this.typeFlowAnalysis) {
    typeVisitor = new _TreeShakerTypeVisitor(this);
    constantVisitor = new _TreeShakerConstantVisitor(this, typeVisitor);
    _pass1 = new _TreeShakerPass1(this);
    _pass2 = new _TreeShakerPass2(this);
  }

  transformComponent(Component component) {
    _pass1.transform(component);
    _pass2.transform(component);
  }

  bool isClassUsed(Class c) => _usedClasses.contains(c);
  bool isClassUsedInType(Class c) => _classesUsedInType.contains(c);
  bool isClassAllocated(Class c) => typeFlowAnalysis.isClassAllocated(c);
  bool isMemberUsed(Member m) => _usedMembers.contains(m);
  bool isMemberBodyReachable(Member m) => typeFlowAnalysis.isMemberUsed(m);
  bool isMemberReferencedFromNativeCode(Member m) =>
      typeFlowAnalysis.nativeCodeOracle.isMemberReferencedFromNativeCode(m);
  bool isTypedefUsed(Typedef t) => _usedTypedefs.contains(t);

  void addClassUsedInType(Class c) {
    if (_classesUsedInType.add(c)) {
      if (kPrintDebug) {
        debugPrint('Class ${c.name} used in type');
      }
      _usedClasses.add(c);
      visitIterable(c.supers, typeVisitor);
      visitList(c.typeParameters, typeVisitor);
      transformList(c.annotations, _pass1, c);
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

      FunctionNode func = null;
      if (m is Field) {
        m.type.accept(typeVisitor);
      } else if (m is Procedure) {
        func = m.function;
        if (m.forwardingStubSuperTarget != null) {
          addUsedMember(m.forwardingStubSuperTarget);
        }
        if (m.forwardingStubInterfaceTarget != null) {
          addUsedMember(m.forwardingStubInterfaceTarget);
        }
      } else if (m is Constructor) {
        func = m.function;
      } else {
        throw 'Unexpected member ${m.runtimeType}: $m';
      }

      if (func != null) {
        visitList(func.typeParameters, typeVisitor);
        visitList(func.positionalParameters, typeVisitor);
        visitList(func.namedParameters, typeVisitor);
        func.returnType.accept(typeVisitor);
      }

      transformList(m.annotations, _pass1, m);
    }
  }

  void addUsedTypedef(Typedef typedef) {
    if (_usedTypedefs.add(typedef)) {
      transformList(typedef.annotations, _pass1, typedef);
      visitList(typedef.typeParameters, typeVisitor);
      typedef.type?.accept(typeVisitor);
    }
  }
}

/// Visits Dart types and collects all classes and typedefs used in types.
/// This visitor is used during pass 1 of tree shaking. It is a separate
/// visitor because [Transformer] does not provide a way to traverse types.
class _TreeShakerTypeVisitor extends RecursiveVisitor<Null> {
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
  }

  @override
  visitFunctionType(FunctionType node) {
    node.visitChildren(this);
    final typedef = node.typedef;
    if (typedef != null) {
      shaker.addUsedTypedef(typedef);
    }
  }

  @override
  visitTypeParameterType(TypeParameterType node) {
    final parent = node.parameter.parent;
    if (parent is Class) {
      shaker.addClassUsedInType(parent);
    }
  }
}

/// The first pass of [TreeShaker].
/// Visits all classes, members and bodies of reachable members.
/// Collects all used classes, members and types, and
/// transforms unreachable calls into 'throw' expressions.
class _TreeShakerPass1 extends Transformer {
  final TreeShaker shaker;

  _TreeShakerPass1(this.shaker);

  void transform(Component component) {
    component.transformChildren(this);
  }

  bool _isUnreachable(TreeNode node) {
    final callSite = shaker.typeFlowAnalysis.callSite(node);
    return (callSite != null) && !callSite.isReachable;
  }

  List<Expression> _flattenArguments(Arguments arguments,
      {Expression receiver}) {
    final args = <Expression>[];
    if (receiver != null) {
      args.add(receiver);
    }
    args.addAll(arguments.positional);
    args.addAll(arguments.named.map((a) => a.value));
    return args;
  }

  bool _isThrowExpression(Expression expr) {
    while (expr is Let) {
      expr = (expr as Let).body;
    }
    return expr is Throw;
  }

  TreeNode _makeUnreachableCall(List<Expression> args) {
    TreeNode node;
    final int last = args.indexWhere(_isThrowExpression);
    if (last >= 0) {
      // One of the arguments is a Throw expression.
      // Ignore the rest of the arguments.
      node = args[last];
      args = args.sublist(0, last);
      Statistics.throwExpressionsPruned++;
    } else {
      node = new Throw(new StringLiteral(
          'Attempt to execute code removed by Dart AOT compiler (TFA)'));
    }
    for (var arg in args.reversed) {
      node = new Let(new VariableDeclaration(null, initializer: arg), node);
    }
    Statistics.callsDropped++;
    return node;
  }

  TreeNode _makeUnreachableInitializer(List<Expression> args) {
    return new LocalInitializer(
        new VariableDeclaration(null, initializer: _makeUnreachableCall(args)));
  }

  TreeNode _visitAssertNode(TreeNode node) {
    if (kRemoveAsserts) {
      return null;
    } else {
      node.transformChildren(this);
      return node;
    }
  }

  @override
  DartType visitDartType(DartType node) {
    node.accept(shaker.typeVisitor);
    return node;
  }

  @override
  Supertype visitSupertype(Supertype node) {
    node.accept(shaker.typeVisitor);
    return node;
  }

  @override
  TreeNode visitTypedef(Typedef node) {
    return node; // Do not go deeper.
  }

  @override
  TreeNode visitClass(Class node) {
    if (shaker.isClassAllocated(node)) {
      shaker.addClassUsedInType(node);
    }
    transformList(node.constructors, this, node);
    transformList(node.procedures, this, node);
    transformList(node.fields, this, node);
    transformList(node.redirectingFactoryConstructors, this, node);
    return node;
  }

  @override
  TreeNode defaultMember(Member node) {
    if (shaker.isMemberBodyReachable(node)) {
      if (kPrintTrace) {
        tracePrint("Visiting $node");
      }
      shaker.addUsedMember(node);
      node.transformChildren(this);
    } else if (shaker.isMemberReferencedFromNativeCode(node)) {
      // Preserve members referenced from native code to satisfy lookups, even
      // if they are not reachable. An instance member could be added via
      // native code entry point but still unreachable if no instances of
      // its enclosing class are allocated.
      shaker.addUsedMember(node);
    }
    return node;
  }

  @override
  TreeNode visitMethodInvocation(MethodInvocation node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(
          _flattenArguments(node.arguments, receiver: node.receiver));
    } else {
      if (node.interfaceTarget != null) {
        shaker.addUsedMember(node.interfaceTarget);
      }
      return node;
    }
  }

  @override
  TreeNode visitPropertyGet(PropertyGet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver]);
    } else {
      if (node.interfaceTarget != null) {
        shaker.addUsedMember(node.interfaceTarget);
      }
      return node;
    }
  }

  @override
  TreeNode visitPropertySet(PropertySet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver, node.value]);
    } else {
      if (node.interfaceTarget != null) {
        shaker.addUsedMember(node.interfaceTarget);
      }
      return node;
    }
  }

  @override
  TreeNode visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    } else {
      if (node.interfaceTarget != null) {
        shaker.addUsedMember(node.interfaceTarget);
      }
      return node;
    }
  }

  @override
  TreeNode visitSuperPropertyGet(SuperPropertyGet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([]);
    } else {
      if (node.interfaceTarget != null) {
        shaker.addUsedMember(node.interfaceTarget);
      }
      return node;
    }
  }

  @override
  TreeNode visitSuperPropertySet(SuperPropertySet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.value]);
    } else {
      if (node.interfaceTarget != null) {
        shaker.addUsedMember(node.interfaceTarget);
      }
      return node;
    }
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    } else {
      assertx(shaker.isMemberBodyReachable(node.target), details: node.target);
      return node;
    }
  }

  @override
  TreeNode visitStaticGet(StaticGet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([]);
    } else {
      if (!shaker.isMemberBodyReachable(node.target)) {
        // Annotations could contain references to constant fields.
        assertx((node.target is Field) && (node.target as Field).isConst);
        shaker.addUsedMember(node.target);
      }
      return node;
    }
  }

  @override
  TreeNode visitConstantExpression(ConstantExpression node) {
    shaker.constantVisitor.analyzeConstant(node.constant);
    return node;
  }

  @override
  TreeNode visitStaticSet(StaticSet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.value]);
    } else {
      assertx(shaker.isMemberBodyReachable(node.target), details: node.target);
      return node;
    }
  }

  @override
  TreeNode visitDirectMethodInvocation(DirectMethodInvocation node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(
          _flattenArguments(node.arguments, receiver: node.receiver));
    } else {
      assertx(shaker.isMemberBodyReachable(node.target), details: node.target);
      return node;
    }
  }

  @override
  TreeNode visitDirectPropertyGet(DirectPropertyGet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver]);
    } else {
      assertx(shaker.isMemberBodyReachable(node.target), details: node.target);
      return node;
    }
  }

  @override
  TreeNode visitDirectPropertySet(DirectPropertySet node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall([node.receiver, node.value]);
    } else {
      assertx(shaker.isMemberBodyReachable(node.target), details: node.target);
      return node;
    }
  }

  @override
  TreeNode visitConstructorInvocation(ConstructorInvocation node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableCall(_flattenArguments(node.arguments));
    } else {
      if (!shaker.isMemberBodyReachable(node.target)) {
        // Annotations could contain references to const constructors.
        assertx(node.isConst);
        shaker.addUsedMember(node.target);
      }
      return node;
    }
  }

  @override
  TreeNode visitRedirectingInitializer(RedirectingInitializer node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableInitializer(_flattenArguments(node.arguments));
    } else {
      assertx(shaker.isMemberBodyReachable(node.target), details: node.target);
      return node;
    }
  }

  @override
  TreeNode visitSuperInitializer(SuperInitializer node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableInitializer(_flattenArguments(node.arguments));
    } else {
      // Can't assert that node.target is used due to partial mixin resolution.
      return node;
    }
  }

  @override
  visitFieldInitializer(FieldInitializer node) {
    node.transformChildren(this);
    if (_isUnreachable(node)) {
      return _makeUnreachableInitializer([node.value]);
    } else {
      assertx(shaker.isMemberBodyReachable(node.field), details: node.field);
      return node;
    }
  }

  @override
  TreeNode visitAssertStatement(AssertStatement node) {
    return _visitAssertNode(node);
  }

  @override
  TreeNode visitAssertBlock(AssertBlock node) {
    return _visitAssertNode(node);
  }

  @override
  TreeNode visitAssertInitializer(AssertInitializer node) {
    return _visitAssertNode(node);
  }
}

/// The second pass of [TreeShaker]. It is called after set of used
/// classes, members and typedefs is determined during the first pass.
/// This pass visits classes and members and removes unused classes and member.
/// Bodies of unreachable but used members are replaced with 'throw'
/// expressions. This pass does not dive deeper than member level.
class _TreeShakerPass2 extends Transformer {
  final TreeShaker shaker;

  _TreeShakerPass2(this.shaker);

  void transform(Component component) {
    component.transformChildren(this);
  }

  @override
  TreeNode visitLibrary(Library node) {
    node.transformChildren(this);
    // The transformer API does not iterate over `Library.additionalExports`,
    // so we manually delete the references to shaken nodes.
    node.additionalExports.removeWhere((Reference reference) {
      final node = reference.node;
      if (node is Class) {
        return !shaker.isClassUsed(node);
      } else if (node is Typedef) {
        return !shaker.isTypedefUsed(node);
      } else {
        return !shaker.isMemberUsed(node as Member);
      }
    });
    return node;
  }

  @override
  Typedef visitTypedef(Typedef node) {
    return shaker.isTypedefUsed(node) ? node : null;
  }

  @override
  Class visitClass(Class node) {
    if (!shaker.isClassUsed(node)) {
      debugPrint('Dropped class ${node.name}');
      node.canonicalName?.unbind();
      Statistics.classesDropped++;
      return null; // Remove the class.
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
      // Mixin applications cannot have static members.
      assertx(node.mixedInType == null);
      node.annotations = const <Expression>[];
    }

    if (!shaker.isClassAllocated(node)) {
      debugPrint('Class ${node.name} converted to abstract');
      node.isAbstract = true;
    }

    node.transformChildren(this);

    return node;
  }

  /// Preserve instance fields of enums as VM relies on their existence.
  bool _preserveSpecialMember(Member node) =>
      node is Field &&
      !node.isStatic &&
      node.enclosingClass != null &&
      node.enclosingClass.isEnum;

  @override
  Member defaultMember(Member node) {
    if (!shaker.isMemberUsed(node) && !_preserveSpecialMember(node)) {
      node.canonicalName?.unbind();
      Statistics.membersDropped++;
      return null;
    }

    if (!shaker.isMemberBodyReachable(node)) {
      if (node is Procedure) {
        // Remove body of unused member.
        if (!node.isStatic && node.enclosingClass.isAbstract) {
          node.isAbstract = true;
          node.function.body = null;
        } else {
          // If the enclosing class is not abstract, the method should still
          // have a body even if it can never be called.
          _makeUnreachableBody(node.function);
        }
        node.function.asyncMarker = AsyncMarker.Sync;
        node.forwardingStubSuperTargetReference = null;
        node.forwardingStubInterfaceTargetReference = null;
        Statistics.methodBodiesDropped++;
      } else if (node is Field) {
        node.initializer = null;
        Statistics.fieldInitializersDropped++;
      } else if (node is Constructor) {
        _makeUnreachableBody(node.function);
        node.initializers = const <Initializer>[];
        Statistics.constructorBodiesDropped++;
      } else {
        throw 'Unexpected member ${node.runtimeType}: $node';
      }
    }

    return node;
  }

  void _makeUnreachableBody(FunctionNode function) {
    if (function.body != null) {
      function.body = new ExpressionStatement(new Throw(new StringLiteral(
          "Attempt to execute method removed by Dart AOT compiler (TFA)")))
        ..parent = function;
    }
  }

  @override
  TreeNode defaultTreeNode(TreeNode node) {
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
  visitStringConstant(StringConstant constant) {}

  @override
  visitMapConstant(MapConstant node) {
    throw 'The kernel2kernel constants transformation desugars const maps!';
  }

  @override
  visitListConstant(ListConstant constant) {
    for (final Constant entry in constant.entries) {
      analyzeConstant(entry);
    }
  }

  @override
  visitInstanceConstant(InstanceConstant constant) {
    instanceConstants.add(constant);
    shaker.addClassUsedInType(constant.klass);
    constant.fieldValues.forEach((Reference fieldRef, Constant value) {
      shaker.addUsedMember(fieldRef.asField);
      analyzeConstant(value);
    });
  }

  @override
  visitTearOffConstant(TearOffConstant constant) {
    shaker.addUsedMember(constant.procedure);
  }

  @override
  visitPartialInstantiationConstant(PartialInstantiationConstant constant) {
    analyzeConstant(constant.tearOffConstant);
  }

  @override
  visitTypeLiteralConstant(TypeLiteralConstant constant) {
    constant.type.accept(typeVisitor);
  }
}
