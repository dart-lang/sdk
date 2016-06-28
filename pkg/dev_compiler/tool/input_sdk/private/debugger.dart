// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._debugger;

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;
import 'dart:core';
import 'dart:collection';
import 'dart:html' as html;
import 'dart:math';

/// JsonMLConfig object to pass to devtools to specify how an Object should
/// be displayed. skipDart signals that an object should not be formatted
/// by the Dart formatter. This is used to specify that an Object
/// should just be displayed using the regular JavaScript view instead of a
/// custom Dart view. For example, this is used to display the JavaScript view
/// of a Dart Function as a child of the regular Function object. keyToString
/// signals that a map key object should have its toString() displayed by
/// the Dart formatter.
///
/// We'd like this to be an enum, but we can't because it's a dev_compiler bug.
class JsonMLConfig {
  const JsonMLConfig(this.name);

  final String name;
  static const none = const JsonMLConfig("none");
  static const skipDart = const JsonMLConfig("skipDart");
  static const keyToString = const JsonMLConfig("keyToString");
}

int maxSpanLength = 100;

var _devtoolsFormatter = new JsonMLFormatter(new DartFormatter());

String _typeof(object) => JS('String', 'typeof #', object);

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
  if (name == 'JSArray<dynamic>' || name == 'JSObject<Array>')
    return 'List<dynamic>';
  return name;
}

String safePreview(object) {
  try {
    var preview = _devtoolsFormatter._simpleFormatter.preview(object);
    if (preview != null) return preview;
    return object.toString();
  } catch (e) {
    return '<Exception thrown> $e';
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
  NameValuePair(
      {this.name,
      this.value,
      this.config: JsonMLConfig.none,
      this.hideName: false});

  // Define equality and hashCode so that NameValuePair can be used
  // in a Set to dedupe entries with duplicate names.
  operator ==(other) => other is NameValuePair && other.name == name;
  int get hashCode => name.hashCode;

  final String name;
  final Object value;
  final JsonMLConfig config;
  final bool hideName;

  String get displayName => hideName ? '' : name;
}

class MapEntry {
  MapEntry({this.key, this.value});

  final Object key;
  final Object value;
}

class IterableSpan {
  IterableSpan({this.start, this.end, this.iterable});

  final int start;
  final int end;
  final Iterable iterable;
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

/// Whether an object is a native JavaScript type where we should display the
/// JavaScript view of the object instead of the custom Dart specific render
/// of properties.
bool isNativeJavaScriptObject(object) {
  var type = _typeof(object);
  // Treat Node objects as a native JavaScript type as the regular DOM render
  // in devtools is superior to the dart specific view.
  return (type != 'object' && type != 'function') ||
      object is dart.JSObject ||
      object is html.Node;
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
    if (config == JsonMLConfig.skipDart || isNativeJavaScriptObject(object)) {
      return null;
    }

    var c = _simpleFormatter.preview(object);
    if (c == null) return null;

    if (config == JsonMLConfig.keyToString) {
      c = object.toString();
    }

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
        ..createTextChild(
            child.displayName.isNotEmpty ? '${child.displayName}: ' : '')
        ..setStyle('color: rgb(136, 19, 145);');
      if (_typeof(child.value) == 'object' ||
          _typeof(child.value) == 'function') {
        nameSpan.addStyle("padding-left: 13px;");

        li.appendChild(nameSpan);
        var objectTag = li.createObjectTag(child.value);
        objectTag.addAttribute('config', child.config);
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
      new IterableSpanFormatter(),
      new ClassMetadataFormatter(),
      new HeritageClauseFormatter(),
      new ObjectFormatter(),
    ];
  }

  String preview(object) {
    try {
      if (object == null ||
          object is num ||
          object is String ||
          isNativeJavaScriptObject(object)) {
        return object.toString();
      }

      for (var formatter in _formatters) {
        if (formatter.accept(object)) return formatter.preview(object);
      }
    } catch (e, trace) {
      // Log formatter internal errors as unfortunately the devtools cannot
      // be used to debug formatter errors.
      html.window.console.error("Caught exception $e\n trace:\n$trace");
    }

    return null;
  }

  bool hasChildren(object) {
    if (object == null) return false;
    try {
      for (var formatter in _formatters) {
        if (formatter.accept(object)) return formatter.hasChildren(object);
      }
    } catch (e, trace) {
      // See comment for preview.
      html.window.console
          .error("[hasChildren] Caught exception $e\n trace:\n$trace");
    }
    return false;
  }

  List<NameValuePair> children(object) {
    try {
      if (object != null) {
        for (var formatter in _formatters) {
          if (formatter.accept(object)) return formatter.children(object);
        }
      }
    } catch (e, trace) {
      // See comment for preview.
      html.window.console.error("Caught exception $e\n trace:\n$trace");
    }
    return <NameValuePair>[];
  }
}

/// Default formatter for Dart Objects.
class ObjectFormatter extends Formatter {
  static Set<String> _customNames = new Set()
    ..add('constructor')
    ..add('prototype')
    ..add('__proto__');
  bool accept(object) => !isNativeJavaScriptObject(object);

  String preview(object) => getObjectTypeName(object);

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) {
    var properties = new LinkedHashSet<NameValuePair>();
    // Set of property names used to avoid duplicates.
    addMetadataChildren(object, properties);

    /// Helper to add members walking up the prototype chain being careful
    /// to avoid properties that are Dart methods.
    var protoChain = <Object>[];
    var current = object;
    while (current != null &&
        !isNativeJavaScriptObject(current) &&
        JS("bool", "# !== Object.prototype", current)) {
      protoChain.add(current);
      current = JSNative.getProperty(current, '__proto__');
    }

    // We walk the prototype chain for symbol properties because they take
    // priority and are accessed instead of Dart properties according to Dart
    // calling conventions.
    // TODO(jacobr): where possible use the data stored by dart.setSignature
    // instead of walking the JavaScript object directly.
    for (current in protoChain) {
      for (var symbol in getOwnPropertySymbols(current)) {
        var dartName = symbolName(symbol);
        if (hasMethod(object, dartName)) {
          continue;
        }
        // TODO(jacobr): find a cleaner solution than checking for dartx
        String dartXPrefix = 'dartx.';
        if (dartName.startsWith(dartXPrefix)) {
          dartName = dartName.substring(dartXPrefix.length);
        } else if (!dartName.startsWith('_')) {
          // Dart method extension names should either be from dartx or should
          // start with an _
          continue;
        }
        var value;
        try {
          value = JSNative.getProperty(object, symbol);
        } catch (e) {
          value = '<Exception thrown> $e';
        }
        properties.add(new NameValuePair(name: dartName, value: value));
      }
    }

    for (current in protoChain) {
      // TODO(jacobr): optionally distinguish properties and fields so that
      // it is safe to expand untrusted objects without side effects.
      var className = dart.getReifiedType(current).name;
      for (var name in getOwnPropertyNames(current)) {
        if (_customNames.contains(name) || name == className) continue;
        if (hasMethod(object, name)) {
          continue;
        }
        var value;
        try {
          value = JSNative.getProperty(object, name);
        } catch (e) {
          value = '<Exception thrown> $e';
        }
        properties.add(new NameValuePair(name: name, value: value));
      }
    }

    return properties.toList();
  }

  addMetadataChildren(object, Set<NameValuePair> ret) {
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
            name: 'JavaScript Function',
            value: object,
            config: JsonMLConfig.skipDart)
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
    var entries = new LinkedHashSet<NameValuePair>();
    map.forEach((key, value) {
      var entryWrapper = new MapEntry(key: key, value: value);
      entries.add(new NameValuePair(
          name: entries.length.toString(), value: entryWrapper));
    });
    addMetadataChildren(object, entries);
    return entries.toList();
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
    var ret = new LinkedHashSet<NameValuePair>();
    ret.addAll(childrenHelper(
        new IterableSpan(start: 0, end: object.length, iterable: object)));
    // TODO(jacobr): provide a link to show regular class properties here.
    // required for subclasses of iterable, etc.
    addMetadataChildren(object, ret);
    return ret.toList();
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
    if (mixins != null && mixins.isNotEmpty) {
      ret.add(new NameValuePair(
          name: '[[Mixins]]', value: new HeritageClause('mixins', mixins)));
    }
    ret.add(new NameValuePair(
        name: '[[JavaScript View]]',
        value: entry.object,
        config: JsonMLConfig.skipDart));

    // TODO(jacobr): provide a link to the base class or perhaps the entire
    // base class hierarchy as a flat list.

    if (entry.object is! Type) {
      ret.add(new NameValuePair(
          name: '[[JavaScript Constructor]]',
          value: JSNative.getProperty(entry.object, 'constructor'),
          config: JsonMLConfig.skipDart));
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
        new NameValuePair(
            name: 'key', value: object.key, config: JsonMLConfig.keyToString),
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

/// Formatter for synthetic IterableSpan objects used to display contents of
/// an Iterable cleanly.
class IterableSpanFormatter implements Formatter {
  accept(object) => object is IterableSpan;

  String preview(object) {
    IterableSpan entry = object;
    return '[${object.start}...${object.end-1}]';
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) => childrenHelper(object);
}

List<NameValuePair> childrenHelper(IterableSpan span) {
  var length = span.end - span.start;
  var ret = new List<NameValuePair>();
  if (length <= maxSpanLength) {
    for (var i = span.start; i < span.end; i++) {
      /// TODO(bmilligan): Stop using elementAt if it becomes a performance
      /// bottleneck in the future.
      ret.add(new NameValuePair(
          name: i.toString(), value: span.iterable.elementAt(i)));
    }
  } else {
    /// Using length - .5, a list of length 10000 results in a
    /// maxPowerOfSubsetSize of 1, so the list will be broken up into 100,
    /// 100-length subsets. A list of length 10001 results in a
    /// maxPowerOfSubsetSize of 2, so the list will be broken up into 1
    /// 10000-length subset and 1 1-length subset.
    var maxPowerOfSubsetSize =
        (log(length - .5) / log(maxSpanLength)).truncate();
    var subsetSize = pow(maxSpanLength, maxPowerOfSubsetSize);
    for (var i = span.start; i < span.end; i += subsetSize) {
      var endIndex = min(span.end, subsetSize + i);
      if (endIndex - i == 1)
        ret.add(new NameValuePair(
            name: i.toString(), value: span.iterable.elementAt(i)));
      else {
        var entryWrapper =
            new IterableSpan(start: i, end: endIndex, iterable: span.iterable);
        ret.add(new NameValuePair(
            name: '[${i}...${endIndex - 1}]',
            value: entryWrapper,
            hideName: true));
      }
    }
  }
  return ret;
}

/// This entry point is automatically invoked by the code generated by
/// Dart Dev Compiler
registerDevtoolsFormatter() {
  var formatters = [_devtoolsFormatter];
  JS('', 'dart.global.devtoolsFormatters = #', formatters);
}
