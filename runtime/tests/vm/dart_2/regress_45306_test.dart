// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for https://github.com/dart-lang/sdk/issues/45306.
// Verifies that ScopeBuilder doesn't crash on an async closure inside
// instance field initializer.

class X {
  final Y y = Y(
    () async {},
  );

  final double a;
  final double b;
  final String c;

  X({
    this.a,
    this.b,
    this.c,
  });
}

typedef Callback = Future<void> Function();

class Y {
  Y(Callback f);
}

void main() {
  X();
}
