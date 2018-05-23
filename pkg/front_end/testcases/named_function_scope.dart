// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=error,warning,context*/

class T {}

class V {}

test() {
  T t;
  V v;
  {
    // This doesn't cause an error as the previous use of T is in an enclosing
    // scope.
    T() {}
  }
  {
    // This doesn't cause an error as the previous use of V is in an enclosing
    // scope.
    var v;
  }
  {
    T t;
    // This doesn't cause a scope error as the named function expression has
    // its own scope.
    var x = /*@error=NamedFunctionExpression*/ T() {};
  }
  {
    /*@context=DuplicatedNamePreviouslyUsedCause*/ V  v;
    // This causes an error, V is already used in this scope.
    var /*@error=DuplicatedNamePreviouslyUsed*/ V;
  }
  {
    /*@context=DuplicatedNamePreviouslyUsedCause*/ V  v;
    // This causes an error, V is already used in this scope.
    var /*@error=DuplicatedNamePreviouslyUsed*/ V = null;
  }
  {
    // This causes a scope error as T is already used in the function-type
    // scope (the return type).
    var x =
        /*@context=DuplicatedNamePreviouslyUsedCause*/
        T
        /*@error=NamedFunctionExpression*/
        /*@error=DuplicatedNamePreviouslyUsed*/
        T() {};
  }
  {
    // This causes a scope error: using the outer definition of `V` as a type
    // when defining `V`.
    /*@context=DuplicatedNamePreviouslyUsedCause*/
    V /*@error=DuplicatedNamePreviouslyUsed*/ V;
  }
  {
    // This causes a scope error as T is already defined as a type variable in
    // the function-type scope.
    var x =
        /*@error=NamedFunctionExpression*/
        /*@error=DuplicatedName*/
        T< /*@context=DuplicatedNameCause*/ T>() {};
  }
  {
    /*@context=DuplicatedNamePreviouslyUsedCause*/
    T t;
    T /*@error=DuplicatedNamePreviouslyUsed*/ T() {}
  }
  {
    /*@context=DuplicatedNamePreviouslyUsedCause*/
    T /*@error=DuplicatedNamePreviouslyUsed*/ T() {}
  }
  {
    /*@context=DuplicatedNamePreviouslyUsedCause*/
    T t;
    T /*@error=DuplicatedNamePreviouslyUsed*/ T(T t) {}
  }
  {
    /*@context=DuplicatedNamePreviouslyUsedCause*/
    T /*@error=DuplicatedNamePreviouslyUsed*/ T(T t) {}
  }
  {
    void T(/*@error=NotAType*/ T t) {}
  }
}

void main() {
}
