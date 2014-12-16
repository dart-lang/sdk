// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test [source_update.dart].
library trydart.source_update_test;

import 'package:expect/expect.dart' show
    Expect;

import 'source_update.dart' show
    expandUpdates;

main() {
  Expect.listEquals(
      ["head v1 tail", "head v2 tail"],
      expandUpdates(["head ", ["v1", "v2"], " tail"]));

  Expect.listEquals(
      ["head v1 tail v2", "head v2 tail v1"],
      expandUpdates(["head ", ["v1", "v2"], " tail ", ["v2", "v1"]]));

  Expect.throws(() {
    expandUpdates(["head ", ["v1", "v2"], " tail ", ["v1"]]);
  });

  Expect.throws(() {
    expandUpdates(["head ", ["v1", "v2"], " tail ", ["v1", "v2", "v3"]]);
  });
}
