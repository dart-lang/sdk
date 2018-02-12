// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: B:checks=[]*/
class B<T> {}

/*class: C:checks=[$asB]*/
class C extends B<String> {}

@noInline
test(o) => o is B<String>;

main() {
  test(new C());
  test(null);
}
