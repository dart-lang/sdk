// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_view_element;

import 'isolate_element.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('field-view')
class FieldViewElement extends IsolateElement {
  @published Map field;
  FieldViewElement.created() : super.created();

  void refresh(var done) {
    isolate.getMap(field['id']).then((map) {
        field = map;
    }).catchError((e, trace) {
        Logger.root.severe('Error while refreshing field-view: $e\n$trace');
    }).whenComplete(done);
  }
}