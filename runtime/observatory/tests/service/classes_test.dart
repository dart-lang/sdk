// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override --checked

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [

(Isolate isolate) =>
  isolate.getClassHierarchy().then((Class o) {
    expect(o.name, equals('Object'));
}),

(Isolate isolate) =>
  isolate.getObject('classes/62').then((Class c) {
    expect(c.name, equals('_ImmutableList'));
    expect(c.vmCid, equals(62));
}),


];

main(args) => runIsolateTests(args, tests);
