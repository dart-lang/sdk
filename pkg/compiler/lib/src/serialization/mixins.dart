// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Mixin that implements all convenience methods of [DataSource].
abstract class DataSourceMixin implements DataSource {
  @override
  E readValueOrNull<E>(E f()) {
    bool hasValue = readBool();
    if (hasValue) {
      return f();
    }
    return null;
  }

  @override
  List<E> readList<E>(E f(), {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = f();
    }
    return list;
  }

  @override
  int readIntOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readInt();
    }
    return null;
  }

  @override
  String readStringOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readString();
    }
    return null;
  }

  @override
  List<String> readStrings({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<String> list = new List<String>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readString();
    }
    return list;
  }

  @override
  List<DartType> readDartTypes({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<DartType> list = new List<DartType>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readDartType();
    }
    return list;
  }

  @override
  List<ir.TypeParameter> readTypeParameterNodes({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<ir.TypeParameter> list =
        new List<ir.TypeParameter>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readTypeParameterNode();
    }
    return list;
  }

  @override
  List<E> readMembers<E extends MemberEntity>({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      MemberEntity member = readMember();
      list[i] = member;
    }
    return list;
  }

  @override
  List<E> readMemberNodes<E extends ir.Member>({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ir.Member value = readMemberNode();
      list[i] = value;
    }
    return list;
  }

  @override
  List<E> readClasses<E extends ClassEntity>({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ClassEntity cls = readClass();
      list[i] = cls;
    }
    return list;
  }

  @override
  Map<K, V> readLibraryMap<K extends LibraryEntity, V>(V f(),
      {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      LibraryEntity library = readLibrary();
      V value = f();
      map[library] = value;
    }
    return map;
  }

  @override
  Map<K, V> readClassMap<K extends ClassEntity, V>(V f(),
      {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ClassEntity cls = readClass();
      V value = f();
      map[cls] = value;
    }
    return map;
  }

  @override
  Map<K, V> readMemberMap<K extends MemberEntity, V>(V f(MemberEntity member),
      {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      MemberEntity member = readMember();
      V value = f(member);
      map[member] = value;
    }
    return map;
  }

  @override
  Map<K, V> readMemberNodeMap<K extends ir.Member, V>(V f(),
      {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ir.Member node = readMemberNode();
      V value = f();
      map[node] = value;
    }
    return map;
  }

  @override
  Map<K, V> readTreeNodeMap<K extends ir.TreeNode, V>(V f(),
      {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ir.TreeNode node = readTreeNode();
      V value = f();
      map[node] = value;
    }
    return map;
  }

  @override
  List<E> readLocals<E extends Local>({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      Local local = readLocal();
      list[i] = local;
    }
    return list;
  }

  @override
  Map<K, V> readLocalMap<K extends Local, V>(V f(), {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      Local local = readLocal();
      V value = f();
      map[local] = value;
    }
    return map;
  }

  @override
  List<E> readTreeNodes<E extends ir.TreeNode>({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ir.TreeNode node = readTreeNode();
      list[i] = node;
    }
    return list;
  }

  @override
  Map<String, V> readStringMap<V>(V f(), {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<String, V> map = {};
    for (int i = 0; i < count; i++) {
      String key = readString();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  @override
  IndexedClass readClassOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readClass();
    }
    return null;
  }

  @override
  ir.TreeNode readTreeNodeOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readTreeNode();
    }
    return null;
  }

  @override
  IndexedMember readMemberOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readMember();
    }
    return null;
  }

  @override
  Local readLocalOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readLocal();
    }
    return null;
  }

  @override
  ConstantValue readConstantOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readConstant();
    }
    return null;
  }

  @override
  List<E> readConstants<E extends ConstantValue>({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = new List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ConstantValue value = readConstant();
      list[i] = value;
    }
    return list;
  }

  @override
  Map<K, V> readConstantMap<K extends ConstantValue, V>(V f(),
      {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ConstantValue key = readConstant();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  @override
  IndexedLibrary readLibraryOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readLibrary();
    }
    return null;
  }

  @override
  ImportEntity readImportOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readImport();
    }
    return null;
  }

  @override
  List<ImportEntity> readImports({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<ImportEntity> list = new List<ImportEntity>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readImport();
    }
    return list;
  }

  @override
  Map<ImportEntity, V> readImportMap<V>(V f(), {bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<ImportEntity, V> map = {};
    for (int i = 0; i < count; i++) {
      ImportEntity key = readImport();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  @override
  List<ir.DartType> readDartTypeNodes({bool emptyAsNull: false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<ir.DartType> list = new List<ir.DartType>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readDartTypeNode();
    }
    return list;
  }

  @override
  ir.Name readName() {
    String text = readString();
    ir.Library library = readValueOrNull(readLibraryNode);
    return new ir.Name(text, library);
  }

  @override
  ir.LibraryDependency readLibraryDependencyNode() {
    ir.Library library = readLibraryNode();
    int index = readInt();
    return library.dependencies[index];
  }

  @override
  ir.LibraryDependency readLibraryDependencyNodeOrNull() {
    return readValueOrNull(readLibraryDependencyNode);
  }

  @override
  js.Node readJsNodeOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readJsNode();
    }
    return null;
  }
}

/// Mixin that implements all convenience methods of [DataSink].
abstract class DataSinkMixin implements DataSink {
  @override
  void writeIntOrNull(int value) {
    writeBool(value != null);
    if (value != null) {
      writeInt(value);
    }
  }

  @override
  void writeStringOrNull(String value) {
    writeBool(value != null);
    if (value != null) {
      writeString(value);
    }
  }

  @override
  void writeClassOrNull(IndexedClass value) {
    writeBool(value != null);
    if (value != null) {
      writeClass(value);
    }
  }

  @override
  void writeLocalOrNull(Local value) {
    writeBool(value != null);
    if (value != null) {
      writeLocal(value);
    }
  }

  @override
  void writeClasses(Iterable<ClassEntity> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (IndexedClass value in values) {
        writeClass(value);
      }
    }
  }

  @override
  void writeTreeNodes(Iterable<ir.TreeNode> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.TreeNode value in values) {
        writeTreeNode(value);
      }
    }
  }

  @override
  void writeStrings(Iterable<String> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (String value in values) {
        writeString(value);
      }
    }
  }

  @override
  void writeMemberNodes(Iterable<ir.Member> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.Member value in values) {
        writeMemberNode(value);
      }
    }
  }

  @override
  void writeDartTypes(Iterable<DartType> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (DartType value in values) {
        writeDartType(value);
      }
    }
  }

  @override
  void writeLibraryMap<V>(Map<LibraryEntity, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((LibraryEntity library, V value) {
        writeLibrary(library);
        f(value);
      });
    }
  }

  @override
  void writeClassMap<V>(Map<ClassEntity, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ClassEntity cls, V value) {
        writeClass(cls);
        f(value);
      });
    }
  }

  @override
  void writeMemberMap<V>(
      Map<MemberEntity, V> map, void f(MemberEntity member, V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((MemberEntity member, V value) {
        writeMember(member);
        f(member, value);
      });
    }
  }

  @override
  void writeStringMap<V>(Map<String, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((String key, V value) {
        writeString(key);
        f(value);
      });
    }
  }

  @override
  void writeLocals(Iterable<Local> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (Local value in values) {
        writeLocal(value);
      }
    }
  }

  @override
  void writeLocalMap<V>(Map<Local, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((Local key, V value) {
        writeLocal(key);
        f(value);
      });
    }
  }

  @override
  void writeMemberNodeMap<V>(Map<ir.Member, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ir.Member key, V value) {
        writeMemberNode(key);
        f(value);
      });
    }
  }

  @override
  void writeTreeNodeMap<V>(Map<ir.TreeNode, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ir.TreeNode key, V value) {
        writeTreeNode(key);
        f(value);
      });
    }
  }

  @override
  void writeList<E>(Iterable<E> values, void f(E value),
      {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      values.forEach(f);
    }
  }

  @override
  void writeTreeNodeOrNull(ir.TreeNode value) {
    writeBool(value != null);
    if (value != null) {
      writeTreeNode(value);
    }
  }

  @override
  void writeValueOrNull<E>(E value, void f(E value)) {
    writeBool(value != null);
    if (value != null) {
      f(value);
    }
  }

  @override
  void writeMemberOrNull(IndexedMember value) {
    writeBool(value != null);
    if (value != null) {
      writeMember(value);
    }
  }

  @override
  void writeMembers(Iterable<MemberEntity> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (IndexedMember value in values) {
        writeMember(value);
      }
    }
  }

  @override
  void writeTypeParameterNodes(Iterable<ir.TypeParameter> values,
      {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.TypeParameter value in values) {
        writeTypeParameterNode(value);
      }
    }
  }

  @override
  void writeConstantOrNull(ConstantValue value) {
    writeBool(value != null);
    if (value != null) {
      writeConstant(value);
    }
  }

  @override
  void writeConstants(Iterable<ConstantValue> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ConstantValue value in values) {
        writeConstant(value);
      }
    }
  }

  @override
  void writeConstantMap<V>(Map<ConstantValue, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ConstantValue key, V value) {
        writeConstant(key);
        f(value);
      });
    }
  }

  @override
  void writeLibraryOrNull(IndexedLibrary value) {
    writeBool(value != null);
    if (value != null) {
      writeLibrary(value);
    }
  }

  @override
  void writeImportOrNull(ImportEntity value) {
    writeBool(value != null);
    if (value != null) {
      writeImport(value);
    }
  }

  @override
  void writeImports(Iterable<ImportEntity> values, {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ImportEntity value in values) {
        writeImport(value);
      }
    }
  }

  @override
  void writeImportMap<V>(Map<ImportEntity, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ImportEntity key, V value) {
        writeImport(key);
        f(value);
      });
    }
  }

  @override
  void writeDartTypeNodes(Iterable<ir.DartType> values,
      {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.DartType value in values) {
        writeDartTypeNode(value);
      }
    }
  }

  @override
  void writeName(ir.Name value) {
    writeString(value.text);
    writeValueOrNull(value.library, writeLibraryNode);
  }

  @override
  void writeLibraryDependencyNode(ir.LibraryDependency value) {
    ir.Library library = value.parent;
    writeLibraryNode(library);
    writeInt(library.dependencies.indexOf(value));
  }

  @override
  void writeLibraryDependencyNodeOrNull(ir.LibraryDependency value) {
    writeValueOrNull(value, writeLibraryDependencyNode);
  }

  @override
  void writeJsNodeOrNull(js.Node value) {
    writeBool(value != null);
    if (value != null) {
      writeJsNode(value);
    }
  }
}
