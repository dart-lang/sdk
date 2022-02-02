// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

@JS()
library foo;

// TODO(johnniwinther): Avoid generating duplicate is/as function when multiple
// jsinterop classes implement the same interface.
/*class: global#LegacyJavaScriptObject:checks=[$isA,$isB,$isB],instance*/

import 'package:compiler/src/util/testing.dart';
import 'package:js/js.dart';

/*class: A:checkedInstance,checks=[],instance,onlyForRti*/
@JS()
@anonymous
class A<T> {
  external factory A();
}

/*class: B:checkedInstance*/
class B<T> {}

/*class: C:checks=[],instance,onlyForRti*/
@JS()
@anonymous
class C implements B<int> {
  external factory C();
}

/*class: D:*/
class D<T> {}

/*class: E:checks=[],instance,onlyForRti*/
@JS()
@anonymous
class E implements B<String> {
  external factory E();
}

main() {
  test(new A<int>());
  test(new A<String>());
  test(new C());
  test(new E());
}

test(o) {
  makeLive(o is A<int>);
  makeLive(o is A<String>);

  makeLive(o is B<int>);
  makeLive(o is B<String>);

  makeLive(o is D<int>);
}
