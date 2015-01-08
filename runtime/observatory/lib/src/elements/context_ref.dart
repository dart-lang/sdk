// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context_ref_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('context-ref')
class ContextRefElement extends ServiceRefElement {
  ContextRefElement.created() : super.created();

  // TODO(turnidge): This is here to workaround vm/dart2js differences.
  dynamic expander() {
    return expandEvent;
  }

  void expandEvent(bool expand, Function onDone) {
    assert(ref is Context);
    if (expand) {
      ref.reload().then((result) {
        ref = result;
        notifyPropertyChange(#ref, 0, 1);
      }).whenComplete(onDone);
    } else {
      Context refMap = ref;
      refMap.variables = null;
      onDone();
    }
  }
}
