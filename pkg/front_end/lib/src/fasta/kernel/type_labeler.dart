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
        VoidType;

import 'package:kernel/visitor.dart' show ConstantVisitor, DartTypeVisitor;

import '../blacklisted_classes.dart' show blacklistedCoreClasses;

import '../fasta_codes.dart'
    show Message, templateTypeOrigin, templateTypeOriginWithFileUri;

/// A pretty-printer for Kernel types and constants with the ability to label
/// raw types with numeric markers in Dart comments (e.g. `/*1*/`) to
/// distinguish different types with the same name. This is used in diagnostic
/// messages to indicate the origins of types occurring in the message.
class TypeLabeler
    implements DartTypeVisitor<List<Object>>, ConstantVisitor<List<Object>> {
  List<LabeledClassName> names = <LabeledClassName>[];
  Map<String, List<LabeledClassName>> nameMap =
      <String, List<LabeledClassName>>{};

  /// Pretty-print a type.
  /// When all types and constants appearing in the same message have been
  /// pretty-printed, the returned list can be converted to its string
  /// representation (with labels on duplicated names) by the `join()` method.
  List<Object> labelType(DartType type) {
    // TODO(askesc): Remove null check when we are completely null clean here.
    if (type == null) return ["null-type"];
    return type.accept(this);
  }

  /// Pretty-print a constant.
  /// When all types and constants appearing in the same message have been
  /// pretty-printed, the returned list can be converted to its string
  /// representation (with labels on duplicated names) by the `join()` method.
  List<Object> labelConstant(Constant constant) {
    // TODO(askesc): Remove null check when we are completely null clean here.
    if (constant == null) return ["null-constant"];
    return constant.accept(this);
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

  List<Object> defaultDartType(DartType type) => null;
  List<Object> visitTypedefType(TypedefType node) => null;

  // TODO(askesc): Throw internal error if InvalidType appears in diagnostics.
  List<Object> visitInvalidType(InvalidType node) => ["invalid-type"];

  // TODO(askesc): Throw internal error if BottomType appears in diagnostics.
  List<Object> visitBottomType(BottomType node) => ["bottom-type"];

  List<Object> visitDynamicType(DynamicType node) => ["dynamic"];
  List<Object> visitVoidType(VoidType node) => ["void"];
  List<Object> visitTypeParameterType(TypeParameterType node) =>
      [node.parameter.name];

  List<Object> visitFunctionType(FunctionType node) {
    List<Object> result = node.returnType.accept(this);
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
          result.addAll(param.bound.accept(this));
        }
      }
      result.add(">");
    }
    result.add("(");
    bool first = true;
    for (int i = 0; i < node.requiredParameterCount; i++) {
      if (!first) result.add(", ");
      result.addAll(node.positionalParameters[i].accept(this));
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
        result.addAll(node.positionalParameters[i].accept(this));
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
        result.addAll(node.namedParameters[i].type.accept(this));
        result.add(" ${node.namedParameters[i].name}");
        first = false;
      }
      result.add("}");
    }
    result.add(")");
    return result;
  }

  List<Object> visitInterfaceType(InterfaceType node) {
    List<Object> result = [nameForClass(node.classNode)];
    if (node.typeArguments.isNotEmpty) {
      result.add("<");
      bool first = true;
      for (DartType typeArg in node.typeArguments) {
        if (!first) result.add(", ");
        result.addAll(typeArg.accept(this));
        first = false;
      }
      result.add(">");
    }
    return result;
  }

  List<Object> defaultConstant(Constant node) => null;

  List<Object> visitNullConstant(NullConstant node) => [node];
  List<Object> visitBoolConstant(BoolConstant node) => [node];
  List<Object> visitIntConstant(IntConstant node) => [node];
  List<Object> visitDoubleConstant(DoubleConstant node) => [node];
  List<Object> visitSymbolConstant(SymbolConstant node) => [node];
  List<Object> visitStringConstant(StringConstant node) =>
      [json.encode(node.value)];

  List<Object> visitInstanceConstant(InstanceConstant node) {
    List<Object> result =
        new InterfaceType(node.klass, node.typeArguments).accept(this);
    result.add(" {");
    bool first = true;
    for (Field field in node.klass.fields) {
      if (!first) result.add(", ");
      result.add("${field.name}: ");
      result.addAll(node.fieldValues[field.reference].accept(this));
      first = false;
    }
    result.add("}");
    return result;
  }

  List<Object> visitListConstant(ListConstant node) {
    List<Object> result = ["<"];
    result.addAll(node.typeArgument.accept(this));
    result.add(">[");
    bool first = true;
    for (Constant constant in node.entries) {
      if (!first) result.add(", ");
      result.addAll(constant.accept(this));
      first = false;
    }
    result.add("]");
    return result;
  }

  List<Object> visitMapConstant(MapConstant node) {
    List<Object> result = ["<"];
    result.addAll(node.keyType.accept(this));
    result.add(", ");
    result.addAll(node.valueType.accept(this));
    result.add(">{");
    bool first = true;
    for (ConstantMapEntry entry in node.entries) {
      if (!first) result.add(", ");
      result.addAll(entry.key.accept(this));
      result.add(": ");
      result.addAll(entry.value.accept(this));
      first = false;
    }
    result.add("}");
    return result;
  }

  List<Object> visitTearOffConstant(TearOffConstant node) {
    List<Object> result = [];
    Procedure procedure = node.procedure;
    Class classNode = procedure.enclosingClass;
    if (classNode != null) {
      result.add(nameForClass(classNode));
      result.add(".");
    }
    result.add(procedure.name.name);
    return result;
  }

  List<Object> visitPartialInstantiationConstant(
      PartialInstantiationConstant node) {
    List<Object> result = node.tearOffConstant.accept(this);
    if (node.types.isNotEmpty) {
      result.add("<");
      bool first = true;
      for (DartType typeArg in node.types) {
        if (!first) result.add(", ");
        result.addAll(typeArg.accept(this));
        first = false;
      }
      result.add(">");
    }
    return result;
  }

  List<Object> visitTypeLiteralConstant(TypeLiteralConstant node) {
    return node.type.accept(this);
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
