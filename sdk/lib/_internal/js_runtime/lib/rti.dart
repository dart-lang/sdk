// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains support for runtime type information.
library rti;

import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JSArray, JSUnmodifiableArray;

/// An Rti object represents both a type (e.g `Map<int, String>`) and a type
/// environment (`Map<int, String>` binds `Map.K=int` and `Map.V=String`).
///
/// There is a single [Rti] class to help reduce polymorphism in the JavaScript
/// runtime. The class has a default constructor and no final fields so it can
/// be created before much of the runtime exists.
///
/// The fields are declared in an order that gets shorter minified names for the
/// more commonly used fields. (TODO: we should exploit the fact that an Rti
/// instance never appears in a dynamic context, so does not need field names to
/// be distinct from dynamic selectors).
///
class Rti {
  /// JavaScript method for 'as' check. The method is called from generated code,
  /// e.g. `o as T` generates something like `rtiForT._as(o)`.
  @pragma('dart2js:noElision')
  dynamic _as;

  /// JavaScript method for type check.  The method is called from generated
  /// code, e.g. parameter check for `T param` generates something like
  /// `rtiForT._check(param)`.
  @pragma('dart2js:noElision')
  dynamic _check;

  /// JavaScript method for 'is' test.  The method is called from generated
  /// code, e.g. `o is T` generates something like `rtiForT._is(o)`.
  @pragma('dart2js:noElision')
  dynamic _is;

  static void _setAsCheckFunction(Rti rti, fn) {
    rti._as = fn;
  }

  static void _setTypeCheckFunction(Rti rti, fn) {
    rti._check = fn;
  }

  static void _setIsTestFunction(Rti rti, fn) {
    rti._is = fn;
  }

  /// Method called from generated code to evaluate a type environment recipe in
  /// `this` type environment.
  Rti _eval(String recipe) => _rtiEval(this, recipe);

  /// Method called from generated code to extend `this` type environment (an
  /// interface or binding Rti) with function type arguments (a singleton
  /// argument or tuple of arguments).
  Rti _bind(Rti typeOrTuple) => _rtiBind(this, typeOrTuple);

  /// Method called from generated code to extend `this` type (as a singleton
  /// type environment) with function type arguments (a singleton argument or
  /// tuple of arguments).
  Rti _bind1(Rti typeOrTuple) => _rtiBind1(this, typeOrTuple);

  // Precomputed derived types. These fields are used to hold derived types that
  // are computed eagerly.
  // TODO(sra): Implement precomputed type optimizations.
  dynamic _precomputed1;
  dynamic _precomputed2;
  dynamic _precomputed3;
  dynamic _precomputed4;

  // The Type object corresponding to this Rti.
  Type _typeCache;

  /// The kind of Rti `this` is, one of the kindXXX constants below.
  ///
  /// We don't use an enum since we need to create Rti objects very early.
  ///
  /// The zero initializer ensures dart2js type analysis considers [_kind] is
  /// non-nullable.
  int _kind = 0;

  static int _getKind(Rti rti) => rti._kind;
  static void _setKind(Rti rti, int kind) {
    rti._kind = kind;
  }

  // Terminal terms.
  static const kindNever = 1;
  static const kindDynamic = 2;
  static const kindVoid = 3; // TODO(sra): Use `dynamic` instead?
  static const kindAny = 4; // Dart1-style 'dynamic' for JS-interop.
  // Unary terms.
  static const kindStar = 5;
  static const kindQuestion = 6;
  static const kindFutureOr = 7;
  // More complex terms.
  static const kindInterface = 8;
  // A vector of type parameters from enclosing functions and closures.
  static const kindBinding = 9;
  static const kindFunction = 10;
  static const kindGenericFunction = 11;
  static const kindGenericFunctionParameter = 12;

  /// Primary data associated with type.
  ///
  /// - Minified name of interface for interface types.
  /// - Underlying type for unary terms.
  /// - Class part of a type environment inside a generic class, or `null` for
  ///   type tuple.
  /// - Return type of function types.
  dynamic _primary;

  static Object _getPrimary(Rti rti) => rti._primary;
  static void _setPrimary(Rti rti, value) {
    rti._primary = value;
  }

  /// Additional data associated with type.
  ///
  /// - The type arguments of an interface type.
  /// - The type arguments from enclosing functions and closures for a
  ///   kindBinding.
  /// - TBD for kindFunction and kindGenericFunction.
  dynamic _rest;

  static Object _getRest(Rti rti) => rti._rest;
  static void _setRest(Rti rti, value) {
    rti._rest = value;
  }

  static String _getInterfaceName(Rti rti) {
    assert(_getKind(rti) == kindInterface);
    return _Utils.asString(_getPrimary(rti));
  }

  static JSArray _getInterfaceTypeArguments(rti) {
    // The array is a plain JavaScript Array, otherwise we would need the type
    // `JSArray<Rti>` to exist before we could create the type `JSArray<Rti>`.
    assert(_getKind(rti) == kindInterface);
    return JS('JSUnmodifiableArray', '#', _getRest(rti));
  }

  static Rti _getBindingBase(Rti rti) {
    assert(_getKind(rti) == kindBinding);
    return _castToRti(_getPrimary(rti));
  }

  static JSArray _getBindingArguments(rti) {
    assert(_getKind(rti) == kindBinding);
    return JS('JSUnmodifiableArray', '#', _getRest(rti));
  }

  /// On [Rti]s that are type environments*, derived types are cached on the
  /// environment to ensure fast canonicalization. Ground-term types (i.e. not
  /// dependent on class or function type parameters) are cached in the
  /// universe. This field starts as `null` and the cache is created on demand.
  ///
  /// *Any Rti can be a type environment, since we use the type for a function
  /// type environment. The ambiguity between 'generic class is the environment'
  /// and 'generic class is a singleton type argument' is resolved by using
  /// different indexing in the recipe.
  Object _evalCache;

  static Object _getEvalCache(Rti rti) => rti._evalCache;
  static void _setEvalCache(Rti rti, value) {
    rti._evalCache = value;
  }

  /// On [Rti]s that are type environments*, extended environments are cached on
  /// the base environment to ensure fast canonicalization.
  ///
  /// This field starts as `null` and the cache is created on demand.
  ///
  /// *This is valid only on kindInterface and kindBinding Rtis. The ambiguity
  /// between 'generic class is the base environment' and 'generic class is a
  /// singleton type argument' is resolved [TBD] (either (1) a bind1 cache, or
  /// (2)using `env._eval("@<0>")._bind(args)` in place of `env._bind1(args)`).
  Object _bindCache;

  static Object _getBindCache(Rti rti) => rti._evalCache;
  static void _setBindCache(Rti rti, value) {
    rti._evalCache = value;
  }

  static Rti allocate() {
    return new Rti();
  }

  String _canonicalRecipe;

  static String _getCanonicalRecipe(Rti rti) {
    var s = rti._canonicalRecipe;
    assert(_Utils.isString(s), 'Missing canonical recipe');
    return _Utils.asString(s);
  }

  static void _setCanonicalRecipe(Rti rti, String s) {
    rti._canonicalRecipe = s;
  }
}

Rti _rtiEval(Rti environment, String recipe) {
  // TODO(sra): return _Universe.eval(the-universe, environment, recipe);
  throw UnimplementedError('_rtiEval');
}

Rti _rtiBind1(Rti environment, Rti types) {
  // TODO(sra): return _Universe.bind1(the-universe, environment, types);
  throw UnimplementedError('_rtiBind1');
}

Rti _rtiBind(Rti environment, Rti typeTuple) {
  // TODO(sra): return _Universe.bind(the-universe, environment, types);
  throw UnimplementedError('_rtiBind');
}

Type getRuntimeType(object) {
  throw UnimplementedError('getRuntimeType');
}

String _rtiToString(Rti rti, List<String> genericContext) {
  int kind = Rti._getKind(rti);

  if (kind == Rti.kindDynamic) return 'dynamic';

  if (kind == Rti.kindInterface) {
    String name = Rti._getInterfaceName(rti);
    var arguments = Rti._getInterfaceTypeArguments(rti);
    if (arguments.length != 0) {
      name += '<';
      for (int i = 0; i < arguments.length; i++) {
        if (i > 0) name += ', ';
        name += _rtiToString(_castToRti(arguments[i]), genericContext);
      }
      name += '>';
    }
    return name;
  }

  return '?';
}

String _rtiToDebugString(Rti rti) {
  String arrayToString(Object array) {
    String s = '[', sep = '';
    for (int i = 0; i < _Utils.arrayLength(array); i++) {
      s += sep + _rtiToDebugString(_castToRti(_Utils.arrayAt(array, i)));
      sep = ', ';
    }
    return s + ']';
  }

  int kind = Rti._getKind(rti);

  if (kind == Rti.kindDynamic) return 'dynamic';

  if (kind == Rti.kindInterface) {
    String name = Rti._getInterfaceName(rti);
    var arguments = Rti._getInterfaceTypeArguments(rti);
    if (_Utils.arrayLength(arguments) == 0) {
      return 'interface("$name")';
    } else {
      return 'interface("$name", ${arrayToString(arguments)})';
    }
  }

  if (kind == Rti.kindBinding) {
    var base = Rti._getBindingBase(rti);
    var arguments = Rti._getBindingArguments(rti);
    return 'binding(${_rtiToDebugString(base)}, ${arrayToString(arguments)})';
  }

  return 'other(kind=$kind)';
}

/// Class of static methods for the universe of Rti objects.
///
/// The universe is the manager object for the Rti instances.
///
/// The universe itself is allocated at startup before any types or Dart objects
/// can be created, so it does not have a Dart type.
class _Universe {
  _Universe._() {
    throw UnimplementedError('_Universe is static methods only');
  }

  @pragma('dart2js:noInline')
  static Object create() {
    // TODO(sra): For consistency, this expression should be a JS_BUILTIN that
    // uses the same template as emitted by the emitter.
    return JS(
        '',
        '{'
            'evalCache: new Map(),'
            'unprocessedRules:[],'
            'a0:[],' // shared empty array.
            '}');
  }

  // Field accessors.

  static evalCache(universe) => JS('', '#.evalCache', universe);

  static void addRules(universe, String rules) {
    JS('', '#.unprocessedRules.push(#)', universe, rules);
  }

  static Object sharedEmptyArray(universe) => JS('JSArray', '#.a0', universe);

  /// Evaluates [recipe] in the global environment.
  static Rti eval(Object universe, String recipe) {
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, recipe);
    if (probe != null) return _castToRti(probe);
    var rti = _parseRecipe(universe, null, recipe);
    _cacheSet(cache, recipe, rti);
    return rti;
  }

  static Rti evalInEnvironment(
      Object universe, Rti environment, String recipe) {
    var cache = Rti._getEvalCache(environment);
    if (cache == null) {
      cache = JS('', 'new Map()');
      Rti._setEvalCache(environment, cache);
    }
    var probe = _cacheGet(cache, recipe);
    if (probe != null) return _castToRti(probe);
    var rti = _parseRecipe(universe, environment, recipe);
    _cacheSet(cache, recipe, rti);
    return rti;
  }

  static Rti bind(Object universe, Rti environment, Rti argumentsRti) {
    var cache = Rti._getBindCache(environment);
    if (cache == null) {
      cache = JS('', 'new Map()');
      Rti._setBindCache(environment, cache);
    }
    var argumentsRecipe = Rti._getCanonicalRecipe(argumentsRti);
    var probe = _cacheGet(cache, argumentsRecipe);
    if (probe != null) return _castToRti(probe);
    var argumentsArray;
    if (Rti._getKind(argumentsRti) == Rti.kindBinding) {
      argumentsArray = Rti._getBindingArguments(argumentsRti);
    } else {
      argumentsArray = JS('', '[]');
      _Utils.arrayPush(argumentsArray, argumentsRti);
    }
    var rti = _lookupBindingRti(universe, environment, argumentsArray);
    _cacheSet(cache, argumentsRecipe, rti);
    return rti;
  }

  static Rti evalTypeVariable(Object universe, Rti environment, String name) {
    throw UnimplementedError('_Universe.evalTypeVariable("$name")');
  }

  static _cacheGet(cache, key) => JS('', '#.get(#)', cache, key);
  static void _cacheSet(cache, key, value) {
    JS('', '#.set(#, #)', cache, key, value);
  }

  static Rti _parseRecipe(Object universe, Object environment, String recipe) {
    var parser = _Parser.create(universe, environment, recipe);
    Rti rti = _Parser.parse(parser);
    if (rti != null) return rti;
    throw UnimplementedError('_Universe._parseRecipe("$recipe")');
  }

  static Rti _finishRti(Object universe, Rti rti) {
    // Enter fresh Rti in global table under it's canonical recipe.
    String key = Rti._getCanonicalRecipe(rti);
    _cacheSet(evalCache(universe), key, rti);

    // Set up methods to type tests.
    // TODO(sra): These are for `dynamic`. Install general functions and
    // specializations.
    var alwaysPasses = JS('', 'function(o) { return o; }');
    Rti._setAsCheckFunction(rti, alwaysPasses);
    Rti._setTypeCheckFunction(rti, alwaysPasses);
    Rti._setIsTestFunction(rti, JS('', 'function(o) { return true; }'));

    return rti;
  }

  // For each kind of Rti there are three methods:
  //
  // * `lookupXXX` which takes the component parts and returns an existing Rti
  //   object if it exists.
  // * `canonicalRecipeOfXXX` that returns the compositional canonical recipe
  //   for the proposed type.
  // * `createXXX` to create the type if it does not exist.

  static String _canonicalRecipeOfDynamic() => '@';

  static Rti _lookupDynamicRti(universe) {
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, _canonicalRecipeOfDynamic());
    if (probe != null) return _castToRti(probe);
    return _createDynamicRti(universe);
  }

  static Rti _createDynamicRti(Object universe) {
    var rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindDynamic);
    Rti._setCanonicalRecipe(rti, _canonicalRecipeOfDynamic());
    return _finishRti(universe, rti);
  }

  static String _canonicalRecipeJoin(Object arguments) {
    String s = '', sep = '';
    int length = _Utils.arrayLength(arguments);
    for (int i = 0; i < length; i++) {
      Rti argument = _castToRti(_Utils.arrayAt(arguments, i));
      String subrecipe = Rti._getCanonicalRecipe(argument);
      s += sep + subrecipe;
      sep = ',';
    }
    return s;
  }

  static String _canonicalRecipeOfInterface(String name, Object arguments) {
    assert(_Utils.isString(name));
    String s = _Utils.asString(name);
    int length = _Utils.arrayLength(arguments);
    if (length != 0) {
      s += '<' + _canonicalRecipeJoin(arguments) + '>';
    }
    return s;
  }

  static Rti _lookupInterfaceRti(
      Object universe, String name, Object arguments) {
    String key = _canonicalRecipeOfInterface(name, arguments);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _createInterfaceRti(universe, name, arguments, key);
  }

  static Rti _createInterfaceRti(
      Object universe, String name, Object typeArguments, String key) {
    var rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindInterface);
    Rti._setPrimary(rti, name);
    Rti._setRest(rti, typeArguments);
    Rti._setCanonicalRecipe(rti, key);
    return _finishRti(universe, rti);
  }

  static String _canonicalRecipeOfBinding(Rti base, Object arguments) {
    String s = Rti._getCanonicalRecipe(base);
    s += ';'; // TODO(sra): Omit when base encoding is Rti without ToType.
    s += '<' + _canonicalRecipeJoin(arguments) + '>';
    return s;
  }

  /// [arguments] becomes owned by the created Rti.
  static Rti _lookupBindingRti(Object universe, Rti base, Object arguments) {
    var newBase = base;
    var newArguments = arguments;
    if (Rti._getKind(base) == Rti.kindBinding) {
      newBase = Rti._getBindingBase(base);
      newArguments =
          _Utils.arrayConcat(Rti._getBindingArguments(base), arguments);
    }
    String key = _canonicalRecipeOfBinding(newBase, newArguments);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _createBindingRti(universe, newBase, newArguments, key);
  }

  static Rti _createBindingRti(
      Object universe, Rti base, Object arguments, String key) {
    var rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindBinding);
    Rti._setPrimary(rti, base);
    Rti._setRest(rti, arguments);
    Rti._setCanonicalRecipe(rti, key);
    return _finishRti(universe, rti);
  }
}

/// Class of static methods implementing recipe parser.
///
/// The recipe is a sequence of operations on a stack machine. The operations
/// are described below using the format
///
///      operation: stack elements before --- stack elements after
///
/// integer:  --- integer-value
///
/// identifier:  --- string-value
///
/// identifier-with-one-period:  --- type-variable-value
///
///   Period may be in any position, including first and last e.g. `.x`.
///
/// ',': ignored
///
///   Used to separate elements.
///
/// ';': item  ---  ToType(item)
///
///   Used to separate elements.
///
/// '@': --- dynamicType
///
/// '?':  type  ---  type?
///
/// '<':  --- position
///
///   Saves (pushes) position register, sets position register to end of stack.
///
/// '>':  name saved-position type ... type  ---  name<type, ..., type>
/// '>':  type saved-position type ... type  ---  binding(type, type, ..., type)
///
///   When first element is a String: Creates interface type from string 'name'
///   and the types pushed since the position register was last set. The types
///   are converted with a ToType operation. Restores position register to
///   previous saved value.
///
///   When first element is an Rti: Creates binding Rti wrapping the first
///   element. Binding Rtis are flattened: if the first element is a binding
///   Rti, the new binding Rti has the concatentation of the first element
///   bindings and new type.
///
///
/// The ToType operation coerces an item to an Rti. This saves encoding looking
/// up simple interface names and indexed variables.
///
///   ToType(string): Creates an interface Rti for the non-generic class.
///   ToType(integer): Indexes into the environment.
///   ToType(Rti): Same Rti
///
///
/// Notes on enviroments and indexing.
///
/// To avoid creating a binding Rti for a single function type parameter, the
/// type is passed without creating a 1-tuple object. This means that the
/// interface Rti for, say, `Map<num,dynamic>` serves as two environments with
/// different shapes. It is a class environment (K=num, V=dynamic) and a simple
/// 1-tuple environment. This is supported by index '0' refering to the whole
/// type, and '1 and '2' refering to K and V positionally:
///
///     interface("Map", [num,dynamic])
///     0                 1   2
///
/// Thus the type expression `List<K>` encodes as `List<1>` and in this
/// environment evaluates to `List<num>`. `List<Map<K,V>>` could be encoded as
/// either `List<0>` or `List<Map<1,2>>` (and in this environment evaluates to
/// `List<Map<num,dynamic>>`).
///
/// When `Map<num,dynamic>` is combined with a binding `<int,bool>` (e.g. inside
/// the instance method `Map<K,V>.cast<RK,RV>()`), '0' refers to the base object
/// of the binding, and then the numbering counts the bindings followed by the
/// class parameters.
///
///     binding(interface("Map", [num,dynamic]), [int, bool])
///             0                 3   4           1    2
///
/// Any environment can be reconstructed via a recipe. The above enviroment for
/// method `cast` can be constructed as the ground term
/// `Map<num,dynamic><int,bool>`, or (somewhat pointlessly) reconstructed via
/// `0<1,2>` or `Map<3,4><1,2>`. The ability to construct an environment
/// directly rather than via `bind` calls is used in folding sequences of `eval`
/// and `bind` calls.
///
/// While a single type parameter is passed as the type, multiple type
/// parameters are passed as a tuple. Tuples are encoded as a binding with an
/// ignored base. `dynamic` can be used as the base, giving an encoding like
/// `@<int,bool>`.
///
/// Bindings flatten, so `@<int><bool><num>` is the same as `@<int,bool,num>`.
///
/// The base of a binding does not have to have type parameters. Consider
/// `CodeUnits`, which mixes in `ListMixin<int>`. The environment inside of
/// `ListMixin.fold` (from the call `x.codeUnits.fold<bool>(...)`) would be
///
///     binding(interface("CodeUnits", []), [bool])
///
/// This can be encoded as `CodeUnits;<bool>` (note the `;` to force ToType to
/// avoid creating an interface type Rti with a single class type
/// argument). Metadata about the supertypes is used to resolve the recipe
/// `ListMixin.E` to `int`.

class _Parser {
  _Parser._() {
    throw UnimplementedError('_Parser is static methods only');
  }

  /// Creates a parser object for parsing a recipe against an environment in a
  /// universe.
  ///
  /// Marked as no-inline so the object literal is not cloned by inlining.
  @pragma('dart2js:noInline')
  static Object create(Object universe, Object environment, String recipe) {
    return JS(
        '',
        '{'
            'u:#,' // universe
            'e:#,' // environment
            'r:#,' // recipe
            's:[],' // stack
            'p:0,' // position of sequence start.
            '}',
        universe,
        environment,
        recipe);
  }

  // Field accessors for the parser.
  static Object universe(Object parser) => JS('String', '#.u', parser);
  static Rti environment(Object parser) => JS('Rti', '#.e', parser);
  static String recipe(Object parser) => JS('String', '#.r', parser);
  static Object stack(Object parser) => JS('', '#.s', parser);
  static Object position(Object parser) => JS('int', '#.p', parser);
  static void setPosition(Object parser, int p) {
    JS('', '#.p = #', parser, p);
  }

  static int charCodeAt(String s, int i) => JS('int', '#.charCodeAt(#)', s, i);
  static void push(Object stack, Object value) {
    JS('', '#.push(#)', stack, value);
  }

  static Object pop(Object stack) => JS('', '#.pop()', stack);

  static Rti parse(Object parser) {
    String source = _Parser.recipe(parser);
    var stack = _Parser.stack(parser);
    int i = 0;
    while (i < source.length) {
      int ch = charCodeAt(source, i);
      if (isDigit(ch)) {
        i = handleDigit(i + 1, ch, source, stack);
      } else if (isIdentifierStart(ch)) {
        i = handleIdentifer(parser, i, source, stack, false);
      } else if (ch == $PERIOD) {
        i = handleIdentifer(parser, i, source, stack, true);
      } else {
        i++;
        switch (ch) {
          case $COMMA:
            // ignored
            break;

          case $AT:
            push(stack, _Universe._lookupDynamicRti(universe(parser)));
            break;

          case $SEMICOLON:
            push(stack,
                toType(universe(parser), environment(parser), pop(stack)));
            break;

          case $LT:
            push(stack, position(parser));
            setPosition(parser, _Utils.arrayLength(stack));
            break;

          case $GT:
            handleTypeArguments(parser, stack);
            break;

          default:
            JS('', 'throw "Bad character " + #', ch);
        }
      }
    }
    Object item = pop(stack);
    return toType(universe(parser), environment(parser), item);
  }

  static int handleDigit(int i, int digit, String source, Object stack) {
    int value = digit - $0;
    for (; i < source.length; i++) {
      int ch = charCodeAt(source, i);
      if (!isDigit(ch)) break;
      value = value * 10 + ch - $0;
    }
    push(stack, value);
    return i;
  }

  static int handleIdentifer(
      Object parser, int start, String source, Object stack, bool hasPeriod) {
    int i = start + 1;
    for (; i < source.length; i++) {
      int ch = charCodeAt(source, i);
      if (ch == $PERIOD) {
        if (hasPeriod) break;
        hasPeriod = true;
      } else if (isIdentifierStart(ch) || isDigit(ch)) {
        // Accept.
      } else {
        break;
      }
    }
    String string = _Utils.substring(source, start, i);
    if (hasPeriod) {
      push(
          stack,
          _Universe.evalTypeVariable(
              universe(parser), environment(parser), string));
    } else {
      push(stack, string);
    }
    return i;
  }

  static void handleTypeArguments(Object parser, Object stack) {
    var universe = _Parser.universe(parser);
    var arguments = collectArray(parser, stack);
    var head = pop(stack);
    if (_Utils.isString(head)) {
      String name = _Utils.asString(head);
      push(stack, _Universe._lookupInterfaceRti(universe, name, arguments));
    } else {
      Rti base = toType(universe, environment(parser), head);
      push(stack, _Universe._lookupBindingRti(universe, base, arguments));
    }
  }

  static Object collectArray(Object parser, Object stack) {
    var array = _Utils.arraySplice(stack, position(parser));
    toTypes(_Parser.universe(parser), environment(parser), array);
    setPosition(parser, _Utils.asInt(pop(stack)));
    return array;
  }

  /// Coerce a stack item into an Rti object. Strings are converted to interface
  /// types, integers are looked up in the type environment.
  static Rti toType(Object universe, Rti environment, Object item) {
    if (_Utils.isString(item)) {
      String name = _Utils.asString(item);
      // TODO(sra): Compile this out for minified code.
      if ('dynamic' == name) {
        return _Universe._lookupDynamicRti(universe);
      }
      return _Universe._lookupInterfaceRti(
          universe, name, _Universe.sharedEmptyArray(universe));
    } else if (_Utils.isNum(item)) {
      return _Parser.indexToType(universe, environment, _Utils.asInt(item));
    } else {
      return _castToRti(item);
    }
  }

  static void toTypes(Object universe, Rti environment, Object items) {
    int length = _Utils.arrayLength(items);
    for (int i = 0; i < length; i++) {
      var item = _Utils.arrayAt(items, i);
      var type = toType(universe, environment, item);
      _Utils.arraySetAt(items, i, type);
    }
  }

  static Rti indexToType(Object universe, Rti environment, int index) {
    int kind = Rti._getKind(environment);
    if (kind == Rti.kindBinding) {
      if (index == 0) return Rti._getBindingBase(environment);
      var typeArguments = Rti._getBindingArguments(environment);
      int len = _Utils.arrayLength(typeArguments);
      if (index <= len) {
        return _castToRti(_Utils.arrayAt(typeArguments, index - 1));
      }
      // Is index into interface Rti in base.
      index -= len;
      environment = Rti._getBindingBase(environment);
      kind = Rti._getKind(environment);
    } else {
      if (index == 0) return environment;
    }
    if (kind != Rti.kindInterface) {
      throw AssertionError('Indexed base must be an interface type');
    }
    var typeArguments = Rti._getInterfaceTypeArguments(environment);
    int len = _Utils.arrayLength(typeArguments);
    if (index <= len) {
      return _castToRti(_Utils.arrayAt(typeArguments, index - 1));
    }
    throw AssertionError('Bad index $index for $environment');
  }

  static bool isDigit(int ch) => ch >= $0 && ch <= $9;
  static bool isIdentifierStart(int ch) =>
      (ch >= $A && ch <= $Z) ||
      (ch >= $a && ch <= $z) ||
      (ch == $_) ||
      (ch == $$);

  static const int $$ = 0x24;
  static const int $PLUS = 0x2B;
  static const int $COMMA = 0x2C;
  static const int $PERIOD = 0x2E;
  static const int $0 = 0x30;
  static const int $9 = 0x39;
  static const int $SEMICOLON = 0x3B;
  static const int $LT = 0x3C;
  static const int $GT = 0x3E;
  static const int $QUESTION = 0x3F;
  static const int $AT = 0x40;
  static const int $A = 0x41;
  static const int $Z = 0x5A;
  static const int $LBRACKET = 0x5B;
  static const int $RBRACKET = 0x5D;
  static const int $a = $A + 32;
  static const int $z = $Z + 32;
  static const int $_ = 0x5F;
}

// -------- Subtype tests ------------------------------------------------------

// Future entry point from compiled code.
bool isSubtype(Rti s, Rti t) {
  return _isSubtype(s, null, t, null);
}

bool _isSubtype(Rti s, var sEnv, Rti t, var tEnv) {
  if (_Utils.isIdentical(s, t)) return true;
  int tKind = Rti._getKind(t);
  if (tKind == Rti.kindDynamic) return true;
  if (tKind == Rti.kindNever) return false;
  return false;
}

/// Unchecked cast to Rti.
Rti _castToRti(s) => JS('Rti', '#', s);

///
class _Utils {
  static int asInt(Object o) => JS('int', '#', o);
  static String asString(Object o) => JS('String', '#', o);

  static bool isString(Object o) => JS('bool', 'typeof # == "string"', o);
  static bool isNum(Object o) => JS('bool', 'typeof # == "number"', o);

  static bool isIdentical(s, t) => JS('bool', '# === #', s, t);

  static int arrayLength(Object array) => JS('int', '#.length', array);

  static Object arrayAt(Object array, int i) => JS('', '#[#]', array, i);

  static Object arraySetAt(Object array, int i, Object value) {
    JS('', '#[#] = #', array, i, value);
  }

  static JSArray arraySplice(Object array, int position) =>
      JS('JSArray', '#.splice(#)', array, position);

  static JSArray arrayConcat(Object a1, Object a2) =>
      JS('JSArray', '#.concat(#)', a1, a2);

  static void arrayPush(Object array, Object value) {
    JS('', '#.push(#)', array, value);
  }

  static String substring(String s, int start, int end) =>
      JS('String', '#.substring(#, #)', s, start, end);

  static mapGet(cache, key) => JS('', '#.get(#)', cache, key);

  static void mapSet(cache, key, value) {
    JS('', '#.set(#, #)', cache, key, value);
  }
}
// -------- Entry points for testing -------------------------------------------

String testingRtiToString(rti) {
  return _rtiToString(_castToRti(rti), null);
}

String testingRtiToDebugString(rti) {
  return _rtiToDebugString(_castToRti(rti));
}

Object testingCreateUniverse() {
  return _Universe.create();
}

Object testingAddRules(universe, String rules) {
  _Universe.addRules(universe, rules);
}

bool testingIsSubtype(rti1, rti2) {
  return isSubtype(_castToRti(rti1), _castToRti(rti2));
}

Object testingUniverseEval(universe, String recipe) {
  return _Universe.eval(universe, recipe);
}

Object testingEnvironmentEval(universe, environment, String recipe) {
  return _Universe.evalInEnvironment(universe, _castToRti(environment), recipe);
}

Object testingEnvironmentBind(universe, environment, arguments) {
  return _Universe.bind(
      universe, _castToRti(environment), _castToRti(arguments));
}
