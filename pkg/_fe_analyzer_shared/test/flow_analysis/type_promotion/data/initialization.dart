// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file exercise "promotable via initialization" part of
// the flow analysis specification.

localVariable() {
  var x;
  x = 1;
  /*int*/ x;
  x = 2.3;
  x;
}

localVariable_hasInitializer(num a) {
  var x = a;
  x = 1;
  x;
}

localVariable_hasTypeAnnotation() {
  num x;
  x = 1;
  x;
}

localVariable_hasTypeAnnotation_dynamic() {
  dynamic x;
  x = 1;
  x;
}

localVariable_ifElse_differentTypes(bool a) {
  var x;
  if (a) {
    x = 0;
    /*int*/ x;
  } else {
    x = 1.2;
    /*double*/ x;
  }
  x;
}

localVariable_ifElse_sameTypes(bool a) {
  var x;
  if (a) {
    x = 0;
    /*int*/ x;
  } else {
    x = 1;
    /*int*/ x;
  }
  /*int*/ x;
}

localVariable_notDefinitelyUnassigned(bool a) {
  var x;
  if (a) {
    x = 1.2;
  }
  x = 1;
  x;
}

localVariable_notDefinitelyUnassigned_hasLocalFunction() {
  var x;

  void f() {
    // Note, no assignment to 'x', but because 'x' is assigned somewhere in
    // the enclosing function, it is not definitely unassigned in 'f'.
    // So, when we join after 'f' declaration, we make 'x' not definitely
    // unassigned in the enclosing function as well.
  }

  f();

  x = 1;
  x;
}

parameter(x) {
  x = 1;
  x;
}

parameterLocal() {
  void f(x) {
    x = 1;
    x;
  }

  f(0);
}
