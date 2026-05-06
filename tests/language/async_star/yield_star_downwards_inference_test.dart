// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../static_type_helper.dart';

class A implements Stream<dynamic> {
  final Stream<dynamic> _stream = (() async* {})();

  /// This do-nothing method is only defined for the class `A`, so calling it
  /// serves as a runtime check that `this` is `A`.
  void checkThisIsA() {}

  @override
  listen(onData, {onError, onDone, cancelOnError}) => _stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

dynamic returnTypeIsDynamic() async* {
  T f<T>() => A() as T;

  // Downward inference context for the operand of `yield*` is `_`, so `f` is
  // instantiated as `f<dynamic>`, hence the call to `..checkThisIsA()` is
  // allowed (it's a dynamic invocation).
  yield* f()..checkThisIsA();
}

Stream<dynamic> returnTypeIsStreamDynamic() async* {
  // Downward inference context for the operand of `yield*` is
  // `Stream<dynamic>`.
  yield* contextType(A())..expectStaticType<Exactly<Stream<dynamic>>>();
}

dynamic returnContextIsUnknown() {
  T f<T>() => A() as T;

  var g = () async* {
    // Downward inference context for the operand of `yield*` is `_`, so `f` is
    // instantiated as `f<dynamic>`, hence the call to `..checkThisIsA()` is
    // allowed (it's a dynamic invocation).
    yield* f()..checkThisIsA();
  };
  return g();
}

dynamic returnContextIsStreamUnknown() {
  T f<T>(Stream<T> Function() g) => g() as T;
  T h<T>() => A() as T;

  var x = f(
    // Context for `f(...)` is `_`, so context for this closure is
    // `Stream<_> Function()`.
    () async* {
      // Downward inference context for the operand of `yield*` is `_`, so `h`
      // is instantiated as `h<dynamic>`, hence the call to `..checkThisIsA()`
      // is allowed (it's a dynamic invocation).
      yield* h()..checkThisIsA();
    },
  );

  // f() returns the yielded stream, so just return x.
  return x;
}

main() async {
  await for (var _ in returnTypeIsDynamic()) {}
  await for (var _ in returnTypeIsStreamDynamic()) {}
  await for (var _ in returnContextIsUnknown()) {}
  await for (var _ in returnContextIsStreamUnknown()) {}
}
