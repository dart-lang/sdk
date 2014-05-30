// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.test.utils;

import 'package:string_scanner/string_scanner.dart';
import 'package:unittest/unittest.dart';

/// Returns a matcher that asserts that a closure throws a [FormatException]
/// with the given [message].
Matcher throwsStringScannerException(String text) {
  return throwsA(predicate((error) {
    expect(error, new isInstanceOf<StringScannerException>());
    expect(error.span.text, equals(text));
    return true;
  }));
}
