// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Element] API. */
class _ElementExtension extends _NodeExtension {
  _ElementExtension(Element node) : super(node);

  // TODO(jmesserly): should path be optional, and default to empty path?
  // It is used that way in at least one path in JS TemplateElement tests
  // (see "BindImperative" test in original JS code).
  NodeBinding createBinding(String name, model, String path) =>
      new _AttributeBinding(node, name, model, path);
}

class _AttributeBinding extends NodeBinding {
  final bool conditional;

  _AttributeBinding._(node, name, model, path, this.conditional)
      : super(node, name, model, path);

  factory _AttributeBinding(Element node, name, model, path) {
    bool conditional = name.endsWith('?');
    if (conditional) {
      node.xtag.attributes.remove(name);
      name = name.substring(0, name.length - 1);
    }
    return new _AttributeBinding._(node, name, model, path, conditional);
  }

  Element get node => super.node;

  void boundValueChanged(value) {
    if (conditional) {
      if (_toBoolean(value)) {
        node.xtag.attributes[property] = '';
      } else {
        node.xtag.attributes.remove(property);
      }
    } else {
      // TODO(jmesserly): escape value if needed to protect against XSS.
      // See https://github.com/polymer-project/mdv/issues/58
      node.xtag.attributes[property] = sanitizeBoundValue(value);
    }
  }
}
