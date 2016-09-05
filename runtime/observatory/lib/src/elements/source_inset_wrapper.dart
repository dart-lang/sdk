// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/service_html.dart' show SourceLocation;
import 'package:observatory/src/elements/script_inset.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class SourceInsetElementWrapper extends HtmlElement {
  static const binder = const Binder<SourceInsetElementWrapper>(const {
      'location': #location, 'currentpos': #currentPos,
      'indebuggercontext': #inDebuggerContext, 'variables': #variables
    });

  static const tag = const Tag<SourceInsetElementWrapper>('source-inset');

  SourceLocation _location;
  int _currentPos;
  bool _inDebuggerContext;
  Iterable _variables;

  SourceLocation get location => _location;
  int get currentPos => _currentPos;
  bool get inDebuggerContext => _inDebuggerContext;
  Iterable get variables => _variables;

  set location(SourceLocation value) {
    _location = value;
    render();
  }
  set currentPos(int value) {
    _currentPos = value;
    render();
  }
  set inDebuggerContext(bool value) {
    _inDebuggerContext = value;
    render();
  }
  set variables(Iterable value) {
    _variables = value;
    render();
  }

  SourceInsetElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  Future render() async {
    shadowRoot.children = [];
    if (_location == null) {
      return;
    }

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        script-inset-wrapped {
          position: relative;
        }
        script-inset-wrapped button.refresh,
        script-inset-wrapped button.toggle-profile {
          background-color: transparent;
          padding: 0;
          margin: 0;
          border: none;
          position: absolute;
          display: inline-block;
          top: 5px;
          color: #888888;
          line-height: 30px;
          font: 400 20px 'Montserrat', sans-serif;
        }
        script-inset-wrapped button.refresh {
          right: 5px;
          font-size: 25px;
        }
        script-inset-wrapped button.toggle-profile {
          right: 30px;
          font-size: 20px;
        }
        script-inset-wrapped button.toggle-profile.enabled {
          color: #BB3322;
        }
        script-inset-wrapped a {
          color: #0489c3;
          text-decoration: none;
        }
        script-inset-wrapped a:hover {
          text-decoration: underline;
        }
        script-inset-wrapped .sourceInset {
        }
        script-inset-wrapped .sourceTable {
          position: relative;
          background-color: #f5f5f5;
          border: 1px solid #ccc;
          padding: 10px;
          width: 100%;
          box-sizing: border-box;
          overflow-x: scroll;
        }
        script-inset-wrapped .sourceRow {
          display: flex;
          flex-direction: row;
          width: 100%;
        }
        script-inset-wrapped .sourceItem,
        script-inset-wrapped .sourceItemCurrent {
          vertical-align: top;
          font: 400 14px consolas, courier, monospace;
          line-height: 125%;
          white-space: pre;
          max-width: 0;
        }
        script-inset-wrapped .currentLine {
          background-color: #fff;
        }
        script-inset-wrapped .currentCol {
          background-color: #6cf;
        }
        script-inset-wrapped .hitsCurrent,
        script-inset-wrapped .hitsNone,
        script-inset-wrapped .hitsNotExecuted,
        script-inset-wrapped .hitsExecuted,
        script-inset-wrapped .hitsCompiled,
        script-inset-wrapped .hitsNotCompiled {
          display: table-cell;
          vertical-align: top;
          font: 400 14px consolas, courier, monospace;
          margin-left: 5px;
          margin-right: 5px;
          text-align: right;
          color: #a8a8a8;
        }
        script-inset-wrapped .hitsCurrent {
          background-color: #6cf;
          color: black;
        }
        script-inset-wrapped .hitsNotExecuted {
          background-color: #faa;
        }
        script-inset-wrapped .hitsExecuted {
          background-color: #aea;
        }
        script-inset-wrapped .hitsCompiled {
          background-color: #e0e0e0;
        }
        script-inset-wrapped .hitsNotCompiled {
          background-color: #f0c5c5;
        }
        script-inset-wrapped .noCopy {}
        script-inset-wrapped .emptyBreakpoint,
        script-inset-wrapped .possibleBreakpoint,
        script-inset-wrapped .busyBreakpoint,
        script-inset-wrapped .unresolvedBreakpoint,
        script-inset-wrapped .resolvedBreakpoint  {
          display: table-cell;
          vertical-align: top;
          font: 400 14px consolas, courier, monospace;
          width: 1em;
          text-align: center;
          cursor: pointer;
        }
        script-inset-wrapped .possibleBreakpoint {
          color: #e0e0e0;
        }
        script-inset-wrapped .possibleBreakpoint:hover {
          color: white;
          background-color: #777;
        }
        script-inset-wrapped .busyBreakpoint {
          color: white;
          background-color: black;
          cursor: wait;
        }
        script-inset-wrapped .unresolvedBreakpoint {
          color: white;
          background-color: #cac;
        }
        script-inset-wrapped .resolvedBreakpoint {
          color: white;
          background-color: #e66;
        }
        script-inset-wrapped .unresolvedBreakAnnotation {
          color: white;
          background-color: #cac;
        }
        script-inset-wrapped .resolvedBreakAnnotation {
          color: white;
          background-color: #e66;
        }
        script-inset-wrapped .notSourceProfile,
        script-inset-wrapped .noProfile,
        script-inset-wrapped .coldProfile,
        script-inset-wrapped .mediumProfile,
        script-inset-wrapped .hotProfile {
          display: table-cell;
          vertical-align: top;
          font: 400 14px consolas, courier, monospace;
          width: 4em;
          text-align: right;
          cursor: pointer;
          margin-left: 5px;
          margin-right: 5px;
        }
        script-inset-wrapped .notSourceProfile {
        }
        script-inset-wrapped .noProfile {
          background-color: #e0e0e0;
        }
        script-inset-wrapped .coldProfile {
          background-color: #aea;
        }
        script-inset-wrapped .mediumProfile {
          background-color: #fe9;
        }
        script-inset-wrapped .hotProfile {
          background-color: #faa;
        }''',
      new ScriptInsetElement(_location.script.isolate, _location.script,
                             new ScriptRepository(),
                             new InstanceRepository(),
                             ObservatoryApplication.app.events,
                             startPos: _location.tokenPos,
                             endPos: _location.endTokenPos,
                             currentPos: _currentPos,
                             inDebuggerContext: _inDebuggerContext ?? false,
                             variables: _variables ?? const [],
                             queue: ObservatoryApplication.app.queue)
    ];
  }
}
