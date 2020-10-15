// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library eval_box_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/instance_ref.dart';

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

  factory EvalBoxElement(M.IsolateRef isolate, M.ObjectRef context,
      M.ObjectRepository objects, M.EvalRepository eval,
      {bool multiline: false,
      Iterable<String> quickExpressions: const [],
      RenderingQueue? queue}) {
    assert(isolate != null);
    assert(context != null);
    assert(objects != null);
    assert(eval != null);
    assert(multiline != null);
    assert(quickExpressions != null);
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
    children = <Element>[];
    _results.clear();
  }

  void render() {
    children = <Element>[
      new DivElement()
        ..classes = ['quicks']
        ..children = _quickExpressions
            .map<Element>((q) => new ButtonElement()
              ..text = q
              ..onClick.listen((_) {
                _expression = q;
                _run();
              }))
            .toList(),
      new DivElement()
        ..classes = ['heading']
        ..children = <Element>[
          new FormElement()
            ..autocomplete = 'on'
            ..children = <Element>[
              _multiline ? _createEvalTextArea() : _createEvalTextBox(),
              new SpanElement()
                ..classes = ['buttons']
                ..children = <Element>[
                  _createEvalButton(),
                  _createMultilineCheckbox(),
                  new SpanElement()..text = 'Multi-line'
                ]
            ]
        ],
      new TableElement()
        ..children = _results.reversed
            .map<Element>((result) => new TableRowElement()
              ..children = <Element>[
                new TableCellElement()
                  ..classes = ['historyExpr']
                  ..children = <Element>[
                    new ButtonElement()
                      ..text = result.expression
                      ..onClick.listen((_) {
                        _expression = result.expression;
                        _r.dirty();
                      })
                  ],
                new TableCellElement()
                  ..classes = ['historyValue']
                  ..children = <Element>[
                    result.isPending
                        ? (new SpanElement()..text = 'Pending...')
                        : anyRef(_isolate, result.value, _objects,
                            queue: _r.queue)
                  ],
                new TableCellElement()
                  ..classes = ['historyDelete']
                  ..children = <Element>[
                    new ButtonElement()
                      ..text = '✖ Remove'
                      ..onClick.listen((_) {
                        _results.remove(result);
                        _r.dirty();
                      })
                  ]
              ])
            .toList()
    ];
  }

  TextAreaElement _createEvalTextArea() {
    var area = new TextAreaElement()
      ..classes = ['textbox']
      ..placeholder = 'evaluate an expression'
      ..value = _expression!
      ..onKeyUp.where((e) => e.key == '\n').listen((e) {
        e.preventDefault();
        _run();
      });
    area.onInput.listen((e) {
      _expression = area.value;
    });
    return area;
  }

  TextInputElement _createEvalTextBox() {
    _expression = (_expression ?? '').split('\n')[0];
    var textbox = new TextInputElement()
      ..classes = ['textbox']
      ..placeholder = 'evaluate an expression'
      ..value = _expression!
      ..onKeyUp.where((e) => e.key == '\n').listen((e) {
        e.preventDefault();
        _run();
      });
    textbox.onInput.listen((e) {
      _expression = textbox.value;
    });
    return textbox;
  }

  ButtonElement _createEvalButton() {
    final button = new ButtonElement()
      ..text = 'Evaluate'
      ..onClick.listen((e) {
        e.preventDefault();
        _run();
      });
    return button;
  }

  CheckboxInputElement _createMultilineCheckbox() {
    final checkbox = new CheckboxInputElement()..checked = _multiline;
    checkbox.onClick.listen((e) {
      e.preventDefault();
      _multiline = checkbox.checked!;
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
        expression, await _eval.evaluate(_isolate, _context, expression));
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
