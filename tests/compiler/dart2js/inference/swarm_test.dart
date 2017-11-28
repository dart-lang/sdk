// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'inference_equivalence.dart';

main(List<String> args) {
  asyncTest(() async {
    Expect.isTrue(
        await mainInternal(['samples-dev/swarm/swarm.dart']..addAll(args)));
  });
}
