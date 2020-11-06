// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

import 'package:kernel/ast.dart'
    show
        BoolConstant,
        BottomType,
        Class,
        Constant,
        ConstantMapEntry,
        DartType,
        DoubleConstant,
        DynamicType,
        Field,
        FunctionType,
        FutureOrType,
        InvalidType,
        InstanceConstant,
        IntConstant,
        InterfaceType,
        Library,
        ListConstant,
        MapConstant,
        NeverType,
        NullConstant,
        NullType,
        Nullability,
        PartialInstantiationConstant,
        Procedure,
        SetConstant,
        StringConstant,
        SymbolConstant,
        TearOffConstant,
        TreeNode,
        TypedefType,
        TypeLiteralConstant,
        TypeParameter,
        TypeParameterType,
        UnevaluatedConstant,
        VoidType;

import 'package:kernel/visitor.dart' show ConstantVisitor, DartTypeVisitor;

import '../denylisted_classes.dart' show denylistedCoreClasses;

import '../fasta_codes.dart'
    show Message, templateTypeOrigin, templateTypeOriginWithFileUri;

import '../problems.dart' show unsupported;

/// A pretty-printer for Kernel types and constants with the ability to label
/// raw types with numeric markers in Dart comments (e.g. `/*1*/`) to
/// distinguish different types with the same name. This is used in diagnostic
/// messages to indicate the origins of types occurring in the message.
class TypeLabeler implements DartTypeVisitor<void>, ConstantVisitor<void> {
  final List<LabeledNode> names = <LabeledNode>[];
  final Map<String, List<LabeledNode>> nameMap = <String, List<LabeledNode>>{};
  final bool printNullability;

  List<Object> result;

  TypeLabeler(this.printNullability);

  /// Pretty-print a type.
  /// When all types and constants appearing in the same message have been
  /// pretty-printed, the returned list can be converted to its string
  /// representation (with labels on duplicated names) by the `join()` method.
  List<Object> labelType(DartType type) {
    // TODO(askesc): Remove null check when we are completely null clean here.
    if (type == null) return ["null-type"];
    result = [];
    type.accept(this);
    return result;
  }

  /// Pretty-print a constant.
  /// When all types and constants appearing in the same message have been
  /// pretty-printed, the returned list can be converted to its string
  /// representation (with labels on duplicated names) by the `join()` method.
  List<Object> labelConstant(Constant constant) {
    // TODO(askesc): Remove null check when we are completely null clean here.
    if (constant == null) return ["null-constant"];
    result = [];
    constant.accept(this);
    return result;
  }

  /// Get a textual description of the origins of the raw types appearing in
  /// types and constants that have been pretty-printed using this labeler.
  String get originMessages {
    StringBuffer messages = new StringBuffer();
    for (LabeledNode name in names) {
      messages.write(name.originMessage);
    }
    return messages.toString();
  }

  // We don't have access to coreTypes here, so we have our own Object check.
  static bool isObject(DartType type) {
    if (type is InterfaceType && type.classNode.name == 'Object') {
      Uri importUri = type.classNode.enclosingLibrary.importUri;
      return importUri.scheme == 'dart' && importUri.path == 'core';
    }
    return false;
  }

  LabeledNode nameForEntity(
      TreeNode node, String nodeName, Uri importUri, Uri fileUri) {
    List<LabeledNode> labelsForName = nameMap[nodeName];
    if (labelsForName == null) {
      // First encountered entity with this name
      LabeledNode name =
          new LabeledNode(node, nodeName, importUri, fileUri, this);
      names.add(name);
      nameMap[nodeName] = [name];
      return name;
    } else {
      for (LabeledNode entityForName in labelsForName) {
        if (entityForName.node == node) {
          // Previously encountered entity
          return entityForName;
        }
      }
      // New entity with name that was previously encountered
      LabeledNode name =
          new LabeledNode(node, nodeName, importUri, fileUri, this);
      names.add(name);
      labelsForName.add(name);
      return name;
    }
  }

  void addNullability(Nullability nullability) {
    if (printNullability) {
      if (nullability == Nullability.nullable) {
        result.add("?");
      }
    }
  }

  void defaultDartType(DartType type) {}
  void visitTypedefType(TypedefType node) {}

  void visitInvalidType(InvalidType node) {
    // TODO(askesc): Throw internal error if InvalidType appears in diagnostics.
    result.add("invalid-type");
  }

  void visitBottomType(BottomType node) {
    // TODO(askesc): Throw internal error if BottomType appears in diagnostics.
    result.add("bottom-type");
  }

  void visitNeverType(NeverType node) {
    result.add("Never");
    addNullability(node.declaredNullability);
  }

  void visitNullType(NullType node) {
    result.add("Null");
  }

  void visitDynamicType(DynamicType node) {
    result.add("dynamic");
  }

  void visitVoidType(VoidType node) {
    result.add("void");
  }

  void visitTypeParameterType(TypeParameterType node) {
    TreeNode parent = node.parameter;
    while (parent is! Library && parent != null) {
      parent = parent.parent;
    }
    // Note that this can be null if, for instance, the erroneous code is not
    // actually in the tree - then we don't know where it comes from!
    Library enclosingLibrary = parent;

    result.add(nameForEntity(
        node.parameter,
        node.parameter.name,
        enclosingLibrary == null ? unknownUri : enclosingLibrary.importUri,
        enclosingLibrary == null ? unknownUri : enclosingLibrary.fileUri));
    addNullability(node.declaredNullability);
  }

  void visitFunctionType(FunctionType node) {
    node.returnType.accept(this);
    result.add(" Function");
    if (node.typeParameters.isNotEmpty) {
      result.add("<");
      bool first = true;
      for (TypeParameter param in node.typeParameters) {
        if (!first) result.add(", ");
        result.add(param.name);
        if (isObject(param.bound) && param.defaultType is DynamicType) {
          // Bound was not specified, and therefore should not be printed.
        } else {
          result.add(" extends ");
          param.bound.accept(this);
        }
        first = false;
      }
      result.add(">");
    }
    result.add("(");
    bool first = true;
    for (int i = 0; i < node.requiredParameterCount; i++) {
      if (!first) result.add(", ");
      node.positionalParameters[i].accept(this);
      first = false;
    }
    if (node.positionalParameters.length > node.requiredParameterCount) {
      if (node.requiredParameterCount > 0) result.add(", ");
      result.add("[");
      first = true;
      for (int i = node.requiredParameterCount;
          i < node.positionalParameters.length;
          i++) {
        if (!first) result.add(", ");
        node.positionalParameters[i].accept(this);
        first = false;
      }
      result.add("]");
    }
    if (node.namedParameters.isNotEmpty) {
      if (node.positionalParameters.isNotEmpty) result.add(", ");
      result.add("{");
      first = true;
      for (int i = 0; i < node.namedParameters.length; i++) {
        if (!first) result.add(", ");
        node.namedParameters[i].type.accept(this);
        result.add(" ${node.namedParameters[i].name}");
        first = false;
      }
      result.add("}");
    }
    result.add(")");
    addNullability(node.nullability);
  }

  void visitInterfaceType(InterfaceType node) {
    Class classNode = node.classNode;
    result.add(nameForEntity(
        classNode,
        classNode.name,
        classNode.enclosingLibrary.importUri,
        classNode.enclosingLibrary.fileUri));
    if (node.typeArguments.isNotEmpty) {
      result.add("<");
      bool first = true;
      for (DartType typeArg in node.typeArguments) {
        if (!first) result.add(", ");
        typeArg.accept(this);
        first = false;
      }
      result.add(">");
    }
    addNullability(node.nullability);
  }

  void visitFutureOrType(FutureOrType node) {
    result.add("FutureOr<");
    node.typeArgument.accept(this);
    result.add(">");
    addNullability(node.declaredNullability);
  }

  void defaultConstant(Constant node) {}

  void visitNullConstant(NullConstant node) {
    result.add('${node.value}');
  }

  void visitBoolConstant(BoolConstant node) {
    result.add('${node.value}');
  }

  void visitIntConstant(IntConstant node) {
    result.add('${node.value}');
  }

  void visitDoubleConstant(DoubleConstant node) {
    result.add('${node.value}');
  }

  void visitSymbolConstant(SymbolConstant node) {
    String text = node.libraryReference != null
        ? '#${node.libraryReference.asLibrary.importUri}::${node.name}'
        : '#${node.name}';
    result.add(text);
  }

  void visitStringConstant(StringConstant node) {
    result.add(json.encode(node.value));
  }

  void visitInstanceConstant(InstanceConstant node) {
    new InterfaceType(node.classNode, Nullability.legacy, node.typeArguments)
        .accept(this);
    result.add(" {");
    bool first = true;
    for (Field field in node.classNode.fields) {
      if (field.isStatic) continue;
      if (!first) result.add(", ");
      result.add("${field.name}: ");
      node.fieldValues[field.getterReference].accept(this);
      first = false;
    }
    result.add("}");
  }

  void visitListConstant(ListConstant node) {
    result.add("<");
    node.typeArgument.accept(this);
    result.add(">[");
    bool first = true;
    for (Constant constant in node.entries) {
      if (!first) result.add(", ");
      constant.accept(this);
      first = false;
    }
    result.add("]");
  }

  void visitSetConstant(SetConstant node) {
    result.add("<");
    node.typeArgument.accept(this);
    result.add(">{");
    bool first = true;
    for (Constant constant in node.entries) {
      if (!first) result.add(", ");
      constant.accept(this);
      first = false;
    }
    result.add("}");
  }

  void visitMapConstant(MapConstant node) {
    result.add("<");
    node.keyType.accept(this);
    result.add(", ");
    node.valueType.accept(this);
    result.add(">{");
    bool first = true;
    for (ConstantMapEntry entry in node.entries) {
      if (!first) result.add(", ");
      entry.key.accept(this);
      result.add(": ");
      entry.value.accept(this);
      first = false;
    }
    result.add("}");
  }

  void visitTearOffConstant(TearOffConstant node) {
    Procedure procedure = node.procedure;
    Class classNode = procedure.enclosingClass;
    if (classNode != null) {
      result.add(nameForEntity(
          classNode,
          classNode.name,
          classNode.enclosingLibrary.importUri,
          classNode.enclosingLibrary.fileUri));
      result.add(".");
    }
    result.add(procedure.name.text);
  }

  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    node.tearOffConstant.accept(this);
    if (node.types.isNotEmpty) {
      result.add("<");
      bool first = true;
      for (DartType typeArg in node.types) {
        if (!first) result.add(", ");
        typeArg.accept(this);
        first = false;
      }
      result.add(">");
    }
  }

  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    node.type.accept(this);
  }

  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    unsupported('printing unevaluated constants', -1, null);
  }
}

final Uri unknownUri = Uri.parse("unknown");

class LabeledNode {
  final TreeNode node;
  final TypeLabeler typeLabeler;
  final String name;
  final Uri importUri;
  final Uri fileUri;

  LabeledNode(
      this.node, this.name, this.importUri, this.fileUri, this.typeLabeler);

  String toString() {
    List<LabeledNode> entityForName = typeLabeler.nameMap[name];
    if (entityForName.length == 1) {
      return name;
    }
    return "$name/*${entityForName.indexOf(this) + 1}*/";
  }

  String get originMessage {
    if (importUri.scheme == 'dart' && importUri.path == 'core') {
      if (node is Class && denylistedCoreClasses.contains(name)) {
        // Denylisted core class. Only print if ambiguous.
        List<LabeledNode> entityForName = typeLabeler.nameMap[name];
        if (entityForName.length == 1) {
          return "";
        }
      }
    }
    if (importUri == unknownUri || node is! Class) {
      // We don't know where it comes from and/or it's not a class.
      // Only print if ambiguous.
      List<LabeledNode> entityForName = typeLabeler.nameMap[name];
      if (entityForName.length == 1) {
        return "";
      }
    }
    Message message = (importUri == fileUri || importUri.scheme == 'dart')
        ? templateTypeOrigin.withArguments(toString(), importUri)
        : templateTypeOriginWithFileUri.withArguments(
            toString(), importUri, fileUri);
    return "\n - " + message.message;
  }
}
