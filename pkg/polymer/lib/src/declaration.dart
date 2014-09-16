// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/// *Warning* this class is experimental and subject to change.
///
/// The data associated with a polymer-element declaration, if it is backed
/// by a Dart class instead of a JavaScript prototype.
class PolymerDeclaration {
  /// The one syntax to rule them all.
  static final BindingDelegate _polymerSyntax = new PolymerExpressions();

  /// The polymer-element for this declaration.
  final HtmlElement element;

  /// The Dart type corresponding to this custom element declaration.
  final Type type;

  /// If we extend another custom element, this points to the super declaration.
  final PolymerDeclaration superDeclaration;

  /// The name of the custom element.
  final String name;

  /// Map of publish properties. Can be a field or a property getter, but if
  /// this map contains a getter, is because it also has a corresponding setter.
  ///
  /// Note: technically these are always single properties, so we could use a
  /// Symbol instead of a PropertyPath. However there are lookups between this
  /// map and [_observe] so it is easier to just track paths.
  Map<PropertyPath, smoke.Declaration> _publish;

  /// The names of published properties for this polymer-element.
  Iterable<String> get publishedProperties =>
      _publish != null ? _publish.keys.map((p) => '$p') : const [];

  /// Same as [_publish] but with lower case names.
  Map<String, smoke.Declaration> _publishLC;

  Map<PropertyPath, List<Symbol>> _observe;

  /// Name and expression for each computed property.
  Map<Symbol, String> _computed = {};

  Map<String, Object> _instanceAttributes;

  /// A set of properties that should be automatically reflected to attributes.
  /// Typically this is used for CSS styling. If none, this variable will be
  /// left as null.
  Set<String> _reflect;

  List<Element> _sheets;
  List<Element> get sheets => _sheets;

  List<Element> _styles;
  List<Element> get styles => _styles;

  // The default syntax for polymer-elements.
  PolymerExpressions syntax = _polymerSyntax;

  DocumentFragment get templateContent {
    final template = fetchTemplate();
    return template != null ? templateBind(template).content : null;
  }

  /// Maps event names and their associated method in the element class.
  final Map<String, String> _eventDelegates = {};

  /// Expected events per element node.
  // TODO(sigmund): investigate whether we need more than 1 set of local events
  // per element (why does the js implementation stores 1 per template node?)
  Expando<Set<String>> _templateDelegates;

  String get extendee => superDeclaration != null ?
      superDeclaration.name : null;

  /// The root URI for assets.
  Uri _rootUri;

  // Dart note: since polymer-element is handled in JS now, we have a simplified
  // flow for registering. We don't need to wait for the supertype or the code
  // to be noticed.
  PolymerDeclaration(this.element, this.name, this.type, this.superDeclaration);

  void register() {
    // more declarative features
    desugar();
    // register our custom element
    registerType(name);

    // NOTE: skip in Dart because we don't have mutable global scope.
    // reference constructor in a global named by 'constructor' attribute
    // publishConstructor();
  }

  /// Implement various declarative features.
  // Dart note: this merges "buildPrototype" "desugarBeforeChaining" and
  // "desugarAfterChaining", because we don't have prototypes.
  void desugar() {

    // back reference declaration element
    _declarations[name] = this;

    // transcribe `attributes` declarations onto own prototype's `publish`
    publishAttributes(superDeclaration);

    publishProperties();

    inferObservers();

    // desugar compound observer syntax, e.g. @ObserveProperty('a b c')
    explodeObservers();

    createPropertyAccessors();
    // install mdv delegate on template
    installBindingDelegate(fetchTemplate());
    // install external stylesheets as if they are inline
    installSheets();
    // adjust any paths in dom from imports
    resolveElementPaths(element);
    // compile list of attributes to copy to instances
    accumulateInstanceAttributes();
    // parse on-* delegates declared on `this` element
    parseHostEvents();
    // install a helper method this.resolvePath to aid in
    // setting resource urls. e.g.
    // this.$.image.src = this.resolvePath('images/foo.png')
    initResolvePath();
    // under ShadowDOMPolyfill, transforms to approximate missing CSS features
    _shimShadowDomStyling(templateContent, name, extendee);

    // TODO(jmesserly): this feels unnatrual in Dart. Since we have convenient
    // lazy static initialization, can we get by without it?
    if (smoke.hasStaticMethod(type, #registerCallback)) {
      smoke.invoke(type, #registerCallback, [this]);
    }
  }

  void registerType(String name) {
    var baseTag;
    var decl = this;
    while (decl != null) {
      baseTag = decl.element.attributes['extends'];
      decl = decl.superDeclaration;
    }
    document.registerElement(name, type, extendsTag: baseTag);
  }

  // from declaration/mdv.js
  Element fetchTemplate() => element.querySelector('template');

  void installBindingDelegate(Element template) {
    if (template != null) {
      templateBind(template).bindingDelegate = this.syntax;
    }
  }

  // from declaration/path.js
  void resolveElementPaths(Node node) {
    if (_Polymer == null) return;
    _Polymer['urlResolver'].callMethod('resolveDom', [node]);
  }

  // Dart note: renamed from "addResolvePathApi".
  void initResolvePath() {
    // let assetpath attribute modify the resolve path
    var assetPath = element.attributes['assetpath'];
    if (assetPath == null) assetPath = '';
    var base = Uri.parse(element.ownerDocument.baseUri);
    _rootUri = base.resolve(assetPath);
  }

  String resolvePath(String urlPath, [baseUrlOrString]) {
    Uri base;
    if (baseUrlOrString == null) {
      // Dart note: this enforces the same invariant as JS, where you need to
      // call addResolvePathApi first.
      if (_rootUri == null) {
        throw new StateError('call initResolvePath before calling resolvePath');
      }
      base = _rootUri;
    } else if (baseUrlOrString is Uri) {
      base = baseUrlOrString;
    } else {
      base = Uri.parse(baseUrlOrString);
    }
    return base.resolve(urlPath).toString();
  }

  void publishAttributes(PolymerDeclaration superDecl) {
    // get properties to publish
    if (superDecl != null) {
      // Dart note: even though we walk the type hierarchy in
      // _getPublishedProperties, this will additionally include any names
      // published via the `attributes` attribute.
      if (superDecl._publish != null) {
        _publish = new Map.from(superDecl._publish);
      }
      if (superDecl._reflect != null) {
        _reflect = new Set.from(superDecl._reflect);
      }
    }

    _getPublishedProperties(type);

    // merge names from 'attributes' attribute into the '_publish' object
    var attrs = element.attributes['attributes'];
    if (attrs != null) {
      // names='a b c' or names='a,b,c'
      // record each name for publishing
      for (var attr in attrs.split(_ATTRIBUTES_REGEX)) {
        // remove excess ws
        attr = attr.trim();

        // if the user hasn't specified a value, we want to use the
        // default, unless a superclass has already chosen one
        if (attr == '') continue;

        var decl, path;
        var property = smoke.nameToSymbol(attr);
        if (property != null) {
          path = new PropertyPath([property]);
          if (_publish != null && _publish.containsKey(path)) {
            continue;
          }
          decl = smoke.getDeclaration(type, property);
        }

        if (property == null || decl == null || decl.isMethod || decl.isFinal) {
          window.console.warn('property for attribute $attr of polymer-element '
              'name=$name not found.');
          continue;
        }
        if (_publish == null) _publish = {};
        _publish[path] = decl;
      }
    }

    // NOTE: the following is not possible in Dart; fields must be declared.
    // install 'attributes' as properties on the prototype,
    // but don't override
  }

  void _getPublishedProperties(Type type) {
    var options = const smoke.QueryOptions(includeInherited: true,
        includeUpTo: HtmlElement, withAnnotations: const [PublishedProperty]);
    for (var decl in smoke.query(type, options)) {
      if (decl.isFinal) continue;
      if (_publish == null) _publish = {};
      _publish[new PropertyPath([decl.name])] = decl;

      // Should we reflect the property value to the attribute automatically?
      if (decl.annotations
          .where((a) => a is PublishedProperty)
          .any((a) => a.reflect)) {

        if (_reflect == null) _reflect = new Set();
        _reflect.add(smoke.symbolToName(decl.name));
      }
    }
  }


  void accumulateInstanceAttributes() {
    // inherit instance attributes
    _instanceAttributes = new Map<String, Object>();
    if (superDeclaration != null) {
      _instanceAttributes.addAll(superDeclaration._instanceAttributes);
    }

    // merge attributes from element
    element.attributes.forEach((name, value) {
      if (isInstanceAttribute(name)) {
        _instanceAttributes[name] = value;
      }
    });
  }

  static bool isInstanceAttribute(name) {
    // do not clone these attributes onto instances
    final blackList = const {
      'name': 1,
      'extends': 1,
      'constructor': 1,
      'noscript': 1,
      'assetpath': 1,
      'cache-csstext': 1,
      // add ATTRIBUTES_ATTRIBUTE to the blacklist
      'attributes': 1,
    };

    return !blackList.containsKey(name) && !name.startsWith('on-');
  }

  /// Extracts events from the element tag attributes.
  void parseHostEvents() {
    addAttributeDelegates(_eventDelegates);
  }

  void addAttributeDelegates(Map<String, String> delegates) {
    element.attributes.forEach((name, value) {
      if (_hasEventPrefix(name)) {
        var start = value.indexOf('{{');
        var end = value.lastIndexOf('}}');
        if (start >= 0 && end >= 0) {
          delegates[_removeEventPrefix(name)] =
              value.substring(start + 2, end).trim();
        }
      }
    });
  }

  String urlToPath(String url) {
    if (url == null) return '';
    return (url.split('/')..removeLast()..add('')).join('/');
  }

  // Dart note: loadStyles, convertSheetsToStyles, copySheetAttribute and
  // findLoadableStyles are not ported because they're handled by Polymer JS
  // before we get into [register].

  /// Install external stylesheets loaded in <element> elements into the
  /// element's template.
  void installSheets() {
    cacheSheets();
    cacheStyles();
    installLocalSheets();
    installGlobalStyles();
  }

  void cacheSheets() {
    _sheets = findNodes(_SHEET_SELECTOR);
    for (var s in sheets) s.remove();
  }

  void cacheStyles() {
    _styles = findNodes('$_STYLE_SELECTOR[$_SCOPE_ATTR]');
    for (var s in styles) s.remove();
  }

  /// Takes external stylesheets loaded in an `<element>` element and moves
  /// their content into a style element inside the `<element>`'s template.
  /// The sheet is then removed from the `<element>`. This is done only so
  /// that if the element is loaded in the main document, the sheet does
  /// not become active.
  /// Note, ignores sheets with the attribute 'polymer-scope'.
  void installLocalSheets() {
    var sheets = this.sheets.where(
        (s) => !s.attributes.containsKey(_SCOPE_ATTR));
    var content = templateContent;
    if (content != null) {
      var cssText = new StringBuffer();
      for (var sheet in sheets) {
        cssText..write(_cssTextFromSheet(sheet))..write('\n');
      }
      if (cssText.length > 0) {
        var style = element.ownerDocument.createElement('style')
            ..text = '$cssText';

        content.insertBefore(style, content.firstChild);
      }
    }
  }

  List<Element> findNodes(String selector, [bool matcher(Element e)]) {
    var nodes = element.querySelectorAll(selector).toList();
    var content = templateContent;
    if (content != null) {
      nodes = nodes..addAll(content.querySelectorAll(selector));
    }
    if (matcher != null) return nodes.where(matcher).toList();
    return nodes;
  }

  /// Promotes external stylesheets and style elements with the attribute
  /// polymer-scope='global' into global scope.
  /// This is particularly useful for defining @keyframe rules which
  /// currently do not function in scoped or shadow style elements.
  /// (See wkb.ug/72462)
  // TODO(sorvell): remove when wkb.ug/72462 is addressed.
  void installGlobalStyles() {
    var style = styleForScope(_STYLE_GLOBAL_SCOPE);
    Polymer.applyStyleToScope(style, document.head);
  }

  String cssTextForScope(String scopeDescriptor) {
    var cssText = new StringBuffer();
    // handle stylesheets
    var selector = '[$_SCOPE_ATTR=$scopeDescriptor]';
    matcher(s) => s.matches(selector);

    for (var sheet in sheets.where(matcher)) {
      cssText..write(_cssTextFromSheet(sheet))..write('\n\n');
    }
    // handle cached style elements
    for (var style in styles.where(matcher)) {
      cssText..write(style.text)..write('\n\n');
    }
    return cssText.toString();
  }

  StyleElement styleForScope(String scopeDescriptor) {
    var cssText = cssTextForScope(scopeDescriptor);
    return cssTextToScopeStyle(cssText, scopeDescriptor);
  }

  StyleElement cssTextToScopeStyle(String cssText, String scopeDescriptor) {
    if (cssText == '') return null;

    return new StyleElement()
        ..text = cssText
        ..attributes[_STYLE_SCOPE_ATTRIBUTE] = '$name-$scopeDescriptor';
  }

  /// Fetch a list of all *Changed methods so we can observe the associated
  /// properties.
  void inferObservers() {
    for (var decl in smoke.query(type, _changedMethodQueryOptions)) {
      // TODO(jmesserly): now that we have a better system, should we
      // deprecate *Changed methods?
      if (_observe == null) _observe = new HashMap();
      var name = smoke.symbolToName(decl.name);
      name = name.substring(0, name.length - 7);
      _observe[new PropertyPath(name)] = [decl.name];
    }
  }

  /// Fetch a list of all methods annotated with [ObserveProperty] so we can
  /// observe the associated properties.
  void explodeObservers() {
    var options = const smoke.QueryOptions(includeFields: false,
        includeProperties: false, includeMethods: true, includeInherited: true,
        includeUpTo: HtmlElement, withAnnotations: const [ObserveProperty]);
    for (var decl in smoke.query(type, options)) {
      for (var meta in decl.annotations) {
        if (meta is! ObserveProperty) continue;
        if (_observe == null) _observe = new HashMap();
        for (String name in meta.names) {
          _observe.putIfAbsent(new PropertyPath(name), () => []).add(decl.name);
        }
      }
    }
  }

  void publishProperties() {
    // Dart note: _publish was already populated by publishAttributes
    if (_publish != null) _publishLC = _lowerCaseMap(_publish);
  }

  Map<String, dynamic> _lowerCaseMap(Map<PropertyPath, dynamic> properties) {
    final map = new Map<String, dynamic>();
    properties.forEach((PropertyPath path, value) {
      map['$path'.toLowerCase()] = value;
    });
    return map;
  }

  void createPropertyAccessors() {
    // Dart note: since we don't have a prototype in Dart, most of the work of
    // createPolymerAccessors is done lazily on the first access of properties.
    // Here we just extract the information from annotations and store it as
    // properties on the declaration.
    var options = const smoke.QueryOptions(includeInherited: true,
        includeUpTo: HtmlElement, withAnnotations: const [ComputedProperty]);
    var existing = {};
    for (var decl in smoke.query(type, options)) {
      var meta = decl.annotations.firstWhere((e) => e is ComputedProperty);
      var name = decl.name;
      var prev = existing[name];
      // The definition of a child class takes priority.
      if (prev == null || smoke.isSubclassOf(decl.type, prev.type)) {
        _computed[name] = meta.expression;
        existing[name] = decl;
      }
    }
  }
}

/// maps tag names to prototypes
final Map _typesByName = new Map<String, Type>();

Type _getRegisteredType(String name) => _typesByName[name];

/// track document.register'ed tag names and their declarations
final Map _declarations = new Map<String, PolymerDeclaration>();

bool _isRegistered(String name) => _declarations.containsKey(name);
PolymerDeclaration _getDeclaration(String name) => _declarations[name];

/// Using Polymer's platform/src/ShadowCSS.js passing the style tag's content.
void _shimShadowDomStyling(DocumentFragment template, String name,
    String extendee) {
  if (_ShadowCss == null ||!_hasShadowDomPolyfill) return;

  _ShadowCss.callMethod('shimStyling', [template, name, extendee]);
}

final bool _hasShadowDomPolyfill = js.context.hasProperty('ShadowDOMPolyfill');
final JsObject _ShadowCss = _Platform != null ? _Platform['ShadowCSS'] : null;

const _STYLE_SELECTOR = 'style';
const _SHEET_SELECTOR = 'link[rel=stylesheet]';
const _STYLE_GLOBAL_SCOPE = 'global';
const _SCOPE_ATTR = 'polymer-scope';
const _STYLE_SCOPE_ATTRIBUTE = 'element';
const _STYLE_CONTROLLER_SCOPE = 'controller';

String _cssTextFromSheet(LinkElement sheet) {
  if (sheet == null) return '';

  // In deploy mode we should never do a sync XHR; link rel=stylesheet will
  // be inlined into a <style> tag by ImportInliner.
  if (loader.deployMode) return '';

  // TODO(jmesserly): sometimes the href property is wrong after deployment.
  var href = sheet.href;
  if (href == '') href = sheet.attributes["href"];

  // TODO(jmesserly): it seems like polymer-js is always polyfilling
  // HTMLImports, because their code depends on "__resource" to work, so I
  // don't see how it can work with native HTML Imports. We use a sync-XHR
  // under the assumption that the file is likely to have been already
  // downloaded and cached by HTML Imports.
  try {
    return (new HttpRequest()
        ..open('GET', href, async: false)
        ..send())
        .responseText;
  } on DomException catch (e, t) {
    _sheetLog.fine('failed to XHR stylesheet text href="$href" error: '
        '$e, trace: $t');
    return '';
  }
}

final Logger _sheetLog = new Logger('polymer.stylesheet');


final smoke.QueryOptions _changedMethodQueryOptions = new smoke.QueryOptions(
    includeFields: false, includeProperties: false, includeMethods: true,
    includeInherited: true, includeUpTo: HtmlElement,
    matches: _isObserverMethod);

bool _isObserverMethod(Symbol symbol) {
  String name = smoke.symbolToName(symbol);
  if (name == null) return false;
  return name.endsWith('Changed') && name != 'attributeChanged';
}


final _ATTRIBUTES_REGEX = new RegExp(r'\s|,');

final JsObject _Platform = js.context['Platform'];
final JsObject _Polymer = js.context['Polymer'];
