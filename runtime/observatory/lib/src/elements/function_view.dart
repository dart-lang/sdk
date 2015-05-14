// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';

import 'package:polymer/polymer.dart';

@CustomTag('function-view')
class FunctionViewElement extends ObservatoryElement {
  @published ServiceFunction function;
  FunctionViewElement.created() : super.created();

  Future refresh() {
    return function.reload();
  }

  Future refreshCoverage() {
    return function.refreshCoverage();
  }
}
