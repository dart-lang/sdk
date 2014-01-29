// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/**
 * **Warning**: this class is experiental and subject to change.
 *
 * The implementation for the `polymer-element` element.
 *
 * Normally you do not need to use this class directly, see [PolymerElement].
 */
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

  String _name;
  String get name => _name;

  /**
   * Map of publish properties. Can be a [VariableMirror] or a [MethodMirror]
   * representing a getter. If it is a getter, there will also be a setter.
   */
  Map<Symbol, DeclarationMirror> _publish;

  /** The names of published properties for this polymer-element. */
  Iterable<Symbol> get publishedProperties =>
      _publish != null ? _publish.keys : const [];

  /** Same as [_publish] but with lower case names. */
  Map<String, DeclarationMirror> _publishLC;

  Map<Symbol, Symbol> _observe;

  Map<String, Object> _instanceAttributes;

  List<Element> _sheets;
  List<Element> get sheets => _sheets;

  List<Element> _styles;
  List<Element> get styles => _styles;

  DocumentFragment get templateContent {
    final template = this.querySelector('template');
    return template != null ? templateBind(template).content : null;
  }

  /** Maps event names and their associated method in the element class. */
  final Map<String, String> _eventDelegates = {};

  /** Expected events per element node. */
  // TODO(sigmund): investigate whether we need more than 1 set of local events
  // per element (why does the js implementation stores 1 per template node?)
  Expando<Set<String>> _templateDelegates;

  PolymerDeclaration.created() : super.created() {
    // fetch the element name
    _name = attributes['name'];
    // install element definition, if ready
    registerWhenReady();
  }

  void registerWhenReady() {
    // if we have no prototype, wait
    if (waitingForType(name)) {
      return;
    }
    // fetch our extendee name
    var extendee = attributes['extends'];
    if (waitingForExtendee(extendee)) {
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
    _register(extendee);
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

  /**
   * Gets the Dart type registered for this name, and sets up declarative
   * features. Fills in the [type] and [supertype] fields.
   *
   * *Note*: unlike the JavaScript version, we do not have to metaprogram the
   * prototype, which simplifies this method.
   */
  void buildType(String name, String extendee) {
    // get our custom type
    _type = _getRegisteredType(name);

    // get basal prototype
    _supertype = _getRegisteredType(extendee);
    if (_supertype != null) _super = _getDeclaration(extendee);

    var cls = reflectClass(_type);

    // transcribe `attributes` declarations onto own prototype's `publish`
    publishAttributes(cls, _super);

    publishProperties(type);

    inferObservers(cls);

    // Skip the rest in Dart:
    // chain various meta-data objects to inherited versions
    // chain custom api to inherited
    // build side-chained lists to optimize iterations
    // inherit publishing meta-data
    // x-platform fixup
  }

  /** Implement various declarative features. */
  void desugar(name, extendee) {
    // compile list of attributes to copy to instances
    accumulateInstanceAttributes();
    // parse on-* delegates declared on `this` element
    parseHostEvents();
    // install external stylesheets as if they are inline
    installSheets();

    // TODO(sorvell): install a helper method this.resolvePath to aid in
    // setting resource paths. e.g.
    // this.$.image.src = this.resolvePath('images/foo.png')
    // Potentially remove when spec bug is addressed.
    // https://www.w3.org/Bugs/Public/show_bug.cgi?id=21407
    // TODO(jmesserly): resolvePath not ported, see first comment in this class.

    // under ShadowDOMPolyfill, transforms to approximate missing CSS features
    _shimShadowDomStyling(templateContent, name, extendee);

    var cls = reflectClass(type);
    // TODO(jmesserly): this feels unnatrual in Dart. Since we have convenient
    // lazy static initialization, can we get by without it?
    var registered = cls.declarations[#registerCallback];
    if (registered != null &&
        registered is MethodMirror &&
        registered.isStatic &&
        registered.isRegularMethod) {
      cls.invoke(#registerCallback, [this]);
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

  void publishAttributes(ClassMirror cls, PolymerDeclaration superDecl) {
    // get properties to publish
    if (superDecl != null && superDecl._publish != null) {
      // Dart note: even though we walk the type hierarchy in
      // _getPublishedProperties, this will additionally include any names
      // published via the `attributes` attribute.
      _publish = new Map.from(superDecl._publish);
    }

    _publish = _getPublishedProperties(cls, _publish);

    // merge names from 'attributes' attribute
    var attrs = attributes['attributes'];
    if (attrs != null) {
      // names='a b c' or names='a,b,c'
      // record each name for publishing
      for (var attr in attrs.split(attrs.contains(',') ? ',' : ' ')) {
        // remove excess ws
        attr = attr.trim();

        // do not override explicit entries
        if (attr != '' && _publish != null && _publish.containsKey(attr)) {
          continue;
        }

        var property = new Symbol(attr);
        var mirror = _getProperty(cls, property);
        if (mirror == null) {
          window.console.warn('property for attribute $attr of polymer-element '
              'name=$name not found.');
          continue;
        }
        if (_publish == null) _publish = {};
        _publish[property] = mirror;
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

  /** Extracts events from the element tag attributes. */
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

  /**
   * Install external stylesheets loaded in <element> elements into the
   * element's template.
   */
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

  /**
   * Takes external stylesheets loaded in an `<element>` element and moves
   * their content into a style element inside the `<element>`'s template.
   * The sheet is then removed from the `<element>`. This is done only so
   * that if the element is loaded in the main document, the sheet does
   * not become active.
   * Note, ignores sheets with the attribute 'polymer-scope'.
   */
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
      nodes = nodes..addAll(content.queryAll(selector));
    }
    if (matcher != null) return nodes.where(matcher).toList();
    return nodes;
  }

  /**
   * Promotes external stylesheets and style elements with the attribute
   * polymer-scope='global' into global scope.
   * This is particularly useful for defining @keyframe rules which
   * currently do not function in scoped or shadow style elements.
   * (See wkb.ug/72462)
   */
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
      cssText..write(style.textContent)..write('\n\n');
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

  /**
   * fetch a list of all observable properties names in our inheritance chain
   * above Polymer.
   */
  // TODO(sjmiles): perf: reflection is slow, relatively speaking
  // If an element may take 6us to create, getCustomPropertyNames might
  // cost 1.6us more.
  void inferObservers(ClassMirror cls) {
    if (cls == _objectType) return;
    inferObservers(cls.superclass);
    for (var method in cls.declarations.values) {
      if (method is! MethodMirror || method.isStatic
          || !method.isRegularMethod) continue;

      String name = MirrorSystem.getName(method.simpleName);
      if (name.endsWith(_OBSERVE_SUFFIX) && name != 'attributeChanged') {
        if (_observe == null) _observe = new Map();
        name = name.substring(0, name.length - 7);
        _observe[new Symbol(name)] = method.simpleName;
      }
    }
  }

  void publishProperties(Type type) {
    // Dart note: _publish was already populated by publishAttributes
    if (_publish != null) _publishLC = _lowerCaseMap(_publish);
  }

  Map<String, dynamic> _lowerCaseMap(Map<Symbol, dynamic> properties) {
    final map = new Map<String, dynamic>();
    properties.forEach((name, value) {
      map[MirrorSystem.getName(name).toLowerCase()] = value;
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

final _objectType = reflectClass(Object);


Map _getPublishedProperties(ClassMirror cls, Map props) {
  if (cls == _objectType) return props;
  props = _getPublishedProperties(cls.superclass, props);
  for (var member in cls.declarations.values) {
    if (member.isStatic || member.isPrivate) continue;

    if (member is VariableMirror && !member.isFinal
        || member is MethodMirror && member.isGetter) {

      for (var meta in member.metadata) {
        if (meta.reflectee is PublishedProperty) {
          // Note: we delay the setter check until we find @published because
          // it's a tad expensive.
          if (member is! MethodMirror || _hasSetter(cls, member)) {
            if (props == null) props = {};
            props[member.simpleName] = member;
          }
          break;
        }
      }
    }
  }

  return props;
}

DeclarationMirror _getProperty(ClassMirror cls, Symbol property) {
  do {
    var mirror = cls.declarations[property];
    if (mirror is MethodMirror && mirror.isGetter && _hasSetter(cls, mirror)
        || mirror is VariableMirror) {
      return mirror;
    }
    cls = cls.superclass;

    // It's generally a good idea to stop at Object, since we know it doesn't
    // have what we want.
    // TODO(jmesserly): This is also a workaround for what appears to be a V8
    // bug introduced between Chrome 31 and 32. After 32
    // JsClassMirror.declarations on Object calls
    // JsClassMirror.typeVariables, which tries to get the _jsConstructor's
    // .prototype["<>"]. This ends up getting the "" property instead, maybe
    // because "<>" doesn't exist, and gets ";" which then blows up because
    // the code later on expects a List of ints.
  } while (cls != _objectType);
  return null;
}

bool _hasSetter(ClassMirror cls, MethodMirror getter) {
  var setterName = new Symbol('${MirrorSystem.getName(getter.simpleName)}=');
  var mirror = cls.declarations[setterName];
  return mirror is MethodMirror && mirror.isSetter;
}


/** Attribute prefix used for declarative event handlers. */
const _EVENT_PREFIX = 'on-';

/** Whether an attribute declares an event. */
bool _hasEventPrefix(String attr) => attr.startsWith(_EVENT_PREFIX);

String _removeEventPrefix(String name) => name.substring(_EVENT_PREFIX.length);

/**
 * Using Polymer's platform/src/ShadowCSS.js passing the style tag's content.
 */
void _shimShadowDomStyling(DocumentFragment template, String name,
    String extendee) {
  if (js.context == null || template == null) return;
  if (!js.context.hasProperty('ShadowDOMPolyfill')) return;

  var platform = js.context['Platform'];
  if (platform == null) return;
  var shadowCss = platform['ShadowCSS'];
  if (shadowCss == null) return;
  shadowCss.callMethod('shimStyling', [template, name, extendee]);
}

const _STYLE_SELECTOR = 'style';
const _SHEET_SELECTOR = '[rel=stylesheet]';
const _STYLE_GLOBAL_SCOPE = 'global';
const _SCOPE_ATTR = 'polymer-scope';
const _STYLE_SCOPE_ATTRIBUTE = 'element';
const _STYLE_CONTROLLER_SCOPE = 'controller';

String _cssTextFromSheet(LinkElement sheet) {
  if (sheet == null) return '';

  // TODO(jmesserly): sometimes the href property is wrong after deployment.
  var href = sheet.href;
  if (href == '') href = sheet.attributes["href"];

  if (js.context != null && js.context.hasProperty('HTMLImports')) {
    var jsSheet = new js.JsObject.fromBrowserObject(sheet);
    var resource = jsSheet['__resource'];
    if (resource != null) return resource;
    _sheetLog.fine('failed to get stylesheet text href="$href"');
    return '';
  }
  // TODO(jmesserly): it seems like polymer-js is always polyfilling
  // HTMLImports, because their code depends on "__resource" to work.
  // We work around this by using a sync XHR to get the stylesheet text.
  // Right now this code is only used in Dartium, but if it's going to stick
  // around we will need to find a different approach.
  try {
    return (new HttpRequest()
        ..open('GET', href, async: false)
        ..send())
        .responseText;
  } on DomException catch (e, t) {
    _sheetLog.fine('failed to get stylesheet text href="$href" error: '
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
