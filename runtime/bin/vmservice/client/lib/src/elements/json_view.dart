// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_view_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('json-view')
class JsonViewElement extends ObservatoryElement {
  @published var json = null;
  var _count = 0;

  JsonViewElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    _count = 0;
  }

  void jsonChanged(oldValue) {
    notifyPropertyChange(#valueType, "a", "b");
  }

  String get primitiveString {
    return json.toString();
  }

  String get valueType {
    if (json is Map) {
      return 'Map';
    } else if (json is List) {
      return 'List';
    }
    return 'Primitive';
  }

  int get counter {
    return _count++;
  }

  List get list {
    if (json is List) {
      return json;
    }
    return [];
  }

  List get keys {
    if (json is Map) {
      return json.keys.toList();
    }
    return [];
  }

  dynamic value(String key) {
    return json[key];
  }
}
