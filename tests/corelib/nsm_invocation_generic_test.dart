// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test the invocations passed to noSuchMethod for generic invocations.

main() {
  var argument = new Object();
  var argument2 = new Object();
  // Method invocation.
  expectInvocation(
      new Invocation.genericMethod(#name, [int], []), nsm.name<int>());
  expectInvocation(new Invocation.genericMethod(#name, [int], [argument]),
      nsm.name<int>(argument));
  expectInvocation(
      new Invocation.genericMethod(#name, [int], [], {#arg: argument}),
      nsm.name<int>(arg: argument));
  expectInvocation(
      new Invocation.genericMethod(#name, [int], [argument], {#arg: argument2}),
      nsm.name<int>(argument, arg: argument2));
  // Call invocation.
  expectInvocation(new Invocation.genericMethod(#call, [int], []), nsm<int>());
  expectInvocation(new Invocation.genericMethod(#call, [int], [argument]),
      nsm<int>(argument));
  expectInvocation(
      new Invocation.genericMethod(#call, [int], [], {#arg: argument}),
      nsm<int>(arg: argument));
  expectInvocation(
      new Invocation.genericMethod(#call, [int], [argument], {#arg: argument2}),
      nsm<int>(argument, arg: argument2));
}

dynamic nsm = new Recorder();

class Recorder {
  noSuchMethod(Invocation invocation) {
    return invocation;
  }
}

void checkUnmodifiableList(List<dynamic> list) {
  if (list.isNotEmpty) {
    Expect.throws(() {
      list[0] = null;
    });
  }
  Expect.throws(() {
    list.add(null);
  });
}

void checkUnmodifiableMap(Map<Symbol, dynamic> map) {
  Expect.throws(() {
    map[#key] = null;
  });
}

expectInvocation(Invocation expect, Invocation actual) {
  Expect.equals(expect.isGetter, actual.isGetter, "isGetter");
  Expect.equals(expect.isSetter, actual.isSetter, "isSetter");
  Expect.equals(expect.isAccessor, actual.isAccessor, "isAccessor");
  Expect.equals(actual.isGetter || actual.isSetter, actual.isAccessor);
  Expect.equals(expect.isMethod, actual.isMethod, "isMethod");
  Expect.isTrue(actual.isMethod || actual.isGetter || actual.isSetter);
  Expect.isFalse(actual.isMethod && actual.isGetter);
  Expect.isFalse(actual.isMethod && actual.isSetter);
  Expect.isFalse(actual.isSetter && actual.isGetter);
  Expect.equals(expect.memberName, actual.memberName, "memberName");
  Expect.listEquals(expect.typeArguments, actual.typeArguments, "types");
  Expect.listEquals(
      expect.positionalArguments, actual.positionalArguments, "positional");
  Expect.mapEquals(expect.namedArguments, actual.namedArguments, "named");
  checkUnmodifiableList(actual.typeArguments);
  checkUnmodifiableList(actual.positionalArguments);
  checkUnmodifiableMap(actual.namedArguments);
}
