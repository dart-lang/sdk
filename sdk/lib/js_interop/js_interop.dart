// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for JS interop. Includes a JS type hierarchy to facilitate sound
/// interop with JS. The JS type hierarchy is modeled after the actual type
/// hierarchy in JS, and not the Dart type hierarchy.
///
/// Note: The JS types defined in this library only provide static guarantees.
/// The runtime types differ based on the backend, so rely on static
/// functionality like the conversion functions e.g. `toJS` and not runtime
/// mechanisms like type checks and casts.
///
/// **WARNING**:
/// This library is still a work in progress. As such, JS types, allowed syntax,
/// semantics, and functionality may all change, so avoid using this library in
/// production.
///
/// {@category Web}
library dart.js_interop;

import 'dart:_js_types';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Allow use of `@staticInterop` classes with JS types as well as export
/// functionality.
export 'dart:_js_annotations' show staticInterop, anonymous, JSExport;
export 'dart:js_util' show NullRejectionException;

/// The annotation for JS interop members.
///
/// This is meant to signify that a given library, top-level external member, or
/// inline class is a JS interop declaration.
///
/// Specifying [name] customizes the JavaScript name to use. This can be used in
/// the following scenarios:
///
/// - Namespacing all the external top-level members, static members, and
/// constructors of a library by annotating the library with a custom name.
/// - Namespacing all the external static members and constructors of an inline
/// class by annotating the inline class with a custom name.
/// - Renaming external members by annotating the member with a custom name.
///
/// In the case where [name] is not specified, we default to the Dart name for
/// inline classes and external members.
///
/// Note: `package:js` exports an `@JS` annotation as well. Unlike that
/// annotation, this is meant for inline classes, and will result in more
/// type-checking for external top-level members.
class JS {
  final String? name;
  const JS([this.name]);
}

/// The JS types users should use to write their external APIs.
///
/// These are meant to separate the Dart and JS type hierarchies statically.
///
/// **WARNING**:
/// The runtime semantics between backends differ and may not be intuitive e.g.
/// casting to [JSString] may give you inconsistent and surprising results
/// depending on the value and the backend. It is preferred to always use the
/// conversion functions e.g. `toJS` and `toDart`. You should always use interop
/// to type-check e.g. `typeofEquals` and `instanceOfString` instead of relying
/// on `is` and `as`, as the latter is backend-dependent.

/// The overall top type in the JS types hierarchy.
extension type JSAny._(JSAnyRepType _jsAny) implements Object {}

/// The representation type of all JavaScript objects for extension types.
///
/// This is the supertype of all JS objects, but not other JS types, like
/// primitives. See https://dart.dev/web/js-interop for more details on how to
/// use JS interop.
extension type JSObject._(JSObjectRepType _jsObject) implements JSAny {
  /// Constructor to go from an object from previous interop, like the types
  /// from `package:js` or `dart:html`, to [JSObject].
  ///
  /// This and the public representation field are intended to avoid users
  /// having to cast to and from [JSObject].
  JSObject.fromInteropObject(Object interopObject)
      : _jsObject = interopObject as JSObjectRepType;

  /// Returns a new object literal.
  JSObject() : _jsObject = _createObjectLiteral();
}

// TODO(srujzs): Move this to `JSObject` once we can patch extension type
// members.
external JSObjectRepType _createObjectLiteral();

/// The type of all JS functions.
extension type JSFunction._(JSFunctionRepType _jsFunction)
    implements JSObject {}

/// The type of all Dart functions adapted to be callable from JS. We only allow
/// a subset of Dart functions to be callable from JS.
// TODO(joshualitt): Detail exactly what are the requirements.
extension type JSExportedDartFunction._(
        JSExportedDartFunctionRepType _jsExportedDartFunction)
    implements JSFunction {}

/// The type of all JS arrays.
///
/// Because [JSArray] is an extension type, [T] is only a static guarantee and
/// the array does not necessarily only contain [T] elements. For example:
///
/// ```
/// @JS()
/// external JSArray<JSNumber> get array;
/// ```
///
/// We do not check that `array` actually has [JSNumber]s when calling this
/// member. The only check is that `array` is a [JSArrayRepType].
///
/// [T] may introduce additional checking elsewhere, however. When accessing
/// elements of [JSArray] with type [T], there is a check to ensure the element
/// is a [T] to ensure soundness. Similarly, when converting to a [List<T>],
/// casts may be introduced to ensure that it is indeed a [List<T>].
@JS('Array')
extension type JSArray<T extends JSAny?>._(JSArrayRepType _jsArray)
    implements JSObject {
  external JSArray();
  external JSArray.withLength(int length);
}

/// The type of JS promises and promise-like objects.
///
/// Because [JSPromise] is an extension type, [T] is only a static guarantee and
/// the [JSPromise] may not actually resolve to a [T]. Like with [JSArray], we
/// only check that this is a [JSPromiseRepType].
///
/// Also like with [JSArray], [T] may introduce additional checking elsewhere.
/// When converted to a [Future<T>], there is a cast to ensure that the [Future]
/// actually resolves to a [T] to ensure soundness.
@JS('Promise')
extension type JSPromise<T extends JSAny?>._(JSPromiseRepType _jsPromise)
    implements JSObject {
  external JSPromise(JSFunction executor);
}

/// The type of the boxed Dart object that can be passed to JS safely. There is
/// no interface specified of this boxed object, and you may get a new box each
/// time you box the same Dart object.
extension type JSBoxedDartObject._(JSBoxedDartObjectRepType _jsBoxedDartObject)
    implements JSObject {}

/// The type of JS' `ArrayBuffer`.
extension type JSArrayBuffer._(JSArrayBufferRepType _jsArrayBuffer)
    implements JSObject {}

/// The type of JS' `DataView`.
extension type JSDataView._(JSDataViewRepType _jsDataView)
    implements JSObject {}

/// The abstract supertype of all JS typed arrays.
extension type JSTypedArray._(JSTypedArrayRepType _jsTypedArray)
    implements JSObject {}

/// The type of JS' `Int8Array`.
extension type JSInt8Array._(JSInt8ArrayRepType _jsInt8Array)
    implements JSTypedArray {}

/// The type of JS' `Uint8Array`.
extension type JSUint8Array._(JSUint8ArrayRepType _jsUint8Array)
    implements JSTypedArray {}

/// The type of JS' `Uint8ClampedArray`.
extension type JSUint8ClampedArray._(
    JSUint8ClampedArrayRepType _jsUint8ClampedArray) implements JSTypedArray {}

/// The type of JS' `Int16Array`.
extension type JSInt16Array._(JSInt16ArrayRepType _jsInt16Array)
    implements JSTypedArray {}

/// The type of JS' `Uint16Array`.
extension type JSUint16Array._(JSUint16ArrayRepType _jsUint16Array)
    implements JSTypedArray {}

/// The type of JS' `Int32Array`.
extension type JSInt32Array._(JSInt32ArrayRepType _jsInt32Array)
    implements JSTypedArray {}

/// The type of JS' `Uint32Array`.
extension type JSUint32Array._(JSUint32ArrayRepType _jsUint32Array)
    implements JSTypedArray {}

/// The type of JS' `Float32Array`.
extension type JSFloat32Array._(JSFloat32ArrayRepType _jsFloat32Array)
    implements JSTypedArray {}

/// The type of JS' `Float64Array`.
extension type JSFloat64Array._(JSFloat64ArrayRepType _jsFloat64Array)
    implements JSTypedArray {}

// The various JS primitive types. Crucially, unlike the Dart type hierarchy,
// none of these are subtypes of [JSObject], but rather they are logically
// subtypes of [JSAny].

/// The type of JS numbers.
extension type JSNumber._(JSNumberRepType _jsNumber) implements JSAny {}

/// The type of JS booleans.
extension type JSBoolean._(JSBooleanRepType _jsBoolean) implements JSAny {}

/// The type of JS strings.
extension type JSString._(JSStringRepType _jsString) implements JSAny {}

/// The type of JS `Symbol`s.
extension type JSSymbol._(JSSymbolRepType _jsSymbol) implements JSAny {}

/// The type of JS `BigInt`s.
extension type JSBigInt._(JSBigIntRepType _jsBigInt) implements JSAny {}

/// A getter to retrieve the global context that is used in static interop
/// lowering.
external JSObject get globalContext;

/// JS `undefined` and JS `null` are internalized differently based on the
/// backends. In the JS backends, Dart `null` can actually be JS `undefined` or
/// JS `null`. In dart2wasm, that's not the case: there's only one Wasm value
/// `null` can be. Therefore, when we get back JS `null` or JS `undefined`, we
/// internalize both as Dart `null` in dart2wasm, and when we pass Dart `null`
/// to an interop API, we pass JS `null`. In the JS backends, Dart `null`
/// retains its original value when passed back to an interop API. Be wary of
/// writing code where this distinction between `null` and `undefined` matters.
// TODO(srujzs): Investigate what it takes to allow users to distinguish between
// the two "nullish" values. An annotation-based model where users annotate
// interop APIs to internalize `undefined` differently seems promising, but does
// not handle some cases like converting a `JSArray` with `undefined`s in it to
// `List<JSAny?>`. In this case, the implementation of the list wrapper needs to
// make the decision, not the user.
extension NullableUndefineableJSAnyExtension on JSAny? {
  /// Determine if this value corresponds to JS `undefined`.
  ///
  /// **WARNING**: Currently, there isn't a way to distinguish between JS
  /// `undefined` and JS `null` in dart2wasm. As such, this should only be used
  /// for code that compiles to JS and will throw on dart2wasm.
  external bool get isUndefined;

  /// Determine if this value corresponds to JS `null`.
  ///
  /// **WARNING**: Currently, there isn't a way to distinguish between JS
  /// `undefined` and JS `null` in dart2wasm. As such, this should only be used
  /// for code that compiles to JS and will throw on dart2wasm.
  external bool get isNull;

  bool get isUndefinedOrNull => this == null;
  bool get isDefinedAndNotNull => !isUndefinedOrNull;
}

/// Common utility functions that are useful for any JS value.
extension JSAnyUtilityExtension on JSAny? {
  /// Returns whether the result of `typeof` on this [JSAny]? is [typeString].
  external bool typeofEquals(String typeString);

  /// Returns whether this [JSAny]? is an `instanceof` [constructor].
  external bool instanceof(JSFunction constructor);

  /// Like [instanceof], but only takes a [String] for the constructor name,
  /// which is then looked up in the [globalContext].
  bool instanceOfString(String constructorName) {
    final constructor = globalContext[constructorName] as JSFunction?;
    return constructor != null && instanceof(constructor);
  }

  /// Effectively the inverse of [jsify], [dartify] Takes a JavaScript object,
  /// and converts it to a Dart based object. Only JS primitives, arrays, or
  /// 'map' like JS objects are supported.
  external Object? dartify();
}

/// Utility extensions for [Object?].
extension NullableObjectUtilExtension on Object? {
  /// Recursively converts a JSON-like collection, or Dart primitive to a
  /// JavaScript compatible representation.
  external JSAny? jsify();
}

/// The type of `JSUndefined` when returned from functions. Unlike pure JS,
/// no actual object will be returned.
// TODO(srujzs): Should we just remove this? There are no performance costs from
// using `void`, and we'll likely provide a different way to box `undefined`.
typedef JSVoid = JSVoidRepType;

// Extension members to support conversions between Dart types and JS types.
// Not all Dart types can be converted to JS types and vice versa.
// TODO(joshualitt): We might want to investigate using extension types instead
// of extension methods for these methods.

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  external Function get toDart;
}

extension FunctionToJSExportedDartFunction on Function {
  external JSExportedDartFunction get toJS;
}

/// Utility extensions for [JSFunction].
extension JSFunctionUtilExtension on JSFunction {
  // Take at most 4 args for consistency with other APIs and relative brevity.
  // If more are needed, you can declare your own external member. We rename
  // this function since declaring a `call` member makes a class callable in
  // Dart. This is convenient, but unlike Dart functions, JS functions
  // explicitly take a `this` argument (which users can provide `null` for in
  // the case where the function doesn't need it), which may lead to confusion.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/call
  @JS('call')
  external JSAny? callAsFunction(
      [JSAny? thisArg, JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);
}

/// [JSBoxedDartObject] <-> [Object]
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  external Object get toDart;
}

extension ObjectToJSBoxedDartObject on Object {
  external JSBoxedDartObject get toJSBox;
}

/// [JSPromise] -> [Future].
extension JSPromiseToFuture<T extends JSAny?> on JSPromise<T> {
  external Future<T> get toDart;
}

extension FutureOfJSAnyToJSPromise<T extends JSAny?> on Future<T> {
  JSPromise<T> get toJS {
    return JSPromise<T>((JSFunction resolve, JSFunction reject) {
      this.then((JSAny? value) {
        resolve.callAsFunction(resolve, value);
        return value;
      }, onError: (Object error, StackTrace stackTrace) {
        // TODO(srujzs): Can we do something better here? This is pretty much
        // useless to the user unless they call a Dart callback that consumes
        // this value and unboxes.
        final errorConstructor = globalContext['Error'] as JSFunction;
        final wrapper = errorConstructor.callAsConstructor<JSObject>(
            "Dart exception thrown from converted Future. Use the properties "
                    "'error' to fetch the boxed error and 'stack' to recover "
                    "the stack trace."
                .toJS);
        wrapper['error'] = error.toJSBox;
        wrapper['stack'] = stackTrace.toString().toJS;
        reject.callAsFunction(reject, wrapper);
        return wrapper;
      });
    }.toJS);
  }
}

extension FutureOfVoidToJSPromise on Future<void> {
  JSPromise get toJS {
    return JSPromise((JSFunction resolve, JSFunction reject) {
      this.then((_) => resolve.callAsFunction(resolve),
          onError: (Object error, StackTrace stackTrace) {
        // TODO(srujzs): Can we do something better here? This is pretty much
        // useless to the user unless they call a Dart callback that consumes
        // this value and unboxes.
        final errorConstructor = globalContext['Error'] as JSFunction;
        final wrapper = errorConstructor.callAsConstructor<JSObject>(
            "Dart exception thrown from converted Future. Use the properties "
                    "'error' to fetch the boxed error and 'stack' to recover "
                    "the stack trace."
                .toJS);
        wrapper['error'] = error.toJSBox;
        wrapper['stack'] = stackTrace.toString().toJS;
        reject.callAsFunction(reject, wrapper);
      });
    }.toJS);
  }
}

// **WARNING**:
// Currently, the `toJS` getters on `dart:typed_data` types have inconsistent
// semantics today between dart2wasm and the JS compilers. dart2wasm copies the
// contents over, while the JS compilers passes the typed arrays by reference as
// they are JS typed arrays under the hood. Do not rely on modifications to the
// Dart type to affect the JS type.
//
// All the `toDart` getters on the JS typed arrays will introduce a wrapper
// around the JS typed array, however. So modifying the Dart type will modify
// the JS type and vice versa in that case.

/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  external ByteBuffer get toDart;
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  external JSArrayBuffer get toJS;
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  external ByteData get toDart;
}

extension ByteDataToJSDataView on ByteData {
  external JSDataView get toJS;
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  external Int8List get toDart;
}

extension Int8ListToJSInt8Array on Int8List {
  external JSInt8Array get toJS;
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  external Uint8List get toDart;
}

extension Uint8ListToJSUint8Array on Uint8List {
  external JSUint8Array get toJS;
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  external Uint8ClampedList get toDart;
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  external JSUint8ClampedArray get toJS;
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  external Int16List get toDart;
}

extension Int16ListToJSInt16Array on Int16List {
  external JSInt16Array get toJS;
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  external Uint16List get toDart;
}

extension Uint16ListToJSInt16Array on Uint16List {
  external JSUint16Array get toJS;
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  external Int32List get toDart;
}

extension Int32ListToJSInt32Array on Int32List {
  external JSInt32Array get toJS;
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  external Uint32List get toDart;
}

extension Uint32ListToJSUint32Array on Uint32List {
  external JSUint32Array get toJS;
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  external Float32List get toDart;
}

extension Float32ListToJSFloat32Array on Float32List {
  external JSFloat32Array get toJS;
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  external Float64List get toDart;
}

extension Float64ListToJSFloat64Array on Float64List {
  external JSFloat64Array get toJS;
}

/// [JSArray] <-> [List]
extension JSArrayToList<T extends JSAny?> on JSArray<T> {
  /// Returns a list wrapper of the JS array.
  ///
  /// Modifying the JS array will modify the returned list and vice versa.
  external List<T> get toDart;
}

extension ListToJSArray<T extends JSAny?> on List<T> {
  /// Compiler-specific conversion from list to JS array.
  ///
  /// This is either a pass-by-reference, unwrap, or copy depending on the
  /// implementation of the given list, and users shouldn't rely on
  /// modifications to the list to affect the array or vice versa.
  external JSArray<T> get toJS;

  /// Either passes by reference, unwraps, or creates a heavyweight proxy that
  /// wraps the list.
  ///
  /// Only use this member if you want modifications to the list to also affect
  /// the JS array and vice versa. In practice, dart2js and DDC will pass lists
  /// by reference and dart2wasm will add a proxy or unwrap for most lists.
  ///
  /// **WARNING**: Do not rely on this to be performant.
  external JSArray<T> get toJSProxyOrRef;
}

/// [JSNumber] -> [double] or [int].
extension JSNumberToNumber on JSNumber {
  /// Returns a Dart [double] for the given [JSNumber].
  external double get toDartDouble;

  /// Returns a Dart [int] for the given [JSNumber].
  ///
  /// If the [JSNumber] is not an integer value, throws.
  external int get toDartInt;
}

/// [double] -> [JSNumber].
extension DoubleToJSNumber on double {
  external JSNumber get toJS;
}

/// [num] -> [JSNumber].
extension NumToJSExtension on num {
  JSNumber get toJS => DoubleToJSNumber(toDouble()).toJS;
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  external bool get toDart;
}

extension BoolToJSBoolean on bool {
  external JSBoolean get toJS;
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  external String get toDart;
}

extension StringToJSString on String {
  external JSString get toJS;
}

// General-purpose operators.
//
// Indexing operators (`[]`, `[]=`) should be declared through operator
// overloading instead e.g. `external operator int [](int key);`.
// TODO(srujzs): Add more as needed. For now, we just expose the ones needed to
// migrate from `dart:js_util`.
extension JSAnyOperatorExtension on JSAny? {
  // Artithmetic operators.

  /// Returns the result of '[this] + [any]' in JS.
  external JSAny add(JSAny? any);

  /// Returns the result of '[this] - [any]' in JS.
  external JSAny subtract(JSAny? any);

  /// Returns the result of '[this] * [any]' in JS.
  external JSAny multiply(JSAny? any);

  /// Returns the result of '[this] / [any]' in JS.
  external JSAny divide(JSAny? any);

  /// Returns the result of '[this] % [any]' in JS.
  external JSAny modulo(JSAny? any);

  /// Returns the result of '[this] ** [any]' in JS.
  external JSAny exponentiate(JSAny? any);

  // Comparison operators.

  /// Returns the result of '[this] > [any]' in JS.
  external JSBoolean greaterThan(JSAny? any);

  /// Returns the result of '[this] >= [any]' in JS.
  external JSBoolean greaterThanOrEqualTo(JSAny? any);

  /// Returns the result of '[this] < [any]' in JS.
  external JSBoolean lessThan(JSAny? any);

  /// Returns the result of '[this] <= [any]' in JS.
  external JSBoolean lessThanOrEqualTo(JSAny? any);

  /// Returns the result of '[this] == [any]' in JS.
  external JSBoolean equals(JSAny? any);

  /// Returns the result of '[this] != [any]' in JS.
  external JSBoolean notEquals(JSAny? any);

  /// Returns the result of '[this] === [any]' in JS.
  external JSBoolean strictEquals(JSAny? any);

  /// Returns the result of '[this] !== [any]' in JS.
  external JSBoolean strictNotEquals(JSAny? any);

  // Bitwise operators.

  /// Returns the result of '[this] >>> [any]' in JS.
  external JSNumber unsignedRightShift(JSAny? any);

  // Logical operators.

  /// Returns the result of '[this] && [any]' in JS.
  external JSAny? and(JSAny? any);

  /// Returns the result of '[this] || [any]' in JS.
  external JSAny? or(JSAny? any);

  /// Returns the result of '![this]' in JS.
  external bool get not;

  /// Returns the result of '!![this]' in JS.
  external bool get isTruthy;
}

// Top-levels.

/// Given a Dart object that is marked "exportable", creates a JS object that
/// wraps the given Dart object. Look at the `@JSExport` annotation to determine
/// what constitutes "exportable" for a Dart class. The object literal
/// will be a map of export names (which are either the written instance member
/// names or their rename) to their respective Dart instance members.
///
/// For example:
///
/// ```
/// import 'dart:js_interop';
///
/// import 'package:expect/expect.dart';
///
/// @JSExport()
/// class ExportCounter {
///   @JSExport('value')
///   int counterValue = 0;
///   String stringify() => counterValue.toString();
/// }
///
/// extension type Counter(JSObject _) {
///   external int get value;
///   external set value(int val);
///   external String stringify();
/// }
///
/// void main() {
///   var export = ExportCounter();
///   var counter = Counter(createJSInteropWrapper(export));
///   export.counterValue = 1;
///   Expect.equals(counter.value, export.counterValue);
///   Expect.equals(counter.stringify(), export.stringify());
/// }
/// ```
external JSObject createJSInteropWrapper<T extends Object>(T dartObject);

// TODO(srujzs): Expose this method when we handle conformance checking for
// interop extension types. We don't expose this method today due to the bound
// on `T`. `@staticInterop` types can't implement `JSObject`, so this method
// simply wouldn't work. We could make it extend `Object` to support the
// `@staticInterop` case, but if we ever refactor to `extends JSObject`, this
// would be a breaking change. For now, due to the low usage of
// `createStaticInteropMock`, we avoid introducing this method until later.
// external T createJSInteropMock<T extends JSObject, U extends Object>(
//     U dartMock, [JSObject? proto = null]);

/// Call to dynamically import a JS module with the given [moduleName] using the
/// JS `import()` syntax.
///
/// See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/import
/// for more details.
///
/// Returns a [JSPromise] that resolves to a [JSObject] that's the module
/// namespace object.
external JSPromise<JSObject> importModule(String moduleName);
