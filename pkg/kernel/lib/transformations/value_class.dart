// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.value_class;

import 'package:kernel/type_environment.dart';

import '../ast.dart';
import '../core_types.dart' show CoreTypes;
import '../class_hierarchy.dart' show ClassHierarchy;
import '../reference_from_index.dart';
import './scanner.dart';

class ValueClassScanner extends ClassScanner<Null> {
  ValueClassScanner() : super(null);

  @override
  bool predicate(Class node) => isValueClass(node);
}

class JenkinsClassScanner extends ClassScanner<Procedure> {
  JenkinsClassScanner(Scanner<Procedure, TreeNode?> next) : super(next);

  @override
  bool predicate(Class node) {
    return node.name == "JenkinsSmiHash";
  }
}

class HashCombineMethodsScanner extends ProcedureScanner<Null> {
  HashCombineMethodsScanner() : super(null);

  @override
  bool predicate(Procedure node) {
    return node.name.text == "combine" || node.name.text == "finish";
  }
}

class AllMemberScanner extends MemberScanner<InstanceInvocationExpression> {
  AllMemberScanner(Scanner<InstanceInvocationExpression, TreeNode?> next)
      : super(next);

  @override
  bool predicate(Member member) => true;
}

// Scans and matches all copyWith invocations were the receiver is _ as dynamic
// It will filter out the results that are not value classes afterwards
class ValueClassCopyWithScanner extends MethodInvocationScanner<Null> {
  ValueClassCopyWithScanner() : super(null);

  // The matching construct followed in unit-tests is:
  // @valueClass V {}
  // V v;
  // (v as dynamic).copyWith() as V
  @override
  bool predicate(InstanceInvocationExpression node) {
    return node.name.text == "copyWith" &&
        _isValueClassAsConstruct(node.receiver);
  }

  bool _isValueClassAsConstruct(Expression node) {
    return node is AsExpression && node.type is DynamicType;
  }
}

void transformComponent(
    Component node,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    ReferenceFromIndex? referenceFromIndex,
    TypeEnvironment typeEnvironment) {
  ValueClassScanner scanner = new ValueClassScanner();
  ScanResult<Class, Null> valueClasses = scanner.scan(node);
  for (Class valueClass in valueClasses.targets.keys) {
    transformValueClass(
        valueClass,
        coreTypes,
        hierarchy,
        referenceFromIndex
            ?.lookupLibrary(valueClass.enclosingLibrary)
            ?.lookupIndexedClass(valueClass.name),
        typeEnvironment);
  }

  treatCopyWithCallSites(node, coreTypes, typeEnvironment, hierarchy);

  for (Class valueClass in valueClasses.targets.keys) {
    removeValueClassAnnotation(valueClass);
  }
}

void transformValueClass(
    Class cls,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    IndexedClass? indexedClass,
    TypeEnvironment typeEnvironment) {
  Constructor? syntheticConstructor = null;
  for (Constructor constructor in cls.constructors) {
    if (constructor.isSynthetic) {
      syntheticConstructor = constructor;
    }
  }

  List<VariableDeclaration> allVariables = queryAllInstanceVariables(cls);
  List<VariableDeclaration> allVariablesList = allVariables.toList();
  allVariablesList.sort((a, b) => a.name!.compareTo(b.name!));

  addConstructor(cls, coreTypes, syntheticConstructor!);
  addEqualsOperator(cls, coreTypes, hierarchy, indexedClass, allVariablesList);
  addHashCode(cls, coreTypes, hierarchy, indexedClass, allVariablesList);
  addToString(cls, coreTypes, hierarchy, indexedClass, allVariablesList);
  addCopyWith(cls, coreTypes, hierarchy, indexedClass, allVariablesList,
      syntheticConstructor, typeEnvironment);
}

void addConstructor(
    Class cls, CoreTypes coreTypes, Constructor syntheticConstructor) {
  Constructor? superConstructor = null;
  for (Constructor constructor in cls.superclass!.constructors) {
    if (constructor.name.text == "") {
      superConstructor = constructor;
    }
  }
  List<VariableDeclaration> superParameters = superConstructor!
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
          FieldInitializer(f, VariableGet(ownFields[f.name.text]!))
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
    IndexedClass? indexedClass, List<VariableDeclaration> allVariablesList) {
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
          hierarchy.getInterfaceMember(fieldsType.classNode, Name("=="))!;
      target = hierarchy.getInterfaceMember(cls, Name(variable.name!))!;
    }
    targetsEquals[variable] = targetEquals;
    targets[variable] = target;
  }

  Name name = Name("==");
  Procedure equalsOperator = Procedure(
      name,
      ProcedureKind.Operator,
      FunctionNode(
          ReturnStatement(allVariables
              .map((f) => _createEquals(
                  _createGet(ThisExpression(), Name(f.name!),
                      interfaceTarget: targets[f]),
                  _createGet(VariableGet(other, myType), Name(f.name!),
                      interfaceTarget: targets[f]),
                  interfaceTarget: targetsEquals[f] as Procedure))
              .fold(
                  IsExpression(VariableGet(other), myType),
                  (previousValue, element) => LogicalExpression(
                      previousValue!, LogicalExpressionOperator.AND, element))),
          returnType: returnType,
          positionalParameters: [other]),
      fileUri: cls.fileUri,
      reference: indexedClass?.lookupGetterReference(name))
    ..fileOffset = cls.fileOffset;
  cls.addProcedure(equalsOperator);
}

void addHashCode(Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy,
    IndexedClass? indexedClass, List<VariableDeclaration> allVariablesList) {
  List<VariableDeclaration> allVariables = allVariablesList.toList();
  for (Procedure procedure in cls.procedures) {
    if (procedure.kind == ProcedureKind.Getter &&
        procedure.name.text == "hashCode") {
      // hashCode getter is already implemented, spec is to do nothing
      return;
    }
  }
  DartType returnType = coreTypes.intRawType(cls.enclosingLibrary.nonNullable);

  Procedure? hashCombine, hashFinish;
  HashCombineMethodsScanner hashCombineMethodsScanner =
      new HashCombineMethodsScanner();
  JenkinsClassScanner jenkinsScanner =
      new JenkinsClassScanner(hashCombineMethodsScanner);
  ScanResult<Class, Procedure> hashMethodsResult =
      jenkinsScanner.scan(cls.enclosingLibrary.enclosingComponent!);
  for (Class clazz in hashMethodsResult.targets.keys) {
    for (Procedure procedure
        in hashMethodsResult.targets[clazz]!.targets.keys) {
      if (procedure.name.text == "combine") {
        hashCombine = procedure;
      }
      if (procedure.name.text == "finish") {
        hashFinish = procedure;
      }
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
          hierarchy.getInterfaceMember(fieldsType.classNode, Name("hashCode"))!;
      target = hierarchy.getInterfaceMember(cls, Name(variable.name!))!;
    }
    targetsHashcode[variable] = targetHashcode;
    targets[variable] = target;
  }
  Name name = Name("hashCode");
  cls.addProcedure(Procedure(
      name,
      ProcedureKind.Getter,
      FunctionNode(
          ReturnStatement(StaticInvocation(
              hashFinish!,
              Arguments([
                allVariables
                    .map((f) => (_createGet(
                        _createGet(ThisExpression(), Name(f.name!),
                            interfaceTarget: targets[f]),
                        Name("hashCode"),
                        interfaceTarget: targetsHashcode[f])))
                    .fold(
                        _createGet(
                            StringLiteral(
                                cls.enclosingLibrary.importUri.toString() +
                                    cls.name),
                            Name("hashCode"),
                            interfaceTarget: hierarchy.getInterfaceMember(
                                coreTypes.stringClass, Name("hashCode"))),
                        (previousValue, element) => StaticInvocation(
                            hashCombine!, Arguments([previousValue, element])))
              ]))),
          returnType: returnType),
      fileUri: cls.fileUri,
      reference: indexedClass?.lookupGetterReference(name))
    ..fileOffset = cls.fileOffset);
}

void addToString(Class cls, CoreTypes coreTypes, ClassHierarchy hierarchy,
    IndexedClass? indexedClass, List<VariableDeclaration> allVariablesList) {
  List<Expression> wording = [StringLiteral("${cls.name}(")];

  for (VariableDeclaration variable in allVariablesList) {
    wording.add(StringLiteral("${variable.name}: "));
    Member? variableTarget =
        hierarchy.getInterfaceMember(cls, Name(variable.name!));
    Procedure toStringTarget = hierarchy.getInterfaceMember(
        variable.type is InterfaceType
            ? (variable.type as InterfaceType).classNode
            : coreTypes.objectClass,
        Name("toString")) as Procedure;
    wording.add(_createInvocation(
        _createGet(ThisExpression(), Name(variable.name!),
            interfaceTarget: variableTarget),
        Name("toString"),
        Arguments([]),
        interfaceTarget: toStringTarget));
    wording.add(StringLiteral(", "));
  }
  if (allVariablesList.length != 0) {
    wording[wording.length - 1] = StringLiteral(")");
  } else {
    wording.add(StringLiteral(")"));
  }
  DartType returnType =
      coreTypes.stringRawType(cls.enclosingLibrary.nonNullable);
  Name name = Name("toString");
  cls.addProcedure(Procedure(
      name,
      ProcedureKind.Method,
      FunctionNode(ReturnStatement(StringConcatenation(wording)),
          returnType: returnType),
      fileUri: cls.fileUri,
      reference: indexedClass?.lookupGetterReference(name))
    ..fileOffset = cls.fileOffset);
}

void addCopyWith(
    Class cls,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    IndexedClass? indexedClass,
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
          hierarchy.getInterfaceMember(fieldsType.classNode, Name("=="))!;
      target = hierarchy.getInterfaceMember(cls, Name(variable.name!))!;
    }
    targetsEquals[variable] = targetEquals;
    targets[variable] = target;
  }

  Name name = Name("copyWith");
  cls.addProcedure(Procedure(
      name,
      ProcedureKind.Method,
      FunctionNode(
          ReturnStatement(ConstructorInvocation(
              syntheticConstructor,
              Arguments([],
                  named: allVariables
                      .map((f) => NamedExpression(f.name!, VariableGet(f)))
                      .toList()))),
          namedParameters: allVariables),
      fileUri: cls.fileUri,
      reference: indexedClass?.lookupGetterReference(name))
    ..fileOffset = cls.fileOffset);
}

List<VariableDeclaration> queryAllInstanceVariables(Class cls) {
  Constructor? superConstructor = null;
  for (Constructor constructor in cls.superclass!.constructors) {
    if (constructor.name.text == "") {
      superConstructor = constructor;
    }
  }
  return superConstructor!.function.namedParameters
      .map<VariableDeclaration>(
          (f) => VariableDeclaration(f.name, type: f.type))
      .toList()
    ..addAll(cls.fields.map<VariableDeclaration>(
        (f) => VariableDeclaration(f.name.text, type: f.type)));
}

void removeValueClassAnnotation(Class cls) {
  int? valueClassAnnotationIndex;
  for (int annotationIndex = 0;
      annotationIndex < cls.annotations.length;
      annotationIndex++) {
    Expression annotation = cls.annotations[annotationIndex];
    if (annotation is ConstantExpression &&
        annotation.constant is StringConstant) {
      StringConstant constant = annotation.constant as StringConstant;
      if (constant.value == 'valueClass') {
        valueClassAnnotationIndex = annotationIndex;
      }
    }
  }
  cls.annotations.removeAt(valueClassAnnotationIndex!);
}

void treatCopyWithCallSites(Component component, CoreTypes coreTypes,
    TypeEnvironment typeEnvironment, ClassHierarchy hierarchy) {
  ValueClassCopyWithScanner valueCopyWithScanner =
      new ValueClassCopyWithScanner();
  AllMemberScanner copyWithScanner = AllMemberScanner(valueCopyWithScanner);
  ScanResult<Member, InstanceInvocationExpression> copyWithCallSites =
      copyWithScanner.scan(component);
  for (Member memberWithCopyWith in copyWithCallSites.targets.keys) {
    Map<InstanceInvocationExpression, ScanResult<TreeNode?, TreeNode?>?>?
        targets = copyWithCallSites.targets[memberWithCopyWith]?.targets;
    if (targets != null) {
      StaticTypeContext staticTypeContext =
          StaticTypeContext(memberWithCopyWith, typeEnvironment);
      for (InstanceInvocationExpression copyWithCall in targets.keys) {
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

void treatCopyWithCallSite(
    Class valueClass,
    InstanceInvocationExpression copyWithCall,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy) {
  Map<String, Expression> preTransformationArguments = new Map();
  for (NamedExpression argument in copyWithCall.arguments.named) {
    preTransformationArguments[argument.name] = argument.value;
  }
  Constructor? syntheticConstructor;
  for (Constructor constructor in valueClass.constructors) {
    if (constructor.isSynthetic) {
      syntheticConstructor = constructor;
    }
  }
  List<VariableDeclaration> allArguments =
      syntheticConstructor!.function.namedParameters;

  VariableDeclaration letVariable =
      VariableDeclaration.forValue(copyWithCall.receiver);
  Arguments postTransformationArguments = Arguments.empty();
  for (VariableDeclaration argument in allArguments) {
    if (preTransformationArguments.containsKey(argument.name)) {
      postTransformationArguments.named.add(NamedExpression(
          argument.name!, preTransformationArguments[argument.name]!)
        ..parent = postTransformationArguments);
    } else {
      postTransformationArguments.named.add(NamedExpression(argument.name!,
          _createGet(VariableGet(letVariable), Name(argument.name!)))
        ..parent = postTransformationArguments);
    }
  }
  copyWithCall.replaceWith(Let(
      letVariable,
      _createInvocation(VariableGet(letVariable), Name("copyWith"),
          postTransformationArguments)));
}

bool isValueClass(Class node) {
  for (Expression annotation in node.annotations) {
    if (annotation is ConstantExpression &&
        annotation.constant is StringConstant) {
      StringConstant constant = annotation.constant as StringConstant;
      if (constant.value == "valueClass") {
        return true;
      }
    }
  }
  return false;
}

// TODO(johnniwinther): Ensure correct invocation function type and instance
// access kind on InstanceInvocation.
Expression _createInvocation(
    Expression receiver, Name name, Arguments arguments,
    {Procedure? interfaceTarget}) {
  if (interfaceTarget != null) {
    return InstanceInvocation(
        InstanceAccessKind.Instance, receiver, name, arguments,
        interfaceTarget: interfaceTarget,
        functionType: interfaceTarget.getterType as FunctionType);
  } else {
    return DynamicInvocation(
        DynamicAccessKind.Dynamic, receiver, name, arguments);
  }
}

Expression _createEquals(Expression left, Expression right,
    {required Procedure interfaceTarget}) {
  return EqualsCall(left, right,
      interfaceTarget: interfaceTarget,
      functionType: interfaceTarget.getterType as FunctionType);
}

// TODO(johnniwinther): Ensure correct result type on InstanceGet.
Expression _createGet(Expression receiver, Name name,
    {Member? interfaceTarget}) {
  if (interfaceTarget != null) {
    return InstanceGet(InstanceAccessKind.Instance, receiver, name,
        interfaceTarget: interfaceTarget,
        resultType: interfaceTarget.getterType);
  } else {
    return DynamicGet(DynamicAccessKind.Dynamic, receiver, name);
  }
}
