// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'dart:collection';
import 'dart:typed_data';
import 'package:kernel/ast.dart' as ir;
import '../closure.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../diagnostics/source_span.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../ir/constants.dart';
import '../ir/static_type_base.dart';
import '../js/js.dart' as js;
import '../js_model/closure.dart';
import '../js_model/locals.dart';
import '../js_model/type_recipe.dart' show TypeRecipe;

import 'data_sink.dart';
import 'data_source.dart';
import 'member_data.dart';
import 'serialization_interfaces.dart' as migrated
    show DataSourceReader, DataSinkWriter;
import 'indexed_sink_source.dart';
import 'tags.dart';

export 'binary_sink.dart';
export 'binary_source.dart';
export 'member_data.dart' show ComponentLookup, computeMemberName;
export 'object_sink.dart';
export 'object_source.dart';
export 'tags.dart';

part 'sink.dart';
part 'source.dart';
part 'helpers.dart';

class ValueInterner {
  final Map<DartType, DartType> _dartTypeMap = HashMap();
  final Map<ir.DartType, ir.DartType> _dartTypeNodeMap = HashMap();

  DartType internDartType(DartType dartType) {
    return _dartTypeMap[dartType] ??= dartType;
  }

  ir.DartType internDartTypeNode(ir.DartType dartType) {
    return _dartTypeNodeMap[dartType] ??= dartType;
  }
}

/// Data class representing cache information for a given [T] which can be
/// passed from a [DataSourceReader] to other [DataSourceReader]s and [DataSinkWriter]s.
class DataSourceTypeIndices<E, T> {
  Map<E, int> get cache => _cache ??= source.reshape(_getValue);

  final E Function(T value) _getValue;
  Map<E, int> _cache;
  final IndexedSource<T> source;

  /// Though [DataSourceTypeIndices] supports two types of caches. If the
  /// exported indices are imported into a [DataSourceReader] then the [cacheAsMap]
  /// will be used as is. If, however, the exported indices are imported into a
  /// [DataSinkWriter] then we need to reshape the [List<T>] into a [Map<E, int>]
  /// where [E] is either [T] or some value which can be derived from [T] by
  /// [_getValue].
  DataSourceTypeIndices(this.source, [this._getValue]) {
    assert(_getValue != null || T == E);
  }
}

/// Data class representing the sum of all cache information for a given
/// [DataSourceReader].
class DataSourceIndices {
  final Map<Type, DataSourceTypeIndices> caches = {};
}

/// Interface used for looking up entities by index during deserialization.
abstract class EntityLookup {
  /// Returns the indexed library corresponding to [index].
  IndexedLibrary getLibraryByIndex(int index);

  /// Returns the indexed class corresponding to [index].
  IndexedClass getClassByIndex(int index);

  /// Returns the indexed member corresponding to [index].
  IndexedMember getMemberByIndex(int index);

  /// Returns the indexed type variable corresponding to [index].
  IndexedTypeVariable getTypeVariableByIndex(int index);
}

/// Decoding strategy for entity references.
class EntityReader {
  const EntityReader();

  IndexedLibrary readLibraryFromDataSource(
      DataSourceReader source, EntityLookup entityLookup) {
    return entityLookup.getLibraryByIndex(source.readInt());
  }

  IndexedClass readClassFromDataSource(
      DataSourceReader source, EntityLookup entityLookup) {
    return entityLookup.getClassByIndex(source.readInt());
  }

  IndexedMember readMemberFromDataSource(
      DataSourceReader source, EntityLookup entityLookup) {
    return entityLookup.getMemberByIndex(source.readInt());
  }

  IndexedTypeVariable readTypeVariableFromDataSource(
      DataSourceReader source, EntityLookup entityLookup) {
    return entityLookup.getTypeVariableByIndex(source.readInt());
  }
}

/// Encoding strategy for entity references.
class EntityWriter {
  const EntityWriter();

  void writeLibraryToDataSink(DataSinkWriter sink, IndexedLibrary value) {
    sink.writeInt(value.libraryIndex);
  }

  void writeClassToDataSink(DataSinkWriter sink, IndexedClass value) {
    sink.writeInt(value.classIndex);
  }

  void writeMemberToDataSink(DataSinkWriter sink, IndexedMember value) {
    sink.writeInt(value.memberIndex);
  }

  void writeTypeVariableToDataSink(
      DataSinkWriter sink, IndexedTypeVariable value) {
    sink.writeInt(value.typeVariableIndex);
  }
}

/// Interface used for looking up locals by index during deserialization.
abstract class LocalLookup {
  Local getLocalByIndex(MemberEntity memberContext, int index);
}

/// Interface used for reading codegen only data during deserialization.
abstract class CodegenReader {
  AbstractValue readAbstractValue(DataSourceReader source);
  OutputUnit readOutputUnitReference(DataSourceReader source);
  js.Node readJsNode(DataSourceReader source);
  TypeRecipe readTypeRecipe(DataSourceReader source);
}

/// Interface used for writing codegen only data during serialization.
abstract class CodegenWriter {
  void writeAbstractValue(DataSinkWriter sink, AbstractValue value);
  void writeOutputUnitReference(DataSinkWriter sink, OutputUnit value);
  void writeJsNode(DataSinkWriter sink, js.Node node);
  void writeTypeRecipe(DataSinkWriter sink, TypeRecipe recipe);
}
