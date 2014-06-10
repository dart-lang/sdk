// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

/// Box with script source code in it.
@CustomTag('script-inset')
class ScriptInsetElement extends ObservatoryElement {
  @published Script script;
  @published int pos;
  @published int endPos;
  @published bool coverage = false;

  @observable List<ScriptLine> lines = toObservable([]);

  void scriptChanged(oldValue) {
    _updateProperties();
    notifyPropertyChange(#hitStyle, 0, 1);
    notifyPropertyChange(#lines, 0, 1);
  }

  void posChanged(oldValue) {
    _updateProperties();
  }

  coverageChanged(oldValue) {
    _updateProperties();
    notifyPropertyChange(#lines, 0, 1);
    notifyPropertyChange(#hitStyle, 0, 1);
  }

  static const hitStyleNone = 'min-width:32px;';
  static const hitStyleExecuted = 'min-width:32px;background-color:green';
  static const hitStyleNotExecuted = 'min-width:32px;background-color:red';

  @observable String hitStyle(ScriptLine line) {
    if ((script == null) || !coverage) {
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
    lines.clear();
    var startLineNumber = script.tokenToLine(pos);
    if (startLineNumber != null) {
      if (endPos == null) {
        lines.add(script.lines[startLineNumber - 1]);
      } else {
        var endLineNumber = script.tokenToLine(endPos);
        assert(endLineNumber != null);
        for (var i = startLineNumber; i <= endLineNumber; i++) {
          lines.add(script.lines[i - 1]);
        }
      }
    }
  }

  ScriptInsetElement.created() : super.created();
}
