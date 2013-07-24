// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Element] API. */
class _ElementExtension extends _NodeExtension {
  _ElementExtension(Element node) : super(node);

  Element get node => super.node;

  Map<String, StreamSubscription> _attributeBindings;

  // TODO(jmesserly): should path be optional, and default to empty path?
  // It is used that way in at least one path in JS TemplateElement tests
  // (see "BindImperative" test in original JS code).
  void bind(String name, model, String path) {
    if (_attributeBindings == null) {
      _attributeBindings = new Map<String, StreamSubscription>();
    }

    var changed;
    if (name.endsWith('?')) {
      node.xtag.attributes.remove(name);
      name = name.substring(0, name.length - 1);

      changed = (value) {
        if (_toBoolean(value)) {
          node.xtag.attributes[name] = '';
        } else {
          node.xtag.attributes.remove(name);
        }
      };
    } else {
      changed = (value) {
        // TODO(jmesserly): escape value if needed to protect against XSS.
        // See https://github.com/polymer-project/mdv/issues/58
        node.xtag.attributes[name] = value == null ? '' : '$value';
      };
    }

    unbind(name);

    _attributeBindings[name] = new PathObserver(model, path).bindSync(changed);
  }

  void unbind(String name) {
    if (_attributeBindings != null) {
      var binding = _attributeBindings.remove(name);
      if (binding != null) binding.cancel();
    }
  }

  void unbindAll() {
    if (_attributeBindings != null) {
      for (var binding in _attributeBindings.values) {
        binding.cancel();
      }
      _attributeBindings = null;
    }
  }
}
