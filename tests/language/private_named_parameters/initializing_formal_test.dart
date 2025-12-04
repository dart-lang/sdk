// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Private named parameters can be used on initializing formals.

// SharedOptions=--enable-experiment=private-named-parameters

import 'package:expect/expect.dart';

class C {
  String _foo;
  String _bar;

  C({required this._foo, required this._bar});
}

class Both {
  String? _foo;
  String? foo;

  Both({this._foo});
}

void main() {
  var c = C(foo: 'foo', bar: 'bar');
  Expect.equals(c._foo, 'foo');
  Expect.equals(c._bar, 'bar');

  // If a class has both public and private instance variables, the initializing
  // formal always refers to the private one.
  var b = Both(foo: 'foo');
  Expect.equals(b._foo, 'foo');
  Expect.equals(b.foo, null);
}
