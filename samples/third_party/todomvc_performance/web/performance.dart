// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library todomvc_performance;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'package:polymer/polymer.dart';
import 'package:web_components/polyfill.dart';
import 'elements/td_model.dart';

/**
 * This test determines how fast the TodoMVC app has loaded.
 */
main() {
  initPolymer();
  Polymer.onReady.then((_) {
    var endInitTime = new DateTime.now();
    window.postMessage(endInitTime.millisecondsSinceEpoch, '*');
  });
}
