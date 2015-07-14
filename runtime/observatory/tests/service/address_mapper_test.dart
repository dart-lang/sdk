// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override

import 'package:observatory/object_graph.dart';
import 'package:expect/expect.dart';

main() {
  var map = new AddressMapper(42);

  Expect.equals(null, map.get(1, 2, 3));
  Expect.equals(4, map.put(1, 2, 3, 4));
  Expect.equals(4, map.get(1, 2, 3));

  Expect.equals(null, map.get(2, 3, 1));
  Expect.equals(null, map.get(3, 1, 2));

  Expect.throws(() => map.put(1, 2, 3, 44),
                (e) => true,
                "Overwrite key");

  Expect.throws(() => map.put(5, 6, 7, 0),
                (e) => true,
                "Invalid value");

  Expect.throws(() => map.put("5", 6, 7, 0),
                (e) => true,
                "Invalid key");
}
