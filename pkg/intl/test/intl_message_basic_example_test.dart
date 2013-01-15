// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests internationalization of messages using the basic example as a template.
 */
library intl_message_test_2;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl//message_lookup_local.dart';
import '../example/basic/basic_example.dart';
import 'package:unittest/unittest.dart';
import 'dart:async';

List list;

main() {
  list = [];
  setup(runAllTests, addToList);
}

var waitForIt = new Completer();

addToList(x) {
  list.add(x);
  if (list.length == 4) waitForIt.complete(list);
}

runAllTests(_) {
  setup(runProgram, addToList);
  waitForIt.future.then(actuallyRunTheTests);
}

actuallyRunTheTests(_) {
  test('Verify basic example printing localized messages', () {
    expect(list[0], "Ran at 00:00:00 on Thursday, January 1, 1970");
    expect(list[1], "Ausgedruckt am 00:00:00 am Donnerstag, 1. Januar 1970.");
    expect(list[2], "วิ่ง 0:00:00 on วันพฤหัสบดี 1 มกราคม 1970.");
    expect(list[3], "วิ่ง now on today.");
  });
}
