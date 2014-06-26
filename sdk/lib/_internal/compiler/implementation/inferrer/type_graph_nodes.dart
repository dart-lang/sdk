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

  /// We abandon inference in certain cases (complex cyclic flow, native
  /// behaviours, etc.). In some case, we might resume inference in the
  /// closure tracer, which is handled by checking whether [assignments] has
  /// been set to [STOP_TRACKING_ASSIGNMENTS_MARKER].
  bool abandonInferencing = false;
  bool get mightResume =>
      !identical(assignments, STOP_TRACKING_ASSIGNMENTS_MARKER);

  /// Number of times this [TypeInformation] has changed type.
  int refineCount = 0;

  /// Whether this [TypeInformation] is currently in the inferrer's
  /// work queue.
  bool inQueue = false;

  /// Whether this [TypeInformation] has a stable [type] that will not
  /// change.
  bool isStable = false;

  // TypeInformations are unique.
  static int staticHashCode = 0;
  final int hashCode = staticHashCode++;

  bool get isConcrete => false;

  TypeInformation([users, assignments])
      : users = (users == null) ? new Setlet<TypeInformation>() : users,
        assignments = (assignments == null) ? <TypeInformation>[] : assignments;


  void addUser(TypeInformation user) {
    assert(!user.isConcrete);
    users.add(user);
  }

  void removeUser(TypeInformation user) {
    assert(!user.isConcrete);
    users.remove(user);
  }

  // The below is not a compile time constant to make it differentiable
  // from other empty lists of [TypeInformation].
  static final STOP_TRACKING_ASSIGNMENTS_MARKER = new List<TypeInformation>(0);

  bool areAssignmentsTracked() {
    return assignments != STOP_TRACKING_ASSIGNMENTS_MARKER;
  }

  void addAssignment(TypeInformation assignment) {
    // Cheap one-level cycle detection.
    if (assignment == this) return;
    if (areAssignmentsTracked()) {
      assignments.add(assignment);
    }
    // Even if we abandon inferencing on this [TypeInformation] we
    // need to collect the users, so that phases that track where
    // elements flow in still work.
    assignment.addUser(this);
  }

  void removeAssignment(TypeInformation assignment) {
    if (!abandonInferencing || mightResume) {
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

  void giveUp(TypeGraphInferrerEngine inferrer, {bool clearAssignments: true}) {
    abandonInferencing = true;
    type = inferrer.types.dynamicType.type;
    // Do not remove [this] as a user of nodes in [assignments],
    // because our tracing analysis could be interested in tracing
    // this node.
    if (clearAssignments) assignments = STOP_TRACKING_ASSIGNMENTS_MARKER;
    // Do not remove users because our tracing analysis could be
    // interested in tracing the users of this node.
  }

  void clear() {
    assignments = STOP_TRACKING_ASSIGNMENTS_MARKER;
    users = const <TypeInformation>[];
  }

  /// Reset the analysis of this node by making its type empty.
  void reset(TypeGraphInferrerEngine inferrer) {
    if (abandonInferencing) return;
    type = const TypeMask.nonNullEmpty();
    refineCount = 0;
  }

  accept(TypeInformationVisitor visitor);

  /// The [Element] where this [TypeInformation] was created. May be
  /// for some [TypeInformation] nodes, where we do not need to store
  /// the information.
  Element get owner => null;

  /// Returns whether the type cannot change after it has been
  /// inferred.
  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return !mightResume && assignments.every((e) => e.isStable);
  }

  void removeAndClearReferences(TypeGraphInferrerEngine inferrer) {
    assignments.forEach((info) { info.removeUser(this); });
  }

  void stabilize(TypeGraphInferrerEngine inferrer) {
    removeAndClearReferences(inferrer);
    // Do not remove users because the tracing analysis could be interested
    // in tracing the users of this node.
    assignments = STOP_TRACKING_ASSIGNMENTS_MARKER;
    abandonInferencing = true;
    isStable = true;
  }
}

abstract class ApplyableTypeInformation extends TypeInformation {
  bool mightBePassedToFunctionApply = false;

  ApplyableTypeInformation([users, assignments]) : super(users, assignments);
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
      new Map<TypeInformation, int>();

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
 * elements that need an [ElementTypeInformation] are:
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
 * and they are dealt in [ElementTypeInformation.handleSpecialCases]:
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
class ElementTypeInformation extends ApplyableTypeInformation  {
  final Element element;

  /// Marker to disable inference for closures in [handleSpecialCases].
  bool disableInferenceForClosures = true;

  /**
   * If [element] is a function, [closurizedCount] is the number of
   * times it is closurized. The value gets updated while infering.
   */
  int closurizedCount = 0;

  /**
   * This map contains the callers of [element]. It stores all unique call sites
   * to enable counting the global number of call sites of [element].
   *
   * A call site is either an AST [ast.Node], an [ir.Node] or in the case of
   * synthesized calls, an [Element] (see uses of [synthesizeForwardingCall]
   * in [SimpleTypeInferrerVisitor]).
   */
  final Map<Element, Setlet<Spannable>> _callers = new Map<Element, Setlet>();

  ElementTypeInformation.internal(this.element, assignments)
      : super(null, assignments);

  factory ElementTypeInformation(Element element) {
    var assignments = null;
    if (element.enclosingElement.isInstanceMember &&
        (element.isParameter || element.isFieldParameter)) {
      assignments = new ParameterAssignments();
    }
    return new ElementTypeInformation.internal(element, assignments);
  }

  void addCall(Element caller, Spannable node) {
    assert(node is ast.Node || node is ir.Node || node is Element);
    _callers.putIfAbsent(caller, () => new Setlet()).add(node);
  }

  void removeCall(Element caller, node) {
    Setlet calls = _callers[caller];
    if (calls == null) return;
    calls.remove(node);
    if (calls.isEmpty) {
      _callers.remove(caller);
    }
  }

  Iterable<Element> get callers => _callers.keys;

  bool isCalledOnce() {
    int count = 0;
    for (var set in _callers.values) {
      count += set.length;
      if (count > 1) return false;
    }
    return count == 1;
  }

  bool get isClosurized => closurizedCount > 0;

  // Closurized methods never become stable to ensure that the information in
  // [users] is accurate. The inference stops tracking users for stable types.
  // Note that we only override the getter, the setter will still modify the
  // state of the [isStable] field inhertied from [TypeInformation].
  bool get isStable => super.isStable && !isClosurized;

  TypeMask handleSpecialCases(TypeGraphInferrerEngine inferrer) {
    if (abandonInferencing) return type;

    if (element.isParameter) {
      Element enclosing = element.enclosingElement;
      if (Elements.isLocal(enclosing) && disableInferenceForClosures) {
        // Do not infer types for parameters of closures. We do not
        // clear the assignments in case the closure is successfully
        // traced.
        giveUp(inferrer, clearAssignments: false);
        return type;
      } else if (enclosing.isInstanceMember &&
                 (enclosing.name == Compiler.NO_SUCH_METHOD ||
                  (enclosing.name == Compiler.CALL_OPERATOR_NAME &&
                   disableInferenceForClosures))) {
        // Do not infer types for parameters of [noSuchMethod] and
        // [call] instance methods.
        giveUp(inferrer);
        return type;
      } else if (enclosing == inferrer.mainElement) {
        // The implicit call to main is not seen by the inferrer,
        // therefore we explicitly set the type of its parameters as
        // dynamic.
        // TODO(14566): synthesize a call instead to get the exact
        // types.
        giveUp(inferrer);
        return type;
      }
    }
    if (element.isField ||
        element.isParameter ||
        element.isFieldParameter) {
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
      if (element.isField) {
        return inferrer.typeOfNativeBehavior(
            native.NativeBehavior.ofFieldLoad(element, inferrer.compiler)).type;
      } else {
        assert(element.isFunction ||
               element.isGetter ||
               element.isSetter);
        TypedElement typedElement = element;
        var elementType = typedElement.type;
        if (elementType.kind != TypeKind.FUNCTION) {
          return type;
        } else {
          return inferrer.typeOfNativeBehavior(
              native.NativeBehavior.ofMethod(element, inferrer.compiler)).type;
        }
      }
    }

    Compiler compiler = inferrer.compiler;
    if (element.declaration == compiler.intEnvironment) {
      giveUp(inferrer);
      return compiler.typesTask.intType.nullable();
    } else if (element.declaration == compiler.boolEnvironment) {
      giveUp(inferrer);
      return compiler.typesTask.boolType.nullable();
    } else if (element.declaration == compiler.stringEnvironment) {
      giveUp(inferrer);
      return compiler.typesTask.stringType.nullable();
    }
    return null;
  }

  TypeMask potentiallyNarrowType(TypeMask mask,
                                 TypeGraphInferrerEngine inferrer) {
    Compiler compiler = inferrer.compiler;
    // Parameters are being explicitly checked in the method.
    if (element.isParameter || element.isFieldParameter) return mask;
    if (!compiler.trustTypeAnnotations && !compiler.enableTypeAssertions) {
      return mask;
    }
    if (element.isGenerativeConstructor || element.isSetter) return mask;
    var type = element.computeType(compiler);
    if (element.isFunction ||
        element.isGetter ||
        element.isFactoryConstructor) {
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

  accept(TypeInformationVisitor visitor) {
    return visitor.visitElementTypeInformation(this);
  }

  Element get owner => element.outermostEnclosingMemberOrTopLevel;

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    // The number of assignments of parameters of instance methods is
    // not stable. Therefore such a parameter cannot be stable.
    if (element.isParameter && element.enclosingElement.isInstanceMember) {
      return false;
    }

    // The number of assignments of non-final fields is
    // not stable. Therefore such a field cannot be stable.
    if (element.isField && !(element.isConst || element.isFinal)) {
      return false;
    }

    if (element.isFunction) return false;

    return super.hasStableType(inferrer);
  }
}

/**
 * A [CallSiteTypeInformation] is a call found in the AST, or a
 * synthesized call for implicit calls in Dart (such as forwarding
 * factories). The [call] field is a [ast.Node] for the former, and an
 * [Element] for the latter.
 *
 * In the inferrer graph, [CallSiteTypeInformation] nodes do not have
 * any assignment. They rely on the [caller] field for static calls,
 * and [selector] and [receiver] fields for dynamic calls.
 */
abstract class CallSiteTypeInformation extends ApplyableTypeInformation {
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

  Element get owner => caller;
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
        this, calledElement, arguments, selector, remove: false,
        addToQueue: false);
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

  accept(TypeInformationVisitor visitor) {
    return visitor.visitStaticCallSiteTypeInformation(this);
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.getInferredTypeOf(calledElement).isStable &&
        (arguments == null || arguments.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }

  void removeAndClearReferences(TypeGraphInferrerEngine inferrer) {
    ElementTypeInformation callee =
        inferrer.types.getInferredTypeOf(calledElement);
    callee.removeUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }
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
          this, element, arguments, typedSelector, remove: false,
          addToQueue: false);
    }
  }

  Iterable<Element> get callees => targets.map((e) => e.implementation);

  Selector computeTypedSelector(TypeGraphInferrerEngine inferrer) {
    TypeMask receiverType = receiver.type;

    if (selector.mask != receiverType) {
      return receiverType == inferrer.compiler.typesTask.dynamicType
          ? selector.asUntyped
          : new TypedSelector(receiverType, selector, inferrer.compiler);
    } else {
      return selector;
    }
  }

  bool get targetsIncludeNoSuchMethod {
    return targets.any((Element e) {
      return e is FunctionElement &&
             e.isInstanceMember &&
             e.name == Compiler.NO_SUCH_METHOD;
    });
  }

  /**
   * We optimize certain operations on the [int] class because we know
   * more about their return type than the actual Dart code. For
   * example, we know int + int returns an int. The Dart code for
   * [int.operator+] only says it returns a [num].
   */
  TypeInformation handleIntrisifiedSelector(Selector selector,
                                            TypeGraphInferrerEngine inferrer) {
    Compiler compiler = inferrer.compiler;
    if (!compiler.backend.intImplementation.isResolved) return null;
    TypeMask emptyType = const TypeMask.nonNullEmpty();
    if (selector.mask == null) return null;
    if (!selector.mask.containsOnlyInt(compiler)) {
      return null;
    }
    if (!selector.isCall && !selector.isOperator) return null;
    if (!arguments.named.isEmpty) return null;
    if (arguments.positional.length > 1) return null;

    ClassElement uint31Implementation = compiler.backend.uint31Implementation;
    bool isInt(info) => info.type.containsOnlyInt(compiler);
    bool isEmpty(info) => info.type == emptyType;
    bool isUInt31(info) {
      return info.type.satisfies(uint31Implementation, compiler);
    }
    bool isPositiveInt(info) {
      return info.type.satisfies(
          compiler.backend.positiveIntImplementation, compiler);
    }

    String name = selector.name;
    // We are optimizing for the cases that are not expressed in the
    // Dart code, for example:
    // int + int -> int
    // uint31 | uint31 -> uint31
    if (name == '*' || name == '+' || name == '%' || name == 'remainder' ||
        name == '~/') {
      if (isPositiveInt(receiver) &&
          arguments.hasOnePositionalArgumentThatMatches(isPositiveInt)) {
        return inferrer.types.positiveIntType;
      } else if (arguments.hasOnePositionalArgumentThatMatches(isInt)) {
        return inferrer.types.intType;
      } else if (arguments.hasOnePositionalArgumentThatMatches(isEmpty)) {
        return inferrer.types.nonNullEmptyType;
      } else {
        return null;
      }
    } else if (name == '|' || name == '^') {
      if (isUInt31(receiver) &&
          arguments.hasOnePositionalArgumentThatMatches(isUInt31)) {
        return inferrer.types.uint31Type;
      }
    } else if (name == '>>') {
      if (isUInt31(receiver)) {
        return inferrer.types.uint31Type;
      }
    } else if (name == '&') {
      if (isUInt31(receiver) ||
          arguments.hasOnePositionalArgumentThatMatches(isUInt31)) {
        return inferrer.types.uint31Type;
      }
    } else if (name == 'unary-') {
      // The receiver being an int, the return value will also be an
      // int.
      return inferrer.types.intType;
    } else if (name == '-') {
      if (arguments.hasOnePositionalArgumentThatMatches(isInt)) {
        return inferrer.types.intType;
      } else if (arguments.hasOnePositionalArgumentThatMatches(isEmpty)) {
        return inferrer.types.nonNullEmptyType;
      }
      return null;
    } else if (name == 'abs') {
      return arguments.hasNoArguments() ? inferrer.types.positiveIntType : null;
    }
    return null;
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    Iterable<Element> oldTargets = targets;
    Selector typedSelector = computeTypedSelector(inferrer);
    inferrer.updateSelectorInTree(caller, call, typedSelector);

    Compiler compiler = inferrer.compiler;
    Selector selectorToUse = typedSelector.extendIfReachesAll(compiler);

    bool canReachAll = compiler.enabledInvokeOn &&
        (selectorToUse != typedSelector);

    // If this call could potentially reach all methods that satisfy
    // the untyped selector (through noSuchMethod's `Invocation`
    // and a call to `delegate`), we iterate over all these methods to
    // update their parameter types.
    targets = compiler.world.allFunctions.filter(selectorToUse);
    Iterable<Element> typedTargets = canReachAll
        ? compiler.world.allFunctions.filter(typedSelector)
        : targets;

    // Walk over the found targets, and compute the joined union type mask
    // for all these targets.
    TypeMask newType = inferrer.types.joinTypeMasks(targets.map((element) {
      if (!oldTargets.contains(element)) {
        ElementTypeInformation callee =
            inferrer.types.getInferredTypeOf(element);
        callee.addCall(caller, call);
        callee.addUser(this);
        inferrer.updateParameterAssignments(
            this, element, arguments, typedSelector, remove: false,
            addToQueue: true);
      }

      // If [canReachAll] is true, then we are iterating over all
      // targets that satisfy the untyped selector. We skip the return
      // type of the targets that can only be reached through
      // `Invocation.delegate`. Note that the `noSuchMethod` targets
      // are included in [typedTargets].
      if (canReachAll && !typedTargets.contains(element)) {
        return const TypeMask.nonNullEmpty();
      }

      if (inferrer.returnsListElementType(typedSelector)) {
        ContainerTypeMask mask = receiver.type;
        return mask.elementType;
      } else if (inferrer.returnsMapValueType(typedSelector)) {
        if (typedSelector.mask.isDictionary &&
            arguments.positional[0].type.isValue) {
          DictionaryTypeMask mask = typedSelector.mask;
          ValueTypeMask arg = arguments.positional[0].type;
          String key = arg.value;
          if (mask.typeMap.containsKey(key)) {
            if (_VERBOSE) {
              print("Dictionary lookup for $key yields ${mask.typeMap[key]}.");
            }
            return mask.typeMap[key];
          } else {
            // The typeMap is precise, so if we do not find the key, the lookup
            // will be [null] at runtime.
            if (_VERBOSE) {
              print("Dictionary lookup for $key yields [null].");
            }
            return inferrer.types.nullType.type;
          }
        }
        MapTypeMask mask = typedSelector.mask;
        if (_VERBOSE) {
          print("Map lookup for $typedSelector yields ${mask.valueType}.");
        }
        return mask.valueType;
      } else {
        TypeInformation info =
            handleIntrisifiedSelector(typedSelector, inferrer);
        if (info != null) return info.type;
        return inferrer.typeOfElementWithSelector(element, typedSelector).type;
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
            this, element, arguments, typedSelector, remove: true,
            addToQueue: true);
      }
    });

    return newType;
  }

  void giveUp(TypeGraphInferrerEngine inferrer, {bool clearAssignments: true}) {
    inferrer.updateSelectorInTree(caller, call, selector);
    Iterable<Element> oldTargets = targets;
    targets = inferrer.compiler.world.allFunctions.filter(selector);
    for (Element element in targets) {
      if (!oldTargets.contains(element)) {
        ElementTypeInformation callee =
            inferrer.types.getInferredTypeOf(element);
        callee.addCall(caller, call);
        inferrer.updateParameterAssignments(
            this, element, arguments, selector, remove: false,
            addToQueue: true);
      }
    }
    super.giveUp(inferrer, clearAssignments: clearAssignments);
  }

  void removeAndClearReferences(TypeGraphInferrerEngine inferrer) {
    for (Element element in targets) {
      ElementTypeInformation callee = inferrer.types.getInferredTypeOf(element);
      callee.removeUser(this);
    }
    if (arguments != null) {
      arguments.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }

  String toString() => 'Call site $call on ${receiver.type} $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitDynamicCallSiteTypeInformation(this);
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return receiver.isStable &&
        targets.every(
            (element) => inferrer.types.getInferredTypeOf(element).isStable) &&
        (arguments == null || arguments.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }
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
    closure.addUser(this);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.dynamicType.type;
  }

  Iterable<Element> get callees {
    throw new UnsupportedError("Cannot compute callees of a closure call.");
  }

  String toString() => 'Closure call $call on $closure';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitClosureCallSiteTypeInformation(this);
  }

  void removeAndClearReferences(TypeGraphInferrerEngine inferrer) {
    // This method is a placeholder for the following comment:
    // We should maintain the information that the closure is a user
    // of its arguments because we do not check that the arguments
    // have a stable type for a closure call to be stable; our tracing
    // analysis want to know whether an (non-stable) argument is
    // passed to a closure.
    return super.removeAndClearReferences(inferrer);
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
      : super(const <TypeInformation>[], const <TypeInformation>[]) {
    this.type = type;
    this.isStable = true;
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

  void reset(TypeGraphInferrerEngine inferrer) {
    assert(false);
  }

  String toString() => 'Type $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitConcreteTypeInformation(this);
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return true;
  }
}

class StringLiteralTypeInformation extends ConcreteTypeInformation {
  final ast.DartString value;

  StringLiteralTypeInformation(value, TypeMask mask)
      : super(new ValueTypeMask(mask, value.slowToString())),
        this.value = value;

  String asString() => value.slowToString();
  String toString() => 'Type $type value ${value.slowToString()}';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitStringLiteralTypeInformation(this);
  }
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

  String toString() {
    return 'Narrow to $typeAnnotation $type';
  }

  accept(TypeInformationVisitor visitor) {
    return visitor.visitNarrowTypeInformation(this);
  }
}

/**
 * An [InferredTypeInformation] is a [TypeInformation] that
 * defaults to the dynamic type until it is marked as beeing
 * inferred, at which point it computes its type based on
 * its assignments.
 */
abstract class InferredTypeInformation extends TypeInformation {
  /** Whether the element type in that container has been inferred. */
  bool inferred = false;

  InferredTypeInformation(parentType) {
    if (parentType != null) addAssignment(parentType);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    if (!inferred) {
      return inferrer.types.dynamicType.type;
    }
    return inferrer.types.computeTypeMask(assignments);
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return inferred && super.hasStableType(inferrer);
  }
}

/**
 * A [ListTypeInformation] is a [TypeInformation] created
 * for each `List` instantiations.
 */
class ListTypeInformation extends TypeInformation {
  final ElementInContainerTypeInformation elementType;

  /** The container type before it is inferred. */
  final ContainerTypeMask originalContainerType;

  /** The length at the allocation site. */
  final int originalLength;

  /** The length after the container has been traced. */
  int inferredLength;

  /**
   * Whether this list goes through a growable check.
   * We conservatively assume it does.
   */
  bool checksGrowable = true;

  // The set of [TypeInformation] where the traced container could
  // flow in.
  final Setlet<TypeInformation> flowsInto = new Setlet<TypeInformation>();

  bool bailedOut = true;
  bool analyzed = false;

  ListTypeInformation(this.originalContainerType,
                      this.elementType,
                      this.originalLength) {
    type = originalContainerType;
    inferredLength = originalContainerType.length;
    elementType.addUser(this);
  }

  String toString() => 'List type $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitListTypeInformation(this);
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return elementType.isStable && super.hasStableType(inferrer);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    var mask = type;
    if (!mask.isContainer ||
        mask.elementType != elementType.type ||
        mask.length != inferredLength) {
      return new ContainerTypeMask(originalContainerType.forwardTo,
                                   originalContainerType.allocationNode,
                                   originalContainerType.allocationElement,
                                   elementType.type,
                                   inferredLength);
    }
    return mask;
  }

  void giveUp(TypeGraphInferrerEngine inferrer, {bool clearAssignments: true}) {
    super.giveUp(inferrer, clearAssignments: clearAssignments);
    // We still know that this node represents a container, so we explicitly
    // preserve that information here.
    type = new ContainerTypeMask(originalContainerType.forwardTo,
                                 originalContainerType.allocationNode,
                                 originalContainerType.allocationElement,
                                 inferrer.types.dynamicType.type,
                                 null);
  }
}

/**
 * An [ElementInContainerTypeInformation] holds the common type of the
 * elements in a [ListTypeInformation].
 */
class ElementInContainerTypeInformation extends InferredTypeInformation {
  ElementInContainerTypeInformation(elementType) : super(elementType);

  String toString() => 'Element in container $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitElementInContainerTypeInformation(this);
  }
}

/**
 * A [MapTypeInformation] is a [TypeInformation] created
 * for maps.
 */
class MapTypeInformation extends TypeInformation {
  // When in Dictionary mode, this map tracks the type of the values that
  // have been assigned to a specific [String] key.
  final Map<String, ValueInMapTypeInformation> typeInfoMap = {};
  // These fields track the overall type of the keys/values in the map.
  final KeyInMapTypeInformation keyType;
  final ValueInMapTypeInformation valueType;
  final MapTypeMask initialType;

  // The set of [TypeInformation] where values from the traced map could
  // flow in.
  final Setlet<TypeInformation> flowsInto = new Setlet<TypeInformation>();

  // Set to false once analysis has succeeded.
  bool bailedOut = true;
  bool analyzed = false;

  // Set to false if a statically unknown key flows into this map.
  bool _allKeysAreStrings = true;

  bool get inDictionaryMode => !bailedOut && _allKeysAreStrings;

  MapTypeInformation(this.initialType, this.keyType, this.valueType) {
    keyType.addUser(this);
    valueType.addUser(this);
    type = initialType;
  }

  TypeInformation addEntryAssignment(TypeInformation key,
                                     TypeInformation value,
                                     [bool nonNull = false]) {
    TypeInformation newInfo = null;
    if (_allKeysAreStrings && key is StringLiteralTypeInformation) {
      String keyString = key.asString();
      typeInfoMap.putIfAbsent(keyString,
          () => newInfo = new ValueInMapTypeInformation(null, nonNull));
      typeInfoMap[keyString].addAssignment(value);
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addAssignment(key);
    valueType.addAssignment(value);
    if (newInfo != null) newInfo.addUser(this);

    return newInfo;
  }

  List<TypeInformation> addMapAssignment(MapTypeInformation other) {
    List<TypeInformation> newInfos = <TypeInformation>[];
    if (_allKeysAreStrings && other.inDictionaryMode) {
      other.typeInfoMap.forEach((keyString, value) {
        typeInfoMap.putIfAbsent(keyString, () {
          TypeInformation newInfo = new ValueInMapTypeInformation(null, false);
          newInfos.add(newInfo);
          return newInfo;
        });
        typeInfoMap[keyString].addAssignment(value);
      });
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addAssignment(other.keyType);
    valueType.addAssignment(other.valueType);

    return newInfos;
  }

  markAsInferred() {
    keyType.inferred = valueType.inferred = true;
    typeInfoMap.values.forEach((v) => v.inferred = true);
  }

  addAssignment(TypeInformation other) {
    throw "not supported";
  }

  accept(TypeInformationVisitor visitor) {
    return visitor.visitMapTypeInformation(this);
  }

  TypeMask toTypeMask(TypeGraphInferrerEngine inferrer) {
    if (inDictionaryMode) {
      Map<String, TypeMask> mappings = new Map<String, TypeMask>();
      for (var key in typeInfoMap.keys) {
        mappings[key] = typeInfoMap[key].type;
      }
      return new DictionaryTypeMask(initialType.forwardTo,
                                    initialType.allocationNode,
                                    initialType.allocationElement,
                                    keyType.type,
                                    valueType.type,
                                    mappings);
    } else {
      return new MapTypeMask(initialType.forwardTo,
                             initialType.allocationNode,
                             initialType.allocationElement,
                             keyType.type,
                             valueType.type);
    }
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    if (type.isDictionary != inDictionaryMode) {
      return toTypeMask(inferrer);
    } else if (type.isDictionary) {
      assert(inDictionaryMode);
      DictionaryTypeMask mask = type;
      for (var key in typeInfoMap.keys) {
        TypeInformation value = typeInfoMap[key];
        if (!mask.typeMap.containsKey(key) &&
            !value.type.containsAll(inferrer.compiler) &&
            !value.type.isNullable) {
          return toTypeMask(inferrer);
        }
        if (mask.typeMap[key] != typeInfoMap[key].type) {
          return toTypeMask(inferrer);
        }
      }
    } else if (type.isMap) {
      MapTypeMask mask = type;
      if (mask.keyType != keyType.type ||
          mask.valueType != valueType.type) {
        return toTypeMask(inferrer);
      }
    } else {
      return toTypeMask(inferrer);
    }

    return type;
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return keyType.isStable &&
           valueType.isStable &&
           super.hasStableType(inferrer);
  }

  String toString() {
    return 'Map $type (K:$keyType, V:$valueType) contents $typeInfoMap';
  }
}

/**
 * A [KeyInMapTypeInformation] holds the common type
 * for the keys in a [MapTypeInformation]
 */
class KeyInMapTypeInformation extends InferredTypeInformation {
  KeyInMapTypeInformation(TypeInformation keyType) : super(keyType);

  accept(TypeInformationVisitor visitor) {
    return visitor.visitKeyInMapTypeInformation(this);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return super.refine(inferrer);
  }

  String toString() => 'Key in Map $type';
}

/**
 * A [ValueInMapTypeInformation] holds the common type
 * for the values in a [MapTypeInformation]
 */
class ValueInMapTypeInformation extends InferredTypeInformation {
  // [nonNull] is set to true if this value is known to be part of the map.
  // Note that only values assigned to a specific key value in dictionary
  // mode can ever be marked as [nonNull].
  final bool nonNull;

  ValueInMapTypeInformation(TypeInformation valueType, [this.nonNull = false])
      : super(valueType);

  accept(TypeInformationVisitor visitor) {
    return visitor.visitValueInMapTypeInformation(this);
  }

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return nonNull ? super.refine(inferrer) : super.refine(inferrer).nullable();
  }

  String toString() => 'Value in Map $type';
}

/**
 * A [PhiElementTypeInformation] is an union of
 * [ElementTypeInformation], that is local to a method.
 */
class PhiElementTypeInformation extends TypeInformation {
  final ast.Node branchNode;
  final bool isLoopPhi;
  final Element element;

  PhiElementTypeInformation(this.branchNode, this.isLoopPhi, this.element);

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Phi $element $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitPhiElementTypeInformation(this);
  }
}

class ClosureTypeInformation extends ApplyableTypeInformation {
  final ast.Node node;
  final Element element;

  ClosureTypeInformation(this.node, this.element);

  TypeMask refine(TypeGraphInferrerEngine inferrer) {
    return inferrer.types.functionType.type;
  }

  String toString() => 'Closure $element';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitClosureTypeInformation(this);
  }

  bool hasStableType(TypeGraphInferrerEngine inferrer) {
    return false;
  }
}

abstract class TypeInformationVisitor<T> {
  T visitNarrowTypeInformation(NarrowTypeInformation info);
  T visitPhiElementTypeInformation(PhiElementTypeInformation info);
  T visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info);
  T visitKeyInMapTypeInformation(KeyInMapTypeInformation info);
  T visitValueInMapTypeInformation(ValueInMapTypeInformation info);
  T visitListTypeInformation(ListTypeInformation info);
  T visitMapTypeInformation(MapTypeInformation info);
  T visitConcreteTypeInformation(ConcreteTypeInformation info);
  T visitStringLiteralTypeInformation(StringLiteralTypeInformation info);
  T visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info);
  T visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info);
  T visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info);
  T visitElementTypeInformation(ElementTypeInformation info);
  T visitClosureTypeInformation(ClosureTypeInformation info);
}
