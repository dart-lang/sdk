// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A binding delegate used with Polymer elements that
 * allows for complex binding expressions, including
 * property access, function invocation,
 * list/map indexing, and two-way filtering.
 *
 * When you install polymer.dart,
 * polymer_expressions is automatically installed as well.
 *
 * Polymer expressions are part of the Polymer.dart project.
 * Refer to the
 * [Polymer.dart](http://www.dartlang.org/polymer-dart/)
 * homepage for example code, project status, and
 * information about how to get started using Polymer.dart in your apps.
 *
 * ## Other resources
 *
 * The
 * [Polymer expressions](http://pub.dartlang.org/packages/polymer_expressions)
 * pub repository contains detailed documentation about using polymer
 * expressions.
 */

library polymer_expressions;

import 'dart:async';
import 'dart:html';

import 'package:observe/observe.dart';
import 'package:template_binding/template_binding.dart';

import 'eval.dart';
import 'expression.dart';
import 'parser.dart';
import 'src/globals.dart';

// TODO(justin): Investigate XSS protection
Object _classAttributeConverter(v) =>
    (v is Map) ? v.keys.where((k) => v[k] == true).join(' ') :
    (v is Iterable) ? v.join(' ') :
    v;

Object _styleAttributeConverter(v) =>
    (v is Map) ? v.keys.map((k) => '$k: ${v[k]}').join(';') :
    (v is Iterable) ? v.join(';') :
    v;

class PolymerExpressions extends BindingDelegate {
  /** The default [globals] to use for Polymer expressions. */
  static const Map DEFAULT_GLOBALS = const { 'enumerate': enumerate };

  final Map<String, Object> globals;

  /**
   * Creates a new binding delegate for Polymer expressions, with the provided
   * variables used as [globals]. If no globals are supplied, a copy of the
   * [DEFAULT_GLOBALS] will be used.
   */
  PolymerExpressions({Map<String, Object> globals})
      : globals = globals == null ?
          new Map<String, Object>.from(DEFAULT_GLOBALS) : globals;

  prepareBinding(String path, name, node) {
    if (path == null) return null;
    var expr = new Parser(path).parse();

    // For template bind/repeat to an empty path, just pass through the model.
    // We don't want to unwrap the Scope.
    // TODO(jmesserly): a custom element extending <template> could notice this
    // behavior. An alternative is to associate the Scope with the node via an
    // Expando, which is what the JavaScript PolymerExpressions does.
    if (isSemanticTemplate(node) && (name == 'bind' || name == 'repeat') &&
        expr is EmptyExpression) {
      return null;
    }

    return (model, node, oneTime) {
      if (model is! Scope) {
        model = new Scope(model: model, variables: globals);
      }
      var converter = null;
      if (node is Element && name == "class") {
        converter = _classAttributeConverter;
      }
      if (node is Element && name == "style") {
        converter = _styleAttributeConverter;
      }

      if (oneTime) {
        return _Binding._oneTime(expr, model, converter);
      }

      return new _Binding(expr, model, converter);
    };
  }

  prepareInstanceModel(Element template) => (model) =>
      model is Scope ? model : new Scope(model: model, variables: globals);
}

class _Binding extends Bindable {
  final Scope _scope;
  final _converter;
  Expression _expr;
  Function _callback;
  StreamSubscription _sub;
  var _value;

  _Binding(this._expr, this._scope, [converter])
      : _converter = converter == null ? _identity : converter;

  static _oneTime(Expression expr, Scope scope, [converter]) {
    try {
      var v = eval(expr, scope);
      return converter == null ? v : converter(v);
    } catch (e, s) {
      new Completer().completeError(
          "Error evaluating expression '$expr': $e", s);
    }
    return null;
  }

  _check(v, {bool skipChanges: false}) {
    var oldValue = _value;
    _value = _converter(v);
    if (!skipChanges && _callback != null && oldValue != _value) {
      _callback(_value);
    }
  }

  get value {
    if (_callback != null) return _value;
    return _oneTime(_expr, _scope, _converter);
  }

  set value(v) {
    try {
      var newValue = assign(_expr, v, _scope);
      _check(newValue, skipChanges: true);
    } catch (e, s) {
      new Completer().completeError(
          "Error evaluating expression '$_expr': $e", s);
    }
  }

  open(callback(value)) {
    if (_callback != null) throw new StateError('already open');

    _callback = callback;
    final expr = observe(_expr, _scope);
    _expr = expr;
    _sub = expr.onUpdate.listen(_check)..onError((e, s) {
      new Completer().completeError(
          "Error evaluating expression '$expr': $e", s);
    });
    try {
      update(expr, _scope);
      _check(expr.currentValue, skipChanges: true);
    } catch (e, s) {
      new Completer().completeError(
          "Error evaluating expression '$expr': $e", s);
    }
    return _value;
  }

  void close() {
    if (_callback == null) return;

    _sub.cancel();
    _sub = null;
    _expr = (_expr as ExpressionObserver).expression;
    _callback = null;
  }
}

_identity(x) => x;
