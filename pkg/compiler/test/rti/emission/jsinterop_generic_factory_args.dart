// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library foo;

/*class: global#JavaScriptObject:*/

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
@anonymous
/*spec.class: A:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A:checkedTypeArgument,typeArgument*/
class A<T> {
  external factory A();
}

/*class: Class1:checks=[],instance*/
class Class1<T> {
  method() {
    // This caused and assertion failure in codegen.
    test1(new List<A<T>>.from([]));
  }
}

/*class: Class2:checks=[],instance*/
class Class2<T> {
  method() {
    // This caused and assertion failure in codegen.
    test2(new List<A<T> Function()>.from([]));
  }
}

main() {
  new Class1<int>().method();
  new Class1<String>().method();
  new Class2<int>().method();
  new Class2<String>().method();
}

test1(o) {
  Expect.isTrue(o is List<A<int>>, "Expected $o to be List<A<int>>");
  Expect.isTrue(o is List<A<String>>, "Expected $o to be List<A<String>>");
}

test2(o) {
  Expect.isTrue(o is List<A<int> Function()>,
      "Expected $o to be List<A<int> Function()>");
  Expect.isTrue(o is List<A<String> Function()>,
      "Expected $o to be List<A<String> Function()>");
}
