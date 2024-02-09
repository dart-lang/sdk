// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';

String constantToText(DartTypes dartTypes, ConstantValue constant) {
  StringBuffer sb = StringBuffer();
  ConstantToTextVisitor(dartTypes).visit(constant, sb);
  return sb.toString();
}

class DartTypeToTextVisitor extends DartTypeVisitor<void, StringBuffer> {
  String visitList(Iterable<DartType> types, StringBuffer sb,
      [String comma = '']) {
    for (DartType type in types) {
      sb.write(comma);
      visit(type, sb);
      comma = ',';
    }
    return comma;
  }

  @override
  void visitLegacyType(LegacyType type, StringBuffer sb) {
    bool wrapFunction = type.baseType is FunctionType;
    if (wrapFunction) sb.write('(');
    visit(type.baseType, sb);
    if (wrapFunction) sb.write(')');
    sb.write('*');
  }

  @override
  void visitNullableType(NullableType type, StringBuffer sb) {
    bool wrapFunction = type.baseType is FunctionType;
    if (wrapFunction) sb.write('(');
    visit(type.baseType, sb);
    if (wrapFunction) sb.write(')');
    sb.write('?');
  }

  @override
  void visitNeverType(NeverType type, StringBuffer sb) {
    sb.write('Never');
  }

  @override
  void visitVoidType(VoidType type, StringBuffer sb) {
    sb.write('void');
  }

  @override
  void visitDynamicType(DynamicType type, StringBuffer sb) {
    sb.write('dynamic');
  }

  @override
  void visitErasedType(ErasedType type, StringBuffer sb) {
    sb.write('erased');
  }

  @override
  void visitAnyType(AnyType type, StringBuffer sb) {
    sb.write('any');
  }

  @override
  void visitTypeVariableType(TypeVariableType type, StringBuffer sb) {
    sb.write(type.element.name);
  }

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, StringBuffer sb) {
    sb.write(type.index);
  }

  @override
  void visitFunctionType(FunctionType type, StringBuffer sb) {
    sb.write('(');
    String comma = visitList(type.parameterTypes, sb);
    if (type.optionalParameterTypes.isNotEmpty) {
      sb.write(comma);
      sb.write('[');
      visitList(type.optionalParameterTypes, sb);
      sb.write(']');
      comma = ',';
    }
    if (type.namedParameters.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      comma = '';
      for (int index = 0; index < type.namedParameters.length; index++) {
        sb.write(comma);
        visit(type.namedParameterTypes[index], sb);
        sb.write(' ');
        sb.write(type.namedParameters[index]);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')->');
    visit(type.returnType, sb);
  }

  @override
  void visitInterfaceType(InterfaceType type, StringBuffer sb) {
    sb.write(type.element.name);
    if (type.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(type.typeArguments, sb);
      sb.write('>');
    }
  }

  @override
  void visitRecordType(RecordType type, StringBuffer sb) {
    throw UnimplementedError();
  }

  @override
  void visitFutureOrType(FutureOrType type, StringBuffer sb) {
    sb.write('FutureOr<');
    visit(type.typeArgument, sb);
    sb.write('>');
  }
}

class ConstantToTextVisitor
    implements ConstantValueVisitor<void, StringBuffer> {
  final DartTypes _dartTypes;
  final DartTypeToTextVisitor typeToText = DartTypeToTextVisitor();

  ConstantToTextVisitor(this._dartTypes);

  void visit(ConstantValue constant, StringBuffer sb) =>
      constant.accept(this, sb);

  void visitConstants(Iterable<ConstantValue> constants, StringBuffer sb) {
    String comma = '';
    for (ConstantValue constant in constants) {
      sb.write(comma);
      visit(constant, sb);
      comma = ',';
    }
  }

  @override
  void visitFunction(FunctionConstantValue constant, StringBuffer sb) {
    sb.write('Function(${constant.element.name})');
  }

  @override
  void visitNull(NullConstantValue constant, StringBuffer sb) {
    sb.write('Null()');
  }

  @override
  void visitInt(IntConstantValue constant, StringBuffer sb) {
    sb.write('Int(${constant.intValue})');
  }

  @override
  void visitDouble(DoubleConstantValue constant, StringBuffer sb) {
    sb.write('Double(${constant.doubleValue})');
  }

  @override
  void visitBool(BoolConstantValue constant, StringBuffer sb) {
    sb.write('Bool(${constant.boolValue})');
  }

  @override
  void visitString(StringConstantValue constant, StringBuffer sb) {
    sb.write('String(${constant.stringValue})');
  }

  @override
  void visitList(ListConstantValue constant, StringBuffer sb) {
    sb.write('List<');
    typeToText.visitList(constant.type.typeArguments, sb);
    sb.write('>(');
    visitConstants(constant.entries, sb);
    sb.write(')');
  }

  @override
  void visitSet(SetConstantValue constant, StringBuffer sb) {
    sb.write('Set<');
    typeToText.visitList(constant.type.typeArguments, sb);
    sb.write('>(');
    visitConstants(constant.values, sb);
    sb.write(')');
  }

  @override
  void visitMap(MapConstantValue constant, StringBuffer sb) {
    sb.write('Map<');
    typeToText.visitList(constant.type.typeArguments, sb);
    sb.write('>(');
    for (int index = 0; index < constant.keys.length; index++) {
      if (index > 0) {
        sb.write(',');
      }
      visit(constant.keys[index], sb);
      sb.write(':');
      visit(constant.values[index], sb);
    }
    sb.write(')');
  }

  @override
  void visitConstructed(ConstructedConstantValue constant, StringBuffer sb) {
    sb.write('Instance(');
    typeToText.visit(constant.type, sb);
    if (constant.fields.isNotEmpty) {
      sb.write(',{');
      String comma = '';
      constant.fields.forEach((FieldEntity field, ConstantValue value) {
        sb.write(comma);
        sb.write(field.name);
        sb.write(':');
        visit(value, sb);
        comma = ',';
      });
    }
    sb.write(')');
  }

  @override
  void visitRecord(RecordConstantValue constant, StringBuffer sb) {
    sb.write('Record(');
    final shape = constant.shape;
    final values = constant.values;
    for (int i = 0; i < values.length; i++) {
      if (i > 0) sb.write(',');
      if (i >= shape.positionalFieldCount) {
        sb.write(shape.fieldNames[i - shape.positionalFieldCount]);
        sb.write(':');
      }
      visit(values[i], sb);
    }
    sb.write(')');
  }

  @override
  void visitType(TypeConstantValue constant, StringBuffer sb) {
    sb.write('TypeLiteral(');
    typeToText.visit(constant.representedType, sb);
    sb.write(')');
  }

  void _unsupported(ConstantValue constant) => throw UnsupportedError(
      'Unsupported constant value: ${constant.toStructuredText(_dartTypes)}');

  @override
  void visitInterceptor(InterceptorConstantValue constant, StringBuffer sb) =>
      _unsupported(constant);

  @override
  void visitDummyInterceptor(
          DummyInterceptorConstantValue constant, StringBuffer sb) =>
      _unsupported(constant);

  @override
  void visitLateSentinel(LateSentinelConstantValue constant, StringBuffer sb) =>
      _unsupported(constant);

  @override
  void visitUnreachable(UnreachableConstantValue constant, StringBuffer sb) =>
      _unsupported(constant);

  @override
  void visitJsName(JsNameConstantValue constant, StringBuffer sb) =>
      _unsupported(constant);

  @override
  void visitDeferredGlobal(
          DeferredGlobalConstantValue constant, StringBuffer sb) =>
      _unsupported(constant);

  @override
  void visitInstantiation(
      InstantiationConstantValue constant, StringBuffer sb) {
    sb.write('Instantiation(');
    sb.write(constant.function.element.name);
    sb.write('<');
    typeToText.visitList(constant.typeArguments, sb);
    sb.write('>)');
  }

  @override
  void visitJavaScriptObject(
      JavaScriptObjectConstantValue constant, StringBuffer sb) {
    sb.write('JavaScriptObject({');
    for (int index = 0; index < constant.keys.length; index++) {
      if (index > 0) {
        sb.write(',');
      }
      visit(constant.keys[index], sb);
      sb.write(':');
      visit(constant.values[index], sb);
    }
    sb.write('})');
  }
}
