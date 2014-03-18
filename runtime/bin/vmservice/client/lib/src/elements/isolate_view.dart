// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('isolate-view')
class IsolateViewElement extends ObservatoryElement {
  @published Isolate isolate;
  IsolateViewElement.created() : super.created();

  Future<ServiceObject> eval(String text) {
    return isolate.get(
        isolate.rootLib.id + "/eval?expr=${Uri.encodeComponent(text)}");
  }

  void refresh(var done) {
    isolate.reload().whenComplete(done);
  }
}
