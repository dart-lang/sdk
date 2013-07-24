// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [TextAreaElement] API. */
class _TextAreaElementExtension extends _ElementExtension {
  _ValueBinding _valueBinding;

  _TextAreaElementExtension(TextAreaElement node) : super(node);

  TextAreaElement get node => super.node;

  void bind(String name, model, String path) {
    if (name.toLowerCase() == 'value') {
      unbind('value');
      node.attributes.remove('value');
      _valueBinding = new _ValueBinding(node, model, path);
    }
  }

  void unbind(String name) {
    if (name.toLowerCase() == 'value' && _valueBinding != null) {
      _valueBinding.unbind();
      _valueBinding = null;
    }
  }

  void unbindAll() {
    unbind('value');
    super.unbindAll();
  }
}
