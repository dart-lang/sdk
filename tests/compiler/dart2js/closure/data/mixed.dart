// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that free variables aren't mixed between capturing and non-capturing
// closures.

/*mutateInClosure:box=(box0 which holds [localVar])*/
mutateInClosure() {
  var /*boxed*/ localVar;
  /*free=[box0,localVar]*/ () {
    localVar = 42;
  };
  /**/ () {
    // Use nothing.
  };
  return localVar;
}

/*mutateOutsideClosure:box=(box0 which holds [localVar])*/
mutateOutsideClosure() {
  var /*boxed*/ localVar;
  /*free=[box0,localVar]*/ () {
    print(localVar);
  };
  /**/ () {
    // Use nothing.
  };
  localVar = 43;
  return localVar;
}

/*mutateInOtherClosure:box=(box0 which holds [localVar])*/
mutateInOtherClosure() {
  var /*boxed*/ localVar;
  /*free=[box0,localVar]*/ () {
    print(localVar);
  };
  /*free=[box0,localVar]*/ () {
    localVar = 44;
  };
  /**/ () {
    // Use nothing.
  };
  return localVar;
}

/*mutateInNestedClosure:box=(box0 which holds [localVar])*/
mutateInNestedClosure() {
  var /*boxed*/ localVar;
  /*free=[box0,localVar]*/ () {
    print(localVar);
    /*free=[box0,localVar]*/ () {
      localVar = 45;
    };
    /**/ () {
      // Use nothing.
    };
  };
  /**/ () {
    // Use nothing.
  };
  return localVar;
}

main() {
  mutateInClosure();
  mutateOutsideClosure();
  mutateInOtherClosure();
  mutateInNestedClosure();
}
