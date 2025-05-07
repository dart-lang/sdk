// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_inset_element;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/app.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart' as S;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class ScriptInsetElement extends CustomElement implements Renderable {
  late RenderingScheduler<ScriptInsetElement> _r;

  Stream<RenderedEvent<ScriptInsetElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ScriptRef _script;
  M.Script? _loadedScript;
  late M.ScriptRepository _scripts;
  late M.ObjectRepository _objects;
  late M.EventRepository _events;
  late StreamSubscription _subscription;
  int? _startPos;
  int? _endPos;
  int? _currentPos;
  late bool _inDebuggerContext;
  Iterable? _variables;

  M.IsolateRef get isolate => _isolate;
  M.ScriptRef get script => _script;

  factory ScriptInsetElement(
      M.IsolateRef isolate,
      M.ScriptRef script,
      M.ScriptRepository scripts,
      M.ObjectRepository objects,
      M.EventRepository events,
      {int? startPos,
      int? endPos,
      int? currentPos,
      bool inDebuggerContext = false,
      Iterable variables = const [],
      RenderingQueue? queue}) {
    ScriptInsetElement e = new ScriptInsetElement.created();
    e._r = new RenderingScheduler<ScriptInsetElement>(e, queue: queue);
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

  ScriptInsetElement.created() : super.created('script-inset');

  bool get noSource => _startPos == -1 || _loadedScript!.source == null;

  @override
  void attached() {
    super.attached();
    _r.enable();
    _subscription = _events.onDebugEvent
        .where((e) => e is M.BreakpointEvent)
        .map((e) => (e as M.BreakpointEvent).breakpoint)
        .listen((M.Breakpoint b) async {
      final M.Location loc = b.location!;
      int? line;
      if (loc.script!.id == script.id) {
        if (loc.tokenPos != null) {
          line = _loadedScript!.tokenToLine(loc.tokenPos!);
        } else {
          line = (loc as dynamic).line;
        }
      } else {
        try {
          line = (loc as dynamic).line;
        } on NoSuchMethodError {
          if (loc.tokenPos != null) {
            M.Script scriptUsed = await _scripts.get(_isolate, loc.script!.id!);
            line = scriptUsed.tokenToLine(loc.tokenPos!);
          }
        }
      }
      if ((line == null) || ((line >= _startLine!) && (line <= _endLine!))) {
        _r.dirty();
      }
    });
    _refresh();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
    _subscription.cancel();
  }

  void render() {
    if (_loadedScript == null) {
      children = <HTMLElement>[
        new HTMLSpanElement()..textContent = 'Loading...'
      ];
    } else if (noSource) {
      children = <HTMLElement>[
        new HTMLSpanElement()..textContent = 'No source'
      ];
    } else {
      final table = linesTable();
      var firstBuild = false;
      if (container == null) {
        // Indirect to avoid deleting the style element.
        container = new HTMLDivElement();

        firstBuild = true;
      }
      children = <HTMLElement>[container!];
      container!
        ..removeChildren()
        ..appendChild(table);
      _makeCssClassUncopyable(table, "noCopy");
      if (firstBuild) {
        _scrollToCurrentPos();
      }
    }
  }

  Future _refresh() async {
    _loadedScript = await _scripts.get(_isolate, _script.id!);
    await _refreshSourceReport();
    await _computeAnnotations();
    _r.dirty();
  }

  HTMLButtonElement? _refreshButton;
  HTMLButtonElement? _toggleProfileButton;

  int? _currentLine;
  int? _currentCol;
  int? _startLine;
  int? _endLine;

  Map/*<int, List<S.ServiceMap>>*/ _rangeMap = {};
  Set _callSites = new Set<S.CallSite>();
  Set _possibleBreakpointLines = new Set<int>();
  Map<int, ScriptLineProfile> _profileMap = {};

  var _annotations = [];
  var _annotationsCursor;

  bool _includeProfile = false;

  String makeLineClass(int? line) {
    return 'script-inset-line-$line';
  }

  void _scrollToCurrentPos() {
    final lines = getElementsByClassName(makeLineClass(_currentLine));
    if (lines.length > 0) {
      lines.item(0)!.scrollIntoView();
    }
  }

  HTMLElement a(String text) => new HTMLAnchorElement()..textContent = text;
  HTMLElement span(String text) => new HTMLSpanElement()..textContent = text;

  HTMLElement hitsCurrent(HTMLElement element) {
    element.className += ' hitsCurrent';
    element.title = "";
    return element;
  }

  HTMLElement hitsUnknown(HTMLElement element) {
    element.className += ' hitsNone';
    element.title = "";
    return element;
  }

  HTMLElement hitsNotExecuted(HTMLElement element) {
    element.className += ' hitsNotExecuted';
    element.title = "Line did not execute";
    return element;
  }

  HTMLElement hitsExecuted(HTMLElement element) {
    element.className += ' hitsExecuted';
    element.title = "Line did execute";
    return element;
  }

  HTMLElement hitsCompiled(HTMLElement element) {
    element.className += ' hitsCompiled';
    element.title = "Line in compiled function";
    return element;
  }

  HTMLElement hitsNotCompiled(HTMLElement element) {
    element.className += ' hitsNotCompiled';
    element.title = "Line in uncompiled function";
    return element;
  }

  HTMLElement? container;

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
    dynamic sourceReport = await isolate.getSourceReport(
        reports, script as S.Script, _startPos, _endPos);
    _possibleBreakpointLines =
        S.getPossibleBreakpointLines(sourceReport, script as S.Script);
    _rangeMap.clear();
    _callSites.clear();
    _profileMap.clear();
    for (var range in sourceReport['ranges']) {
      int? startLine = _loadedScript!.tokenToLine(range['startPos']);
      int? endLine = _loadedScript!.tokenToLine(range['endPos']);
      // TODO(turnidge): Track down the root cause of null startLine/endLine.
      if ((startLine != null) && (endLine != null)) {
        for (var line = startLine; line <= endLine; line++) {
          final rangeList = _rangeMap[line];
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
          int? line = _loadedScript!.tokenToLine(positions[i]);
          ScriptLineProfile? lineProfile = _profileMap[line];
          if (lineProfile == null) {
            lineProfile = new ScriptLineProfile(line!, sampleCount);
            _profileMap[line] = lineProfile;
          }
          lineProfile.process(exclusiveTicks[i], inclusiveTicks[i]);
        }
      }
      if (range['compiled']) {
        var rangeCallSites = range['callSites'];
        if (rangeCallSites != null) {
          for (var callSiteMap in rangeCallSites) {
            _callSites
                .add(new S.CallSite.fromMap(callSiteMap, script as S.Script));
          }
        }
      }
    }
  }

  Future _computeAnnotations() async {
    if (noSource) return;

    _startLine = (_startPos != null
        ? _loadedScript!.tokenToLine(_startPos!)
        : 1 + _loadedScript!.lineOffset!);
    _currentLine =
        (_currentPos != null ? _loadedScript!.tokenToLine(_currentPos!) : null);
    _currentCol = (_currentPos != null
        ? (_loadedScript!.tokenToCol(_currentPos!))
        : null);
    if (_currentCol != null) {
      _currentCol = _currentCol! - 1; // make this 0-based.
    }

    S.Script script = _loadedScript as S.Script;

    _endLine = (_endPos != null
        ? _loadedScript!.tokenToLine(_endPos!)
        : script.lines.length + _loadedScript!.lineOffset!);

    if (_startLine == null || _endLine == null) {
      return;
    }

    _annotations.clear();

    addCurrentExecutionAnnotation();
    addBreakpointAnnotations();

    if (!_inDebuggerContext && script.library != null) {
      await loadDeclarationsOfLibrary(script.library!);
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
      a.line = _currentLine!;
      a.columnStart = _currentCol!;
      S.Script script = _loadedScript as S.Script;
      var length = script.guessTokenLength(_currentLine!, _currentCol!);
      if (length == null) {
        length = 1;
      }
      a.columnStop = _currentCol! + length;
      _annotations.add(a);
    }
  }

  void addBreakpointAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var line = _startLine!; line <= _endLine!; line++) {
      var bpts = script.getLine(line)!.breakpoints;
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
    return lib.load().then((serviceObject) {
      S.Library lib = serviceObject as S.Library;
      var loads = <Future>[];
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
    return cls.load().then((serviceObject) {
      S.Class cls = serviceObject as S.Class;
      var loads = <Future>[];
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
      var pattern = new RegExp("library ${script.library!.name!}");
      var match = pattern.firstMatch(line.text);
      if (match != null) {
        var anno = new LibraryAnnotation(
            _isolate,
            _objects,
            _r.queue,
            _loadedScript!.library as S.Library,
            Uris.inspect(isolate, object: _loadedScript!.library));
        anno.line = line.line;
        anno.columnStart = match.start + 8;
        anno.columnStop = match.end;
        _annotations.add(anno);
      }
      // TODO(rmacnak): Use a real scanner.
      pattern = new RegExp("part of ${script.library!.name!}");
      match = pattern.firstMatch(line.text);
      if (match != null) {
        var anno = new LibraryAnnotation(
            _isolate,
            _objects,
            _r.queue,
            _loadedScript!.library as S.Library,
            Uris.inspect(isolate, object: _loadedScript!.library));
        anno.line = line.line;
        anno.columnStart = match.start + 8;
        anno.columnStop = match.end;
        _annotations.add(anno);
      }
    }
  }

  S.Library? resolveDependency(String relativeUri) {
    S.Script script = _loadedScript as S.Script;
    // This isn't really correct: we need to ask the embedder to do the
    // uri canonicalization for us, but Observatory isn't in a position
    // to invoke the library tag handler. Handle the most common cases.
    var targetUri =
        Uri.parse(_loadedScript!.library!.uri!).resolve(relativeUri);
    for (M.Library l in script.isolate!.libraries) {
      if (targetUri.toString() == l.uri) {
        return l as S.Library;
      }
    }
    if (targetUri.isScheme('package')) {
      var targetUriString = "packages/${targetUri.path}";
      for (M.Library l in script.isolate!.libraries) {
        if (targetUriString == l.uri) {
          return l as S.Library;
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
          M.Library? target = resolveDependency(match[1]!);
          if (target != null) {
            var anno = new LibraryAnnotation(_isolate, _objects, _r.queue,
                target as S.Library, Uris.inspect(isolate, object: target));
            anno.line = line.line;
            anno.columnStart = match.start + 8;
            anno.columnStop = match.end - 1;
            _annotations.add(anno);
          }
        }
      }
    }
  }

  S.Script? resolvePart(String relativeUri) {
    S.Script script = _loadedScript as S.Script;
    var rootUri = Uri.parse(script.library!.uri!);
    if (rootUri.isScheme('dart')) {
      // The relative paths from dart:* libraries to their parts are not valid.
      rootUri = Uri.parse(script.library!.uri! + '/');
    }
    var targetUri = rootUri.resolve(relativeUri);
    for (M.Script s in script.library!.scripts) {
      if (targetUri.toString() == s.uri) {
        return s as S.Script?;
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
          S.Script? part = resolvePart(match[1]!);
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
    for (var cls in script.library!.classes) {
      if ((cls.location != null) && (cls.location!.script == script)) {
        var a = new ClassDeclarationAnnotation(_isolate, _objects, _r.queue,
            cls, Uris.inspect(isolate, object: cls));
        _annotations.add(a);
      }
    }
  }

  void addFieldAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var field in script.library!.variables) {
      if ((field.location != null) && (field.location!.script == script)) {
        var a = new FieldDeclarationAnnotation(_isolate, _objects, _r.queue,
            field, Uris.inspect(isolate, object: field));
        _annotations.add(a);
      }
    }
    for (var cls in script.library!.classes) {
      for (var field in cls.fields) {
        if ((field.location != null) && (field.location!.script == script)) {
          var a = new FieldDeclarationAnnotation(_isolate, _objects, _r.queue,
              field, Uris.inspect(isolate, object: field));
          _annotations.add(a);
        }
      }
    }
  }

  void addFunctionAnnotations() {
    S.Script script = _loadedScript as S.Script;
    for (var func in script.library!.functions) {
      if ((func.location != null) &&
          (func.location!.script == script) &&
          (func.kind != M.FunctionKind.implicitGetter) &&
          (func.kind != M.FunctionKind.implicitSetter)) {
        // We annotate a field declaration with the field instead of the
        // implicit getter or setter.
        var a = new FunctionDeclarationAnnotation(_isolate, _objects, _r.queue,
            func, Uris.inspect(isolate, object: func));
        _annotations.add(a);
      }
    }
    for (var cls in script.library!.classes) {
      S.Script script = _loadedScript as S.Script;
      for (var func in cls.functions) {
        if ((func.location != null) &&
            (func.location!.script == script) &&
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
      for (var variable in _variables!) {
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

  HTMLButtonElement _newRefreshButton() {
    var button = new HTMLButtonElement();
    button.className = 'refresh';
    button.onClick.listen((_) async {
      button.disabled = true;
      await _refresh();
      button.disabled = false;
    });
    button.title = 'Refresh coverage';
    button.appendChild(HTMLSpanElement()..textContent = "↻");
    return button;
  }

  HTMLButtonElement _newToggleProfileButton() {
    HTMLButtonElement button = new HTMLButtonElement();
    button.className =
        _includeProfile ? 'toggle-profile enabled' : 'toggle-profile';
    button.title = 'Toggle CPU profile information';
    button.onClick.listen((_) async {
      _includeProfile = !_includeProfile;
      toggleClass(button, ' enabled');
      button.disabled = true;
      _refresh();
      button.disabled = false;
    });
    button.appendChild(HTMLSpanElement()..textContent = "🔥");
    return button;
  }

  HTMLElement linesTable() {
    S.Script script = _loadedScript as S.Script;
    var table = new HTMLDivElement();
    table.className += " sourceTable";

    _refreshButton = _newRefreshButton();
    _toggleProfileButton = _newToggleProfileButton();
    table.append(_refreshButton!);
    table.append(_toggleProfileButton!);

    if (_startLine == null || _endLine == null) {
      return table;
    }

    var endLine = (_endPos != null
        ? _loadedScript!.tokenToLine(_endPos!)
        : script.lines.length + _loadedScript!.lineOffset!);
    var lineNumPad = endLine.toString().length;

    _annotationsCursor = 0;

    int blankLineCount = 0;
    for (int i = _startLine!; i <= _endLine!; i++) {
      var line = script.getLine(i)!;
      if (line.isBlank) {
        // Try to introduce ellipses if there are 4 or more contiguous
        // blank lines.
        blankLineCount++;
      } else {
        if (blankLineCount > 0) {
          int firstBlank = i - blankLineCount;
          int lastBlank = i - 1;
          if (blankLineCount < 4) {
            // Too few blank lines for an ellipsis.
            for (int j = firstBlank; j <= lastBlank; j++) {
              table.append(lineElement(script.getLine(j), lineNumPad));
            }
          } else {
            // Add an ellipsis for the skipped region.
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
  Annotation? nextAnnotationOnLine(int line) {
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

  HTMLElement lineElement(S.ScriptLine? line, int lineNumPad) {
    var e = new HTMLDivElement();
    e.className += " sourceRow";
    e.append(lineBreakpointElement(line));
    e.append(lineNumberElement(line, lineNumPad));
    if (_includeProfile) {
      e.append(lineProfileElement(line, false));
      e.append(lineProfileElement(line, true));
    }
    e.append(lineSourceElement(line));
    return e;
  }

  HTMLElement lineProfileElement(S.ScriptLine? line, bool self) {
    var e = span('');
    e.className += ' noCopy';
    if (self) {
      e.title = 'Self %';
    } else {
      e.title = 'Total %';
    }

    if (line == null) {
      e.className += ' notSourceProfile';
      e.textContent = nbsp;
      return e;
    }

    var ranges = _rangeMap[line.line];
    if ((ranges == null) || ranges.isEmpty) {
      e.className += ' notSourceProfile';
      e.textContent = nbsp;
      return e;
    }

    ScriptLineProfile? lineProfile = _profileMap[line.line];
    if (lineProfile == null) {
      e.className += ' noProfile';
      e.textContent = nbsp;
      return e;
    }

    if (self) {
      e.textContent = lineProfile.formattedSelfTicks;
    } else {
      e.textContent = lineProfile.formattedTotalTicks;
    }

    if (lineProfile.isHot(self)) {
      e.className += ' hotProfile';
    } else if (lineProfile.isMedium(self)) {
      e.className += ' mediumProfile';
    } else {
      e.className += ' coldProfile';
    }

    return e;
  }

  HTMLElement lineBreakpointElement(S.ScriptLine? line) {
    var e = new HTMLDivElement();
    if (line == null || !_possibleBreakpointLines.contains(line.line)) {
      e.className += ' noCopy';
      e.className += ' emptyBreakpoint';
      e.textContent = nbsp;
      return e;
    }

    e.textContent = 'B';
    var busy = false;
    void update() {
      e.className += ' noCopy';
      if (busy) {
        e.className += ' busyBreakpoint';
      } else if (line.breakpoints != null) {
        bool resolved = false;
        for (var bpt in line.breakpoints!) {
          if (bpt.resolved!) {
            resolved = true;
            break;
          }
        }
        if (resolved) {
          e.className += ' resolvedBreakpoint';
        } else {
          e.className += ' unresolvedBreakpoint';
        }
      } else {
        e.className += ' possibleBreakpoint';
      }
    }

    e.onClick.listen((event) {
      if (busy) {
        return;
      }
      busy = true;
      if (line.breakpoints == null) {
        // No breakpoint.  Add it.
        line.script.isolate!.addBreakpoint(line.script, line.line).then((_) {},
            onError: (e, st) {
          if (e is! S.ServerRpcException ||
              e.code != S.ServerRpcException.kCannotAddBreakpoint) {
            ObservatoryApplication.app.handleException(e, st);
          }
        }).whenComplete(() {
          busy = false;
          update();
        });
      } else {
        // Existing breakpoint.  Remove it.
        List<Future> pending = [];
        for (var bpt in line.breakpoints!) {
          pending.add(line.script.isolate!.removeBreakpoint(bpt));
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

  HTMLElement lineNumberElement(S.ScriptLine? line, int lineNumPad) {
    var lineNumber = line == null ? "..." : line.line;
    var e =
        span("$nbsp${lineNumber.toString().padLeft(lineNumPad, nbsp)}$nbsp");
    e.className += ' noCopy';
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
          var callLine = line!.script.tokenToLine(callSite['tokenPos']);
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

  HTMLElement lineSourceElement(S.ScriptLine? line) {
    var e = new HTMLDivElement();
    e.className += ' sourceItem';

    if (line != null) {
      e.className += ' ' + makeLineClass(line.line);
      if (line.line == _currentLine) {
        e.className += ' currentLine';
      }

      var position = 0;
      consumeUntil(var stop) {
        if (stop <= position) {
          return null; // Empty gap between annotations/boundaries.
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
      var annotation = nextAnnotationOnLine(line.line);
      while (annotation != null) {
        consumeUntil(annotation.columnStart);
        annotation.applyStyleTo(consumeUntil(annotation.columnStop));
        annotation = nextAnnotationOnLine(line.line);
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
  static void _makeCssClassUncopyable(HTMLElement root, String className) {
    final HTMLCollection noCopyNodes = root.getElementsByClassName(className);
    for (int i = 0; i < noCopyNodes.length; i++) {
      var node = noCopyNodes.item(i) as HTMLElement;
      node.style.setProperty('-moz-user-select', 'none');
      node.style.setProperty('-khtml-user-select', 'none');
      node.style.setProperty('-webkit-user-select', 'none');
      node.style.setProperty('-ms-user-select', 'none');
      node.style.setProperty('user-select', 'none');
    }
    root.onCopy.listen((event) {
      // Mark the nodes as hidden before the copy happens, then mark them as
      // visible on the next event loop turn.
      for (int i = 0; i < noCopyNodes.length; i++) {
        final HTMLElement node = noCopyNodes.item(i) as HTMLElement;
        node.style.visibility = 'hidden';
      }
      Timer.run(() {
        for (int i = 0; i < noCopyNodes.length; i++) {
          final HTMLElement node = noCopyNodes.item(i) as HTMLElement;
          node.style.visibility = 'visible';
        }
      });
    });
  }
}

const nbsp = "\u00A0";

void addInfoBox(HTMLElement content, HTMLElement infoBoxGenerator ()) {
  var show = false;
  final originalBackground = content.style.backgroundColor;
  late HTMLElement infoBox = () {
    final infoBox = infoBoxGenerator();
    infoBox.style.position = 'absolute';
    infoBox.style.padding = '1em';
    infoBox.style.border = 'solid black 2px';
    infoBox.style.zIndex = '10';
    infoBox.style.backgroundColor = 'white';
    infoBox.style.cursor = 'auto';
    // Don't inherit pre formatting from the script lines.
    infoBox.style.whiteSpace = 'normal';
    content.append(infoBox);
    return infoBox;
  } ();

  content.onClick.listen((event) {
    show = !show;
    infoBox.style.display = show ? 'block' : 'none';
    content.style.backgroundColor = show ? 'white' : originalBackground;
  });

  // Causes infoBox to be positioned relative to the bottom-left of content.
  content.style.display = 'inline-block';
  content.style.cursor = 'pointer';
}

void addLink(HTMLElement content, String target) {
  // Ick, destructive but still compatible with also adding an info box.
  var a = new HTMLAnchorElement()..href = target;
  a.textContent = content.textContent;
  content.textContent = '';
  content.append(a);
}

abstract class Annotation implements Comparable<Annotation> {
  M.IsolateRef _isolate;
  M.ObjectRepository _objects;
  RenderingQueue? queue;
  int? line;
  int? columnStart;
  int? columnStop;
  int get priority;

  Annotation(this._isolate, this._objects, this.queue);

  void applyStyleTo(HTMLElement? element);

  int compareTo(Annotation other) {
    if (line == other.line) {
      if (columnStart == other.columnStart) {
        return priority.compareTo(other.priority);
      }
      return columnStart!.compareTo(other.columnStart!);
    }
    return line!.compareTo(other.line!);
  }

  HTMLElement table() {
    return HTMLDivElement()
      ..style.display = "table"
      ..style.color = "#333"
      ..style.font = "400 14px 'Montserrat', sans-serif";
  }

  HTMLElement row([content]) {
    final e = HTMLDivElement()
      ..style.display = "table-row";
    if (content is String) e.textContent = content;
    if (content is HTMLElement) e.appendChild(content);
    return e;
  }

  HTMLElement cell(content) {
    final e = HTMLDivElement()
      ..style.display = 'table-cell'
      ..style.padding = '3px';
    if (content is String) e.textContent = content;
    if (content is HTMLElement) e.appendChild(content);
    return e;
  }

  HTMLElement serviceRef(object) {
    return anyRef(_isolate, object, _objects, queue: queue);
  }
}

class CurrentExecutionAnnotation extends Annotation {
  int priority = 0; // highest priority.

  CurrentExecutionAnnotation(
      M.IsolateRef isolate, M.ObjectRepository objects, RenderingQueue? queue)
      : super(isolate, objects, queue);

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.className += ' currentCol';
    element.title = 'Current execution';
  }
}

class BreakpointAnnotation extends Annotation {
  M.Breakpoint bpt;
  int priority = 1;

  BreakpointAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue? queue, this.bpt)
      : super(isolate, objects, queue) {
    S.Script script = bpt.location!.script as S.Script;
    var location = bpt.location!;
    if (location.tokenPos != null) {
      var pos = location.tokenPos!;
      line = script.tokenToLine(pos);
      columnStart = script.tokenToCol(pos)! - 1; // tokenToCol is 1-origin.
    } else if (location is M.UnresolvedSourceLocation) {
      line = location.line!;
      columnStart = location.column ?? 0;
    }
    var length = script.guessTokenLength(line!, columnStart!);
    if (length == null) {
      length = 1;
    }
    columnStop = columnStart! + length;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    S.Script script = bpt.location!.script as S.Script;
    int? pos = bpt.location!.tokenPos;
    int? line = script.tokenToLine(pos);
    int? column = script.tokenToCol(pos);
    if (bpt.resolved!) {
      element.className += ' resolvedBreakAnnotation';
    } else {
      element.className += ' unresolvedBreakAnnotation';
    }
    element.title = 'Breakpoint ${bpt.number} at ${line}:${column}';
  }
}

class LibraryAnnotation extends Annotation {
  S.Library target;
  String url;
  int priority = 2;

  LibraryAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue? queue, this.target, this.url)
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
      RenderingQueue? queue, this.part, this.url)
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
      RenderingQueue? queue, S.LocalVarLocation location, this.value)
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
      RenderingQueue? queue, this.callSite)
      : super(isolate, objects, queue) {
    line = callSite.line;
    columnStart = callSite.column - 1; // Call site is 1-origin.
    var tokenLength = callSite.script.guessTokenLength(line!, columnStart!);
    if (tokenLength == null) {
      tokenLength = callSite.name.length; // Approximate.
      if (callSite.name.startsWith("get:") || callSite.name.startsWith("set:"))
        tokenLength -= 4;
    }
    columnStop = columnStart! + tokenLength;
  }

  void applyStyleTo(element) {
    if (element == null) {
      return; // TODO(rmacnak): Handling overlapping annotations.
    }
    element.style.fontWeight = "bold";
    element.title = "Call site: ${callSite.name}";

    addInfoBox(element, () {
      final HTMLElement details = table();
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
      RenderingQueue? queue, decl, this.url)
      : super(isolate, objects, queue) {
    assert(decl.loaded);
    S.SourceLocation location = decl.location;
    S.Script script = location.script;
    line = script.tokenToLine(location.tokenPos);
    columnStart = script.tokenToCol(location.tokenPos);
    if ((line == null) || (columnStart == null)) {
      line = 0;
      columnStart = 0;
      columnStop = 0;
    } else {
      columnStart = columnStart! - 1; // 1-origin -> 0-origin.

      // The method's token position is at the beginning of the method
      // declaration, which may be a return type annotation, metadata, static
      // modifier, etc. Try to scan forward to position this annotation on the
      // function's name instead.
      var lineSource = script.getLine(line!)!.text;
      var betterStart = lineSource.indexOf(decl.name, columnStart!);
      if (betterStart != -1) {
        columnStart = betterStart;
      }
      columnStop = columnStart! + (decl.name.length as int);
    }
  }
}

class ClassDeclarationAnnotation extends DeclarationAnnotation {
  S.Class klass;

  ClassDeclarationAnnotation(M.IsolateRef isolate, M.ObjectRepository objects,
      RenderingQueue? queue, S.Class cls, String url)
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
      RenderingQueue? queue, S.Field fld, String url)
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
      RenderingQueue? queue,
      S.ServiceFunction func,
      String url)
      : function = func,
        super(isolate, objects, queue, func, url);

  void applyStyleTo(HTMLElement? element) {
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
    if (function.deoptimizations! > 0) {
      tooltip += "\nDeoptimized ${function.deoptimizations} times!";
    }
    element.title = tooltip;

    if (function.isOptimizable == false ||
        function.isInlinable == false ||
        function.deoptimizations! > 0) {
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
