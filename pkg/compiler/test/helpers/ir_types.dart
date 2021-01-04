// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:kernel/ast.dart' as ir;

class TypeTextVisitor implements ir.DartTypeVisitor1<void, StringBuffer> {
  const TypeTextVisitor();

  @override
  void defaultDartType(ir.DartType node, StringBuffer sb) {
    throw new UnsupportedError("Unhandled type $node (${node.runtimeType}).");
  }

  void writeType(ir.DartType type, StringBuffer sb) {
    type.accept1(this, sb);
  }

  void _writeTypes(Iterable<ir.DartType> types, StringBuffer sb) {
    String comma = '';
    for (ir.DartType type in types) {
      sb.write(comma);
      writeType(type, sb);
      comma = ',';
    }
  }

  void _writeTypeArguments(
      Iterable<ir.DartType> typeArguments, StringBuffer sb) {
    if (typeArguments.isNotEmpty) {
      sb.write('<');
      _writeTypes(typeArguments, sb);
      sb.write('>');
    }
  }

  @override
  void visitTypedefType(ir.TypedefType node, StringBuffer sb) {
    sb.write(node.typedefNode.name);
    _writeTypeArguments(node.typeArguments, sb);
  }

  @override
  void visitTypeParameterType(ir.TypeParameterType node, StringBuffer sb) {
    sb.write(node.parameter.name);
  }

  @override
  void visitFunctionType(ir.FunctionType node, StringBuffer sb) {
    writeType(node.returnType, sb);
    sb.write(' Function');
    if (node.typeParameters.isNotEmpty) {
      sb.write('<');
      String comma = '';
      for (ir.TypeParameter typeParameter in node.typeParameters) {
        sb.write(comma);
        sb.write(typeParameter.name);
        if (typeParameter is! ir.DynamicType) {
          sb.write(' extends ');
          writeType(typeParameter.bound, sb);
        }
        comma = ',';
      }
      sb.write('>');
    }
    sb.write('(');
    _writeTypes(
        node.positionalParameters.take(node.requiredParameterCount), sb);
    if (node.requiredParameterCount < node.positionalParameters.length) {
      if (node.requiredParameterCount > 0) {
        sb.write(',');
      }
      _writeTypes(
          node.positionalParameters.skip(node.requiredParameterCount), sb);
    }
    if (node.namedParameters.isNotEmpty) {
      if (node.positionalParameters.isNotEmpty) {
        sb.write(',');
      }
      String comma = '';
      for (ir.NamedType namedType in node.namedParameters) {
        sb.write(comma);
        sb.write(namedType.name);
        sb.write(': ');
        writeType(namedType.type, sb);
        comma = ',';
      }
    }
    sb.write(')');
  }

  @override
  void visitInterfaceType(ir.InterfaceType node, StringBuffer sb) {
    sb.write(node.classNode.name);
    _writeTypeArguments(node.typeArguments, sb);
  }

  @override
  void visitFutureOrType(ir.FutureOrType node, StringBuffer sb) {
    sb.write('FutureOr<');
    writeType(node.typeArgument, sb);
    sb.write('>');
  }

  @override
  void visitBottomType(ir.BottomType node, StringBuffer sb) {
    sb.write('<bottom>');
  }

  @override
  void visitNeverType(ir.NeverType node, StringBuffer sb) {
    sb.write('Never');
  }

  @override
  void visitNullType(ir.NullType node, StringBuffer sb) {
    sb.write('Null');
  }

  @override
  void visitVoidType(ir.VoidType node, StringBuffer sb) {
    sb.write('void');
  }

  @override
  void visitDynamicType(ir.DynamicType node, StringBuffer sb) {
    sb.write('dynamic');
  }

  @override
  void visitInvalidType(ir.InvalidType node, StringBuffer sb) {
    sb.write('<invalid>');
  }
}

String typeToText(ir.DartType type) {
  StringBuffer sb = new StringBuffer();
  const TypeTextVisitor().writeType(type, sb);
  return sb.toString();
}

String typesToText(Iterable<ir.DartType> types) {
  StringBuffer sb = new StringBuffer();
  String comma = '';
  for (ir.DartType type in types) {
    sb.write(comma);
    const TypeTextVisitor().writeType(type, sb);
    comma = ',';
  }
  return sb.toString();
}
