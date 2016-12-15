// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.round_trip_test;

import 'self_check_util.dart';
import 'round_trip.dart' as cmd;

void main(List<String> args) {
  runSelfCheck(args, (String filename) {
    cmd.main([filename]);
  });
}
