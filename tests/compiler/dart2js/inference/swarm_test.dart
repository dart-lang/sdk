// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../equivalence/id_equivalence.dart';
import 'inference_equivalence.dart';

main(List<String> args) {
  asyncTest(() async {
    Expect.isTrue(
        await mainInternal(['samples-dev/swarm/swarm.dart']..addAll(args),
            whiteList: (Uri uri, Id id) {
      if (uri.pathSegments.last == 'date_time.dart' &&
          '$id' == 'IdKind.node:15944') {
        // DateTime.== uses `if (!(other is DateTime))` for which kernel is
        // smarter.
        return true;
      }
      return false;
    }));
  });
}
