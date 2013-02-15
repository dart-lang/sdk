// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library microtask_;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:async';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('setImmediate', () {
    var timeoutCalled = false;
    var rafCalled = false;
    var immediateCalled = false;

    Timer.run(expectAsync0(() {
      timeoutCalled = true;
      expect(immediateCalled, true);
    }));


    window.requestAnimationFrame((_) {
      rafCalled = true;
    });

    window.setImmediate(expectAsync0(() {
      expect(timeoutCalled, false);
      expect(rafCalled, false);
      immediateCalled = true;
    }));
    expect(immediateCalled, false);
  });
}
