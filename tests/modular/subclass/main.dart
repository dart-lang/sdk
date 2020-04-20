// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'f1.dart';
import 'a/a.dart';

class C2 extends B1 {
  final foo = createA0();
}

main() {
  var buffer = new C2().foo.buffer;

  buffer.write('world! $x');
  print(buffer.toString());
}
