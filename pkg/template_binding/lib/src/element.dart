// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Element] API. */
class _ElementExtension extends NodeBindExtension {
  _ElementExtension(Element node) : super._(node);

  NodeBinding bind(String name, model, [String path]) {
    _self.unbind(name);

    var binding;
    if (_node is OptionElement && name == 'value') {
      // Note: because <option> can be a semantic template, <option> will be
      // a TemplateBindExtension sometimes. So we need to handle it here.
      (_node as OptionElement).attributes.remove(name);
      binding = new _OptionValueBinding(_node, model, path);
    } else {
      binding = new _AttributeBinding(_node, name, model, path);
    }
    return bindings[name] = binding;
  }
}

class _AttributeBinding extends NodeBinding {
  final bool conditional;

  _AttributeBinding._(node, name, model, path, this.conditional)
      : super(node, name, model, path);

  factory _AttributeBinding(Element node, name, model, path) {
    bool conditional = name.endsWith('?');
    if (conditional) {
      node.attributes.remove(name);
      name = name.substring(0, name.length - 1);
    }
    return new _AttributeBinding._(node, name, model, path, conditional);
  }

  Element get node => super.node;

  void valueChanged(value) {
    if (conditional) {
      if (_toBoolean(value)) {
        node.attributes[property] = '';
      } else {
        node.attributes.remove(property);
      }
    } else {
      // TODO(jmesserly): escape value if needed to protect against XSS.
      // See https://github.com/polymer-project/mdv/issues/58
      node.attributes[property] = sanitizeBoundValue(value);
    }
  }
}

class _OptionValueBinding extends _ValueBinding {
  _OptionValueBinding(node, model, path) : super(node, model, path);

  OptionElement get node => super.node;

  void valueChanged(newValue) {
    var oldValue = null;
    var selectBinding = null;
    var select = node.parent;
    if (select is SelectElement) {
      var valueBinding = nodeBind(select).bindings['value'];
      if (valueBinding is _SelectBinding) {
        selectBinding = valueBinding;
        oldValue = select.value;
      }
    }

    super.valueChanged(newValue);

    if (selectBinding != null && !selectBinding.closed &&
        select.value != oldValue) {
      selectBinding.nodeValueChanged(null);
    }
  }
}
