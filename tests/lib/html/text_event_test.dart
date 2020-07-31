// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

import 'event_test.dart';

main() {
  eventTest('TextEvent', () => new TextEvent('foo', view: window, data: 'data'),
      (ev) {
    expect(ev.data, 'data');
  });
}
