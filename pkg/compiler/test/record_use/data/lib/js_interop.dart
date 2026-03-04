// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

// ignore: experimental_member_use
import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(someExternalFunction(6));
}

@JS()
// ignore: experimental_member_use
@RecordUse()
external int someExternalFunction(int k);
