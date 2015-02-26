// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_ref_element;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('function-ref')
class FunctionRefElement extends ServiceRefElement {
  @published bool qualified = true;

  FunctionRefElement.created() : super.created();

  refChanged(oldValue) {
    super.refChanged(oldValue);
    _updateShadowDom();
  }

  ServiceFunction get function => ref;
  void _updateShadowDom() {
    clearShadowRoot();
    if (ref == null) {
      return;
    }
    if (function.isDart) {
      if (qualified) {
        // Add class-name or parent-function-name followed by a dot.
        if ((function.parent == null) && (function.owningClass != null)) {
          var classRef = new Element.tag('class-ref');
          classRef.ref = function.owningClass;
          shadowRoot.children.add(classRef);
          insertTextSpanIntoShadowRoot('.');
        } else if (function.parent != null) {
          var functionRef = new Element.tag('function-ref');
          functionRef.ref = function.parent;
          functionRef.qualified = true;
          shadowRoot.children.add(functionRef);
          insertTextSpanIntoShadowRoot('.');
        }
      }
      insertLinkIntoShadowRoot(name, url, hoverText);
    } else {
      insertTextSpanIntoShadowRoot(name);
    }
  }
}