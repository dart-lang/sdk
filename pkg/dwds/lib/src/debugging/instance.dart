// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/debugging/metadata/class.dart';
import 'package:dwds/src/debugging/metadata/function.dart';
import 'package:dwds/src/utilities/conversions.dart';
import 'package:dwds/src/utilities/objects.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Contains a set of methods for getting [Instance]s and [InstanceRef]s.
class ChromeAppInstanceHelper {
  final _logger = Logger('InstanceHelper');
  final ChromeClassMetaDataHelper metadataHelper;
  final ChromeAppInspector inspector;

  ChromeAppInstanceHelper(this.inspector)
    : metadataHelper = ChromeClassMetaDataHelper(inspector);

  static final InstanceRef kNullInstanceRef = _primitiveInstanceRef(
    InstanceKind.kNull,
    null,
  );

  /// Creates an [InstanceRef] for a primitive [RemoteObject].
  static InstanceRef _primitiveInstanceRef(
    String kind,
    RemoteObject? remoteObject,
  ) {
    final classRef = classRefFor('dart:core', kind);
    return InstanceRef(
      identityHashCode: dartIdFor(remoteObject?.value).hashCode,
      kind: kind,
      classRef: classRef,
      id: dartIdFor(remoteObject?.value),
      valueAsString: '${remoteObject?.value}',
    );
  }

  /// Creates an [Instance] for a primitive [RemoteObject].
  Instance? _primitiveInstance(String kind, RemoteObject? remoteObject) {
    final objectId = remoteObject?.objectId;
    if (objectId == null) return null;
    return Instance(
      identityHashCode: objectId.hashCode,
      id: objectId,
      kind: kind,
      classRef: classRefFor('dart:core', kind),
      valueAsString: '${remoteObject?.value}',
    );
  }

  Instance? _stringInstanceFor(
    RemoteObject? remoteObject,
    int? offset,
    int? count,
  ) {
    // TODO(#777) Consider a way of not passing the whole string around (in the
    // ID) in order to find a substring.
    final objectId = remoteObject?.objectId;
    if (objectId == null) return null;
    final fullString = stringFromDartId(objectId);
    var preview = fullString;
    var truncated = false;
    if (offset != null || count != null) {
      truncated = true;
      final start = offset ?? 0;
      final end = count == null ? null : min(start + count, fullString.length);
      preview = fullString.substring(start, end);
    }
    return Instance(
      identityHashCode: createId().hashCode,
      kind: InstanceKind.kString,
      classRef: classRefForString,
      id: createId(),
      valueAsString: preview,
      valueAsStringIsTruncated: truncated,
      length: fullString.length,
      count: (truncated ? preview.length : null),
      offset: (truncated ? offset : null),
    );
  }

  Instance? _closureInstanceFor(RemoteObject remoteObject) {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;
    final result = Instance(
      kind: InstanceKind.kClosure,
      id: objectId,
      identityHashCode: remoteObject.objectId.hashCode,
      classRef: classRefForClosure,
    );
    return result;
  }

  /// Create an [Instance] for the given [remoteObject].
  ///
  /// Does a remote eval to get instance information. Returns null if there
  /// isn't a corresponding instance. For enumerable objects, [offset] and
  /// [count] allow retrieving a sub-range of properties.
  Future<Instance?> instanceFor(
    RemoteObject? remoteObject, {
    int? offset,
    int? count,
  }) async {
    final primitive = _primitiveInstanceOrNull(remoteObject, offset, count);
    if (primitive != null) {
      return primitive;
    }
    final objectId = remoteObject?.objectId;
    if (remoteObject == null || objectId == null) return null;

    final metaData = await metadataHelper.metaDataFor(remoteObject);

    final classRef = metaData?.classRef;
    if (metaData == null || classRef == null) return null;

    switch (metaData.runtimeKind) {
      case RuntimeObjectKind.function:
        return _closureInstanceFor(remoteObject);
      case RuntimeObjectKind.recordType:
        return await _recordTypeInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
      case RuntimeObjectKind.type:
        return await _plainTypeInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
      case RuntimeObjectKind.list:
        return await _listInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
      case RuntimeObjectKind.set:
        return await _setInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
      case RuntimeObjectKind.map:
        return await _mapInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
      case RuntimeObjectKind.record:
        return await _recordInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
      case RuntimeObjectKind.object:
      case RuntimeObjectKind.nativeError:
      case RuntimeObjectKind.nativeObject:
        return await _plainInstanceFor(
          metaData,
          remoteObject,
          offset: offset,
          count: count,
        );
    }
  }

  /// If [remoteObject] represents a primitive, return an [Instance] for it,
  /// otherwise return null.
  Instance? _primitiveInstanceOrNull(
    RemoteObject? remoteObject,
    int? offset,
    int? count,
  ) {
    switch (remoteObject?.type ?? 'undefined') {
      case 'string':
        return _stringInstanceFor(remoteObject, offset, count);
      case 'number':
        return _primitiveInstance(InstanceKind.kDouble, remoteObject);
      case 'boolean':
        return _primitiveInstance(InstanceKind.kBool, remoteObject);
      case 'undefined':
        return _primitiveInstance(InstanceKind.kNull, remoteObject);
      default:
        return null;
    }
  }

  /// Create a bound field for [property] in an instance of [classRef].
  Future<BoundField> _fieldFor(Property property, ClassRef classRef) async {
    final instance = await _instanceRefForRemote(property.value);
    // TODO(annagrin): convert JS name to dart and fill missing information.
    //https://github.com/dart-lang/sdk/issues/46723
    return BoundField(
      name: property.name,
      decl: FieldRef(
        // TODO(grouma) - Convert JS name to Dart.
        name: property.name,
        declaredType: InstanceRef(
          kind: InstanceKind.kType,
          classRef: instance?.classRef,
          identityHashCode: createId().hashCode,
          id: createId(),
        ),
        owner: classRef,
        isConst: false,
        isFinal: false,
        isStatic: false,
        id: createId(),
      ),
      value: instance,
    );
  }

  /// Create a plain instance of `classRef` from [remoteObject] and the JS
  /// properties `properties`.
  Future<Instance?> _plainInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;

    final fields = await _getInstanceFields(
      metaData,
      remoteObject,
      offset: offset,
      count: count,
    );

    final result = Instance(
      kind: InstanceKind.kPlainInstance,
      id: objectId,
      identityHashCode: remoteObject.objectId.hashCode,
      classRef: metaData.classRef,
      fields: fields,
    );
    return result;
  }

  Future<List<BoundField>> _getInstanceFields(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) throw StateError('Object id is null for instance');

    final properties = await inspector.getProperties(
      objectId,
      offset: offset,
      count: count,
      length: metaData.kind != InstanceKind.kPlainInstance
          ? metaData.length
          : null,
    );

    final dartProperties = await _dartFieldsFor(properties, remoteObject);
    final boundFields = await Future.wait(
      dartProperties.map<Future<BoundField>>(
        (p) => _fieldFor(p, metaData.classRef),
      ),
    );

    return boundFields
        .where((bv) => inspector.isDisplayableObject(bv.value))
        .toList()
      ..sort(_compareBoundFields);
  }

  int _compareBoundFields(BoundField a, BoundField b) {
    final aName = a.decl?.name;
    final bName = b.decl?.name;
    if (aName == null) return bName == null ? 0 : -1;
    if (bName == null) return 1;
    return aName.compareTo(bName);
  }

  /// The associations for a Dart Map or IdentityMap.
  ///
  /// Returns a range of [count] associations, if available, starting from
  /// the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  Future<List<MapAssociation>> _mapAssociations(
    RemoteObject map, {
    int? offset,
    int? count,
  }) async {
    // We do this in in awkward way because we want the keys and values, but we
    // can't return things by value or some Dart objects will come back as
    // values that we need to be RemoteObject, e.g. a List of int.
    final expression = globalToolConfiguration.loadStrategy.dartRuntimeDebugger
        .getMapElementsJsExpression();

    final keysAndValues = await inspector.jsCallFunctionOn(map, expression, []);
    final keys = await inspector.loadField(keysAndValues, 'keys');
    final values = await inspector.loadField(keysAndValues, 'values');
    final keysInstance = await instanceFor(keys, offset: offset, count: count);
    final valuesInstance = await instanceFor(
      values,
      offset: offset,
      count: count,
    );
    final associations = <MapAssociation>[];
    final keyElements = keysInstance?.elements;
    final valueElements = valuesInstance?.elements;
    if (keyElements != null && valueElements != null) {
      Map.fromIterables(keyElements, valueElements).forEach((key, value) {
        associations.add(MapAssociation(key: key, value: value));
      });
    }
    return associations;
  }

  /// Create a Map instance with class `classRef` from [remoteObject].
  ///
  /// Returns an instance containing [count] associations, if available,
  /// starting from the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  /// `length` is the expected length of the whole object, read from
  /// the [ClassMetaData].
  Future<Instance?> _mapInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;

    // Maps are complicated, do an eval to get keys and values.
    final associations = await _mapAssociations(
      remoteObject,
      offset: offset,
      count: count,
    );
    final rangeCount = _calculateRangeCount(
      count: count,
      elementCount: associations.length,
      length: metaData.length,
    );
    return Instance(
      identityHashCode: remoteObject.objectId.hashCode,
      kind: InstanceKind.kMap,
      id: objectId,
      classRef: metaData.classRef,
      length: metaData.length,
      offset: offset,
      count: rangeCount,
      associations: associations,
    );
  }

  /// Create a List instance of `classRef` from [remoteObject].
  ///
  /// Returns an instance containing [count] elements, if available,
  /// starting from the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  /// `length` is the expected length of the whole object, read from
  /// the [ClassMetaData].
  Future<Instance?> _listInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;

    final elements = await _listElements(
      remoteObject,
      offset: offset,
      count: count,
      length: metaData.length,
    );
    final rangeCount = _calculateRangeCount(
      count: count,
      elementCount: elements.length,
      length: metaData.length,
    );
    return Instance(
      identityHashCode: remoteObject.objectId.hashCode,
      kind: InstanceKind.kList,
      id: objectId,
      classRef: metaData.classRef,
      length: metaData.length,
      elements: elements,
      offset: offset,
      count: rangeCount,
    );
  }

  /// The elements for a Dart List.
  ///
  /// Returns a range of [count] elements, if available, starting from
  /// the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  /// [length] is the expected length of the whole object, read from
  /// the [ClassMetaData].
  Future<List<InstanceRef?>> _listElements(
    RemoteObject list, {
    int? offset,
    int? count,
    int? length,
  }) async {
    final properties = await inspector.getProperties(
      list.objectId!,
      offset: offset,
      count: count,
      length: length,
    );

    // Filter out all non-indexed properties
    final elements = _indexedListProperties(properties);

    final rangeCount = _calculateRangeCount(
      count: count,
      elementCount: elements.length,
      length: length,
    );
    final range = elements.sublist(0, rangeCount);

    return Future.wait(
      range.map((element) => _instanceRefForRemote(element.value)),
    );
  }

  /// Return elements of the list from [properties].
  ///
  /// Ignore any non-elements like 'length', 'fixed$length', etc.
  static List<Property> _indexedListProperties(List<Property> properties) =>
      properties
          .where((p) => p.name != null && int.tryParse(p.name!) != null)
          .toList();

  /// The field names for a Dart record shape.
  ///
  /// Returns a range of [count] fields, if available, starting from
  /// the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  /// The [shape] object describes the shape using `positionalCount`
  /// and `named` fields.
  ///
  /// Returns list of field names for the record shape.
  Future<List<dynamic>> _recordShapeFields(
    RemoteObject shape, {
    int? offset,
    int? count,
  }) async {
    final positionalCountObject = await inspector.loadField(
      shape,
      'positionalCount',
    );
    if (positionalCountObject.value is! int) {
      _logger.warning(
        'Unexpected positional count from record: $positionalCountObject',
      );
      return [];
    }

    final namedObject = await inspector.loadField(shape, 'named');
    final positionalCount = positionalCountObject.value as int;
    final positionalOffset = offset ?? 0;
    final positionalAvailable = _remainingCount(
      positionalOffset,
      positionalCount,
    );
    final positionalRangeCount = min(
      positionalAvailable,
      count ?? positionalAvailable,
    );
    final positionalElements = [
      for (
        var i = positionalOffset + 1;
        i <= positionalOffset + positionalRangeCount;
        i++
      )
        i,
    ];

    // Collect named fields in the requested range.
    // Account for already collected positional fields.
    final namedRangeOffset = offset == null
        ? null
        : _remainingCount(positionalCount, offset);
    final namedRangeCount = count == null
        ? null
        : _remainingCount(positionalRangeCount, count);
    final namedInstance = await instanceFor(
      namedObject,
      offset: namedRangeOffset,
      count: namedRangeCount,
    );
    final namedElements =
        (namedInstance?.elements as List<InstanceRef?>?)?.map(
          (e) => e?.valueAsString,
        ) ??
        [];

    return [...positionalElements, ...namedElements];
  }

  /// The fields for a Dart Record.
  ///
  /// Returns a range of [count] fields, if available, starting from
  /// the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  Future<List<BoundField>> _recordFields(
    RemoteObject record, {
    int? offset,
    int? count,
  }) async {
    // We do this in in awkward way because we want the keys and values, but we
    // can't return things by value or some Dart objects will come back as
    // values that we need to be RemoteObject, e.g. a List of int.
    final expression = globalToolConfiguration.loadStrategy.dartRuntimeDebugger
        .getRecordFieldsJsExpression();

    final result = await inspector.jsCallFunctionOn(record, expression, []);
    final fieldNameElements = await _recordShapeFields(
      result,
      offset: offset,
      count: count,
    );

    final valuesObject = await inspector.loadField(result, 'values');
    final valuesInstance = await instanceFor(
      valuesObject,
      offset: offset,
      count: count,
    );
    final valueElements = valuesInstance?.elements ?? [];

    return _elementsToBoundFields(fieldNameElements, valueElements);
  }

  /// Create a list of `BoundField`s from field [names] and [values].
  List<BoundField> _elementsToBoundFields(
    List<dynamic> names,
    List<dynamic> values,
  ) {
    if (names.length != values.length) {
      _logger.warning('Bound field names and values are not the same length.');
      return [];
    }

    final boundFields = <BoundField>[];
    Map.fromIterables(names, values).forEach((name, value) {
      boundFields.add(BoundField(name: name, value: value));
    });
    return boundFields;
  }

  static int _remainingCount(int collected, int requested) {
    return requested < collected ? 0 : requested - collected;
  }

  /// Create a Record instance with class `classRef` from [remoteObject].
  ///
  /// Returns an instance containing [count] fields, if available,
  /// starting from the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  /// `length` is the expected length of the whole object, read from
  /// the [ClassMetaData].
  Future<Instance?> _recordInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;
    // Records are complicated, do an eval to get names and values.
    final fields = await _recordFields(
      remoteObject,
      offset: offset,
      count: count,
    );
    final rangeCount = _calculateRangeCount(
      count: count,
      elementCount: fields.length,
      length: metaData.length,
    );
    return Instance(
      identityHashCode: remoteObject.objectId.hashCode,
      kind: InstanceKind.kRecord,
      id: objectId,
      classRef: metaData.classRef,
      length: metaData.length,
      offset: offset,
      count: rangeCount,
      fields: fields,
    );
  }

  /// Create a RecordType instance with class `classRef` from [remoteObject].
  ///
  /// Returns an instance containing [count] fields, if available,
  /// starting from the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all fields starting from the offset.
  /// `length` is the expected length of the whole object, read from
  /// the [ClassMetaData].
  Future<Instance?> _recordTypeInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;

    // Records are complicated, do an eval to get names and values.
    final fields = await _recordTypeFields(
      remoteObject,
      offset: offset,
      count: count,
    );
    final rangeCount = _calculateRangeCount(
      count: count,
      elementCount: fields.length,
      length: metaData.length,
    );
    return Instance(
      identityHashCode: remoteObject.objectId.hashCode,
      kind: InstanceKind.kRecordType,
      id: objectId,
      classRef: metaData.classRef,
      length: metaData.length,
      offset: offset,
      count: rangeCount,
      fields: fields,
    );
  }

  /// The field types for a Dart RecordType.
  ///
  /// Returns a range of [count] field types, if available, starting from
  /// the [offset].
  ///
  /// If [offset] is `null`, assumes 0 offset.
  /// If [count] is `null`, return all field types starting from the offset.
  Future<List<BoundField>> _recordTypeFields(
    RemoteObject record, {
    int? offset,
    int? count,
  }) async {
    // We do this in in awkward way because we want the names and types, but we
    // can't return things by value or some Dart objects will come back as
    // values that we need to be RemoteObject, e.g. a List of int.
    final expression = globalToolConfiguration.loadStrategy.dartRuntimeDebugger
        .getRecordTypeFieldsJsExpression();

    final result = await inspector.jsCallFunctionOn(record, expression, []);
    final fieldNameElements = await _recordShapeFields(
      result,
      offset: offset,
      count: count,
    );

    final typesObject = await inspector.loadField(result, 'types');
    final typesInstance = await instanceFor(
      typesObject,
      offset: offset,
      count: count,
    );
    final typeElements = typesInstance?.elements ?? [];

    return _elementsToBoundFields(fieldNameElements, typeElements);
  }

  Future<Instance?> _setInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final length = metaData.length;
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;
    final expression = globalToolConfiguration.loadStrategy.dartRuntimeDebugger
        .getSetElementsJsExpression();

    final result = await inspector.jsCallFunctionOn(
      remoteObject,
      expression,
      [],
    );
    final entriesObject = await inspector.loadField(result, 'entries');
    final entriesInstance = await instanceFor(
      entriesObject,
      offset: offset,
      count: count,
    );
    final elements = entriesInstance?.elements ?? [];

    final setInstance = Instance(
      identityHashCode: remoteObject.objectId.hashCode,
      kind: InstanceKind.kSet,
      id: objectId,
      classRef: metaData.classRef,
      length: length,
      elements: elements,
    );

    if (offset != null && offset > 0) {
      setInstance.offset = offset;
    }
    if (length != null && elements.length < length) {
      setInstance.count = elements.length;
    }

    return setInstance;
  }

  /// Create Type instance with class `classRef` from [remoteObject].
  ///
  /// Collect information from the internal [remoteObject] and present
  /// it as an instance of [Type] class.
  ///
  /// Returns an instance containing `hashCode` and `runtimeType` fields.
  /// `length` is the expected length of the whole object, read from
  /// the [ClassMetaData].
  Future<Instance?> _plainTypeInstanceFor(
    ClassMetaData metaData,
    RemoteObject remoteObject, {
    int? offset,
    int? count,
  }) async {
    final objectId = remoteObject.objectId;
    if (objectId == null) return null;

    final fields = await _getInstanceFields(
      metaData,
      remoteObject,
      offset: offset,
      count: count,
    );

    return Instance(
      identityHashCode: objectId.hashCode,
      kind: InstanceKind.kType,
      id: objectId,
      classRef: metaData.classRef,
      name: metaData.typeName,
      length: metaData.length,
      offset: offset,
      count: count,
      fields: fields,
    );
  }

  /// Return the available count of elements in the requested range.
  /// Return `null` if the range includes the whole object.
  /// [count] is the range length requested by the `getObject` call.
  /// [elementCount] is the number of elements in the runtime object.
  /// [length] is the expected length of the whole object, read from
  /// the [ClassMetaData].
  static int? _calculateRangeCount({
    int? count,
    int? elementCount,
    int? length,
  }) {
    if (count == null) return null;
    if (elementCount == null) return null;
    if (length == elementCount) return null;
    return min(count, elementCount);
  }

  /// Filter [allJsProperties] and return a list containing only those
  /// that correspond to Dart fields on [remoteObject].
  ///
  /// This only applies to objects with named fields, not Lists or Maps.
  Future<List<Property>> _dartFieldsFor(
    List<Property> allJsProperties,
    RemoteObject remoteObject,
  ) async {
    // An expression to find the field names from the types, extract both
    // private (named by symbols) and public (named by strings) and return them
    // as a comma-separated single string, so we can return it by value and not
    // need to make multiple round trips.
    //
    // For maps and lists it's more complicated. Treat the actual SDK versions
    // of these as special.
    final fieldNameExpression = globalToolConfiguration
        .loadStrategy
        .dartRuntimeDebugger
        .getObjectFieldNamesJsExpression();
    final result = await inspector.jsCallFunctionOn(
      remoteObject,
      fieldNameExpression,
      [],
      returnByValue: true,
    );
    final names = List<String>.from(result.value as List);
    // TODO(#761): Better support for large collections.
    return allJsProperties
        .where((property) => names.contains(property.name))
        .toList();
  }

  /// Create an InstanceRef for an object, which may be a RemoteObject, or may
  /// be something returned by value from Chrome, e.g. number, boolean, or
  /// String.
  Future<InstanceRef?> instanceRefFor(Object value) {
    final remote = value is RemoteObject
        ? value
        : RemoteObject({'value': value, 'type': _chromeType(value)});
    return _instanceRefForRemote(remote);
  }

  /// The Chrome type for a value.
  String? _chromeType(Object? value) {
    if (value == null) return null;
    if (value is String) return 'string';
    if (value is num) return 'number';
    if (value is bool) return 'boolean';
    if (value is Function) return 'function';
    return 'object';
  }

  /// Create an [InstanceRef] for the given Chrome [remoteObject].
  Future<InstanceRef?> _instanceRefForRemote(RemoteObject? remoteObject) async {
    // If we have a null result, treat it as a reference to null.
    if (remoteObject == null) {
      return kNullInstanceRef;
    }

    switch (remoteObject.type) {
      case 'string':
        final stringValue = remoteObject.value as String?;
        // TODO: Support truncation for long strings.
        // TODO(#777): dartIdFor() will return an ID containing the entire
        // string, even if we're truncating the string value here.
        return InstanceRef(
          identityHashCode: dartIdFor(remoteObject.value).hashCode,
          id: dartIdFor(remoteObject.value),
          classRef: classRefForString,
          kind: InstanceKind.kString,
          valueAsString: stringValue,
          length: stringValue?.length,
        );
      case 'number':
        return _primitiveInstanceRef(InstanceKind.kDouble, remoteObject);
      case 'boolean':
        return _primitiveInstanceRef(InstanceKind.kBool, remoteObject);
      case 'undefined':
        return _primitiveInstanceRef(InstanceKind.kNull, remoteObject);
      case 'object':
        final objectId = remoteObject.objectId;
        if (objectId == null) {
          return _primitiveInstanceRef(InstanceKind.kNull, remoteObject);
        }
        final metaData = await metadataHelper.metaDataFor(remoteObject);
        if (metaData == null) return null;

        return InstanceRef(
          kind: metaData.kind,
          id: objectId,
          identityHashCode: objectId.hashCode,
          classRef: metaData.classRef,
          length: metaData.length,
          name: metaData.typeName,
        );
      case 'function':
        final objectId = remoteObject.objectId;
        if (objectId == null) {
          return _primitiveInstanceRef(InstanceKind.kNull, remoteObject);
        }
        final functionMetaData = await FunctionMetaData.metaDataFor(
          inspector.remoteDebugger,
          remoteObject,
        );
        // TODO(annagrin) - fill missing information.
        // https://github.com/dart-lang/sdk/issues/46723
        return InstanceRef(
          kind: InstanceKind.kClosure,
          id: objectId,
          identityHashCode: objectId.hashCode,
          classRef: classRefForClosure,
          closureFunction: FuncRef(
            name: functionMetaData.name,
            id: createId(),
            owner: classRefForUnknown,
            isConst: false,
            isStatic: false,
            implicit: false,
            isGetter: false,
            isSetter: false,
          ),
          closureContext: ContextRef(length: 0, id: createId()),
        );
      default:
        // Return null for an unsupported type. This is likely a JS construct.
        return null;
    }
  }
}
