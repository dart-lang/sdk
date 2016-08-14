// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library objectstore_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';


@CustomTag('objectstore-view')
class ObjectStoreViewElement extends ObservatoryElement {
  @published ObjectStore objectStore;

  ObjectStoreViewElement.created() : super.created();

  Future refresh() {
    return objectStore.isolate.getObjectStore().then((newObjectStore) {
      objectStore = newObjectStore;
    });
  }
}
