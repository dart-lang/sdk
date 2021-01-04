// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../compiler/js_names.dart' as js_ast;
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;

/// Represents a top-level property hoisted to a top-level object.
class ModuleItemData {
  /// The container that holds this module item in the emitted JS.
  js_ast.Identifier id;

  /// This module item's key in the emitted JS.
  ///
  /// A LiteralString if this object is backed by a JS Object/Map.
  /// A LiteralNumber if this object is backed by a JS Array.
  js_ast.Literal jsKey;

  /// This module item's value in the emitted JS.
  js_ast.Expression jsValue;

  ModuleItemData(this.id, this.jsKey, this.jsValue);
}

/// Holds variables emitted during code gen.
///
/// Associates a [K] with a container-unique JS key and arbitrary JS value.
/// The container is emitted as a single object:
/// ```
/// var C = {
///   jsKey: jsValue,
///   ...
/// };
/// ```
abstract class ModuleItemContainer<K> {
  /// Name of the container in the emitted JS.
  String name;

  /// Refers to the latest container if this container is sharded.
  js_ast.Identifier containerId;

  final Map<K, ModuleItemData> moduleItems = {};

  /// Holds keys that will not be emitted when calling [emit].
  final Set<K> _noEmit = {};

  ModuleItemContainer._(this.name, this.containerId);

  /// Creates an automatically sharding container backed by JS Objects.
  factory ModuleItemContainer.asObject(String name,
      {String Function(K) keyToString}) {
    return ModuleItemObjectContainer<K>(name, keyToString);
  }

  /// Creates a container backed by a JS Array.
  factory ModuleItemContainer.asArray(String name) {
    return ModuleItemArrayContainer<K>(name);
  }

  bool get isNotEmpty => moduleItems.isNotEmpty;

  Iterable<K> get keys => moduleItems.keys;

  int get length => moduleItems.keys.length;

  bool get isEmpty => moduleItems.isEmpty;

  js_ast.Expression operator [](K key) => moduleItems[key]?.jsValue;

  void operator []=(K key, js_ast.Expression value);

  /// Returns the expression that retrieves [key]'s corresponding JS value via
  /// a property access through its container.
  js_ast.Expression access(K key);

  bool contains(K key) => moduleItems.containsKey(key);

  bool canEmit(K key) => !_noEmit.contains(key);

  /// Indicates that [K] should be treated as if it weren't hoisted.
  ///
  /// Used when we are managing the variable declarations manually (such as
  /// unhoisting specific symbols for performance reasons).
  void setNoEmit(K key) {
    _noEmit.add(key);
  }

  /// Emit the container declaration/initializer, using multiple statements if
  /// necessary.
  List<js_ast.Statement> emit();

  /// Emit the container declaration/initializer incrementally.
  ///
  /// Used during expression evaluation. Appends all newly added types to the
  /// most recent container.
  List<js_ast.Statement> emitIncremental();
}

/// Associates a [K] with a container-unique JS key and arbitrary JS value.
///
/// Emitted as a series of JS Objects, splitting them into groups of 500 for
/// JS optimization purposes:
/// ```
/// var C = {
///   jsKey: jsValue,
///   ...
/// };
/// var C$1 = { ... };
/// ```
class ModuleItemObjectContainer<K> extends ModuleItemContainer<K> {
  /// Tracks how often JS emitted field names appear.
  ///
  /// [keyToString] may resolve multiple unique keys to the same JS string.
  /// When this occurs, the resolved JS string will automatically be renamed.
  final Map<String, int> _nameFrequencies = {};

  /// Transforms a [K] into a valid name for a JS object property key.
  ///
  /// Non-unique generated strings are automatically renamed.
  String Function(K) keyToString;

  ModuleItemObjectContainer(String name, this.keyToString)
      : super._(name, js_ast.TemporaryId(name));

  @override
  void operator []=(K key, js_ast.Expression value) {
    if (this.contains(key)) {
      moduleItems[key].jsValue = value;
      return;
    }
    // Create a unique name for K when emitted as a JS field.
    var fieldString = keyToString(key);
    _nameFrequencies.update(fieldString, (v) {
      fieldString += '\$${v + 1}';
      return v + 1;
    }, ifAbsent: () {
      // Avoid shadowing common JS properties.
      if (js_ast.objectProperties.contains(fieldString)) {
        fieldString += '\$';
      }
      return 0;
    });
    moduleItems[key] = ModuleItemData(
        containerId, js_ast.LiteralString("'$fieldString'"), value);
    if (length % 500 == 0) containerId = js_ast.TemporaryId(name);
  }

  @override
  js_ast.Expression access(K key) {
    return js.call('#.#', [moduleItems[key].id, moduleItems[key].jsKey]);
  }

  @override
  List<js_ast.Statement> emit() {
    var containersToProperties = <js_ast.Identifier, List<js_ast.Property>>{};
    moduleItems.forEach((k, v) {
      if (_noEmit.contains(k)) return;
      if (!containersToProperties.containsKey(v.id)) {
        containersToProperties[v.id] = <js_ast.Property>[];
      }
      containersToProperties[v.id].add(js_ast.Property(v.jsKey, v.jsValue));
    });

    // Emit a self-reference for the next container so V8 does not optimize it
    // away. Required for expression evaluation.
    if (containersToProperties[containerId] == null) {
      containersToProperties[containerId] = [
        js_ast.Property(
            js_ast.LiteralString('_'), js.call('() => #', [containerId]))
      ];
    }
    var statements = <js_ast.Statement>[];
    containersToProperties.forEach((containerId, properties) {
      var containerObject = js_ast.ObjectInitializer(properties,
          multiline: properties.length > 1);
      statements.add(js.statement(
          'var # = Object.create(#)', [containerId, containerObject]));
    });
    return statements;
  }

  /// Appends all newly added types to the most recent container.
  @override
  List<js_ast.Statement> emitIncremental() {
    var statements = <js_ast.Statement>[];
    moduleItems.forEach((k, v) {
      if (_noEmit.contains(k)) return;
      statements
          .add(js.statement('#[#] = #', [containerId, v.jsKey, v.jsValue]));
    });
    return statements;
  }
}

/// Associates a unique [K] with an arbitrary JS value.
///
/// Emitted as a JS Array:
/// ```
/// var C = [
///   jsValue,
///   ...
/// ];
/// ```
class ModuleItemArrayContainer<K> extends ModuleItemContainer<K> {
  ModuleItemArrayContainer(String name)
      : super._(name, js_ast.TemporaryId(name));

  @override
  void operator []=(K key, js_ast.Expression value) {
    if (moduleItems.containsKey(key)) {
      moduleItems[key].jsValue = value;
      return;
    }
    moduleItems[key] =
        ModuleItemData(containerId, js_ast.LiteralNumber('$length'), value);
  }

  @override
  js_ast.Expression access(K key) {
    return js.call('#[#]', [containerId, moduleItems[key].jsKey]);
  }

  @override
  List<js_ast.Statement> emit() {
    var properties = List<js_ast.Expression>.filled(length, null);

    // If the entire array holds just one value, generate a short initializer.
    var valueSet = <js_ast.Expression>{};
    moduleItems.forEach((k, v) {
      if (_noEmit.contains(k)) return;
      valueSet.add(v.jsValue);
      properties[int.parse((v.jsKey as js_ast.LiteralNumber).value)] =
          v.jsValue;
    });

    if (valueSet.length == 1 && moduleItems.length > 1) {
      return [
        js.statement('var # = Array(#).fill(#)', [
          containerId,
          js_ast.LiteralNumber('${properties.length}'),
          valueSet.first
        ])
      ];
    }
    // Array containers are not sharded, as we do not expect to hit V8's
    // dictionary-mode limit of 99999 elements.
    return [
      js.statement('var # = #', [
        containerId,
        js_ast.ArrayInitializer(properties, multiline: properties.length > 1)
      ])
    ];
  }

  @override
  List<js_ast.Statement> emitIncremental() {
    var statements = <js_ast.Statement>[];
    moduleItems.forEach((k, v) {
      if (_noEmit.contains(k)) return;
      statements
          .add(js.statement('#[#] = #', [containerId, v.jsKey, v.jsValue]));
    });
    return statements;
  }
}
