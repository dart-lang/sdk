// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to [Element]s that behave as templates. */
class TemplateBindExtension extends _ElementExtension {
  var _model;
  BindingDelegate _bindingDelegate;
  _TemplateIterator _iterator;
  bool _scheduled = false;

  Element _templateInstanceRef;

  // Note: only used if `this is! TemplateElement`
  DocumentFragment _content;
  bool _templateIsDecorated;

  HtmlDocument _stagingDocument;

  var _bindingMap;

  TemplateBindExtension._(Element node) : super(node);

  Element get _node => super._node;

  TemplateBindExtension get _self => super._node is TemplateBindExtension
      ? _node : this;

  NodeBinding bind(String name, model, [String path]) {
    path = path != null ? path : '';

    if (_iterator == null) {
      // TODO(jmesserly): since there's only one iterator, we could just
      // inline it into this object.
      _iterator = new _TemplateIterator(this);
    }

    // Dart note: we return _TemplateBinding instead of _iterator.
    // See comment on _TemplateBinding class.
    switch (name) {
      case 'bind':
        _iterator..hasBind = true
            ..bindModel = model
            ..bindPath = path;
        _scheduleIterator();
        return bindings[name] = new _TemplateBinding(this, name, model, path);
      case 'repeat':
        _iterator..hasRepeat = true
            ..repeatModel = model
            ..repeatPath = path;
        _scheduleIterator();
        return bindings[name] = new _TemplateBinding(this, name, model, path);
      case 'if':
        _iterator..hasIf = true
            ..ifModel = model
            ..ifPath = path;
        _scheduleIterator();
        return bindings[name] = new _TemplateBinding(this, name, model, path);
      default:
        return super.bind(name, model, path);
    }
  }

  void unbind(String name) {
    switch (name) {
      case 'bind':
        if (_iterator == null) return;
        _iterator..hasBind = false
            ..bindModel = null
            ..bindPath = null;
        _scheduleIterator();
        bindings.remove(name);
        return;
      case 'repeat':
        if (_iterator == null) return;
        _iterator..hasRepeat = false
            ..repeatModel = null
            ..repeatPath = null;
        _scheduleIterator();
        bindings.remove(name);
        return;
      case 'if':
        if (_iterator == null) return;
        _iterator..hasIf = false
            ..ifModel = null
            ..ifPath = null;
        _scheduleIterator();
        bindings.remove(name);
        return;
      default:
        super.unbind(name);
        return;
    }
  }

  void _scheduleIterator() {
    if (!_iterator.depsChanging) {
      _iterator.depsChanging = true;
      scheduleMicrotask(_iterator.resolve);
    }
  }

  /**
   * Creates an instance of the template, using the provided model and optional
   * binding delegate.
   */
  DocumentFragment createInstance([model, BindingDelegate delegate,
      List<NodeBinding> bound]) {
    var ref = templateBind(this.ref);
    var content = ref.content;
    // Dart note: we store _bindingMap on the TemplateBindExtension instead of
    // the "content" because we already have an expando for it.
    var map = ref._bindingMap;
    if (map == null) {
      // TODO(rafaelw): Setup a MutationObserver on content to detect
      // when the instanceMap is invalid.
      map = _createInstanceBindingMap(content, delegate);
      ref._bindingMap = map;
    }

    var staging = _getTemplateStagingDocument();
    var instance = _deepCloneIgnoreTemplateContent(content, staging);

    _addMapBindings(instance, map, model, delegate, bound);
    // TODO(rafaelw): We can do this more lazily, but setting a sentinel
    // in the parent of the template element, and creating it when it's
    // asked for by walking back to find the iterating template.
    _addTemplateInstanceRecord(instance, model);
    return instance;
  }

  /** The data model which is inherited through the tree. */
  get model => _model;

  void set model(value) {
    _model = value;
    _ensureSetModelScheduled();
  }

  static Node _deepCloneIgnoreTemplateContent(Node node, stagingDocument) {
    var clone = stagingDocument.importNode(node, false);
    if (isSemanticTemplate(clone)) return clone;

    for (var c = node.firstChild; c != null; c = c.nextNode) {
      clone.append(_deepCloneIgnoreTemplateContent(c, stagingDocument));
    }
    return clone;
  }

  /**
   * The binding delegate which is inherited through the tree. It can be used
   * to configure custom syntax for `{{bindings}}` inside this template.
   */
  BindingDelegate get bindingDelegate => _bindingDelegate;

  void set bindingDelegate(BindingDelegate value) {
    _bindingDelegate = value;
    _ensureSetModelScheduled();
  }

  _ensureSetModelScheduled() {
    if (_scheduled) return;
    _decorate();
    _scheduled = true;
    scheduleMicrotask(_setModel);
  }

  void _setModel() {
    _scheduled = false;
    _addBindings(_node, _model, _bindingDelegate);
  }

  /** Gets the template this node refers to. */
  Element get ref {
    _decorate();

    Element result = null;
    var refId = _node.attributes['ref'];
    if (refId != null) {
      var treeScope = _getTreeScope(_node);
      if (treeScope != null) {
        result = treeScope.getElementById(refId);
      }
    }

    if (result == null) {
      result = _templateInstanceRef;
      if (result == null) return _node;
    }

    var nextRef = templateBind(result).ref;
    return nextRef != null ? nextRef : result;
  }

  /**
   * Gets the content of this template.
   */
  DocumentFragment get content {
    _decorate();
    return _content != null ? _content : (_node as TemplateElement).content;
  }

  /**
   * Ensures proper API and content model for template elements.
   *
   * [instanceRef] can be used to set the [Element.ref] property of [template],
   * and use the ref's content will be used as source when createInstance() is
   * invoked.
   *
   * Returns true if this template was just decorated, or false if it was
   * already decorated.
   */
  static bool decorate(Element template, [Element instanceRef]) =>
      templateBindFallback(template)._decorate(instanceRef);

  bool _decorate([Element instanceRef]) {
    // == true check because it starts as a null field.
    if (_templateIsDecorated == true) return false;

    _injectStylesheet();

    var templateElementExt = this;
    _templateIsDecorated = true;
    var isNative = _node is TemplateElement;
    var bootstrapContents = isNative;
    var liftContents = !isNative;
    var liftRoot = false;

    if (!isNative && _isAttributeTemplate(_node)) {
      if (instanceRef != null) {
        // TODO(jmesserly): this is just an assert in TemplateBinding.
        throw new ArgumentError('instanceRef should not be supplied for '
            'attribute templates.');
      }
      templateElementExt = templateBind(
          _extractTemplateFromAttributeTemplate(_node));
      templateElementExt._templateIsDecorated = true;
      isNative = templateElementExt._node is TemplateElement;
      liftRoot = true;
     }

    if (!isNative) {
      var doc = _getOrCreateTemplateContentsOwner(templateElementExt._node);
      templateElementExt._content = doc.createDocumentFragment();
    }

    if (instanceRef != null) {
      // template is contained within an instance, its direct content must be
      // empty
      templateElementExt._templateInstanceRef = instanceRef;
    } else if (liftContents) {
      _liftNonNativeChildrenIntoContent(templateElementExt, _node, liftRoot);
    } else if (bootstrapContents) {
      bootstrap(templateElementExt.content);
    }

    return true;
  }

  static final _contentsOwner = new Expando();
  static final _ownerStagingDocument = new Expando();

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#dfn-template-contents-owner
  static HtmlDocument _getOrCreateTemplateContentsOwner(Element template) {
    var doc = template.ownerDocument;
    if (doc.window == null) return doc;

    var d = _contentsOwner[doc];
    if (d == null) {
      // TODO(arv): This should either be a Document or HTMLDocument depending
      // on doc.
      d = doc.implementation.createHtmlDocument('');
      while (d.lastChild != null) {
        d.lastChild.remove();
      }
      _contentsOwner[doc] = d;
    }
    return d;
  }

  HtmlDocument _getTemplateStagingDocument() {
    if (_stagingDocument == null) {
      var owner = _node.ownerDocument;
      var doc = _ownerStagingDocument[owner];
      if (doc == null) {
        doc = owner.implementation.createHtmlDocument('');
        _ownerStagingDocument[owner] = doc;
      }
      _stagingDocument = doc;
    }
    return _stagingDocument;
  }

  // For non-template browsers, the parser will disallow <template> in certain
  // locations, so we allow "attribute templates" which combine the template
  // element with the top-level container node of the content, e.g.
  //
  //   <tr template repeat="{{ foo }}"" class="bar"><td>Bar</td></tr>
  //
  // becomes
  //
  //   <template repeat="{{ foo }}">
  //   + #document-fragment
  //     + <tr class="bar">
  //       + <td>Bar</td>
  //
  static Element _extractTemplateFromAttributeTemplate(Element el) {
    var template = el.ownerDocument.createElement('template');
    el.parentNode.insertBefore(template, el);

    for (var name in el.attributes.keys.toList()) {
      switch (name) {
        case 'template':
          el.attributes.remove(name);
          break;
        case 'repeat':
        case 'bind':
        case 'ref':
          template.attributes[name] = el.attributes.remove(name);
          break;
      }
    }

    return template;
  }

  static void _liftNonNativeChildrenIntoContent(TemplateBindExtension template,
      Element el, bool useRoot) {

    var content = template.content;
    if (useRoot) {
      content.append(el);
      return;
    }

    var child;
    while ((child = el.firstChild) != null) {
      content.append(child);
    }
  }

  /**
   * This used to decorate recursively all templates from a given node.
   *
   * By default [decorate] will be called on templates lazily when certain
   * properties such as [model] are accessed, but it can be run eagerly to
   * decorate an entire tree recursively.
   */
  // TODO(rafaelw): Review whether this is the right public API.
  static void bootstrap(Node content) {
    void _bootstrap(template) {
      if (!TemplateBindExtension.decorate(template)) {
        bootstrap(templateBind(template).content);
      }
    }

    // Need to do this first as the contents may get lifted if |node| is
    // template.
    // TODO(jmesserly): content is DocumentFragment or Element
    var descendents =
        (content as dynamic).querySelectorAll(_allTemplatesSelectors);
    if (isSemanticTemplate(content)) {
      _bootstrap(content);
    }

    descendents.forEach(_bootstrap);
  }

  static final String _allTemplatesSelectors =
      'template, ' +
      _SEMANTIC_TEMPLATE_TAGS.keys.map((k) => "$k[template]").join(", ");

  static bool _initStyles;

  // This is to replicate template_element.css
  // TODO(jmesserly): move this to an opt-in CSS file?
  static void _injectStylesheet() {
    if (_initStyles == true) return;
    _initStyles = true;

    var style = new StyleElement()
        ..text = '$_allTemplatesSelectors { display: none; }';
    document.head.append(style);
  }
}

// TODO(jmesserly): https://github.com/polymer/templatebinding uses
// TemplateIterator as the binding. This is a nice performance optimization,
// however it means it doesn't share any of the reflective APIs with
// NodeBinding: https://github.com/Polymer/TemplateBinding/issues/147
class _TemplateBinding implements NodeBinding {
  TemplateBindExtension _ext;
  Object _model;
  final String property;
  final String path;

  Node get node => _ext._node;

  get model => _model;

  bool get closed => _ext == null;

  get value => _observer.value;

  set value(newValue) {
    _observer.value = newValue;
  }

  // No need to cache this since we only have it to support get/set value.
  get _observer {
    if ((_model is PathObserver || _model is CompoundPathObserver) &&
        path == 'value') {
      return _model;
    }
    return new PathObserver(_model, path);
  }

  _TemplateBinding(this._ext, this.property, this._model, this.path);

  void valueChanged(newValue) {}

  sanitizeBoundValue(value) => value == null ? '' : '$value';

  void close() {
    if (closed) return;

    // TODO(jmesserly): unlike normal NodeBinding.close methods this will remove
    // the binding from _node.bindings. Is that okay?
    _ext.unbind(property);

    _model = null;
    _ext = null;
  }
}

_getTreeScope(Node node) {
  while (node.parentNode != null) {
    node = node.parentNode;
  }

  // Note: JS code tests that getElementById is present. We can't do that
  // easily, so instead check for the types known to implement it.
  if (node is Document || node is ShadowRoot || node is SvgSvgElement) {
    return node;
  }
  return null;
}
