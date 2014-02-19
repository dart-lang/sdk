// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_ref_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('service-ref')
class ServiceRefElement extends ObservatoryElement {
  @published Map ref;
  @published bool internal = false;
  @published Isolate isolate = null;
  ServiceRefElement.created() : super.created();

  void refChanged(oldValue) {
    notifyPropertyChange(#url, "", url);
    notifyPropertyChange(#name, [], name);
    notifyPropertyChange(#hoverText, "", hoverText);
  }

  String get url {
    if (ref != null) {
      return relativeLink(ref['id']);
    }
    return '';
  }

  String get hoverText {
    if (ref == null) {
      return '';
    }
    // Return the VM name by default.
    var name = ref['name'];
    return name != null ? name : '';
  }

  String get name {
    if (ref == null) {
      return '';
    }
    String name_key = internal ? 'name' : 'user_name';
    if (ref[name_key] != null) {
      return ref[name_key];
    } else if (ref['name'] != null) {
      return ref['name'];
    }
    return '';
  }

  void isolateChanged(oldValue) {
    notifyPropertyChange(#relativeLink, 0, 1);
  }

  @observable
  String relativeLink(String link) {
    if (app == null) {
      return '';
    } else if (isolate == null) {
      return app.locationManager.currentIsolateRelativeLink(link);
    } else {
      return app.locationManager.relativeLink(isolate.id, link);
    }
  }
}
