// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that instanceof works correctly with type variables.

part of GenericInstanceofTest.dart;

class Foo<T> {
  Foo() {}

  bool isT(x) {
    // Untyped parameter to ensure that the static type
    // does not affect the result.
    return x is T;
  }

  bool isListT(x) {
    return x is List<T>;
  }
}

class GenericInstanceof {
  static void testMain() {
    // Using Object instead of String to ensure that the static type
    // does not affect the result.
    Foo<Object> fooObject = new Foo<String>();
    Expect.equals(true, fooObject.isT("string"));
    Expect.equals(false, fooObject.isT(1));

    Foo<String> fooString = new Foo<String>();
    Expect.equals(true, fooString.isT("string"));
    Expect.equals(false, fooString.isT(1));

    // Not providing a type argument to ensure that the static type
    // does not affect the result.
    {
      Foo foo = new Foo<String>();
      Expect.equals(true, foo.isT("string"));
      Expect.equals(false, foo.isT(1));
    }
    {
      Foo foo = new Foo();
      Expect.equals(true, foo.isT(new List(5)));
      Expect.equals(true, foo.isT(new List<Object>(5)));
      Expect.equals(true, foo.isT(new List<int>(5)));
      Expect.equals(true, foo.isT(new List<num>(5)));
      Expect.equals(true, foo.isT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<List>();
      Expect.equals(true, foo.isT(new List(5)));
      Expect.equals(true, foo.isT(new List<Object>(5)));
      Expect.equals(true, foo.isT(new List<int>(5)));
      Expect.equals(true, foo.isT(new List<num>(5)));
      Expect.equals(true, foo.isT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<List<Object>>();
      Expect.equals(true, foo.isT(new List(5)));
      Expect.equals(true, foo.isT(new List<Object>(5)));
      Expect.equals(true, foo.isT(new List<int>(5)));
      Expect.equals(true, foo.isT(new List<num>(5)));
      Expect.equals(true, foo.isT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<List<int>>();
      Expect.equals(true, foo.isT(new List(5)));
      Expect.equals(false, foo.isT(new List<Object>(5)));
      Expect.equals(true, foo.isT(new List<int>(5)));
      Expect.equals(false, foo.isT(new List<num>(5)));
      Expect.equals(false, foo.isT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<List<num>>();
      Expect.equals(true, foo.isT(new List(5)));
      Expect.equals(false, foo.isT(new List<Object>(5)));
      Expect.equals(true, foo.isT(new List<int>(5)));
      Expect.equals(true, foo.isT(new List<num>(5)));
      Expect.equals(false, foo.isT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<List<String>>();
      Expect.equals(true, foo.isT(new List(5)));
      Expect.equals(false, foo.isT(new List<Object>(5)));
      Expect.equals(false, foo.isT(new List<int>(5)));
      Expect.equals(false, foo.isT(new List<num>(5)));
      Expect.equals(true, foo.isT(new List<String>(5)));
    }
    {
      Foo foo = new Foo();
      Expect.equals(true, foo.isListT(new List(5)));
      Expect.equals(true, foo.isListT(new List<Object>(5)));
      Expect.equals(true, foo.isListT(new List<int>(5)));
      Expect.equals(true, foo.isListT(new List<num>(5)));
      Expect.equals(true, foo.isListT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<Object>();
      Expect.equals(true, foo.isListT(new List(5)));
      Expect.equals(true, foo.isListT(new List<Object>(5)));
      Expect.equals(true, foo.isListT(new List<int>(5)));
      Expect.equals(true, foo.isListT(new List<num>(5)));
      Expect.equals(true, foo.isListT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<int>();
      Expect.equals(true, foo.isListT(new List(5)));
      Expect.equals(false, foo.isListT(new List<Object>(5)));
      Expect.equals(true, foo.isListT(new List<int>(5)));
      Expect.equals(false, foo.isListT(new List<num>(5)));
      Expect.equals(false, foo.isListT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<num>();
      Expect.equals(true, foo.isListT(new List(5)));
      Expect.equals(false, foo.isListT(new List<Object>(5)));
      Expect.equals(true, foo.isListT(new List<int>(5)));
      Expect.equals(true, foo.isListT(new List<num>(5)));
      Expect.equals(false, foo.isListT(new List<String>(5)));
    }
    {
      Foo foo = new Foo<String>();
      Expect.equals(true, foo.isListT(new List(5)));
      Expect.equals(false, foo.isListT(new List<Object>(5)));
      Expect.equals(false, foo.isListT(new List<int>(5)));
      Expect.equals(false, foo.isListT(new List<num>(5)));
      Expect.equals(true, foo.isListT(new List<String>(5)));
    }
  }
}
