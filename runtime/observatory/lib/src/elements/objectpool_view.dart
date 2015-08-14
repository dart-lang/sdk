// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library objectpool_view;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('objectpool-view')
class ObjectPoolViewElement extends ObservatoryElement {
  @published ObjectPool pool;
  @published List annotatedEntries;

  ObjectPoolViewElement.created() : super.created();

  bool isServiceObject(o) => o is ServiceObject;

  void poolChanged(oldValue) {
    annotateExternalLabels();
  }

  Future annotateExternalLabels() {
    var tasks = pool.entries.map((entry) {
     if (entry is String) {
       var addr = entry.substring(2);
       return pool.isolate.getObjectByAddress(addr).then((result) {
         return result is ServiceObject ? result : null;
       });
     } else {
       return new Future.value(null);
     }
    });

    return Future.wait(tasks).then((results) => annotatedEntries = results);
  }

  Future refresh() {
    return pool.reload().then((_) => annotateExternalLabels());
  }
}
