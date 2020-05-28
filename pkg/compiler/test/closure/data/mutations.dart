// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that captured variables are boxed regardless of where they are mutated.

/*member: mutateUnused:*/
mutateUnused() {
  var localVar;
  /**/ () {
    // Use nothing.
  };
  localVar = 42;
  return localVar;
}

/*member: mutateInClosure:box=(box0 which holds [localVar])*/
mutateInClosure() {
  var /*boxed*/ localVar;
  /*fields=[box0],free=[box0,localVar]*/ () {
    localVar = 43;
  };
  return localVar;
}

/*member: mutateOutsideClosure:box=(box0 which holds [localVar])*/
mutateOutsideClosure() {
  var /*boxed*/ localVar;
  /*fields=[box0],free=[box0,localVar]*/ () {
    print(localVar);
  };
  localVar = 44;
  return localVar;
}

/*member: mutateInOtherClosure:box=(box0 which holds [localVar])*/
mutateInOtherClosure() {
  var /*boxed*/ localVar;
  /*fields=[box0],free=[box0,localVar]*/ () {
    print(localVar);
  };
  /*fields=[box0],free=[box0,localVar]*/ () {
    localVar = 45;
  };
  return localVar;
}

/*member: mutateInNestedClosure:box=(box0 which holds [localVar])*/
mutateInNestedClosure() {
  var /*boxed*/ localVar;
  /*fields=[box0],free=[box0,localVar]*/ () {
    print(localVar);
    /*fields=[box0],free=[box0,localVar]*/ () {
      localVar = 46;
    };
  };
  return localVar;
}

main() {
  mutateUnused();
  mutateInClosure();
  mutateOutsideClosure();
  mutateInOtherClosure();
  mutateInNestedClosure();
}
