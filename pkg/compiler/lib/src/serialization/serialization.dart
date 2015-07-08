// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization;

import '../elements/elements.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';

import 'element_serialization.dart';
import 'constant_serialization.dart';
import 'type_serialization.dart';
import 'keys.dart';
import 'json_serializer.dart';
import 'values.dart';

/// An object that supports the encoding an [ObjectValue] for serialization.
///
/// The [ObjectEncoder] ensures that nominality and circularities of
/// non-primitive values like [Element], [DartType] and [ConstantExpression] are
/// handled.
class ObjectEncoder extends AbstractEncoder<Key> {
  /// Creates an [ObjectEncoder] in the scope of [serializer] that uses [map]
  /// as its internal storage.
  ObjectEncoder(Serializer serializer, Map<dynamic, Value> map)
        : super(serializer, map);

  String get _name => 'Object';
}

/// An object that supports the encoding a [MapValue] for serialization.
///
/// The [MapEncoder] ensures that nominality and circularities of
/// non-primitive values like [Element], [DartType] and [ConstantExpression] are
/// handled.
class MapEncoder extends AbstractEncoder<String> {
  /// Creates an [MapEncoder] in the scope of [serializer] that uses [map]
  /// as its internal storage.
  MapEncoder(Serializer serializer, Map<String, Value> map)
      : super(serializer, map);

  String get _name => 'Map';
}

/// An object that supports the encoding a [ListValue] containing [ObjectValue]s
/// or [MapValue]s.
///
/// The [ListEncoder] ensures that nominality and circularities of
/// non-primitive values like [Element], [DartType] and [ConstantExpression] are
/// handled.
class ListEncoder {
  final Serializer _serializer;
  final List<Value> _list;

  /// Creates an [ListEncoder] in the scope of [_serializer] that uses [_list]
  /// as its internal storage.
  ListEncoder(this._serializer, this._list);

  /// Creates an [ObjectEncoder] and adds it to the encoded list.
  ObjectEncoder createObject() {
    Map<Key, Value> map = <Key, Value>{};
    _list.add(new ObjectValue(map));
    return new ObjectEncoder(_serializer, map);
  }

  /// Creates an [ObjectEncoder] and adds it to the encoded list.
  MapEncoder createMap() {
    Map<String, Value> map = {};
    _list.add(new MapValue(map));
    return new MapEncoder(_serializer, map);
  }
}

/// Abstract base implementation for [ObjectEncoder] and [MapEncoder].
abstract class AbstractEncoder<K> {
  final Serializer _serializer;
  final Map<K, Value> _map;

  AbstractEncoder(this._serializer, this._map);

  /// The name of the encoder kind. Use for error reporting.
  String get _name;

  void _checkKey(K key) {
    if (_map.containsKey(key)) {
      throw new StateError("$_name value '$key' already in $_map.");
    }
  }

  /// Maps the [key] entry to the enum [value] in the encoded object.
  void setEnum(K key, var value) {
    _checkKey(key);
    _map[key] = new EnumValue(value);
  }

  /// Maps the [key] entry to the [element] in the encoded object.
  void setElement(K key, Element element) {
    _checkKey(key);
    _map[key] = _serializer.createElementValue(element);
  }

  /// Maps the [key] entry to the [elements] in the encoded object.
  ///
  /// If [elements] is empty, it is skipped.
  void setElements(K key, Iterable<Element> elements) {
    _checkKey(key);
    if (elements.isNotEmpty) {
      _map[key] = new ListValue(
          elements.map(_serializer.createElementValue).toList());
    }
  }

  /// Maps the [key] entry to the [constant] in the encoded object.
  void setConstant(K key, ConstantExpression constant) {
    _checkKey(key);
    _map[key] = _serializer.createConstantValue(constant);
  }

  /// Maps the [key] entry to the [constants] in the encoded object.
  ///
  /// If [constants] is empty, it is skipped.
  void setConstants(K key, Iterable<ConstantExpression> constants) {
    _checkKey(key);
    if (constants.isNotEmpty) {
      _map[key] = new ListValue(
          constants.map(_serializer.createConstantValue).toList());
    }
  }

  /// Maps the [key] entry to the [type] in the encoded object.
  void setType(K key, DartType type) {
    _checkKey(key);
    _map[key] = _serializer.createTypeValue(type);
  }

  /// Maps the [key] entry to the [types] in the encoded object.
  ///
  /// If [types] is empty, it is skipped.
  void setTypes(K key, Iterable<DartType> types) {
    _checkKey(key);
    if (types.isNotEmpty) {
      _map[key] =
          new ListValue(types.map(_serializer.createTypeValue).toList());
    }
  }

  /// Maps the [key] entry to the [uri] in the encoded object using [baseUri] to
  /// relatives the encoding.
  ///
  /// For instance, a source file like `sdk/lib/core/string.dart` should be
  /// serialized relative to the library root.
  void setUri(K key, Uri baseUri, Uri uri) {
    _checkKey(key);
    _map[key] = new UriValue(baseUri, uri);
  }

  /// Maps the [key] entry to the string [value] in the encoded object.
  void setString(K key, String value) {
    _checkKey(key);
    _map[key] = new StringValue(value);
  }

  /// Maps the [key] entry to the string [values] in the encoded object.
  ///
  /// If [values] is empty, it is skipped.
  void setStrings(K key, Iterable<String> values) {
    _checkKey(key);
    if (values.isNotEmpty) {
      _map[key] = new ListValue(values.map((v) => new StringValue(v)).toList());
    }
  }

  /// Maps the [key] entry to the bool [value] in the encoded object.
  void setBool(K key, bool value) {
    _checkKey(key);
    _map[key] = new BoolValue(value);
  }

  /// Maps the [key] entry to the int [value] in the encoded object.
  void setInt(K key, int value) {
    _checkKey(key);
    _map[key] = new IntValue(value);
  }

  /// Maps the [key] entry to the int [values] in this serializer.
  ///
  /// If [values] is empty, it is skipped.
  void setInts(K key, Iterable<int> values) {
    _checkKey(key);
    if (values.isNotEmpty) {
      _map[key] = new ListValue(values.map((v) => new IntValue(v)).toList());
    }
  }

  /// Maps the [key] entry to the double [value] in the encoded object.
  void setDouble(K key, double value) {
    _checkKey(key);
    _map[key] = new DoubleValue(value);
  }

  /// Creates and returns an [ObjectEncoder] that is mapped to the [key]
  /// entry in the encoded object.
  ObjectEncoder createObject(K key) {
    Map<Key, Value> map = <Key, Value>{};
    _map[key] = new ObjectValue(map);
    return new ObjectEncoder(_serializer, map);
  }

  /// Creates and returns a [MapEncoder] that is mapped to the [key] entry
  /// in the encoded object.
  MapEncoder createMap(K key) {
    Map<String, Value> map = <String, Value>{};
    _map[key] = new MapValue(map);
    return new MapEncoder(_serializer, map);
  }

  /// Creates and returns a [ListEncoder] that is mapped to the [key] entry
  /// in the encoded object.
  ListEncoder createList(K key) {
    List<Value> list = <Value>[];
    _map[key] = new ListValue(list);
    return new ListEncoder(_serializer, list);
  }

  String toString() => _map.toString();
}

/// [ObjectDecoder] reads serialized values from a [Map] encoded from an
/// [ObjectValue] where properties are stored using [Key] values as keys.
class ObjectDecoder extends AbstractDecoder<Key> {
  /// Creates an [ObjectDecoder] that decodes [map] into deserialized values
  /// using [deserializer] to create canonicalized values.
  ObjectDecoder(Deserializer deserializer, Map map)
      : super(deserializer, map);

  @override
  _getKeyValue(Key key) => _deserializer.decoder.getObjectPropertyValue(key);
}

/// [MapDecoder] reads serialized values from a [Map] encoded from an
/// [MapValue] where entries are stored using [String] values as keys.
class MapDecoder extends AbstractDecoder<String> {
  /// Creates an [MapDecoder] that decodes [map] into deserialized values
  /// using [deserializer] to create canonicalized values.
  MapDecoder(Deserializer deserializer, Map<String, dynamic> map)
      : super(deserializer, map);

  @override
  _getKeyValue(String key) => key;

  /// Applies [f] to every key in the decoded [Map].
  void forEachKey(f(String key)) {
    _map.keys.forEach(f);
  }
}

/// [ListDecoder] reads serialized map or object values from a [List].
class ListDecoder {
  final Deserializer _deserializer;
  final List _list;

  /// Creates a [ListDecoder] that decodes [_list] using [_deserializer] to
  /// create canonicalized values.
  ListDecoder(this._deserializer, this._list);

  /// The number of values in the decoded list.
  int get length => _list.length;

  /// Returns an [ObjectDecoder] for the [index]th object value in the decoded
  /// list.
  ObjectDecoder getObject(int index) {
    return new ObjectDecoder(_deserializer, _list[index]);
  }

  /// Returns an [MapDecoder] for the [index]th map value in the decoded list.
  MapDecoder getMap(int index) {
    return new MapDecoder(_deserializer, _list[index]);
  }
}

/// Abstract base implementation for [ObjectDecoder] and [MapDecoder].
abstract class AbstractDecoder<K> {
  final Deserializer _deserializer;
  final Map<K, dynamic> _map;

  AbstractDecoder(this._deserializer, this._map) {
    assert(_deserializer != null);
    assert(_map != null);
  }

  /// Returns the value for [key] defined by the [SerializationDecoder] in used
  /// [_deserializer].
  _getKeyValue(K key);

  /// Returns `true` if [key] has an associated value in the decoded object.
  bool containsKey(K key) => _map.containsKey(_getKeyValue(key));

  /// Returns the enum value from the [enumValues] associated with [key] in the
  /// decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// [defaultValue] is returned, otherwise an exception is thrown.
  getEnum(K key, List enumValues, {bool isOptional: false, defaultValue}) {
    int value = _map[_getKeyValue(key)];
    if (value == null) {
      if (isOptional || defaultValue != null) {
        return defaultValue;
      }
      throw new StateError("enum value '$key' not found in $_map.");
    }
    return enumValues[value];
  }

  /// Returns the [Element] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// `null` is returned, otherwise an exception is thrown.
  Element getElement(K key, {bool isOptional: false}) {
    int id = _map[_getKeyValue(key)];
    if (id == null) {
      if (isOptional) {
        return null;
      }
      throw new StateError("Element value '$key' not found in $_map.");
    }
    return _deserializer.deserializeElement(id);
  }

  /// Returns the list of [Element] values associated with [key] in the decoded
  /// object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// and empty [List] is returned, otherwise an exception is thrown.
  List<Element> getElements(K key, {bool isOptional: false}) {
    List list = _map[_getKeyValue(key)];
    if (list == null) {
      if (isOptional) {
        return const [];
      }
      throw new StateError("Elements value '$key' not found in $_map.");
    }
    return list.map(_deserializer.deserializeElement).toList();
  }

  /// Returns the [ConstantExpression] value associated with [key] in the
  /// decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// `null` is returned, otherwise an exception is thrown.
  ConstantExpression getConstant(K key, {bool isOptional: false}) {
    int id = _map[_getKeyValue(key)];
    if (id == null) {
      if (isOptional) {
        return null;
      }
      throw new StateError("Constant value '$key' not found in $_map.");
    }
    return _deserializer.deserializeConstant(id);
  }

  /// Returns the list of [ConstantExpression] values associated with [key] in
  /// the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// and empty [List] is returned, otherwise an exception is thrown.
  List<ConstantExpression> getConstants(K key, {bool isOptional: false}) {
    List list = _map[_getKeyValue(key)];
    if (list == null) {
      if (isOptional) {
        return const [];
      }
      throw new StateError("Constants value '$key' not found in $_map.");
    }
    return list.map(_deserializer.deserializeConstant).toList();
  }

  /// Returns the [DartType] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// `null` is returned, otherwise an exception is thrown.
  DartType getType(K key, {bool isOptional: false}) {
    int id = _map[_getKeyValue(key)];
    if (id == null) {
      if (isOptional) {
        return null;
      }
      throw new StateError("Type value '$key' not found in $_map.");
    }
    return _deserializer.deserializeType(id);
  }

  /// Returns the list of [DartType] values associated with [key] in the decoded
  /// object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// and empty [List] is returned, otherwise an exception is thrown.
  List<DartType> getTypes(K key, {bool isOptional: false}) {
    List list = _map[_getKeyValue(key)];
    if (list == null) {
      if (isOptional) {
        return const [];
      }
      throw new StateError("Types value '$key' not found in $_map.");
    }
    return list.map(_deserializer.deserializeType).toList();
  }

  /// Returns the [Uri] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// [defaultValue] is returned, otherwise an exception is thrown.
  Uri getUri(K key, {bool isOptional: false, Uri defaultValue}) {
    String value = _map[_getKeyValue(key)];
    if (value == null) {
      if (isOptional || defaultValue != null) {
        return defaultValue;
      }
      throw new StateError("Uri value '$key' not found in $_map.");
    }
    return Uri.parse(value);
  }

  /// Returns the [String] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// [defaultValue] is returned, otherwise an exception is thrown.
  String getString(K key, {bool isOptional: false, String defaultValue}) {
    String value = _map[_getKeyValue(key)];
    if (value == null) {
      if (isOptional || defaultValue != null) {
        return defaultValue;
      }
      throw new StateError("String value '$key' not found in $_map.");
    }
    return value;
  }

  /// Returns the list of [String] values associated with [key] in the decoded
  /// object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// and empty [List] is returned, otherwise an exception is thrown.
  List<String> getStrings(K key, {bool isOptional: false}) {
    List list = _map[_getKeyValue(key)];
    if (list == null) {
      if (isOptional) {
        return const [];
      }
      throw new StateError("Strings value '$key' not found in $_map.");
    }
    return list;
  }

  /// Returns the [bool] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// [defaultValue] is returned, otherwise an exception is thrown.
  bool getBool(K key, {bool isOptional: false, bool defaultValue}) {
    bool value = _map[_getKeyValue(key)];
    if (value == null) {
      if (isOptional || defaultValue != null) {
        return defaultValue;
      }
      throw new StateError("bool value '$key' not found in $_map.");
    }
    return value;
  }

  /// Returns the [int] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// [defaultValue] is returned, otherwise an exception is thrown.
  int getInt(K key, {bool isOptional: false, int defaultValue}) {
    int value = _map[_getKeyValue(key)];
    if (value == null) {
      if (isOptional || defaultValue != null) {
        return defaultValue;
      }
      throw new StateError("int value '$key' not found in $_map.");
    }
    return value;
  }

  /// Returns the list of [int] values associated with [key] in the decoded
  /// object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// and empty [List] is returned, otherwise an exception is thrown.
  List<int> getInts(K key, {bool isOptional: false}) {
    List list = _map[_getKeyValue(key)];
    if (list == null) {
      if (isOptional) {
        return const [];
      }
      throw new StateError("Ints value '$key' not found in $_map.");
    }
    return list;
  }

  /// Returns the [double] value associated with [key] in the decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// [defaultValue] is returned, otherwise an exception is thrown.
  double getDouble(K key, {bool isOptional: false, double defaultValue}) {
    double value = _map[_getKeyValue(key)];
    if (value == null) {
      if (isOptional || defaultValue != null) {
        return defaultValue;
      }
      throw new StateError("double value '$key' not found in $_map.");
    }
    return value;
  }

  /// Returns an [ObjectDecoder] for the map value associated with [key] in the
  /// decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// `null` is returned, otherwise an exception is thrown.
  ObjectDecoder getObject(K key, {bool isOptional: false}) {
    Map map = _map[_getKeyValue(key)];
    if (map == null) {
      if (isOptional) {
        return null;
      }
      throw new StateError("Object value '$key' not found in $_map.");
    }
    return new ObjectDecoder(_deserializer, map);
  }

  /// Returns an [MapDecoder] for the map value associated with [key] in the
  /// decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// `null` is returned, otherwise an exception is thrown.
  MapDecoder getMap(K key, {bool isOptional: false}) {
    Map map = _map[_getKeyValue(key)];
    if (map == null) {
      if (isOptional) {
        return null;
      }
      throw new StateError("Map value '$key' not found in $_map.");
    }
    return new MapDecoder(_deserializer, map);
  }

  /// Returns an [ListDecoder] for the list value associated with [key] in the
  /// decoded object.
  ///
  /// If no value is associated with [key], then if [isOptional] is `true`,
  /// `null` is returned, otherwise an exception is thrown.
  ListDecoder getList(K key, {bool isOptional: false}) {
    List list = _map[_getKeyValue(key)];
    if (list == null) {
      if (isOptional) {
        return null;
      }
      throw new StateError("List value '$key' not found in $_map.");
    }
    return new ListDecoder(_deserializer, list);
  }
}

/// A nominal object containing its serialized value.
class DataObject {
  /// The id for the object.
  final Value id;

  /// The serialized value of the object.
  final ObjectValue objectValue;

  DataObject(Value id, EnumValue kind)
      : this.id = id,
        this.objectValue =
            new ObjectValue(<Key, Value>{Key.ID: id, Key.KIND: kind});

  Map<Key, Value> get map => objectValue.map;
}

/// Serializer for the transitive closure of a collection of libraries.
///
/// The serializer creates an [ObjectValue] model of the [Element], [DartType]
/// and [ConstantExpression] values in the transitive closure of the serialized
/// libraries.
///
/// The model layout of the produced [objectValue] is:
///
///     { // Header object
///       Key.ELEMENTS: [
///         {...}, // [ObjectValue] of the 0th [Element].
///         ...
///         {...}, // [ObjectValue] of the n-th [Element].
///       ],
///       Key.TYPES: [
///         {...}, // [ObjectValue] of the 0th [DartType].
///         ...
///         {...}, // [ObjectValue] of the n-th [DartType].
///       ],
///       Key.CONSTANTS: [
///         {...}, // [ObjectValue] of the 0th [ConstantExpression].
///         ...
///         {...}, // [ObjectValue] of the n-th [ConstantExpression].
///       ],
///     }
///
// TODO(johnniwinther): Support per-library serialization and dependencies
// between serialized subcomponent.
class Serializer {
  final SerializationEncoder _encoder;

  Map<Element, DataObject> _elementMap = <Element, DataObject>{};
  Map<ConstantExpression, DataObject> _constantMap =
      <ConstantExpression, DataObject>{};
  Map<DartType, DataObject> _typeMap = <DartType, DataObject>{};
  List _pendingList = [];

  Serializer(this._encoder);

  /// Add the transitive closure of [library] to this serializer.
  void serialize(LibraryElement library) {
    // Call [_getElementDataObject] for its side-effect: To create a
    // [DataObject] for [library]. If not already created, this will
    // put the serialization of [library] in the work queue.
    _getElementDataObject(library);
    _emptyWorklist();
  }

  void _emptyWorklist() {
    while (_pendingList.isNotEmpty) {
      _pendingList.removeLast()();
    }
  }

  /// Returns the [DataObject] for [element].
  ///
  /// If [constant] has no [DataObject], a new [DataObject] is created and
  /// encoding the [ObjectValue] for [constant] is put into the work queue of
  /// this serializer.
  DataObject _getElementDataObject(Element element) {
    if (element == null) {
      throw new ArgumentError('Serializer._getElementDataObject(null)');
    }
    return _elementMap.putIfAbsent(element, () {
      // Run through [ELEMENT_SERIALIZERS] sequentially to find the one that
      // deals with [element].
      for (ElementSerializer serializer in ELEMENT_SERIALIZERS) {
        SerializedElementKind kind = serializer.getSerializedKind(element);
        if (kind != null) {
          DataObject dataObject = new DataObject(
              new IntValue(_elementMap.length), new EnumValue(kind));
          // Delay the serialization of the element itself to avoid loops, and
          // to keep the call stack small.
          _pendingList.add(() {
            serializer.serialize(
                element, new ObjectEncoder(this, dataObject.map), kind);
          });
          return dataObject;
        }
      }
      throw new UnsupportedError(
          'Unsupported element: $element (${element.kind})');
    });
  }

  /// Creates the [ElementValue] for [element].
  ///
  /// If [element] has not already been serialized, it is added to the work
  /// queue of this serializer.
  ElementValue createElementValue(Element element) {
    return new ElementValue(element, _getElementDataObject(element).id);
  }

  /// Returns the [DataObject] for [constant].
  ///
  /// If [constant] has no [DataObject], a new [DataObject] is created and
  /// encoding the [ObjectValue] for [constant] is put into the work queue of
  /// this serializer.
  DataObject _getConstantDataObject(ConstantExpression constant) {
    return _constantMap.putIfAbsent(constant, () {
      DataObject dataObject = new DataObject(
          new IntValue(_constantMap.length), new EnumValue(constant.kind));
      // Delay the serialization of the constant itself to avoid loops, and to
      // keep the call stack small.
      _pendingList.add(() => _encodeConstant(constant, dataObject));
      return dataObject;
    });
  }

  /// Encodes [constant] into the [ObjectValue] of [dataObject].
  void _encodeConstant(ConstantExpression constant, DataObject dataObject) {
    const ConstantSerializer().visit(constant,
        new ObjectEncoder(this, dataObject.map));
  }

  /// Creates the [ConstantValue] for [constant].
  ///
  /// If [constant] has not already been serialized, it is added to the work
  /// queue of this serializer.
  ConstantValue createConstantValue(ConstantExpression constant) {
    return new ConstantValue(constant, _getConstantDataObject(constant).id);
  }

  /// Returns the [DataObject] for [type].
  ///
  /// If [type] has no [DataObject], a new [DataObject] is created and
  /// encoding the [ObjectValue] for [type] is put into the work queue of this
  /// serializer.
  DataObject _getTypeDataObject(DartType type) {
    return _typeMap.putIfAbsent(type, () {
      DataObject dataObject = new DataObject(
          new IntValue(_typeMap.length), new EnumValue(type.kind));
      // Delay the serialization of the type itself to avoid loops, and to keep
      // the call stack small.
      _pendingList.add(() => _encodeType(type, dataObject));
      return dataObject;
    });
  }

  /// Encodes [type] into the [ObjectValue] of [dataObject].
  void _encodeType(DartType type, DataObject dataObject) {
    const TypeSerializer().visit(type, new ObjectEncoder(this, dataObject.map));
  }

  /// Creates the [TypeValue] for [type].
  ///
  /// If [type] has not already been serialized, it is added to the work
  /// queue of this serializer.
  TypeValue createTypeValue(DartType type) {
    return new TypeValue(type, _getTypeDataObject(type).id);
  }

  ObjectValue get objectValue {
    Map<Key, Value> map = <Key, Value>{};
    map[Key.ELEMENTS] =
        new ListValue(_elementMap.values.map((l) => l.objectValue).toList());
    if (_typeMap.isNotEmpty) {
      map[Key.TYPES] =
          new ListValue(_typeMap.values.map((l) => l.objectValue).toList());
    }
    if (_constantMap.isNotEmpty) {
      map[Key.CONSTANTS] =
          new ListValue(_constantMap.values.map((l) => l.objectValue).toList());
    }
    return new ObjectValue(map);
  }

  String toText() {
    return _encoder.encode(objectValue);
  }

  String prettyPrint() {
    PrettyPrintEncoder encoder = new PrettyPrintEncoder();
    return encoder.toText(objectValue);
  }
}

/// Deserializer for a closed collection of libraries.
// TODO(johnniwinther): Support per-library deserialization and dependencies
// between deserialized subcomponent.
class Deserializer {
  final SerializationDecoder decoder;
  ObjectDecoder _headerObject;
  ListDecoder _elementList;
  ListDecoder _typeList;
  ListDecoder _constantList;
  Map<int, Element> _elementMap = {};
  Map<int, DartType> _typeMap = {};
  Map<int, ConstantExpression> _constantMap = {};

  Deserializer.fromText(String text, this.decoder) {
    _headerObject = new ObjectDecoder(this, decoder.decode(text));
  }

  /// Returns the [ListDecoder] for the [Element]s in this deserializer.
  ListDecoder get elements {
    if (_elementList == null) {
      _elementList = _headerObject.getList(Key.ELEMENTS);
    }
    return _elementList;
  }

  /// Returns the [ListDecoder] for the [DartType]s in this deserializer.
  ListDecoder get types {
    if (_typeList == null) {
      _typeList = _headerObject.getList(Key.TYPES);
    }
    return _typeList;
  }

  /// Returns the [ListDecoder] for the [ConstantExpression]s in this
  /// deserializer.
  ListDecoder get constants {
    if (_constantList == null) {
      _constantList = _headerObject.getList(Key.CONSTANTS);
    }
    return _constantList;
  }

  /// Returns the [LibraryElement] for [uri] if part of the deserializer.
  LibraryElement lookupLibrary(Uri uri) {
    // TODO(johnniwinther): Libraries should be stored explicitly in the header.
    ListDecoder list = elements;
    for (int i = 0; i < list.length; i++) {
      ObjectDecoder object = list.getObject(i);
      SerializedElementKind kind =
          object.getEnum(Key.KIND, SerializedElementKind.values);
      if (kind == SerializedElementKind.LIBRARY) {
        Uri libraryUri = object.getUri(Key.CANONICAL_URI);
        if (libraryUri == uri) {
          return deserializeElement(object.getInt(Key.ID));
        }
      }
    }
    return null;
  }

  /// Returns the deserialized [Element] for [id].
  Element deserializeElement(int id) {
    if (id == null) throw new ArgumentError('Deserializer.getElement(null)');
    return _elementMap.putIfAbsent(id, () {
      return ElementDeserializer.deserialize(elements.getObject(id));
    });
  }

  /// Returns the deserialized [DartType] for [id].
  DartType deserializeType(int id) {
    if (id == null) throw new ArgumentError('Deserializer.getType(null)');
    return _typeMap.putIfAbsent(id, () {
      return TypeDeserializer.deserialize(types.getObject(id));
    });
  }

  /// Returns the deserialized [ConstantExpression] for [id].
  ConstantExpression deserializeConstant(int id) {
    if (id == null) throw new ArgumentError('Deserializer.getConstant(null)');
    return _constantMap.putIfAbsent(id, () {
      return ConstantDeserializer.deserialize(constants.getObject(id));
    });
  }
}

/// Strategy used by [Serializer] to define the memory and output encoding.
abstract class SerializationEncoder {
  /// Encode [objectValue] into text.
  String encode(ObjectValue objectValue);
}

/// Strategy used by [Deserializer] for decoding and reading data from a
/// serialized output.
abstract class SerializationDecoder {
  /// Decode [text] into [Map] containing the data corresponding to an encoding
  /// of the serializer header object.
  Map decode(String text);

  /// Returns the value used to store [key] as a property in the encoding an
  /// [ObjectValue].
  ///
  /// Different encodings have different restrictions and capabilities as how
  /// to store a [Key] value. For instance: A JSON encoding needs to convert
  /// [Key] to a [String] to store it in a JSON object; a Dart encoding can
  /// choose to store a [Key] as an [int] or as the [Key] itself.
  getObjectPropertyValue(Key key);
}
