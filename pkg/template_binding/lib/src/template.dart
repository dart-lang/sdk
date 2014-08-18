// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to [Element]s that behave as templates. */
class TemplateBindExtension extends NodeBindExtension {
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

  Node _refContent;

  TemplateBindExtension._(Element node) : super._(node);

  Element get _node => super._node;

  TemplateBindExtension get _self => _node is TemplateBindExtension
      ? _node : this;

  Bindable bind(String name, value, {bool oneTime: false}) {
    if (name != 'ref') return super.bind(name, value, oneTime: oneTime);

    var ref = oneTime ? value : value.open((ref) {
      _node.attributes['ref'] = ref;
      _refChanged();
    });

    _node.attributes['ref'] = ref;
    _refChanged();
    if (oneTime) return null;

    if (bindings == null) bindings = {};
    return bindings['ref'] = value;
  }

  _TemplateIterator _processBindingDirectives(_TemplateBindingMap directives) {
    if (_iterator != null) _iterator._closeDependencies();

    if (directives._if == null &&
        directives._bind == null &&
        directives._repeat == null) {

      if (_iterator != null) {
        _iterator.close();
        _iterator = null;
      }
      return null;
    }

    if (_iterator == null) {
      _iterator = new _TemplateIterator(this);
    }

    _iterator._updateDependencies(directives, model);

    _templateObserver.observe(_node,
        attributes: true, attributeFilter: ['ref']);

    return _iterator;
  }

  /**
   * Creates an instance of the template, using the provided [model] and
   * optional binding [delegate].
   *
   * If [instanceBindings] is supplied, each [Bindable] in the returned
   * instance will be added to the list. This makes it easy to close all of the
   * bindings without walking the tree. This is not normally necessary, but is
   * used internally by the system.
   */
  DocumentFragment createInstance([model, BindingDelegate delegate]) {
    if (delegate == null) delegate = _bindingDelegate;
    if (_refContent == null) _refContent = templateBind(_ref).content;

    var content = _refContent;
    if (content.firstChild == null) return _emptyInstance;

    final map = _getInstanceBindingMap(content, delegate);
    final staging = _getTemplateStagingDocument();
    final instance = _stagingDocument.createDocumentFragment();

    final instanceExt = new _InstanceExtension();
    _instanceExtension[instance] = instanceExt
      .._templateCreator = _node
      .._protoContent = content;

    final instanceRecord = new TemplateInstance(model);
    nodeBindFallback(instance)._templateInstance = instanceRecord;

    var i = 0;
    bool collectTerminator = false;
    for (var c = content.firstChild; c != null; c = c.nextNode, i++) {
      // The terminator of the instance is the clone of the last child of the
      // content. If the last child is an active template, it may produce
      // instances as a result of production, so simply collecting the last
      // child of the instance after it has finished producing may be wrong.
      if (c.nextNode == null) collectTerminator = true;

      final childMap = map != null ? map.getChild(i) : null;
      var clone = _cloneAndBindInstance(c, instance, _stagingDocument,
          childMap, model, delegate, instanceExt._bindings);

      nodeBindFallback(clone)._templateInstance = instanceRecord;
      if (collectTerminator) instanceExt._terminator = clone;
    }

    instanceRecord._firstNode = instance.firstChild;
    instanceRecord._lastNode = instance.lastChild;

    instanceExt._protoContent = null;
    instanceExt._templateCreator = null;
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
    if (_bindingDelegate != null) {
      throw new StateError('Template must be cleared before a new '
          'bindingDelegate can be assigned');
    }
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

  _refChanged() {
    if (_iterator == null || _refContent == templateBind(_ref).content) return;

    _refContent = null;
    _iterator._valueChanged(null);
    _iterator._updateIteratedValue(null);
  }

  void clear() {
    _model = null;
    _bindingDelegate = null;
    if (bindings != null) {
      var ref = bindings.remove('ref');
      if (ref != null) ref.close();
    }
    _refContent = null;
    if (_iterator == null) return;
    _iterator._valueChanged(null);
    _iterator.close();
    _iterator = null;
  }

  /** Gets the template this node refers to. */
  Element get _ref {
    _decorate();

    var ref = _searchRefId(_node, _node.attributes['ref']);
    if (ref == null) {
      ref = _templateInstanceRef;
      if (ref == null) return _node;
    }

    var nextRef = templateBindFallback(ref)._ref;
    return nextRef != null ? nextRef : ref;
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
    _globalBaseUriWorkaround();

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
        _isStagingDocument[doc] = true;
        _baseUriWorkaround(doc);
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

  static bool _initBaseUriWorkaround;

  static void _globalBaseUriWorkaround() {
    if (_initBaseUriWorkaround == true) return;
    _initBaseUriWorkaround = true;

    var t = document.createElement('template');
    if (t is TemplateElement) {
      var d = t.content.ownerDocument;
      if (d.documentElement == null) {
        d.append(d.createElement('html')).append(d.createElement('head'));
      }
      // don't patch this if TemplateBinding.js already has.
      if (d.head.querySelector('base') == null) {
        _baseUriWorkaround(d);
      }
    }
  }

  // TODO(rafaelw): Remove when fix for
  // https://codereview.chromium.org/164803002/
  // makes it to Chrome release.
  static void _baseUriWorkaround(HtmlDocument doc) {
    BaseElement base = doc.createElement('base');
    base.href = document.baseUri;
    doc.head.append(base);
  }

  static final _templateObserver = new MutationObserver((records, _) {
    for (MutationRecord record in records) {
      templateBindFallback(record.target)._refChanged();
    }
  });

}

final DocumentFragment _emptyInstance = () {
  var empty = new DocumentFragment();
  _instanceExtension[empty] = new _InstanceExtension();
  return empty;
}();

// TODO(jmesserly): if we merged with wtih TemplateInstance, it seems like it
// would speed up some operations (e.g. _getInstanceRoot wouldn't need to walk
// the parent chain).
class _InstanceExtension {
  final List _bindings = [];
  Node _terminator;
  Element _templateCreator;
  DocumentFragment _protoContent;
}

// TODO(jmesserly): this is private in JS but public for us because pkg:polymer
// uses it.
List getTemplateInstanceBindings(DocumentFragment fragment) {
  var ext = _instanceExtension[fragment];
  return ext != null ? ext._bindings : ext;
}

/// Gets the root of the current node's parent chain
_getFragmentRoot(Node node) {
  var p;
  while ((p = node.parentNode) != null) {
    node = p;
  }
  return node;
}

Node _searchRefId(Node node, String id) {
  if (id == null || id == '') return null;

  final selector = '#$id';
  while (true) {
    node = _getFragmentRoot(node);

    Node ref = null;

    _InstanceExtension instance = _instanceExtension[node];
    if (instance != null && instance._protoContent != null) {
      ref = instance._protoContent.querySelector(selector);
    } else if (_hasGetElementById(node)) {
      ref = (node as dynamic).getElementById(id);
    }

    if (ref != null) return ref;

    if (instance == null) return null;
    node = instance._templateCreator;
    if (node == null) return null;
  }
}

_getInstanceRoot(node) {
  while (node.parentNode != null) {
    node = node.parentNode;
  }
  _InstanceExtension instance = _instanceExtension[node];
  return instance != null && instance._templateCreator != null ? node : null;
}

// Note: JS code tests that getElementById is present. We can't do that
// easily, so instead check for the types known to implement it.
bool _hasGetElementById(Node node) =>
    node is Document || node is ShadowRoot || node is SvgSvgElement;

final Expando<_InstanceExtension> _instanceExtension = new Expando();

final _isStagingDocument = new Expando();
