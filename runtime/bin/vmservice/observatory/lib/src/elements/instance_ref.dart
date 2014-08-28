// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_ref_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('instance-ref')
class InstanceRefElement extends ServiceRefElement {
  InstanceRefElement.created() : super.created();

  String get hoverText {
    if (ref != null) {
      if (ref.serviceType == 'Null') {
        if (ref.id == 'objects/optimized-out') {
          return 'This object is no longer needed and has been removed by the optimizing compiler.';
        } else if (ref.id == 'objects/collected') {
          return 'This object has been reclaimed by the garbage collector.';
        } else if (ref.id == 'objects/expired') {
          return 'The handle to this object has expired.  Consider refreshing the page.';
        } else if (ref.id == 'objects/not-initialized') {
          return 'This object will be initialized once it is accessed by the program.';
        } else if (ref.id == 'objects/being-initialized') {
          return 'This object is currently being initialized.';
        }
      }
    }
    return super.hoverText;
  }

  // TODO(turnidge): This is here to workaround vm/dart2js differences.
  dynamic expander() {
    return expandEvent;
  }

  void expandEvent(bool expand, var done) {
    assert(ref is Instance);
    if (expand) {
      ref.reload().then((result) {
        if (result.valueAsString != null) {
          result.name = result.valueAsString;
          result.vmName = result.valueAsString;
        }
        ref = result;
        notifyPropertyChange(#ref, 0, 1);
      }).whenComplete(done);
    } else {
      Instance refMap = ref;
      refMap.fields = null;
      refMap.elements = null;
      done();
    }
  }
}
