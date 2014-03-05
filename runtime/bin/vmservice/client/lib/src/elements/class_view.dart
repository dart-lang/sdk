// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_view_element;

import 'isolate_element.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('class-view')
class ClassViewElement extends IsolateElement {
  @published Map cls;
  ClassViewElement.created() : super.created();

  void refresh(var done) {
    isolate.getMap(cls['id']).then((map) {
        cls = map;
    }).catchError((e, trace) {
        Logger.root.severe('Error while refreshing class-view: $e\n$trace');
    }).whenComplete(done);
  }
}