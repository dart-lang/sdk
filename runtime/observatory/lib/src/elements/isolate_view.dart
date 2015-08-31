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
  @published Library rootLibrary;
  IsolateViewElement.created() : super.created();

  Future<ServiceObject> evaluate(String expression) {
    return isolate.rootLibrary.evaluate(expression);
  }

  void attached() {
    super.attached();
    if (isolate.topFrame != null) {
      isolate.topFrame.function.load();
    }
    isolate.rootLibrary.load().then((lib) => rootLibrary = lib);
  }

  Future refresh() async {
    await isolate.reload();
    if (isolate.topFrame != null) {
      await isolate.topFrame.function.load();
    }
  }

  Future refreshCoverage() {
    return isolate.refreshCoverage();
  }
}
