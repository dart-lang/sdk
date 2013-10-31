// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_view_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('code-view')
class CodeViewElement extends ObservatoryElement {
  @published Map code = toObservable({});
  CodeViewElement.created() : super.created();

  String get cssPanelClass {
    if (code != null && code['is_optimized'] != null) {
      return 'panel panel-success';
    }
    return 'panel panel-warning';
  }
}