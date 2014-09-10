// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_common_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('object-common')
class ObjectCommonElement extends ObservatoryElement {
  @published ServiceObject object;
  @published ServiceMap path;
  @published ServiceMap inboundReferences;
  @observable int retainedBytes = null;

  ObjectCommonElement.created() : super.created();

  // TODO(koda): Add no-arg "calculate-link" instead of reusing "eval-link".
  Future<ServiceObject> retainedSize(var dummy) {
    return object.isolate.get(object.id + "/retained")
        .then((ServiceMap obj) {
          retainedBytes = int.parse(obj['valueAsString']);
        });
  }

  Future<ServiceObject> retainingPath(var arg) {
    return object.isolate.get(object.id + "/retaining_path?limit=$arg")
        .then((ServiceObject obj) {
          path = obj;
        });
  }

  Future<ServiceObject> fetchInboundReferences(var arg) {
    return object.isolate.get(object.id + "/inbound_references?limit=$arg")
        .then((ServiceObject obj) {
           inboundReferences = obj;
        });
  }

  void refresh(Function onDone) {
    object.reload().whenComplete(onDone);
  }
}
