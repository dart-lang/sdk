// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._debugger;

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;
import 'dart:core';

/// Config object to pass to devtools to signal that an object should not be
/// formatted by the Dart formatter. This is used to specify that an Object
/// should just be displayed using the regular JavaScript view instead of a
/// custom Dart view. For example, this is used to display the JavaScript view
/// of a Dart Function as a child of the regular Function object.
const skipDartConfig = const Object();
final int maxIterableChildrenToDisplay = 50;

var _devtoolsFormatter = new JsonMLFormatter(new DartFormatter());

String _typeof(object) => JS('String', 'typeof #', object);
bool _instanceof(object, clazz) => JS('bool', '# instanceof #', object, clazz);

List<String> getOwnPropertyNames(object) => JS('List<String>',
    'dart.list(Object.getOwnPropertyNames(#), #)', object, String);

List getOwnPropertySymbols(object) =>
    JS('List', 'Object.getOwnPropertySymbols(#)', object);

// TODO(jacobr): move this to dart:js and fully implement.
class JSNative {
  // Name may be a String or a Symbol.
  static getProperty(object, name) => JS('', '#[#]', object, name);
  // Name may be a String or a Symbol.
  static setProperty(object, name, value) =>
      JS('', '#[#]=#', object, name, value);
}

bool isRegularDartObject(object) {
  if (_typeof(object) == 'function') return false;
  return _instanceof(object, JS('Type', '#', Object));
}

String getObjectTypeName(object) {
  var reifiedType = dart.getReifiedType(object);
  if (reifiedType == null) {
    if (_typeof(object) == 'function') {
      return '[[Raw JavaScript Function]]';
    }
    return '<Error getting type name>';
  }
  return getTypeName(reifiedType);
}

String getTypeName(Type type) {
  var name = dart.typeName(type);
  // Hack to cleanup names for List<dynamic>
  // TODO(jacobr): it would be nice if there was a way we could distinguish
  // between a List<dynamic> created from Dart and an Array passed in from
  // JavaScript.
  if (name == 'JSArray<dynamic>' ||
      name == 'JSObject<Array>') return 'List<dynamic>';
  return name;
}

String safePreview(object) {
  try {
    var preview = _devtoolsFormatter._simpleFormatter.preview(object);
    if (preview != null) return preview;
    return object.toString();
  } catch (e) {
    return '<Exception thrown>';
  }
}

String symbolName(symbol) {
  var name = symbol.toString();
  assert(name.startsWith('Symbol('));
  return name.substring('Symbol('.length, name.length - 1);
}

bool hasMethod(object, String name) {
  try {
    return dart.hasMethod(object, name);
  } catch (e) {
    return false;
  }
}

/// [JsonMLFormatter] consumes [NameValuePair] objects and
class NameValuePair {
  NameValuePair({this.name, this.value, bool skipDart})
      : skipDart = skipDart == true;

  final String name;
  final Object value;
  final bool skipDart;
}

class MapEntry {
  MapEntry({this.key, this.value});

  final String key;
  final Object value;
}

class ClassMetadata {
  ClassMetadata(this.object);

  final Object object;
}

class HeritageClause {
  HeritageClause(this.name, this.types);

  final String name;
  final List types;
}

/// Class to simplify building the JsonML objects expected by the
/// Devtools Formatter API.
class JsonMLElement {
  dynamic _attributes;
  List _jsonML;

  JsonMLElement(tagName) {
    _attributes = JS('', '{}');
    _jsonML = [tagName, _attributes];
  }

  appendChild(element) {
    _jsonML.add(element.toJsonML());
  }

  JsonMLElement createChild(String tagName) {
    var c = new JsonMLElement(tagName);
    _jsonML.add(c.toJsonML());
    return c;
  }

  JsonMLElement createObjectTag(object) =>
      createChild('object')..addAttribute('object', object);

  void setStyle(String style) {
    _attributes.style = style;
  }

  addStyle(String style) {
    if (_attributes.style == null) {
      _attributes.style = style;
    } else {
      _attributes.style += style;
    }
  }

  addAttribute(key, value) {
    JSNative.setProperty(_attributes, key, value);
  }

  createTextChild(String text) {
    _jsonML.add(text);
  }

  toJsonML() => _jsonML;
}

/// Class implementing the Devtools Formatter API described by:
/// https://docs.google.com/document/d/1FTascZXT9cxfetuPRT2eXPQKXui4nWFivUnS_335T3U
/// Specifically, a formatter implements a header, hasBody, and body method.
/// This class renders the simple structured format objects [_simpleFormatter]
/// provides as JsonML.
class JsonMLFormatter {
  // TODO(jacobr): define a SimpleFormatter base class that DartFormatter
  // implements if we decide to use this class elsewhere. We specify that the
  // type is DartFormatter here purely to get type checking benefits not because
  // this class is really intended to only support instances of type
  // DartFormatter.
  DartFormatter _simpleFormatter;

  JsonMLFormatter(this._simpleFormatter);

  header(object, config) {
    if (identical(config, skipDartConfig)) return null;

    var c = _simpleFormatter.preview(object);
    if (c == null) return null;

    // Indicate this is a Dart Object by using a Dart background color.
    // This is stylistically a bit ugly but it eases distinguishing Dart and
    // JS objects.
    var element = new JsonMLElement('span')
      ..setStyle('background-color: #d9edf7')
      ..createTextChild(c);
    return element.toJsonML();
  }

  bool hasBody(object) => _simpleFormatter.hasChildren(object);

  body(object) {
    var body = new JsonMLElement('ol')
      ..setStyle('list-style-type: none;'
          'padding-left: 0px;'
          'margin-top: 0px;'
          'margin-bottom: 0px;'
          'margin-left: 12px');
    var children = _simpleFormatter.children(object);
    for (NameValuePair child in children) {
      var li = body.createChild('li');
      var nameSpan = new JsonMLElement('span')
        ..createTextChild(child.name != null ? child.name + ': ' : '')
        ..setStyle('color: rgb(136, 19, 145);');
      if (_typeof(child.value) == 'object' ||
          _typeof(child.value) == 'function') {
        nameSpan.addStyle("padding-left: 13px;");

        li.appendChild(nameSpan);
        var objectTag = li.createObjectTag(child.value);
        if (child.skipDart) {
          objectTag.addAttribute('config', skipDartConfig);
        }
        if (!_simpleFormatter.hasChildren(child.value)) {
          li.setStyle("padding-left: 13px;");
        }
      } else {
        li.setStyle("padding-left: 13px;");
        li.createChild('span')
          ..appendChild(nameSpan)
          ..createTextChild(safePreview(child.value));
      }
    }
    return body.toJsonML();
  }
}

abstract class Formatter {
  bool accept(object);
  String preview(object);
  bool hasChildren(object);
  List<NameValuePair> children(object);
}

class DartFormatter {
  List<Formatter> _formatters;

  DartFormatter() {
    // The order of formatters matters as formatters later in the list take
    // precidence.
    _formatters = [
      new FunctionFormatter(),
      new MapFormatter(),
      new IterableFormatter(),
      new MapEntryFormatter(),
      new ClassMetadataFormatter(),
      new HeritageClauseFormatter(),
      new ObjectFormatter()
    ];
  }

  String preview(object) {
    if (object == null) return 'null';
    if (object is num) return object.toString();
    if (object is String) return '"$object"';

    for (var formatter in _formatters) {
      if (formatter.accept(object)) return formatter.preview(object);
    }

    return null;
  }

  bool hasChildren(object) {
    if (object == null) return false;

    for (var formatter in _formatters) {
      if (formatter.accept(object)) return formatter.hasChildren(object);
    }

    return false;
  }

  List<NameValuePair> children(object) {
    if (object != null) {
      for (var formatter in _formatters) {
        if (formatter.accept(object)) return formatter.children(object);
      }
    }
    return <NameValuePair>[];
  }
}

/// Default formatter for Dart Objects.
class ObjectFormatter extends Formatter {
  bool accept(object) => isRegularDartObject(object);

  String preview(object) => getObjectTypeName(object);

  bool hasChildren(object) => true;

  /// Helper to add members walking up the prototype chain being careful
  /// to avoid properties that are Dart methods.
  _addMembers(current, object, List<NameValuePair> properties) {
    // TODO(jacobr): optionally distinguish properties and fields so that
    // it is safe to expand untrusted objects without side effects.
    var className = dart.getReifiedType(current).name;
    for (var name in getOwnPropertyNames(current)) {
      if (name == 'constructor' ||
          name == '__proto__' ||
          name == className) continue;
      if (hasMethod(object, name)) {
        continue;
      }
      var value;
      try {
        value = JSNative.getProperty(object, name);
      } catch (e) {
        value = '<Exception thrown>';
      }
      properties.add(new NameValuePair(name: name, value: value));
    }
    for (var symbol in getOwnPropertySymbols(current)) {
      var dartName = symbolName(symbol);
      if (hasMethod(object, dartName)) {
        continue;
      }
      var value;
      try {
        value = JSNative.getProperty(object, symbol);
      } catch (e) {
        value = '<Exception thrown>';
      }
      properties.add(new NameValuePair(name: dartName, value: value));
    }
    var base = JSNative.getProperty(current, '__proto__');
    if (base == null) return;
    if (isRegularDartObject(base)) {
      _addMembers(base, object, properties);
    }
  }

  List<NameValuePair> children(object) {
    var properties = <NameValuePair>[];
    addMetadataChildren(object, properties);
    _addMembers(object, object, properties);
    return properties;
  }

  addMetadataChildren(object, List<NameValuePair> ret) {
    ret.add(
        new NameValuePair(name: '[[class]]', value: new ClassMetadata(object)));
  }
}

/// Formatter for Dart Function objects.
/// Dart functions happen to be regular JavaScript Function objects but
/// we can distinguish them based on whether they have been tagged with
/// runtime type information.
class FunctionFormatter extends Formatter {
  accept(object) {
    if (_typeof(object) != 'function') return false;
    return dart.getReifiedType(object) != null;
  }

  bool hasChildren(object) => true;

  String preview(object) {
    return dart.typeName(dart.getReifiedType(object));
  }

  List<NameValuePair> children(object) => <NameValuePair>[
        new NameValuePair(name: 'signature', value: preview(object)),
        new NameValuePair(
            name: 'JavaScript Function', value: object, skipDart: true)
      ];
}

/// Formatter for Dart Map objects.
class MapFormatter extends ObjectFormatter {
  accept(object) => object is Map;

  bool hasChildren(object) => true;

  String preview(object) {
    Map map = object;
    return '${getObjectTypeName(map)} length ${map.length}';
  }

  List<NameValuePair> children(object) {
    // TODO(jacobr): be lazier about enumerating contents of Maps that are not
    // the build in LinkedHashMap class.
    // TODO(jacobr): handle large Maps better.
    Map map = object;
    var keys = map.keys.toList();
    var entries = <NameValuePair>[];
    map.forEach((key, value) {
      var entryWrapper = new MapEntry(key: key, value: value);
      entries.add(new NameValuePair(
          name: entries.length.toString(), value: entryWrapper));
    });
    addMetadataChildren(object, entries);
    return entries;
  }
}

/// Formatter for Dart Iterable objects including List and Set.
class IterableFormatter extends ObjectFormatter {
  bool accept(object) => object is Iterable;

  String preview(object) {
    Iterable iterable = object;
    try {
      var length = iterable.length;
      return '${getObjectTypeName(iterable)} length $length';
    } catch (_) {
      return '${getObjectTypeName(iterable)}';
    }
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) {
    // TODO(jacobr): be lazier about enumerating contents of Iterables that
    // are not the built in Set or List types.
    // TODO(jacobr): handle large Iterables better.
    // TODO(jacobr): consider only using numeric indices
    Iterable iterable = object;
    var ret = <NameValuePair>[];
    var i = 0;
    for (var entry in iterable) {
      if (i > maxIterableChildrenToDisplay) {
        ret.add(new NameValuePair(
            name: 'Warning', value: 'Truncated Iterable display'));
        // TODO(jacobr): provide an expandable entry to show more entries.
        break;
      }
      ret.add(new NameValuePair(name: i.toString(), value: entry));
      i++;
    }
    // TODO(jacobr): provide a link to show regular class properties here.
    // required for subclasses of iterable, etc.
    addMetadataChildren(object, ret);
    return ret;
  }
}

// This class does double duting displaying metadata for
class ClassMetadataFormatter implements Formatter {
  accept(object) => object is ClassMetadata;

  _getType(object) {
    if (object is Type) return object;
    return dart.getReifiedType(object);
  }

  String preview(object) {
    ClassMetadata entry = object;
    return getTypeName(_getType(entry.object));
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) {
    ClassMetadata entry = object;
    // TODO(jacobr): add other entries describing the class such as
    // links to the superclass, mixins, implemented interfaces, and methods.
    var type = _getType(entry.object);
    var ret = <NameValuePair>[];
    var implements = dart.getImplements(type);
    if (implements != null) {
      ret.add(new NameValuePair(
          name: '[[Implements]]',
          value: new HeritageClause('implements', implements())));
    }
    var mixins = dart.getMixins(type);
    if (mixins != null) {
      ret.add(new NameValuePair(
          name: '[[Mixins]]', value: new HeritageClause('mixins', mixins())));
    }
    ret.add(new NameValuePair(
        name: '[[JavaScript View]]', value: entry.object, skipDart: true));

    // TODO(jacobr): provide a link to the base class or perhaps the entire
    // base class hierarchy as a flat list.

    if (entry.object is! Type) {
      ret.add(new NameValuePair(
          name: '[[JavaScript Constructor]]',
          value: JSNative.getProperty(entry.object, 'constructor'),
          skipDart: true));
      // TODO(jacobr): add constructors, methods, extended class, and static
    }
    return ret;
  }
}

/// Formatter for synthetic MapEntry objects used to display contents of a Map
/// cleanly.
class MapEntryFormatter implements Formatter {
  accept(object) => object is MapEntry;

  String preview(object) {
    MapEntry entry = object;
    return '${safePreview(entry.key)} => ${safePreview(entry.value)}';
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) => <NameValuePair>[
        new NameValuePair(name: 'key', value: object.key),
        new NameValuePair(name: 'value', value: object.value)
      ];
}

/// Formatter for Dart Iterable objects including List and Set.
class HeritageClauseFormatter implements Formatter {
  bool accept(object) => object is HeritageClause;

  String preview(object) {
    HeritageClause clause = object;
    var typeNames = clause.types.map((type) => getTypeName(type));
    return '${clause.name} ${typeNames.join(", ")}';
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) {
    HeritageClause clause = object;
    var ret = <NameValuePair>[];
    for (var type in clause.types) {
      ret.add(new NameValuePair(value: new ClassMetadata(type)));
    }
    return ret;
  }
}

/// This entry point is automatically invoked by the code generated by
/// Dart Dev Compiler
registerDevtoolsFormatter() {
  var formatters = [_devtoolsFormatter];
  JS('', 'dart.global.devtoolsFormatters = #', formatters);
}
