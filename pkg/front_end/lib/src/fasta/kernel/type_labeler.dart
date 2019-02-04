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
        InvalidType,
        InstanceConstant,
        IntConstant,
        InterfaceType,
        ListConstant,
        MapConstant,
        NullConstant,
        PartialInstantiationConstant,
        Procedure,
        StringConstant,
        SymbolConstant,
        TearOffConstant,
        TypedefType,
        TypeLiteralConstant,
        TypeParameter,
        TypeParameterType,
        UnevaluatedConstant,
        VoidType;

import 'package:kernel/visitor.dart' show ConstantVisitor, DartTypeVisitor;

import '../blacklisted_classes.dart' show blacklistedCoreClasses;

import '../fasta_codes.dart'
    show Message, templateTypeOrigin, templateTypeOriginWithFileUri;

import '../problems.dart' show unsupported;

/// A pretty-printer for Kernel types and constants with the ability to label
/// raw types with numeric markers in Dart comments (e.g. `/*1*/`) to
/// distinguish different types with the same name. This is used in diagnostic
/// messages to indicate the origins of types occurring in the message.
class TypeLabeler implements DartTypeVisitor<void>, ConstantVisitor<void> {
  List<LabeledClassName> names = <LabeledClassName>[];
  Map<String, List<LabeledClassName>> nameMap =
      <String, List<LabeledClassName>>{};

  List<Object> result;

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
    for (LabeledClassName name in names) {
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

  LabeledClassName nameForClass(Class classNode) {
    List<LabeledClassName> classesForName = nameMap[classNode.name];
    if (classesForName == null) {
      // First encountered class with this name
      LabeledClassName name = new LabeledClassName(classNode, this);
      names.add(name);
      nameMap[classNode.name] = [name];
      return name;
    } else {
      for (LabeledClassName classForName in classesForName) {
        if (classForName.classNode == classNode) {
          // Previously encountered class
          return classForName;
        }
      }
      // New class with name that was previously encountered
      LabeledClassName name = new LabeledClassName(classNode, this);
      names.add(name);
      classesForName.add(name);
      return name;
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

  void visitDynamicType(DynamicType node) {
    result.add("dynamic");
  }

  void visitVoidType(VoidType node) {
    result.add("void");
  }

  void visitTypeParameterType(TypeParameterType node) {
    result.add(node.parameter.name);
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
  }

  void visitInterfaceType(InterfaceType node) {
    result.add(nameForClass(node.classNode));
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
  }

  void defaultConstant(Constant node) {}

  void visitNullConstant(NullConstant node) {
    result.add(node);
  }

  void visitBoolConstant(BoolConstant node) {
    result.add(node);
  }

  void visitIntConstant(IntConstant node) {
    result.add(node);
  }

  void visitDoubleConstant(DoubleConstant node) {
    result.add(node);
  }

  void visitSymbolConstant(SymbolConstant node) {
    result.add(node);
  }

  void visitStringConstant(StringConstant node) {
    result.add(json.encode(node.value));
  }

  void visitInstanceConstant(InstanceConstant node) {
    new InterfaceType(node.classNode, node.typeArguments).accept(this);
    result.add(" {");
    bool first = true;
    for (Field field in node.classNode.fields) {
      if (field.isStatic) continue;
      if (!first) result.add(", ");
      result.add("${field.name}: ");
      node.fieldValues[field.reference].accept(this);
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
      result.add(nameForClass(classNode));
      result.add(".");
    }
    result.add(procedure.name.name);
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

class LabeledClassName {
  Class classNode;
  TypeLabeler typeLabeler;

  LabeledClassName(this.classNode, this.typeLabeler);

  String toString() {
    String name = classNode.name;
    List<LabeledClassName> classesForName = typeLabeler.nameMap[name];
    if (classesForName.length == 1) {
      return name;
    }
    return "$name/*${classesForName.indexOf(this) + 1}*/";
  }

  String get originMessage {
    Uri importUri = classNode.enclosingLibrary.importUri;
    if (importUri.scheme == 'dart' && importUri.path == 'core') {
      String name = classNode.name;
      if (blacklistedCoreClasses.contains(name)) {
        // Blacklisted core class. Only print if ambiguous.
        List<LabeledClassName> classesForName = typeLabeler.nameMap[name];
        if (classesForName.length == 1) {
          return "";
        }
      }
    }
    Uri fileUri = classNode.enclosingLibrary.fileUri;
    Message message = (importUri == fileUri || importUri.scheme == 'dart')
        ? templateTypeOrigin.withArguments(toString(), importUri)
        : templateTypeOriginWithFileUri.withArguments(
            toString(), importUri, fileUri);
    return "\n - " + message.message;
  }
}
