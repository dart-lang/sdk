// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'nsm_forwarder_optional_param_regress_63904_helper.dart';

final alwaysTrue = int.parse('1') == 1;

void main() {
  final i = Implementation1();
  expectNamedArgument(i.foo(), null);
  expectNamedArgument(i.foo(arg: true), true);
  expectNamedArgument(i.foo(arg: false), false);
  expectPositionalArgument(i.bar(), null);
  expectPositionalArgument(i.bar(true), true);
  expectPositionalArgument(i.bar(false), false);

  final iunknown = alwaysTrue ? i : Implementation2();
  expectNamedArgument(iunknown.foo(), null);
  expectNamedArgument(iunknown.foo(arg: true), true);
  expectNamedArgument(iunknown.foo(arg: false), false);
  expectPositionalArgument(iunknown.bar(), null);
  expectPositionalArgument(iunknown.bar(true), true);
  expectPositionalArgument(iunknown.bar(false), false);

  final dynamic idynamic = alwaysTrue ? i : Object();
  expectNamedArgument(idynamic.foo(), null);
  expectNamedArgument(idynamic.foo(arg: true), true);
  expectNamedArgument(idynamic.foo(arg: false), false);
  expectPositionalArgument(idynamic.bar(), null);
  expectPositionalArgument(idynamic.bar(true), true);
  expectPositionalArgument(idynamic.bar(false), false);
}

void expectNamedArgument(Invocation invocation, dynamic expectedValue) {
  // Either the caller passed the optional argument or the CFE-inserted
  // no-such-method forwarder will populate with with null.
  Expect.isTrue(invocation.namedArguments.containsKey(#arg));
  Expect.equals(expectedValue, invocation.namedArguments[#arg]);
}

void expectPositionalArgument(Invocation invocation, dynamic expectedValue) {
  // Either the caller passed the optional argument or the CFE-inserted
  // no-such-method forwarder will populate with with null.
  Expect.isTrue(invocation.positionalArguments.length == 1);
  Expect.equals(expectedValue, invocation.positionalArguments[0]);
}

class Implementation1 implements Interface {
  @override
  Invocation noSuchMethod(Invocation invocation) {
    return invocation;
  }
}

class Implementation2 implements Interface {
  @override
  Invocation noSuchMethod(Invocation invocation) {
    return invocation;
  }
}
