// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [SelectElement] API. */
class _SelectElementExtension extends _ElementExtension {
  _SelectElementExtension(SelectElement node) : super(node);

  SelectElement get _node => super._node;

  NodeBinding bind(String name, model, [String path]) {
    if (name == 'selectedindex') name = 'selectedIndex';
    if (name != 'selectedIndex' && name != 'value') {
      return super.bind(name, model, path);
    }

    _self.unbind(name);
    _node.attributes.remove(name);
    return bindings[name] = new _SelectBinding(_node, name, model, path);
  }
}
