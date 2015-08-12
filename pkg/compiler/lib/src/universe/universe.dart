// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import 'dart:collection';

import '../compiler.dart' show
    Compiler;
import '../diagnostics/invariant.dart' show
    invariant;
import '../diagnostics/spannable.dart' show
    SpannableAssertionFailure;
import '../elements/elements.dart';
import '../dart_types.dart';
import '../types/types.dart';
import '../tree/tree.dart';
import '../util/util.dart';
import '../world.dart' show
    ClassWorld,
    World;

part 'function_set.dart';
part 'side_effects.dart';

class UniverseSelector {
  final Selector selector;
  final TypeMask mask;

  UniverseSelector(this.selector, this.mask);

  bool appliesUnnamed(Element element, ClassWorld world) {
    return selector.appliesUnnamed(element, world) &&
        (mask == null || mask.canHit(element, selector, world));
  }

  String toString() => '$selector,$mask';
}

abstract class TypeMaskSet {
  bool applies(Element element, Selector selector, ClassWorld world);
  Iterable<TypeMask> get masks;
}

/// An implementation of a [TypeMaskSet] that is only increasing, that is, once
/// a mask is added it cannot be removed.
class IncreasingTypeMaskSet extends TypeMaskSet {
  bool isAll = false;
  Set<TypeMask> _masks;

  bool applies(Element element, Selector selector, ClassWorld world) {
    if (isAll) return true;
    if (_masks == null) return false;
    for (TypeMask mask in _masks) {
      if (mask.canHit(element, selector, world)) return true;
    }
    return false;
  }

  bool add(TypeMask mask) {
    if (isAll) return false;
    if (mask == null) {
      isAll = true;
      _masks = null;
      return true;
    }
    if (_masks == null) {
      _masks = new Setlet<TypeMask>();
    }
    return _masks.add(mask);
  }

  Iterable<TypeMask> get masks {
    if (isAll) return const [null];
    if (_masks == null) return const [];
    return _masks;
  }

  String toString() {
    if (isAll) {
      return '<all>';
    } else if (_masks != null) {
      return '$_masks';
    } else {
      return '<none>';
    }
  }
}



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

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<FieldElement> allReferencedStaticFields = new Set<FieldElement>();

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> staticFunctionsNeedingGetter =
      new Set<FunctionElement>();
  final Set<FunctionElement> methodsNeedingSuperGetter =
      new Set<FunctionElement>();
  final Map<String, Map<Selector, TypeMaskSet>> _invokedNames =
      <String, Map<Selector, TypeMaskSet>>{};
  final Map<String, Map<Selector, TypeMaskSet>> _invokedGetters =
      <String, Map<Selector, TypeMaskSet>>{};
  final Map<String, Map<Selector, TypeMaskSet>> _invokedSetters =
      <String, Map<Selector, TypeMaskSet>>{};

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

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get directlyInstantiatedClasses {
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
  /// See [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<DartType> get instantiatedTypes => _instantiatedTypes;

  /// Returns `true` if [cls] is considered to be instantiated, either directly,
  /// through subclasses or through subtypes. The latter case only contains
  /// spurious information from instatiations through factory constructors and
  /// mixins.
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

  bool _hasMatchingSelector(Map<Selector, TypeMaskSet> selectors,
                            Element member,
                            World world) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member, world)) {
        TypeMaskSet masks = selectors[selector];
        if (masks.applies(member, selector, world)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasInvocation(Element member, World world) {
    return _hasMatchingSelector(_invokedNames[member.name], member, world);
  }

  bool hasInvokedGetter(Element member, World world) {
    return _hasMatchingSelector(_invokedGetters[member.name], member, world);
  }

  bool hasInvokedSetter(Element member, World world) {
    return _hasMatchingSelector(_invokedSetters[member.name], member, world);
  }

  bool registerInvocation(UniverseSelector selector) {
    return _registerNewSelector(selector, _invokedNames);
  }

  bool registerInvokedGetter(UniverseSelector selector) {
    return _registerNewSelector(selector, _invokedGetters);
  }

  bool registerInvokedSetter(UniverseSelector selector) {
    return _registerNewSelector(selector, _invokedSetters);
  }

  bool _registerNewSelector(
      UniverseSelector universeSelector,
      Map<String, Map<Selector, TypeMaskSet>> selectorMap) {
    Selector selector = universeSelector.selector;
    String name = selector.name;
    TypeMask mask = universeSelector.mask;
    Map<Selector, TypeMaskSet> selectors = selectorMap.putIfAbsent(
        name, () => new Maplet<Selector, TypeMaskSet>());
    IncreasingTypeMaskSet masks = selectors.putIfAbsent(
        selector, () => new IncreasingTypeMaskSet());
    return masks.add(mask);
  }

  Map<Selector, TypeMaskSet> _asUnmodifiable(Map<Selector, TypeMaskSet> map) {
    if (map == null) return null;
    return new UnmodifiableMapView(map);
  }

  Map<Selector, TypeMaskSet> invocationsByName(String name) {
    return _asUnmodifiable(_invokedNames[name]);
  }

  Map<Selector, TypeMaskSet> getterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedGetters[name]);
  }

  Map<Selector, TypeMaskSet> setterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedSetters[name]);
  }

  void forEachInvokedName(
      f(String name, Map<Selector, TypeMaskSet> selectors)) {
    _invokedNames.forEach(f);
  }

  void forEachInvokedGetter(
      f(String name, Map<Selector, TypeMaskSet> selectors)) {
    _invokedGetters.forEach(f);
  }

  void forEachInvokedSetter(
      f(String name, Map<Selector, TypeMaskSet> selectors)) {
    _invokedSetters.forEach(f);
  }

  DartType registerIsCheck(DartType type, Compiler compiler) {
    type = type.unalias(compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    isChecks.add(type);
    return type;
  }

  void registerStaticFieldUse(FieldElement staticField) {
    assert(Elements.isStaticOrTopLevel(staticField) && staticField.isField);
    assert(staticField.isDeclaration);

    allReferencedStaticFields.add(staticField);
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

/// The structure of the arguments at a call-site.
// TODO(johnniwinther): Should these be cached?
// TODO(johnniwinther): Should isGetter/isSetter be part of the call structure
// instead of the selector?
class CallStructure {
  static const CallStructure NO_ARGS = const CallStructure.unnamed(0);
  static const CallStructure ONE_ARG = const CallStructure.unnamed(1);
  static const CallStructure TWO_ARGS = const CallStructure.unnamed(2);

  /// The numbers of arguments of the call. Includes named arguments.
  final int argumentCount;

  /// The number of named arguments of the call.
  int get namedArgumentCount => 0;

  /// The number of positional argument of the call.
  int get positionalArgumentCount => argumentCount;

  const CallStructure.unnamed(this.argumentCount);

  factory CallStructure(int argumentCount, [List<String> namedArguments]) {
    if (namedArguments == null || namedArguments.isEmpty) {
      return new CallStructure.unnamed(argumentCount);
    }
    return new NamedCallStructure(argumentCount, namedArguments);
  }

  /// `true` if this call has named arguments.
  bool get isNamed => false;

  /// `true` if this call has no named arguments.
  bool get isUnnamed => true;

  /// The names of the named arguments in call-site order.
  List<String> get namedArguments => const <String>[];

  /// The names of the named arguments in canonicalized order.
  List<String> getOrderedNamedArguments() => const <String>[];

  /// A description of the argument structure.
  String structureToString() => 'arity=$argumentCount';

  String toString() => 'CallStructure(${structureToString()})';

  Selector get callSelector {
    return new Selector(SelectorKind.CALL, Selector.CALL_NAME, this);
  }

  bool match(CallStructure other) {
    if (identical(this, other)) return true;
    return this.argumentCount == other.argumentCount
        && this.namedArgumentCount == other.namedArgumentCount
        && sameNames(this.namedArguments, other.namedArguments);
  }

  // TODO(johnniwinther): Cache hash code?
  int get hashCode {
    return Hashing.listHash(namedArguments,
        Hashing.objectHash(argumentCount, namedArguments.length));
  }

  bool operator ==(other) {
    if (other is! CallStructure) return false;
    return match(other);
  }

  bool signatureApplies(FunctionSignature parameters) {
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

  /**
   * Returns a `List` with the evaluated arguments in the normalized order.
   *
   * [compileDefaultValue] is a function that returns a compiled constant
   * of an optional argument that is not in [compiledArguments].
   *
   * Precondition: `this.applies(element, world)`.
   *
   * Invariant: [element] must be the implementation element.
   */
  /*<T>*/ List/*<T>*/ makeArgumentsList(
      Link<Node> arguments,
      FunctionElement element,
      /*T*/ compileArgument(Node argument),
      /*T*/ compileDefaultValue(ParameterElement element)) {
    assert(invariant(element, element.isImplementation));
    List/*<T>*/ result = new List();

    FunctionSignature parameters = element.functionSignature;
    parameters.forEachRequiredParameter((ParameterElement element) {
      result.add(compileArgument(arguments.head));
      arguments = arguments.tail;
    });

    if (!parameters.optionalParametersAreNamed) {
      parameters.forEachOptionalParameter((ParameterElement element) {
        if (!arguments.isEmpty) {
          result.add(compileArgument(arguments.head));
          arguments = arguments.tail;
        } else {
          result.add(compileDefaultValue(element));
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
          result.add(compiledNamedArguments[foundIndex]);
        } else {
          result.add(compileDefaultValue(element));
        }
      });
    }
    return result;
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
  static /*<T>*/ bool addForwardingElementArgumentsToList(
      ConstructorElement caller,
      List/*<T>*/ list,
      ConstructorElement callee,
      /*T*/ compileArgument(ParameterElement element),
      /*T*/ compileConstant(ParameterElement element)) {
    assert(invariant(caller, !callee.isErroneous,
        message: "Cannot compute arguments to erroneous constructor: "
                 "$caller calling $callee."));

    FunctionSignature signature = caller.functionSignature;
    Map<Node, ParameterElement> mapping = <Node, ParameterElement>{};

    // TODO(ngeoffray): This is a hack that fakes up AST nodes, so
    // that we can call [addArgumentsToList].
    Link<Node> computeCallNodesFromParameters() {
      LinkBuilder<Node> builder = new LinkBuilder<Node>();
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

    /*T*/ internalCompileArgument(Node node) {
      return compileArgument(mapping[node]);
    }

    Link<Node> nodes = computeCallNodesFromParameters();

    // Synthesize a structure for the call.
    // TODO(ngeoffray): Should the resolver do it instead?
    List<String> namedParameters;
    if (signature.optionalParametersAreNamed) {
      namedParameters =
          signature.optionalParameters.map((e) => e.name).toList();
    }
    CallStructure callStructure =
        new CallStructure(signature.parameterCount, namedParameters);
    if (!callStructure.signatureApplies(signature)) {
      return false;
    }
    list.addAll(callStructure.makeArgumentsList(
        nodes,
        callee,
        internalCompileArgument,
        compileConstant));

    return true;
  }

  static bool sameNames(List<String> first, List<String> second) {
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}

///
class NamedCallStructure extends CallStructure {
  final List<String> namedArguments;
  final List<String> _orderedNamedArguments = <String>[];

  NamedCallStructure(int argumentCount, this.namedArguments)
      : super.unnamed(argumentCount) {
    assert(namedArguments.isNotEmpty);
  }

  @override
  bool get isNamed => true;

  @override
  bool get isUnnamed => false;

  @override
  int get namedArgumentCount => namedArguments.length;

  @override
  int get positionalArgumentCount => argumentCount - namedArgumentCount;

  @override
  List<String> getOrderedNamedArguments() {
    if (!_orderedNamedArguments.isEmpty) return _orderedNamedArguments;

    _orderedNamedArguments.addAll(namedArguments);
    _orderedNamedArguments.sort((String first, String second) {
      return first.compareTo(second);
    });
    return _orderedNamedArguments;
  }

  @override
  String structureToString() {
    return 'arity=$argumentCount, named=[${namedArguments.join(', ')}]';
  }
}

class Selector {
  final SelectorKind kind;
  final Name memberName;
  final CallStructure callStructure;

  final int hashCode;

  int get argumentCount => callStructure.argumentCount;
  int get namedArgumentCount => callStructure.namedArgumentCount;
  int get positionalArgumentCount => callStructure.positionalArgumentCount;
  List<String> get namedArguments => callStructure.namedArguments;

  String get name => memberName.text;

  LibraryElement get library => memberName.library;

  static const Name INDEX_NAME = const PublicName("[]");
  static const Name INDEX_SET_NAME = const PublicName("[]=");
  static const Name CALL_NAME = const PublicName(Compiler.CALL_OPERATOR_NAME);

  Selector.internal(this.kind,
                    this.memberName,
                    this.callStructure,
                    this.hashCode) {
    assert(kind == SelectorKind.INDEX ||
           (memberName != INDEX_NAME && memberName != INDEX_SET_NAME));
    assert(kind == SelectorKind.OPERATOR ||
           kind == SelectorKind.INDEX ||
           !Elements.isOperatorName(memberName.text) ||
           identical(memberName.text, '??'));
    assert(kind == SelectorKind.CALL ||
           kind == SelectorKind.GETTER ||
           kind == SelectorKind.SETTER ||
           Elements.isOperatorName(memberName.text) ||
           identical(memberName.text, '??'));
  }

  // TODO(johnniwinther): Extract caching.
  static Map<int, List<Selector>> canonicalizedValues =
      new Map<int, List<Selector>>();

  factory Selector(SelectorKind kind,
                   Name name,
                   CallStructure callStructure) {
    // TODO(johnniwinther): Maybe use equality instead of implicit hashing.
    int hashCode = computeHashCode(kind, name, callStructure);
    List<Selector> list = canonicalizedValues.putIfAbsent(hashCode,
        () => <Selector>[]);
    for (int i = 0; i < list.length; i++) {
      Selector existing = list[i];
      if (existing.match(kind, name, callStructure)) {
        assert(existing.hashCode == hashCode);
        return existing;
      }
    }
    Selector result = new Selector.internal(
        kind, name, callStructure, hashCode);
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
            SelectorKind.OPERATOR,
            new PublicName(name),
            new CallStructure(arity, namedArguments));
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
    } else if (element.isConstructor) {
      return new Selector.callConstructor(name, element.library);
    } else {
      throw new SpannableAssertionFailure(
          element, "Can't get selector from $element");
    }
  }

  factory Selector.getter(String name, LibraryElement library)
      => new Selector(SelectorKind.GETTER,
                      new Name(name, library),
                      CallStructure.NO_ARGS);

  factory Selector.getterFrom(Selector selector)
      => new Selector(SelectorKind.GETTER,
                      selector.memberName.getter,
                      CallStructure.NO_ARGS);

  factory Selector.setter(String name, LibraryElement library)
      => new Selector(SelectorKind.SETTER,
                      new Name(name, library, isSetter: true),
                      CallStructure.ONE_ARG);

  factory Selector.unaryOperator(String name) => new Selector(
      SelectorKind.OPERATOR,
      new PublicName(Elements.constructOperatorName(name, true)),
      CallStructure.NO_ARGS);

  factory Selector.binaryOperator(String name) => new Selector(
      SelectorKind.OPERATOR,
      new PublicName(Elements.constructOperatorName(name, false)),
      CallStructure.ONE_ARG);

  factory Selector.index()
      => new Selector(SelectorKind.INDEX, INDEX_NAME,
                      CallStructure.ONE_ARG);

  factory Selector.indexSet()
      => new Selector(SelectorKind.INDEX, INDEX_SET_NAME,
                      CallStructure.TWO_ARGS);

  factory Selector.call(String name,
                        LibraryElement library,
                        int arity,
                        [List<String> namedArguments])
      => new Selector(SelectorKind.CALL,
          new Name(name, library),
          new CallStructure(arity, namedArguments));

  factory Selector.callClosure(int arity, [List<String> namedArguments])
      => new Selector(SelectorKind.CALL, CALL_NAME,
                      new CallStructure(arity, namedArguments));

  factory Selector.callClosureFrom(Selector selector)
      => new Selector(SelectorKind.CALL, CALL_NAME, selector.callStructure);

  factory Selector.callConstructor(String name, LibraryElement library,
                                   [int arity = 0,
                                    List<String> namedArguments])
      => new Selector(SelectorKind.CALL, new Name(name, library),
                      new CallStructure(arity, namedArguments));

  factory Selector.callDefaultConstructor()
      => new Selector(
          SelectorKind.CALL,
          const PublicName(''),
          CallStructure.NO_ARGS);

  bool get isGetter => kind == SelectorKind.GETTER;
  bool get isSetter => kind == SelectorKind.SETTER;
  bool get isCall => kind == SelectorKind.CALL;
  bool get isClosureCall => isCall && memberName == CALL_NAME;

  bool get isIndex => kind == SelectorKind.INDEX && argumentCount == 1;
  bool get isIndexSet => kind == SelectorKind.INDEX && argumentCount == 2;

  bool get isOperator => kind == SelectorKind.OPERATOR;
  bool get isUnaryOperator => isOperator && argumentCount == 0;

  /** Check whether this is a call to 'assert'. */
  bool get isAssert => isCall && identical(name, "assert");

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
    if (memberName.isPrivate && memberName.library != element.library) {
      // TODO(johnniwinther): Maybe this should be
      // `memberName != element.memberName`.
      return false;
    }
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
    if (Elements.isUnresolved(function)) return false;
    return callStructure.signatureApplies(function.functionSignature);
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

  bool match(SelectorKind kind,
             Name memberName,
             CallStructure callStructure) {
    return this.kind == kind
        && this.memberName == memberName
        && this.callStructure.match(callStructure);
  }

  static int computeHashCode(SelectorKind kind,
                             Name name,
                             CallStructure callStructure) {
    // Add bits from name and kind.
    int hash = Hashing.mixHashCodeBits(name.hashCode, kind.hashCode);
    // Add bits from the call structure.
    return Hashing.mixHashCodeBits(hash, callStructure.hashCode);
  }

  String toString() {
    return 'Selector($kind, $name, ${callStructure.structureToString()})';
  }

  Selector toCallSelector() => new Selector.callClosureFrom(this);
}
