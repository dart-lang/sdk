// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('instance-view')
class InstanceViewElement extends ObservatoryElement {
  @published Instance instance;

  InstanceViewElement.created() : super.created();

  Future<ServiceObject> evaluate(String expression) {
    return instance.evaluate(expression);
  }

  Future setBreakOnActivation() {
    return instance.isolate.addBreakOnActivation(instance)
        .then((_) => refresh());
  }

  Future clearBreakOnActivation() {
    return instance.isolate.removeBreakpoint(instance.activationBreakpoint)
        .then((_) => refresh());
  }

  Future refresh() {
    return instance.reload();
  }
}
