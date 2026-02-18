// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interoperability, "interop" for short, with JavaScript and browser APIs.
///
/// JavaScript interop allows a Dart program to interact with a JavaScript
/// runtime. This can, for example, be to access JavaScript declarations and
/// interact with JavaScript values, or to adapt Dart values so that they can be
/// passed to and used by JavaScript code.
///
/// This JavaScript interop library works by introducing an abstraction over
/// JavaScript values, a Dart type hierarchy ("JS types") which mirrors known
/// JavaScript types, and a framework for introducing new Dart types that bind
/// Dart type declarations to JavaScript values and external member declarations
/// to JavaScript APIs.
///
/// This abstraction allows the same interop API to be used both when the Dart
/// code is compiled to JavaScript and when compiled to Wasm.
///
/// See https://dart.dev/interop/js-interop for more details on usage, types,
/// and previous JavaScript interop.
///
/// > [!NOTE]
/// > The types defined in this library only provide static guarantees. The
/// > runtime types differ based on the backend, so it is important to rely on
/// > static functionality like the conversion functions. Similarly, don't rely
/// > on `is` checks that involve JS types or JS-typed values. Furthermore,
/// > `identical` may also return different results for the same JS value
/// > depending on the compiler. Use `==` to check for equality of two JS-typed
/// > values instead, but do not check for equality between a Dart value and a
/// > JS-typed value.
///
/// {@category Web}
library;

import 'dart:_internal' show Since;
import 'dart:_js_types';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// An annotation on a JavaScript interop declaration.
///
/// This annotation defines a given library, top-level external declaration, or
/// extension type as a JavaScript interop declaration.
///
/// Specifying [name] customizes the JavaScript name to use, which can be used
/// in the following scenarios:
///
/// - Adding a JavaScript prefix to all the external top-level declarations,
///   static members, and constructors of a library by parameterizing the
///   annotation on the library with [name].
/// - Specifying the JavaScript class to use for external static members and
///   constructors of an interop extension type by parameterizing the annotation
///   on the interop extension type with [name].
/// - Renaming external declarations by parameterizing the annotation on the
///   member with [name].
///
/// In the case where [name] is not specified, the Dart name of the extension
/// type or external declaration is used as the default.
///
/// See https://dart.dev/interop/js-interop/usage#js for more details on how to
/// use this annotation.
///
/// > [!NOTE]
/// > `package:js` exports an `@JS` annotation as well. Unlike that annotation,
/// > this annotation applies to extension types, and will result in more
/// > type-checking for external top-level declarations.
class JS {
  final String? name;
  const JS([this.name]);
}

// To support an easier transition, we allow users to use `@staticInterop`
// classes - with or without the `@anonymous` annotation.

class _StaticInterop {
  const _StaticInterop();
}

/// [staticInterop] enables the [JS] annotated class to be treated as a "static"
/// interop class.
///
/// These classes allow interop with native types, like the ones in `dart:html`.
/// These classes implicitly all erase to the internal interceptor
/// `JavaScriptObject`, so they can be freely casted to and from other
/// [staticInterop] types, `dart:html` types, and `JSObject` from
/// `dart:js_interop`. Non-[staticInterop] `package:js` types can be casted to
/// [staticInterop] types, but the reverse can fail if the underlying value is a
/// `@Native`-reserved type (like `dart:html` types).
///
/// [staticInterop] classes have the following restrictions:
///  - They must contain a [JS] annotation, either from this library or from
///    `dart:js_interop`.
///  - They should not contain any instance members, inherited or otherwise, and
///    should instead use static extension members, which can be external or
///    non-external.
///  - They can only contain factories and `static` members. They can be
///    combined with [anonymous] to make external factories create new
///    JavaScript object literals instead.
///  - They should not implement, extend, or mixin non-[staticInterop] classes
///    and vice-versa.
///  - The annotation should only be applied to non-mixin classes and no other
///    declarations.
const _StaticInterop staticInterop = _StaticInterop();

class _Anonymous {
  const _Anonymous();
}

/// An annotation that indicates a [JS] annotated class is structural and does
/// not have a known JavaScript prototype.
///
/// A class marked with [anonymous] allows external factories with named
/// parameters. Invoking these factories creates JavaScript object literals with
/// name-value pairs corresponding to any named parameters and their values. If
/// there are no named parameters, an empty JavaScript object is created.
///
/// [anonymous] classes have the following restrictions:
///   - They must contain a [JS] annotation, either from this library or from
///     `dart:js_interop`. If the latter, the class must also contain
///     [staticInterop].
///   - They cannot contain any non-external members unless it's a
///     [staticInterop] class, in which case it can also contain non-external
///     factories and static methods.
///   - They cannot contain any external generative constructors.
///   - Any external factory must not contain any positional parameters.
///   - They cannot extend or be extended by a non-[JS] annotated class.
///   - The annotation should only be applied to non-mixin classes and no other
///     declarations.
const _Anonymous anonymous = _Anonymous();

/// Annotation to allow Dart classes to be wrapped with a JS object using
/// `dart:js_interop`'s `createJSInteropWrapper`.
///
/// When an instance of a class annotated with this annotation is passed to
/// `createJSInteropWrapper`, the method returns a JS object that contains
/// a property for each of the class' instance members. When called, these
/// properties forward to the instance's corresponding members.
///
/// You can either annotate specific instance members to only wrap those members
/// or you can annotate the entire class, which will include all of its instance
/// members.
///
/// By default, the property will have the same name as the corresponding
/// instance member. You can change the property name of a member in the JS
/// object by providing a [name] in the @[JSExport] annotation on the member,
/// like so:
/// ```
/// class Export {
///   @JSExport('printHelloWorld')
///   void printMessage() => print('Hello World!');
/// }
/// ```
/// which will then set the property 'printHelloWorld' in the JS object to
/// forward to `printMessage`.
///
/// Classes and mixins in the hierarchy of the annotated class are included only
/// if they are annotated as well or specific members in them are annotated. If
/// a superclass does not have an annotation anywhere, its members are not
/// included. If members are overridden, only the overriding member will
/// be wrapped as long as it or its class has this annotation.
///
/// Only concrete instance members can and will be wrapped, and it's an error to
/// annotate other members with this annotation.
class JSExport {
  final String name;
  const JSExport([this.name = '']);
}

@JS('Reflect.get')
external JSAny? _getPropertyForJSAny(JSAny value, JSAny property);

/// A non-nullish JavaScript value.
///
/// A [JSAny] can be any JavaScript value except JavaScript `null` and
/// `undefined`. JavaScript `null` and `undefined` are instead converted to Dart
/// `null` by the compiler. Therefore, <code>[JSAny]?</code> is the top type of
/// the type hierarchy as it includes nullish JavaScript values as well.
extension type JSAny._(JSAnyType _jsAny) implements Object, JSAnyType {
  /// Like `JSObjectUnsafeExtension.getProperty`, but works for any JS type.
  R _getProperty<R extends JSAny?>(JSAny property) =>
      _getPropertyForJSAny(this, property) as R;

  /// Like `JSObjectUnsafeExtension.callMethod`, but works for any JS type.
  R _callMethod<R extends JSAny?>(JSAny method) =>
      _getProperty<JSFunction>(method).callAsFunction(this) as R;
}

/// A JavaScript `Object`.
///
/// [JSObject] is the supertype of all JavaScript objects, but not other JS
/// types, like primitives. See https://dart.dev/interop/js-interop for more
/// details on how to use JavaScript interop.
///
/// When declaring interop extension types, [JSObject] is usually the type you
/// will use as the representation type.
@JS('Object')
extension type JSObject._(JSObjectType _jsObject)
    implements JSAny, JSObjectType {
  /// Creates a [JSObject] from an object provided by an earlier interop
  /// library.
  ///
  /// Accepts, for example, the types created using `package:js` or `dart:html`.
  ///
  /// This constructor is intended to allow users to avoid having to cast to and
  /// from [JSObject].
  JSObject.fromInteropObject(Object interopObject)
    : _jsObject = interopObject as JSObjectType;

  /// Creates a new empty JavaScript object.
  ///
  /// The object is created using the JavaScript object initializer syntax
  /// (`{}`), and this constructor is more efficient than `{}.jsify()`.
  JSObject() : _jsObject = _createObjectLiteral();
}

// TODO(srujzs): Move this member to `JSObject` once we can patch extension type
// members.
external JSObjectType _createObjectLiteral();

/// A JavaScript [`Function`](https://tc39.es/ecma262/#sec-function-objects)
/// value.
@JS('Function')
extension type JSFunction._(JSFunctionType _jsFunction)
    implements JSObject, JSFunctionType {}

/// A JavaScript callable function created from a Dart function.
///
/// See [FunctionToJSExportedDartFunction.toJS] or
/// [FunctionToJSExportedDartFunction.toJSCaptureThis] for more details on how
/// to convert a Dart function.
@JS('Function')
extension type JSExportedDartFunction._(
  JSExportedDartFunctionType _jsExportedDartFunction
)
    implements JSFunction, JSExportedDartFunctionType {}

/// An object that implements the synchronous [JS iterable protocol].
///
/// [JS iterable protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterable_protocol
///
/// This interface represents the minimal protocol necessary to interact with JS
/// features like `for`/`of`. In practice, all JS standard library types
/// implement [JSIterable] as well, which returns a [JSIterator] object which
/// supports many utility methods.
@Since('3.12')
extension type JSIterableProtocol<T extends JSAny?>._(JSAnyType _)
    implements JSAny {
  /// See [`[Symbol.iterator]()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#symbol.iterator).
  JSIteratorProtocol<T> get iterator => _callMethod(JSSymbol.iterator);
}

/// An interface for built-in JS objects that not only implement the synchronous
/// [JS iterable protocol] but return a full-fledged [Iterator] object with all
/// its utility methods.
///
/// [JS iterable protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterable_protocol
/// [Iterator]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterator
///
/// All types that implement [JSIterableProtocol] in the JS core library are
/// [JSIterable]s, but user-defined [JSIterableProtocol] implementations may not
/// be.
@Since('3.12')
extension type JSIterable<T extends JSAny?>._(JSAnyType _)
    implements JSIterableProtocol<T> {
  /// See [`[Symbol.iterator]()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#symbol.iterator).
  /// Unlike [JSIterableProtocol.iterator], this always returns a full-fledged
  /// [JSIterator].
  JSIterator<T> get iterator => _callMethod<JSIterator<T>>(JSSymbol.iterator);
}

/// An object that implements the synchronous [JS iterator protocol].
///
/// [JS iterator protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterator_protocol
///
/// This is the minimal interface that JS iterators are allowed to implement in
/// order to work with core library APIs and language features like `for`/`of`.
/// Iterators are strongly encouraged to also extend the [JSIterator] class
/// which adds various utility methods, in which case they're referred to as
/// "proper iterators". All iterators returned by the core library are proper.
@Since('3.12')
extension type JSIteratorProtocol<T extends JSAny?>._(JSAny _)
    implements JSAny {
  @JS('return')
  external JSFunction? get _nullableReturnValue;

  @JS('throw')
  external JSFunction? get _nullableThrowError;

  /// See [`next()`].
  ///
  /// [`next()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#next
  external JSIteratorResult<T> next([JSAny? yieldValue]);

  @JS('return')
  external JSIteratorResult<T> _returnValue([JSAny? value]);

  /// See [`return()`].
  ///
  /// This is a nullable getter because not all iterators support this method.
  ///
  /// [`return()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#returnvalue
  JSIteratorResult<T> Function([JSAny? value])? get returnValue =>
      // Make sure to pass along whether an argument was passed or not, because
      // that's observable from JavaScript.
      _nullableReturnValue == null
      ? null
      : ([value]) => value == null ? _returnValue() : _returnValue(value);

  @JS('throw')
  external JSIteratorResult<T> _throwError([JSAny? error]);

  /// See [`throw()`].
  ///
  /// This is a nullable getter because not all iterators support this method.
  ///
  /// [`throw()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#throwexception
  @JS('throw')
  JSIteratorResult<T> Function([JSAny? error])? get throwError =>
      // Make sure to pass along whether an argument was passed or not, because
      // that's observable from JavaScript.
      _nullableThrowError == null
      ? null
      : ([error]) => error == null ? _throwError() : _throwError(error);
}

/// A subtype of the [JS Iterator class] that also implements the [Iterator
/// protocol].
///
/// In JS terms, an object that meets both of these qualifications is called a
/// "proper iterator". In Dart, we call it a `JSIterator` and we call an object
/// that only implements the iterator protocol a [JSIteratorProtocol]. (There's
/// no need to represent an instance of the `Iterator` class that doesn't also
/// follow the Iterator protocol, because this isn't something that's ever
/// expected to appear in well-behaved libraries.)
///
/// [JS Iterator class]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterator#proper_iterators
/// [Iterator protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterator_protocol
@JS('Iterator')
@Since('3.12')
extension type JSIterator<T extends JSAny?>._(JSObject _)
    implements JSIteratorProtocol<T>, JSIterable<T> {
  /// Converts an object that just implements the [Iterator protocol] into a
  /// proper iterator.
  ///
  /// [Iterator protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterator_protocol
  external static JSIterator<T> from<T extends JSAny?>(
    JSIteratorProtocol<T> object,
  );

  /// Creates a proper iterator from an object that just implements the
  /// [Iterable protocol].
  ///
  /// [Iterable protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols
  ///
  /// This is equivalent to `JSIterator.from(object.iterator)`.
  @JS('from')
  external static JSIterator<T> fromIterable<T extends JSAny?>(
    JSIterableProtocol<T> object,
  );

  /// Creates a proper [JSIterator] from the methods defined by the [Iterator
  /// protocol].
  ///
  /// [Iterator protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterator_protocol
  ///
  /// This is the best way to create a custom JS iterator from Dart code. To
  /// convert an existing Dart iterable, use
  /// [IterableToJSIterable.toJSIterable], and to convert an existing Dart
  /// iterator use [IteratorToJSIterator.toJSIterator]
  static JSIterator<T> fromFunctions<T extends JSAny?>(
    JSIteratorResult<T> Function() next, {
    JSIteratorResult<T> Function()? returnValue,
  }) {
    final iterator = _CustomIteratorProtocol<T>(next: next.toJS);
    if (returnValue != null) iterator.returnValue = returnValue.toJS;
    return from<T>(iterator);
  }

  /// See [`Iterator.drop()`].
  ///
  /// [`Iterator.drop()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterator/drop
  external JSIterator<T> drop(int limit);

  /// See [`Iterator.every()`].
  ///
  /// [`Iterator.every()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterator/every
  bool every(bool Function(T element) callback) => _every(callback.toJS);

  /// See [`Iterator.every()`].
  ///
  /// [`Iterator.every()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterator/every
  bool everyWithIndex(bool Function(T element, int index) callback) =>
      _every(callback.toJS);

  @JS('every')
  external bool _every(JSFunction callback);

  /// See [`Iterable.filter()`].
  ///
  /// [`Iterable.filter()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/filter
  JSIterator<T> filter(bool Function(T element) callback) =>
      _filter(callback.toJS);

  /// See [`Iterable.filter()`].
  ///
  /// [`Iterable.filter()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/filter
  JSIterator<T> filterWithIndex(bool Function(T element, int index) callback) =>
      _filter(callback.toJS);

  @JS('filter')
  external JSIterator<T> _filter(JSFunction callback);

  /// See [`Iterable.find()`].
  ///
  /// [`Iterable.find()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/find
  T find(bool Function(T element) callback) => _find(callback.toJS);

  /// See [`Iterable.find()`].
  ///
  /// [`Iterable.find()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/find
  T findWithIndex(bool Function(T element, int index) callback) =>
      _find(callback.toJS);

  @JS('find')
  external T _find(JSFunction callback);

  /// See [`Iterable.flatMap()`].
  ///
  /// [`Iterable.flatMap()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/flatMap
  JSIterator<S> flatMap<S extends JSAny?>(
    JSIterableProtocol<S> Function(T element) callback,
  ) => _flatMap(callback.toJS) as JSIterator<S>;

  /// See [`Iterable.flatMap()`].
  ///
  /// [`Iterable.flatMap()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/flatMap
  JSIterator<S> flatMapWithIndex<S extends JSAny?>(
    JSIterableProtocol<S> Function(T element, int index) callback,
  ) => _flatMap(callback.toJS) as JSIterator<S>;

  /// See [`Iterable.flatMap()`].
  ///
  /// This overload allows the callback to return either arrays or individual
  /// values, at the expense of type safety.
  ///
  /// [`Iterable.flatMap()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/flatMap
  JSIterator flatMapHeterogeneous(JSAny? Function(T element) callback) =>
      _flatMap(callback.toJS);

  /// See [`Iterable.flatMap()`].
  ///
  /// This overload allows the callback to return either arrays or individual
  /// values, at the expense of type safety.
  ///
  /// [`Iterable.flatMap()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/flatMap
  JSIterator flatMapHeterogeneousWithIndex(
    JSAny? Function(T element, int index) callback,
  ) => _flatMap(callback.toJS);

  @JS('flatMap')
  external JSIterator _flatMap(JSFunction callback);

  /// See [`Iterable.forEach()`].
  ///
  /// [`Iterable.forEach()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/forEach
  void forEach(void Function(T element) callback) => _forEach(callback.toJS);

  /// See [`Iterable.forEach()`].
  ///
  /// [`Iterable.forEach()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/forEach
  void forEachWithIndex(void Function(T element, int index) callback) =>
      _forEach(callback.toJS);

  @JS('forEach')
  external void _forEach(JSFunction callback);

  /// See [`Iterable.map()`].
  ///
  /// [`Iterable.map()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/map
  JSIterator<S> map<S extends JSAny?>(S Function(T element) callback) =>
      _map(callback.toJS) as JSIterator<S>;

  /// See [`Iterable.map()`].
  ///
  /// [`Iterable.map()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/map
  JSIterator<S> mapWithIndex<S extends JSAny?>(
    S Function(T element, int index) callback,
  ) => _map(callback.toJS) as JSIterator<S>;

  @JS('map')
  external JSIterator _map(JSFunction callback);

  /// See [`Iterable.reduce()`].
  ///
  /// [`Iterable.reduce()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/reduce
  T reduce(T Function(T accumulator, T currentValue) callback) =>
      _reduce(callback.toJS) as T;

  /// See [`Iterable.reduce()`].
  ///
  /// [`Iterable.reduce()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/reduce
  T reduceWithIndex(
    T Function(T accumulator, T currentValue, int index) callback,
  ) => _reduce(callback.toJS) as T;

  /// See [`Iterable.reduce()`].
  ///
  /// [`Iterable.reduce()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/reduce
  S reduceWithInitial<S extends JSAny?>(
    S Function(S accumulator, T currentValue) callback,
    S initialValue,
  ) => _reduce(callback.toJS, initialValue) as S;

  /// See [`Iterable.reduce()`].
  ///
  /// [`Iterable.reduce()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/reduce
  S reduceWithInitialAndIndex<S extends JSAny?>(
    S Function(S accumulator, T currentValue, int index) callback,
    S initialValue,
  ) => _reduce(callback.toJS, initialValue) as S;

  @JS('reduce')
  external JSAny? _reduce(JSFunction callback, [JSAny? initialValue]);

  /// See [`Iterable.some()`].
  ///
  /// [`Iterable.some()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/some
  bool some(bool Function(T element) callback) => _some(callback.toJS);

  /// See [`Iterable.some()`].
  ///
  /// [`Iterable.some()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterable/some
  bool someWithIndex(bool Function(T element, int index) callback) =>
      _some(callback.toJS);

  @JS('some')
  external bool _some(JSFunction callback);

  /// See [`Iterator.take()`].
  ///
  /// [`Iterator.take()`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Iterator/take
  external JSIterator<T> take(int limit);
}

/// A custom type that exposes the JS [Iterator protocol]. This is never
/// returned directly, only wrapped by [JSIterator.from] to produce a proper
/// iterator.
///
/// [Iterator protocol]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#the_iterator_protocol
extension type _CustomIteratorProtocol<T extends JSAny?>._(JSObject _)
    implements JSIteratorProtocol<T> {
  @JS('return')
  set _returnValue(JSFunction? function);

  external _CustomIteratorProtocol({required JSFunction next});
}

/// An object that implements the synchronous [JS `IteratorResult` interface].
///
/// [JS `IteratorResult` interface]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#done
@Since('3.12')
extension type JSIteratorResult<T extends JSAny?>._(JSObject _)
    implements JSObject {
  /// Creates a result that indicates the end of iteration. The value is the
  /// "return value" of the iterator.
  factory JSIteratorResult.done([T? returnValue]) {
    final result = JSIteratorResult<T>._(JSObject());
    result._done = true;
    if (returnValue != null) result._value = returnValue;
    return result;
  }

  /// Creates a result that indicates the iterator is emitting a value and is
  /// not yet finished.
  factory JSIteratorResult.value(T value) {
    final result = JSIteratorResult<T>._(JSObject());
    result._value = value;
    return result;
  }

  // Wrap this to hide the distinction between undefined and false from users.
  @JS('done')
  external bool? _done;

  /// Wrap this so that the setter is private.
  @JS('value')
  external T? _value;

  /// See [`done`].
  ///
  /// [`done`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#done
  bool get isDone => _done == true;

  /// See [`value`].
  ///
  /// [`value`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#value
  external T? get value;
}

/// A JavaScript [`Array`](https://tc39.es/ecma262/#sec-array-objects).
///
/// Because [JSArray] is an extension type, [T] is only a static guarantee and
/// the array does not necessarily only contain [T] elements. For example:
///
/// ```dart
/// @JS()
/// external JSArray<JSNumber> get array;
/// ```
///
/// `array` is not actually checked to ensure it contains instances of
/// [JSNumber] when called.
///
/// [T] may introduce additional checking elsewhere, however. When accessing
/// elements of [JSArray] with type [T], there is a check to ensure the element
/// is a [T] to ensure soundness. Similarly, when converting to a
/// <code>[List]<T></code>, casts may be introduced to ensure that it is indeed
/// a <code>[List]<T></code>.
@JS('Array')
extension type JSArray<T extends JSAny?>._(JSArrayType _jsArray)
    implements JSObject, JSArrayType, JSIterable<T> {
  /// Creates an empty JavaScript `Array`.
  ///
  /// Equivalent to `new Array()` and more efficient than `[].jsify()`.
  external JSArray();

  /// Creates a JavaScript `Array` of size [length] with no elements.
  external JSArray.withLength(int length);

  /// Creates a new, shallow-copied JavaScript `Array` instance from a
  /// JavaScript iterable or array-like object.
  @Since('3.6')
  external static JSArray<T> from<T extends JSAny>(JSObject arrayLike);

  /// The length in elements of this `Array`.
  @Since('3.6')
  external int get length;

  /// Sets the length in elements of this `Array`.
  ///
  /// Setting it smaller than the current length truncates this `Array`, and
  /// setting it larger adds empty slots, which requires [T] to be nullable.
  @Since('3.6')
  external set length(int newLength);

  /// The value at [position] in this `Array`.
  @Since('3.6')
  external T operator [](int position);

  /// Sets the [value] at [position] in this `Array`.
  @Since('3.6')
  external void operator []=(int position, T value);

  /// Adds [value] to the end of this `Array`, extending the length by one.
  // This maps to `List.add` to avoid accidental usage of
  // `JSAnyOperatorExtension.add` when migrating `List`s to `JSArray`s. See
  // https://github.com/dart-lang/sdk/issues/59830.
  @Since('3.10')
  @JS('push')
  external void add(T value);
}

/// A JavaScript `Promise` or a promise-like object.
///
/// Because [JSPromise] is an extension type, [T] is only a static guarantee and
/// the [JSPromise] may not actually resolve to a [T].
///
/// Also like with [JSArray], [T] may introduce additional checking elsewhere.
/// When converted to a <code>[Future]<T></code>, there is a cast to ensure that
/// the [Future] actually resolves to a [T] to ensure soundness.
@JS('Promise')
extension type JSPromise<T extends JSAny?>._(JSPromiseType _jsPromise)
    implements JSObject, JSPromiseType {
  external JSPromise(JSFunction executor);
}

/// Exception for when a [JSPromise] that is converted via
/// [JSPromiseToFuture.toDart] is rejected with a `null` or `undefined` value.
///
/// This is public to allow users to catch when the promise is rejected with
/// `null` or `undefined` versus some other value.
class NullRejectionException implements Exception {
  // Indicates whether the value is `undefined` or `null`.
  final bool isUndefined;

  NullRejectionException(this.isUndefined);

  @override
  String toString() {
    var value = this.isUndefined ? 'undefined' : 'null';
    return 'Promise was rejected with a value of `$value`.';
  }
}

/// A Dart object that is wrapped with a JavaScript object so that it can be
/// passed to JavaScript safely.
///
/// Unlike [ExternalDartReference], this can be used as a JS type and is a
/// subtype of [JSAny]. Users can also declare interop types using this as the
/// representation type or declare interop members on this type.
///
/// Use this interface when you want to pass Dart objects within the same
/// runtime through JavaScript. There are no usable members in the resulting
/// [JSBoxedDartObject].
///
/// See [ObjectToJSBoxedDartObject.toJSBox] to wrap an arbitrary [Object].
@JS('Object')
extension type JSBoxedDartObject._(JSBoxedDartObjectType _jsBoxedDartObject)
    implements JSObject, JSBoxedDartObjectType {}

/// A JavaScript `ArrayBuffer`.
@JS('ArrayBuffer')
extension type JSArrayBuffer._(JSArrayBufferType _jsArrayBuffer)
    implements JSObject, JSArrayBufferType {
  /// Creates a JavaScript `ArrayBuffer` of size [length] using an optional
  /// [options] JavaScript object that sets the `maxByteLength`.
  @Since('3.6')
  external JSArrayBuffer(int length, [JSObject options]);
}

/// A JavaScript `DataView`.
@JS('DataView')
extension type JSDataView._(JSDataViewType _jsDataView)
    implements JSObject, JSDataViewType {
  /// Creates a JavaScript `DataView` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [byteLength].
  @Since('3.6')
  external JSDataView(JSArrayBuffer buffer, [int byteOffset, int byteLength]);
}

/// Abstract supertype of all JavaScript typed arrays.
extension type JSTypedArray._(JSTypedArrayType _jsTypedArray)
    implements JSObject, JSTypedArrayType {}

/// A JavaScript `Int8Array`.
@JS('Int8Array')
extension type JSInt8Array._(JSInt8ArrayType _jsInt8Array)
    implements JSTypedArray, JSInt8ArrayType {
  /// Creates a JavaScript `Int8Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Int8Array`.
  @Since('3.6')
  external JSInt8Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Int8Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSInt8Array.withLength(int length);
}

/// A JavaScript `Uint8Array`.
@JS('Uint8Array')
extension type JSUint8Array._(JSUint8ArrayType _jsUint8Array)
    implements JSTypedArray, JSUint8ArrayType {
  /// Creates a JavaScript `Uint8Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Uint8Array`.
  @Since('3.6')
  external JSUint8Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Uint8Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSUint8Array.withLength(int length);
}

/// A JavaScript `Uint8ClampedArray`.
@JS('Uint8ClampedArray')
extension type JSUint8ClampedArray._(
  JSUint8ClampedArrayType _jsUint8ClampedArray
)
    implements JSTypedArray, JSUint8ClampedArrayType {
  /// Creates a JavaScript `Uint8ClampedArray` with [buffer] as its backing
  /// storage, offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Uint8ClampedArray`.
  @Since('3.6')
  external JSUint8ClampedArray([
    JSArrayBuffer buffer,
    int byteOffset,
    int length,
  ]);

  /// Creates a JavaScript `Uint8ClampedArray` of size [length] whose elements
  /// are initialized to 0.
  @Since('3.6')
  external JSUint8ClampedArray.withLength(int length);
}

/// A JavaScript `Int16Array`.
@JS('Int16Array')
extension type JSInt16Array._(JSInt16ArrayType _jsInt16Array)
    implements JSTypedArray, JSInt16ArrayType {
  /// Creates a JavaScript `Int16Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Int16Array`.
  @Since('3.6')
  external JSInt16Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Int16Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSInt16Array.withLength(int length);
}

/// A JavaScript `Uint16Array`.
@JS('Uint16Array')
extension type JSUint16Array._(JSUint16ArrayType _jsUint16Array)
    implements JSTypedArray, JSUint16ArrayType {
  /// Creates a JavaScript `Uint16Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Uint16Array`.
  @Since('3.6')
  external JSUint16Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Uint16Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSUint16Array.withLength(int length);
}

/// A JavaScript `Int32Array`.
@JS('Int32Array')
extension type JSInt32Array._(JSInt32ArrayType _jsInt32Array)
    implements JSTypedArray, JSInt32ArrayType {
  /// Creates a JavaScript `Int32Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Int32Array`.
  @Since('3.6')
  external JSInt32Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Int32Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSInt32Array.withLength(int length);
}

/// A JavaScript `Uint32Array`.
@JS('Uint32Array')
extension type JSUint32Array._(JSUint32ArrayType _jsUint32Array)
    implements JSTypedArray, JSUint32ArrayType {
  /// Creates a JavaScript `Uint32Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Uint32Array`.
  @Since('3.6')
  external JSUint32Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Uint32Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSUint32Array.withLength(int length);
}

/// A JavaScript `Float32Array`.
@JS('Float32Array')
extension type JSFloat32Array._(JSFloat32ArrayType _jsFloat32Array)
    implements JSTypedArray, JSFloat32ArrayType {
  /// Creates a JavaScript `Float32Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Float32Array`.
  @Since('3.6')
  external JSFloat32Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Float32Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSFloat32Array.withLength(int length);
}

/// A JavaScript `Float64Array`.
@JS('Float64Array')
extension type JSFloat64Array._(JSFloat64ArrayType _jsFloat64Array)
    implements JSTypedArray, JSFloat64ArrayType {
  /// Creates a JavaScript `Float64Array` with [buffer] as its backing storage,
  /// offset by [byteOffset] bytes, of size [length].
  ///
  /// If no [buffer] is provided, creates an empty `Float64Array`.
  @Since('3.6')
  external JSFloat64Array([JSArrayBuffer buffer, int byteOffset, int length]);

  /// Creates a JavaScript `Float64Array` of size [length] whose elements are
  /// initialized to 0.
  @Since('3.6')
  external JSFloat64Array.withLength(int length);
}

// The various JavaScript primitive types. Crucially, unlike the Dart type
// hierarchy, none of these types are subtypes of [JSObject]. They are just
// subtypes of [JSAny].

/// A JavaScript number.
extension type JSNumber._(JSNumberType _jsNumber)
    implements JSAny, JSNumberType {}

/// A JavaScript boolean.
extension type JSBoolean._(JSBooleanType _jsBoolean)
    implements JSAny, JSBooleanType {}

/// A JavaScript string.
extension type JSString._(JSStringType _jsString)
    implements JSAny, JSStringType, JSIterable<JSString> {}

@JS('Symbol')
external JSSymbol _constructSymbol([String? description]);

/// A JavaScript `Symbol`.
@JS('Symbol')
extension type JSSymbol._(JSSymbolType _jsSymbol)
    implements JSAny, JSSymbolType {
  // TODO(srujzs): See if this can be made `const` so it can be used in similar
  // situations to a Dart symbol literal.
  /// Creates a new, unique JavaScript `Symbol`.
  ///
  /// If [description] is provided, it's used for debugging but not to access
  /// the symbol itself.
  @Since('3.11')
  JSSymbol([String? description])
    : _jsSymbol =
          (description == null
                  ? _constructSymbol()
                  : _constructSymbol(description))
              ._jsSymbol;

  /// Searches for an existing symbol in a runtime-wide symbol registry with the
  /// given key and returns it if found.
  ///
  /// Otherwise, creates a new symbol with this key, adds it to the global
  /// registry, and returns it.
  @Since('3.11')
  @JS('for')
  external static JSSymbol forKey(String key);

  /// See [`Symbol.asyncIterator`].
  ///
  /// [`Symbol.asyncIterator`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/asyncIterator
  @Since('3.11')
  external static JSSymbol get asyncIterator;

  /// See [`Symbol.hasInstance`].
  ///
  /// [`Symbol.hasInstance`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/hasInstance
  @Since('3.11')
  external static JSSymbol get hasInstance;

  /// See [`Symbol.isConcatSpreadable`].
  ///
  /// [`Symbol.isConcatSpreadable`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/isConcatSpreadable
  @Since('3.11')
  external static JSSymbol get isConcatSpreadable;

  /// See [`Symbol.iterator`].
  ///
  /// [`Symbol.iterator`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/iterator
  @Since('3.11')
  external static JSSymbol get iterator;

  /// See [`Symbol.match`].
  ///
  /// [`Symbol.match`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/match
  @Since('3.11')
  external static JSSymbol get match;

  /// See [`Symbol.matchAll`].
  ///
  /// [`Symbol.matchAll`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/matchAll
  @Since('3.11')
  external static JSSymbol get matchAll;

  /// See [`Symbol.replace`].
  ///
  /// [`Symbol.replace`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/replace
  @Since('3.11')
  external static JSSymbol get replace;

  /// See [`Symbol.search`].
  ///
  /// [`Symbol.search`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/search
  @Since('3.11')
  external static JSSymbol get search;

  /// See [`Symbol.species`].
  ///
  /// [`Symbol.species`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/species
  @Since('3.11')
  external static JSSymbol get species;

  /// See [`Symbol.split`].
  ///
  /// [`Symbol.split`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/split
  @Since('3.11')
  external static JSSymbol get split;

  /// See [`Symbol.toPrimitive`].
  ///
  /// [`Symbol.toPrimitive`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/toPrimitive
  @Since('3.11')
  external static JSSymbol get toPrimitive;

  /// See [`Symbol.toStringTag`].
  ///
  /// [`Symbol.toStringTag`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/toStringTag
  @Since('3.11')
  external static JSSymbol get toStringTag;

  /// See [`Symbol.unscopables`].
  ///
  /// [`Symbol.unscopables`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/unscopables
  @Since('3.11')
  external static JSSymbol get unscopables;

  @Since('3.11')
  @JS('keyFor')
  external static String? _keyFor(JSSymbol symbol);

  /// Returns the shared symbol key from the global symbol registry for this
  /// symbol (as registered with [forKey]), if this symbol was created with
  /// [JSSymbol.forKey].
  @Since('3.11')
  String? get key => _keyFor(this);

  /// A string containing the description of the symbol, as passed to
  /// [JSSymbol.new].
  @Since('3.11')
  external String get description;
}

/// A JavaScript `BigInt`.
extension type JSBigInt._(JSBigIntType _jsBigInt)
    implements JSAny, JSBigIntType {}

/// An opaque reference to a Dart object that can be passed to JavaScript.
///
/// The reference representation depends on the underlying platform. When
/// compiling to JavaScript, a Dart object is a JavaScript object, and can be
/// used directly without any conversions. When compiling to Wasm, an internal
/// Wasm function is used to convert the Dart object to an opaque JavaScript
/// value, which can later be converted back using another internal function.
/// The underlying representation type is nullable, meaning a non-nullable
/// [ExternalDartReference] may be `null`.
///
/// This interface is a faster alternative to [JSBoxedDartObject] by not
/// wrapping the Dart object with a JavaScript object. However, unlike
/// [JSBoxedDartObject], this value belongs to the Dart runtime, and therefore
/// can not be used as a JS type. This means users cannot declare interop types
/// using this as the representation type or declare interop members on this
/// type. This type is also not a subtype of [JSAny]. This type can only be used
/// as parameter and return types of external JavaScript interop members or
/// callbacks. Use [JSBoxedDartObject] to avoid those limitations.
///
/// Besides these differences, [ExternalDartReference] operates functionally the
/// same as [JSBoxedDartObject]. Use it to pass Dart objects within the same
/// runtime through JavaScript. There are no usable members in the resulting
/// [ExternalDartReference].
///
/// See [ObjectToExternalDartReference.toExternalReference] to allow an
/// arbitrary value of type [T] to be passed to JavaScript.
extension type ExternalDartReference<T extends Object?>._(
  ExternalDartReferenceType<T> _externalDartReference
) {}

/// JS type equivalent for `undefined` for interop member return types.
///
/// Prefer using `void` instead of this.
// TODO(srujzs): Mark this as deprecated. There are no performance costs from
// using `void`, and we'll likely provide a different way to box `undefined`.
typedef JSVoid = JSVoidType;

/// Helper members to determine if a value is JavaScript `undefined` or `null`.
///
/// > [!NOTE]
/// > The members within these extensions may throw depending on the platform.
/// > Do not rely on them to be platform-consistent.
///
/// JavaScript `undefined` and JavaScript `null` are internalized differently
/// based on the backend. When compiling to JavaScript, Dart `null` can actually
/// be JavaScript `undefined` or JavaScript `null`. When compiling to Wasm,
/// that's not the case: there's only one Wasm value `null` can be. Therefore,
/// when an interop API returns JavaScript `null` or JavaScript `undefined`,
/// they are both converted to Dart `null` when compiling to Wasm, and when you
/// pass a Dart `null` to an interop API, it is called with JavaScript `null`.
/// When compiling to JavaScript, Dart `null` retains its original JavaScript
/// value. Avoid writing code where this distinction between `null` and
/// `undefined` matters.
// TODO(srujzs): Investigate what it takes to allow users to distinguish between
// the two "nullish" values. An annotation-based model where users annotate
// interop APIs to internalize `undefined` differently seems promising, but does
// not handle some cases like converting a `JSArray` with `undefined`s in it to
// `List<JSAny?>`. In this case, the implementation of the list wrapper needs to
// make the decision, not the user.
extension NullableUndefineableJSAnyExtension on JSAny? {
  /// Whether this value corresponds to JavaScript `undefined`.
  ///
  /// > [!NOTE]
  /// > Currently, there is no way to distinguish between JavaScript `undefined`
  /// > and JavaScript `null` when compiling to Wasm. Therefore, this getter
  /// > should only be used for code that compiles to JavaScript and will throw
  /// > when compiling to Wasm.
  external bool get isUndefined;

  /// Whether this value corresponds to JavaScript `null`.
  ///
  /// > [!NOTE]
  /// > Currently, there is no way to distinguish between JavaScript `undefined`
  /// > and JavaScript `null` when compiling to Wasm. Therefore, this getter
  /// > should only be used for code that compiles to JavaScript and will throw
  /// > when compiling to Wasm.
  external bool get isNull;

  bool get isUndefinedOrNull => this == null;
  bool get isDefinedAndNotNull => !isUndefinedOrNull;
}

/// Common utility functions that are useful for any JavaScript value.
extension JSAnyUtilityExtension on JSAny? {
  /// Whether the result of `typeof` on this <code>[JSAny]?</code> is
  /// [typeString].
  external bool typeofEquals(String typeString);

  /// Whether this <code>[JSAny]?</code> is an `instanceof` [constructor].
  external bool instanceof(JSFunction constructor);

  /// Whether this <code>[JSAny]?</code> is an `instanceof` the constructor that
  /// is defined by [constructorName], which is looked up in the
  /// [globalContext].
  ///
  /// If [constructorName] contains '.'s, the name is split into several parts
  /// in order to get the constructor. For example, `library1.JSClass` would
  /// involve fetching `library1` off of the [globalContext], and then fetching
  /// `JSClass` off of `library1` to get the constructor.
  ///
  /// If [constructorName] is empty or any of the parts or the constructor don't
  /// exist, returns false.
  bool instanceOfString(String constructorName) {
    if (constructorName.isEmpty) return false;
    final parts = constructorName.split('.');
    JSObject? constructor = globalContext;
    for (final part in parts) {
      constructor = constructor?[part] as JSObject?;
      if (constructor == null) return false;
    }
    return instanceof(constructor as JSFunction);
  }

  /// Whether this <code>[JSAny]?</code> is an instance of the JavaScript type
  /// that is declared by [T].
  ///
  /// Since the type-check this function emits is determined at compile-time,
  /// [T] needs to be an interop extension type that can also be determined at
  /// compile-time. In particular, `isA` can't be provided a generic type
  /// variable as a type argument.
  ///
  /// This method uses a combination of `null`, `typeof`, and `instanceof`
  /// checks in order to do this check. Use this instead of `is` checks.
  ///
  /// If [T] is a primitive JS type like [JSString], this uses a `typeof` check
  /// that corresponds to that primitive type like `typeofEquals('string')`.
  ///
  /// If [T] is a non-primitive JS type like [JSArray] or an interop extension
  /// type on one, this uses an `instanceof` check using the name or the
  /// <code>@[JS]</code> rename of the given type like
  /// `instanceOfString('Array')`. Note that if you rename the library using the
  /// <code>@[JS]</code> annotation, this uses the rename in the `instanceof`
  /// check like `instanceOfString('library1.JSClass')`.
  ///
  /// To determine the JavaScript constructor to use as the second operand in
  /// the `instanceof` check, this function uses the JavaScript name associated
  /// with the extension type, which is either the argument given to the
  /// <code>@[JS]</code> annotation or the Dart declaration name. So, if you had
  /// an interop extension type `JSClass` that wraps `JSArray` without a rename,
  /// this does an `instanceOfString('JSClass')` check and not an
  /// `instanceOfString('Array')` check.
  ///
  /// There are a few values for [T] that are exceptions to this rule:
  /// - `JSTypedArray`: As `TypedArray` does not exist as a class in JavaScript,
  ///   this does some prototype checking to make `isA<JSTypedArray>` do the
  ///   right thing.
  /// - `JSBoxedDartObject`: `isA<JSBoxedDartObject>` will check if the value is
  ///   a result of a previous [ObjectToJSBoxedDartObject.toJSBox] call.
  /// - `JSAny`: If you do an `isA<JSAny>` check, it will only check for `null`.
  /// - User interop types whose representation types are JS primitive types:
  ///   This will result in an error to avoid confusion on whether the user
  ///   interop type is used in the type-check. Use the primitive JS type as the
  ///   value for [T] instead.
  /// - User interop types that have an object literal constructor: This will
  ///   result in an error as you likely want to use [JSObject] instead.
  @Since('3.4')
  external bool isA<T extends JSAny?>();

  /// Converts a JavaScript JSON-like value to the Dart equivalent if possible.
  ///
  /// Effectively the inverse of [NullableObjectUtilExtension.jsify], [dartify]
  /// takes a JavaScript JSON-like value and recursively converts it to a Dart
  /// object, doing the following:
  ///
  /// - If the value is a string, number, boolean, `null`, `undefined`,
  ///   `DataView` or a typed array, does the equivalent `toDart` operation if
  ///   it exists and returns the result.
  /// - If the value is a simple JS object (the protoype is either `null` or JS
  ///   `Object`), creates and returns a `[Map]<Object?, Object?>` whose keys
  ///   are the recursively converted keys obtained from `Object.keys` and its
  ///   values are the associated values of the keys in the JS object.
  /// - If the value is a JS `Array`, each item in it is recursively converted
  ///   and added to a new `[List]<Object?>`, which is then returned.
  /// - Otherwise, the conversion is undefined.
  ///
  /// If the value contains a cycle, the behavior is undefined.
  ///
  /// > [!NOTE]
  /// > Prefer using the specific conversion member like `toDart` if you know
  /// > the JavaScript type as this method may perform many type-checks. You
  /// > should generally call this method with values that only contain
  /// > JSON-like values as the conversion may be platform- and
  /// > compiler-specific otherwise.
  // TODO(srujzs): We likely need stronger tests for this method to ensure
  // consistency. We should also limit the accepted types in this API to avoid
  // confusion. Once the conversion for unrelated types is consistent across all
  // backends, we can update the documentation to say that the value is
  // internalized instead of the conversion being undefined.
  external Object? dartify();
}

/// Common utility functions for <code>[Object]?</code>s.
extension NullableObjectUtilExtension on Object? {
  /// Converts a Dart JSON-like object to the JavaScript equivalent if possible.
  ///
  /// Effectively the inverse of [JSAnyUtilityExtension.dartify], [jsify] takes
  /// a Dart JSON-like object and recursively converts it to a JavaScript value,
  /// doing the following:
  ///
  /// - If the object is a JS value, returns the object.
  /// - If the object is a Dart primitive type, `null`, or a `dart:typed_data`
  ///   type, does the equivalent `toJS` operation if it exists and returns the
  ///   result.
  /// - If the object is a [Map], creates and returns a new JS object whose
  ///   properties and associated values are the recursively converted keys and
  ///   values of the [Map].
  /// - If the object is an [Iterable], each item in it is recursively converted
  ///   and pushed into a new JS `Array` which is then returned.
  /// - Otherwise, the conversion is undefined.
  ///
  /// If the object contains a cycle, the behavior is undefined.
  ///
  /// > [!NOTE]
  /// > Prefer using the specific conversion member like `toJS` if you know the
  /// > Dart type as this method may perform many type-checks. You should
  /// > generally call this method with objects that only contain JSON-like
  /// > values as the conversion may be platform- and compiler-specific
  /// > otherwise.
  // TODO(srujzs): We likely need stronger tests for this method to ensure
  // consistency. We should also limit the accepted types in this API to avoid
  // confusion. Once the conversion for unrelated types is consistent across all
  // backends, we can update the documentation to say that the object is
  // externalized instead of the conversion being undefined.
  external JSAny? jsify();
}

/// Utility extensions for [JSFunction].
// TODO(srujzs): We may want to provide a syntax for users to avoid `.call` and
// directly call the function in JavaScript using `(...)`.
extension JSFunctionUtilExtension on JSFunction {
  /// Call this [JSFunction] using the JavaScript `.call` syntax and returns the
  /// result.
  ///
  /// Takes at most 4 args for consistency with other APIs and relative brevity.
  /// If more are needed, you can declare your own external member with the same
  /// syntax.
  // We rename this function since declaring a `call` member makes a class
  // callable in Dart. This is convenient, but unlike Dart functions, JavaScript
  // functions explicitly take a `this` argument (which users can provide `null`
  // for in the case where the function doesn't need it), which may lead to
  // confusion.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/call
  @JS('call')
  external JSAny? callAsFunction([
    JSAny? thisArg,
    JSAny? arg1,
    JSAny? arg2,
    JSAny? arg3,
    JSAny? arg4,
  ]);
}

// Extension members to support conversions between Dart types and JS types.
// Not all Dart types can be converted to JS types and vice versa.
// TODO(srujzs): Move some of these to the associated extension type.

/// Conversions from [JSExportedDartFunction] to [Function].
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  /// The Dart [Function] that this [JSExportedDartFunction] wrapped.
  ///
  /// Must be a function that was wrapped with
  /// [FunctionToJSExportedDartFunction.toJS] or
  /// [FunctionToJSExportedDartFunction.toJSCaptureThis].
  external Function get toDart;
}

/// Conversions from [Function] to [JSExportedDartFunction].
extension FunctionToJSExportedDartFunction on Function {
  /// A callable JavaScript function that wraps this [Function].
  ///
  /// If the static type of the [Function] could not be determined or if
  /// the static type uses types that are disallowed, the call will fail to
  /// compile. See
  /// https://dart.dev/interop/js-interop/js-types#requirements-on-external-declarations-and-function-tojs
  /// for more details on what types are allowed.
  ///
  /// The max number of arguments that are passed to this [Function] from the
  /// wrapper JavaScript function is determined by this [Function]'s static
  /// type. Any extra arguments passed to the JavaScript function after the max
  /// number of arguments are discarded like they are with regular JavaScript
  /// functions.
  ///
  /// Calling this on the same [Function] again will always result in a new
  /// JavaScript function.
  external JSExportedDartFunction get toJS;

  /// A callable JavaScript function that wraps this [Function] and captures the
  /// `this` value when called.
  ///
  /// Identical to [toJS], except the resulting [JSExportedDartFunction] will
  /// pass `this` from JavaScript as the first argument to the converted
  /// [Function]. Any [Function] that is converted with this member should take
  /// in an extra parameter at the beginning of the parameter list to handle
  /// this.
  @Since('3.6')
  external JSExportedDartFunction get toJSCaptureThis;
}

/// Conversions from [JSBoxedDartObject] to [Object].
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  /// The Dart [Object] that this [JSBoxedDartObject] wrapped.
  ///
  /// Throws an [Exception] if the Dart runtime was not the same as the one in
  /// which the [Object] was wrapped or if this was not a wrapped Dart [Object].
  external Object get toDart;
}

/// Conversions from [Object] to [JSBoxedDartObject].
extension ObjectToJSBoxedDartObject on Object {
  /// A JavaScript object that wraps this [Object].
  ///
  /// There are no usable members in the resulting [JSBoxedDartObject] and you
  /// may get a new [JSBoxedDartObject] when calling [toJSBox] on the same Dart
  /// [Object].
  ///
  /// Throws an [Exception] if this [Object] is a JavaScript value.
  ///
  /// Unlike [ObjectToExternalDartReference.toExternalReference], this returns a
  /// JavaScript value. Therefore, the representation is guaranteed to be
  /// consistent across all platforms and interop members can be declared on
  /// [JSBoxedDartObject]s.
  external JSBoxedDartObject get toJSBox;
}

/// Conversions from [ExternalDartReference] to the value of type [T].
extension ExternalDartReferenceToObject<T extends Object?>
    on ExternalDartReference<T> {
  /// The Dart value of type [T] that this [ExternalDartReference] refers to.
  ///
  /// When compiling to JavaScript, a Dart object is a JavaScript object, and
  /// therefore this directly returns the Dart object. When compiling to Wasm,
  /// an internal Wasm function is used to convert the opaque JavaScript value
  /// to the original Dart object.
  external T get toDartObject;
}

/// Conversions from a value of type [T] to [ExternalDartReference].
extension ObjectToExternalDartReference<T extends Object?> on T {
  /// An opaque reference to this value of type [T] which can be passed to
  /// JavaScript.
  ///
  /// When compiling to JavaScript, a Dart object is a JavaScript object, and
  /// therefore this directly returns the Dart object. When compiling to Wasm,
  /// an internal Wasm function is used to convert the Dart object to an opaque
  /// JavaScript value. If this value is `null`, returns `null`.
  ///
  /// A value of type [ExternalDartReference] should be treated as completely
  /// opaque. It can only be passed around as-is or converted back using
  /// [ExternalDartReferenceToObject.toDartObject].
  ///
  /// When this getter is called multiple times on the same Dart object, the
  /// underlying references in the resulting [ExternalDartReference]s are
  /// guaranteed to be equal. Therefore, `==` will always return true between
  /// such [ExternalDartReference]s. However, like JS types, `identical` between
  /// such values may return different results depending on the compiler.
  external ExternalDartReference<T> get toExternalReference;
}

/// Conversions from [JSPromise] to [Future].
extension JSPromiseToFuture<T extends JSAny?> on JSPromise<T> {
  /// A [Future] that either completes with the result of the resolved
  /// [JSPromise] or propagates the error that the [JSPromise] rejected with.
  ///
  /// If the [JSPromise] is rejected with a `null` or `undefined` value, a
  /// [NullRejectionException] will be thrown.
  external Future<T> get toDart;
}

/// Conversions from [Future] to [JSPromise] where the [Future] returns a value.
extension FutureOfJSAnyToJSPromise<T extends JSAny?> on Future<T> {
  /// A [JSPromise] that either resolves with the result of the completed
  /// [Future] or rejects with an object that contains its error.
  ///
  /// The rejected object contains the original error as a [JSBoxedDartObject]
  /// in the property `error` and the original stack trace as a [String] in the
  /// property `stack`.
  JSPromise<T> get toJS {
    return JSPromise<T>(
      (JSFunction resolve, JSFunction reject) {
        this.then(
          (JSAny? value) {
            resolve.callAsFunction(resolve, value);
            return value;
          },
          onError: (Object error, StackTrace stackTrace) {
            // TODO(srujzs): Can we do something better here? This is pretty much
            // useless to the user unless they call a Dart callback that consumes
            // this value and unboxes.
            final errorConstructor = globalContext['Error'] as JSFunction;
            final wrapper = errorConstructor.callAsConstructor<JSObject>(
              "Dart exception thrown from converted Future. Use the properties "
                      "'error' to fetch the boxed error and 'stack' to recover "
                      "the stack trace."
                  .toJS,
            );
            wrapper['error'] = error.toJSBox;
            wrapper['stack'] = stackTrace.toString().toJS;
            reject.callAsFunction(reject, wrapper);
            return wrapper;
          },
        );
      }.toJS,
    );
  }
}

/// Conversions from [Future] to [JSPromise] where the [Future] does not return
/// a value.
extension FutureOfVoidToJSPromise on Future<void> {
  /// A [JSPromise] that either resolves once this [Future] completes or rejects
  /// with an object that contains its error.
  ///
  /// The rejected object contains the original error as a [JSBoxedDartObject]
  /// in the property `error` and the original stack trace as a [String] in the
  /// property `stack`.
  JSPromise get toJS {
    return JSPromise(
      (JSFunction resolve, JSFunction reject) {
        this.then(
          (_) => resolve.callAsFunction(resolve),
          onError: (Object error, StackTrace stackTrace) {
            // TODO(srujzs): Can we do something better here? This is pretty much
            // useless to the user unless they call a Dart callback that consumes
            // this value and unboxes.
            final errorConstructor = globalContext['Error'] as JSFunction;
            final wrapper = errorConstructor.callAsConstructor<JSObject>(
              "Dart exception thrown from converted Future. Use the properties "
                      "'error' to fetch the boxed error and 'stack' to recover "
                      "the stack trace."
                  .toJS,
            );
            wrapper['error'] = error.toJSBox;
            wrapper['stack'] = stackTrace.toString().toJS;
            reject.callAsFunction(reject, wrapper);
          },
        );
      }.toJS,
    );
  }
}

/// Conversions from [JSArrayBuffer] to [ByteBuffer].
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  /// Converts this [JSArrayBuffer] to a [ByteBuffer] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [ByteBuffer]s are [JSArrayBuffer]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSArrayBuffer] is wrapped with a [ByteBuffer]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSArrayBuffer] will affect the returned
  /// [ByteBuffer] and vice versa.
  external ByteBuffer get toDart;
}

/// Conversions from [ByteBuffer] to [JSArrayBuffer].
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  /// Converts this [ByteBuffer] to a [JSArrayBuffer] by either casting,
  /// unwrapping, or cloning the [ByteBuffer].
  ///
  /// Throws if the [ByteBuffer] is backed by a JS `SharedArrayBuffer`.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [ByteBuffer]s are either `ArrayBuffer`s or
  /// `SharedArrayBuffer`s so this will just check the type and cast, throwing
  /// if it's a `SharedArrayBuffer`.
  ///
  /// When compiling to Wasm, this [ByteBuffer] is a wrapper around an
  /// `ArrayBuffer` if it was converted via [JSArrayBufferToByteBuffer.toDart].
  /// If it is a wrapper, this getter unwraps it and either returns the
  /// `ArrayBuffer` or throws if the unwrapped buffer was a `SharedArrayBuffer`.
  /// If it's instantiated in Dart, this getter clones this [ByteBuffer]'s
  /// values into a new [JSArrayBuffer].
  ///
  /// Avoid assuming that modifications to this [ByteBuffer] will affect the
  /// returned [JSArrayBuffer] and vice versa on all compilers unless it was
  /// first converted via [JSArrayBufferToByteBuffer.toDart].
  external JSArrayBuffer get toJS;
}

/// Conversions from [JSDataView] to [ByteData].
extension JSDataViewToByteData on JSDataView {
  /// Converts this [JSDataView] to a [ByteData] by either casting or wrapping
  /// it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [ByteData]s are [JSDataView]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSDataView] is wrapped with a [ByteData]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSDataView] will affect the returned [ByteData] and
  /// vice versa.
  external ByteData get toDart;
}

/// Conversions from [ByteData] to [JSDataView].
extension ByteDataToJSDataView on ByteData {
  /// Converts this [ByteData] to a [JSDataView] by either casting, unwrapping,
  /// or cloning the [ByteData].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [ByteData] is a wrapper around a `DataView`
  /// if it was converted via [JSDataViewToByteData.toDart]. If it is a wrapper,
  /// this getter unwraps it and returns the `DataView`. If it's instantiated in
  /// Dart, this getter clones this [ByteData]'s values into a new [JSDataView].
  ///
  /// Avoid assuming that modifications to this [ByteData] will affect the
  /// returned [JSDataView] and vice versa on all compilers unless it was first
  /// converted via [JSDataViewToByteData.toDart].
  external JSDataView get toJS;
}

/// Conversions from [JSInt8Array] to [Int8List].
extension JSInt8ArrayToInt8List on JSInt8Array {
  /// Converts this [JSInt8Array] to a [Int8List] by either casting or wrapping
  /// it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Int8List]s are [JSInt8Array]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSInt8Array] is wrapped with a [Int8List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSInt8Array] will affect the returned [Int8List]
  /// and vice versa.
  external Int8List get toDart;
}

/// Conversions from [Int8List] to [JSInt8Array].
extension Int8ListToJSInt8Array on Int8List {
  /// Converts this [Int8List] to a [JSInt8Array] by either casting,
  /// unwrapping, or cloning the [Int8List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Int8List] is a wrapper around a `Int8Array`
  /// if it was converted via [JSInt8ArrayToInt8List.toDart]. If it is a
  /// wrapper, this getter unwraps it and returns the `Int8Array`. If it's
  /// instantiated in Dart, this getter clones this [Int8List]'s values into a
  /// new [JSInt8Array].
  ///
  /// Avoid assuming that modifications to this [Int8List] will affect the
  /// returned [JSInt8Array] and vice versa on all compilers unless it was
  /// first converted via [JSInt8ArrayToInt8List.toDart].
  external JSInt8Array get toJS;
}

/// Conversions from [JSUint8Array] to [Uint8List].
extension JSUint8ArrayToUint8List on JSUint8Array {
  /// Converts this [JSUint8Array] to a [Uint8List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Uint8List]s are [JSUint8Array]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSUint8Array] is wrapped with a [Uint8List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSUint8Array] will affect the returned [Uint8List]
  /// and vice versa.
  external Uint8List get toDart;
}

/// Conversions from [Uint8List] to [JSUint8Array].
extension Uint8ListToJSUint8Array on Uint8List {
  /// Converts this [Uint8List] to a [JSUint8Array] by either casting,
  /// unwrapping, or cloning the [Uint8List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Uint8List] is a wrapper around a
  /// `Uint8Array` if it was converted via [JSUint8ArrayToUint8List.toDart]. If
  /// it is a wrapper, this getter unwraps it and returns the `Uint8Array`. If
  /// it's instantiated in Dart, this getter clones this [Uint8List]'s values
  /// into a new [JSUint8Array].
  ///
  /// Avoid assuming that modifications to this [Uint8List] will affect the
  /// returned [JSUint8Array] and vice versa on all compilers unless it was
  /// converted first via [JSUint8ArrayToUint8List.toDart].
  external JSUint8Array get toJS;
}

/// Conversions from [JSUint8ClampedArray] to [Uint8ClampedList].
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  /// Converts this [JSUint8ClampedArray] to a [Uint8ClampedList] by either
  /// casting or wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Uint8ClampedList]s are
  /// [JSUint8ClampedArray]s and this getter will be a cast.
  ///
  /// When compiling to Wasm, the [JSUint8ClampedArray] is wrapped with a
  /// [Uint8ClampedList] implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSUint8ClampedArray] will affect the returned
  /// [Uint8ClampedList] and vice versa.
  external Uint8ClampedList get toDart;
}

/// Conversions from [Uint8ClampedList] to [JSUint8ClampedArray].
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  /// Converts this [Uint8ClampedList] to a [JSUint8ClampedArray] by either
  /// casting, unwrapping, or cloning the [Uint8ClampedList].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Uint8ClampedList] is a wrapper around a
  /// `Uint8ClampedArray` if it was converted via
  /// [JSUint8ClampedArrayToUint8ClampedList.toDart]. If it is a wrapper, this
  /// getter unwraps it and returns the `Uint8ClampedArray`. If it's
  /// instantiated in Dart, this getter clones this [Uint8ClampedList]'s values
  /// into a new [JSUint8ClampedArray].
  ///
  /// Avoid assuming that modifications to this [Uint8ClampedList] will affect
  /// the returned [JSUint8ClampedArray] and vice versa on all compilers unless
  /// it was converted first via [JSUint8ClampedArrayToUint8ClampedList.toDart].
  external JSUint8ClampedArray get toJS;
}

/// Conversions from [JSInt16Array] to [Int16List].
extension JSInt16ArrayToInt16List on JSInt16Array {
  /// Converts this [JSInt16Array] to a [Int16List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Int16List]s are [JSInt16Array]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSInt16Array] is wrapped with a [Int16List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSInt16Array] will affect the returned [Int16List]
  /// and vice versa.
  external Int16List get toDart;
}

/// Conversions from [Int16List] to [JSInt16Array].
extension Int16ListToJSInt16Array on Int16List {
  /// Converts this [Int16List] to a [JSInt16Array] by either casting,
  /// unwrapping, or cloning the [Int16List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Int16List] is a wrapper around a
  /// `Int16Array` if it was converted via [JSInt16ArrayToInt16List.toDart]. If
  /// it is a wrapper, this getter unwraps it and returns the `Int16Array`. If
  /// it's instantiated in Dart, this getter clones this [Int16List]'s values
  /// into a new [JSInt16Array].
  ///
  /// Avoid assuming that modifications to this [Int16List] will affect the
  /// returned [JSInt16Array] and vice versa on all compilers unless it was
  /// converted first via [JSInt16ArrayToInt16List.toDart].
  external JSInt16Array get toJS;
}

/// Conversions from [JSUint16Array] to [Uint16List].
extension JSUint16ArrayToUint16List on JSUint16Array {
  /// Converts this [JSUint16Array] to a [Uint16List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Uint16List]s are [JSUint16Array]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSUint16Array] is wrapped with a [Uint16List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSUint16Array] will affect the returned
  /// [Uint16List] and vice versa.
  external Uint16List get toDart;
}

/// Conversions from [Uint16List] to [JSUint16Array].
extension Uint16ListToJSUint16Array on Uint16List {
  /// Converts this [Uint16List] to a [JSUint16Array] by either casting,
  /// unwrapping, or cloning the [Uint16List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Uint16List] is a wrapper around a
  /// `Uint16Array` if it was converted via [JSUint16ArrayToUint16List.toDart].
  /// If it is a wrapper, this getter unwraps it and returns the `Uint16Array`.
  /// If it's instantiated in Dart, this getter clones this [Uint16List]'s
  /// values into a new [JSUint16Array].
  ///
  /// Avoid assuming that modifications to this [Uint16List] will affect the
  /// returned [JSUint16Array] and vice versa on all compilers unless it was
  /// converted first via [JSUint16ArrayToUint16List.toDart].
  external JSUint16Array get toJS;
}

/// Conversions from [JSInt32Array] to [Int32List].
extension JSInt32ArrayToInt32List on JSInt32Array {
  /// Converts this [JSInt32Array] to a [Int32List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Int32List]s are [JSInt32Array]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSInt32Array] is wrapped with a [Int32List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSInt32Array] will affect the returned [Int32List]
  /// and vice versa.
  external Int32List get toDart;
}

/// Conversions from [Int32List] to [JSInt32Array].
extension Int32ListToJSInt32Array on Int32List {
  /// Converts this [Int32List] to a [JSInt32Array] by either casting,
  /// unwrapping, or cloning the [Int32List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Int32List] is a wrapper around a
  /// `Int32Array` if it was converted via [JSInt32ArrayToInt32List.toDart]. If
  /// it is a wrapper, this getter unwraps it and returns the `Int32Array`. If
  /// it's instantiated in Dart, this getter clones this [Int32List]'s values
  /// into a new [JSInt32Array].
  ///
  /// Avoid assuming that modifications to this [Int32List] will affect the
  /// returned [JSInt32Array] and vice versa on all compilers unless it was
  /// converted first via [JSInt32ArrayToInt32List.toDart].
  external JSInt32Array get toJS;
}

/// Conversions from [JSUint32Array] to [Uint32List].
extension JSUint32ArrayToUint32List on JSUint32Array {
  /// Converts this [JSUint32Array] to a [Uint32List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Uint32List]s are [JSUint32Array]s and this
  /// operation will be a cast.
  ///
  /// When compiling to Wasm, the [JSUint32Array] is wrapped with a [Uint32List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSUint32Array] will affect the returned
  /// [Uint32List] and vice versa.
  external Uint32List get toDart;
}

/// Conversions from [Uint32List] to [JSUint32Array].
extension Uint32ListToJSUint32Array on Uint32List {
  /// Converts this [Uint32List] to a [JSUint32Array] by either casting,
  /// unwrapping, or cloning the [Uint32List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Uint32List] is a wrapper around a
  /// `Uint32Array` if it was converted via [JSUint32ArrayToUint32List.toDart].
  /// If it is a wrapper, this getter unwraps it and returns the `Uint32Array`.
  /// If it's instantiated in Dart, this getter clones this [Uint32List]'s
  /// values into a new [JSUint32Array].
  ///
  /// Avoid assuming that modifications to this [Uint32List] will affect the
  /// returned [JSUint32Array] and vice versa on all compilers unless it was
  /// converted first via [JSUint32ArrayToUint32List.toDart].
  external JSUint32Array get toJS;
}

/// Conversions from [JSFloat32Array] to [Float32List].
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  /// Converts this [JSFloat32Array] to a [Float32List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Float32List]s are [JSFloat32Array]s and
  /// this getter will be a cast.
  ///
  /// When compiling to Wasm, the [JSFloat32Array] is wrapped with a
  /// [Float32List] implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSFloat32Array] will affect the returned
  /// [Float32List] and vice versa.
  external Float32List get toDart;
}

/// Conversions from [Float32List] to [JSFloat32Array].
extension Float32ListToJSFloat32Array on Float32List {
  /// Converts this [Float32List] to a [JSFloat32Array] by either casting,
  /// unwrapping, or cloning the [Float32List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Float32List] is a wrapper around a
  /// `Float32Array` if it was converted via
  /// [JSFloat32ArrayToFloat32List.toDart]. If it is a wrapper, this getter
  /// unwraps it and returns the `Float32Array`. If it's instantiated in Dart,
  /// this getter clones this [Float32List]'s values into a new
  /// [JSFloat32Array].
  ///
  /// Avoid assuming that modifications to this [Float32List] will affect the
  /// returned [JSFloat32Array] and vice versa on all compilers unless it was
  /// converted first via [JSFloat32ArrayToFloat32List.toDart].
  external JSFloat32Array get toJS;
}

/// Conversions from [JSFloat64Array] to [Float64List].
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  /// Converts this [JSFloat64Array] to a [Float64List] by either casting or
  /// wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, [Float64List]s are [JSFloat64Array]s and
  /// this getter will be a cast.
  ///
  /// When compiling to Wasm, the [JSFloat64Array] is wrapped with a
  /// [Float64List] implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSFloat64Array] will affect the returned
  /// [Float64List] and vice versa.
  external Float64List get toDart;
}

/// Conversions from [Float64List] to [JSFloat64Array].
extension Float64ListToJSFloat64Array on Float64List {
  /// Converts this [Float64List] to a [JSFloat64Array] by either casting,
  /// unwrapping, or cloning the [Float64List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, all typed lists are the equivalent
  /// JavaScript typed arrays, and therefore this getter simply casts.
  ///
  /// When compiling to Wasm, this [Float64List] is a wrapper around a
  /// `Float64Array` if it was converted via
  /// [JSFloat64ArrayToFloat64List.toDart]. If it is a wrapper, this getter
  /// unwraps it and returns the `Float64Array`. If it's instantiated in Dart,
  /// this getter clones this [Float64List]'s values into a new
  /// [JSFloat64Array].
  ///
  /// Avoid assuming that modifications to this [Float64List] will affect the
  /// returned [JSFloat64Array] and vice versa on all compilers unless it was
  /// converted first via [JSFloat64ArrayToFloat64List.toDart].
  external JSFloat64Array get toJS;
}

/// Conversion from [Iterable] to [JSIterable].
@Since('3.12')
extension IterableToJSIterable<T extends JSAny?> on Iterable<T> {
  /// Returns a [JSIterable] wrapper that proxies to the Dart iterable API.
  JSIterable<T> get toJSIterable {
    final object = JSObject();
    object.setProperty(
      JSSymbol.iterator,
      (() => this.iterator.toJSIterator).toJS,
    );
    return object as JSIterable<T>;
  }
}

/// Conversion from [JSIterable] to [Iterable].
@Since('3.12')
extension JSIterableToIterable<T extends JSAny?> on JSIterable<T> {
  /// Returns a Dart [Iterable] that iterates over the values in this.
  Iterable<T> get toDartIterable => _JSIterableToIterable<T>(this);
}

/// A wrapper around a [JSIterable] that implements the Dart iterable API.
class _JSIterableToIterable<T extends JSAny?> extends Iterable<T> {
  /// The wrapped JavaScript iterable.
  final JSIterableProtocol<T> _js;

  _JSIterableToIterable(this._js);

  @override
  Iterator<T> get iterator => _JSIteratorToIterator<T>(_js.iterator);
}

/// Conversion from [Iterator] to [JSIterator].
@Since('3.12')
extension IteratorToJSIterator<T extends JSAny?> on Iterator<T> {
  /// Returns a [JSIterator] wrapper that proxies to the Dart iterator API.
  JSIterator<T> get toJSIterator => JSIterator.fromFunctions<T>(
    () => this.moveNext()
        ? JSIteratorResult<T>.value(this.current)
        : JSIteratorResult<T>.done(),
  );
}

/// Conversion from [JSIterator] to [Iterator].
@Since('3.12')
extension JSIteratorToIterator<T extends JSAny?> on JSIterator<T> {
  /// Returns a Dart [Iterator] that iterates over the values in this.
  Iterator<T> get toDartIterator => _JSIteratorToIterator<T>(this);
}

/// A wrapper around a [JSIterator] that implements the Dart iterator API.
class _JSIteratorToIterator<T extends JSAny?> implements Iterator<T> {
  /// The wrapped JavaScript iterator.
  final JSIteratorProtocol<T> _js;

  /// The most recent result emitted by [_js].
  JSIteratorResult<T>? _lastResult;

  @override
  T get current {
    if (_lastResult case final result?) {
      if (result.isDone) {
        throw StateError(
          "current can't be called after the end of an iterator.",
        );
      } else {
        return result.value as T;
      }
    } else {
      throw StateError("moveNext must be called before current.");
    }
  }

  _JSIteratorToIterator(this._js);

  @override
  bool moveNext() {
    final result = _js.next();
    _lastResult = result;
    return !result.isDone;
  }
}

/// Conversions from [JSArray] to [List].
extension JSArrayToList<T extends JSAny?> on JSArray<T> {
  /// Converts this [JSArray] to a [List] by either casting or wrapping it.
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, core [List]s are `Array`s and therefore, if
  /// the [JSArray] was already a <code>[List]<T></code> converted via
  /// [ListToJSArray.toJS], this getter simply casts the `Array`. Otherwise, it
  /// wraps the `Array` with a [List] that casts the elements to [T] to ensure
  /// soundness.
  ///
  /// When compiling to Wasm, the [JSArray] is wrapped with a [List]
  /// implementation and the wrapper is returned.
  ///
  /// Modifications to this [JSArray] will affect the returned [List] and vice
  /// versa.
  external List<T> get toDart;
}

/// Conversions from [List] to [JSArray].
extension ListToJSArray<T extends JSAny?> on List<T> {
  /// Converts this [List] to a [JSArray] by either casting, unwrapping, or
  /// cloning the [List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, the core [List] is a JavaScript `Array`, and
  /// therefore this getter simply casts. If the [List] is not a core [List]
  /// e.g. a user-defined list, this getter throws with a cast error.
  ///
  /// When compiling to Wasm, this [List] is a wrapper around an `Array` if it
  /// was converted via [JSArrayToList.toDart]. If it's a wrapper, this getter
  /// unwraps it and returns the `Array`. If it's instantiated in Dart, this
  /// getter clones this [List]'s values into a new [JSArray].
  ///
  /// Avoid assuming that modifications to this [List] will affect the returned
  /// [JSArray] and vice versa in all compilers unless it was first converted
  /// via [JSArrayToList.toDart].
  external JSArray<T> get toJS;

  /// Converts this [List] to a [JSArray] by either casting, unwrapping, or
  /// proxying the [List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  ///
  /// When compiling to JavaScript, the core [List] is a JavaScript `Array`, and
  /// therefore this getter simply casts. If the [List] is not a core [List]
  /// e.g. a user-defined list, this getter throws with a cast error.
  ///
  /// When compiling to Wasm, this [List] is a wrapper around an `Array` if it
  /// was converted via [JSArrayToList.toDart]. If it's a wrapper, this getter
  /// unwraps it and returns the `Array`. If it's instantiated in Dart, this
  /// getter proxies the [List] using a heavyweight `Array` wrapper. Access to
  /// the original [List]'s elements may be very unperformant.
  ///
  /// Modifications to this [List] will affect the returned [JSArray] and vice
  /// versa.
  external JSArray<T> get toJSProxyOrRef;
}

/// Conversions from [JSNumber] to [double] or [int].
extension JSNumberToNumber on JSNumber {
  /// Converts this [JSNumber] to a [double].
  external double get toDartDouble;

  /// Converts this [JSNumber] to an [int].
  ///
  /// If this [JSNumber] is not an integer value, throws.
  external int get toDartInt;
}

/// Conversions from [double] to [JSNumber].
extension DoubleToJSNumber on double {
  /// Converts this [double] to a [JSNumber].
  external JSNumber get toJS;
}

/// Conversions from [num] to [JSNumber].
extension NumToJSExtension on num {
  /// Converts this [num] to a [JSNumber].
  JSNumber get toJS => DoubleToJSNumber(toDouble()).toJS;
}

/// Conversions from [JSBoolean] to [bool].
extension JSBooleanToBool on JSBoolean {
  /// Converts this [JSBoolean] to a [bool].
  external bool get toDart;
}

/// Conversions from [bool] to [JSBoolean].
extension BoolToJSBoolean on bool {
  /// Converts this [bool] to a [JSBoolean].
  external JSBoolean get toJS;
}

/// Conversions from [JSString] to [String].
extension JSStringToString on JSString {
  /// Converts this [JSString] to a [String].
  external String get toDart;
}

/// Conversions from [String] to [JSString].
extension StringToJSString on String {
  /// Converts this [String] to a [JSString].
  external JSString get toJS;
}

/// General-purpose JavaScript operators.
///
/// Indexing operators (`[]`, `[]=`) should be declared through operator
/// overloading instead like:
/// ```
/// external operator int [](int key);
/// ```
///
/// All operators in this extension shall accept and return only JS types.
// TODO(srujzs): Add more as needed. For now, we just expose the ones needed to
// migrate from `dart:js_util`.
extension JSAnyOperatorExtension on JSAny? {
  // Arithmetic operators.

  /// The result of <code>`this` + [any]</code> in JavaScript.
  external JSAny add(JSAny? any);

  /// The result of <code>`this` - [any]</code> in JavaScript.
  external JSAny subtract(JSAny? any);

  /// The result of <code>`this` * [any]</code> in JavaScript.
  external JSAny multiply(JSAny? any);

  /// The result of <code>`this` / [any]</code> in JavaScript.
  external JSAny divide(JSAny? any);

  /// The result of <code>`this` % [any]</code> in JavaScript.
  external JSAny modulo(JSAny? any);

  /// The result of <code>`this` ** [any]</code> in JavaScript.
  external JSAny exponentiate(JSAny? any);

  // Comparison operators.

  /// The result of <code>`this` > [any]</code> in JavaScript.
  external JSBoolean greaterThan(JSAny? any);

  /// The result of <code>`this` >= [any]</code> in JavaScript.
  external JSBoolean greaterThanOrEqualTo(JSAny? any);

  /// The result of <code>`this` < [any]</code> in JavaScript.
  external JSBoolean lessThan(JSAny? any);

  /// The result of <code>`this` <= [any]</code> in JavaScript.
  external JSBoolean lessThanOrEqualTo(JSAny? any);

  /// The result of <code>`this` == [any]</code> in JavaScript.
  external JSBoolean equals(JSAny? any);

  /// The result of <code>`this` != [any]</code> in JavaScript.
  external JSBoolean notEquals(JSAny? any);

  /// The result of <code>`this` === [any]</code> in JavaScript.
  external JSBoolean strictEquals(JSAny? any);

  /// The result of <code>`this` !== [any]</code> in JavaScript.
  external JSBoolean strictNotEquals(JSAny? any);

  // Bitwise operators.

  /// The result of <code>`this` >>> [any]</code> in JavaScript.
  // TODO(srujzs): This should return `num` or `double` instead.
  external JSNumber unsignedRightShift(JSAny? any);

  // Logical operators.

  /// The result of <code>`this` && [any]</code> in JavaScript.
  external JSAny? and(JSAny? any);

  /// The result of <code>`this` || [any]</code> in JavaScript.
  external JSAny? or(JSAny? any);

  /// The result of <code>!`this`</code> in JavaScript.
  external JSBoolean get not;

  /// The result of <code>!!`this`</code> in JavaScript.
  external JSBoolean get isTruthy;
}

/// The global scope that is used to find user-declared interop members.
///
/// For example:
///
/// ```
/// library;
///
/// @JS()
/// external String get name;
/// ```
///
/// Reading the top-level member `name` will execute JavaScript code like
/// `<globalContext>.name`.
///
/// There are subtle differences depending on the compiler, but in general,
/// [globalContext] can be treated like JavaScript's `globalThis`.
external JSObject get globalContext;

/// Given a instance of a Dart class that contains an <code>@[JSExport]</code>
/// annotation, creates a JavaScript object that wraps the given Dart object.
///
/// The object literal will be a map of properties, which are either the written
/// instance member names or their renames, to callbacks that call the
/// corresponding Dart instance members.
///
/// If [proto] is provided, it will be used as the prototype for the created
/// object.
///
/// See https://dart.dev/interop/js-interop/mock for more details on how to
/// declare classes that can be used in this method.
external JSObject createJSInteropWrapper<T extends Object>(
  T dartObject, [
  JSObject? proto = null,
]);

// TODO(srujzs): Expose this method when we handle conformance checking for
// interop extension types. We don't expose this method today due to the bound
// on `T`. `@staticInterop` types can't implement `JSObject`, so this method
// simply wouldn't work. We could make it extend `Object` to support the
// `@staticInterop` case, but if we ever refactor to `extends JSObject`, this
// would be a breaking change. For now, due to the low usage of
// `createStaticInteropMock`, we avoid introducing this method until later.
// external T createJSInteropMock<T extends JSObject, U extends Object>(
//     U dartMock, [JSObject? proto = null]);

/// Dynamically imports a JavaScript module with the given [moduleName] using
/// the JavaScript `import()` syntax.
///
/// See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/import
/// for more details.
///
/// Returns a [JSPromise] that resolves to a [JSObject] that's the module
/// namespace object.
external JSPromise<JSObject> importModule(JSAny moduleName);
