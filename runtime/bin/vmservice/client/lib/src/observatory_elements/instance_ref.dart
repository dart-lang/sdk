// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_ref_element;

import 'package:polymer/polymer.dart';
import 'service_ref.dart';

@CustomTag('instance-ref')
class InstanceRefElement extends ServiceRefElement {
  InstanceRefElement.created() : super.created();

  String get name {
    if (ref == null) {
      return super.name;
    }
    return ref['preview'];
  }
}