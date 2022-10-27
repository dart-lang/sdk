// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock;

import 'package:js/js.dart';

@JS()
@staticInterop
class StaticInterop {}

extension on StaticInterop {
  external String field;
  external final String finalField;
  external String get getSet;
  external set getSet(String val);
  external String method();
}
