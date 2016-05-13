// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.cps_fragment;

import 'cps_ir_nodes.dart';
import '../constants/values.dart';
import '../universe/selector.dart' show Selector;
import '../types/types.dart' show TypeMask;
import '../io/source_information.dart';
import '../elements/elements.dart';

/// Builds a CPS fragment that can be plugged into another CPS term.
///
/// A CPS fragment contains a CPS term, possibly with a "hole" in it denoting
/// where to insert new IR nodes. We say a fragment is "open" if it has such
/// a hole. Otherwise, the fragment is "closed" and cannot be extended further.
///
/// This class is designed for building non-trivial CPS terms in a readable and
/// non-error prone manner. It is not designed to manipulate existing IR nodes,
/// nor is it intended to shield the user from every complexity in the IR.
///
/// EXAMPLES:
///
/// Call `cont` with `obj.field + 1` as argument:
///
///   CpsFragment cps = new CpsFragment();
///   var fieldValue = cps.letPrim(new GetField(obj, field));
///   var plusOne = cps.applyBuiltin(BuiltinOperator.NumAdd,
///                                  [fieldValue, cps.makeOne()]);
///   cps.invokeContinuation(cont, [plusOne]);
///
/// If `condition` is true then invoke `cont1`, else `cont2`.
///
///   cps.ifTruthy(condition).invokeContinuation(cont1, []);
///   cps.invokeContinuation(cont2, []);
///
/// If `condition` is true then invoke `cont` with a bound primitive:
///
///   CpsFragment branch = cps.ifTruthy(condition);
///   branch.invokeContinuation(cont, [branch.letPrim(arg)]);
///
/// Loop and call a method until it returns false:
///
///   Continuation loop = cps.beginLoop();
///   var result = cps.invokeMethod(receiver, selector, ...);
///   cps.ifFalsy(result).invokeContinuation(exit, []);
///   cps.continueLoop(loop);
///
class CpsFragment {
  /// The root of the IR built using this fragment.
  Expression root;

  /// Node whose body is the hole in this CPS fragment. May be null.
  InteriorNode context;

  /// Source information to attach to every IR node created in the fragment.
  SourceInformation sourceInformation;

  CpsFragment([this.sourceInformation, this.context]);

  bool get isOpen => root == null || context != null;
  bool get isClosed => !isOpen;
  bool get isEmpty => root == null;

  /// Asserts that the fragment is non-empty and closed and returns the IR that
  /// was built.
  Expression get result {
    assert(!isEmpty);
    assert(isClosed);
    return root;
  }

  /// Put the given expression into the fragment's hole.
  ///
  /// Afterwards the fragment is closed and cannot be extended until a new
  /// [context] is set.
  void put(Expression node) {
    assert(root == null || context != null); // We must put the node somewhere.
    if (root == null) {
      root = node;
    }
    if (context != null) {
      context.body = node;
      node.parent = context;
    }
    context = null;
  }

  /// Bind a primitive. Returns the same primitive for convenience.
  Primitive letPrim(Primitive prim) {
    assert(prim != null);
    LetPrim let = new LetPrim(prim);
    put(let);
    context = let;
    return prim;
  }

  /// Bind a constant value.
  Primitive makeConstant(ConstantValue constant) {
    return letPrim(new Constant(constant));
  }

  Primitive makeZero() => makeConstant(new IntConstantValue(0));
  Primitive makeOne() => makeConstant(new IntConstantValue(1));
  Primitive makeMinusOne() => makeConstant(new IntConstantValue(-1));
  Primitive makeNull() => makeConstant(new NullConstantValue());
  Primitive makeTrue() => makeConstant(new TrueConstantValue());
  Primitive makeFalse() => makeConstant(new FalseConstantValue());

  /// Invoke a built-in operator.
  Primitive applyBuiltin(BuiltinOperator op, List<Primitive> args) {
    return letPrim(new ApplyBuiltinOperator(op, args, sourceInformation));
  }

  Primitive refine(Primitive value, TypeMask type) {
    return letPrim(new Refinement(value, type));
  }

  Primitive invokeBuiltin(
      BuiltinMethod method, Primitive receiver, List<Primitive> arguments,
      {bool receiverIsNotNull: false}) {
    ApplyBuiltinMethod apply =
        new ApplyBuiltinMethod(method, receiver, arguments, sourceInformation);
    return letPrim(apply);
  }

  /// Inserts an invocation and returns a primitive holding the returned value.
  Primitive invokeMethod(Primitive receiver, Selector selector, TypeMask mask,
      List<Primitive> arguments,
      {Primitive interceptor, CallingConvention callingConvention}) {
    InvokeMethod invoke = new InvokeMethod(receiver, selector, mask, arguments,
        sourceInformation: sourceInformation,
        callingConvention: callingConvention,
        interceptor: interceptor);
    return letPrim(invoke);
  }

  /// Inserts an invocation and returns a primitive holding the returned value.
  Primitive invokeStatic(FunctionElement target, List<Primitive> arguments) {
    return letPrim(new InvokeStatic(target, new Selector.fromElement(target),
        arguments, sourceInformation));
  }

  /// Inserts an invocation to a static function that throws an error.
  ///
  /// This closes the fragment; no more nodes may be added.
  void invokeStaticThrower(FunctionElement target, List<Primitive> arguments) {
    invokeStatic(target, arguments);
    put(new Unreachable());
  }

  /// Invoke a non-recursive continuation.
  ///
  /// This closes the fragment; no more nodes may be inserted.
  void invokeContinuation(Continuation cont, [List<Primitive> arguments]) {
    if (arguments == null) arguments = <Primitive>[];
    put(new InvokeContinuation(cont, arguments));
  }

  /// Build a loop with the given loop variables and initial values.
  /// Call [continueLoop] with the returned continuation to iterate the loop.
  ///
  /// The loop body becomes the new hole.
  Continuation beginLoop(
      [List<Parameter> loopVars, List<Primitive> initialValues]) {
    if (initialValues == null) {
      assert(loopVars == null);
      loopVars = <Parameter>[];
      initialValues = <Primitive>[];
    }
    Continuation cont = new Continuation(loopVars);
    put(new LetCont(cont, new InvokeContinuation(cont, initialValues)));
    context = cont;
    return cont;
  }

  /// Continue a loop started by [beginLoop].
  ///
  /// This closes the fragment; no more nodes may be inserted.
  void continueLoop(Continuation cont, [List<Primitive> updatedLoopVariables]) {
    put(new InvokeContinuation(cont, updatedLoopVariables, isRecursive: true));
  }

  /// Branch on [condition].
  ///
  /// Returns a new fragment for the 'then' branch, or the 'else' branch
  /// if [negate] is true.
  ///
  /// The other branch becomes the new hole.
  CpsFragment branch(Primitive condition,
      {bool negate: false, bool strict: false}) {
    Continuation trueCont = new Continuation(<Parameter>[]);
    Continuation falseCont = new Continuation(<Parameter>[]);
    put(new LetCont.two(
        trueCont,
        falseCont,
        new Branch(condition, trueCont, falseCont, sourceInformation,
            strict: strict)));
    if (negate) {
      context = trueCont;
      return new CpsFragment(sourceInformation, falseCont);
    } else {
      context = falseCont;
      return new CpsFragment(sourceInformation, trueCont);
    }
  }

  /// Branch on [condition].
  ///
  /// Returns a new fragment for the 'then' branch.
  ///
  /// The 'else' branch becomes the new hole.
  CpsFragment ifTruthy(Primitive condition) => branch(condition);

  /// Branch on [condition].
  ///
  /// Returns a new fragment for the 'else' branch.
  ///
  /// The 'then' branch becomes the new hole.
  CpsFragment ifFalsy(Primitive condition) => branch(condition, negate: true);

  /// Create a new empty continuation and bind it here.
  ///
  /// Convenient for making a join point where multiple branches
  /// meet later.
  ///
  /// The LetCont body becomes the new hole.
  ///
  /// Example use:
  ///
  ///   Continuation fail = cps.letCont();
  ///
  ///   // Fail if something
  ///   cps.ifTrue(<condition>)
  ///      ..invokeMethod(<method>)
  ///      ..invokeContinuation(fail);
  ///
  ///   // Fail if something else
  ///   cps.ifTrue(<anotherCondition>)
  ///      ..invokeMethod(<anotherMethod>)
  ///      ..invokeContinuation(fail);
  ///
  ///   // Build the fail branch
  ///   cps.insideContinuation(fail)
  ///      ..invokeStaticThrower(...);
  ///
  ///   // Go to the happy branch
  ///   cps.invokeContinuation(cont..)
  ///
  Continuation letCont([List<Parameter> parameters]) {
    if (parameters == null) parameters = <Parameter>[];
    Continuation cont = new Continuation(parameters);
    bindContinuation(cont);
    return cont;
  }

  /// Binds an existing continuation at this position.
  ///
  /// The LetCont body becomes the new hole.
  void bindContinuation(Continuation cont) {
    LetCont let = new LetCont(cont, null);
    put(let);
    context = let;
  }

  /// Inlines [target] at the current position, substituting the provided
  /// arguments.
  ///
  /// Returns a primitive containing the function's return value.
  ///
  /// The new hole is the point after [target] has returned. The fragment
  /// remains open, even if [target] never returns.
  ///
  /// The [target] function is destroyed and should not be reused.
  Primitive inlineFunction(
      FunctionDefinition target, Primitive receiver, List<Primitive> arguments,
      {Entity hint, Primitive interceptor}) {
    if (interceptor != null) {
      target.interceptorParameter.replaceUsesWith(interceptor);
    }
    if (receiver != null) {
      target.receiverParameter.replaceUsesWith(receiver);
    }
    for (int i = 0; i < arguments.length; ++i) {
      target.parameters[i].replaceUsesWith(arguments[i]);
    }
    Continuation returnCont = target.returnContinuation;
    bindContinuation(returnCont);
    put(target.body);
    Parameter returnValue = returnCont.parameters.single;
    returnValue.hint = hint;
    context = returnCont;
    return returnValue;
  }

  /// Returns a fragment whose context is the body of the given continuation.
  ///
  /// Does not change the state of this CPS fragment.
  ///
  /// Useful for building the body of a continuation created using [letCont].
  CpsFragment insideContinuation(Continuation cont) {
    return new CpsFragment(sourceInformation, cont);
  }

  /// Puts the given fragment into this one.
  ///
  /// If [other] was an open fragment, its hole becomes the new hole
  /// in this fragment.
  ///
  /// [other] is reset to an empty fragment after this.
  void append(CpsFragment other) {
    if (other.root == null) return;
    put(other.root);
    context = other.context;
    other.context = null;
    other.root = null;
  }

  /// Reads the value of the given mutable variable.
  Primitive getMutable(MutableVariable variable) {
    return letPrim(new GetMutable(variable));
  }

  /// Sets the value of the given mutable variable.
  void setMutable(MutableVariable variable, Primitive value) {
    letPrim(new SetMutable(variable, value));
  }

  /// Declare a new mutable variable.
  void letMutable(MutableVariable variable, Primitive initialValue) {
    LetMutable let = new LetMutable(variable, initialValue);
    put(let);
    context = let;
  }

  void insertBelow(InteriorNode node) {
    assert(isOpen);
    if (isEmpty) return;
    Expression child = node.body;
    node.body = root;
    root.parent = node;
    context.body = child;
    child.parent = context;
    root = context = null;
  }

  void insertAbove(InteriorExpression node) {
    insertBelow(node.parent);
  }
}

/// Removes [node], unlinking all its references and replaces it with [newNode].
void destroyAndReplace(Expression node, Expression newNode) {
  InteriorNode parent = node.parent;
  RemovalVisitor.remove(node);
  parent.body = newNode;
  newNode.parent = parent;
}

/// Removes all [Refinement] uses of a given primitive that has no effective
/// uses.
void destroyRefinementsOfDeadPrimitive(Primitive prim) {
  while (prim.firstRef != null) {
    Refinement refine = prim.firstRef.parent;
    destroyRefinementsOfDeadPrimitive(refine);
    LetPrim letPrim = refine.parent;
    InteriorNode parent = letPrim.parent;
    parent.body = letPrim.body;
    letPrim.body.parent = parent;
    prim.firstRef.unlink();
  }
}
