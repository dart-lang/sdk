// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests the constructors of the Invocation class.

main() {
  var argument = new Object();
  var argument2 = new Object();
  // Getter Invocation.
  expectInvocation(new Invocation.getter(#name), nsm.name);
  // Setter Invocation.
  expectInvocation(new Invocation.setter(const Symbol("name="), argument),
      (nsm..name = argument).last);
  // Method invocation.
  expectInvocation(new Invocation.method(#name, []), nsm.name());
  expectInvocation(
      new Invocation.method(#name, [argument]), nsm.name(argument));
  expectInvocation(new Invocation.method(#name, [], {#arg: argument}),
      nsm.name(arg: argument));
  expectInvocation(new Invocation.method(#name, [argument], {#arg: argument2}),
      nsm.name(argument, arg: argument2));
  // Operator invocation.
  expectInvocation(new Invocation.method(#+, [argument]), nsm + argument);
  expectInvocation(new Invocation.method(#-, [argument]), nsm - argument);
  expectInvocation(new Invocation.method(#~, []), ~nsm);
  expectInvocation(new Invocation.method(Symbol.unaryMinus, []), -nsm);
  expectInvocation(new Invocation.method(#[], [argument]), nsm[argument]);
  nsm[argument] = argument2;
  expectInvocation(
      new Invocation.method(#[]=, [argument, argument2]), nsm.last);
  // Call invocation.
  expectInvocation(new Invocation.method(#call, []), nsm());
  expectInvocation(new Invocation.method(#call, [argument]), nsm(argument));
  expectInvocation(
      new Invocation.method(#call, [], {#arg: argument}), nsm(arg: argument));
  expectInvocation(new Invocation.method(#call, [argument], {#arg: argument2}),
      nsm(argument, arg: argument2));
}

dynamic nsm = new Recorder();

class Recorder {
  Invocation last;
  noSuchMethod(Invocation invocation) {
    return last = invocation;
  }
}

void checkUnmodifiableList(List<Object> list) {
  if (list.isNotEmpty) {
    Expect.throws(() {
      list[0] = null;
    });
  }
  Expect.throws(() {
    list.add(null);
  });
}

void checkUnmodifiableMap(Map<Symbol, Object> map) {
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
