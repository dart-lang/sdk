// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main([args, message]) {
  if (message != null) return isolateMain(message);

  bool isChecked = false;
  assert((isChecked = true));
  if (isChecked) return; // Skip this test in checked mode.

  var responses = {};
  var port = new RawReceivePort();
  port.handler = (pair) {
    responses[pair[0]] = pair[1];
    if (responses.length == 3) {
      port.close();
      Expect.isTrue(responses[true], "true @ $isChecked");
      Expect.isTrue(responses[false], "false @ $isChecked");
      Expect.isTrue(responses[null], "null @ $isChecked");
    }
  };
  test(checked) {
    Isolate.spawnUri(
        Uri.parse("checked_test.dart"), [], [checked, isChecked, port.sendPort],
        checked: checked);
  }

  test(true);
  test(false);
  test(null);
}

void isolateMain(args) {
  var checkedFlag = args[0];
  var parentIsChecked = args[1];
  var responsePort = args[2];
  bool isChecked = false;
  assert((isChecked = true));
  bool expected = checkedFlag;
  if (checkedFlag == null) expected = parentIsChecked;
  responsePort.send([checkedFlag, expected == isChecked]);
}
