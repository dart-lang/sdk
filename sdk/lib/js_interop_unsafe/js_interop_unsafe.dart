// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Typed utility methods to manipulate JS objects in cases where the name to
/// call is not known at runtime.
///
/// Safe usage of these methods cannot necessarily be verified statically.
/// Therefore, they should be used cautiously and only when the same effect
/// cannot be achieved with static interop.
///
/// {@category Web}
library dart.js_util_typed;

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
