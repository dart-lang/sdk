// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_view;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('object-view')
class ObjectViewElement extends ObservatoryElement {
  @published ServiceObject object;

  ObjectViewElement.created() : super.created();
}
