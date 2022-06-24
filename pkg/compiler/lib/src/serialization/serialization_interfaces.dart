// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir show DartType, Member, TreeNode;

import '../constants/values.dart' show ConstantValue;
import '../elements/entities.dart';
import '../elements/types.dart' show DartType;
import '../inferrer/abstract_value_domain.dart' show AbstractValue;

import 'deferrable.dart';
export 'tags.dart';

abstract class StringInterner {
  String internString(String string);
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

  void writeDartTypeNode(ir.DartType value);
  void writeDartTypeNodeOrNull(ir.DartType? value);

  void writeDartType(DartType value);
  void writeDartTypeOrNull(DartType? value);
  void writeDartTypesOrNull(Iterable<DartType>? values);
  void writeDartTypes(Iterable<DartType> values);

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

  void writeImport(ImportEntity import);
  void writeImportOrNull(ImportEntity? import);
  void writeImports(Iterable<ImportEntity>? values, {bool allowNull = false});
  void writeImportMap<V>(Map<ImportEntity, V>? map, void f(V value),
      {bool allowNull = false});

  void writeAbstractValue(AbstractValue value);

  void writeDeferrable(void f());
}

/// Migrated interface for methods of DataSourceReader.
abstract class DataSourceReader {
  int get length;
  int get startOffset;
  int get endOffset;

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

  ir.DartType readDartTypeNode();
  ir.DartType? readDartTypeNodeOrNull();

  DartType readDartType();
  DartType? readDartTypeOrNull();
  List<DartType> readDartTypes();
  List<DartType>? readDartTypesOrNull();

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

  ImportEntity readImport();
  ImportEntity? readImportOrNull();
  List<ImportEntity> readImports();
  List<ImportEntity>? readImportsOrNull();
  Map<ImportEntity, V> readImportMap<V>(V f());
  Map<ImportEntity, V>? readImportMapOrNull<V>(V f());

  AbstractValue readAbstractValue();

  E readWithSource<E>(DataSourceReader source, E f());
  E readWithOffset<E>(int offset, E f());
  Deferrable<E> readDeferrable<E>(E f(), {bool cacheData = true});
}
