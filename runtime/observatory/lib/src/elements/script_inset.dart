// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'service_ref.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

const nbsp = "\u00A0";

void addInfoBox(content, infoBox) {
  infoBox.style.position = 'absolute';
  infoBox.style.padding = '1em';
  infoBox.style.border = 'solid black 2px';
  infoBox.style.zIndex = '10';
  infoBox.style.backgroundColor = 'white';
  infoBox.style.cursor = 'auto';
  infoBox.style.display = 'none';  // Initially hidden.

  var show = false;
  content.onClick.listen((event) {
    show = !show;
    infoBox.style.display = show ? 'block' : 'none';
    content.style.backgroundColor = show ? 'white' : '';
  });

  // Causes infoBox to be positioned relative to the bottom-left of content.
  content.style.display = 'inline-block';
  content.style.cursor = 'pointer';
  content.append(infoBox);
}

abstract class Annotation {
  int line;
  int columnStart;
  int columnStop;

  void applyStyleTo(element);
}

class CurrentExecutionAnnotation extends Annotation {
  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.classes.add("currentCol");
    element.title = "Current execution";
  }
}

class CallSiteAnnotation extends Annotation {
  CallSite callSite;

  Element row([content]) {
    var e = new DivElement();
    e.style.display = "table-row";
    if (content is String) e.text = content;
    return e;
  }

  Element cell(content) {
    var e = new DivElement();
    e.style.display = "table-cell";
    e.style.padding = "3px";
    if (content is String) e.text = content;
    if (content is Element) e.children.add(content);
    return e;
  }

  Element serviceRef(object) {
    AnyServiceRefElement e = new Element.tag("any-service-ref");
    e.ref = object;
    return e;
  }

  Element entriesTable() {
    var e = new DivElement();
    e.style.display = "table";
    e.style.color = "#333";
    e.style.font = "400 14px 'Montserrat', sans-serif";

    if (callSite.entries.isEmpty) {
      e.append(row('Did not execute'));
    } else {
      var r = row();
      r.append(cell("Container"));
      r.append(cell("Count"));
      r.append(cell("Target"));
      e.append(r);

      for (var entry in callSite.entries) {
        var r = row();
        r.append(cell(serviceRef(entry.receiverContainer)));
        r.append(cell(entry.count.toString()));
        r.append(cell(serviceRef(entry.target)));
        e.append(r);
      }
    }

    return e;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "Call site: ${callSite.name}";

    addInfoBox(element, entriesTable());
  }
}

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

  var annotations = [];
  var annotationsCursor;

  StreamSubscription scriptChangeSubscription;

  String makeLineId(int line) {
    return 'line-$line';
  }

  void _scrollToCurrentPos() {
    var line = querySelector('#${makeLineId(currentLine)}');
    if (line != null) {
      line.scrollIntoView();
    }
  }

  void detached() {
    if (scriptChangeSubscription != null) {
      // Don't leak. If only Dart and Javascript exposed weak references...
      scriptChangeSubscription.cancel();
      scriptChangeSubscription = null;
    }
    super.detached();
  }

  void currentPosChanged(oldValue) {
    update();
    _scrollToCurrentPos();
  }

  void startPosChanged(oldValue) {
    update();
  }

  void endPosChanged(oldValue) {
    update();
  }

  void scriptChanged(oldValue) {
    update();
  }

  Element a(String text) => new AnchorElement()..text = text;
  Element span(String text) => new SpanElement()..text = text;

  Element hitsUnknown(Element element) {
    element.classes.add('hitsNone');
    element.title = "";
    return element;
  }
  Element hitsNotExecuted(Element element) {
    element.classes.add('hitsNotExecuted');
    element.title = "Line did not execute";
    return element;
  }
  Element hitsExecuted(Element element) {
    element.classes.add('hitsExecuted');
    element.title = "Line did execute";
    return element;
  }

  Element container;

  void update() {
    if (script == null) {
      // We may have previously had a script.
      if (container != null) {
        container.children.clear();
      }
      return;
    }
    if (!script.loaded) {
      script.load().then((_) => update());
      return;
    }

    if (scriptChangeSubscription == null) {
      scriptChangeSubscription = script.changes.listen((_) => update());
    }

    computeAnnotations();

    var table = linesTable();
    if (container == null) {
      // Indirect to avoid deleting the style element.
      container = new DivElement();
      shadowRoot.append(container);
    }
    container.children.clear();
    container.children.add(table);
  }

  void computeAnnotations() {
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

    annotations.clear();
    if (currentLine != null) {
      var a = new CurrentExecutionAnnotation();
      a.line = currentLine;
      a.columnStart = currentCol;
      a.columnStop = currentCol + 1;
      annotations.add(a);
    }

    for (var callSite in script.callSites) {
      var a = new CallSiteAnnotation();
      a.line = callSite.line;
      a.columnStart = callSite.column - 1;  // Call site is 1-origin.
      var tokenLength = callSite.name.length;  // Approximate.
      a.columnStop = a.columnStart + tokenLength;
      a.callSite = callSite;
      annotations.add(a);
    }

    annotations.sort((a, b) {
      if (a.line == b.line) {
        return a.columnStart.compareTo(b.columnStart);
      }
      return a.line.compareTo(b.line);
    });
  }

  Element linesTable() {
    var table = new DivElement();
    table.classes.add("sourceTable");

    annotationsCursor = 0;

    int blankLineCount = 0;
    for (int i = (startLine - 1); i <= (endLine - 1); i++) {
      if (script.lines[i].isBlank) {
        // Try to introduce elipses if there are 4 or more contiguous
        // blank lines.
        blankLineCount++;
      } else {
        if (blankLineCount > 0) {
          int firstBlank = i - blankLineCount;
          int lastBlank = i - 1;
          if (blankLineCount < 4) {
            // Too few blank lines for an elipsis.
            for (int j = firstBlank; j  <= lastBlank; j++) {
              table.append(lineElement(script.lines[j]));
            }
          } else {
            // Add an elipsis for the skipped region.
            table.append(lineElement(script.lines[firstBlank]));
            table.append(lineElement(null));
            table.append(lineElement(script.lines[lastBlank]));
          }
          blankLineCount = 0;
        }
        table.append(lineElement(script.lines[i]));
      }
    }

    return table;
  }

  // Assumes annotations are sorted.
  Annotation nextAnnotationOnLine(int line) {
    if (annotationsCursor >= annotations.length) return null;
    var annotation = annotations[annotationsCursor];
    if (annotation.line != line) return null;
    annotationsCursor++;
    return annotation;
  }

  Element lineElement(ScriptLine line) {
    var e = new DivElement();
    e.classes.add("sourceRow");
    e.append(lineBreakpointElement(line));
    e.append(lineNumberElement(line));
    e.append(lineSourceElement(line));
    return e;
  }

  Element lineBreakpointElement(ScriptLine line) {
    BreakpointToggleElement e = new Element.tag("breakpoint-toggle");
    e.line = line;
    return e;
  }

  Element lineNumberElement(ScriptLine line) {
    var lineNumber = line == null ? "..." : line.line;
    var e = span("$nbsp$lineNumber$nbsp");

    if ((line == null) || (line.hits == null)) {
      hitsUnknown(e);
    } else if (line.hits == 0) {
      hitsNotExecuted(e);
    } else {
      hitsExecuted(e);
    }

    return e;
  }

  Element lineSourceElement(ScriptLine line) {
    var e = new DivElement();
    e.classes.add("sourceItem");

    if (line != null) {
      if (line.line == currentLine) {
        e.classes.add("currentLine");
      }

      e.id = makeLineId(line.line);

      var position = 0;
      consumeUntil(var stop) {
        if (stop <= position) {
          return null;  // Empty gap between annotations/boundries.
        }
        if (stop > line.text.length) {
          // Approximated token length can run past the end of the line.
          stop = line.text.length;
        }

        var chunk = line.text.substring(position, stop);
        var chunkNode = span(chunk);
        e.append(chunkNode);
        position = stop;
        return chunkNode;
      }

      // TODO(rmacnak): Tolerate overlapping annotations.
      var annotation;
      while ((annotation = nextAnnotationOnLine(line.line)) != null) {
        consumeUntil(annotation.columnStart);
        annotation.applyStyleTo(consumeUntil(annotation.columnStop));
      }
      consumeUntil(line.text.length);
    }

    return e;
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
    if (line.breakpoints == null) {
      // No breakpoint.  Add it.
      line.script.isolate.addBreakpoint(line.script, line.line).then((_) {
          busy = false;
      });
    } else {
      // Existing breakpoint.  Remove it.
      List pending = [];
      for (var bpt in line.breakpoints) {
        pending.add(line.script.isolate.removeBreakpoint(bpt));
      }
      Future.wait(pending).then((_) {
        busy = false;
      });
    }
  }

  BreakpointToggleElement.created() : super.created();
}
