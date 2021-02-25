// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_to_binary.dart';
import '../closure.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../deferred_load.dart';
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

part 'abstract_sink.dart';
part 'abstract_source.dart';
part 'binary_sink.dart';
part 'binary_source.dart';
part 'helpers.dart';
part 'member_data.dart';
part 'mixins.dart';
part 'node_indexer.dart';
part 'object_sink.dart';
part 'object_source.dart';

/// Interface for serialization.
abstract class DataSink {
  /// The amount of data written to this data sink.
  ///
  /// The units is based on the underlying data structure for this data sink.
  int get length;

  /// Flushes any pending data and closes this data sink.
  ///
  /// The data sink can no longer be written to after closing.
  void close();

  /// Registers that the section [tag] starts.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  void begin(String tag);

  /// Registers that the section [tag] ends.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  void end(String tag);

  /// Writes a reference to [value] to this data sink. If [value] has not yet
  /// been serialized, [f] is called to serialize the value itself.
  void writeCached<E>(E value, void f(E value));

  /// Writes the potentially `null` [value] to this data sink. If [value] is
  /// non-null [f] is called to write the non-null value to the data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readValueOrNull].
  void writeValueOrNull<E>(E value, void f(E value));

  /// Writes the [values] to this data sink calling [f] to write each value to
  /// the data sink. If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readList].
  void writeList<E>(Iterable<E> values, void f(E value),
      {bool allowNull: false});

  /// Writes the boolean [value] to this data sink.
  void writeBool(bool value);

  /// Writes the non-negative 30 bit integer [value] to this data sink.
  void writeInt(int value);

  /// Writes the potentially `null` non-negative [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readIntOrNull].
  void writeIntOrNull(int value);

  /// Writes the string [value] to this data sink.
  void writeString(String value);

  /// Writes the potentially `null` string [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readStringOrNull].
  void writeStringOrNull(String value);

  /// Writes the string [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readStrings].
  void writeStrings(Iterable<String> values, {bool allowNull: false});

  /// Writes the [map] from string to [V] values to this data sink, calling [f]
  /// to write each value to the data sink. If [allowNull] is `true`, [map] is
  /// allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readStringMap].
  void writeStringMap<V>(Map<String, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes the enum value [value] to this data sink.
  // TODO(johnniwinther): Change the signature to
  // `void writeEnum<E extends Enum<E>>(E value);` when an interface for enums
  // is added to the language.
  void writeEnum(dynamic value);

  /// Writes the URI [value] to this data sink.
  void writeUri(Uri value);

  /// Writes a reference to the kernel library node [value] to this data sink.
  void writeLibraryNode(ir.Library value);

  /// Writes a reference to the kernel class node [value] to this data sink.
  void writeClassNode(ir.Class value);

  /// Writes a reference to the kernel typedef node [value] to this data sink.
  void writeTypedefNode(ir.Typedef value);

  /// Writes a reference to the kernel member node [value] to this data sink.
  void writeMemberNode(ir.Member value);

  /// Writes references to the kernel member node [values] to this data sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readMemberNodes].
  void writeMemberNodes(Iterable<ir.Member> values, {bool allowNull: false});

  /// Writes the [map] from references to kernel member nodes to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readMemberNodeMap].
  void writeMemberNodeMap<V>(Map<ir.Member, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes a kernel name node to this data sink.
  void writeName(ir.Name value);

  /// Writes a kernel library dependency node [value] to this data sink.
  void writeLibraryDependencyNode(ir.LibraryDependency value);

  /// Writes a potentially `null` kernel library dependency node [value] to
  /// this data sink.
  void writeLibraryDependencyNodeOrNull(ir.LibraryDependency value);

  /// Writes a reference to the kernel tree node [value] to this data sink.
  void writeTreeNode(ir.TreeNode value);

  /// Writes a reference to the potentially `null` kernel tree node [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTreeNodeOrNull].
  void writeTreeNodeOrNull(ir.TreeNode value);

  /// Writes references to the kernel tree node [values] to this data sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTreeNodes].
  void writeTreeNodes(Iterable<ir.TreeNode> values, {bool allowNull: false});

  /// Writes the [map] from references to kernel tree nodes to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTreeNodeMap].
  void writeTreeNodeMap<V>(Map<ir.TreeNode, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes a reference to the kernel tree node [value] in the known [context]
  /// to this data sink.
  void writeTreeNodeInContext(ir.TreeNode value);

  /// Writes a reference to the potentially `null` kernel tree node [value] in
  /// the known [context] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTreeNodeOrNullInContext].
  void writeTreeNodeOrNullInContext(ir.TreeNode value);

  /// Writes references to the kernel tree node [values] in the known [context]
  /// to this data sink. If [allowNull] is `true`, [values] is allowed to be
  /// `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTreeNodesInContext].
  void writeTreeNodesInContext(Iterable<ir.TreeNode> values,
      {bool allowNull: false});

  /// Writes the [map] from references to kernel tree nodes to [V] values in the
  /// known [context] to this data sink, calling [f] to write each value to the
  /// data sink. If [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTreeNodeMapInContext].
  void writeTreeNodeMapInContext<V>(Map<ir.TreeNode, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes a reference to the kernel type parameter node [value] to this data
  /// sink.
  void writeTypeParameterNode(ir.TypeParameter value);

  /// Writes references to the kernel type parameter node [values] to this data
  /// sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readTypeParameterNodes].
  void writeTypeParameterNodes(Iterable<ir.TypeParameter> values,
      {bool allowNull: false});

  /// Writes the type [value] to this data sink. If [allowNull] is `true`,
  /// [value] is allowed to be `null`.
  void writeDartType(DartType value, {bool allowNull: false});

  /// Writes the type [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readDartTypes].
  void writeDartTypes(Iterable<DartType> values, {bool allowNull: false});

  /// Writes the kernel type node [value] to this data sink. If [allowNull] is
  /// `true`, [value] is allowed to be `null`.
  void writeDartTypeNode(ir.DartType value, {bool allowNull: false});

  /// Writes the kernel type node [values] to this data sink. If [allowNull] is
  /// `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readDartTypeNodes].
  void writeDartTypeNodes(Iterable<ir.DartType> values,
      {bool allowNull: false});

  /// Writes the source span [value] to this data sink.
  void writeSourceSpan(SourceSpan value);

  /// Writes a reference to the indexed library [value] to this data sink.
  void writeLibrary(IndexedLibrary value);

  /// Writes a reference to the potentially `null` indexed library [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readLibraryOrNull].
  void writeLibraryOrNull(IndexedLibrary value);

  /// Writes the [map] from references to indexed libraries to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readLibraryMap].
  void writeLibraryMap<V>(Map<LibraryEntity, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes a reference to the indexed class [value] to this data sink.
  void writeClass(IndexedClass value);

  /// Writes a reference to the potentially `null` indexed class [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readClassOrNull].
  void writeClassOrNull(IndexedClass value);

  /// Writes references to the indexed class [values] to this data sink. If
  /// [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readClasses].
  void writeClasses(Iterable<ClassEntity> values, {bool allowNull: false});

  /// Writes the [map] from references to indexed classes to [V] values to this
  /// data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readClassMap].
  void writeClassMap<V>(Map<ClassEntity, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes a reference to the indexed member [value] to this data sink.
  void writeMember(IndexedMember value);

  /// Writes a reference to the potentially `null` indexed member [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readMemberOrNull].
  void writeMemberOrNull(IndexedMember value);

  /// Writes references to the indexed member [values] to this data sink. If
  /// [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readMembers].
  void writeMembers(Iterable<MemberEntity> values, {bool allowNull: false});

  /// Writes the [map] from references to indexed members to [V] values to this
  /// data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readMemberMap].
  void writeMemberMap<V>(
      Map<MemberEntity, V> map, void f(MemberEntity member, V value),
      {bool allowNull: false});

  /// Writes a reference to the indexed type variable [value] to this data sink.
  void writeTypeVariable(IndexedTypeVariable value);

  /// Writes a reference to the local [value] to this data sink.
  void writeLocal(Local local);

  /// Writes a reference to the potentially `null` local [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readLocalOrNull].
  void writeLocalOrNull(Local local);

  /// Writes references to the local [values] to this data sink. If [allowNull]
  /// is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readLocals].
  void writeLocals(Iterable<Local> values, {bool allowNull: false});

  /// Writes the [map] from references to locals to [V] values to this data
  /// sink, calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readLocalMap].
  void writeLocalMap<V>(Map<Local, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes the constant [value] to this data sink.
  void writeConstant(ConstantValue value);

  /// Writes the potentially `null` constant [value] to this data sink.
  void writeConstantOrNull(ConstantValue value);

  /// Writes constant [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readConstants].
  void writeConstants(Iterable<ConstantValue> values, {bool allowNull: false});

  /// Writes the [map] from constant values to [V] values to this data sink,
  /// calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readConstantMap].
  void writeConstantMap<V>(Map<ConstantValue, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes a double value to this data sink.
  void writeDoubleValue(double value);

  /// Writes an integer of arbitrary value to this data sink.
  ///
  /// This is should only when the value is not known to be a non-negative
  /// 30 bit integer. Otherwise [writeInt] should be used.
  void writeIntegerValue(int value);

  /// Writes the import [value] to this data sink.
  void writeImport(ImportEntity value);

  /// Writes the potentially `null` import [value] to this data sink.
  void writeImportOrNull(ImportEntity value);

  /// Writes import [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readImports].
  void writeImports(Iterable<ImportEntity> values, {bool allowNull: false});

  /// Writes the [map] from imports to [V] values to this data sink,
  /// calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSource.readImportMap].
  void writeImportMap<V>(Map<ImportEntity, V> map, void f(V value),
      {bool allowNull: false});

  /// Writes an abstract [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeAbstractValue(AbstractValue value);

  /// Writes a reference to the output unit [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeOutputUnitReference(OutputUnit value);

  /// Writes a js node [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeJsNode(js.Node value);

  /// Writes a potentially `null` js node [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeJsNodeOrNull(js.Node value);

  /// Writes TypeRecipe [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeTypeRecipe(TypeRecipe value);

  /// Register an [EntityWriter] with this data sink for non-default encoding
  /// of entity references.
  void registerEntityWriter(EntityWriter writer);

  /// Register a [CodegenWriter] with this data sink to support serialization
  /// of codegen only data.
  void registerCodegenWriter(CodegenWriter writer);

  /// Invoke [f] in the context of [member]. This sets up support for
  /// serialization of `ir.TreeNode`s using the `writeTreeNode*InContext`
  /// methods.
  void inMemberContext(ir.Member member, void f());
}

/// Interface for deserialization.
abstract class DataSource {
  /// Registers that the section [tag] starts.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  void begin(String tag);

  /// Registers that the section [tag] ends.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  void end(String tag);

  /// Registers a [ComponentLookup] object with this data source to support
  /// deserialization of references to kernel nodes.
  void registerComponentLookup(ComponentLookup componentLookup);

  /// Registers an [EntityLookup] object with this data source to support
  /// deserialization of references to indexed entities.
  void registerEntityLookup(EntityLookup entityLookup);

  /// Registers an [EntityReader] with this data source for non-default encoding
  /// of entity references.
  void registerEntityReader(EntityReader reader);

  /// Registers a [LocalLookup] object with this data source to support
  /// deserialization of references to locals.
  void registerLocalLookup(LocalLookup localLookup);

  /// Registers a [CodegenReader] with this data source to support
  /// deserialization of codegen only data.
  void registerCodegenReader(CodegenReader reader);

  /// Unregisters the [CodegenReader] from this data source to remove support
  /// for deserialization of codegen only data.
  void deregisterCodegenReader(CodegenReader reader);

  /// Invoke [f] in the context of [member]. This sets up support for
  /// deserialization of `ir.TreeNode`s using the `readTreeNode*InContext`
  /// methods.
  T inMemberContext<T>(ir.Member member, T f());

  /// Reads a reference to an [E] value from this data source. If the value has
  /// not yet been deserialized, [f] is called to deserialize the value itself.
  E readCached<E>(E f());

  /// Reads a potentially `null` [E] value from this data source, calling [f] to
  /// read the non-null value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeValueOrNull].
  E readValueOrNull<E>(E f());

  /// Reads a list of [E] values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeList].
  List<E> readList<E>(E f(), {bool emptyAsNull: false});

  /// Reads a boolean value from this data source.
  bool readBool();

  /// Reads a non-negative 30 bit integer value from this data source.
  int readInt();

  /// Reads a potentially `null` non-negative integer value from this data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeIntOrNull].
  int readIntOrNull();

  /// Reads a string value from this data source.
  String readString();

  /// Reads a potentially `null` string value from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeStringOrNull].
  String readStringOrNull();

  /// Reads a list of string values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeStrings].
  List<String> readStrings({bool emptyAsNull: false});

  /// Reads a map from string values to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeStringMap].
  Map<String, V> readStringMap<V>(V f(), {bool emptyAsNull: false});

  /// Reads an enum value from the list of enum [values] from this data source.
  ///
  /// The [values] argument is intended to be the static `.values` field on
  /// enum classes, for instance:
  ///
  ///    enum Foo { bar, baz }
  ///    ...
  ///    Foo foo = source.readEnum(Foo.values);
  ///
  E readEnum<E>(List<E> values);

  /// Reads a URI value from this data source.
  Uri readUri();

  /// Reads a reference to a kernel library node from this data source.
  ir.Library readLibraryNode();

  /// Reads a reference to a kernel class node from this data source.
  ir.Class readClassNode();

  /// Reads a reference to a kernel class node from this data source.
  ir.Typedef readTypedefNode();

  /// Reads a reference to a kernel member node from this data source.
  ir.Member readMemberNode();

  /// Reads a list of references to kernel member nodes from this data source.
  /// If [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeMemberNodes].
  List<ir.Member> readMemberNodes<E extends ir.Member>(
      {bool emptyAsNull: false});

  /// Reads a map from kernel member nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeMemberNodeMap].
  Map<K, V> readMemberNodeMap<K extends ir.Member, V>(V f(),
      {bool emptyAsNull: false});

  /// Reads a kernel name node from this data source.
  ir.Name readName();

  /// Reads a kernel library dependency node from this data source.
  ir.LibraryDependency readLibraryDependencyNode();

  /// Reads a potentially `null` kernel library dependency node from this data
  /// source.
  ir.LibraryDependency readLibraryDependencyNodeOrNull();

  /// Reads a reference to a kernel tree node from this data source.
  ir.TreeNode readTreeNode();

  /// Reads a reference to a potentially `null` kernel tree node from this data
  /// source.
  ir.TreeNode readTreeNodeOrNull();

  /// Reads a list of references to kernel tree nodes from this data source.
  /// If [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeTreeNodes].
  List<E> readTreeNodes<E extends ir.TreeNode>({bool emptyAsNull: false});

  /// Reads a map from kernel tree nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeTreeNodeMap].
  Map<K, V> readTreeNodeMap<K extends ir.TreeNode, V>(V f(),
      {bool emptyAsNull: false});

  /// Reads a reference to a kernel tree node in the known [context] from this
  /// data source.
  ir.TreeNode readTreeNodeInContext();

  /// Reads a reference to a potentially `null` kernel tree node in the known
  /// [context] from this data source.
  ir.TreeNode readTreeNodeOrNullInContext();

  /// Reads a list of references to kernel tree nodes in the known [context]
  /// from this data source. If [emptyAsNull] is `true`, `null` is returned
  /// instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeTreeNodesInContext].
  List<E> readTreeNodesInContext<E extends ir.TreeNode>(
      {bool emptyAsNull: false});

  /// Reads a map from kernel tree nodes to [V] values in the known [context]
  /// from this data source, calling [f] to read each value from the data
  /// source. If [emptyAsNull] is `true`, `null` is returned instead of an empty
  /// map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeTreeNodeMapInContext].
  Map<K, V> readTreeNodeMapInContext<K extends ir.TreeNode, V>(V f(),
      {bool emptyAsNull: false});

  /// Reads a reference to a kernel type parameter node from this data source.
  ir.TypeParameter readTypeParameterNode();

  /// Reads a list of references to kernel type parameter nodes from this data
  /// source. If [emptyAsNull] is `true`, `null` is returned instead of an empty
  /// list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeTypeParameterNodes].
  List<ir.TypeParameter> readTypeParameterNodes({bool emptyAsNull: false});

  /// Reads a type from this data source. If [allowNull], the returned type is
  /// allowed to be `null`.
  DartType readDartType({bool allowNull: false});

  /// Reads a list of types from this data source. If [emptyAsNull] is `true`,
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeDartTypes].
  List<DartType> readDartTypes({bool emptyAsNull: false});

  /// Reads a kernel type node from this data source. If [allowNull], the
  /// returned type is allowed to be `null`.
  ir.DartType readDartTypeNode({bool allowNull: false});

  /// Reads a list of kernel type nodes from this data source. If [emptyAsNull]
  /// is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeDartTypeNodes].
  List<ir.DartType> readDartTypeNodes({bool emptyAsNull: false});

  /// Reads a source span from this data source.
  SourceSpan readSourceSpan();

  /// Reads a reference to an indexed library from this data source.
  IndexedLibrary readLibrary();

  /// Reads a reference to a potentially `null` indexed library from this data
  /// source.
  IndexedLibrary readLibraryOrNull();
  Map<K, V> readLibraryMap<K extends LibraryEntity, V>(V f(),
      {bool emptyAsNull: false});

  /// Reads a reference to an indexed class from this data source.
  IndexedClass readClass();

  /// Reads a reference to a potentially `null` indexed class from this data
  /// source.
  IndexedClass readClassOrNull();

  /// Reads a list of references to indexed classes from this data source.
  /// If [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeClasses].
  List<E> readClasses<E extends ClassEntity>({bool emptyAsNull: false});

  /// Reads a map from indexed classes to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeClassMap].
  Map<K, V> readClassMap<K extends ClassEntity, V>(V f(),
      {bool emptyAsNull: false});

  /// Reads a reference to an indexed member from this data source.
  IndexedMember readMember();

  /// Reads a reference to a potentially `null` indexed member from this data
  /// source.
  IndexedMember readMemberOrNull();

  /// Reads a list of references to indexed members from this data source.
  /// If [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeMembers].
  List<E> readMembers<E extends MemberEntity>({bool emptyAsNull: false});

  /// Reads a map from indexed members to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeMemberMap].
  Map<K, V> readMemberMap<K extends MemberEntity, V>(V f(MemberEntity member),
      {bool emptyAsNull: false});

  /// Reads a reference to an indexed type variable from this data source.
  IndexedTypeVariable readTypeVariable();

  /// Reads a reference to a local from this data source.
  Local readLocal();

  /// Reads a reference to a potentially `null` local from this data source.
  Local readLocalOrNull();

  /// Reads a list of references to locals from this data source. If
  /// [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeLocals].
  List<E> readLocals<E extends Local>({bool emptyAsNull: false});

  /// Reads a map from locals to [V] values from this data source, calling [f]
  /// to read each value from the data source. If [emptyAsNull] is `true`,
  /// `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeLocalMap].
  Map<K, V> readLocalMap<K extends Local, V>(V f(), {bool emptyAsNull: false});

  /// Reads a constant value from this data source.
  ConstantValue readConstant();

  /// Reads a potentially `null` constant value from this data source.
  ConstantValue readConstantOrNull();

  /// Reads a double value from this data source.
  double readDoubleValue();

  /// Reads an integer of arbitrary value from this data source.
  ///
  /// This is should only when the value is not known to be a non-negative
  /// 30 bit integer. Otherwise [readInt] should be used.
  int readIntegerValue();

  /// Reads a list of constant values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeConstants].
  List<E> readConstants<E extends ConstantValue>({bool emptyAsNull: false});

  /// Reads a map from constant values to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeConstantMap].
  Map<K, V> readConstantMap<K extends ConstantValue, V>(V f(),
      {bool emptyAsNull: false});

  /// Reads a import from this data source.
  ImportEntity readImport();

  /// Reads a potentially `null` import from this data source.
  ImportEntity readImportOrNull();

  /// Reads a list of imports from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeImports].
  List<ImportEntity> readImports({bool emptyAsNull: false});

  /// Reads a map from imports to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSink.writeImportMap].
  Map<ImportEntity, V> readImportMap<V>(V f(), {bool emptyAsNull: false});

  /// Reads an [AbstractValue] from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  AbstractValue readAbstractValue();

  /// Reads a reference to an [OutputUnit] from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  OutputUnit readOutputUnitReference();

  /// Reads a [js.Node] value from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  js.Node readJsNode();

  /// Reads a potentially `null` [js.Node] value from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  js.Node readJsNodeOrNull();

  /// Reads a [TypeRecipe] value from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  TypeRecipe readTypeRecipe();
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
      DataSource source, EntityLookup entityLookup) {
    return entityLookup.getLibraryByIndex(source.readInt());
  }

  IndexedClass readClassFromDataSource(
      DataSource source, EntityLookup entityLookup) {
    return entityLookup.getClassByIndex(source.readInt());
  }

  IndexedMember readMemberFromDataSource(
      DataSource source, EntityLookup entityLookup) {
    return entityLookup.getMemberByIndex(source.readInt());
  }

  IndexedTypeVariable readTypeVariableFromDataSource(
      DataSource source, EntityLookup entityLookup) {
    return entityLookup.getTypeVariableByIndex(source.readInt());
  }
}

/// Encoding strategy for entity references.
class EntityWriter {
  const EntityWriter();

  void writeLibraryToDataSink(DataSink sink, IndexedLibrary value) {
    sink.writeInt(value.libraryIndex);
  }

  void writeClassToDataSink(DataSink sink, IndexedClass value) {
    sink.writeInt(value.classIndex);
  }

  void writeMemberToDataSink(DataSink sink, IndexedMember value) {
    sink.writeInt(value.memberIndex);
  }

  void writeTypeVariableToDataSink(DataSink sink, IndexedTypeVariable value) {
    sink.writeInt(value.typeVariableIndex);
  }
}

/// Interface used for looking up locals by index during deserialization.
abstract class LocalLookup {
  Local getLocalByIndex(MemberEntity memberContext, int index);
}

/// Interface used for reading codegen only data during deserialization.
abstract class CodegenReader {
  AbstractValue readAbstractValue(DataSource source);
  OutputUnit readOutputUnitReference(DataSource source);
  js.Node readJsNode(DataSource source);
  TypeRecipe readTypeRecipe(DataSource source);
}

/// Interface used for writing codegen only data during serialization.
abstract class CodegenWriter {
  void writeAbstractValue(DataSink sink, AbstractValue value);
  void writeOutputUnitReference(DataSink sink, OutputUnit value);
  void writeJsNode(DataSink sink, js.Node node);
  void writeTypeRecipe(DataSink sink, TypeRecipe recipe);
}
