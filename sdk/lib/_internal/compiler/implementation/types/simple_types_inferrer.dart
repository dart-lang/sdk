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
import '../util/util.dart' show Link;
import 'types.dart' show TypesInferrer, FlatTypeMask, TypeMask;

// BUG(8802): There's a bug in the analyzer that makes the re-export
// of Selector from dart2jslib.dart fail. For now, we work around that
// by importing universe.dart explicitly and disabling the re-export.
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../universe/universe.dart' show Selector, SideEffects, TypedSelector;

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
 * Placeholder for type information of final fields of classes.
 */
class ClassInfoForFinalFields {
  /**
   * Maps a final field to a map from generative constructor to the
   * inferred type of the field in that generative constructor.
   */
  final Map<Element, Map<Node, TypeMask>> typesOfFinalFields =
      new Map<Element, Map<Node, TypeMask>>();

  /**
   * The number of generative constructors that need to be visited
   * before we can take any decision on the type of the fields.
   * Given that all generative constructors must be analyzed before
   * re-analyzing one, we know that once [constructorsToVisitCount]
   * reaches to 0, all generative constructors have been analyzed.
   */
  int constructorsToVisitCount;

  ClassInfoForFinalFields(this.constructorsToVisitCount);

  /**
   * Records that the generative [constructor] has inferred [type]
   * for the final [field].
   */
  void recordFinalFieldType(Node node,
                            Element constructor,
                            Element field,
                            TypeMask type) {
    Map<Node, TypeMask> typesFor = typesOfFinalFields.putIfAbsent(
        field, () => new Map<Node, TypeMask>());
    typesFor[node] = type;
  }

  /**
   * Records that [constructor] has been analyzed. If not at 0,
   * decrement [constructorsToVisitCount].
   */
  void doneAnalyzingGenerativeConstructor(Element constructor) {
    if (constructorsToVisitCount != 0) constructorsToVisitCount--;
  }

  /**
   * Returns whether all generative constructors of the class have
   * been analyzed.
   */
  bool get isDone => constructorsToVisitCount == 0;
}

/**
 * A sentinel type mask class used by the inferrer for the give up
 * type, and the dynamic type.
 */
class SentinelTypeMask extends FlatTypeMask {
  final String name;

  SentinelTypeMask(this.name) : super(null, 0, false);

  bool operator==(other) {
    return identical(this, other);
  }

  TypeMask nullable() {
    throw 'Unsupported operation';
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    return other;
  }

  bool get isNullable => true;

  String toString() => '$name sentinel type mask';
}

final OPTIMISTIC = 0;
final RETRY = 1;
final PESSIMISTIC = 2;

class SimpleTypesInferrer extends TypesInferrer {
  InternalSimpleTypesInferrer internal;
  Compiler compiler;

  SimpleTypesInferrer(Compiler compiler) :
      compiler = compiler,
      internal = new InternalSimpleTypesInferrer(compiler, OPTIMISTIC);

  TypeMask get dynamicType => internal.dynamicType;
  TypeMask get nullType => internal.nullType;
  TypeMask get intType => internal.intType;
  TypeMask get doubleType => internal.doubleType;
  TypeMask get numType => internal.numType;
  TypeMask get boolType => internal.boolType;
  TypeMask get functionType => internal.functionType;
  TypeMask get listType => internal.listType;
  TypeMask get constListType => internal.constListType;
  TypeMask get fixedListType => internal.fixedListType;
  TypeMask get growableListType => internal.growableListType;
  TypeMask get mapType => internal.mapType;
  TypeMask get constMapType => internal.constMapType;
  TypeMask get stringType => internal.stringType;
  TypeMask get typeType => internal.typeType;

  TypeMask getReturnTypeOfElement(Element element) {
    return internal.getReturnTypeOfElement(element);
  }
  TypeMask getTypeOfElement(Element element) {
    return internal.getTypeOfElement(element);
  }
  TypeMask getTypeOfNode(Element owner, Node node) {
    return internal.getTypeOfNode(owner, node);
  }
  TypeMask getTypeOfSelector(Selector selector) {
    return internal.getTypeOfSelector(selector);
  }

  bool analyzeMain(Element element) {
    if (compiler.disableTypeInference) return true;
    bool result = internal.analyzeMain(element);
    if (internal.optimismState == OPTIMISTIC) return result;
    assert(internal.optimismState == RETRY);

    // Discard the inferrer and start again with a pessimistic one.
    internal = new InternalSimpleTypesInferrer(compiler, PESSIMISTIC);
    return internal.analyzeMain(element);
  }
}



class InternalSimpleTypesInferrer extends TypesInferrer {
  /**
   * Maps an element to its callers.
   */
  final Map<Element, Set<Element>> callersOf =
      new Map<Element, Set<Element>>();

  /**
   * Maps an element to its return type.
   */
  final Map<Element, TypeMask> returnTypeOf =
      new Map<Element, TypeMask>();

  /**
   * Maps an element to its type.
   */
  final Map<Element, TypeMask> typeOf = new Map<Element, TypeMask>();

  /**
   * Maps an element to its assignments and the types inferred at
   * these assignments.
   */
  final Map<Element, Map<Node, TypeMask>> typeOfFields =
      new Map<Element, Map<Node, TypeMask>>();

  /**
   * Maps an element to the type of its parameters at call sites.
   */
  final Map<Element, Map<Node, ArgumentsTypes>> typeOfArguments =
      new Map<Element, Map<Node, ArgumentsTypes>>();

  /**
   * Maps an optional parameter to its default type.
   */
  final Map<Element, TypeMask> defaultTypeOfParameter =
      new Map<Element, TypeMask>();

  /**
   * Set of methods that the inferrer found could be closurized. We
   * don't compute parameter types for such methods.
   */
  final Set<Element> methodsThatCanBeClosurized = new Set<Element>();

  /**
   * Maps an element to the number of times this type inferrer
   * analyzed it.
   */
  final Map<Element, int> analyzeCount = new Map<Element, int>();

  /**
   * Maps a class to a [ClassInfoForFinalFields] to help collect type
   * information of final fields.
   */
  final Map<ClassElement, ClassInfoForFinalFields> classInfoForFinalFields =
      new Map<ClassElement, ClassInfoForFinalFields>();

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
  final Map<Node, Selector> setterConstraints = new Map<Node, Selector>();

  /**
   * The work list of the inferrer.
   */
  final WorkSet<Element> workSet = new WorkSet<Element>();

  /**
   * Heuristic for avoiding too many re-analysis of an element.
   */
  final int MAX_ANALYSIS_COUNT_PER_ELEMENT = 5;

  int optimismState;

  /**
   * Sentinel used by the inferrer to notify that it does not know
   * the type of a specific element.
   */
  TypeMask dynamicType;
  bool isDynamicType(TypeMask type) => identical(type, dynamicType);

  TypeMask nullType;
  TypeMask intType;
  TypeMask doubleType;
  TypeMask numType;
  TypeMask boolType;
  TypeMask functionType;
  TypeMask listType;
  TypeMask constListType;
  TypeMask fixedListType;
  TypeMask growableListType;
  TypeMask mapType;
  TypeMask constMapType;
  TypeMask stringType;
  TypeMask typeType;

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

  final Compiler compiler;

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

  InternalSimpleTypesInferrer(this.compiler, this.optimismState);

  /**
   * Main entry point of the inferrer.  Analyzes all elements that the resolver
   * found as reachable. Returns whether it succeeded.
   */
  bool analyzeMain(Element element) {
    initializeTypes();
    buildWorkQueue();
    int analyzed = 0;
    compiler.progress.reset();
    do {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Inferred $analyzed methods.');
        compiler.progress.reset();
      }
      element = workSet.remove();
      if (element.isErroneous()) continue;

      bool wasAnalyzed = analyzeCount.containsKey(element);
      if (wasAnalyzed) {
        recompiles++;
        if (recompiles >= numberOfElementsToAnalyze) {
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
    clear();
    return true;
  }

  /**
   * Query method after the analysis to know the type of [element].
   */
  TypeMask getReturnTypeOfElement(Element element) {
    return getTypeIfValuable(returnTypeOf[element]);
  }

  TypeMask getTypeOfElement(Element element) {
    return getTypeIfValuable(typeOf[element]);
  }

  TypeMask getTypeOfSelector(Selector selector) {
    return getTypeIfValuable(typeOfSelector(selector));
  }

  bool isTypeValuable(TypeMask returnType) {
    return !isDynamicType(returnType);
  }

  TypeMask getTypeIfValuable(TypeMask returnType) {
    return isTypeValuable(returnType) ? returnType : null;
  }

  /**
   * Query method after the analysis to know the type of [node],
   * defined in the context of [owner].
   */
  TypeMask getTypeOfNode(Element owner, Node node) {
    var elements = compiler.enqueuer.resolution.resolvedElements[owner];
    // TODO(ngeoffray): Not sure why the resolver would put a null
    // mapping.
    if (elements == null) return null;
    Selector selector = elements.getSelector(node);
    // TODO(ngeoffray): Should the builder call this method with a
    // SendSet?
    if (selector == null || selector.isSetter() || selector.isIndexSet()) {
      return null;
    }
    return getTypeIfValuable(typeOfSelector(selector));
  }

  void checkAnalyzedAll() {
    if (hasAnalyzedAll) return;
    if (analyzeCount.length != numberOfElementsToAnalyze) return;
    hasAnalyzedAll = true;
    // If we have analyzed all the world, we know all assigments to
    // fields and can therefore infer a type for them.
    typeOfFields.keys.forEach(updateNonFinalFieldType);
    // We also know all calls to methods.
    typeOfArguments.keys.forEach(updateArgumentsType);
  }

  /**
   * Enqueues [e] in the work queue if it is valuable.
   */
  void enqueueAgain(Element e) {
    int count = analyzeCount[e];
    if (count != null && count > MAX_ANALYSIS_COUNT_PER_ELEMENT) return;
    workSet.add(e);
  }

  void enqueueCallersOf(Element element) {
    Set<Element> methodCallers = callersOf[element];
    if (methodCallers != null) {
      methodCallers.forEach(enqueueAgain);
    }
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
            returnTypeOf[element.implementation] = boolType;
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
          new ClassInfoForFinalFields(constructorCount);
    });
  }

  // TODO(ngeoffray): Get rid of this method. Unit tests don't always
  // ensure these classes are resolved.
  rawTypeOf(ClassElement cls) {
    cls.ensureResolved(compiler);
    assert(cls.rawType != null);
    return cls.rawType;
  }

  void initializeTypes() {
    nullType = new TypeMask.empty();

    Backend backend = compiler.backend;
    intType = new TypeMask.nonNullExact(
        rawTypeOf(backend.intImplementation));
    doubleType = new TypeMask.nonNullExact(
        rawTypeOf(backend.doubleImplementation));
    numType = new TypeMask.nonNullSubclass(
        rawTypeOf(backend.numImplementation));
    stringType = new TypeMask.nonNullExact(
        rawTypeOf(backend.stringImplementation));
    boolType = new TypeMask.nonNullExact(
        rawTypeOf(backend.boolImplementation));

    listType = new TypeMask.nonNullExact(
        rawTypeOf(backend.listImplementation));
    constListType = new TypeMask.nonNullExact(
        rawTypeOf(backend.constListImplementation));
    fixedListType = new TypeMask.nonNullExact(
        rawTypeOf(backend.fixedListImplementation));
    growableListType = new TypeMask.nonNullExact(
        rawTypeOf(backend.growableListImplementation));

    mapType = new TypeMask.nonNullSubtype(
        rawTypeOf(backend.mapImplementation));
    constMapType = new TypeMask.nonNullSubtype(
        rawTypeOf(backend.constMapImplementation));
    functionType = new TypeMask.nonNullSubtype(
        rawTypeOf(backend.functionImplementation));
    typeType = new TypeMask.nonNullExact(
        rawTypeOf(backend.typeImplementation));

    dynamicType = new TypeMask.subclass(rawTypeOf(compiler.objectClass));
  }

  dump() {
    int interestingTypes = 0;
    returnTypeOf.forEach((Element element, TypeMask type) {
      if (type != nullType && !isDynamicType(type)) {
        interestingTypes++;
      }
    });
    typeOf.forEach((Element element, TypeMask type) {
      if (type != nullType && !isDynamicType(type)) {
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
    callersOf.clear();
    analyzeCount.clear();
    classInfoForFinalFields.clear();
    typeOfFields.clear();
    setterConstraints.clear();
  }

  bool analyze(Element element) {
    if (element.isForwardingConstructor) {
      element = element.targetConstructor;
    }
    SimpleTypeInferrerVisitor visitor =
        new SimpleTypeInferrerVisitor(element, compiler, this);
    TypeMask returnType = visitor.run();
    if (analyzeCount.containsKey(element)) {
      analyzeCount[element]++;
    } else {
      analyzeCount[element] = 1;
    }
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
          recordNonFinalFieldElementType(node, element, returnType, null);
        }
        return false;
      } else {
        recordNonFinalFieldElementType(node, element, returnType, null);
        // [recordNonFinalFieldElementType] takes care of re-enqueuing
        // users of the field.
        return false;
      }
    } else {
      return recordReturnType(element, returnType);
    }
  }

  bool recordType(Element analyzedElement, TypeMask type) {
    assert(type != null);
    assert(analyzedElement.isField()
           || analyzedElement.isParameter()
           || analyzedElement.isFieldParameter());
    return internalRecordType(analyzedElement, type, typeOf);
  }

  /**
   * Records [returnType] as the return type of [analyzedElement].
   * Returns whether the new type is worth recompiling the callers of
   * [analyzedElement].
   */
  bool recordReturnType(Element analyzedElement, TypeMask returnType) {
    assert(analyzedElement.implementation == analyzedElement);
    if (optimismState == OPTIMISTIC
        && shouldOptimisticallyOptimizeToBool(analyzedElement)
        && returnType != returnTypeOf[analyzedElement]) {
      // One of the functions turned out not to return what we expected.
      // This means we need to restart the analysis.
      optimismState = RETRY;
    }
    return internalRecordType(analyzedElement, returnType, returnTypeOf);
  }

  bool isNativeElement(Element element) {
    if (element.isNative()) return true;
    return element.isMember()
        && element.getEnclosingClass().isNative()
        && element.isField();
  }

  bool internalRecordType(Element analyzedElement,
                          TypeMask newType,
                          Map<Element, TypeMask> types) {
    if (compiler.trustTypeAnnotations
        // Parameters are being checked by the method, and we can
        // therefore only trust their type after the checks.
        || (compiler.enableTypeAssertions && !analyzedElement.isParameter())) {
      var annotation = analyzedElement.computeType(compiler);
      if (types == returnTypeOf) {
        assert(annotation is FunctionType);
        annotation = annotation.returnType;
      }
      newType = narrowType(newType, annotation);
    }

    // Fields and native methods of native classes are handled
    // specially when querying for their type or return type.
    if (isNativeElement(analyzedElement)) return false;
    assert(newType != null);
    TypeMask existing = types[analyzedElement];
    types[analyzedElement] = newType;
    // If the return type is useful, say it has changed.
    return existing != newType
        && !isDynamicType(newType)
        && newType != nullType;
  }

  /**
   * Returns the return type of [element]. Returns [:dynamic:] if
   * [element] has not been analyzed yet.
   */
  TypeMask returnTypeOfElement(Element element) {
    element = element.implementation;
    if (element.isGenerativeConstructor()) {
      return returnTypeOf.putIfAbsent(element, () {
        return new TypeMask.nonNullExact(
            rawTypeOf(element.getEnclosingClass()));
      });
    } else if (element.isNative()) {
      return returnTypeOf.putIfAbsent(element, () {
        var elementType = element.computeType(compiler);
        if (elementType.kind != TypeKind.FUNCTION) {
          return dynamicType;
        }
        return typeOfNativeBehavior(
            native.NativeBehavior.ofMethod(element, compiler));
      });
    }
    TypeMask returnType = returnTypeOf[element];
    if (returnType == null) {
      if ((compiler.trustTypeAnnotations || compiler.enableTypeAssertions)
          && (element.isFunction()
              || element.isGetter()
              || element.isFactoryConstructor())) {
        FunctionType functionType = element.computeType(compiler);
        returnType = narrowType(dynamicType, functionType.returnType);
      } else {
        returnType = dynamicType;
      }
    }
    return returnType;
  }

  TypeMask typeOfNativeBehavior(native.NativeBehavior nativeBehavior) {
    if (nativeBehavior == null) return dynamicType;
    List typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return dynamicType;
    TypeMask returnType;
    for (var type in typesReturned) {
      TypeMask mappedType;
      if (type == native.SpecialType.JsObject) {
        mappedType = new TypeMask.nonNullExact(rawTypeOf(compiler.objectClass));
      } else if (type == native.SpecialType.JsArray) {
        mappedType = listType;
      } else if (type.element == compiler.stringClass) {
        mappedType = stringType;
      } else if (type.element == compiler.intClass) {
        mappedType = intType;
      } else if (type.element == compiler.doubleClass) {
        mappedType = doubleType;
      } else if (type.element == compiler.numClass) {
        mappedType = numType;
      } else if (type.element == compiler.boolClass) {
        mappedType = boolType;
      } else if (type.element == compiler.nullClass) {
        mappedType = nullType;
      } else if (type.isVoid) {
        mappedType = nullType;
      } else if (type.isDynamic) {
        return dynamicType;
      } else if (compiler.world.hasAnySubclass(type.element)) {
        mappedType = new TypeMask.nonNullSubclass(rawTypeOf(type.element));
      } else if (compiler.world.hasAnySubtype(type.element)) {
        mappedType = new TypeMask.nonNullSubtype(rawTypeOf(type.element));
      } else {
        mappedType = new TypeMask.nonNullExact(rawTypeOf(type.element));
      }
      returnType = computeLUB(returnType, mappedType);
      if (!isTypeValuable(returnType)) {
        returnType = dynamicType;
        break;
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
    if (isNativeElement(element) && element.isField()) {
      var type = typeOf.putIfAbsent(element, () {
        InterfaceType rawType = element.computeType(compiler).asRaw();
        return rawType.isDynamic ? dynamicType : new TypeMask.subtype(rawType);
      });
      assert(type != null);
      return type;
    }
    TypeMask type = typeOf[element];
    if (type == null) {
      if ((compiler.trustTypeAnnotations
           && (element.isField()
               || element.isParameter()
               || element.isVariable()))
          // Parameters are being checked by the method, and we can
          // therefore only trust their type after the checks.
          || (compiler.enableTypeAssertions
              && (element.isField() || element.isVariable()))) {
        type = narrowType(dynamicType, element.computeType(compiler));
      } else {
        type = dynamicType;
      }
    }
    return type;
  }

  /**
   * Returns the union of the types of all elements that match
   * the called [selector].
   */
  TypeMask typeOfSelector(Selector selector) {
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall()) return dynamicType;

    TypeMask result;
    iterateOverElements(selector, (Element element) {
      assert(element.isImplementation);
      TypeMask type = typeOfElementWithSelector(element, selector);
      result = computeLUB(result, type);
      return isTypeValuable(result);
    });
    if (result == null) {
      result = dynamicType;
    }
    return result;
  }

  TypeMask typeOfElementWithSelector(Element element, Selector selector) {
    if (element.name == Compiler.NO_SUCH_METHOD
        && selector.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return returnTypeOfElement(element);
    } else if (selector.isGetter()) {
      if (element.isFunction()) {
        // [functionType] is null if the inferrer did not run.
        return functionType == null ? dynamicType : functionType;
      } else if (element.isField()) {
        return typeOfElement(element);
      } else if (Elements.isUnresolved(element)) {
        return dynamicType;
      } else {
        assert(element.isGetter());
        return returnTypeOfElement(element);
      }
    } else {
      return returnTypeOfElement(element);
    }
  }

  bool isNotClosure(Element element) {
    // If the outermost enclosing element of [element] is [element]
    // itself, we know it cannot be a closure.
    Element outermost = element.getOutermostEnclosingMemberOrTopLevel();
    return outermost.declaration == element.declaration;
  }

  void addCaller(Element caller, Element callee) {
    assert(caller.isImplementation);
    assert(callee.isImplementation);
    assert(isNotClosure(caller));
    Set<Element> callers = callersOf.putIfAbsent(
        callee, () => new Set<Element>());
    callers.add(caller);
  }

  bool addArguments(Node node, Element element, ArgumentsTypes arguments) {
    Map<Node, ArgumentsTypes> types = typeOfArguments.putIfAbsent(
        element, () => new Map<Node, ArgumentsTypes>());
    ArgumentsTypes existing = types[node];
    types[node] = arguments;
    return existing != arguments;
  }

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
   * Registers that [caller] calls [callee] with the given
   * [arguments]. [constraint] is a setter constraint (see
   * [setterConstraints] documentation).
   */
  void registerCalledElement(Node node,
                             Selector selector,
                             Element caller,
                             Element callee,
                             ArgumentsTypes arguments,
                             Selector constraint,
                             SideEffects sideEffects,
                             bool inLoop) {
    updateSideEffects(sideEffects, selector, callee);

    // Bailout for closure calls. We're not tracking types of
    // arguments for closures.
    if (callee.isInstanceMember() && selector.isClosureCall()) {
      return;
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
    if (!analyzeCount.containsKey(caller)) {
      addCaller(caller, callee);
    }

    if (selector.isSetter() && callee.isField()) {
      recordNonFinalFieldElementType(
          node, callee, arguments.positional[0], constraint);
      return;
    } else if (selector.isGetter()) {
      assert(arguments == null);
      if (callee.isFunction()) {
        methodsThatCanBeClosurized.add(callee);
      }
      return;
    } else if (callee.isField()) {
      // We're not tracking closure calls.
      return;
    } else if (callee.isGetter()) {
      // Getters don't have arguments.
      return;
    }
    FunctionElement function = callee;
    if (function.computeSignature(compiler).parameterCount == 0) return;

    assert(arguments != null);
    bool isUseful = addArguments(node, callee, arguments);
    if (hasAnalyzedAll && isUseful) {
      enqueueAgain(callee);
    }
  }

  void unregisterCalledElement(Node node,
                               Selector selector,
                               Element caller,
                               Element callee) {
    if (callee.isField()) {
      if (selector.isSetter()) {
        Map<Node, TypeMask> types = typeOfFields[callee];
        if (types == null || !types.containsKey(node)) return;
        types.remove(node);
        if (hasAnalyzedAll) updateNonFinalFieldType(callee);
      }
    } else if (callee.isGetter()) {
      return;
    } else {
      Map<Node, ArgumentsTypes> types = typeOfArguments[callee];
      if (types == null || !types.containsKey(node)) return;
      types.remove(node);
      if (hasAnalyzedAll) enqueueAgain(callee);
    }
  }

  /**
   * Computes the parameter types of [element], based on all call sites we
   * have collected on that [element]. This method can only be called after
   * we have analyzed all elements in the world.
   */
  void updateArgumentsType(FunctionElement element) {
    assert(hasAnalyzedAll);
    if (methodsThatCanBeClosurized.contains(element)) return;
    // A [noSuchMethod] method can be the target of any call, with
    // any number of arguments. For simplicity, we just do not
    // infer any parameter types for [noSuchMethod].
    if (element.name == Compiler.NO_SUCH_METHOD) return;
    FunctionSignature signature = element.computeSignature(compiler);

    if (typeOfArguments[element] == null || typeOfArguments[element].isEmpty) {
      signature.forEachParameter((Element parameter) {
        typeOf.remove(parameter);
      });
      return;
    }

    int parameterIndex = 0;
    bool changed = false;
    bool visitingOptionalParameter = false;
    signature.forEachParameter((Element parameter) {
      if (parameter == signature.firstOptionalParameter) {
        visitingOptionalParameter = true;
      }
      TypeMask type;
      typeOfArguments[element].forEach((_, ArgumentsTypes arguments) {
        if (!visitingOptionalParameter) {
          type = computeLUB(type, arguments.positional[parameterIndex]);
        } else {
          TypeMask argumentType = signature.optionalParametersAreNamed
              ? arguments.named[parameter.name]
              : parameterIndex < arguments.positional.length
                  ? arguments.positional[parameterIndex]
                  : null;
          if (argumentType == null) {
            argumentType = defaultTypeOfParameter[parameter];
          }
          assert(argumentType != null);
          type = computeLUB(type, argumentType);
        }
      });
      if (recordType(parameter, type)) {
        changed = true;
      }
      parameterIndex++;
    });

    if (changed) enqueueAgain(element);
  }

  TypeMask handleIntrisifiedSelector(Selector selector,
                                     ArgumentsTypes arguments) {
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
                                  Selector constraint,
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

        if (!selector.isSetter()) {
          TypeMask type = handleIntrisifiedSelector(selector, arguments);
          if (type == null) type = typeOfElementWithSelector(element, selector);
          result = computeLUB(result, type);
        }
      }
    }

    if (result == null) {
      result = dynamicType;
    }
    return result;
  }

  /**
   * Applies [f] to all elements in the universe that match
   * [selector]. If [f] returns false, aborts the iteration.
   */
  void iterateOverElements(Selector selector, bool f(Element element)) {
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element e in elements) {
      if (!f(e.implementation)) return;
    }
  }

  /**
   * Records an assignment to [element] with the given
   * [argumentType].
   */
  void recordNonFinalFieldElementType(Node node,
                                      Element element,
                                      TypeMask argumentType,
                                      Selector constraint) {
    Map<Node, TypeMask> map =
        typeOfFields.putIfAbsent(element, () => new Map<Node, TypeMask>());
    map[node] = argumentType;
    bool changed = typeOf[element] != argumentType;
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

  TypeMask computeFieldTypeWithConstraints(Element element, Map types) {
    Set<Selector> constraints = new Set<Selector>();
    TypeMask fieldType;
    types.forEach((Node node, TypeMask mask) {
      Selector constraint = setterConstraints[node];
      if (constraint != null) {
        // If this update has a constraint, we collect it and don't
        // use its type.
        constraints.add(constraint);
      } else {
        fieldType = computeLUB(fieldType, mask);
      }
    });

    if (!constraints.isEmpty && !isDynamicType(fieldType)) {
      // Now that we have found a type, we go over the collected
      // constraints, and make sure they apply to the found type. We
      // update [typeOf] to make sure [typeOfSelector] knows the field
      // type.
      TypeMask existing = typeOf[element];
      typeOf[element] = fieldType;

      for (Selector constraint in constraints) {
        if (constraint.isOperator()) {
          // If the constraint is on an operator, we type the receiver
          // to be the field.
          constraint = new TypedSelector(fieldType, constraint);
        } else {
          // Otherwise the constraint is on the form [: field = other.field :].
          assert(constraint.isGetter());
        }
        fieldType = computeLUB(fieldType, typeOfSelector(constraint));
      }
      if (existing == null) {
        typeOf.remove(element);
      } else {
        typeOf[element] = existing;
      }
    }
    return fieldType;
  }

  /**
   * Computes the type of [element], based on all assignments we have
   * collected on that [element]. This method can only be called after
   * we have analyzed all elements in the world.
   */
  void updateNonFinalFieldType(Element element) {
    if (isNativeElement(element)) return;
    assert(hasAnalyzedAll);

    if (typeOfFields[element] == null || typeOfFields[element].isEmpty) {
      typeOf.remove(element);
      return;
    }

    TypeMask fieldType = computeFieldTypeWithConstraints(
        element, typeOfFields[element]);

    // If the type of [element] has changed, re-analyze its users.
    if (recordType(element, fieldType)) {
      enqueueCallersOf(element);
    }
  }

  /**
   * Records in [classInfoForFinalFields] that [constructor] has
   * inferred [type] for the final [field].
   */
  void recordFinalFieldType(Node node,
                            Element constructor,
                            Element field,
                            TypeMask type,
                            Selector constraint) {
    if (constraint != null) {
      setterConstraints[node] = constraint;
    }
    // If the field is being set at its declaration site, it is not
    // being tracked in the [classInfoForFinalFields] map.
    if (constructor == field) return;
    assert(field.modifiers.isFinal() || field.modifiers.isConst());
    ClassElement cls = constructor.getEnclosingClass();
    ClassInfoForFinalFields info = classInfoForFinalFields[cls.implementation];
    info.recordFinalFieldType(node, constructor, field, type);
  }

  /**
   * Records that we are done analyzing [constructor]. If all
   * generative constructors of its enclosing class have already been
   * analyzed, this method updates the types of final fields.
   */
  void doneAnalyzingGenerativeConstructor(Element constructor) {
    ClassElement cls = constructor.getEnclosingClass();
    ClassInfoForFinalFields info = classInfoForFinalFields[cls.implementation];
    info.doneAnalyzingGenerativeConstructor(constructor);
    if (info.isDone) {
      updateFinalFieldsType(info);
    }
  }

  /**
   * Updates types of final fields listed in [info].
   */
  void updateFinalFieldsType(ClassInfoForFinalFields info) {
    assert(info.isDone);
    info.typesOfFinalFields.forEach((Element field,
                                     Map<Node, TypeMask> types) {
      if (isNativeElement(field)) return;
      assert(field.modifiers.isFinal());
      TypeMask fieldType = computeFieldTypeWithConstraints(field, types);
      if (recordType(field, fieldType)) {
        enqueueCallersOf(field);
      }
    });
  }

  /**
   * Returns the least upper bound between [firstType] and
   * [secondType].
   */
  TypeMask computeLUB(TypeMask firstType, TypeMask secondType) {
    if (firstType == null) {
      return secondType;
    } else if (isDynamicType(secondType)) {
      return secondType;
    } else if (isDynamicType(firstType)) {
      return firstType;
    } else {
      TypeMask union = firstType.union(secondType, compiler);
      // TODO(kasperl): If the union isn't nullable it seems wasteful
      // to use dynamic. Fix that.
      return union.containsAll(compiler) ? dynamicType : union;
    }
  }

  TypeMask narrowType(TypeMask type,
                      DartType annotation,
                      {bool isNullable: true}) {
    if (annotation.isDynamic) return type;
    if (annotation.isMalformed) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == compiler.objectClass) return type;
    TypeMask otherType;
    if (annotation.kind == TypeKind.TYPEDEF
        || annotation.kind == TypeKind.FUNCTION) {
      otherType = functionType;
    } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
      return type;
    } else {
      assert(annotation.kind == TypeKind.INTERFACE);
      otherType = new TypeMask.nonNullSubtype(annotation);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type == null) return otherType;
    return type.intersection(otherType, compiler);
  }
}

/**
 * Placeholder for inferred arguments types on sends.
 */
class ArgumentsTypes {
  final List<TypeMask> positional;
  final Map<SourceString, TypeMask> named;
  ArgumentsTypes(this.positional, named)
    : this.named = (named == null) ? new Map<SourceString, TypeMask>() : named;

  int get length => positional.length + named.length;

  String toString() => "{ positional = $positional, named = $named }";

  bool operator==(other) {
    if (positional.length != other.positional.length) return false;
    if (named.length != other.named.length) return false;
    for (int i = 0; i < positional.length; i++) {
      if (positional[i] != other.positional[i]) return false;
    }
    named.forEach((name, type) {
      if (other.named[name] != type) return false;
    });
    return true;
  }

  bool hasNoArguments() => positional.isEmpty && named.isEmpty;

  bool hasOnePositionalArgumentWithType(TypeMask type) {
    return named.isEmpty && positional.length == 1 && positional[0] == type;
  }
}

/**
 * Placeholder for inferred types of local variables.
 */
class LocalsHandler {
  final InternalSimpleTypesInferrer inferrer;
  final Map<Element, TypeMask> locals;
  final Map<Element, Element> capturedAndBoxed;
  final Map<Element, TypeMask> fieldsInitializedInConstructor;
  final bool inTryBlock;
  bool isThisExposed;
  bool seenReturn = false;
  bool seenBreakOrContinue = false;

  bool get aborts {
    return seenReturn || seenBreakOrContinue;
  }

  LocalsHandler(this.inferrer)
      : locals = new Map<Element, TypeMask>(),
        capturedAndBoxed = new Map<Element, Element>(),
        fieldsInitializedInConstructor = new Map<Element, TypeMask>(),
        inTryBlock = false,
        isThisExposed = true;
  LocalsHandler.from(LocalsHandler other, {bool inTryBlock: false})
      : locals = new Map<Element, TypeMask>.from(other.locals),
        capturedAndBoxed = new Map<Element, Element>.from(
            other.capturedAndBoxed),
        fieldsInitializedInConstructor = new Map<Element, TypeMask>.from(
            other.fieldsInitializedInConstructor),
        inTryBlock = other.inTryBlock || inTryBlock,
        inferrer = other.inferrer,
        isThisExposed = other.isThisExposed;

  TypeMask use(Element local) {
    if (capturedAndBoxed.containsKey(local)) {
      return inferrer.typeOfElement(capturedAndBoxed[local]);
    }
    return locals[local];
  }

  void update(Element local, TypeMask type) {
    assert(type != null);
    if (inferrer.compiler.trustTypeAnnotations
        || inferrer.compiler.enableTypeAssertions) {
      type = inferrer.narrowType(type, local.computeType(inferrer.compiler));
    }
    if (capturedAndBoxed.containsKey(local) || inTryBlock) {
      // If a local is captured and boxed, or is set in a try block,
      // we compute the LUB of its assignments.
      //
      // We don't know if an assignment in a try block
      // will be executed, so all assigments in that block are
      // potential types after we have left it.
      type = inferrer.computeLUB(locals[local], type);
    }
    locals[local] = type;
  }

  void setCapturedAndBoxed(Element local, Element field) {
    capturedAndBoxed[local] = field;
  }

  /**
   * Merge handlers [first] and [second] into [:this:] and returns
   * whether the merge changed one of the variables types in [first].
   */
  bool merge(LocalsHandler other, {bool discardIfAborts: true}) {
    bool changed = false;
    List<Element> toRemove = <Element>[];
    // Iterating over a map and just updating its entries is OK.
    locals.forEach((Element local, TypeMask oldType) {
      TypeMask otherType = other.locals[local];
      bool isCaptured = capturedAndBoxed.containsKey(local);
      if (otherType == null) {
        if (!isCaptured) {
          // If [local] is not in the other map and is not captured
          // and boxed, we know it is not a
          // local we want to keep. For example, in an if/else, we don't
          // want to keep variables declared in the if or in the else
          // branch at the merge point.
          toRemove.add(local);
        }
        return;
      }
      if (!isCaptured && aborts && discardIfAborts) {
        locals[local] = otherType;
      } else if (!isCaptured && other.aborts && discardIfAborts) {
        // Don't do anything.
      } else {
        TypeMask type = inferrer.computeLUB(oldType, otherType);
        if (type != oldType) changed = true;
        locals[local] = type;
      }
    });

    // Remove locals that will not be used anymore.
    toRemove.forEach((Element element) {
      locals.remove(element);
    });

    // Update the locals that are captured and boxed. We
    // unconditionally add them to [this] because we register the type
    // of boxed variables after analyzing all closures.
    other.capturedAndBoxed.forEach((Element local, Element field) {
      capturedAndBoxed[local] =  field;
      // If [element] is not in our [locals], we need to update it.
      // Otherwise, we have already computed the LUB of it.
      if (locals[local] == null) {
        locals[local] = other.locals[local];
      }
    });

    // Merge instance fields initialized in both handlers. This is
    // only relevant for generative constructors.
    toRemove = <Element>[];
    // Iterate over the map in [:this:]. The map in [other] may
    // contain different fields, but if this map does not contain it,
    // then we know the field can be null and we don't need to track
    // it.
    fieldsInitializedInConstructor.forEach((Element element, TypeMask type) {
      TypeMask otherType = other.fieldsInitializedInConstructor[element];
      if (otherType == null) {
        toRemove.add(element);
      } else {
        fieldsInitializedInConstructor[element] =
            inferrer.computeLUB(type, otherType);
      }
    });
    // Remove fields that were not initialized in [other].
    toRemove.forEach((Element element) {
      fieldsInitializedInConstructor.remove(element);
    });
    isThisExposed = isThisExposed || other.isThisExposed;
    seenReturn = seenReturn && other.seenReturn;
    seenBreakOrContinue = seenBreakOrContinue && other.seenBreakOrContinue;

    return changed;
  }

  void updateField(Element element, TypeMask type) {
    if (isThisExposed) return;
    fieldsInitializedInConstructor[element] = type;
  }
}

class SimpleTypeInferrerVisitor extends ResolvedVisitor<TypeMask> {
  final Element analyzedElement;
  final Element outermostElement;
  final InternalSimpleTypesInferrer inferrer;
  final Compiler compiler;
  final Map<TargetElement, List<LocalsHandler>> breaksFor =
      new Map<TargetElement, List<LocalsHandler>>();
  final Map<TargetElement, List<LocalsHandler>> continuesFor =
      new Map<TargetElement, List<LocalsHandler>>();
  LocalsHandler locals;
  TypeMask returnType;

  bool visitingInitializers = false;
  bool isConstructorRedirect = false;
  bool accumulateIsChecks = false;
  bool conditionIsSimple = false;

  List<Send> isChecks;
  int loopLevel = 0;
  SideEffects sideEffects = new SideEffects.empty();

  bool get inLoop => loopLevel > 0;
  bool get isThisExposed => locals.isThisExposed;
  void set isThisExposed(value) { locals.isThisExposed = value; }

  SimpleTypeInferrerVisitor.internal(TreeElements mapping,
                                     this.analyzedElement,
                                     this.outermostElement,
                                     this.inferrer,
                                     this.compiler,
                                     this.locals)
    : super(mapping);

  factory SimpleTypeInferrerVisitor(Element element,
                                    Compiler compiler,
                                    InternalSimpleTypesInferrer inferrer,
                                    [LocalsHandler handler]) {
    Element outermostElement =
        element.getOutermostEnclosingMemberOrTopLevel().implementation;
    TreeElements elements = compiler.enqueuer.resolution.resolvedElements[
        outermostElement.declaration];
    assert(elements != null);
    assert(outermostElement != null);
    handler = handler != null ? handler : new LocalsHandler(inferrer);
    return new SimpleTypeInferrerVisitor.internal(
        elements, element, outermostElement, inferrer, compiler, handler);
  }

  TypeMask run() {
    var node = analyzedElement.parseNode(compiler);
    if (analyzedElement.isField() && node.asSendSet() == null) {
      // Eagerly bailout, because computing the closure data only
      // works for functions and field assignments.
      return inferrer.nullType;
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
    if (inferrer.hasAnalyzedAll) {
      inferrer.updateArgumentsType(function);
    }
    FunctionSignature signature = function.computeSignature(compiler);
    signature.forEachOptionalParameter((element) {
      Node node = element.parseNode(compiler);
      Send send = node.asSendSet();
      inferrer.defaultTypeOfParameter[element] = (send == null)
          ? inferrer.nullType
          : visit(send.arguments.head);
      assert(inferrer.defaultTypeOfParameter[element] != null);
    });

    if (analyzedElement.isNative()) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      return inferrer.dynamicType;
    }

    if (analyzedElement.isGenerativeConstructor()) {
      isThisExposed = false;
      signature.forEachParameter((element) {
        TypeMask parameterType = inferrer.typeOfElement(element);
        if (element.kind == ElementKind.FIELD_PARAMETER) {
          if (element.fieldElement.modifiers.isFinal()) {
            inferrer.recordFinalFieldType(
                node,
                analyzedElement,
                element.fieldElement,
                parameterType,
                null);
          } else {
            locals.updateField(element.fieldElement, parameterType);
            inferrer.recordNonFinalFieldElementType(
                element.parseNode(compiler),
                element.fieldElement,
                parameterType,
                null);
          }
        } else {
          locals.update(element, parameterType);
        }
      });
      visitingInitializers = true;
      visit(node.initializers);
      visitingInitializers = false;
      visit(node.body);
      ClassElement cls = analyzedElement.getEnclosingClass();
      if (!isConstructorRedirect) {
        // Iterate over all instance fields, and give a null type to
        // fields that we haven't initialized for sure.
        cls.forEachInstanceField((_, field) {
          if (field.modifiers.isFinal()) return;
          TypeMask type = locals.fieldsInitializedInConstructor[field];
          if (type == null && field.parseNode(compiler).asSendSet() == null) {
            inferrer.recordNonFinalFieldElementType(
                node, field, inferrer.nullType, null);
          }
        });
      }
      inferrer.doneAnalyzingGenerativeConstructor(analyzedElement);
      returnType = new TypeMask.nonNullExact(inferrer.rawTypeOf(cls));
    } else {
      signature.forEachParameter((element) {
        locals.update(element, inferrer.typeOfElement(element));
      });
      visit(node.body);
      if (returnType == null) {
        // No return in the body.
        returnType = inferrer.nullType;
      } else if (!locals.seenReturn && !inferrer.isDynamicType(returnType)) {
        // We haven't seen returns on all branches. So the method may
        // also return null.
        returnType = returnType.nullable();
      }

      if (analyzedElement.name == const SourceString('==')) {
        // TODO(ngeoffray): Should this be done at the call site?
        // When the argument passed in is null, we know we return a
        // bool.
        signature.forEachParameter((Element parameter) {
          if (inferrer.typeOfElement(parameter).isNullable){
            returnType = inferrer.computeLUB(returnType, inferrer.boolType);
          }
        });
      }
    }

    if (analyzedElement == outermostElement) {
      bool changed = false;
      locals.capturedAndBoxed.forEach((Element local, Element field) {
        if (inferrer.recordType(field, locals.locals[local])) {
          changed = true;
        }
      });
      // TODO(ngeoffray): Re-analyze method if [changed]?
    }
    compiler.world.registerSideEffects(analyzedElement, sideEffects);    
    assert(breaksFor.isEmpty);
    assert(continuesFor.isEmpty);
    return returnType;
  }

  TypeMask _thisType;
  TypeMask get thisType {
    if (_thisType != null) return _thisType;
    ClassElement cls = outermostElement.getEnclosingClass();
    if (compiler.world.isUsedAsMixin(cls)) {
      return _thisType = new TypeMask.nonNullSubtype(inferrer.rawTypeOf(cls));
    } else if (compiler.world.hasAnySubclass(cls)) {
      return _thisType = new TypeMask.nonNullSubclass(inferrer.rawTypeOf(cls));
    } else {
      return _thisType = new TypeMask.nonNullExact(inferrer.rawTypeOf(cls));
    }
  }

  TypeMask _superType;
  TypeMask get superType {
    if (_superType != null) return _superType;
    return _superType = new TypeMask.nonNullExact(
        inferrer.rawTypeOf(outermostElement.getEnclosingClass().superclass));
  }

  void recordReturnType(TypeMask type) {
    returnType = inferrer.computeLUB(returnType, type);
  }

  TypeMask visitNode(Node node) {
    node.visitChildren(this);
    return inferrer.dynamicType;
  }

  TypeMask visitNewExpression(NewExpression node) {
    return node.send.accept(this);
  }

  TypeMask visit(Node node) {
    return node == null ? inferrer.dynamicType : node.accept(this);
  }

  TypeMask visitFunctionExpression(FunctionExpression node) {
    Element element = elements[node];
    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalsHandler closureLocals = new LocalsHandler.from(locals);
    SimpleTypeInferrerVisitor visitor = new SimpleTypeInferrerVisitor(
        element, compiler, inferrer, closureLocals);
    visitor.run();
    inferrer.recordReturnType(element, visitor.returnType);
    locals.merge(visitor.locals);

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure. Note that analyzing the same closure multiple
    // times closure will refine the type of those variables, therefore
    // [:inferrer.typeOf[variable]:] is not necessarilly null, nor the
    // same as [newType].
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    nestedClosureData.forEachNonBoxedCapturedVariable((variable, field) {
      // The type may be null for instance contexts (this and type
      // parameters), as well as captured argument checks.
      if (locals.locals[variable] == null) return;
      inferrer.recordType(field, locals.locals[variable]);
    });

    return inferrer.functionType;
  }

  TypeMask visitFunctionDeclaration(FunctionDeclaration node) {
    locals.update(elements[node], inferrer.functionType);
    return visit(node.function);
  }

  TypeMask visitLiteralString(LiteralString node) {
    return inferrer.stringType;
  }

  TypeMask visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return inferrer.stringType;
  }

  TypeMask visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
    return inferrer.stringType;
  }

  TypeMask visitLiteralBool(LiteralBool node) {
    return inferrer.boolType;
  }

  TypeMask visitLiteralDouble(LiteralDouble node) {
    return inferrer.doubleType;
  }

  TypeMask visitLiteralInt(LiteralInt node) {
    return inferrer.intType;
  }

  TypeMask visitLiteralList(LiteralList node) {
    node.visitChildren(this);
    return node.isConst()
        ? inferrer.constListType
        : inferrer.growableListType;
  }

  TypeMask visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
    return node.isConst()
        ? inferrer.constMapType
        : inferrer.mapType;
  }

  TypeMask visitLiteralNull(LiteralNull node) {
    return inferrer.nullType;
  }

  TypeMask visitTypeReferenceSend(Send node) {
    return inferrer.typeType;
  }

  bool isThisOrSuper(Node node) => node.isThis() || node.isSuper();

  void checkIfExposesThis(Selector selector) {
    if (isThisExposed) return;
    inferrer.iterateOverElements(selector, (element) {
      if (element.isField()) {
        if (!selector.isSetter()
            && element.getEnclosingClass() ==
                    outermostElement.getEnclosingClass()
            && !element.modifiers.isFinal()
            && locals.fieldsInitializedInConstructor[element] == null
            && element.parseNode(compiler).asSendSet() == null) {
          // If the field is being used before this constructor
          // actually had a chance to initialize it, say it can be
          // null.
          inferrer.recordNonFinalFieldElementType(
              analyzedElement.parseNode(compiler), element,
              inferrer.nullType, null);
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

  TypeMask visitSendSet(SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType()) {
      node.visitChildren(this);
      return inferrer.dynamicType;
    }

    Selector getterSelector =
        elements.getGetterSelectorInComplexSendSet(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    Selector setterSelector = elements.getSelector(node);

    String op = node.assignmentOperator.source.stringValue;
    bool isIncrementOrDecrement = op == '++' || op == '--';

    TypeMask receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null
        && element != null
        && element.isInstanceMember()) {
      receiverType = thisType;
      isCallOnThis = true;
    } else {
      receiverType = visit(node.receiver);
      isCallOnThis = node.receiver != null && isThisOrSuper(node.receiver);
    }

    TypeMask rhsType;
    TypeMask indexType;

    if (isIncrementOrDecrement) {
      rhsType = inferrer.intType;
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
        checkIfExposesThis(new TypedSelector(receiverType, setterSelector));
      }
    }

    if (node.isIndex) {
      if (op == '=') {
        // [: foo[0] = 42 :]
        handleDynamicSend(
            node,
            setterSelector,
            receiverType,
            new ArgumentsTypes([indexType, rhsType], null));
        return rhsType;
      } else {
        // [: foo[0] += 42 :] or [: foo[0]++ :].
        TypeMask getterType = handleDynamicSend(
            node,
            getterSelector,
            receiverType,
            new ArgumentsTypes([indexType], null));
        TypeMask returnType = handleDynamicSend(
            node,
            operatorSelector,
            getterType,
            new ArgumentsTypes([rhsType], null));
        handleDynamicSend(
            node,
            setterSelector,
            receiverType,
            new ArgumentsTypes([indexType, returnType], null));

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
      Selector constraint;
      if (!Elements.isLocal(element)) {
        // Record a constraint of the form [: field++ :], or [: field += 42 :].
        constraint = operatorSelector;
      }
      TypeMask getterType;
      TypeMask newType;
      ArgumentsTypes operatorArguments = new ArgumentsTypes([rhsType], null);
      if (Elements.isStaticOrTopLevelField(element)) {
        Element getterElement = elements[node.selector];
        getterType =
            inferrer.typeOfElementWithSelector(getterElement, getterSelector);
        handleStaticSend(node, getterSelector, getterElement, null);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        handleStaticSend(
            node, setterSelector, element,
            new ArgumentsTypes([newType], null));
      } else if (Elements.isUnresolved(element)
                 || element.isSetter()
                 || element.isField()) {
        getterType = handleDynamicSend(
            node, getterSelector, receiverType, null);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        handleDynamicSend(node, setterSelector, receiverType,
                          new ArgumentsTypes([newType], null),
                          constraint);
      } else if (Elements.isLocal(element)) {
        getterType = locals.use(element);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        locals.update(element, newType);
      } else {
        // Bogus SendSet, for example [: myMethod += 42 :].
        getterType = inferrer.dynamicType;
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

  TypeMask handlePlainAssignment(Node node,
                                 Element element,
                                 Selector setterSelector,
                                 TypeMask receiverType,
                                 TypeMask rhsType,
                                 Node rhs) {
    Selector constraint;
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
        constraint = elements.getSelector(rhs);
      }
    }
    ArgumentsTypes arguments = new ArgumentsTypes([rhsType], null);
    if (Elements.isStaticOrTopLevelField(element)) {
      handleStaticSend(node, setterSelector, element, arguments);
    } else if (Elements.isUnresolved(element) || element.isSetter()) {
      handleDynamicSend(
          node, setterSelector, receiverType, arguments, constraint);
    } else if (element.isField()) {
      if (element.modifiers.isFinal()) {
        inferrer.recordFinalFieldType(
            node, outermostElement, element, rhsType, constraint);
      } else {
        locals.updateField(element, rhsType);
        if (visitingInitializers) {
          inferrer.recordNonFinalFieldElementType(
              node, element, rhsType, constraint);
        } else {
          handleDynamicSend(
              node, setterSelector, receiverType, arguments, constraint);
        }
      }
    } else if (Elements.isLocal(element)) {
      locals.update(element, rhsType);
    }
    return rhsType;
  }

  TypeMask visitIdentifier(Identifier node) {
    if (node.isThis()) {
      return thisType;
    } else if (node.isSuper()) {
      return superType;
    }
    return inferrer.dynamicType;
  }

  TypeMask visitSuperSend(Send node) {
    Element element = elements[node];
    if (Elements.isUnresolved(element)) {
      return inferrer.dynamicType;
    }
    Selector selector = elements.getSelector(node);
    // TODO(ngeoffray): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    if (node.isPropertyAccess) {
      handleStaticSend(node, selector, element, null);
      return inferrer.typeOfElementWithSelector(element, selector);
    } else if (element.isFunction()) {
      if (!selector.applies(element, compiler)) return inferrer.dynamicType;
      ArgumentsTypes arguments = analyzeArguments(node.arguments);
      handleStaticSend(node, selector, element, arguments);
      return inferrer.returnTypeOfElement(element);
    } else {
      analyzeArguments(node.arguments);
      // Closure call on a getter. We don't have function types yet,
      // so we just return [:dynamic:].
      return inferrer.dynamicType;
    }
  }

  TypeMask visitStaticSend(Send node) {
    if (visitingInitializers && Initializers.isConstructorRedirect(node)) {
      isConstructorRedirect = true;
    }
    Element element = elements[node];
    if (element.isForeign(compiler)) {
      return handleForeignSend(node);
    }
    Selector selector = elements.getSelector(node);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    if (!selector.applies(element, compiler)) return inferrer.dynamicType;

    handleStaticSend(node, selector, element, arguments);
    if (Elements.isGrowableListConstructorCall(element, node, compiler)) {
      return inferrer.growableListType;
    } else if (Elements.isFixedListConstructorCall(element, node, compiler)) {
      return inferrer.fixedListType;
    } else if (element.isFunction() || element.isConstructor()) {
      return inferrer.returnTypeOfElement(element);
    } else {
      assert(element.isField() || element.isGetter());
      // Closure call.
      return inferrer.dynamicType;
    }
  }

  TypeMask handleForeignSend(Send node) {
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
               || name == const SourceString('JS_OBJECT_CLASS_NAME')) {
      return inferrer.stringType;
    } else {
      sideEffects.setAllSideEffects();
      return inferrer.dynamicType;
    }
  }

  ArgumentsTypes analyzeArguments(Link<Node> arguments) {
    List<TypeMask> positional = [];
    Map<SourceString, TypeMask> named = new Map<SourceString, TypeMask>();
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
    return new ArgumentsTypes(positional, named);
  }

  void potentiallyAddIsCheck(Send node) {
    if (!accumulateIsChecks) return;
    if (!Elements.isLocal(elements[node.receiver])) return;
    isChecks.add(node);
  }

  void updateIsChecks(List<Node> tests, {bool usePositive}) {
    if (tests == null) return;
    for (Send node in tests) {
      if (node.isIsNotCheck) {
        if (usePositive) continue;
      } else {
        if (!usePositive) continue;
      }
      DartType type = elements.getType(node.typeAnnotationFromIsCheck);
      Element element = elements[node.receiver];
      TypeMask existing = locals.use(element);
      TypeMask newType = inferrer.narrowType(existing, type, isNullable: false);
      locals.update(element, newType);
    }
  }

  TypeMask visitOperatorSend(Send node) {
    Operator op = node.selector;
    if (const SourceString("[]") == op.source) {
      return visitDynamicSend(node);
    } else if (const SourceString("&&") == op.source) {
      conditionIsSimple = false;
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = true;
      if (isChecks == null) isChecks = <Send>[];
      visit(node.receiver);
      accumulateIsChecks = oldAccumulateIsChecks;
      if (!accumulateIsChecks) isChecks = null;
      LocalsHandler saved = new LocalsHandler.from(locals);
      updateIsChecks(isChecks, usePositive: true);
      visit(node.arguments.head);
      locals.merge(saved);
      return inferrer.boolType;
    } else if (const SourceString("||") == op.source) {
      conditionIsSimple = false;
      visit(node.receiver);
      LocalsHandler saved = new LocalsHandler.from(locals);
      updateIsChecks(isChecks, usePositive: false);
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      visit(node.arguments.head);
      accumulateIsChecks = oldAccumulateIsChecks;
      locals.merge(saved);
      return inferrer.boolType;
    } else if (const SourceString("!") == op.source) {
      bool oldAccumulateIsChecks = accumulateIsChecks;
      accumulateIsChecks = false;
      node.visitChildren(this);
      accumulateIsChecks = oldAccumulateIsChecks;
      return inferrer.boolType;
    } else if (const SourceString("is") == op.source) {
      potentiallyAddIsCheck(node);
      node.visitChildren(this);
      return inferrer.boolType;
    } else if (const SourceString("as") == op.source) {
      TypeMask receiverType = visit(node.receiver);
      DartType type = elements.getType(node.arguments.head);
      return inferrer.narrowType(receiverType, type);
    } else if (node.isParameterCheck) {
      node.visitChildren(this);
      return inferrer.boolType;
    } else if (node.argumentsNode is Prefix) {
      // Unary operator.
      return visitDynamicSend(node);
    } else if (const SourceString('===') == op.source
               || const SourceString('!==') == op.source) {
      node.visitChildren(this);
      return inferrer.boolType;
    } else {
      // Binary operator.
      return visitDynamicSend(node);
    }
  }

  // Because some nodes just visit their children, we may end up
  // visiting a type annotation, that may contain a send in case of a
  // prefixed type. Therefore we explicitly visit the type annotation
  // to avoid confusing the [ResolvedVisitor].
  visitTypeAnnotation(TypeAnnotation node) {}

  TypeMask visitGetterSend(Send node) {
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (Elements.isStaticOrTopLevelField(element)) {
      handleStaticSend(node, selector, element, null);
      return inferrer.typeOfElementWithSelector(element, selector);
    } else if (Elements.isInstanceSend(node, elements)) {
      return visitDynamicSend(node);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      handleStaticSend(node, selector, element, null);
      return inferrer.functionType;
    } else if (Elements.isErroneousElement(element)) {
      return inferrer.dynamicType;
    } else if (Elements.isLocal(element)) {
      assert(locals.use(element) != null);
      return locals.use(element);
    } else {
      node.visitChildren(this);
      return inferrer.dynamicType;
    }
  }

  TypeMask visitClosureSend(Send node) {
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
    return inferrer.dynamicType;
  }

  void handleStaticSend(Node node,
                        Selector selector,
                        Element element,
                        ArgumentsTypes arguments) {
    if (Elements.isUnresolved(element)) return;
    inferrer.registerCalledElement(
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

  TypeMask handleDynamicSend(Node node,
                             Selector selector,
                             TypeMask receiver,
                             ArgumentsTypes arguments,
                             [Selector constraint]) {
    if (selector.mask != receiver) {
      selector = inferrer.isDynamicType(receiver)
          ? selector.asUntyped
          : new TypedSelector(receiver, selector);
      updateSelectorInTree(node, selector);
    }
    return inferrer.registerCalledSelector(
        node, selector, receiver, outermostElement, arguments,
        constraint, sideEffects, inLoop);
  }

  TypeMask visitDynamicSend(Send node) {
    Element element = elements[node];
    TypeMask receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      isCallOnThis = true;
      receiverType = thisType;
    } else {
      Node receiver = node.receiver;
      isCallOnThis = isThisOrSuper(receiver);
      receiverType = visit(receiver);
    }

    Selector selector = elements.getSelector(node);
    if (!isThisExposed && isCallOnThis) {
      checkIfExposesThis(new TypedSelector(receiverType, selector));
    }

    ArgumentsTypes arguments = node.isPropertyAccess
        ? null
        : analyzeArguments(node.arguments);
    return handleDynamicSend(node, selector, receiverType, arguments);
  }

  TypeMask visitReturn(Return node) {
    if (node.isRedirectingFactoryBody) {
      Element element = elements[node.expression];
      if (Elements.isErroneousElement(element)) {
        recordReturnType(inferrer.dynamicType);
      } else {
        element = element.implementation;
        // We don't create a selector for redirecting factories, and
        // the send is just a property access. Therefore we must
        // manually create the [ArgumentsTypes] of the call, and
        // manually register [analyzedElement] as a caller of [element].
        FunctionElement function = analyzedElement;
        FunctionSignature signature = function.computeSignature(compiler);
        List<TypeMask> unnamed = <TypeMask>[];
        Map<SourceString, TypeMask> named = new Map<SourceString, TypeMask>();
        signature.forEachRequiredParameter((Element element) {
          unnamed.add(locals.use(element));
        });
        signature.forEachOptionalParameter((Element element) {
          if (signature.optionalParametersAreNamed) {
            named[element.name] = locals.use(element);
          } else {
            unnamed.add(locals.use(element));
          }
        });
        ArgumentsTypes arguments = new ArgumentsTypes(unnamed, named);
        inferrer.addCaller(analyzedElement, element);
        inferrer.addArguments(node.expression, element, arguments);
        recordReturnType(inferrer.returnTypeOfElement(element));
      }
    } else {
      Node expression = node.expression;
      recordReturnType(expression == null
          ? inferrer.nullType
          : expression.accept(this));
    }
    locals.seenReturn = true;
    return inferrer.dynamicType;
  }

  TypeMask visitConditional(Conditional node) {
    List<Send> tests = <Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = new LocalsHandler.from(locals);
    updateIsChecks(tests, usePositive: true);
    TypeMask firstType = visit(node.thenExpression);
    LocalsHandler thenLocals = locals;
    locals = saved;
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    TypeMask secondType = visit(node.elseExpression);
    locals.merge(thenLocals);
    TypeMask type = inferrer.computeLUB(firstType, secondType);
    return type;
  }

  TypeMask visitVariableDefinitions(VariableDefinitions node) {
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      if (definition is Identifier) {
        locals.update(elements[definition], inferrer.nullType);
      } else {
        assert(definition.asSendSet() != null);
        visit(definition);
      }
    }
    return inferrer.dynamicType;
  }

  bool handleCondition(Node node, List<Send> tests) {
    bool oldConditionIsSimple = conditionIsSimple;
    bool oldAccumulateIsChecks = accumulateIsChecks;
    List<Send> oldIsChecks = isChecks;
    accumulateIsChecks = true;
    conditionIsSimple = true;
    isChecks = tests;
    visit(node);
    bool simpleCondition = conditionIsSimple;
    accumulateIsChecks = oldAccumulateIsChecks;
    isChecks = oldIsChecks;
    conditionIsSimple = oldConditionIsSimple;
    return simpleCondition;
  }

  TypeMask visitIf(If node) {
    List<Send> tests = <Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = new LocalsHandler.from(locals);
    updateIsChecks(tests, usePositive: true);
    visit(node.thenPart);
    LocalsHandler thenLocals = locals;
    locals = saved;
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    visit(node.elsePart);
    locals.merge(thenLocals);
    return inferrer.dynamicType;
  }

  void setupBreaksAndContinues(TargetElement element) {
    if (element == null) return;
    if (element.isContinueTarget) continuesFor[element] = <LocalsHandler>[];
    if (element.isBreakTarget) breaksFor[element] = <LocalsHandler>[];
  }

  void clearBreaksAndContinues(TargetElement element) {
    continuesFor.remove(element);
    breaksFor.remove(element);
  }

  void mergeBreaks(TargetElement element) {
    if (element == null) return;
    if (!element.isBreakTarget) return;
    for (LocalsHandler handler in breaksFor[element]) {
      locals.merge(handler, discardIfAborts: false);
    }
  }

  bool mergeContinues(TargetElement element) {
    if (element == null) return false;
    if (!element.isContinueTarget) return false;
    bool changed = false;
    for (LocalsHandler handler in continuesFor[element]) {
      changed = locals.merge(handler, discardIfAborts: false) || changed;
    }
    return changed;
  }

  TypeMask handleLoop(Node node, void logic()) {
    loopLevel++;
    bool changed = false;
    TargetElement target = elements[node];
    setupBreaksAndContinues(target);
    do {
      LocalsHandler saved = new LocalsHandler.from(locals);
      logic();
      changed = saved.merge(locals);
      locals = saved;
      changed = mergeContinues(target) || changed;
    } while (changed);
    loopLevel--;
    mergeBreaks(target);
    clearBreaksAndContinues(target);
    return inferrer.dynamicType;
  }

  TypeMask visitWhile(While node) {
    return handleLoop(node, () {
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
    });
  }

  TypeMask visitDoWhile(DoWhile node) {
    return handleLoop(node, () {
      visit(node.body);
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
    });
  }

  TypeMask visitFor(For node) {
    visit(node.initializer);
    return handleLoop(node, () {
      List<Send> tests = <Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
      visit(node.update);
    });
  }

  TypeMask visitForIn(ForIn node) {
    bool changed = false;
    TypeMask expressionType = visit(node.expression);
    Selector iteratorSelector = elements.getIteratorSelector(node);
    Selector currentSelector = elements.getCurrentSelector(node);
    Selector moveNextSelector = elements.getMoveNextSelector(node);

    TypeMask iteratorType =
        handleDynamicSend(node, iteratorSelector, expressionType, null);
    handleDynamicSend(node, moveNextSelector,
                      iteratorType, new ArgumentsTypes([], null));
    TypeMask currentType =
        handleDynamicSend(node, currentSelector, iteratorType, null);

    // We nullify the type in case there is no element in the
    // iterable.
    currentType = currentType.nullable();

    if (node.expression.isThis()) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      isThisExposed = true;
    }

    Node identifier = node.declaredIdentifier;
    Element element = elements[identifier];
    Selector selector = elements.getSelector(identifier);

    TypeMask receiverType;
    if (element != null && element.isInstanceMember()) {
      receiverType = thisType;
    } else {
      receiverType = inferrer.dynamicType;
    }

    handlePlainAssignment(identifier, element, selector,
                          receiverType, currentType,
                          node.expression);
    return handleLoop(node, () {
      visit(node.body);
    });
  }

  TypeMask visitTryStatement(TryStatement node) {
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, inTryBlock: true);
    visit(node.tryBlock);
    saved.merge(locals);
    locals = saved;
    for (Node catchBlock in node.catchBlocks) {
      saved = new LocalsHandler.from(locals);
      visit(catchBlock);
      saved.merge(locals);
      locals = saved;
    }
    visit(node.finallyBlock);
    return inferrer.dynamicType;
  }

  TypeMask visitThrow(Throw node) {
    node.visitChildren(this);
    locals.seenReturn = true;
    return inferrer.dynamicType;
  }

  TypeMask visitCatchBlock(CatchBlock node) {
    Node exception = node.exception;
    if (exception != null) {
      DartType type = elements.getType(node.type);
      TypeMask mask = type == null
          ? inferrer.dynamicType
          : new TypeMask.nonNullSubtype(type.asRaw());
      locals.update(elements[exception], mask);
    }
    Node trace = node.trace;
    if (trace != null) {
      locals.update(elements[trace], inferrer.dynamicType);
    }
    visit(node.block);
    return inferrer.dynamicType;
  }

  TypeMask visitParenthesizedExpression(ParenthesizedExpression node) {
    return visit(node.expression);
  }

  TypeMask visitBlock(Block node) {
    if (node.statements != null) {
      for (Node statement in node.statements) {
        visit(statement);
        if (locals.aborts) break;
      }
    }
    return inferrer.dynamicType;
  }

  TypeMask visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    if (body is Loop
        || body is SwitchStatement
        || Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
      return inferrer.dynamicType;
    }

    TargetElement targetElement = elements[body];
    setupBreaksAndContinues(targetElement);
    visit(body);
    mergeBreaks(targetElement);
    clearBreaksAndContinues(targetElement);
    return inferrer.dynamicType;
  }

  TypeMask visitBreakStatement(BreakStatement node) {
    TargetElement target = elements[node];
    breaksFor[target].add(locals);
    locals.seenBreakOrContinue = true;
    return inferrer.dynamicType;
  }

  TypeMask visitContinueStatement(ContinueStatement node) {
    TargetElement target = elements[node];
    continuesFor[target].add(locals);
    locals.seenBreakOrContinue = true;
    return inferrer.dynamicType;
  }

  void internalError(String reason, {Node node}) {
    compiler.internalError(reason, node: node);
  }

  TypeMask visitSwitchStatement(SwitchStatement node) {
    visit(node.parenthesizedExpression);

    setupBreaksAndContinues(elements[node]);
    if (Elements.switchStatementHasContinue(node, elements)) {
      void forEachLabeledCase(void action(TargetElement target)) {
        for (SwitchCase switchCase in node.cases) {
          for (Node labelOrCase in switchCase.labelsAndCases) {
            if (labelOrCase.asLabel() == null) continue;
            LabelElement labelElement = elements[labelOrCase];
            if (labelElement != null) {
              action(labelElement.target);
            }
          }
        }
      }

      forEachLabeledCase((TargetElement target) {
        setupBreaksAndContinues(target);
      });

      // If the switch statement has a continue, we conservatively
      // visit all cases and update [locals] until we have reached a
      // fixed point.
      bool changed;
      do {
        changed = false;
        for (Node switchCase in node.cases) {
          LocalsHandler saved = new LocalsHandler.from(locals);
          visit(switchCase);
          changed = saved.merge(locals, discardIfAborts: false) || changed;
          locals = saved;
        }
      } while (changed);

      forEachLabeledCase((TargetElement target) {
        clearBreaksAndContinues(target);
      });
    } else {
      LocalsHandler saved = new LocalsHandler.from(locals);
      // If there is a default case, the current values of the local
      // variable might be overwritten, so we don't need the current
      // [locals] for the join block.
      LocalsHandler result = Elements.switchStatementHasDefault(node)
          ? null
          : new LocalsHandler.from(locals);

      for (Node switchCase in node.cases) {
        locals = new LocalsHandler.from(saved);
        visit(switchCase);
        if (result == null) {
          result = locals;
        } else {
          result.merge(locals, discardIfAborts: false);
        }
      }
      locals = result;
    }
    clearBreaksAndContinues(elements[node]);
    // In case there is a default in the switch we discard the
    // incoming localsHandler, because the types it holds do not need
    // to be merged after the switch statement. This means that, if all
    // cases, including the default, break or continue, the [result]
    // handler may think it just aborts the current block. Therefore
    // we set the current locals to not have any break or continue, so
    // that the [visitBlock] method does not assume the code after the
    // switch is dead code.
    locals.seenBreakOrContinue = false;
    return inferrer.dynamicType;
  }
}
