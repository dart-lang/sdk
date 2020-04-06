// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library HistoryTest;

import 'package:async_helper/async_minitest.dart';
import 'dart:html';
import 'dart:async';

main() {
  test('supports_state', () {
    expect(History.supportsState, true);
  });

  test('supported_HashChangeEvent', () {
    expect(HashChangeEvent.supported, true);
  });
}
