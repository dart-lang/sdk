// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper methods to use on annotated tests.

import 'package:kernel/ast.dart';

/// Returns a canonical simple name for [member].
String getMemberName(Member member) {
  if (member is Procedure && member.isSetter) return '${member.name.name}=';
  return member.name.name;
}

/// Returns the enclosing [Member] for [node].
Member getEnclosingMember(TreeNode node) {
  while (node is! Member) {
    node = node.parent;
  }
  return node;
}

/// Finds the first [Library] in [component] with the given import [uri].
///
/// If [required] is `true` an error is thrown if no library was found.
Library lookupLibrary(Component component, Uri uri, {bool required: true}) {
  return component.libraries
      .firstWhere((Library library) => library.importUri == uri, orElse: () {
    if (required) {
      throw new ArgumentError("Library '$uri' not found.");
    }
    return null;
  });
}

/// Finds the first [Class] in [component] with the given [className].
///
/// If [required] is `true` an error is thrown if no class was found.
Class lookupClass(Library library, String className, {bool required: true}) {
  return library.classes.firstWhere((Class cls) => cls.name == className,
      orElse: () {
    if (required) {
      throw new ArgumentError("Class '$className' not found in '$library'.");
    }
    return null;
  });
}

/// Finds the first [Member] in [library] with the given canonical simple
/// [memberName] as computed by [getMemberName].
///
/// If [required] is `true` an error is thrown if no member was found.
Member lookupLibraryMember(Library library, String memberName,
    {bool required: true}) {
  return library.members.firstWhere(
      (Member member) => getMemberName(member) == memberName, orElse: () {
    if (required) {
      throw new ArgumentError("Member '$memberName' not found in '$library'.");
    }
    return null;
  });
}

/// Finds the first [Member] in [cls] with the given canonical simple
/// [memberName] as computed by [getMemberName].
///
/// If [required] is `true` an error is thrown if no member was found.
Member lookupClassMember(Class cls, String memberName, {bool required: true}) {
  return cls.members.firstWhere(
      (Member member) => getMemberName(member) == memberName, orElse: () {
    if (required) {
      throw new ArgumentError("Member '$memberName' not found in '$cls'.");
    }
    return null;
  });
}

/// Returns a textual representation of the constant [node] to be used in
/// testing.
String constantToText(Constant node) {
  StringBuffer sb = new StringBuffer();
  new ConstantToTextVisitor(sb).visit(node);
  return sb.toString();
}

/// Returns a textual representation of the type [node] to be used in
/// testing.
String typeToText(DartType node) {
  StringBuffer sb = new StringBuffer();
  new DartTypeToTextVisitor(sb).visit(node);
  return sb.toString();
}

class ConstantToTextVisitor implements ConstantVisitor<void> {
  final StringBuffer sb;
  final DartTypeToTextVisitor typeToText;

  ConstantToTextVisitor(this.sb) : typeToText = new DartTypeToTextVisitor(sb);

  void visit(Constant node) => node.accept(this);

  void visitList(Iterable<Constant> nodes) {
    String comma = '';
    for (Constant node in nodes) {
      sb.write(comma);
      visit(node);
      comma = ',';
    }
  }

  void defaultConstant(Constant node) => throw UnimplementedError(
      'Unexpected constant $node (${node.runtimeType})');

  void visitNullConstant(NullConstant node) {
    sb.write('Null()');
  }

  void visitBoolConstant(BoolConstant node) {
    sb.write('Bool(${node.value})');
  }

  void visitIntConstant(IntConstant node) {
    sb.write('Int(${node.value})');
  }

  void visitDoubleConstant(DoubleConstant node) {
    sb.write('Double(${node.value})');
  }

  void visitStringConstant(StringConstant node) {
    sb.write('String(${node.value})');
  }

  void visitSymbolConstant(SymbolConstant node) {
    sb.write('Symbol(${node.name})');
  }

  void visitMapConstant(MapConstant node) {
    sb.write('Map<');
    typeToText.visit(node.keyType);
    sb.write(',');
    typeToText.visit(node.valueType);
    sb.write('>(');
    String comma = '';
    for (ConstantMapEntry entry in node.entries) {
      sb.write(comma);
      entry.key.accept(this);
      sb.write(':');
      entry.value.accept(this);
      comma = ',';
    }
    sb.write(')');
  }

  void visitListConstant(ListConstant node) {
    sb.write('List<');
    typeToText.visit(node.typeArgument);
    sb.write('>(');
    visitList(node.entries);
    sb.write(')');
  }

  void visitSetConstant(SetConstant node) {
    sb.write('Set<');
    typeToText.visit(node.typeArgument);
    sb.write('>(');
    visitList(node.entries);
    sb.write(')');
  }

  void visitInstanceConstant(InstanceConstant node) {
    sb.write('Instance(');
    sb.write(node.classNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      typeToText.visitList(node.typeArguments);
      sb.write('>');
    }
    if (node.fieldValues.isNotEmpty) {
      sb.write(',{');
      String comma = '';
      for (Reference ref in node.fieldValues.keys) {
        sb.write(comma);
        sb.write(getMemberName(ref.asField));
        sb.write(':');
        visit(node.fieldValues[ref]);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')');
  }

  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    sb.write('Instantiation(');
    sb.write(getMemberName(node.tearOffConstant.procedure));
    sb.write('<');
    typeToText.visitList(node.types);
    sb.write('>)');
  }

  void visitTearOffConstant(TearOffConstant node) {
    sb.write('Function(');
    sb.write(getMemberName(node.procedure));
    sb.write(')');
  }

  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    sb.write('TypeLiteral(');
    typeToText.visit(node.type);
    sb.write(')');
  }

  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    sb.write('Unevaluated()');
  }
}

class DartTypeToTextVisitor implements DartTypeVisitor<void> {
  final StringBuffer sb;

  DartTypeToTextVisitor(this.sb);

  void visit(DartType node) => node.accept(this);

  void visitList(Iterable<DartType> nodes) {
    String comma = '';
    for (DartType node in nodes) {
      sb.write(comma);
      visit(node);
      comma = ',';
    }
  }

  void defaultDartType(DartType node) =>
      throw UnimplementedError('Unexpected type $node (${node.runtimeType})');

  void visitInvalidType(InvalidType node) {
    sb.write('<invalid>');
  }

  void visitDynamicType(DynamicType node) {
    sb.write('dynamic');
  }

  void visitVoidType(VoidType node) {
    sb.write('void');
  }

  void visitBottomType(BottomType node) {
    sb.write('<bottom>');
  }

  void visitInterfaceType(InterfaceType node) {
    sb.write(node.classNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(node.typeArguments);
      sb.write('>');
    }
  }

  void visitFunctionType(FunctionType node) {
    sb.write('(');
    String comma = '';
    visitList(node.positionalParameters.take(node.requiredParameterCount));
    if (node.requiredParameterCount > 0) {
      comma = ',';
    }
    if (node.requiredParameterCount < node.positionalParameters.length) {
      sb.write(comma);
      sb.write('[');
      visitList(node.positionalParameters.skip(node.requiredParameterCount));
      sb.write(']');
      comma = ',';
    }
    if (node.namedParameters.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      comma = '';
      for (NamedType namedParameter in node.namedParameters) {
        sb.write(comma);
        visit(namedParameter.type);
        sb.write(' ');
        sb.write(namedParameter.name);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')->');
    visit(node.returnType);
  }

  void visitTypeParameterType(TypeParameterType node) {
    sb.write(node.parameter.name);
    if (node.promotedBound != null) {
      sb.write(' extends ');
      visit(node.promotedBound);
    }
  }

  void visitTypedefType(TypedefType node) {
    sb.write(node.typedefNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(node.typeArguments);
      sb.write('>');
    }
  }
}
