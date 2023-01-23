// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library export;

import 'package:js/js.dart';

import 'mock.dart';

@JSExport()
class DartClass {
  String field = '';
  final String finalField = '';
  String get getSet => '';
  set getSet(String val) {}
  @JSExport('method')
  String renamedMethod() => '';
}

extension on StaticInterop {
  // Different implementation for same field.
  external bool field;
}
