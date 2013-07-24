// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [InputElement] API. */
class _InputElementExtension extends _ElementExtension {
  _ValueBinding _valueBinding;
  _CheckedBinding _checkedBinding;

  _InputElementExtension(InputElement node) : super(node);

  InputElement get node => super.node;

  void bind(String name, model, String path) {
    switch (name.toLowerCase()) {
      case 'value':
        unbind('value');
        node.attributes.remove('value');
        _valueBinding = new _ValueBinding(node, model, path);
        break;
      case 'checked':
        unbind('checked');
        node.attributes.remove('checked');
        _checkedBinding = new _CheckedBinding(node, model, path);
        break;
      default:
        super.bind(name, model, path);
        break;
    }
  }

  void unbind(String name) {
    switch (name.toLowerCase()) {
      case 'value':
        if (_valueBinding != null) {
          _valueBinding.unbind();
          _valueBinding = null;
        }
        break;
      case 'checked':
        if (_checkedBinding != null) {
          _checkedBinding.unbind();
          _checkedBinding = null;
        }
        break;
      default:
        super.unbind(name);
        break;
    }
  }

  void unbindAll() {
    unbind('value');
    unbind('checked');
    super.unbindAll();
  }
}
