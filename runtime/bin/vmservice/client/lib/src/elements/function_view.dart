// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_view_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';

import 'package:polymer/polymer.dart';

@CustomTag('function-view')
class FunctionViewElement extends ObservatoryElement {
  @published ServiceFunction function;
  FunctionViewElement.created() : super.created();

  void refresh(var done) {
    function.reload().whenComplete(done);
  }

  void refreshCoverage(var done) {
    function.refreshCoverage().whenComplete(done);
  }
}
