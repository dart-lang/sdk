// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Node] API. */
class NodeBindExtension {
  final Node _node;

  /**
   * Gets the data bindings that are associated with this node, if any.
   *
   * This starts out null, and if [enableBindingsReflection] is enabled, calls
   * to [bind] will initialize this field and the binding.
   */
  // Dart note: in JS this has a trailing underscore, meaning "private".
  // But in dart if we made it _bindings, it wouldn't be accessible at all.
  // It is unfortunately needed to implement Node.bind correctly.
  Map<String, Bindable> bindings;

  NodeBindExtension._(this._node);

  /**
   * Binds the attribute [name] to [value]. [value] can be a simple value when
   * [oneTime] is true, or a [Bindable] like [PathObserver].
   * Returns the [Bindable] instance.
   */
  Bindable bind(String name, value, {bool oneTime: false}) {
    // TODO(jmesserly): in Dart we could deliver an async error, which would
    // have a similar affect but be reported as a test failure. Should we?
    window.console.error('Unhandled binding to Node: '
        '$this $name $value $oneTime');
    return null;
  }

  /**
   * Called when all [bind] calls are finished for a given template expansion.
   */
  void bindFinished() {}

  /**
   * Dispatch support so custom HtmlElement's can override these methods.
   *
   * A public method like [this.bind] should not call another public method.
   *
   * Instead it should dispatch through [_self] to give the "overridden" method
   * a chance to intercept.
   */
  NodeBindExtension get _self => _node is NodeBindExtension ? _node : this;

  TemplateInstance _templateInstance;

  /** Gets the template instance that instantiated this node, if any. */
  TemplateInstance get templateInstance =>
      _templateInstance != null ? _templateInstance :
      (_node.parent != null ? nodeBind(_node.parent).templateInstance : null);

  _open(Bindable bindable, callback(value)) =>
      callback(bindable.open(callback));

  Bindable _maybeUpdateBindings(String name, Bindable binding) {
    return enableBindingsReflection ? _updateBindings(name, binding) : binding;
  }

  Bindable _updateBindings(String name, Bindable binding) {
    if (bindings == null) bindings = {};
    var old = bindings[name];
    if (old != null) old.close();
    return bindings[name] = binding;
  }
}


/** Information about the instantiated template. */
class TemplateInstance {
  // TODO(rafaelw): firstNode & lastNode should be read-synchronous
  // in cases where script has modified the template instance boundary.

  /** The first node of this template instantiation. */
  Node get firstNode => _firstNode;

  /**
   * The last node of this template instantiation.
   * This could be identical to [firstNode] if the template only expanded to a
   * single node.
   */
  Node get lastNode => _lastNode;

  /** The model used to instantiate the template. */
  final model;

  Node _firstNode, _lastNode;

  TemplateInstance(this.model);
}
