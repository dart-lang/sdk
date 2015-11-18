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

  ObjectPoolViewElement.created() : super.created();

  bool isServiceObject(o) => o is ServiceObject;

  Future refresh() {
    return pool.reload();
  }
}
