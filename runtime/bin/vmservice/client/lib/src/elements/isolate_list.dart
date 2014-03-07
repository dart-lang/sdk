// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_list_element;

import 'vm_element.dart';
import 'dart:async';
import 'package:polymer/polymer.dart';

/// Displays an IsolateList response.
@CustomTag('isolate-list')
class IsolateListElement extends VMElement {
  IsolateListElement.created() : super.created();

  void refresh(var done) {
    var futures = [];
    vm.isolates.forEach((id, isolate) {
       futures.add(isolate.refresh());
    });
    Future.wait(futures).then((_) => done());
  }
}