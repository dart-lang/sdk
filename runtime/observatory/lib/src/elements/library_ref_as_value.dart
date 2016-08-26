// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_ref_as_value_element;

import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';
import 'service_ref.dart';
import 'dart:async';

@CustomTag('library-ref-as-value')
class LibraryRefAsValueElement extends ServiceRefElement {
  LibraryRefAsValueElement.created() : super.created();

  String makeExpandKey(String key) {
    return '${expandKey}/${key}';
  }

  dynamic expander() {
    return expandEvent;
  }

  void expandEvent(bool expand, Function onDone) {
    if (expand) {
      Library lib = ref;
      lib.reload().then((result) {
        return Future.wait(lib.variables.map((field) => field.reload()));
      }).whenComplete(onDone);
    } else {
      onDone();
    }
  }
}
