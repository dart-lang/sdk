// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Base implementation of [DataSink] using [DataSinkMixin] to implement
/// convenience methods.
abstract class AbstractDataSink extends DataSinkMixin implements DataSink {
  /// If `true`, serialization of every data kind is preceded by a [DataKind]
  /// value.
  ///
  /// This is used for debugging data inconsistencies between serialization
  /// and deserialization.
  final bool useDataKinds;

  /// Visitor used for serializing [ir.DartType]s.
  DartTypeNodeWriter _dartTypeNodeWriter;

  /// Stack of tags used when [useDataKinds] is `true` to help debugging section
  /// inconsistencies between serialization and deserialization.
  List<String> _tags;

  /// Map of [_MemberData] object for serialized kernel member nodes.
  Map<ir.Member, _MemberData> _memberData = {};

  IndexedSink<String> _stringIndex;
  IndexedSink<Uri> _uriIndex;
  IndexedSink<ir.Member> _memberNodeIndex;
  IndexedSink<ImportEntity> _importIndex;
  IndexedSink<ConstantValue> _constantIndex;

  Map<Type, IndexedSink> _generalCaches = {};

  EntityWriter _entityWriter = const EntityWriter();
  CodegenWriter _codegenWriter;

  final Map<String, int> tagFrequencyMap;

  ir.Member _currentMemberContext;
  _MemberData _currentMemberData;

  AbstractDataSink({this.useDataKinds: false, this.tagFrequencyMap}) {
    _dartTypeNodeWriter = new DartTypeNodeWriter(this);
    _stringIndex = new IndexedSink<String>(this);
    _uriIndex = new IndexedSink<Uri>(this);
    _memberNodeIndex = new IndexedSink<ir.Member>(this);
    _importIndex = new IndexedSink<ImportEntity>(this);
    _constantIndex = new IndexedSink<ConstantValue>(this);
  }

  @override
  void begin(String tag) {
    if (tagFrequencyMap != null) {
      tagFrequencyMap[tag] ??= 0;
      tagFrequencyMap[tag]++;
    }
    if (useDataKinds) {
      _tags ??= <String>[];
      _tags.add(tag);
      _begin(tag);
    }
  }

  @override
  void end(Object tag) {
    if (useDataKinds) {
      _end(tag);

      String existingTag = _tags.removeLast();
      assert(existingTag == tag,
          "Unexpected tag end. Expected $existingTag, found $tag.");
    }
  }

  @override
  void inMemberContext(ir.Member context, void f()) {
    ir.Member oldMemberContext = _currentMemberContext;
    _MemberData oldMemberData = _currentMemberData;
    _currentMemberContext = context;
    _currentMemberData = null;
    f();
    _currentMemberData = oldMemberData;
    _currentMemberContext = oldMemberContext;
  }

  _MemberData get currentMemberData {
    assert(_currentMemberContext != null,
        "DataSink has no current member context.");
    return _currentMemberData ??= _memberData[_currentMemberContext] ??=
        new _MemberData(_currentMemberContext);
  }

  @override
  void writeCached<E>(E value, void f(E value)) {
    IndexedSink sink = _generalCaches[E] ??= new IndexedSink<E>(this);
    sink.write(value, (v) => f(v));
  }

  @override
  void writeSourceSpan(SourceSpan value) {
    _writeDataKind(DataKind.sourceSpan);
    _writeUri(value.uri);
    _writeIntInternal(value.begin);
    _writeIntInternal(value.end);
  }

  @override
  void writeDartType(DartType value, {bool allowNull: false}) {
    _writeDataKind(DataKind.dartType);
    _writeDartType(value, [], allowNull: allowNull);
  }

  void _writeDartType(
      DartType value, List<FunctionTypeVariable> functionTypeVariables,
      {bool allowNull: false}) {
    if (value == null) {
      if (!allowNull) {
        throw new UnsupportedError("Missing DartType is not allowed.");
      }
      writeEnum(DartTypeKind.none);
    } else {
      value.writeToDataSink(this, functionTypeVariables);
    }
  }

  @override
  void writeDartTypeNode(ir.DartType value, {bool allowNull: false}) {
    _writeDataKind(DataKind.dartTypeNode);
    _writeDartTypeNode(value, [], allowNull: allowNull);
  }

  void _writeDartTypeNode(
      ir.DartType value, List<ir.TypeParameter> functionTypeVariables,
      {bool allowNull: false}) {
    if (value == null) {
      if (!allowNull) {
        throw new UnsupportedError("Missing ir.DartType node is not allowed.");
      }
      writeEnum(DartTypeNodeKind.none);
    } else {
      value.accept1(_dartTypeNodeWriter, functionTypeVariables);
    }
  }

  @override
  void writeMemberNode(ir.Member value) {
    _writeDataKind(DataKind.memberNode);
    _writeMemberNode(value);
  }

  void _writeMemberNode(ir.Member value) {
    _memberNodeIndex.write(value, _writeMemberNodeInternal);
  }

  void _writeMemberNodeInternal(ir.Member value) {
    ir.Class cls = value.enclosingClass;
    if (cls != null) {
      _writeEnumInternal(MemberContextKind.cls);
      _writeClassNode(cls);
      _writeString(_computeMemberName(value));
    } else {
      _writeEnumInternal(MemberContextKind.library);
      _writeLibraryNode(value.enclosingLibrary);
      _writeString(_computeMemberName(value));
    }
  }

  @override
  void writeClassNode(ir.Class value) {
    _writeDataKind(DataKind.classNode);
    _writeClassNode(value);
  }

  void _writeClassNode(ir.Class value) {
    _writeLibraryNode(value.enclosingLibrary);
    _writeString(value.name);
  }

  @override
  void writeTypedefNode(ir.Typedef value) {
    _writeDataKind(DataKind.typedefNode);
    _writeTypedefNode(value);
  }

  void _writeTypedefNode(ir.Typedef value) {
    _writeLibraryNode(value.enclosingLibrary);
    _writeString(value.name);
  }

  @override
  void writeLibraryNode(ir.Library value) {
    _writeDataKind(DataKind.libraryNode);
    _writeLibraryNode(value);
  }

  void _writeLibraryNode(ir.Library value) {
    _writeUri(value.importUri);
  }

  @override
  void writeEnum(dynamic value) {
    _writeDataKind(DataKind.enumValue);
    _writeEnumInternal(value);
  }

  @override
  void writeBool(bool value) {
    assert(value != null);
    _writeDataKind(DataKind.bool);
    _writeBool(value);
  }

  void _writeBool(bool value) {
    _writeIntInternal(value ? 1 : 0);
  }

  @override
  void writeUri(Uri value) {
    assert(value != null);
    _writeDataKind(DataKind.uri);
    _writeUri(value);
  }

  @override
  void writeString(String value) {
    assert(value != null);
    _writeDataKind(DataKind.string);
    _writeString(value);
  }

  @override
  void writeInt(int value) {
    assert(value != null);
    assert(value >= 0 && value >> 30 == 0);
    _writeDataKind(DataKind.uint30);
    _writeIntInternal(value);
  }

  @override
  void writeTreeNode(ir.TreeNode value) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, null);
  }

  @override
  void writeTreeNodeInContext(ir.TreeNode value) {
    writeTreeNodeInContextInternal(value, currentMemberData);
  }

  void writeTreeNodeInContextInternal(
      ir.TreeNode value, _MemberData memberData) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, memberData);
  }

  @override
  void writeTreeNodeOrNullInContext(ir.TreeNode value) {
    writeBool(value != null);
    if (value != null) {
      writeTreeNodeInContextInternal(value, currentMemberData);
    }
  }

  @override
  void writeTreeNodesInContext(Iterable<ir.TreeNode> values,
      {bool allowNull: false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.TreeNode value in values) {
        writeTreeNodeInContextInternal(value, currentMemberData);
      }
    }
  }

  @override
  void writeTreeNodeMapInContext<V>(Map<ir.TreeNode, V> map, void f(V value),
      {bool allowNull: false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ir.TreeNode key, V value) {
        writeTreeNodeInContextInternal(key, currentMemberData);
        f(value);
      });
    }
  }

  _MemberData _getMemberData(ir.TreeNode node) {
    ir.TreeNode member = node;
    while (member is! ir.Member) {
      if (member == null) {
        throw new UnsupportedError("No enclosing member of TreeNode "
            "$node (${node.runtimeType})");
      }
      member = member.parent;
    }
    _writeMemberNode(member);
    return _memberData[member] ??= new _MemberData(member);
  }

  void _writeTreeNode(ir.TreeNode value, _MemberData memberData) {
    if (value is ir.Class) {
      _writeEnumInternal(_TreeNodeKind.cls);
      _writeClassNode(value);
    } else if (value is ir.Member) {
      _writeEnumInternal(_TreeNodeKind.member);
      _writeMemberNode(value);
    } else if (value is ir.VariableDeclaration &&
        value.parent is ir.FunctionDeclaration) {
      _writeEnumInternal(_TreeNodeKind.functionDeclarationVariable);
      _writeTreeNode(value.parent, memberData);
    } else if (value is ir.FunctionNode) {
      _writeEnumInternal(_TreeNodeKind.functionNode);
      _writeFunctionNode(value, memberData);
    } else if (value is ir.TypeParameter) {
      _writeEnumInternal(_TreeNodeKind.typeParameter);
      _writeTypeParameter(value, memberData);
    } else if (value is ConstantReference) {
      _writeEnumInternal(_TreeNodeKind.constant);
      memberData ??= _getMemberData(value.expression);
      _writeTreeNode(value.expression, memberData);
      int index =
          memberData.getIndexByConstant(value.expression, value.constant);
      _writeIntInternal(index);
    } else {
      _writeEnumInternal(_TreeNodeKind.node);
      memberData ??= _getMemberData(value);
      int index = memberData.getIndexByTreeNode(value);
      assert(
          index != null,
          "No TreeNode index found for ${value.runtimeType} "
          "found in ${memberData}.");
      _writeIntInternal(index);
    }
  }

  void _writeFunctionNode(ir.FunctionNode value, _MemberData memberData) {
    ir.TreeNode parent = value.parent;
    if (parent is ir.Procedure) {
      _writeEnumInternal(_FunctionNodeKind.procedure);
      _writeMemberNode(parent);
    } else if (parent is ir.Constructor) {
      _writeEnumInternal(_FunctionNodeKind.constructor);
      _writeMemberNode(parent);
    } else if (parent is ir.FunctionExpression) {
      _writeEnumInternal(_FunctionNodeKind.functionExpression);
      _writeTreeNode(parent, memberData);
    } else if (parent is ir.FunctionDeclaration) {
      _writeEnumInternal(_FunctionNodeKind.functionDeclaration);
      _writeTreeNode(parent, memberData);
    } else {
      throw new UnsupportedError(
          "Unsupported FunctionNode parent ${parent.runtimeType}");
    }
  }

  @override
  void writeTypeParameterNode(ir.TypeParameter value) {
    _writeDataKind(DataKind.typeParameterNode);
    _writeTypeParameter(value, null);
  }

  void _writeTypeParameter(ir.TypeParameter value, _MemberData memberData) {
    ir.TreeNode parent = value.parent;
    if (parent is ir.Class) {
      _writeEnumInternal(_TypeParameterKind.cls);
      _writeClassNode(parent);
      _writeIntInternal(parent.typeParameters.indexOf(value));
    } else if (parent is ir.FunctionNode) {
      _writeEnumInternal(_TypeParameterKind.functionNode);
      _writeFunctionNode(parent, memberData);
      _writeIntInternal(parent.typeParameters.indexOf(value));
    } else {
      throw new UnsupportedError(
          "Unsupported TypeParameter parent ${parent.runtimeType}");
    }
  }

  void _writeDataKind(DataKind kind) {
    if (useDataKinds) _writeEnumInternal(kind);
  }

  @override
  void writeLibrary(IndexedLibrary value) {
    _entityWriter.writeLibraryToDataSink(this, value);
  }

  @override
  void writeClass(IndexedClass value) {
    _entityWriter.writeClassToDataSink(this, value);
  }

  @override
  void writeMember(IndexedMember value) {
    _entityWriter.writeMemberToDataSink(this, value);
  }

  @override
  void writeTypeVariable(IndexedTypeVariable value) {
    _entityWriter.writeTypeVariableToDataSink(this, value);
  }

  @override
  void writeLocal(Local local) {
    if (local is JLocal) {
      writeEnum(LocalKind.jLocal);
      writeMember(local.memberContext);
      writeInt(local.localIndex);
    } else if (local is ThisLocal) {
      writeEnum(LocalKind.thisLocal);
      writeClass(local.enclosingClass);
    } else if (local is BoxLocal) {
      writeEnum(LocalKind.boxLocal);
      writeClass(local.container);
    } else if (local is AnonymousClosureLocal) {
      writeEnum(LocalKind.anonymousClosureLocal);
      writeClass(local.closureClass);
    } else if (local is TypeVariableLocal) {
      writeEnum(LocalKind.typeVariableLocal);
      writeTypeVariable(local.typeVariable);
    } else {
      throw new UnsupportedError("Unsupported local ${local.runtimeType}");
    }
  }

  @override
  void writeConstant(ConstantValue value) {
    _writeDataKind(DataKind.constant);
    _writeConstant(value);
  }

  @override
  void writeDoubleValue(double value) {
    _writeDataKind(DataKind.double);
    _writeDoubleValue(value);
  }

  void _writeDoubleValue(double value) {
    ByteData data = new ByteData(8);
    data.setFloat64(0, value);
    writeInt(data.getUint16(0));
    writeInt(data.getUint16(2));
    writeInt(data.getUint16(4));
    writeInt(data.getUint16(6));
  }

  @override
  void writeIntegerValue(int value) {
    _writeDataKind(DataKind.int);
    _writeBigInt(new BigInt.from(value));
  }

  void _writeBigInt(BigInt value) {
    writeString(value.toString());
  }

  void _writeConstant(ConstantValue value) {
    _constantIndex.write(value, _writeConstantInternal);
  }

  void _writeConstantInternal(ConstantValue value) {
    _writeEnumInternal(value.kind);
    switch (value.kind) {
      case ConstantValueKind.BOOL:
        BoolConstantValue constant = value;
        writeBool(constant.boolValue);
        break;
      case ConstantValueKind.INT:
        IntConstantValue constant = value;
        _writeBigInt(constant.intValue);
        break;
      case ConstantValueKind.DOUBLE:
        DoubleConstantValue constant = value;
        _writeDoubleValue(constant.doubleValue);
        break;
      case ConstantValueKind.STRING:
        StringConstantValue constant = value;
        writeString(constant.stringValue);
        break;
      case ConstantValueKind.NULL:
        break;
      case ConstantValueKind.FUNCTION:
        FunctionConstantValue constant = value;
        IndexedFunction function = constant.element;
        writeMember(function);
        writeDartType(constant.type);
        break;
      case ConstantValueKind.LIST:
        ListConstantValue constant = value;
        writeDartType(constant.type);
        writeConstants(constant.entries);
        break;
      case ConstantValueKind.SET:
        constant_system.JavaScriptSetConstant constant = value;
        writeDartType(constant.type);
        writeConstant(constant.entries);
        break;
      case ConstantValueKind.MAP:
        constant_system.JavaScriptMapConstant constant = value;
        writeDartType(constant.type);
        writeConstant(constant.keyList);
        writeConstants(constant.values);
        writeConstantOrNull(constant.protoValue);
        writeBool(constant.onlyStringKeys);
        break;
      case ConstantValueKind.CONSTRUCTED:
        ConstructedConstantValue constant = value;
        writeDartType(constant.type);
        writeMemberMap(constant.fields,
            (MemberEntity member, ConstantValue value) => writeConstant(value));
        break;
      case ConstantValueKind.TYPE:
        TypeConstantValue constant = value;
        writeDartType(constant.representedType);
        writeDartType(constant.type);
        break;
      case ConstantValueKind.INSTANTIATION:
        InstantiationConstantValue constant = value;
        writeDartTypes(constant.typeArguments);
        writeConstant(constant.function);
        break;
      case ConstantValueKind.NON_CONSTANT:
        break;
      case ConstantValueKind.INTERCEPTOR:
        InterceptorConstantValue constant = value;
        writeClass(constant.cls);
        break;
      case ConstantValueKind.DEFERRED_GLOBAL:
        DeferredGlobalConstantValue constant = value;
        writeConstant(constant.referenced);
        writeOutputUnitReference(constant.unit);
        break;
      case ConstantValueKind.DUMMY_INTERCEPTOR:
        break;
      case ConstantValueKind.UNREACHABLE:
        break;
      case ConstantValueKind.JS_NAME:
        JsNameConstantValue constant = value;
        writeJsNode(constant.name);
        break;
    }
  }

  void _writeString(String value) {
    _stringIndex.write(value, _writeStringInternal);
  }

  void _writeUri(Uri value) {
    _uriIndex.write(value, _writeUriInternal);
  }

  @override
  void writeImport(ImportEntity value) {
    _writeDataKind(DataKind.import);
    _writeImport(value);
  }

  void _writeImport(ImportEntity value) {
    _importIndex.write(value, _writeImportInternal);
  }

  void _writeImportInternal(ImportEntity value) {
    // TODO(johnniwinther): Do we need to serialize non-deferred imports?
    writeStringOrNull(value.name);
    _writeUri(value.uri);
    _writeUri(value.enclosingLibraryUri);
    _writeBool(value.isDeferred);
  }

  @override
  void registerEntityWriter(EntityWriter writer) {
    assert(writer != null);
    _entityWriter = writer;
  }

  @override
  void registerCodegenWriter(CodegenWriter writer) {
    assert(writer != null);
    assert(_codegenWriter == null);
    _codegenWriter = writer;
  }

  @override
  void writeOutputUnitReference(OutputUnit value) {
    assert(
        _codegenWriter != null,
        "Can not serialize an OutputUnit reference "
        "without a registered codegen writer.");
    _codegenWriter.writeOutputUnitReference(this, value);
  }

  @override
  void writeAbstractValue(AbstractValue value) {
    assert(_codegenWriter != null,
        "Can not serialize an AbstractValue without a registered codegen writer.");
    _codegenWriter.writeAbstractValue(this, value);
  }

  @override
  void writeJsNode(js.Node value) {
    assert(_codegenWriter != null,
        "Can not serialize a JS node without a registered codegen writer.");
    _codegenWriter.writeJsNode(this, value);
  }

  @override
  void writeTypeRecipe(TypeRecipe value) {
    assert(_codegenWriter != null,
        "Can not serialize a TypeRecipe without a registered codegen writer.");
    _codegenWriter.writeTypeRecipe(this, value);
  }

  /// Actual serialization of a section begin tag, implemented by subclasses.
  void _begin(String tag);

  /// Actual serialization of a section end tag, implemented by subclasses.
  void _end(String tag);

  /// Actual serialization of a URI value, implemented by subclasses.
  void _writeUriInternal(Uri value);

  /// Actual serialization of a String value, implemented by subclasses.
  void _writeStringInternal(String value);

  /// Actual serialization of a non-negative integer value, implemented by
  /// subclasses.
  void _writeIntInternal(int value);

  /// Actual serialization of an enum value, implemented by subclasses.
  void _writeEnumInternal(dynamic value);
}
