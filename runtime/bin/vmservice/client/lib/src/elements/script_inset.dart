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
  final List<int> lineNumbers = new ObservableList<int>();
  @observable int startLine;
  @observable int endLine;

  @observable List<ScriptLine> lines = toObservable([]);

  void attached() {
    super.attached();
  }

  void scriptChanged(oldValue) {
    _updateLines();
  }

  void posChanged(oldValue) {
    _updateLines();
  }

  void endPosChanged(oldValue) {
    _updateLines();
  }

  static const hitStyleNone = 'min-width:32px;';
  static const hitStyleExecuted = 'min-width:32px; background-color:green';
  static const hitStyleNotExecuted = 'min-width:32px; background-color:red';

  /// [hits] can be null which indicates that the line is not executable.
  /// When [hits] is 0, the line is executable but hasn't been executed and
  /// when [hits] is positive, the line is executable and has been executed.
  String styleForHits(int hits) {
    if (hits == null) {
      return hitStyleNone;
    } else if (hits == 0) {
      return hitStyleNotExecuted;
    }
    assert(hits > 0);
    return hitStyleExecuted;
  }

  var _updateFuture;

  void _updateLines() {
    if (_updateFuture != null) {
      // Already scheduled.
      return;
    }
    if (!script.loaded) {
      _updateFuture = script.load().then((_) {
        if (script.loaded) {
          _updateFuture = null;
          _updateLines();
        }
      });
      return;
    }
    startLine =
        (pos != null) ? script.tokenToLine(pos) - 1 : 0;
    endLine =
        (endPos != null) ? script.tokenToLine(endPos) : script.lines.length;
    // Add line numbers.
    lineNumbers.clear();
    for (var i = startLine; i < endLine; i++) {
      lineNumbers.add(i);
    }
  }

  ScriptInsetElement.created() : super.created();
}
