// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Node] API. */
class NodeBindExtension {
  final Node _node;
  Map<String, NodeBinding> _bindings;

  NodeBindExtension._(this._node);

  /**
   * Binds the attribute [name] to the [path] of the [model].
   * Path is a String of accessors such as `foo.bar.baz`.
   * Returns the `NodeBinding` instance.
   */
  NodeBinding bind(String name, model, [String path]) {
    window.console.error('Unhandled binding to Node: '
        '$this $name $model $path');
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
  /** Gets the data bindings that are associated with this node. */
  Map<String, NodeBinding> get bindings {
    if (_bindings == null) _bindings = new LinkedHashMap<String, NodeBinding>();
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
      (_node.parent != null ? _node.parent.templateInstance : null);
}


/** Information about the instantiated template. */
class TemplateInstance {
  // TODO(rafaelw): firstNode & lastNode should be read-synchronous
  // in cases where script has modified the template instance boundary.

  /** The first node of this template instantiation. */
  final Node firstNode;

  /**
   * The last node of this template instantiation.
   * This could be identical to [firstNode] if the template only expanded to a
   * single node.
   */
  final Node lastNode;

  /** The model used to instantiate the template. */
  final model;

  TemplateInstance(this.firstNode, this.lastNode, this.model);
}


/**
 * Template Bindings native features enables a wide-range of use cases,
 * but (by design) don't attempt to implement a wide array of specialized
 * behaviors.
 *
 * Enabling these features is a matter of implementing and registering a
 * BindingDelegate. A binding delegate is an object which contains one or more
 * delegation functions which implement specialized behavior. This object is
 * registered via [TemplateBindExtension.bindingDelegate]:
 *
 * HTML:
 *     <template bind>
 *       {{ What!Ever('crazy')->thing^^^I+Want(data) }}
 *     </template>
 *
 * Dart:
 *     class MySyntax extends BindingDelegate {
 *       getBinding(model, path, name, node) {
 *         // The magic happens here!
 *       }
 *     }
 *     ...
 *     templateBind(query('template'))
 *         ..bindingDelegate = new MySyntax()
 *         ..model = new MyModel();
 *
 * See <https://github.com/polymer-project/mdv/blob/master/docs/syntax.md> for
 * more information about Custom Syntax.
 */
abstract class BindingDelegate {
  /**
   * This syntax method allows for a custom interpretation of the contents of
   * mustaches (`{{` ... `}}`).
   *
   * When a template is inserting an instance, it will invoke this method for
   * each mustache which is encountered. The function is invoked with four
   * arguments:
   *
   * - [model]: The data context for which this instance is being created.
   * - [path]: The text contents (trimmed of outer whitespace) of the mustache.
   * - [name]: The context in which the mustache occurs. Within element
   *   attributes, this will be the name of the attribute. Within text,
   *   this will be 'text'.
   * - [node]: A reference to the node to which this binding will be created.
   *
   * If the method wishes to handle binding, it is required to return an object
   * which has at least a `value` property that can be observed. If it does,
   * then MDV will call [NodeBindExtension.bind] on the node:
   *
   *     nodeBind(node).bind(name, retval, 'value');
   *
   * If the 'getBinding' does not wish to override the binding, it should return
   * null.
   */
  // TODO(jmesserly): I had to remove type annotations from "name" and "node"
  // Normally they are String and Node respectively. But sometimes it will pass
  // (int name, CompoundBinding node). That seems very confusing; we may want
  // to change this API.
  getBinding(model, String path, name, node) => null;

  /**
   * This syntax method allows a syntax to provide an alterate model than the
   * one the template would otherwise use when producing an instance.
   *
   * When a template is about to create an instance, it will invoke this method
   * The function is invoked with two arguments:
   *
   * - [template]: The template element which is about to create and insert an
   *   instance.
   * - [model]: The data context for which this instance is being created.
   *
   * The template element will always use the return value of `getInstanceModel`
   * as the model for the new instance. If the syntax does not wish to override
   * the value, it should simply return the `model` value it was passed.
   */
  getInstanceModel(Element template, model) => model;
}

/**
 * A data binding on a [Node].
 * See [NodeBindExtension.bindings] and [NodeBindExtension.bind].
 */
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
  bool get closed => _node == null;

  /** The value at the [path] on [model]. */
  get value => _observer.value;

  set value(newValue) {
    _observer.value = newValue;
  }

  NodeBinding(this._node, this.property, this._model, [String path])
      : path = path != null ? path : '' {
    _observePath();
  }

  _observePath() {
    // Fast path if we're observing PathObserver.value
    if (model is PathObserver && path == 'value') {
      _observer = model;
    } else {
      // Create the path observer
      _observer = new PathObserver(model, path);
    }
    _pathSub = _observer.bindSync(valueChanged);
  }

  /** Called when [value] changes to update the [node]. */
  // TODO(jmesserly): the impl in template_binding uses reflection to set the
  // property, but that isn't used except for specific known fields like
  // "textContent", so I'm overridding this in the subclasses instead.
  void valueChanged(newValue);

  /** Called to sanitize the value before it is assigned into the property. */
  sanitizeBoundValue(value) => value == null ? '' : '$value';

  /**
   * Called by [NodeBindExtension.unbind] to close this binding and unobserve
   * the [path].
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
