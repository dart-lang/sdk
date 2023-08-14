// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to manipulate JS objects dynamically.
///
/// This library is meant to be used when the names of properties or methods are
/// not known statically. This library is similar to 'dart:js_util', except
/// the methods here are extension methods that use JS types. This enables
/// support with dart2wasm.
///
/// In general, we expect people to use 'dart:js_interop' and that this library
/// will be rarely used. Prefer to write JS interop interfaces and external
/// static interop members using 'dart:js_interop'. The APIs in this library are
/// meant to work around issues and help with migration from older JS interop
/// libraries like 'dart:js'.
///
/// As the name suggests, usage of this library is considered unsafe. This means
/// that safe usage of these methods cannot necessarily be verified statically.
/// Therefore, they should be used cautiously and only when the same effect
/// cannot be achieved with static interop.
///
/// {@category Web}
library dart.js_interop_unsafe;

import 'dart:js_interop';

extension JSObjectUtilExtension on JSObject {
  /// Whether or not this [JSObject] has a given property.
  external JSBoolean hasProperty(JSAny property);

  /// Equivalent to invoking operator `[]` in JS.
  external JSAny? operator [](JSAny property);

  /// Gets a given property from this [JSObject].
  T getProperty<T extends JSAny?>(JSAny property) => this[property] as T;

  /// Equivalent to invoking `[]=` in JS.
  external void operator []=(JSAny property, JSAny? value);

  /// Calls a method on this [JSObject] with up to four arguments and returns
  /// the result.
  external JSAny? _callMethod(JSAny method,
      [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);
  T callMethod<T extends JSAny?>(JSAny method,
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      _callMethod(method, arg1, arg2, arg3, arg4) as T;

  /// Calls a method on this [JSObject] with a variable number of arguments and
  /// returns the result.
  external JSAny? _callMethodVarArgs(JSAny method, [List<JSAny?>? arguments]);
  T callMethodVarArgs<T extends JSAny?>(JSAny method,
          [List<JSAny?>? arguments]) =>
      _callMethodVarArgs(method, arguments) as T;

  /// Deletes the given property from this [JSObject].
  external JSBoolean delete(JSAny property);
}

extension JSFunctionUtilExtension on JSFunction {
  /// Calls this [JSFunction] as a constructor with up to four arguments and
  /// returns the constructed [JSObject].
  external JSObject _callAsConstructor(
      [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);
  T callAsConstructor<T>(
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      _callAsConstructor(arg1, arg2, arg3, arg4) as T;

  /// Calls this [JSFunction] as a constructor with a variable number of
  /// arguments and returns the constructed [JSObject].
  external JSObject _callAsConstructorVarArgs([List<JSAny?>? arguments]);
  T callAsConstructorVarArgs<T extends JSObject>([List<JSAny?>? arguments]) =>
      _callAsConstructorVarArgs(arguments) as T;
}
