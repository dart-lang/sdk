// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Text] API. */
class _TextExtension extends NodeBindExtension {
  _TextExtension(Text node) : super._(node);

  NodeBinding bind(String name, model, [String path]) {
    // Dart note: 'text' instead of 'textContent' to match the DOM property.
    if (name != 'text') {
      return super.bind(name, model, path);
    }
    unbind(name);
    return bindings[name] = new _TextBinding(_node, model, path);
  }
}

class _TextBinding extends NodeBinding {
  _TextBinding(node, model, path) : super(node, 'text', model, path);

  void valueChanged(newValue) {
    node.text = sanitizeBoundValue(newValue);
  }
}
