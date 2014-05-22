// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library eval_link_element;

import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('eval-link')
class EvalLinkElement extends PolymerElement {
  EvalLinkElement.created() : super.created();

  @observable bool busy = false;
  @published String label = "[evaluate]";
  @published var callback = null;
  @published var expr = '';
  @published ServiceObject result = null;

  void evalNow(var a, var b, var c) {
    if (busy) {
      return;
    }
    if (callback != null) {
      busy = true;
      result = null;
      callback(expr).then((ServiceObject obj) {
          result = obj;
        }).whenComplete(() {
          busy = false;
        });
    }
  }
}
