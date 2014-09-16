// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 20935.

import 'regress_20935_foo.dart';

baz(x) => x*2;

main() {
  print(baz is Future);
}
