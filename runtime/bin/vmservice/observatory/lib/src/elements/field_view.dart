// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_view_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('field-view')
class FieldViewElement extends ObservatoryElement {
  @published Field field;
  FieldViewElement.created() : super.created();

  void refresh(var done) {
    field.reload().whenComplete(done);
  }
}
