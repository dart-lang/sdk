// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [SelectElement] API. */
class _SelectElementExtension extends _ElementExtension {
  _SelectedIndexBinding _valueBinding;

  _SelectElementExtension(SelectElement node) : super(node);

  SelectElement get node => super.node;

  void bind(String name, model, String path) {
    if (name.toLowerCase() == 'selectedindex') {
      unbind('selectedindex');
      node.attributes.remove('selectedindex');
      _valueBinding = new _SelectedIndexBinding(node, model, path);
      return;
    }
    super.bind(name, model, path);
  }

  void unbind(String name) {
    if (name.toLowerCase() == 'selectedindex' && _valueBinding != null) {
      _valueBinding.unbind();
      _valueBinding = null;
      return;
    }
    super.unbind(name);
  }

  void unbindAll() {
    unbind('selectedindex');
    super.unbindAll();
  }
}
