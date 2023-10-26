// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the VM correctly undoes the layers of mixin application to report the
// evaluation scope the frontend as the original mixin.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 23;

class S {}

mixin class M {
  static String? foo;
  bar() {
    foo = "theExpectedValue";
    debugger();
  }
}

// MA=S&M -> S -> Object
class MA = S with M;

testeeMain() {
  MA().bar();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'foo',
      'theExpectedValue',
    );
  },
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_in_mixin_application_alias_frame_test.dart',
      testeeConcurrent: testeeMain,
    );
