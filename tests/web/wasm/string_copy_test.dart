// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

main() async {
  final String oneByteString = makeLongString('012345789');
  final String twoByteString = makeLongString('01234中6789');

  Expect.equals(oneByteString, roundTrip(oneByteString));
  Expect.equals(twoByteString, roundTrip(twoByteString));
}

/// Ensure we make a very long string, ensuring that we'll also hit slow paths
/// in the string copy implementation.
String makeLongString(String string) {
  while (string.length < 1024 * 1024) {
    string = string + string;
  }
  return string;
}

/// Copies the string to JS and back again to a dart internal String.
String roundTrip(String dartString) {
  final JSString jsString = dartString.toJS;

  // Using string interpolation will force conversion to internal string (vs
  // `JSStringImpl`)
  final string = 'A${jsString.toDart}Z';
  return string.substring(1, string.length - 1);
}
