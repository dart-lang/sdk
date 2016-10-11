// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 21793.

import 'package:expect/expect.dart';

/*   /// 01: static type warning, runtime error
class A { call(x) => x; }
*/   /// 01: continued

main() {
  print(new A()(499));
}
