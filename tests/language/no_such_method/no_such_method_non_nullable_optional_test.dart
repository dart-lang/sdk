// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  final i = Implementation();
  expectNamedArg(i.foo(), null);
  expectNamedArg(i.foo(arg: true), true);
  expectNamedArg(i.foo(arg: false), false);
  expectPositionalArg(i.bar(), null);
  expectPositionalArg(i.bar(true), true);
  expectPositionalArg(i.bar(false), false);

  final ifoo = i.foo;
  Expect.type<void Function({bool? arg})>(ifoo);
  final ibar = i.bar;
  Expect.type<void Function([bool? arg])>(ibar);
}

void expectNamedArg(Invocation invocation, bool? expectedValue) {
  // Either the caller passed it or the CFE-inserted no-such-method forwarder
  // will populate it with `null`.
  Expect.isTrue(invocation.namedArguments.containsKey(#arg));
  Expect.equals(expectedValue, invocation.namedArguments[#arg]);
}

void expectPositionalArg(Invocation invocation, bool? expectedValue) {
  // Either the caller passed it or the CFE-inserted no-such-method forwarder
  // will populate it with `null`.
  Expect.isTrue(invocation.positionalArguments.length == 1);
  Expect.equals(expectedValue, invocation.positionalArguments[0]);
}

abstract class Interface {
  Invocation bar([bool arg]);
  Invocation foo({bool arg});
}

class Implementation implements Interface {
  @override
  Invocation noSuchMethod(Invocation invocation) {
    return invocation;
  }
}
