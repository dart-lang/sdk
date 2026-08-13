// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'redirecting_factory_vs_field_inference2_lib.dart';

class Element {}

class Class {
  var field = Util<Element>(0);
}

class SubClass extends Class {
  Util<Element> get field => super.field;

  set field(Util<Element> value) {
    super.field = value;
  }
}
