// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart';
import '../common.dart';
import '../compiler.dart' show Compiler;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/js_backend.dart';
import '../native/native.dart' as native;
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../world.dart' show ClosedWorld;

import 'graph_builder.dart';
import 'nodes.dart';
import 'types.dart';

/// Keeps track of locals (including parameters and phis) when building. The
/// 'this' reference is treated as parameter and hence handled by this class,
/// too.
class LocalsHandler {
  /// The values of locals that can be directly accessed (without redirections
  /// to boxes or closure-fields).
  ///
  /// [directLocals] is iterated, so it is "insertion ordered" to make the
  /// iteration order a function only of insertions and not a function of
  /// e.g. Element hash codes.  I'd prefer to use a SortedMap but some elements
  /// don't have source locations for [Elements.compareByPosition].
  Map<Local, HInstruction> directLocals = new Map<Local, HInstruction>();
  Map<Local, CapturedVariable> redirectionMapping =
      new Map<Local, CapturedVariable>();
  final GraphBuilder builder;
  ClosureClassMap closureData;
  Map<TypeVariableType, TypeVariableLocal> typeVariableLocals =
      new Map<TypeVariableType, TypeVariableLocal>();
  final ExecutableElement executableContext;

  /// The class that defines the current type environment or null if no type
  /// variables are in scope.
  ClassElement get contextClass => executableContext.contextClass;

  /// The type of the current instance, if concrete.
  ///
  /// This allows for handling fixed type argument in case of inlining. For
  /// instance, checking `'foo'` against `String` instead of `T` in `main`:
  ///
  ///     class Foo<T> {
  ///       T field;
  ///       Foo(this.field);
  ///     }
  ///     main() {
  ///       new Foo<String>('foo');
  ///     }
  ///
  /// [instanceType] is not used if it contains type variables, since these
  /// might not be in scope or from the current instance.
  ///
  final InterfaceType instanceType;

  final Compiler _compiler;

  LocalsHandler(this.builder, this.executableContext,
      InterfaceType instanceType, this._compiler)
      : this.instanceType =
            instanceType == null || instanceType.containsTypeVariables
                ? null
                : instanceType;

  /// Substituted type variables occurring in [type] into the context of
  /// [contextClass].
  DartType substInContext(DartType type) {
    if (contextClass != null) {
      ClassElement typeContext = Types.getClassContext(type);
      if (typeContext != null) {
        type = type.substByContext(contextClass.asInstanceOf(typeContext));
      }
    }
    if (instanceType != null) {
      type = type.substByContext(instanceType);
    }
    return type;
  }

  /// Creates a new [LocalsHandler] based on [other]. We only need to
  /// copy the [directLocals], since the other fields can be shared
  /// throughout the AST visit.
  LocalsHandler.from(LocalsHandler other)
      : directLocals = new Map<Local, HInstruction>.from(other.directLocals),
        redirectionMapping = other.redirectionMapping,
        executableContext = other.executableContext,
        instanceType = other.instanceType,
        builder = other.builder,
        closureData = other.closureData,
        _compiler = other._compiler,
        activationVariables = other.activationVariables,
        cachedTypeOfThis = other.cachedTypeOfThis,
        cachedTypesOfCapturedVariables = other.cachedTypesOfCapturedVariables;

  /// Redirects accesses from element [from] to element [to]. The [to] element
  /// must be a boxed variable or a variable that is stored in a closure-field.
  void redirectElement(Local from, CapturedVariable to) {
    assert(redirectionMapping[from] == null);
    redirectionMapping[from] = to;
    assert(isStoredInClosureField(from) || isBoxed(from));
  }

  HInstruction createBox() {
    // TODO(floitsch): Clean up this hack. Should we create a box-object by
    // just creating an empty object literal?
    JavaScriptBackend backend = _compiler.backend;
    HInstruction box = new HForeignCode(
        js.js.parseForeignJS('{}'), backend.nonNullType, <HInstruction>[],
        nativeBehavior: native.NativeBehavior.PURE_ALLOCATION);
    builder.add(box);
    return box;
  }

  /// If the scope (function or loop) [node] has captured variables then this
  /// method creates a box and sets up the redirections.
  void enterScope(ast.Node node, Element element) {
    // See if any variable in the top-scope of the function is captured. If yes
    // we need to create a box-object.
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    HInstruction box;
    // The scope has captured variables.
    if (element != null && element.isGenerativeConstructorBody) {
      // The box is passed as a parameter to a generative
      // constructor body.
      JavaScriptBackend backend = _compiler.backend;
      box = builder.addParameter(scopeData.boxElement, backend.nonNullType);
    } else {
      box = createBox();
    }
    // Add the box to the known locals.
    directLocals[scopeData.boxElement] = box;
    // Make sure that accesses to the boxed locals go into the box. We also
    // need to make sure that parameters are copied into the box if necessary.
    scopeData.forEachCapturedVariable(
        (LocalVariableElement from, BoxFieldElement to) {
      // The [from] can only be a parameter for function-scopes and not
      // loop scopes.
      if (from.isRegularParameter && !element.isGenerativeConstructorBody) {
        // Now that the redirection is set up, the update to the local will
        // write the parameter value into the box.
        // Store the captured parameter in the box. Get the current value
        // before we put the redirection in place.
        // We don't need to update the local for a generative
        // constructor body, because it receives a box that already
        // contains the updates as the last parameter.
        HInstruction instruction = readLocal(from);
        redirectElement(from, to);
        updateLocal(from, instruction);
      } else {
        redirectElement(from, to);
      }
    });
  }

  /// Replaces the current box with a new box and copies over the given list
  /// of elements from the old box into the new box.
  void updateCaptureBox(
      BoxLocal boxElement, List<LocalVariableElement> toBeCopiedElements) {
    // Create a new box and copy over the values from the old box into the
    // new one.
    HInstruction oldBox = readLocal(boxElement);
    HInstruction newBox = createBox();
    for (LocalVariableElement boxedVariable in toBeCopiedElements) {
      // [readLocal] uses the [boxElement] to find its box. By replacing it
      // behind its back we can still get to the old values.
      updateLocal(boxElement, oldBox);
      HInstruction oldValue = readLocal(boxedVariable);
      updateLocal(boxElement, newBox);
      updateLocal(boxedVariable, oldValue);
    }
    updateLocal(boxElement, newBox);
  }

  /// Documentation wanted -- johnniwinther
  ///
  /// Invariant: [function] must be an implementation element.
  void startFunction(AstElement element, ast.Node node) {
    assert(invariant(element, element.isImplementation));
    closureData = _compiler.closureToClassMapper
        .getClosureToClassMapping(element.resolvedAst);

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature params = functionElement.functionSignature;
      ClosureScope scopeData = closureData.capturingScopes[node];
      params.orderedForEachParameter((ParameterElement parameterElement) {
        if (element.isGenerativeConstructorBody) {
          if (scopeData != null &&
              scopeData.isCapturedVariable(parameterElement)) {
            // The parameter will be a field in the box passed as the
            // last parameter. So no need to have it.
            return;
          }
        }
        HInstruction parameter = builder.addParameter(
            parameterElement,
            TypeMaskFactory.inferredTypeForElement(
                parameterElement, _compiler));
        builder.parameters[parameterElement] = parameter;
        directLocals[parameterElement] = parameter;
      });
    }

    enterScope(node, element);

    // If the freeVariableMapping is not empty, then this function was a
    // nested closure that captures variables. Redirect the captured
    // variables to fields in the closure.
    closureData.forEachFreeVariable((Local from, CapturedVariable to) {
      redirectElement(from, to);
    });
    JavaScriptBackend backend = _compiler.backend;
    if (closureData.isClosure) {
      // Inside closure redirect references to itself to [:this:].
      HThis thisInstruction =
          new HThis(closureData.thisLocal, backend.nonNullType);
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      updateLocal(closureData.closureElement, thisInstruction);
    } else if (element.isInstanceMember) {
      // Once closures have been mapped to classes their instance members might
      // not have any thisElement if the closure was created inside a static
      // context.
      HThis thisInstruction = new HThis(closureData.thisLocal, getTypeOfThis());
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      directLocals[closureData.thisLocal] = thisInstruction;
    }

    // If this method is an intercepted method, add the extra
    // parameter to it, that is the actual receiver for intercepted
    // classes, or the same as [:this:] for non-intercepted classes.
    ClassElement cls = element.enclosingClass;

    // When the class extends a native class, the instance is pre-constructed
    // and passed to the generative constructor factory function as a parameter.
    // Instead of allocating and initializing the object, the constructor
    // 'upgrades' the native subclass object by initializing the Dart fields.
    bool isNativeUpgradeFactory =
        element.isGenerativeConstructor && backend.isNativeOrExtendsNative(cls);
    if (backend.isInterceptedMethod(element)) {
      bool isInterceptorClass = backend.isInterceptorClass(cls.declaration);
      String name = isInterceptorClass ? 'receiver' : '_';
      SyntheticLocal parameter = new SyntheticLocal(name, executableContext);
      HParameterValue value = new HParameterValue(parameter, getTypeOfThis());
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAfter(directLocals[closureData.thisLocal], value);
      if (builder.lastAddedParameter == null) {
        // If this is the first parameter inserted, make sure it stays first.
        builder.lastAddedParameter = value;
      }
      if (isInterceptorClass) {
        // Only use the extra parameter in intercepted classes.
        directLocals[closureData.thisLocal] = value;
      }
    } else if (isNativeUpgradeFactory) {
      SyntheticLocal parameter =
          new SyntheticLocal('receiver', executableContext);
      // Unlike `this`, receiver is nullable since direct calls to generative
      // constructor call the constructor with `null`.
      ClosedWorld closedWorld = _compiler.closedWorld;
      HParameterValue value =
          new HParameterValue(parameter, new TypeMask.exact(cls, closedWorld));
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAtEntry(value);
    }
  }

  /// Returns true if the local can be accessed directly. Boxed variables or
  /// captured variables that are stored in the closure-field return [:false:].
  bool isAccessedDirectly(Local local) {
    assert(local != null);
    return !redirectionMapping.containsKey(local) &&
        !closureData.variablesUsedInTryOrGenerator.contains(local);
  }

  bool isStoredInClosureField(Local local) {
    assert(local != null);
    if (isAccessedDirectly(local)) return false;
    CapturedVariable redirectTarget = redirectionMapping[local];
    if (redirectTarget == null) return false;
    return redirectTarget is ClosureFieldElement;
  }

  bool isBoxed(Local local) {
    if (isAccessedDirectly(local)) return false;
    if (isStoredInClosureField(local)) return false;
    return redirectionMapping.containsKey(local);
  }

  bool isUsedInTryOrGenerator(Local local) {
    return closureData.variablesUsedInTryOrGenerator.contains(local);
  }

  /// Returns an [HInstruction] for the given element. If the element is
  /// boxed or stored in a closure then the method generates code to retrieve
  /// the value.
  HInstruction readLocal(Local local, {SourceInformation sourceInformation}) {
    if (isAccessedDirectly(local)) {
      if (directLocals[local] == null) {
        if (local is TypeVariableElement) {
          _compiler.reporter.internalError(_compiler.currentElement,
              "Runtime type information not available for $local.");
        } else {
          _compiler.reporter.internalError(
              local, "Cannot find value $local in ${directLocals.keys}.");
        }
      }
      HInstruction value = directLocals[local];
      if (sourceInformation != null) {
        value = new HRef(value, sourceInformation);
        builder.add(value);
      }
      return value;
    } else if (isStoredInClosureField(local)) {
      ClosureFieldElement redirect = redirectionMapping[local];
      HInstruction receiver = readLocal(closureData.closureElement);
      TypeMask type = local is BoxLocal
          ? (_compiler.backend as JavaScriptBackend).nonNullType
          : getTypeOfCapturedVariable(redirect);
      HInstruction fieldGet = new HFieldGet(redirect, receiver, type);
      builder.add(fieldGet);
      return fieldGet..sourceInformation = sourceInformation;
    } else if (isBoxed(local)) {
      BoxFieldElement redirect = redirectionMapping[local];
      // In the function that declares the captured variable the box is
      // accessed as direct local. Inside the nested closure the box is
      // accessed through a closure-field.
      // Calling [readLocal] makes sure we generate the correct code to get
      // the box.
      HInstruction box = readLocal(redirect.box);
      HInstruction lookup =
          new HFieldGet(redirect, box, getTypeOfCapturedVariable(redirect));
      builder.add(lookup);
      return lookup..sourceInformation = sourceInformation;
    } else {
      assert(isUsedInTryOrGenerator(local));
      HLocalValue localValue = getLocal(local);
      HInstruction instruction = new HLocalGet(
          local,
          localValue,
          (_compiler.backend as JavaScriptBackend).dynamicType,
          sourceInformation);
      builder.add(instruction);
      return instruction;
    }
  }

  HInstruction readThis() {
    HInstruction res = readLocal(closureData.thisLocal);
    if (res.instructionType == null) {
      res.instructionType = getTypeOfThis();
    }
    return res;
  }

  HLocalValue getLocal(Local local, {SourceInformation sourceInformation}) {
    // If the element is a parameter, we already have a
    // HParameterValue for it. We cannot create another one because
    // it could then have another name than the real parameter. And
    // the other one would not know it is just a copy of the real
    // parameter.
    if (local is ParameterElement) {
      assert(invariant(local, builder.parameters.containsKey(local),
          message: "No local value for parameter $local in "
              "${builder.parameters}."));
      return builder.parameters[local];
    }

    return activationVariables.putIfAbsent(local, () {
      JavaScriptBackend backend = _compiler.backend;
      HLocalValue localValue = new HLocalValue(local, backend.nonNullType)
        ..sourceInformation = sourceInformation;
      builder.graph.entry.addAtExit(localValue);
      return localValue;
    });
  }

  Local getTypeVariableAsLocal(TypeVariableType type) {
    return typeVariableLocals.putIfAbsent(type, () {
      return new TypeVariableLocal(type, executableContext);
    });
  }

  /// Sets the [element] to [value]. If the element is boxed or stored in a
  /// closure then the method generates code to set the value.
  void updateLocal(Local local, HInstruction value,
      {SourceInformation sourceInformation}) {
    if (value is HRef) {
      HRef ref = value;
      value = ref.value;
    }
    assert(!isStoredInClosureField(local));
    if (isAccessedDirectly(local)) {
      directLocals[local] = value;
    } else if (isBoxed(local)) {
      BoxFieldElement redirect = redirectionMapping[local];
      // The box itself could be captured, or be local. A local variable that
      // is captured will be boxed, but the box itself will be a local.
      // Inside the closure the box is stored in a closure-field and cannot
      // be accessed directly.
      HInstruction box = readLocal(redirect.box);
      builder.add(new HFieldSet(redirect, box, value)
        ..sourceInformation = sourceInformation);
    } else {
      assert(isUsedInTryOrGenerator(local));
      HLocalValue localValue = getLocal(local);
      builder.add(new HLocalSet(local, localValue, value)
        ..sourceInformation = sourceInformation);
    }
  }

  /// This function, startLoop, must be called before visiting any children of
  /// the loop. In particular it needs to be called before executing the
  /// initializers.
  ///
  /// The [LocalsHandler] will make the boxes and updates at the right moment.
  /// The builder just needs to call [enterLoopBody] and [enterLoopUpdates]
  /// (for [ast.For] loops) at the correct places. For phi-handling
  /// [beginLoopHeader] and [endLoop] must also be called.
  ///
  /// The correct place for the box depends on the given loop. In most cases
  /// the box will be created when entering the loop-body: while, do-while, and
  /// for-in (assuming the call to [:next:] is inside the body) can always be
  /// constructed this way.
  ///
  /// Things are slightly more complicated for [ast.For] loops. If no declared
  /// loop variable is boxed then the loop-body approach works here too. If a
  /// loop-variable is boxed we need to introduce a new box for the
  /// loop-variable before we enter the initializer so that the initializer
  /// writes the values into the box. In any case we need to create the box
  /// before the condition since the condition could box the variable.
  /// Since the first box is created outside the actual loop we have a second
  /// location where a box is created: just before the updates. This is
  /// necessary since updates are considered to be part of the next iteration
  /// (and can again capture variables).
  ///
  /// For example the following Dart code prints 1 3 -- 3 4.
  ///
  ///     var fs = [];
  ///     for (var i = 0; i < 3; (f() { fs.add(f); print(i); i++; })()) {
  ///       i++;
  ///     }
  ///     print("--");
  ///     for (var i = 0; i < 2; i++) fs[i]();
  ///
  /// We solve this by emitting the following code (only for [ast.For] loops):
  ///  <Create box>    <== move the first box creation outside the loop.
  ///  <initializer>;
  ///  loop-entry:
  ///    if (!<condition>) goto loop-exit;
  ///    <body>
  ///    <update box>  // create a new box and copy the captured loop-variables.
  ///    <updates>
  ///    goto loop-entry;
  ///  loop-exit:
  void startLoop(ast.Node node) {
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    if (scopeData.hasBoxedLoopVariables()) {
      // If there are boxed loop variables then we set up the box and
      // redirections already now. This way the initializer can write its
      // values into the box.
      // For other loops the box will be created when entering the body.
      enterScope(node, null);
    }
  }

  /// Create phis at the loop entry for local variables (ready for the values
  /// from the back edge).  Populate the phis with the current values.
  void beginLoopHeader(HBasicBlock loopEntry) {
    // Create a copy because we modify the map while iterating over it.
    Map<Local, HInstruction> savedDirectLocals =
        new Map<Local, HInstruction>.from(directLocals);

    JavaScriptBackend backend = _compiler.backend;
    // Create phis for all elements in the definitions environment.
    savedDirectLocals.forEach((Local local, HInstruction instruction) {
      if (isAccessedDirectly(local)) {
        // We know 'this' cannot be modified.
        if (local != closureData.thisLocal) {
          HPhi phi =
              new HPhi.singleInput(local, instruction, backend.dynamicType);
          loopEntry.addPhi(phi);
          directLocals[local] = phi;
        } else {
          directLocals[local] = instruction;
        }
      }
    });
  }

  void enterLoopBody(ast.Node node) {
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    // If there are no declared boxed loop variables then we did not create the
    // box before the initializer and we have to create the box now.
    if (!scopeData.hasBoxedLoopVariables()) {
      enterScope(node, null);
    }
  }

  void enterLoopUpdates(ast.Node node) {
    // If there are declared boxed loop variables then the updates might have
    // access to the box and we must switch to a new box before executing the
    // updates.
    // In all other cases a new box will be created when entering the body of
    // the next iteration.
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    if (scopeData.hasBoxedLoopVariables()) {
      updateCaptureBox(scopeData.boxElement, scopeData.boxedLoopVariables);
    }
  }

  /// Goes through the phis created in beginLoopHeader entry and adds the
  /// input from the back edge (from the current value of directLocals) to them.
  void endLoop(HBasicBlock loopEntry) {
    // If the loop has an aborting body, we don't update the loop
    // phis.
    if (loopEntry.predecessors.length == 1) return;
    loopEntry.forEachPhi((HPhi phi) {
      Local element = phi.sourceElement;
      HInstruction postLoopDefinition = directLocals[element];
      phi.addInput(postLoopDefinition);
    });
  }

  /// Merge [otherLocals] into this locals handler, creating phi-nodes when
  /// there is a conflict.
  /// If a phi node is necessary, it will use this handler's instruction as the
  /// first input, and the otherLocals instruction as the second.
  void mergeWith(LocalsHandler otherLocals, HBasicBlock joinBlock) {
    // If an element is in one map but not the other we can safely
    // ignore it. It means that a variable was declared in the
    // block. Since variable declarations are scoped the declared
    // variable cannot be alive outside the block. Note: this is only
    // true for nodes where we do joins.
    Map<Local, HInstruction> joinedLocals = new Map<Local, HInstruction>();
    JavaScriptBackend backend = _compiler.backend;
    otherLocals.directLocals.forEach((Local local, HInstruction instruction) {
      // We know 'this' cannot be modified.
      if (local == closureData.thisLocal) {
        assert(directLocals[local] == instruction);
        joinedLocals[local] = instruction;
      } else {
        HInstruction mine = directLocals[local];
        if (mine == null) return;
        if (identical(instruction, mine)) {
          joinedLocals[local] = instruction;
        } else {
          HInstruction phi = new HPhi.manyInputs(
              local, <HInstruction>[mine, instruction], backend.dynamicType);
          joinBlock.addPhi(phi);
          joinedLocals[local] = phi;
        }
      }
    });
    directLocals = joinedLocals;
  }

  /// When control flow merges, this method can be used to merge several
  /// localsHandlers into a new one using phis.  The new localsHandler is
  /// returned.  Unless it is also in the list, the current localsHandler is not
  /// used for its values, only for its declared variables. This is a way to
  /// exclude local values from the result when they are no longer in scope.
  LocalsHandler mergeMultiple(
      List<LocalsHandler> localsHandlers, HBasicBlock joinBlock) {
    assert(localsHandlers.length > 0);
    if (localsHandlers.length == 1) return localsHandlers[0];
    Map<Local, HInstruction> joinedLocals = new Map<Local, HInstruction>();
    HInstruction thisValue = null;
    JavaScriptBackend backend = _compiler.backend;
    directLocals.forEach((Local local, HInstruction instruction) {
      if (local != closureData.thisLocal) {
        HPhi phi = new HPhi.noInputs(local, backend.dynamicType);
        joinedLocals[local] = phi;
        joinBlock.addPhi(phi);
      } else {
        // We know that "this" never changes, if it's there.
        // Save it for later. While merging, there is no phi for "this",
        // so we don't have to special case it in the merge loop.
        thisValue = instruction;
      }
    });
    for (LocalsHandler handler in localsHandlers) {
      handler.directLocals.forEach((Local local, HInstruction instruction) {
        HPhi phi = joinedLocals[local];
        if (phi != null) {
          phi.addInput(instruction);
        }
      });
    }
    if (thisValue != null) {
      // If there was a "this" for the scope, add it to the new locals.
      joinedLocals[closureData.thisLocal] = thisValue;
    }

    // Remove locals that are not in all handlers.
    directLocals = new Map<Local, HInstruction>();
    joinedLocals.forEach((Local local, HInstruction instruction) {
      if (local != closureData.thisLocal &&
          instruction.inputs.length != localsHandlers.length) {
        joinBlock.removePhi(instruction);
      } else {
        directLocals[local] = instruction;
      }
    });
    return this;
  }

  TypeMask cachedTypeOfThis;

  TypeMask getTypeOfThis() {
    TypeMask result = cachedTypeOfThis;
    if (result == null) {
      ThisLocal local = closureData.thisLocal;
      ClassElement cls = local.enclosingClass;
      ClosedWorld closedWorld = _compiler.closedWorld;
      if (closedWorld.isUsedAsMixin(cls)) {
        // If the enclosing class is used as a mixin, [:this:] can be
        // of the class that mixins the enclosing class. These two
        // classes do not have a subclass relationship, so, for
        // simplicity, we mark the type as an interface type.
        result =
            new TypeMask.nonNullSubtype(cls.declaration, _compiler.closedWorld);
      } else {
        result = new TypeMask.nonNullSubclass(
            cls.declaration, _compiler.closedWorld);
      }
      cachedTypeOfThis = result;
    }
    return result;
  }

  Map<Element, TypeMask> cachedTypesOfCapturedVariables =
      new Map<Element, TypeMask>();

  TypeMask getTypeOfCapturedVariable(Element element) {
    assert(element.isField);
    return cachedTypesOfCapturedVariables.putIfAbsent(element, () {
      return TypeMaskFactory.inferredTypeForElement(element, _compiler);
    });
  }

  /// Variables stored in the current activation. These variables are
  /// being updated in try/catch blocks, and should be
  /// accessed indirectly through [HLocalGet] and [HLocalSet].
  Map<Local, HLocalValue> activationVariables = <Local, HLocalValue>{};
}

/// A synthetic local variable only used with the SSA graph.
///
/// For instance used for holding return value of function or the exception of a
/// try-catch statement.
class SyntheticLocal extends Local {
  final String name;
  final ExecutableElement executableContext;

  // Avoid slow Object.hashCode.
  final int hashCode = _nextHashCode = (_nextHashCode + 1).toUnsigned(30);
  static int _nextHashCode = 0;

  SyntheticLocal(this.name, this.executableContext);

  toString() => 'SyntheticLocal($name)';
}
