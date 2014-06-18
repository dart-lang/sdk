// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_view_element;

import 'observatory_element.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

/// Displays an Script response.
@CustomTag('script-view')
class ScriptViewElement extends ObservatoryElement {
  @published Script script;
  @published bool showCoverage = false;

  ScriptViewElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    if (script == null) {
      return;
    }
    script.load();
  }

  showCoverageChanged(oldValue) {
    ScriptInsetElement sie = shadowRoot.querySelector('#scriptInset');
    sie.coverage = showCoverage;
  }

  void refresh(var done) {
    script.reload().whenComplete(done);
  }

  void refreshCoverage(var done) {
    script.isolate.refreshCoverage().then((_) {
      ScriptInsetElement sie = shadowRoot.querySelector('#scriptInset');
      showCoverage = true;
      sie.coverage = showCoverage;
    }).whenComplete(done);
  }
}
