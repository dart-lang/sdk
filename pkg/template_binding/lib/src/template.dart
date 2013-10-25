// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to [Element]s that behave as templates. */
class TemplateBindExtension extends _ElementExtension {
  var _model;
  BindingDelegate _bindingDelegate;
  _TemplateIterator _templateIterator;
  bool _scheduled = false;

  Element _templateInstanceRef;

  // Note: only used if `this is! TemplateElement`
  DocumentFragment _content;
  bool _templateIsDecorated;

  TemplateBindExtension._(Element node) : super(node);

  Element get _node => super._node;

  NodeBinding bind(String name, model, [String path]) {
    switch (name) {
      case 'bind':
      case 'repeat':
      case 'if':
        _self.unbind(name);
        if (_templateIterator == null) {
          _templateIterator = new _TemplateIterator(_node);
        }
        return bindings[name] = new _TemplateBinding(this, name, model, path);
      default:
        return super.bind(name, model, path);
    }
  }

  /**
   * Creates an instance of the template, using the provided model and optional
   * binding delegate.
   */
  DocumentFragment createInstance([model, BindingDelegate delegate]) {
    var instance = _createDeepCloneAndDecorateTemplates(
        templateBind(ref).content, delegate);

    _addBindings(instance, model, delegate);
    _addTemplateInstanceRecord(instance, model);
    return instance;
  }

  /** The data model which is inherited through the tree. */
  get model => _model;

  void set model(value) {
    _model = value;
    _ensureSetModelScheduled();
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
        // TODO(jmesserly): this is just an assert in MDV.
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
      var doc = _getTemplateContentsOwner(
          templateElementExt._node.ownerDocument);
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

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#dfn-template-contents-owner
  static Document _getTemplateContentsOwner(HtmlDocument doc) {
    if (doc.window == null) {
      return doc;
    }
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

  static void _injectStylesheet() {
    if (_initStyles == true) return;
    _initStyles = true;

    var style = new StyleElement();
    style.text = r'''
template,
thead[template],
tbody[template],
tfoot[template],
th[template],
tr[template],
td[template],
caption[template],
colgroup[template],
col[template],
option[template] {
  display: none;
}''';
    document.head.append(style);
  }
}

class _TemplateBinding extends NodeBinding {
  TemplateBindExtension _ext;

  // TODO(jmesserly): MDV uses TemplateIterator as the node, see:
  // https://github.com/Polymer/mdv/issues/127
  _TemplateBinding(ext, name, model, path)
      : _ext = ext, super(ext._node, name, model, path) {
    _ext._templateIterator.inputs.bind(property, model, this.path);
  }

  // These are no-ops because we don't use the underlying PathObserver.
  void _observePath() {}
  void valueChanged(newValue) {}

  void close() {
    if (closed) return;
    var templateIterator = _ext._templateIterator;
    if (templateIterator != null) templateIterator.inputs.unbind(property);
    super.close();
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
