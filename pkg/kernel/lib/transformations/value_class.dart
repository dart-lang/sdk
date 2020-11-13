// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.value_class;

import 'package:kernel/type_environment.dart';

import '../ast.dart';
import '../kernel.dart';
import '../core_types.dart' show CoreTypes;
import '../class_hierarchy.dart' show ClassHierarchy;
import './scanner.dart';

class ValueClassScanner extends ClassScanner<Null> {
  ValueClassScanner() : super(null);

  bool predicate(Class node) => isValueClass(node);
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
    return node.name.text == "combine" || node.name.text == "finish";
  }
}

class AllMemberScanner extends MemberScanner<MethodInvocation> {
  AllMemberScanner(Scanner<MethodInvocation, TreeNode> next) : super(next);

  bool predicate(Member member) => true;
}

// Scans and matches all copyWith invocations were the reciever is _ as dynamic
// It will filter out the results that are not value classes afterwards
class ValueClassCopyWithScanner extends MethodInvocationScanner<Null> {
  ValueClassCopyWithScanner() : super(null);

  // The matching construct followed in unit-tests is:
  // @valueClass V {}
  // V v;
  // (v as dynamic).copyWith() as V
  bool predicate(MethodInvocation node) {
    return node.name.name == "copyWith" &&
        _isValueClassAsConstruct(node.receiver);
  }

  bool _isValueClassAsConstruct(Expression node) {
    return node is AsExpression && node.type is DynamicType;
  }
}

void transformComponent(Component node, CoreTypes coreTypes,
    ClassHierarchy hierarchy, TypeEnvironment typeEnvironment) {
  ValueClassScanner scanner = new ValueClassScanner();
  ScanResult<Class, Null> valueClasses = scanner.scan(node);
  for (Class valueClass in valueClasses.targets.keys) {
    transformValueClass(valueClass, coreTypes, hierarchy, typeEnvironment);
  }

  treatCopyWithCallSites(node, coreTypes, typeEnvironment, hierarchy);

  for (Class valueClass in valueClasses.targets.keys) {
    removeValueClassAnnotation(valueClass);
  }
}

void transformValueClass(Class cls, CoreTypes coreTypes,
    ClassHierarchy hierarchy, TypeEnvironment typeEnvironment) {
  Constructor syntheticConstructor = null;
  for (Constructor constructor in cls.constructors) {
    if (constructor.isSynthetic) {
      syntheticConstructor = constructor;
    }
  }

  List<VariableDeclaration> allVariables = queryAllInstanceVariables(cls);
  List<VariableDeclaration> allVariablesList = allVariables.toList();
  allVariablesList.sort((a, b) => a.name.compareTo(b.name));

  addConstructor(cls, coreTypes, syntheticConstructor);
  addEqualsOperator(cls, coreTypes, hierarchy, allVariablesList);
  addHashCode(cls, coreTypes, hierarchy, allVariablesList);
  addToString(cls, coreTypes, hierarchy, allVariablesList);
  addCopyWith(cls, coreTypes, hierarchy, allVariablesList, syntheticConstructor,
      typeEnvironment);
}

void addConstructor(
    Class cls, CoreTypes coreTypes, Constructor syntheticConstructor) {
  Constructor superConstructor = null;
  for (Constructor constructor in cls.superclass.constructors) {
    if (constructor.name.text == "") {
      superConstructor = constructor;
    }
  }
  List<VariableDeclaration> superParameters = superConstructor
      .function.namedParameters
      .map<VariableDeclaration>((e) => VariableDeclaration(e.name, type: e.type)
        ..parent = syntheticConstructor.function)
      .toList();
  Map<String, VariableDeclaration> ownFields = Map.fromIterable(cls.fields,
      key: (f) => f.name.text,
      value: (f) =>
          VariableDeclaration(f.name.text, type: f.type, isRequired: true)
            ..parent = syntheticConstructor.function);

  List<Initializer> initializersConstructor = cls.fields
      .map<Initializer>((f) =>
          FieldInitializer(f, VariableGet(ownFields[f.name.text]))
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
}

void addEqualsOperator(Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy,
    List<VariableDeclaration> allVariablesList) {
  List<VariableDeclaration> allVariables = allVariablesList.toList();
  for (Procedure procedure in cls.procedures) {
    if (procedure.kind == ProcedureKind.Operator &&
        procedure.name.text == "==") {
      // ==operator is already implemented, spec is to do nothing
      return;
    }
  }
  DartType returnType = coreTypes.boolRawType(cls.enclosingLibrary.nonNullable);
  DartType myType = coreTypes.thisInterfaceType(cls, Nullability.nonNullable);

  VariableDeclaration other = VariableDeclaration("other",
      type: coreTypes.objectRawType(Nullability.nonNullable));

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
                  (previousValue, element) => LogicalExpression(
                      previousValue, LogicalExpressionOperator.AND, element))),
          returnType: returnType,
          positionalParameters: [other]),
      fileUri: cls.fileUri)
    ..fileOffset = cls.fileOffset;
  cls.addProcedure(equalsOperator);
}

void addHashCode(Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy,
    List<VariableDeclaration> allVariablesList) {
  List<VariableDeclaration> allVariables = allVariablesList.toList();
  for (Procedure procedure in cls.procedures) {
    if (procedure.kind == ProcedureKind.Getter &&
        procedure.name.text == "hashCode") {
      // hashCode getter is already implemented, spec is to do nothing
      return;
    }
  }
  DartType returnType = coreTypes.intRawType(cls.enclosingLibrary.nonNullable);

  Procedure hashCombine, hashFinish;
  HashCombineMethodsScanner hashCombineMethodsScanner =
      new HashCombineMethodsScanner();
  JenkinsClassScanner jenkinsScanner =
      new JenkinsClassScanner(hashCombineMethodsScanner);
  ScanResult<Class, Procedure> hashMethodsResult =
      jenkinsScanner.scan(cls.enclosingLibrary.enclosingComponent);
  for (Class clazz in hashMethodsResult.targets.keys) {
    for (Procedure procedure in hashMethodsResult.targets[clazz].targets.keys) {
      if (procedure.name.text == "combine") hashCombine = procedure;
      if (procedure.name.text == "finish") hashFinish = procedure;
    }
  }

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
  cls.addProcedure(Procedure(
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

void addToString(Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy,
    List<VariableDeclaration> allVariablesList) {
  List<Expression> wording = [StringLiteral("${cls.name}(")];

  for (VariableDeclaration variable in allVariablesList) {
    wording.add(StringLiteral("${variable.name}: "));
    wording.add(MethodInvocation(
        PropertyGet(ThisExpression(), Name(variable.name),
            hierarchy.getInterfaceMember(cls, Name(variable.name))),
        Name("toString"),
        Arguments([]),
        (variable.type is InterfaceType)
            ? hierarchy.getInterfaceMember(
                (variable.type as InterfaceType).classNode, Name("toString"))
            : null));
    wording.add(StringLiteral(", "));
  }
  if (allVariablesList.length != 0) {
    wording[wording.length - 1] = StringLiteral(")");
  } else {
    wording.add(StringLiteral(")"));
  }
  DartType returnType =
      coreTypes.stringRawType(cls.enclosingLibrary.nonNullable);
  cls.addProcedure(Procedure(
      Name("toString"),
      ProcedureKind.Method,
      FunctionNode(ReturnStatement(StringConcatenation(wording)),
          returnType: returnType),
      fileUri: cls.fileUri)
    ..fileOffset = cls.fileOffset);
}

void addCopyWith(
    Class cls,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<VariableDeclaration> allVariablesList,
    Constructor syntheticConstructor,
    TypeEnvironment typeEnvironment) {
  List<VariableDeclaration> allVariables = allVariablesList.toList();

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

  cls.addProcedure(Procedure(
      Name("copyWith"),
      ProcedureKind.Method,
      FunctionNode(
          ReturnStatement(ConstructorInvocation(
              syntheticConstructor,
              Arguments([],
                  named: allVariables
                      .map((f) => NamedExpression(f.name, VariableGet(f)))
                      .toList()))),
          namedParameters: allVariables),
      fileUri: cls.fileUri)
    ..fileOffset = cls.fileOffset);
}

List<VariableDeclaration> queryAllInstanceVariables(Class cls) {
  Constructor superConstructor = null;
  for (Constructor constructor in cls.superclass.constructors) {
    if (constructor.name.text == "") {
      superConstructor = constructor;
    }
  }
  return superConstructor.function.namedParameters
      .map<VariableDeclaration>(
          (f) => VariableDeclaration(f.name, type: f.type))
      .toList()
        ..addAll(cls.fields.map<VariableDeclaration>(
            (f) => VariableDeclaration(f.name.text, type: f.type)));
}

void removeValueClassAnnotation(Class cls) {
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

void treatCopyWithCallSites(Component component, CoreTypes coreTypes,
    TypeEnvironment typeEnvironment, ClassHierarchy hierarchy) {
  ValueClassCopyWithScanner valueCopyWithScanner =
      new ValueClassCopyWithScanner();
  AllMemberScanner copyWithScanner = AllMemberScanner(valueCopyWithScanner);
  ScanResult<Member, MethodInvocation> copyWithCallSites =
      copyWithScanner.scan(component);
  for (Member memberWithCopyWith in copyWithCallSites.targets.keys) {
    if (copyWithCallSites.targets[memberWithCopyWith].targets != null) {
      StaticTypeContext staticTypeContext =
          StaticTypeContext(memberWithCopyWith, typeEnvironment);
      for (MethodInvocation copyWithCall
          in copyWithCallSites.targets[memberWithCopyWith].targets.keys) {
        AsExpression receiver = copyWithCall.receiver as AsExpression;

        Expression valueClassInstance = receiver.operand;
        DartType valueClassType =
            valueClassInstance.getStaticType(staticTypeContext);
        if (valueClassType is InterfaceType) {
          Class valueClass = valueClassType.classNode;
          if (isValueClass(valueClass)) {
            treatCopyWithCallSite(
                valueClass, copyWithCall, coreTypes, hierarchy);
          }
        }
      }
    }
  }
}

void treatCopyWithCallSite(Class valueClass, MethodInvocation copyWithCall,
    CoreTypes coreTypes, ClassHierarchy hierarchy) {
  Map<String, Expression> preTransformationArguments = new Map();
  for (NamedExpression argument in copyWithCall.arguments.named) {
    preTransformationArguments[argument.name] = argument.value;
  }
  Constructor syntheticConstructor;
  for (Constructor constructor in valueClass.constructors) {
    if (constructor.isSynthetic) {
      syntheticConstructor = constructor;
    }
  }
  List<VariableDeclaration> allArguments =
      syntheticConstructor.function.namedParameters;

  VariableDeclaration letVariable =
      VariableDeclaration.forValue(copyWithCall.receiver);
  Arguments postTransformationArguments = Arguments.empty();
  for (VariableDeclaration argument in allArguments) {
    if (preTransformationArguments.containsKey(argument.name)) {
      postTransformationArguments.named.add(NamedExpression(
          argument.name, preTransformationArguments[argument.name])
        ..parent = postTransformationArguments);
    } else {
      postTransformationArguments.named.add(NamedExpression(argument.name,
          PropertyGet(VariableGet(letVariable), Name(argument.name)))
        ..parent = postTransformationArguments);
    }
  }
  copyWithCall.replaceWith(Let(
      letVariable,
      MethodInvocation(VariableGet(letVariable), Name("copyWith"),
          postTransformationArguments)));
}

bool isValueClass(Class node) {
  for (Expression annotation in node.annotations) {
    if (annotation is ConstantExpression &&
        annotation.constant is StringConstant) {
      StringConstant constant = annotation.constant;
      if (constant.value == "valueClass") {
        return true;
      }
    }
  }
  return false;
}
