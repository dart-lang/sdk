// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_ref_as_value_element;

import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';
import 'service_ref.dart';
import 'dart:async';

@CustomTag('class-ref-as-value')
class ClassRefAsValueElement extends ServiceRefElement {

  ClassRefAsValueElement.created() : super.created();

  String makeExpandKey(String key) {
    return '${expandKey}/${key}';
  }

  dynamic expander() {
    return expandEvent;
  }

  void expandEvent(bool expand, Function onDone) {
    if (expand) {
      Class cls = ref;
      cls.reload().then((result) {
        return Future.wait(cls.fields.map((field) => field.reload()));
      }).whenComplete(onDone);
    } else {
      onDone();
    }
  }
}
