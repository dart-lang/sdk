// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

// Dart test program for constructors and initializers.

// Check function subtyping for local functions on generic type against generic
// typedefs.

typedef int Foo<T>(T a, [String b]);
typedef int Bar<T>(T a, [String b]);
typedef int Baz<T>(T a, {String b});
typedef int Boz<T>(T a);
typedef int Biz<T>(T a, int b);

/*class: C:direct,explicit=[int* Function(C.T*)*,int* Function(C.T*,[String*])*,int* Function(C.T*,int*)*,int* Function(C.T*,{,b:String*})*],needsArgs*/
class C<T> {
  void test(String nameOfT, bool expectedResult) {
    // TODO(johnniwinther): Optimize local function type signature need.

    /*needsSignature*/
    int foo(bool a, [String b]) => null;

    /*needsSignature*/
    int baz(bool a, {String b}) => null;

    makeLive(expectedResult == foo is Foo<T>);
    makeLive(expectedResult == foo is Bar<T>);
    makeLive(foo is Baz<T>);
    makeLive(expectedResult == foo is Boz<T>);
    makeLive(foo is Biz<T>);

    makeLive(baz is Foo<T>);
    makeLive(baz is Bar<T>);
    makeLive(expectedResult == baz is Baz<T>);
    makeLive(expectedResult == baz is Boz<T>);
    makeLive(baz is Biz<T>);
  }
}

/*class: D:needsArgs*/
class D<S, T> extends C<T> {}

main() {
  new D<String, bool>().test('bool', true);
  new D<bool, int>().test('int', false);
  new D().test('dynamic', true);
}
