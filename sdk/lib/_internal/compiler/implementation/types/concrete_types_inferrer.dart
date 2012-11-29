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
  factory ConcreteType.empty() => new UnionType(new Set<BaseType>());

  /**
   * The singleton constituted of the unknown base type is the unknown concrete
   * type.
   */
  factory ConcreteType.singleton(BaseType baseType) {
    if (baseType.isUnknown()) {
      return const UnknownConcreteType();
    }
    Set<BaseType> singletonSet = new Set<BaseType>();
    singletonSet.add(baseType);
    return new UnionType(singletonSet);
  }

  factory ConcreteType.unknown() => const UnknownConcreteType();

  ConcreteType union(ConcreteType other);
  bool isUnkown();
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
  final Set<BaseType> baseTypes;

  /**
   * The argument should NOT be mutated later. Do not call directly, use
   * ConcreteType.singleton instead.
   */
  UnionType(this.baseTypes);

  bool isUnkown() => false;

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
  ConcreteType union(ConcreteType other) {
    if (other.isUnkown()) {
      return const UnknownConcreteType();
    }
    UnionType otherUnion = other;  // cast
    Set<BaseType> newBaseTypes = new Set<BaseType>.from(baseTypes);
    newBaseTypes.addAll(otherUnion.baseTypes);
    return new UnionType(newBaseTypes);
  }

  ClassElement getUniqueType() {
    if (baseTypes.length == 1) {
      BaseType uniqueBaseType = baseTypes.iterator().next();
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
    implements Iterable<ConcreteTypesEnvironment> {
  final BaseType baseTypeOfThis;
  final Map<Element, ConcreteType> concreteTypes;
  ConcreteTypeCartesianProduct(this.baseTypeOfThis, this.concreteTypes);
  Iterator iterator() => concreteTypes.isEmpty
      ? [new ConcreteTypesEnvironment(baseTypeOfThis)].iterator()
      : new ConcreteTypeCartesianProductIterator(baseTypeOfThis, concreteTypes);
  String toString() {
    List<ConcreteTypesEnvironment> cartesianProduct =
        new List<ConcreteTypesEnvironment>.from(this);
    return cartesianProduct.toString();
  }
}

/**
 * An helper class for [ConcreteTypeCartesianProduct].
 */
class ConcreteTypeCartesianProductIterator implements Iterator {
  final BaseType baseTypeOfThis;
  final Map<Element, ConcreteType> concreteTypes;
  final Map<Element, BaseType> nextValues;
  final Map<Element, Iterator> state;
  int size = 1;
  int counter = 0;

  ConcreteTypeCartesianProductIterator(this.baseTypeOfThis,
      Map<Element, ConcreteType> concreteTypes) :
    this.concreteTypes = concreteTypes,
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

  bool get hasNext {
    return counter < size;
  }

  ConcreteTypesEnvironment takeSnapshot() {
    Map<Element, ConcreteType> result = new Map<Element, ConcreteType>();
    nextValues.forEach((k, v) { result[k] = new ConcreteType.singleton(v); });
    return new ConcreteTypesEnvironment.of(result, baseTypeOfThis);
  }

  ConcreteTypesEnvironment next() {
    if (!hasNext) throw new StateError("No more elements");
    Element keyToIncrement = null;
    for (final key in concreteTypes.keys) {
      final iterator = state[key];
      if (iterator != null && iterator.hasNext) {
        nextValues[key] = state[key].next();
        break;
      }
      Iterator newIterator = concreteTypes[key].baseTypes.iterator();
      state[key] = newIterator;
      nextValues[key] = newIterator.next();
    }
    counter++;
    return takeSnapshot();
  }
}

/**
 * [BaseType] Constants.
 */
class BaseTypes {
  final BaseType intBaseType;
  final BaseType doubleBaseType;
  final BaseType numBaseType;
  final BaseType boolBaseType;
  final BaseType stringBaseType;
  final BaseType listBaseType;
  final BaseType mapBaseType;
  final BaseType objectBaseType;
  final BaseType typeBaseType;

  BaseTypes(Compiler compiler) :
    intBaseType = new ClassBaseType(compiler.intClass),
    doubleBaseType = new ClassBaseType(compiler.doubleClass),
    numBaseType = new ClassBaseType(compiler.numClass),
    boolBaseType = new ClassBaseType(compiler.boolClass),
    stringBaseType = new ClassBaseType(compiler.stringClass),
    listBaseType = new ClassBaseType(compiler.listClass),
    mapBaseType = new ClassBaseType(compiler.mapClass),
    objectBaseType = new ClassBaseType(compiler.objectClass),
    typeBaseType = new ClassBaseType(compiler.typeClass);
}

/**
 * A method-local immutable mapping from variables to their inferred
 * [ConcreteTypes]. Each visitor owns one.
 */
class ConcreteTypesEnvironment {
  final Map<Element, ConcreteType> environment;
  final BaseType typeOfThis;
  ConcreteTypesEnvironment([this.typeOfThis]) :
    this.environment = new Map<Element, ConcreteType>();
  ConcreteTypesEnvironment.of(this.environment, this.typeOfThis);

  ConcreteType lookupType(Element element) => environment[element];
  ConcreteType lookupTypeOfThis() {
    return (typeOfThis == null)
        ? null
        : new ConcreteType.singleton(typeOfThis);
  }

  ConcreteTypesEnvironment put(Element element, ConcreteType type) {
    Map<Element, ConcreteType> newMap =
        new Map<Element, ConcreteType>.from(environment);
    newMap[element] = type;
    return new ConcreteTypesEnvironment.of(newMap, typeOfThis);
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
        newMap[element] = currentType.union(type);
      }
    });
    return new ConcreteTypesEnvironment.of(newMap, typeOfThis);
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
   * When true, the string litteral [:"__dynamic_for_test":] is inferred to
   * have the unknown type.
   */
  // TODO(polux): get rid of this hack once we have a natural way of inferring
  // the unknown type.
  bool testMode = false;

  /**
   * Constants representing builtin base types. Initialized in [analyzeMain]
   * and not in the constructor because the compiler elements are not yet
   * populated.
   */
  BaseTypes baseTypes;

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
        readers = new Map<Element, Set<FunctionElement>>();

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
          [new ConcreteType.singleton(argumentType)],
          new Map());
      Map<Element, ConcreteType> argumentMap =
          associateArguments(method, argumentsTypes);
      return new ConcreteTypesEnvironment.of(argumentMap, receiverType);
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
      map[environment] = new ConcreteType.singleton(returnType);
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

  /**
   * Returns all the members with name [methodName].
   */
  List<Element> getMembersByName(SourceString methodName) {
    // TODO(polux): make this faster!
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
        : currentType.union(type);
  }

  /**
   * Returns the current inferred concrete type of [field].
   */
  ConcreteType getFieldType(Element field) {
    ConcreteType result = inferredFieldTypes[field];
    return (result == null) ? new ConcreteType.empty() : result;
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

  /**
   * Sets the concrete type associated to [parameter] to the union of the
   * inferred concrete type so far and [type].
   */
  void augmentParameterType(VariableElement parameter, ConcreteType type) {
    ConcreteType oldType = inferredParameterTypes[parameter];
    inferredParameterTypes[parameter] =
        (oldType == null) ? type : oldType.union(type);
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
                                 BaseType receiverType,
                                 ArgumentsTypes argumentsTypes) {
    ConcreteType result = new ConcreteType.empty();
    Map<Element, ConcreteType> argumentMap =
        associateArguments(function, argumentsTypes);
    // if the association failed, this send will never occur or will fail
    if (argumentMap == null) {
      return new ConcreteType.empty();
    }
    argumentMap.forEach(augmentParameterType);
    ConcreteTypeCartesianProduct product =
        new ConcreteTypeCartesianProduct(receiverType, argumentMap);
    for (ConcreteTypesEnvironment environment in product) {
      result = result.union(
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
    // too many arguments
    if (argumentsTypes.length > signature.parameterCount) {
      return null;
    }
    // not enough arguments
    if (argumentsTypes.positional.length < signature.requiredParameterCount) {
      return null;
    }
    final Iterator<ConcreteType> remainingPositionalArguments =
        argumentsTypes.positional.iterator();
    // we attach each positional parameter to its corresponding positional
    // argument
    for (Link<Element> requiredParameters = signature.requiredParameters;
         !requiredParameters.isEmpty;
         requiredParameters = requiredParameters.tail) {
      final Element requiredParameter = requiredParameters.head;
      // we know next() is defined because of the guard above
      result[requiredParameter] = remainingPositionalArguments.next();
    }
    // we attach the remaining positional arguments to their corresponding
    // named arguments
    Link<Element> remainingNamedParameters = signature.optionalParameters;
    while (remainingPositionalArguments.hasNext) {
      final Element namedParameter = remainingNamedParameters.head;
      result[namedParameter] = remainingPositionalArguments.next();
      // we know tail is defined because of the guard above
      remainingNamedParameters = remainingNamedParameters.tail;
    }
    // we build a map out of the remaining named parameters
    final Map<SourceString, Element> leftOverNamedParameters =
        new Map<SourceString, Element>();
    for (;
         !remainingNamedParameters.isEmpty;
         remainingNamedParameters = remainingNamedParameters.tail) {
      final Element namedParameter = remainingNamedParameters.head;
      leftOverNamedParameters[namedParameter.name] = namedParameter;
    }
    // we attach the named arguments to their corresponding named paramaters
    // (we don't use foreach because we want to be able to return early)
    for (Identifier identifier in argumentsTypes.named.keys) {
      final ConcreteType concreteType = argumentsTypes.named[identifier];
      SourceString source = identifier.source;
      final Element namedParameter = leftOverNamedParameters[source];
      // unexisting or already used named parameter
      if (namedParameter == null) return null;
      result[namedParameter] = concreteType;
      leftOverNamedParameters.remove(source);
    };
    // we use null for each unused named parameter
    // TODO(polux): use default value whenever available
    // TODO(polux): add a marker to indicate whether an argument was provided
    //     in order to handle "?parameter" tests
    leftOverNamedParameters.forEach((_, Element namedParameter) {
      result[namedParameter] =
          new ConcreteType.singleton(const NullBaseType());
    });
    return result;
  }

  ConcreteType getMonomorphicSendReturnType(
      FunctionElement function,
      ConcreteTypesEnvironment environment) {

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
      return new ConcreteType.empty();
    }
  }

  ConcreteType analyze(FunctionElement element,
                       ConcreteTypesEnvironment environment) {
    return element.isGenerativeConstructor()
        ? analyzeConstructor(element, environment)
        : analyzeMethod(element, environment);
  }

  ConcreteType analyzeMethod(FunctionElement element,
                             ConcreteTypesEnvironment environment) {
    FunctionExpression tree = element.parseNode(compiler);
    // This should never happen since we only deal with concrete types, except
    // for external methods whose typing rules have not been hardcoded yet.
    if (!tree.hasBody()) {
      return new ConcreteType.unknown();
    }
    TreeElements elements =
        compiler.enqueuer.resolution.resolvedElements[element];
    Visitor visitor =
        new TypeInferrerVisitor(elements, element, this, environment);
    return tree.accept(visitor);
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
        final superClassConcreteType = new ConcreteType.singleton(
            new ClassBaseType(enclosingClass));
        getSendReturnType(target, new ClassBaseType(enclosingClass),
            new ArgumentsTypes(new List(), new Map()));
      }
    }

    tree.accept(visitor);
    return new ConcreteType.singleton(new ClassBaseType(enclosingClass));
  }

  void analyzeMain(Element element) {
    baseTypes = new BaseTypes(compiler);
    cache[element] = new Map<ConcreteTypesEnvironment, ConcreteType>();
    populateCacheWithBuiltinRules();
    try {
      workQueue.addLast(
          new InferenceWorkItem(element, new ConcreteTypesEnvironment()));
      while (!workQueue.isEmpty) {
        InferenceWorkItem item = workQueue.removeFirst();
        ConcreteType concreteType = analyze(item.method, item.environment);
        var template = cache[item.method];
        if (template[item.environment] == concreteType) continue;
        template[item.environment] = concreteType;
        final methodCallers = callers[item.method];
        if (methodCallers == null) continue;
        for (final caller in methodCallers) {
          final callerInstances = cache[caller];
          if (callerInstances != null) {
            callerInstances.forEach((environment, _) {
              workQueue.addLast(
                  new InferenceWorkItem(caller, environment));
            });
          }
        }
      }
    } on CancelTypeInferenceException catch(e) {
      if (LOG_FAILURES) {
        compiler.log("'${e.node}': ${e.reason}");
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
    return new ConcreteType.empty();
  }

  ConcreteType visitFor(For node) {
    if (node.initializer != null) {
      analyze(node.initializer);
    }
    analyze(node.conditionStatement);
    ConcreteType result = new ConcreteType.empty();
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
                                             : new ConcreteType.empty();
    environment = environment.join(snapshot);
    return thenType.union(elseType);
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
      BaseType baseReceiverType = new ClassBaseType(receiver.enclosingElement);
      inferrer.getSendReturnType(setter, baseReceiverType,
          new ArgumentsTypes([argumentType], new Map()));
    }
    return argumentType;
  }

  ConcreteType analyzeSetNode(Node receiver, ConcreteType argumentType,
                              SourceString source) {
    ConcreteType receiverType = analyze(receiver);

    void augmentField(BaseType baseReceiverType, Element fieldOrSetter) {
      if (fieldOrSetter.isField()) {
        inferrer.augmentFieldType(fieldOrSetter, argumentType);
      } else {
        AbstractFieldElement abstractField = fieldOrSetter;
        FunctionElement setter = abstractField.setter;
        // TODO(polux): A setter always returns void so there's no need to
        // invalidate its callers even if it is called with new arguments.
        // However, if we start to record more than returned types, like
        // exceptions for instance, we need to do it by uncommenting the
        // following line.
        // inferrer.addCaller(setter, currentMethod);
        inferrer.getSendReturnType(setter, baseReceiverType,
            new ArgumentsTypes([argumentType], new Map()));
      }
    }

    if (receiverType.isUnkown()) {
      for (Element member in inferrer.getMembersByName(source)) {
        Element classElem = member.getEnclosingClass();
        BaseType baseReceiverType = new ClassBaseType(classElem);
        augmentField(baseReceiverType, member);
      }
    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isClass()) continue;
        ClassBaseType baseReceiverClassType = baseReceiverType;
        Element member = baseReceiverClassType.element.lookupMember(source);
        if (member != null) {
          augmentField(baseReceiverClassType, member);
        }
      }
    }
    return argumentType;
  }

  SourceString canonicalizeCompoundOperator(String op) {
    // TODO(ahe): This class should work on elements or selectors, not
    // names.  Otherwise, it is repeating work the resolver has
    // already done (or should have done).  In this case, the problem
    // is that the resolver is not recording the selectors it is
    // registering in registerBinaryOperator in
    // ResolverVisitor.visitSendSet.
    if (op == '++') return const SourceString(r'+');
    else return const SourceString(r'-');
  }

  // TODO(polux): handle sendset as expression
  ConcreteType visitSendSet(SendSet node) {
    Identifier selector = node.selector;
    final name = node.assignmentOperator.source.stringValue;
    ConcreteType argumentType;
    if (name == '++' || name == '--') {
      ConcreteType receiverType = visitGetterSend(node);
      SourceString canonicalizedMethodName = canonicalizeCompoundOperator(name);
      List<ConcreteType> positionalArguments = <ConcreteType>[
          new ConcreteType.singleton(inferrer.baseTypes.intBaseType)];
      ArgumentsTypes argumentsTypes =
          new ArgumentsTypes(positionalArguments, new Map());
      argumentType = analyzeDynamicSend(receiverType, canonicalizedMethodName,
                                        argumentsTypes);
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
    return new ConcreteType.singleton(inferrer.baseTypes.intBaseType);
  }

  ConcreteType visitLiteralDouble(LiteralDouble node) {
    return new ConcreteType.singleton(inferrer.baseTypes.doubleBaseType);
  }

  ConcreteType visitLiteralBool(LiteralBool node) {
    return new ConcreteType.singleton(inferrer.baseTypes.boolBaseType);
  }

  ConcreteType visitLiteralString(LiteralString node) {
    // TODO(polux): get rid of this hack once we have a natural way of inferring
    // the unknown type.
    if (inferrer.testMode
        && node.dartString.slowToString() == "__dynamic_for_test") {
      return new ConcreteType.unknown();
    }
    return new ConcreteType.singleton(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitStringJuxtaposition(StringJuxtaposition node) {
    analyze(node.first);
    analyze(node.second);
    return new ConcreteType.singleton(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitLiteralNull(LiteralNull node) {
    return new ConcreteType.singleton(const NullBaseType());
  }

  ConcreteType visitNewExpression(NewExpression node) {
    Element constructor = elements[node.send];
    inferrer.addCaller(constructor, currentMethod);
    ClassElement cls = constructor.enclosingElement;
    return inferrer.getSendReturnType(constructor,
        new ClassBaseType(cls), analyzeArguments(node.send.arguments));
  }

  ConcreteType visitLiteralList(LiteralList node) {
    visitNodeList(node.elements);
    return new ConcreteType.singleton(inferrer.baseTypes.listBaseType);
  }

  ConcreteType visitNodeList(NodeList node) {
    ConcreteType type = new ConcreteType.empty();
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
        ? new ConcreteType.singleton(const NullBaseType())
        : analyze(expression);
  }

  ConcreteType visitThrow(Throw node) {
    if (node.expression != null) analyze(node.expression);
    return new ConcreteType.empty();
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
    return new ConcreteType.empty();
  }

  ConcreteType visitWhile(While node) {
    analyze(node.condition);
    ConcreteType result = new ConcreteType.empty();
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
    return thenType.union(elseType);
  }

  ConcreteType visitModifiers(Modifiers node) {
    inferrer.fail(node, 'not yet implemented');
  }

  ConcreteType visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return new ConcreteType.singleton(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitStringInterpolationPart(StringInterpolationPart node) {
    node.visitChildren(this);
    return new ConcreteType.singleton(inferrer.baseTypes.stringBaseType);
  }

  ConcreteType visitEmptyStatement(EmptyStatement node) {
    return new ConcreteType.empty();
  }

  ConcreteType visitBreakStatement(BreakStatement node) {
    return new ConcreteType.empty();
  }

  ConcreteType visitContinueStatement(ContinueStatement node) {
    // TODO(polux): we can be more precise
    return new ConcreteType.empty();
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
    return new ConcreteType.singleton(inferrer.baseTypes.mapBaseType);
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

  ConcreteType analyzeGetterSend(BaseType baseReceiverType,
                                 FunctionElement getter) {
      inferrer.addCaller(getter, currentMethod);
      return inferrer.getSendReturnType(getter,
                                        baseReceiverType,
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
          ClassBaseType baseReceiverType =
              new ClassBaseType(element.enclosingElement);
          return analyzeGetterSend(baseReceiverType, element);
        }
      }
    } else {
      // node is a field of not(this)
      assert(node.receiver != null);

      ConcreteType result = new ConcreteType.empty();
      void augmentResult(BaseType baseReceiverType, Element getterOrField) {
        if (getterOrField.isField()) {
          result = result.union(analyzeFieldRead(getterOrField));
        } else {
          // call to a getter
          AbstractFieldElement abstractField = getterOrField;
          result = result.union(analyzeGetterSend(baseReceiverType,
                                                  abstractField.getter));
        }
      }

      ConcreteType receiverType = analyze(node.receiver);
      if (receiverType.isUnkown()) {
        List<Element> members =
            inferrer.getMembersByName(node.selector.asIdentifier().source);
        for (final member in members) {
          Element classElement = member.getEnclosingClass();
          ClassBaseType baseReceiverType = new ClassBaseType(classElement);
          augmentResult(baseReceiverType, member);
        }
      } else {
        for (BaseType baseReceiverType in receiverType.baseTypes) {
          if (!baseReceiverType.isNull()) {
            ClassBaseType classBaseType = baseReceiverType;
            Element getterOrField = classBaseType.element
                .lookupMember(node.selector.asIdentifier().source);
            if (getterOrField != null) {
              augmentResult(baseReceiverType, getterOrField);
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

  // TODO(polux): handle unary operators and share this list with the rest of
  // dart2js.
  final Set<SourceString> operators = new Set<SourceString>()
      ..add(const SourceString('=='))
      ..add(const SourceString('!='))
      ..add(const SourceString('~'))
      ..add(const SourceString('[]'))
      ..add(const SourceString('[]='))
      ..add(const SourceString('*'))
      ..add(const SourceString('*='))
      ..add(const SourceString('/'))
      ..add(const SourceString('/='))
      ..add(const SourceString('%'))
      ..add(const SourceString('%='))
      ..add(const SourceString('~/'))
      ..add(const SourceString('~/='))
      ..add(const SourceString('+'))
      ..add(const SourceString('+='))
      ..add(const SourceString('-'))
      ..add(const SourceString('-='))
      ..add(const SourceString('<<'))
      ..add(const SourceString('<<='))
      ..add(const SourceString('>>'))
      ..add(const SourceString('>>='))
      ..add(const SourceString('>='))
      ..add(const SourceString('>'))
      ..add(const SourceString('<='))
      ..add(const SourceString('<'))
      ..add(const SourceString('&'))
      ..add(const SourceString('&='))
      ..add(const SourceString('^'))
      ..add(const SourceString('^='))
      ..add(const SourceString('|'))
      ..add(const SourceString('|='));

  SourceString canonicalizeMethodName(SourceString s) {
    return operators.contains(s)
        ? Elements.constructOperatorName(s, false)
        : s;
  }

  ConcreteType analyzeDynamicSend(ConcreteType receiverType,
                                  SourceString canonicalizedMethodName,
                                  ArgumentsTypes argumentsTypes) {
    ConcreteType result = new ConcreteType.empty();

    if (receiverType.isUnkown()) {
      List<Element> methods =
          inferrer.getMembersByName(canonicalizedMethodName);
      for (Element element in methods) {
        // TODO(polux): when we handle closures, we must handle sends to fields
        // that are closures.
        if (!element.isFunction()) continue;
        FunctionElement method = element;
        inferrer.addCaller(method, currentMethod);
        Element classElem = method.enclosingElement;
        ClassBaseType baseReceiverType = new ClassBaseType(classElem);
        result = result.union(
          inferrer.getSendReturnType(method, baseReceiverType, argumentsTypes));
      }

    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseReceiverType = baseReceiverType;
          FunctionElement method = classBaseReceiverType.element.lookupMember(
              canonicalizedMethodName);
          if (method != null) {
            inferrer.addCaller(method, currentMethod);
            result = result.union(inferrer.getSendReturnType(method,
                baseReceiverType, argumentsTypes));
          }
        }
      }
    }
    return result;
  }

  ConcreteType visitDynamicSend(Send node) {
    ConcreteType receiverType = (node.receiver != null)
        ? analyze(node.receiver)
        : new ConcreteType.singleton(
            new ClassBaseType(currentMethod.getEnclosingClass()));
    SourceString name =
        canonicalizeMethodName(node.selector.asIdentifier().source);
    ArgumentsTypes argumentsTypes = analyzeArguments(node.arguments);
    return analyzeDynamicSend(receiverType, name, argumentsTypes);
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
    return new ConcreteType.singleton(inferrer.baseTypes.typeBaseType);
  }
}
