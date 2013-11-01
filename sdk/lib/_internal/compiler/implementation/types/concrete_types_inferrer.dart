// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library concrete_types_inferrer;

import 'dart:collection' show Queue, IterableBase;
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../native_handler.dart' as native;
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart';

import 'types.dart' show TypeMask, TypesInferrer;

class CancelTypeInferenceException {
  final Node node;
  final String reason;

  CancelTypeInferenceException(this.node, this.reason);
}

/**
 * A singleton concrete type. More precisely, a [BaseType] is one of the
 * following:
 *
 *   - a non-asbtract class like [: int :] or [: Uri :] but not [: List :]
 *   - the null base type
 *   - the unknown base type
 */
abstract class BaseType {
  bool isClass();
  bool isUnknown();
  bool isNull();
}

/**
 * A non-asbtract class like [: int :] or [: Uri :] but not [: List :].
 */
class ClassBaseType implements BaseType {
  final ClassElement element;

  ClassBaseType(this.element);

  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! ClassBaseType) return false;
    return element == other.element;
  }
  int get hashCode => element.hashCode;
  String toString() {
    return element == null ? 'toplevel' : element.name;
  }
  bool isClass() => true;
  bool isUnknown() => false;
  bool isNull() => false;
}

/**
 * The unknown base type.
 */
class UnknownBaseType implements BaseType {
  const UnknownBaseType();
  bool operator ==(BaseType other) => other is UnknownBaseType;
  int get hashCode => 0;
  bool isClass() => false;
  bool isUnknown() => true;
  bool isNull() => false;
  toString() => "unknown";
}

/**
 * The null base type.
 */
class NullBaseType implements BaseType {
  const NullBaseType();
  bool operator ==(BaseType other) => identical(other, this);
  int get hashCode => 1;
  bool isClass() => false;
  bool isUnknown() => false;
  bool isNull() => true;
  toString() => "null";
}

/**
 * An immutable set of base types, like [: {int, bool} :] or the unknown
 * concrete type.
 */
abstract class ConcreteType {
  ConcreteType();

  factory ConcreteType.empty(int maxConcreteTypeSize,
                             BaseTypes classBaseTypes) {
    return new UnionType(maxConcreteTypeSize, classBaseTypes,
                         new Set<BaseType>());
  }

  /**
   * The singleton constituted of the unknown base type is the unknown concrete
   * type.
   */
  factory ConcreteType.singleton(int maxConcreteTypeSize,
                                 BaseTypes classBaseTypes, BaseType baseType) {
    if (baseType.isUnknown() || maxConcreteTypeSize < 1) {
      return const UnknownConcreteType();
    }
    Set<BaseType> singletonSet = new Set<BaseType>();
    singletonSet.add(baseType);
    return new UnionType(maxConcreteTypeSize, classBaseTypes, singletonSet);
  }

  factory ConcreteType.unknown() {
    return const UnknownConcreteType();
  }

  ConcreteType union(ConcreteType other);
  bool isUnknown();
  bool isEmpty();
  Set<BaseType> get baseTypes;

  /**
   * Returns the unique element of [: this :] if [: this :] is a singleton,
   * null otherwise.
   */
  ClassElement getUniqueType();
}

/**
 * The unkown concrete type: it is absorbing for the union.
 */
class UnknownConcreteType implements ConcreteType {
  const UnknownConcreteType();
  bool isUnknown() => true;
  bool isEmpty() => false;
  bool operator ==(ConcreteType other) => identical(this, other);
  Set<BaseType> get baseTypes =>
      new Set<BaseType>.from([const UnknownBaseType()]);
  int get hashCode => 0;
  ConcreteType union(ConcreteType other) => this;
  ClassElement getUniqueType() => null;
  toString() => "unknown";
}

/**
 * An immutable set of base types, like [: {int, bool} :].
 */
class UnionType implements ConcreteType {
  final int maxConcreteTypeSize;
  final BaseTypes classBaseTypes;

  final Set<BaseType> baseTypes;

  /**
   * The argument should NOT be mutated later. Do not call directly, use
   * ConcreteType.singleton instead.
   */
  UnionType(this.maxConcreteTypeSize, this.classBaseTypes, this.baseTypes);

  bool isUnknown() => false;
  bool isEmpty() => baseTypes.isEmpty;

  bool operator ==(ConcreteType other) {
    if (other is! UnionType) return false;
    if (baseTypes.length != other.baseTypes.length) return false;
    return baseTypes.containsAll(other.baseTypes);
  }

  int get hashCode {
    int result = 1;
    for (final baseType in baseTypes) {
      result = 31 * result + baseType.hashCode;
    }
    return result;
  }

  ConcreteType union(ConcreteType other) {
    if (other.isUnknown()) {
      return const UnknownConcreteType();
    }
    UnionType otherUnion = other;  // cast
    Set<BaseType> newBaseTypes = new Set<BaseType>.from(baseTypes);
    newBaseTypes.addAll(otherUnion.baseTypes);

    // normalize {int, float}, {int, num} or {float, num} into num
    // TODO(polux): generalize this to all types when we extend the concept of
    //     "concrete type" to other abstract classes than num
    if (newBaseTypes.contains(classBaseTypes.numBaseType) ||
        (newBaseTypes.contains(classBaseTypes.intBaseType)
            && newBaseTypes.contains(classBaseTypes.doubleBaseType))) {
      newBaseTypes.remove(classBaseTypes.intBaseType);
      newBaseTypes.remove(classBaseTypes.doubleBaseType);
      newBaseTypes.add(classBaseTypes.numBaseType);
    }

    // widen big types to dynamic
    return newBaseTypes.length > maxConcreteTypeSize
        ? const UnknownConcreteType()
        : new UnionType(maxConcreteTypeSize, classBaseTypes, newBaseTypes);
  }

  ClassElement getUniqueType() {
    if (baseTypes.length == 1) {
      var iterator = baseTypes.iterator;
      iterator.moveNext();
      BaseType uniqueBaseType = iterator.current;
      if (uniqueBaseType.isClass()) {
        ClassBaseType uniqueClassType = uniqueBaseType;
        return uniqueClassType.element;
      }
    }
    return null;
  }

  String toString() => baseTypes.toString();
}

/**
 * The cartesian product of concrete types: an iterable of [BaseTypeTuple]s. For
 * instance, the cartesian product of the concrete types [: {A, B} :] and
 * [: {C, D} :] is an itearble whose iterators will yield [: (A, C) :],
 * [: (A, D) :], [: (B, C) :] and finally [: (B, D) :].
 */
class ConcreteTypeCartesianProduct
    extends IterableBase<ConcreteTypesEnvironment> {
  final ConcreteTypesInferrer inferrer;
  final ClassElement typeOfThis;
  final Map<Element, ConcreteType> concreteTypes;
  ConcreteTypeCartesianProduct(this.inferrer, this.typeOfThis,
                               this.concreteTypes);
  Iterator get iterator => concreteTypes.isEmpty
      ? [new ConcreteTypesEnvironment(inferrer, new ClassBaseType(typeOfThis))]
            .iterator
      : new ConcreteTypeCartesianProductIterator(inferrer,
            new ClassBaseType(typeOfThis), concreteTypes);
  String toString() {
    List<ConcreteTypesEnvironment> cartesianProduct =
        new List<ConcreteTypesEnvironment>.from(this);
    return cartesianProduct.toString();
  }
}

/**
 * An helper class for [ConcreteTypeCartesianProduct].
 */
class ConcreteTypeCartesianProductIterator
    implements Iterator<ConcreteTypesEnvironment> {
  final ConcreteTypesInferrer inferrer;
  final BaseType baseTypeOfThis;
  final Map<Element, ConcreteType> concreteTypes;
  final Map<Element, BaseType> nextValues;
  final Map<Element, Iterator> state;
  int size = 1;
  int counter = 0;
  ConcreteTypesEnvironment _current;

  ConcreteTypeCartesianProductIterator(this.inferrer, this.baseTypeOfThis,
      Map<Element, ConcreteType> concreteTypes)
      : this.concreteTypes = concreteTypes,
        nextValues = new Map<Element, BaseType>(),
        state = new Map<Element, Iterator>() {
    if (concreteTypes.isEmpty) {
      size = 0;
      return;
    }
    for (final e in concreteTypes.keys) {
      final baseTypes = concreteTypes[e].baseTypes;
      size *= baseTypes.length;
    }
  }

  ConcreteTypesEnvironment get current => _current;

  ConcreteTypesEnvironment takeSnapshot() {
    Map<Element, ConcreteType> result = new Map<Element, ConcreteType>();
    nextValues.forEach((k, v) {
      result[k] = inferrer.singletonConcreteType(v);
    });
    return new ConcreteTypesEnvironment.of(inferrer, result, baseTypeOfThis);
  }

  bool moveNext() {
    if (counter >= size) {
      _current = null;
      return false;
    }
    Element keyToIncrement = null;
    for (final key in concreteTypes.keys) {
      final iterator = state[key];
      if (iterator != null && iterator.moveNext()) {
        nextValues[key] = state[key].current;
        break;
      }
      Iterator newIterator = concreteTypes[key].baseTypes.iterator;
      state[key] = newIterator;
      newIterator.moveNext();
      nextValues[key] = newIterator.current;
    }
    counter++;
    _current = takeSnapshot();
    return true;
  }
}

/**
 * [BaseType] Constants.
 */
class BaseTypes {
  final ClassBaseType intBaseType;
  final ClassBaseType doubleBaseType;
  final ClassBaseType numBaseType;
  final ClassBaseType boolBaseType;
  final ClassBaseType stringBaseType;
  final ClassBaseType listBaseType;
  final ClassBaseType growableListBaseType;
  final ClassBaseType fixedListBaseType;
  final ClassBaseType constListBaseType;
  final ClassBaseType mapBaseType;
  final ClassBaseType objectBaseType;
  final ClassBaseType typeBaseType;
  final ClassBaseType functionBaseType;

  BaseTypes(Compiler compiler) :
    intBaseType = new ClassBaseType(compiler.backend.intImplementation),
    doubleBaseType = new ClassBaseType(compiler.backend.doubleImplementation),
    numBaseType = new ClassBaseType(compiler.backend.numImplementation),
    boolBaseType = new ClassBaseType(compiler.backend.boolImplementation),
    stringBaseType = new ClassBaseType(compiler.backend.stringImplementation),
    listBaseType = new ClassBaseType(compiler.backend.listImplementation),
    growableListBaseType =
        new ClassBaseType(compiler.backend.growableListImplementation),
    fixedListBaseType =
        new ClassBaseType(compiler.backend.fixedListImplementation),
    constListBaseType =
        new ClassBaseType(compiler.backend.constListImplementation),
    mapBaseType = new ClassBaseType(compiler.backend.mapImplementation),
    objectBaseType = new ClassBaseType(compiler.objectClass),
    typeBaseType = new ClassBaseType(compiler.backend.typeImplementation),
    functionBaseType
        = new ClassBaseType(compiler.backend.functionImplementation);
}

/**
 * A method-local immutable mapping from variables to their inferred
 * [ConcreteTypes]. Each visitor owns one.
 */
class ConcreteTypesEnvironment {
  final ConcreteTypesInferrer inferrer;
  final Map<Element, ConcreteType> environment;
  final BaseType typeOfThis;

  ConcreteTypesEnvironment(this.inferrer, [this.typeOfThis]) :
      environment = new Map<Element, ConcreteType>();
  ConcreteTypesEnvironment.of(this.inferrer, this.environment, this.typeOfThis);

  ConcreteType lookupType(Element element) => environment[element];
  ConcreteType lookupTypeOfThis() {
    return (typeOfThis == null)
        ? null
        : inferrer.singletonConcreteType(typeOfThis);
  }

  ConcreteTypesEnvironment put(Element element, ConcreteType type) {
    Map<Element, ConcreteType> newMap =
        new Map<Element, ConcreteType>.from(environment);
    newMap[element] = type;
    return new ConcreteTypesEnvironment.of(inferrer, newMap, typeOfThis);
  }

  ConcreteTypesEnvironment join(ConcreteTypesEnvironment other) {
    if (typeOfThis != other.typeOfThis) {
      throw "trying to join incompatible environments";
    }
    Map<Element, ConcreteType> newMap =
        new Map<Element, ConcreteType>.from(environment);
    other.environment.forEach((element, type) {
      ConcreteType currentType = newMap[element];
      if (currentType == null) {
        newMap[element] = type;
      } else {
        newMap[element] = currentType.union(type);
      }
    });
    return new ConcreteTypesEnvironment.of(inferrer, newMap, typeOfThis);
  }

  bool operator ==(ConcreteTypesEnvironment other) {
    if (other is! ConcreteTypesEnvironment) return false;
    if (typeOfThis != other.typeOfThis) return false;
    if (environment.length != other.environment.length) return false;
    for (Element key in environment.keys) {
      if (!other.environment.containsKey(key)
          || (environment[key] != other.environment[key])) {
        return false;
      }
    }
    return true;
  }

  int get hashCode {
    int result = (typeOfThis != null) ? typeOfThis.hashCode : 1;
    environment.forEach((element, concreteType) {
      result = 31 * (31 * result + element.hashCode) +
          concreteType.hashCode;
    });
    return result;
  }

  /**
   * Returns true if and only if the environment is compatible with [signature].
   */
  bool matches(FunctionSignature signature) {
    Types types = inferrer.compiler.types;
    bool paramMatches(ConcreteType concrete, VariableElement parameter) {
      DartType parameterType = parameter.variables.type;
      if (parameterType.treatAsDynamic || parameterType.treatAsRaw) {
        return true;
      }
      for (BaseType baseType in concrete.baseTypes) {
        if (baseType.isUnknown()) return false;
        if (baseType.isNull()) continue;
        ClassBaseType classType = baseType;
        if (!types.isSubtype(classType.element.rawType,
                             parameterType)) return false;
      }
      return true;
    }
    for (VariableElement param in signature.requiredParameters) {
      ConcreteType concrete = environment[param];
      if (concrete == null || !paramMatches(concrete, param)) return false;
    }
    for (VariableElement param in signature.optionalParameters) {
      ConcreteType concrete = environment[param];
      if (concrete != null && !paramMatches(concrete, param)) return false;
    }
    return true;
  }

  String toString() => "{ this: $typeOfThis, env: $environment }";
}

/**
 * A work item for the type inference queue.
 */
class InferenceWorkItem {
  Element methodOrField;
  ConcreteTypesEnvironment environment;
  InferenceWorkItem(this.methodOrField, this.environment);

  toString() {
    final elementType = methodOrField.isField() ? "field" : "method";
    final elementRepresentation = methodOrField.name;
    return "{ $elementType = $elementRepresentation"
           ", environment = $environment }";
  }
}

/**
 * A sentinel type mask class representing the dynamicType. It is absorbing
 * for [:ConcreteTypesEnvironment.typeMaskUnion:].
 */
class DynamicTypeMask implements TypeMask {
  const DynamicTypeMask();

  String toString() => 'sentinel type mask';

  TypeMask nullable() {
    throw new UnsupportedError("");
  }

  TypeMask nonNullable() {
    throw new UnsupportedError("");
  }

  TypeMask simplify(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool get isEmpty {
    throw new UnsupportedError("");
  }

  bool get isNullable {
    throw new UnsupportedError("");
  }

  bool get isExact {
    throw new UnsupportedError("");
  }

  bool get isUnion {
    throw new UnsupportedError("");
  }

  bool get isContainer {
    throw new UnsupportedError("");
  }

  bool get isForwarding {
    throw new UnsupportedError("");
  }

  bool containsOnlyInt(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsOnlyDouble(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsOnlyNum(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsOnlyNull(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsOnlyBool(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsOnlyString(Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsOnly(ClassElement element) {
    throw new UnsupportedError("");
  }

  bool satisfies(ClassElement cls, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool contains(ClassElement type, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsAll(Compiler compiler) {
    throw new UnsupportedError("");
  }

  ClassElement singleClass(Compiler compiler) {
    throw new UnsupportedError("");
  }

  Iterable<ClassElement> containedClasses(Compiler compiler) {
    throw new UnsupportedError("");
  }

  TypeMask union(TypeMask other, Compiler compiler) {
    throw new UnsupportedError("");
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool understands(Selector selector, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool canHit(Element element, Selector selector, Compiler compiler) {
    throw new UnsupportedError("");
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool needsNoSuchMethodHandling(Selector selector, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool isInMask(TypeMask other, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool containsMask(TypeMask other, Compiler compiler) {
    throw new UnsupportedError("");
  }
}

/**
 * A task which conservatively infers a [ConcreteType] for each sub expression
 * of the program. The entry point is [analyzeMain].
 */
class ConcreteTypesInferrer extends TypesInferrer {
  static final bool LOG_FAILURES = true;

  final String name = "Type inferrer";

  final Compiler compiler;

  /**
   * When true, the string literal [:"__dynamic_for_test":] is inferred to
   * have the unknown type.
   */
  // TODO(polux): get rid of this hack once we have a natural way of inferring
  // the unknown type.
  bool testMode = false;

  /**
   * Constants representing builtin base types. Initialized in [initialize]
   * and not in the constructor because the compiler elements are not yet
   * populated.
   */
  BaseTypes baseTypes;

  /**
   * Constant representing [:ConcreteList#[]:] where [:ConcreteList:] is the
   * concrete implementation of lists for the selected backend.
   */
  FunctionElement listIndex;

  /**
   * Constant representing [:ConcreteList#[]=:] where [:ConcreteList:] is the
   * concrete implementation of lists for the selected backend.
   */
  FunctionElement listIndexSet;

  /**
   * Constant representing [:ConcreteList#add:] where [:ConcreteList:] is the
   * concrete implementation of lists for the selected backend.
   */
  FunctionElement listAdd;

  /**
   * Constant representing [:ConcreteList#removeAt:] where [:ConcreteList:] is
   * the concrete implementation of lists for the selected backend.
   */
  FunctionElement listRemoveAt;

  /**
   * Constant representing [:ConcreteList#insert:] where [:ConcreteList:] is
   * the concrete implementation of lists for the selected backend.
   */
  FunctionElement listInsert;

  /**
   * Constant representing [:ConcreteList#removeLast:] where [:ConcreteList:] is
   * the concrete implementation of lists for the selected backend.
   */
  FunctionElement listRemoveLast;

  /**
   * Constant representing [:List():].
   */
  FunctionElement listConstructor;

  /**
   * Constant mapping between types returned by native calls and concrete types.
   */
  Map<ClassElement, ConcreteType> nativeTypesToConcreteTypes;

  /**
   * Constant mapping between types returned by native calls and the set of
   * classes that should augment [seenClasses] when encountered.
   */
  Map<ClassElement, List<ClassElement>> nativeTypesToSeenClasses;

  /**
   * Constant list of concrete classes seen by the resolver.
   */
  List<ClassElement> concreteSeenClasses;

  /**
   * A cache from (function x argument base types) to concrete types,
   * used to memoize [analyzeMonoSend]. Another way of seeing [cache] is as a
   * map from [FunctionElement]s to "templates" in the sense of "The Cartesian
   * Product Algorithm - Simple and Precise Type Inference of Parametric
   * Polymorphism" by Ole Agesen.
   */
  // TODO(polux): rename and build a better abstraction.
  final Map<FunctionElement, Map<ConcreteTypesEnvironment, ConcreteType>> cache;

  /** A map from expressions to their inferred concrete types. */
  final Map<Node, ConcreteType> inferredTypes;

  /** A map from fields to their inferred concrete types. */
  final Map<Element, ConcreteType> inferredFieldTypes;

  /** The work queue consumed by [analyzeMain]. */
  final Queue<InferenceWorkItem> workQueue;

  /**
   * [:callers[f]:] is the list of [:f:]'s possible callers or fields
   * whose initialization is a call to [:f:].
   */
  final Map<FunctionElement, Set<Element>> callers;

  /**
   * [:readers[field]:] is the list of [:field:]'s possible readers or fields
   * whose initialization is a read of [:field:].
   */
  final Map<Element, Set<Element>> readers;

  /// The set of classes encountered so far.
  final Set<ClassElement> seenClasses;

  /**
   * A map from method names to callers of methods with this name on objects
   * of unknown inferred type.
   */
  final Map<String, Set<FunctionElement>> dynamicCallers;

  /** The inferred type of elements stored in Lists. */
  ConcreteType listElementType;

  /**
   * A map from parameters to their inferred concrete types. It plays no role
   * in the analysis, it is write only.
   */
  final Map<VariableElement, ConcreteType> inferredParameterTypes;

  /**
   * A map from selectors to their inferred type masks, indexed by the mask
   * of the receiver. It plays no role in the analysis, it is write only.
   */
  final Map<Selector, Map<TypeMask, TypeMask>> inferredSelectorTypes;

  ConcreteTypesInferrer(Compiler compiler)
      : this.compiler = compiler,
        cache = new Map<FunctionElement,
            Map<ConcreteTypesEnvironment, ConcreteType>>(),
        inferredTypes = new Map<Node, ConcreteType>(),
        inferredFieldTypes = new Map<Element, ConcreteType>(),
        inferredParameterTypes = new Map<VariableElement, ConcreteType>(),
        workQueue = new Queue<InferenceWorkItem>(),
        callers = new Map<FunctionElement, Set<Element>>(),
        readers = new Map<Element, Set<Element>>(),
        seenClasses = new Set<ClassElement>(),
        dynamicCallers = new Map<String, Set<FunctionElement>>(),
        inferredSelectorTypes = new Map<Selector, Map<TypeMask, TypeMask>>() {
    unknownConcreteType = new ConcreteType.unknown();
  }

  // --- utility methods ---

  /** The unknown concrete type */
  ConcreteType unknownConcreteType;

  /** The empty concrete type */
  ConcreteType emptyConcreteType;

  /** The null concrete type */
  ConcreteType nullConcreteType;

  /** Creates a singleton concrete type containing [baseType]. */
  ConcreteType singletonConcreteType(BaseType baseType) {
    return new ConcreteType.singleton(compiler.maxConcreteTypeSize, baseTypes,
                                      baseType);
  }

  /**
   * Computes the union of [mask1] and [mask2] where [mask1] and [mask2] are
   * possibly equal to [: DynamicTypeMask.instance :].
   */
  TypeMask typeMaskUnion(TypeMask mask1, TypeMask mask2) {
    if (mask1 == const DynamicTypeMask()
        || mask2 == const DynamicTypeMask()) {
      return const DynamicTypeMask();
    }
    return mask1.union(mask2, compiler);
  }

  /**
   * Returns all the members with name [methodName].
   */
  List<Element> getMembersByName(String methodName) {
    // TODO(polux): memoize?
    var result = new List<Element>();
    for (ClassElement cls in seenClasses) {
      Element elem = cls.lookupMember(methodName);
      if (elem != null) {
        result.add(elem.implementation);
      }
    }
    return result;
  }

  /**
   * Sets the concrete type associated to [node] to the union of the inferred
   * concrete type so far and [type].
   */
  void augmentInferredType(Node node, ConcreteType type) {
    ConcreteType currentType = inferredTypes[node];
    inferredTypes[node] = (currentType == null)
        ? type
        : currentType.union(type);
  }

  /**
   * Sets the concrete type associated to [selector] to the union of the
   * inferred concrete type so far and [type].
   * Precondition: [:typeOfThis != null:]
   */
  void augmentInferredSelectorType(Selector selector, TypeMask typeOfThis,
                                   TypeMask returnType) {
    assert(returnType != null);
    assert(typeOfThis != null);
    selector = selector.asUntyped;
    Map<TypeMask, TypeMask> currentMap = inferredSelectorTypes.putIfAbsent(
        selector, () => new Map<TypeMask, TypeMask>());
    TypeMask currentReturnType = currentMap[typeOfThis];
    currentMap[typeOfThis] = (currentReturnType == null)
        ? returnType
        : typeMaskUnion(currentReturnType, returnType);
  }

  /**
   * Returns the current inferred concrete type of [field].
   */
  ConcreteType getFieldType(Selector selector, Element field) {
    ConcreteType result = inferredFieldTypes[field];
    if (result == null) {
      // field is a toplevel variable, we trigger its analysis because no object
      // creation is ever going to trigger it
      result = analyzeFieldInitialization(field);
      return (result == null) ? emptyConcreteType : result;
    }
    if (selector != null) {
      Element enclosing = field.enclosingElement;
      if (enclosing.isClass()) {
        ClassElement cls = enclosing;
        TypeMask receiverMask = new TypeMask.exact(cls);
        TypeMask resultMask = concreteTypeToTypeMask(result);
        augmentInferredSelectorType(selector, receiverMask, resultMask);
      }
    }
    return result;
  }

  /**
   * Sets the concrete type associated to [field] to the union of the inferred
   * concrete type so far and [type].
   */
  void augmentFieldType(Element field, ConcreteType type) {
    ConcreteType oldType = inferredFieldTypes[field];
    ConcreteType newType = (oldType != null)
        ? oldType.union(type)
        : type;
    if (oldType != newType) {
      inferredFieldTypes[field] = newType;
      final fieldReaders = readers[field];
      if (fieldReaders != null) {
        fieldReaders.forEach(invalidate);
      }
    }
  }

  /// Augment the inferred type of elements stored in Lists.
  void augmentListElementType(ConcreteType type) {
    ConcreteType newType = listElementType.union(type);
    if (newType != listElementType) {
      invalidateCallers(listIndex);
      listElementType = newType;
    }
  }

  /**
   * Sets the concrete type associated to [parameter] to the union of the
   * inferred concrete type so far and [type].
   */
  void augmentParameterType(VariableElement parameter, ConcreteType type) {
    ConcreteType oldType = inferredParameterTypes[parameter];
    inferredParameterTypes[parameter] =
        (oldType == null) ? type : oldType.union(type);
  }

  /// Augments the set of classes encountered so far.
  void augmentSeenClasses(ClassElement cls) {
    if (!seenClasses.contains(cls)) {
      seenClasses.add(cls);
      cls.forEachMember((_, Element member) {
        Set<FunctionElement> functions = dynamicCallers[member.name];
        if (functions == null) return;
        for (FunctionElement function in functions) {
          invalidate(function);
        }
      }, includeSuperAndInjectedMembers: true);
    }
  }

  /**
   * Add [caller] to the set of [callee]'s callers.
   */
  void addCaller(FunctionElement callee, Element caller) {
    Set<Element> current = callers[callee];
    if (current != null) {
      current.add(caller);
    } else {
      Set<Element> newSet = new Set<Element>();
      newSet.add(caller);
      callers[callee] = newSet;
    }
  }

  /**
   * Add [caller] to the set of [callee]'s dynamic callers.
   */
  void addDynamicCaller(String callee, FunctionElement caller) {
    Set<FunctionElement> current = dynamicCallers[callee];
    if (current != null) {
      current.add(caller);
    } else {
      Set<FunctionElement> newSet = new Set<FunctionElement>();
      newSet.add(caller);
      dynamicCallers[callee] = newSet;
    }
  }

  /**
   * Add [reader] to the set of [field]'s readers.
   */
  void addReader(Element field, Element reader) {
    Set<Element> current = readers[field];
    if (current != null) {
      current.add(reader);
    } else {
      Set<Element> newSet = new Set<Element>();
      newSet.add(reader);
      readers[field] = newSet;
    }
  }

  /**
   * Add callers of [function] to the workqueue.
   */
  void invalidateCallers(FunctionElement function) {
    Set<Element> methodCallers = callers[function];
    if (methodCallers == null) return;
    for (Element caller in methodCallers) {
      invalidate(caller);
    }
  }

  /**
   * Add all instances of [methodOrField] to the workqueue.
   */
  void invalidate(Element methodOrField) {
    if (methodOrField.isField()) {
      workQueue.addLast(new InferenceWorkItem(
          methodOrField, new ConcreteTypesEnvironment(this)));
    } else {
      Map<ConcreteTypesEnvironment, ConcreteType> instances =
          cache[methodOrField];
      if (instances != null) {
        instances.forEach((environment, _) {
          workQueue.addLast(
              new InferenceWorkItem(methodOrField, environment));
        });
      }
    }
  }

  /**
   * Returns the template associated to [function] in cache or create an
   * empty template for [function] in cache and returns it.
   */
  Map<ConcreteTypesEnvironment, ConcreteType>
      getTemplatesOrEmpty(FunctionElement function) {
    return cache.putIfAbsent(
        function,
        () => new Map<ConcreteTypesEnvironment, ConcreteType>());
  }

  // -- query --

  /**
   * Returns the [TypeMask] representation of [baseType].
   */
  TypeMask baseTypeToTypeMask(BaseType baseType) {
    if (baseType.isUnknown()) {
      return const DynamicTypeMask();
    } else if (baseType.isNull()) {
      return new TypeMask.empty();
    } else {
      ClassBaseType classBaseType = baseType;
      final element = classBaseType.element;
      assert(element != null);
      if (element == compiler.backend.numImplementation) {
        return new TypeMask.nonNullSubclass(
            compiler.backend.numImplementation);
      } else if (element == compiler.dynamicClass) {
        return new TypeMask.nonNullSubclass(compiler.objectClass);
      } else {
        return new TypeMask.nonNullExact(element);
      }
    }
  }

  /**
   * Returns the [TypeMask] representation of [concreteType].
   */
  TypeMask concreteTypeToTypeMask(ConcreteType concreteType) {
    if (concreteType == null) return null;
    TypeMask typeMask = new TypeMask.nonNullEmpty();
    for (BaseType baseType in concreteType.baseTypes) {
      TypeMask baseMask = baseTypeToTypeMask(baseType);
      if (baseMask == const DynamicTypeMask()) return baseMask;
      typeMask = typeMask.union(baseMask, compiler);
    }
    return typeMask;
  }

  /**
   * Get the inferred concrete type of [node].
   */
  TypeMask getTypeOfNode(Element owner, Node node) {
    TypeMask result = concreteTypeToTypeMask(inferredTypes[node]);
    return result == const DynamicTypeMask() ? null : result;
  }

  /**
   * Get the inferred concrete type of [element].
   */
  TypeMask getTypeOfElement(Element element) {
    TypeMask result = null;
    if (element.isParameter()) {
      result = concreteTypeToTypeMask(inferredParameterTypes[element]);
    } else if (element.isField()) {
      result = concreteTypeToTypeMask(inferredFieldTypes[element]);
    }
    // TODO(polux): handle field parameters
    return result == const DynamicTypeMask() ? null : result;
  }

  /**
   * Get the inferred concrete return type of [element].
   */
  TypeMask getReturnTypeOfElement(Element element) {
    if (!element.isFunction()) return null;
    Map<ConcreteTypesEnvironment, ConcreteType> templates = cache[element];
    if (templates == null) return null;
    ConcreteType returnType = emptyConcreteType;
    templates.forEach((_, concreteType) {
      returnType = returnType.union(concreteType);
    });
    TypeMask result = concreteTypeToTypeMask(returnType);
    return result == const DynamicTypeMask() ? null : result;
  }

  /**
   * Get the inferred concrete type of [selector]. A null return value means
   * "I don't know".
   */
  TypeMask getTypeOfSelector(Selector selector) {
    Map<TypeMask, TypeMask> candidates =
        inferredSelectorTypes[selector.asUntyped];
    if (candidates == null) {
      return null;
    }
    TypeMask result = new TypeMask.nonNullEmpty();
    if (selector.mask == null) {
      candidates.forEach((TypeMask receiverType, TypeMask returnType) {
        result = typeMaskUnion(result, returnType);
      });
    } else {
      candidates.forEach((TypeMask receiverType, TypeMask returnType) {
        TypeMask intersection =
            receiverType.intersection(selector.mask, compiler);
        if (!intersection.isEmpty || intersection.isNullable) {
          result = typeMaskUnion(result, returnType);
        }
      });
    }
    return result == const DynamicTypeMask() ? null : result;
  }

  Iterable<TypeMask> get containerTypes {
    throw new UnsupportedError("");
  }

  void clear() {}

  Iterable<Element> getCallersOf(Element element) {
    throw new UnsupportedError("");
  }

  // --- analysis ---

  /**
   * Returns the concrete type returned by [function] given arguments of
   * concrete types [argumentsTypes]. If [function] is static then
   * [receiverType] must be null, else [function] must be a member of the class
   * of [receiverType].
   */
  ConcreteType getSendReturnType(Selector selector,
                                 FunctionElement function,
                                 ClassElement receiverType,
                                 ArgumentsTypes argumentsTypes) {
    ConcreteType result = emptyConcreteType;
    Map<Element, ConcreteType> argumentMap =
        associateArguments(function, argumentsTypes);
    // if the association failed, this send will never occur or will fail
    if (argumentMap == null) {
      return emptyConcreteType;
    }

    argumentMap.forEach(augmentParameterType);
    ConcreteTypeCartesianProduct product =
        new ConcreteTypeCartesianProduct(this, receiverType, argumentMap);
    for (ConcreteTypesEnvironment environment in product) {
      result =
          result.union(getMonomorphicSendReturnType(function, environment));
    }

    if (selector != null && receiverType != null) {
      // TODO(polux): generalize to any abstract class if we ever handle other
      // abstract classes than num.
      TypeMask receiverMask =
          (receiverType == compiler.backend.numImplementation)
              ? new TypeMask.nonNullSubclass(receiverType)
              : new TypeMask.nonNullExact(receiverType);
      TypeMask resultMask = concreteTypeToTypeMask(result);
      augmentInferredSelectorType(selector, receiverMask, resultMask);
    }

    return result;
  }

  /**
   * Given a method signature and a list of concrete types, builds a map from
   * formals to their corresponding concrete types. Returns null if the
   * association is impossible (for instance: too many arguments).
   */
  Map<Element, ConcreteType> associateArguments(FunctionElement function,
                                                ArgumentsTypes argumentsTypes) {
    final Map<Element, ConcreteType> result = new Map<Element, ConcreteType>();
    final FunctionSignature signature = function.computeSignature(compiler);

    // guard 1: too many arguments
    if (argumentsTypes.length > signature.parameterCount) {
      return null;
    }
    // guard 2: not enough arguments
    if (argumentsTypes.positional.length < signature.requiredParameterCount) {
      return null;
    }
    // guard 3: too many positional arguments
    if (signature.optionalParametersAreNamed &&
        argumentsTypes.positional.length > signature.requiredParameterCount) {
      return null;
    }

    handleLeftoverOptionalParameter(Element parameter) {
      // TODO(polux): use default value whenever available
      // TODO(polux): add a marker to indicate whether an argument was provided
      //     in order to handle "?parameter" tests
      result[parameter] = nullConcreteType;
    }

    final Iterator<ConcreteType> remainingPositionalArguments =
        argumentsTypes.positional.iterator;
    // we attach each positional parameter to its corresponding positional
    // argument
    for (Link<Element> requiredParameters = signature.requiredParameters;
        !requiredParameters.isEmpty;
        requiredParameters = requiredParameters.tail) {
      final Element requiredParameter = requiredParameters.head;
      // we know moveNext() succeeds because of guard 2
      remainingPositionalArguments.moveNext();
      result[requiredParameter] = remainingPositionalArguments.current;
    }
    if (signature.optionalParametersAreNamed) {
      // we build a map out of the remaining named parameters
      Link<Element> remainingOptionalParameters = signature.optionalParameters;
      final Map<String, Element> leftOverNamedParameters =
          new Map<String, Element>();
      for (;
           !remainingOptionalParameters.isEmpty;
           remainingOptionalParameters = remainingOptionalParameters.tail) {
        final Element namedParameter = remainingOptionalParameters.head;
        leftOverNamedParameters[namedParameter.name] = namedParameter;
      }
      // we attach the named arguments to their corresponding optional
      // parameters
      for (Identifier identifier in argumentsTypes.named.keys) {
        final ConcreteType concreteType = argumentsTypes.named[identifier];
        String source = identifier.source;
        final Element namedParameter = leftOverNamedParameters[source];
        // unexisting or already used named parameter
        if (namedParameter == null) return null;
        result[namedParameter] = concreteType;
        leftOverNamedParameters.remove(source);
      }
      leftOverNamedParameters.forEach((_, Element parameter) {
        handleLeftoverOptionalParameter(parameter);
      });
    } else { // optional parameters are positional
      // we attach the remaining positional arguments to their corresponding
      // optional parameters
      Link<Element> remainingOptionalParameters = signature.optionalParameters;
      while (remainingPositionalArguments.moveNext()) {
        final Element optionalParameter = remainingOptionalParameters.head;
        result[optionalParameter] = remainingPositionalArguments.current;
        // we know tail is defined because of guard 1
        remainingOptionalParameters = remainingOptionalParameters.tail;
      }
      for (;
           !remainingOptionalParameters.isEmpty;
           remainingOptionalParameters = remainingOptionalParameters.tail) {
        handleLeftoverOptionalParameter(remainingOptionalParameters.head);
      }
    }
    return result;
  }

  ConcreteType getMonomorphicSendReturnType(
      FunctionElement function,
      ConcreteTypesEnvironment environment) {
    Map<ConcreteTypesEnvironment, ConcreteType> template =
        getTemplatesOrEmpty(function);
    ConcreteType type = template[environment];
    ConcreteType specialType = getSpecialCaseReturnType(function, environment);
    if (type != null) {
      return specialType != null ? specialType : type;
    } else {
      workQueue.addLast(new InferenceWorkItem(function, environment));
      // in case of a constructor, optimize by returning the class
      return specialType != null ? specialType : emptyConcreteType;
    }
  }

  /**
   * Computes the type of a call to the magic 'JS' function.
   */
  ConcreteType getNativeCallReturnType(Send node) {
    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);
    assert(nativeBehavior != null);
    List typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return unknownConcreteType;

    ConcreteType result = emptyConcreteType;
    void registerClass(ClassElement element) {
      if (!element.isAbstract(compiler)) {
        result =
            result.union(singletonConcreteType(new ClassBaseType(element)));
        augmentSeenClasses(element);
      }
    }
    void registerDynamic() {
      result = unknownConcreteType;
      concreteSeenClasses.forEach(augmentSeenClasses);
    }

    for (final type in typesReturned) {
      if (type == native.SpecialType.JsObject) {
        registerDynamic();
      } else if (type.treatAsDynamic) {
        registerDynamic();
      } else {
        ClassElement element = type.element;
        ConcreteType concreteType = nativeTypesToConcreteTypes[element];
        if (concreteType != null) {
          result = result.union(concreteType);
          nativeTypesToSeenClasses[element].forEach(augmentSeenClasses);
        } else {
          if (compiler.enqueuer.resolution.seenClasses.contains(element)) {
            registerClass(element);
          }
          Set<ClassElement> subtypes = compiler.world.subtypesOf(element);
          if (subtypes != null) {
            subtypes.forEach(registerClass);
          }
        }
      }
    }
    return result;
  }

  /// Replaces native types by their backend implementation.
  Element normalize(Element cls) {
    if (cls == compiler.boolClass) {
      return compiler.backend.boolImplementation;
    }
    if (cls == compiler.intClass) {
      return compiler.backend.intImplementation;
    }
    if (cls == compiler.doubleClass) {
      return compiler.backend.doubleImplementation;
    }
    if (cls == compiler.numClass) {
      return compiler.backend.numImplementation;
    }
    if (cls == compiler.stringClass) {
      return compiler.backend.stringImplementation;
    }
    if (cls == compiler.listClass) {
      return compiler.backend.listImplementation;
    }
    return cls;
  }

  /**
   * Handles external methods that cannot be cached because they depend on some
   * other state of [ConcreteTypesInferrer] like [:List#[]:] and
   * [:List#[]=:]. Returns null if [function] and [environment] don't form a
   * special case
   */
  ConcreteType getSpecialCaseReturnType(FunctionElement function,
                                        ConcreteTypesEnvironment environment) {
    // Handles int + int, double + double, int - int, ...
    // We cannot compare function to int#+, int#-, etc. because int and double
    // don't override these methods. So for 1+2, getSpecialCaseReturnType will
    // be invoked with function = num#+. We use environment.typeOfThis instead.
    BaseType baseType = environment.typeOfThis;
    if (baseType != null && baseType.isClass()) {
      ClassBaseType classBaseType = baseType;
      ClassElement cls = classBaseType.element;
      String name = function.name;
      if ((cls == baseTypes.intBaseType.element
          || cls == baseTypes.doubleBaseType.element)
          && (name == '+' || name == '-' || name == '*')) {
        Link<Element> parameters =
            function.functionSignature.requiredParameters;
        ConcreteType argumentType = environment.lookupType(parameters.head);
        if (argumentType.getUniqueType() == cls) {
          return singletonConcreteType(new ClassBaseType(cls));
        }
      }
    }

    if (function == listIndex || function == listRemoveAt) {
      Link<Element> parameters = function.functionSignature.requiredParameters;
      ConcreteType indexType = environment.lookupType(parameters.head);
      if (!indexType.baseTypes.contains(baseTypes.intBaseType)) {
        return emptyConcreteType;
      }
      return listElementType;
    } else if (function == listIndexSet || function == listInsert) {
      Link<Element> parameters = function.functionSignature.requiredParameters;
      ConcreteType indexType = environment.lookupType(parameters.head);
      if (!indexType.baseTypes.contains(baseTypes.intBaseType)) {
        return emptyConcreteType;
      }
      ConcreteType elementType = environment.lookupType(parameters.tail.head);
      augmentListElementType(elementType);
      return emptyConcreteType;
    } else if (function == listAdd) {
      Link<Element> parameters = function.functionSignature.requiredParameters;
      ConcreteType elementType = environment.lookupType(parameters.head);
      augmentListElementType(elementType);
      return emptyConcreteType;
    } else if (function == listRemoveLast) {
      return listElementType;
    }
    return null;
  }

  /**
   * [element] must be either a field with an initializing expression,
   * a generative constructor or a function.
   */
  ConcreteType analyze(Selector selector,
                       Element element,
                       ConcreteTypesEnvironment environment) {
    if (element.isGenerativeConstructor()) {
      return analyzeConstructor(selector, element, environment);
    } else if (element.isField()) {
      analyzeFieldInitialization(element);
      return emptyConcreteType;
    } else {
      assert(element is FunctionElement);
      return analyzeMethod(element, environment);
    }
  }

  ConcreteType analyzeMethod(FunctionElement element,
                             ConcreteTypesEnvironment environment) {
    TreeElements elements =
        compiler.enqueuer.resolution.resolvedElements[element.declaration];
    assert(elements != null);
    ConcreteType specialResult = handleSpecialMethod(element, environment);
    if (specialResult != null) return specialResult;
    FunctionExpression tree = element.parseNode(compiler);
    if (tree.hasBody()) {
      Visitor visitor =
          new TypeInferrerVisitor(elements, element, this, environment);
      return tree.accept(visitor);
    } else {
      // TODO(polux): handle num#<, num#>, etc. in order to get rid of this
      //     else branch
      return new ConcreteType.unknown();
    }
  }

  /**
   * Analyzes the initialization of a field. Returns [:null:] if and only if
   * [element] has no initialization expression.
   */
  ConcreteType analyzeFieldInitialization(VariableElement element) {
    TreeElements elements =
        compiler.enqueuer.resolution.resolvedElements[element];
    assert(elements != null);
    Visitor visitor = new TypeInferrerVisitor(elements, element, this,
        new ConcreteTypesEnvironment(this));
    Node tree = element.parseNode(compiler);
    ConcreteType type = initializerDo(tree, (node) => node.accept(visitor));
    if (type != null) {
      augmentFieldType(element, type);
    }
    return type;
  }

  ConcreteType analyzeConstructor(Selector selector,
                                  FunctionElement element,
                                  ConcreteTypesEnvironment environment) {
    Set<Element> uninitializedFields = new Set<Element>();

    // initialize fields
    ClassElement enclosingClass = element.enclosingElement;
    augmentSeenClasses(enclosingClass);
    enclosingClass.forEachInstanceField((_, VariableElement field) {
      ConcreteType type = analyzeFieldInitialization(field);
      if (type == null) {
        uninitializedFields.add(field);
      }
    });

    // handle initializing formals
    element.computeSignature(compiler).forEachParameter((param) {
      if (param.kind == ElementKind.FIELD_PARAMETER) {
        FieldParameterElement fieldParam = param;
        augmentFieldType(fieldParam.fieldElement,
            environment.lookupType(param));
        uninitializedFields.remove(fieldParam.fieldElement);
      }
    });

    // analyze initializers, including a possible call to super or a redirect
    FunctionExpression tree = compiler.parser.parse(element);
    TreeElements elements =
        compiler.enqueuer.resolution.resolvedElements[element.declaration];
    assert(elements != null);
    Visitor visitor =
        new TypeInferrerVisitor(elements, element, this, environment);

    bool foundSuperOrRedirect = false;
    if (tree != null && tree.initializers != null) {
      // we look for a possible call to super in the initializer list
      for (final init in tree.initializers) {
        init.accept(visitor);
        SendSet sendSet = init.asSendSet();
        if (init.asSendSet() == null) {
          foundSuperOrRedirect = true;
        } else {
          uninitializedFields.remove(elements[init]);
        }
      }
    }

    // set uninitialized fields to null
    for (VariableElement field in uninitializedFields) {
      augmentFieldType(field, nullConcreteType);
    }

    // if no call to super or redirect has been found, call the default
    // constructor (if the current class is not Object).
    if (!foundSuperOrRedirect) {
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        FunctionElement target = superClass.lookupConstructor(
            new Selector.callDefaultConstructor(enclosingClass.getLibrary()))
                .implementation;
        final superClassConcreteType = singletonConcreteType(
            new ClassBaseType(enclosingClass));
        getSendReturnType(selector, target, enclosingClass,
            new ArgumentsTypes(new List(), new Map()));
      }
    }

    if (tree != null) tree.accept(visitor);
    return singletonConcreteType(new ClassBaseType(enclosingClass));
  }

  /**
   * Hook that performs side effects on some special method calls (like
   * [:List(length):]) and possibly returns a concrete type.
   */
  ConcreteType handleSpecialMethod(FunctionElement element,
                                   ConcreteTypesEnvironment environment) {
    // When List([length]) is called with some length, we must augment
    // listElementType with {null}.
    if (element == listConstructor) {
      Link<Element> parameters =
          listConstructor.functionSignature.optionalParameters;
      ConcreteType lengthType = environment.lookupType(parameters.head);
      if (lengthType.baseTypes.contains(baseTypes.intBaseType)) {
        augmentListElementType(nullConcreteType);
      }
    }
  }

  /* Initialization code that cannot be run in the constructor because it
   * requires the compiler's elements to be populated.
   */
  void initialize() {
    baseTypes = new BaseTypes(compiler);
    ClassElement jsArrayClass = baseTypes.listBaseType.element;
    listIndex = jsArrayClass.lookupMember('[]');
    listIndexSet = jsArrayClass.lookupMember('[]=');
    listAdd = jsArrayClass.lookupMember('add');
    listRemoveAt = jsArrayClass.lookupMember('removeAt');
    listInsert = jsArrayClass.lookupMember('insert');
    listRemoveLast =
        jsArrayClass.lookupMember('removeLast');
    List<String> typePreservingOps = const ['+', '-', '*'];
    listConstructor =
        compiler.listClass.lookupConstructor(
            new Selector.callConstructor(
                '',
                compiler.listClass.getLibrary())).implementation;
    emptyConcreteType = new ConcreteType.empty(compiler.maxConcreteTypeSize,
                                               baseTypes);
    nullConcreteType = singletonConcreteType(const NullBaseType());
    listElementType = emptyConcreteType;
    concreteSeenClasses = compiler.enqueuer.resolution
        .seenClasses
        .where((cls) => !cls.isAbstract(compiler))
        .toList()
        ..add(baseTypes.numBaseType.element);
    nativeTypesToConcreteTypes = new Map<ClassElement, ConcreteType>()
        ..[compiler.nullClass] = nullConcreteType
        ..[compiler.objectClass] = unknownConcreteType
        ..[compiler.stringClass] =
            singletonConcreteType(baseTypes.stringBaseType)
        ..[compiler.intClass] = singletonConcreteType(baseTypes.intBaseType)
        ..[compiler.doubleClass] =
            singletonConcreteType(baseTypes.doubleBaseType)
        ..[compiler.numClass] = singletonConcreteType(baseTypes.numBaseType)
        ..[compiler.boolClass] = singletonConcreteType(baseTypes.boolBaseType);
    nativeTypesToSeenClasses = new Map<dynamic, List<ClassElement>>()
        ..[compiler.nullClass] = []
        ..[compiler.objectClass] = concreteSeenClasses
        ..[compiler.stringClass] = [baseTypes.stringBaseType.element]
        ..[compiler.intClass] = [baseTypes.intBaseType.element]
        ..[compiler.doubleClass] = [baseTypes.doubleBaseType.element]
        ..[compiler.numClass] = [baseTypes.numBaseType.element,
                                 baseTypes.intBaseType.element,
                                 baseTypes.doubleBaseType.element]
        ..[compiler.boolClass] = [baseTypes.boolBaseType.element];
  }

  /**
   * Performs concrete type inference of the code reachable from [element].
   * Returns [:true:] if and only if analysis succeeded.
   */
  bool analyzeMain(Element element) {
    initialize();
    try {
      workQueue.addLast(
          new InferenceWorkItem(element, new ConcreteTypesEnvironment(this)));
      while (!workQueue.isEmpty) {
        InferenceWorkItem item = workQueue.removeFirst();
        if (item.methodOrField.isField()) {
          analyze(null, item.methodOrField, item.environment);
        } else {
          Map<ConcreteTypesEnvironment, ConcreteType> template =
              getTemplatesOrEmpty(item.methodOrField);
          template.putIfAbsent(item.environment, () => emptyConcreteType);
          ConcreteType concreteType =
              analyze(null, item.methodOrField, item.environment);
          if (template[item.environment] != concreteType) {
            template[item.environment] = concreteType;
            invalidateCallers(item.methodOrField);
          }
        }
      }
      return true;
    } on CancelTypeInferenceException catch(e) {
      if (LOG_FAILURES) {
        compiler.log(e.reason);
      }
      return false;
    }
  }

  /**
   * Dumps debugging information on the standard output.
   */
  void debug() {
    print("seen classes:");
    for (ClassElement cls in seenClasses) {
      print("  ${cls.name}");
    }
    print("callers:");
    callers.forEach((k,v) {
      print("  $k: $v");
    });
    print("dynamic callers:");
    dynamicCallers.forEach((k,v) {
      print("  $k: $v");
    });
    print("readers:");
    readers.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferredFieldTypes:");
    inferredFieldTypes.forEach((k,v) {
      print("  $k: $v");
    });
    print("listElementType:");
    print("  $listElementType");
    print("inferredParameterTypes:");
    inferredParameterTypes.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferred selector types:");
    inferredSelectorTypes.forEach((selector, map) {
      print("  $selector:");
      map.forEach((k, v) {
        print("    $k: $v");
      });
    });
    print("cache:");
    cache.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferred expression types:");
    inferredTypes.forEach((k,v) {
      print("  $k: $v");
    });
  }

  /**
   * Fail with a message and abort.
   */
  void fail(node, [reason]) {
    String message = 'cannot infer types';
    if (reason != null) {
      message = '$message: $reason';
    }
    throw new CancelTypeInferenceException(node, message);
  }
}

/**
 * Represents the concrete types of the arguments of a send, indexed by
 * position or name.
 */
class ArgumentsTypes {
  final List<ConcreteType> positional;
  final Map<Identifier, ConcreteType> named;
  ArgumentsTypes(this.positional, this.named);
  int get length => positional.length + named.length;
  toString() => "{ positional = $positional, named = $named }";
}

/**
 * The core logic of the type inference algorithm.
 */
class TypeInferrerVisitor extends ResolvedVisitor<ConcreteType> {
  final ConcreteTypesInferrer inferrer;
  /// Invariant: backend = inferrer.compiler.backend
  final Backend backend;

  final Element currentMethodOrField;
  ConcreteTypesEnvironment environment;
  Node lastSeenNode;

  TypeInferrerVisitor(TreeElements elements, this.currentMethodOrField,
                      ConcreteTypesInferrer inferrer, this.environment)
      : this.inferrer = inferrer
      , this.backend = inferrer.compiler.backend
      , super(elements, inferrer.compiler) {
        for (Element element in elements.otherDependencies) {
          if (element.isClass()) {
            inferrer.augmentSeenClasses(inferrer.normalize(element));
          } else {
            FunctionElement functionElement = element;
            List<ConcreteType> unknowns = new List.filled(
                functionElement.computeSignature(inferrer.compiler)
                               .requiredParameterCount,
                inferrer.unknownConcreteType);
            inferrer.getSendReturnType(
                null,
                functionElement,
                functionElement.getEnclosingClass(),
                new ArgumentsTypes(unknowns, new Map()));
          }
        }
      }

  ArgumentsTypes analyzeArguments(Link<Node> arguments) {
    final positional = new List<ConcreteType>();
    final named = new Map<Identifier, ConcreteType>();
    for(Link<Node> iterator = arguments;
        !iterator.isEmpty;
        iterator = iterator.tail) {
      Node node = iterator.head;
      NamedArgument namedArgument = node.asNamedArgument();
      if (namedArgument != null) {
        named[namedArgument.name] = analyze(namedArgument.expression);
      } else {
        positional.add(analyze(node));
      }
    }
    return new ArgumentsTypes(positional, named);
  }

  /**
   * A proxy to accept which does book keeping and error reporting. Returns null
   * if [node] is a non-returning statement, its inferred concrete type
   * otherwise.
   */
  ConcreteType analyze(Node node) {
    if (node == null) {
      final String error = 'internal error: unexpected node: null';
      inferrer.fail(lastSeenNode, error);
    } else {
      lastSeenNode = node;
    }
    ConcreteType result = node.accept(this);
    if (result == null) {
      inferrer.fail(node, 'internal error: inferred type is null');
    }
    inferrer.augmentInferredType(node, result);
    return result;
  }

  ConcreteType visitBlock(Block node) {
    return analyze(node.statements);
  }

  ConcreteType visitCascade(Cascade node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitCascadeReceiver(CascadeReceiver node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitClassNode(ClassNode node) {
    inferrer.fail(node, 'not implemented');
  }

  ConcreteType visitDoWhile(DoWhile node) {
    analyze(node.body);
    analyze(node.condition);
    ConcreteTypesEnvironment oldEnvironment;
    do {
      oldEnvironment = environment;
      analyze(node.body);
      analyze(node.condition);
      environment = oldEnvironment.join(environment);
    } while (oldEnvironment != environment);
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitExpressionStatement(ExpressionStatement node) {
    analyze(node.expression);
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitFor(For node) {
    if (node.initializer != null) {
      analyze(node.initializer);
    }
    analyze(node.conditionStatement);
    ConcreteTypesEnvironment oldEnvironment;
    do {
      oldEnvironment = environment;
      analyze(node.conditionStatement);
      analyze(node.body);
      analyze(node.update);
      environment = oldEnvironment.join(environment);
    // TODO(polux): Maybe have a destructive join-method that returns a boolean
    // value indicating whether something changed to avoid performing this
    // comparison twice.
    } while (oldEnvironment != environment);
    return inferrer.emptyConcreteType;
  }

  void analyzeClosure(FunctionExpression node) {
    for (VariableDefinitions definitions in node.parameters) {
      for (Node parameter in definitions.definitions) {
        environment = environment.put(elements[parameter],
            inferrer.unknownConcreteType);
      }
    }
    analyze(node.body);
  }

  ConcreteType visitFunctionDeclaration(FunctionDeclaration node) {
    analyzeClosure(node.function);
    environment = environment.put(elements[node],
        inferrer.singletonConcreteType(inferrer.baseTypes.functionBaseType));
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitFunctionExpression(FunctionExpression node) {
    // Naive handling of closures: we assume their body is always executed,
    // and that each of their arguments has type dynamic.
    // TODO(polux): treat closures as classes
    if (node.name == null) {
      analyzeClosure(node);
      return inferrer.singletonConcreteType(
          inferrer.baseTypes.functionBaseType);
    } else {
      return analyze(node.body);
    }
  }

  ConcreteType visitIdentifier(Identifier node) {
    if (node.isThis()) {
      ConcreteType result = environment.lookupTypeOfThis();
      if (result == null) {
        inferrer.fail(node, '"this" has no type');
      }
      return result;
    }
    Element element = elements[node];
    assert(element != null);
    ConcreteType result = environment.lookupType(element);
    if (result != null) {
      assert(element.isParameter());
      return result;
    } else {
      environment = environment.put(element, inferrer.nullConcreteType);
      return inferrer.nullConcreteType;
    }
  }

  ConcreteType visitIf(If node) {
    analyze(node.condition);
    ConcreteType thenType = analyze(node.thenPart);
    ConcreteTypesEnvironment snapshot = environment;
    ConcreteType elseType = node.hasElsePart ? analyze(node.elsePart)
                                             : inferrer.emptyConcreteType;
    environment = environment.join(snapshot);
    return thenType.union(elseType);
  }

  ConcreteType visitLoop(Loop node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType analyzeSetElement(Selector selector,
                                 Element receiver, ConcreteType argumentType) {
    environment = environment.put(receiver, argumentType);
    if (receiver.isField()) {
      inferrer.augmentFieldType(receiver, argumentType);
    } else if (receiver.isSetter()){
      FunctionElement setter = receiver;
      // TODO(polux): A setter always returns void so there's no need to
      // invalidate its callers even if it is called with new arguments.
      // However, if we start to record more than returned types, like
      // exceptions for instance, we need to do it by uncommenting the following
      // line.
      // inferrer.addCaller(setter, currentMethod);
      inferrer.getSendReturnType(selector, setter, receiver.enclosingElement,
          new ArgumentsTypes([argumentType], new Map()));
    }
    return argumentType;
  }

  ConcreteType analyzeSetNode(Selector selector,
                              Node receiver, ConcreteType argumentType,
                              String name) {
    ConcreteType receiverType = analyze(receiver);

    void augmentField(ClassElement receiverType, Element member) {
      if (member.isField()) {
        inferrer.augmentFieldType(member, argumentType);
      } else if (member.isAbstractField()){
        AbstractFieldElement abstractField = member;
        FunctionElement setter = abstractField.setter;
        // TODO(polux): A setter always returns void so there's no need to
        // invalidate its callers even if it is called with new arguments.
        // However, if we start to record more than returned types, like
        // exceptions for instance, we need to do it by uncommenting the
        // following line.
        // inferrer.addCaller(setter, currentMethod);
        inferrer.getSendReturnType(selector, setter, receiverType,
            new ArgumentsTypes([argumentType], new Map()));
      }
      // since this is a sendSet we ignore non-fields
    }

    if (receiverType.isUnknown()) {
      inferrer.addDynamicCaller(name, currentMethodOrField);
      for (Element member in inferrer.getMembersByName(name)) {
        if (!(member.isField() || member.isAbstractField())) continue;
        Element cls = member.getEnclosingClass();
        augmentField(cls, member);
      }
    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isClass()) continue;
        ClassBaseType baseReceiverClassType = baseReceiverType;
        Element member = baseReceiverClassType.element.lookupMember(name);
        if (member != null) {
          augmentField(baseReceiverClassType.element, member);
        }
      }
    }
    return argumentType;
  }

  String canonicalizeCompoundOperator(String op) {
    // TODO(ahe): This class should work on elements or selectors, not
    // names.  Otherwise, it is repeating work the resolver has
    // already done (or should have done).  In this case, the problem
    // is that the resolver is not recording the selectors it is
    // registering in registerBinaryOperator in
    // ResolverVisitor.visitSendSet.
    if (op == '++') return '+';
    else if (op == '--') return '-';
    else return Elements.mapToUserOperatorOrNull(op);
  }

  ConcreteType visitSendSet(SendSet node) {
    // Operator []= has a different behaviour than other send sets: it is
    // actually a send whose return type is that of its second argument.
    if (node.selector.asIdentifier().source == '[]') {
      ConcreteType receiverType = analyze(node.receiver);
      ArgumentsTypes argumentsTypes = analyzeArguments(node.arguments);
      analyzeDynamicSend(elements.getSelector(node), receiverType,
                         '[]=', argumentsTypes);
      return argumentsTypes.positional[1];
    }

    // All other operators have a single argument (++ and -- have an implicit
    // argument: 1). We will store its type in argumentType.
    ConcreteType argumentType;
    String operatorName = node.assignmentOperator.source;
    String compoundOperatorName =
        canonicalizeCompoundOperator(node.assignmentOperator.source);
    // ++, --, +=, -=, ...
    if (compoundOperatorName != null) {
      ConcreteType receiverType = visitGetterSendForSelector(node,
          elements.getGetterSelectorInComplexSendSet(node));
      // argumentsTypes is either computed from the actual arguments or [{int}]
      // in case of ++ or --.
      ArgumentsTypes argumentsTypes;
      if (operatorName == '++' || operatorName == '--') {
        List<ConcreteType> positionalArguments = <ConcreteType>[
            inferrer.singletonConcreteType(inferrer.baseTypes.intBaseType)];
        argumentsTypes = new ArgumentsTypes(positionalArguments, new Map());
      } else {
        argumentsTypes = analyzeArguments(node.arguments);
      }
      argumentType = analyzeDynamicSend(
          elements.getOperatorSelectorInComplexSendSet(node),
          receiverType,
          compoundOperatorName,
          argumentsTypes);
    // The simple assignment case: receiver = argument.
    } else {
      argumentType = analyze(node.argumentsNode);
    }

    Element element = elements[node];
    if (element != null) {
      return analyzeSetElement(elements.getSelector(node),
                               element, argumentType);
    } else {
      return analyzeSetNode(elements.getSelector(node),
                            node.receiver, argumentType,
                            node.selector.asIdentifier().source);
    }
  }

  ConcreteType visitLiteralInt(LiteralInt node) {
    inferrer.augmentSeenClasses(backend.intImplementation);
    inferrer.augmentSeenClasses(backend.numImplementation);
    return inferrer.singletonConcreteType(inferrer.baseTypes.intBaseType);
  }

  ConcreteType visitLiteralDouble(LiteralDouble node) {
    inferrer.augmentSeenClasses(backend.doubleImplementation);
    inferrer.augmentSeenClasses(backend.numImplementation);
    return inferrer.singletonConcreteType(inferrer.baseTypes.doubleBaseType);
  }

  ConcreteType visitLiteralBool(LiteralBool node) {
    inferrer.augmentSeenClasses(backend.boolImplementation);
    return inferrer.singletonConcreteType(inferrer.baseTypes.boolBaseType);
  }

  ConcreteType visitLiteralString(LiteralString node) {
    // TODO(polux): get rid of this hack once we have a natural way of inferring
    // the unknown type.
    if (inferrer.testMode
        && node.dartString.slowToString() == "__dynamic_for_test") {
      return inferrer.unknownConcreteType;
    }
    inferrer.augmentSeenClasses(inferrer.compiler.stringClass);
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitStringJuxtaposition(StringJuxtaposition node) {
    analyze(node.first);
    analyze(node.second);
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitLiteralNull(LiteralNull node) {
    return inferrer.nullConcreteType;
  }

  ConcreteType visitNewExpression(NewExpression node) {
    Element constructor = elements[node.send].implementation;
    inferrer.addCaller(constructor, currentMethodOrField);
    ClassElement cls = constructor.enclosingElement;
    return inferrer.getSendReturnType(null, constructor, cls,
                                      analyzeArguments(node.send.arguments));
  }

  ConcreteType visitLiteralList(LiteralList node) {
    ConcreteType elementsType = inferrer.emptyConcreteType;
    // We compute the union of the types of the list literal's elements.
    for (Link<Node> link = node.elements.nodes;
         !link.isEmpty;
         link = link.tail) {
      elementsType = elementsType.union(analyze(link.head));
    }
    inferrer.augmentListElementType(elementsType);
    inferrer.augmentSeenClasses(backend.listImplementation);
    return inferrer.singletonConcreteType(
        inferrer.baseTypes.growableListBaseType);
  }

  ConcreteType visitNodeList(NodeList node) {
    ConcreteType type = inferrer.emptyConcreteType;
    // The concrete type of a sequence of statements is the union of the
    // statement's types.
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      type = type.union(analyze(link.head));
    }
    return type;
  }

  ConcreteType visitOperator(Operator node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitReturn(Return node) {
    final expression = node.expression;
    return (expression == null)
        ? inferrer.nullConcreteType
        : analyze(expression);
  }

  ConcreteType visitThrow(Throw node) {
    if (node.expression != null) analyze(node.expression);
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitTypeAnnotation(TypeAnnotation node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitTypeVariable(TypeVariable node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitVariableDefinitions(VariableDefinitions node) {
    for (Link<Node> link = node.definitions.nodes; !link.isEmpty;
         link = link.tail) {
      analyze(link.head);
    }
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitWhile(While node) {
    analyze(node.condition);
    ConcreteTypesEnvironment oldEnvironment;
    do {
      oldEnvironment = environment;
      analyze(node.condition);
      analyze(node.body);
      environment = oldEnvironment.join(environment);
    } while (oldEnvironment != environment);
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitParenthesizedExpression(ParenthesizedExpression node) {
    return analyze(node.expression);
  }

  ConcreteType visitConditional(Conditional node) {
    analyze(node.condition);
    ConcreteType thenType = analyze(node.thenExpression);
    ConcreteType elseType = analyze(node.elseExpression);
    return thenType.union(elseType);
  }

  ConcreteType visitModifiers(Modifiers node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    inferrer.augmentSeenClasses(inferrer.compiler.stringClass);
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitStringInterpolationPart(StringInterpolationPart node) {
    node.visitChildren(this);
    inferrer.augmentSeenClasses(inferrer.compiler.stringClass);
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitEmptyStatement(EmptyStatement node) {
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitBreakStatement(BreakStatement node) {
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitContinueStatement(ContinueStatement node) {
    // TODO(polux): we can be more precise
    return inferrer.emptyConcreteType;
  }

  ConcreteType visitForIn(ForIn node) {
    Element declaredIdentifier = elements[node.declaredIdentifier];
    assert(declaredIdentifier != null);
    ConcreteType iterableType = analyze(node.expression);

    // var n0 = e.iterator
    ConcreteType iteratorType = analyzeDynamicGetterSend(
        elements.getIteratorSelector(node),
        iterableType);
    ConcreteType result = inferrer.emptyConcreteType;
    ConcreteTypesEnvironment oldEnvironment;
    do {
      oldEnvironment = environment;
      // n0.moveNext();
      analyzeDynamicSend(
          elements.getMoveNextSelector(node),
          iteratorType,
          "moveNext",
          new ArgumentsTypes(const [], const {}));
      // id = n0.current
      ConcreteType currentType = analyzeDynamicGetterSend(
          elements.getCurrentSelector(node),
          iteratorType);
      environment = environment.put(declaredIdentifier, currentType);
      result = result.union(analyze(node.body));
      environment = oldEnvironment.join(environment);
    } while (oldEnvironment != environment);
    return result;
  }

  ConcreteType visitLabel(Label node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitLabeledStatement(LabeledStatement node) {
    return analyze(node.statement);
  }

  ConcreteType visitLiteralMap(LiteralMap node) {
    visitNodeList(node.entries);
    inferrer.augmentSeenClasses(inferrer.compiler.mapClass);
    return inferrer.singletonConcreteType(inferrer.baseTypes.mapBaseType);
  }

  ConcreteType visitLiteralMapEntry(LiteralMapEntry node) {
    // We don't need to visit the key, it's always a string.
    return analyze(node.value);
  }

  ConcreteType visitNamedArgument(NamedArgument node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitSwitchStatement(SwitchStatement node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitSwitchCase(SwitchCase node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitCaseMatch(CaseMatch node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitTryStatement(TryStatement node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitCatchBlock(CatchBlock node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitTypedef(Typedef node) {
    inferrer.fail(node, 'not implemented');
  }

  ConcreteType visitSuperSend(Send node) {
    inferrer.fail(node, 'not implemented');
  }

  ConcreteType visitOperatorSend(Send node) {
    String name =
        canonicalizeMethodName(node.selector.asIdentifier().source);
    if (name == 'is') {
      return inferrer.singletonConcreteType(inferrer.baseTypes.boolBaseType);
    }
    return visitDynamicSend(node);
  }

  ConcreteType analyzeFieldRead(Selector selector, Element field) {
    inferrer.addReader(field, currentMethodOrField);
    return inferrer.getFieldType(selector, field);
  }

  ConcreteType analyzeGetterSend(Selector selector,
                                 ClassElement receiverType,
                                 FunctionElement getter) {
      inferrer.addCaller(getter, currentMethodOrField);
      return inferrer.getSendReturnType(selector, getter, receiverType,
                                        new ArgumentsTypes([], new Map()));
  }

  ConcreteType visitGetterSend(Send node) {
    Selector selector = elements.getSelector(node);
    return visitGetterSendForSelector(node, selector);
  }

  ConcreteType analyzeDynamicGetterSend(Selector selector,
                                        ConcreteType receiverType) {
    ConcreteType result = inferrer.emptyConcreteType;
    void augmentResult(ClassElement baseReceiverType, Element member) {
      if (member.isField()) {
        result = result.union(analyzeFieldRead(selector, member));
      } else if (member.isAbstractField()){
        // call to a getter
        AbstractFieldElement abstractField = member;
        ConcreteType getterReturnType = analyzeGetterSend(
            selector, baseReceiverType, abstractField.getter);
        result = result.union(getterReturnType);
      }
      // since this is a get we ignore non-fields
    }

    if (receiverType.isUnknown()) {
      inferrer.addDynamicCaller(selector.name, currentMethodOrField);
      List<Element> members = inferrer.getMembersByName(selector.name);
      for (Element member in members) {
        Element cls = member.getEnclosingClass();
        augmentResult(cls, member);
      }
    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseType = baseReceiverType;
          ClassElement cls = classBaseType.element;
          Element getterOrField = cls.lookupMember(selector.name);
          if (getterOrField != null) {
            augmentResult(cls, getterOrField.implementation);
          }
        }
      }
    }
    return result;
  }

  ConcreteType visitGetterSendForSelector(Send node, Selector selector) {
    Element element = elements[node];
    if (element != null) {
      // node is a local variable or a field of this
      ConcreteType result = environment.lookupType(element);
      if (result != null) {
        // node is a local variable
        return result;
      } else {
        // node is a field or a getter of this
        if (element.isField()) {
          return analyzeFieldRead(selector, element);
        } else {
          assert(element.isGetter());
          ClassElement receiverType = element.enclosingElement;
          return analyzeGetterSend(selector, receiverType, element);
        }
      }
    } else {
      // node is a field/getter which doesn't belong to the current class or
      // the field/getter of a mixed-in class
      ConcreteType receiverType = node.receiver != null
          ? analyze(node.receiver)
          : environment.lookupTypeOfThis();
      return analyzeDynamicGetterSend(selector, receiverType);
    }
  }

  ConcreteType visitClosureSend(Send node) {
    return inferrer.unknownConcreteType;
  }

  ConcreteType analyzeDynamicSend(Selector selector,
                                  ConcreteType receiverType,
                                  String canonicalizedMethodName,
                                  ArgumentsTypes argumentsTypes) {
    ConcreteType result = inferrer.emptyConcreteType;

    if (receiverType.isUnknown()) {
      inferrer.addDynamicCaller(canonicalizedMethodName, currentMethodOrField);
      List<Element> methods =
          inferrer.getMembersByName(canonicalizedMethodName);
      for (Element element in methods) {
        // TODO(polux): when we handle closures, we must handle sends to fields
        // that are closures.
        if (!element.isFunction()) continue;
        FunctionElement method = element;
        inferrer.addCaller(method, currentMethodOrField);
        Element cls = method.enclosingElement;
        result = result.union(
            inferrer.getSendReturnType(selector, method, cls, argumentsTypes));
      }

    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseReceiverType = baseReceiverType;
          ClassElement cls = classBaseReceiverType.element;
          FunctionElement method = cls.lookupMember(canonicalizedMethodName);
          if (method != null) {
            method = method.implementation;
            inferrer.addCaller(method, currentMethodOrField);
            result = result.union(
                inferrer.getSendReturnType(selector, method, cls,
                                           argumentsTypes));
          }
        }
      }
    }
    return result;
  }

  String canonicalizeMethodName(String name) {
    // TODO(polux): handle unary-
    String operatorName = Elements.constructOperatorNameOrNull(name, false);
    if (operatorName != null) return operatorName;
    return name;
  }

  ConcreteType visitDynamicSend(Send node) {
    ConcreteType receiverType = (node.receiver != null)
        ? analyze(node.receiver)
        : environment.lookupTypeOfThis();
    String name = canonicalizeMethodName(node.selector.asIdentifier().source);
    if (name == '!=') {
      ArgumentsTypes argumentsTypes = analyzeArguments(node.arguments);
      ConcreteType returnType = analyzeDynamicSend(elements.getSelector(node),
                                                   receiverType,
                                                   '==',
                                                   argumentsTypes);
      return returnType.isEmpty()
          ? returnType
          : inferrer.singletonConcreteType(inferrer.baseTypes.boolBaseType);
    } else if (name == '&&' || name == '||') {
      ConcreteTypesEnvironment oldEnvironment = environment;
      analyze(node.arguments.head);
      environment = oldEnvironment.join(environment);
      return inferrer.singletonConcreteType(inferrer.baseTypes.boolBaseType);
    } else {
      ArgumentsTypes argumentsTypes = analyzeArguments(node.arguments);
      return analyzeDynamicSend(elements.getSelector(node),
                                receiverType, name, argumentsTypes);
    }
  }

  ConcreteType visitForeignSend(Send node) {
    return inferrer.unknownConcreteType;
  }

  ConcreteType visitAssert(Send node) {
    if (!compiler.enableUserAssertions) {
      return inferrer.nullConcreteType;
    } else {
      return visitStaticSend(node);
    }
  }

  ConcreteType visitStaticSend(Send node) {
    if (elements.getSelector(node).name == 'JS') {
      return inferrer.getNativeCallReturnType(node);
    }
    Element element = elements[node].implementation;
    inferrer.addCaller(element, currentMethodOrField);
    return inferrer.getSendReturnType(elements.getSelector(node),
                                      element, null,
                                      analyzeArguments(node.arguments));
  }

  void internalError(String reason, {Node node}) {
    inferrer.fail(node, reason);
  }

  ConcreteType visitTypeReferenceSend(Send) {
    return inferrer.singletonConcreteType(inferrer.baseTypes.typeBaseType);
  }
}
