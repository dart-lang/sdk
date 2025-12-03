// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Private named parameters can be used with declaring private constructor
/// parameters.

// SharedOptions=--enable-experiment=private-named-parameters,primary-constructors

import 'package:expect/expect.dart';

class C({required final String _foo, required final String _bar});

void main() {
  var c = C(foo: 'foo', bar: 'bar');
  Expect.equals(c._foo, 'foo');
  Expect.equals(c._bar, 'bar');
}
