// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library eval_box_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';

class EvalBoxElement extends CustomElement implements Renderable {
  late RenderingScheduler<EvalBoxElement> _r;

  Stream<RenderedEvent<EvalBoxElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ObjectRef _context;
  late M.ObjectRepository _objects;
  late M.EvalRepository _eval;
  final _results = <_ExpressionDescription>[];
  String? _expression = '';
  late bool _multiline;
  late Iterable<String> _quickExpressions;

  M.IsolateRef get isolate => _isolate;
  M.ObjectRef get context => _context;

  factory EvalBoxElement(
    M.IsolateRef isolate,
    M.ObjectRef context,
    M.ObjectRepository objects,
    M.EvalRepository eval, {
    bool multiline = false,
    Iterable<String> quickExpressions = const [],
    RenderingQueue? queue,
  }) {
    EvalBoxElement e = new EvalBoxElement.created();
    e._r = new RenderingScheduler<EvalBoxElement>(e, queue: queue);
    e._isolate = isolate;
    e._context = context;
    e._objects = objects;
    e._eval = eval;
    e._multiline = multiline;
    e._quickExpressions = new List.unmodifiable(quickExpressions);
    return e;
  }

  EvalBoxElement.created() : super.created('eval-box');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
    _results.clear();
  }

  void render() {
    setChildren(<HTMLElement>[
      new HTMLDivElement()
        ..className = 'quicks'
        ..appendChildren(
          _quickExpressions.map<HTMLElement>(
            (q) => new HTMLButtonElement()
              ..textContent = q
              ..onClick.listen((_) {
                _expression = q;
                _run();
              }),
          ),
        ),
      new HTMLDivElement()
        ..className = 'heading'
        ..appendChildren(<HTMLElement>[
          new HTMLFormElement()
            ..autocomplete = 'on'
            ..appendChildren(<HTMLElement>[
              _multiline ? _createEvalTextArea() : _createEvalTextBox(),
              new HTMLSpanElement()
                ..className = 'buttons'
                ..appendChildren(<HTMLElement>[
                  _createEvalButton(),
                  _createMultilineCheckbox(),
                  new HTMLSpanElement()..textContent = 'Multi-line',
                ]),
            ]),
        ]),
      new HTMLTableElement()..appendChildren(
        _results.reversed
            .map<HTMLElement>(
              (result) =>
                  new HTMLTableRowElement()..appendChildren(<HTMLElement>[
                    new HTMLTableCellElement.td()
                      ..className = 'historyExpr'
                      ..appendChildren(<HTMLElement>[
                        new HTMLButtonElement()
                          ..textContent = result.expression
                          ..onClick.listen((_) {
                            _expression = result.expression;
                            _r.dirty();
                          }),
                      ]),
                    new HTMLTableCellElement.td()
                      ..className = 'historyValue'
                      ..appendChildren(<HTMLElement>[
                        result.isPending
                            ? (new HTMLSpanElement()
                                ..textContent = 'Pending...')
                            : anyRef(
                                _isolate,
                                result.value,
                                _objects,
                                queue: _r.queue,
                              ),
                      ]),
                    new HTMLTableCellElement.td()
                      ..className = 'historyDelete'
                      ..appendChildren(<HTMLElement>[
                        new HTMLButtonElement()
                          ..textContent = '✖ Remove'
                          ..onClick.listen((_) {
                            _results.remove(result);
                            _r.dirty();
                          }),
                      ]),
                  ]),
            )
            .toList(),
      ),
    ]);
  }

  HTMLTextAreaElement _createEvalTextArea() {
    var area = new HTMLTextAreaElement()
      ..className = 'textbox'
      ..placeholder = 'evaluate an expression'
      ..value = _expression ?? ''
      ..onKeyUp.where((e) => e.key == '\n').listen((e) {
        e.preventDefault();
        _run();
      });
    area.onInput.listen((e) {
      _expression = area.value;
    });
    return area;
  }

  HTMLInputElement _createEvalTextBox() {
    final expression = (_expression ?? '').split('\n')[0];
    _expression = expression;
    var textbox = new HTMLInputElement()
      ..className = 'textbox'
      ..placeholder = 'evaluate an expression'
      ..value = expression
      ..onKeyUp.where((e) => e.key == '\n').listen((e) {
        e.preventDefault();
        _run();
      });
    textbox.onInput.listen((e) {
      _expression = textbox.value;
    });
    return textbox;
  }

  HTMLButtonElement _createEvalButton() {
    final button = new HTMLButtonElement()
      ..textContent = 'Evaluate'
      ..onClick.listen((e) {
        e.preventDefault();
        _run();
      });
    return button;
  }

  HTMLInputElement _createMultilineCheckbox() {
    final checkbox = new HTMLInputElement()
      ..type = 'checkbox'
      ..checked = _multiline;
    checkbox.onClick.listen((e) {
      e.preventDefault();
      _multiline = checkbox.checked;
      _r.dirty();
    });
    return checkbox;
  }

  Future _run() async {
    final expression = _expression;
    if (expression == null || expression.isEmpty) return;
    _expression = null;
    final result = new _ExpressionDescription.pending(expression);
    _results.add(result);
    _r.dirty();
    final index = _results.indexOf(result);
    _results[index] = new _ExpressionDescription(
      expression,
      await _eval.evaluate(_isolate, _context, expression),
    );
    _r.dirty();
  }
}

class _ExpressionDescription {
  final String expression;
  final M.ObjectRef? value;
  bool get isPending => value == null;

  _ExpressionDescription(this.expression, this.value);
  _ExpressionDescription.pending(this.expression) : value = null;
}
