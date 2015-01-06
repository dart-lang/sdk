// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library eval_box_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:polymer/polymer.dart';


typedef Future evalType(String text);


@CustomTag('eval-box')
class EvalBoxElement extends ObservatoryElement {
  @observable String text;
  @observable String lineMode = "1-line";

  @published evalType callback;
  @observable ObservableList results = toObservable([]);

  void updateLineMode(Event e, var detail, Node target) {
    lineMode = (e.target as InputElement).value;
    if (lineMode == '1-line') {
      text = text.replaceAll('\n', ' ');
    }
  }

  void eval(Event e, var detail, Node target) {
    // Prevent any form action.
    e.preventDefault();

    // Clear the text box.
    var expr = text;
    text = '';

    // Use provided callback to eval the expression.
    if (callback != null) {
      var map = toObservable({});
      map['expr'] = expr;
      results.insert(0, map);
      callback(expr).then((result) {
          map['value'] = result;
      });
    }
  }

  void selectExpr(MouseEvent e) {
    assert(e.target is Element);
    Element targetElement = e.target;
    text = targetElement.getAttribute('expr');
  }

  EvalBoxElement.created() : super.created();
}
