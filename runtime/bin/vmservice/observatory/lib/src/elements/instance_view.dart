// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('instance-view')
class InstanceViewElement extends ObservatoryElement {
  @published Instance instance;
  @published ServiceMap path;
  @published ServiceMap inboundReferences;
  @observable int retainedBytes = null;

  InstanceViewElement.created() : super.created();

  Future<ServiceObject> eval(String text) {
    return instance.isolate.get(
        instance.id + "/eval?expr=${Uri.encodeComponent(text)}");
  }

  // TODO(koda): Add no-arg "calculate-link" instead of reusing "eval-link".
  Future<ServiceObject> retainedSize(var dummy) {
    return instance.isolate.get(instance.id + "/retained")
        .then((ServiceMap obj) {
          retainedBytes = int.parse(obj['valueAsString']);
        });
  }

  Future<ServiceObject> retainingPath(var arg) {
    return instance.isolate.get(instance.id + "/retaining_path?limit=$arg")
        .then((ServiceObject obj) {
          path = obj;
        });
  }

  Future<ServiceObject> fetchInboundReferences(var arg) {
    return instance.isolate.get(instance.id + "/inbound_references?limit=$arg")
        .then((ServiceObject obj) {
           inboundReferences = obj;
        });
  }

  void refresh(var done) {
    instance.reload().whenComplete(done);
  }
}
