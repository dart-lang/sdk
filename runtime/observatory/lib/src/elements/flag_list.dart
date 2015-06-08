// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library flag_list_element;

import 'dart:async';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';
import 'package:observatory/service.dart';

@CustomTag('flag-list')
class FlagListElement extends ObservatoryElement {
  @published ServiceMap flagList;

  void flagListChanged(oldValue) {
    modifiedFlags =
        flagList['flags'].where((flag) => flag['modified']).toList();
    unmodifiedFlags =
        flagList['flags'].where((flag) => !flag['modified']).toList();
  }

  @observable List<ServiceMap> modifiedFlags = new List<ServiceMap>();
  @observable List<ServiceMap> unmodifiedFlags = new List<ServiceMap>();

  FlagListElement.created() : super.created();

  Future refresh() {
    return flagList.reload();
  }
}

@CustomTag('flag-item')
class FlagItemElement extends ObservatoryElement {
  @published ObservableMap flag;

  FlagItemElement.created() : super.created();
}
