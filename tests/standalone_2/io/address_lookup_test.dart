// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies that one can provide timeout handler for InternetAddress.lookup,
// which was reported broken https://github.com/dart-lang/sdk/issues/45542.

// @dart = 2.9

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void main() async {
  asyncStart();
  final result = <InternetAddress>[];
  try {
    result.addAll(await InternetAddress.lookup("some.bad.host.name.7654321")
        .timeout(const Duration(milliseconds: 1), onTimeout: () => []));
  } catch (e) {
    print('managed to fail with $e lookup before timeout');
  }
  Expect.isTrue(result.isEmpty);
  asyncEnd();
}
