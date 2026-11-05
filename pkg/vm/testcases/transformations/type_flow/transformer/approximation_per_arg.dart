// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies per-argument approximation in TFA call-site caching:
//
// When a selector is invoked many times with some arguments varying and other
// arguments non-varying (e.g. always same constant), the varying arguments get
// approximated while the invariant arguments retain exact type.

class Token1 {}

class Token2 {}

class Token3 {}

abstract class Base {
  void method(Object token, Symbol invariantSymbol, [int? optionalArg]);
}

class Sub1 extends Base {
  @override
  void method(Object token, Symbol invariantSymbol, [int? optionalArg]) {
    print(token);
    print(invariantSymbol);
    print(optionalArg);
  }
}

class Sub2 extends Base {
  @override
  void method(
    Object token,
    Symbol invariantSymbol, [
    int? optionalArg,
    String? extraSubclassArg,
  ]) {
    print(token);
    print(invariantSymbol);
    print(optionalArg);
  }
}

void callMethod(Base b, Object token, [int? opt]) {
  if (opt != null) {
    b.method(token, #invariant, opt);
  } else {
    b.method(token, #invariant);
  }
}

void main() {
  final sub1 = Sub1();
  final sub2 = Sub2();

  // Call with different token types to trigger selector approximation
  // (maxInterfaceInvocationsPerSelector is set to 2 in .options).
  callMethod(sub1, Token1());
  callMethod(sub2, Token2(), 42);
  callMethod(sub1, Token3());
}
