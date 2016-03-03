// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.optimization.inline;

import 'cps_fragment.dart';
import 'cps_ir_builder.dart' show ThisParameterLocal;
import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import 'type_mask_system.dart' show TypeMaskSystem;
import '../dart_types.dart' show DartType, GenericType;
import '../world.dart' show World;
import '../elements/elements.dart';
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../js_backend/codegen/task.dart' show CpsFunctionCompiler;
import '../types/types.dart' show
    FlatTypeMask, ForwardingTypeMask, TypeMask, UnionTypeMask;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import 'package:js_ast/js_ast.dart' as js;

/// Inlining stack entries.
///
/// During inlining, a stack is used to detect cycles in the call graph.
class StackEntry {
  // Dynamically resolved calls might be targeting an adapter function that
  // fills in optional arguments not passed at the call site.  Therefore these
  // calls are represented by the eventual target and the call structure at
  // the call site, which together identify the target.  Statically resolved
  // calls are represented by the target element and a null call structure.
  final ExecutableElement target;
  final CallStructure callStructure;

  StackEntry(this.target, this.callStructure);

  bool match(ExecutableElement otherTarget, CallStructure otherCallStructure) {
    if (target != otherTarget) return false;
    if (callStructure == null) return otherCallStructure == null;
    return otherCallStructure != null &&
        callStructure.match(otherCallStructure);
  }
}

/// Inlining cache entries.
class CacheEntry {
  // The cache maps a function element to a list of entries, where each entry
  // is a tuple of (call structure, abstract receiver, abstract arguments)
  // along with the inlining decision and optional IR function definition.
  final CallStructure callStructure;
  final TypeMask receiver;
  final List<TypeMask> arguments;

  final bool decision;
  final FunctionDefinition function;

  CacheEntry(this.callStructure, this.receiver, this.arguments, this.decision,
      this.function);

  bool match(CallStructure otherCallStructure, TypeMask otherReceiver,
      List<TypeMask> otherArguments) {
    if (callStructure == null) {
      if (otherCallStructure != null) return false;
    } else if (otherCallStructure == null ||
               !callStructure.match(otherCallStructure)) {
      return false;
    }

    if (receiver != otherReceiver) return false;
    assert(arguments.length == otherArguments.length);
    for (int i = 0; i < arguments.length; ++i) {
      if (arguments[i] != otherArguments[i]) return false;
    }
    return true;
  }
}

/// An inlining cache.
///
/// During inlining a cache is used to remember inlining decisions for shared
/// parts of the call graph, to avoid exploring them more than once.
///
/// The cache maps a tuple of (function element, call structure,
/// abstract receiver, abstract arguments) to a boolean inlining decision and
/// an IR function definition if the decision is positive.
class InliningCache {
  static const int ABSENT = -1;
  static const int NO_INLINE = 0;

  final Map<ExecutableElement, FunctionDefinition> unoptimized =
      <ExecutableElement, FunctionDefinition>{};

  final Map<ExecutableElement, List<CacheEntry>> map =
      <ExecutableElement, List<CacheEntry>>{};

  // When function definitions are put into or removed from the cache, they are
  // copied because the compiler passes will mutate them.
  final CopyingVisitor copier = new CopyingVisitor();

  void _putInternal(ExecutableElement element, CallStructure callStructure,
      TypeMask receiver,
      List<TypeMask> arguments,
      bool decision,
      FunctionDefinition function) {
    map.putIfAbsent(element, () => <CacheEntry>[])
        .add(new CacheEntry(callStructure, receiver, arguments, decision,
            function));
  }

  /// Put a positive inlining decision in the cache.
  ///
  /// A positive inlining decision maps to an IR function definition.
  void putPositive(ExecutableElement element, CallStructure callStructure,
      TypeMask receiver,
      List<TypeMask> arguments,
      FunctionDefinition function) {
    _putInternal(element, callStructure, receiver, arguments, true,
        copier.copy(function));
  }

  /// Put a negative inlining decision in the cache.
  void putNegative(ExecutableElement element,
      CallStructure callStructure,
      TypeMask receiver,
      List<TypeMask> arguments) {
    _putInternal(element, callStructure, receiver, arguments, false, null);
  }

  /// Look up a tuple in the cache.
  ///
  /// A positive lookup result return the IR function definition.  A negative
  /// lookup result returns [NO_INLINE].  If there is no cached result,
  /// [ABSENT] is returned.
  get(ExecutableElement element, CallStructure callStructure, TypeMask receiver,
      List<TypeMask> arguments) {
    List<CacheEntry> entries = map[element];
    if (entries != null) {
      for (CacheEntry entry in entries) {
        if (entry.match(callStructure, receiver, arguments)) {
          if (entry.decision) {
            FunctionDefinition function = copier.copy(entry.function);
            ParentVisitor.setParents(function);
            return function;
          }
          return NO_INLINE;
        }
      }
    }
    return ABSENT;
  }

  /// Cache the unoptimized CPS term for a function.
  ///
  /// The unoptimized term should not have any inlining-context-specific
  /// optimizations applied to it.  It will be used to compile the
  /// non-specialized version of the function.
  void putUnoptimized(ExecutableElement element, FunctionDefinition function) {
    unoptimized.putIfAbsent(element, () => copier.copy(function));
  }

  /// Look up the unoptimized CPS term for a function.
  ///
  /// The unoptimized term will not have any inlining-context-specific
  /// optimizations applied to it.  It can be used to compile the
  /// non-specialized version of the function.
  FunctionDefinition getUnoptimized(ExecutableElement element) {
    FunctionDefinition function = unoptimized[element];
    if (function != null) {
      function = copier.copy(function);
      ParentVisitor.setParents(function);
    }
    return function;
  }
}

class Inliner implements Pass {
  get passName => 'Inline calls';

  final CpsFunctionCompiler functionCompiler;

  final InliningCache cache = new InliningCache();

  final List<StackEntry> stack = <StackEntry>[];

  Inliner(this.functionCompiler);

  bool isCalledOnce(Element element) {
    return functionCompiler.compiler.typesTask.typesInferrer.isCalledOnce(
        element);
  }

  void rewrite(FunctionDefinition node, [CallStructure callStructure]) {
    ExecutableElement function = node.element;

    // Inlining in asynchronous or generator functions is disabled.  Inlining
    // triggers a bug in the async rewriter.
    // TODO(kmillikin): Fix the bug and eliminate this restriction if it makes
    // sense.
    if (function is FunctionElement &&
        function.asyncMarker != AsyncMarker.SYNC) {
      return;
    }

    // Do not inline in functions containing try statements.  V8 does not
    // optimize code in such functions, so inlining will move optimizable code
    // into a context where it cannot be optimized.
    if (function.resolvedAst.elements.containsTryStatement) {
      return;
    }

    stack.add(new StackEntry(function, callStructure));
    new InliningVisitor(this).visit(node);
    assert(stack.last.match(function, callStructure));
    stack.removeLast();
    new ShrinkingReducer().rewrite(node);
  }
}

/// Compute an abstract size of an IR function definition.
///
/// The size represents the cost of inlining at a call site.
class SizeVisitor extends TrampolineRecursiveVisitor {
  int size = 0;

  void countArgument(Reference<Primitive> argument, Parameter parameter) {
    // If a parameter is unused and the corresponding argument has only the
    // one use at the invocation, then inlining the call might enable
    // elimination of the argument.  This 'pays for itself' by decreasing the
    // cost of inlining at the call site.
    if (argument != null &&
        argument.definition.hasExactlyOneUse &&
        parameter.hasNoUses) {
      --size;
    }
  }

  static int sizeOf(InvocationPrimitive invoke, FunctionDefinition function) {
    SizeVisitor visitor = new SizeVisitor();
    visitor.visit(function);
    visitor.countArgument(invoke.receiverRef, function.thisParameter);
    for (int i = 0; i < invoke.argumentRefs.length; ++i) {
      visitor.countArgument(invoke.argumentRefs[i], function.parameters[i]);
    }
    return visitor.size;
  }

  // Inlining a function incurs a cost equal to the number of primitives and
  // non-jump tail expressions.
  // TODO(kmillikin): Tune the size computation and size bound.
  processLetPrim(LetPrim node) => ++size;
  processLetMutable(LetMutable node) => ++size;
  processBranch(Branch node) => ++size;
  processThrow(Throw nose) => ++size;
  processRethrow(Rethrow node) => ++size;

  // Discount primitives that do not generate code.
  processRefinement(Refinement node) => --size;
  processBoundsCheck(BoundsCheck node) {
    if (node.hasNoChecks) {
      --size;
    }
  }

  processForeignCode(ForeignCode node) {
    // Count the number of nodes in the JS fragment, and discount the size
    // originally added by LetPrim.
    JsSizeVisitor visitor = new JsSizeVisitor();
    node.codeTemplate.ast.accept(visitor);
    size += visitor.size - 1;
  }
}

class JsSizeVisitor extends js.BaseVisitor {
  int size = 0;

  visitNode(js.Node node) {
    ++size;
    return super.visitNode(node);
  }

  visitInterpolatedExpression(js.InterpolatedExpression node) {
    // Suppress call to visitNode.  Placeholders should not be counted, because
    // the argument has already been counted, and will in most cases be inserted
    // directly in the placeholder.
  }
}


class InliningVisitor extends TrampolineRecursiveVisitor {
  final Inliner _inliner;

  // A successful inlining attempt returns the [Primitive] that represents the
  // result of the inlined call or null.  If the result is non-null, the body
  // of the inlined function is available in this field.
  CpsFragment _fragment;

  InliningVisitor(this._inliner);

  JavaScriptBackend get backend => _inliner.functionCompiler.backend;
  TypeMaskSystem get typeSystem => _inliner.functionCompiler.typeSystem;
  World get world => _inliner.functionCompiler.compiler.world;

  FunctionDefinition compileToCpsIr(AstElement element) {
    return _inliner.functionCompiler.compileToCpsIr(element);
  }

  void optimizeBeforeInlining(FunctionDefinition function) {
    _inliner.functionCompiler.optimizeCpsBeforeInlining(function);
  }

  void applyCpsPass(Pass pass, FunctionDefinition function) {
    return _inliner.functionCompiler.applyCpsPass(pass, function);
  }

  bool isRecursive(Element target, CallStructure callStructure) {
    return _inliner.stack.any((StackEntry s) => s.match(target, callStructure));
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    // A successful inlining attempt will set the node's body to null, so it is
    // read before visiting the primitive.
    Expression next = node.body;
    Primitive replacement = visit(node.primitive);
    if (replacement != null) {
      node.primitive.replaceWithFragment(_fragment, replacement);
    }
    return next;
  }

  TypeMask abstractType(Reference<Primitive> ref) {
    return ref.definition.type ?? typeSystem.dynamicType;
  }

  /// Build the IR term for the function that adapts a call site targeting a
  /// function that takes optional arguments not passed at the call site.
  FunctionDefinition buildAdapter(InvokeMethod node, FunctionElement target) {
    Parameter thisParameter = new Parameter(new ThisParameterLocal(target))
        ..type = node.receiver.type;
    List<Parameter> parameters = new List<Parameter>.generate(
        node.argumentRefs.length,
        (int index) {
          // TODO(kmillikin): Use a hint for the parameter names.
          return new Parameter(null)
              ..type = node.argument(index).type;
        });
    Continuation returnContinuation = new Continuation.retrn();
    CpsFragment cps = new CpsFragment();

    FunctionSignature signature = target.functionSignature;
    int requiredParameterCount = signature.requiredParameterCount;
    if (node.callingConvention == CallingConvention.Intercepted ||
        node.callingConvention == CallingConvention.DummyIntercepted) {
      ++requiredParameterCount;
    }
    List<Primitive> arguments = new List<Primitive>.generate(
        requiredParameterCount,
        (int index) => parameters[index]);

    int parameterIndex = requiredParameterCount;
    CallStructure newCallStructure;
    if (signature.optionalParametersAreNamed) {
      List<String> incomingNames =
          node.selector.callStructure.getOrderedNamedArguments();
      List<String> outgoingNames = <String>[];
      int nameIndex = 0;
      signature.orderedOptionalParameters.forEach((ParameterElement formal) {
        if (nameIndex < incomingNames.length &&
            formal.name == incomingNames[nameIndex]) {
          arguments.add(parameters[parameterIndex++]);
          ++nameIndex;
        } else {
          Constant defaultValue = cps.makeConstant(
              backend.constants.getConstantValueForVariable(formal));
          defaultValue.type = typeSystem.getParameterType(formal);
          arguments.add(defaultValue);
        }
        outgoingNames.add(formal.name);
      });
      newCallStructure =
          new CallStructure(signature.parameterCount, outgoingNames);
    } else {
      signature.forEachOptionalParameter((ParameterElement formal) {
        if (parameterIndex < parameters.length) {
          arguments.add(parameters[parameterIndex++]);
        } else {
          Constant defaultValue = cps.makeConstant(
              backend.constants.getConstantValueForVariable(formal));
          defaultValue.type = typeSystem.getParameterType(formal);
          arguments.add(defaultValue);
        }
      });
      newCallStructure = new CallStructure(signature.parameterCount);
    }

    Selector newSelector =
        new Selector(node.selector.kind, node.selector.memberName,
            newCallStructure);
    Primitive result = cps.invokeMethod(thisParameter, newSelector, node.mask,
        arguments, node.callingConvention);
    result.type = typeSystem.getInvokeReturnType(node.selector, node.mask);
    returnContinuation.parameters.single.type = result.type;
    cps.invokeContinuation(returnContinuation, <Primitive>[result]);
    return new FunctionDefinition(target, thisParameter, parameters,
        returnContinuation,
        cps.root);
  }

  // Given an invocation and a known target, possibly perform inlining.
  //
  // An optional call structure indicates a dynamic call.  Calls that are
  // already resolved statically have a null call structure.
  //
  // The [Primitive] representing the result of the inlined call is returned
  // if the call was inlined, and the inlined function body is available in
  // [_fragment].  If the call was not inlined, null is returned.
  Primitive tryInlining(InvocationPrimitive invoke, FunctionElement target,
                        CallStructure callStructure) {
    // Quick checks: do not inline or even cache calls to targets without an
    // AST node, targets that are asynchronous or generator functions, or
    // targets containing a try statement.
    if (!target.hasNode) return null;
    if (backend.isJsInterop(target)) return null;
    if (target.asyncMarker != AsyncMarker.SYNC) return null;
    // V8 does not optimize functions containing a try statement.  Inlining
    // code containing a try statement will make the optimizable calling code
    // become unoptimizable.
    if (target.resolvedAst.elements.containsTryStatement) {
      return null;
    }

    // Don't inline methods that never return. They are usually helper functions
    // that throw an exception.
    if (invoke.type.isEmpty) {
      // TODO(sra): It would be ok to inline if doing so was shrinking.
      return null;
    }

    if (isBlacklisted(target)) return null;

    if (invoke.callingConvention == CallingConvention.OneShotIntercepted) {
      // One-shot interceptor calls with a known target are only inserted on
      // uncommon code paths, so they should not be inlined.
      return null;
    }

    Reference<Primitive> dartReceiver = invoke.dartReceiverRef;
    TypeMask abstractReceiver =
        dartReceiver == null ? null : abstractType(dartReceiver);
    // The receiver is non-null in a method body, unless the receiver is known
    // to be `null` (isEmpty covers `null` and unreachable).
    TypeMask abstractReceiverInMethod = abstractReceiver == null
        ? null
        : abstractReceiver.isEmptyOrNull
            ? abstractReceiver
            : abstractReceiver.nonNullable();
    List<TypeMask> abstractArguments =
        invoke.argumentRefs.map(abstractType).toList();
    var cachedResult = _inliner.cache.get(target, callStructure,
        abstractReceiverInMethod,
        abstractArguments);

    // Negative inlining result in the cache.
    if (cachedResult == InliningCache.NO_INLINE) return null;

    Primitive finish(FunctionDefinition function) {
      _fragment = new CpsFragment(invoke.sourceInformation);
      Primitive receiver = invoke.receiver;
      List<Primitive> arguments = invoke.arguments.toList();
      // Add a null check to the inlined function body if necessary.  The
      // cached function body does not contain the null check.
      if (dartReceiver != null && abstractReceiver.isNullable) {
        Primitive check = nullReceiverGuard(
            invoke, _fragment, dartReceiver.definition, abstractReceiver);
        if (invoke.callingConvention == CallingConvention.Intercepted) {
          arguments[0] = check;
        } else {
          receiver = check;
        }
      }
      return _fragment.inlineFunction(function, receiver, arguments,
          hint: invoke.hint);
    }

    // Positive inlining result in the cache.
    if (cachedResult is FunctionDefinition) {
      return finish(cachedResult);
    }

    // We have not seen this combination of target and abstract arguments
    // before.  Make an inlining decision.
    assert(cachedResult == InliningCache.ABSENT);
    Primitive doNotInline() {
      _inliner.cache.putNegative(
          target, callStructure, abstractReceiverInMethod, abstractArguments);
      return null;
    }
    if (backend.annotations.noInline(target)) return doNotInline();
    if (isRecursive(target, callStructure)) return doNotInline();

    FunctionDefinition function;
    if (callStructure != null &&
        target.functionSignature.parameterCount !=
            callStructure.argumentCount) {
      // The argument count at the call site does not match the target's
      // formal parameter count.  Build the IR term for an adapter function
      // body.
      if (backend.isNative(target)) {
        // TODO(25548): Generate correct adaptor for native methods.
        return doNotInline();
      } else {
        function = buildAdapter(invoke, target);
      }
    } else {
      function = compileToCpsIr(target);
      void setValue(Variable variable, Reference<Primitive> value) {
        variable.type = value.definition.type;
      }
      if (invoke.callingConvention == CallingConvention.Intercepted) {
        setValue(function.thisParameter, invoke.receiverRef);
        function.parameters[0].type = abstractReceiverInMethod;
        for (int i = 1; i < invoke.argumentRefs.length; ++i) {
          setValue(function.parameters[i], invoke.argumentRefs[i]);
        }
      } else {
        if (invoke.receiverRef != null) {
          function.thisParameter.type = abstractReceiverInMethod;
        }
        for (int i = 0; i < invoke.argumentRefs.length; ++i) {
          setValue(function.parameters[i], invoke.argumentRefs[i]);
        }
      }
      optimizeBeforeInlining(function);
    }

    // Inline calls in the body.
    _inliner.rewrite(function, callStructure);

    // Compute the size.
    // TODO(kmillikin): Tune the size bound.
    int size = SizeVisitor.sizeOf(invoke, function);
    if (!_inliner.isCalledOnce(target) && size > 11) return doNotInline();

    _inliner.cache.putPositive(target, callStructure, abstractReceiverInMethod,
        abstractArguments, function);
    return finish(function);
  }

  Primitive nullReceiverGuard(InvocationPrimitive invoke,
                              CpsFragment fragment,
                              Primitive dartReceiver,
                              TypeMask abstractReceiver) {
    if (invoke is! InvokeMethod) return dartReceiver;
    InvokeMethod invokeMethod = invoke;
    Selector selector = invokeMethod.selector;
    if (typeSystem.isDefinitelyNum(abstractReceiver, allowNull: true)) {
      Primitive condition = _fragment.letPrim(
          new ApplyBuiltinOperator(BuiltinOperator.IsNotNumber,
                                   <Primitive>[dartReceiver],
                                   invoke.sourceInformation));
      condition.type = typeSystem.boolType;
      Primitive check = _fragment.letPrim(
          new ReceiverCheck.nullCheck(dartReceiver, selector,
              invoke.sourceInformation,
              condition: condition));
      check.type = abstractReceiver.nonNullable();
      return check;
    }

    Primitive check = _fragment.letPrim(
        new ReceiverCheck.nullCheck(dartReceiver, selector,
            invoke.sourceInformation));
    check.type = abstractReceiver.nonNullable();
    return check;
  }


  @override
  Primitive visitInvokeStatic(InvokeStatic node) {
    return tryInlining(node, node.target, null);
  }

  @override
  Primitive visitInvokeMethod(InvokeMethod node) {
    Primitive receiver = node.dartReceiver;
    Element element = world.locateSingleElement(node.selector, receiver.type);
    if (element == null || element is! FunctionElement) return null;
    if (node.selector.isGetter != element.isGetter) return null;
    if (node.selector.isSetter != element.isSetter) return null;
    if (node.selector.name != element.name) return null;

    return tryInlining(node, element.asFunctionElement(),
        node.selector.callStructure);
  }

  @override
  Primitive visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    if (node.selector.isGetter != node.target.isGetter) return null;
    if (node.selector.isSetter != node.target.isSetter) return null;
    return tryInlining(node, node.target, null);
  }

  @override
  Primitive visitInvokeConstructor(InvokeConstructor node) {
    if (node.dartType is GenericType) {
      // We cannot inline a constructor invocation containing type arguments
      // because CreateInstance in the body does not know the type arguments.
      // We would incorrectly instantiate a class like A instead of A<B>.
      // TODO(kmillikin): try to fix this.
      GenericType generic = node.dartType;
      if (generic.typeArguments.any((DartType t) => !t.isDynamic)) return null;
    }
    return tryInlining(node, node.target, null);
  }

  bool isBlacklisted(FunctionElement target) {
    ClassElement enclosingClass = target.enclosingClass;
    if (target.isOperator &&
        (enclosingClass == backend.helpers.jsNumberClass ||
         enclosingClass == backend.helpers.jsDoubleClass ||
         enclosingClass == backend.helpers.jsIntClass)) {
      // These should be handled by operator specialization.
      return true;
    }
    if (target == backend.helpers.stringInterpolationHelper) return true;
    return false;
  }
}
