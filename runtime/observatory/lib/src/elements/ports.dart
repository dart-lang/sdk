// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ports;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('ports-page')
class PortsPageElement extends ObservatoryElement {
  PortsPageElement.created() : super.created();

  @observable Isolate isolate;
  @observable var /*ObservableList | ServiceObject*/ ports;

  void isolateChanged(oldValue) {
    if (isolate != null) {
      isolate.getPorts().then(_refreshView);
    }
  }

  Future refresh() {
    return isolate.getPorts().then(_refreshView);
  }

  _refreshView(/*ObservableList | ServiceObject*/ object) {
    ports = object['ports'];
  }
}
