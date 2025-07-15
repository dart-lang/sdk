// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'private.dart';

class A {
  A._();
}

class B {
  factory B._() = _B;
}

class _B implements B {}

class C {
  C.named();
  C._();
}

class G extends D {
  G._() : super._(); // TODO(johnniwinther): This should be an error.
}

class H extends E {
  H._() : super._(); // Error
}

class I extends F {
  I.named() : super.named(); // Ok
  I._() : super._(); // TODO(johnniwinther): This should be an error.
}

method() {
  D._(); // Error
  D._; // Error
  E._(); // Error
  E._; // Error
  F._(); // Error
  F._; // Error
}
