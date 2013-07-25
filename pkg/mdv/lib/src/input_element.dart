// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [InputElement] API. */
class _InputElementExtension extends _ElementExtension {
  _InputElementExtension(InputElement node) : super(node);

  InputElement get node => super.node;

  NodeBinding createBinding(String name, model, String path) {
    if (name == 'value') {
      // TODO(rafaelw): Maybe template should remove all binding instructions.
      node.attributes.remove(name);
      return new _ValueBinding(node, model, path);
    }
    if (name == 'checked') {
      node.attributes.remove(name);
      return new _CheckedBinding(node, model, path);
    }
    return super.createBinding(name, model, path);
  }
}
