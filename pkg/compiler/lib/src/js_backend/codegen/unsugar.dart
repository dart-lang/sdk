library dart2js.unsugar_cps;

import '../../cps_ir/cps_ir_nodes.dart';

import '../../cps_ir/optimizers.dart' show ParentVisitor;
import '../../constants/values.dart';
import '../../elements/elements.dart';
import '../../io/source_information.dart';
import '../../js_backend/codegen/glue.dart';
import '../../universe/universe.dart' show Selector;
import '../../cps_ir/cps_ir_builder.dart' show ThisParameterLocal;

class ExplicitReceiverParameterEntity implements Local {
  String get name => 'receiver';
  final ExecutableElement executableContext;
  ExplicitReceiverParameterEntity(this.executableContext);
  toString() => 'ExplicitReceiverParameterEntity($executableContext)';
}

/// Suggested name for an interceptor.
class InterceptorEntity extends Entity {
  Entity interceptedVariable;

  InterceptorEntity(this.interceptedVariable);

  String get name => interceptedVariable.name + '_';
}


/// Rewrites the initial CPS IR to make Dart semantics explicit and inserts
/// special nodes that respect JavaScript behavior.
///
/// Performs the following rewrites:
///  - Rewrite [IsTrue] in a [Branch] to do boolean conversion.
///  - Add interceptors at call sites that use interceptor calling convention.
///  - Add explicit receiver argument for methods that are called in interceptor
///    calling convention.
///  - Convert two-parameter exception handlers to one-parameter ones.
class UnsugarVisitor extends RecursiveVisitor {
  Glue _glue;
  ParentVisitor _parentVisitor = new ParentVisitor();

  Parameter thisParameter;
  Parameter explicitReceiverParameter;

  Map<Primitive, Interceptor> interceptors = <Primitive, Interceptor>{};

  // In a catch block, rethrow implicitly throws the block's exception
  // parameter.  This is the exception parameter when nested in a catch
  // block and null otherwise.
  Parameter _exceptionParameter = null;

  UnsugarVisitor(this._glue);

  void rewrite(FunctionDefinition function) {
    bool inInterceptedMethod = _glue.isInterceptedMethod(function.element);

    if (function.element.name == '==' &&
        function.parameters.length == 1 &&
        !_glue.operatorEqHandlesNullArgument(function.element)) {
      // Insert the null check that the language semantics requires us to
      // perform before calling operator ==.
      insertEqNullCheck(function);
    }

    if (inInterceptedMethod) {
      thisParameter = function.thisParameter;
      ThisParameterLocal holder = thisParameter.hint;
      explicitReceiverParameter = new Parameter(
          new ExplicitReceiverParameterEntity(
              holder.executableContext));
      function.parameters.insert(0, explicitReceiverParameter);
    }

    // Set all parent pointers.
    _parentVisitor.visit(function);

    if (inInterceptedMethod) {
      explicitReceiverParameter.substituteFor(thisParameter);
    }

    visit(function);
  }

  Constant get trueConstant {
    return new Constant(new TrueConstantValue());
  }

  Constant get falseConstant {
    return new Constant(new FalseConstantValue());
  }

  Constant get nullConstant {
    return new Constant(new NullConstantValue());
  }

  void insertLetPrim(Primitive primitive, Expression node) {
    LetPrim let = new LetPrim(primitive);
    InteriorNode parent = node.parent;
    parent.body = let;
    let.body = node;
    node.parent = let;
    let.parent = parent;
  }

  void insertEqNullCheck(FunctionDefinition function) {
    // Replace
    //
    //     body;
    //
    // with
    //
    //     if (identical(arg, null))
    //       return false;
    //     else
    //       body;
    //
    Continuation originalBody = new Continuation(<Parameter>[]);
    originalBody.body = function.body;

    Continuation returnFalse = new Continuation(<Parameter>[]);
    Primitive falsePrimitive = falseConstant;
    returnFalse.body =
        new LetPrim(falsePrimitive,
            new InvokeContinuation(
                function.returnContinuation, <Primitive>[falsePrimitive]));

    Primitive nullPrimitive = nullConstant;
    Primitive test = new ApplyBuiltinOperator(
        BuiltinOperator.Identical,
          <Primitive>[function.parameters.single, nullPrimitive],
          function.parameters.single.sourceInformation);

    Expression newBody =
        new LetCont.many(<Continuation>[returnFalse, originalBody],
            new LetPrim(nullPrimitive,
                new LetPrim(test,
                    new Branch(
                        new IsTrue(test),
                        returnFalse,
                        originalBody))));
    function.body = newBody;
  }

  /// Insert a static call to [function] at the point of [node] with result
  /// [result].
  ///
  /// Rewrite [node] to
  ///
  /// let cont continuation(result) = node
  /// in invoke function arguments continuation
  void insertStaticCall(FunctionElement function, List<Primitive> arguments,
      Parameter result,
      Expression node) {
    InteriorNode parent = node.parent;
    Continuation continuation = new Continuation([result]);
    continuation.body = node;
    _parentVisitor.processContinuation(continuation);

    Selector selector = new Selector.fromElement(function);
    // TODO(johnniwinther): Come up with an implementation of SourceInformation
    // for calls such as this one that don't appear in the original source.
    InvokeStatic invoke = new InvokeStatic(
        function, selector, arguments, continuation, null);
    _parentVisitor.processInvokeStatic(invoke);

    LetCont letCont = new LetCont(continuation, invoke);
    _parentVisitor.processLetCont(letCont);

    parent.body = letCont;
    letCont.parent = parent;
  }

  @override
  Expression traverseLetHandler(LetHandler node) {
    assert(node.handler.parameters.length == 2);
    Parameter previousExceptionParameter = _exceptionParameter;

    // BEFORE: Handlers have two parameters, exception and stack trace.
    // AFTER: Handlers have a single parameter, which is unwrapped to get
    // the exception and stack trace.
    _exceptionParameter = node.handler.parameters.first;
    Parameter stackTraceParameter = node.handler.parameters.last;
    Expression body = node.handler.body;
    if (_exceptionParameter.hasAtLeastOneUse ||
        stackTraceParameter.hasAtLeastOneUse) {
      Parameter exceptionValue = new Parameter(null);
      exceptionValue.substituteFor(_exceptionParameter);
      insertStaticCall(_glue.getExceptionUnwrapper(), [_exceptionParameter],
          exceptionValue, body);

      if (stackTraceParameter.hasAtLeastOneUse) {
        Parameter stackTraceValue = new Parameter(null);
        stackTraceValue.substituteFor(stackTraceParameter);
        insertStaticCall(_glue.getTraceFromException(), [_exceptionParameter],
            stackTraceValue, body);
      }
    }

    assert(stackTraceParameter.hasNoUses);
    node.handler.parameters.removeLast();

    visit(node.handler);
    _exceptionParameter = previousExceptionParameter;

    return node.body;
  }

  processThrow(Throw node) {
    // The subexpression of throw is wrapped in the JavaScript output.
    Parameter value = new Parameter(null);
    insertStaticCall(_glue.getWrapExceptionHelper(), [node.value.definition],
        value, node);
    node.value.unlink();
    node.value = new Reference<Primitive>(value);
  }

  processRethrow(Rethrow node) {
    // Rethrow can only appear in a catch block.  It throws that block's
    // (wrapped) caught exception.
    Throw replacement = new Throw(_exceptionParameter);
    InteriorNode parent = node.parent;
    parent.body = replacement;
    replacement.parent = parent;
    // The original rethrow does not have any references that we need to
    // worry about unlinking.
  }

  /// Returns an interceptor for the given value, capable of responding to
  /// [selector].
  ///
  /// A single getInterceptor call will be created per primitive, bound
  /// immediately after the primitive is bound.
  ///
  /// The type propagation pass will later narrow the set of interceptors
  /// based on the input type, and the let sinking pass will propagate the
  /// getInterceptor call closer to its use when this is profitable.
  Interceptor getInterceptorFor(Primitive prim, Selector selector,
                                SourceInformation sourceInformation) {
    assert(prim is! Interceptor);
    Interceptor interceptor = interceptors[prim];
    if (interceptor == null) {
      interceptor = new Interceptor(prim, sourceInformation);
      interceptors[prim] = interceptor;
      InteriorNode parent = prim.parent;
      insertLetPrim(interceptor, parent.body);
      if (prim.hint != null) {
        interceptor.hint = new InterceptorEntity(prim.hint);
      }
    }
    // Add the interceptor classes that can respond to the given selector.
    interceptor.interceptedClasses.addAll(
        _glue.getInterceptedClassesOn(selector));
    return interceptor;
  }

  processInvokeMethod(InvokeMethod node) {
    Selector selector = node.selector;
    if (!_glue.isInterceptedSelector(selector)) return;

    Primitive receiver = node.receiver.definition;
    Primitive newReceiver;

    if (receiver == explicitReceiverParameter) {
      // If the receiver is the explicit receiver, we are calling a method in
      // the same interceptor:
      //  Change 'receiver.foo()'  to  'this.foo(receiver)'.
      newReceiver = thisParameter;
    } else {
      newReceiver = getInterceptorFor(
          receiver, node.selector, node.sourceInformation);
    }

    node.arguments.insert(0, node.receiver);
    node.receiver = new Reference<Primitive>(newReceiver);
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {
    if (_glue.isInterceptedMethod(node.target)) {
      Primitive nullPrim = nullConstant;
      insertLetPrim(nullPrim, node);
      node.arguments.insert(0, node.receiver);
      // TODO(sra): `null` is not adequate.  Interceptors project the class
      // hierarchy onto an interceptor hierarchy.  A super call that does a
      // method call will use the javascript 'this' parameter to avoid calling
      // getInterceptor again, so the receiver must be the interceptor (likely
      // `this`), not `null`.
      node.receiver = new Reference<Primitive>(nullPrim);
    }
  }

  processBranch(Branch node) {
    // TODO(karlklose): implement the checked mode part of boolean conversion.
    InteriorNode parent = node.parent;
    IsTrue condition = node.condition;

    // Do not rewrite conditions that are foreign code.
    // It is redundant, and causes infinite recursion (if not optimized)
    // in the implementation of identical, which itself contains a condition.
    Primitive value = condition.value.definition;
    if (value is Parameter && value.parent is Continuation) {
      Continuation cont = value.parent;
      if (cont.hasExactlyOneUse && cont.firstRef.parent is ForeignCode) {
        ForeignCode foreign = cont.firstRef.parent;
        if (foreign.type.containsOnlyBool(_glue.classWorld)) {
          return;
        }
      }
    }

    Primitive t = trueConstant;
    Primitive i = new ApplyBuiltinOperator(
        BuiltinOperator.Identical,
        <Primitive>[condition.value.definition, t],
        condition.value.definition.sourceInformation);
    LetPrim newNode = new LetPrim(t,
        new LetPrim(i,
            new Branch(new IsTrue(i),
                node.trueContinuation.definition,
                node.falseContinuation.definition)));
    condition.value.unlink();
    node.trueContinuation.unlink();
    node.falseContinuation.unlink();
    parent.body = newNode;
  }

  processInterceptor(Interceptor node) {
    _glue.registerSpecializedGetInterceptor(node.interceptedClasses);
  }
}
