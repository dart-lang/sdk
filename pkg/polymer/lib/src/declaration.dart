// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/// **Warning**: this class is experiental and subject to change.
///
/// The implementation for the `polymer-element` element.
///
/// Normally you do not need to use this class directly, see [PolymerElement].
class PolymerDeclaration extends HtmlElement {
  static const _TAG = 'polymer-element';

  factory PolymerDeclaration() => new Element.tag(_TAG);
  // Fully ported from revision:
  // https://github.com/Polymer/polymer/blob/b7200854b2441a22ce89f6563963f36c50f5150d
  //
  //   src/declaration/attributes.js
  //   src/declaration/events.js
  //   src/declaration/polymer-element.js
  //   src/declaration/properties.js
  //   src/declaration/prototype.js (note: most code not needed in Dart)
  //   src/declaration/styles.js
  //
  // Not yet ported:
  //   src/declaration/path.js - blocked on HTMLImports.getDocumentUrl

  Type _type;
  Type get type => _type;

  // TODO(jmesserly): this is a cache, because it's tricky in Dart to get from
  // Type -> Supertype.
  Type _supertype;
  Type get supertype => _supertype;

  // TODO(jmesserly): this is also a cache, since we can't store .element on
  // each level of the __proto__ like JS does.
  PolymerDeclaration _super;
  PolymerDeclaration get superDeclaration => _super;

  String _extendsName;

  String _name;
  String get name => _name;

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

  Map<String, Object> _instanceAttributes;

  List<Element> _sheets;
  List<Element> get sheets => _sheets;

  List<Element> _styles;
  List<Element> get styles => _styles;

  DocumentFragment get templateContent {
    final template = this.querySelector('template');
    return template != null ? templateBind(template).content : null;
  }

  /// Maps event names and their associated method in the element class.
  final Map<String, String> _eventDelegates = {};

  /// Expected events per element node.
  // TODO(sigmund): investigate whether we need more than 1 set of local events
  // per element (why does the js implementation stores 1 per template node?)
  Expando<Set<String>> _templateDelegates;

  PolymerDeclaration.created() : super.created() {
    // fetch the element name
    _name = attributes['name'];
    // fetch our extendee name
    _extendsName = attributes['extends'];
    // install element definition, if ready
    registerWhenReady();
  }

  void registerWhenReady() {
    // if we have no prototype, wait
    if (waitingForType(name)) {
      return;
    }
    if (waitingForExtendee(_extendsName)) {
      //console.warn(name + ': waitingForExtendee:' + extendee);
      return;
    }
    // TODO(sjmiles): HTMLImports polyfill awareness:
    // elements in the main document are likely to parse
    // in advance of elements in imports because the
    // polyfill parser is simulated
    // therefore, wait for imports loaded before
    // finalizing elements in the main document
    // TODO(jmesserly): Polymer.dart waits for HTMLImportsLoaded, so I've
    // removed "whenImportsLoaded" for now. Restore the workaround if needed.
    _register(_extendsName);
  }

  void _register(extendee) {
    //console.group('registering', name);
    register(name, extendee);
    //console.groupEnd();
    // subclasses may now register themselves
    _notifySuper(name);
  }

  bool waitingForType(String name) {
    if (_getRegisteredType(name) != null) return false;

    // then wait for a prototype
    _waitType[name] = this;
    // if explicitly marked as 'noscript'
    if (attributes.containsKey('noscript')) {
      // TODO(sorvell): CustomElements polyfill awareness:
      // noscript elements should upgrade in logical order
      // script injection ensures this under native custom elements;
      // under imports + ce polyfills, scripts run before upgrades.
      // dependencies should be ready at upgrade time so register
      // prototype at this time.
      // TODO(jmesserly): I'm not sure how to port this; since script
      // injection doesn't work for Dart, we'll just call Polymer.register
      // here and hope for the best.
      Polymer.register(name);
    }
    return true;
  }

  bool waitingForExtendee(String extendee) {
    // if extending a custom element...
    if (extendee != null && extendee.indexOf('-') >= 0) {
      // wait for the extendee to be _registered first
      if (!_isRegistered(extendee)) {
        _waitSuper.putIfAbsent(extendee, () => []).add(this);
        return true;
      }
    }
    return false;
  }

  void register(String name, String extendee) {
    // build prototype combining extendee, Polymer base, and named api
    buildType(name, extendee);

    // back reference declaration element
    // TODO(sjmiles): replace `element` with `elementElement` or `declaration`
    _declarations[name] = this;

    // more declarative features
    desugar(name, extendee);
    // register our custom element
    registerType(name);

    // NOTE: skip in Dart because we don't have mutable global scope.
    // reference constructor in a global named by 'constructor' attribute
    // publishConstructor();
  }

  /// Gets the Dart type registered for this name, and sets up declarative
  /// features. Fills in the [type] and [supertype] fields.
  ///
  /// *Note*: unlike the JavaScript version, we do not have to metaprogram the
  /// prototype, which simplifies this method.
  void buildType(String name, String extendee) {
    // get our custom type
    _type = _getRegisteredType(name);

    // get basal prototype
    _supertype = _getRegisteredType(extendee);
    if (_supertype != null) _super = _getDeclaration(extendee);

    // transcribe `attributes` declarations onto own prototype's `publish`
    publishAttributes(_super);

    publishProperties();

    inferObservers();

    // desugar compound observer syntax, e.g. @ObserveProperty('a b c')
    explodeObservers();

    // Skip the rest in Dart:
    // chain various meta-data objects to inherited versions
    // chain custom api to inherited
    // build side-chained lists to optimize iterations
    // inherit publishing meta-data
    // x-platform fixup
  }

  /// Implement various declarative features.
  void desugar(name, extendee) {
    // compile list of attributes to copy to instances
    accumulateInstanceAttributes();
    // parse on-* delegates declared on `this` element
    parseHostEvents();
    // install external stylesheets as if they are inline
    installSheets();

    adjustShadowElement();

    // TODO(sorvell): install a helper method this.resolvePath to aid in
    // setting resource paths. e.g.
    // this.$.image.src = this.resolvePath('images/foo.png')
    // Potentially remove when spec bug is addressed.
    // https://www.w3.org/Bugs/Public/show_bug.cgi?id=21407
    // TODO(jmesserly): resolvePath not ported, see first comment in this class.

    // under ShadowDOMPolyfill, transforms to approximate missing CSS features
    _shimShadowDomStyling(templateContent, name, extendee);

    // TODO(jmesserly): this feels unnatrual in Dart. Since we have convenient
    // lazy static initialization, can we get by without it?
    if (smoke.hasStaticMethod(type, #registerCallback)) {
      smoke.invoke(type, #registerCallback, [this]);
    }
  }

  // TODO(sorvell): remove when spec addressed:
  // https://www.w3.org/Bugs/Public/show_bug.cgi?id=22460
  // make <shadow></shadow> be <shadow><content></content></shadow>
  void adjustShadowElement() {
    // TODO(sorvell): avoid under SD polyfill until this bug is addressed:
    // https://github.com/Polymer/ShadowDOM/issues/297
    if (!_hasShadowDomPolyfill) {
      final content = templateContent;
      if (content == null) return;

      for (var s in content.querySelectorAll('shadow')) {
        if (s.nodes.isEmpty) s.append(new ContentElement());
      }
    }
  }

  void registerType(String name) {
    var baseTag;
    var decl = this;
    while (decl != null) {
      baseTag = decl.attributes['extends'];
      decl = decl.superDeclaration;
    }
    document.register(name, type, extendsTag: baseTag);
  }

  void publishAttributes(PolymerDeclaration superDecl) {
    // get properties to publish
    if (superDecl != null && superDecl._publish != null) {
      // Dart note: even though we walk the type hierarchy in
      // _getPublishedProperties, this will additionally include any names
      // published via the `attributes` attribute.
      _publish = new Map.from(superDecl._publish);
    }

    _publish = _getPublishedProperties(_type, _publish);

    // merge names from 'attributes' attribute
    var attrs = attributes['attributes'];
    if (attrs != null) {
      // names='a b c' or names='a,b,c'
      // record each name for publishing
      for (var attr in attrs.split(_ATTRIBUTES_REGEX)) {
        // remove excess ws
        attr = attr.trim();

        // do not override explicit entries
        if (attr == '') continue;

        var property = new Symbol(attr);
        var path = new PropertyPath([property]);
        if (_publish != null && _publish.containsKey(path)) {
          continue;
        }

        var decl = smoke.getDeclaration(_type, property);
        if (decl == null || decl.isMethod || decl.isFinal) {
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

  void accumulateInstanceAttributes() {
    // inherit instance attributes
    _instanceAttributes = new Map<String, Object>();
    if (_super != null) _instanceAttributes.addAll(_super._instanceAttributes);

    // merge attributes from element
    attributes.forEach((name, value) {
      if (isInstanceAttribute(name)) {
        _instanceAttributes[name] = value;
      }
    });
  }

  static bool isInstanceAttribute(name) {
    // do not clone these attributes onto instances
    final blackList = const {
        'name': 1, 'extends': 1, 'constructor': 1, 'noscript': 1,
        'attributes': 1};

    return !blackList.containsKey(name) && !name.startsWith('on-');
  }

  /// Extracts events from the element tag attributes.
  void parseHostEvents() {
    addAttributeDelegates(_eventDelegates);
  }

  void addAttributeDelegates(Map<String, String> delegates) {
    attributes.forEach((name, value) {
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
        content.insertBefore(
            new StyleElement()..text = '$cssText',
            content.firstChild);
      }
    }
  }

  List<Element> findNodes(String selector, [bool matcher(Element e)]) {
    var nodes = this.querySelectorAll(selector).toList();
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
    var options = const smoke.QueryOptions(includeFields: false,
        includeProperties: false, includeMethods: true, includeInherited: true,
        includeUpTo: HtmlElement);
    for (var decl in smoke.query(_type, options)) {
      String name = smoke.symbolToName(decl.name);
      if (name.endsWith(_OBSERVE_SUFFIX) && name != 'attributeChanged') {
        // TODO(jmesserly): now that we have a better system, should we
        // deprecate *Changed methods?
        if (_observe == null) _observe = new HashMap();
        name = name.substring(0, name.length - 7);
        _observe[new PropertyPath(name)] = [decl.name];
      }
    }
  }

  /// Fetch a list of all methods annotated with [ObserveProperty] so we can
  /// observe the associated properties.
  void explodeObservers() {
    var options = const smoke.QueryOptions(includeFields: false,
        includeProperties: false, includeMethods: true, includeInherited: true,
        includeUpTo: HtmlElement, withAnnotations: const [ObserveProperty]);
    for (var decl in smoke.query(_type, options)) {
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
}

/// maps tag names to prototypes
final Map _typesByName = new Map<String, Type>();

Type _getRegisteredType(String name) => _typesByName[name];

/// elements waiting for prototype, by name
final Map _waitType = new Map<String, PolymerDeclaration>();

void _notifyType(String name) {
  var waiting = _waitType.remove(name);
  if (waiting != null) waiting.registerWhenReady();
}

/// elements waiting for super, by name
final Map _waitSuper = new Map<String, List<PolymerDeclaration>>();

void _notifySuper(String name) {
  var waiting = _waitSuper.remove(name);
  if (waiting != null) {
    for (var w in waiting) {
      w.registerWhenReady();
    }
  }
}

/// track document.register'ed tag names and their declarations
final Map _declarations = new Map<String, PolymerDeclaration>();

bool _isRegistered(String name) => _declarations.containsKey(name);
PolymerDeclaration _getDeclaration(String name) => _declarations[name];

Map<PropertyPath, smoke.Declaration> _getPublishedProperties(
    Type type, Map<PropertyPath, smoke.Declaration> props) {
  var options = const smoke.QueryOptions(includeInherited: true,
      includeUpTo: HtmlElement, withAnnotations: const [PublishedProperty]);
  for (var decl in smoke.query(type, options)) {
    if (decl.isFinal) continue;
    if (props == null) props = {};
    props[new PropertyPath([decl.name])] = decl;
  }
  return props;
}

/// Attribute prefix used for declarative event handlers.
const _EVENT_PREFIX = 'on-';

/// Whether an attribute declares an event.
bool _hasEventPrefix(String attr) => attr.startsWith(_EVENT_PREFIX);

String _removeEventPrefix(String name) => name.substring(_EVENT_PREFIX.length);

/// Using Polymer's platform/src/ShadowCSS.js passing the style tag's content.
void _shimShadowDomStyling(DocumentFragment template, String name,
    String extendee) {
  if (template == null || !_hasShadowDomPolyfill) return;

  var platform = js.context['Platform'];
  if (platform == null) return;
  var shadowCss = platform['ShadowCSS'];
  if (shadowCss == null) return;
  shadowCss.callMethod('shimStyling', [template, name, extendee]);
}

final bool _hasShadowDomPolyfill = js.context != null &&
    js.context.hasProperty('ShadowDOMPolyfill');

const _STYLE_SELECTOR = 'style';
const _SHEET_SELECTOR = '[rel=stylesheet]';
const _STYLE_GLOBAL_SCOPE = 'global';
const _SCOPE_ATTR = 'polymer-scope';
const _STYLE_SCOPE_ATTRIBUTE = 'element';
const _STYLE_CONTROLLER_SCOPE = 'controller';

String _cssTextFromSheet(LinkElement sheet) {
  if (sheet == null) return '';

  // In deploy mode we should never do a sync XHR; link rel=stylesheet will
  // be inlined into a <style> tag by ImportInliner.
  if (_deployMode) return '';

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

const _OBSERVE_SUFFIX = 'Changed';

// TODO(jmesserly): is this list complete?
final _eventTranslations = const {
  // TODO(jmesserly): these three Polymer.js translations won't work in Dart,
  // because we strip the webkit prefix (below). Reconcile.
  'webkitanimationstart': 'webkitAnimationStart',
  'webkitanimationend': 'webkitAnimationEnd',
  'webkittransitionend': 'webkitTransitionEnd',

  'domfocusout': 'DOMFocusOut',
  'domfocusin': 'DOMFocusIn',
  'dommousescroll': 'DOMMouseScroll',

  // TODO(jmesserly): Dart specific renames. Reconcile with Polymer.js
  'animationend': 'webkitAnimationEnd',
  'animationiteration': 'webkitAnimationIteration',
  'animationstart': 'webkitAnimationStart',
  'doubleclick': 'dblclick',
  'fullscreenchange': 'webkitfullscreenchange',
  'fullscreenerror': 'webkitfullscreenerror',
  'keyadded': 'webkitkeyadded',
  'keyerror': 'webkitkeyerror',
  'keymessage': 'webkitkeymessage',
  'needkey': 'webkitneedkey',
  'speechchange': 'webkitSpeechChange',
};

final _reverseEventTranslations = () {
  final map = new Map<String, String>();
  _eventTranslations.forEach((onName, eventType) {
    map[eventType] = onName;
  });
  return map;
}();

// Dart note: we need this function because we have additional renames JS does
// not have. The JS renames are simply case differences, whereas we have ones
// like doubleclick -> dblclick and stripping the webkit prefix.
String _eventNameFromType(String eventType) {
  final result = _reverseEventTranslations[eventType];
  return result != null ? result : eventType;
}

final _ATTRIBUTES_REGEX = new RegExp(r'\s|,');
