// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

class _InstanceBindingMap {
  final List bindings;
  final List<_InstanceBindingMap> children;
  final Node templateRef;
  final bool hasSubTemplate;

  _InstanceBindingMap._(this.bindings, this.children, this.templateRef,
      this.hasSubTemplate);

  factory _InstanceBindingMap(Node node, BindingDelegate delegate) {
    var bindings = _getBindings(node, delegate);

    bool hasSubTemplate = false;
    Node templateRef = null;

    if (isSemanticTemplate(node)) {
      templateRef = node;
      hasSubTemplate = true;
    }

    List children = null;
    for (var c = node.firstChild, i = 0; c != null; c = c.nextNode, i++) {
      var childMap = new _InstanceBindingMap(c, delegate);
      if (childMap == null) continue;

      if (children == null) children = new List(node.nodes.length);
      children[i] = childMap;
      if (childMap.hasSubTemplate) {
        hasSubTemplate = true;
      }
    }

    return new _InstanceBindingMap._(bindings, children, templateRef,
        hasSubTemplate);
  }
}


void _addMapBindings(Node node, _InstanceBindingMap map, model,
    BindingDelegate delegate, List bound) {
  if (map == null) return;

  if (map.templateRef != null) {
    TemplateBindExtension.decorate(node, map.templateRef);
    if (delegate != null) {
      templateBindFallback(node)._bindingDelegate = delegate;
    }
  }

  if (map.bindings != null) {
    _processBindings(map.bindings, node, model, bound);
  }

  if (map.children == null) return;

  int i = 0;
  for (var c = node.firstChild; c != null; c = c.nextNode) {
    _addMapBindings(c, map.children[i++], model, delegate, bound);
  }
}
