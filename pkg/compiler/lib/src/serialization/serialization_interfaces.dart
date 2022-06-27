// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:kernel/ast.dart' as ir
    show
        Class,
        DartType,
        Library,
        LibraryDependency,
        Member,
        Name,
        TreeNode,
        TypeParameter;

import '../common.dart';
import '../constants/values.dart' show ConstantValue;
import '../deferred_load/output_unit.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/types.dart' show DartType;
import '../inferrer/abstract_value_domain.dart' show AbstractValue;
import '../js/js.dart' as js;
import '../js_model/type_recipe.dart';
import 'deferrable.dart';
import 'indexed_sink_source.dart';
import 'member_data.dart' show ComponentLookup;

export 'binary_sink.dart';
export 'binary_source.dart';
export 'member_data.dart' show ComponentLookup;
export 'object_sink.dart';
export 'object_source.dart';
export 'tags.dart';

abstract class StringInterner {
  String internString(String string);
}

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

/// NNBD-migrated interface for methods of DataSinkWriter.
///
/// This is a pure interface or facade for DataSinkWriter.
///
/// This interface has the same name as the implementation class. Using the same
/// name allows some libraries that use DataSinkWriter to be migrated before the
/// serialization library by changing
///
///     import '../serialization/serialization.dart';
///
/// to:
///
///     import '../serialization/serialization_interfaces.dart';
///
/// Documentation of the methods can be found in source.dart.
// TODO(sra): Copy documentation for methods?
abstract class DataSinkWriter {
  int get length;

  void begin(String tag);
  void end(Object tag);

  void writeBool(bool value);
  void writeInt(int value);
  void writeIntOrNull(int? value);
  void writeString(String value);
  void writeStringOrNull(String? value);
  void writeStringMap<V>(Map<String, V>? map, void f(V value),
      {bool allowNull = false});
  void writeStrings(Iterable<String>? values, {bool allowNull = false});
  void writeEnum(dynamic value);
  void writeUri(Uri value);

  void writeMemberNode(ir.Member nvalue);
  void writeMemberNodes(Iterable<ir.Member>? values, {bool allowNull = false});
  void writeMemberNodeMap<V>(Map<ir.Member, V>? map, void f(V value),
      {bool allowNull = false});

  void writeName(ir.Name value);
  void writeLibraryDependencyNode(ir.LibraryDependency value);
  void writeLibraryDependencyNodeOrNull(ir.LibraryDependency? value);

  void writeTreeNode(ir.TreeNode value);
  void writeTreeNodeOrNull(ir.TreeNode value);
  void writeTreeNodes(Iterable<ir.TreeNode>? values, {bool allowNull = false});
  void writeTreeNodeMap<V>(Map<ir.TreeNode, V> map, void f(V value));

  void writeClassNode(ir.Class value);

  // TODO(48820): 'covariant ClassEntity' is used below because the
  // implementation takes IndexedClass. What this means is that in pre-NNBD
  // code, the call site to the implementation DataSinkWriter has an implicit
  // downcast from ClassEntity to IndexedClass. With NNND, these casts become
  // explicit and quite tedious. It is cleaner to move the cast into the method,
  // which is what 'covariant' achieves.
  //
  // If we want to retire this facade interface, we will have to make the
  // DataSinkWriter implementation accept ClassEntity and manually check for
  // IndexedClass. This is not necessarily a bad thing, since it opens the way
  // for being able to serialize some non-indexed entities.

  void writeClass(covariant ClassEntity value); // IndexedClass
  void writeClassOrNull(covariant ClassEntity? value); // IndexedClass
  void writeClasses(Iterable<ClassEntity>? values, {bool allowNull = false});
  void writeClassMap<V>(Map<ClassEntity, V>? map, void f(V value),
      {bool allowNull = false});

  void writeTypeVariable(
      covariant TypeVariableEntity value); // IndexedTypeVariable

  void writeMember(covariant MemberEntity member); // IndexMember
  void writeMemberOrNull(covariant MemberEntity? member); // IndexMember
  void writeMembers(Iterable<MemberEntity>? values, {bool allowNull = false});

  void writeMemberMap<V>(
      Map<MemberEntity, V>? map, void f(MemberEntity member, V value),
      {bool allowNull = false});

  void writeLibrary(covariant LibraryEntity value); // IndexedLibrary
  void writeLibraryOrNull(covariant LibraryEntity? value); // IndexedLibrary
  void writeLibraryMap<V>(Map<LibraryEntity, V>? map, void f(V value),
      {bool allowNull = false});

  void writeLibraryNode(ir.Library value);

  void writeTypeRecipe(TypeRecipe value);

  void writeDartTypeNode(ir.DartType value);
  void writeDartTypeNodeOrNull(ir.DartType? value);
  void writeDartTypeNodes(Iterable<ir.DartType>? values,
      {bool allowNull = false});

  void writeDartType(DartType value);
  void writeDartTypeOrNull(DartType? value);
  void writeDartTypesOrNull(Iterable<DartType>? values);
  void writeDartTypes(Iterable<DartType> values);

  void writeTypeParameterNode(ir.TypeParameter value);
  void writeTypeParameterNodes(Iterable<ir.TypeParameter> values);

  void writeTypeVariableMap<V>(
      Map<IndexedTypeVariable, V> map, void f(V value));

  void inMemberContext(ir.Member context, void f());
  void writeTreeNodeMapInContext<V>(Map<ir.TreeNode, V>? map, void f(V value),
      {bool allowNull = false});

  void writeCached<E extends Object>(E? value, void f(E value));

  void writeList<E extends Object>(Iterable<E>? values, void f(E value),
      {bool allowNull = false});

  void writeConstant(ConstantValue value);
  void writeConstantOrNull(ConstantValue? value);
  void writeConstantMap<V>(Map<ConstantValue, V>? map, void f(V value),
      {bool allowNull = false});

  void writeValueOrNull<E>(E? value, void f(E value));

  void writeDoubleValue(double value);
  void writeIntegerValue(int value);

  void writeLocalOrNull(Local? local);
  void writeLocalMap<V>(Map<Local, V> map, void f(V value));

  void writeImport(ImportEntity import);
  void writeImportOrNull(ImportEntity? import);
  void writeImports(Iterable<ImportEntity>? values, {bool allowNull = false});
  void writeImportMap<V>(Map<ImportEntity, V>? map, void f(V value),
      {bool allowNull = false});

  void writeAbstractValue(AbstractValue value);

  void writeJsNodeOrNull(js.Node? value);

  void writeSourceSpan(SourceSpan value);

  void writeDeferrable(void f());
}

/// Migrated interface for methods of DataSourceReader.
abstract class DataSourceReader {
  int get length;
  int get startOffset;
  int get endOffset;

  void registerComponentLookup(ComponentLookup componentLookup);
  void registerLocalLookup(LocalLookup localLookup);
  void registerEntityLookup(EntityLookup entityLookup);
  void registerEntityReader(EntityReader reader);

  void begin(String tag);
  void end(String tag);

  bool readBool();
  int readInt();
  int? readIntOrNull();
  String readString();
  String? readStringOrNull();
  List<String>? readStrings({bool emptyAsNull = false});
  Map<String, V>? readStringMap<V>(V f(), {bool emptyAsNull = false});
  E readEnum<E>(List<E> values);
  Uri readUri();

  ir.Member readMemberNode();
  List<E> readMemberNodes<E extends ir.Member>();
  List<E>? readMemberNodesOrNull<E extends ir.Member>();
  Map<K, V> readMemberNodeMap<K extends ir.Member, V>(V f());
  Map<K, V>? readMemberNodeMapOrNull<K extends ir.Member, V>(V f());

  ir.Name readName();
  ir.LibraryDependency readLibraryDependencyNode();
  ir.LibraryDependency readLibraryDependencyNodeOrNull();

  ir.TreeNode readTreeNode();
  ir.TreeNode? readTreeNodeOrNull();
  List<E> readTreeNodes<E extends ir.TreeNode>();
  List<E>? readTreeNodesOrNull<E extends ir.TreeNode>();
  Map<K, V> readTreeNodeMap<K extends ir.TreeNode, V>(V f());
  Map<K, V> readTreeNodeMapOrNull<K extends ir.TreeNode, V>(V f());

  ir.Class readClassNode();

  ClassEntity readClass(); // IndexedClass
  ClassEntity? readClassOrNull(); // IndexedClass
  List<E> readClasses<E extends ClassEntity>();
  List<E>? readClassesOrNull<E extends ClassEntity>();
  Map<K, V> readClassMap<K extends ClassEntity, V>(V f());
  Map<K, V>? readClassMapOrNull<K extends ClassEntity, V>(V f());

  TypeVariableEntity readTypeVariable(); // IndexedTypeVariable

  MemberEntity readMember();
  MemberEntity? readMemberOrNull();
  List<E> readMembers<E extends MemberEntity>();
  List<E>? readMembersOrNull<E extends MemberEntity>();
  Map<K, V> readMemberMap<K extends MemberEntity, V>(V f(MemberEntity member));
  Map<K, V>? readMemberMapOrNull<K extends MemberEntity, V>(
      V f(MemberEntity member));

  LibraryEntity readLibrary(); // IndexedLibrary;
  LibraryEntity? readLibraryOrNull(); // IndexedLibrary;
  Map<K, V> readLibraryMap<K extends LibraryEntity, V>(V f());
  Map<K, V>? readLibraryMapOrNull<K extends LibraryEntity, V>(V f());

  ir.Library readLibraryNode();

  TypeRecipe readTypeRecipe();

  ir.DartType readDartTypeNode();
  ir.DartType? readDartTypeNodeOrNull();
  List<ir.DartType> readDartTypeNodes();
  List<ir.DartType>? readDartTypeNodesOrNull();

  DartType readDartType();
  DartType? readDartTypeOrNull();
  List<DartType> readDartTypes();
  List<DartType>? readDartTypesOrNull();

  Map<K, V> readTypeVariableMap<K extends IndexedTypeVariable, V>(V f());

  ir.TypeParameter readTypeParameterNode();
  List<ir.TypeParameter> readTypeParameterNodes();

  T inMemberContext<T>(ir.Member context, T f());
  Map<K, V> readTreeNodeMapInContext<K extends ir.TreeNode, V>(V f());
  Map<K, V>? readTreeNodeMapInContextOrNull<K extends ir.TreeNode, V>(V f());

  E readCached<E extends Object>(E f());
  E? readCachedOrNull<E extends Object>(E f());

  List<E> readList<E extends Object>(E f());
  List<E>? readListOrNull<E extends Object>(E f());

  ConstantValue readConstant();
  ConstantValue? readConstantOrNull();
  Map<K, V> readConstantMap<K extends ConstantValue, V>(V f());
  Map<K, V>? readConstantMapOrNull<K extends ConstantValue, V>(V f());

  E? readValueOrNull<E>(E f());

  double readDoubleValue();
  int readIntegerValue();

  ImportEntity readImport();
  ImportEntity? readImportOrNull();
  List<ImportEntity> readImports();
  List<ImportEntity>? readImportsOrNull();
  Map<ImportEntity, V> readImportMap<V>(V f());
  Map<ImportEntity, V>? readImportMapOrNull<V>(V f());

  AbstractValue readAbstractValue();

  js.Node? readJsNodeOrNull();

  SourceSpan readSourceSpan();

  Local? readLocalOrNull();
  Map<K, V> readLocalMap<K extends Local, V>(V f());

  E readWithSource<E>(DataSourceReader source, E f());
  E readWithOffset<E>(int offset, E f());
  Deferrable<E> readDeferrable<E>(E f(), {bool cacheData = true});
}

/// Data class representing cache information for a given [T] which can be
/// passed from a [DataSourceReader] to other [DataSourceReader]s and [DataSinkWriter]s.
class DataSourceTypeIndices<E, T> {
  Map<E, int> get cache => _cache ??= source.reshapeCacheAsMap(_getValue);

  final E Function(T? value)? _getValue;
  Map<E, int>? _cache;
  final IndexedSource<T> source;

  /// Uses the cache from the provided [source] and reshapes it if necessary
  /// to create a lookup map of cached entities. If [_getValue] is provided,
  /// the function will be used to map the cached entities into lookup keys.
  DataSourceTypeIndices(this.source, [this._getValue]) {
    assert(_getValue != null || T == E);
  }
}

/// Data class representing the sum of all cache information for a given
/// [DataSourceReader].
class DataSourceIndices {
  final Map<Type, DataSourceTypeIndices> caches = {};
  final DataSourceReader? previousSourceReader;

  DataSourceIndices(this.previousSourceReader);
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
