// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=triple-shift

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// The >>> operator is (again) supported by Dart
// (This test does not test int.operator>>>, such a test belongs in the corelib
// test collection. Const uses of int.operator>>> is tested elsewhere as well).

/// Syntactically tricky coincidences containing >>> and >>>=.
/// DO NOT FORMAT THIS FILE. There should not be a space between >>> and =.
typedef F3<T extends List<List<int>>>= T Function();
typedef F4<T extends List<List<List<int>>>>= T Function();
typedef F5<T extends List<List<List<List<int>>>>>= T Function();
typedef F6<T extends List<List<List<List<List<int>>>>>>= T Function();
class E3<T extends List<List<int>>> {}
class E4<T extends List<List<List<int>>>> {}
class E5<T extends List<List<List<List<int>>>>> {}
class E6<T extends List<List<List<List<List<int>>>>>> {}

main() {
  // >>> is an overridable operator.
  const c1 = C(1);
  const c2 = C(2);
  Expect.identical(c2, c1 >>> c2);

  /// It combines to an assignment operator.
  C c = c1;
  c >>>= c2;
  Expect.identical(c2, c);

  // Operand needs to have correct type for typed invocation.
  c1 //
     >>> 4 //# 01: compile-time error
     >>> "string" //# 02: compile-time error
  ;
  c //
     >>>= 4 //# 03: compile-time error
  ;

  // Dynamic invocations are allowed, and check types at run-time.
  dynamic d = c1;
  Expect.identical(c2, d >>> c2);
  Expect.throws(() => d >>> 4);

  // There is a symbol for >>>, both as constructed and literal.
  Expect.identical(const Symbol(">>>"), #>>>);

  // No such method can catch dynamic invocations of >>>:
  dynamic nsm = NSM();
  Invocation invocation = nsm >>> c2;
  Expect.isTrue(invocation.isMethod);
  Expect.isFalse(invocation.isAccessor);
  Expect.equals(#>>>, invocation.memberName);
  Expect.equals(1, invocation.positionalArguments.length);
  Expect.identical(c2, invocation.positionalArguments[0]);
  Expect.equals(0, invocation.namedArguments.length);

  invocation = (nsm >>>= c2);
  Expect.isTrue(invocation.isMethod);
  Expect.isFalse(invocation.isAccessor);
  Expect.equals(#>>>, invocation.memberName);
  Expect.equals(1, invocation.positionalArguments.length);
  Expect.identical(c2, invocation.positionalArguments[0]);
  Expect.equals(0, invocation.namedArguments.length);

  // And unimplemented interface methods.
  ShiftNSM shnsm = ShiftNSM();
  invocation = shnsm >>> c2;
  Expect.isTrue(invocation.isMethod);
  Expect.isFalse(invocation.isAccessor);
  Expect.equals(#>>>, invocation.memberName);
  Expect.equals(1, invocation.positionalArguments.length);
  Expect.identical(c2, invocation.positionalArguments[0]);
  Expect.equals(0, invocation.namedArguments.length);

  // If there is an interface, we must match it, even if the call
  // otherwise goes to noSuchMethod.
  shnsm //
      >>> 4 //# 04: compile-time error
  ;

  /// A type error in the nSM return value is caught.
  dynamic badNSM = BadNSM();
  Expect.throws(() => badNSM >>> "not an int", (e) => e != "Unreachable");
  Expect.throws(() => badNSM >>> 4, (e) => e != "Unreachable");

  asyncStart();
  () async {
    // Operands can be asynchronous.
    var fc1 = Future.value(c1);
    var fc2 = Future.value(c2);
    Expect.identical(c2, (await fc1) >>> (await fc2));
    /// The operator itself can be async.
    var async = Async();
    Expect.identical(c1, await (async >>> c1));

    var asyncStar = AsyncStar();
    int count = 0;
    await for (var v in asyncStar >>> c1) {
      count++;
      Expect.identical(c1, v);
    }
    Expect.equals(1, count);
    asyncEnd();
  }();

  {
    var syncStar = SyncStar();
    int count = 0;
    for (var v in syncStar >>> c1) {
      count++;
      Expect.identical(c1, v);
    }
    Expect.equals(1, count);
  }

  // >>> has same precedence as >> (and <<), is left associative.
  // Binds weaker than addition/multiplication, stronger than other bitwise
  // operators and comparisons.
  final a = Assoc("*");
  Expect.equals("((~*)>>>(~*))", "${~a >>> ~a}");
  Expect.equals("((*+*)>>>(*+*))", "${a + a >>> a + a}");
  Expect.equals("((*/*)>>>(*/*))", "${a / a >>> a / a}");
  Expect.equals("(((*>>*)>>>*)>>*)", "${a >> a >>> a >> a}");
  Expect.equals("((*&(*>>>*))&*)", "${a & a >>> a & a}");
  Expect.equals("((*|(*>>>*))|*)", "${a | a >>> a | a}");
  Expect.equals("((*^(*>>>*))^*)", "${a ^ a >>> a ^ a}");
  Expect.equals("(*<(*>>>*))", "${a < a >>> a}");
  Expect.equals("((*>>>*)<*)", "${a >>> a < a}");

  var res = a;
  res >>>= a;
  res >>>= a;
  Expect.equals("((*>>>*)>>>*)", "$res");

  // Exercise the type declarations below.
  E3<List<List<int>>>();
  E4<List<List<List<int>>>>();
  E5<List<List<List<List<int>>>>>();
  E6<List<List<List<List<List<int>>>>>>();
  Expect.type<F3<List<List<int>>>>(() => <List<int>>[]);
  Expect.type<F4<List<List<List<int>>>>>(() => <List<List<int>>>[]);
  Expect.type<F5<List<List<List<List<int>>>>>>(() => <List<List<List<int>>>>[]);
  Expect.type<F6<List<List<List<List<List<int>>>>>>>(
      () => <List<List<List<List<int>>>>>[]);
}

/// Class with a simple overridden `operator>>>`.
class C {
  final int id;
  const C(this. id);
  C operator >>>(C other) => other;
  String toString() => "C($id)";
}

/// Invalid declarations of `>>>` operator.
class Invalid {
  // Overridable operator must have exactly one required parameter.
  Object operator>>>() => null;  //# arg0: compile-time error
  Object operator>>>(v1, v2) => null;  //# arg2: compile-time error
  Object operator>>>([v1]) => null;  //# argOpt: compile-time error
  Object operator>>>({v1}) => null;  //# argNam: compile-time error
}

/// Class with noSuchMethod and no `>>>` operator.
class NSM {
  dynamic noSuchMethod(Invocation invocation) {
    return invocation;
  }
}

/// Class with nSM and abstract `>>>` (implicit typed forwarder).
class ShiftNSM extends NSM {
  dynamic operator>>>(C o);
}

/// Class with nSM and abstract `>>>` where nSM returns wrong type.
class BadNSM {
  int operator>>>(int n);
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #>>>) {
      if (i.positionalArguments.first is! int) throw "Unreachable";
      return "notAnInt";
    }
    return super.noSuchMethod(i);
  }
}

/// Class with an `async` implementation of `operator >>>`
class Async {
  Future<C> operator >>>(C value) async => value;
}

/// Class with an `async*` implementation of `operator >>>`
class AsyncStar {
  Stream<C> operator >>>(C value) async* {
    yield value;
  }
}

/// Class with a `sync*` implementation of `operator >>>`
class SyncStar {
  Iterable<C> operator >>>(C value) sync* {
    yield value;
  }
}

/// Helper class to record precedence and associativity of operators.
class Assoc {
  final String ops;
  Assoc(this.ops);
  Assoc operator ~() => Assoc("(~${this})");
  Assoc operator +(Assoc other) => Assoc("(${this}+$other)");
  Assoc operator /(Assoc other) => Assoc("(${this}/$other)");
  Assoc operator &(Assoc other) => Assoc("(${this}&$other)");
  Assoc operator |(Assoc other) => Assoc("(${this}|$other)");
  Assoc operator ^(Assoc other) => Assoc("(${this}^$other)");
  Assoc operator >(Assoc other) => Assoc("(${this}>$other)");
  Assoc operator >>(Assoc other) => Assoc("(${this}>>$other)");
  Assoc operator >>>(Assoc other) => Assoc("(${this}>>>$other)");
  Assoc operator <(Assoc other) => Assoc("(${this}<$other)");
  Assoc operator >=(Assoc other) => Assoc("(${this}>=$other)");
  Assoc operator <=(Assoc other) => Assoc("(${this}<=$other)");
  String toString() => ops;
}
