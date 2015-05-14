// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library eval_link_element;

import 'package:observatory/service.dart';
import 'observatory_element.dart';
import 'package:polymer/polymer.dart';

@CustomTag('eval-link')
class EvalLinkElement extends ObservatoryElement {
  EvalLinkElement.created() : super.created();

  @observable bool busy = false;
  @published String label = "[evaluate]";
  @published var callback = null;
  @published var expr = '';
  @published var result = null;
  @published var error = null;

  void evalNow(var a, var b, var c) {
    if (busy) {
      return;
    }
    if (callback != null) {
      busy = true;
      result = null;
      callback(expr).then((ServiceObject obj) {
        result = obj;
      }).catchError((e, st) {
        error = e.message;
        app.handleException(e, st);
      }).whenComplete(() {
        busy = false;
      });
    }
  }
}
