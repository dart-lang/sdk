// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.transformation.builder;

import '../asts.dart';
import 'package:kernel/ast.dart';
import 'dart:collection' show LinkedHashMap;
import 'binding.dart' show RuntimeLibrary;
import 'package:kernel/core_types.dart' show CoreTypes;

class Scope {
  final Map<String, TreeNode> names = <String, TreeNode>{};

  bool nameAlreadyTaken(String name, TreeNode node) {
    TreeNode existing = names[name];
    return existing != null && existing == node;
  }

  void add(String name, TreeNode node) {
    assert(!nameAlreadyTaken(name, node));
    names[name] = node;
  }
}

class Namer {
  final Scope scope;
  Namer([Scope scope]) : this.scope = scope ?? new Scope();

  String _getProposal(TreeNode node) {
    if (node is Class) {
      return node.name;
    }
    throw 'unsupported node: $node';
  }

  String getNameFor(TreeNode node) {
    String base = _getProposal(node);
    int id = 0;
    String proposal = base;
    while (scope.nameAlreadyTaken(proposal, node)) {
      proposal = "$base${++id}";
    }
    scope.add(proposal, node);
    return proposal;
  }
}

class RuntimeTypeSupportBuilder {
  // TODO(karlklose): group this together with other information about what
  // needs to be built.
  final LinkedHashMap<Class, int> reifiedClassIds =
      new LinkedHashMap<Class, int>();

  int currentDeclarationId = 0;

  final Field declarations;

  final RuntimeLibrary rtiLibrary;

  final CoreTypes coreTypes;

  final DartType declarationType;

  RuntimeTypeSupportBuilder(
      RuntimeLibrary rtiLibrary, CoreTypes coreTypes, Library mainLibrary)
      : declarations = new Field(new Name(r"$declarations"),
            isFinal: true, isStatic: true, fileUri: mainLibrary.fileUri),
        declarationType = new InterfaceType(coreTypes.listClass,
            <DartType>[rtiLibrary.declarationClass.rawType]),
        rtiLibrary = rtiLibrary,
        coreTypes = coreTypes {
    mainLibrary.addMember(declarations);
  }

  int addDeclaration(Class cls) {
    return reifiedClassIds.putIfAbsent(cls, () {
      return currentDeclarationId++;
    });
  }

  final Name indexOperatorName = new Name("[]");

  MethodInvocation createArrayAccess(Expression target, int index) {
    return new MethodInvocation(target, indexOperatorName,
        new Arguments(<Expression>[new IntLiteral(index)]));
  }

  Expression createAccessDeclaration(Class cls) {
    return createArrayAccess(new StaticGet(declarations), addDeclaration(cls));
  }

  Name getTypeTestTagName(Class cls) {
    return new Name('\$is\$${cls.name}');
  }

  Name typeVariableGetterName(TypeParameter parameter) {
    Class cls = getEnclosingClass(parameter);
    return new Name("\$${cls.name}\$${parameter.name}");
  }

  // A call to a constructor or factory of a class that we have not transformed
  // is wrapped in a call to `attachType`.
  Expression attachTypeToConstructorInvocation(
      InvocationExpression invocation, Member member) {
    assert(member is Procedure && member.kind == ProcedureKind.Factory ||
        member is Constructor);
    Class targetClass = member.parent;
    assert(targetClass != null);
    DartType type = new InterfaceType(targetClass, invocation.arguments.types);
    return callAttachType(invocation, type);
  }

  Expression callAttachType(Expression expression, DartType type) {
    return new StaticInvocation(rtiLibrary.attachTypeFunction,
        new Arguments(<Expression>[expression, createRuntimeType(type)]));
  }

  Expression createGetType(Expression receiver, {needsInterceptor: true}) {
    if (receiver is ThisExpression || !needsInterceptor) {
      return new PropertyGet(receiver, rtiLibrary.runtimeTypeName);
    }
    return new StaticInvocation(
        rtiLibrary.interceptorFunction, new Arguments(<Expression>[receiver]));
  }

  Expression createGetTypeArguments(Expression typeObject) {
    return new StaticInvocation(rtiLibrary.typeArgumentsFunction,
        new Arguments(<Expression>[typeObject]));
  }

  // TODO(karlklose): consider adding a unique identifier for each test site.
  /// `receiver.[subtypeTestName]([type])`
  StaticInvocation createIsSubtypeOf(
      Expression receiver, Expression typeExpression,
      {targetHasTypeProperty: false}) {
    Expression receiverType =
        createGetType(receiver, needsInterceptor: !targetHasTypeProperty);
    return new StaticInvocation(rtiLibrary.isSubtypeOfFunction,
        new Arguments(<Expression>[receiverType, typeExpression]));
  }

  int getTypeVariableIndex(TypeParameter variable) {
    Class c = getEnclosingClass(variable);
    List<TypeParameter> variables = c.typeParameters;
    for (int i = 0; i < variables.length; ++i) {
      if (variables[i].name == variable.name) {
        return i;
      }
    }
    throw new Exception(
        "Type variable $variable not found in enclosing class $c");
  }

  Expression createNewInterface(
      Expression declaration, Expression typeArgumentList) {
    List<Expression> arguments = <Expression>[declaration];
    if (typeArgumentList != null) {
      arguments.add(typeArgumentList);
    }
    return new ConstructorInvocation(
        rtiLibrary.interfaceTypeConstructor, new Arguments(arguments));
  }

  /// Returns `true` if [types] is a list of [TypeParameterType]s that exactly
  /// match the [TypeParameters] of the class they are defined in, i.e.,
  ///   for all 0 <= i < cls.typeParameters.length.
  ///     types[i].parameter == cls.typeParameters[i].
  bool matchesTypeParameters(List<DartType> types) {
    List<TypeParameter> parameters;
    for (int i = 0; i < types.length; ++i) {
      var type = types[i];
      if (type is TypeParameterType) {
        if (parameters == null) {
          Class cls = getEnclosingClass(type.parameter);
          parameters = cls.typeParameters;
          if (parameters.length != types.length) return false;
        }
        if (type.parameter != parameters[i]) {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  // TODO(karlklose): Refactor into visitor.
  // TODO(karlklose): split this method in different strategies.
  /// Creates an expression to represent a runtime type instance of type [type].
  Expression createRuntimeType(DartType type,
      {reifyTypeVariable: false,
      Expression createReference(Class cls),
      VariableDeclaration typeContext}) {
    Expression buildReifiedTypeVariable(TypeParameterType type) {
      Expression typeVariables = new PropertyGet(
          createReference(type.parameter.parent),
          rtiLibrary.variablesFieldName);
      return createArrayAccess(
          typeVariables, getTypeVariableIndex(type.parameter));
    }

    Expression buildDirectTypeVariableAccess(TypeParameterType variable) {
      Class cls = getEnclosingClass(variable.parameter);
      return extractTypeVariable(
          cls,
          variable.parameter,
          getTypeVariableIndex(variable.parameter),
          new VariableGet(typeContext));
    }

    Expression buildGetterTypeVariableAccess(TypeParameterType type) {
      return new PropertyGet(
          new ThisExpression(), typeVariableGetterName(type.parameter));
    }

    Expression buildTypeVariable(TypeParameterType type) {
      if (reifyTypeVariable) {
        assert(typeContext == null);
        return buildReifiedTypeVariable(type);
      } else if (typeContext != null) {
        return buildDirectTypeVariableAccess(type);
      } else {
        return buildGetterTypeVariableAccess(type);
      }
    }

    createReference ??= createAccessDeclaration;

    /// Helper to make recursive invocation more readable.
    Expression createPart(DartType type) {
      return createRuntimeType(type,
          reifyTypeVariable: reifyTypeVariable,
          createReference: createReference,
          typeContext: typeContext);
    }

    if (type is InterfaceType || type is Supertype) {
      InterfaceType interfaceType =
          (type is InterfaceType) ? type : (type as Supertype).asInterfaceType;
      Class cls = interfaceType.classNode;
      Expression declaration = createReference(cls);
      List<DartType> typeArguments = interfaceType.typeArguments;
      Expression typeArgumentList;
      if (typeArguments.isNotEmpty) {
        if (!reifyTypeVariable && matchesTypeParameters(typeArguments)) {
          // The type argument list corresponds to the list of type parameters
          // and we are not in "declaration emitter" mode, we can reuse the
          // type argument vector.
          TypeParameterType parameterType = typeArguments[0];
          Class cls = parameterType.parameter.parent;
          Expression typeObject = typeContext != null
              ? new VariableGet(typeContext)
              : createGetType(new ThisExpression());
          typeArgumentList =
              createGetTypeArguments(createCallAsInstanceOf(typeObject, cls));
        } else {
          typeArgumentList =
              new ListLiteral(typeArguments.map(createPart).toList());
        }
      }
      return createNewInterface(declaration, typeArgumentList);
    } else if (type is DynamicType) {
      return new ConstructorInvocation(
          rtiLibrary.dynamicTypeConstructor, new Arguments([]),
          isConst: true);
    } else if (type is TypeParameterType) {
      return buildTypeVariable(type);
    } else if (type is FunctionType) {
      FunctionType functionType = type;
      Expression returnType = createPart(functionType.returnType);
      List<Expression> encodedParameterTypes =
          functionType.positionalParameters.map(createPart).toList();
      List<NamedType> namedParameters = functionType.namedParameters;
      int data;
      if (namedParameters.isNotEmpty) {
        for (NamedType param in namedParameters) {
          encodedParameterTypes.add(new StringLiteral(param.name));
          encodedParameterTypes.add(createPart(param.type));
        }
        data = functionType.namedParameters.length << 1 | 1;
      } else {
        data = (functionType.positionalParameters.length -
                functionType.requiredParameterCount) <<
            1;
      }
      Expression functionTypeExpression = new ConstructorInvocation(
          rtiLibrary.interfaceTypeConstructor,
          new Arguments(
              <Expression>[createReference(coreTypes.functionClass)]));
      Arguments arguments = new Arguments(<Expression>[
        functionTypeExpression,
        returnType,
        new IntLiteral(data),
        new ListLiteral(encodedParameterTypes)
      ]);
      return new ConstructorInvocation(
          rtiLibrary.functionTypeConstructor, arguments);
    } else if (type is VoidType) {
      return new ConstructorInvocation(
          rtiLibrary.voidTypeConstructor, new Arguments(<Expression>[]));
    }
    return new InvalidExpression();
  }

  Expression createCallAsInstanceOf(Expression receiver, Class cls) {
    return new StaticInvocation(rtiLibrary.asInstanceOfFunction,
        new Arguments(<Expression>[receiver, createAccessDeclaration(cls)]));
  }

  /// `get get$<variable-name> => <get-type>.arguments[<variable-index>]`
  Member createTypeVariableGetter(
      Class cls, TypeParameter variable, int index) {
    Expression type = createGetType(new ThisExpression());
    Expression argument = extractTypeVariable(cls, variable, index, type);
    return new Procedure(
        typeVariableGetterName(variable),
        ProcedureKind.Getter,
        new FunctionNode(new ReturnStatement(argument),
            returnType: rtiLibrary.typeType),
        fileUri: cls.fileUri);
  }

  Expression extractTypeVariable(
      Class cls, TypeParameter variable, int index, Expression typeObject) {
    Expression type = createCallAsInstanceOf(typeObject, cls);
    Expression arguments = new StaticInvocation(
        rtiLibrary.typeArgumentsFunction, new Arguments(<Expression>[type]));
    // TODO(karlklose): use the global index instead of the local one.
    return createArrayAccess(arguments, index);
  }

  void insertAsFirstArgument(Arguments arguments, Expression expression) {
    expression.parent = arguments;
    arguments.positional.insert(0, expression);
  }

  /// Creates a call to the `init` function that completes the definition of a
  /// class by setting its (direct) supertypes.
  Expression createCallInit(
      VariableDeclaration declarations,
      int index,
      InterfaceType supertype,
      List<InterfaceType> interfaces,
      FunctionType callableType) {
    /// Helper to create a reference to the declaration in the declaration
    /// list instead of the field to avoid cycles if that field's
    /// initialization depends on the class we are currently initializing.
    Expression createReference(Class declaration) {
      int id = reifiedClassIds[declaration];
      return createArrayAccess(new VariableGet(declarations), id);
    }

    bool isNotMarkerInterface(InterfaceType interface) {
      return interface.classNode != rtiLibrary.markerClass;
    }

    Expression createLocalType(DartType type) {
      if (type == null) return null;
      return createRuntimeType(type,
          reifyTypeVariable: true, createReference: createReference);
    }

    Expression supertypeExpression =
        supertype == null ? new NullLiteral() : createLocalType(supertype);

    List<Expression> interfaceTypes = interfaces
        .where(isNotMarkerInterface)
        .map(createLocalType)
        .toList(growable: false);

    Expression callableTypeExpression = createLocalType(callableType);

    List<Expression> arguments = <Expression>[
      new VariableGet(declarations),
      new IntLiteral(index),
      supertypeExpression,
    ];

    if (interfaceTypes.isNotEmpty || callableTypeExpression != null) {
      arguments.add(new ListLiteral(interfaceTypes));
      if (callableTypeExpression != null) {
        arguments.add(callableTypeExpression);
      }
    }

    return new StaticInvocation(
        rtiLibrary.initFunction, new Arguments(arguments));
  }

  Expression createDeclarationsInitializer() {
    List<Statement> statements = <Statement>[];
    // Call function to allocate the class declarations given the names and
    // number of type variables of the classes.
    Namer classNamer = new Namer();
    List<Expression> names = <Expression>[];
    List<Expression> parameterCount = <Expression>[];
    reifiedClassIds.keys.forEach((Class c) {
      names.add(new StringLiteral(classNamer.getNameFor(c)));
      parameterCount.add(new IntLiteral(c.typeParameters.length));
    });
    Expression namesList = new ListLiteral(names);
    Expression parameterCountList = new ListLiteral(parameterCount);
    StaticInvocation callAllocate = new StaticInvocation(
        rtiLibrary.allocateDeclarationsFunction,
        new Arguments(<Expression>[namesList, parameterCountList]));

    VariableDeclaration parameter =
        new VariableDeclaration("d", type: declarationType);

    reifiedClassIds.forEach((Class cls, int id) {
      if (cls == rtiLibrary.markerClass) return;

      // If the class declares a `call` method, translate the signature to a
      // reified type.
      FunctionType callableType;
      Procedure call = cls.procedures.firstWhere(
          (Procedure p) => p.name.name == "call",
          orElse: () => null);
      if (call != null) {
        FunctionNode function = call.function;

        final namedParameters = new List<NamedType>();
        for (VariableDeclaration v in function.namedParameters) {
          namedParameters.add(new NamedType(v.name, v.type));
        }

        List<DartType> positionalArguments = function.positionalParameters
            .map((VariableDeclaration v) => v.type)
            .toList();
        callableType = new FunctionType(
            positionalArguments, function.returnType,
            namedParameters: namedParameters,
            requiredParameterCount: function.requiredParameterCount);
      }
      statements.add(new ExpressionStatement(createCallInit(
          parameter,
          id,
          cls.supertype?.asInterfaceType,
          cls.implementedTypes
              .map((Supertype type) => type?.asInterfaceType)
              .toList(),
          callableType)));
    });

    statements.add(new ReturnStatement(new VariableGet(parameter)));

    Expression function = new FunctionExpression(new FunctionNode(
        new Block(statements),
        positionalParameters: <VariableDeclaration>[parameter],
        returnType: declarationType));

    return new MethodInvocation(
        function, new Name("call"), new Arguments(<Expression>[callAllocate]));
  }

  void createDeclarations() {
    /// Recursively find all referenced classes in [type].
    void collectNewReferencedClasses(DartType type, Set<Class> newClasses) {
      if (type is InterfaceType || type is Supertype) {
        InterfaceType interfaceType = null;
        if (type is InterfaceType) {
          interfaceType = type;
        } else {
          interfaceType = (type as Supertype).asInterfaceType;
        }
        Class cls = interfaceType.classNode;
        if (!reifiedClassIds.containsKey(cls) && !newClasses.contains(cls)) {
          newClasses.add(cls);
        }

        interfaceType.typeArguments.forEach((DartType argument) {
          collectNewReferencedClasses(argument, newClasses);
        });
      }
      // TODO(karlklose): function types
    }

    Iterable<Class> classes = reifiedClassIds.keys;
    while (classes.isNotEmpty) {
      Set<Class> newClasses = new Set<Class>();
      for (Class c in classes) {
        collectNewReferencedClasses(c.supertype?.asInterfaceType, newClasses);
        c.implementedTypes.forEach((Supertype supertype) {
          collectNewReferencedClasses(supertype?.asInterfaceType, newClasses);
        });
      }
      for (Class newClass in newClasses) {
        // Make sure that there is a declaration field for the class and its
        // library's declaration list is setup.
        addDeclaration(newClass);
      }
      classes = newClasses;
    }
    Expression initializer = createDeclarationsInitializer();
    initializer.parent = declarations;
    declarations.initializer = initializer;
    declarations.type = declarationType;
  }

  Procedure createGetter(
      Name name, Expression expression, Class cls, DartType type) {
    return new Procedure(name, ProcedureKind.Getter,
        new FunctionNode(new ReturnStatement(expression), returnType: type),
        fileUri: cls.fileUri);
  }
}
