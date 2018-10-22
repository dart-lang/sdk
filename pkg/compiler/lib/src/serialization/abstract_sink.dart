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

  /// Visitor used for serializing [DartType]s.
  DartTypeWriter _dartTypeWriter;

  /// Stack of tags used when [useDataKinds] is `true` to help debugging section
  /// inconsistencies between serialization and deserialization.
  List<String> _tags;

  /// Map of [_MemberData] object for serialized kernel member nodes.
  Map<ir.Member, _MemberData> _memberData = {};

  AbstractDataSink({this.useDataKinds: false}) {
    _dartTypeWriter = new DartTypeWriter(this);
  }

  void begin(String tag) {
    if (useDataKinds) {
      _tags ??= <String>[];
      _tags.add(tag);
      _begin(tag);
    }
  }

  void end(Object tag) {
    if (useDataKinds) {
      _end(tag);

      String existingTag = _tags.removeLast();
      assert(existingTag == tag,
          "Unexpected tag end. Expected $existingTag, found $tag.");
    }
  }

  @override
  void writeSourceSpan(SourceSpan value) {
    _writeDataKind(DataKind.sourceSpan);
    _writeUri(value.uri);
    _writeInt(value.begin);
    _writeInt(value.end);
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
      _dartTypeWriter.visit(value, functionTypeVariables);
    }
  }

  @override
  void writeMemberNode(ir.Member value) {
    _writeDataKind(DataKind.memberNode);
    _writeMemberNode(value);
  }

  void _writeMemberNode(ir.Member value) {
    ir.Class cls = value.enclosingClass;
    if (cls != null) {
      _writeEnum(MemberContextKind.cls);
      _writeClassNode(cls);
      _writeString(_computeMemberName(value));
    } else {
      _writeEnum(MemberContextKind.library);
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
    _writeEnum(value);
  }

  @override
  void writeBool(bool value) {
    assert(value != null);
    _writeDataKind(DataKind.bool);
    _writeInt(value ? 1 : 0);
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
    _writeDataKind(DataKind.int);
    _writeInt(value);
  }

  void writeTreeNode(ir.TreeNode value) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value);
  }

  void _writeTreeNode(ir.TreeNode value) {
    if (value is ir.Class) {
      _writeEnum(_TreeNodeKind.cls);
      _writeClassNode(value);
    } else if (value is ir.Member) {
      _writeEnum(_TreeNodeKind.member);
      _writeMemberNode(value);
    } else if (value is ir.VariableDeclaration &&
        value.parent is ir.FunctionDeclaration) {
      _writeEnum(_TreeNodeKind.functionDeclarationVariable);
      _writeTreeNode(value.parent);
    } else if (value is ir.FunctionNode) {
      _writeEnum(_TreeNodeKind.functionNode);
      _writeFunctionNode(value);
    } else if (value is ir.TypeParameter) {
      _writeEnum(_TreeNodeKind.typeParameter);
      _writeTypeParameter(value);
    } else {
      _writeEnum(_TreeNodeKind.node);
      ir.TreeNode member = value;
      while (member is! ir.Member) {
        if (member == null) {
          throw new UnsupportedError("No enclosing member of TreeNode "
              "$value (${value.runtimeType})");
        }
        member = member.parent;
      }
      _writeMemberNode(member);
      _MemberData memberData = _memberData[member] ??= new _MemberData(member);
      int index = memberData.getIndexByTreeNode(value);
      assert(index != null, "No index found for ${value.runtimeType}.");
      _writeInt(index);
    }
  }

  void _writeFunctionNode(ir.FunctionNode value) {
    ir.TreeNode parent = value.parent;
    if (parent is ir.Procedure) {
      _writeEnum(_FunctionNodeKind.procedure);
      _writeMemberNode(parent);
    } else if (parent is ir.Constructor) {
      _writeEnum(_FunctionNodeKind.constructor);
      _writeMemberNode(parent);
    } else if (parent is ir.FunctionExpression) {
      _writeEnum(_FunctionNodeKind.functionExpression);
      _writeTreeNode(parent);
    } else if (parent is ir.FunctionDeclaration) {
      _writeEnum(_FunctionNodeKind.functionDeclaration);
      _writeTreeNode(parent);
    } else {
      throw new UnsupportedError(
          "Unsupported FunctionNode parent ${parent.runtimeType}");
    }
  }

  @override
  void writeTypeParameterNode(ir.TypeParameter value) {
    _writeDataKind(DataKind.typeParameterNode);
    _writeTypeParameter(value);
  }

  void _writeTypeParameter(ir.TypeParameter value) {
    ir.TreeNode parent = value.parent;
    if (parent is ir.Class) {
      _writeEnum(_TypeParameterKind.cls);
      _writeClassNode(parent);
      _writeInt(parent.typeParameters.indexOf(value));
    } else if (parent is ir.FunctionNode) {
      _writeEnum(_TypeParameterKind.functionNode);
      _writeFunctionNode(parent);
      _writeInt(parent.typeParameters.indexOf(value));
    } else {
      throw new UnsupportedError(
          "Unsupported TypeParameter parent ${parent.runtimeType}");
    }
  }

  void _writeDataKind(DataKind kind) {
    if (useDataKinds) _writeEnum(kind);
  }

  void writeLibrary(IndexedLibrary value) {
    writeInt(value.libraryIndex);
  }

  void writeClass(IndexedClass value) {
    writeInt(value.classIndex);
  }

  void writeTypedef(IndexedTypedef value) {
    writeInt(value.typedefIndex);
  }

  void writeMember(IndexedMember value) {
    writeInt(value.memberIndex);
  }

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
      writeDartType(local.typeVariable);
    } else {
      throw new UnsupportedError("Unsupported local ${local.runtimeType}");
    }
  }

  @override
  void writeConstant(ConstantValue value) {
    _writeDataKind(DataKind.constant);
    _writeConstant(value);
  }

  void _writeConstant(ConstantValue value) {
    _writeEnum(value.kind);
    switch (value.kind) {
      case ConstantValueKind.BOOL:
        BoolConstantValue constant = value;
        writeBool(constant.boolValue);
        break;
      case ConstantValueKind.INT:
        IntConstantValue constant = value;
        writeString(constant.intValue.toString());
        break;
      case ConstantValueKind.DOUBLE:
        DoubleConstantValue constant = value;
        ByteData data = new ByteData(8);
        data.setFloat64(0, constant.doubleValue);
        writeInt(data.getUint16(0));
        writeInt(data.getUint16(2));
        writeInt(data.getUint16(4));
        writeInt(data.getUint16(6));
        break;
      case ConstantValueKind.STRING:
        StringConstantValue constant = value;
        writeString(constant.stringValue);
        break;
      case ConstantValueKind.NULL:
        break;
      default:
        // TODO(johnniwinther): Support remaining constant values.
        throw new UnsupportedError(
            "Unexpected constant value kind ${value.kind}.");
    }
  }

  /// Actual serialization of a section begin tag, implemented by subclasses.
  void _begin(String tag);

  /// Actual serialization of a section end tag, implemented by subclasses.
  void _end(String tag);

  /// Actual serialization of a URI value, implemented by subclasses.
  void _writeUri(Uri value);

  /// Actual serialization of a String value, implemented by subclasses.
  void _writeString(String value);

  /// Actual serialization of a non-negative integer value, implemented by
  /// subclasses.
  void _writeInt(int value);

  /// Actual serialization of an enum value, implemented by subclasses.
  void _writeEnum(dynamic value);
}
