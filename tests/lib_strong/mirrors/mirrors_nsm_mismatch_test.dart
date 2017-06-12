// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.mirrors_nsm_mistatch;

import 'dart:mirrors';
import 'mirrors_nsm_test.dart';

topLevelMethod({missing}) {}

class C {
  C.constructor({missing});
  factory C.redirecting({missing}) = C.constructor;
  static staticMethod({missing}) {}
  instanceMethod({missing}) {}
}

main() {
  var mirrors = currentMirrorSystem();
  var libMirror = mirrors.findLibrary(#test.mirrors_nsm_mistatch);
  expectMatchingErrors(() => libMirror.invoke(#topLevelMethod, [], {#extra: 1}),
      () => topLevelMethod(extra: 1));
  expectMatchingErrors(() => libMirror.invoke(#topLevelMethod, ['positional']),
      () => topLevelMethod('positional'));

  var classMirror = reflectClass(C);
  expectMatchingErrors(
      () => classMirror.newInstance(#constructor, [], {#extra: 1}),
      () => new C.constructor(extra: 1));
  expectMatchingErrors(
      () => classMirror.newInstance(#redirecting, [], {#extra: 1}),
      () => new C.redirecting(extra: 1));
  expectMatchingErrors(() => classMirror.invoke(#staticMethod, [], {#extra: 1}),
      () => C.staticMethod(extra: 1));
  expectMatchingErrors(
      () => classMirror.newInstance(#constructor, ['positional']),
      () => new C.constructor('positional'));
  expectMatchingErrors(
      () => classMirror.newInstance(#redirecting, ['positional']),
      () => new C.redirecting('positional'));
  expectMatchingErrors(() => classMirror.invoke(#staticMethod, ['positional']),
      () => C.staticMethod('positional'));

  var instanceMirror = reflect(new C.constructor());
  expectMatchingErrors(
      () => instanceMirror.invoke(#instanceMethod, [], {#extra: 1}),
      () => instanceMirror.reflectee.instanceMethod(extra: 1));
  expectMatchingErrors(
      () => instanceMirror.invoke(#instanceMethod, ['positional']),
      () => instanceMirror.reflectee.instanceMethod('positional'));
}
