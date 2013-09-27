// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

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
  /// Initially empty.
  TypeMask type = const TypeMask.nonNullEmpty();

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

  TypeInformation([users, assignments])
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

  String toString() => assignments.keys.toList().toString();
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

  ElementTypeInformation.internal(this.element, assignments)
      : super(null, assignments);

  factory ElementTypeInformation(Element element) {
    var assignments = null;
    if (element.enclosingElement.isInstanceMember()
        && (element.isParameter() || element.isFieldParameter())) {
      assignments = new ParameterAssignments();
    }
    return new ElementTypeInformation.internal(element, assignments);
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
            : new TypeMask.subtype(rawType.element);
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

  String toString() => 'Element $element $type';
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
  final bool inLoop;

  CallSiteTypeInformation(
      this.call,
      this.caller,
      this.selector,
      this.arguments,
      this.inLoop) : super(null, const <TypeInformation>[]);

  String toString() => 'Call site $call $type';

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
      bool inLoop) : super(call, enclosing, selector, arguments, inLoop);

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
      bool inLoop) : super(call, enclosing, selector, arguments, inLoop);

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
    TypeMask emptyType = const TypeMask.nonNullEmpty();
    if (selector.mask != intType) return null;
    if (!selector.isCall() && !selector.isOperator()) return null;
    if (!arguments.named.isEmpty) return null;
    if (arguments.positional.length > 1) return null;

    SourceString name = selector.name;
    if (name == const SourceString('*')
        || name == const SourceString('+')
        || name == const SourceString('%')
        || name == const SourceString('remainder')) {
      if (hasOnePositionalArgumentWithType(intType)) {
        return inferrer.types.intType;
      } else if (hasOnePositionalArgumentWithType(emptyType)) {
        return inferrer.types.nonNullEmptyType;
      } else {
        return null;
      }
    } else if (name == const SourceString('-')) {
      if (arguments.hasNoArguments()) return inferrer.types.intType;
      if (hasOnePositionalArgumentWithType(intType)) {
        return inferrer.types.intType;
      } else if (hasOnePositionalArgumentWithType(emptyType)) {
        return inferrer.types.nonNullEmptyType;
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

      if (returnsElementType(typedSelector)) {
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

  String toString() => 'Call site $call ${receiver.type} $type';
}

class ClosureCallSiteTypeInformation extends CallSiteTypeInformation {
  final TypeInformation closure;

  ClosureCallSiteTypeInformation(
      Spannable call,
      Element enclosing,
      Selector selector,
      this.closure,
      ArgumentsTypes arguments,
      bool inLoop) : super(call, enclosing, selector, arguments, inLoop);

  void addToGraph(TypeGraphInferrerEngine inferrer) {
    arguments.forEach((info) => info.addUser(this));
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.dynamicType.type;
  }

  Iterable<Element> get callees {
    throw new UnsupportedError("Cannot compute callees of a closure.");
  }

  String toString() => 'Closure call $call on $closure';
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
      : super(const <TypeInformation>[], const <TypeInformation>[]) {
    this.type = type;
  }

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

  NarrowTypeInformation(narrowedType, this.typeAnnotation) {
    addAssignment(narrowedType);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return assignments[0].type.intersection(typeAnnotation, inferrer.compiler);
  }

  String toString() => 'Narrow ${assignments.first} to $typeAnnotation $type';
}

/**
 * A [ContainerTypeInformation] is a [ConcreteTypeInformation] created
 * for each `List` instantiations.
 */
class ContainerTypeInformation extends ConcreteTypeInformation {
  final TypeInformation elementType;

  ContainerTypeInformation(containerType, this.elementType)
      : super(containerType);

  void addUser(TypeInformation user) {
    elementType.addUser(user);
  }

  String toString() => 'Container type $type';
}

/**
 * An [ElementInContainerTypeInformation] holds the common type of the
 * elements in a [ContainerTypeInformation].
 */
class ElementInContainerTypeInformation extends TypeInformation {
  final ContainerTypeMask container;

  ElementInContainerTypeInformation(elementType, this.container) {
    // [elementType] is not null for const lists.
    if (elementType != null) addAssignment(elementType);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    if (assignments.isEmpty) return inferrer.types.dynamicType.type;
    return container.elementType =
        inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Element in container $type';
}

/**
 * A [PhiElementTypeInformation] is an union of
 * [ElementTypeInformation], that is local to a method.
 */
class PhiElementTypeInformation extends TypeInformation {
  final Node branchNode;
  final bool isLoopPhi;
  final Element element;

  PhiElementTypeInformation(this.branchNode, this.isLoopPhi, this.element);

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Phi $element $type';
}
