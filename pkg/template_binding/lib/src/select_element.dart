// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [SelectElement] API. */
class _SelectElementExtension extends _ElementExtension {
  _SelectElementExtension(SelectElement node) : super(node);

  SelectElement get _node => super._node;

  NodeBinding createBinding(String name, model, String path) {
    if (name.toLowerCase() == 'selectedindex') {
      // TODO(rafaelw): Maybe template should remove all binding instructions.
      _node.attributes.remove(name);
      return new _SelectedIndexBinding(_node, model, path);
    }
    return super.createBinding(name, model, path);
  }
}
