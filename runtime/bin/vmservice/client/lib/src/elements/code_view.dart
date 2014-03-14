// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('code-view')
class CodeViewElement extends ObservatoryElement {
  @published Code code;
  CodeViewElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    if (code == null) {
      return;
    }
    code.load();
  }

  void refresh(var done) {
    code.reload().whenComplete(done);
  }

  String get cssPanelClass {
    return 'panel panel-success';
  }
}