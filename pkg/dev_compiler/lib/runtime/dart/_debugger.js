dart_library.library('dart/_debugger', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  const skipDartConfig = dart.const(new core.Object());
  exports.maxIterableChildrenToDisplay = 50;
  dart.defineLazyProperties(exports, {
    get _devtoolsFormatter() {
      return new JsonMLFormatter(new DartFormatter());
    },
    set _devtoolsFormatter(_) {}
  });
  function _typeof(object) {
    return typeof object;
  }
  dart.fn(_typeof, core.String, [dart.dynamic]);
  function _instanceof(object, clazz) {
    return object instanceof clazz;
  }
  dart.fn(_instanceof, core.bool, [dart.dynamic, dart.dynamic]);
  function getOwnPropertyNames(object) {
    return dart.as(dart.list(Object.getOwnPropertyNames(object), core.String), core.List$(core.String));
  }
  dart.fn(getOwnPropertyNames, core.List$(core.String), [dart.dynamic]);
  function getOwnPropertySymbols(object) {
    return Object.getOwnPropertySymbols(object);
  }
  dart.fn(getOwnPropertySymbols, core.List, [dart.dynamic]);
  class JSNative extends core.Object {
    static getProperty(object, name) {
      return object[name];
    }
    static setProperty(object, name, value) {
      return object[name] = value;
    }
  }
  dart.setSignature(JSNative, {
    statics: () => ({
      getProperty: [dart.dynamic, [dart.dynamic, dart.dynamic]],
      setProperty: [dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['getProperty', 'setProperty']
  });
  function isRegularDartObject(object) {
    if (_typeof(object) == 'function') return false;
    return _instanceof(object, core.Object);
  }
  dart.fn(isRegularDartObject, core.bool, [dart.dynamic]);
  function getObjectTypeName(object) {
    let realRuntimeType = dart.realRuntimeType(object);
    if (realRuntimeType == null) {
      if (_typeof(object) == 'function') {
        return '[[Raw JavaScript Function]]';
      }
      return '<Error getting type name>';
    }
    return getTypeName(dart.as(realRuntimeType, core.Type));
  }
  dart.fn(getObjectTypeName, core.String, [dart.dynamic]);
  function getTypeName(type) {
    let name = dart.typeName(type);
    if (dart.equals(name, 'JSArray<dynamic>') || dart.equals(name, 'JSObject<Array>')) return 'List<dynamic>';
    return dart.as(name, core.String);
  }
  dart.fn(getTypeName, core.String, [core.Type]);
  const _simpleFormatter = Symbol('_simpleFormatter');
  function safePreview(object) {
    try {
      let preview = exports._devtoolsFormatter[_simpleFormatter].preview(object);
      if (preview != null) return preview;
      return dart.toString(object);
    } catch (e) {
      return '<Exception thrown>';
    }

  }
  dart.fn(safePreview, core.String, [dart.dynamic]);
  function symbolName(symbol) {
    let name = dart.toString(symbol);
    dart.assert(name[dartx.startsWith]('Symbol('));
    return name[dartx.substring]('Symbol('[dartx.length], dart.notNull(name[dartx.length]) - 1);
  }
  dart.fn(symbolName, core.String, [dart.dynamic]);
  function hasMethod(object, name) {
    try {
      return dart.as(dart.hasMethod(object, name), core.bool);
    } catch (e) {
      return false;
    }

  }
  dart.fn(hasMethod, core.bool, [dart.dynamic, core.String]);
  class NameValuePair extends core.Object {
    NameValuePair(opts) {
      let name = opts && 'name' in opts ? opts.name : null;
      let value = opts && 'value' in opts ? opts.value : null;
      let skipDart = opts && 'skipDart' in opts ? opts.skipDart : null;
      this.name = name;
      this.value = value;
      this.skipDart = skipDart == true;
    }
  }
  dart.setSignature(NameValuePair, {
    constructors: () => ({NameValuePair: [NameValuePair, [], {name: core.String, value: core.Object, skipDart: core.bool}]})
  });
  class MapEntry extends core.Object {
    MapEntry(opts) {
      let key = opts && 'key' in opts ? opts.key : null;
      let value = opts && 'value' in opts ? opts.value : null;
      this.key = key;
      this.value = value;
    }
  }
  dart.setSignature(MapEntry, {
    constructors: () => ({MapEntry: [MapEntry, [], {key: core.String, value: core.Object}]})
  });
  class ClassMetadata extends core.Object {
    ClassMetadata(object) {
      this.object = object;
    }
  }
  dart.setSignature(ClassMetadata, {
    constructors: () => ({ClassMetadata: [ClassMetadata, [core.Object]]})
  });
  class HeritageClause extends core.Object {
    HeritageClause(name, types) {
      this.name = name;
      this.types = types;
    }
  }
  dart.setSignature(HeritageClause, {
    constructors: () => ({HeritageClause: [HeritageClause, [core.String, core.List]]})
  });
  const _attributes = Symbol('_attributes');
  const _jsonML = Symbol('_jsonML');
  class JsonMLElement extends core.Object {
    JsonMLElement(tagName) {
      this[_attributes] = null;
      this[_jsonML] = null;
      this[_attributes] = {};
      this[_jsonML] = [tagName, this[_attributes]];
    }
    appendChild(element) {
      this[_jsonML][dartx.add](dart.dsend(element, 'toJsonML'));
    }
    createChild(tagName) {
      let c = new JsonMLElement(tagName);
      this[_jsonML][dartx.add](c.toJsonML());
      return c;
    }
    createObjectTag(object) {
      return (() => {
        let _ = this.createChild('object');
        _.addAttribute('object', object);
        return _;
      }).bind(this)();
    }
    setStyle(style) {
      dart.dput(this[_attributes], 'style', style);
    }
    addStyle(style) {
      if (dart.dload(this[_attributes], 'style') == null) {
        dart.dput(this[_attributes], 'style', style);
      } else {
        let o = this[_attributes];
        dart.dput(o, 'style', dart.dsend(dart.dload(o, 'style'), '+', style));
      }
    }
    addAttribute(key, value) {
      JSNative.setProperty(this[_attributes], key, value);
    }
    createTextChild(text) {
      this[_jsonML][dartx.add](text);
    }
    toJsonML() {
      return this[_jsonML];
    }
  }
  dart.setSignature(JsonMLElement, {
    constructors: () => ({JsonMLElement: [JsonMLElement, [dart.dynamic]]}),
    methods: () => ({
      appendChild: [dart.dynamic, [dart.dynamic]],
      createChild: [JsonMLElement, [core.String]],
      createObjectTag: [JsonMLElement, [dart.dynamic]],
      setStyle: [dart.void, [core.String]],
      addStyle: [dart.dynamic, [core.String]],
      addAttribute: [dart.dynamic, [dart.dynamic, dart.dynamic]],
      createTextChild: [dart.dynamic, [core.String]],
      toJsonML: [dart.dynamic, []]
    })
  });
  class JsonMLFormatter extends core.Object {
    JsonMLFormatter(simpleFormatter) {
      this[_simpleFormatter] = simpleFormatter;
    }
    header(object, config) {
      if (dart.notNull(core.identical(config, skipDartConfig))) return null;
      let c = this[_simpleFormatter].preview(object);
      if (c == null) return null;
      let element = new JsonMLElement('span');
      element.setStyle('background-color: #d9edf7');
      element.createTextChild(c);
      return element.toJsonML();
    }
    hasBody(object) {
      return this[_simpleFormatter].hasChildren(object);
    }
    body(object) {
      let body = new JsonMLElement('ol');
      body.setStyle('list-style-type: none;' + 'padding-left: 0px;' + 'margin-top: 0px;' + 'margin-bottom: 0px;' + 'margin-left: 12px');
      let children = this[_simpleFormatter].children(object);
      for (let child of children) {
        let li = body.createChild('li');
        let nameSpan = new JsonMLElement('span');
        nameSpan.createTextChild(child.name != null ? dart.notNull(child.name) + ': ' : '');
        nameSpan.setStyle('color: rgb(136, 19, 145);');
        if (_typeof(child.value) == 'object' || _typeof(child.value) == 'function') {
          nameSpan.addStyle("padding-left: 13px;");
          li.appendChild(nameSpan);
          let objectTag = li.createObjectTag(child.value);
          if (dart.notNull(child.skipDart)) {
            objectTag.addAttribute('config', skipDartConfig);
          }
          if (!dart.notNull(this[_simpleFormatter].hasChildren(child.value))) {
            li.setStyle("padding-left: 13px;");
          }
        } else {
          li.setStyle("padding-left: 13px;");
          let _ = li.createChild('span');
          _.appendChild(nameSpan);
          _.createTextChild(safePreview(child.value));
        }
      }
      return body.toJsonML();
    }
  }
  dart.setSignature(JsonMLFormatter, {
    constructors: () => ({JsonMLFormatter: [JsonMLFormatter, [DartFormatter]]}),
    methods: () => ({
      header: [dart.dynamic, [dart.dynamic, dart.dynamic]],
      hasBody: [core.bool, [dart.dynamic]],
      body: [dart.dynamic, [dart.dynamic]]
    })
  });
  class Formatter extends core.Object {}
  const _formatters = Symbol('_formatters');
  class DartFormatter extends core.Object {
    DartFormatter() {
      this[_formatters] = null;
      this[_formatters] = dart.list([new FunctionFormatter(), new MapFormatter(), new IterableFormatter(), new MapEntryFormatter(), new ClassMetadataFormatter(), new HeritageClauseFormatter(), new ObjectFormatter()], Formatter);
    }
    preview(object) {
      if (object == null) return 'null';
      if (typeof object == 'number') return dart.toString(object);
      if (typeof object == 'string') return `"${object}"`;
      for (let formatter of this[_formatters]) {
        if (dart.notNull(formatter.accept(object))) return formatter.preview(object);
      }
      return null;
    }
    hasChildren(object) {
      if (object == null) return false;
      for (let formatter of this[_formatters]) {
        if (dart.notNull(formatter.accept(object))) return formatter.hasChildren(object);
      }
      return false;
    }
    children(object) {
      if (object != null) {
        for (let formatter of this[_formatters]) {
          if (dart.notNull(formatter.accept(object))) return formatter.children(object);
        }
      }
      return dart.list([], NameValuePair);
    }
  }
  dart.setSignature(DartFormatter, {
    constructors: () => ({DartFormatter: [DartFormatter, []]}),
    methods: () => ({
      preview: [core.String, [dart.dynamic]],
      hasChildren: [core.bool, [dart.dynamic]],
      children: [core.List$(NameValuePair), [dart.dynamic]]
    })
  });
  const _addMembers = Symbol('_addMembers');
  class ObjectFormatter extends Formatter {
    accept(object) {
      return isRegularDartObject(object);
    }
    preview(object) {
      return getObjectTypeName(object);
    }
    hasChildren(object) {
      return true;
    }
    [_addMembers](current, object, properties) {
      let className = dart.dload(dart.realRuntimeType(current), 'name');
      for (let name of getOwnPropertyNames(current)) {
        if (name == 'constructor' || name == '__proto__' || dart.equals(name, className)) continue;
        if (dart.notNull(hasMethod(object, name))) {
          continue;
        }
        let value = null;
        try {
          value = JSNative.getProperty(object, name);
        } catch (e) {
          value = '<Exception thrown>';
        }

        properties[dartx.add](new NameValuePair({name: name, value: value}));
      }
      for (let symbol of getOwnPropertySymbols(current)) {
        let dartName = symbolName(symbol);
        if (dart.notNull(hasMethod(object, dartName))) {
          continue;
        }
        let value = null;
        try {
          value = JSNative.getProperty(object, symbol);
        } catch (e) {
          value = '<Exception thrown>';
        }

        properties[dartx.add](new NameValuePair({name: dartName, value: value}));
      }
      let base = JSNative.getProperty(current, '__proto__');
      if (base == null) return;
      if (dart.notNull(isRegularDartObject(base))) {
        this[_addMembers](base, object, properties);
      }
    }
    children(object) {
      let properties = dart.list([], NameValuePair);
      this.addMetadataChildren(object, properties);
      this[_addMembers](object, object, properties);
      return properties;
    }
    addMetadataChildren(object, ret) {
      ret[dartx.add](new NameValuePair({name: '[[class]]', value: new ClassMetadata(object)}));
    }
  }
  dart.setSignature(ObjectFormatter, {
    methods: () => ({
      accept: [core.bool, [dart.dynamic]],
      preview: [core.String, [dart.dynamic]],
      hasChildren: [core.bool, [dart.dynamic]],
      [_addMembers]: [dart.dynamic, [dart.dynamic, dart.dynamic, core.List$(NameValuePair)]],
      children: [core.List$(NameValuePair), [dart.dynamic]],
      addMetadataChildren: [dart.dynamic, [dart.dynamic, core.List$(NameValuePair)]]
    })
  });
  class FunctionFormatter extends Formatter {
    accept(object) {
      if (_typeof(object) != 'function') return false;
      return dart.realRuntimeType(object) != null;
    }
    hasChildren(object) {
      return true;
    }
    preview(object) {
      return dart.as(dart.typeName(dart.realRuntimeType(object)), core.String);
    }
    children(object) {
      return dart.list([new NameValuePair({name: 'signature', value: this.preview(object)}), new NameValuePair({name: 'JavaScript Function', value: object, skipDart: true})], NameValuePair);
    }
  }
  dart.setSignature(FunctionFormatter, {
    methods: () => ({
      accept: [core.bool, [dart.dynamic]],
      hasChildren: [core.bool, [dart.dynamic]],
      preview: [core.String, [dart.dynamic]],
      children: [core.List$(NameValuePair), [dart.dynamic]]
    })
  });
  class MapFormatter extends ObjectFormatter {
    accept(object) {
      return dart.is(object, core.Map);
    }
    hasChildren(object) {
      return true;
    }
    preview(object) {
      let map = dart.as(object, core.Map);
      return `${getObjectTypeName(map)} length ${map.length}`;
    }
    children(object) {
      let map = dart.as(object, core.Map);
      let keys = map.keys[dartx.toList]();
      let entries = dart.list([], NameValuePair);
      map.forEach(dart.fn((key, value) => {
        let entryWrapper = new MapEntry({key: dart.as(key, core.String), value: value});
        entries[dartx.add](new NameValuePair({name: dart.toString(entries[dartx.length]), value: entryWrapper}));
      }, dart.void, [dart.dynamic, dart.dynamic]));
      this.addMetadataChildren(object, entries);
      return entries;
    }
  }
  class IterableFormatter extends ObjectFormatter {
    accept(object) {
      return dart.is(object, core.Iterable);
    }
    preview(object) {
      let iterable = dart.as(object, core.Iterable);
      try {
        let length = iterable[dartx.length];
        return `${getObjectTypeName(iterable)} length ${length}`;
      } catch (_) {
        return `${getObjectTypeName(iterable)}`;
      }

    }
    hasChildren(object) {
      return true;
    }
    children(object) {
      let iterable = dart.as(object, core.Iterable);
      let ret = dart.list([], NameValuePair);
      let i = 0;
      for (let entry of iterable) {
        if (i > dart.notNull(exports.maxIterableChildrenToDisplay)) {
          ret[dartx.add](new NameValuePair({name: 'Warning', value: 'Truncated Iterable display'}));
          break;
        }
        ret[dartx.add](new NameValuePair({name: dart.toString(i), value: entry}));
        i++;
      }
      this.addMetadataChildren(object, ret);
      return ret;
    }
  }
  const _getType = Symbol('_getType');
  class ClassMetadataFormatter extends core.Object {
    accept(object) {
      return dart.is(object, ClassMetadata);
    }
    [_getType](object) {
      if (dart.is(object, core.Type)) return object;
      return dart.realRuntimeType(object);
    }
    preview(object) {
      let entry = dart.as(object, ClassMetadata);
      return getTypeName(dart.as(this[_getType](entry.object), core.Type));
    }
    hasChildren(object) {
      return true;
    }
    children(object) {
      let entry = dart.as(object, ClassMetadata);
      let type = this[_getType](entry.object);
      let ret = dart.list([], NameValuePair);
      let implements$ = dart.getImplements(type);
      if (implements$ != null) {
        ret[dartx.add](new NameValuePair({name: '[[Implements]]', value: new HeritageClause('implements', dart.as(dart.dcall(implements$), core.List))}));
      }
      let mixins = dart.getMixins(type);
      if (mixins != null) {
        ret[dartx.add](new NameValuePair({name: '[[Mixins]]', value: new HeritageClause('mixins', dart.as(dart.dcall(mixins), core.List))}));
      }
      ret[dartx.add](new NameValuePair({name: '[[JavaScript View]]', value: entry.object, skipDart: true}));
      if (!dart.is(entry.object, core.Type)) {
        ret[dartx.add](new NameValuePair({name: '[[JavaScript Constructor]]', value: JSNative.getProperty(entry.object, 'constructor'), skipDart: true}));
      }
      return ret;
    }
  }
  ClassMetadataFormatter[dart.implements] = () => [Formatter];
  dart.setSignature(ClassMetadataFormatter, {
    methods: () => ({
      accept: [core.bool, [dart.dynamic]],
      [_getType]: [dart.dynamic, [dart.dynamic]],
      preview: [core.String, [dart.dynamic]],
      hasChildren: [core.bool, [dart.dynamic]],
      children: [core.List$(NameValuePair), [dart.dynamic]]
    })
  });
  class MapEntryFormatter extends core.Object {
    accept(object) {
      return dart.is(object, MapEntry);
    }
    preview(object) {
      let entry = dart.as(object, MapEntry);
      return `${safePreview(entry.key)} => ${safePreview(entry.value)}`;
    }
    hasChildren(object) {
      return true;
    }
    children(object) {
      return dart.list([new NameValuePair({name: 'key', value: dart.dload(object, 'key')}), new NameValuePair({name: 'value', value: dart.dload(object, 'value')})], NameValuePair);
    }
  }
  MapEntryFormatter[dart.implements] = () => [Formatter];
  dart.setSignature(MapEntryFormatter, {
    methods: () => ({
      accept: [core.bool, [dart.dynamic]],
      preview: [core.String, [dart.dynamic]],
      hasChildren: [core.bool, [dart.dynamic]],
      children: [core.List$(NameValuePair), [dart.dynamic]]
    })
  });
  class HeritageClauseFormatter extends core.Object {
    accept(object) {
      return dart.is(object, HeritageClause);
    }
    preview(object) {
      let clause = dart.as(object, HeritageClause);
      let typeNames = clause.types[dartx.map](dart.fn(type => getTypeName(dart.as(type, core.Type)), core.String, [dart.dynamic]));
      return `${clause.name} ${typeNames[dartx.join](", ")}`;
    }
    hasChildren(object) {
      return true;
    }
    children(object) {
      let clause = dart.as(object, HeritageClause);
      let ret = dart.list([], NameValuePair);
      for (let type of clause.types) {
        ret[dartx.add](new NameValuePair({value: new ClassMetadata(type)}));
      }
      return ret;
    }
  }
  HeritageClauseFormatter[dart.implements] = () => [Formatter];
  dart.setSignature(HeritageClauseFormatter, {
    methods: () => ({
      accept: [core.bool, [dart.dynamic]],
      preview: [core.String, [dart.dynamic]],
      hasChildren: [core.bool, [dart.dynamic]],
      children: [core.List$(NameValuePair), [dart.dynamic]]
    })
  });
  function registerDevtoolsFormatter() {
    let formatters = [exports._devtoolsFormatter];
    window.devtoolsFormatters = formatters;
  }
  dart.fn(registerDevtoolsFormatter);
  // Exports:
  exports.skipDartConfig = skipDartConfig;
  exports.getOwnPropertyNames = getOwnPropertyNames;
  exports.getOwnPropertySymbols = getOwnPropertySymbols;
  exports.JSNative = JSNative;
  exports.isRegularDartObject = isRegularDartObject;
  exports.getObjectTypeName = getObjectTypeName;
  exports.getTypeName = getTypeName;
  exports.safePreview = safePreview;
  exports.symbolName = symbolName;
  exports.hasMethod = hasMethod;
  exports.NameValuePair = NameValuePair;
  exports.MapEntry = MapEntry;
  exports.ClassMetadata = ClassMetadata;
  exports.HeritageClause = HeritageClause;
  exports.JsonMLElement = JsonMLElement;
  exports.JsonMLFormatter = JsonMLFormatter;
  exports.Formatter = Formatter;
  exports.DartFormatter = DartFormatter;
  exports.ObjectFormatter = ObjectFormatter;
  exports.FunctionFormatter = FunctionFormatter;
  exports.MapFormatter = MapFormatter;
  exports.IterableFormatter = IterableFormatter;
  exports.ClassMetadataFormatter = ClassMetadataFormatter;
  exports.MapEntryFormatter = MapEntryFormatter;
  exports.HeritageClauseFormatter = HeritageClauseFormatter;
  exports.registerDevtoolsFormatter = registerDevtoolsFormatter;
});
