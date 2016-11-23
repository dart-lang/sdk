// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.round_trip_test;

import 'package:test/test.dart';
import 'round_trip.dart' as cmd;

void main() {
  test('dart2js', () {
    cmd.main(['test/data/dart2js.dill']);
  });
  test('dart2js-strong', () {
    cmd.main(['test/data/dart2js-strong.dill']);
  });
  test('boms', () {
    cmd.main(['test/data/boms.dill']);
  });
}
