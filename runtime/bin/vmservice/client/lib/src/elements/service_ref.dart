// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_ref_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';
import 'package:observatory/service.dart';

@CustomTag('service-ref')
class ServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  @published bool internal = false;
  ServiceRefElement.created() : super.created();

  void refChanged(oldValue) {
    notifyPropertyChange(#url, "", url);
    notifyPropertyChange(#name, [], name);
    notifyPropertyChange(#nameIsEmpty, 0, 1);
    notifyPropertyChange(#hoverText, "", hoverText);
  }

  String get url {
    if (ref == null) {
      return 'NULL REF';
    }
    return gotoLink(ref.link);
  }

  String get serviceId {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.id;
  }

  String get hoverText {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.vmName;
  }

  String get name {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.name;
  }

  // Workaround isEmpty not being useable due to missing @MirrorsUsed.
  bool get nameIsEmpty {
    return name.isEmpty;
  }
}
