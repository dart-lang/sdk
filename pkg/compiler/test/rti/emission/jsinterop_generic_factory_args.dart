// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library foo;

/*class: global#LegacyJavaScriptObject:*/

import 'package:compiler/src/util/testing.dart';
import 'package:js/js.dart';

@JS()
@anonymous
/*class: A:checkedInstance,checkedTypeArgument,typeArgument*/
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
  Class1<int>().method();
  Class1<String>().method();
  Class2<int>().method();
  Class2<String>().method();
}

test1(o) {
  makeLive(o is List<A<int>>);
  makeLive(o is List<A<String>>);
}

test2(o) {
  makeLive(o is List<A<int> Function()>);
  makeLive(o is List<A<String> Function()>);
}
