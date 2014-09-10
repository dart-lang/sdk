// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library inbound_reference_element;

import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'observatory_element.dart';

@CustomTag('inbound-reference')
class InboundReferenceElement extends ObservatoryElement {
  @published ObservableMap ref;
  InboundReferenceElement.created() : super.created();

  dynamic get slot => ref['slot'];
  bool get slotIsArrayIndex => slot is num;
  bool get slotIsField => slot is ServiceMap && slot['type'] == '@Field';

  ServiceObject get source => ref['source'];

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

  void expandEvent(bool expand, Function onDone) {
    if (expand) {
      fetchInboundReferences(100).then((result) {
        notifyPropertyChange(#ref, 0, 1);
      }).whenComplete(onDone);
    } else {
      inboundReferences = null;
      onDone();
    }
  }
}
