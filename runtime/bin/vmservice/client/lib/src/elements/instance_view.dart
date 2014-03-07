// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_view_element;

import 'isolate_element.dart';
import 'package:polymer/polymer.dart';

@CustomTag('instance-view')
class InstanceViewElement extends IsolateElement {
  @published Map instance;
  InstanceViewElement.created() : super.created();
}
