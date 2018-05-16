// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

@JS()
library foo;

// TODO(johnniwinther): Avoid generating duplicate is/as function when multiple
// jsinterop classes implement the same interface.
/*class: global#JavaScriptObject:checks=[$asA,$asB,$asB,$isA,$isB,$isB],instance*/

import 'package:expect/expect.dart';
import 'package:js/js.dart';

/*class: A:checkedInstance,checks=[],instance*/
@JS()
@anonymous
class A<T> {
  external factory A();
}

/*class: B:checkedInstance*/
class B<T> {}

/*class: C:checks=[],instance*/
@JS()
@anonymous
class C implements B<int> {
  external factory C();
}

/*class: D:checkedInstance*/
class D<T> {}

/*class: E:checks=[],instance*/
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
  Expect.isTrue(o is A<int>, "Expected $o to be A<int>");
  Expect.isTrue(o is A<String>, "Expected $o to be A<String>");

  Expect.isTrue(o is B<int>, "Expected $o to be B<int>");
  Expect.isTrue(o is B<String>, "Expected $o to be B<String>");

  Expect.isFalse(o is D<int>, "Expected $o not to be D<int>");
}
