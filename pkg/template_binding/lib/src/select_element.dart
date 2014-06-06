// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [SelectElement] API. */
class _SelectElementExtension extends _ElementExtension {
  _SelectElementExtension(SelectElement node) : super(node);

  SelectElement get _node => super._node;

  Bindable bind(String name, value, {bool oneTime: false}) {
    if (name == 'selectedindex') name = 'selectedIndex';
    if (name != 'selectedIndex' && name != 'value') {
      return super.bind(name, value, oneTime: oneTime);
    }

    // TODO(jmesserly): merge logic here with InputElement, it's the same except
    // for the addition of selectedIndex as a valid property name.
    _node.attributes.remove(name);
    if (oneTime) {
      _InputBinding._updateProperty(_node, value, name);
      return null;
    }

    // Option update events may need to access select bindings.
    return _updateBindings(name, new _InputBinding(_node, value, name));
  }
}
