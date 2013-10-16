// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library collapsible_content_element;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

/// An element which conditionally displays its children elements.
@CustomTag('collapsible-content')
class CollapsibleContentElement extends ObservatoryElement {
  static const String _openIconClass = 'glyphicon glyphicon-chevron-down';
  static const String _closeIconClass = 'glyphicon glyphicon-chevron-up';

  @observable String get iconClass => __$iconClass; String __$iconClass = _openIconClass; set iconClass(String value) { __$iconClass = notifyPropertyChange(#iconClass, __$iconClass, value); }
  @observable String get displayValue => __$displayValue; String __$displayValue = 'none'; set displayValue(String value) { __$displayValue = notifyPropertyChange(#displayValue, __$displayValue, value); }

  bool _collapsed = true;
  bool get collapsed => _collapsed;
  set collapsed(bool r) {
    _collapsed = r;
    _refresh();
  }

  void toggleDisplay(Event e, var detail, Node target) {
    collapsed = !collapsed;
    _refresh();
  }

  void inserted() {
    super.inserted();
    _refresh();
  }

  void _refresh() {
    if (_collapsed) {
      iconClass = _openIconClass;
      displayValue = 'none';
    } else {
      iconClass = _closeIconClass;
      displayValue = 'block';
    }
  }
}