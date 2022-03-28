// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'return_async_promoted_lib.dart';

void main() {
  var f = <T>(o) async => o is int ? o : throw '';
  var g = () async => legacy();
}

int? nullable() => null;
int? nonNullable() => 0;
