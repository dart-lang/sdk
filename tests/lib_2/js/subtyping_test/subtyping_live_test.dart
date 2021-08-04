// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

// Tests subtyping relationships after making package:js types live.

@JS()
library subtyping_live_test;

import 'package:js/js.dart';
import 'subtyping_test_util.dart';

@JS()
external dynamic get externalGetter;

void main() {
  // Call to foreign function should trigger dart2js to assume types are live.
  externalGetter;
  testSubtyping();
}
