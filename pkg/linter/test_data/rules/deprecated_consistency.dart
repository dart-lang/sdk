// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
class A {
  A.ko(); // LINT
  @deprecated
  A.ok(); // OK
}

class B {
  B.ko({this.field = 0}); // LINT
  B.ok({@deprecated this.field = 0}); // OK

  @deprecated
  Object field;
}

class C {
  C({@deprecated this.field = 0}); // OK

  Object field; // LINT
}
