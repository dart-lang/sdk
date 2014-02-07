// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Node] API. */
class NodeBindExtension {
  final Node _node;
  Map<String, Bindable> _bindings;

  NodeBindExtension._(this._node);

  /**
   * Binds the attribute [name] to the [path] of the [model].
   * Path is a String of accessors such as `foo.bar.baz`.
   * Returns the `Bindable` instance.
   */
  Bindable bind(String name, value, {bool oneTime: false}) {
    // TODO(jmesserly): in Dart we could deliver an async error, which would
    // have a similar affect but be reported as a test failure. Should we?
    window.console.error('Unhandled binding to Node: '
        '$this $name $value $oneTime');
    return null;
  }

  /** Unbinds the attribute [name]. */
  void unbind(String name) {
    if (_bindings == null) return;
    var binding = bindings.remove(name);
    if (binding != null) binding.close();
  }

  /** Unbinds all bound attributes. */
  void unbindAll() {
    if (_bindings == null) return;
    for (var binding in bindings.values.toList()) {
      if (binding != null) binding.close();
    }
    _bindings = null;
  }

  // TODO(jmesserly): we should return a read-only wrapper here.
  /** Gets the data bindings that are associated with this node. */
  Map<String, Bindable> get bindings {
    if (_bindings == null) _bindings = new LinkedHashMap<String, Bindable>();
    return _bindings;
  }

  /**
   * Dispatch support so custom HtmlElement's can override these methods.
   * A public method like [this.bind] should not call another public method such
   * as [this.unbind]. Instead it should dispatch through [_self.unbind].
   */
  NodeBindExtension get _self => _node is NodeBindExtension ? _node : this;

  TemplateInstance _templateInstance;

  /** Gets the template instance that instantiated this node, if any. */
  TemplateInstance get templateInstance =>
      _templateInstance != null ? _templateInstance :
      (_node.parent != null ? nodeBind(_node.parent).templateInstance : null);

  _open(Bindable bindable, callback(value)) =>
      callback(bindable.open(callback));
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
