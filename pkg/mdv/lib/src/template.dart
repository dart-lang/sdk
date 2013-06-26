// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to [Element]s that behave as templates. */
class _TemplateExtension extends _ElementExtension {
  var _model;
  _TemplateIterator _templateIterator;

  _TemplateExtension(Element node) : super(node);

  void bind(String name, model, String path) {
    switch (name) {
      case 'bind':
      case 'repeat':
      case 'if':
        if (_templateIterator == null) {
          _templateIterator = new _TemplateIterator(node);
        }
        _templateIterator.inputs.bind(name, model, path);
        return;
      default:
        super.bind(name, model, path);
    }
  }

  void unbind(String name) {
    switch (name) {
      case 'bind':
      case 'repeat':
      case 'if':
        if (_templateIterator != null) {
          _templateIterator.inputs.unbind(name);
        }
        return;
      default:
        super.unbind(name);
    }
  }

  void unbindAll() {
    unbind('bind');
    unbind('repeat');
    unbind('if');
    super.unbindAll();
  }

  /**
   * Creates an instance of the template.
   */
  DocumentFragment createInstance() {
    var template = node.ref;
    if (template == null) template = node;

    var instance = _Bindings._createDeepCloneAndDecorateTemplates(
        template.content, node.attributes['syntax']);

    if (_instanceCreated != null) {
      _instanceCreated.add(instance);
    }
    return instance;
  }

  /**
   * The data model which is inherited through the tree.
   */
  get model => _model;

  void set model(value) {
    var syntax = TemplateElement.syntax[node.attributes['syntax']];
    _model = value;
    _Bindings._addBindings(node, model, syntax);
  }
}
