// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_object_view_element;

import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('service-view')
class ServiceObjectViewElement extends ObservatoryElement {
  @published ServiceObject object;

  ServiceObjectViewElement.created() : super.created();

  objectChanged(oldValue) {
    if (object == null) {
      Logger.root.info('Message set to null.');
      return;
    }
    Logger.root.info('Viewing object of type \'${object.serviceType}\'');
  }
}
