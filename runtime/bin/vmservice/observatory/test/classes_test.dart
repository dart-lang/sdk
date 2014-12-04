// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [

(Isolate isolate) =>
  isolate.get('classes/62').then((Class c) {
    expect(c.name, equals('_List'));
    expect(c.vmCid, equals(62));
}),

];

main(args) => runIsolateTests(args, tests);
