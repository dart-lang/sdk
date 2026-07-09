// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Program used by regress_flutter169921_test.dart.

import 'regress_flutter169921_deferred.dart' deferred as d;

void main() async {
  d.loadLibrary();
  print(d.foo(0));
  print(d.foo(1));
}
