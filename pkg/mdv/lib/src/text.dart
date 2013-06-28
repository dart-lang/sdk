// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Text] API. */
class _TextExtension extends _NodeExtension {
  _TextExtension(Text node) : super(node);

  Text get node => super.node;

  StreamSubscription _textBinding;

  void bind(String name, model, String path) {
    if (name != 'text') {
      super.bind(name, model, path);
      return;
    }

    unbind('text');

    _textBinding = new PathObserver(model, path).bindSync((value) {
      node.text = value == null ? '' : '$value';
    });
  }

  void unbind(String name) {
    if (name != 'text') {
      super.unbind(name);
      return;
    }

    if (_textBinding == null) return;

    _textBinding.cancel();
    _textBinding = null;
  }

  void unbindAll() {
    unbind('text');
    super.unbindAll();
  }
}
