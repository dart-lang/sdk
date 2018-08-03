// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:async_helper/async_helper.dart';

main() async {
  useHtmlConfiguration();

  test('Notification.requestPermission', () async {
    String permission = await Notification.requestPermission();
    expect(permission, isNotNull);
  });
}
