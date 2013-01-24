// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

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

  bool operator ==(BaseType other) {
    if (identical(this, other)) return true;
    if (other is! ClassBaseType) return false;
    return element == other.element;
  }
  int get hashCode => element.hashCode;
  String toString() => element.name.slowToString();
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
  bool operator ==(BaseType other) => other is NullBaseType;
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
  factory ConcreteType.empty() {
    return new UnionType(new Set<BaseType>());
  }

  /**
   * The singleton constituted of the unknown base type is the unknown concrete
   * type.
   */
  factory ConcreteType.singleton(int maxConcreteTypeSize, BaseType baseType) {
    if (baseType.isUnknown() || maxConcreteTypeSize < 1) {
      return new UnknownConcreteType();
    }
    Set<BaseType> singletonSet = new Set<BaseType>();
    singletonSet.add(baseType);
    return new UnionType(singletonSet);
  }

  factory ConcreteType.unknown() {
    return const UnknownConcreteType();
  }

  ConcreteType union(int maxConcreteTypeSize, ConcreteType other);
  bool isUnkown();
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
  bool isUnkown() => true;
  bool isEmpty() => false;
  bool operator ==(ConcreteType other) => identical(this, other);
  Set<BaseType> get baseTypes =>
      new Set<BaseType>.from([const UnknownBaseType()]);
  int get hashCode => 0;
  ConcreteType union(int maxConcreteTypeSize, ConcreteType other) => this;
  ClassElement getUniqueType() => null;
  toString() => "unknown";
}

/**
 * An immutable set of base types, like [: {int, bool} :].
 */
class UnionType implements ConcreteType {
  final Set<BaseType> baseTypes;

  /**
   * The argument should NOT be mutated later. Do not call directly, use
   * ConcreteType.singleton instead.
   */
  UnionType(this.baseTypes);

  bool isUnkown() => false;
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

  // TODO(polux): Collapse {num, int, ...}, {num, double, ...} and
  // {int, double,...} into {num, ...} as an optimization. It will require
  // UnionType to know about these class elements, which is cumbersome because
  // there are no nested classes. We need factory methods instead.
  ConcreteType union(int maxConcreteTypeSize, ConcreteType other) {
    if (other.isUnkown()) {
      return const UnknownConcreteType();
    }
    UnionType otherUnion = other;  // cast
    Set<BaseType> newBaseTypes = new Set<BaseType>.from(baseTypes);
    newBaseTypes.addAll(otherUnion.baseTypes);
    return newBaseTypes.length > maxConcreteTypeSize
        ? const UnknownConcreteType()
        : new UnionType(newBaseTypes);
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
    extends Iterable<ConcreteTypesEnvironment> {
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
  final ClassBaseType mapBaseType;
  final ClassBaseType objectBaseType;
  final ClassBaseType typeBaseType;

  static _getNativeListClass(Compiler compiler) {
    // TODO(polux): switch to other implementations on other backends
    JavaScriptBackend backend = compiler.backend;
    return backend.jsArrayClass;
  }

  BaseTypes(Compiler compiler) :
    intBaseType = new ClassBaseType(compiler.intClass),
    doubleBaseType = new ClassBaseType(compiler.doubleClass),
    numBaseType = new ClassBaseType(compiler.numClass),
    boolBaseType = new ClassBaseType(compiler.boolClass),
    stringBaseType = new ClassBaseType(compiler.stringClass),
    // in the Javascript backend, lists are implemented by JsArray
    listBaseType = new ClassBaseType(_getNativeListClass(compiler)),
    mapBaseType = new ClassBaseType(compiler.mapClass),
    objectBaseType = new ClassBaseType(compiler.objectClass),
    typeBaseType = new ClassBaseType(compiler.typeClass);
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
    this.environment = new Map<Element, ConcreteType>();
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
      if (element == null) {
        newMap[element] = type;
      } else {
        newMap[element] = inferrer.union(currentType, type);
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

  String toString() => "{ this: $typeOfThis, env: ${environment.toString()} }";
}

/**
 * A work item for the type inference queue.
 */
class InferenceWorkItem {
  FunctionElement method;
  ConcreteTypesEnvironment environment;
  InferenceWorkItem(this.method, this.environment);

  toString() => "{ method = ${method.name.slowToString()}, "
                "environment = $environment }";
}

/**
 * A task which conservatively infers a [ConcreteType] for each sub expression
 * of the program. The entry point is [analyzeMain].
 */
class ConcreteTypesInferrer {
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
   * concrete implmentation of lists for the selected backend.
   */
  FunctionElement listIndex;

  /**
   * Constant representing [:ConcreteList#[]=:] where [:ConcreteList:] is the
   * concrete implmentation of lists for the selected backend.
   */
  FunctionElement listIndexSet;

  /**
   * Constant representing [:List():].
   */
  FunctionElement listConstructor;

  /**
   * A cache from (function x argument base types) to concrete types,
   * used to memoize [analyzeMonoSend]. Another way of seeing [cache] is as a
   * map from [FunctionElement]s to "templates" in the sense of "The Cartesian
   * Product Algorithm - Simple and Precise Type Inference of Parametric
   * Polymorphism" by Ole Agesen.
   */
  final Map<FunctionElement, Map<ConcreteTypesEnvironment, ConcreteType>> cache;

  /** A map from expressions to their inferred concrete types. */
  final Map<Node, ConcreteType> inferredTypes;

  /** A map from fields to their inferred concrete types. */
  final Map<Element, ConcreteType> inferredFieldTypes;

  /** The work queue consumed by [analyzeMain]. */
  final Queue<InferenceWorkItem> workQueue;

  /** [: callers[f] :] is the list of [: f :]'s possible callers. */
  final Map<FunctionElement, Set<FunctionElement>> callers;

  /** [: readers[field] :] is the list of [: field :]'s possible readers. */
  final Map<Element, Set<FunctionElement>> readers;

  /** The inferred type of elements stored in Lists. */
  ConcreteType listElementType;

  /**
   * A map from parameters to their inferred concrete types. It plays no role
   * in the analysis, it is write only.
   */
  final Map<VariableElement, ConcreteType> inferredParameterTypes;

  ConcreteTypesInferrer(Compiler compiler)
      : this.compiler = compiler,
        cache = new Map<FunctionElement,
            Map<ConcreteTypesEnvironment, ConcreteType>>(),
        inferredTypes = new Map<Node, ConcreteType>(),
        inferredFieldTypes = new Map<Element, ConcreteType>(),
        inferredParameterTypes = new Map<VariableElement, ConcreteType>(),
        workQueue = new Queue<InferenceWorkItem>(),
        callers = new Map<FunctionElement, Set<FunctionElement>>(),
        readers = new Map<Element, Set<FunctionElement>>(),
        listElementType = new ConcreteType.empty() {
    unknownConcreteType = new ConcreteType.unknown();
    emptyConcreteType = new ConcreteType.empty();
  }

  /**
   * Populates [cache] with ad hoc rules like:
   *
   *     {int} + {int}    -> {int}
   *     {int} + {double} -> {num}
   *     {int} + {num}    -> {double}
   *     ...
   */
  populateCacheWithBuiltinRules() {
    // Builds the environment that would be looked up if we were to analyze
    // o.method(arg) where o has concrete type {receiverType} and arg has
    // concrete type {argumentType}.
    ConcreteTypesEnvironment makeEnvironment(BaseType receiverType,
                                             FunctionElement method,
                                             BaseType argumentType) {
      ArgumentsTypes argumentsTypes = new ArgumentsTypes(
          [singletonConcreteType(argumentType)],
          new Map());
      Map<Element, ConcreteType> argumentMap =
          associateArguments(method, argumentsTypes);
      return new ConcreteTypesEnvironment.of(this, argumentMap, receiverType);
    }

    // Adds the rule {receiverType}.method({argumentType}) -> {returnType}
    // to cache.
    void rule(ClassBaseType receiverType, String method,
              BaseType argumentType, BaseType returnType) {
      // The following line shouldn't be needed but the mock compiler doesn't
      // resolve num for some reason.
      receiverType.element.ensureResolved(compiler);
      FunctionElement methodElement =
          receiverType.element.lookupMember(new SourceString(method));
      ConcreteTypesEnvironment environment =
          makeEnvironment(receiverType, methodElement, argumentType);
      Map<ConcreteTypesEnvironment, ConcreteType> map =
          cache.containsKey(methodElement)
              ? cache[methodElement]
              : new Map<ConcreteTypesEnvironment, ConcreteType>();
      map[environment] = singletonConcreteType(returnType);
      cache[methodElement] = map;
    }

    // The hardcoded typing rules.
    final ClassBaseType int = baseTypes.intBaseType;
    final ClassBaseType double = baseTypes.doubleBaseType;
    final ClassBaseType num = baseTypes.numBaseType;
    for (String method in ['+', '*', '-']) {
      rule(int, method, int, int);
      rule(int, method, double, num);
      rule(int, method, num, num);

      rule(double, method, double, double);
      rule(double, method, int, num);
      rule(double, method, num, num);

      rule(num, method, int, num);
      rule(num, method, double, num);
      rule(num, method, num, num);
    }
  }

  // --- utility methods ---

  /** The unknown concrete type */
  ConcreteType unknownConcreteType;

  /** The empty concrete type */
  ConcreteType emptyConcreteType;

  /** Creates a singleton concrete type containing [baseType]. */
  ConcreteType singletonConcreteType(BaseType baseType) {
    return new ConcreteType.singleton(compiler.maxConcreteTypeSize, baseType);
  }

  /** Returns the union of its two arguments */
  ConcreteType union(ConcreteType concreteType1, ConcreteType concreteType2) {
    return concreteType1.union(compiler.maxConcreteTypeSize, concreteType2);
  }

  /**
   * Returns all the members with name [methodName].
   */
  List<Element> getMembersByName(SourceString methodName) {
    // TODO(polux): memoize?
    var result = new List<Element>();
    for (ClassElement cls in compiler.enqueuer.resolution.seenClasses) {
      Element elem = cls.lookupLocalMember(methodName);
      if (elem != null) {
        result.add(elem);
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
        : union(currentType, type);
  }

  /**
   * Returns the current inferred concrete type of [field].
   */
  ConcreteType getFieldType(Element field) {
    ConcreteType result = inferredFieldTypes[field];
    return (result == null) ? emptyConcreteType : result;
  }

  /**
   * Sets the concrete type associated to [field] to the union of the inferred
   * concrete type so far and [type].
   */
  void augmentFieldType(Element field, ConcreteType type) {
    ConcreteType oldType = inferredFieldTypes[field];
    ConcreteType newType = (oldType != null)
        ? union(oldType, type)
        : type;
    if (oldType != newType) {
      inferredFieldTypes[field] = newType;
      final fieldReaders = readers[field];
      if (fieldReaders != null) {
        for (final reader in fieldReaders) {
          final readerInstances = cache[reader];
          if (readerInstances != null) {
            readerInstances.forEach((environment, _) {
              workQueue.addLast(new InferenceWorkItem(reader, environment));
            });
          }
        }
      }
    }
  }

  /// Augment the inferred type of elements stored in Lists.
  void augmentListElementType(ConcreteType type) {
    ConcreteType newType = union(listElementType, type);
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
        (oldType == null) ? type : union(oldType, type);
  }

  /**
   * Add [caller] to the set of [callee]'s callers.
   */
  void addCaller(FunctionElement callee, FunctionElement caller) {
    Set<FunctionElement> current = callers[callee];
    if (current != null) {
      current.add(caller);
    } else {
      Set<FunctionElement> newSet = new Set<FunctionElement>();
      newSet.add(caller);
      callers[callee] = newSet;
    }
  }

  /**
   * Add [reader] to the set of [field]'s readers.
   */
  void addReader(Element field, FunctionElement reader) {
    Set<FunctionElement> current = readers[field];
    if (current != null) {
      current.add(reader);
    } else {
      Set<FunctionElement> newSet = new Set<FunctionElement>();
      newSet.add(reader);
      readers[field] = newSet;
    }
  }

  /**
   * Add callers of [function] to the workqueue.
   */
  void invalidateCallers(FunctionElement function) {
    Set<FunctionElement> methodCallers = callers[function];
    if (methodCallers == null) return;
    for (FunctionElement caller in methodCallers) {
      Map<ConcreteTypesEnvironment, ConcreteType> callerInstances =
          cache[caller];
      if (callerInstances != null) {
        callerInstances.forEach((environment, _) {
          workQueue.addLast(
              new InferenceWorkItem(caller, environment));
        });
      }
    }
  }

  // -- query --

  /**
   * Get the inferred concrete type of [node].
   */
  ConcreteType getConcreteTypeOfNode(Node node) => inferredTypes[node];

  /**
   * Get the inferred concrete type of [parameter].
   */
  ConcreteType getConcreteTypeOfParameter(VariableElement parameter) {
    return inferredParameterTypes[parameter];
  }

  // --- analysis ---

  /**
   * Returns the concrete type returned by [function] given arguments of
   * concrete types [argumentsTypes]. If [function] is static then
   * [receiverType] must be null, else [function] must be a member of the class
   * of [receiverType].
   */
  ConcreteType getSendReturnType(FunctionElement function,
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
      result = union(result,
                     getMonomorphicSendReturnType(function, environment));
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
      result[parameter] = singletonConcreteType(const NullBaseType());
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
      final Map<SourceString, Element> leftOverNamedParameters =
          new Map<SourceString, Element>();
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
        SourceString source = identifier.source;
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
    ConcreteType specialType = getSpecialCaseReturnType(function, environment);
    if (specialType != null) return specialType;

    Map<ConcreteTypesEnvironment, ConcreteType> template = cache[function];
    if (template == null) {
      template = new Map<ConcreteTypesEnvironment, ConcreteType>();
      cache[function] = template;
    }
    ConcreteType type = template[environment];
    if (type != null) {
      return type;
    } else {
      workQueue.addLast(
        new InferenceWorkItem(function, environment));
      // in case of a constructor, optimize by returning the class
      return emptyConcreteType;
    }
  }

  /**
   * Handles external methods that cannot be cached because they depend on some
   * other state of [ConcreteTypesInferrer] like [:List#[]:] and
   * [:List#[]=:]. Returns null if [function] and [environment] don't form a
   * special case
   */
  ConcreteType getSpecialCaseReturnType(FunctionElement function,
                                        ConcreteTypesEnvironment environment) {
    if (function == listIndex) {
      ConcreteType indexType = environment.lookupType(
          listIndex.functionSignature.requiredParameters.head);
      if (!indexType.baseTypes.contains(baseTypes.intBaseType)) {
        return new ConcreteType.empty();
      }
      return listElementType;
    } else if (function == listIndexSet) {
      Link<Element> parameters =
          listIndexSet.functionSignature.requiredParameters;
      ConcreteType indexType = environment.lookupType(parameters.head);
      if (!indexType.baseTypes.contains(baseTypes.intBaseType)) {
        return new ConcreteType.empty();
      }
      ConcreteType elementType = environment.lookupType(parameters.tail.head);
      augmentListElementType(elementType);
      return new ConcreteType.empty();
    }
    return null;
  }

  ConcreteType analyze(FunctionElement element,
                       ConcreteTypesEnvironment environment) {
    return element.isGenerativeConstructor()
        ? analyzeConstructor(element, environment)
        : analyzeMethod(element, environment);
  }

  ConcreteType analyzeMethod(FunctionElement element,
                             ConcreteTypesEnvironment environment) {
    TreeElements elements =
        compiler.enqueuer.resolution.resolvedElements[element];
    ConcreteType specialResult = handleSpecialMethod(element, environment);
    if (specialResult != null) return specialResult;
    FunctionExpression tree = element.parseNode(compiler);
    if (tree.hasBody()) {
      Visitor visitor =
          new TypeInferrerVisitor(elements, element, this, environment);
      return tree.accept(visitor);
    } else {
      // TODO(polux): implement visitForeingCall and always use the
      // implementation element instead of this hack
      return new ConcreteType.unknown();
    }
  }

  ConcreteType analyzeConstructor(FunctionElement element,
                                  ConcreteTypesEnvironment environment) {
    ClassElement enclosingClass = element.enclosingElement;
    FunctionExpression tree = compiler.parser.parse(element);
    TreeElements elements =
        compiler.enqueuer.resolution.resolvedElements[element];
    Visitor visitor =
        new TypeInferrerVisitor(elements, element, this, environment);

    // handle initializing formals
    element.functionSignature.forEachParameter((param) {
      if (param.kind == ElementKind.FIELD_PARAMETER) {
        FieldParameterElement fieldParam = param;
        augmentFieldType(fieldParam.fieldElement,
            environment.lookupType(param));
      }
    });

    // analyze initializers, including a possible call to super or a redirect
    bool foundSuperOrRedirect = false;
    if (tree.initializers != null) {
      // we look for a possible call to super in the initializer list
      for (final init in tree.initializers) {
        init.accept(visitor);
        if (init.asSendSet() == null) {
          foundSuperOrRedirect = true;
        }
      }
    }

    // if no call to super or redirect has been found, call the default
    // constructor (if the current class is not Object).
    if (!foundSuperOrRedirect) {
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        FunctionElement target = superClass.lookupConstructor(
          new Selector.callDefaultConstructor(enclosingClass.getLibrary()));
        final superClassConcreteType = singletonConcreteType(
            new ClassBaseType(enclosingClass));
        getSendReturnType(target, enclosingClass,
            new ArgumentsTypes(new List(), new Map()));
      }
    }

    tree.accept(visitor);
    return singletonConcreteType(new ClassBaseType(enclosingClass));
  }

  /**
   * Hook that performs side effects on some special method calls (like
   * [:List(length):]) and possibly returns a concrete type
   * (like [:{JsArray}:]).
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
        augmentListElementType(singletonConcreteType(new NullBaseType()));
      }
      return singletonConcreteType(baseTypes.listBaseType);
    }
  }

  /* Initialization code that cannot be run in the constructor because it
   * requires the compiler's elements to be populated.
   */
  void initialize() {
    baseTypes = new BaseTypes(compiler);
    ClassElement jsArrayClass = baseTypes.listBaseType.element;
    listIndex = jsArrayClass.lookupMember(const SourceString('[]'));
    listIndexSet =
        jsArrayClass.lookupMember(const SourceString('[]='));
    listConstructor =
        compiler.listClass.lookupConstructor(
            new Selector.callConstructor(const SourceString(''),
                                         compiler.listClass.getLibrary()));
  }

  void analyzeMain(Element element) {
    initialize();
    cache[element] = new Map<ConcreteTypesEnvironment, ConcreteType>();
    populateCacheWithBuiltinRules();
    try {
      workQueue.addLast(
          new InferenceWorkItem(element, new ConcreteTypesEnvironment(this)));
      while (!workQueue.isEmpty) {
        InferenceWorkItem item = workQueue.removeFirst();
        ConcreteType concreteType = analyze(item.method, item.environment);
        var template = cache[item.method];
        if (template[item.environment] == concreteType) continue;
        template[item.environment] = concreteType;
        invalidateCallers(item.method);
      }
    } on CancelTypeInferenceException catch(e) {
      if (LOG_FAILURES) {
        compiler.log("'${e.node.toDebugString()}': ${e.reason}");
      }
    }
  }

  /**
   * Dumps debugging information on the standard output.
   */
  void debug() {
    print("callers :");
    callers.forEach((k,v) {
      print("  $k: $v");
    });
    print("readers :");
    readers.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferredFieldTypes:");
    inferredFieldTypes.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferredParameterTypes:");
    inferredParameterTypes.forEach((k,v) {
      print("  $k: $v");
    });
    print("cache:");
    cache.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferred expression types: ");
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

  final FunctionElement currentMethod;
  ConcreteTypesEnvironment environment;
  Node lastSeenNode;

  TypeInferrerVisitor(TreeElements elements, this.currentMethod, this.inferrer,
                      this.environment)
      : super(elements);

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
    inferrer.fail(node, 'not yet implemented');
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
    ConcreteType result = inferrer.emptyConcreteType;
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
    return result;
  }

  ConcreteType visitFunctionDeclaration(FunctionDeclaration node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitFunctionExpression(FunctionExpression node) {
    return analyze(node.body);
  }

  ConcreteType visitIdentifier(Identifier node) {
    if (node.isThis()) {
      ConcreteType result = environment.lookupTypeOfThis();
      if (result == null) {
        inferrer.fail(node, '"this" has no type');
      }
      return result;
    }
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitIf(If node) {
    analyze(node.condition);
    ConcreteType thenType = analyze(node.thenPart);
    ConcreteTypesEnvironment snapshot = environment;
    ConcreteType elseType = node.hasElsePart ? analyze(node.elsePart)
                                             : inferrer.emptyConcreteType;
    environment = environment.join(snapshot);
    return inferrer.union(thenType, elseType);
  }

  ConcreteType visitLoop(Loop node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType analyzeSetElement(Element receiver, ConcreteType argumentType) {
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
      inferrer.getSendReturnType(setter, receiver.enclosingElement,
          new ArgumentsTypes([argumentType], new Map()));
    }
    return argumentType;
  }

  ConcreteType analyzeSetNode(Node receiver, ConcreteType argumentType,
                              SourceString name) {
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
        inferrer.getSendReturnType(setter, receiverType,
            new ArgumentsTypes([argumentType], new Map()));
      }
      // since this is a sendSet we ignore non-fields
    }

    if (receiverType.isUnkown()) {
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

  SourceString canonicalizeCompoundOperator(SourceString op) {
    // TODO(ahe): This class should work on elements or selectors, not
    // names.  Otherwise, it is repeating work the resolver has
    // already done (or should have done).  In this case, the problem
    // is that the resolver is not recording the selectors it is
    // registering in registerBinaryOperator in
    // ResolverVisitor.visitSendSet.
    String stringValue = op.stringValue;
    if (stringValue == '++') return const SourceString(r'+');
    else if (stringValue == '--') return const SourceString(r'-');
    else return Elements.mapToUserOperatorOrNull(op);
  }

  ConcreteType visitSendSet(SendSet node) {
    // Operator []= has a different behaviour than other send sets: it is
    // actually a send whose return type is that of its second argument.
    if (node.selector.asIdentifier().source.stringValue == '[]') {
      ConcreteType receiverType = analyze(node.receiver);
      ArgumentsTypes argumentsTypes = analyzeArguments(node.arguments);
      analyzeDynamicSend(receiverType, const SourceString('[]='),
                         argumentsTypes);
      return argumentsTypes.positional[1];
    }

    // All other operators have a single argument (++ and -- have an implicit
    // argument: 1). We will store its type in argumentType.
    ConcreteType argumentType;
    SourceString operatorName = node.assignmentOperator.source;
    SourceString compoundOperatorName =
        canonicalizeCompoundOperator(node.assignmentOperator.source);
    // ++, --, +=, -=, ...
    if (compoundOperatorName != null) {
      ConcreteType receiverType = visitGetterSend(node);
      // argumentsTypes is either computed from the actual arguments or [{int}]
      // in case of ++ or --.
      ArgumentsTypes argumentsTypes;
      if (operatorName.stringValue == '++'
          || operatorName.stringValue == '--') {
        List<ConcreteType> positionalArguments = <ConcreteType>[
            inferrer.singletonConcreteType(inferrer.baseTypes.intBaseType)];
        argumentsTypes = new ArgumentsTypes(positionalArguments, new Map());
      } else {
        argumentsTypes = analyzeArguments(node.arguments);
      }
      argumentType = analyzeDynamicSend(receiverType, compoundOperatorName,
                                        argumentsTypes);
    // The simple assignment case: receiver = argument.
    } else {
      argumentType = analyze(node.argumentsNode);
    }

    Element element = elements[node];
    if (element != null) {
      return analyzeSetElement(element, argumentType);
    } else {
      return analyzeSetNode(node.receiver, argumentType,
                            node.selector.asIdentifier().source);
    }
  }

  ConcreteType visitLiteralInt(LiteralInt node) {
    return inferrer.singletonConcreteType(inferrer.baseTypes.intBaseType);
  }

  ConcreteType visitLiteralDouble(LiteralDouble node) {
    return inferrer.singletonConcreteType(inferrer.baseTypes.doubleBaseType);
  }

  ConcreteType visitLiteralBool(LiteralBool node) {
    return inferrer.singletonConcreteType(inferrer.baseTypes.boolBaseType);
  }

  ConcreteType visitLiteralString(LiteralString node) {
    // TODO(polux): get rid of this hack once we have a natural way of inferring
    // the unknown type.
    if (inferrer.testMode
        && node.dartString.slowToString() == "__dynamic_for_test") {
      return inferrer.unknownConcreteType;
    }
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitStringJuxtaposition(StringJuxtaposition node) {
    analyze(node.first);
    analyze(node.second);
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitLiteralNull(LiteralNull node) {
    return inferrer.singletonConcreteType(const NullBaseType());
  }

  ConcreteType visitNewExpression(NewExpression node) {
    Element constructor = elements[node.send];
    inferrer.addCaller(constructor, currentMethod);
    ClassElement cls = constructor.enclosingElement;
    return inferrer.getSendReturnType(constructor, cls,
                                      analyzeArguments(node.send.arguments));
  }

  ConcreteType visitLiteralList(LiteralList node) {
    ConcreteType elementsType = new ConcreteType.empty();
    // We compute the union of the types of the list literal's elements.
    for (Link<Node> link = node.elements.nodes;
         !link.isEmpty;
         link = link.tail) {
      elementsType = inferrer.union(elementsType, analyze(link.head));
    }
    inferrer.augmentListElementType(elementsType);
    return inferrer.singletonConcreteType(inferrer.baseTypes.listBaseType);
  }

  ConcreteType visitNodeList(NodeList node) {
    ConcreteType type = inferrer.emptyConcreteType;
    // The concrete type of a sequence of statements is the union of the
    // statement's types.
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      type = inferrer.union(type, analyze(link.head));
    }
    return type;
  }

  ConcreteType visitOperator(Operator node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitReturn(Return node) {
    final expression = node.expression;
    return (expression == null)
        ? inferrer.singletonConcreteType(const NullBaseType())
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
    ConcreteType result = inferrer.emptyConcreteType;
    ConcreteTypesEnvironment oldEnvironment;
    do {
      oldEnvironment = environment;
      analyze(node.condition);
      analyze(node.body);
      environment = oldEnvironment.join(environment);
    } while (oldEnvironment != environment);
    return result;
  }

  ConcreteType visitParenthesizedExpression(ParenthesizedExpression node) {
    return analyze(node.expression);
  }

  ConcreteType visitConditional(Conditional node) {
    analyze(node.condition);
    ConcreteType thenType = analyze(node.thenExpression);
    ConcreteType elseType = analyze(node.elseExpression);
    return inferrer.union(thenType, elseType);
  }

  ConcreteType visitModifiers(Modifiers node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return inferrer.singletonConcreteType(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitStringInterpolationPart(StringInterpolationPart node) {
    node.visitChildren(this);
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
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitLabel(Label node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitLabeledStatement(LabeledStatement node) {
    return analyze(node.statement);
  }

  ConcreteType visitLiteralMap(LiteralMap node) {
    visitNodeList(node.entries);
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

  ConcreteType visitScriptTag(ScriptTag node) {
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
    return visitDynamicSend(node);
  }

  ConcreteType analyzeFieldRead(Element field) {
    inferrer.addReader(field, currentMethod);
    return inferrer.getFieldType(field);
  }

  ConcreteType analyzeGetterSend(ClassElement receiverType,
                                 FunctionElement getter) {
      inferrer.addCaller(getter, currentMethod);
      return inferrer.getSendReturnType(getter,
                                        receiverType,
                                        new ArgumentsTypes([], new Map()));
  }

  ConcreteType visitGetterSend(Send node) {
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
          return analyzeFieldRead(element);
        } else {
          assert(element.isGetter());
          ClassElement receiverType = element.enclosingElement;
          return analyzeGetterSend(receiverType, element);
        }
      }
    } else {
      // node is a field of not(this)
      assert(node.receiver != null);

      ConcreteType result = inferrer.emptyConcreteType;
      void augmentResult(ClassElement baseReceiverType, Element member) {
        if (member.isField()) {
          result = inferrer.union(result, analyzeFieldRead(member));
        } else if (member.isAbstractField()){
          // call to a getter
          AbstractFieldElement abstractField = member;
          result = inferrer.union(
              result,
              analyzeGetterSend(baseReceiverType, abstractField.getter));
        }
        // since this is a get we ignore non-fields
      }

      ConcreteType receiverType = analyze(node.receiver);
      if (receiverType.isUnkown()) {
        List<Element> members =
            inferrer.getMembersByName(node.selector.asIdentifier().source);
        for (Element member in members) {
          if (!(member.isField() || member.isAbstractField())) continue;
          Element cls = member.getEnclosingClass();
          augmentResult(cls, member);
        }
      } else {
        for (BaseType baseReceiverType in receiverType.baseTypes) {
          if (!baseReceiverType.isNull()) {
            ClassBaseType classBaseType = baseReceiverType;
            ClassElement cls = classBaseType.element;
            Element getterOrField =
                cls.lookupMember(node.selector.asIdentifier().source);
            if (getterOrField != null) {
              augmentResult(cls, getterOrField);
            }
          }
        }
      }
      return result;
    }
  }

  ConcreteType visitClosureSend(Send node) {
    inferrer.fail(node, 'not implemented');
  }

  ConcreteType analyzeDynamicSend(ConcreteType receiverType,
                                  SourceString canonicalizedMethodName,
                                  ArgumentsTypes argumentsTypes) {
    ConcreteType result = inferrer.emptyConcreteType;

    if (receiverType.isUnkown()) {
      List<Element> methods =
          inferrer.getMembersByName(canonicalizedMethodName);
      for (Element element in methods) {
        // TODO(polux): when we handle closures, we must handle sends to fields
        // that are closures.
        if (!element.isFunction()) continue;
        FunctionElement method = element;
        inferrer.addCaller(method, currentMethod);
        Element cls = method.enclosingElement;
        result = inferrer.union(
            result,
            inferrer.getSendReturnType(method, cls, argumentsTypes));
      }

    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseReceiverType = baseReceiverType;
          ClassElement cls = classBaseReceiverType.element;
          FunctionElement method = cls.lookupMember(canonicalizedMethodName);
          if (method != null) {
            inferrer.addCaller(method, currentMethod);
            result = inferrer.union(
                result,
                inferrer.getSendReturnType(method, cls, argumentsTypes));
          }
        }
      }
    }
    return result;
  }

  SourceString canonicalizeMethodName(SourceString name) {
    // TODO(polux): handle unary-
    SourceString operatorName =
        Elements.constructOperatorNameOrNull(name, false);
    if (operatorName != null) return operatorName;
    return name;
  }

  ConcreteType visitDynamicSend(Send node) {
    ConcreteType receiverType = (node.receiver != null)
        ? analyze(node.receiver)
        : inferrer.singletonConcreteType(
            new ClassBaseType(currentMethod.getEnclosingClass()));
    SourceString name =
        canonicalizeMethodName(node.selector.asIdentifier().source);
    ArgumentsTypes argumentsTypes = analyzeArguments(node.arguments);
    if (name.stringValue == '!=') {
      ConcreteType returnType = analyzeDynamicSend(receiverType,
                                                   const SourceString('=='),
                                                   argumentsTypes);
      return returnType.isEmpty()
          ? returnType
          : inferrer.singletonConcreteType(inferrer.baseTypes.boolBaseType);
    } else {
      return analyzeDynamicSend(receiverType, name, argumentsTypes);
    }
  }

  ConcreteType visitForeignSend(Send node) {
    inferrer.fail(node, 'not implemented');
  }

  ConcreteType visitStaticSend(Send node) {
    Element element = elements[node];
    inferrer.addCaller(element, currentMethod);
    return inferrer.getSendReturnType(element, null,
        analyzeArguments(node.arguments));
  }

  void internalError(String reason, {Node node}) {
    inferrer.fail(node, reason);
  }

  ConcreteType visitTypeReferenceSend(Send) {
    return inferrer.singletonConcreteType(inferrer.baseTypes.typeBaseType);
  }
}
