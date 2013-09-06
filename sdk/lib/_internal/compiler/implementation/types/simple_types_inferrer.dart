// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library simple_types_inferrer;

import 'dart:collection' show Queue, LinkedHashSet;

import '../closure.dart' show ClosureClassMap, ClosureScope;
import '../dart_types.dart'
    show DartType, InterfaceType, FunctionType, TypeKind;
import '../elements/elements.dart';
import '../native_handler.dart' as native;
import '../tree/tree.dart';
import '../util/util.dart' show Link, Spannable;
import 'types.dart'
    show TypesInferrer, FlatTypeMask, TypeMask, ContainerTypeMask,
         ElementTypeMask, TypeSystem, MinimalInferrerEngine;
import 'inferrer_visitor.dart';

// BUG(8802): There's a bug in the analyzer that makes the re-export
// of Selector from dart2jslib.dart fail. For now, we work around that
// by importing universe.dart explicitly and disabling the re-export.
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../universe/universe.dart' show Selector, SideEffects, TypedSelector;

/**
 * An implementation of [TypeSystem] for [TypeMask].
 */
class TypeMaskSystem implements TypeSystem<TypeMask> {
  final Compiler compiler;
  TypeMaskSystem(this.compiler);

  TypeMask narrowType(TypeMask type,
                      DartType annotation,
                      {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == compiler.objectClass) return type;
    TypeMask otherType;
    if (annotation.kind == TypeKind.TYPEDEF
        || annotation.kind == TypeKind.FUNCTION) {
      otherType = functionType;
    } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      assert(annotation.kind == TypeKind.INTERFACE);
      otherType = new TypeMask.nonNullSubtype(annotation);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type == null) return otherType;
    return type.intersection(otherType, compiler);
  }

  TypeMask computeLUB(TypeMask firstType, TypeMask secondType) {
    if (firstType == null) {
      return secondType;
    } else if (secondType == dynamicType || firstType == dynamicType) {
      return dynamicType;
    } else if (firstType == secondType) {
      return firstType;
    } else {
      TypeMask union = firstType.union(secondType, compiler);
      // TODO(kasperl): If the union isn't nullable it seems wasteful
      // to use dynamic. Fix that.
      return union.containsAll(compiler) ? dynamicType : union;
    }
  }

  TypeMask allocateDiamondPhi(TypeMask firstType, TypeMask secondType) {
    return computeLUB(firstType, secondType);
  }

  TypeMask get dynamicType => compiler.typesTask.dynamicType;
  TypeMask get nullType => compiler.typesTask.nullType;
  TypeMask get intType => compiler.typesTask.intType;
  TypeMask get doubleType => compiler.typesTask.doubleType;
  TypeMask get numType => compiler.typesTask.numType;
  TypeMask get boolType => compiler.typesTask.boolType;
  TypeMask get functionType => compiler.typesTask.functionType;
  TypeMask get listType => compiler.typesTask.listType;
  TypeMask get constListType => compiler.typesTask.constListType;
  TypeMask get fixedListType => compiler.typesTask.fixedListType;
  TypeMask get growableListType => compiler.typesTask.growableListType;
  TypeMask get mapType => compiler.typesTask.mapType;
  TypeMask get constMapType => compiler.typesTask.constMapType;
  TypeMask get stringType => compiler.typesTask.stringType;
  TypeMask get typeType => compiler.typesTask.typeType;

  TypeMask nonNullSubtype(DartType type) => new TypeMask.nonNullSubtype(type);
  TypeMask nonNullSubclass(DartType type) => new TypeMask.nonNullSubclass(type);
  TypeMask nonNullExact(DartType type) => new TypeMask.nonNullExact(type);
  TypeMask nonNullEmpty() => new TypeMask.nonNullEmpty();

  TypeMask allocateContainer(TypeMask type,
                             Node node,
                             Element enclosing,
                             [TypeMask elementType, int length]) {
    ContainerTypeMask mask = new ContainerTypeMask(type, node, enclosing);
    mask.elementType = elementType;
    mask.length = length;
    return mask;
  }

  Selector newTypedSelector(TypeMask receiver, Selector selector) {
    return new TypedSelector(receiver, selector);
  }

  TypeMask addPhiInput(Element element, TypeMask phiType, TypeMask newType) {
    return computeLUB(phiType, newType);
  }

  TypeMask allocatePhi(Node node, Element element, TypeMask inputType) {
    return inputType;
  }

  TypeMask simplifyPhi(Node node, Element element, TypeMask phiType) {
    return phiType;
  }

  TypeMask refineReceiver(Selector selector, TypeMask receiverType) {
    // If the receiver is based on an element, we let the type
    // inferrer handle it. Otherwise, we might prevent it from finding
    // one-level cycles in the inference graph.
    if (receiverType.isElement) return receiverType;
    TypeMask newType = compiler.world.allFunctions.receiverType(selector);
    return receiverType.intersection(newType, compiler);
  }
}

/**
 * A work queue that ensures there are no duplicates, and adds and
 * removes in FIFO.
 */
class WorkSet<E extends Element> {
  final Queue<E> queue = new Queue<E>();
  final Set<E> elementsInQueue = new Set<E>();

  void add(E element) {
    element = element.implementation;
    if (elementsInQueue.contains(element)) return;
    queue.addLast(element);
    elementsInQueue.add(element);
  }

  E remove() {
    E element = queue.removeFirst();
    elementsInQueue.remove(element);
    return element;
  }

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;
}

/**
 * A [TypeInformation] object contains information from the inferrer
 * on a specific [Element].
 */
abstract class TypeInformation {
  /**
   * Assignments on the element and the types inferred at
   * these assignments.
   */
  Map<Spannable, TypeMask> get assignments => null;

  /**
   * Callers of an element.
   */
  Map<Element, Set<Spannable>> get callers => null;

  /**
   * Number of times the element has been processed.
   */
  int get analyzeCount => 0;
  void set analyzeCount(value) {}

  TypeMask get type => null;
  void set type(value) {}

  TypeMask get returnType => null;
  void set returnType(value) {}

  void addCaller(Element caller, Spannable node) {
    if (callers.containsKey(caller)) {
      callers[caller].add(node);
    } else {
      callers[caller] = new Set<Spannable>()..add(node);
    }
  }

  void removeCall(Element caller, Spannable node) {
    if (!callers.containsKey(caller)) return;
    Set<Spannable> calls = callers[caller];
    calls.remove(node);
    if (calls.isEmpty) {
      callers.remove(caller);
    }
  }

  void addAssignment(Spannable node, TypeMask mask) {
    assignments[node] = mask;
  }

  void clear();
}

class FunctionTypeInformation extends TypeInformation {
  Map<Element, Set<Spannable>> callers = new Map<Element, Set<Spannable>>();
  TypeMask returnType;
  int analyzeCount = 0;
  bool canBeClosurized = false;

  void clear() {
    callers = null;
  }
}

class ParameterTypeInformation extends TypeInformation {
  Map<Spannable, TypeMask> assignments = new Map<Spannable, TypeMask>();
  TypeMask type;
  TypeMask defaultType;

  void clear() {
    assignments = null;
  }
}

class FieldTypeInformation extends TypeInformation {
  TypeMask type;
  Map<Element, Set<Spannable>> callers = new Map<Element, Set<Spannable>>();
  Map<Spannable, TypeMask> assignments = new Map<Spannable, TypeMask>();
  int analyzeCount = 0;

  void clear() {
    assignments = null;
    callers = null;
  }
}

/**
 * A class for knowing when can we compute a type for final fields.
 */
class ClassTypeInformation {
  /**
   * The number of generative constructors that need to be visited
   * before we can take any decision on the type of the fields.
   * Given that all generative constructors must be analyzed before
   * re-analyzing one, we know that once [constructorsToVisitCount]
   * reaches to 0, all generative constructors have been analyzed.
   */
  int constructorsToVisitCount;

  ClassTypeInformation(this.constructorsToVisitCount);

  /**
   * Records that [constructor] has been analyzed. If not at 0,
   * decrement [constructorsToVisitCount].
   */
  void onGenerativeConstructorAnalyzed(Element constructor) {
    if (constructorsToVisitCount != 0) constructorsToVisitCount--;
  }

  /**
   * Returns whether all generative constructors of the class have
   * been analyzed.
   */
  bool get isDone => constructorsToVisitCount == 0;
}

final OPTIMISTIC = 0;
final RETRY = 1;
final PESSIMISTIC = 2;

class SimpleTypesInferrer extends TypesInferrer {
  InternalSimpleTypesInferrer internal;
  final Compiler compiler;
  final TypeMaskSystem types;

  SimpleTypesInferrer(Compiler compiler) :
      compiler = compiler,
      types = new TypeMaskSystem(compiler) {
    internal = new InternalSimpleTypesInferrer(this, OPTIMISTIC);
  }

  TypeMask getReturnTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return internal.getReturnTypeOfElement(element.implementation);
  }

  TypeMask getTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return internal.getTypeOfElement(element.implementation);
  }

  TypeMask getTypeOfNode(Element owner, Node node) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return internal.getTypeOfNode(owner, node);
  }

  TypeMask getTypeOfSelector(Selector selector) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return internal.getTypeOfSelector(selector);
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) throw "Don't use me";
    return internal.getCallersOf(element.implementation);
  }

  Iterable<TypeMask> get containerTypes => internal.containerTypes;

  bool analyzeMain(Element element) {
    if (compiler.disableTypeInference) return true;
    bool result = internal.analyzeMain(element);
    if (internal.optimismState == OPTIMISTIC) return result;
    assert(internal.optimismState == RETRY);

    // Discard the inferrer and start again with a pessimistic one.
    internal = new InternalSimpleTypesInferrer(this, PESSIMISTIC);
    return internal.analyzeMain(element);
  }

  void clear() {
    internal.clear();
  }
}

/**
 * Common super class used by [SimpleTypeInferrerVisitor] to propagate
 * type information about visited nodes, as well as to request type
 * information of elements.
 */
abstract class InferrerEngine<T> implements MinimalInferrerEngine<T> {
  final Compiler compiler;
  final TypeSystem<T> types;
  final Map<Node, T> concreteTypes = new Map<Node, T>();

  InferrerEngine(this.compiler, this.types);

  /**
   * Requests updates of all parameters types of [function].
   */
  void updateAllParametersOf(FunctionElement function);

  /**
   * Records the default type of parameter [parameter].
   */
  void setDefaultTypeOfParameter(Element parameter, T type);

  /**
   * Returns the type of [element].
   */
  T typeOfElement(Element element);

  /**
   * Returns the return type of [element].
   */
  T returnTypeOfElement(Element element);

  /**
   * Returns the type returned by a call to this [selector].
   */
  T returnTypeOfSelector(Selector selector);

  /**
   * Records that [node] sets final field [element] to be of type [type].
   *
   * [nodeHolder] is the element holder of [node].
   *
   * [constraint] is a constraint, as described in
   * [InternalSimpleTypesInferrer].
   */
  void recordTypeOfFinalField(Node node,
                              Element nodeHolder,
                              Element field,
                              T type,
                              CallSite constraint);

  /**
   * Records that [node] sets non-final field [element] to be of type
   * [type].
   *
   * [constraint] is a field assignment constraint, as described in
   * [InternalSimpleTypesInferrer].
   */
  void recordTypeOfNonFinalField(Spannable node,
                                 Element field,
                                 T type,
                                 CallSite constraint);

  /**
   * Notifies that the visitor is done visiting generative constructor
   * [element].
   */
  void onGenerativeConstructorAnalyzed(Element element);

  /**
   * Records that [element] is of type [type]. Returns whether the
   * type is useful for the inferrer.
   */
  bool recordType(Element element, T type);

  /**
   * Records that the return type [element] is of type [type].
   */
  void recordReturnType(Element element, T type);

  /**
   * Registers that [caller] calls [callee] at location [node], with
   * [selector], and [arguments]. Note that [selector] is null for
   * forwarding constructors.
   *
   * [constraint] is a field assignment constraint, as described in
   * [InternalSimpleTypesInferrer].
   *
   * [sideEffects] will be updated to incorporate [callee]'s side
   * effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  T registerCalledElement(Spannable node,
                          Selector selector,
                          Element caller,
                          Element callee,
                          ArgumentsTypes<T> arguments,
                          CallSite constraint,
                          SideEffects sideEffects,
                          bool inLoop);

  /**
   * Registers that [caller] calls [selector] with [receiverType] as
   * receiver, and [arguments].
   *
   * [constraint] is a field assignment constraint, as described in
   * [InternalSimpleTypesInferrer].
   *
   * [sideEffects] will be updated to incorporate [callee]'s side
   * effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  T registerCalledSelector(Node node,
                           Selector selector,
                           T receiverType,
                           Element caller,
                           ArgumentsTypes<T> arguments,
                           CallSite constraint,
                           SideEffects sideEffects,
                           bool inLoop);

  /**
   * Returns the callers of [elements].
   */
  Iterable<Element> getCallersOf(Element element);

  /**
   * Notifies to the inferrer that [analyzedElement] can have return
   * type [newType]. [currentType] is the type the [InferrerVisitor]
   * currently found.
   *
   * Returns the new type for [analyzedElement].
   */
  T addReturnTypeFor(Element analyzedElement, T currentType, T newType);

  /**
   * Applies [f] to all elements in the universe that match
   * [selector]. If [f] returns false, aborts the iteration.
   */
  void forEachElementMatching(Selector selector, bool f(Element element)) {
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element e in elements) {
      if (!f(e.implementation)) return;
    }
  }

  /**
   * Update [sideEffects] with the side effects of [callee] being
   * called with [selector].
   */
  void updateSideEffects(SideEffects sideEffects,
                         Selector selector,
                         Element callee) {
    if (callee.isField()) {
      if (callee.isInstanceMember()) {
        if (selector.isSetter()) {
          sideEffects.setChangesInstanceProperty();
        } else if (selector.isGetter()) {
          sideEffects.setDependsOnInstancePropertyStore();
        } else {
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      } else {
        if (selector.isSetter()) {
          sideEffects.setChangesStaticProperty();
        } else if (selector.isGetter()) {
          sideEffects.setDependsOnStaticPropertyStore();
        } else {
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      }
    } else if (callee.isGetter() && !selector.isGetter()) {
      sideEffects.setAllSideEffects();
      sideEffects.setDependsOnSomething();
    } else {
      sideEffects.add(compiler.world.getSideEffectsOfElement(callee));
    }
  }

  /**
   * Returns the type for [nativeBehavior]. See documentation on
   * [native.NativeBehavior].
   */
  T typeOfNativeBehavior(native.NativeBehavior nativeBehavior) {
    if (nativeBehavior == null) return types.dynamicType;
    List typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return types.dynamicType;
    T returnType;
    for (var type in typesReturned) {
      T mappedType;
      if (type == native.SpecialType.JsObject) {
        mappedType = types.nonNullExact(compiler.objectClass.rawType);
      } else if (type.element == compiler.stringClass) {
        mappedType = types.stringType;
      } else if (type.element == compiler.intClass) {
        mappedType = types.intType;
      } else if (type.element == compiler.doubleClass) {
        mappedType = types.doubleType;
      } else if (type.element == compiler.numClass) {
        mappedType = types.numType;
      } else if (type.element == compiler.boolClass) {
        mappedType = types.boolType;
      } else if (type.element == compiler.nullClass) {
        mappedType = types.nullType;
      } else if (type.isVoid) {
        mappedType = types.nullType;
      } else if (type.isDynamic) {
        return types.dynamicType;
      } else if (!compiler.world.hasAnySubtype(type.element)) {
        mappedType = types.nonNullExact(type.element.rawType);
      } else {
        ClassElement element = type.element;
        Set<ClassElement> subtypes = compiler.world.subtypesOf(element);
        Set<ClassElement> subclasses = compiler.world.subclassesOf(element);
        if (subclasses != null && subtypes.length == subclasses.length) {
          mappedType = types.nonNullSubclass(element.rawType);
        } else {
          mappedType = types.nonNullSubtype(element.rawType);
        }
      }
      returnType = types.computeLUB(returnType, mappedType);
      if (returnType == types.dynamicType) {
        break;
      }
    }
    return returnType;
  }

  /**
   * Returns the type of [element] when being called with [selector].
   */
  T typeOfElementWithSelector(Element element, Selector selector) {
    if (element.name == Compiler.NO_SUCH_METHOD
        && selector.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return returnTypeOfElement(element);
    } else if (selector.isGetter()) {
      if (element.isFunction()) {
        // [functionType] is null if the inferrer did not run.
        return types.functionType == null
            ? types.dynamicType
            : types.functionType;
      } else if (element.isField()) {
        return typeOfElement(element);
      } else if (Elements.isUnresolved(element)) {
        return types.dynamicType;
      } else {
        assert(element.isGetter());
        return returnTypeOfElement(element);
      }
    } else if (element.isGetter() || element.isField()) {
      assert(selector.isCall() || selector.isSetter());
      return types.dynamicType;
    } else {
      return returnTypeOfElement(element);
    }
  }
}

class InternalSimpleTypesInferrer
    extends InferrerEngine<TypeMask> implements TypesInferrer {
  /**
   * Maps a class to a [ClassTypeInformation] to help collect type
   * information of final fields.
   */
  Map<ClassElement, ClassTypeInformation> classInfoForFinalFields =
      new Map<ClassElement, ClassTypeInformation>();

  /**
   * Maps an element to its corresponding [TypeInformation].
   */
  final Map<Element, TypeInformation> typeInfo =
      new Map<Element, TypeInformation>();

  /**
   * Maps a node to its type. Currently used for computing element
   * types of lists.
   */
  final Map<Node, TypeMask> concreteTypes = new Map<Node, TypeMask>();

  Iterable<TypeMask> get containerTypes => concreteTypes.values;

  /**
   * A map of constraints on a setter. When computing the type
   * of a field, these [Node] are initially discarded, and once the
   * type is computed, we make sure these constraints are satisfied
   * for that type. For example:
   *
   * [: field++ ], or [: field += 42 :], the constraint is on the
   * operator+, and we make sure that a typed selector with the found
   * type returns that type.
   *
   * [: field = other.field :], the constraint in on the [:field]
   * getter selector, and we make sure that the getter selector
   * returns that type.
   *
   */
  Map<Spannable, CallSite> setterConstraints = new Map<Spannable, CallSite>();

  /**
   * The work list of the inferrer.
   */
  WorkSet<Element> workSet = new WorkSet<Element>();

  /**
   * Heuristic for avoiding too many re-analysis of an element.
   */
  final int MAX_ANALYSIS_COUNT_PER_ELEMENT = 5;

  int optimismState;

  bool isDynamicType(TypeMask type) => identical(type, types.dynamicType);

  /**
   * These are methods that are expected to return only bool.  We optimistically
   * assume that they do this.  If we later find a contradiction, we have to
   * restart the simple types inferrer, because it normally goes from less
   * optimistic to more optimistic as it refines its type information.  Without
   * this optimization, method names that are mutually recursive in the tail
   * position will be typed as dynamic.
   */
  // TODO(erikcorry): Autogenerate the alphanumeric names in this set.
  Set<SourceString> PREDICATES = new Set<SourceString>.from([
      const SourceString('=='),
      const SourceString('<='),
      const SourceString('>='),
      const SourceString('>'),
      const SourceString('<'),
      const SourceString('moveNext')]);

  bool shouldOptimisticallyOptimizeToBool(Element element) {
    return element == compiler.identicalFunction.implementation
        || (element.isFunction()
            && element.isInstanceMember()
            && PREDICATES.contains(element.name));
  }

  // Times the computation of re-analysis of methods.
  final Stopwatch recomputeWatch = new Stopwatch();
  // Number of re-analysis.
  int recompiles = 0;

  /**
   * Set to [true] when the analysis has analyzed all elements in the
   * world.
   */
  bool hasAnalyzedAll = false;

  /**
   * The number of elements in the world.
   */
  int numberOfElementsToAnalyze;

  /**
   * The number of analysis already done.
   */
  int analyzed = 0;

  InternalSimpleTypesInferrer(SimpleTypesInferrer inferrer, this.optimismState)
      : super(inferrer.compiler, inferrer.types);

  /**
   * Main entry point of the inferrer.  Analyzes all elements that the resolver
   * found as reachable. Returns whether it succeeded.
   */
  bool analyzeMain(Element element) {
    buildWorkQueue();
    compiler.progress.reset();
    int maxReanalysis = (numberOfElementsToAnalyze * 1.5).toInt();
    do {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Inferred $analyzed methods.');
        compiler.progress.reset();
      }
      element = workSet.remove();
      if (element.isErroneous()) continue;

      bool wasAnalyzed = typeInformationOf(element).analyzeCount != 0;
      if (wasAnalyzed) {
        recompiles++;
        if (recompiles >= maxReanalysis) {
          compiler.log('Ran out of budget for inferring.');
          break;
        }
        if (compiler.verbose) recomputeWatch.start();
      }
      bool changed =
          compiler.withCurrentElement(element, () => analyze(element));
      if (optimismState == RETRY) return true;  // Abort.
      analyzed++;
      if (wasAnalyzed && compiler.verbose) {
        recomputeWatch.stop();
      }
      checkAnalyzedAll();
      if (changed) {
        // If something changed during the analysis of [element], put back
        // callers of it in the work list.
        enqueueCallersOf(element);
      }
    } while (!workSet.isEmpty);
    dump();
    return true;
  }

  TypeInformation typeInformationOf(Element element) {
    return typeInfo.putIfAbsent(element, () {
      if (element.isParameter() || element.isFieldParameter()) {
        return new ParameterTypeInformation();
      } else if (element.isField() || element.isVariable()) {
        return new FieldTypeInformation();
      } else {
        assert(element is FunctionElement);
        return new FunctionTypeInformation();
      }
    });
  }

  /**
   * Query method after the analysis to know the type of [element].
   */
  TypeMask getReturnTypeOfElement(Element element) {
    return getNonNullType(typeInformationOf(element).returnType);
  }

  TypeMask getTypeOfElement(Element element) {
    return getNonNullType(typeInformationOf(element).type);
  }

  TypeMask getTypeOfSelector(Selector selector) {
    return getNonNullType(returnTypeOfSelector(selector));
  }

  bool isTypeValuable(TypeMask returnType) {
    return !isDynamicType(returnType);
  }

  TypeMask getNonNullType(TypeMask returnType) {
    return returnType != null ? returnType : types.dynamicType;
  }

  Iterable<Element> getCallersOf(Element element) {
    return typeInformationOf(element).callers.keys;
  }

  /**
   * Query method after the analysis to know the type of [node],
   * defined in the context of [owner].
   */
  TypeMask getTypeOfNode(Element owner, Node node) {
    return getNonNullType(concreteTypes[node]);
  }

  void checkAnalyzedAll() {
    if (hasAnalyzedAll) return;
    if (analyzed < numberOfElementsToAnalyze) return;
    hasAnalyzedAll = true;

    // If we have analyzed all the world, we know all assigments to
    // fields and parameters, and can therefore infer a type for them.
    typeInfo.forEach((element, TypeInformation info) {
      if (element.isParameter() || element.isFieldParameter()) {
        if (updateParameterType(element)) {
          enqueueAgain(element.enclosingElement);
        }
      } else if (element.isField()
                 && !(element.modifiers.isFinal()
                      || element.modifiers.isConst())) {
        updateNonFinalFieldType(element);
      } else if (element.isVariable()) {
        updateNonFinalFieldType(element);
      }
    });
  }

  /**
   * Enqueues [e] in the work queue if it is valuable.
   */
  void enqueueAgain(Element e) {
    assert(isNotClosure(e));
    int count = typeInformationOf(e).analyzeCount;
    if (count != null && count > MAX_ANALYSIS_COUNT_PER_ELEMENT) return;
    workSet.add(e);
  }

  void enqueueCallersOf(Element element) {
    assert(isNotClosure(element));
    typeInformationOf(element).callers.keys.forEach(enqueueAgain);
  }

  /**
   * Builds the initial work queue by adding all resolved elements in
   * the work queue, ordered by the number of selectors they use. This
   * order is benficial for the analysis of return types, but we may
   * have to refine it once we analyze parameter types too.
   */
  void buildWorkQueue() {
    int max = 0;
    Map<int, Set<Element>> methodSizes = new Map<int, Set<Element>>();
    compiler.enqueuer.resolution.resolvedElements.forEach(
      (Element element, TreeElementMapping mapping) {
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
        // Add the relational operators, ==, !=, <, etc., before any
        // others, as well as the identical function.
        if (shouldOptimisticallyOptimizeToBool(element)) {
          workSet.add(element);
          // Optimistically assume that they return bool.  We may need to back
          // out of this.
          if (optimismState == OPTIMISTIC) {
            FunctionTypeInformation info =
                typeInformationOf(element.implementation);
            info.returnType = types.boolType;
          }
        } else {
          // Put the other operators in buckets by length, later to be added in
          // length order.
          int length = mapping.selectors.length;
          max = length > max ? length : max;
          Set<Element> set = methodSizes.putIfAbsent(
              length, () => new LinkedHashSet<Element>());
          set.add(element);
        }
    });

    // This iteration assumes the [WorkSet] is FIFO.
    for (int i = 0; i <= max; i++) {
      Set<Element> set = methodSizes[i];
      if (set != null) {
        set.forEach((e) { workSet.add(e); });
      }
    }
    numberOfElementsToAnalyze = workSet.length;

    // Build the [classInfoForFinalFields] map by iterating over all
    // seen classes and counting the number of their generative
    // constructors.
    // We iterate over the seen classes and not the instantiated ones,
    // because we also need to analyze the final fields of super
    // classes that are not instantiated.
    compiler.enqueuer.resolution.seenClasses.forEach((ClassElement cls) {
      int constructorCount = 0;
      cls.forEachMember((_, member) {
        if (member.isGenerativeConstructor()
            && compiler.enqueuer.resolution.isProcessed(member)) {
          constructorCount++;
        }
      });
      classInfoForFinalFields[cls.implementation] =
          new ClassTypeInformation(constructorCount);
    });
  }

  // TODO(ngeoffray): Get rid of this method. Unit tests don't always
  // ensure these classes are resolved.
  rawTypeOf(ClassElement cls) {
    cls.ensureResolved(compiler);
    assert(cls.rawType != null);
    return cls.rawType;
  }

  dump() {
    int interestingTypes = 0;
    typeInfo.forEach((element, TypeInformation info) {
      TypeMask type = info.type;
      TypeMask returnType = info.returnType;
      if (type != null && type != types.nullType && !isDynamicType(type)) {
        interestingTypes++;
      }
      if (returnType != null
          && returnType != types.nullType
          && !isDynamicType(returnType)) {
        interestingTypes++;
      }
    });

    compiler.log('Type inferrer re-analyzed methods $recompiles times '
                 'in ${recomputeWatch.elapsedMilliseconds} ms.');
    compiler.log('Type inferrer found $interestingTypes interesting '
                 'types.');
  }

  /**
   * Clear data structures that are not used after the analysis.
   */
  void clear() {
    classInfoForFinalFields = null;
    setterConstraints = null;
    workSet = null;
    typeInfo.forEach((_, info) { info.clear(); });
  }

  bool analyze(Element element) {
    SimpleTypeInferrerVisitor visitor =
        new SimpleTypeInferrerVisitor<TypeMask>(element, compiler, this);
    TypeMask returnType = visitor.run();
    typeInformationOf(element).analyzeCount++;
    if (element.isGenerativeConstructor()) {
      // We always know the return type of a generative constructor.
      return false;  // Nothing changed.
    } else if (element.isField()) {
      Node node = element.parseNode(compiler);
      if (element.modifiers.isFinal() || element.modifiers.isConst()) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (node.asSendSet() != null) {
          return recordType(element, returnType);
        }
        return false;
      } else if (node.asSendSet() == null) {
        // Only update types of static fields if there is no
        // assignment. Instance fields are dealt with in the constructor.
        if (Elements.isStaticOrTopLevelField(element)) {
          recordTypeOfNonFinalField(node, element, returnType, null);
        }
        return false;
      } else {
        recordTypeOfNonFinalField(node, element, returnType, null);
        // [recordTypeOfNonFinalField] takes care of re-enqueuing
        // users of the field.
        return false;
      }
    } else {
      return recordReturnType(element, returnType);
    }
  }

  bool recordType(Element analyzedElement, TypeMask type) {
    if (isNativeElement(analyzedElement)) return false;
    if (!compiler.backend.canBeUsedForGlobalOptimizations(analyzedElement)) {
      return false;
    }
    assert(type != null);
    assert(analyzedElement.isField()
           || analyzedElement.isParameter()
           || analyzedElement.isFieldParameter());
    TypeMask newType = checkTypeAnnotation(analyzedElement, type);
    TypeMask existing = typeInformationOf(analyzedElement).type;
    typeInformationOf(analyzedElement).type = newType;
    // If the type is useful, say it has changed.
    return existing != newType
        && !isDynamicType(newType)
        && newType != types.nullType;
  }

  /**
   * Records [returnType] as the return type of [analyzedElement].
   * Returns whether the new type is worth recompiling the callers of
   * [analyzedElement].
   */
  bool recordReturnType(Element analyzedElement, TypeMask returnType) {
    if (isNativeElement(analyzedElement)) return false;
    assert(analyzedElement.implementation == analyzedElement);
    TypeMask existing = typeInformationOf(analyzedElement).returnType;
    if (optimismState == OPTIMISTIC
        && shouldOptimisticallyOptimizeToBool(analyzedElement)
        && returnType != existing) {
      // One of the functions turned out not to return what we expected.
      // This means we need to restart the analysis.
      optimismState = RETRY;
    }
    TypeMask newType = checkTypeAnnotation(analyzedElement, returnType);
    if (analyzedElement.name == const SourceString('==')) {
      // TODO(ngeoffray): Should this be done at the call site?
      // When the argument passed in is null, we know we return a
      // bool.
      FunctionElement function = analyzedElement;
      function.computeSignature(compiler).forEachParameter((Element parameter) {
        if (typeOfElement(parameter).isNullable){
          newType = types.computeLUB(newType, types.boolType);
        }
      });
    }
    FunctionTypeInformation info = typeInformationOf(analyzedElement);
    info.returnType = newType;
    // If the return type is useful, say it has changed.
    return existing != newType
        && !isDynamicType(newType)
        && newType != types.nullType;
  }

  bool isNativeElement(Element element) {
    if (element.isNative()) return true;
    return element.isMember()
        && element.getEnclosingClass().isNative()
        && element.isField();
  }

  TypeMask checkTypeAnnotation(Element analyzedElement, TypeMask newType) {
    if (compiler.trustTypeAnnotations
        // Parameters are being checked by the method, and we can
        // therefore only trust their type after the checks.
        || (compiler.enableTypeAssertions &&
            !analyzedElement.isParameter() &&
            !analyzedElement.isFieldParameter())) {
      var annotation = analyzedElement.computeType(compiler);
      if (analyzedElement.isGetter()
          || analyzedElement.isFunction()
          || analyzedElement.isConstructor()
          || analyzedElement.isSetter()) {
        assert(annotation is FunctionType);
        annotation = annotation.returnType;
      }
      newType = types.narrowType(newType, annotation);
    }
    return newType;
  }

  TypeMask fetchReturnType(Element element) {
    TypeMask returnType = returnTypeOfElement(element);
    return returnType is ElementTypeMask ? types.dynamicType : returnType;
  }

  TypeMask fetchType(Element element) {
    TypeMask type = typeOfElement(element);
    return type is ElementTypeMask ? types.dynamicType : type;
  }

  /**
   * Returns the return type of [element]. Returns [:dynamic:] if
   * [element] has not been analyzed yet.
   */
  TypeMask returnTypeOfElement(Element element) {
    element = element.implementation;
    TypeInformation info = typeInformationOf(element);
    if (element.isGenerativeConstructor()) {
      return info.returnType == null
          ? info.returnType = new TypeMask.nonNullExact(
                rawTypeOf(element.getEnclosingClass()))
          : info.returnType;
    } else if (element.isNative()) {
      if (info.returnType == null) {
        var elementType = element.computeType(compiler);
        if (elementType.kind != TypeKind.FUNCTION) {
          info.returnType = types.dynamicType;
        } else {
          info.returnType = typeOfNativeBehavior(
            native.NativeBehavior.ofMethod(element, compiler));
        }
      }
      return info.returnType;
    }
    TypeMask returnType = info.returnType;
    if (returnType == null) {
      if ((compiler.trustTypeAnnotations || compiler.enableTypeAssertions)
          && (element.isFunction()
              || element.isGetter()
              || element.isFactoryConstructor())) {
        FunctionType functionType = element.computeType(compiler);
        returnType = types.narrowType(
            types.dynamicType, functionType.returnType);
      } else {
        returnType = info.returnType =
            new ElementTypeMask(fetchReturnType, element);
      }
    }
    return returnType;
  }

  /**
   * Returns the type of [element]. Returns [:dynamic:] if
   * [element] has not been analyzed yet.
   */
  TypeMask typeOfElement(Element element) {
    element = element.implementation;
    TypeInformation info = typeInformationOf(element);
    TypeMask type = info.type;
    if (isNativeElement(element) && element.isField()) {
      if (type == null) {
        InterfaceType rawType = element.computeType(compiler).asRaw();
        info.type = type = rawType.treatAsDynamic
            ? types.dynamicType
            : new TypeMask.subtype(rawType);
      }
      assert(type != null);
      return type;
    }
    if (type == null) {
      if ((compiler.trustTypeAnnotations
           && (element.isField()
               || element.isParameter()
               || element.isVariable()))
          // Parameters are being checked by the method, and we can
          // therefore only trust their type after the checks.
          || (compiler.enableTypeAssertions
              && (element.isField() || element.isVariable()))) {
        type = types.narrowType(
            types.dynamicType, element.computeType(compiler));
      } else {
        type = info.type = new ElementTypeMask(fetchType, element);
      }
    }
    return type;
  }

  /**
   * Returns the union of the types of all elements that match
   * the called [selector].
   */
  TypeMask returnTypeOfSelector(Selector selector) {
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall()) return types.dynamicType;
    if (selector.isSetter() || selector.isIndexSet()) return types.dynamicType;

    TypeMask result;
    forEachElementMatching(selector, (Element element) {
      assert(element.isImplementation);
      TypeMask type = typeOfElementWithSelector(element, selector);
      result = types.computeLUB(result, type);
      return isTypeValuable(result);
    });
    if (result == null) {
      result = new TypeMask.nonNullEmpty();
    }
    return result;
  }

  TypeMask typeOfElementWithSelector(Element element, Selector selector) {
    if (selector.isIndex()
        && selector.mask != null
        && selector.mask.isContainer
        && element.name == selector.name) {
      ContainerTypeMask mask = selector.mask;
      TypeMask elementType = mask.elementType;
      return elementType == null ? types.dynamicType : elementType;
    } else {
      return super.typeOfElementWithSelector(element, selector);
    }
  }

  bool isNotClosure(Element element) {
    if (!element.isFunction()) return true;
    // If the outermost enclosing element of [element] is [element]
    // itself, we know it cannot be a closure.
    Element outermost = element.getOutermostEnclosingMemberOrTopLevel();
    return outermost.declaration == element.declaration;
  }

  void addCaller(Element caller, Element callee, Spannable node) {
    assert(caller.isImplementation);
    assert(callee.isImplementation);
    assert(isNotClosure(caller));
    typeInformationOf(callee).addCaller(caller, node);
  }

  bool addArguments(Spannable node,
                    FunctionElement element,
                    ArgumentsTypes arguments) {
    FunctionTypeInformation info = typeInformationOf(element);
    if (info.canBeClosurized) return false;
    // A [noSuchMethod] method can be the target of any call, with
    // any number of arguments. For simplicity, we just do not
    // infer any parameter types for [noSuchMethod].
    if (element.name == Compiler.NO_SUCH_METHOD) return false;

    FunctionSignature signature = element.computeSignature(compiler);
    int parameterIndex = 0;
    bool changed = false;
    bool visitingOptionalParameter = false;
    signature.forEachParameter((Element parameter) {
      if (parameter == signature.firstOptionalParameter) {
        visitingOptionalParameter = true;
      }
      TypeMask type;
      ParameterTypeInformation info = typeInformationOf(parameter);
      if (!visitingOptionalParameter) {
        type = arguments.positional[parameterIndex];
      } else {
        if (signature.optionalParametersAreNamed) {
          type = arguments.named[parameter.name];
          if (type == null) type = info.defaultType;
        } else if (parameterIndex < arguments.positional.length) {
          type = arguments.positional[parameterIndex];
        } else {
          type = info.defaultType;
        }
      }
      TypeMask oldType = info.assignments[node];
      info.addAssignment(node, type);
      changed = changed || (oldType != type);
      parameterIndex++;
    });
    return changed;
  }

  bool updateParameterType(Element parameter) {
    Element function = parameter.enclosingElement;
    FunctionTypeInformation functionInfo = typeInformationOf(function);
    if (functionInfo.canBeClosurized) return false;
    if (!isNotClosure(parameter.enclosingElement)) return false;

    ParameterTypeInformation info = typeInformationOf(parameter);
    TypeMask elementType;
    info.assignments.forEach((Spannable node, TypeMask mask) {
      if (mask == null) {
        // Now that we know we have analyzed the function holding
        // [parameter], we have a default type for that [parameter].
        mask = info.defaultType;
        info.addAssignment(node, mask);
      }
      elementType = computeLubFor(elementType, mask, parameter);
    });
    if (elementType == null) {
      elementType = types.dynamicType;
    }
    return recordType(parameter, elementType);
  }

  void updateAllParametersOf(FunctionElement function) {
    if (!hasAnalyzedAll) return;
    function.computeSignature(compiler).forEachParameter((Element parameter) {
      updateParameterType(parameter);
    });
  }

  /**
   * Registers that [caller] calls [callee] with the given
   * [arguments]. [constraint] is a setter constraint (see
   * [setterConstraints] documentation).
   */
  TypeMask registerCalledElement(Spannable node,
                                 Selector selector,
                                 Element caller,
                                 Element callee,
                                 ArgumentsTypes arguments,
                                 CallSite constraint,
                                 SideEffects sideEffects,
                                 bool inLoop) {
    updateSideEffects(sideEffects, selector, callee);

    // Bailout for closure calls. We're not tracking types of
    // arguments for closures.
    if (callee.isInstanceMember() && selector.isClosureCall()) {
      return types.dynamicType;
    }
    if (inLoop) {
      // For instance methods, we only register a selector called in a
      // loop if it is a typed selector, to avoid marking too many
      // methods as being called from within a loop. This cuts down
      // on the code bloat.
      // TODO(ngeoffray): We should move the filtering on the selector
      // in the backend. It is not the inferrer role to do this kind
      // of optimization.
      if (Elements.isStaticOrTopLevel(callee) || selector.mask != null) {
        compiler.world.addFunctionCalledInLoop(callee);
      }
    }

    assert(isNotClosure(caller));
    callee = callee.implementation;
    addCaller(caller, callee, node);

    if (selector != null && selector.isSetter() && callee.isField()) {
      recordTypeOfNonFinalField(
          node,
          callee,
          arguments.positional[0],
          constraint);
      return arguments.positional[0];
    } else if (selector != null && selector.isGetter()) {
      assert(arguments == null);
      if (callee.isFunction()) {
        FunctionTypeInformation functionInfo = typeInformationOf(callee);
        functionInfo.canBeClosurized = true;
        return types.functionType;
      }
      return callee.isGetter()
          ? returnTypeOfElement(callee)
          : typeOfElement(callee);
    } else if (callee.isField() || callee.isGetter()) {
      // We're not tracking closure calls.
      return types.dynamicType;
    }
    FunctionElement function = callee;
    if (function.computeSignature(compiler).parameterCount == 0) {
      return returnTypeOfElement(callee);
    }

    assert(arguments != null);
    bool isUseful = addArguments(node, callee, arguments);
    if (hasAnalyzedAll && isUseful) {
      enqueueAgain(callee);
    }
    return returnTypeOfElement(callee);
  }

  void unregisterCalledElement(Node node,
                               Selector selector,
                               Element caller,
                               Element callee) {
    typeInformationOf(callee).removeCall(caller, node);
    if (callee.isField()) {
      if (selector.isSetter()) {
        Map<Spannable, TypeMask> assignments =
            typeInformationOf(callee).assignments;
        if (assignments == null || !assignments.containsKey(node)) return;
        assignments.remove(node);
        if (hasAnalyzedAll) updateNonFinalFieldType(callee);
      }
    } else if (callee.isGetter()) {
      return;
    } else {
      FunctionElement element = callee;
      element.computeSignature(compiler).forEachParameter((Element parameter) {
        Map<Spannable, TypeMask> assignments =
            typeInformationOf(parameter).assignments;
        if (assignments == null || !assignments.containsKey(node)) return;
        assignments.remove(node);
        if (hasAnalyzedAll) enqueueAgain(callee);
      });
    }
  }

  TypeMask addReturnTypeFor(Element element,
                            TypeMask existing,
                            TypeMask newType) {
    return computeLubFor(existing, newType, element);
  }

  TypeMask computeLubFor(TypeMask firstType,
                         TypeMask secondType,
                         Element element) {
    if (secondType.isElement) {
      ElementTypeMask mask = secondType;
      if (element == mask.element) {
        // Simple constraint of the abstract form [: foo = foo :], for
        // example a recursive function passing the same parameter.
        return firstType;
      }
    }
    return types.computeLUB(firstType, secondType);
  }

  TypeMask handleIntrisifiedSelector(Selector selector,
                                     ArgumentsTypes arguments) {
    TypeMask intType = types.intType;
    if (selector.mask != intType) return null;
    if (!selector.isCall() && !selector.isOperator()) return null;
    if (!arguments.named.isEmpty) return null;
    if (arguments.positional.length > 1) return null;

    SourceString name = selector.name;
    if (name == const SourceString('*')
        || name == const SourceString('+')
        || name == const SourceString('%')
        || name == const SourceString('remainder')) {
        return arguments.hasOnePositionalArgumentWithType(intType)
            ? intType
            : null;
    } else if (name == const SourceString('-')) {
      if (arguments.hasNoArguments()) return intType;
      if (arguments.hasOnePositionalArgumentWithType(intType)) return intType;
      return null;
    } else if (name == const SourceString('abs')) {
      return arguments.hasNoArguments() ? intType : null;
    }
    return null;
  }

  /**
   * Registers that [caller] calls an element matching [selector]
   * with the given [arguments].
   */
  TypeMask registerCalledSelector(Node node,
                                  Selector selector,
                                  TypeMask receiverType,
                                  Element caller,
                                  ArgumentsTypes arguments,
                                  CallSite constraint,
                                  SideEffects sideEffects,
                                  bool inLoop) {
    TypeMask result;
    Iterable<Element> untypedTargets =
        compiler.world.allFunctions.filter(selector.asUntyped);
    Iterable<Element> typedTargets =
        compiler.world.allFunctions.filter(selector);
    for (Element element in untypedTargets) {
      element = element.implementation;
      if (!typedTargets.contains(element.declaration)) {
        unregisterCalledElement(node, selector, caller, element);
      } else {
        registerCalledElement(
            node, selector, caller, element, arguments,
            constraint, sideEffects, inLoop);
        // We cannot use the type returned by [registerCalledElement]
        // here because it does not handle [noSuchMethod]
        // targets, unlike [typeOfElementWithSelector].
        if (!selector.isSetter()) {
          TypeMask type = handleIntrisifiedSelector(selector, arguments);
          if (type == null) type = typeOfElementWithSelector(element, selector);
          result = types.computeLUB(result, type);
        }
      }
    }

    if (result == null) {
      result = types.dynamicType;
    }
    return result;
  }

  /**
   * Records an assignment to [element] with the given
   * [argumentType].
   */
  void recordTypeOfNonFinalField(Spannable node,
                                 Element element,
                                 TypeMask argumentType,
                                 CallSite constraint) {
    TypeInformation info = typeInformationOf(element);
    info.addAssignment(node, argumentType);
    bool changed = info.type != argumentType;
    if (constraint != null && constraint != setterConstraints[node]) {
      changed = true;
      setterConstraints[node] = constraint;
    }
    // If we have analyzed all elements, we can update the type of the
    // field right away.
    if (hasAnalyzedAll && changed) {
      updateNonFinalFieldType(element);
    }
  }

  TypeMask computeTypeWithConstraints(Element element,
                                      Map<Spannable, TypeMask> assignments) {
    List<CallSite> constraints = <CallSite>[];
    TypeMask elementType;
    assignments.forEach((Spannable node, TypeMask mask) {
      CallSite constraint = setterConstraints[node];
      if (constraint != null) {
        // If this update has a constraint, we collect it and don't
        // use its type.
        constraints.add(constraint);
      } else {
        elementType = computeLubFor(elementType, mask, element);
      }
    });

    if (!constraints.isEmpty && !isDynamicType(elementType)) {
      // Now that we have found a type, we go over the collected
      // constraints, and make sure they apply to the found type. We
      // update [typeOf] to make sure [returnTypeOfSelector] knows the field
      // type.
      TypeInformation info = typeInformationOf(element);
      TypeMask existing = info.type;
      info.type = elementType;

      for (CallSite constraint in constraints) {
        Selector selector = constraint.selector;
        TypeMask type;
        if (selector.isOperator()) {
          // If the constraint is on an operator, we type the receiver
          // to be the field.
          if (elementType != null) {
            selector = types.newTypedSelector(elementType, selector);
          }
          type = handleIntrisifiedSelector(selector, constraint.arguments);
          if (type == null) type = returnTypeOfSelector(selector);
        } else {
          // Otherwise the constraint is on the form [: field = other.field :].
          assert(selector.isGetter());
          type = returnTypeOfSelector(selector);
        }
        elementType = types.computeLUB(elementType, type);
      }
      info.type = existing;
    }
    if (elementType == null) {
      elementType = new TypeMask.nonNullEmpty();
    }
    return elementType;
  }

  /**
   * Computes the type of [element], based on all assignments we have
   * collected on that [element]. This method can only be called after
   * we have analyzed all elements in the world.
   */
  void updateNonFinalFieldType(Element element) {
    if (isNativeElement(element)) return;
    assert(hasAnalyzedAll);

    TypeInformation info = typeInformationOf(element);
    Map<Spannable, TypeMask> assignments = info.assignments;
    if (assignments.isEmpty) return;

    TypeMask fieldType = computeTypeWithConstraints(element, assignments);

    // If the type of [element] has changed, re-analyze its users.
    if (recordType(element, fieldType)) {
      enqueueCallersOf(element);
    }
  }

  /**
   * Records in [classInfoForFinalFields] that [constructor] has
   * inferred [type] for the final [field].
   */
  void recordTypeOfFinalField(Node node,
                            Element constructor,
                            Element field,
                            TypeMask type,
                            CallSite constraint) {
    if (constraint != null) {
      setterConstraints[node] = constraint;
    }
    // If the field is being set at its declaration site, it is not
    // being tracked in the [classInfoForFinalFields] map.
    if (constructor == field) return;
    assert(field.modifiers.isFinal() || field.modifiers.isConst());
    TypeInformation info = typeInformationOf(field);
    info.addAssignment(node, type);
  }

  /**
   * Records that we are done analyzing [constructor]. If all
   * generative constructors of its enclosing class have already been
   * analyzed, this method updates the types of final fields.
   */
  void onGenerativeConstructorAnalyzed(Element constructor) {
    ClassElement cls = constructor.getEnclosingClass();
    ClassTypeInformation info = classInfoForFinalFields[cls.implementation];
    info.onGenerativeConstructorAnalyzed(constructor);
    if (info.isDone) {
      updateFinalFieldsType(info, constructor.getEnclosingClass());
    }
  }

  /**
   * Updates types of final fields listed in [info].
   */
  void updateFinalFieldsType(ClassTypeInformation info, ClassElement cls) {
    assert(info.isDone);
    cls.forEachInstanceField((_, Element field) {
      if (isNativeElement(field)) return;
      if (!field.modifiers.isFinal()) return;
      // If the field is being set at its declaration site, it is not
      // being tracked in the [classInfoForFinalFields] map.
      if (field.parseNode(compiler).asSendSet() != null) return;
      TypeInformation info = typeInformationOf(field);
      TypeMask fieldType = computeTypeWithConstraints(field, info.assignments);
      if (recordType(field, fieldType)) {
        enqueueCallersOf(field);
      }
    });
  }

  void setDefaultTypeOfParameter(Element parameter, TypeMask type) {
    ParameterTypeInformation info = typeInformationOf(parameter);
    info.defaultType = type;
  }
}

class SimpleTypeInferrerVisitor<T>
    extends InferrerVisitor<T, InferrerEngine<T>> {
  T returnType;
  bool visitingInitializers = false;
  bool isConstructorRedirect = false;
  SideEffects sideEffects = new SideEffects.empty();
  final Element outermostElement;
  final InferrerEngine<T> inferrer;
  final Set<Element> capturedVariables = new Set<Element>();

  SimpleTypeInferrerVisitor.internal(analyzedElement,
                                     this.outermostElement,
                                     inferrer,
                                     compiler,
                                     locals)
    : super(analyzedElement, inferrer, inferrer.types, compiler, locals),
      this.inferrer = inferrer;

  factory SimpleTypeInferrerVisitor(Element element,
                                    Compiler compiler,
                                    InferrerEngine<T> inferrer,
                                    [LocalsHandler<T> handler]) {
    Element outermostElement =
        element.getOutermostEnclosingMemberOrTopLevel().implementation;
    assert(outermostElement != null);
    return new SimpleTypeInferrerVisitor<T>.internal(
        element, outermostElement, inferrer, compiler, handler);
  }

  T run() {
    var node = analyzedElement.parseNode(compiler);
    if (analyzedElement.isField() && node.asSendSet() == null) {
      // Eagerly bailout, because computing the closure data only
      // works for functions and field assignments.
      return types.nullType;
    }
    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureClassMap closureData =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            analyzedElement, node, elements);
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData != null) {
      scopeData.capturedVariableMapping.forEach((variable, field) {
        locals.setCapturedAndBoxed(variable, field);
      });
    }
    if (analyzedElement.isField()) {
      return visit(node.asSendSet().arguments.head);
    }

    FunctionElement function = analyzedElement;
    inferrer.updateAllParametersOf(function);
    FunctionSignature signature = function.computeSignature(compiler);
    signature.forEachOptionalParameter((element) {
      Node node = element.parseNode(compiler);
      Send send = node.asSendSet();
      T type = (send == null) ? types.nullType : visit(send.arguments.head);
      inferrer.setDefaultTypeOfParameter(element, type);
    });

    if (analyzedElement.isNative()) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      return types.dynamicType;
    }

    if (analyzedElement.isGenerativeConstructor()) {
      isThisExposed = false;
      signature.forEachParameter((element) {
        T parameterType = inferrer.typeOfElement(element);
        if (element.kind == ElementKind.FIELD_PARAMETER) {
          if (element.fieldElement.modifiers.isFinal()) {
            inferrer.recordTypeOfFinalField(
                node,
                analyzedElement,
                element.fieldElement,
                parameterType,
                null);
          } else {
            locals.updateField(element.fieldElement, parameterType);
            inferrer.recordTypeOfNonFinalField(
                element.parseNode(compiler),
                element.fieldElement,
                parameterType,
                null);
          }
        }
        locals.update(element, parameterType, node);
      });
      if (analyzedElement.isSynthesized) {
        node = analyzedElement;
        synthesizeForwardingCall(node, analyzedElement.targetConstructor);
      } else {
        visitingInitializers = true;
        visit(node.initializers);
        visitingInitializers = false;
        visit(node.body);
      }
      ClassElement cls = analyzedElement.getEnclosingClass();
      if (!isConstructorRedirect) {
        // Iterate over all instance fields, and give a null type to
        // fields that we haven't initialized for sure.
        cls.forEachInstanceField((_, field) {
          if (field.modifiers.isFinal()) return;
          T type = locals.fieldScope.readField(field);
          if (type == null && field.parseNode(compiler).asSendSet() == null) {
            inferrer.recordTypeOfNonFinalField(
                node, field, types.nullType, null);
          }
        });
      }
      inferrer.onGenerativeConstructorAnalyzed(analyzedElement);
      returnType = types.nonNullExact(cls.rawType);
    } else {
      signature.forEachParameter((element) {
        locals.update(element, inferrer.typeOfElement(element), node);
      });
      visit(node.body);
      if (returnType == null) {
        // No return in the body.
        returnType = locals.seenReturnOrThrow
            ? types.nonNullEmpty()  // Body always throws.
            : types.nullType;
      } else if (!locals.seenReturnOrThrow) {
        // We haven't seen returns on all branches. So the method may
        // also return null.
        returnType = inferrer.addReturnTypeFor(
            analyzedElement, returnType, types.nullType);
      }
    }

    compiler.world.registerSideEffects(analyzedElement, sideEffects);
    assert(breaksFor.isEmpty);
    assert(continuesFor.isEmpty);
    return returnType;
  }

  T visitFunctionExpression(FunctionExpression node) {
    Element element = elements[node];
    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalsHandler closureLocals = new LocalsHandler<T>.from(
        locals, node, useOtherTryBlock: false);
    SimpleTypeInferrerVisitor visitor = new SimpleTypeInferrerVisitor<T>(
        element, compiler, inferrer, closureLocals);
    visitor.run();
    inferrer.recordReturnType(element, visitor.returnType);

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure. Note that analyzing the same closure multiple
    // times closure will refine the type of those variables, therefore
    // [:inferrer.typeOf[variable]:] is not necessarilly null, nor the
    // same as [newType].
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    nestedClosureData.forEachCapturedVariable((variable, field) {
      if (!nestedClosureData.isVariableBoxed(variable)) {
        // The type may be null for instance contexts: the 'this'
        // variable and type parameters.
        if (locals.locals[variable] == null) return;
        inferrer.recordType(field, locals.locals[variable]);
      }
      capturedVariables.add(variable);
    });

    return types.functionType;
  }

  T visitLiteralList(LiteralList node) {
    if (node.isConst()) {
      // We only set the type once. We don't need to re-visit the children
      // when re-analyzing the node.
      return inferrer.concreteTypes.putIfAbsent(node, () {
        T elementType = types.nonNullEmpty();
        int length = 0;
        for (Node element in node.elements.nodes) {
          length++;
          elementType = types.computeLUB(elementType, visit(element));
        }
        return types.allocateContainer(
            types.constListType,
            node,
            outermostElement,
            elementType,
            length);
      });
    } else {
      node.visitChildren(this);
      return inferrer.concreteTypes.putIfAbsent(node, () {
        return types.allocateContainer(
            types.growableListType,
            node,
            outermostElement);
      });
    }
  }

  bool isThisOrSuper(Node node) => node.isThis() || node.isSuper();

  void checkIfExposesThis(Selector selector) {
    if (isThisExposed) return;
    inferrer.forEachElementMatching(selector, (element) {
      if (element.isField()) {
        if (!selector.isSetter()
            && element.getEnclosingClass() ==
                    outermostElement.getEnclosingClass()
            && !element.modifiers.isFinal()
            && locals.fieldScope.readField(element) == null
            && element.parseNode(compiler).asSendSet() == null) {
          // If the field is being used before this constructor
          // actually had a chance to initialize it, say it can be
          // null.
          inferrer.recordTypeOfNonFinalField(
              analyzedElement.parseNode(compiler), element,
              types.nullType, null);
        }
        // Accessing a field does not expose [:this:].
        return true;
      }
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      isThisExposed = true;
      return false;
    });
  }

  bool get inInstanceContext {
    return (outermostElement.isInstanceMember() && !outermostElement.isField())
        || outermostElement.isGenerativeConstructor();
  }

  bool treatAsInstanceMember(Element element) {
    return (Elements.isUnresolved(element) && inInstanceContext)
        || (element != null && element.isInstanceMember());
  }

  T visitSendSet(SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType()) {
      node.visitChildren(this);
      return types.dynamicType;
    }

    Selector getterSelector =
        elements.getGetterSelectorInComplexSendSet(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    Selector setterSelector = elements.getSelector(node);

    String op = node.assignmentOperator.source.stringValue;
    bool isIncrementOrDecrement = op == '++' || op == '--';

    T receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        receiverType = thisType;
        isCallOnThis = true;
      }
    } else {
      receiverType = visit(node.receiver);
      isCallOnThis = isThisOrSuper(node.receiver);
    }

    T rhsType;
    T indexType;

    if (isIncrementOrDecrement) {
      rhsType = types.intType;
      if (node.isIndex) indexType = visit(node.arguments.head);
    } else if (node.isIndex) {
      indexType = visit(node.arguments.head);
      rhsType = visit(node.arguments.tail.head);
    } else {
      rhsType = visit(node.arguments.head);
    }

    if (!visitingInitializers && !isThisExposed) {
      for (Node node in node.arguments) {
        if (isThisOrSuper(node)) {
          isThisExposed = true;
          break;
        }
      }
      if (!isThisExposed && isCallOnThis) {
        checkIfExposesThis(
            types.newTypedSelector(receiverType, setterSelector));
        if (getterSelector != null) {
          checkIfExposesThis(
              types.newTypedSelector(receiverType, getterSelector));
        }
      }
    }

    if (node.isIndex) {
      if (op == '=') {
        // [: foo[0] = 42 :]
        handleDynamicSend(
            node,
            setterSelector,
            receiverType,
            new ArgumentsTypes<T>([indexType, rhsType], null));
        return rhsType;
      } else {
        // [: foo[0] += 42 :] or [: foo[0]++ :].
        T getterType = handleDynamicSend(
            node,
            getterSelector,
            receiverType,
            new ArgumentsTypes<T>([indexType], null));
        T returnType = handleDynamicSend(
            node,
            operatorSelector,
            getterType,
            new ArgumentsTypes<T>([rhsType], null));
        handleDynamicSend(
            node,
            setterSelector,
            receiverType,
            new ArgumentsTypes<T>([indexType, returnType], null));

        if (node.isPostfix) {
          return getterType;
        } else {
          return returnType;
        }
      }
    } else if (op == '=') {
      return handlePlainAssignment(
          node, element, setterSelector, receiverType, rhsType,
          node.arguments.head);
    } else {
      // [: foo++ :] or [: foo += 1 :].
      ArgumentsTypes operatorArguments = new ArgumentsTypes<T>([rhsType], null);
      CallSite constraint;
      if (!Elements.isLocal(element)) {
        // Record a constraint of the form [: field++ :], or [: field += 42 :].
        constraint = new CallSite(operatorSelector, operatorArguments);
      }
      T getterType;
      T newType;
      if (Elements.isErroneousElement(element)) {
        getterType = types.dynamicType;
        newType = types.dynamicType;
      } else if (Elements.isStaticOrTopLevelField(element)) {
        Element getterElement = elements[node.selector];
        getterType =
            handleStaticSend(node, getterSelector, getterElement, null);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        handleStaticSend(
            node, setterSelector, element,
            new ArgumentsTypes<T>([newType], null));
      } else if (Elements.isUnresolved(element)
                 || element.isSetter()
                 || element.isField()) {
        getterType = handleDynamicSend(
            node, getterSelector, receiverType, null);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        handleDynamicSend(node, setterSelector, receiverType,
                          new ArgumentsTypes<T>([newType], null),
                          constraint);
      } else if (Elements.isLocal(element)) {
        getterType = locals.use(element);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        locals.update(element, newType, node);
      } else {
        // Bogus SendSet, for example [: myMethod += 42 :].
        getterType = types.dynamicType;
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
      }

      if (node.isPostfix) {
        return getterType;
      } else {
        return newType;
      }
    }
  }

  T handlePlainAssignment(Node node,
                          Element element,
                          Selector setterSelector,
                          T receiverType,
                          T rhsType,
                          Node rhs) {
    CallSite constraint;
    if (node.asSend() != null && !Elements.isLocal(element)) {
      // Recognize a constraint of the form [: field = other.field :].
      // Note that we check if the right hand side is a local to
      // recognize the situation [: var a = 42; this.a = a; :]. Our
      // constraint mechanism only works with members or top level
      // elements.
      Send send = rhs.asSend();
      if (send != null
          && send.isPropertyAccess
          && !Elements.isLocal(elements[rhs])
          && send.selector.asIdentifier().source
               == node.asSend().selector.asIdentifier().source) {
        constraint = new CallSite(elements.getSelector(rhs), null);
      }
    }
    ArgumentsTypes arguments = new ArgumentsTypes<T>([rhsType], null);
    if (Elements.isErroneousElement(element)) {
      // Code will always throw.
    } else if (Elements.isStaticOrTopLevelField(element)) {
      handleStaticSend(node, setterSelector, element, arguments);
    } else if (Elements.isUnresolved(element) || element.isSetter()) {
      handleDynamicSend(
          node, setterSelector, receiverType, arguments, constraint);
    } else if (element.isField()) {
      if (element.modifiers.isFinal()) {
        inferrer.recordTypeOfFinalField(
            node, outermostElement, element, rhsType, constraint);
      } else {
        if (analyzedElement.isGenerativeConstructor()) {
          locals.updateField(element, rhsType);
        }
        if (visitingInitializers) {
          inferrer.recordTypeOfNonFinalField(
              node, element, rhsType, constraint);
        } else {
          handleDynamicSend(
              node, setterSelector, receiverType, arguments, constraint);
        }
      }
    } else if (Elements.isLocal(element)) {
      locals.update(element, rhsType, node);
    }
    return rhsType;
  }

  T visitSuperSend(Send node) {
    Element element = elements[node];
    if (Elements.isUnresolved(element)) {
      return types.dynamicType;
    }
    Selector selector = elements.getSelector(node);
    // TODO(ngeoffray): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    if (node.isPropertyAccess) {
      return handleStaticSend(node, selector, element, null);
    } else if (element.isFunction()) {
      if (!selector.applies(element, compiler)) return types.dynamicType;
      ArgumentsTypes arguments = analyzeArguments(node.arguments);
      return handleStaticSend(node, selector, element, arguments);
    } else {
      analyzeArguments(node.arguments);
      // Closure call on a getter. We don't have function types yet,
      // so we just return [:dynamic:].
      return types.dynamicType;
    }
  }

  T visitStaticSend(Send node) {
    if (visitingInitializers && Initializers.isConstructorRedirect(node)) {
      isConstructorRedirect = true;
    }
    Element element = elements[node];
    if (element.isForeign(compiler)) {
      return handleForeignSend(node);
    }
    Selector selector = elements.getSelector(node);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    if (!selector.applies(element, compiler)) return types.dynamicType;

    T returnType = handleStaticSend(node, selector, element, arguments);
    if (Elements.isGrowableListConstructorCall(element, node, compiler)) {
      return inferrer.concreteTypes.putIfAbsent(
          node, () => types.allocateContainer(
              types.growableListType, node, outermostElement));
    } else if (Elements.isFixedListConstructorCall(element, node, compiler)
        || Elements.isFilledListConstructorCall(element, node, compiler)) {
      return inferrer.concreteTypes.putIfAbsent(
          node, () => types.allocateContainer(
              types.fixedListType, node, outermostElement));
    } else if (element.isFunction() || element.isConstructor()) {
      return returnType;
    } else {
      assert(element.isField() || element.isGetter());
      // Closure call.
      return types.dynamicType;
    }
  }

  T handleForeignSend(Send node) {
    node.visitChildren(this);
    Selector selector = elements.getSelector(node);
    SourceString name = selector.name;
    if (name == const SourceString('JS')) {
      native.NativeBehavior nativeBehavior =
          compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);
      sideEffects.add(nativeBehavior.sideEffects);
      return inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == const SourceString('JS_OPERATOR_IS_PREFIX')
               || name == const SourceString('JS_OPERATOR_AS_PREFIX')
               || name == const SourceString('JS_OBJECT_CLASS_NAME')
               || name == const SourceString('JS_NULL_CLASS_NAME')) {
      return types.stringType;
    } else {
      sideEffects.setAllSideEffects();
      return types.dynamicType;
    }
  }

  ArgumentsTypes analyzeArguments(Link<Node> arguments) {
    List<T> positional = [];
    Map<SourceString, T> named = new Map<SourceString, T>();
    for (var argument in arguments) {
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        argument = namedArgument.expression;
        named[namedArgument.name.source] = argument.accept(this);
      } else {
        positional.add(argument.accept(this));
      }
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      isThisExposed = isThisExposed || argument.isThis();
    }
    return new ArgumentsTypes<T>(positional, named);
  }

  T visitGetterSend(Send node) {
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (Elements.isStaticOrTopLevelField(element)) {
      return handleStaticSend(node, selector, element, null);
    } else if (Elements.isInstanceSend(node, elements)) {
      return visitDynamicSend(node);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      handleStaticSend(node, selector, element, null);
      return types.functionType;
    } else if (Elements.isErroneousElement(element)) {
      return types.dynamicType;
    } else if (Elements.isLocal(element)) {
      assert(locals.use(element) != null);
      return locals.use(element);
    } else {
      node.visitChildren(this);
      return types.dynamicType;
    }
  }

  T visitClosureSend(Send node) {
    node.visitChildren(this);
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (element != null && element.isFunction()) {
      assert(Elements.isLocal(element));
      // This only works for function statements. We need a
      // more sophisticated type system with function types to support
      // more.
      inferrer.updateSideEffects(sideEffects, selector, element);
      return inferrer.returnTypeOfElement(element);
    }
    sideEffects.setDependsOnSomething();
    sideEffects.setAllSideEffects();
    return types.dynamicType;
  }

  T handleStaticSend(Node node,
                     Selector selector,
                     Element element,
                     ArgumentsTypes arguments) {
    if (Elements.isUnresolved(element)) return types.dynamicType;
    return inferrer.registerCalledElement(
        node, selector, outermostElement, element, arguments, null,
        sideEffects, inLoop);
  }

  void updateSelectorInTree(Node node, Selector selector) {
    if (node.asSendSet() != null) {
      if (selector.isSetter() || selector.isIndexSet()) {
        elements.setSelector(node, selector);
      } else if (selector.isGetter() || selector.isIndex()) {
        elements.setGetterSelectorInComplexSendSet(node, selector);
      } else {
        assert(selector.isOperator());
        elements.setOperatorSelectorInComplexSendSet(node, selector);
      }
    } else if (node.asSend() != null) {
      elements.setSelector(node, selector);
    } else {
      assert(node.asForIn() != null);
      if (selector.asUntyped == compiler.iteratorSelector) {
        elements.setIteratorSelector(node, selector);
      } else if (selector.asUntyped == compiler.currentSelector) {
        elements.setCurrentSelector(node, selector);
      } else {
        assert(selector.asUntyped == compiler.moveNextSelector);
        elements.setMoveNextSelector(node, selector);
      }
    }
  }

  T handleDynamicSend(Node node,
                      Selector selector,
                      T receiverType,
                      ArgumentsTypes arguments,
                      [CallSite constraint]) {
    assert(receiverType != null);
    if (selector.mask != receiverType) {
      selector = (receiverType == types.dynamicType)
          ? selector.asUntyped
          : types.newTypedSelector(receiverType, selector);
      updateSelectorInTree(node, selector);
    }

    // If the receiver of the call is a local, we may know more about
    // its type by refining it with the potential targets of the
    // calls. 
    if (node.asSend() != null) {
      Node receiver = node.asSend().receiver;
      if (receiver != null) {
        Element element = elements[receiver];
        if (Elements.isLocal(element) && !capturedVariables.contains(element)) {
          T refinedType = types.refineReceiver(selector, receiverType);
          locals.update(element, refinedType, node);
        }
      }
    }

    return inferrer.registerCalledSelector(
        node, selector, receiverType, outermostElement, arguments,
        constraint, sideEffects, inLoop);
  }

  T visitDynamicSend(Send node) {
    Element element = elements[node];
    T receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        isCallOnThis = true;
        receiverType = thisType;
      }
    } else {
      Node receiver = node.receiver;
      isCallOnThis = isThisOrSuper(receiver);
      receiverType = visit(receiver);
    }

    Selector selector = elements.getSelector(node);
    if (!isThisExposed && isCallOnThis) {
      checkIfExposesThis(types.newTypedSelector(receiverType, selector));
    }

    ArgumentsTypes arguments = node.isPropertyAccess
        ? null
        : analyzeArguments(node.arguments);
    return handleDynamicSend(node, selector, receiverType, arguments);
  }

  void recordReturnType(T type) {
    returnType = inferrer.addReturnTypeFor(analyzedElement, returnType, type);
  }

  void synthesizeForwardingCall(Spannable node, FunctionElement element) {
    element = element.implementation;
    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.computeSignature(compiler);
    List<T> unnamed = <T>[];
    Map<SourceString, T> named = new Map<SourceString, T>();
    signature.forEachRequiredParameter((Element element) {
      assert(locals.use(element) != null);
      unnamed.add(locals.use(element));
    });
    signature.forEachOptionalParameter((Element element) {
      if (signature.optionalParametersAreNamed) {
        named[element.name] = locals.use(element);
      } else {
        unnamed.add(locals.use(element));
      }
    });
    ArgumentsTypes arguments = new ArgumentsTypes<T>(unnamed, named);
    inferrer.registerCalledElement(node,
                                   null,
                                   outermostElement,
                                   element,
                                   arguments,
                                   null,
                                   sideEffects,
                                   inLoop);
  }

  T visitReturn(Return node) {
    if (node.isRedirectingFactoryBody) {
      Element element = elements[node.expression];
      if (Elements.isErroneousElement(element)) {
        recordReturnType(types.dynamicType);
      } else {
        // We don't create a selector for redirecting factories, and
        // the send is just a property access. Therefore we must
        // manually create the [ArgumentsTypes] of the call, and
        // manually register [analyzedElement] as a caller of [element].
        synthesizeForwardingCall(node.expression, element);
        recordReturnType(inferrer.returnTypeOfElement(element));
      }
    } else {
      Node expression = node.expression;
      recordReturnType(expression == null
          ? types.nullType
          : expression.accept(this));
    }
    locals.seenReturnOrThrow = true;
  }

  T visitForIn(ForIn node) {
    T expressionType = visit(node.expression);
    Selector iteratorSelector = elements.getIteratorSelector(node);
    Selector currentSelector = elements.getCurrentSelector(node);
    Selector moveNextSelector = elements.getMoveNextSelector(node);

    T iteratorType =
        handleDynamicSend(node, iteratorSelector, expressionType, null);
    handleDynamicSend(node, moveNextSelector,
                      iteratorType, new ArgumentsTypes<T>([], null));
    T currentType =
        handleDynamicSend(node, currentSelector, iteratorType, null);

    if (node.expression.isThis()) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      isThisExposed = true;
    }

    Node identifier = node.declaredIdentifier;
    Element element = elements[identifier];
    Selector selector = elements.getSelector(identifier);

    T receiverType;
    if (element != null && element.isInstanceMember()) {
      receiverType = thisType;
    } else {
      receiverType = types.dynamicType;
    }

    handlePlainAssignment(identifier, element, selector,
                          receiverType, currentType,
                          node.expression);
    return handleLoop(node, () {
      visit(node.body);
    });
  }
}
