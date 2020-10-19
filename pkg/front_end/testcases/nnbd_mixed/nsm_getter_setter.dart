// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

import 'nsm_getter_setter_lib.dart';

class B implements A {
  @override
  noSuchMethod(Invocation invocation) => null;
}

main() {}
