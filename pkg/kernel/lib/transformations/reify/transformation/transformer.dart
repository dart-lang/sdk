// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.transformation.transformer;

import '../analysis/program_analysis.dart';
import '../../../ast.dart';
import 'binding.dart' show RuntimeLibrary;
import 'builder.dart' show RuntimeTypeSupportBuilder;
import 'dart:collection' show LinkedHashMap;
import '../asts.dart';

export 'binding.dart' show RuntimeLibrary;
export 'builder.dart' show RuntimeTypeSupportBuilder;

enum RuntimeTypeStorage {
  none,
  inheritedField,
  field,
  getter,
}

class TransformationContext {
  /// Describes how the runtime type is stored on the object.
  RuntimeTypeStorage runtimeTypeStorage;

  /// Field added to store the runtime type if [runtimeType] is
  /// [RuntimeTypeStorage.field].
  Field runtimeTypeField;

  /// The parameter for the type information introduced to the constructor or
  /// to static initializers.
  VariableDeclaration parameter;

  /// A ordered collection of fields together with their initializers rewritten
  /// to static initializer functions that can be used in the constructor's
  /// initializer list.
  /// The order is important because of possible side-effects in the
  /// initializers.
  LinkedHashMap<Field, Procedure> initializers;

  // `true` if the visitor currently is in a field initializer, a initializer
  // list of a constructor, or the body of a factory method. In these cases,
  // type argument access is different than in an instance context, since `this`
  // is not available.
  bool inInitializer = false;

  String toString() => "s: ${runtimeTypeStorage} f: $runtimeTypeField,"
      " p: $parameter, i: $inInitializer";
}

abstract class DebugTrace {
  static const bool debugTrace = false;

  static const int lineLength = 80;

  TransformationContext get context;

  String getNodeLevel(TreeNode node) {
    String level = "";
    while (node != null && node is! Library) {
      level = " $level";
      node = node.parent;
    }
    return level;
  }

  String shorten(String s) {
    return s.length > lineLength ? s.substring(0, lineLength) : s;
  }

  void trace(TreeNode node) {
    if (debugTrace) {
      String nodeText = node.toString().replaceAll("\n", " ");
      print(shorten("trace:${getNodeLevel(node)}$context"
          " [${node.runtimeType}] $nodeText"));
    }
  }
}

/// Rewrites a tree to remove generic types and runtime type checks and replace
/// them with Dart objects.
///
/// Runtime types are stored in a field/getter called [runtimeTypeName] on the
/// object, which for parameterized classes is initialized in the constructor.
//  TODO(karlklose):
//  - add a scoped namer
//  - rewrite types (supertypes, implemented types)
//  - rewrite as
class ReifyVisitor extends Transformer with DebugTrace {
  final RuntimeLibrary rtiLibrary;
  final RuntimeTypeSupportBuilder builder;
  final ProgramKnowledge knowledge;

  ReifyVisitor(this.rtiLibrary, this.builder, this.knowledge,
      [this.libraryToTransform]);

  /// If not null, the transformation will only be applied to classes declared
  /// in this library.
  final Library libraryToTransform;

  // TODO(karlklose): find a way to get rid of this state in the visitor.
  TransformationContext context;

  static const String genericMethodTypeParametersName = r"$typeParameters";

  bool libraryShouldBeTransformed(Library library) {
    return libraryToTransform == null || libraryToTransform == library;
  }

  bool needsTypeInformation(Class cls) {
    return !isObject(cls) &&
        !rtiLibrary.contains(cls) &&
        libraryShouldBeTransformed(cls.enclosingLibrary);
  }

  bool usesTypeGetter(Class cls) {
    return cls.typeParameters.isEmpty;
  }

  bool isObject(Class cls) {
    // TODO(karlklose): use [CoreTypes].
    return "$cls" == 'dart.core::Object';
  }

  Initializer addTypeAsArgument(initializer) {
    assert(initializer is SuperInitializer ||
        initializer is RedirectingInitializer);
    Class cls = getEnclosingClass(initializer.target);
    if (needsTypeInformation(cls) && !usesTypeGetter(cls)) {
      // If the current class uses a getter for type information, we did not add
      // a parameter to the constructor, but we can pass `null` as the value to
      // initialize the type field, since it will be shadowed by the getter.
      Expression type = (context.parameter != null)
          ? new VariableGet(context.parameter)
          : new NullLiteral();
      builder.insertAsFirstArgument(initializer.arguments, type);
    }
    return initializer;
  }

  Expression interceptInstantiation(
      InvocationExpression invocation, Member target) {
    Class targetClass = target.parent;
    Library targetLibrary = targetClass.parent;
    Library currentLibrary = getEnclosingLibrary(invocation);
    if (libraryShouldBeTransformed(currentLibrary) &&
        !libraryShouldBeTransformed(targetLibrary) &&
        !rtiLibrary.contains(target)) {
      return builder.attachTypeToConstructorInvocation(invocation, target);
    }
    return invocation;
  }

  Expression createRuntimeType(DartType type) {
    if (context?.inInitializer == true) {
      // In initializer context, the instance type is provided in
      // `context.parameter` as there is no `this`.
      return builder.createRuntimeType(type, typeContext: context.parameter);
    } else {
      return builder.createRuntimeType(type);
    }
  }

  TreeNode defaultTreeNode(TreeNode node) {
    trace(node);
    return super.defaultTreeNode(node);
  }

  Expression visitStaticInvocation(StaticInvocation invocation) {
    trace(invocation);

    invocation.transformChildren(this);

    Procedure target = invocation.target;
    if (target == rtiLibrary.reifyFunction) {
      /// Rewrite calls to reify(TypeLiteral) to a reified type.
      TypeLiteral literal = invocation.arguments.positional.single;
      return createRuntimeType(literal.type);
    } else if (target.kind == ProcedureKind.Factory) {
      // Intercept calls to factories of classes we do not transform
      return interceptInstantiation(invocation, target);
    }

    addTypeArgumentToGenericInvocation(invocation);

    return invocation;
  }

  Library visitLibrary(Library library) {
    trace(library);

    if (libraryShouldBeTransformed(library)) {
      library.transformChildren(this);
    }
    return library;
  }

  Expression visitConstructorInvocation(ConstructorInvocation invocation) {
    invocation.transformChildren(this);
    return interceptInstantiation(invocation, invocation.target);
  }

  Member getStaticInvocationTarget(InvocationExpression invocation) {
    if (invocation is ConstructorInvocation) {
      return invocation.target;
    } else if (invocation is StaticInvocation) {
      return invocation.target;
    } else {
      throw "Unexpected InvocationExpression $invocation.";
    }
  }

  bool isInstantiation(TreeNode invocation) {
    return invocation is ConstructorInvocation ||
        invocation is StaticInvocation &&
            invocation.target.kind == ProcedureKind.Factory;
  }

  bool isTypeVariable(DartType type) => type is TypeParameterType;

  /// Add the runtime type as an extra argument to constructor invocations.
  Arguments visitArguments(Arguments arguments) {
    trace(arguments);

    arguments.transformChildren(this);
    TreeNode parent = arguments.parent;
    if (isInstantiation(parent)) {
      Class targetClass = getEnclosingClass(getStaticInvocationTarget(parent));
      // Do not add the extra argument if the class does not need a type member
      // or if it can be implemented as a getter.
      if (!needsTypeInformation(targetClass) || usesTypeGetter(targetClass)) {
        return arguments;
      }

      List<DartType> typeArguments = arguments.types;

      Expression type =
          createRuntimeType(new InterfaceType(targetClass, typeArguments));

      builder.insertAsFirstArgument(arguments, type);
    }
    return arguments;
  }

  Field visitField(Field field) {
    trace(field);

    visitDartType(field.type);
    for (Expression annotation in field.annotations) {
      annotation.accept(this);
    }
    // Do not visit initializers, they have already been transformed when the
    // class was handled.
    return field;
  }

  /// Go through all initializers of fields and record a static initializer
  /// function, if necessary.
  void rewriteFieldInitializers(Class cls) {
    assert(context != null);
    context.initializers = new LinkedHashMap<Field, Procedure>();
    List<Field> fields = cls.fields;
    bool initializerRewritten = false;
    for (Field field in fields) {
      if (!initializerRewritten && knowledge.usedParameters(field).isEmpty) {
        // This field needs no static initializer.
        continue;
      }

      Expression initializer = field.initializer;
      if (initializer == null || field.isStatic) continue;
      // Declare a new variable that holds the type information and can be
      // used to access type variables in initializer context.
      // TODO(karlklose): some fields do not need the parameter.
      VariableDeclaration typeObject = new VariableDeclaration(r"$type");
      context.parameter = typeObject;
      context.inInitializer = true;
      // Translate the initializer while keeping track of whether there was
      // already an initializers that required type information in
      // [typeVariableUsedInInitializer].
      initializer = initializer.accept(this);
      context.parameter = null;
      context.inInitializer = false;
      // Create a static initializer function from the translated initializer
      // expression and record it.
      Name name = new Name("\$init\$${field.name.name}");
      Statement body = new ReturnStatement(initializer);
      Procedure staticInitializer = new Procedure(
          name,
          ProcedureKind.Method,
          new FunctionNode(body,
              positionalParameters: <VariableDeclaration>[typeObject]),
          isStatic: true,
          fileUri: cls.fileUri);
      context.initializers[field] = staticInitializer;
      // Finally, remove the initializer from the field.
      field.initializer = null;
    }
  }

  bool inheritsTypeProperty(Class cls) {
    assert(needsTypeInformation(cls));
    Class superclass = cls.superclass;
    return needsTypeInformation(superclass);
  }

  Class visitClass(Class cls) {
    trace(cls);

    if (needsTypeInformation(cls)) {
      context = new TransformationContext();
      List<TypeParameter> typeParameters = cls.typeParameters;
      if (usesTypeGetter(cls)) {
        assert(typeParameters.isEmpty);
        context.runtimeTypeStorage = RuntimeTypeStorage.getter;
        Member getter = builder.createGetter(rtiLibrary.runtimeTypeName,
            createRuntimeType(cls.rawType), cls, rtiLibrary.typeType);
        cls.addMember(getter);
      } else if (!inheritsTypeProperty(cls)) {
        context.runtimeTypeStorage = RuntimeTypeStorage.field;
        // TODO(karlklose): should we add the field to [Object]?
        context.runtimeTypeField = new Field(rtiLibrary.runtimeTypeName,
            fileUri: cls.fileUri, isFinal: true, type: rtiLibrary.typeType);
        cls.addMember(context.runtimeTypeField);
      } else {
        context.runtimeTypeStorage = RuntimeTypeStorage.inheritedField;
      }

      for (int i = 0; i < typeParameters.length; ++i) {
        TypeParameter variable = typeParameters[i];
        cls.addMember(builder.createTypeVariableGetter(cls, variable, i));
      }

      // Tag the class as supporting the runtime type getter.
      InterfaceType interfaceTypeForSupertype =
          new InterfaceType(rtiLibrary.markerClass);
      cls.implementedTypes.add(new Supertype(
          interfaceTypeForSupertype.classNode,
          interfaceTypeForSupertype.typeArguments));

      // Before transforming the parts of the class declaration, rewrite field
      // initializers that use type variables (or that would be called after one
      // that does) to static functions that can be used from constructors.
      rewriteFieldInitializers(cls);

      // Add properties for declaration tests.
      for (Class test in knowledge.classTests) {
        if (test == rtiLibrary.markerClass) continue;

        Procedure tag = builder.createGetter(
            builder.getTypeTestTagName(test),
            new BoolLiteral(isSuperClass(test, cls)),
            cls,
            builder.coreTypes.boolClass.rawType);
        cls.addMember(tag);
      }

      // Add a runtimeType getter.
      if (!usesTypeGetter(cls) && !inheritsTypeProperty(cls)) {
        cls.addMember(new Procedure(
            new Name("runtimeType"),
            ProcedureKind.Getter,
            new FunctionNode(
                new ReturnStatement(new DirectPropertyGet(
                    new ThisExpression(), context.runtimeTypeField)),
                returnType: builder.coreTypes.typeClass.rawType),
            fileUri: cls.fileUri));
      }
    }

    cls.transformChildren(this);

    // Add the static initializer functions. They have already been transformed.
    if (context?.initializers != null) {
      context.initializers.forEach((_, Procedure initializer) {
        cls.addMember(initializer);
      });
    }

    // TODO(karlklose): clear type arguments later, the order of class
    // transformations otherwise influences the result.
    // cls.typeParameters.clear();
    context = null;
    return cls;
  }

  // TODO(karlklose): replace with a structure that can answer also the question
  // which tags must be overriden due to different values.
  /// Returns `true` if [a] is a declaration used in a supertype of [b].
  bool isSuperClass(Class a, Class b) {
    if (b == null) return false;
    if (a == b) return true;

    if (isSuperClass(a, b.superclass)) {
      return true;
    }

    Iterable<Class> interfaceClasses = b.implementedTypes
        .map((Supertype type) => type.classNode)
        .where((Class cls) => cls != rtiLibrary.markerClass);
    return interfaceClasses
        .any((Class declaration) => isSuperClass(a, declaration));
  }

  bool isConstructorOrFactory(TreeNode node) {
    return isFactory(node) || node is Constructor;
  }

  bool isFactory(TreeNode node) {
    return node is Procedure && node.kind == ProcedureKind.Factory;
  }

  bool needsParameterForRuntimeType(TreeNode node) {
    if (!isConstructorOrFactory(node)) return false;

    RuntimeTypeStorage access = context.runtimeTypeStorage;
    assert(access != RuntimeTypeStorage.none);
    return access == RuntimeTypeStorage.field ||
        access == RuntimeTypeStorage.inheritedField;
  }

  FunctionNode visitFunctionNode(FunctionNode node) {
    trace(node);

    addTypeArgumentToGenericDeclaration(node);

    // If we have a [TransformationContext] with a runtime type field and we
    // translate a constructor or factory, we need a parameter that the code of
    // initializers or the factory body can use to access type arguments.
    // The parameter field in the context will be reset in the visit-method of
    // the parent.
    if (context != null && needsParameterForRuntimeType(node.parent)) {
      assert(context.parameter == null);
      // Create the parameter and insert it as the function's first parameter.
      context.parameter = new VariableDeclaration(
          rtiLibrary.runtimeTypeName.name,
          type: rtiLibrary.typeType);
      context.parameter.parent = node;
      node.positionalParameters.insert(0, context.parameter);
      node.requiredParameterCount++;
    }
    node.transformChildren(this);
    return node;
  }

  SuperInitializer visitSuperInitializer(SuperInitializer initializer) {
    initializer.transformChildren(this);
    return addTypeAsArgument(initializer);
  }

  RedirectingInitializer visitRedirectingInitializer(
      RedirectingInitializer initializer) {
    initializer.transformChildren(this);
    return addTypeAsArgument(initializer);
  }

  Procedure visitProcedure(Procedure procedure) {
    trace(procedure);

    transformList(procedure.annotations, this, procedure.parent);
    // Visit the function body in a initializing context, if it is a factory.
    context?.inInitializer = isFactory(procedure);
    procedure.function?.accept(this);
    context?.inInitializer = false;

    context?.parameter = null;
    return procedure;
  }

  Constructor visitConstructor(Constructor constructor) {
    trace(constructor);

    transformList(constructor.annotations, this, constructor);
    if (constructor.function != null) {
      constructor.function = constructor.function.accept(this);
      constructor.function?.parent = constructor;
    }

    context?.inInitializer = true;
    transformList(constructor.initializers, this, constructor);
    context?.inInitializer = false;

    if (context != null) {
      if (context.runtimeTypeStorage == RuntimeTypeStorage.field) {
        // Initialize the runtime type field with value given in the additional
        // constructor parameter.
        assert(context.parameter != null);
        Initializer initializer = new FieldInitializer(
            context.runtimeTypeField, new VariableGet(context.parameter));
        initializer.parent = constructor;
        constructor.initializers.insert(0, initializer);
      }
      if (context.initializers != null) {
        // For each field that needed a static initializer function, initialize
        // the field by calling the function.
        List<Initializer> fieldInitializers = <Initializer>[];
        context.initializers.forEach((Field field, Procedure initializer) {
          assert(context.parameter != null);
          Arguments argument =
              new Arguments(<Expression>[new VariableGet(context.parameter)]);
          fieldInitializers.add(new FieldInitializer(
              field, new StaticInvocation(initializer, argument)));
        });
        constructor.initializers.insertAll(0, fieldInitializers);
      }
      context.parameter = null;
    }

    return constructor;
  }

  /// Returns `true` if the given type can be tested using type test tags.
  ///
  /// This implies that there are no subtypes of the [type] that are not
  /// transformed.
  bool typeSupportsTagTest(InterfaceType type) {
    return needsTypeInformation(type.classNode);
  }

  Expression visitIsExpression(IsExpression expression) {
    trace(expression);

    expression.transformChildren(this);

    if (getEnclosingLibrary(expression) == rtiLibrary.interceptorsLibrary) {
      // In the interceptor library we need actual is-checks at the moment.
      return expression;
    }

    Expression target = expression.operand;
    DartType type = expression.type;

    if (type is InterfaceType && typeSupportsTagTest(type)) {
      assert(knowledge.classTests.contains(type.classNode));
      bool checkArguments =
          type.typeArguments.any((DartType type) => type is! DynamicType);
      Class declaration = type.classNode;
      VariableDeclaration typeExpression =
          new VariableDeclaration(null, initializer: createRuntimeType(type));
      VariableDeclaration targetValue =
          new VariableDeclaration(null, initializer: target);
      Expression markerClassTest = new IsExpression(
          new VariableGet(targetValue), rtiLibrary.markerClass.rawType);
      Expression tagCheck = new PropertyGet(new VariableGet(targetValue),
          builder.getTypeTestTagName(declaration));
      Expression check = new LogicalExpression(markerClassTest, "&&", tagCheck);
      if (checkArguments) {
        // TODO(karlklose): support a direct argument check, we already checked
        // the declaration.
        Expression uninterceptedCheck = new Let(
            typeExpression,
            builder.createIsSubtypeOf(
                new VariableGet(targetValue), new VariableGet(typeExpression),
                targetHasTypeProperty: true));
        check = new LogicalExpression(check, "&&", uninterceptedCheck);
      }
      return new Let(targetValue, check);
    } else {
      return builder.createIsSubtypeOf(target, createRuntimeType(type));
    }
  }

  Expression visitListLiteral(ListLiteral node) {
    trace(node);
    node.transformChildren(this);
    return builder.callAttachType(
        node,
        new InterfaceType(
            builder.coreTypes.listClass, <DartType>[node.typeArgument]));
  }

  Expression visitMapLiteral(MapLiteral node) {
    trace(node);
    node.transformChildren(this);
    return builder.callAttachType(
        node,
        new InterfaceType(builder.coreTypes.mapClass,
            <DartType>[node.keyType, node.valueType]));
  }

  Expression visitMethodInvocation(MethodInvocation node) {
    node.transformChildren(this);
    addTypeArgumentToGenericInvocation(node);
    return node;
  }

  bool isGenericMethod(FunctionNode node) {
    if (node.parent is Member) {
      Member member = node.parent;
      if (member is Constructor ||
          member is Procedure && member.kind == ProcedureKind.Factory) {
        return member.enclosingClass.typeParameters.length <
            node.typeParameters.length;
      }
    }
    return node.typeParameters.isNotEmpty;
  }

  void addTypeArgumentToGenericInvocation(InvocationExpression expression) {
    if (expression.arguments.types.length > 0) {
      ListLiteral genericMethodTypeParameters = new ListLiteral(
          expression.arguments.types
              .map(createRuntimeType)
              .toList(growable: false),
          typeArgument: rtiLibrary.typeType);
      expression.arguments.named.add(new NamedExpression(
          genericMethodTypeParametersName, genericMethodTypeParameters)
        ..parent = expression.arguments);
    }
  }

  void addTypeArgumentToGenericDeclaration(FunctionNode node) {
    if (isGenericMethod(node)) {
      VariableDeclaration genericMethodTypeParameters = new VariableDeclaration(
          genericMethodTypeParametersName,
          type: new InterfaceType(
              builder.coreTypes.listClass, <DartType>[rtiLibrary.typeType]));
      genericMethodTypeParameters.parent = node;
      node.namedParameters.insert(0, genericMethodTypeParameters);
    }
  }
}
