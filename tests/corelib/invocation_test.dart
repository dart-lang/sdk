// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests the constructors of the Invocation class.

main() {
  {
    var name = "getter";
    var invocation = new Invocation.getter(#name);
    Expect.isTrue(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isTrue(invocation.isAccessor, "$name:isAccessor");
    Expect.isFalse(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals([], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);
  }
  {
    var name = "setter";
    var argument = new Object();
    var invocation = new Invocation.setter(const Symbol("name="), argument);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isTrue(invocation.isSetter, "$name:isSetter");
    Expect.isTrue(invocation.isAccessor, "$name:isAccessor");
    Expect.isFalse(invocation.isMethod, "$name:isMethod");
    Expect.equals(const Symbol("name="), invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);
  }
  {
    var name = ".name()";
    var invocation = new Invocation.method(#name, []);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals([], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation("$name:", invocation, new Invocation.method(#name, null));
    expectInvocation(
        "$name:", invocation, new Invocation.method(#name, [], null));
    expectInvocation(
        "$name:", invocation, new Invocation.method(#name, [], {}));

    expectInvocation(
        "$name:", invocation, new Invocation.genericMethod(#name, [], []));
    expectInvocation(
        "$name:", invocation, new Invocation.genericMethod(#name, [], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [], [], null));
    expectInvocation(
        "$name:", invocation, new Invocation.genericMethod(#name, [], [], {}));
    expectInvocation(
        "$name:", invocation, new Invocation.genericMethod(#name, null, []));
    expectInvocation(
        "$name:", invocation, new Invocation.genericMethod(#name, null, null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, null, [], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, null, [], {}));
  }
  {
    var name = ".name(a)";
    var argument = new Object();
    var invocation = new Invocation.method(#name, [argument]);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation(
        "$name:", invocation, new Invocation.method(#name, [argument], null));
    expectInvocation(
        "$name:", invocation, new Invocation.method(#name, [argument], {}));

    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [], [argument], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [], [argument], {}));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, null, [argument], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, null, [argument], {}));
  }
  {
    var name = ".name(a,b)";
    var argument = new Object();
    var argument2 = new Object();
    var invocation = new Invocation.method(#name, [argument, argument2]);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals(
        [argument, argument2], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation("$name:", invocation,
        new Invocation.method(#name, [argument, argument2], null));
    expectInvocation("$name:", invocation,
        new Invocation.method(#name, [argument, argument2], {}));

    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [], [argument, argument2], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [], [argument, argument2], {}));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, null, [argument, argument2], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, null, [argument, argument2], {}));
  }
  {
    var name = ".name(a,b:)";
    var argument = new Object();
    var argument2 = new Object();
    var invocation =
        new Invocation.method(#name, [argument], {#arg: argument2});
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals(
        {#arg: argument2}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation(
        "$name:",
        invocation,
        new Invocation.genericMethod(
            #name, null, [argument], {#arg: argument2}));
  }
  {
    var name = ".name(a:,b:)";
    var argument = new Object();
    var argument2 = new Object();
    var invocation =
        new Invocation.method(#name, [], {#arg: argument, #arg2: argument2});
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([], invocation.typeArguments, "$name:types");
    Expect.listEquals([], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({#arg: argument, #arg2: argument2},
        invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation("$name:", invocation,
        new Invocation.method(#name, null, {#arg: argument, #arg2: argument2}));
    expectInvocation(
        "$name:",
        invocation,
        new Invocation.genericMethod(
            #name, null, [], {#arg: argument, #arg2: argument2}));
    expectInvocation(
        "$name:",
        invocation,
        new Invocation.genericMethod(
            #name, null, null, {#arg: argument, #arg2: argument2}));
  }
  {
    var name = ".name<i>()";
    var invocation = new Invocation.genericMethod(#name, [int], []);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([int], invocation.typeArguments, "$name:types");
    Expect.listEquals([], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation(
        "$name:", invocation, new Invocation.genericMethod(#name, [int], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], [], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], null, null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], [], {}));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], null, {}));
  }
  {
    var name = ".name<i>(a)";
    var argument = new Object();
    var invocation = new Invocation.genericMethod(#name, [int], [argument]);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([int], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], [argument], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], [argument], {}));
  }
  {
    var name = ".name<i>(a,b)";
    var argument = new Object();
    var argument2 = new Object();
    var invocation =
        new Invocation.genericMethod(#name, [int], [argument, argument2]);
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([int], invocation.typeArguments, "$name:types");
    Expect.listEquals(
        [argument, argument2], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation(
        "$name:",
        invocation,
        new Invocation.genericMethod(
            #name, [int], [argument, argument2], null));
    expectInvocation("$name:", invocation,
        new Invocation.genericMethod(#name, [int], [argument, argument2], {}));
  }
  {
    var name = ".name<i>(a,b:)";
    var argument = new Object();
    var argument2 = new Object();
    var invocation = new Invocation.genericMethod(
        #name, [int], [argument], {#arg: argument2});
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([int], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals(
        {#arg: argument2}, invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);
  }
  {
    var name = ".name<i>(a:,b:)";
    var argument = new Object();
    var argument2 = new Object();
    var invocation = new Invocation.genericMethod(
        #name, [int], [], {#arg: argument, #arg2: argument2});
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals([int], invocation.typeArguments, "$name:types");
    Expect.listEquals([], invocation.positionalArguments, "$name:pos");
    Expect.mapEquals({#arg: argument, #arg2: argument2},
        invocation.namedArguments, "$name: named");
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);

    expectInvocation(
        "$name:",
        invocation,
        new Invocation.genericMethod(
            #name, [int], null, {#arg: argument, #arg2: argument2}));
  }
  {
    // Many arguments.
    var name = ".name<..>(..,..:)";
    var argument = new Object();
    var argument2 = new Object();
    Type intList = new TypeHelper<List<int>>().type;
    var invocation = new Invocation.genericMethod(
        #name,
        [int, double, intList],
        [argument, argument2, null, argument],
        {#arg: argument, #arg2: argument2, #arg3: null, #arg4: argument});
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals(
        [int, double, intList], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument, argument2, null, argument],
        invocation.positionalArguments, "$name:pos");
    Expect.mapEquals(
        {#arg: argument, #arg2: argument2, #arg3: null, #arg4: argument},
        invocation.namedArguments);
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);
  }
  {
    // Accepts iterables, not just lists.
    var name = "iterables";
    var argument = new Object();
    var argument2 = new Object();
    Type intList = new TypeHelper<List<int>>().type;
    var invocation = new Invocation.genericMethod(
        #name,
        [int, double, intList].where(kTrue),
        [argument, argument2, null, argument].where(kTrue),
        {#arg: argument, #arg2: argument2, #arg3: null, #arg4: argument});
    Expect.isFalse(invocation.isGetter, "$name:isGetter");
    Expect.isFalse(invocation.isSetter, "$name:isSetter");
    Expect.isFalse(invocation.isAccessor, "$name:isAccessor");
    Expect.isTrue(invocation.isMethod, "$name:isMethod");
    Expect.equals(#name, invocation.memberName, "$name:name");
    Expect.listEquals(
        [int, double, intList], invocation.typeArguments, "$name:types");
    Expect.listEquals([argument, argument2, null, argument],
        invocation.positionalArguments, "$name:pos");
    Expect.mapEquals(
        {#arg: argument, #arg2: argument2, #arg3: null, #arg4: argument},
        invocation.namedArguments);
    checkUnmodifiableList("$name types", invocation.typeArguments);
    checkUnmodifiableList("$name positional", invocation.positionalArguments);
    checkUnmodifiableMap("$name named", invocation.namedArguments);
  }
}

void checkUnmodifiableList(String name, List<Object?> list) {
  if (list.isNotEmpty) {
    Expect.throws(() {
      list[0] = null;
    }, (_) => true, "$name: list not unmodifiable");
  }
  Expect.throws(() {
    list.add(null);
  }, (_) => true, "$name: list not unmodifiable");
}

void checkUnmodifiableMap(String name, Map<Symbol, Object?> map) {
  Expect.throws(() {
    map[#key] = null;
  }, (_) => true, "$name: map not unmodifiable");
}

class TypeHelper<T> {
  Type get type => T;
}

expectInvocation(String name, Invocation expect, Invocation actual) {
  Expect.equals(expect.isGetter, actual.isGetter, "$name:isGetter");
  Expect.equals(expect.isSetter, actual.isSetter, "$name:isSetter");
  Expect.equals(expect.isAccessor, actual.isAccessor, "$name:isAccessor");
  Expect.equals(actual.isGetter || actual.isSetter, actual.isAccessor);
  Expect.equals(expect.isMethod, actual.isMethod, "$name:isMethod");
  Expect.isTrue(actual.isMethod || actual.isGetter || actual.isSetter);
  Expect.isFalse(actual.isMethod && actual.isGetter);
  Expect.isFalse(actual.isMethod && actual.isSetter);
  Expect.isFalse(actual.isSetter && actual.isGetter);
  Expect.equals(expect.memberName, actual.memberName, "$name:memberName");
  Expect.listEquals(expect.typeArguments, actual.typeArguments, "$name:types");
  Expect.listEquals(
      expect.positionalArguments, actual.positionalArguments, "$name:pos");
  Expect.mapEquals(expect.namedArguments, actual.namedArguments, "$name:named");
  checkUnmodifiableList(name, actual.typeArguments);
  checkUnmodifiableList(name, actual.positionalArguments);
  checkUnmodifiableMap(name, actual.namedArguments);
}

bool kTrue(_) => true;
