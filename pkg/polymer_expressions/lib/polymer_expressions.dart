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

  final ScopeFactory _scopeFactory;
  final Map<String, Object> globals;

  // allows access to scopes created for template instances
  final Expando<Scope> _scopes = new Expando<Scope>();
  // allows access to scope identifiers (for "in" and "as")
  final Expando<String> _scopeIdents = new Expando<String>();

  /**
   * Creates a new binding delegate for Polymer expressions, with the provided
   * variables used as [globals]. If no globals are supplied, a copy of the
   * [DEFAULT_GLOBALS] will be used.
   */
  PolymerExpressions({Map<String, Object> globals,
      ScopeFactory scopeFactory: const ScopeFactory()})
      : globals = globals == null ?
          new Map<String, Object>.from(DEFAULT_GLOBALS) : globals,
          _scopeFactory = scopeFactory;

  @override
  PrepareBindingFunction prepareBinding(String path, name, Node boundNode) {
    if (path == null) return null;
    var expr = new Parser(path).parse();

    if (isSemanticTemplate(boundNode) && (name == 'bind' || name == 'repeat')) {
      if (expr is HasIdentifier) {
        var identifier = expr.identifier;
        var bindExpr = expr.expr;
        return (model, Node node, bool oneTime) {
          _scopeIdents[node] = identifier;
          // model may not be a Scope if it was assigned directly via
          // template.model = x; In that case, prepareInstanceModel will
          // be called _after_ prepareBinding and will lookup this scope from
          // _scopes
          var scope = _scopes[node] = (model is Scope)
              ? model
              : _scopeFactory.modelScope(model: model, variables: globals);
          return new _Binding(bindExpr, scope);
        };
      } else {
        return (model, Node node, bool oneTime) {
          var scope = _scopes[node] = (model is Scope)
              ? model
              : _scopeFactory.modelScope(model: model, variables: globals);
          if (oneTime) {
            return _Binding._oneTime(expr, scope, null);
          }
          return new _Binding(expr, scope);
        };
      }
    }

    // For regular bindings, not bindings on a template, the model is always
    // a Scope created by prepareInstanceModel
    _Converter converter = null;
    if (boundNode is Element && name == 'class') {
      converter = _classAttributeConverter;
    } else if (boundNode is Element && name == 'style') {
      converter = _styleAttributeConverter;
    }

    return (model, Node node, bool oneTime) {
      var scope = _getScopeForModel(node, model);
      if (oneTime) {
        return _Binding._oneTime(expr, scope, converter);
      }
      return new _Binding(expr, scope, converter);
    };
  }

  prepareInstanceModel(Element template) {
    var ident = _scopeIdents[template];

    if (ident == null) {
      return (model) {
        var existingScope = _scopes[template];
        // TODO (justinfagnani): make template binding always call
        // prepareInstanceModel first and get rid of this check
        if (existingScope != null) {
          // If there's an existing scope, we created it in prepareBinding
          // If it has the same model, then we can reuse it, otherwise it's
          // a repeat with no identifier and we create new scope to occlude
          // the outer one
          if (model == existingScope.model) return existingScope;
          return _scopeFactory.modelScope(model: model, variables: globals);
        } else {
          return _getScopeForModel(template, model);
        }
      };
    }

    return (model) {
      var existingScope = _scopes[template];
      if (existingScope != null) {
        // This only happens when a model has been assigned programatically
        // and prepareBinding is called _before_ prepareInstanceModel.
        // The scope assigned in prepareBinding wraps the model and is the
        // scope of the expression. That should be the parent of the templates
        // scope in the case of bind/as or repeat/in bindings.
        return _scopeFactory.childScope(existingScope, ident, model);
      } else {
        // If there's not an existing scope then we have a bind/as or
        // repeat/in binding enclosed in an outer scope, so we use that as
        // the parent
        var parentScope = _getParentScope(template);
        return _scopeFactory.childScope(parentScope, ident, model);
      }
    };
  }

  /**
   * Gets an existing scope for use as a parent, but does not create a new one.
   */
  Scope _getParentScope(Node node) {
    var parent = node.parentNode;
    if (parent == null) return null;

    if (isSemanticTemplate(node)) {
      var templateExtension = templateBind(node);
      var templateInstance = templateExtension.templateInstance;
      var model = templateInstance == null
          ? templateExtension.model
          : templateInstance.model;
      if (model is Scope) {
        return model;
      } else {
        // A template with a bind binding might have a non-Scope model
        return _scopes[node];
      }
    }
    if (parent != null) return _getParentScope(parent);
    return null;
  }

  /**
   * Returns the Scope to be used to evaluate expressions in the template
   * containing [node]. Since all expressions in the same template evaluate
   * against the same model, [model] is passed in and checked against the
   * template model to make sure they agree.
   *
   * For nested templates, we might have a binding on the nested template that
   * should be evaluated in the context of the parent template. All scopes are
   * retreived from an ancestor of [node], since node may be establishing a new
   * Scope.
   */
  Scope _getScopeForModel(Node node, model) {
    // This only happens in bindings_test because it calls prepareBinding()
    // directly. Fix the test and throw if node is null?
    if (node == null) {
      return _scopeFactory.modelScope(model: model, variables: globals);
    }

    var id = node is Element ? node.id : '';
    if (model is Scope) {
      return model;
    }
    if (_scopes[node] != null) {
      var scope = _scopes[node];
      assert(scope.model == model);
      return _scopes[node];
    } else if (node.parentNode != null) {
      return _getContainingScope(node.parentNode, model);
    } else {
      // here we should be at a top-level template, so there's no parent to
      // look for a Scope on.
      if (!isSemanticTemplate(node)) {
        throw "expected a template instead of $node";
      }
      return _getContainingScope(node, model);
    }
  }

  Scope _getContainingScope(Node node, model) {
    if (isSemanticTemplate(node)) {
      var templateExtension = templateBind(node);
      var templateInstance = templateExtension.templateInstance;
      var templateModel = templateInstance == null
          ? templateExtension.model
          : templateInstance.model;
      assert(templateModel == model);
      var scope = _scopes[node];
      assert(scope != null);
      assert(scope.model == model);
      return scope;
    } else if (node.parent == null) {
      var scope = _scopes[node];
      if (scope != null) {
        assert(scope.model == model);
      } else {
        // only happens in bindings_test
        scope = _scopeFactory.modelScope(model: model, variables: globals);
      }
      return scope;
    } else {
      return _getContainingScope(node.parentNode, model);
    }
  }

}

typedef Object _Converter(Object);

class _Binding extends Bindable {
  final Scope _scope;
  final _Converter _converter;
  final Expression _expr;

  Function _callback;
  StreamSubscription _sub;
  ExpressionObserver _observer;
  var _value;

  _Binding(this._expr, this._scope, [converter])
      : _converter = converter == null ? _identity : converter;

  static Object _oneTime(Expression expr, Scope scope, _Converter converter) {
    try {
      var value = eval(expr, scope);
      return (converter == null) ? value : converter(value);
    } catch (e, s) {
      new Completer().completeError(
          "Error evaluating expression '$expr': $e", s);
    }
    return null;
  }

  bool _convertAndCheck(newValue, {bool skipChanges: false}) {
    var oldValue = _value;
    _value = _converter(newValue);

    if (!skipChanges && _callback != null && oldValue != _value) {
      _callback(_value);
      return true;
    }
    return false;
  }

  get value {
    // if there's a callback, then _value has been set, if not we need to
    // force an evaluation
    if (_callback != null) {
      _check(skipChanges: true);
      return _value;
    }
    return _oneTime(_expr, _scope, _converter);
  }

  set value(v) {
    try {
      assign(_expr, v, _scope, checkAssignability: false);
    } catch (e, s) {
      new Completer().completeError(
          "Error evaluating expression '$_expr': $e", s);
    }
  }

  Object open(callback(value)) {
    if (_callback != null) throw new StateError('already open');

    _callback = callback;
    _observer = observe(_expr, _scope);
    _sub = _observer.onUpdate.listen(_convertAndCheck)..onError((e, s) {
      new Completer().completeError(
          "Error evaluating expression '$_observer': $e", s);
    });

    _check(skipChanges: true);
    return _value;
  }

  bool _check({bool skipChanges: false}) {
    try {
      update(_observer, _scope, skipChanges: skipChanges);
      return _convertAndCheck(_observer.currentValue, skipChanges: skipChanges);
    } catch (e, s) {
      new Completer().completeError(
          "Error evaluating expression '$_observer': $e", s);
      return false;
    }
  }

  void close() {
    if (_callback == null) return;

    _sub.cancel();
    _sub = null;
    _callback = null;

    new Closer().visit(_observer);
    _observer = null;
  }


  // TODO(jmesserly): the following code is copy+pasted from path_observer.dart
  // What seems to be going on is: polymer_expressions.dart has its own _Binding
  // unlike polymer-expressions.js, which builds on CompoundObserver.
  // This can lead to subtle bugs and should be reconciled. I'm not sure how it
  // should go, but CompoundObserver does have some nice optimizations around
  // ObservedSet which are lacking here. And reuse is nice.
  void deliver() {
    if (_callback != null) _dirtyCheck();
  }

  bool _dirtyCheck() {
    var cycles = 0;
    while (cycles < _MAX_DIRTY_CHECK_CYCLES && _check()) {
      cycles++;
    }
    return cycles > 0;
  }

  static const int _MAX_DIRTY_CHECK_CYCLES = 1000;
}

_identity(x) => x;

/**
 * Factory function used for testing.
 */
class ScopeFactory {
  const ScopeFactory();
  modelScope({Object model, Map<String, Object> variables}) =>
      new Scope(model: model, variables: variables);

  childScope(Scope parent, String name, Object value) =>
      parent.childScope(name, value);
}
