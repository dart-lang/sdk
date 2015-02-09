// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

/// Box with script source code in it.
@CustomTag('script-inset')
class ScriptInsetElement extends ObservatoryElement {
  @published Script script;

  /// Set the height to make the script inset scroll.  Otherwise it
  /// will show from startPos to endPos.
  @published String height = null;

  @published int currentPos;
  @published int startPos;
  @published int endPos;

  @observable int currentLine;
  @observable int currentCol;
  @observable int startLine;
  @observable int endLine;
  @observable bool linesReady = false;

  // Contents are either ScriptLine or ScriptElipsis.
  @observable List lines = toObservable([]);

  String makeLineId(int line) {
    return 'line-$line';
  }

  String clip(String line, int start, [int limit]) {
    try {
      return line.substring(start, limit);
    } catch (_) {
      // NOTE(turnidge): Sometimes polymer updates give us garbage
      // starts and limits during page updates.
      return "OOB";
    }
  }

  MutationObserver _observer;

  void _scrollToCurrentPos() {
    var line = shadowRoot.querySelector('#line-$currentLine');
    if (line != null) {
      line.scrollIntoView();
    }
  }

  void _onMutation(mutations, observer) {
    _scrollToCurrentPos();
  } 

  void attached() {
    super.attached();
    var table = shadowRoot.querySelector('.sourceTable');
    if (table != null) {
      _observer = new MutationObserver(_onMutation);
      _observer.observe(table, childList:true);
    }
  }

  void detached() {
    if (_observer != null) {
      _observer.disconnect();
      _observer = null;
    }
    super.detached();
  }

  void currentPosChanged(oldValue) {
    _updateLines();
    _scrollToCurrentPos();
  }

  void startPosChanged(oldValue) {
    _updateLines();
  }

  void endPosChanged(oldValue) {
    _updateLines();
  }

  void scriptChanged(oldValue) {
    _updateLines();
  }

  var _updateFuture;

  void _updateLines() {
    linesReady = false;
    if (_updateFuture != null) {
      // Already scheduled.
      return;
    }
    if (script == null) {
      // Wait for script to be assigned.
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
    startLine = (startPos != null
                 ? script.tokenToLine(startPos)
                 : 1);
    currentLine = (currentPos != null
                   ? script.tokenToLine(currentPos)
                   : null);
    currentCol = (currentPos != null
                  ? (script.tokenToCol(currentPos) - 1)  // make this 0-based.
                  : null);
    endLine = (endPos != null
               ? script.tokenToLine(endPos)
               : script.lines.length);

    lines.clear();
    int blankLineCount = 0;
    for (int i = (startLine - 1); i <= (endLine - 1); i++) {
      if (script.lines[i].isBlank) {
        // Try to introduce elipses if there are 4 or more contiguous blank lines.
        blankLineCount++;
      } else {
        if (blankLineCount > 0) {
          int firstBlank = i - blankLineCount;
          int lastBlank = i - 1;
          if (blankLineCount < 4) {
            // Too few blank lines for an elipsis.
            for (int j = firstBlank; j  <= lastBlank; j++) {
              lines.add(script.lines[j]);
            }
          } else {
            // Add an elipsis for the skipped region.
            lines.add(script.lines[firstBlank]);
            lines.add(null);
            lines.add(script.lines[lastBlank]);
          }
          blankLineCount = 0;
        }
        lines.add(script.lines[i]);
      }
    }
    linesReady = true;
  }

  ScriptInsetElement.created() : super.created();
}

@CustomTag('breakpoint-toggle')
class BreakpointToggleElement extends ObservatoryElement {
  @published ScriptLine line;
  @observable bool busy = false;

  void toggleBreakpoint(var a, var b, var c) {
    if (busy) {
      return;
    }
    busy = true;
    if (line.bpt == null) {
      // No breakpoint.  Add it.
      line.script.isolate.addBreakpoint(line.script, line.line).then((_) {
          busy = false;
      });
    } else {
      // Existing breakpoint.  Remove it.
      line.script.isolate.removeBreakpoint(line.bpt).then((_) {
          busy = false;
      });
    }
  }

  BreakpointToggleElement.created() : super.created();
}
