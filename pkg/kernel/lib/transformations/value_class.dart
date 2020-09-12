// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.value_class;

import '../ast.dart';
import '../kernel.dart';
import '../core_types.dart' show CoreTypes;
import '../class_hierarchy.dart' show ClassHierarchy;
import './scanner.dart';

class ValueClassScanner extends ClassScanner<Null> {
  ValueClassScanner() : super(null);

  bool predicate(Class node) {
    for (Expression annotation in node.annotations) {
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
}

class JenkinsClassScanner extends ClassScanner<Procedure> {
  JenkinsClassScanner(Scanner<Procedure, TreeNode> next) : super(next);

  bool predicate(Class node) {
    return node.name == "JenkinsSmiHash";
  }
}

class HashCombineMethodsScanner extends ProcedureScanner<Null> {
  HashCombineMethodsScanner() : super(null);

  bool predicate(Procedure node) {
    return node.name.name == "combine" || node.name.name == "finish";
  }
}

void transformComponent(
    Component node, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  ValueClassScanner scanner = new ValueClassScanner();
  ScanResult<Class, Null> valueClasses = scanner.scan(node);
  for (Class valueClass in valueClasses.targets.keys) {
    transformValueClass(valueClass, coreTypes, hierarchy);
  }
}

void transformValueClass(
    Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  addConstructor(cls, coreTypes);
  addEqualsOperator(cls, coreTypes, hierarchy);
  addHashCode(cls, coreTypes, hierarchy);
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

void addEqualsOperator(
    Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  for (Procedure procedure in cls.procedures) {
    if (procedure.kind == ProcedureKind.Operator &&
        procedure.name.name == "==") {
      // ==operator is already implemented, spec is to do nothing
      return;
    }
  }
  DartType returnType = cls.enclosingLibrary.isNonNullableByDefault
      ? coreTypes.boolNonNullableRawType
      : coreTypes.boolLegacyRawType;
  DartType myType = coreTypes.thisInterfaceType(cls, Nullability.nonNullable);

  Constructor superConstructor = null;
  for (Constructor constructor in cls.superclass.constructors) {
    if (constructor.name.name == "") {
      superConstructor = constructor;
    }
  }
  VariableDeclaration other = VariableDeclaration("other",
      type: coreTypes.objectRawType(Nullability.nonNullable));
  List<VariableDeclaration> allVariables = superConstructor
      .function.namedParameters
      .map<VariableDeclaration>(
          (f) => VariableDeclaration(f.name, type: f.type))
      .toList()
        ..addAll(cls.fields.map<VariableDeclaration>(
            (f) => VariableDeclaration(f.name.name, type: f.type)));

  Map<VariableDeclaration, Member> targetsEquals = new Map();
  Map<VariableDeclaration, Member> targets = new Map();
  for (VariableDeclaration variable in allVariables) {
    Member target = coreTypes.objectEquals;
    Member targetEquals = coreTypes.objectEquals;
    DartType fieldsType = variable.type;
    if (fieldsType is InterfaceType) {
      targetEquals =
          hierarchy.getInterfaceMember(fieldsType.classNode, Name("=="));
      target = hierarchy.getInterfaceMember(cls, Name(variable.name));
    }
    targetsEquals[variable] = targetEquals;
    targets[variable] = target;
  }

  Procedure equalsOperator = Procedure(
      Name("=="),
      ProcedureKind.Operator,
      FunctionNode(
          ReturnStatement(allVariables
              .map((f) => MethodInvocation(
                  PropertyGet(ThisExpression(), Name(f.name), targets[f]),
                  Name("=="),
                  Arguments([
                    PropertyGet(
                        VariableGet(other, myType), Name(f.name), targets[f])
                  ]),
                  targetsEquals[f]))
              .fold(
                  IsExpression(VariableGet(other), myType),
                  (previousValue, element) =>
                      LogicalExpression(previousValue, '&&', element))),
          returnType: returnType,
          positionalParameters: [other]),
      fileUri: cls.fileUri)
    ..fileOffset = cls.fileOffset;
  cls.addMember(equalsOperator);
}

void addHashCode(Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  for (Procedure procedure in cls.procedures) {
    if (procedure.kind == ProcedureKind.Getter &&
        procedure.name.name == "hashCode") {
      // hashCode getter is already implemented, spec is to do nothing
      return;
    }
  }
  DartType returnType = cls.enclosingLibrary.isNonNullableByDefault
      ? coreTypes.intNonNullableRawType
      : coreTypes.intLegacyRawType;

  Constructor superConstructor = null;
  for (Constructor constructor in cls.superclass.constructors) {
    if (constructor.name.name == "") {
      superConstructor = constructor;
    }
  }

  Procedure hashCombine, hashFinish;
  HashCombineMethodsScanner hashCombineMethodsScanner =
      new HashCombineMethodsScanner();
  JenkinsClassScanner jenkinsScanner =
      new JenkinsClassScanner(hashCombineMethodsScanner);
  ScanResult<Class, Procedure> hashMethodsResult =
      jenkinsScanner.scan(cls.enclosingLibrary.enclosingComponent);
  for (Class clazz in hashMethodsResult.targets.keys) {
    for (Procedure procedure in hashMethodsResult.targets[clazz].targets.keys) {
      if (procedure.name.name == "combine") hashCombine = procedure;
      if (procedure.name.name == "finish") hashFinish = procedure;
    }
  }

  List<VariableDeclaration> allVariables = superConstructor
      .function.namedParameters
      .map<VariableDeclaration>(
          (f) => VariableDeclaration(f.name, type: f.type))
      .toList()
        ..addAll(cls.fields.map<VariableDeclaration>(
            (f) => VariableDeclaration(f.name.name, type: f.type)));

  Map<VariableDeclaration, Member> targetsHashcode = new Map();
  Map<VariableDeclaration, Member> targets = new Map();
  for (VariableDeclaration variable in allVariables) {
    Member target = coreTypes.objectEquals;
    Member targetHashcode = coreTypes.objectEquals;
    DartType fieldsType = variable.type;
    if (fieldsType is InterfaceType) {
      targetHashcode =
          hierarchy.getInterfaceMember(fieldsType.classNode, Name("hashCode"));
      target = hierarchy.getInterfaceMember(cls, Name(variable.name));
    }
    targetsHashcode[variable] = targetHashcode;
    targets[variable] = target;
  }
  cls.addMember(Procedure(
      Name("hashCode"),
      ProcedureKind.Getter,
      FunctionNode(
          ReturnStatement(StaticInvocation(
              hashFinish,
              Arguments([
                allVariables
                    .map((f) => (PropertyGet(
                        PropertyGet(ThisExpression(), Name(f.name), targets[f]),
                        Name("hashCode"),
                        targetsHashcode[f])))
                    .fold(
                        PropertyGet(
                            StringLiteral(
                                cls.enclosingLibrary.importUri.toString() +
                                    cls.name),
                            Name("hashCode"),
                            hierarchy.getInterfaceMember(
                                coreTypes.stringClass, Name("hashCode"))),
                        (previousValue, element) => StaticInvocation(
                            hashCombine, Arguments([previousValue, element])))
              ]))),
          returnType: returnType),
      fileUri: cls.fileUri)
    ..fileOffset = cls.fileOffset);
}

/*
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
