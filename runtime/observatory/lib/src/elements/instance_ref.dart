// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_ref_element;

import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('instance-ref')
class InstanceRefElement extends ServiceRefElement {
  InstanceRefElement.created() : super.created();

  String get hoverText {
    if (ref != null) {
      if (ref.type == 'Sentinel') {
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

  void expandEvent(bool expand, Function onDone) {
    assert(ref is Instance);
    if (expand) {
      ref.reload().then((result) {
        if (result.valueAsString != null) {
          result.name = result.valueAsString;
          result.vmName = result.valueAsString;
        }
        ref = result;
        notifyPropertyChange(#ref, 0, 1);
      }).whenComplete(onDone);
    } else {
      Instance refMap = ref;
      refMap.fields = null;
      refMap.elements = null;
      onDone();
    }
  }

  String makeExpandKey(String key) {
    return '${expandKey}/${key}';
  }

  Future showMore() async {
    Instance instance = ref;
    if (instance.isList) {
      await instance.reload(count: instance.elements.length * 2);
    } else if (instance.isMap) {
      await instance.reload(count: instance.associations.length * 2);
    } else if (instance.isTypedData) {
      await instance.reload(count: instance.typedElements.length * 2);
    }
  }
}
