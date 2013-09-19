// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'dart:collection' show Queue, LinkedHashSet, IterableBase, HashMap;
import '../dart_types.dart' show DartType, InterfaceType, TypeKind;
import '../elements/elements.dart';
import '../tree/tree.dart' show Node;
import 'types.dart' show TypeMask, ContainerTypeMask, TypesInferrer;
import '../universe/universe.dart' show Selector, TypedSelector, SideEffects;
import '../dart2jslib.dart' show Compiler, SourceString, TreeElementMapping;
import 'inferrer_visitor.dart' show TypeSystem, ArgumentsTypes, CallSite;
import '../native_handler.dart' as native;
import '../util/util.dart' show Spannable;
import 'simple_types_inferrer.dart';
import '../dart2jslib.dart' show invariant;

/**
 * Common class for all nodes in the graph. The current nodes are:
 *
 * - Concrete types
 * - Elements
 * - Call sites
 * - Narrowing instructions
 * - Phi instructions
 * - Containers (for lists)
 * - Type of the element in a container
 *
 * A node has a set of assignments and users. Assignments are used to
 * compute the type of the node ([TypeInformation.refine]). Users are
 * added to the inferrer's work queue when the type of the node
 * changes.
 */
abstract class TypeInformation {
  var /* List|Set */ users;
  var /* List|ParameterAssignments */ assignments;

  /// The type the inferrer has found for this [TypeInformation].
  /// Initially dynamic.
  TypeMask type;

  /// We give up on inferencing for special elements, as well as for
  /// complicated cyclic dependencies.
  bool abandonInferencing = false;

  /// Number of times this [TypeInformation] has changed type.
  int refineCount = 0;

  /// Whether this [TypeInformation] is currently in the inferrer's
  /// work queue.
  bool inQueue = false;

  // TypeInformations are unique.
  static int staticHashCode = 0;
  final int hashCode = staticHashCode++;

  bool get isConcrete => false;

  TypeInformation(this.type, [users, assignments])
      : users = (users == null) ? new Set<TypeInformation>() : users,
        assignments = (assignments == null) ? <TypeInformation>[] : assignments;
      

  void addUser(TypeInformation user) {
    assert(!user.isConcrete);
    users.add(user);
  }

  void removeUser(TypeInformation user) {
    assert(!user.isConcrete);
    users.remove(user);
  }

  void addAssignment(TypeInformation assignment) {
    if (abandonInferencing) return;
    // Cheap one-level cycle detection.
    if (assignment == this) return;
    assignments.add(assignment);
    assignment.addUser(this);
  }

  void removeAssignment(TypeInformation assignment) {
    if (!abandonInferencing) {
      assignments.remove(assignment);
    }
    // We can have multiple assignments of the same [TypeInformation].
    if (!assignments.contains(assignment)) {
      assignment.removeUser(this);
    }
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return type;
  }

  TypeMask refineOptimistic(TypeGraphInferrerEngine inferrer) {
    return refine(inferrer);
  }

  void giveUp(TypeGraphInferrerEngine inferrer) {
    abandonInferencing = true;
    type = inferrer.types.dynamicType.type;
    assignments = const <TypeInformation>[];
  }

  void clear() {
    assignments = const <TypeInformation>[];
    users = const <TypeInformation>[];
  }
}

/**
 * Parameters of instance functions behave differently than other
 * elements because the inferrer may remove assignments. This happens
 * when the receiver of a dynamic call site can be refined
 * to a type where we know more about which instance method is being
 * called.
 */
class ParameterAssignments extends IterableBase<TypeInformation> {
  final Map<TypeInformation, int> assignments =
      new HashMap<TypeInformation, int>();

  void remove(TypeInformation info) {
    int existing = assignments[info];
    if (existing == null) return;
    if (existing == 1) {
      assignments.remove(info);
    } else {
      assignments[info] = existing - 1;
    }
  }

  void add(TypeInformation info) {
    int existing = assignments[info];
    if (existing == null) {
      assignments[info] = 1;
    } else {
      assignments[info] = existing + 1;
    }
  }

  Iterator<TypeInformation> get iterator => assignments.keys.iterator;
  Iterable<TypeInformation> where(Function f) => assignments.keys.where(f);

  bool contains(TypeInformation info) => assignments.containsKey(info);
}

/**
 * A node representing a resolved element of the program. The kind of
 * elements that need an [ElementTypeRepresentation] are:
 *
 * - Functions (including getters and setters)
 * - Constructors (factory or generative)
 * - Fields
 * - Parameters
 * - Local variables mutated in closures
 *
 * The [ElementTypeInformation] of a function and a constructor is its
 * return type.
 *
 * Note that a few elements of these kinds must be treated specially,
 * and they are dealt in [ElementTypeInformation.handleSpecialCase]:
 *
 * - Parameters of closures, [noSuchMethod] and [call] instance
 *   methods: we currently do not infer types for those.
 *
 * - Fields and parameters being assigned by synthesized calls done by
 *   the backend: we do not know what types the backend will use.
 *
 * - Native functions and fields: because native methods contain no Dart
 *   code, and native fields do not have Dart assignments, we just
 *   trust their type annotation.
 *   
 */
class ElementTypeInformation extends TypeInformation {
  final Element element;
  final Map<Element, Set<Spannable>> callers =
      new Map<Element, Set<Spannable>>();

  ElementTypeInformation.internal(this.element, type, assignments)
      : super(type, null, assignments);

  factory ElementTypeInformation(Element element, TypeMask type) {
    var assignments = null;
    if (element.enclosingElement.isInstanceMember()
        && (element.isParameter() || element.isFieldParameter())) {
      assignments = new ParameterAssignments();
    }
    return new ElementTypeInformation.internal(element, type, assignments);
  }

  void addCall(Element caller, Spannable node) {
    callers.putIfAbsent(caller, () => new Set<Spannable>()).add(node);
  }

  void removeCall(Element caller, Spannable node) {
    Set<Spannable> calls = callers[caller];
    if (calls == null) return;
    calls.remove(node);
    if (calls.isEmpty) {
      callers.remove(caller);
    }
  }

  TypeMask handleSpecialCases(TypeGraphInferrerEngine inferrer) {
    if (abandonInferencing) {
      return type;
    }
    if (element.isParameter()) {
      Element enclosing = element.enclosingElement;
      if (Elements.isLocal(enclosing)) {
        // Do not infer types for parameters of closures.
        giveUp(inferrer);
        return type;
      } else if (enclosing.isInstanceMember()
                 && (enclosing.name == Compiler.NO_SUCH_METHOD
                     || enclosing.name == Compiler.CALL_OPERATOR_NAME)) {
        // Do not infer types for parameters of [noSuchMethod] and
        // [call] instance methods.
        giveUp(inferrer);
        return type;
      }
    }
    if (element.isField()
        || element.isParameter()
        || element.isFieldParameter()) {
      if (!inferrer.compiler.backend.canBeUsedForGlobalOptimizations(element)) {
        // Do not infer types for fields and parameters being assigned
        // by synthesized calls.
        giveUp(inferrer);
        return type;
      }
    }
    if (inferrer.isNativeElement(element)) {
      // Use the type annotation as the type for native elements. We
      // also give up on inferring to make sure this element never
      // goes in the work queue.
      giveUp(inferrer);
      if (element.isField()) {
        InterfaceType rawType = element.computeType(inferrer.compiler).asRaw();
        return rawType.treatAsDynamic
            ? inferrer.types.dynamicType.type
            : new TypeMask.subtype(rawType);
      } else {
        assert(element.isFunction()
               || element.isGetter()
               || element.isSetter());
        var elementType = element.computeType(inferrer.compiler);
        if (elementType.kind != TypeKind.FUNCTION) {
          return type;
        } else {
          return inferrer.typeOfNativeBehavior(
              native.NativeBehavior.ofMethod(element, inferrer.compiler)).type;
        }
      }
    }
    return null;
  }

  TypeMask potentiallyNarrowType(TypeMask mask,
                                 TypeGraphInferrerEngine inferrer) {
    Compiler compiler = inferrer.compiler;
    if (!compiler.trustTypeAnnotations && !compiler.enableTypeAssertions) {
      return mask;
    }
    if (element.isGenerativeConstructor() || element.isSetter()) return mask;
    var type = element.computeType(compiler);
    if (element.isFunction()
        || element.isGetter()
        || element.isFactoryConstructor()) {
      type = type.returnType;
    }
    return new TypeMaskSystem(compiler).narrowType(mask, type);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    TypeMask special = handleSpecialCases(inferrer);
    if (special != null) return potentiallyNarrowType(special, inferrer);
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(assignments), inferrer);
  }

  TypeMask refineOptimistic(TypeGraphInferrerEngine inferrer) {
    TypeMask special = handleSpecialCases(inferrer);
    if (special != null) return potentiallyNarrowType(special, inferrer);
    return potentiallyNarrowType(inferrer.types.computeTypeMask(
        assignments.where((e) => e.isConcrete)), inferrer);
  }

  String toString() => 'Element $element';
}

/**
 * A [CallSiteTypeInformation] is a call found in the AST, or a
 * synthesized call for implicit calls in Dart (such as forwarding
 * factories). The [call] field is a [Node] for the former, and an
 * [Element] for the latter.
 *
 * In the inferrer graph, [CallSiteTypeInformation] nodes do not have
 * any assignment. They rely on the [caller] field for static calls,
 * and [selector] and [receiver] fields for dynamic calls.
 */
abstract class CallSiteTypeInformation extends TypeInformation {
  final Spannable call;
  final Element caller;
  final Selector selector;
  final ArgumentsTypes arguments;

  CallSiteTypeInformation(
      this.call,
      this.caller,
      this.selector,
      this.arguments,
      TypeMask type) : super(type, null, const <TypeInformation>[]);

  String toString() => 'Call site $call';

  /// Add [this] to the graph being computed by [engine].
  void addToGraph(TypeGraphInferrerEngine engine);

  /// Return an iterable over the targets of this call.
  Iterable<Element> get callees;
}

class StaticCallSiteTypeInformation extends CallSiteTypeInformation {
  final Element calledElement;

  StaticCallSiteTypeInformation(
      Spannable call,
      Element enclosing,
      this.calledElement,
      Selector selector,
      ArgumentsTypes arguments,
      TypeMask type) : super(call, enclosing, selector, arguments, type);

  void addToGraph(TypeGraphInferrerEngine inferrer) {
    ElementTypeInformation callee =
        inferrer.types.getInferredTypeOf(calledElement);
    callee.addCall(caller, call);
    callee.addUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.addUser(this));
    }
    inferrer.updateParameterAssignments(
        this, calledElement, arguments, selector, remove: false, init: true);
  }

  bool get isSynthesized {
    // Some calls do not have a corresponding node, for example
    // fowarding factory constructors, or synthesized super
    // constructor calls. We synthesize these calls but do
    // not create a selector for them.
    return selector == null;
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    if (isSynthesized) {
      assert(arguments != null);
      return inferrer.types.getInferredTypeOf(calledElement).type;
    } else {
      return inferrer.typeOfElementWithSelector(calledElement, selector).type;
    }
  }

  Iterable<Element> get callees => [calledElement.implementation];
}

class DynamicCallSiteTypeInformation extends CallSiteTypeInformation {
  final TypeInformation receiver;
  /// Cached targets of this call.
  Iterable<Element> targets;

  DynamicCallSiteTypeInformation(
      Spannable call,
      Element enclosing,
      Selector selector,
      this.receiver,
      ArgumentsTypes arguments,
      TypeMask type) : super(call, enclosing, selector, arguments, type);

  void addToGraph(TypeGraphInferrerEngine inferrer) {
    assert(receiver != null);
    Selector typedSelector = computeTypedSelector(inferrer);
    targets = inferrer.compiler.world.allFunctions.filter(typedSelector);
    receiver.addUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.addUser(this));
    }
    for (Element element in targets) {
      ElementTypeInformation callee = inferrer.types.getInferredTypeOf(element);
      callee.addCall(caller, call);
      callee.addUser(this);
      inferrer.updateParameterAssignments(
          this, element, arguments, typedSelector, remove: false, init: true);
    }
  }

  Iterable<Element> get callees => targets.map((e) => e.implementation);

  Selector computeTypedSelector(TypeGraphInferrerEngine inferrer) {
    TypeMask receiverType = receiver.type;
    if (selector.mask != receiverType) {
      return receiverType == inferrer.compiler.typesTask.dynamicType
          ? selector.asUntyped
          : new TypedSelector(receiverType, selector);
    } else {
      return selector;
    }
  }

  bool hasOnePositionalArgumentWithType(TypeMask type) {
    return arguments.named.isEmpty
        && arguments.positional.length == 1
        && arguments.positional[0].type == type;
  }

  /**
   * We optimize certain operations on the [int] class because we know
   * more about their return type than the actual Dart code. For
   * example, we know int + int returns an int. The Dart code for
   * [int.operator+] only says it returns a [num].
   */
  TypeInformation handleIntrisifiedSelector(Selector selector,
                                            TypeGraphInferrerEngine inferrer) {
    if (!inferrer.compiler.backend.intImplementation.isResolved) return null;
    TypeMask intType = inferrer.compiler.typesTask.intType;
    if (selector.mask != intType) return null;
    if (!selector.isCall() && !selector.isOperator()) return null;
    if (!arguments.named.isEmpty) return null;
    if (arguments.positional.length > 1) return null;

    SourceString name = selector.name;
    if (name == const SourceString('*')
        || name == const SourceString('+')
        || name == const SourceString('%')
        || name == const SourceString('remainder')) {
        return hasOnePositionalArgumentWithType(intType)
            ? inferrer.types.intType
            : null;
    } else if (name == const SourceString('-')) {
      if (arguments.hasNoArguments()) return inferrer.types.intType;
      if (hasOnePositionalArgumentWithType(intType)) {
        return inferrer.types.intType;
      }
      return null;
    } else if (name == const SourceString('abs')) {
      return arguments.hasNoArguments() ? inferrer.types.intType : null;
    }
    return null;
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    Iterable<Element> oldTargets = targets;
    Selector typedSelector = computeTypedSelector(inferrer);
    inferrer.updateSelectorInTree(caller, call, typedSelector);
    targets = inferrer.compiler.world.allFunctions.filter(typedSelector);

    // Walk over the found targets, and compute the joined union type mask
    // for all these targets.
    TypeMask newType = inferrer.types.computeTypeMask(targets.map((element) {
      if (!oldTargets.contains(element)) {
        ElementTypeInformation callee =
            inferrer.types.getInferredTypeOf(element);
        callee.addCall(caller, call);
        callee.addUser(this);
        inferrer.updateParameterAssignments(
            this, element, arguments, typedSelector, remove: false);
      }
      
      if (receiver.type.isContainer && selector.isIndex()) {
        // Find the [ElementInContainerTypeInformation] node and tell
        // that this node is a user of it. Later, when the element
        // type changes, this node will be notified.
        ContainerTypeMask mask = receiver.type;
        ContainerTypeInformation container =
            inferrer.types.allocatedContainers[mask.allocationNode];
        ElementInContainerTypeInformation element = container.elementType;
        if (!element.users.contains(element)) {
          element.addUser(this);
        }
        return element;
      } else {
        TypeInformation info =
            handleIntrisifiedSelector(typedSelector, inferrer);
        if (info != null) return info;
        return inferrer.typeOfElementWithSelector(element, typedSelector);
      }
    }));

    // Walk over the old targets, and remove calls that cannot happen
    // anymore.
    oldTargets.forEach((element) {
      if (!targets.contains(element)) {
        ElementTypeInformation callee =
            inferrer.types.getInferredTypeOf(element);
        callee.removeCall(caller, call);
        callee.removeUser(this);
        inferrer.updateParameterAssignments(
            this, element, arguments, typedSelector, remove: true);
      }
    });
    return newType;
  }

  void giveUp(TypeGraphInferrerEngine inferrer) {
    inferrer.updateSelectorInTree(caller, call, selector);
    Iterable<Element> oldTargets = targets;
    targets = inferrer.compiler.world.allFunctions.filter(selector);
    for (Element element in targets) {
      if (!oldTargets.contains(element)) {
        ElementTypeInformation callee =
            inferrer.types.getInferredTypeOf(element);
        callee.addCall(caller, call);
        inferrer.updateParameterAssignments(
            this, element, arguments, selector, remove: false);
      }
    }
    super.giveUp(inferrer);
  }
}

/**
 * A [ConcreteTypeInformation] represents a type that needed
 * to be materialized during the creation of the graph. For example,
 * literals, [:this:] or [:super:] need a [ConcreteTypeInformation].
 *
 * [ConcreteTypeInformation] nodes have no assignment. Also, to save
 * on memory, we do not add users to [ConcreteTypeInformation] nodes,
 * because we know such node will never be refined to a different
 * type.
 */
class ConcreteTypeInformation extends TypeInformation {
  ConcreteTypeInformation(TypeMask type)
      : super(type, const <TypeInformation>[], const <TypeInformation>[]);

  bool get isConcrete => true;

  void addUser(TypeInformation user) {
    // Nothing to do, a concrete type does not get updated so never
    // needs to notify its users.
  }

  void removeUser(TypeInformation user) {
  }

  void addAssignment(TypeInformation assignment) {
  }

  void removeAssignment(TypeInformation assignment) {
    assert(false);
  }

  String toString() => 'Type $type';
}

/**
 * A [NarrowTypeInformation] narrows a [TypeInformation] to a type,
 * represented in [typeAnnotation].
 *
 * A [NarrowTypeInformation] node has only one assignment: the
 * [TypeInformation] it narrows.
 *
 * [NarrowTypeInformation] nodes are created for:
 *
 * - Code after `is` and `as` checks, where we have more information
 *   on the type of the right hand side of the expression.
 *
 * - Code after a dynamic call, where we have more information on the
 *   type of the receiver: it can only be of a class that holds a
 *   potential target of this dynamic call.
 *
 * - In checked mode, after a type annotation, we have more
 *   information on the type of a local.
 */
class NarrowTypeInformation extends TypeInformation {
  final TypeMask typeAnnotation;

  NarrowTypeInformation(narrowedType,
                        this.typeAnnotation,
                        TypeMask type) : super(type) {
    addAssignment(narrowedType);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return assignments[0].type.intersection(typeAnnotation, inferrer.compiler);
  }

  String toString() => 'Narrow ${assignments.first} to $typeAnnotation';
}

/**
 * A [ContainerTypeInformation] is a [ConcreteTypeInformation] created
 * for each `List` instantiations.
 */
class ContainerTypeInformation extends ConcreteTypeInformation {
  final TypeInformation elementType;

  ContainerTypeInformation(containerType, this.elementType)
      : super(containerType);

  String toString() => 'Container type';
}

/**
 * An [ElementInContainerTypeInformation] holds the common type of the
 * elements in a [ContainerTypeInformation].
 */
class ElementInContainerTypeInformation extends TypeInformation {
  final ContainerTypeMask container;

  ElementInContainerTypeInformation(elementType, this.container, type)
      : super(type) {
    // [elementType] is not null for const lists.
    if (elementType != null) addAssignment(elementType);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    if (assignments.isEmpty) return type;
    return container.elementType =
        inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Element in container';
}

/**
 * A [PhiElementTypeInformation] is an union of
 * [ElementTypeInformation], that is local to a method.
 */
class PhiElementTypeInformation extends TypeInformation {
  final Node branchNode;
  final bool isLoopPhi;
  final Element element;

  PhiElementTypeInformation(this.branchNode, this.isLoopPhi, this.element, type)
      : super(type);

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.computeTypeMask(assignments);
  }

  TypeMask refineOptimistic(TypeGraphInferrerEngine inferrer) {
    return isLoopPhi
        ? assignments[0].type
        : inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Phi $element';
}

class TypeInformationSystem extends TypeSystem<TypeInformation> {
  final Compiler compiler;

  /// [ElementTypeInformation]s for elements.
  final Map<Element, TypeInformation> typeInformations =
      new Map<Element, TypeInformation>();

  /// [ContainerTypeInformation] for allocated containers.
  final Map<Node, TypeInformation> allocatedContainers =
      new Map<Node, TypeInformation>();

  /// Cache of [ConcreteTypeInformation].
  final Map<TypeMask, TypeInformation> concreteTypes =
      new Map<TypeMask, TypeInformation>();

  /// List of [TypeInformation]s allocated inside method bodies (calls,
  /// narrowing, phis, and containers).
  final List<TypeInformation> allocatedTypes = <TypeInformation>[];

  TypeInformationSystem(this.compiler) {
    nonNullEmptyType = getConcreteTypeFor(const TypeMask.nonNullEmpty());
  }

  TypeInformation nullTypeCache;
  TypeInformation get nullType {
    if (nullTypeCache != null) return nullTypeCache;
    return nullTypeCache = getConcreteTypeFor(compiler.typesTask.nullType);
  }

  TypeInformation intTypeCache;
  TypeInformation get intType {
    if (intTypeCache != null) return intTypeCache;
    return intTypeCache = getConcreteTypeFor(compiler.typesTask.intType);
  }

  TypeInformation doubleTypeCache;
  TypeInformation get doubleType {
    if (doubleTypeCache != null) return doubleTypeCache;
    return doubleTypeCache = getConcreteTypeFor(compiler.typesTask.doubleType);
  }

  TypeInformation numTypeCache;
  TypeInformation get numType {
    if (numTypeCache != null) return numTypeCache;
    return numTypeCache = getConcreteTypeFor(compiler.typesTask.numType);
  }

  TypeInformation boolTypeCache;
  TypeInformation get boolType {
    if (boolTypeCache != null) return boolTypeCache;
    return boolTypeCache = getConcreteTypeFor(compiler.typesTask.boolType);
  }

  TypeInformation functionTypeCache;
  TypeInformation get functionType {
    if (functionTypeCache != null) return functionTypeCache;
    return functionTypeCache =
        getConcreteTypeFor(compiler.typesTask.functionType);
  }

  TypeInformation listTypeCache;
  TypeInformation get listType {
    if (listTypeCache != null) return listTypeCache;
    return listTypeCache = getConcreteTypeFor(compiler.typesTask.listType);
  }

  TypeInformation constListTypeCache;
  TypeInformation get constListType {
    if (constListTypeCache != null) return constListTypeCache;
    return constListTypeCache =
        getConcreteTypeFor(compiler.typesTask.constListType);
  }

  TypeInformation fixedListTypeCache;
  TypeInformation get fixedListType {
    if (fixedListTypeCache != null) return fixedListTypeCache;
    return fixedListTypeCache =
        getConcreteTypeFor(compiler.typesTask.fixedListType);
  }

  TypeInformation growableListTypeCache;
  TypeInformation get growableListType {
    if (growableListTypeCache != null) return growableListTypeCache;
    return growableListTypeCache =
        getConcreteTypeFor(compiler.typesTask.growableListType);
  }

  TypeInformation mapTypeCache;
  TypeInformation get mapType {
    if (mapTypeCache != null) return mapTypeCache;
    return mapTypeCache = getConcreteTypeFor(compiler.typesTask.mapType);
  }

  TypeInformation constMapTypeCache;
  TypeInformation get constMapType {
    if (constMapTypeCache != null) return constMapTypeCache;
    return constMapTypeCache =
        getConcreteTypeFor(compiler.typesTask.constMapType);
  }

  TypeInformation stringTypeCache;
  TypeInformation get stringType {
    if (stringTypeCache != null) return stringTypeCache;
    return stringTypeCache = getConcreteTypeFor(compiler.typesTask.stringType);
  }

  TypeInformation typeTypeCache;
  TypeInformation get typeType {
    if (typeTypeCache != null) return typeTypeCache;
    return typeTypeCache = getConcreteTypeFor(compiler.typesTask.typeType);
  }

  TypeInformation dynamicTypeCache;
  TypeInformation get dynamicType {
    if (dynamicTypeCache != null) return dynamicTypeCache;
    return dynamicTypeCache =
        getConcreteTypeFor(compiler.typesTask.dynamicType);
  }

  TypeInformation nonNullEmptyType;

  TypeInformation computeLUB(TypeInformation firstType,
                             TypeInformation secondType) {
    if (firstType == null) return secondType;
    if (firstType == secondType) return firstType;
    if (firstType == nonNullEmptyType) return secondType;
    if (secondType == nonNullEmptyType) return firstType;
    if (firstType == dynamicType || secondType == dynamicType) {
      return dynamicType;
    }
    return getConcreteTypeFor(
        firstType.type.union(secondType.type, compiler));
  }

  TypeInformation refineReceiver(Selector selector, TypeInformation receiver) {
    if (receiver.type.isExact) return receiver;
    TypeMask otherType = compiler.world.allFunctions.receiverType(selector);
    // If this is refining to nullable subtype of `Object` just return
    // the receiver. We know the narrowing is useless.
    if (otherType.isNullable && otherType.containsAll(compiler)) {
      return receiver;
    }
    TypeInformation newType =
        new NarrowTypeInformation(receiver, otherType, dynamicType.type);
    allocatedTypes.add(newType);
    return newType;
  }

  TypeInformation narrowType(TypeInformation type,
                             DartType annotation,
                             {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == compiler.objectClass) return type;
    TypeMask otherType;
    if (annotation.kind == TypeKind.TYPEDEF
        || annotation.kind == TypeKind.FUNCTION) {
      otherType = functionType.type;
    } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      assert(annotation.kind == TypeKind.INTERFACE);
      otherType = new TypeMask.nonNullSubtype(annotation);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type.type.isExact) {
      return type;
    } else {
      TypeInformation newType =
          new NarrowTypeInformation(type, otherType, dynamicType.type);
      allocatedTypes.add(newType);
      return newType;
    }
  }

  ElementTypeInformation getInferredTypeOf(Element element) {
    element = element.implementation;
    return typeInformations.putIfAbsent(element, () {
      return new ElementTypeInformation(element, dynamicType.type);
    });
  }

  ConcreteTypeInformation getConcreteTypeFor(TypeMask mask) {
    return concreteTypes.putIfAbsent(mask, () {
      return new ConcreteTypeInformation(mask);
    });
  }

  TypeInformation nonNullSubtype(DartType type) {
    return getConcreteTypeFor(new TypeMask.nonNullSubtype(type));
  }

  TypeInformation nonNullSubclass(DartType type) {
    return getConcreteTypeFor(new TypeMask.nonNullSubclass(type));
  }

  TypeInformation nonNullExact(DartType type) {
    return getConcreteTypeFor(new TypeMask.nonNullExact(type));
  }

  TypeInformation nonNullEmpty() {
    return nonNullEmptyType;
  }

  TypeInformation allocateContainer(TypeInformation type,
                                    Node node,
                                    Element enclosing,
                                    [TypeInformation elementType, int length]) {
    ContainerTypeMask mask = new ContainerTypeMask(type.type, node, enclosing);
    mask.elementType = elementType == null ? null : elementType.type;
    mask.length = length;
    TypeMask elementTypeMask = elementType == null
        ? dynamicType.type
        : elementType.type;
    TypeInformation element = new ElementInContainerTypeInformation(
        elementType, mask, elementTypeMask);
    allocatedTypes.add(element);
    return allocatedContainers[node] =
        new ContainerTypeInformation(mask, element);
  }

  Selector newTypedSelector(TypeInformation info, Selector selector) {
    return new TypedSelector(info.type, selector);
  }

  TypeInformation allocateDiamondPhi(TypeInformation firstInput,
                                     TypeInformation secondInput) {
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(null, false, null, dynamicType.type);
    result.addAssignment(firstInput);
    result.addAssignment(secondInput);
    allocatedTypes.add(result);
    return result;
  }

  PhiElementTypeInformation allocatePhi(Node node,
                                        Element element,
                                        inputType) {
    // Check if [inputType] is a phi for a local updated in
    // the try/catch block [node]. If it is, no need to allocate a new
    // phi.
    if (inputType is PhiElementTypeInformation
        && inputType.branchNode == node) {
      return inputType;
    }
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(node, true, element, dynamicType.type);
    allocatedTypes.add(result);
    result.addAssignment(inputType);
    return result;
  }

  TypeInformation simplifyPhi(Node node,
                              Element element,
                              PhiElementTypeInformation phiType) {
    if (phiType.assignments.length == 1) return phiType.assignments.first;
    return phiType;
  }

  PhiElementTypeInformation addPhiInput(Element element,
                                        PhiElementTypeInformation phiType,
                                        TypeInformation newType) {
    phiType.addAssignment(newType);
    return phiType;
  }

  TypeMask computeTypeMask(Iterable<TypeInformation> assignments) {
    TypeMask newType = const TypeMask.nonNullEmpty();
    for (var info in assignments) {
      newType = newType.union(info.type, compiler);
    }
    return newType.containsAll(compiler) ? dynamicType.type : newType;
  }
}

/**
 * A work queue for the inferrer. It filters out nodes on
 * which we gave up on inferencing, as well as ensures through
 * [TypeInformation.inQueue] that a node is in the queue only once at
 * a time.
 */
class WorkQueue {
  final Queue<TypeInformation> queue = new Queue<TypeInformation>();

  void add(TypeInformation element) {
    if (element.abandonInferencing) return;
    if (element.inQueue) return;
    queue.addLast(element);
    element.inQueue = true;
  }

  void addAll(Iterable<TypeInformation> all) {
    all.forEach(add);
  }

  TypeInformation remove() {
    TypeInformation element = queue.removeFirst();
    element.inQueue = false;
    return element;
  }

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;
}

/**
 * An inferencing engine that computes a call graph of
 * [TypeInformation] nodes by visiting the AST of the application, and
 * then does the inferencing on the graph.
 *
 * The inferencing is currently done in three steps:
 *
 * 1) Compute the call graph.
 * 2) Refine all nodes in a way that avoids cycles.
 * 3) Refine all nodes.
 *
 */
class TypeGraphInferrerEngine
    extends InferrerEngine<TypeInformation, TypeInformationSystem> {
  final Map<Element, ConcreteTypeInformation> defaultTypeOfParameter =
      new Map<Element, ConcreteTypeInformation>();
  final WorkQueue workQueue = new WorkQueue();

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int MAX_CHANGE_COUNT = 5;

  int overallRefineCount = 0;

  TypeGraphInferrerEngine(Compiler compiler)
        : super(compiler, new TypeInformationSystem(compiler));

  void runOverAllElements() {
    if (compiler.disableTypeInference) return;
    int addedInGraph = 0;
    compiler.progress.reset();

    sortResolvedElements().forEach((Element element) {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Added $addedInGraph elements in inferencing graph.');
        compiler.progress.reset();
      }
      SimpleTypeInferrerVisitor visitor =
          new SimpleTypeInferrerVisitor(element, compiler, this);
      TypeInformation type;
      compiler.withCurrentElement(element, () {
        type = visitor.run();
      });
      addedInGraph++;

      if (element.isField()) {
        Node node = element.parseNode(compiler);
        if (element.modifiers.isFinal() || element.modifiers.isConst()) {
          // If [element] is final and has an initializer, we record
          // the inferred type.
          if (node.asSendSet() != null) {
            recordType(element, type);
          } else if (!element.isInstanceMember()) {
            recordType(element, types.nullType);
          }
        } else if (node.asSendSet() == null) {
          // Only update types of static fields if there is no
          // assignment. Instance fields are dealt with in the constructor.
          if (Elements.isStaticOrTopLevelField(element)) {
            recordTypeOfNonFinalField(node, element, type, null);
          }
        } else {
          recordTypeOfNonFinalField(node, element, type, null);
        }
        if (Elements.isStaticOrTopLevelField(element)
            && node.asSendSet() != null
            && !element.modifiers.isConst()) {
          var argument = node.asSendSet().arguments.head;
          // TODO(13429): We could do better here by using the
          // constant handler to figure out if it's a lazy field or not.
          if (argument.asSend() != null
              || (argument.asNewExpression() != null && !argument.isConst())) {
            recordType(element, types.nullType);
          }
        }
      } else {
        recordReturnType(element, type);
      }
    });
    compiler.log('Added $addedInGraph elements in inferencing graph.');

    buildWorkQueue();
    refineOptimistic();
    buildWorkQueue();
    refine();

    compiler.log('Inferred $overallRefineCount types.');

    if (compiler.enableTypeAssertions) {
      // Undo the narrowing of parameters types. Parameters are being
      // checked by the method, and we can therefore only trust their
      // type after the checks. It is okay for the inferrer to rely on
      // the type annotations, but the backend should has to
      // insert the checks.
      types.typeInformations.forEach((Element element,
                                      ElementTypeInformation info) {
        if (element.isParameter() || element.isFieldParameter()) {
          if (info.abandonInferencing) {
            info.type = types.dynamicType.type;
          } else {
            info.type = types.computeTypeMask(info.assignments);
          }
        }
      });
    }
  }


  void refineOptimistic() {
    while (!workQueue.isEmpty) {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Inferred $overallRefineCount types.');
        compiler.progress.reset();
      }
      TypeInformation info = workQueue.remove();
      TypeMask oldType = info.type;
      TypeMask newType = info.refineOptimistic(this);
      if ((info.type = newType) != oldType) {
        overallRefineCount++;
        workQueue.addAll(info.users);
      }
    }
  }

  void refine() {
    while (!workQueue.isEmpty) {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Inferred $overallRefineCount types.');
        compiler.progress.reset();
      }
      TypeInformation info = workQueue.remove();
      TypeMask oldType = info.type;
      TypeMask newType = info.refine(this);
      if ((info.type = newType) != oldType) {
        overallRefineCount++;
        info.refineCount++;
        if (info.refineCount > MAX_CHANGE_COUNT) {
          info.giveUp(this);
        }
        workQueue.addAll(info.users);
      }
    }
  }

  void buildWorkQueue() {
    workQueue.addAll(types.typeInformations.values);
    workQueue.addAll(types.allocatedTypes);
  }

  /**
   * Update the assignments to parameters in the graph. [remove] tells
   * wheter assignments must be added or removed. If [init] is true,
   * parameters are added to the work queue.
   */
  void updateParameterAssignments(TypeInformation caller,
                                  Element callee,
                                  ArgumentsTypes arguments,
                                  Selector selector,
                                  {bool remove, bool init: false}) {
    if (callee.name == Compiler.NO_SUCH_METHOD) return;
    if (callee.isField()) {
      if (selector.isSetter()) {
        ElementTypeInformation info = types.getInferredTypeOf(callee);
        if (remove) {
          info.removeAssignment(arguments.positional[0]);
        } else {
          info.addAssignment(arguments.positional[0]);
        }
        if (!init) workQueue.add(info);
      }
    } else if (callee.isGetter()) {
      return;
    } else if (selector != null && selector.isGetter()) {
      if (!remove) {
        FunctionElement function = callee.implementation;
        FunctionSignature signature = function.computeSignature(compiler);
        signature.forEachParameter((Element parameter) {
          ElementTypeInformation info = types.getInferredTypeOf(parameter);
          info.giveUp(this);
        });
      }
    } else {
      FunctionElement function = callee.implementation;
      FunctionSignature signature = function.computeSignature(compiler);
      int parameterIndex = 0;
      bool visitingRequiredParameter = true;
      signature.forEachParameter((Element parameter) {
        if (parameter == signature.firstOptionalParameter) {
          visitingRequiredParameter = false;
        }
        TypeInformation type = visitingRequiredParameter
            ? arguments.positional[parameterIndex]
            : signature.optionalParametersAreNamed
              ? arguments.named[parameter.name]
              : parameterIndex < arguments.positional.length
                  ? arguments.positional[parameterIndex]
                  : null;
        if (type == null) type = getDefaultTypeOfParameter(parameter);
        TypeInformation info = types.getInferredTypeOf(parameter);
        if (remove) {
          info.removeAssignment(type);
        } else {
          info.addAssignment(type);
        }
        parameterIndex++;
        if (!init) workQueue.add(info);
      });
    }
  }

  void updateAllParametersOf(FunctionElement function) {}
  void onGenerativeConstructorAnalyzed(Element element) {}

  void setDefaultTypeOfParameter(Element parameter, TypeInformation type) {
    assert(parameter.enclosingElement.isImplementation);
    getDefaultTypeOfParameter(parameter).type = type.type;
  }

  TypeInformation getDefaultTypeOfParameter(Element parameter) {
    return defaultTypeOfParameter.putIfAbsent(parameter, () {
      return new ConcreteTypeInformation(types.dynamicType.type);
    });
  }

  TypeInformation typeOfElement(Element element) {
    if (element is FunctionElement) return types.functionType;
    return types.getInferredTypeOf(element);
  }

  TypeInformation returnTypeOfElement(Element element) {
    if (element is !FunctionElement) return types.dynamicType;
    return types.getInferredTypeOf(element);
  }

  void recordTypeOfFinalField(Spannable node,
                              Element analyzed,
                              Element element,
                              TypeInformation type,
                              CallSite constraint) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  void recordTypeOfNonFinalField(Spannable node,
                                 Element element,
                                 TypeInformation type,
                                 CallSite constraint) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  bool recordType(Element element, TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
    return false;
  }

  void recordReturnType(Element element, TypeInformation type) {
    TypeInformation info = types.getInferredTypeOf(element);
    if (element.name == const SourceString('==')) {
      info.addAssignment(types.boolType);
    }
    // TODO(ngeoffray): Clean up. We do these checks because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (type == null) return;
    if (info.assignments.isEmpty) info.addAssignment(type);
  }

  TypeInformation addReturnTypeFor(Element element,
                                   TypeInformation unused,
                                   TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOf(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element.isGenerativeConstructor()) return type;
    type.addAssignment(newType);
    return type;
  }

  TypeInformation registerCalledElement(Spannable node,
                                        Selector selector,
                                        Element caller,
                                        Element callee,
                                        ArgumentsTypes arguments,
                                        CallSite constraint,
                                        SideEffects sideEffects,
                                        bool inLoop) {
    CallSiteTypeInformation info = new StaticCallSiteTypeInformation(
          node, caller, callee, selector, arguments, types.dynamicType.type);
    if (inLoop) {
      compiler.world.addFunctionCalledInLoop(callee);
    }
    info.addToGraph(this);
    updateSideEffects(sideEffects, selector, callee);
    return info;
  }

  TypeInformation registerCalledSelector(Node node,
                                         Selector selector,
                                         TypeInformation receiverType,
                                         Element caller,
                                         ArgumentsTypes arguments,
                                         CallSite constraint,
                                         SideEffects sideEffects,
                                         bool inLoop) {
    if (selector.isClosureCall()) return types.dynamicType;

    if (inLoop && selector.mask != null) {
      // For instance methods, we only register a selector called in a
      // loop if it is a typed selector, to avoid marking too many
      // methods as being called from within a loop. This cuts down
      // on the code bloat.
      // TODO(ngeoffray): We should move the filtering on the selector
      // in the backend. It is not the inferrer role to do this kind
      // of optimization.
      compiler.world.allFunctions.filter(selector).forEach((callee) {
        compiler.world.addFunctionCalledInLoop(callee);
      });
    }
    compiler.world.allFunctions.filter(selector).forEach((callee) {
      updateSideEffects(sideEffects, selector, callee);
    });

    DynamicCallSiteTypeInformation info = new DynamicCallSiteTypeInformation(
        node, caller, selector, receiverType, arguments,
        types.dynamicType.type);
    info.addToGraph(this);
    return info;
  }

  // Sorts the resolved elements by size. We do this for this inferrer
  // to get the same results for [ContainerTracer] compared to the
  // [SimpleTypesInferrer].
  Iterable<Element> sortResolvedElements() {
    int max = 0;
    Map<int, Set<Element>> methodSizes = new Map<int, Set<Element>>();
    compiler.enqueuer.resolution.resolvedElements.forEach(
      (Element element, TreeElementMapping mapping) {
        element = element.implementation;
        if (element.impliesType()) return;
        assert(invariant(element,
            element.isField() ||
            element.isFunction() ||
            element.isGenerativeConstructor() ||
            element.isGetter() ||
            element.isSetter(),
            message: 'Unexpected element kind: ${element.kind}'));
        // TODO(ngeoffray): Not sure why the resolver would put a null
        // mapping.
        if (mapping == null) return;
        if (element.isAbstract(compiler)) return;
        // Put the other operators in buckets by length, later to be added in
        // length order.
        int length = mapping.selectors.length;
        max = length > max ? length : max;
        Set<Element> set = methodSizes.putIfAbsent(
            length, () => new LinkedHashSet<Element>());
        set.add(element);
    });

    List<Element> result = <Element>[];

    for (int i = 0; i <= max; i++) {
      Set<Element> set = methodSizes[i];
      if (set != null) {
        result.addAll(set);
      }
    }
    return result;
  }

  void clear() {
    defaultTypeOfParameter.clear();
    types.typeInformations.values.forEach((info) => info.clear());
    types.allocatedTypes.clear();
    types.concreteTypes.clear();
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return types.getInferredTypeOf(element).callers.keys;
  }
}

class TypeGraphInferrer implements TypesInferrer {
  TypeGraphInferrerEngine inferrer;
  final Compiler compiler;
  TypeGraphInferrer(Compiler this.compiler);

  String get name => 'Graph inferrer';

  void analyzeMain(_) {
    inferrer = new TypeGraphInferrerEngine(compiler);
    inferrer.runOverAllElements();
  }

  TypeMask getReturnTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return inferrer.types.getInferredTypeOf(element).type;
  }

  TypeMask getTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return inferrer.types.getInferredTypeOf(element).type;
  }

  TypeMask getTypeOfNode(Element owner, Node node) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return inferrer.types.allocatedContainers[node].type;
  }

  TypeMask getTypeOfSelector(Selector selector) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall()) return compiler.typesTask.dynamicType;
    if (selector.isSetter() || selector.isIndexSet()) {
      return compiler.typesTask.dynamicType;
    }
    if (selector.isIndex()
        && selector.mask != null
        && selector.mask.isContainer) {
      ContainerTypeMask mask = selector.mask;
      TypeMask elementType = mask.elementType;
      return elementType == null ? compiler.typesTask.dynamicType : elementType;
    }

    TypeMask result = const TypeMask.nonNullEmpty();
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element element in elements) {
      TypeMask type =
          inferrer.typeOfElementWithSelector(element, selector).type;
      result = result.union(type, compiler);
    }
    return result;
  }

  Iterable<TypeMask> get containerTypes {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.types.allocatedContainers.values.map((info) => info.type);
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.getCallersOf(element);
  }

  void clear() {
    inferrer.clear();
  }
}
