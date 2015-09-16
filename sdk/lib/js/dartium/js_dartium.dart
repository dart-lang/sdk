// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interoperating with JavaScript.
 * 
 * This library provides access to JavaScript objects from Dart, allowing
 * Dart code to get and set properties, and call methods of JavaScript objects
 * and invoke JavaScript functions. The library takes care of converting
 * between Dart and JavaScript objects where possible, or providing proxies if
 * conversion isn't possible.
 *
 * This library does not yet make Dart objects usable from JavaScript, their
 * methods and proeprties are not accessible, though it does allow Dart
 * functions to be passed into and called from JavaScript.
 *
 * [JsObject] is the core type and represents a proxy of a JavaScript object.
 * JsObject gives access to the underlying JavaScript objects properties and
 * methods. `JsObject`s can be acquired by calls to JavaScript, or they can be
 * created from proxies to JavaScript constructors.
 *
 * The top-level getter [context] provides a [JsObject] that represents the
 * global object in JavaScript, usually `window`.
 *
 * The following example shows an alert dialog via a JavaScript call to the
 * global function `alert()`:
 *
 *     import 'dart:js';
 *     
 *     main() => context.callMethod('alert', ['Hello from Dart!']);
 *
 * This example shows how to create a [JsObject] from a JavaScript constructor
 * and access its properties:
 *
 *     import 'dart:js';
 *     
 *     main() {
 *       var object = new JsObject(context['Object']);
 *       object['greeting'] = 'Hello';
 *       object['greet'] = (name) => "${object['greeting']} $name";
 *       var message = object.callMethod('greet', ['JavaScript']);
 *       context['console'].callMethod('log', [message]);
 *     }
 *
 * ## Proxying and automatic conversion
 * 
 * When setting properties on a JsObject or passing arguments to a Javascript
 * method or function, Dart objects are automatically converted or proxied to
 * JavaScript objects. When accessing JavaScript properties, or when a Dart
 * closure is invoked from JavaScript, the JavaScript objects are also
 * converted to Dart.
 *
 * Functions and closures are proxied in such a way that they are callable. A
 * Dart closure assigned to a JavaScript property is proxied by a function in
 * JavaScript. A JavaScript function accessed from Dart is proxied by a
 * [JsFunction], which has a [apply] method to invoke it.
 *
 * The following types are transferred directly and not proxied:
 *
 * * "Basic" types: `null`, `bool`, `num`, `String`, `DateTime`
 * * `Blob`
 * * `Event`
 * * `HtmlCollection`
 * * `ImageData`
 * * `KeyRange`
 * * `Node`
 * * `NodeList`
 * * `TypedData`, including its subclasses like `Int32List`, but _not_
 *   `ByteBuffer`
 * * `Window`
 *
 * ## Converting collections with JsObject.jsify()
 *
 * To create a JavaScript collection from a Dart collection use the
 * [JsObject.jsify] constructor, which converts Dart [Map]s and [Iterable]s
 * into JavaScript Objects and Arrays.
 *
 * The following expression creats a new JavaScript object with the properties
 * `a` and `b` defined:
 *
 *     var jsMap = new JsObject.jsify({'a': 1, 'b': 2});
 * 
 * This expression creates a JavaScript array:
 *
 *     var jsArray = new JsObject.jsify([1, 2, 3]);
 */
library dart.js;

import 'dart:collection' show ListMixin;
import 'dart:nativewrappers';
import 'dart:math' as math;
import 'dart:mirrors' as mirrors;

// Pretend we are always in checked mode as we aren't interested in users
// running Dartium code outside of checked mode.
final bool CHECK_JS_INVOCATIONS = true;

final _allowedMethods = new Map<Symbol, _DeclarationSet>();
final _allowedGetters = new Map<Symbol, _DeclarationSet>();
final _allowedSetters = new Map<Symbol, _DeclarationSet>();

final _jsInterfaceTypes = new Set<Type>();
Iterable<Type> get jsInterfaceTypes => _jsInterfaceTypes;

/// A collection of methods where all methods have the same name.
/// This class is intended to optimize whether a specific invocation is
/// appropritate for at least some of the methods in the collection.
class _DeclarationSet {
  _DeclarationSet() : _members = <mirrors.DeclarationMirror>[];

  static bool _checkType(obj, mirrors.TypeMirror type) {
    if (obj == null) return true;
    return mirrors.reflectType(obj.runtimeType).isSubtypeOf(type);
  }

  /// Returns whether the return [value] has a type is consistent with the
  /// return type from at least one of the members matching the DeclarationSet.
  bool _checkReturnType(value) {
    if (value == null) return true;
    var valueMirror = mirrors.reflectType(value.runtimeType);
    for (var member in _members) {
      if (member is mirrors.VariableMirror || member.isGetter) {
        // TODO(jacobr): actually check return types for getters that return
        // function types.
        return true;
      } else {
        if (valueMirror.isSubtypeOf(member.returnType)) return true;
      }
    }
    return false;
  }

  /**
   * Check whether the [invocation] is consistent with the [member] mirror.
   */
  bool _checkDeclaration(
      Invocation invocation, mirrors.DeclarationMirror member) {
    if (member is mirrors.VariableMirror || (member as dynamic).isGetter) {
      // TODO(jacobr): actually check method types against the function type
      // returned by the getter or field.
      return true;
    }
    var parameters = (member as dynamic).parameters;
    var positionalArguments = invocation.positionalArguments;
    // Too many arguments
    if (parameters.length < positionalArguments.length) return false;
    // Too few required arguments.
    if (parameters.length > positionalArguments.length &&
        !parameters[positionalArguments.length].isOptional) return false;
    for (var i = 0; i < positionalArguments.length; i++) {
      if (parameters[i].isNamed) {
        // Not enough positional arguments.
        return false;
      }
      if (!_checkType(
          invocation.positionalArguments[i], parameters[i].type)) return false;
    }
    if (invocation.namedArguments.isNotEmpty) {
      var startNamed;
      for (startNamed = parameters.length - 1; startNamed >= 0; startNamed--) {
        if (!parameters[startNamed].isNamed) break;
      }
      startNamed++;

      // TODO(jacobr): we are unneccessarily using an O(n^2) algorithm here.
      // If we have JS APIs with a lange number of named parameters we should
      // optimize this. Either use a HashSet or invert this, walking over
      // parameters, querying invocation, and making sure we match
      //invocation.namedArguments.size keys.
      for (var name in invocation.namedArguments.keys) {
        bool match = false;
        for (var j = startNamed; j < parameters.length; j++) {
          var p = parameters[j];
          if (p.simpleName == name) {
            if (!_checkType(invocation.namedArguments[name],
                parameters[j].type)) return false;
            match = true;
            break;
          }
        }
        if (match == false) return false;
      }
    }
    return true;
  }

  bool checkInvocation(Invocation invocation) {
    for (var member in _members) {
      if (_checkDeclaration(invocation, member)) return true;
    }
    return false;
  }

  void add(mirrors.DeclarationMirror mirror) {
    _members.add(mirror);
  }

  final List<mirrors.DeclarationMirror> _members;
}

/**
 * Temporary method that we hope to remove at some point. This method should
 * generally only be called by machine generated code.
 */
void registerJsInterfaces(List<Type> classes) {
  if (_finalized == true) {
    throw 'JSInterop class registration already finalized';
  }
  for (Type type in classes) {
    if (!_jsInterfaceTypes.add(type)) continue; // Already registered.
    mirrors.ClassMirror typeMirror = mirrors.reflectType(type);
    typeMirror.declarations.forEach((symbol, declaration) {
      if (declaration is mirrors.MethodMirror ||
          declaration is mirrors.VariableMirror && !declaration.isStatic) {
        bool treatAsGetter = false;
        bool treatAsSetter = false;
        if (declaration is mirrors.VariableMirror) {
          treatAsGetter = true;
          if (!declaration.isConst && !declaration.isFinal) {
            treatAsSetter = true;
          }
        } else {
          if (declaration.isGetter) {
            treatAsGetter = true;
          } else if (declaration.isSetter) {
            treatAsSetter = true;
          } else if (!declaration.isConstructor) {
            _allowedMethods
                .putIfAbsent(symbol, () => new _DeclarationSet())
                .add(declaration);
          }
        }
        if (treatAsGetter) {
          _allowedGetters
              .putIfAbsent(symbol, () => new _DeclarationSet())
              .add(declaration);
          _allowedMethods
              .putIfAbsent(symbol, () => new _DeclarationSet())
              .add(declaration);
        }
        if (treatAsSetter) {
          _allowedSetters
              .putIfAbsent(symbol, () => new _DeclarationSet())
              .add(declaration);
        }
      }
    });
  }
}

_finalizeJsInterfaces() native "Js_finalizeJsInterfaces";

/**
 * Generates a part file defining source code for JsObjectImpl and related
 * classes. This calass is needed so that type checks for all registered JavaScript
 * interop classes pass.
 */
String _generateJsObjectImplPart() {
  Iterable<Type> types = jsInterfaceTypes;
  var libraryPrefixes = new Map<mirrors.LibraryMirror, String>();
  var prefixNames = new Set<String>();
  var sb = new StringBuffer();

  var implements = <String>[];
  for (var type in types) {
    mirrors.ClassMirror typeMirror = mirrors.reflectType(type);
    mirrors.LibraryMirror libraryMirror = typeMirror.owner;
    var prefixName;
    if (libraryPrefixes.containsKey(libraryMirror)) {
      prefixName = libraryPrefixes[libraryMirror];
    } else {
      var basePrefixName =
          mirrors.MirrorSystem.getName(libraryMirror.simpleName);
      basePrefixName = basePrefixName.replaceAll('.', '_');
      if (basePrefixName.isEmpty) basePrefixName = "lib";
      prefixName = basePrefixName;
      var i = 1;
      while (prefixNames.contains(prefixName)) {
        prefixName = '$basePrefixName$i';
        i++;
      }
      prefixNames.add(prefixName);
      libraryPrefixes[libraryMirror] = prefixName;
    }
    implements.add(
        '${prefixName}.${mirrors.MirrorSystem.getName(typeMirror.simpleName)}');
  }
  libraryPrefixes.forEach((libraryMirror, prefix) {
    sb.writeln('import "${libraryMirror.uri}" as $prefix;');
  });
  var implementsClause =
      implements.isEmpty ? "" : "implements ${implements.join(', ')}";
  // TODO(jacobr): only certain classes need to be implemented by
  // Function and Array.
  sb.write('''
class JsObjectImpl extends JsObject $implementsClause {
  JsObjectImpl.internal() : super.internal();
}

class JsFunctionImpl extends JsFunction $implementsClause {
  JsFunctionImpl.internal() : super.internal();
}

class JsArrayImpl<E> extends JsArray<E> $implementsClause {
  JsArrayImpl.internal() : super.internal();
}
''');
  return sb.toString();
}

// Start of block of helper methods facilitating emulating JavaScript Array
// methods on Dart List objects passed to JavaScript via JS interop.
// TODO(jacobr): match JS more closely.
String _toStringJs(obj) => '$obj';

// TODO(jacobr): this might not exactly match JS semantics but should be
// adequate for now.
int _toIntJs(obj) {
  if (obj is int) return obj;
  if (obj is num) return obj.toInt();
  return num.parse('$obj'.trim(), (_) => 0).toInt();
}

// TODO(jacobr): this might not exactly match JS semantics but should be
// adequate for now.
num _toNumJs(obj) {
  return obj is num ? obj : num.parse('$obj'.trim(), (_) => 0);
}

/// Match the behavior of setting List length in JavaScript with the exception
/// that Dart does not distinguish undefined and null.
_setListLength(List list, rawlen) {
  num len = _toNumJs(rawlen);
  if (len is! int || len < 0) {
    throw new RangeError("Invalid array length");
  }
  if (len > list.length) {
    _arrayExtend(list, len);
  } else if (len < list.length) {
    list.removeRange(len, list.length);
  }
  return rawlen;
}

// TODO(jacobr): should we really bother with this method instead of just
// shallow copying to a JS array and calling the JavaScript join method?
String _arrayJoin(List list, sep) {
  if (sep == null) {
    sep = ",";
  }
  return list.map((e) => e == null ? "" : e.toString()).join(sep.toString());
}

// TODO(jacobr): should we really bother with this method instead of just
// shallow copying to a JS array and using the toString method?
String _arrayToString(List list) => _arrayJoin(list, ",");

int _arrayPush(List list, List args) {
  for(var e in args) {
    list.add(e);
  }
  return list.length;
}

_arrayPop(List list) {
  if (list.length > 0) return list.removeLast();
}

// TODO(jacobr): would it be better to just copy input to a JS List
// and call Array.concat?
List _arrayConcat(List input, List args) {
  var ret = new List.from(input);
  for (var e in args) {
    // TODO(jacobr): technically in ES6 we should use
    // Symbol.isConcatSpreadable to determine whether call addAll. Once v8
    // supports it, we can make all Dart classes implementing Iterable
    // specify isConcatSpreadable and tweak this behavior to allow Iterable.
    if (e is List) {
      ret.addAll(e);
    } else {
      ret.add(e);
    }
  }
  return ret;
}

List _arraySplice(List input, List args) {
  int start = 0;
  if (args.length > 0) {
    var rawStart = _toIntJs(args[0]);
    if (rawStart < 0) {
      start = math.max(0, input.length - rawStart);
    } else {
      start = math.min(input.length, rawStart);
    }
  }
  var end = start;
  if (args.length > 1) {
    var rawDeleteCount = _toIntJs(args[1]);
    if (rawDeleteCount < 0) rawDeleteCount = 0;
    end = math.min(input.length, start + rawDeleteCount);
  }
  var replacement = [];
  var removedElements = input.getRange(start, end).toList();
  if (args.length > 2) {
    replacement = args.getRange(2, args.length);
  }
  input.replaceRange(start, end, replacement);
  return removedElements;
}

List _arrayReverse(List l) {
  for (var i = 0, j = l.length - 1; i < j; i++, j--) {
    var tmp = l[i];
    l[i] = l[j];
    l[j] = tmp;
  }
  return l;
}

_arrayShift(List l) {
  if (l.isEmpty) return null; // Technically we should return undefined.
  return l.removeAt(0);
}

int _arrayUnshift(List l, List args) {
  l.insertAll(0, args);
  return l.length;
}

_arrayExtend(List l, int newLength) {
  for (var i = l.length; i < newLength; i++) {
    // TODO(jacobr): we'd really like to add undefined to better match
    // JavaScript semantics.
    l.add(null);
  }
}

List _arraySort(List l, rawCompare) {
  // TODO(jacobr): alternately we could just copy the Array to JavaScript,
  // invoke the JS sort method and then copy the result back to Dart.
  Comparator compare;
  if (rawCompare == null) {
    compare = (a, b) => _toStringJs(a).compareTo(_toStringJs(b));
  } else if (rawCompare is JsFunction) {
    compare = (a, b) => rawCompare.apply([a, b]);
  } else {
    compare = rawCompare;
  }
  l.sort(compare);
  return l;
}
// End of block of helper methods to emulate JavaScript Array methods on Dart List.

/**
 * Can be called to provide a predictable point where no more JS interfaces can
 * be added. Creating an instance of JsObject will also automatically trigger
 * all JsObjects to be finalized.
 */
void finalizeJsInterfaces() {
  if (_finalized == true) {
    throw 'JSInterop class registration already finalized';
  }
  _finalizeJsInterfaces();
}

JsObject _cachedContext;

JsObject get _context native "Js_context_Callback";

bool get _finalized native "Js_interfacesFinalized_Callback";

JsObject get context {
  if (_cachedContext == null) {
    _cachedContext = _context;
  }
  return _cachedContext;
}

/**
 * Proxies a JavaScript object to Dart.
 *
 * The properties of the JavaScript object are accessible via the `[]` and
 * `[]=` operators. Methods are callable via [callMethod].
 */
class JsObject extends NativeFieldWrapperClass2 {
  JsObject.internal();

  /**
   * Constructs a new JavaScript object from [constructor] and returns a proxy
   * to it.
   */
  factory JsObject(JsFunction constructor, [List arguments]) =>
      _create(constructor, arguments);

  static JsObject _create(
      JsFunction constructor, arguments) native "JsObject_constructorCallback";

  _buildArgs(Invocation invocation) {
    if (invocation.namedArguments.isEmpty) {
      return invocation.positionalArguments;
    } else {
      var varArgs = new Map<String, Object>();
      invocation.namedArguments.forEach((symbol, val) {
        varArgs[mirrors.MirrorSystem.getName(symbol)] = val;
      });
      return invocation.positionalArguments.toList()
        ..add(new JsObject.jsify(varArgs));
    }
  }

  /**
   * Constructs a [JsObject] that proxies a native Dart object; _for expert use
   * only_.
   *
   * Use this constructor only if you wish to get access to JavaScript
   * properties attached to a browser host object, such as a Node or Blob, that
   * is normally automatically converted into a native Dart object.
   * 
   * An exception will be thrown if [object] either is `null` or has the type
   * `bool`, `num`, or `String`.
   */
  factory JsObject.fromBrowserObject(object) {
    if (object is num || object is String || object is bool || object == null) {
      throw new ArgumentError("object cannot be a num, string, bool, or null");
    }
    return _fromBrowserObject(object);
  }

  /**
   * Recursively converts a JSON-like collection of Dart objects to a
   * collection of JavaScript objects and returns a [JsObject] proxy to it.
   *
   * [object] must be a [Map] or [Iterable], the contents of which are also
   * converted. Maps and Iterables are copied to a new JavaScript object.
   * Primitives and other transferrable values are directly converted to their
   * JavaScript type, and all other objects are proxied.
   */
  factory JsObject.jsify(object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw new ArgumentError("object must be a Map or Iterable");
    }
    return _jsify(object);
  }

  static JsObject _jsify(object) native "JsObject_jsify";

  static JsObject _fromBrowserObject(
      object) native "JsObject_fromBrowserObject";

  /**
   * Returns the value associated with [property] from the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator [](property) native "JsObject_[]";

  /**
   * Sets the value associated with [property] on the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator []=(property, value) native "JsObject_[]=";

  int get hashCode native "JsObject_hashCode";

  operator ==(other) => other is JsObject && _identityEquality(this, other);

  static bool _identityEquality(
      JsObject a, JsObject b) native "JsObject_identityEquality";

  /**
   * Returns `true` if the JavaScript object contains the specified property
   * either directly or though its prototype chain.
   *
   * This is the equivalent of the `in` operator in JavaScript.
   */
  bool hasProperty(String property) native "JsObject_hasProperty";

  /**
   * Removes [property] from the JavaScript object.
   *
   * This is the equivalent of the `delete` operator in JavaScript.
   */
  void deleteProperty(String property) native "JsObject_deleteProperty";

  /**
   * Returns `true` if the JavaScript object has [type] in its prototype chain.
   *
   * This is the equivalent of the `instanceof` operator in JavaScript.
   */
  bool instanceof(JsFunction type) native "JsObject_instanceof";

  /**
   * Returns the result of the JavaScript objects `toString` method.
   */
  String toString() {
    try {
      return _toString();
    } catch (e) {
      return super.toString();
    }
  }

  String _toString() native "JsObject_toString";

  /**
   * Calls [method] on the JavaScript object with the arguments [args] and
   * returns the result.
   *
   * The type of [method] must be either [String] or [num].
   */
  callMethod(String method, [List args]) {
    try {
      return _callMethod(method, args);
    } catch (e) {
      if (hasProperty(method)) {
        rethrow;
      } else {
        throw new NoSuchMethodError(this, new Symbol(method), args, null);
      }
    }
  }

  noSuchMethod(Invocation invocation) {
    throwError() {
      throw new NoSuchMethodError(this, invocation.memberName,
          invocation.positionalArguments, invocation.namedArguments);
    }

    String name = mirrors.MirrorSystem.getName(invocation.memberName);
    if (invocation.isGetter) {
      if (CHECK_JS_INVOCATIONS) {
        var matches = _allowedGetters[invocation.memberName];
        if (matches == null &&
            !_allowedMethods.containsKey(invocation.memberName)) {
          throwError();
        }
        var ret = this[name];
        if (matches != null && matches._checkReturnType(ret)) return ret;
        if (ret is Function ||
            (ret is JsFunction /* shouldn't be needed in the future*/) &&
                _allowedMethods.containsKey(
                    invocation.memberName)) return ret; // Warning: we have not bound "this"... we could type check on the Function but that is of little value in Dart.
        throwError();
      } else {
        // TODO(jacobr): should we throw if the JavaScript object doesn't have the property?
        return this[name];
      }
    } else if (invocation.isSetter) {
      if (CHECK_JS_INVOCATIONS) {
        var matches = _allowedSetters[invocation.memberName];
        if (matches == null ||
            !matches.checkInvocation(invocation)) throwError();
      }
      assert(name.endsWith("="));
      name = name.substring(0, name.length - 1);
      return this[name] = invocation.positionalArguments.first;
    } else {
      // TODO(jacobr): also allow calling getters that look like functions.
      var matches;
      if (CHECK_JS_INVOCATIONS) {
        matches = _allowedMethods[invocation.memberName];
        if (matches == null ||
            !matches.checkInvocation(invocation)) throwError();
      }
      var ret = this.callMethod(name, _buildArgs(invocation));
      if (CHECK_JS_INVOCATIONS) {
        if (!matches._checkReturnType(ret)) throwError();
      }
      return ret;
    }
  }

  _callMethod(String name, List args) native "JsObject_callMethod";
}

/**
 * Proxies a JavaScript Function object.
 */
class JsFunction extends JsObject implements Function {
  JsFunction.internal() : super.internal();

  /**
   * Returns a [JsFunction] that captures its 'this' binding and calls [f]
   * with the value of this passed as the first argument.
   */
  factory JsFunction.withThis(Function f) => _withThis(f);

  /**
   * Invokes the JavaScript function with arguments [args]. If [thisArg] is
   * supplied it is the value of `this` for the invocation.
   */
  dynamic apply(List args, {thisArg}) native "JsFunction_apply";

  noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #call) {
      return apply(_buildArgs(invocation));
    }
    return super.noSuchMethod(invocation);
  }

  /**
   * Internal only version of apply which uses debugger proxies of Dart objects
   * rather than opaque handles. This method is private because it cannot be
   * efficiently implemented in Dart2Js so should only be used by internal
   * tools.
   */
  _applyDebuggerOnly(List args,
      {thisArg}) native "JsFunction_applyDebuggerOnly";

  static JsFunction _withThis(Function f) native "JsFunction_withThis";
}

/**
 * A [List] proxying a JavaScript Array.
 */
class JsArray<E> extends JsObject with ListMixin<E> {
  JsArray.internal() : super.internal();

  factory JsArray() => _newJsArray();

  static JsArray _newJsArray() native "JsArray_newJsArray";

  factory JsArray.from(Iterable<E> other) =>
      _newJsArrayFromSafeList(new List.from(other));

  static JsArray _newJsArrayFromSafeList(
      List list) native "JsArray_newJsArrayFromSafeList";

  _checkIndex(int index, {bool insert: false}) {
    int length = insert ? this.length + 1 : this.length;
    if (index is int && (index < 0 || index >= length)) {
      throw new RangeError.range(index, 0, length);
    }
  }

  _checkRange(int start, int end) {
    int cachedLength = this.length;
    if (start < 0 || start > cachedLength) {
      throw new RangeError.range(start, 0, cachedLength);
    }
    if (end < start || end > cachedLength) {
      throw new RangeError.range(end, start, cachedLength);
    }
  }

  // Methods required by ListMixin

  E operator [](index) {
    if (index is int) {
      _checkIndex(index);
    }
    return super[index];
  }

  void operator []=(index, E value) {
    if (index is int) {
      _checkIndex(index);
    }
    super[index] = value;
  }

  int get length native "JsArray_length";

  void set length(int length) {
    super['length'] = length;
  }

  // Methods overriden for better performance

  void add(E value) {
    callMethod('push', [value]);
  }

  void addAll(Iterable<E> iterable) {
    // TODO(jacobr): this can be optimized slightly.
    callMethod('push', new List.from(iterable));
  }

  void insert(int index, E element) {
    _checkIndex(index, insert: true);
    callMethod('splice', [index, 0, element]);
  }

  E removeAt(int index) {
    _checkIndex(index);
    return callMethod('splice', [index, 1])[0];
  }

  E removeLast() {
    if (length == 0) throw new RangeError(-1);
    return callMethod('pop');
  }

  void removeRange(int start, int end) {
    _checkRange(start, end);
    callMethod('splice', [start, end - start]);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _checkRange(start, end);
    int length = end - start;
    if (length == 0) return;
    if (skipCount < 0) throw new ArgumentError(skipCount);
    var args = [start, length]..addAll(iterable.skip(skipCount).take(length));
    callMethod('splice', args);
  }

  void sort([int compare(E a, E b)]) {
    callMethod('sort', [compare]);
  }
}

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED = const Object();

// TODO(jacobr): this method is a hack to work around the lack of proper dart
// support for varargs methods.
List _stripUndefinedArgs(List args) =>
    args.takeWhile((i) => i != _UNDEFINED).toList();

/**
 * Returns a method that can be called with an arbitrary number (for n less
 * than 11) of arguments without violating Dart type checks.
 */
Function _wrapAsDebuggerVarArgsFunction(JsFunction jsFunction) =>
    ([a1 = _UNDEFINED, a2 = _UNDEFINED, a3 = _UNDEFINED, a4 = _UNDEFINED,
        a5 = _UNDEFINED, a6 = _UNDEFINED, a7 = _UNDEFINED, a8 = _UNDEFINED,
        a9 = _UNDEFINED, a10 = _UNDEFINED]) => jsFunction._applyDebuggerOnly(
            _stripUndefinedArgs([a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]));
