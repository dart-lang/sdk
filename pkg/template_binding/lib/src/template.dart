// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to [Element]s that behave as templates. */
class TemplateBindExtension extends _ElementExtension {
  var _model;
  BindingDelegate _bindingDelegate;
  _TemplateIterator _iterator;
  bool _setModelScheduled = false;

  Element _templateInstanceRef;

  // Note: only used if `this is! TemplateElement`
  DocumentFragment _content;
  bool _templateIsDecorated;

  HtmlDocument _stagingDocument;

  _InstanceBindingMap _bindingMap;

  TemplateBindExtension._(Element node) : super(node);

  Element get _node => super._node;

  TemplateBindExtension get _self => super._node is TemplateBindExtension
      ? _node : this;

  _TemplateIterator _processBindingDirectives(_TemplateBindingMap directives) {
    if (_iterator != null) _iterator._closeDependencies();

    if (directives._if == null &&
        directives._bind == null &&
        directives._repeat == null) {

      if (_iterator != null) {
        _iterator.close();
        _iterator = null;
        bindings.remove('iterator');
      }
      return null;
    }

    if (_iterator == null) {
      bindings['iterator'] = _iterator = new _TemplateIterator(this);
    }

    _iterator._updateDependencies(directives, model);
    return _iterator;
  }

  /**
   * Creates an instance of the template, using the provided [model] and
   * optional binding [delegate].
   *
   * If [instanceBindings] is supplied, each [Bindable] in the returned
   * instance will be added to the list. This makes it easy to close all of the
   * bindings without walking the tree. This is not normally necesssary, but is
   * used internally by the system.
   */
  DocumentFragment createInstance([model, BindingDelegate delegate,
      List<Bindable> instanceBindings]) {

    final content = templateBind(ref).content;
    // Dart note: we store _bindingMap on the TemplateBindExtension instead of
    // the "content" because we already have an expando for it.
    var map = _bindingMap;
    if (map == null || !identical(map.content, content)) {
      // TODO(rafaelw): Setup a MutationObserver on content to detect
      // when the instanceMap is invalid.
      map = _createInstanceBindingMap(content, delegate);
      map.content = content;
      _bindingMap = map;
    }

    final staging = _getTemplateStagingDocument();
    final instance = _stagingDocument.createDocumentFragment();
    _templateCreator[instance] = _node;

    final instanceRecord = new TemplateInstance(model);

    var i = 0;
    for (var c = content.firstChild; c != null; c = c.nextNode, i++) {
      final childMap = map != null ? map.getChild(i) : null;
      var clone = _cloneAndBindInstance(c, instance, _stagingDocument,
          childMap, model, delegate, instanceBindings);
      nodeBindFallback(clone)._templateInstance = instanceRecord;
    }

    instanceRecord._firstNode = instance.firstChild;
    instanceRecord._lastNode = instance.lastChild;

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

    // Clear cached state based on the binding delegate.
    _bindingMap = null;
    if (_iterator != null) {
      _iterator._initPrepareFunctions = false;
      _iterator._instanceModelFn = null;
      _iterator._instancePositionChangedFn = null;
    }
  }

  _ensureSetModelScheduled() {
    if (_setModelScheduled) return;
    _decorate();
    _setModelScheduled = true;
    scheduleMicrotask(_setModel);
  }

  void _setModel() {
    _setModelScheduled = false;
    var map = _getBindings(_node, _bindingDelegate);
    _processBindings(_node, map, _model);
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
      if (result == null) {
        var instanceRoot = _getInstanceRoot(_node);

        // TODO(jmesserly): this won't work if refId is a number
        // Similar to bug: https://github.com/Polymer/ShadowDOM/issues/340
        if (instanceRoot != null) {
          result = instanceRoot.querySelector('#$refId');
        }
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
    var isNativeHtmlTemplate = _node is TemplateElement;
    final bootstrapContents = isNativeHtmlTemplate;
    final liftContents = !isNativeHtmlTemplate;
    var liftRoot = false;

    if (!isNativeHtmlTemplate) {
      if (_isAttributeTemplate(_node)) {
        if (instanceRef != null) {
          // Dart note: this is just an assert in JS.
          throw new ArgumentError('instanceRef should not be supplied for '
              'attribute templates.');
        }
        templateElementExt = templateBind(
            _extractTemplateFromAttributeTemplate(_node));
        templateElementExt._templateIsDecorated = true;
        isNativeHtmlTemplate = templateElementExt._node is TemplateElement;
        liftRoot = true;
      } else if (_isSvgTemplate(_node)) {
        templateElementExt = templateBind(
            _extractTemplateFromSvgTemplate(_node));
        templateElementExt._templateIsDecorated = true;
        isNativeHtmlTemplate = templateElementExt._node is TemplateElement;
      }
    }

    if (!isNativeHtmlTemplate) {
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

  static Element _extractTemplateFromSvgTemplate(Element el) {
    var template = el.ownerDocument.createElement('template');
    el.parentNode.insertBefore(template, el);
    template.attributes.addAll(el.attributes);

    el.attributes.clear();
    el.remove();
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

final _templateCreator = new Expando();

_getTreeScope(Node node) {
  while (true) {
    var parent = node.parentNode;
    if (parent != null) {
      node = parent;
    } else {
      var creator = _templateCreator[node];
      if (creator == null) break;

      node = creator;
    }
  }

  // Note: JS code tests that getElementById is present. We can't do that
  // easily, so instead check for the types known to implement it.
  if (node is Document || node is ShadowRoot || node is SvgSvgElement) {
    return node;
  }
  return null;
}

_getInstanceRoot(node) {
  while (node.parentNode != null) {
    node = node.parentNode;
  }
  return _templateCreator[node] != null ? node : null;
}
