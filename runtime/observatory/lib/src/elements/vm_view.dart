// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('vm-view')
class VMViewElement extends ObservatoryElement {
  @published VM vm;
  @published DartError error;

  VMViewElement.created() : super.created();

  Future refresh() {
    return vm.reload().then((vm) => vm.reloadIsolates());
  }
}
