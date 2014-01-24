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

JsObject _cachedContext;

JsObject get _context native "Js_context_Callback";

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
  factory JsObject(JsFunction constructor, [List arguments]) => _create(constructor, arguments);

  static JsObject _create(JsFunction constructor, arguments) native "JsObject_constructorCallback";

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
      throw new ArgumentError(
        "object cannot be a num, string, bool, or null");
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

  static JsObject _fromBrowserObject(object) native "JsObject_fromBrowserObject";

  /**
   * Returns the value associated with [property] from the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator[](property) native "JsObject_[]";

  /**
   * Sets the value associated with [property] on the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator[]=(property, value) native "JsObject_[]=";

  int get hashCode native "JsObject_hashCode";

  operator==(other) => other is JsObject && _identityEquality(this, other);

  static bool _identityEquality(JsObject a, JsObject b) native "JsObject_identityEquality";

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
    } catch(e) {
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
    } catch(e) {
      if (hasProperty(method)) {
        rethrow;
      } else {
        throw new NoSuchMethodError(this, new Symbol(method), args, null);
      }
    }
  }

  _callMethod(String name, List args) native "JsObject_callMethod";
}

/**
 * Proxies a JavaScript Function object.
 */
class JsFunction extends JsObject {
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

  /**
   * Internal only version of apply which uses debugger proxies of Dart objects
   * rather than opaque handles. This method is private because it cannot be
   * efficiently implemented in Dart2Js so should only be used by internal
   * tools.
   */
  _applyDebuggerOnly(List args, {thisArg}) native "JsFunction_applyDebuggerOnly";

  static JsFunction _withThis(Function f) native "JsFunction_withThis";
}

/**
 * A [List] proxying a JavaScript Array.
 */
class JsArray<E> extends JsObject with ListMixin<E> {

  factory JsArray() => _newJsArray();

  static JsArray _newJsArray() native "JsArray_newJsArray";

  factory JsArray.from(Iterable<E> other) => _newJsArrayFromSafeList(new List.from(other));

  static JsArray _newJsArrayFromSafeList(List list) native "JsArray_newJsArrayFromSafeList";

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
    if(index is int) {
      _checkIndex(index);
    }
    super[index] = value;
  }

  int get length native "JsArray_length";

  void set length(int length) { super['length'] = length; }

  // Methods overriden for better performance

  void add(E value) {
    callMethod('push', [value]);
  }

  void addAll(Iterable<E> iterable) {
    // TODO(jacobr): this can be optimized slightly.
    callMethod('push', new List.from(iterable));
  }

  void insert(int index, E element) {
    _checkIndex(index, insert:true);
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

// FIXME(jacobr): this method is a hack to work around the lack of proper dart
// support for varargs methods.
List _stripUndefinedArgs(List args) =>
    args.takeWhile((i) => i != _UNDEFINED).toList();

/**
 * Returns a method that can be called with an arbitrary number (for n less
 * than 11) of arguments without violating Dart type checks.
 */
Function _wrapAsDebuggerVarArgsFunction(JsFunction jsFunction) =>
  ([a1=_UNDEFINED, a2=_UNDEFINED, a3=_UNDEFINED, a4=_UNDEFINED,
    a5=_UNDEFINED, a6=_UNDEFINED, a7=_UNDEFINED, a8=_UNDEFINED,
    a9=_UNDEFINED, a10=_UNDEFINED]) =>
    jsFunction._applyDebuggerOnly(_stripUndefinedArgs(
        [a1,a2,a3,a4,a5,a6,a7,a8,a9,a10]));
