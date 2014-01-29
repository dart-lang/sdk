// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library navigation_bar_isolate_element;

import 'observatory_element.dart';
import 'package:polymer/polymer.dart';

@CustomTag('navigation-bar-isolate')
class NavigationBarIsolateElement extends ObservatoryElement {
  NavigationBarIsolateElement.created() : super.created();
  @observable List<String> links = toObservable(
      [ 'Stacktrace', 'Library', 'CPU Profile']);

  void appChanged(oldValue) {
    super.appChanged(oldValue);
    notifyPropertyChange(#currentIsolateName, '', currentIsolateName);
  }

  String currentIsolateName() {
    if (app == null) {
      return '';
    }
    var isolate = app.locationManager.currentIsolate();
    if (isolate == null) {
      return '';
    }
    return isolate.name;
  }

  String currentIsolateLink(String link) {
    if (app == null) {
      return '';
    }
    switch (link) {
      case 'Stacktrace':
        return app.locationManager.currentIsolateRelativeLink('stacktrace');
      case 'Library':
        return app.locationManager.currentIsolateRelativeLink('library');
      case 'CPU Profile':
        return app.locationManager.currentIsolateRelativeLink('profile');
      default:
        return app.locationManager.currentIsolateRelativeLink('');
    }
  }
}