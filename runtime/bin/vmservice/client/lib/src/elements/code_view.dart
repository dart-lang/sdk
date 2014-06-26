// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('code-view')
class CodeViewElement extends ObservatoryElement {
  @published Code code;
  CodeViewElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    if (code == null) {
      return;
    }
    code.load().then((Code c) {
      c.loadScript();
    });
  }

  void refresh(var done) {
    code.reload().whenComplete(done);
  }

  Element _findJumpTarget(Element target) {
    var jumpTarget = target.attributes['data-jump-target'];
    if (jumpTarget == '') {
      return null;
    }
    var address = int.parse(jumpTarget);
    var node = shadowRoot.querySelector('#addr-$address');
    if (node == null) {
      return null;
    }
    return node;
  }

  void mouseOver(Event e, var detail, Node target) {
    var jt = _findJumpTarget(target);
    if (jt == null) {
      return;
    }
    jt.classes.add('highlight');
  }

  void mouseOut(Event e, var detail, Node target) {
    var jt = _findJumpTarget(target);
    if (jt == null) {
      return;
    }
    jt.classes.remove('highlight');
  }
}
