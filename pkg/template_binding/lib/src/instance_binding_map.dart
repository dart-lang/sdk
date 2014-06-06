// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

class _InstanceBindingMap {
  final List bindings;
  List<_InstanceBindingMap> children;
  DocumentFragment content;

  bool get isTemplate => false;

  _InstanceBindingMap(this.bindings);

  _InstanceBindingMap getChild(int index) {
    if (children == null || index >= children.length) return null;
    return children[index];
  }
}

class _TemplateBindingMap extends _InstanceBindingMap {
  bool get isTemplate => true;

  MustacheTokens _if, _bind, _repeat;

  _TemplateBindingMap(List bindings) : super(bindings);
}

_InstanceBindingMap _createInstanceBindingMap(Node node,
    BindingDelegate delegate) {

  _InstanceBindingMap map = _getBindings(node, delegate);
  if (map == null) map = new _InstanceBindingMap([]);

  List children = null;
  int index = 0;
  for (var c = node.firstChild; c != null; c = c.nextNode, index++) {
    var childMap = _createInstanceBindingMap(c, delegate);
    if (childMap == null) continue;

    // TODO(jmesserly): use a sparse map instead?
    if (children == null) children = new List(node.nodes.length);
    children[index] = childMap;
  }
  map.children = children;

  return map;
}

Node _cloneAndBindInstance(Node node, Node parent, Document stagingDocument,
    _InstanceBindingMap bindings, model, BindingDelegate delegate,
    List instanceBindings, [TemplateInstance instanceRecord]) {

  var clone = parent.append(stagingDocument.importNode(node, false));

  int i = 0;
  for (var c = node.firstChild; c != null; c = c.nextNode, i++) {
    var childMap = bindings != null ? bindings.getChild(i) : null;
    _cloneAndBindInstance(c, clone, stagingDocument, childMap, model, delegate,
        instanceBindings);
  }

  if (bindings.isTemplate) {
    TemplateBindExtension.decorate(clone, node);
    if (delegate != null) {
      templateBindFallback(clone).bindingDelegate = delegate;
    }
  }

  _processBindings(clone, bindings, model, instanceBindings);
  return clone;
}

// TODO(rafaelw): Setup a MutationObserver on content which clears the expando
// so that bindingMaps regenerate when template.content changes.
_getInstanceBindingMap(DocumentFragment content, BindingDelegate delegate) {
  if (delegate == null) delegate = BindingDelegate._DEFAULT;

  if (delegate._bindingMaps == null) delegate._bindingMaps = new Expando();
  var map = delegate._bindingMaps[content];
  if (map == null) {
    map = _createInstanceBindingMap(content, delegate);
    delegate._bindingMaps[content] = map;
  }
  return map;
}
