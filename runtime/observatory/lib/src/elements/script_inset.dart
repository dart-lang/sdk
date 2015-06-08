// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'service_ref.dart';
import 'package:observatory/service.dart';
import 'package:observatory/utils.dart';
import 'package:polymer/polymer.dart';

const nbsp = "\u00A0";

void addInfoBox(Element content, Function infoBoxGenerator) {
  var infoBox;
  var show = false;
  var originalBackground = content.style.backgroundColor;
  buildInfoBox() {
    infoBox = infoBoxGenerator();
    infoBox.style.position = 'absolute';
    infoBox.style.padding = '1em';
    infoBox.style.border = 'solid black 2px';
    infoBox.style.zIndex = '10';
    infoBox.style.backgroundColor = 'white';
    infoBox.style.cursor = 'auto';
    // Don't inherit pre formating from the script lines.
    infoBox.style.whiteSpace = 'normal';
    content.append(infoBox);
  }
  content.onClick.listen((event) {
    show = !show;
    if (infoBox == null) buildInfoBox();  // Created lazily on the first click.
    infoBox.style.display = show ? 'block' : 'none';
    content.style.backgroundColor = show ? 'white' : originalBackground;
  });

  // Causes infoBox to be positioned relative to the bottom-left of content.
  content.style.display = 'inline-block';
  content.style.cursor = 'pointer';
}

abstract class Annotation implements Comparable<Annotation> {
  int line;
  int columnStart;
  int columnStop;

  void applyStyleTo(element);

  int compareTo(Annotation other) {
    if (line == other.line) {
      return columnStart.compareTo(other.columnStart);
    }
    return line.compareTo(other.line);
  }

  Element table() {
    var e = new DivElement();
    e.style.display = "table";
    e.style.color = "#333";
    e.style.font = "400 14px 'Montserrat', sans-serif";
    return e;
  }

  Element row([content]) {
    var e = new DivElement();
    e.style.display = "table-row";
    if (content is String) e.text = content;
    if (content is Element) e.children.add(content);
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

class LocalVariableAnnotation extends Annotation {
  final value;

  LocalVariableAnnotation(LocalVarLocation location, this.value) {
    line = location.line;
    columnStart = location.column;
    columnStop = location.endColumn;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "${value.shortName}";
  }
}

class CallSiteAnnotation extends Annotation {
  CallSite callSite;

  CallSiteAnnotation(this.callSite) {
    line = callSite.line;
    columnStart = callSite.column - 1;  // Call site is 1-origin.
    var tokenLength = callSite.name.length;  // Approximate.
    if (callSite.name.startsWith("get:") ||
        callSite.name.startsWith("set:")) tokenLength -= 4;
    columnStop = columnStart + tokenLength;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "Call site: ${callSite.name}";

    addInfoBox(element, () {
      var details = table();
      if (callSite.entries.isEmpty) {
        details.append(row('Call of "${callSite.name}" did not execute'));
      } else {
        var r = row();
        r.append(cell("Container"));
        r.append(cell("Count"));
        r.append(cell("Target"));
        details.append(r);

        for (var entry in callSite.entries) {
          var r = row();
          r.append(cell(serviceRef(entry.receiverContainer)));
          r.append(cell(entry.count.toString()));
          r.append(cell(serviceRef(entry.target)));
          details.append(r);
        }
      }
      return details;
    });
  }
}

abstract class DeclarationAnnotation extends Annotation {
  DeclarationAnnotation(decl) {
    assert(decl.loaded);
    SourceLocation location = decl.location;
    if (location == null) {
      line = 0;
      columnStart = 0;
      columnStop = 0;
      return;
    }
    Script script = location.script;
    line = script.tokenToLine(location.tokenPos);
    columnStart = script.tokenToCol(location.tokenPos);
    if ((line == null) || (columnStart == null)) {
      line = 0;
      columnStart = 0;
      columnStop = 0;
    } else {
      columnStart--; // 1-origin -> 0-origin.

      // The method's token position is at the beginning of the method
      // declaration, which may be a return type annotation, metadata, static
      // modifier, etc. Try to scan forward to position this annotation on the
      // function's name instead.
      var lineSource = script.getLine(line).text;
      var betterStart = lineSource.indexOf(decl.name, columnStart);
      if (betterStart != -1) {
        columnStart = betterStart;
      }
      columnStop = columnStart + decl.name.length;
    }
  }
}

class ClassDeclarationAnnotation extends DeclarationAnnotation {
  Class klass;

  ClassDeclarationAnnotation(Class cls) : klass = cls, super(cls);

  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "class ${klass.name}";

    addInfoBox(element, () {
      var details = table();
      var r = row();
      r.append(cell("Class"));
      r.append(cell(serviceRef(klass)));
      details.append(r);

      return details;
    });
  }
}

class FieldDeclarationAnnotation extends DeclarationAnnotation {
  Field field;

  FieldDeclarationAnnotation(Field fld) : field = fld, super(fld);

  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "field ${field.name}";

    addInfoBox(element, () {
      var details = table();
      var r = row();
      r.append(cell("Field"));
      r.append(cell(serviceRef(field)));
      details.append(r);

      if (field.isStatic) {
        if (field.loaded) {
          r = row();
          r.append(cell("Value"));
          r.append(cell(serviceRef(field.staticValue)));
          details.append(r);
        }
      } else {
        r = row();
        r.append(cell("Nullable"));
        r.append(cell(field.guardNullable ? "null observed"
                                          : "null not observed"));
        details.append(r);

        r = row();
        r.append(cell("Types"));
        if (field.guardClass == "dynamic") {
          r.append(cell("various"));
        } else if (field.guardClass == "unknown") {
          r.append(cell("none"));
        } else {
          r.append(cell(serviceRef(field.guardClass)));
        }
        details.append(r);
      }

      return details;
    });
  }
}

class FunctionDeclarationAnnotation extends DeclarationAnnotation {
  ServiceFunction function;

  FunctionDeclarationAnnotation(ServiceFunction func)
    : function = func, super(func);

  void applyStyleTo(element) {
    if (element == null) {
      return;  // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "method ${function.name}";

    if (function.isOptimizable == false ||
        function.isInlinable == false ||
        function.deoptimizations >0) {
      element.style.backgroundColor = "red";
    }

    addInfoBox(element, () {
      var details = table();
      var r = row();
      r.append(cell("Function"));
      r.append(cell(serviceRef(function)));
      details.append(r);

      r = row();
      r.append(cell("Usage Count"));
      r.append(cell("${function.usageCounter}"));
      details.append(r);

      if (function.isOptimizable == false) {
        details.append(row(cell("Unoptimizable!")));
      }
      if (function.isInlinable == false) {
        details.append(row(cell("Not inlinable!")));
      }
      if (function.deoptimizations > 0) {
        details.append(row("Deoptimized ${function.deoptimizations} times!"));
      }
      return details;
    });
  }
}

/// Box with script source code in it.
@CustomTag('script-inset')
class ScriptInsetElement extends ObservatoryElement {
  @published Script script;
  @published int startPos;
  @published int endPos;

  /// Set the height to make the script inset scroll.  Otherwise it
  /// will show from startPos to endPos.
  @published String height = null;

  @published int currentPos;
  @published bool inDebuggerContext = false;
  @published ObservableList variables;

  int _currentLine;
  int _currentCol;
  int _startLine;
  int _endLine;

  var annotations = [];
  var annotationsCursor;

  StreamSubscription scriptChangeSubscription;

  String makeLineId(int line) {
    return 'line-$line';
  }

  void _scrollToCurrentPos() {
    var line = querySelector('#${makeLineId(_currentLine)}');
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
    _updateTask.queue();
    _scrollToCurrentPos();
  }

  void startPosChanged(oldValue) {
    _updateTask.queue();
  }

  void endPosChanged(oldValue) {
    _updateTask.queue();
  }

  void scriptChanged(oldValue) {
    _updateTask.queue();
  }

  void variablesChanged(oldValue) {
    _updateTask.queue();
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

  Task _updateTask;
  void update() {
    assert(_updateTask != null);
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
    makeCssClassUncopyable(table, "noCopy");
  }

  void computeAnnotations() {
    _startLine = (startPos != null
                  ? script.tokenToLine(startPos)
                  : 1 + script.lineOffset);
    _currentLine = (currentPos != null
                    ? script.tokenToLine(currentPos)
                    : null);
    _currentCol = (currentPos != null
                   ? (script.tokenToCol(currentPos) - 1)  // make this 0-based.
                   : null);
    _endLine = (endPos != null
                ? script.tokenToLine(endPos)
                : script.lines.length + script.lineOffset);

    annotations.clear();

    addCurrentExecutionAnnotation();

    if (!inDebuggerContext) {
      loadDeclarationsOfLibrary(script.library);

      // Add fields before functions so they beat out conflicting
      // implicit g/setters.
      addClassAnnotations();
      addFieldAnnotations();
      addFunctionAnnotations();
      addCallSiteAnnotations();
    }

    addLocalVariableAnnotations();

    annotations.sort();
  }

  void addCurrentExecutionAnnotation() {
    if (_currentLine != null) {
      var a = new CurrentExecutionAnnotation();
      a.line = _currentLine;
      a.columnStart = _currentCol;
      a.columnStop = _currentCol + 1;
      annotations.add(a);
    }
  }

  void loadDeclarationsOfLibrary(Library lib) {
    lib.load().then((lib) {
      for (var func in lib.functions) {
        func.load();
      }
      for (var field in lib.variables) {
        field.load();
      }
      for (var cls in lib.classes) {
        cls.load().then((cls) {
          for (var func in cls.functions) {
            func.load();
          }
          for (var field in cls.fields) {
            field.load();
          }
        });
      }
    });
  }

  void addClassAnnotations() {
    for (var cls in script.library.classes) {
      if ((cls.location != null) && (cls.location.script == script)) {
        annotations.add(new ClassDeclarationAnnotation(cls));
      }
    }
  }

  void addFieldAnnotations() {
    for (var field in script.library.variables) {
      if ((field.location != null) && (field.location.script == script)) {
        annotations.add(new FieldDeclarationAnnotation(field));
      }
    }
    for (var cls in script.library.classes) {
      for (var field in cls.fields) {
        if ((field.location != null) && (field.location.script == script)) {
          annotations.add(new FieldDeclarationAnnotation(field));
        }
      }
    }
  }

  void addFunctionAnnotations() {
    for (var func in script.library.functions) {
      if ((func.location != null) && (func.location.script == script)) {
        annotations.add(new FunctionDeclarationAnnotation(func));
      }
    }
    for (var cls in script.library.classes) {
      for (var func in cls.functions) {
        if ((func.location != null) && (func.location.script == script)) {
          annotations.add(new FunctionDeclarationAnnotation(func));
        }
      }
    }
  }

  void addCallSiteAnnotations() {
    for (var callSite in script.callSites) {
      annotations.add(new CallSiteAnnotation(callSite));
    }
  }

  void addLocalVariableAnnotations() {
    // We have local variable information.
    if (variables != null) {
      // For each variable.
      for (var variable in variables) {
        // Find variable usage locations.
        var locations = script.scanForLocalVariableLocations(
              variable['name'],
              variable['_tokenPos'],
              variable['_endTokenPos']);

        // Annotate locations.
        for (var location in locations) {
          annotations.add(new LocalVariableAnnotation(location,
                                                      variable['value']));
        }
      }
    }
  }

  Element linesTable() {
    var table = new DivElement();
    table.classes.add("sourceTable");

    annotationsCursor = 0;

    int blankLineCount = 0;
    for (int i = _startLine; i <= _endLine; i++) {
      var line = script.getLine(i);
      if (line.isBlank) {
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
              table.append(lineElement(script.getLine(j)));
            }
          } else {
            // Add an elipsis for the skipped region.
            table.append(lineElement(script.getLine(firstBlank)));
            table.append(lineElement(null));
            table.append(lineElement(script.getLine(lastBlank)));
          }
          blankLineCount = 0;
        }
        table.append(lineElement(line));
      }
    }

    return table;
  }

  // Assumes annotations are sorted.
  Annotation nextAnnotationOnLine(int line) {
    if (annotationsCursor >= annotations.length) return null;
    var annotation = annotations[annotationsCursor];

    // Fast-forward past any annotations before the first line that
    // we are displaying.
    while (annotation.line < line) {
      annotationsCursor++;
      if (annotationsCursor >= annotations.length) return null;
      annotation = annotations[annotationsCursor];
    }

    // Next annotation is for a later line, don't advance past it.
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
    var e = new DivElement();
    var busy = false;
    if (line == null || !line.possibleBpt) {
      e.classes.add("emptyBreakpoint");
      e.classes.add('noCopy');
      e.text = nbsp;
      return e;
    }
    e.text = 'B';
    update() {
      e.classes.clear();
      e.classes.add('noCopy');

      if (!line.possibleBpt) {
        e.classes.add("emptyBreakpoint");
        e.text = nbsp;
      } else if (busy) {
        e.classes.add("busyBreakpoint");
      } else {
        if (line.breakpoints != null) {
          if (line.breakpointResolved) {
            e.classes.add("resolvedBreakpoint");
          } else {
            e.classes.add("unresolvedBreakpoint");
          }
        } else {
          e.classes.add("possibleBreakpoint");
        }
      }
    }
    line.changes.listen((_) => update());
    e.onClick.listen((event) {
      if (busy) {
        return;
      }
      busy = true;
      if (line.breakpoints == null) {
        // No breakpoint.  Add it.
        line.script.isolate.addBreakpoint(line.script, line.line)
          .catchError((e, st) {
            if (e is! ServerRpcException ||
                (e as ServerRpcException).code !=
                ServerRpcException.kCannotAddBreakpoint) {
              app.handleException(e, st);
            }})
          .whenComplete(() {
            busy = false;
            update();
          });
      } else {
        // Existing breakpoint.  Remove it.
        List pending = [];
        for (var bpt in line.breakpoints) {
          pending.add(line.script.isolate.removeBreakpoint(bpt));
        }
        Future.wait(pending).then((_) {
          busy = false;
          update();
        });
      }
      update();
    });
    update();
    return e;
  }

  Element lineNumberElement(ScriptLine line) {
    var lineNumber = line == null ? "..." : line.line;
    var e = span("$nbsp$lineNumber$nbsp");
    e.classes.add('noCopy');

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
      if (line.line == _currentLine) {
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

    // So blank lines are included when copying script to the clipboard.
    e.append(span('\n'));

    return e;
  }

  ScriptInsetElement.created()
      : super.created() {
    _updateTask = new Task(update);
  }
}

@CustomTag('source-inset')
class SourceInsetElement extends PolymerElement {
  SourceInsetElement.created() : super.created();

  @published SourceLocation location;
  @published String height = null;
  @published int currentPos;
  @published bool inDebuggerContext = false;
  @published ObservableList variables;
}

