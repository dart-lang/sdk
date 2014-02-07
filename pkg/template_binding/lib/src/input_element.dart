// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [InputElement] API. */
class _InputElementExtension extends _ElementExtension {
  _InputElementExtension(InputElement node) : super(node);

  InputElement get _node => super._node;

  Bindable bind(String name, value, {bool oneTime: false}) {
    if (name != 'value' && name != 'checked') {
      return super.bind(name, value, oneTime: oneTime);
    }

    _node.attributes.remove(name);
    if (oneTime) {
      _InputBinding._updateProperty(_node, value, name);
      return null;
    }

    _self.unbind(name);
    return bindings[name] = new _InputBinding(_node, value, name);
  }
}
