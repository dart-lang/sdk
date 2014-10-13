// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../types/types.dart';
import '../tree/tree.dart';
import '../util/util.dart';

part 'function_set.dart';
part 'side_effects.dart';

class Universe {
  /// The set of all directly instantiated classes, that is, classes with a
  /// generative constructor that has been called directly and not only through
  /// a super-call.
  ///
  /// Invariant: Elements are declaration elements.
  // TODO(johnniwinther): [_directlyInstantiatedClasses] and
  // [_instantiatedTypes] sets should be merged.
  final Set<ClassElement> _directlyInstantiatedClasses =
      new Set<ClassElement>();

  /// The set of all directly instantiated types, that is, the types of the
  /// directly instantiated classes.
  ///
  /// See [_directlyInstantiatedClasses].
  final Set<DartType> _instantiatedTypes = new Set<DartType>();

  /// The set of all instantiated classes, either directly, as superclasses or
  /// as supertypes.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<ClassElement> _allInstantiatedClasses = new Set<ClassElement>();

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> staticFunctionsNeedingGetter =
      new Set<FunctionElement>();
  final Set<FunctionElement> methodsNeedingSuperGetter =
      new Set<FunctionElement>();
  final Map<String, Set<Selector>> invokedNames =
      new Map<String, Set<Selector>>();
  final Map<String, Set<Selector>> invokedGetters =
      new Map<String, Set<Selector>>();
  final Map<String, Set<Selector>> invokedSetters =
      new Map<String, Set<Selector>>();

  /**
   * Fields accessed. Currently only the codegen knows this
   * information. The resolver is too conservative when seeing a
   * getter and only registers an invoked getter.
   */
  final Set<Element> fieldGetters = new Set<Element>();

  /**
   * Fields set. See comment in [fieldGetters].
   */
  final Set<Element> fieldSetters = new Set<Element>();
  final Set<DartType> isChecks = new Set<DartType>();

  /**
   * Set of (live) [:call:] methods whose signatures reference type variables.
   *
   * A live [:call:] method is one whose enclosing class has been instantiated.
   */
  final Set<Element> callMethodsWithFreeTypeVariables = new Set<Element>();

  /**
   * Set of (live) local functions (closures) whose signatures reference type
   * variables.
   *
   * A live function is one whose enclosing member function has been enqueued.
   */
  final Set<Element> closuresWithFreeTypeVariables = new Set<Element>();

  /**
   * Set of all closures in the program. Used by the mirror tracking system
   * to find all live closure instances.
   */
  final Set<LocalFunctionElement> allClosures = new Set<LocalFunctionElement>();

  /**
   * Set of methods in instantiated classes that are potentially
   * closurized.
   */
  final Set<Element> closurizedMembers = new Set<Element>();

  bool usingFactoryWithTypeArguments = false;

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get instantiatedClasses {
    return _directlyInstantiatedClasses;
  }

  /// All instantiated classes, either directly, as superclasses or as
  /// supertypes.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get allInstantiatedClasses {
    return _allInstantiatedClasses;
  }

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  ///
  /// See [instantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<DartType> get instantiatedTypes => _instantiatedTypes;

  /// Returns `true` if [cls] is considered to be instantiated, either directly,
  /// through subclasses or throught subtypes.
  // TODO(johnniwinther): Improve semantic precision.
  bool isInstantiated(ClassElement cls) {
    return _allInstantiatedClasses.contains(cls);
  }

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(InterfaceType type,
                                 {bool byMirrors: false}) {
    _instantiatedTypes.add(type);
    ClassElement cls = type.element;
    if (!cls.isAbstract
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        || cls.isNative
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors seperately.
        || byMirrors) {
      _directlyInstantiatedClasses.add(cls);
    }

    // TODO(johnniwinther): Replace this by separate more specific mappings.
    if (!_allInstantiatedClasses.add(cls)) return;
    cls.allSupertypes.forEach((InterfaceType supertype) {
      _allInstantiatedClasses.add(supertype.element);
    });
  }

  bool hasMatchingSelector(Set<Selector> selectors,
                           Element member,
                           World world) {
    if (selectors == null) return false;
    for (Selector selector in selectors) {
      if (selector.appliesUnnamed(member, world)) return true;
    }
    return false;
  }

  bool hasInvocation(Element member, World world) {
    return hasMatchingSelector(invokedNames[member.name], member, world);
  }

  bool hasInvokedGetter(Element member, World world) {
    return hasMatchingSelector(invokedGetters[member.name], member, world);
  }

  bool hasInvokedSetter(Element member, World world) {
    return hasMatchingSelector(invokedSetters[member.name], member, world);
  }

  DartType registerIsCheck(DartType type, Compiler compiler) {
    type = type.unalias(compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    isChecks.add(type);
    return type;
  }

  void forgetElement(Element element, Compiler compiler) {
    allClosures.remove(element);
    slowDirectlyNestedClosures(element).forEach(compiler.forgetElement);
    closurizedMembers.remove(element);
    fieldSetters.remove(element);
    fieldGetters.remove(element);
    _directlyInstantiatedClasses.remove(element);
    _allInstantiatedClasses.remove(element);
    if (element is ClassElement) {
      assert(invariant(
          element, element.thisType.isRaw,
          message: 'Generic classes not supported (${element.thisType}).'));
      _instantiatedTypes
          ..remove(element.rawType)
          ..remove(element.thisType);
    }
  }

  // TODO(ahe): Replace this method with something that is O(1), for example,
  // by using a map.
  List<LocalFunctionElement> slowDirectlyNestedClosures(Element element) {
    // Return new list to guard against concurrent modifications.
    return new List<LocalFunctionElement>.from(
        allClosures.where((LocalFunctionElement closure) {
          return closure.executableContext == element;
        }));
  }
}

class SelectorKind {
  final String name;
  final int hashCode;
  const SelectorKind(this.name, this.hashCode);

  static const SelectorKind GETTER = const SelectorKind('getter', 0);
  static const SelectorKind SETTER = const SelectorKind('setter', 1);
  static const SelectorKind CALL = const SelectorKind('call', 2);
  static const SelectorKind OPERATOR = const SelectorKind('operator', 3);
  static const SelectorKind INDEX = const SelectorKind('index', 4);

  String toString() => name;
}

class Selector {
  final SelectorKind kind;
  final String name;
  final LibraryElement library; // Library is null for non-private selectors.

  // The numbers of arguments of the selector. Includes named arguments.
  final int argumentCount;
  final List<String> namedArguments;
  final List<String> _orderedNamedArguments;
  final int hashCode;

  static const String INDEX_NAME ="[]";
  static const String INDEX_SET_NAME = "[]=";
  static const String CALL_NAME = Compiler.CALL_OPERATOR_NAME;

  Selector.internal(this.kind,
                    this.name,
                    this.library,
                    this.argumentCount,
                    this.namedArguments,
                    this._orderedNamedArguments,
                    this.hashCode) {
    assert(kind == SelectorKind.INDEX
           || (name != INDEX_NAME && name != INDEX_SET_NAME));
    assert(kind == SelectorKind.OPERATOR
           || kind == SelectorKind.INDEX
           || !Elements.isOperatorName(name));
    assert(kind == SelectorKind.CALL
           || kind == SelectorKind.GETTER
           || kind == SelectorKind.SETTER
           || Elements.isOperatorName(name));
    assert(!isPrivateName(name) || library != null);
  }

  static Map<int, List<Selector>> canonicalizedValues =
      new Map<int, List<Selector>>();

  factory Selector(SelectorKind kind,
                   String name,
                   LibraryElement library,
                   int argumentCount,
                   [List<String> namedArguments]) {
    if (!isPrivateName(name)) library = null;
    if (namedArguments == null) namedArguments = const <String>[];
    int hashCode = computeHashCode(
        kind, name, library, argumentCount, namedArguments);
    List<Selector> list = canonicalizedValues.putIfAbsent(hashCode,
        () => <Selector>[]);
    for (int i = 0; i < list.length; i++) {
      Selector existing = list[i];
      if (existing.match(kind, name, library, argumentCount, namedArguments)) {
        assert(existing.hashCode == hashCode);
        assert(existing.mask == null);
        return existing;
      }
    }
    List<String> orderedNamedArguments = namedArguments.isEmpty
        ? const <String>[]
        : <String>[];
    Selector result = new Selector.internal(
        kind, name, library, argumentCount,
        namedArguments, orderedNamedArguments,
        hashCode);
    list.add(result);
    return result;
  }

  factory Selector.fromElement(Element element) {
    String name = element.name;
    if (element.isFunction) {
      if (name == '[]') {
        return new Selector.index();
      } else if (name == '[]=') {
        return new Selector.indexSet();
      }
      FunctionSignature signature =
          element.asFunctionElement().functionSignature;
      int arity = signature.parameterCount;
      List<String> namedArguments = null;
      if (signature.optionalParametersAreNamed) {
        namedArguments =
            signature.orderedOptionalParameters.map((e) => e.name).toList();
      }
      if (element.isOperator) {
        // Operators cannot have named arguments, however, that doesn't prevent
        // a user from declaring such an operator.
        return new Selector(
            SelectorKind.OPERATOR, name, null, arity, namedArguments);
      } else {
        return new Selector.call(
            name, element.library, arity, namedArguments);
      }
    } else if (element.isSetter) {
      return new Selector.setter(name, element.library);
    } else if (element.isGetter) {
      return new Selector.getter(name, element.library);
    } else if (element.isField) {
      return new Selector.getter(name, element.library);
    } else {
      throw new SpannableAssertionFailure(
          element, "Can't get selector from $element");
    }
  }

  factory Selector.getter(String name, LibraryElement library)
      => new Selector(SelectorKind.GETTER, name, library, 0);

  factory Selector.getterFrom(Selector selector)
      => new Selector(SelectorKind.GETTER, selector.name, selector.library, 0);

  factory Selector.setter(String name, LibraryElement library)
      => new Selector(SelectorKind.SETTER, name, library, 1);

  factory Selector.unaryOperator(String name)
      => new Selector(SelectorKind.OPERATOR,
                      Elements.constructOperatorName(name, true),
                      null, 0);

  factory Selector.binaryOperator(String name)
      => new Selector(SelectorKind.OPERATOR,
                      Elements.constructOperatorName(name, false),
                      null, 1);

  factory Selector.index()
      => new Selector(SelectorKind.INDEX,
                      Elements.constructOperatorName(INDEX_NAME, false),
                      null, 1);

  factory Selector.indexSet()
      => new Selector(SelectorKind.INDEX,
                      Elements.constructOperatorName(INDEX_SET_NAME, false),
                      null, 2);

  factory Selector.call(String name,
                        LibraryElement library,
                        int arity,
                        [List<String> namedArguments])
      => new Selector(SelectorKind.CALL, name, library, arity, namedArguments);

  factory Selector.callClosure(int arity, [List<String> namedArguments])
      => new Selector(SelectorKind.CALL, CALL_NAME, null,
                      arity, namedArguments);

  factory Selector.callClosureFrom(Selector selector)
      => new Selector(SelectorKind.CALL, CALL_NAME, null,
                      selector.argumentCount, selector.namedArguments);

  factory Selector.callConstructor(String name, LibraryElement library,
                                   [int arity = 0,
                                    List<String> namedArguments])
      => new Selector(SelectorKind.CALL, name, library,
                      arity, namedArguments);

  factory Selector.callDefaultConstructor(LibraryElement library)
      => new Selector(SelectorKind.CALL, "", library, 0);

  bool get isGetter => identical(kind, SelectorKind.GETTER);
  bool get isSetter => identical(kind, SelectorKind.SETTER);
  bool get isCall => identical(kind, SelectorKind.CALL);
  bool get isClosureCall {
    String callName = Compiler.CALL_OPERATOR_NAME;
    return isCall && name == callName;
  }

  bool get isIndex => identical(kind, SelectorKind.INDEX) && argumentCount == 1;
  bool get isIndexSet => identical(kind, SelectorKind.INDEX) && argumentCount == 2;

  bool get isOperator => identical(kind, SelectorKind.OPERATOR);
  bool get isUnaryOperator => isOperator && argumentCount == 0;

  /** Check whether this is a call to 'assert'. */
  bool get isAssert => isCall && identical(name, "assert");

  int get namedArgumentCount => namedArguments.length;
  int get positionalArgumentCount => argumentCount - namedArgumentCount;

  bool get hasExactMask => false;
  TypeMask get mask => null;
  Selector get asUntyped => this;

  /**
   * The member name for invocation mirrors created from this selector.
   */
  String get invocationMirrorMemberName =>
      isSetter ? '$name=' : name;

  int get invocationMirrorKind {
    const int METHOD = 0;
    const int GETTER = 1;
    const int SETTER = 2;
    int kind = METHOD;
    if (isGetter) {
      kind = GETTER;
    } else if (isSetter) {
      kind = SETTER;
    }
    return kind;
  }

  bool appliesUnnamed(Element element, World world) {
    assert(sameNameHack(element, world));
    return appliesUntyped(element, world);
  }

  bool appliesUntyped(Element element, World world) {
    assert(sameNameHack(element, world));
    if (Elements.isUnresolved(element)) return false;
    if (isPrivateName(name) && library != element.library) return false;
    if (world.isForeign(element)) return true;
    if (element.isSetter) return isSetter;
    if (element.isGetter) return isGetter || isCall;
    if (element.isField) {
      return isSetter
          ? !element.isFinal && !element.isConst
          : isGetter || isCall;
    }
    if (isGetter) return true;
    if (isSetter) return false;
    return signatureApplies(element);
  }

  bool signatureApplies(FunctionElement function) {
    FunctionSignature parameters = function.functionSignature;
    if (argumentCount > parameters.parameterCount) return false;
    int requiredParameterCount = parameters.requiredParameterCount;
    int optionalParameterCount = parameters.optionalParameterCount;
    if (positionalArgumentCount < requiredParameterCount) return false;

    if (!parameters.optionalParametersAreNamed) {
      // We have already checked that the number of arguments are
      // not greater than the number of parameters. Therefore the
      // number of positional arguments are not greater than the
      // number of parameters.
      assert(positionalArgumentCount <= parameters.parameterCount);
      return namedArguments.isEmpty;
    } else {
      if (positionalArgumentCount > requiredParameterCount) return false;
      assert(positionalArgumentCount == requiredParameterCount);
      if (namedArgumentCount > optionalParameterCount) return false;
      Set<String> nameSet = new Set<String>();
      parameters.optionalParameters.forEach((Element element) {
        nameSet.add(element.name);
      });
      for (String name in namedArguments) {
        if (!nameSet.contains(name)) return false;
        // TODO(5213): By removing from the set we are checking
        // that we are not passing the name twice. We should have this
        // check in the resolver also.
        nameSet.remove(name);
      }
      return true;
    }
  }

  bool sameNameHack(Element element, World world) {
    // TODO(ngeoffray): Remove workaround checks.
    return element.isConstructor ||
           name == element.name ||
           name == 'assert' && world.isAssertMethod(element);
  }

  bool applies(Element element, World world) {
    if (!sameNameHack(element, world)) return false;
    return appliesUnnamed(element, world);
  }

  /**
   * Fills [list] with the arguments in the normalized order.
   *
   * [compileArgument] is a function that returns a compiled version
   * of an argument located in [arguments].
   *
   * [compileDefaultValue] is a function that returns a compiled constant
   * of an optional argument that is not in [arguments].
   *
   * Returns [:true:] if the selector and the [element] match; [:false:]
   * otherwise.
   *
   * Invariant: [element] must be the implementation element.
   */
  /*<T>*/ bool addArgumentsToList(
      Link<Node> arguments,
      List/*<T>*/ list,
      FunctionElement element,
      /*T*/ compileArgument(Node argument),
      /*T*/ compileDefaultValue(ParameterElement element),
      World world) {
    assert(invariant(element, element.isImplementation));
    if (!this.applies(element, world)) return false;

    FunctionSignature parameters = element.functionSignature;
    parameters.forEachRequiredParameter((ParameterElement element) {
      list.add(compileArgument(arguments.head));
      arguments = arguments.tail;
    });

    if (!parameters.optionalParametersAreNamed) {
      parameters.forEachOptionalParameter((ParameterElement element) {
        if (!arguments.isEmpty) {
          list.add(compileArgument(arguments.head));
          arguments = arguments.tail;
        } else {
          list.add(compileDefaultValue(element));
        }
      });
    } else {
      // Visit named arguments and add them into a temporary list.
      List compiledNamedArguments = [];
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        NamedArgument namedArgument = arguments.head;
        compiledNamedArguments.add(compileArgument(namedArgument.expression));
      }
      // Iterate over the optional parameters of the signature, and try to
      // find them in [compiledNamedArguments]. If found, we use the
      // value in the temporary list, otherwise the default value.
      parameters.orderedOptionalParameters.forEach((ParameterElement element) {
        int foundIndex = namedArguments.indexOf(element.name);
        if (foundIndex != -1) {
          list.add(compiledNamedArguments[foundIndex]);
        } else {
          list.add(compileDefaultValue(element));
        }
      });
    }
    return true;
  }

  /**
   * Fills [list] with the arguments in the order expected by
   * [callee], and where [caller] is a synthesized element
   *
   * [compileArgument] is a function that returns a compiled version
   * of a parameter of [callee].
   *
   * [compileConstant] is a function that returns a compiled constant
   * of an optional argument that is not in the parameters of [callee].
   *
   * Returns [:true:] if the signature of the [caller] matches the
   * signature of the [callee], [:false:] otherwise.
   */
  static bool addForwardingElementArgumentsToList(
      FunctionElement caller,
      List list,
      FunctionElement callee,
      compileArgument(Element element),
      compileConstant(Element element),
      World world) {

    FunctionSignature signature = caller.functionSignature;
    Map mapping = new Map();

    // TODO(ngeoffray): This is a hack that fakes up AST nodes, so
    // that we can call [addArgumentsToList].
    Link computeCallNodesFromParameters() {
      LinkBuilder builder = new LinkBuilder();
      signature.forEachRequiredParameter((ParameterElement element) {
        Node node = element.node;
        mapping[node] = element;
        builder.addLast(node);
      });
      if (signature.optionalParametersAreNamed) {
        signature.forEachOptionalParameter((ParameterElement element) {
          mapping[element.initializer] = element;
          builder.addLast(new NamedArgument(null, null, element.initializer));
        });
      } else {
        signature.forEachOptionalParameter((ParameterElement element) {
          Node node = element.node;
          mapping[node] = element;
          builder.addLast(node);
        });
      }
      return builder.toLink();
    }

    internalCompileArgument(Node node) {
      return compileArgument(mapping[node]);
    }

    Link<Node> nodes = computeCallNodesFromParameters();

    // Synthesize a selector for the call.
    // TODO(ngeoffray): Should the resolver do it instead?
    List<String> namedParameters;
    if (signature.optionalParametersAreNamed) {
      namedParameters =
          signature.optionalParameters.mapToList((e) => e.name);
    }
    Selector selector = new Selector.call(callee.name,
                                          caller.library,
                                          signature.parameterCount,
                                          namedParameters);

    return selector.addArgumentsToList(nodes,
                                       list,
                                       callee,
                                       internalCompileArgument,
                                       compileConstant,
                                       world);
  }

  static bool sameNames(List<String> first, List<String> second) {
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  bool match(SelectorKind kind,
             String name,
             LibraryElement library,
             int argumentCount,
             List<String> namedArguments) {
    return this.kind == kind
        && this.name == name
        && identical(this.library, library)
        && this.argumentCount == argumentCount
        && this.namedArguments.length == namedArguments.length
        && sameNames(this.namedArguments, namedArguments);
  }

  static int computeHashCode(SelectorKind kind,
                             String name,
                             LibraryElement library,
                             int argumentCount,
                             List<String> namedArguments) {
    // Add bits from name and kind.
    int hash = mixHashCodeBits(name.hashCode, kind.hashCode);
    // Add bits from the library.
    if (library != null) hash = mixHashCodeBits(hash, library.hashCode);
    // Add bits from the unnamed arguments.
    hash = mixHashCodeBits(hash, argumentCount);
    // Add bits from the named arguments.
    int named = namedArguments.length;
    hash = mixHashCodeBits(hash, named);
    for (int i = 0; i < named; i++) {
      hash = mixHashCodeBits(hash, namedArguments[i].hashCode);
    }
    return hash;
  }

  // TODO(kasperl): Move this out so it becomes useful in other places too?
  static int mixHashCodeBits(int existing, int value) {
    // Spread the bits of value. Try to stay in the 30-bit range to
    // avoid overflowing into a more expensive integer representation.
    int h = value & 0x1fffffff;
    h += ((h & 0x3fff) << 15) ^ 0x1fffcd7d;
    h ^= (h >> 10);
    h += ((h & 0x3ffffff) << 3);
    h ^= (h >> 6);
    h += ((h & 0x7ffffff) << 2) + ((h & 0x7fff) << 14);
    h ^= (h >> 16);
    // Combine the two hash values.
    int high = existing >> 15;
    int low = existing & 0x7fff;
    return ((high * 13) ^ (low * 997) ^ h) & SMI_MASK;
  }

  List<String> getOrderedNamedArguments() {
    if (namedArguments.isEmpty) return namedArguments;
    if (!_orderedNamedArguments.isEmpty) return _orderedNamedArguments;

    _orderedNamedArguments.addAll(namedArguments);
    _orderedNamedArguments.sort((String first, String second) {
      return first.compareTo(second);
    });
    return _orderedNamedArguments;
  }

  String namedArgumentsToString() {
    if (namedArgumentCount > 0) {
      StringBuffer result = new StringBuffer();
      for (int i = 0; i < namedArgumentCount; i++) {
        if (i != 0) result.write(', ');
        result.write(namedArguments[i]);
      }
      return "[$result]";
    }
    return '';
  }

  String toString() {
    String named = '';
    String type = '';
    if (namedArgumentCount > 0) named = ', named=${namedArgumentsToString()}';
    if (mask != null) type = ', mask=$mask';
    return 'Selector($kind, $name, '
           'arity=$argumentCount$named$type)';
  }

  Selector extendIfReachesAll(Compiler compiler) {
    return new TypedSelector(
        compiler.typesTask.dynamicType, this, compiler.world);
  }

  Selector toCallSelector() => new Selector.callClosureFrom(this);
}

class TypedSelector extends Selector {
  final Selector asUntyped;
  final TypeMask mask;

  TypedSelector.internal(this.mask, Selector selector, int hashCode)
      : asUntyped = selector,
        super.internal(selector.kind,
                       selector.name,
                       selector.library,
                       selector.argumentCount,
                       selector.namedArguments,
                       selector._orderedNamedArguments,
                       hashCode) {
    assert(mask != null);
    assert(asUntyped.mask == null);
  }

  static Map<Selector, Map<TypeMask, TypedSelector>> canonicalizedValues =
      new Map<Selector, Map<TypeMask, TypedSelector>>();

  factory TypedSelector(TypeMask mask, Selector selector, World world) {
    // TODO(johnniwinther): Allow more TypeSelector kinds during resoluton.
    assert(world.isClosed || mask.isExact);
    if (selector.mask == mask) return selector;
    Selector untyped = selector.asUntyped;
    Map<TypeMask, TypedSelector> map = canonicalizedValues.putIfAbsent(untyped,
        () => new Map<TypeMask, TypedSelector>());
    TypedSelector result = map[mask];
    if (result == null) {
      int hashCode = Selector.mixHashCodeBits(untyped.hashCode, mask.hashCode);
      result = map[mask] = new TypedSelector.internal(mask, untyped, hashCode);
    }
    return result;
  }

  factory TypedSelector.exact(
      ClassElement base, Selector selector, World world)
          => new TypedSelector(new TypeMask.exact(base, world), selector,
              world);

  factory TypedSelector.subclass(
      ClassElement base, Selector selector, World world)
          => new TypedSelector(new TypeMask.subclass(base, world),
                               selector, world);

  factory TypedSelector.subtype(
      ClassElement base, Selector selector, World world)
          => new TypedSelector(new TypeMask.subtype(base, world),
                               selector, world);

  bool appliesUnnamed(Element element, World world) {
    assert(sameNameHack(element, world));
    // [TypedSelector] are only used after resolution.
    if (!element.isClassMember) return false;

    // A closure can be called through any typed selector:
    // class A {
    //   get foo => () => 42;
    //   bar() => foo(); // The call to 'foo' is a typed selector.
    // }
    if (element.enclosingClass.isClosure) {
      return appliesUntyped(element, world);
    }

    if (!mask.canHit(element, this, world)) return false;
    return appliesUntyped(element, world);
  }

  Selector extendIfReachesAll(Compiler compiler) {
    bool canReachAll = compiler.enabledInvokeOn
        && mask.needsNoSuchMethodHandling(this, compiler.world);
    return canReachAll
        ? new TypedSelector(
            compiler.typesTask.dynamicType, this, compiler.world)
        : this;
  }
}
