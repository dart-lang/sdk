// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Node] API. */
class _NodeExtension {
  final Node node;
  Map<String, NodeBinding> _bindings;

  _NodeExtension(this.node);

  NodeBinding createBinding(String name, model, String path) => null;

  /**
   * Binds the attribute [name] to the [path] of the [model].
   * Path is a String of accessors such as `foo.bar.baz`.
   */
  NodeBinding bind(String name, model, String path) {
    var binding = bindings[name];
    if (binding != null) binding.close();

    // Note: dispatch through the xtag so a custom element can override it.
    binding = (node is Element ? (node as Element).xtag : node)
        .createBinding(name, model, path);

    bindings[name] = binding;
    if (binding == null) {
      window.console.error('Unhandled binding to Node: '
          '$this $name $model $path');
    }
    return binding;
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
    for (var binding in bindings.values) {
      if (binding != null) binding.close();
    }
    _bindings = null;
  }

  // TODO(jmesserly): we should return a read-only wrapper here.
  Map<String, NodeBinding> get bindings {
    if (_bindings == null) _bindings = new LinkedHashMap<String, NodeBinding>();
    return _bindings;
  }

  TemplateInstance _templateInstance;

  /** Gets the template instance that instantiated this node, if any. */
  TemplateInstance get templateInstance =>
      _templateInstance != null ? _templateInstance :
      (node.parent != null ? node.parent.templateInstance : null);
}

/** A data binding on a [Node]. See [Node.bindings] and [Node.bind]. */
abstract class NodeBinding {
  Node _node;
  var _model;
  PathObserver _observer;
  StreamSubscription _pathSub;

  /** The property of [node] which will be data bound. */
  final String property;

  /** The property of [node] which will be data bound. */
  final String path;

  /** The node that has [property] which will be data bound. */
  Node get node => _node;

  /**
   * The bound data model.
   */
  get model => _model;

  /** True if this binding has been [closed]. */
  bool get closed => _observer == null;

  /** The value at the [path] on [model]. */
  get value => _observer.value;

  set value(newValue) {
    _observer.value = newValue;
  }

  NodeBinding(this._node, this.property, this._model, this.path) {
    // Create the path observer
    _observer = new PathObserver(model, path);
    _observePath();
  }

  void _observePath() {
    _pathSub = _observer.bindSync(boundValueChanged);
  }

  /** Called when [value] changes to update the [node]. */
  // TODO(jmesserly): the impl in MDV uses mirrors to set the property,
  // but that isn't used except for specific known fields like "textContent",
  // so I'm overridding this in the subclasses instead.
  void boundValueChanged(newValue);

  /** Called to sanitize the value before it is assigned into the property. */
  sanitizeBoundValue(value) => value == null ? '' : '$value';

  /**
   * Called by [Node.unbind] to close this binding and unobserve the [path].
   *
   * This can be overridden in subclasses, but they must call `super.close()`
   * to free associated resources. They must also check [closed] and return
   * immediately if already closed.
   */
  void close() {
    if (closed) return;

    if (_pathSub != null) _pathSub.cancel();
    _pathSub = null;
    _observer = null;
    _node = null;
    _model = null;
  }
}
