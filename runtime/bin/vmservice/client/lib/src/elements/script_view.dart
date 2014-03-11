// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_view_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

/// Displays an Error response.
@CustomTag('script-view')
class ScriptViewElement extends ObservatoryElement {
  @published Script script;
  @published bool showCoverage = false;

  ScriptViewElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    if (script == null) {
      return;
    }
    script.load();
  }

  void _triggerHitRefresh() {
    notifyPropertyChange(#hitsStyle, 0, 1);
  }

  showCoverageChanged(oldValue) {
    _triggerHitRefresh();
  }

  static const hitStyleNone = 'min-width:32px;';
  static const hitStyleExecuted = 'min-width:32px;background-color:green';
  static const hitStyleNotExecuted = 'min-width:32px;background-color:red';

  @observable String hitsStyle(ScriptLine line) {
    if ((script == null) || !showCoverage) {
      return hitStyleNone;
    }
    var hit = script.hits[line.line];
    if (hit == null) {
      return hitStyleNone;
    }
    if (hit == 0) {
      return hitStyleNotExecuted;
    }
    assert(hit > 0);
    return hitStyleExecuted;
  }

  void refresh(var done) {
    script.reload().whenComplete(done);
  }

  void refreshCoverage(var done) {
    script.isolate.refreshCoverage().then((_) {
      _triggerHitRefresh();
      done();
    });
  }
}
