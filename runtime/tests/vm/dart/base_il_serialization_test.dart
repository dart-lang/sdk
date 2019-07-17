// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--serialize_flow_graphs_to=il_tmp.txt

// Just use the existing hello world test.
import 'hello_world_test.dart' as test;

main(args) {
  test.main();
}
