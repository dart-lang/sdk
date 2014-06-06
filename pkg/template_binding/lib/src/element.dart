// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Element] API. */
class _ElementExtension extends NodeBindExtension {
  _ElementExtension(Element node) : super._(node);

  bind(String name, value, {bool oneTime: false}) {
    Element node = _node;

    if (node is OptionElement && name == 'value') {
      // Note: because <option> can be a semantic template, <option> will be
      // a TemplateBindExtension sometimes. So we need to handle it here.
      node.attributes.remove(name);

      if (oneTime) return _updateOption(value);
      _open(value, _updateOption);
    } else {
      bool conditional = name.endsWith('?');
      if (conditional) {
        node.attributes.remove(name);
        name = name.substring(0, name.length - 1);
      }

      if (oneTime) return _updateAttribute(_node, name, conditional, value);

      _open(value, (x) => _updateAttribute(_node, name, conditional, x));
    }
    return _maybeUpdateBindings(name, value);
  }

  void _updateOption(newValue) {
    OptionElement node = _node;
    var oldValue = null;
    var selectBinding = null;
    var select = node.parentNode;
    if (select is SelectElement) {
      var bindings = nodeBind(select).bindings;
      if (bindings != null) {
        var valueBinding = bindings['value'];
        if (valueBinding is _InputBinding) {
          selectBinding = valueBinding;
          oldValue = select.value;
        }
      }
    }

    node.value = _sanitizeValue(newValue);

    if (selectBinding != null && select.value != oldValue) {
      selectBinding.value = select.value;
    }
  }
}

void _updateAttribute(Element node, String name, bool conditional, value) {
  if (conditional) {
    if (_toBoolean(value)) {
      node.attributes[name] = '';
    } else {
      node.attributes.remove(name);
    }
  } else {
    // TODO(jmesserly): escape value if needed to protect against XSS.
    // See https://github.com/polymer-project/mdv/issues/58
    node.attributes[name] = _sanitizeValue(value);
  }
}
