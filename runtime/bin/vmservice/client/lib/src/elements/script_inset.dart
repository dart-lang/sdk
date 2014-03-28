// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

/// Displays an Error response.
@CustomTag('script-inset')
class ScriptInsetElement extends ObservatoryElement {
  @published Script script;
  @published int pos;

  @observable List<ScriptLine> lines = toObservable([]);
  
  void scriptChanged(oldValue) {
    _updateProperties();
  }

  void posChanged(oldValue) {
    _updateProperties();
  }

  void _updateProperties() {
    if (!script.loaded) {
      script.load().then((_) {
          if (script.loaded) {
            _updateProperties();
          }
        });
      return;
    }
    notifyPropertyChange(#lines, 0, 1);
    var lineNumber = script.tokenToLine(pos);
    lines.clear();
    lines.add(script.lines[lineNumber-1]);
  }

  ScriptInsetElement.created() : super.created();
}
