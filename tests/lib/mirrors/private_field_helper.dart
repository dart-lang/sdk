// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.mixin;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Bar {
  String _field = "hello";
  String get field => _field;
}

var privateSymbol2 = #_field;
var publicSymbol2 = #field;
