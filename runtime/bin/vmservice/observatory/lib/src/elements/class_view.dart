// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('class-view')
class ClassViewElement extends ObservatoryElement {
  @published Class cls;
  @observable ServiceMap instances;
  @observable int retainedBytes;
  ClassViewElement.created() : super.created();

  Future<ServiceObject> eval(String text) {
    return cls.get("eval?expr=${Uri.encodeComponent(text)}");
  }

  Future<ServiceObject> reachable(var limit) {
    return cls.get("instances?limit=$limit")
        .then((ServiceMap obj) {
          instances = obj;
        });
  }

  // TODO(koda): Add no-arg "calculate-link" instead of reusing "eval-link".
  Future<ServiceObject> retainedSize(var dummy) {
    return cls.get("retained").then((Instance obj) {
      retainedBytes = int.parse(obj.valueAsString);
    });
  }

  void refresh(var done) {
    instances = null;
    retainedBytes = null;
    cls.reload().whenComplete(done);
  }

  void refreshCoverage(var done) {
    cls.refreshCoverage().whenComplete(done);
  }
}
