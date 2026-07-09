// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that external variable declarations are allowed.
// No implementation at run-time, so it throws.

import 'package:expect/expect.dart';

// External variables cannot be abstract, const, late or have an initializer.

external var top1;
external final top2;
external int top3;
external final bool top4;

/// Class C is not abstract.
class C {
  external static var static1;
  external static final static2;
  external static int static3;
  external static final bool static4;

  external var instance1;
  external final instance2;
  external int instance3;
  external final bool instance4;
  external covariant var instance5;
  external covariant num instance6;
}

class D extends C {
  // Valid override. Inherits covariance.
  external int instance6;
}

void shouldThrow(Function() f) => Expect.throwsNoSuchMethodError(f);

void main() {
  shouldThrow(() => top1);
  shouldThrow(() => top1 = 0);
  shouldThrow(() => top2);
  shouldThrow(() => top3);
  shouldThrow(() => top3 = 0);
  shouldThrow(() => top4);

  shouldThrow(() => C.static1);
  shouldThrow(() => C.static1 = 0);
  shouldThrow(() => C.static2);
  shouldThrow(() => C.static3);
  shouldThrow(() => C.static3 = 0);
  shouldThrow(() => C.static4);

  C c = C();
  shouldThrow(() => c.instance1);
  shouldThrow(() => c.instance1 = 0);
  shouldThrow(() => c.instance2);
  shouldThrow(() => c.instance3);
  shouldThrow(() => c.instance3 = 0);
  shouldThrow(() => c.instance4);
  shouldThrow(() => c.instance5);
  shouldThrow(() => c.instance5 = 0);
  shouldThrow(() => c.instance6);
  shouldThrow(() => c.instance6 = 0);
}
