// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/service_html.dart' show HeapObject;
import 'package:observatory/src/elements/eval_box.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class EvalBoxElementWrapper extends HtmlElement {
  static const binder = const Binder<EvalBoxElementWrapper>(const {
      'context': #context
    });

  static const tag = const Tag<EvalBoxElementWrapper>('eval-box');

  HeapObject _context;

  HeapObject get context => _context;

  void set context(HeapObject value) {
    _context = value;
    render();
  }

  EvalBoxElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  void render() {
    shadowRoot.children = [];
    if (_context == null) {
      return;
    }

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        eval-box-wrapped a[href]:hover {
            text-decoration: underline;
        }
        eval-box-wrapped a[href] {
            color: #0489c3;
            text-decoration: none;
        }
        eval-box-wrapped .quicks > button:hover {
          background-color: transparent;
          border: none;
          text-decoration: underline;
        }
        eval-box-wrapped .quicks > button {
          background-color: transparent;
          border: none;
          color: #0489c3;
          padding: 0;
          margin-right: 1em;
          text-decoration: none;
        }
        eval-box-wrapped .empathize {
          font-style: italic;
        }
        eval-box-wrapped .indent {
          margin-left: 1.5em;
          font: 400 14px 'Montserrat', sans-serif;
          line-height: 150%;
        }
        eval-box-wrapped .stackTraceBox {
          margin-left: 1.5em;
          background-color: #f5f5f5;
          border: 1px solid #ccc;
          padding: 10px;
          font-family: consolas, courier, monospace;
          font-size: 12px;
          white-space: pre;
          overflow-x: auto;
        }
        eval-box-wrapped .heading {
          line-height: 30px;
          position: relative;
          box-sizing: border-box;
          width: 100%;
          min-width: 450px;
          padding-right: 150px;
        }
        eval-box-wrapped .heading .textbox {
          width: 100%;
          min-width: 300px;
        }
        eval-box-wrapped .heading .buttons {
          position: absolute;
          top: 0;
          right: 0px;
        }
        eval-box-wrapped.historyExpr,
        eval-box-wrapped .historyValue {
          vertical-align: text-top;
          font: 400 14px 'Montserrat', sans-serif;
        }
        eval-box-wrapped .historyExpr button {
          display: block;
          color: black;
          border: none;
          background: none;
          text-decoration: none;
          padding: 6px 6px;
          cursor: pointer;
          white-space: pre-line;
        }
        eval-box-wrapped .historyExpr button:hover {
          background-color: #fff3e3;
        }
        eval-box-wrapped .historyValue {
          display: block;
          padding: 6px 6px;
        }
        eval-box-wrapped .historyDelete button {
          border: none;
          background: none;
        }
        eval-box-wrapped .historyDelete button:hover {
          color: #BB3311;
        }
        ''',
      new EvalBoxElement(_context.isolate, _context,
                          new InstanceRepository(),
                          new EvalRepository(),
                          queue: ObservatoryApplication.app.queue)
    ];
  }
}
