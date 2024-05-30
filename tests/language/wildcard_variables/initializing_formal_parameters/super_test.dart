// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `super._` will pass on the given actual argument to the corresponding
// superconstructor parameter.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

void main() {
  var c = C(1);
  Expect.equals(1, c._);

  var cWithPositional = C.withPositional(1, 100);
  Expect.equals(1, cWithPositional._);

  var multipleSuperParameters = MultipleSuperParameters(1, 2, 3);
  Expect.equals(1, multipleSuperParameters._);
  Expect.equals(2, multipleSuperParameters.x);
  Expect.equals(3, multipleSuperParameters.y);
}

class B<_> {
  var _;

  B(this._);
  B.withPositional(this._, _);
}

class C<_> extends B {
  C(super._);
  C.superAndPositional(super._, _);
}

class MultipleParameters {
  final int x, y;
  MultipleParameters(this.x, this.y);
}

class MultipleSuperParameters extends MultipleParameters {
  final int _;
  MultipleSuperParameters(this._, super._, super._);
}
