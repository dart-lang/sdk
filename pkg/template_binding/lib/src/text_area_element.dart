// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [TextAreaElement] API. */
class _TextAreaElementExtension extends _ElementExtension {
  _TextAreaElementExtension(TextAreaElement node) : super(node);

  TextAreaElement get _node => super._node;

  NodeBinding bind(String name, model, [String path]) {
    if (name != 'value') return super.bind(name, model, path);

    _self.unbind(name);
    _node.attributes.remove(name);
    return bindings[name] = new _ValueBinding(_node, model, path);
  }
}
