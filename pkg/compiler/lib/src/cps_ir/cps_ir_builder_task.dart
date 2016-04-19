// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder_task;

import 'package:js_runtime/shared/embedded_names.dart'
    show JsBuiltin, JsGetName;

import '../closure.dart' as closure;
import '../common.dart';
import '../common/names.dart' show Identifiers, Names, Selectors;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/expressions.dart';
import '../constants/values.dart' show ConstantValue;
import '../constants/values.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' show ConstructorBodyElementX;
import '../io/source_information.dart';
import '../js/js.dart' as js show js, Template, Expression, Name;
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/js_backend.dart'
    show JavaScriptBackend, SyntheticConstantKind;
import '../native/native.dart' show NativeBehavior, HasCapturedPlaceholders;
import '../resolution/operators.dart' as op;
import '../resolution/semantic_visitor.dart';
import '../resolution/tree_elements.dart' show TreeElements;
import '../ssa/types.dart' show TypeMaskFactory;
import '../tree/tree.dart' as ast;
import '../types/types.dart' show TypeMask;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../util/util.dart';
import 'cps_ir_builder.dart';
import 'cps_ir_nodes.dart' as ir;
import 'type_mask_system.dart' show TypeMaskSystem;
// TODO(karlklose): remove.

typedef void IrBuilderCallback(Element element, ir.FunctionDefinition irNode);

class ExplicitReceiverParameter implements Local {
  final ExecutableElement executableContext;

  ExplicitReceiverParameter(this.executableContext);

  String get name => 'receiver';
  String toString() => 'ExplicitReceiverParameter($executableContext)';
}

/// This task provides the interface to build IR nodes from [ast.Node]s, which
/// is used from the [CpsFunctionCompiler] to generate code.
///
/// This class is mainly there to correctly measure how long building the IR
/// takes.
class IrBuilderTask extends CompilerTask {
  final SourceInformationStrategy sourceInformationStrategy;

  String bailoutMessage = null;

  /// If not null, this function will be called with for each
  /// [ir.FunctionDefinition] node that has been built.
  IrBuilderCallback builderCallback;

  IrBuilderTask(Compiler compiler, this.sourceInformationStrategy,
      [this.builderCallback])
      : super(compiler);

  String get name => 'CPS builder';

  ir.FunctionDefinition buildNode(
      AstElement element, TypeMaskSystem typeMaskSystem) {
    return measure(() {
      bailoutMessage = null;

      ResolvedAst resolvedAst = element.resolvedAst;
      element = element.implementation;
      return reporter.withCurrentElement(element, () {
        SourceInformationBuilder sourceInformationBuilder =
            sourceInformationStrategy.createBuilderForContext(element);

        IrBuilderVisitor builder = new IrBuilderVisitor(
            resolvedAst, compiler, sourceInformationBuilder, typeMaskSystem);
        ir.FunctionDefinition irNode = builder.buildExecutable(element);
        if (irNode == null) {
          bailoutMessage = builder.bailoutMessage;
        } else if (builderCallback != null) {
          builderCallback(element, irNode);
        }
        return irNode;
      });
    });
  }
}

/// Translates the frontend AST of a method to its CPS IR.
///
/// The visitor has an [IrBuilder] which contains an IR fragment to build upon
/// and the current reaching definition of local variables.
///
/// Visiting a statement or expression extends the IR builder's fragment.
/// For expressions, the primitive holding the resulting value is returned.
/// For statements, `null` is returned.
// TODO(johnniwinther): Implement [SemanticDeclVisitor].
class IrBuilderVisitor extends ast.Visitor<ir.Primitive>
    with
        IrBuilderMixin<ast.Node>,
        SemanticSendResolvedMixin<ir.Primitive, dynamic>,
        ErrorBulkMixin<ir.Primitive, dynamic>,
        BaseImplementationOfStaticsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfLocalsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfDynamicsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfConstantsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfNewMixin<ir.Primitive, dynamic>,
        BaseImplementationOfCompoundsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfSetIfNullsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfIndexCompoundsMixin<ir.Primitive, dynamic>,
        BaseImplementationOfSuperIndexSetIfNullMixin<ir.Primitive, dynamic>
    implements SemanticSendVisitor<ir.Primitive, dynamic> {
  final ResolvedAst resolvedAst;
  final Compiler compiler;
  final SourceInformationBuilder sourceInformationBuilder;
  final TypeMaskSystem typeMaskSystem;

  /// A map from try statements in the source to analysis information about
  /// them.
  ///
  /// The analysis information includes the set of variables that must be
  /// copied into [ir.MutableVariable]s on entry to the try and copied out on
  /// exit.
  Map<ast.Node, TryStatementInfo> tryStatements = null;

  // In SSA terms, join-point continuation parameters are the phis and the
  // continuation invocation arguments are the corresponding phi inputs.  To
  // support name introduction and renaming for source level variables, we use
  // nested (delimited) visitors for constructing subparts of the IR that will
  // need renaming.  Each source variable is assigned an index.
  //
  // Each nested visitor maintains a list of free variable uses in the body.
  // These are implemented as a list of parameters, each with their own use
  // list of references.  When the delimited subexpression is plugged into the
  // surrounding context, the free occurrences can be captured or become free
  // occurrences in the next outer delimited subexpression.
  //
  // Each nested visitor maintains a list that maps indexes of variables
  // assigned in the delimited subexpression to their reaching definition ---
  // that is, the definition in effect at the hole in 'current'.  These are
  // used to determine if a join-point continuation needs to be passed
  // arguments, and what the arguments are.

  /// Construct a top-level visitor.
  IrBuilderVisitor(this.resolvedAst, this.compiler,
      this.sourceInformationBuilder, this.typeMaskSystem);

  TreeElements get elements => resolvedAst.elements;

  JavaScriptBackend get backend => compiler.backend;
  BackendHelpers get helpers => backend.helpers;
  DiagnosticReporter get reporter => compiler.reporter;

  String bailoutMessage = null;

  ir.Primitive visit(ast.Node node) => node.accept(this);

  @override
  ir.Primitive apply(ast.Node node, _) => node.accept(this);

  SemanticSendVisitor get sendVisitor => this;

  /// Result of closure conversion for the current body of code.
  ///
  /// Will be initialized upon entering the body of a function.
  /// It is computed by the [ClosureTranslator].
  closure.ClosureClassMap closureClassMap;

  /// If [node] has declarations for variables that should be boxed,
  /// returns a [ClosureScope] naming a box to create, and enumerating the
  /// variables that should be stored in the box.
  ///
  /// Also see [ClosureScope].
  ClosureScope getClosureScopeForNode(ast.Node node) {
    // We translate a ClosureScope from closure.dart into IR builder's variant
    // because the IR builder should not depend on the synthetic elements
    // created in closure.dart.
    return new ClosureScope(closureClassMap.capturingScopes[node]);
  }

  /// Returns the [ClosureScope] for any function, possibly different from the
  /// one currently being built.
  ClosureScope getClosureScopeForFunction(FunctionElement function) {
    closure.ClosureClassMap map = compiler.closureToClassMapper
        .computeClosureToClassMapping(function.resolvedAst);
    return new ClosureScope(map.capturingScopes[function.node]);
  }

  /// If the current function is a nested function with free variables (or a
  /// captured reference to `this`), returns a [ClosureEnvironment]
  /// indicating how to access these.
  ClosureEnvironment getClosureEnvironment() {
    return new ClosureEnvironment(closureClassMap);
  }

  IrBuilder getBuilderFor(Element element) {
    return new IrBuilder(
        new GlobalProgramInformation(compiler), backend.constants, element);
  }

  /// Builds the [ir.FunctionDefinition] for an executable element. In case the
  /// function uses features that cannot be expressed in the IR, this element
  /// returns `null`.
  ir.FunctionDefinition buildExecutable(ExecutableElement element) {
    return nullIfGiveup(() {
      ir.FunctionDefinition root;
      switch (element.kind) {
        case ElementKind.GENERATIVE_CONSTRUCTOR:
          root = buildConstructor(element);
          break;

        case ElementKind.GENERATIVE_CONSTRUCTOR_BODY:
          root = buildConstructorBody(element);
          break;

        case ElementKind.FACTORY_CONSTRUCTOR:
        case ElementKind.FUNCTION:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
          root = buildFunction(element);
          break;

        case ElementKind.FIELD:
          if (Elements.isStaticOrTopLevel(element)) {
            root = buildStaticFieldInitializer(element);
          } else {
            // Instance field initializers are inlined in the constructor,
            // so we shouldn't need to build anything here.
            // TODO(asgerf): But what should we return?
            return null;
          }
          break;

        default:
          reporter.internalError(element, "Unexpected element type $element");
      }
      return root;
    });
  }

  /// Loads the type variables for all super classes of [superClass] into the
  /// IR builder's environment with their corresponding values.
  ///
  /// The type variables for [currentClass] must already be in the IR builder's
  /// environment.
  ///
  /// Type variables are stored as [TypeVariableLocal] in the environment.
  ///
  /// This ensures that access to type variables mentioned inside the
  /// constructors and initializers will happen through the local environment
  /// instead of using 'this'.
  void loadTypeVariablesForSuperClasses(ClassElement currentClass) {
    if (currentClass.isObject) return;
    loadTypeVariablesForType(currentClass.supertype);
    if (currentClass is MixinApplicationElement) {
      loadTypeVariablesForType(currentClass.mixinType);
    }
  }

  /// Loads all type variables for [type] and all of its super classes into
  /// the environment. All type variables mentioned in [type] must already
  /// be in the environment.
  void loadTypeVariablesForType(InterfaceType type) {
    ClassElement clazz = type.element;
    assert(clazz.typeVariables.length == type.typeArguments.length);
    for (int i = 0; i < clazz.typeVariables.length; ++i) {
      irBuilder.declareTypeVariable(
          clazz.typeVariables[i], type.typeArguments[i]);
    }
    loadTypeVariablesForSuperClasses(clazz);
  }

  /// Returns the constructor body associated with the given constructor or
  /// creates a new constructor body, if none can be found.
  ///
  /// Returns `null` if the constructor does not have a body.
  ConstructorBodyElement getConstructorBody(FunctionElement constructor) {
    // TODO(asgerf): This is largely inherited from the SSA builder.
    // The ConstructorBodyElement has an invalid function signature, but we
    // cannot add a BoxLocal as parameter, because BoxLocal is not an element.
    // Instead of forging ParameterElements to forge a FunctionSignature, we
    // need a way to create backend methods without creating more fake elements.
    assert(constructor.isGenerativeConstructor);
    assert(constructor.isImplementation);
    if (constructor.isSynthesized) return null;
    ast.FunctionExpression node = constructor.node;
    // If we know the body doesn't have any code, we don't generate it.
    if (!node.hasBody) return null;
    if (node.hasEmptyBody) return null;
    ClassElement classElement = constructor.enclosingClass;
    ConstructorBodyElement bodyElement;
    classElement.forEachBackendMember((Element backendMember) {
      if (backendMember.isGenerativeConstructorBody) {
        ConstructorBodyElement body = backendMember;
        if (body.constructor == constructor) {
          bodyElement = backendMember;
        }
      }
    });
    if (bodyElement == null) {
      bodyElement = new ConstructorBodyElementX(constructor);
      classElement.addBackendMember(bodyElement);

      if (constructor.isPatch) {
        // Create origin body element for patched constructors.
        ConstructorBodyElementX patch = bodyElement;
        ConstructorBodyElementX origin =
            new ConstructorBodyElementX(constructor.origin);
        origin.applyPatch(patch);
        classElement.origin.addBackendMember(bodyElement.origin);
      }
    }
    assert(bodyElement.isGenerativeConstructorBody);
    return bodyElement;
  }

  /// The list of parameters to send from the generative constructor
  /// to the generative constructor body.
  ///
  /// Boxed parameters are not in the list, instead, a [BoxLocal] is passed
  /// containing the boxed parameters.
  ///
  /// For example, given the following constructor,
  ///
  ///     Foo(x, y) : field = (() => ++x) { print(x + y) }
  ///
  /// the argument `x` would be replaced by a [BoxLocal]:
  ///
  ///     Foo_body(box0, y) { print(box0.x + y) }
  ///
  List<Local> getConstructorBodyParameters(ConstructorBodyElement body) {
    List<Local> parameters = <Local>[];
    ClosureScope scope = getClosureScopeForFunction(body.constructor);
    if (scope != null) {
      parameters.add(scope.box);
    }
    body.functionSignature.orderedForEachParameter((ParameterElement param) {
      if (scope != null && scope.capturedVariables.containsKey(param)) {
        // Do not pass this parameter; the box will carry its value.
      } else {
        parameters.add(param);
      }
    });
    return parameters;
  }

  /// Builds the IR for a given constructor.
  ///
  /// 1. Computes the type held in all own or "inherited" type variables.
  /// 2. Evaluates all own or inherited field initializers.
  /// 3. Creates the object and assigns its fields and runtime type.
  /// 4. Calls constructor body and super constructor bodies.
  /// 5. Returns the created object.
  ir.FunctionDefinition buildConstructor(ConstructorElement constructor) {
    // TODO(asgerf): Optimization: If constructor is redirecting, then just
    //               evaluate arguments and call the target constructor.
    constructor = constructor.implementation;
    ClassElement classElement = constructor.enclosingClass.implementation;

    IrBuilder builder = getBuilderFor(constructor);

    final bool requiresTypeInformation =
        builder.program.requiresRuntimeTypesFor(classElement);

    return withBuilder(builder, () {
      // Setup parameters and create a box if anything is captured.
      List<Local> parameters = <Local>[];
      if (constructor.isGenerativeConstructor &&
          backend.isNativeOrExtendsNative(classElement)) {
        parameters.add(new ExplicitReceiverParameter(constructor));
      }
      constructor.functionSignature
          .orderedForEachParameter((ParameterElement p) => parameters.add(p));

      int firstTypeArgumentParameterIndex;

      // If instances of the class may need runtime type information, we add a
      // synthetic parameter for each type parameter.
      if (requiresTypeInformation) {
        firstTypeArgumentParameterIndex = parameters.length;
        classElement.typeVariables.forEach((TypeVariableType variable) {
          parameters.add(new closure.TypeVariableLocal(variable, constructor));
        });
      } else {
        classElement.typeVariables.forEach((TypeVariableType variable) {
          irBuilder.declareTypeVariable(variable, const DynamicType());
        });
      }

      // Create IR parameters and setup the environment.
      List<ir.Parameter> irParameters = builder.buildFunctionHeader(parameters,
          closureScope: getClosureScopeForFunction(constructor));

      // Create a list of the values of all type argument parameters, if any.
      ir.Primitive typeInformation;
      if (requiresTypeInformation) {
        typeInformation = new ir.TypeExpression(
            ir.TypeExpressionKind.INSTANCE,
            classElement.thisType,
            irParameters.sublist(firstTypeArgumentParameterIndex));
        irBuilder.add(new ir.LetPrim(typeInformation));
      } else {
        typeInformation = null;
      }

      // -- Load values for type variables declared on super classes --
      // Field initializers for super classes can reference these, so they
      // must be available before evaluating field initializers.
      // This could be interleaved with field initialization, but we choose do
      // get it out of the way here to avoid complications with mixins.
      loadTypeVariablesForSuperClasses(classElement);

      /// Maps each field from this class or a superclass to its initial value.
      Map<FieldElement, ir.Primitive> fieldValues =
          <FieldElement, ir.Primitive>{};

      // -- Evaluate field initializers ---
      // Evaluate field initializers in constructor and super constructors.
      List<ConstructorElement> constructorList = <ConstructorElement>[];
      evaluateConstructorFieldInitializers(
          constructor, constructorList, fieldValues);

      // All parameters in all constructors are now bound in the environment.
      // BoxLocals for captured parameters are also in the environment.
      // The initial value of all fields are now bound in [fieldValues].

      // --- Create the object ---
      // Get the initial field values in the canonical order.
      List<ir.Primitive> instanceArguments = <ir.Primitive>[];
      List<FieldElement> fields = <FieldElement>[];
      classElement.forEachInstanceField((ClassElement c, FieldElement field) {
        ir.Primitive value = fieldValues[field];
        if (value != null) {
          fields.add(field);
          instanceArguments.add(value);
        } else {
          assert(backend.isNativeOrExtendsNative(c));
          // Native fields are initialized elsewhere.
        }
      }, includeSuperAndInjectedMembers: true);

      ir.Primitive instance;
      if (constructor.isGenerativeConstructor &&
          backend.isNativeOrExtendsNative(classElement)) {
        instance = irParameters.first;
        instance.type =
            new TypeMask.exact(classElement, typeMaskSystem.classWorld);
        irBuilder.addPrimitive(new ir.ReceiverCheck.nullCheck(
            instance, Selectors.toString_, null));
        for (int i = 0; i < fields.length; i++) {
          irBuilder.addPrimitive(
              new ir.SetField(instance, fields[i], instanceArguments[i]));
        }
      } else {
        instance = new ir.CreateInstance(
            classElement,
            instanceArguments,
            typeInformation,
            constructor.hasNode
                ? sourceInformationBuilder.buildCreate(constructor.node)
                // TODO(johnniwinther): Provide source information for creation
                // through synthetic constructors.
                : null);
        irBuilder.add(new ir.LetPrim(instance));
      }

      // --- Call constructor bodies ---
      for (ConstructorElement target in constructorList) {
        ConstructorBodyElement bodyElement = getConstructorBody(target);
        if (bodyElement == null) continue; // Skip if constructor has no body.
        List<ir.Primitive> bodyArguments = <ir.Primitive>[];
        for (Local param in getConstructorBodyParameters(bodyElement)) {
          bodyArguments.add(irBuilder.environment.lookup(param));
        }
        Selector selector = new Selector.call(
            target.memberName, new CallStructure(bodyArguments.length));
        irBuilder.addPrimitive(new ir.InvokeMethodDirectly(
            instance, bodyElement, selector, bodyArguments, null));
      }

      // --- step 4: return the created object ----
      irBuilder.buildReturn(
          value: instance,
          sourceInformation:
              sourceInformationBuilder.buildImplicitReturn(constructor));

      return irBuilder.makeFunctionDefinition(
          sourceInformationBuilder.buildVariableDeclaration());
    });
  }

  /// Make a visitor suitable for translating ASTs taken from [context].
  ///
  /// Every visitor can only be applied to nodes in one context, because
  /// the [elements] field is specific to that context.
  IrBuilderVisitor makeVisitorForContext(AstElement context) {
    return new IrBuilderVisitor(context.resolvedAst, compiler,
        sourceInformationBuilder.forContext(context), typeMaskSystem);
  }

  /// Builds the IR for an [expression] taken from a different [context].
  ///
  /// Such expressions need to be compiled with a different [sourceFile] and
  /// [elements] mapping.
  ir.Primitive inlineExpression(AstElement context, ast.Expression expression) {
    IrBuilderVisitor visitor = makeVisitorForContext(context);
    return visitor.withBuilder(irBuilder, () => visitor.visit(expression));
  }

  /// Evaluate the implicit super call in the given mixin constructor.
  void forwardSynthesizedMixinConstructor(
      ConstructorElement constructor,
      List<ConstructorElement> supers,
      Map<FieldElement, ir.Primitive> fieldValues) {
    assert(constructor.enclosingClass.implementation.isMixinApplication);
    assert(constructor.isSynthesized);
    ConstructorElement target = constructor.definingConstructor.implementation;
    // The resolver gives us the exact same FunctionSignature for the two
    // constructors. The parameters for the synthesized constructor
    // are already in the environment, so the target constructor's parameters
    // are also in the environment since their elements are the same.
    assert(constructor.functionSignature == target.functionSignature);
    IrBuilderVisitor visitor = makeVisitorForContext(target);
    visitor.withBuilder(irBuilder, () {
      visitor.evaluateConstructorFieldInitializers(target, supers, fieldValues);
    });
  }

  /// In preparation of inlining (part of) [target], the [arguments] are moved
  /// into the environment bindings for the corresponding parameters.
  ///
  /// Defaults for optional arguments are evaluated in order to ensure
  /// all parameters are available in the environment.
  void loadArguments(ConstructorElement target, CallStructure call,
      List<ir.Primitive> arguments) {
    assert(target.isImplementation);
    assert(target.declaration == resolvedAst.element);
    FunctionSignature signature = target.functionSignature;

    // Establish a scope in case parameters are captured.
    ClosureScope scope = getClosureScopeForFunction(target);
    irBuilder.enterScope(scope);

    // Load required parameters
    int index = 0;
    signature.forEachRequiredParameter((ParameterElement param) {
      irBuilder.declareLocalVariable(param, initialValue: arguments[index]);
      index++;
    });

    // Load optional parameters, evaluating default values for omitted ones.
    signature.forEachOptionalParameter((ParameterElement param) {
      ir.Primitive value;
      // Load argument if provided.
      if (signature.optionalParametersAreNamed) {
        int nameIndex = call.namedArguments.indexOf(param.name);
        if (nameIndex != -1) {
          int translatedIndex = call.positionalArgumentCount + nameIndex;
          value = arguments[translatedIndex];
        }
      } else if (index < arguments.length) {
        value = arguments[index];
      }
      // Load default if argument was not provided.
      if (value == null) {
        if (param.initializer != null) {
          value = visit(param.initializer);
        } else {
          value = irBuilder.buildNullConstant();
        }
      }
      irBuilder.declareLocalVariable(param, initialValue: value);
      index++;
    });
  }

  /// Evaluates a call to the given constructor from an initializer list.
  ///
  /// Calls [loadArguments] and [evaluateConstructorFieldInitializers] in a
  /// visitor that has the proper [TreeElements] mapping.
  void evaluateConstructorCallFromInitializer(
      ConstructorElement target,
      CallStructure call,
      List<ir.Primitive> arguments,
      List<ConstructorElement> supers,
      Map<FieldElement, ir.Primitive> fieldValues) {
    IrBuilderVisitor visitor = makeVisitorForContext(target);
    visitor.withBuilder(irBuilder, () {
      visitor.loadArguments(target, call, arguments);
      visitor.evaluateConstructorFieldInitializers(target, supers, fieldValues);
    });
  }

  /// Evaluates all field initializers on [constructor] and all constructors
  /// invoked through `this()` or `super()` ("superconstructors").
  ///
  /// The resulting field values will be available in [fieldValues]. The values
  /// are not stored in any fields.
  ///
  /// This procedure assumes that the parameters to [constructor] are available
  /// in the IR builder's environment.
  ///
  /// The parameters to superconstructors are, however, assumed *not* to be in
  /// the environment, but will be put there by this procedure.
  ///
  /// All constructors will be added to [supers], with superconstructors first.
  void evaluateConstructorFieldInitializers(
      ConstructorElement constructor,
      List<ConstructorElement> supers,
      Map<FieldElement, ir.Primitive> fieldValues) {
    assert(constructor.isImplementation);
    assert(constructor.declaration == resolvedAst.element);
    ClassElement enclosingClass = constructor.enclosingClass.implementation;
    // Evaluate declaration-site field initializers, unless this constructor
    // redirects to another using a `this()` initializer. In that case, these
    // will be initialized by the effective target constructor.
    if (!constructor.isRedirectingGenerative) {
      enclosingClass.forEachInstanceField((ClassElement c, FieldElement field) {
        if (field.initializer != null) {
          fieldValues[field] = inlineExpression(field, field.initializer);
        } else {
          if (backend.isNativeOrExtendsNative(c)) {
            // Native field is initialized elsewhere.
          } else {
            // Fields without an initializer default to null.
            // This value will be overwritten below if an initializer is found.
            fieldValues[field] = irBuilder.buildNullConstant();
          }
        }
      });
    }
    // If this is a mixin constructor, it does not have its own parameter list
    // or initializer list. Directly forward to the super constructor.
    // Note that the declaration-site initializers originating from the
    // mixed-in class were handled above.
    if (enclosingClass.isMixinApplication) {
      forwardSynthesizedMixinConstructor(constructor, supers, fieldValues);
      return;
    }
    // Evaluate initializing parameters, e.g. `Foo(this.x)`.
    constructor.functionSignature
        .orderedForEachParameter((ParameterElement parameter) {
      if (parameter.isInitializingFormal) {
        InitializingFormalElement fieldParameter = parameter;
        fieldValues[fieldParameter.fieldElement] =
            irBuilder.buildLocalGet(parameter);
      }
    });
    // Evaluate constructor initializers, e.g. `Foo() : x = 50`.
    ast.FunctionExpression node = constructor.node;
    bool hasConstructorCall = false; // Has this() or super() initializer?
    if (node != null && node.initializers != null) {
      for (ast.Node initializer in node.initializers) {
        if (initializer is ast.SendSet) {
          // Field initializer.
          FieldElement field = elements[initializer];
          fieldValues[field] = visit(initializer.arguments.head);
        } else if (initializer is ast.Send) {
          // Super or this initializer.
          ConstructorElement target = elements[initializer].implementation;
          Selector selector = elements.getSelector(initializer);
          List<ir.Primitive> arguments = initializer.arguments.mapToList(visit);
          evaluateConstructorCallFromInitializer(
              target, selector.callStructure, arguments, supers, fieldValues);
          hasConstructorCall = true;
        } else {
          reporter.internalError(
              initializer, "Unexpected initializer type $initializer");
        }
      }
    }
    // If no super() or this() was found, also call default superconstructor.
    if (!hasConstructorCall && !enclosingClass.isObject) {
      ClassElement superClass = enclosingClass.superclass;
      FunctionElement target = superClass.lookupDefaultConstructor();
      if (target == null) {
        reporter.internalError(superClass, "No default constructor available.");
      }
      target = target.implementation;
      evaluateConstructorCallFromInitializer(
          target, CallStructure.NO_ARGS, const [], supers, fieldValues);
    }
    // Add this constructor after the superconstructors.
    supers.add(constructor);
  }

  TryBoxedVariables _analyzeTryBoxedVariables(ast.Node node) {
    TryBoxedVariables variables = new TryBoxedVariables(elements);
    try {
      variables.analyze(node);
    } catch (e) {
      bailoutMessage = variables.bailoutMessage;
      rethrow;
    }
    return variables;
  }

  /// Builds the IR for the body of a constructor.
  ///
  /// This function is invoked from one or more "factory" constructors built by
  /// [buildConstructor].
  ir.FunctionDefinition buildConstructorBody(ConstructorBodyElement body) {
    ConstructorElement constructor = body.constructor;
    ast.FunctionExpression node = constructor.node;
    closureClassMap = compiler.closureToClassMapper
        .computeClosureToClassMapping(constructor.resolvedAst);

    // We compute variables boxed in mutable variables on entry to each try
    // block, not including variables captured by a closure (which are boxed
    // in the heap).  This duplicates some of the work of closure conversion
    // without directly using the results.  This duplication is wasteful and
    // error-prone.
    // TODO(kmillikin): We should combine closure conversion and try/catch
    // variable analysis in some way.
    TryBoxedVariables variables = _analyzeTryBoxedVariables(node);
    tryStatements = variables.tryStatements;
    IrBuilder builder = getBuilderFor(body);

    return withBuilder(builder, () {
      irBuilder.buildConstructorBodyHeader(
          getConstructorBodyParameters(body), getClosureScopeForNode(node));
      visit(node.body);
      return irBuilder.makeFunctionDefinition(
          sourceInformationBuilder.buildVariableDeclaration());
    });
  }

  ir.FunctionDefinition buildFunction(FunctionElement element) {
    assert(invariant(element, element.isImplementation));
    ast.FunctionExpression node = element.node;

    assert(!element.isSynthesized);
    assert(node != null);
    assert(elements[node] != null);

    closureClassMap = compiler.closureToClassMapper
        .computeClosureToClassMapping(element.resolvedAst);
    TryBoxedVariables variables = _analyzeTryBoxedVariables(node);
    tryStatements = variables.tryStatements;
    IrBuilder builder = getBuilderFor(element);
    return withBuilder(
        builder, () => _makeFunctionBody(builder, element, node));
  }

  ir.FunctionDefinition buildStaticFieldInitializer(FieldElement element) {
    if (!backend.constants.lazyStatics.contains(element)) {
      return null; // Nothing to do.
    }
    closureClassMap = compiler.closureToClassMapper
        .computeClosureToClassMapping(element.resolvedAst);
    IrBuilder builder = getBuilderFor(element);
    return withBuilder(builder, () {
      irBuilder.buildFunctionHeader(<Local>[]);
      ir.Primitive initialValue = visit(element.initializer);
      ast.VariableDefinitions node = element.node;
      ast.SendSet sendSet = node.definitions.nodes.head;
      irBuilder.buildReturn(
          value: initialValue,
          sourceInformation:
              sourceInformationBuilder.buildReturn(sendSet.assignmentOperator));
      return irBuilder.makeFunctionDefinition(
          sourceInformationBuilder.buildVariableDeclaration());
    });
  }

  /// Builds the IR for a constant taken from a different [context].
  ///
  /// Such constants need to be compiled with a different [sourceFile] and
  /// [elements] mapping.
  ir.Primitive inlineConstant(AstElement context, ast.Expression exp) {
    IrBuilderVisitor visitor = makeVisitorForContext(context);
    return visitor.withBuilder(irBuilder, () => visitor.translateConstant(exp));
  }

  /// Creates a primitive for the default value of [parameter].
  ir.Primitive translateDefaultValue(ParameterElement parameter) {
    if (parameter.initializer == null ||
        // TODO(sigmund): JS doesn't support default values, so this should be
        // reported as an error earlier (Issue #25759).
        backend.isJsInterop(parameter.functionDeclaration)) {
      return irBuilder.buildNullConstant();
    } else {
      return inlineConstant(parameter.executableContext, parameter.initializer);
    }
  }

  /// Normalizes the argument list of a static invocation.
  ///
  /// A static invocation is one where the target is known.  The argument list
  /// [arguments] is normalized by adding default values for optional arguments
  /// that are not passed, and by sorting it in place so that named arguments
  /// appear in a canonical order.  A [CallStructure] reflecting this order
  /// is returned.
  CallStructure normalizeStaticArguments(CallStructure callStructure,
      FunctionElement target, List<ir.Primitive> arguments) {
    target = target.implementation;
    FunctionSignature signature = target.functionSignature;
    if (!signature.optionalParametersAreNamed &&
        signature.parameterCount == arguments.length) {
      return callStructure;
    }

    if (!signature.optionalParametersAreNamed) {
      int i = signature.requiredParameterCount;
      signature.forEachOptionalParameter((ParameterElement element) {
        if (i < callStructure.positionalArgumentCount) {
          ++i;
        } else {
          arguments.add(translateDefaultValue(element));
        }
      });
      return new CallStructure(signature.parameterCount);
    }

    int offset = signature.requiredParameterCount;
    List<ir.Primitive> namedArguments = arguments.sublist(offset);
    arguments.length = offset;
    List<String> normalizedNames = <String>[];
    // Iterate over the optional parameters of the signature, and try to
    // find them in the callStructure's named arguments. If found, we use the
    // value in the temporary list, otherwise the default value.
    signature.orderedOptionalParameters.forEach((ParameterElement element) {
      int nameIndex = callStructure.namedArguments.indexOf(element.name);
      arguments.add(nameIndex == -1
          ? translateDefaultValue(element)
          : namedArguments[nameIndex]);
      normalizedNames.add(element.name);
    });
    return new CallStructure(signature.parameterCount, normalizedNames);
  }

  /// Normalizes the argument list of a dynamic invocation.
  ///
  /// A dynamic invocation is one where the target is not known.  The argument
  /// list [arguments] is normalized by sorting it in place so that the named
  /// arguments appear in a canonical order.  A [CallStructure] reflecting this
  /// order is returned.
  CallStructure normalizeDynamicArguments(
      CallStructure callStructure, List<ir.Primitive> arguments) {
    assert(arguments.length == callStructure.argumentCount);
    if (callStructure.namedArguments.isEmpty) return callStructure;
    int destinationIndex = callStructure.positionalArgumentCount;
    List<ir.Primitive> namedArguments = arguments.sublist(destinationIndex);
    for (String argName in callStructure.getOrderedNamedArguments()) {
      int sourceIndex = callStructure.namedArguments.indexOf(argName);
      arguments[destinationIndex++] = namedArguments[sourceIndex];
    }
    return new CallStructure(
        callStructure.argumentCount, callStructure.getOrderedNamedArguments());
  }

  /// Read the value of [field].
  ir.Primitive buildStaticFieldGet(FieldElement field, SourceInformation src) {
    ConstantValue constant = getConstantForVariable(field);
    if (constant != null && !field.isAssignable) {
      typeMaskSystem.associateConstantValueWithElement(constant, field);
      return irBuilder.buildConstant(constant, sourceInformation: src);
    } else if (backend.constants.lazyStatics.contains(field)) {
      return irBuilder.addPrimitive(new ir.GetLazyStatic(field,
          sourceInformation: src,
          isFinal: compiler.world.fieldNeverChanges(field)));
    } else {
      return irBuilder.addPrimitive(new ir.GetStatic(field,
          sourceInformation: src,
          isFinal: compiler.world.fieldNeverChanges(field)));
    }
  }

  ir.FunctionDefinition _makeFunctionBody(
      IrBuilder builder, FunctionElement element, ast.FunctionExpression node) {
    FunctionSignature signature = element.functionSignature;
    List<Local> parameters = <Local>[];
    signature.orderedForEachParameter(
        (LocalParameterElement e) => parameters.add(e));

    bool requiresRuntimeTypes = false;
    if (element.isFactoryConstructor) {
      requiresRuntimeTypes =
          builder.program.requiresRuntimeTypesFor(element.enclosingElement);
      if (requiresRuntimeTypes) {
        // Type arguments are passed in as extra parameters.
        for (DartType typeVariable in element.enclosingClass.typeVariables) {
          parameters.add(new closure.TypeVariableLocal(typeVariable, element));
        }
      }
    }

    irBuilder.buildFunctionHeader(parameters,
        closureScope: getClosureScopeForNode(node),
        env: getClosureEnvironment());

    if (element == helpers.jsArrayTypedConstructor) {
      // Generate a body for JSArray<E>.typed(allocation):
      //
      //    t1 = setRuntimeTypeInfo(allocation, TypeExpression($E));
      //    return Refinement(t1, <JSArray>);
      //
      assert(parameters.length == 1 || parameters.length == 2);
      ir.Primitive allocation = irBuilder.buildLocalGet(parameters[0]);

      // Only call setRuntimeTypeInfo if JSArray requires the type parameter.
      if (requiresRuntimeTypes) {
        assert(parameters.length == 2);
        closure.TypeVariableLocal typeParameter = parameters[1];
        ir.Primitive typeArgument =
            irBuilder.buildTypeVariableAccess(typeParameter.typeVariable);

        ir.Primitive typeInformation = irBuilder.addPrimitive(
            new ir.TypeExpression(ir.TypeExpressionKind.INSTANCE,
                element.enclosingClass.thisType, <ir.Primitive>[typeArgument]));

        MethodElement helper = helpers.setRuntimeTypeInfo;
        CallStructure callStructure = CallStructure.TWO_ARGS;
        Selector selector = new Selector.call(helper.memberName, callStructure);
        allocation = irBuilder.buildInvokeStatic(
            helper,
            selector,
            <ir.Primitive>[allocation, typeInformation],
            sourceInformationBuilder.buildGeneric(node));
      }

      ir.Primitive refinement = irBuilder.addPrimitive(
          new ir.Refinement(allocation, typeMaskSystem.arrayType));

      irBuilder.buildReturn(
          value: refinement,
          sourceInformation:
              sourceInformationBuilder.buildImplicitReturn(element));
    } else {
      visit(node.body);
    }
    return irBuilder.makeFunctionDefinition(
        sourceInformationBuilder.buildVariableDeclaration());
  }

  /// Builds the IR for creating an instance of the closure class corresponding
  /// to the given nested function.
  closure.ClosureClassElement makeSubFunction(ast.FunctionExpression node) {
    closure.ClosureClassMap innerMap =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    closure.ClosureClassElement closureClass = innerMap.closureClassElement;
    return closureClass;
  }

  ir.Primitive visitFunctionExpression(ast.FunctionExpression node) {
    return irBuilder.buildFunctionExpression(
        makeSubFunction(node), sourceInformationBuilder.buildCreate(node));
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element = elements[node.function];
    Object inner = makeSubFunction(node.function);
    irBuilder.declareLocalFunction(
        element, inner, sourceInformationBuilder.buildCreate(node.function));
  }

  // ## Statements ##
  visitBlock(ast.Block node) {
    irBuilder.buildBlock(node.statements.nodes, build);
  }

  ir.Primitive visitBreakStatement(ast.BreakStatement node) {
    if (!irBuilder.buildBreak(elements.getTargetOf(node))) {
      reporter.internalError(node, "'break' target not found");
    }
    return null;
  }

  ir.Primitive visitContinueStatement(ast.ContinueStatement node) {
    if (!irBuilder.buildContinue(elements.getTargetOf(node))) {
      reporter.internalError(node, "'continue' target not found");
    }
    return null;
  }

  // Build(EmptyStatement, C) = C
  ir.Primitive visitEmptyStatement(ast.EmptyStatement node) {
    assert(irBuilder.isOpen);
    return null;
  }

  // Build(ExpressionStatement(e), C) = C'
  //   where (C', _) = Build(e, C)
  ir.Primitive visitExpressionStatement(ast.ExpressionStatement node) {
    assert(irBuilder.isOpen);
    if (node.expression is ast.Throw) {
      // Throw expressions that occur as statements are translated differently
      // from ones that occur as subexpressions.  This is achieved by peeking
      // at statement-level expressions here.
      irBuilder.buildThrow(visit(node.expression));
    } else {
      visit(node.expression);
    }
    return null;
  }

  ir.Primitive visitRethrow(ast.Rethrow node) {
    assert(irBuilder.isOpen);
    irBuilder.buildRethrow();
    return null;
  }

  /// Construct a method that executes the forwarding call to the target
  /// constructor.  This is only required, if the forwarding factory
  /// constructor can potentially be the target of a reflective call, because
  /// the builder shortcuts calls to redirecting factories at the call site
  /// (see [handleConstructorInvoke]).
  visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    ConstructorElement targetConstructor =
        elements.getRedirectingTargetConstructor(node).implementation;
    ConstructorElement redirectingConstructor =
        irBuilder.state.currentElement.implementation;
    List<ir.Primitive> arguments = <ir.Primitive>[];
    FunctionSignature redirectingSignature =
        redirectingConstructor.functionSignature;
    List<String> namedParameters = <String>[];
    redirectingSignature.forEachParameter((ParameterElement parameter) {
      arguments.add(irBuilder.environment.lookup(parameter));
      if (parameter.isNamed) {
        namedParameters.add(parameter.name);
      }
    });
    ClassElement cls = redirectingConstructor.enclosingClass;
    InterfaceType targetType =
        redirectingConstructor.computeEffectiveTargetType(cls.thisType);
    CallStructure callStructure =
        new CallStructure(redirectingSignature.parameterCount, namedParameters);
    callStructure =
        normalizeStaticArguments(callStructure, targetConstructor, arguments);
    ir.Primitive instance = irBuilder.buildConstructorInvocation(
        targetConstructor,
        callStructure,
        targetType,
        arguments,
        sourceInformationBuilder.buildNew(node));
    irBuilder.buildReturn(
        value: instance,
        sourceInformation: sourceInformationBuilder.buildReturn(node));
  }

  visitFor(ast.For node) {
    List<LocalElement> loopVariables = <LocalElement>[];
    if (node.initializer is ast.VariableDefinitions) {
      ast.VariableDefinitions definitions = node.initializer;
      for (ast.Node node in definitions.definitions.nodes) {
        LocalElement loopVariable = elements[node];
        loopVariables.add(loopVariable);
      }
    }

    JumpTarget target = elements.getTargetDefinition(node);
    irBuilder.buildFor(
        buildInitializer: subbuild(node.initializer),
        buildCondition: subbuild(node.condition),
        buildBody: subbuild(node.body),
        buildUpdate: subbuildSequence(node.update),
        closureScope: getClosureScopeForNode(node),
        loopVariables: loopVariables,
        target: target);
  }

  visitIf(ast.If node) {
    irBuilder.buildIf(build(node.condition), subbuild(node.thenPart),
        subbuild(node.elsePart), sourceInformationBuilder.buildIf(node));
  }

  visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    if (body is ast.Loop) {
      visit(body);
    } else {
      JumpTarget target = elements.getTargetDefinition(body);
      irBuilder.buildLabeledStatement(
          buildBody: subbuild(body), target: target);
    }
  }

  visitDoWhile(ast.DoWhile node) {
    irBuilder.buildDoWhile(
        buildBody: subbuild(node.body),
        buildCondition: subbuild(node.condition),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  visitWhile(ast.While node) {
    irBuilder.buildWhile(
        buildCondition: subbuild(node.condition),
        buildBody: subbuild(node.body),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  visitAsyncForIn(ast.AsyncForIn node) {
    // Translate await for into a loop over a StreamIterator.  The source
    // statement:
    //
    // await for (<decl> in <stream>) <body>
    //
    // is translated as if it were:
    //
    // var iterator = new StreamIterator(<stream>);
    // try {
    //   while (await iterator.hasNext()) {
    //     <decl> = await iterator.current;
    //     <body>
    //   }
    // } finally {
    //   await iterator.cancel();
    // }
    ir.Primitive stream = visit(node.expression);
    ir.Primitive dummyTypeArgument = irBuilder.buildNullConstant();
    ConstructorElement constructor = helpers.streamIteratorConstructor;
    ir.Primitive iterator = irBuilder.addPrimitive(new ir.InvokeConstructor(
        constructor.enclosingClass.thisType,
        constructor,
        new Selector.callConstructor(constructor.memberName, 1),
        <ir.Primitive>[stream, dummyTypeArgument],
        sourceInformationBuilder.buildGeneric(node)));

    buildTryBody(IrBuilder builder) {
      ir.Node buildLoopCondition(IrBuilder builder) {
        ir.Primitive moveNext = builder.buildDynamicInvocation(
            iterator,
            Selectors.moveNext,
            elements.getMoveNextTypeMask(node),
            <ir.Primitive>[],
            sourceInformationBuilder.buildForInMoveNext(node));
        return builder.addPrimitive(new ir.Await(moveNext));
      }

      ir.Node buildLoopBody(IrBuilder builder) {
        return withBuilder(builder, () {
          ir.Primitive current = irBuilder.buildDynamicInvocation(
              iterator,
              Selectors.current,
              elements.getCurrentTypeMask(node),
              <ir.Primitive>[],
              sourceInformationBuilder.buildForInCurrent(node));
          Element variable = elements.getForInVariable(node);
          SourceInformation sourceInformation =
              sourceInformationBuilder.buildForInSet(node);
          if (Elements.isLocal(variable)) {
            if (node.declaredIdentifier.asVariableDefinitions() != null) {
              irBuilder.declareLocalVariable(variable);
            }
            irBuilder.buildLocalVariableSet(
                variable, current, sourceInformation);
          } else if (Elements.isError(variable) ||
              Elements.isMalformed(variable)) {
            Selector selector =
                new Selector.setter(new Name(variable.name, variable.library));
            List<ir.Primitive> args = <ir.Primitive>[current];
            // Note the comparison below.  It can be the case that an element
            // isError and isMalformed.
            if (Elements.isError(variable)) {
              irBuilder.buildStaticNoSuchMethod(
                  selector, args, sourceInformation);
            } else {
              irBuilder.buildErroneousInvocation(
                  variable, selector, args, sourceInformation);
            }
          } else if (Elements.isStaticOrTopLevel(variable)) {
            if (variable.isField) {
              irBuilder.addPrimitive(new ir.SetStatic(variable, current));
            } else {
              irBuilder.buildStaticSetterSet(
                  variable, current, sourceInformation);
            }
          } else {
            ir.Primitive receiver = irBuilder.buildThis();
            ast.Node identifier = node.declaredIdentifier;
            irBuilder.buildDynamicSet(
                receiver,
                elements.getSelector(identifier),
                elements.getTypeMask(identifier),
                current,
                sourceInformation);
          }
          visit(node.body);
        });
      }

      builder.buildWhile(
          buildCondition: buildLoopCondition,
          buildBody: buildLoopBody,
          target: elements.getTargetDefinition(node),
          closureScope: getClosureScopeForNode(node));
    }

    ir.Node buildFinallyBody(IrBuilder builder) {
      ir.Primitive cancellation = builder.buildDynamicInvocation(
          iterator,
          Selectors.cancel,
          backend.dynamicType,
          <ir.Primitive>[],
          sourceInformationBuilder.buildGeneric(node));
      return builder.addPrimitive(new ir.Await(cancellation));
    }

    irBuilder.buildTryFinally(
        new TryStatementInfo(), buildTryBody, buildFinallyBody);
  }

  visitAwait(ast.Await node) {
    assert(irBuilder.isOpen);
    ir.Primitive value = visit(node.expression);
    return irBuilder.addPrimitive(new ir.Await(value));
  }

  visitYield(ast.Yield node) {
    assert(irBuilder.isOpen);
    ir.Primitive value = visit(node.expression);
    return irBuilder.addPrimitive(new ir.Yield(value, node.hasStar));
  }

  visitSyncForIn(ast.SyncForIn node) {
    // [node.declaredIdentifier] can be either an [ast.VariableDefinitions]
    // (defining a new local variable) or a send designating some existing
    // variable.
    ast.Node identifier = node.declaredIdentifier;
    ast.VariableDefinitions variableDeclaration =
        identifier.asVariableDefinitions();
    Element variableElement = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);

    irBuilder.buildForIn(
        buildExpression: subbuild(node.expression),
        buildVariableDeclaration: subbuild(variableDeclaration),
        variableElement: variableElement,
        variableSelector: selector,
        variableMask: elements.getTypeMask(identifier),
        variableSetSourceInformation:
            sourceInformationBuilder.buildForInSet(node),
        currentMask: elements.getCurrentTypeMask(node),
        currentSourceInformation:
            sourceInformationBuilder.buildForInCurrent(node),
        moveNextMask: elements.getMoveNextTypeMask(node),
        moveNextSourceInformation:
            sourceInformationBuilder.buildForInMoveNext(node),
        iteratorMask: elements.getIteratorTypeMask(node),
        iteratorSourceInformation:
            sourceInformationBuilder.buildForInIterator(node),
        buildBody: subbuild(node.body),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  /// If compiling with trusted type annotations, assumes that [value] is
  /// now known to be `null` or an instance of [type].
  ///
  /// This is also where we should add type checks in checked mode, but this
  /// is not supported yet.
  ir.Primitive checkType(ir.Primitive value, DartType dartType) {
    if (!compiler.options.trustTypeAnnotations) return value;
    TypeMask type = typeMaskSystem.subtypesOf(dartType).nullable();
    return irBuilder.addPrimitive(new ir.Refinement(value, type));
  }

  ir.Primitive checkTypeVsElement(ir.Primitive value, TypedElement element) {
    return checkType(value, element.type);
  }

  ir.Primitive visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(irBuilder.isOpen);
    for (ast.Node definition in node.definitions.nodes) {
      Element element = elements[definition];
      ir.Primitive initialValue;
      // Definitions are either SendSets if there is an initializer, or
      // Identifiers if there is no initializer.
      if (definition is ast.SendSet) {
        assert(!definition.arguments.isEmpty);
        assert(definition.arguments.tail.isEmpty);
        initialValue = visit(definition.arguments.head);
        initialValue = checkTypeVsElement(initialValue, element);
      } else {
        assert(definition is ast.Identifier);
      }
      irBuilder.declareLocalVariable(element, initialValue: initialValue);
    }
    return null;
  }

  static final RegExp nativeRedirectionRegExp =
      new RegExp(r'^[a-zA-Z][a-zA-Z_$0-9]*$');

  // Build(Return(e), C) = C'[InvokeContinuation(return, x)]
  //   where (C', x) = Build(e, C)
  //
  // Return without a subexpression is translated as if it were return null.
  visitReturn(ast.Return node) {
    assert(irBuilder.isOpen);
    SourceInformation source = sourceInformationBuilder.buildReturn(node);
    if (node.beginToken.value == 'native') {
      FunctionElement function = irBuilder.state.currentElement;
      assert(backend.isNative(function));
      ast.Node nativeBody = node.expression;
      if (nativeBody != null) {
        ast.LiteralString jsCode = nativeBody.asLiteralString();
        String javaScriptCode = jsCode.dartString.slowToString();
        assert(invariant(
            nativeBody, !nativeRedirectionRegExp.hasMatch(javaScriptCode),
            message: "Deprecated syntax, use @JSName('name') instead."));
        assert(invariant(
            nativeBody, function.functionSignature.parameterCount == 0,
            message: 'native "..." syntax is restricted to '
                'functions with zero parameters.'));
        irBuilder.buildNativeFunctionBody(function, javaScriptCode,
            sourceInformationBuilder.buildForeignCode(node));
      } else {
        String name = backend.nativeData.getFixedBackendName(function);
        irBuilder.buildRedirectingNativeFunctionBody(function, name, source);
      }
    } else {
      irBuilder.buildReturn(
          value: build(node.expression), sourceInformation: source);
    }
  }

  visitSwitchStatement(ast.SwitchStatement node) {
    // Dart switch cases can be labeled and be the target of continue from
    // within the switch.  Such cases are 'recursive'.  If there are any
    // recursive cases, we implement the switch using a pair of switches with
    // the second one switching over a state variable in a loop.  The first
    // switch contains the non-recursive cases, and the second switch contains
    // the recursive ones.
    //
    // For example, for the Dart switch:
    //
    // switch (E) {
    //   case 0:
    //     BODY0;
    //     break;
    //   LABEL0: case 1:
    //     BODY1;
    //     break;
    //   case 2:
    //     BODY2;
    //     continue LABEL1;
    //   LABEL1: case 3:
    //     BODY3;
    //     continue LABEL0;
    //   default:
    //     BODY4;
    // }
    //
    // We translate it as if it were the JavaScript:
    //
    // var state = -1;
    // switch (E) {
    //   case 0:
    //     BODY0;
    //     break;
    //   case 1:
    //     state = 0;  // Recursive, label ID = 0.
    //     break;
    //   case 2:
    //     BODY2;
    //     state = 1;  // Continue to label ID = 1.
    //     break;
    //   case 3:
    //     state = 1;  // Recursive, label ID = 1.
    //     break;
    //   default:
    //     BODY4;
    // }
    // L: while (state != -1) {
    //   case 0:
    //     BODY1;
    //     break L;  // Break from switch becomes break from loop.
    //   case 1:
    //     BODY2;
    //     state = 0;  // Continue to label ID = 0.
    //     break;
    // }
    assert(irBuilder.isOpen);
    // Preprocess: compute a list of cases that are the target of continue.
    // These are the so-called 'recursive' cases.
    List<JumpTarget> continueTargets = <JumpTarget>[];
    List<ast.Node> switchCases = node.cases.nodes.toList();
    for (ast.SwitchCase switchCase in switchCases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is ast.Label) {
          LabelDefinition definition = elements.getLabelDefinition(labelOrCase);
          if (definition != null && definition.isContinueTarget) {
            continueTargets.add(definition.target);
          }
        }
      }
    }

    // If any cases are continue targets, use an anonymous local value to
    // implement a state machine.  The initial value is -1.
    ir.Primitive initial;
    int stateIndex;
    if (continueTargets.isNotEmpty) {
      initial = irBuilder.buildIntegerConstant(-1);
      stateIndex = irBuilder.environment.length;
      irBuilder.environment.extend(null, initial);
    }

    // Use a simple switch for the non-recursive cases.  A break will go to the
    // join-point after the switch.  A continue to a labeled case will assign
    // to the state variable and go to the join-point.
    ir.Primitive value = visit(node.expression);
    JumpCollector join = new ForwardJumpCollector(irBuilder.environment,
        target: elements.getTargetDefinition(node));
    irBuilder.state.breakCollectors.add(join);
    for (int i = 0; i < continueTargets.length; ++i) {
      // The state value is i, the case's position in the list of recursive
      // cases.
      irBuilder.state.continueCollectors
          .add(new GotoJumpCollector(continueTargets[i], stateIndex, i, join));
    }

    // For each non-default case use a pair of functions, one to translate the
    // condition and one to translate the body.  For the default case use a
    // function to translate the body.  Use continueTargetIterator as a pointer
    // to the next recursive case.
    Iterator<JumpTarget> continueTargetIterator = continueTargets.iterator;
    continueTargetIterator.moveNext();
    List<SwitchCaseInfo> cases = <SwitchCaseInfo>[];
    SubbuildFunction buildDefaultBody;
    for (ast.SwitchCase switchCase in switchCases) {
      JumpTarget nextContinueTarget = continueTargetIterator.current;
      if (switchCase.isDefaultCase) {
        if (nextContinueTarget != null &&
            switchCase == nextContinueTarget.statement) {
          // In this simple switch, recursive cases are as if they immediately
          // continued to themselves.
          buildDefaultBody = nested(() {
            irBuilder.buildContinue(nextContinueTarget);
          });
          continueTargetIterator.moveNext();
        } else {
          // Non-recursive cases consist of the translation of the body.
          // For the default case, there is implicitly a break if control
          // flow reaches the end.
          buildDefaultBody = nested(() {
            irBuilder.buildSequence(switchCase.statements, visit);
            if (irBuilder.isOpen) irBuilder.jumpTo(join);
          });
        }
        continue;
      }

      ir.Primitive buildCondition(IrBuilder builder) {
        // There can be multiple cases sharing the same body, because empty
        // cases are allowed to fall through to the next one.  Each case is
        // a comparison, build a short-circuited disjunction of all of them.
        return withBuilder(builder, () {
          ir.Primitive condition;
          for (ast.Node labelOrCase in switchCase.labelsAndCases) {
            if (labelOrCase is ast.CaseMatch) {
              ir.Primitive buildComparison() {
                ir.Primitive constant =
                    translateConstant(labelOrCase.expression);
                return irBuilder.buildIdentical(value, constant);
              }

              if (condition == null) {
                condition = buildComparison();
              } else {
                condition = irBuilder.buildLogicalOperator(
                    condition,
                    nested(buildComparison),
                    sourceInformationBuilder.buildSwitchCase(switchCase),
                    isLazyOr: true);
              }
            }
          }
          return condition;
        });
      }

      SubbuildFunction buildBody;
      if (nextContinueTarget != null &&
          switchCase == nextContinueTarget.statement) {
        // Recursive cases are as if they immediately continued to themselves.
        buildBody = nested(() {
          irBuilder.buildContinue(nextContinueTarget);
        });
        continueTargetIterator.moveNext();
      } else {
        // Non-recursive cases consist of the translation of the body.  It is a
        // runtime error if control-flow reaches the end of the body of any but
        // the last case.
        buildBody = (IrBuilder builder) {
          withBuilder(builder, () {
            irBuilder.buildSequence(switchCase.statements, visit);
            if (irBuilder.isOpen) {
              if (switchCase == switchCases.last) {
                irBuilder.jumpTo(join);
              } else {
                Element error = helpers.fallThroughError;
                ir.Primitive exception = irBuilder.buildInvokeStatic(
                    error,
                    new Selector.fromElement(error),
                    <ir.Primitive>[],
                    sourceInformationBuilder.buildGeneric(node));
                irBuilder.buildThrow(exception);
              }
            }
          });
          return null;
        };
      }

      cases.add(new SwitchCaseInfo(buildCondition, buildBody,
          sourceInformationBuilder.buildSwitchCase(switchCase)));
    }

    irBuilder.buildSimpleSwitch(join, cases, buildDefaultBody);
    irBuilder.state.breakCollectors.removeLast();
    irBuilder.state.continueCollectors.length -= continueTargets.length;
    if (continueTargets.isEmpty) return;

    // If there were recursive cases build a while loop whose body is a
    // switch containing (only) the recursive cases.  The condition is
    // 'state != initialValue' so the loop is not taken when the state variable
    // has not been assigned.
    //
    // 'loop' is the join-point of the exits from the inner switch which will
    // perform another iteration of the loop.  'exit' is the join-point of the
    // breaks from the switch, outside the loop.
    JumpCollector loop = new ForwardJumpCollector(irBuilder.environment);
    JumpCollector exit = new ForwardJumpCollector(irBuilder.environment,
        target: elements.getTargetDefinition(node));
    irBuilder.state.breakCollectors.add(exit);
    for (int i = 0; i < continueTargets.length; ++i) {
      irBuilder.state.continueCollectors
          .add(new GotoJumpCollector(continueTargets[i], stateIndex, i, loop));
    }
    cases.clear();
    for (int i = 0; i < continueTargets.length; ++i) {
      // The conditions compare to the recursive case index.
      ir.Primitive buildCondition(IrBuilder builder) {
        ir.Primitive constant = builder.buildIntegerConstant(i);
        return builder.buildIdentical(
            builder.environment.index2value[stateIndex], constant);
      }

      ir.Primitive buildBody(IrBuilder builder) {
        withBuilder(builder, () {
          ast.SwitchCase switchCase = continueTargets[i].statement;
          irBuilder.buildSequence(switchCase.statements, visit);
          if (irBuilder.isOpen) {
            if (switchCase == switchCases.last) {
              irBuilder.jumpTo(exit);
            } else {
              Element error = helpers.fallThroughError;
              ir.Primitive exception = irBuilder.buildInvokeStatic(
                  error,
                  new Selector.fromElement(error),
                  <ir.Primitive>[],
                  sourceInformationBuilder.buildGeneric(node));
              irBuilder.buildThrow(exception);
            }
          }
        });
        return null;
      }

      cases.add(new SwitchCaseInfo(buildCondition, buildBody,
          sourceInformationBuilder.buildSwitch(node)));
    }

    // A loop with a simple switch in the body.
    IrBuilder whileBuilder = irBuilder.makeDelimitedBuilder();
    whileBuilder.buildWhile(buildCondition: (IrBuilder builder) {
      ir.Primitive condition = builder.buildIdentical(
          builder.environment.index2value[stateIndex], initial);
      return builder.buildNegation(
          condition, sourceInformationBuilder.buildSwitch(node));
    }, buildBody: (IrBuilder builder) {
      builder.buildSimpleSwitch(loop, cases, null);
    });
    // Jump to the exit continuation.  This jump is the body of the loop exit
    // continuation, so the loop exit continuation can be eta-reduced.  The
    // jump is here for simplicity because `buildWhile` does not expose the
    // loop's exit continuation directly and has already emitted all jumps
    // to it anyway.
    whileBuilder.jumpTo(exit);
    irBuilder.add(new ir.LetCont(exit.continuation, whileBuilder.root));
    irBuilder.environment = exit.environment;
    irBuilder.environment.discard(1); // Discard the state variable.
    irBuilder.state.breakCollectors.removeLast();
    irBuilder.state.continueCollectors.length -= continueTargets.length;
  }

  visitTryStatement(ast.TryStatement node) {
    List<CatchClauseInfo> catchClauseInfos = <CatchClauseInfo>[];
    for (ast.CatchBlock catchClause in node.catchBlocks.nodes) {
      LocalVariableElement exceptionVariable;
      if (catchClause.exception != null) {
        exceptionVariable = elements[catchClause.exception];
      }
      LocalVariableElement stackTraceVariable;
      if (catchClause.trace != null) {
        stackTraceVariable = elements[catchClause.trace];
      }
      DartType type;
      if (catchClause.onKeyword != null) {
        type = elements.getType(catchClause.type);
      }
      catchClauseInfos.add(new CatchClauseInfo(
          type: type,
          exceptionVariable: exceptionVariable,
          stackTraceVariable: stackTraceVariable,
          buildCatchBlock: subbuild(catchClause.block),
          sourceInformation: sourceInformationBuilder.buildCatch(catchClause)));
    }

    assert(!node.catchBlocks.isEmpty || node.finallyBlock != null);
    if (!node.catchBlocks.isEmpty && node.finallyBlock != null) {
      // Try/catch/finally is encoded in terms of try/catch and try/finally:
      //
      // try tryBlock catch (ex, st) catchBlock finally finallyBlock
      // ==>
      // try { try tryBlock catch (ex, st) catchBlock } finally finallyBlock
      irBuilder.buildTryFinally(tryStatements[node.finallyBlock],
          (IrBuilder inner) {
        inner.buildTryCatch(tryStatements[node.catchBlocks],
            subbuild(node.tryBlock), catchClauseInfos);
      }, subbuild(node.finallyBlock));
    } else if (!node.catchBlocks.isEmpty) {
      irBuilder.buildTryCatch(tryStatements[node.catchBlocks],
          subbuild(node.tryBlock), catchClauseInfos);
    } else {
      irBuilder.buildTryFinally(tryStatements[node.finallyBlock],
          subbuild(node.tryBlock), subbuild(node.finallyBlock));
    }
  }

  // ## Expressions ##
  ir.Primitive visitConditional(ast.Conditional node) {
    return irBuilder.buildConditional(
        build(node.condition),
        subbuild(node.thenExpression),
        subbuild(node.elseExpression),
        sourceInformationBuilder.buildIf(node));
  }

  // For all simple literals:
  // Build(Literal(c), C) = C[let val x = Constant(c) in [], x]
  ir.Primitive visitLiteralBool(ast.LiteralBool node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildBooleanConstant(node.value);
  }

  ir.Primitive visitLiteralDouble(ast.LiteralDouble node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildDoubleConstant(node.value);
  }

  ir.Primitive visitLiteralInt(ast.LiteralInt node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildIntegerConstant(node.value);
  }

  ir.Primitive visitLiteralNull(ast.LiteralNull node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildNullConstant();
  }

  ir.Primitive visitLiteralString(ast.LiteralString node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildDartStringConstant(node.dartString);
  }

  ConstantValue getConstantForNode(ast.Node node) {
    return irBuilder.state.constants.getConstantValueForNode(node, elements);
  }

  ConstantValue getConstantForVariable(VariableElement element) {
    return irBuilder.state.constants.getConstantValueForVariable(element);
  }

  ir.Primitive buildConstantExpression(
      ConstantExpression expression, SourceInformation sourceInformation) {
    return irBuilder.buildConstant(
        irBuilder.state.constants.getConstantValue(expression),
        sourceInformation: sourceInformation);
  }

  /// Returns the allocation site-specific type for a given allocation.
  ///
  /// Currently, it is an error to call this with anything that is not the
  /// allocation site for a List object (a literal list or a call to one
  /// of the List constructors).
  TypeMask getAllocationSiteType(ast.Node node) {
    return compiler.typesTask
        .getGuaranteedTypeOfNode(elements.analyzedElement, node);
  }

  ir.Primitive visitLiteralList(ast.LiteralList node) {
    if (node.isConst) {
      return translateConstant(node);
    }
    List<ir.Primitive> values = node.elements.nodes.mapToList(visit);
    InterfaceType type = elements.getType(node);
    TypeMask allocationSiteType = getAllocationSiteType(node);
    // TODO(sra): In checked mode, the elements must be checked as though
    // operator[]= is called.
    ir.Primitive list = irBuilder.buildListLiteral(type, values,
        allocationSiteType: allocationSiteType);
    if (type.treatAsRaw) return list;
    // Call JSArray<E>.typed(allocation) to install the reified type.
    ConstructorElement constructor = helpers.jsArrayTypedConstructor;
    ir.Primitive tagged = irBuilder.buildConstructorInvocation(
        constructor.effectiveTarget,
        CallStructure.ONE_ARG,
        constructor.computeEffectiveTargetType(type),
        <ir.Primitive>[list],
        sourceInformationBuilder.buildNew(node));

    if (allocationSiteType == null) return tagged;

    return irBuilder
        .addPrimitive(new ir.Refinement(tagged, allocationSiteType));
  }

  ir.Primitive visitLiteralMap(ast.LiteralMap node) {
    assert(irBuilder.isOpen);
    if (node.isConst) {
      return translateConstant(node);
    }

    InterfaceType type = elements.getType(node);

    if (node.entries.nodes.isEmpty) {
      if (type.treatAsRaw) {
        return irBuilder.buildStaticFunctionInvocation(
            helpers.mapLiteralUntypedEmptyMaker,
            <ir.Primitive>[],
            sourceInformationBuilder.buildNew(node));
      } else {
        ConstructorElement constructor = helpers.mapLiteralConstructorEmpty;
        return irBuilder.buildConstructorInvocation(
            constructor.effectiveTarget,
            CallStructure.NO_ARGS,
            constructor.computeEffectiveTargetType(type),
            <ir.Primitive>[],
            sourceInformationBuilder.buildNew(node));
      }
    }

    List<ir.Primitive> keysAndValues = <ir.Primitive>[];
    for (ast.LiteralMapEntry entry in node.entries.nodes.toList()) {
      keysAndValues.add(visit(entry.key));
      keysAndValues.add(visit(entry.value));
    }
    ir.Primitive keysAndValuesList =
        irBuilder.buildListLiteral(null, keysAndValues);

    if (type.treatAsRaw) {
      return irBuilder.buildStaticFunctionInvocation(
          helpers.mapLiteralUntypedMaker,
          <ir.Primitive>[keysAndValuesList],
          sourceInformationBuilder.buildNew(node));
    } else {
      ConstructorElement constructor = helpers.mapLiteralConstructor;
      return irBuilder.buildConstructorInvocation(
          constructor.effectiveTarget,
          CallStructure.ONE_ARG,
          constructor.computeEffectiveTargetType(type),
          <ir.Primitive>[keysAndValuesList],
          sourceInformationBuilder.buildNew(node));
    }
  }

  ir.Primitive visitLiteralSymbol(ast.LiteralSymbol node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitParenthesizedExpression(ast.ParenthesizedExpression node) {
    assert(irBuilder.isOpen);
    return visit(node.expression);
  }

  // Stores the result of visiting a CascadeReceiver, so we can return it from
  // its enclosing Cascade.
  ir.Primitive _currentCascadeReceiver;

  ir.Primitive visitCascadeReceiver(ast.CascadeReceiver node) {
    assert(irBuilder.isOpen);
    return _currentCascadeReceiver = visit(node.expression);
  }

  ir.Primitive visitCascade(ast.Cascade node) {
    assert(irBuilder.isOpen);
    var oldCascadeReceiver = _currentCascadeReceiver;
    // Throw away the result of visiting the expression.
    // Instead we return the result of visiting the CascadeReceiver.
    visit(node.expression);
    ir.Primitive receiver = _currentCascadeReceiver;
    _currentCascadeReceiver = oldCascadeReceiver;
    return receiver;
  }

  @override
  ir.Primitive visitAssert(ast.Assert node) {
    assert(irBuilder.isOpen);
    if (compiler.options.enableUserAssertions) {
      return giveup(node, 'assert in checked mode not implemented');
    } else {
      // The call to assert and its argument expression must be ignored
      // in production mode.
      // Assertions can only occur in expression statements, so no value needs
      // to be returned.
      return null;
    }
  }

  // ## Sends ##
  @override
  void previsitDeferredAccess(ast.Send node, PrefixElement prefix, _) {
    if (prefix != null) buildCheckDeferredIsLoaded(prefix, node);
  }

  /// Create a call to check that a deferred import has already been loaded.
  ir.Primitive buildCheckDeferredIsLoaded(PrefixElement prefix, ast.Send node) {
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildCall(node, node.selector);
    ir.Primitive name = irBuilder.buildStringConstant(
        compiler.deferredLoadTask.getImportDeferName(node, prefix));
    ir.Primitive uri =
        irBuilder.buildStringConstant('${prefix.deferredImport.uri}');
    return irBuilder.buildStaticFunctionInvocation(
        helpers.checkDeferredIsLoaded,
        <ir.Primitive>[name, uri],
        sourceInformation);
  }

  ir.Primitive visitNamedArgument(ast.NamedArgument node) {
    assert(irBuilder.isOpen);
    return visit(node.expression);
  }

  @override
  ir.Primitive visitExpressionInvoke(ast.Send node, ast.Node expression,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    ir.Primitive receiver = visit(expression);
    List<ir.Primitive> arguments = argumentsNode.nodes.mapToList(visit);
    callStructure = normalizeDynamicArguments(callStructure, arguments);
    return irBuilder.buildCallInvocation(receiver, callStructure, arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  /// Returns `true` if [node] is a super call.
  // TODO(johnniwinther): Remove the need for this.
  bool isSuperCall(ast.Send node) {
    return node != null && node.receiver != null && node.receiver.isSuper();
  }

  @override
  ir.Primitive handleConstantGet(
      ast.Node node, ConstantExpression constant, _) {
    return buildConstantExpression(
        constant, sourceInformationBuilder.buildGet(node));
  }

  /// If [node] is null, returns this.
  /// Otherwise visits [node] and returns the result.
  ir.Primitive translateReceiver(ast.Expression node) {
    return node != null ? visit(node) : irBuilder.buildThis();
  }

  @override
  ir.Primitive handleDynamicGet(
      ast.Send node, ast.Node receiver, Name name, _) {
    return irBuilder.buildDynamicGet(
        translateReceiver(receiver),
        new Selector.getter(name),
        elements.getTypeMask(node),
        sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitIfNotNullDynamicPropertyGet(
      ast.Send node, ast.Node receiver, Name name, _) {
    ir.Primitive target = visit(receiver);
    return irBuilder.buildIfNotNullSend(
        target,
        nested(() => irBuilder.buildDynamicGet(
            target,
            new Selector.getter(name),
            elements.getTypeMask(node),
            sourceInformationBuilder.buildGet(node))),
        sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive visitDynamicTypeLiteralGet(
      ast.Send node, ConstantExpression constant, _) {
    return buildConstantExpression(
        constant, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitLocalVariableGet(
      ast.Send node, LocalVariableElement element, _) {
    return element.isConst
        ? irBuilder.buildConstant(getConstantForVariable(element),
            sourceInformation: sourceInformationBuilder.buildGet(node))
        : irBuilder.buildLocalGet(element);
  }

  ir.Primitive handleLocalGet(ast.Send node, LocalElement element, _) {
    return irBuilder.buildLocalGet(element);
  }

  @override
  ir.Primitive handleStaticFunctionGet(
      ast.Send node, MethodElement function, _) {
    return irBuilder.addPrimitive(new ir.GetStatic(function, isFinal: true));
  }

  @override
  ir.Primitive handleStaticGetterGet(ast.Send node, FunctionElement getter, _) {
    return buildStaticGetterGet(
        getter, node, sourceInformationBuilder.buildGet(node));
  }

  /// Create a getter invocation of the static getter [getter]. This also
  /// handles the special case where [getter] is the `loadLibrary`
  /// pseudo-function on library prefixes of deferred imports.
  ir.Primitive buildStaticGetterGet(MethodElement getter, ast.Send node,
      SourceInformation sourceInformation) {
    if (getter.isDeferredLoaderGetter) {
      PrefixElement prefix = getter.enclosingElement;
      ir.Primitive loadId = irBuilder.buildStringConstant(
          compiler.deferredLoadTask.getImportDeferName(node, prefix));
      return irBuilder.buildStaticFunctionInvocation(
          compiler.loadLibraryFunction,
          <ir.Primitive>[loadId],
          sourceInformation);
    } else {
      return irBuilder.buildStaticGetterGet(getter, sourceInformation);
    }
  }

  @override
  ir.Primitive visitSuperFieldGet(ast.Send node, FieldElement field, _) {
    return irBuilder.buildSuperFieldGet(
        field, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitSuperGetterGet(ast.Send node, FunctionElement getter, _) {
    return irBuilder.buildSuperGetterGet(
        getter, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitSuperMethodGet(ast.Send node, MethodElement method, _) {
    return irBuilder.buildSuperMethodGet(
        method, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitUnresolvedSuperGet(ast.Send node, Element element, _) {
    return buildSuperNoSuchMethod(
        elements.getSelector(node),
        elements.getTypeMask(node),
        [],
        sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitUnresolvedSuperSet(
      ast.Send node, Element element, ast.Node rhs, _) {
    return buildSuperNoSuchMethod(
        elements.getSelector(node),
        elements.getTypeMask(node),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitThisGet(ast.Identifier node, _) {
    if (irBuilder.state.thisParameter == null) {
      // TODO(asgerf,johnniwinther): Should be in a visitInvalidThis method.
      // 'this' in static context. Just translate to null.
      assert(compiler.compilationFailed);
      return irBuilder.buildNullConstant();
    }
    return irBuilder.buildThis();
  }

  ir.Primitive translateTypeVariableTypeLiteral(
      TypeVariableElement element, SourceInformation sourceInformation) {
    return irBuilder.buildReifyTypeVariable(element.type, sourceInformation);
  }

  @override
  ir.Primitive visitTypeVariableTypeLiteralGet(
      ast.Send node, TypeVariableElement element, _) {
    return translateTypeVariableTypeLiteral(
        element, sourceInformationBuilder.buildGet(node));
  }

  ir.Primitive translateLogicalOperator(ast.Expression left,
      ast.Expression right, SourceInformation sourceInformation,
      {bool isLazyOr}) {
    ir.Primitive leftValue = visit(left);

    ir.Primitive buildRightValue(IrBuilder rightBuilder) {
      return withBuilder(rightBuilder, () => visit(right));
    }

    return irBuilder.buildLogicalOperator(
        leftValue, buildRightValue, sourceInformation,
        isLazyOr: isLazyOr);
  }

  @override
  ir.Primitive visitIfNull(ast.Send node, ast.Node left, ast.Node right, _) {
    return irBuilder.buildIfNull(
        build(left), subbuild(right), sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive visitLogicalAnd(
      ast.Send node, ast.Node left, ast.Node right, _) {
    return translateLogicalOperator(
        left, right, sourceInformationBuilder.buildIf(node),
        isLazyOr: false);
  }

  @override
  ir.Primitive visitLogicalOr(ast.Send node, ast.Node left, ast.Node right, _) {
    return translateLogicalOperator(
        left, right, sourceInformationBuilder.buildIf(node),
        isLazyOr: true);
  }

  @override
  ir.Primitive visitAs(ast.Send node, ast.Node expression, DartType type, _) {
    ir.Primitive receiver = visit(expression);
    return irBuilder.buildTypeOperator(
        receiver, type, sourceInformationBuilder.buildAs(node),
        isTypeTest: false);
  }

  @override
  ir.Primitive visitIs(ast.Send node, ast.Node expression, DartType type, _) {
    ir.Primitive value = visit(expression);
    return irBuilder.buildTypeOperator(
        value, type, sourceInformationBuilder.buildIs(node),
        isTypeTest: true);
  }

  @override
  ir.Primitive visitIsNot(
      ast.Send node, ast.Node expression, DartType type, _) {
    ir.Primitive value = visit(expression);
    ir.Primitive check = irBuilder.buildTypeOperator(
        value, type, sourceInformationBuilder.buildIs(node),
        isTypeTest: true);
    return irBuilder.buildNegation(
        check, sourceInformationBuilder.buildIf(node));
  }

  ir.Primitive translateBinary(ast.Send node, ast.Node left,
      op.BinaryOperator operator, ast.Node right) {
    ir.Primitive receiver = visit(left);
    Selector selector = new Selector.binaryOperator(operator.selectorName);
    List<ir.Primitive> arguments = <ir.Primitive>[visit(right)];
    CallStructure callStructure =
        normalizeDynamicArguments(selector.callStructure, arguments);
    return irBuilder.buildDynamicInvocation(
        receiver,
        new Selector(selector.kind, selector.memberName, callStructure),
        elements.getTypeMask(node),
        arguments,
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive visitBinary(ast.Send node, ast.Node left,
      op.BinaryOperator operator, ast.Node right, _) {
    return translateBinary(node, left, operator, right);
  }

  @override
  ir.Primitive visitIndex(ast.Send node, ast.Node receiver, ast.Node index, _) {
    ir.Primitive target = visit(receiver);
    Selector selector = new Selector.index();
    List<ir.Primitive> arguments = <ir.Primitive>[visit(index)];
    CallStructure callStructure =
        normalizeDynamicArguments(selector.callStructure, arguments);
    return irBuilder.buildDynamicInvocation(
        target,
        new Selector(selector.kind, selector.memberName, callStructure),
        elements.getTypeMask(node),
        arguments,
        sourceInformationBuilder.buildCall(receiver, node.selector));
  }

  ir.Primitive translateSuperBinary(
      FunctionElement function,
      op.BinaryOperator operator,
      ast.Node argument,
      SourceInformation sourceInformation) {
    List<ir.Primitive> arguments = <ir.Primitive>[visit(argument)];
    return irBuilder.buildSuperMethodInvocation(
        function, CallStructure.ONE_ARG, arguments, sourceInformation);
  }

  @override
  ir.Primitive visitSuperBinary(ast.Send node, FunctionElement function,
      op.BinaryOperator operator, ast.Node argument, _) {
    return translateSuperBinary(function, operator, argument,
        sourceInformationBuilder.buildBinary(node));
  }

  @override
  ir.Primitive visitSuperIndex(
      ast.Send node, FunctionElement function, ast.Node index, _) {
    return irBuilder.buildSuperIndex(
        function, visit(index), sourceInformationBuilder.buildIndex(node));
  }

  @override
  ir.Primitive visitEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    return translateBinary(node, left, op.BinaryOperator.EQ, right);
  }

  @override
  ir.Primitive visitSuperEquals(
      ast.Send node, FunctionElement function, ast.Node argument, _) {
    return translateSuperBinary(function, op.BinaryOperator.EQ, argument,
        sourceInformationBuilder.buildBinary(node));
  }

  @override
  ir.Primitive visitNot(ast.Send node, ast.Node expression, _) {
    return irBuilder.buildNegation(
        visit(expression), sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive visitNotEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    return irBuilder.buildNegation(
        translateBinary(node, left, op.BinaryOperator.NOT_EQ, right),
        sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive visitSuperNotEquals(
      ast.Send node, FunctionElement function, ast.Node argument, _) {
    return irBuilder.buildNegation(
        translateSuperBinary(function, op.BinaryOperator.NOT_EQ, argument,
            sourceInformationBuilder.buildBinary(node)),
        sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive visitUnary(
      ast.Send node, op.UnaryOperator operator, ast.Node expression, _) {
    // TODO(johnniwinther): Clean up the creation of selectors.
    Selector selector = operator.selector;
    ir.Primitive receiver = translateReceiver(expression);
    return irBuilder.buildDynamicInvocation(
        receiver,
        selector,
        elements.getTypeMask(node),
        const [],
        sourceInformationBuilder.buildCall(expression, node));
  }

  @override
  ir.Primitive visitSuperUnary(
      ast.Send node, op.UnaryOperator operator, FunctionElement function, _) {
    return irBuilder.buildSuperMethodInvocation(function, CallStructure.NO_ARGS,
        const [], sourceInformationBuilder.buildCall(node, node));
  }

  // TODO(johnniwinther): Handle this in the [IrBuilder] to ensure the correct
  // semantic correlation between arguments and invocation.
  CallStructure translateDynamicArguments(ast.NodeList nodeList,
      CallStructure callStructure, List<ir.Primitive> arguments) {
    assert(arguments.isEmpty);
    for (ast.Node node in nodeList) arguments.add(visit(node));
    return normalizeDynamicArguments(callStructure, arguments);
  }

  // TODO(johnniwinther): Handle this in the [IrBuilder] to ensure the correct
  // semantic correlation between arguments and invocation.
  CallStructure translateStaticArguments(ast.NodeList nodeList, Element element,
      CallStructure callStructure, List<ir.Primitive> arguments) {
    assert(arguments.isEmpty);
    for (ast.Node node in nodeList) arguments.add(visit(node));
    return normalizeStaticArguments(callStructure, element, arguments);
  }

  ir.Primitive translateCallInvoke(
      ir.Primitive target,
      ast.NodeList argumentsNode,
      CallStructure callStructure,
      SourceInformation sourceInformation) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildCallInvocation(
        target, callStructure, arguments, sourceInformation);
  }

  @override
  ir.Primitive handleConstantInvoke(ast.Send node, ConstantExpression constant,
      ast.NodeList arguments, CallStructure callStructure, _) {
    ir.Primitive target = buildConstantExpression(
        constant, sourceInformationBuilder.buildGet(node));
    return translateCallInvoke(target, arguments, callStructure,
        sourceInformationBuilder.buildCall(node, arguments));
  }

  @override
  ir.Primitive handleConstructorInvoke(
      ast.NewExpression node,
      ConstructorElement constructor,
      DartType type,
      ast.NodeList argumentsNode,
      CallStructure callStructure,
      _) {
    // TODO(sigmund): move these checks down after visiting arguments
    // (see issue #25355)
    ast.Send send = node.send;
    // If an allocation refers to a type using a deferred import prefix (e.g.
    // `new lib.A()`), we must ensure that the deferred import has already been
    // loaded.
    var prefix =
        compiler.deferredLoadTask.deferredPrefixElement(send, elements);
    if (prefix != null) buildCheckDeferredIsLoaded(prefix, send);

    // We also emit deferred import checks when using redirecting factories that
    // refer to deferred prefixes.
    if (constructor.isRedirectingFactory && !constructor.isCyclicRedirection) {
      ConstructorElement current = constructor;
      while (current.isRedirectingFactory) {
        var prefix = current.redirectionDeferredPrefix;
        if (prefix != null) buildCheckDeferredIsLoaded(prefix, send);
        current = current.immediateRedirectionTarget;
      }
    }

    List<ir.Primitive> arguments = argumentsNode.nodes.mapToList(visit);
    if (constructor.isGenerativeConstructor &&
        backend.isNativeOrExtendsNative(constructor.enclosingClass)) {
      arguments.insert(0, irBuilder.buildNullConstant());
    }
    // Use default values from the effective target, not the immediate target.
    ConstructorElement target;
    if (constructor == compiler.symbolConstructor) {
      // The Symbol constructor should perform validation of its argument
      // which is not expressible as a Dart const constructor.  Instead, the
      // libraries contain a dummy const constructor implementation that
      // doesn't perform validation and the compiler compiles a call to
      // (non-const) Symbol.validated when it sees new Symbol(...).
      target = helpers.symbolValidatedConstructor;
    } else {
      target = constructor.implementation;
    }
    while (target.isRedirectingFactory && !target.isCyclicRedirection) {
      target = target.effectiveTarget.implementation;
    }

    callStructure = normalizeStaticArguments(callStructure, target, arguments);
    TypeMask allocationSiteType;

    if (Elements.isFixedListConstructorCall(constructor, send, compiler) ||
        Elements.isGrowableListConstructorCall(constructor, send, compiler) ||
        Elements.isFilledListConstructorCall(constructor, send, compiler) ||
        Elements.isConstructorOfTypedArraySubclass(constructor, compiler)) {
      allocationSiteType = getAllocationSiteType(send);
    }
    ConstructorElement constructorImplementation = constructor.implementation;
    return irBuilder.buildConstructorInvocation(
        target,
        callStructure,
        constructorImplementation.computeEffectiveTargetType(type),
        arguments,
        sourceInformationBuilder.buildNew(node),
        allocationSiteType: allocationSiteType);
  }

  @override
  ir.Primitive handleDynamicInvoke(ast.Send node, ast.Node receiver,
      ast.NodeList argumentsNode, Selector selector, _) {
    ir.Primitive target = translateReceiver(receiver);
    List<ir.Primitive> arguments = <ir.Primitive>[];
    CallStructure callStructure = translateDynamicArguments(
        argumentsNode, selector.callStructure, arguments);
    return irBuilder.buildDynamicInvocation(
        target,
        new Selector(selector.kind, selector.memberName, callStructure),
        elements.getTypeMask(node),
        arguments,
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive visitIfNotNullDynamicPropertyInvoke(ast.Send node,
      ast.Node receiver, ast.NodeList argumentsNode, Selector selector, _) {
    ir.Primitive target = visit(receiver);
    return irBuilder.buildIfNotNullSend(target, nested(() {
      List<ir.Primitive> arguments = <ir.Primitive>[];
      CallStructure callStructure = translateDynamicArguments(
          argumentsNode, selector.callStructure, arguments);
      return irBuilder.buildDynamicInvocation(
          target,
          new Selector(selector.kind, selector.memberName, callStructure),
          elements.getTypeMask(node),
          arguments,
          sourceInformationBuilder.buildCall(node, node.selector));
    }), sourceInformationBuilder.buildIf(node));
  }

  ir.Primitive handleLocalInvoke(ast.Send node, LocalElement element,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    ir.Primitive function = irBuilder.buildLocalGet(element);
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildCallInvocation(function, callStructure, arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive handleStaticFieldGet(ast.Send node, FieldElement field, _) {
    return buildStaticFieldGet(field, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive handleStaticFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    SourceInformation src = sourceInformationBuilder.buildGet(node);
    ir.Primitive target = buildStaticFieldGet(field, src);
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildCallInvocation(target, callStructure, arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive handleStaticFunctionInvoke(ast.Send node, MethodElement function,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    if (compiler.backend.isForeign(function)) {
      return handleForeignCode(node, function, argumentsNode, callStructure);
    } else {
      List<ir.Primitive> arguments = <ir.Primitive>[];
      callStructure = translateStaticArguments(
          argumentsNode, function, callStructure, arguments);
      Selector selector = new Selector.call(function.memberName, callStructure);
      return irBuilder.buildInvokeStatic(function, selector, arguments,
          sourceInformationBuilder.buildCall(node, node.selector));
    }
  }

  @override
  ir.Primitive handleStaticFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return irBuilder.buildStaticNoSuchMethod(
        elements.getSelector(node),
        arguments.nodes.mapToList(visit),
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive handleStaticGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    ir.Primitive target = buildStaticGetterGet(
        getter, node, sourceInformationBuilder.buildGet(node));
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildCallInvocation(target, callStructure, arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive visitSuperFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    ir.Primitive target = irBuilder.buildSuperFieldGet(
        field, sourceInformationBuilder.buildGet(node));
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildCallInvocation(target, callStructure, arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive visitSuperGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    ir.Primitive target = irBuilder.buildSuperGetterGet(
        getter, sourceInformationBuilder.buildGet(node));
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildCallInvocation(target, callStructure, arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive visitSuperMethodInvoke(ast.Send node, MethodElement method,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure = translateStaticArguments(
        argumentsNode, method, callStructure, arguments);
    return irBuilder.buildSuperMethodInvocation(method, callStructure,
        arguments, sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive visitSuperMethodIncompatibleInvoke(
      ast.Send node,
      MethodElement method,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    List<ir.Primitive> normalizedArguments = <ir.Primitive>[];
    CallStructure normalizedCallStructure = translateDynamicArguments(
        arguments, callStructure, normalizedArguments);
    return buildSuperNoSuchMethod(
        new Selector.call(method.memberName, normalizedCallStructure),
        elements.getTypeMask(node),
        normalizedArguments,
        sourceInformationBuilder.buildCall(node, arguments));
  }

  @override
  ir.Primitive visitUnresolvedSuperInvoke(ast.Send node, Element element,
      ast.NodeList argumentsNode, Selector selector, _) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    CallStructure callStructure = translateDynamicArguments(
        argumentsNode, selector.callStructure, arguments);
    // TODO(johnniwinther): Supply a member name to the visit function instead
    // of looking it up in elements.
    return buildSuperNoSuchMethod(
        new Selector.call(elements.getSelector(node).memberName, callStructure),
        elements.getTypeMask(node),
        arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive visitThisInvoke(
      ast.Send node, ast.NodeList arguments, CallStructure callStructure, _) {
    return translateCallInvoke(irBuilder.buildThis(), arguments, callStructure,
        sourceInformationBuilder.buildCall(node, arguments));
  }

  @override
  ir.Primitive visitTypeVariableTypeLiteralInvoke(
      ast.Send node,
      TypeVariableElement element,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return translateCallInvoke(
        translateTypeVariableTypeLiteral(
            element, sourceInformationBuilder.buildGet(node)),
        arguments,
        callStructure,
        sourceInformationBuilder.buildCall(node, arguments));
  }

  @override
  ir.Primitive visitIndexSet(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, _) {
    return irBuilder.buildDynamicIndexSet(
        visit(receiver),
        elements.getTypeMask(node),
        visit(index),
        visit(rhs),
        sourceInformationBuilder.buildIndexSet(node));
  }

  @override
  ir.Primitive visitSuperIndexSet(ast.SendSet node, FunctionElement function,
      ast.Node index, ast.Node rhs, _) {
    return irBuilder.buildSuperIndexSet(function, visit(index), visit(rhs),
        sourceInformationBuilder.buildIndexSet(node));
  }

  ir.Primitive translateIfNull(ast.SendSet node, ir.Primitive getValue(),
      ast.Node rhs, void setValue(ir.Primitive value)) {
    ir.Primitive value = getValue();
    // Unlike other compound operators if-null conditionally will not do the
    // assignment operation.
    return irBuilder.buildIfNull(value, nested(() {
      ir.Primitive newValue = build(rhs);
      setValue(newValue);
      return newValue;
    }), sourceInformationBuilder.buildIf(node));
  }

  ir.Primitive translateCompounds(ast.SendSet node, ir.Primitive getValue(),
      CompoundRhs rhs, void setValue(ir.Primitive value)) {
    ir.Primitive value = getValue();
    op.BinaryOperator operator = rhs.operator;
    assert(operator.kind != op.BinaryOperatorKind.IF_NULL);

    Selector operatorSelector =
        new Selector.binaryOperator(operator.selectorName);
    ir.Primitive rhsValue;
    if (rhs.kind == CompoundKind.ASSIGNMENT) {
      rhsValue = visit(rhs.rhs);
    } else {
      rhsValue = irBuilder.buildIntegerConstant(1);
    }
    List<ir.Primitive> arguments = <ir.Primitive>[rhsValue];
    CallStructure callStructure =
        normalizeDynamicArguments(operatorSelector.callStructure, arguments);
    TypeMask operatorTypeMask =
        elements.getOperatorTypeMaskInComplexSendSet(node);
    SourceInformation operatorSourceInformation =
        sourceInformationBuilder.buildCall(node, node.assignmentOperator);
    ir.Primitive result = irBuilder.buildDynamicInvocation(
        value,
        new Selector(
            operatorSelector.kind, operatorSelector.memberName, callStructure),
        operatorTypeMask,
        arguments,
        operatorSourceInformation);
    setValue(result);
    return rhs.kind == CompoundKind.POSTFIX ? value : result;
  }

  ir.Primitive translateSetIfNull(ast.SendSet node, ir.Primitive getValue(),
      ast.Node rhs, void setValue(ir.Primitive value)) {
    ir.Primitive value = getValue();
    // Unlike other compound operators if-null conditionally will not do the
    // assignment operation.
    return irBuilder.buildIfNull(value, nested(() {
      ir.Primitive newValue = build(rhs);
      setValue(newValue);
      return newValue;
    }), sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive handleSuperIndexSetIfNull(
      ast.SendSet node,
      Element indexFunction,
      Element indexSetFunction,
      ast.Node index,
      ast.Node rhs,
      arg,
      {bool isGetterValid,
      bool isSetterValid}) {
    return translateSetIfNull(
        node,
        () {
          if (isGetterValid) {
            return irBuilder.buildSuperMethodGet(
                indexFunction, sourceInformationBuilder.buildIndex(node));
          } else {
            return buildSuperNoSuchGetter(
                indexFunction,
                elements.getGetterTypeMaskInComplexSendSet(node),
                sourceInformationBuilder.buildIndex(node));
          }
        },
        rhs,
        (ir.Primitive result) {
          if (isSetterValid) {
            return irBuilder.buildSuperMethodGet(
                indexSetFunction, sourceInformationBuilder.buildIndexSet(node));
          } else {
            return buildSuperNoSuchSetter(
                indexSetFunction,
                elements.getTypeMask(node),
                result,
                sourceInformationBuilder.buildIndexSet(node));
          }
        });
  }

  @override
  ir.Primitive visitIndexSetIfNull(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, arg) {
    ir.Primitive target = visit(receiver);
    ir.Primitive indexValue = visit(index);
    return translateSetIfNull(
        node,
        () {
          Selector selector = new Selector.index();
          List<ir.Primitive> arguments = <ir.Primitive>[indexValue];
          CallStructure callStructure =
              normalizeDynamicArguments(selector.callStructure, arguments);
          return irBuilder.buildDynamicInvocation(
              target,
              new Selector(selector.kind, selector.memberName, callStructure),
              elements.getGetterTypeMaskInComplexSendSet(node),
              arguments,
              sourceInformationBuilder.buildCall(receiver, node));
        },
        rhs,
        (ir.Primitive result) {
          irBuilder.buildDynamicIndexSet(target, elements.getTypeMask(node),
              indexValue, result, sourceInformationBuilder.buildIndexSet(node));
        });
  }

  @override
  ir.Primitive handleDynamicSet(
      ast.SendSet node, ast.Node receiver, Name name, ast.Node rhs, _) {
    return irBuilder.buildDynamicSet(
        translateReceiver(receiver),
        new Selector.setter(name),
        elements.getTypeMask(node),
        visit(rhs),
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitIfNotNullDynamicPropertySet(
      ast.SendSet node, ast.Node receiver, Name name, ast.Node rhs, _) {
    ir.Primitive target = visit(receiver);
    return irBuilder.buildIfNotNullSend(
        target,
        nested(() => irBuilder.buildDynamicSet(
            target,
            new Selector.setter(name),
            elements.getTypeMask(node),
            visit(rhs),
            sourceInformationBuilder.buildAssignment(node))),
        sourceInformationBuilder.buildIf(node));
  }

  @override
  ir.Primitive handleLocalSet(
      ast.SendSet node, LocalElement element, ast.Node rhs, _) {
    ir.Primitive value = visit(rhs);
    value = checkTypeVsElement(value, element);
    return irBuilder.buildLocalVariableSet(
        element, value, sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive handleStaticFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    ir.Primitive value = visit(rhs);
    irBuilder.addPrimitive(new ir.SetStatic(
        field, value, sourceInformationBuilder.buildAssignment(node)));
    return value;
  }

  @override
  ir.Primitive visitSuperFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    return irBuilder.buildSuperFieldSet(
        field, visit(rhs), sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitSuperSetterSet(
      ast.SendSet node, FunctionElement setter, ast.Node rhs, _) {
    return irBuilder.buildSuperSetterSet(
        setter, visit(rhs), sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitUnresolvedSuperIndexSet(
      ast.Send node, Element element, ast.Node index, ast.Node rhs, arg) {
    return giveup(node, 'visitUnresolvedSuperIndexSet');
  }

  @override
  ir.Primitive handleStaticSetterSet(
      ast.SendSet node, FunctionElement setter, ast.Node rhs, _) {
    return irBuilder.buildStaticSetterSet(
        setter, visit(rhs), sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive handleTypeLiteralConstantCompounds(
      ast.SendSet node, ConstantExpression constant, CompoundRhs rhs, arg) {
    SourceInformation src = sourceInformationBuilder.buildGet(node);
    return translateCompounds(
        node,
        () {
          return buildConstantExpression(constant, src);
        },
        rhs,
        (ir.Primitive value) {
          // The binary operator will throw before this.
        });
  }

  @override
  ir.Primitive handleTypeLiteralConstantSetIfNulls(
      ast.SendSet node, ConstantExpression constant, ast.Node rhs, _) {
    // The type literal is never `null`.
    return buildConstantExpression(
        constant, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive handleDynamicCompounds(
      ast.SendSet node, ast.Node receiver, Name name, CompoundRhs rhs, arg) {
    ir.Primitive target = translateReceiver(receiver);
    ir.Primitive helper() {
      return translateCompounds(
          node,
          () {
            return irBuilder.buildDynamicGet(
                target,
                new Selector.getter(name),
                elements.getGetterTypeMaskInComplexSendSet(node),
                sourceInformationBuilder.buildGet(node));
          },
          rhs,
          (ir.Primitive result) {
            irBuilder.buildDynamicSet(
                target,
                new Selector.setter(name),
                elements.getTypeMask(node),
                result,
                sourceInformationBuilder.buildAssignment(node));
          });
    }
    return node.isConditional
        ? irBuilder.buildIfNotNullSend(
            target, nested(helper), sourceInformationBuilder.buildIf(node))
        : helper();
  }

  @override
  ir.Primitive handleDynamicSetIfNulls(
      ast.Send node, ast.Node receiver, Name name, ast.Node rhs, _) {
    ir.Primitive target = translateReceiver(receiver);
    ir.Primitive helper() {
      return translateSetIfNull(
          node,
          () {
            return irBuilder.buildDynamicGet(
                target,
                new Selector.getter(name),
                elements.getGetterTypeMaskInComplexSendSet(node),
                sourceInformationBuilder.buildGet(node));
          },
          rhs,
          (ir.Primitive result) {
            irBuilder.buildDynamicSet(
                target,
                new Selector.setter(name),
                elements.getTypeMask(node),
                result,
                sourceInformationBuilder.buildAssignment(node));
          });
    }
    return node.isConditional
        ? irBuilder.buildIfNotNullSend(
            target, nested(helper), sourceInformationBuilder.buildIf(node))
        : helper();
  }

  ir.Primitive buildLocalNoSuchSetter(LocalElement local, ir.Primitive value,
      SourceInformation sourceInformation) {
    Selector selector = new Selector.setter(
        new Name(local.name, local.library, isSetter: true));
    return irBuilder.buildStaticNoSuchMethod(
        selector, [value], sourceInformation);
  }

  @override
  ir.Primitive handleLocalCompounds(
      ast.SendSet node, LocalElement local, CompoundRhs rhs, arg,
      {bool isSetterValid}) {
    return translateCompounds(
        node,
        () {
          return irBuilder.buildLocalGet(local);
        },
        rhs,
        (ir.Primitive result) {
          if (isSetterValid) {
            irBuilder.buildLocalVariableSet(
                local, result, sourceInformationBuilder.buildAssignment(node));
          } else {
            Selector selector = new Selector.setter(
                new Name(local.name, local.library, isSetter: true));
            irBuilder.buildStaticNoSuchMethod(selector, <ir.Primitive>[result],
                sourceInformationBuilder.buildAssignment(node));
          }
        });
  }

  @override
  ir.Primitive handleLocalSetIfNulls(
      ast.SendSet node, LocalElement local, ast.Node rhs, _,
      {bool isSetterValid}) {
    return translateSetIfNull(
        node,
        () {
          return irBuilder.buildLocalGet(local,
              sourceInformation: sourceInformationBuilder.buildGet(node));
        },
        rhs,
        (ir.Primitive result) {
          SourceInformation sourceInformation =
              sourceInformationBuilder.buildAssignment(node);
          if (isSetterValid) {
            irBuilder.buildLocalVariableSet(local, result, sourceInformation);
          } else {
            Selector selector = new Selector.setter(
                new Name(local.name, local.library, isSetter: true));
            irBuilder.buildStaticNoSuchMethod(
                selector, <ir.Primitive>[result], sourceInformation);
          }
        });
  }

  @override
  ir.Primitive handleStaticCompounds(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      arg) {
    return translateCompounds(
        node,
        () {
          SourceInformation sourceInformation =
              sourceInformationBuilder.buildGet(node);
          switch (getterKind) {
            case CompoundGetter.FIELD:
              return buildStaticFieldGet(getter, sourceInformation);
            case CompoundGetter.GETTER:
              return buildStaticGetterGet(getter, node, sourceInformation);
            case CompoundGetter.METHOD:
              return irBuilder.addPrimitive(new ir.GetStatic(getter,
                  sourceInformation: sourceInformation, isFinal: true));
            case CompoundGetter.UNRESOLVED:
              return irBuilder.buildStaticNoSuchMethod(
                  new Selector.getter(new Name(getter.name, getter.library)),
                  <ir.Primitive>[],
                  sourceInformation);
          }
        },
        rhs,
        (ir.Primitive result) {
          SourceInformation sourceInformation =
              sourceInformationBuilder.buildAssignment(node);
          switch (setterKind) {
            case CompoundSetter.FIELD:
              irBuilder.addPrimitive(
                  new ir.SetStatic(setter, result, sourceInformation));
              return;
            case CompoundSetter.SETTER:
              irBuilder.buildStaticSetterSet(setter, result, sourceInformation);
              return;
            case CompoundSetter.INVALID:
              irBuilder.buildStaticNoSuchMethod(
                  new Selector.setter(new Name(setter.name, setter.library)),
                  <ir.Primitive>[result],
                  sourceInformation);
              return;
          }
        });
  }

  @override
  ir.Primitive handleStaticSetIfNulls(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      ast.Node rhs,
      _) {
    return translateSetIfNull(
        node,
        () {
          SourceInformation sourceInformation =
              sourceInformationBuilder.buildGet(node);
          switch (getterKind) {
            case CompoundGetter.FIELD:
              return buildStaticFieldGet(getter, sourceInformation);
            case CompoundGetter.GETTER:
              return buildStaticGetterGet(getter, node, sourceInformation);
            case CompoundGetter.METHOD:
              return irBuilder.addPrimitive(new ir.GetStatic(getter,
                  sourceInformation: sourceInformation, isFinal: true));
            case CompoundGetter.UNRESOLVED:
              return irBuilder.buildStaticNoSuchMethod(
                  new Selector.getter(new Name(getter.name, getter.library)),
                  <ir.Primitive>[],
                  sourceInformation);
          }
        },
        rhs,
        (ir.Primitive result) {
          SourceInformation sourceInformation =
              sourceInformationBuilder.buildAssignment(node);
          switch (setterKind) {
            case CompoundSetter.FIELD:
              irBuilder.addPrimitive(
                  new ir.SetStatic(setter, result, sourceInformation));
              return;
            case CompoundSetter.SETTER:
              irBuilder.buildStaticSetterSet(setter, result, sourceInformation);
              return;
            case CompoundSetter.INVALID:
              irBuilder.buildStaticNoSuchMethod(
                  new Selector.setter(new Name(setter.name, setter.library)),
                  <ir.Primitive>[result],
                  sourceInformation);
              return;
          }
        });
  }

  ir.Primitive buildSuperNoSuchGetter(
      Element element, TypeMask mask, SourceInformation sourceInformation) {
    return buildSuperNoSuchMethod(
        new Selector.getter(new Name(element.name, element.library)),
        mask,
        const <ir.Primitive>[],
        sourceInformation);
  }

  ir.Primitive buildSuperNoSuchSetter(Element element, TypeMask mask,
      ir.Primitive value, SourceInformation sourceInformation) {
    return buildSuperNoSuchMethod(
        new Selector.setter(new Name(element.name, element.library)),
        mask,
        <ir.Primitive>[value],
        sourceInformation);
  }

  @override
  ir.Primitive handleSuperCompounds(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      arg) {
    return translateCompounds(
        node,
        () {
          switch (getterKind) {
            case CompoundGetter.FIELD:
              return irBuilder.buildSuperFieldGet(
                  getter, sourceInformationBuilder.buildGet(node));
            case CompoundGetter.GETTER:
              return irBuilder.buildSuperGetterGet(
                  getter, sourceInformationBuilder.buildGet(node));
            case CompoundGetter.METHOD:
              return irBuilder.buildSuperMethodGet(
                  getter, sourceInformationBuilder.buildGet(node));
            case CompoundGetter.UNRESOLVED:
              return buildSuperNoSuchGetter(
                  getter,
                  elements.getGetterTypeMaskInComplexSendSet(node),
                  sourceInformationBuilder.buildGet(node));
          }
        },
        rhs,
        (ir.Primitive result) {
          switch (setterKind) {
            case CompoundSetter.FIELD:
              irBuilder.buildSuperFieldSet(setter, result,
                  sourceInformationBuilder.buildAssignment(node));
              return;
            case CompoundSetter.SETTER:
              irBuilder.buildSuperSetterSet(setter, result,
                  sourceInformationBuilder.buildAssignment(node));
              return;
            case CompoundSetter.INVALID:
              buildSuperNoSuchSetter(setter, elements.getTypeMask(node), result,
                  sourceInformationBuilder.buildAssignment(node));
              return;
          }
        });
  }

  @override
  ir.Primitive handleSuperSetIfNulls(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      ast.Node rhs,
      _) {
    return translateSetIfNull(
        node,
        () {
          switch (getterKind) {
            case CompoundGetter.FIELD:
              return irBuilder.buildSuperFieldGet(
                  getter, sourceInformationBuilder.buildGet(node));
            case CompoundGetter.GETTER:
              return irBuilder.buildSuperGetterGet(
                  getter, sourceInformationBuilder.buildGet(node));
            case CompoundGetter.METHOD:
              return irBuilder.buildSuperMethodGet(
                  getter, sourceInformationBuilder.buildGet(node));
            case CompoundGetter.UNRESOLVED:
              return buildSuperNoSuchGetter(
                  getter,
                  elements.getGetterTypeMaskInComplexSendSet(node),
                  sourceInformationBuilder.buildGet(node));
          }
        },
        rhs,
        (ir.Primitive result) {
          switch (setterKind) {
            case CompoundSetter.FIELD:
              irBuilder.buildSuperFieldSet(setter, result,
                  sourceInformationBuilder.buildAssignment(node));
              return;
            case CompoundSetter.SETTER:
              irBuilder.buildSuperSetterSet(setter, result,
                  sourceInformationBuilder.buildAssignment(node));
              return;
            case CompoundSetter.INVALID:
              buildSuperNoSuchSetter(setter, elements.getTypeMask(node), result,
                  sourceInformationBuilder.buildAssignment(node));
              return;
          }
        });
  }

  @override
  ir.Primitive handleTypeVariableTypeLiteralCompounds(ast.SendSet node,
      TypeVariableElement typeVariable, CompoundRhs rhs, arg) {
    return translateCompounds(
        node,
        () {
          return irBuilder.buildReifyTypeVariable(
              typeVariable.type, sourceInformationBuilder.buildGet(node));
        },
        rhs,
        (ir.Primitive value) {
          // The binary operator will throw before this.
        });
  }

  @override
  ir.Primitive visitTypeVariableTypeLiteralSetIfNull(
      ast.Send node, TypeVariableElement element, ast.Node rhs, _) {
    // The type variable is never `null`.
    return translateTypeVariableTypeLiteral(
        element, sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive handleIndexCompounds(ast.SendSet node, ast.Node receiver,
      ast.Node index, CompoundRhs rhs, arg) {
    ir.Primitive target = visit(receiver);
    ir.Primitive indexValue = visit(index);
    return translateCompounds(
        node,
        () {
          Selector selector = new Selector.index();
          List<ir.Primitive> arguments = <ir.Primitive>[indexValue];
          CallStructure callStructure =
              normalizeDynamicArguments(selector.callStructure, arguments);
          return irBuilder.buildDynamicInvocation(
              target,
              new Selector(selector.kind, selector.memberName, callStructure),
              elements.getGetterTypeMaskInComplexSendSet(node),
              arguments,
              sourceInformationBuilder.buildCall(receiver, node));
        },
        rhs,
        (ir.Primitive result) {
          irBuilder.buildDynamicIndexSet(target, elements.getTypeMask(node),
              indexValue, result, sourceInformationBuilder.buildIndexSet(node));
        });
  }

  @override
  ir.Primitive handleSuperIndexCompounds(
      ast.SendSet node,
      Element indexFunction,
      Element indexSetFunction,
      ast.Node index,
      CompoundRhs rhs,
      arg,
      {bool isGetterValid,
      bool isSetterValid}) {
    ir.Primitive indexValue = visit(index);
    return translateCompounds(
        node,
        () {
          if (isGetterValid) {
            return irBuilder.buildSuperIndex(indexFunction, indexValue,
                sourceInformationBuilder.buildIndex(node));
          } else {
            return buildSuperNoSuchMethod(
                new Selector.index(),
                elements.getGetterTypeMaskInComplexSendSet(node),
                <ir.Primitive>[indexValue],
                sourceInformationBuilder.buildIndex(node));
          }
        },
        rhs,
        (ir.Primitive result) {
          if (isSetterValid) {
            irBuilder.buildSuperIndexSet(indexSetFunction, indexValue, result,
                sourceInformationBuilder.buildIndexSet(node));
          } else {
            buildSuperNoSuchMethod(
                new Selector.indexSet(),
                elements.getTypeMask(node),
                <ir.Primitive>[indexValue, result],
                sourceInformationBuilder.buildIndexSet(node));
          }
        });
  }

  /// Build code to handle foreign code, that is, native JavaScript code, or
  /// builtin values and operations of the backend.
  ir.Primitive handleForeignCode(ast.Send node, MethodElement function,
      ast.NodeList argumentList, CallStructure callStructure) {
    void validateArgumentCount({int minimum, int exactly}) {
      assert((minimum == null) != (exactly == null));
      int count = 0;
      int maximum;
      if (exactly != null) {
        minimum = exactly;
        maximum = exactly;
      }
      for (ast.Node argument in argumentList) {
        count++;
        if (maximum != null && count > maximum) {
          internalError(argument, 'Additional argument.');
        }
      }
      if (count < minimum) {
        internalError(node, 'Expected at least $minimum arguments.');
      }
    }

    /// Call a helper method from the isolate library. The isolate library uses
    /// its own isolate structure, that encapsulates dart2js's isolate.
    ir.Primitive buildIsolateHelperInvocation(
        MethodElement element, CallStructure callStructure) {
      if (element == null) {
        reporter.internalError(node, 'Isolate library and compiler mismatch.');
      }
      List<ir.Primitive> arguments = <ir.Primitive>[];
      callStructure = translateStaticArguments(
          argumentList, element, callStructure, arguments);
      Selector selector = new Selector.call(element.memberName, callStructure);
      return irBuilder.buildInvokeStatic(element, selector, arguments,
          sourceInformationBuilder.buildCall(node, node.selector));
    }

    /// Lookup the value of the enum described by [node].
    getEnumValue(ast.Node node, EnumClassElement enumClass, List values) {
      Element element = elements[node];
      if (element is! EnumConstantElement ||
          element.enclosingClass != enumClass) {
        internalError(node, 'expected a JsBuiltin enum value');
      }
      EnumConstantElement enumConstant = element;
      int index = enumConstant.index;
      return values[index];
    }

    /// Returns the String the node evaluates to, or throws an error if the
    /// result is not a string constant.
    String expectStringConstant(ast.Node node) {
      ir.Primitive nameValue = visit(node);
      if (nameValue is ir.Constant && nameValue.value.isString) {
        StringConstantValue constantValue = nameValue.value;
        return constantValue.primitiveValue.slowToString();
      } else {
        return internalError(node, 'expected a literal string');
      }
    }

    Link<ast.Node> argumentNodes = argumentList.nodes;
    NativeBehavior behavior = elements.getNativeData(node);
    switch (function.name) {
      case 'JS':
        validateArgumentCount(minimum: 2);
        // The first two arguments are the type and the foreign code template,
        // which already have been analyzed by the resolver and can be retrieved
        // using [NativeBehavior]. We can ignore these arguments in the backend.
        List<ir.Primitive> arguments =
            argumentNodes.skip(2).mapToList(visit, growable: false);
        if (behavior.codeTemplate.positionalArgumentCount != arguments.length) {
          reporter.reportErrorMessage(node, MessageKind.GENERIC, {
            'text': 'Mismatch between number of placeholders'
                ' and number of arguments.'
          });
          return irBuilder.buildNullConstant();
        }

        if (HasCapturedPlaceholders.check(behavior.codeTemplate.ast)) {
          reporter.reportErrorMessage(node, MessageKind.JS_PLACEHOLDER_CAPTURE);
          return irBuilder.buildNullConstant();
        }

        return irBuilder.buildForeignCode(behavior.codeTemplate, arguments,
            behavior, sourceInformationBuilder.buildForeignCode(node));

      case 'DART_CLOSURE_TO_JS':
      // TODO(ahe): This should probably take care to wrap the closure in
      // another closure that saves the current isolate.
      case 'RAW_DART_FUNCTION_REF':
        validateArgumentCount(exactly: 1);

        ast.Node argument = node.arguments.single;
        FunctionElement closure = elements[argument].implementation;
        if (!Elements.isStaticOrTopLevelFunction(closure)) {
          internalError(argument, 'only static or toplevel function supported');
        }
        if (closure.functionSignature.hasOptionalParameters) {
          internalError(
              argument, 'closures with optional parameters not supported');
        }
        return irBuilder.buildForeignCode(
            js.js.expressionTemplateYielding(
                backend.emitter.staticFunctionAccess(closure)),
            <ir.Primitive>[],
            NativeBehavior.PURE,
            sourceInformationBuilder.buildForeignCode(node),
            dependency: closure);

      case 'JS_BUILTIN':
        // The first argument is a description of the type and effect of the
        // builtin, which has already been analyzed in the frontend.  The second
        // argument must be a [JsBuiltin] value.  All other arguments are
        // values used by the JavaScript template that is associated with the
        // builtin.
        validateArgumentCount(minimum: 2);

        ast.Node builtin = argumentNodes.tail.head;
        JsBuiltin value =
            getEnumValue(builtin, helpers.jsBuiltinEnum, JsBuiltin.values);
        js.Template template = backend.emitter.builtinTemplateFor(value);
        List<ir.Primitive> arguments =
            argumentNodes.skip(2).mapToList(visit, growable: false);
        return irBuilder.buildForeignCode(template, arguments, behavior,
            sourceInformationBuilder.buildForeignCode(node));

      case 'JS_EMBEDDED_GLOBAL':
        validateArgumentCount(exactly: 2);

        String name = expectStringConstant(argumentNodes.tail.head);
        js.Expression access =
            backend.emitter.generateEmbeddedGlobalAccess(name);
        js.Template template = js.js.expressionTemplateYielding(access);
        return irBuilder.buildForeignCode(template, <ir.Primitive>[], behavior,
            sourceInformationBuilder.buildForeignCode(node));

      case 'JS_INTERCEPTOR_CONSTANT':
        validateArgumentCount(exactly: 1);

        ast.Node argument = argumentNodes.head;
        ir.Primitive argumentValue = visit(argument);
        if (argumentValue is ir.Constant && argumentValue.value.isType) {
          TypeConstantValue constant = argumentValue.value;
          ConstantValue interceptorValue =
              new InterceptorConstantValue(constant.representedType);
          return irBuilder.buildConstant(interceptorValue);
        }
        return internalError(argument, 'expected Type as argument');

      case 'JS_EFFECT':
        return irBuilder.buildNullConstant();

      case 'JS_GET_NAME':
        validateArgumentCount(exactly: 1);

        ast.Node argument = argumentNodes.head;
        JsGetName id =
            getEnumValue(argument, helpers.jsGetNameEnum, JsGetName.values);
        js.Name name = backend.namer.getNameForJsGetName(argument, id);
        ConstantValue nameConstant = new SyntheticConstantValue(
            SyntheticConstantKind.NAME, js.js.quoteName(name));

        return irBuilder.buildConstant(nameConstant);

      case 'JS_GET_FLAG':
        validateArgumentCount(exactly: 1);

        String name = expectStringConstant(argumentNodes.first);
        bool value = false;
        switch (name) {
          case 'MUST_RETAIN_METADATA':
            value = backend.mustRetainMetadata;
            break;
          case 'USE_CONTENT_SECURITY_POLICY':
            value = compiler.options.useContentSecurityPolicy;
            break;
          default:
            internalError(node, 'Unknown internal flag "$name".');
        }
        return irBuilder.buildBooleanConstant(value);

      case 'JS_STRING_CONCAT':
        validateArgumentCount(exactly: 2);
        List<ir.Primitive> arguments = argumentNodes.mapToList(visit);
        return irBuilder.buildStringConcatenation(
            arguments, sourceInformationBuilder.buildForeignCode(node));

      case 'JS_CURRENT_ISOLATE_CONTEXT':
        validateArgumentCount(exactly: 0);

        if (!compiler.hasIsolateSupport) {
          // If the isolate library is not used, we just generate code
          // to fetch the current isolate.
          continue getStaticState;
        }
        return buildIsolateHelperInvocation(
            helpers.currentIsolate, CallStructure.NO_ARGS);

      getStaticState: case 'JS_GET_STATIC_STATE':
        validateArgumentCount(exactly: 0);

        return irBuilder.buildForeignCode(
            js.js.parseForeignJS(backend.namer.staticStateHolder),
            const <ir.Primitive>[],
            NativeBehavior.DEPENDS_OTHER,
            sourceInformationBuilder.buildForeignCode(node));

      case 'JS_SET_STATIC_STATE':
        validateArgumentCount(exactly: 1);

        ir.Primitive value = visit(argumentNodes.single);
        String isolateName = backend.namer.staticStateHolder;
        return irBuilder.buildForeignCode(
            js.js.parseForeignJS("$isolateName = #"),
            <ir.Primitive>[value],
            NativeBehavior.CHANGES_OTHER,
            sourceInformationBuilder.buildForeignCode(node));

      case 'JS_CALL_IN_ISOLATE':
        validateArgumentCount(exactly: 2);

        if (!compiler.hasIsolateSupport) {
          ir.Primitive closure = visit(argumentNodes.tail.head);
          return irBuilder.buildCallInvocation(
              closure,
              CallStructure.NO_ARGS,
              const <ir.Primitive>[],
              sourceInformationBuilder.buildForeignCode(node));
        }
        return buildIsolateHelperInvocation(
            helpers.callInIsolate, CallStructure.TWO_ARGS);

      default:
        return giveup(node, 'unplemented native construct: ${function.name}');
    }
  }

  /// Evaluates a string interpolation and appends each part to [accumulator]
  /// (after stringify conversion).
  void buildStringParts(ast.Node node, List<ir.Primitive> accumulator) {
    if (node is ast.StringJuxtaposition) {
      buildStringParts(node.first, accumulator);
      buildStringParts(node.second, accumulator);
    } else if (node is ast.StringInterpolation) {
      buildStringParts(node.string, accumulator);
      for (ast.StringInterpolationPart part in node.parts) {
        buildStringParts(part.expression, accumulator);
        buildStringParts(part.string, accumulator);
      }
    } else if (node is ast.LiteralString) {
      // Empty strings often occur at the end of a string interpolation,
      // do not bother to include them.
      if (!node.dartString.isEmpty) {
        accumulator.add(irBuilder.buildDartStringConstant(node.dartString));
      }
    } else if (node is ast.ParenthesizedExpression) {
      buildStringParts(node.expression, accumulator);
    } else {
      ir.Primitive value = visit(node);
      accumulator.add(irBuilder.buildStaticFunctionInvocation(
          helpers.stringInterpolationHelper,
          <ir.Primitive>[value],
          sourceInformationBuilder.buildStringInterpolation(node)));
    }
  }

  ir.Primitive visitStringJuxtaposition(ast.StringJuxtaposition node) {
    assert(irBuilder.isOpen);
    List<ir.Primitive> parts = <ir.Primitive>[];
    buildStringParts(node, parts);
    return irBuilder.buildStringConcatenation(
        parts, sourceInformationBuilder.buildStringInterpolation(node));
  }

  ir.Primitive visitStringInterpolation(ast.StringInterpolation node) {
    assert(irBuilder.isOpen);
    List<ir.Primitive> parts = <ir.Primitive>[];
    buildStringParts(node, parts);
    return irBuilder.buildStringConcatenation(
        parts, sourceInformationBuilder.buildStringInterpolation(node));
  }

  ir.Primitive translateConstant(ast.Node node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildConstant(getConstantForNode(node),
        sourceInformation: sourceInformationBuilder.buildGet(node));
  }

  ir.Primitive visitThrow(ast.Throw node) {
    assert(irBuilder.isOpen);
    // This function is not called for throw expressions occurring as
    // statements.
    return irBuilder.buildNonTailThrow(visit(node.expression));
  }

  ir.Primitive buildSuperNoSuchMethod(Selector selector, TypeMask mask,
      List<ir.Primitive> arguments, SourceInformation sourceInformation) {
    ClassElement cls = elements.analyzedElement.enclosingClass;
    MethodElement element = cls.lookupSuperMember(Identifiers.noSuchMethod_);
    if (!Selectors.noSuchMethod_.signatureApplies(element)) {
      element = compiler.coreClasses.objectClass
          .lookupMember(Identifiers.noSuchMethod_);
    }
    return irBuilder.buildSuperMethodInvocation(
        element,
        Selectors.noSuchMethod_.callStructure,
        [irBuilder.buildInvocationMirror(selector, arguments)],
        sourceInformation);
  }

  @override
  ir.Primitive visitUnresolvedCompound(ast.Send node, Element element,
      op.AssignmentOperator operator, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.getter(new Name(element.name, element.library)),
        [],
        sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitUnresolvedClassConstructorInvoke(
      ast.NewExpression node,
      Element element,
      DartType type,
      ast.NodeList arguments,
      Selector selector,
      _) {
    // If the class is missing it's a runtime error.
    ir.Primitive message =
        irBuilder.buildStringConstant("Unresolved class: '${element.name}'");
    return irBuilder.buildStaticFunctionInvocation(helpers.throwRuntimeError,
        <ir.Primitive>[message], sourceInformationBuilder.buildNew(node));
  }

  @override
  ir.Primitive visitUnresolvedConstructorInvoke(
      ast.NewExpression node,
      Element constructor,
      DartType type,
      ast.NodeList argumentsNode,
      Selector selector,
      _) {
    // If the class is there but the constructor is missing, it's an NSM error.
    List<ir.Primitive> arguments = <ir.Primitive>[];
    CallStructure callStructure = translateDynamicArguments(
        argumentsNode, selector.callStructure, arguments);
    return irBuilder.buildStaticNoSuchMethod(
        new Selector(selector.kind, selector.memberName, callStructure),
        arguments,
        sourceInformationBuilder.buildNew(node));
  }

  @override
  ir.Primitive visitConstructorIncompatibleInvoke(
      ast.NewExpression node,
      ConstructorElement constructor,
      DartType type,
      ast.NodeList argumentsNode,
      CallStructure callStructure,
      _) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.call(constructor.memberName, callStructure),
        arguments,
        sourceInformationBuilder.buildNew(node));
  }

  @override
  ir.Primitive visitUnresolvedGet(ast.Send node, Element element, _) {
    return irBuilder.buildStaticNoSuchMethod(elements.getSelector(node), [],
        sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitUnresolvedInvoke(ast.Send node, Element element,
      ast.NodeList arguments, Selector selector, _) {
    return irBuilder.buildStaticNoSuchMethod(
        elements.getSelector(node),
        arguments.nodes.mapToList(visit),
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive visitUnresolvedRedirectingFactoryConstructorInvoke(
      ast.NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      ast.NodeList argumentsNode,
      CallStructure callStructure,
      _) {
    String nameString = Elements.reconstructConstructorName(constructor);
    Name name = new Name(nameString, constructor.library);
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.call(name, callStructure),
        arguments,
        sourceInformationBuilder.buildNew(node));
  }

  @override
  ir.Primitive visitUnresolvedSet(
      ast.Send node, Element element, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(elements.getSelector(node),
        [visit(rhs)], sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitUnresolvedSuperIndex(
      ast.Send node, Element function, ast.Node index, _) {
    // Assume the index getter is missing.
    return buildSuperNoSuchMethod(
        new Selector.index(),
        elements.getTypeMask(node),
        [visit(index)],
        sourceInformationBuilder.buildIndex(node));
  }

  @override
  ir.Primitive visitUnresolvedSuperBinary(ast.Send node, Element element,
      op.BinaryOperator operator, ast.Node argument, _) {
    return buildSuperNoSuchMethod(
        elements.getSelector(node),
        elements.getTypeMask(node),
        [visit(argument)],
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive visitUnresolvedSuperUnary(
      ast.Send node, op.UnaryOperator operator, Element element, _) {
    return buildSuperNoSuchMethod(
        elements.getSelector(node),
        elements.getTypeMask(node),
        [],
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  @override
  ir.Primitive bulkHandleNode(ast.Node node, String message, _) {
    return giveup(node, "Unhandled node: ${message.replaceAll('#', '$node')}");
  }

  @override
  ir.Primitive bulkHandleError(ast.Node node, ErroneousElement error, _) {
    return irBuilder.buildNullConstant();
  }

  @override
  ir.Primitive visitClassTypeLiteralSet(
      ast.SendSet node, TypeConstantExpression constant, ast.Node rhs, _) {
    InterfaceType type = constant.type;
    ClassElement element = type.element;
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(element.memberName),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitTypedefTypeLiteralSet(
      ast.SendSet node, TypeConstantExpression constant, ast.Node rhs, _) {
    TypedefType type = constant.type;
    TypedefElement element = type.element;
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(element.memberName),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitTypeVariableTypeLiteralSet(
      ast.SendSet node, TypeVariableElement element, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(element.memberName),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitDynamicTypeLiteralSet(
      ast.SendSet node, ConstantExpression constant, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(Names.dynamic_),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitAbstractClassConstructorInvoke(
      ast.NewExpression node,
      ConstructorElement element,
      InterfaceType type,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    for (ast.Node argument in arguments) visit(argument);
    ir.Primitive name =
        irBuilder.buildStringConstant(element.enclosingClass.name);
    return irBuilder.buildStaticFunctionInvocation(
        helpers.throwAbstractClassInstantiationError,
        <ir.Primitive>[name],
        sourceInformationBuilder.buildNew(node));
  }

  @override
  ir.Primitive handleFinalStaticFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    // TODO(asgerf): Include class name somehow for static class members?
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(field.memberName),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitFinalSuperFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    return buildSuperNoSuchMethod(
        new Selector.setter(field.memberName),
        elements.getTypeMask(node),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive handleImmutableLocalSet(
      ast.SendSet node, LocalElement local, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(new Name(local.name, local.library)),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive handleStaticFunctionSet(
      ast.Send node, MethodElement function, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(function.memberName),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive handleStaticGetterSet(
      ast.SendSet node, GetterElement getter, ast.Node rhs, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.setter(getter.memberName),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive handleStaticSetterGet(ast.Send node, SetterElement setter, _) {
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.getter(setter.memberName),
        [],
        sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive handleStaticSetterInvoke(ast.Send node, SetterElement setter,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    // Translate as a method call.
    List<ir.Primitive> arguments = argumentsNode.nodes.mapToList(visit);
    return irBuilder.buildStaticNoSuchMethod(
        new Selector.call(setter.memberName, callStructure),
        arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  @override
  ir.Primitive visitSuperGetterSet(
      ast.SendSet node, GetterElement getter, ast.Node rhs, _) {
    return buildSuperNoSuchMethod(
        new Selector.setter(getter.memberName),
        elements.getTypeMask(node),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitSuperMethodSet(
      ast.Send node, MethodElement method, ast.Node rhs, _) {
    return buildSuperNoSuchMethod(
        new Selector.setter(method.memberName),
        elements.getTypeMask(node),
        [visit(rhs)],
        sourceInformationBuilder.buildAssignment(node));
  }

  @override
  ir.Primitive visitSuperSetterGet(ast.Send node, SetterElement setter, _) {
    return buildSuperNoSuchMethod(
        new Selector.getter(setter.memberName),
        elements.getTypeMask(node),
        [],
        sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive visitSuperSetterInvoke(ast.Send node, SetterElement setter,
      ast.NodeList argumentsNode, CallStructure callStructure, _) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    callStructure =
        translateDynamicArguments(argumentsNode, callStructure, arguments);
    return buildSuperNoSuchMethod(
        new Selector.call(setter.memberName, callStructure),
        elements.getTypeMask(node),
        arguments,
        sourceInformationBuilder.buildCall(node, argumentsNode));
  }

  ir.FunctionDefinition nullIfGiveup(ir.FunctionDefinition action()) {
    try {
      return action();
    } catch (e) {
      if (e == ABORT_IRNODE_BUILDER) {
        return null;
      }
      rethrow;
    }
  }

  internalError(ast.Node node, String message) {
    reporter.internalError(node, message);
  }

  @override
  visitNode(ast.Node node) {
    giveup(node, "Unhandled node");
  }

  dynamic giveup(ast.Node node, [String reason]) {
    bailoutMessage = '($node): $reason';
    throw ABORT_IRNODE_BUILDER;
  }
}

final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

/// Determines which local variables should be boxed in a mutable variable
/// inside a given try block.
class TryBoxedVariables extends ast.Visitor {
  final TreeElements elements;
  TryBoxedVariables(this.elements);

  FunctionElement currentFunction;
  bool insideInitializer = false;
  Set<Local> capturedVariables = new Set<Local>();

  /// A map containing variables boxed inside try blocks.
  ///
  /// The map is keyed by the [NodeList] of catch clauses for try/catch and
  /// by the finally block for try/finally.  try/catch/finally is treated
  /// as a try/catch nested in the try block of a try/finally.
  Map<ast.Node, TryStatementInfo> tryStatements =
      <ast.Node, TryStatementInfo>{};

  List<TryStatementInfo> tryNestingStack = <TryStatementInfo>[];
  bool get inTryStatement => tryNestingStack.isNotEmpty;

  String bailoutMessage = null;

  giveup(ast.Node node, [String reason]) {
    bailoutMessage = '($node): $reason';
    throw ABORT_IRNODE_BUILDER;
  }

  void markAsCaptured(Local local) {
    capturedVariables.add(local);
  }

  analyze(ast.Node node) {
    visit(node);
    // Variables that are captured by a closure are boxed for their entire
    // lifetime, so they never need to be boxed on entry to a try block.
    // They are not filtered out before this because we cannot identify all
    // of them in the same pass (they may be captured by a closure after the
    // try statement).
    for (TryStatementInfo info in tryStatements.values) {
      info.boxedOnEntry.removeAll(capturedVariables);
    }
  }

  visit(ast.Node node) => node.accept(this);

  visitNode(ast.Node node) {
    node.visitChildren(this);
  }

  void handleSend(ast.Send node) {
    Element element = elements[node];
    if (Elements.isLocal(element) &&
        !element.isConst &&
        element.enclosingElement != currentFunction) {
      LocalElement local = element;
      markAsCaptured(local);
    }
  }

  visitSend(ast.Send node) {
    handleSend(node);
    node.visitChildren(this);
  }

  visitSendSet(ast.SendSet node) {
    handleSend(node);
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      LocalElement local = element;
      if (insideInitializer &&
          local.isParameter &&
          local.enclosingElement == currentFunction) {
        assert(local.enclosingElement.isConstructor);
        // Initializers in an initializer-list can communicate via parameters.
        // If a parameter is stored in an initializer list we box it.
        // TODO(sigurdm): Fix this.
        // Though these variables do not outlive the activation of the
        // function, they still need to be boxed.  As a simplification, we
        // treat them as if they are captured by a closure (i.e., they do
        // outlive the activation of the function).
        markAsCaptured(local);
      } else if (inTryStatement) {
        assert(local.isParameter || local.isVariable);
        // Search for the position of the try block containing the variable
        // declaration, or -1 if it is declared outside the outermost try.
        int i = tryNestingStack.length - 1;
        while (i >= 0 && !tryNestingStack[i].declared.contains(local)) {
          --i;
        }
        // If there is a next inner try, then the variable should be boxed on
        // entry to it.
        if (i + 1 < tryNestingStack.length) {
          tryNestingStack[i + 1].boxedOnEntry.add(local);
        }
      }
    }
    node.visitChildren(this);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    FunctionElement savedFunction = currentFunction;
    currentFunction = elements[node];

    if (currentFunction.asyncMarker != AsyncMarker.SYNC &&
        currentFunction.asyncMarker != AsyncMarker.SYNC_STAR &&
        currentFunction.asyncMarker != AsyncMarker.ASYNC) {
      giveup(node, "cannot handle async* functions");
    }

    if (node.initializers != null) {
      visit(node.initializers);
    }
    visit(node.body);
    currentFunction = savedFunction;
  }

  visitTryStatement(ast.TryStatement node) {
    // Try/catch/finally is treated as two simpler constructs: try/catch and
    // try/finally.  The encoding is:
    //
    // try S0 catch (ex, st) S1 finally S2
    // ==>
    // try { try S0 catch (ex, st) S1 } finally S2
    //
    // The analysis associates variables assigned in S0 with the catch clauses
    // and variables assigned in S0 and S1 with the finally block.
    TryStatementInfo enterTryFor(ast.Node node) {
      TryStatementInfo info = new TryStatementInfo();
      tryStatements[node] = info;
      tryNestingStack.add(info);
      return info;
    }
    void leaveTryFor(TryStatementInfo info) {
      assert(tryNestingStack.last == info);
      tryNestingStack.removeLast();
    }
    bool hasCatch = !node.catchBlocks.isEmpty;
    bool hasFinally = node.finallyBlock != null;
    TryStatementInfo catchInfo, finallyInfo;
    // There is a nesting stack of try blocks, so the outer try/finally block
    // is added first.
    if (hasFinally) finallyInfo = enterTryFor(node.finallyBlock);
    if (hasCatch) catchInfo = enterTryFor(node.catchBlocks);
    visit(node.tryBlock);

    if (hasCatch) {
      leaveTryFor(catchInfo);
      visit(node.catchBlocks);
    }
    if (hasFinally) {
      leaveTryFor(finallyInfo);
      visit(node.finallyBlock);
    }
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    if (inTryStatement) {
      for (ast.Node definition in node.definitions.nodes) {
        LocalVariableElement local = elements[definition];
        assert(local != null);
        // In the closure conversion pass we check for isInitializingFormal,
        // but I'm not sure it can arise.
        assert(!local.isInitializingFormal);
        tryNestingStack.last.declared.add(local);
      }
    }
    node.visitChildren(this);
  }
}

/// The [IrBuilder]s view on the information about the program that has been
/// computed in resolution and and type interence.
class GlobalProgramInformation {
  final Compiler _compiler;
  JavaScriptBackend get _backend => _compiler.backend;

  GlobalProgramInformation(this._compiler);

  /// Returns [true], if the analysis could not determine that the type
  /// arguments for the class [cls] are never used in the program.
  bool requiresRuntimeTypesFor(ClassElement cls) {
    return cls.typeVariables.isNotEmpty && _backend.classNeedsRti(cls);
  }

  FunctionElement get throwTypeErrorHelper => _backend.helpers.throwTypeError;
  Element get throwNoSuchMethod => _backend.helpers.throwNoSuchMethod;

  ClassElement get nullClass => _compiler.coreClasses.nullClass;

  DartType unaliasType(DartType type) => type.unaliased;

  TypeMask getTypeMaskForForeign(NativeBehavior behavior) {
    if (behavior == null) {
      return _backend.dynamicType;
    }
    return TypeMaskFactory.fromNativeBehavior(behavior, _compiler);
  }

  bool isArrayType(TypeMask type) {
    return type.satisfies(_backend.helpers.jsArrayClass, _compiler.world);
  }

  TypeMask getTypeMaskForNativeFunction(FunctionElement function) {
    return _compiler.typesTask.getGuaranteedReturnTypeOfElement(function);
  }

  FieldElement locateSingleField(Selector selector, TypeMask type) {
    return _compiler.world.locateSingleField(selector, type);
  }

  bool fieldNeverChanges(FieldElement field) {
    return _compiler.world.fieldNeverChanges(field);
  }

  Element get closureConverter {
    return _backend.helpers.closureConverter;
  }

  void addNativeMethod(FunctionElement function) {
    _backend.emitter.nativeEmitter.nativeMethods.add(function);
  }

  bool get trustJSInteropTypeAnnotations =>
      _compiler.options.trustJSInteropTypeAnnotations;

  bool isNative(ClassElement element) => _backend.isNative(element);

  bool isJsInterop(FunctionElement element) => _backend.isJsInterop(element);

  bool isJsInteropAnonymous(FunctionElement element) =>
      _backend.jsInteropAnalysis.hasAnonymousAnnotation(element.contextClass);

  String getJsInteropTargetPath(FunctionElement element) {
    return '${_backend.namer.fixedBackendPath(element)}.'
        '${_backend.nativeData.getFixedBackendName(element)}';
  }

  DartType get jsJavascriptObjectType =>
      _backend.helpers.jsJavaScriptObjectClass.thisType;
}
