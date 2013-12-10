// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

class _InstanceBindingMap {
  final List bindings;
  final Map<int, _InstanceBindingMap> children;
  final Node templateRef;

  // Workaround for:
  // https://github.com/Polymer/TemplateBinding/issues/150
  final int numChildren;

  _InstanceBindingMap._(this.bindings, this.children, this.templateRef,
      this.numChildren);
}

_InstanceBindingMap _createInstanceBindingMap(Node node,
    BindingDelegate delegate) {

  var bindings = _getBindings(node, delegate);
  Node templateRef = null;

  if (isSemanticTemplate(node)) templateRef = node;

  Map children = null;
  int i = 0;
  for (var c = node.firstChild; c != null; c = c.nextNode, i++) {
    var childMap = _createInstanceBindingMap(c, delegate);
    if (childMap == null) continue;

    if (children == null) children = new HashMap();
    children[i] = childMap;
  }

  if (bindings == null && children == null && templateRef == null) return null;

  return new _InstanceBindingMap._(bindings, children, templateRef, i);
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

  // To workaround https://github.com/Polymer/TemplateBinding/issues/150,
  // we try and detect cases where creating a custom element resulted in extra
  // children compared to what we expected. We assume these new children are all
  // at the beginning, because _deepCloneIgnoreTemplateContent creates the
  // element then appends the template content's children to the end.

  int i = map.numChildren - node.nodes.length;
  for (var c = node.firstChild; c != null; c = c.nextNode, i++) {
    if (i < 0) continue;
    _addMapBindings(c, map.children[i], model, delegate, bound);
  }
}
