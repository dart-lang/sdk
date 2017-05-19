// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'dart:async';
import 'dart:html';
import 'dart:svg';
import 'package:observatory/app.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart' as S;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/utils.dart';

class ScriptInsetElement extends HtmlElement implements Renderable {
  static const tag = const Tag<ScriptInsetElement>('script-inset');

  RenderingScheduler _r;

  Stream<RenderedEvent<ScriptInsetElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ScriptRef _script;
  M.Script _loadedScript;
  M.ScriptRepository _scripts;
  M.ObjectRepository _objects;
  M.EventRepository _events;
  StreamSubscription _subscription;
  int _startPos;
  int _endPos;
  int _currentPos;
  bool _inDebuggerContext;
  Iterable _variables;

  M.IsolateRef get isolate => _isolate;
  M.ScriptRef get script => _script;

  factory ScriptInsetElement(
      M.IsolateRef isolate,
      M.ScriptRef script,
      M.ScriptRepository scripts,
      M.ObjectRepository objects,
      M.EventRepository events,
      {int startPos,
      int endPos,
      int currentPos,
      bool inDebuggerContext: false,
      Iterable variables: const [],
      RenderingQueue queue}) {
    assert(isolate != null);
    assert(script != null);
    assert(scripts != null);
    assert(objects != null);
    assert(events != null);
    assert(inDebuggerContext != null);
    assert(variables != null);
    ScriptInsetElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._script = script;
    e._scripts = scripts;
    e._objects = objects;
    e._events = events;
    e._startPos = startPos;
    e._endPos = endPos;
    e._currentPos = currentPos;
    e._inDebuggerContext = inDebuggerContext;
    e._variables = new List.unmodifiable(variables);
    return e;
  }

  ScriptInsetElement.created() : super.created();

  bool get noSource => _startPos == -1;

  @override
  void attached() {
    super.attached();
    _r.enable();
    _subscription = _events.onDebugEvent
        .where((e) =>
            (e is M.BreakpointAddedEvent) ||
            (e is M.BreakpointResolvedEvent) ||
            (e is M.BreakpointRemovedEvent))
        .map((e) => e.breakpoint)
        .listen((M.Breakpoint b) {
      final loc = b.location;
      int line;
      if (loc.script.id == script.id) {
        if (loc.tokenPos != null) {
          line = _loadedScript.tokenToLine(loc.tokenPos);
        } else {
          line = loc.line;
        }
      } else {
        line = loc.line;
      }
      if ((line == null) || ((line >= _startLine) && (line <= _endLine))) {
        _r.dirty();
      }
    });
    _refresh();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
    _subscription.cancel();
  }

  void render() {
    if (noSource) {
      children = [new SpanElement()..text = 'No source'];
    } else if (_loadedScript == null) {
      children = [new SpanElement()..text = 'Loading...'];
    } else {
      final table = linesTable();
      var firstBuild = false;
      if (container == null) {
        // Indirect to avoid deleting the style element.
        container = new DivElement();

        firstBuild = true;
      }
      children = [container];
      container.children.clear();
      container.children.add(table);
      _makeCssClassUncopyable(table, "noCopy");
      if (firstBuild) {
        _scrollToCurrentPos();
      }
    }
  }

  Future _refresh() async {
    _loadedScript = await _scripts.get(_isolate, _script.id);
    await _refreshSourceReport();
    await _computeAnnotations();
    _r.dirty();
  }

  ButtonElement _refreshButton;
  ButtonElement _toggleProfileButton;

  int _currentLine;
  int _currentCol;
  int _startLine;
  int _endLine;

  Map<int, List<S.ServiceMap>> _rangeMap = {};
  Set _callSites = new Set<S.CallSite>();
  Set _possibleBreakpointLines = new Set<int>();
  Map<int, ScriptLineProfile> _profileMap = {};

  var _annotations = [];
  var _annotationsCursor;

  bool _includeProfile = false;

  String makeLineClass(int line) {
    return 'script-inset-line-$line';
  }

  void _scrollToCurrentPos() {
    var lines = getElementsByClassName(makeLineClass(_currentLine));
    if (lines.length > 0) {
      lines[0].scrollIntoView();
    }
  }

  Element a(String text) => new AnchorElement()..text = text;
  Element span(String text) => new SpanElement()..text = text;

  Element hitsCurrent(Element element) {
    element.classes.add('hitsCurrent');
    element.title = "";
    return element;
  }

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

  Element hitsCompiled(Element element) {
    element.classes.add('hitsCompiled');
    element.title = "Line in compiled function";
    return element;
  }

  Element hitsNotCompiled(Element element) {
    element.classes.add('hitsNotCompiled');
    element.title = "Line in uncompiled function";
    return element;
  }

  Element container;

  // Build _rangeMap and _callSites from a source report.
  Future _refreshSourceReport() async {
    if (noSource) return;

    var reports = [
      S.Isolate.kCallSitesReport,
      S.Isolate.kPossibleBreakpointsReport
    ];
    if (_includeProfile) {
      reports.add(S.Isolate.kProfileReport);
    }
    S.Isolate isolate = _isolate as S.Isolate;
    var sourceReport =
        await isolate.getSourceReport(reports, script, _startPos, _endPos);
    _possibleBreakpointLines =
        S.getPossibleBreakpointLines(sourceReport, script);
    _rangeMap.clear();
    _callSites.clear();
    _profileMap.clear();
    for (var range in sourceReport['ranges']) {
      int startLine = _loadedScript.tokenToLine(range['startPos']);
      int endLine = _loadedScript.tokenToLine(range['endPos']);
      // TODO(turnidge): Track down the root cause of null startLine/endLine.
      if ((startLine != null) && (endLine != null)) {
        for (var line = startLine; line <= endLine; line++) {
          var rangeList = _rangeMap[line];
          if (rangeList == null) {
            _rangeMap[line] = [range];
          } else {
            rangeList.add(range);
          }
        }
      }
      if (_includeProfile && range['profile'] != null) {
        List positions = range['profile']['positions'];
        List exclusiveTicks = range['profile']['exclusiveTicks'];
        List inclusiveTicks = range['profile']['inclusiveTicks'];
        int sampleCount = range['profile']['metadata']['sampleCount'];
        assert(positions.length == exclusiveTicks.length);
        assert(positions.length == inclusiveTicks.length);
        for (int i = 0; i < positions.length; i++) {
          if (positions[i] is String) {
            // String positions are classifying token positions.
            // TODO(johnmccutchan): Add classifier data to UI.
            continue;
          }
          int line = _loadedScript.tokenToLine(positions[i]);
          ScriptLineProfile lineProfile = _profileMap[line];
          if (lineProfile == null) {
            lineProfile = new ScriptLineProfile(line, sampleCount);
            _profileMap[line] = lineProfile;
          }
          lineProfile.process(exclusiveTicks[i], inclusiveTicks[i]);
        }
      }
      if (range['compiled']) {
        var rangeCallSites = range['callSites'];
        if (rangeCallSites != null) {
          for (var callSiteMap in rangeCallSites) {
            _callSites.add(new S.CallSite.fromMap(callSiteMap, script));
          }
        }
      }
    }
  }

  Future _computeAnnotations() async {
    _startLine = (_startPos != null
        ? _loadedScript.tokenToLine(_startPos)
        : 1 + _loadedScript.lineOffset);
    _currentLine =
        (_currentPos != null ? _loadedScript.tokenToLine(_currentPos) : null);
    _currentCol =
        (_currentPos != null ? (_loadedScript.tokenToCol(_currentPos)) : null);
    if (_currentCol != null) {
      _currentCol--; // make this 0-based.
    }

    S.Script script = _loadedScript as S.Script;

    _endLine = (_endPos != null
        ? _loadedScript.tokenToLine(_endPos)
        : script.lines.length + _loadedScript.lineOffset);

    if (_startLine == null || _endLine == null) {
      return;
    }

    _annotations.clear();

    addCurrentExecutionAnnotation();
    addBreakpointAnnotations();

    if (!_inDebuggerContext && script.library != null) {
      await loadDeclarationsOfLibrary(script.library);
      addLibraryAnnotations();
      addDependencyAnnotations();
      addPartAnnotations();
      addClassAnnotations();
      addFieldAnnotations();
      addFunctionAnnotations();
      addCallSiteAnnotations();
    }

    addLocalVariableAnnotations();

    _annotations.sort();
  }

  void addCurrentExecutionAnnotation() {
    if (_currentLine != null) {
      var a = new CurrentExecutionAnnotation(_isolate, _objects, _r.queue);
      a.line = _currentLine;
      a.columnStart = _currentCol;
      S.Script script = _loadedScript as S.Script;
      var length = script.guessTokenLength(_currentLine, _currentCol);
      if (length == null) {
        length = 1;
      }
      a.columnStop = _currentCol + length;
      _annotations.add(a);
    }
  }

  void addBreakpointAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var line = _startLine; line <= _endLine; line++) {
      var bpts = script.getLine(line).breakpoints;
      if (bpts != null) {
        for (var bpt in bpts) {
          if (bpt.location != null) {
            _annotations.add(
                new BreakpointAnnotation(_isolate, _objects, _r.queue, bpt));
          }
        }
      }
    }
  }

  Future loadDeclarationsOfLibrary(S.Library lib) {
    return lib.load().then((lib) {
      var loads = [];
      for (var func in lib.functions) {
        loads.add(func.load());
      }
      for (var field in lib.variables) {
        loads.add(field.load());
      }
      for (var cls in lib.classes) {
        loads.add(loadDeclarationsOfClass(cls));
      }
      return Future.wait(loads);
    });
  }

  Future loadDeclarationsOfClass(S.Class cls) {
    return cls.load().then((cls) {
      var loads = [];
      for (var func in cls.functions) {
        loads.add(func.load());
      }
      for (var field in cls.fields) {
        loads.add(field.load());
      }
      return Future.wait(loads);
    });
  }

  void addLibraryAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (S.ScriptLine line in script.lines) {
      // TODO(rmacnak): Use a real scanner.
      var pattern = new RegExp("library ${script.library.name}");
      var match = pattern.firstMatch(line.text);
      if (match != null) {
        var anno = new LibraryAnnotation(
            _isolate,
            _objects,
            _r.queue,
            _loadedScript.library,
            Uris.inspect(isolate, object: _loadedScript.library));
        anno.line = line.line;
        anno.columnStart = match.start + 8;
        anno.columnStop = match.end;
        _annotations.add(anno);
      }
      // TODO(rmacnak): Use a real scanner.
      pattern = new RegExp("part of ${script.library.name}");
      match = pattern.firstMatch(line.text);
      if (match != null) {
        var anno = new LibraryAnnotation(
            _isolate,
            _objects,
            _r.queue,
            _loadedScript.library,
            Uris.inspect(isolate, object: _loadedScript.library));
        anno.line = line.line;
        anno.columnStart = match.start + 8;
        anno.columnStop = match.end;
        _annotations.add(anno);
      }
    }
  }

  M.Library resolveDependency(String relativeUri) {
    S.Script script = _loadedScript as S.Script;
    // This isn't really correct: we need to ask the embedder to do the
    // uri canonicalization for us, but Observatory isn't in a position
    // to invoke the library tag handler. Handle the most common cases.
    var targetUri = Uri.parse(_loadedScript.library.uri).resolve(relativeUri);
    for (M.Library l in script.isolate.libraries) {
      if (targetUri.toString() == l.uri) {
        return l;
      }
    }
    if (targetUri.scheme == 'package') {
      targetUri = "packages/${targetUri.path}";
      for (M.Library l in script.isolate.libraries) {
        if (targetUri.toString() == l.uri) {
          return l;
        }
      }
    }

    print("Could not resolve library dependency: $relativeUri");
    return null;
  }

  void addDependencyAnnotations() {
    S.Script script = _loadedScript as S.Script;
    // TODO(rmacnak): Use a real scanner.
    var patterns = [
      new RegExp("import '(.*)'"),
      new RegExp('import "(.*)"'),
      new RegExp("export '(.*)'"),
      new RegExp('export "(.*)"'),
    ];
    for (S.ScriptLine line in script.lines) {
      for (var pattern in patterns) {
        var match = pattern.firstMatch(line.text);
        if (match != null) {
          M.Library target = resolveDependency(match[1]);
          if (target != null) {
            var anno = new LibraryAnnotation(_isolate, _objects, _r.queue,
                target, Uris.inspect(isolate, object: target));
            anno.line = line.line;
            anno.columnStart = match.start + 8;
            anno.columnStop = match.end - 1;
            _annotations.add(anno);
          }
        }
      }
    }
  }

  M.Script resolvePart(String relativeUri) {
    S.Script script = _loadedScript as S.Script;
    var rootUri = Uri.parse(script.library.uri);
    if (rootUri.scheme == 'dart') {
      // The relative paths from dart:* libraries to their parts are not valid.
      rootUri = new Uri.directory(script.library.uri);
    }
    var targetUri = rootUri.resolve(relativeUri);
    for (M.Script s in script.library.scripts) {
      if (targetUri.toString() == s.uri) {
        return s;
      }
    }
    print("Could not resolve part: $relativeUri");
    return null;
  }

  void addPartAnnotations() {
    S.Script script = _loadedScript as S.Script;
    // TODO(rmacnak): Use a real scanner.
    var patterns = [
      new RegExp("part '(.*)'"),
      new RegExp('part "(.*)"'),
    ];
    for (S.ScriptLine line in script.lines) {
      for (var pattern in patterns) {
        var match = pattern.firstMatch(line.text);
        if (match != null) {
          S.Script part = resolvePart(match[1]);
          if (part != null) {
            var anno = new PartAnnotation(_isolate, _objects, _r.queue, part,
                Uris.inspect(isolate, object: part));
            anno.line = line.line;
            anno.columnStart = match.start + 6;
            anno.columnStop = match.end - 1;
            _annotations.add(anno);
          }
        }
      }
    }
  }

  void addClassAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var cls in script.library.classes) {
      if ((cls.location != null) && (cls.location.script == script)) {
        var a = new ClassDeclarationAnnotation(_isolate, _objects, _r.queue,
            cls, Uris.inspect(isolate, object: cls));
        _annotations.add(a);
      }
    }
  }

  void addFieldAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var field in script.library.variables) {
      if ((field.location != null) && (field.location.script == script)) {
        var a = new FieldDeclarationAnnotation(_isolate, _objects, _r.queue,
            field, Uris.inspect(isolate, object: field));
        _annotations.add(a);
      }
    }
    for (var cls in script.library.classes) {
      for (var field in cls.fields) {
        if ((field.location != null) && (field.location.script == script)) {
          var a = new FieldDeclarationAnnotation(_isolate, _objects, _r.queue,
              field, Uris.inspect(isolate, object: field));
          _annotations.add(a);
        }
      }
    }
  }

  void addFunctionAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var func in script.library.functions) {
      if ((func.location != null) &&
          (func.location.script == script) &&
          (func.kind != M.FunctionKind.implicitGetter) &&
          (func.kind != M.FunctionKind.implicitSetter)) {
        // We annotate a field declaration with the field instead of the
        // implicit getter or setter.
        var a = new FunctionDeclarationAnnotation(_isolate, _objects, _r.queue,
            func, Uris.inspect(isolate, object: func));
        _annotations.add(a);
      }
    }
    for (var cls in script.library.classes) {
      S.Script script = _loadedScript as S.Script;
      for (var func in cls.functions) {
        if ((func.location != null) &&
            (func.location.script == script) &&
            (func.kind != M.FunctionKind.implicitGetter) &&
            (func.kind != M.FunctionKind.implicitSetter)) {
          // We annotate a field declaration with the field instead of the
          // implicit getter or setter.
          var a = new FunctionDeclarationAnnotation(_isolate, _objects,
              _r.queue, func, Uris.inspect(isolate, object: func));
          _annotations.add(a);
        }
      }
    }
  }

  void addCallSiteAnnotations() {
    for (var callSite in _callSites) {
      _annotations
          .add(new CallSiteAnnotation(_isolate, _objects, _r.queue, callSite));
    }
  }

  void addLocalVariableAnnotations() {
    S.Script script = _loadedScript as S.Script;
    // We have local variable information.
    if (_variables != null) {
      // For each variable.
      for (var variable in _variables) {
        // Find variable usage locations.
        var locations = script.scanForLocalVariableLocations(
            variable['name'], variable['_tokenPos'], variable['_endTokenPos']);

        // Annotate locations.
        for (var location in locations) {
          _annotations.add(new LocalVariableAnnotation(
              _isolate, _objects, _r.queue, location, variable['value']));
        }
      }
    }
  }

  ButtonElement _newRefreshButton() {
    var button = new ButtonElement();
    button.classes = ['refresh'];
    button.onClick.listen((_) async {
      button.disabled = true;
      await _refresh();
      button.disabled = false;
    });
    button.title = 'Refresh coverage';
    button.children = [_iconRefresh.clone(true)];
    return button;
  }

  ButtonElement _newToggleProfileButton() {
    ButtonElement button = new ButtonElement();
    button.classes =
        _includeProfile ? ['toggle-profile', 'enabled'] : ['toggle-profile'];
    button.title = 'Toggle CPU profile information';
    button.onClick.listen((_) async {
      _includeProfile = !_includeProfile;
      button.classes.toggle('enabled');
      button.disabled = true;
      _refresh();
      button.disabled = false;
    });
    button.children = [_iconWhatsHot.clone(true)];
    return button;
  }

  Element linesTable() {
    S.Script script = _loadedScript as S.Script;
    var table = new DivElement();
    table.classes.add("sourceTable");

    _refreshButton = _newRefreshButton();
    _toggleProfileButton = _newToggleProfileButton();
    table.append(_refreshButton);
    table.append(_toggleProfileButton);

    if (_startLine == null || _endLine == null) {
      return table;
    }

    var endLine = (_endPos != null
        ? _loadedScript.tokenToLine(_endPos)
        : script.lines.length + _loadedScript.lineOffset);
    var lineNumPad = endLine.toString().length;

    _annotationsCursor = 0;

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
            for (int j = firstBlank; j <= lastBlank; j++) {
              table.append(lineElement(script.getLine(j), lineNumPad));
            }
          } else {
            // Add an elipsis for the skipped region.
            table.append(lineElement(script.getLine(firstBlank), lineNumPad));
            table.append(lineElement(null, lineNumPad));
            table.append(lineElement(script.getLine(lastBlank), lineNumPad));
          }
          blankLineCount = 0;
        }
        table.append(lineElement(line, lineNumPad));
      }
    }

    return table;
  }

  // Assumes annotations are sorted.
  Annotation nextAnnotationOnLine(int line) {
    if (_annotationsCursor >= _annotations.length) return null;
    var annotation = _annotations[_annotationsCursor];

    // Fast-forward past any annotations before the first line that
    // we are displaying.
    while (annotation.line < line) {
      _annotationsCursor++;
      if (_annotationsCursor >= _annotations.length) return null;
      annotation = _annotations[_annotationsCursor];
    }

    // Next annotation is for a later line, don't advance past it.
    if (annotation.line != line) return null;
    _annotationsCursor++;
    return annotation;
  }

  Element lineElement(S.ScriptLine line, int lineNumPad) {
    var e = new DivElement();
    e.classes.add("sourceRow");
    e.append(lineBreakpointElement(line));
    e.append(lineNumberElement(line, lineNumPad));
    if (_includeProfile) {
      e.append(lineProfileElement(line, false));
      e.append(lineProfileElement(line, true));
    }
    e.append(lineSourceElement(line));
    return e;
  }

  Element lineProfileElement(S.ScriptLine line, bool self) {
    var e = span('');
    e.classes.add('noCopy');
    if (self) {
      e.title = 'Self %';
    } else {
      e.title = 'Total %';
    }

    if (line == null) {
      e.classes.add('notSourceProfile');
      e.text = nbsp;
      return e;
    }

    var ranges = _rangeMap[line.line];
    if ((ranges == null) || ranges.isEmpty) {
      e.classes.add('notSourceProfile');
      e.text = nbsp;
      return e;
    }

    ScriptLineProfile lineProfile = _profileMap[line.line];
    if (lineProfile == null) {
      e.classes.add('noProfile');
      e.text = nbsp;
      return e;
    }

    if (self) {
      e.text = lineProfile.formattedSelfTicks;
    } else {
      e.text = lineProfile.formattedTotalTicks;
    }

    if (lineProfile.isHot(self)) {
      e.classes.add('hotProfile');
    } else if (lineProfile.isMedium(self)) {
      e.classes.add('mediumProfile');
    } else {
      e.classes.add('coldProfile');
    }

    return e;
  }

  Element lineBreakpointElement(S.ScriptLine line) {
    var e = new DivElement();
    if (line == null || !_possibleBreakpointLines.contains(line.line)) {
      e.classes.add('noCopy');
      e.classes.add("emptyBreakpoint");
      e.text = nbsp;
      return e;
    }

    e.text = 'B';
    var busy = false;
    void update() {
      e.classes.clear();
      e.classes.add('noCopy');
      if (busy) {
        e.classes.add("busyBreakpoint");
      } else if (line.breakpoints != null) {
        bool resolved = false;
        for (var bpt in line.breakpoints) {
          if (bpt.resolved) {
            resolved = true;
            break;
          }
        }
        if (resolved) {
          e.classes.add("resolvedBreakpoint");
        } else {
          e.classes.add("unresolvedBreakpoint");
        }
      } else {
        e.classes.add("possibleBreakpoint");
      }
    }

    e.onClick.listen((event) {
      if (busy) {
        return;
      }
      busy = true;
      if (line.breakpoints == null) {
        // No breakpoint.  Add it.
        line.script.isolate
            .addBreakpoint(line.script, line.line)
            .catchError((e, st) {
          if (e is! S.ServerRpcException ||
              (e as S.ServerRpcException).code !=
                  S.ServerRpcException.kCannotAddBreakpoint) {
            ObservatoryApplication.app.handleException(e, st);
          }
        }).whenComplete(() {
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

  Element lineNumberElement(S.ScriptLine line, int lineNumPad) {
    var lineNumber = line == null ? "..." : line.line;
    var e = span("$nbsp${lineNumber.toString().padLeft(lineNumPad,nbsp)}$nbsp");
    e.classes.add('noCopy');
    if (lineNumber == _currentLine) {
      hitsCurrent(e);
      return e;
    }
    var ranges = _rangeMap[lineNumber];
    if ((ranges == null) || ranges.isEmpty) {
      // This line is not code.
      hitsUnknown(e);
      return e;
    }
    bool compiled = true;
    bool hasCallInfo = false;
    bool executed = false;
    for (var range in ranges) {
      if (range['compiled']) {
        for (var callSite in range['callSites']) {
          var callLine = line.script.tokenToLine(callSite['tokenPos']);
          if (lineNumber == callLine) {
            // The call site is on the current line.
            hasCallInfo = true;
            for (var cacheEntry in callSite['cacheEntries']) {
              if (cacheEntry['count'] > 0) {
                // If any call site on the line has been executed, we
                // mark the line as executed.
                executed = true;
                break;
              }
            }
          }
        }
      } else {
        // If any range isn't compiled, show the line as not compiled.
        // This is necessary so that nested functions appear to be uncompiled.
        compiled = false;
      }
    }
    if (executed) {
      hitsExecuted(e);
    } else if (hasCallInfo) {
      hitsNotExecuted(e);
    } else if (compiled) {
      hitsCompiled(e);
    } else {
      hitsNotCompiled(e);
    }
    return e;
  }

  Element lineSourceElement(S.ScriptLine line) {
    var e = new DivElement();
    e.classes.add("sourceItem");

    if (line != null) {
      e.classes.add(makeLineClass(line.line));
      if (line.line == _currentLine) {
        e.classes.add("currentLine");
      }

      var position = 0;
      consumeUntil(var stop) {
        if (stop <= position) {
          return null; // Empty gap between annotations/boundries.
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

  /// Exclude nodes from being copied, for example the line numbers and
  /// breakpoint toggles in script insets. Must be called after [root]'s
  /// children have been added, and only supports one node at a time.
  static void _makeCssClassUncopyable(Element root, String className) {
    var noCopyNodes = root.getElementsByClassName(className);
    for (var node in noCopyNodes) {
      node.style.setProperty('-moz-user-select', 'none');
      node.style.setProperty('-khtml-user-select', 'none');
      node.style.setProperty('-webkit-user-select', 'none');
      node.style.setProperty('-ms-user-select', 'none');
      node.style.setProperty('user-select', 'none');
    }
    root.onCopy.listen((event) {
      // Mark the nodes as hidden before the copy happens, then mark them as
      // visible on the next event loop turn.
      for (var node in noCopyNodes) {
        node.style.visibility = 'hidden';
      }
      Timer.run(() {
        for (var node in noCopyNodes) {
          node.style.visibility = 'visible';
        }
      });
    });
  }
}

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
    if (infoBox == null) buildInfoBox(); // Created lazily on the first click.
    infoBox.style.display = show ? 'block' : 'none';
    content.style.backgroundColor = show ? 'white' : originalBackground;
  });

  // Causes infoBox to be positioned relative to the bottom-left of content.
  content.style.display = 'inline-block';
  content.style.cursor = 'pointer';
}

void addLink(Element content, String target) {
  // Ick, destructive but still compatible with also adding an info box.
  var a = new AnchorElement(href: target);
  a.text = content.text;
  content.text = '';
  content.append(a);
}

abstract class Annotation implements Comparable<Annotation> {
  M.IsolateRef _isolate;
  M.ObjectRepository _objects;
  RenderingQueue queue;
  int line;
  int columnStart;
  int columnStop;
  int get priority;

  Annotation(this._isolate, this._objects, this.queue);

  void applyStyleTo(element);

  int compareTo(Annotation other) {
    if (line == other.line) {
      if (columnStart == other.columnStart) {
        return priority.compareTo(other.priority);
      }
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
    return anyRef(_isolate, object, _objects, queue: queue);
  }
}

class CurrentExecutionAnnotation extends Annotation {
  int priority = 0; // highest priority.

  CurrentExecutionAnnotation(
      M.IsolateRef isolate, M.ObjectRepository objects, RenderingQueue queue)
      : super(isolate, objects, queue);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.classes.add("currentCol");
    element.title = "Current execution";
  }
}

class BreakpointAnnotation extends Annotation {
  M.Breakpoint bpt;
  int priority = 1;

  BreakpointAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, this.bpt)
      : super(isolate, objects, queue) {
    var script = bpt.location.script;
    var location = bpt.location;
    if (location.tokenPos != null) {
      var pos = location.tokenPos;
      line = script.tokenToLine(pos);
      columnStart = script.tokenToCol(pos) - 1; // tokenToCol is 1-origin.
    } else if (location is M.UnresolvedSourceLocation) {
      line = location.line;
      columnStart = location.column;
      if (columnStart == null) {
        columnStart = 0;
      }
    }
    var length = script.guessTokenLength(line, columnStart);
    if (length == null) {
      length = 1;
    }
    columnStop = columnStart + length;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    var script = bpt.location.script;
    var pos = bpt.location.tokenPos;
    int line = script.tokenToLine(pos);
    int column = script.tokenToCol(pos);
    if (bpt.resolved) {
      element.classes.add("resolvedBreakAnnotation");
    } else {
      element.classes.add("unresolvedBreakAnnotation");
    }
    element.title = "Breakpoint ${bpt.number} at ${line}:${column}";
  }
}

class LibraryAnnotation extends Annotation {
  S.Library target;
  String url;
  int priority = 2;

  LibraryAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, this.target, this.url)
      : super(isolate, objects, queue);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.title = "library ${target.uri}";
    addLink(element, url);
  }
}

class PartAnnotation extends Annotation {
  S.Script part;
  String url;
  int priority = 2;

  PartAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, this.part, this.url)
      : super(isolate, objects, queue);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.title = "script ${part.uri}";
    addLink(element, url);
  }
}

class LocalVariableAnnotation extends Annotation {
  final value;
  int priority = 2;

  LocalVariableAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, S.LocalVarLocation location, this.value)
      : super(isolate, objects, queue) {
    line = location.line;
    columnStart = location.column;
    columnStop = location.endColumn;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "${value.shortName}";
  }
}

class CallSiteAnnotation extends Annotation {
  S.CallSite callSite;
  int priority = 2;

  CallSiteAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, this.callSite)
      : super(isolate, objects, queue) {
    line = callSite.line;
    columnStart = callSite.column - 1; // Call site is 1-origin.
    var tokenLength = callSite.script.guessTokenLength(line, columnStart);
    if (tokenLength == null) {
      tokenLength = callSite.name.length; // Approximate.
      if (callSite.name.startsWith("get:") || callSite.name.startsWith("set:"))
        tokenLength -= 4;
    }
    columnStop = columnStart + tokenLength;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
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
          if (entry.receiver == null) {
            r.append(cell(""));
          } else {
            r.append(cell(serviceRef(entry.receiver)));
          }
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
  String url;
  int priority = 2;

  DeclarationAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, decl, this.url)
      : super(isolate, objects, queue) {
    assert(decl.loaded);
    S.SourceLocation location = decl.location;
    if (location == null) {
      line = 0;
      columnStart = 0;
      columnStop = 0;
      return;
    }

    S.Script script = location.script;
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
  S.Class klass;

  ClassDeclarationAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, S.Class cls, String url)
      : klass = cls,
        super(isolate, objects, queue, cls, url);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.title = "class ${klass.name}";
    addLink(element, url);
  }
}

class FieldDeclarationAnnotation extends DeclarationAnnotation {
  S.Field field;

  FieldDeclarationAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue queue, S.Field fld, String url)
      : field = fld,
        super(isolate, objects, queue, fld, url);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    var tooltip = "field ${field.name}";
    element.title = tooltip;
    addLink(element, url);
  }
}

class FunctionDeclarationAnnotation extends DeclarationAnnotation {
  S.ServiceFunction function;

  FunctionDeclarationAnnotation(
      M.IsolateRef isolate,
      M.ObjectRepository objects,
      RenderingQueue queue,
      S.ServiceFunction func,
      String url)
      : function = func,
        super(isolate, objects, queue, func, url);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    var tooltip = "method ${function.name}";
    if (function.isOptimizable == false) {
      tooltip += "\nUnoptimizable!";
    }
    if (function.isInlinable == false) {
      tooltip += "\nNot inlinable!";
    }
    if (function.deoptimizations > 0) {
      tooltip += "\nDeoptimized ${function.deoptimizations} times!";
    }
    element.title = tooltip;

    if (function.isOptimizable == false ||
        function.isInlinable == false ||
        function.deoptimizations > 0) {
      element.style.backgroundColor = "#EEA7A7"; // Low-saturation red.
    }

    addLink(element, url);
  }
}

class ScriptLineProfile {
  ScriptLineProfile(this.line, this.sampleCount);

  static const kHotThreshold = 0.05; // 5%.
  static const kMediumThreshold = 0.02; // 2%.

  final int line;
  final int sampleCount;

  int selfTicks = 0;
  int totalTicks = 0;

  void process(int exclusive, int inclusive) {
    selfTicks += exclusive;
    totalTicks += inclusive;
  }

  String get formattedSelfTicks {
    return Utils.formatPercent(selfTicks, sampleCount);
  }

  String get formattedTotalTicks {
    return Utils.formatPercent(totalTicks, sampleCount);
  }

  double _percent(bool self) {
    if (sampleCount == 0) {
      return 0.0;
    }
    if (self) {
      return selfTicks / sampleCount;
    } else {
      return totalTicks / sampleCount;
    }
  }

  bool isHot(bool self) => _percent(self) > kHotThreshold;
  bool isMedium(bool self) => _percent(self) > kMediumThreshold;
}

final SvgSvgElement _iconRefresh = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute(
          'd',
          'M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 '
          '3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 '
          '7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 '
          '0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 '
          '1.78L13 11h7V4l-2.35 2.35z')
  ];

final SvgSvgElement _iconWhatsHot = new SvgSvgElement()
  ..setAttribute('width', '24')
  ..setAttribute('height', '24')
  ..children = [
    new PathElement()
      ..setAttribute(
          'd',
          'M13.5.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 '
          '3.73-2.07 0-3.63-1.67-3.63-3.73l.03-.36C5.21 7.51 '
          '4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 '
          '17.41 3.8 13.5.67zM11.71 19c-1.78 '
          '0-3.22-1.4-3.22-3.14 0-1.62 1.05-2.76 2.81-3.12 '
          '1.77-.36 3.6-1.21 4.62-2.58.39 1.29.59 2.65.59 '
          '4.04 0 2.65-2.15 4.8-4.8 4.8z')
  ];
