// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Node] API. */
class NodeBindExtension {
  final Node _node;
  final JsObject _js;

  NodeBindExtension._(node)
      : _node = node,
        _js = new JsObject.fromBrowserObject(node);

  /**
   * Gets the data bindings that are associated with this node, if any.
   *
   * This starts out null, and if [enableBindingsReflection] is enabled, calls
   * to [bind] will initialize this field and the binding.
   */
  // Dart note: in JS this has a trailing underscore, meaning "private".
  // But in dart if we made it _bindings, it wouldn't be accessible at all.
  // It is unfortunately needed to implement Node.bind correctly.
  Map<String, Bindable> get bindings {
    var b = _js['bindings_'];
    if (b == null) return null;
    // TODO(jmesserly): should cache this for identity.
    return new _NodeBindingsMap(_node, b);
  }
  
  set bindings(Map<String, Bindable> value) {
    if (value == null) {
      _js.deleteProperty('bindings_');
      return;
    }
    var b = bindings;
    if (b == null) {
      _js['bindings_'] = new JsObject.jsify({});
      b = bindings;
    }
    b.addAll(value);
  }

  /**
   * Binds the attribute [name] to [value]. [value] can be a simple value when
   * [oneTime] is true, or a [Bindable] like [PathObserver].
   * Returns the [Bindable] instance.
   */
  Bindable bind(String name, value, {bool oneTime: false}) {
    name = _dartToJsName(_node, name);

    if (!oneTime && value is Bindable) {
      value = bindableToJsObject(value);
    }
    return jsObjectToBindable(_js.callMethod('bind', [name, value, oneTime]));
  }

  /**
   * Called when all [bind] calls are finished for a given template expansion.
   */
  bindFinished() => _js.callMethod('bindFinished');

  // Note: confusingly this is on NodeBindExtension because it can be on any
  // Node. It's really an API added by TemplateBinding. Therefore it stays
  // implemented in Dart because TemplateBinding still is.
  TemplateInstance _templateInstance;

  /** Gets the template instance that instantiated this node, if any. */
  TemplateInstance get templateInstance =>
      _templateInstance != null ? _templateInstance :
      (_node.parent != null ? nodeBind(_node.parent).templateInstance : null);
}

class _NodeBindingsMap extends MapBase<String, Bindable> {
  final Node _node;
  final JsObject _bindings;

  _NodeBindingsMap(this._node, this._bindings);

  // TODO(jmesserly): this should be lazy
  Iterable<String> get keys =>
      js.context['Object'].callMethod('keys', [_bindings]).map(
          (name) => _jsToDartName(_node, name));

  Bindable operator[](String name) =>
      jsObjectToBindable(_bindings[_dartToJsName(_node, name)]);

  operator[]=(String name, Bindable value) {
    _bindings[_dartToJsName(_node, name)] = bindableToJsObject(value);
  }

  @override Bindable remove(String name) {
    name = _dartToJsName(_node, name);
    var old = this[name];
    _bindings.deleteProperty(name);
    return old;
  }

  @override void clear() {
    // Notes: this implementation only works because our "keys" returns a copy.
    // We could also make it O(1) by assigning a new JS object to the bindings_
    // property, if performance is an issue.
    keys.forEach(remove);
  }
}

// TODO(jmesserly): perhaps we should switch Dart's Node.bind API back to
// 'textContent' for consistency? This only affects the raw Node.bind API when
// called on Text nodes, which is unlikely to be used except by TemplateBinding.
// Seems like a lot of magic to support it. I don't think Node.bind promises any
// strong relationship between properties and [name], so textContent seems fine.
String _dartToJsName(Node node, String name) {
  if (node is Text && name == 'text') name = 'textContent';
  return name;
}


String _jsToDartName(Node node, String name) {
  if (node is Text && name == 'textContent') name = 'text';
  return name;
}


/// Given a bindable [JsObject], wraps it in a Dart [Bindable].
/// See [bindableToJsObject] to go in the other direction.
Bindable jsObjectToBindable(JsObject obj) {
  if (obj == null) return null;
  var b = obj['__dartBindable'];
  // For performance, unwrap the Dart bindable if we find one.
  // Note: in the unlikely event some code messes with our __dartBindable
  // property we can simply fallback to a _JsBindable wrapper.
  return b is Bindable ? b : new _JsBindable(obj);
}

class _JsBindable extends Bindable {
  final JsObject _js;
  _JsBindable(JsObject obj) : _js = obj;

  open(callback) => _js.callMethod('open', [callback]);

  close() => _js.callMethod('close');

  get value => _js.callMethod('discardChanges');

  set value(newValue) {
    _js.callMethod('setValue', [newValue]);
  }

  deliver() => _js.callMethod('deliver');
}

/// Given a [bindable], create a JS object proxy for it.
/// This is the inverse of [jsObjectToBindable].
JsObject bindableToJsObject(Bindable bindable) {
  if (bindable is _JsBindable) return bindable._js;

  return new JsObject.jsify({
    'open': (callback) => bindable.open((x) => callback.apply([x])),
    'close': () => bindable.close(),
    'discardChanges': () => bindable.value,
    'setValue': (x) => bindable.value = x,
    // NOTE: this is not used by Node.bind, but it's used by Polymer:
    // https://github.com/Polymer/polymer-dev/blob/ba2b68fe5a5721f60b5994135f3270e63588809a/src/declaration/properties.js#L130
    // Technically this works because 'deliver' is on PathObserver and
    // CompoundObserver. But ideally Polymer-JS would not assume that.
    'deliver': () => bindable.deliver(),
    // Save this so we can return it from [jsObjectToBindable]
    '__dartBindable': bindable
  });
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
