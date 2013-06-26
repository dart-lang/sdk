// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Node] API. */
class _NodeExtension {
  final Node node;

  _NodeExtension(this.node);

  /**
   * Binds the attribute [name] to the [path] of the [model].
   * Path is a String of accessors such as `foo.bar.baz`.
   */
  void bind(String name, model, String path) {
    window.console.error('Unhandled binding to Node: '
        '$this $name $model $path');
  }

  /** Unbinds the attribute [name]. */
  void unbind(String name) {}

  /** Unbinds all bound attributes. */
  void unbindAll() {}

  TemplateInstance _templateInstance;

  /** Gets the template instance that instantiated this node, if any. */
  TemplateInstance get templateInstance =>
      _templateInstance != null ? _templateInstance :
      (node.parent != null ? node.parent.templateInstance : null);
}
