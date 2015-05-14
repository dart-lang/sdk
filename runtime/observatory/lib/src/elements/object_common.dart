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
    return object.isolate.getRetainedSize(object).then((Instance obj) {
      // TODO(turnidge): Handle collected/expired objects gracefully.
      retainedBytes = int.parse(obj.valueAsString);
    });
  }

  Future<ServiceObject> retainingPath(var limit) {
    return object.isolate.getRetainingPath(object, limit).then((ServiceObject obj) {
      path = obj;
    });
  }

  Future<ServiceObject> fetchInboundReferences(var limit) {
    return object.isolate.getInboundReferences(object, limit)
        .then((ServiceObject obj) {
           inboundReferences = obj;
        });
  }

  Future refresh() {
    return object.reload();
  }
}
