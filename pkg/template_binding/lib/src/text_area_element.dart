// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [TextAreaElement] API. */
class _TextAreaElementExtension extends _ElementExtension {
  _TextAreaElementExtension(TextAreaElement node) : super(node);

  TextAreaElement get _node => super._node;

  Bindable bind(String name, value, {bool oneTime: false}) {
    if (name != 'value') return super.bind(name, value, oneTime: oneTime);

    _node.attributes.remove(name);
    if (oneTime) {
      _InputBinding._updateProperty(_node, value, name);
      return null;
    }

    return _maybeUpdateBindings(name, new _InputBinding(_node, value, name));
  }
}
