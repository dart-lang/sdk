// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:checks=[],indirectInstance*/
class A {}

/*class: B:checkedInstance*/
class B {}

/*class: C:checks=[$isB],instance*/
class C extends A implements B {}

@noInline
test(o) => o is B;

main() {
  test(new C());
  test(null);
}
