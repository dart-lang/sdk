// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instance_ref_element;

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'service_ref.dart';

@CustomTag('instance-ref')
class InstanceRefElement extends ServiceRefElement {
  InstanceRefElement.created() : super.created();

  @published bool expanded = false;

  String get name {
    if (ref == null) {
      return super.name;
    }
    return ref['preview'];
  }

  void toggleExpand(var a, var b, var c) {
    if (expanded) {
      ref['fields'] = null;
      ref['elements'] = null;
      expanded = false;
    } else {
      app.requestManager.requestMap(url).then((map) {
          print(map);
          ref['fields'] = map['fields'];
          ref['elements'] = map['elements'];
          ref['length'] = map['length'];
          expanded = true;
      }).catchError((e, trace) {
          Logger.root.severe('Error while expanding instance-ref: $e\n$trace');
      });
    }
  }
}
