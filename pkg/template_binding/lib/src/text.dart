// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Text] API. */
class _TextExtension extends NodeBindExtension {
  _TextExtension(Text node) : super._(node);

  NodeBinding createBinding(String name, model, String path) {
    if (name == 'text') return new _TextBinding(_node, model, path);
    return super.createBinding(name, model, path);
  }
}

class _TextBinding extends NodeBinding {
  _TextBinding(node, model, path) : super(node, 'text', model, path);

  void boundValueChanged(newValue) {
    node.text = sanitizeBoundValue(newValue);
  }
}
