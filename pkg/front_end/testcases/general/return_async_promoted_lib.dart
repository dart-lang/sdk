// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'return_async_promoted.dart';

int legacy() {
  var f = <T>(o) async => o is int ? o : throw '';
  var g = () async => nullable();
  var h = () async => nonNullable();
  return null;
}
