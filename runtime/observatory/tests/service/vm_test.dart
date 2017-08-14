// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [
  (Isolate isolate) {
    VM vm = isolate.owner;
    expect(vm.targetCPU, isNotNull);
    expect(vm.architectureBits == 32 || vm.architectureBits == 64, isTrue);
  },
];

main(args) => runIsolateTests(args, tests);
