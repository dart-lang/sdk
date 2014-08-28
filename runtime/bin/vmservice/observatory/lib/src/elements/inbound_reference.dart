// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library inbound_reference_element;

import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('inbound-reference')
class InboundReferenceElement extends ServiceRefElement {
  InboundReferenceElement.created() : super.created();

  dynamic get slot => (ref as ServiceMap)['slot'];
  bool get slotIsArrayIndex => slot is num;
  bool get slotIsField => slot is ServiceMap && slot['type'] == '@Field';

  ServiceObject get source => (ref as ServiceMap)['source'];

  // I.e., inbound references to 'source' for recursive pointer chasing.
  @observable ObservableList inboundReferences;
  Future<ServiceObject> fetchInboundReferences(arg) {
    return source.isolate.get(source.id + "/inbound_references?limit=$arg")
        .then((ServiceMap response) {
          inboundReferences = new ObservableList.from(response['references']);
        });
  }

  // TODO(turnidge): This is here to workaround vm/dart2js differences.
  dynamic expander() {
    return expandEvent;
  }

  void expandEvent(bool expand, var done) {
    assert(ref is ServiceMap);
    if (expand) {
      fetchInboundReferences(100).then((result) {
        notifyPropertyChange(#ref, 0, 1);
      }).whenComplete(done);
    } else {
      ServiceMap refMap = ref;
      refMap['fields'] = null;
      refMap['elements'] = null;
      done();
    }
  }
}
