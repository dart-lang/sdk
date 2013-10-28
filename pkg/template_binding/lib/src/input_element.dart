// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [InputElement] API. */
class _InputElementExtension extends _ElementExtension {
  _InputElementExtension(InputElement node) : super(node);

  InputElement get _node => super._node;

  NodeBinding bind(String name, model, [String path]) {
    if (name != 'value' && name != 'checked') {
      return super.bind(name, model, path);
    }

    _self.unbind(name);
    _node.attributes.remove(name);
    return bindings[name] = name == 'value' ?
        new _ValueBinding(_node, model, path) :
        new _CheckedBinding(_node, model, path);
  }
}
