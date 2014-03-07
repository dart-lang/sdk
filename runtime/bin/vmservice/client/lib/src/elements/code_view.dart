// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'isolate_element.dart';
import 'package:polymer/polymer.dart';
import 'package:observatory/app.dart';

@CustomTag('code-view')
class CodeViewElement extends IsolateElement {
  @published Code code;
  CodeViewElement.created() : super.created();

  String get cssPanelClass {
    return 'panel panel-success';
  }
}