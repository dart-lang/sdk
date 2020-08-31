// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.value_class;

import '../ast.dart';
import '../kernel.dart';
import '../core_types.dart' show CoreTypes;

void transformComponent(Component node, CoreTypes coreTypes) {
  for (Library library in node.libraries) {
    for (Class cls in library.classes) {
      if (isValueClass(cls)) {
        transformValueClass(cls, coreTypes);
      }
    }
  }
}

void transformValueClass(Class cls, CoreTypes coreTypes) {
  addConstructor(cls, coreTypes);
  // addEqualsOperator(cls, coreTypes);
  // addHashCode(cls, coreTypes);
  // addCopyWith(cls);
}

void addConstructor(Class cls, CoreTypes coreTypes) {
  Constructor superConstructor = null;
  for (Constructor constructor in cls.superclass.constructors) {
    if (constructor.name.name == "") {
      superConstructor = constructor;
    }
  }
  Constructor syntheticConstructor = null;
  for (Constructor constructor in cls.constructors) {
    if (constructor.isSynthetic) {
      syntheticConstructor = constructor;
    }
  }

  List<VariableDeclaration> superParameters = superConstructor
      .function.namedParameters
      .map<VariableDeclaration>((e) => VariableDeclaration(e.name, type: e.type)
        ..parent = syntheticConstructor.function)
      .toList();
  Map<String, VariableDeclaration> ownFields = Map.fromIterable(cls.fields,
      key: (f) => f.name.name,
      value: (f) =>
          VariableDeclaration(f.name.name, type: f.type, isRequired: true)
            ..parent = syntheticConstructor.function);

  List<Initializer> initializersConstructor = cls.fields
      .map<Initializer>((f) =>
          FieldInitializer(f, VariableGet(ownFields[f.name.name]))
            ..parent = syntheticConstructor)
      .toList();

  initializersConstructor.add(SuperInitializer(superConstructor,
      Arguments(superParameters.map((f) => VariableGet(f)).toList()))
    ..parent = syntheticConstructor);

  syntheticConstructor.function.namedParameters
    ..clear()
    ..addAll(ownFields.values)
    ..addAll(superParameters);
  syntheticConstructor.initializers = initializersConstructor;

  int valueClassAnnotationIndex;
  for (int annotationIndex = 0;
      annotationIndex < cls.annotations.length;
      annotationIndex++) {
    Expression annotation = cls.annotations[annotationIndex];
    if (annotation is ConstantExpression &&
        annotation.constant is StringConstant) {
      StringConstant constant = annotation.constant;
      if (constant.value == 'valueClass') {
        valueClassAnnotationIndex = annotationIndex;
      }
    }
  }
  cls.annotations.removeAt(valueClassAnnotationIndex);
}
/*

void addEqualsOperator(Class cls, CoreTypes coreTypes) {
  Map<String, VariableDeclaration> environment = Map.fromIterable(cls.fields,
      key: (f) => f.name.name,
      value: (f) => VariableDeclaration(f.name.name, type: f.type));

  VariableDeclaration other = VariableDeclaration("other");

  var retType = cls.enclosingLibrary.isNonNullableByDefault
      ? coreTypes.boolNonNullableRawType
      : coreTypes.boolLegacyRawType;
  var myType = coreTypes.thisInterfaceType(cls, Nullability.nonNullable);

  cls.addMember(Procedure(
      Name("=="),
      ProcedureKind.Operator,
      FunctionNode(
          ReturnStatement(ConditionalExpression(
              IsExpression(VariableGet(other), myType),
              cls.fields
                  .map((f) => MethodInvocation(
                      PropertyGet(ThisExpression(), f.name, f),
                      Name('=='),
                      Arguments([
                        PropertyGet(VariableGet(other, myType), f.name, f)
                      ])))
                  .toList()
                  .fold(
                      BoolLiteral(true),
                      (previousValue, element) =>
                          LogicalExpression(previousValue, '&&', element)),
              BoolLiteral(false),
              retType)),
          returnType: retType,
          positionalParameters: [other])));
}

void addHashCode(Class cls, CoreTypes coreTypes) {
  Map<String, VariableDeclaration> environment = Map.fromIterable(cls.fields,
      key: (f) => f.name.name,
      value: (f) => VariableDeclaration(f.name.name, type: f.type));

  VariableDeclaration other = VariableDeclaration("other");

  var retType = cls.enclosingLibrary.isNonNullableByDefault
      ? coreTypes.boolNonNullableRawType
      : coreTypes.boolLegacyRawType;

  cls.addMember(Procedure(
      Name("hashCode"),
      ProcedureKind.Getter,
      FunctionNode(ReturnStatement(cls.fields
          .map((f) => DirectPropertyGet(
              VariableGet(environment[f.name.name]),
              Procedure(Name("hashCode"), ProcedureKind.Getter,
                  null) // TODO(jlcontreras): Add ref to the real hashCode getter, dont create a new one
              ))
          .toList()
          .fold(
              IntLiteral(0),
              (previousValue, element) => MethodInvocation(
                  previousValue, Name("*"), Arguments([element])))))));
}

void addCopyWith(Class cls) {
  Map<String, VariableDeclaration> environment = Map.fromIterable(cls.fields,
      key: (f) => f.name.name,
      value: (f) => VariableDeclaration(f.name.name, type: f.type));

  Constructor syntheticConstructor = null;
  for (Constructor constructor in cls.constructors) {
    if (constructor.isSynthetic) {
      syntheticConstructor = constructor;
    }
  }

  cls.addMember(Procedure(
      Name("copyWith"),
      ProcedureKind.Method,
      FunctionNode(
          ReturnStatement(ConstructorInvocation(
              syntheticConstructor,
              Arguments(cls.fields
                  .map((f) => ConditionalExpression(
                      MethodInvocation(VariableGet(environment[f.name.name]),
                          Name('=='), Arguments([NullLiteral()])),
                      PropertyGet(ThisExpression(), f.name, f),
                      VariableGet(environment[f.name.name]),
                      f.type))
                  .toList()))),
          namedParameters:
              cls.fields.map((f) => environment[f.name.name]).toList())));
}
*/

bool isValueClass(Class cls) {
  for (Expression annotation in cls.annotations) {
    if (annotation is ConstantExpression &&
        annotation.constant is StringConstant) {
      StringConstant constant = annotation.constant;
      if (constant.value == 'valueClass') {
        return true;
      }
    }
  }
  return false;
}
