// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Can call constructors with private names during const evaluation.

// SharedOptions=--enable-experiment=private-named-parameters

import 'package:expect/expect.dart';

class C {
  final String _foo;
  final String _bar;

  const C({required this._foo, required this._bar});
}

main() {
  const c = C(foo: 'foo', bar: 'bar');
  Expect.equals(c._foo, 'foo');
  Expect.equals(c._bar, 'bar');
}
