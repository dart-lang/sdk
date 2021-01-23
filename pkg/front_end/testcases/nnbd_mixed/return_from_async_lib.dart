// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'return_from_async.dart';

class Subclass implements Class {
  FutureOr<int> throwFutureOrInt() async {
    throw 'FutureOr<int>';
  }

  int throwInt() {
    throw 'int';
  }

  Future<int> throwFutureInt() async {
    throw 'Future<int>';
  }

  dynamic throwDynamic() {
    throw 'dynamic';
  }

  Future<num> throwFutureNum() async {
    throw 'Future<num>';
  }
}
