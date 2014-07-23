// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../dart2jslib.dart' as dart2js show Constant, ConstructedConstant,
  StringConstant, ListConstant, MapConstant;
import '../elements/elements.dart';
import '../universe/universe.dart' show Selector, SelectorKind;
import '../dart_types.dart' show DartType, GenericType;
import 'const_expression.dart';
import '../helpers/helpers.dart';

abstract class Node {
  static int hashCount = 0;
  final int hashCode = hashCount = (hashCount + 1) & 0x3fffffff;

  accept(Visitor visitor);
}

abstract class Expression extends Node {
  Expression plug(Expression expr) => throw 'impossible';
}

/// The base class of things that variables can refer to: primitives,
/// continuations, function and continuation parameters, etc.
abstract class Definition extends Node {
  // The head of a linked-list of occurrences, in no particular order.
  Reference firstRef = null;

  bool get hasAtMostOneUse => firstRef == null || firstRef.nextRef == null;
  bool get hasExactlyOneUse => firstRef != null && firstRef.nextRef == null;
  bool get hasAtLeastOneUse => firstRef != null;
  bool get hasMultipleUses => !hasAtMostOneUse;

  void substituteFor(Definition other) {
    if (other.firstRef == null) return;
    Reference previous, current = other.firstRef;
    do {
      current.definition = this;
      previous = current;
      current = current.nextRef;
    } while (current != null);
    previous.nextRef = firstRef;
    firstRef = other.firstRef;
  }
}

/// An expression that cannot throw or diverge and has no side-effects.
/// All primitives are named using the identity of the [Primitive] object.
///
/// Primitives may allocate objects, this is not considered side-effect here.
///
/// Although primitives may not mutate state, they may depend on state.
abstract class Primitive extends Definition {
  /// The [VariableElement] or [ParameterElement] from which the primitive
  /// binding originated.
  Element hint;

  /// Register in which the variable binding this primitive can be allocated.
  /// Separate register spaces are used for primitives with different [element].
  /// Assigned by [RegisterAllocator], is null before that phase.
  int registerIndex;

  /// Use the given element as a hint for naming this primitive.
  ///
  /// Has no effect if this primitive already has a non-null [element].
  void useElementAsHint(Element hint) {
    if (this.hint == null) {
      this.hint = hint;
    }
  }
}

/// Operands to invocations and primitives are always variables.  They point to
/// their definition and are linked into a list of occurrences.
class Reference {
  Definition definition;
  Reference nextRef = null;

  Reference(this.definition) {
    nextRef = definition.firstRef;
    definition.firstRef = this;
  }
}

/// Binding a value (primitive or constant): 'let val x = V in E'.  The bound
/// value is in scope in the body.
/// During one-pass construction a LetVal with an empty body is used to
/// represent one-level context 'let val x = V in []'.
class LetPrim extends Expression {
  final Primitive primitive;
  Expression body = null;

  LetPrim(this.primitive);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetPrim(this);
}


/// Binding a continuation: 'let cont k(v) = E in E'.  The bound continuation
/// is in scope in the body and the continuation parameter is in scope in the
/// continuation body.
/// During one-pass construction a LetCont with an empty continuation body is
/// used to represent the one-level context 'let cont k(v) = [] in E'.
class LetCont extends Expression {
  final Continuation continuation;
  final Expression body;

  LetCont(this.continuation, this.body);

  Expression plug(Expression expr) {
    assert(continuation.body == null);
    return continuation.body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetCont(this);
}

abstract class Invoke {
  Selector get selector;
  List<Reference> get arguments;
}

/// Invoke a static function or static field getter/setter.
class InvokeStatic extends Expression implements Invoke {
  /// [FunctionElement] or [FieldElement].
  final Entity target;

  /**
   * The selector encodes how the function is invoked: number of positional
   * arguments, names used in named arguments. This information is required
   * to build the [StaticCallSiteTypeInformation] for the inference graph.
   */
  final Selector selector;

  final Reference continuation;
  final List<Reference> arguments;

  InvokeStatic(this.target, this.selector, Continuation cont,
               List<Definition> args)
      : continuation = new Reference(cont),
        arguments = _referenceList(args) {
    assert(target is ErroneousElement || selector.name == target.name);
  }

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/// Invoke a method, operator, getter, setter, or index getter/setter.
/// Converting a method to a function object is treated as a getter invocation.
class InvokeMethod extends Expression implements Invoke {
  final Reference receiver;
  final Selector selector;
  final Reference continuation;
  final List<Reference> arguments;

  InvokeMethod(Definition receiver,
               this.selector,
               Continuation cont,
               List<Definition> args)
      : receiver = new Reference(receiver),
        continuation = new Reference(cont),
        arguments = _referenceList(args) {
    assert(selector != null);
    assert(selector.kind == SelectorKind.CALL ||
           selector.kind == SelectorKind.OPERATOR ||
           (selector.kind == SelectorKind.GETTER && arguments.isEmpty) ||
           (selector.kind == SelectorKind.SETTER && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 2));
  }

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);
}

/// Invoke a method, operator, getter, setter, or index getter/setter from the
/// super class in tail position.
class InvokeSuperMethod extends Expression implements Invoke {
  final Selector selector;
  final Reference continuation;
  final List<Reference> arguments;

  InvokeSuperMethod(this.selector,
                    Continuation cont,
                    List<Definition> args)
      : continuation = new Reference(cont),
        arguments = _referenceList(args) {
    assert(selector != null);
    assert(selector.kind == SelectorKind.CALL ||
           selector.kind == SelectorKind.OPERATOR ||
           (selector.kind == SelectorKind.GETTER && arguments.isEmpty) ||
           (selector.kind == SelectorKind.SETTER && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 2));
  }

  accept(Visitor visitor) => visitor.visitInvokeSuperMethod(this);
}

/// Non-const call to a constructor. The [target] may be a generative
/// constructor, factory, or redirecting factory.
class InvokeConstructor extends Expression implements Invoke {
  final DartType type;
  final FunctionElement target;
  final Reference continuation;
  final List<Reference> arguments;
  final Selector selector;

  /// The class being instantiated. This is the same as `target.enclosingClass`
  /// and `type.element`.
  ClassElement get targetClass => target.enclosingElement;

  /// True if this is an invocation of a factory constructor.
  bool get isFactory => target.isFactoryConstructor;

  InvokeConstructor(this.type,
                    this.target,
                    this.selector,
                    Continuation cont,
                    List<Definition> args)
      : continuation = new Reference(cont),
        arguments = _referenceList(args) {
    assert(target.isErroneous || target.isConstructor);
    assert(target.isErroneous || type.isDynamic ||
           type.element == target.enclosingElement);
  }

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

/// "as" casts and "is" checks.
// We might want to turn "is"-checks into a [Primitive] as it can never diverge.
// But then we need to special-case for is-checks with an erroneous .type as
// these will throw.
class TypeOperator extends Expression {
  final Reference receiver;
  final DartType type;
  final Reference continuation;
  final String operator;

  TypeOperator(this.operator,
                Primitive receiver,
                this.type,
                Continuation cont)
      : this.receiver = new Reference(receiver),
        this.continuation = new Reference(cont) {
    assert(operator == "is" || operator == "as");
  }

  accept(Visitor visitor) => visitor.visitTypeOperator(this);
}

/// Invoke [toString] on each argument and concatenate the results.
class ConcatenateStrings extends Expression {
  final Reference continuation;
  final List<Reference> arguments;

  ConcatenateStrings(Continuation cont, List<Definition> args)
      : continuation = new Reference(cont),
        arguments = _referenceList(args);

  accept(Visitor visitor) => visitor.visitConcatenateStrings(this);
}

/// Gets the value from a closure variable. The identity of the variable is
/// determined by an [Element].
///
/// Closure variables can be seen as ref cells that are not first-class values.
/// A [LetPrim] with a [GetClosureVariable] can then be seen as:
///
///   let prim p = ![variable] in [body]
///
class GetClosureVariable extends Primitive {
  final Element variable;

  GetClosureVariable(this.variable) {
    assert(variable != null);
  }

  accept(Visitor visitor) => visitor.visitGetClosureVariable(this);
}

/// Assign or declare a closure variable. The identity of the variable is
/// determined by an [Element].
///
/// Closure variables can be seen as ref cells that are not first-class values.
/// If [isDeclaration], this can seen as a let binding:
///
///   let [variable] = ref [value] in [body]
///
/// And otherwise, it can be seen as a dereferencing assignment:
///
///   { ![variable] := [value]; [body] }
///
/// Closure variables without a declaring [SetClosureVariable] are implicitly
/// declared at the entry to the [variable]'s enclosing function.
class SetClosureVariable extends Expression {
  final Element variable;
  final Reference value;
  Expression body;

  /// If true, this declares a new copy of the closure variable. If so, all
  /// uses of the closure variable must occur in the [body].
  ///
  /// There can be at most one declaration per closure variable. If there is no
  /// declaration, only one copy exists (per function execution). It is best to
  /// avoid declaring closure variables if it is not necessary.
  final bool isDeclaration;

  SetClosureVariable(this.variable, Primitive value,
                      {this.isDeclaration : false })
      : this.value = new Reference(value) {
    assert(variable != null);
  }

  accept(Visitor visitor) => visitor.visitSetClosureVariable(this);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }
}

/// Create a potentially recursive function and store it in a closure variable.
/// The function can access itself using [GetClosureVariable] on [variable].
/// There must not exist a [SetClosureVariable] to [variable].
///
/// This can be seen as a let rec binding:
///
///   let rec [variable] = [definition] in [body]
///
class DeclareFunction extends Expression {
  final Element variable;
  final FunctionDefinition definition;
  Expression body;

  DeclareFunction(this.variable, this.definition);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitDeclareFunction(this);
}

/// Invoke a continuation in tail position.
class InvokeContinuation extends Expression {
  final Reference continuation;
  final List<Reference> arguments;

  // An invocation of a continuation is recursive if it occurs in the body of
  // the continuation itself.
  bool isRecursive;

  InvokeContinuation(Continuation cont, List<Definition> args,
                     {recursive: false})
      : continuation = new Reference(cont),
        arguments = _referenceList(args),
        isRecursive = recursive {
    if (recursive) cont.isRecursive = true;
  }

  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

/// The base class of things which can be tested and branched on.
abstract class Condition extends Node {
}

class IsTrue extends Condition {
  final Reference value;

  IsTrue(Definition val) : value = new Reference(val);

  accept(Visitor visitor) => visitor.visitIsTrue(this);
}

/// Choose between a pair of continuations based on a condition value.
class Branch extends Expression {
  final Condition condition;
  final Reference trueContinuation;
  final Reference falseContinuation;

  Branch(this.condition, Continuation trueCont, Continuation falseCont)
      : trueContinuation = new Reference(trueCont),
        falseContinuation = new Reference(falseCont);

  accept(Visitor visitor) => visitor.visitBranch(this);
}

class Constant extends Primitive {
  final ConstExp expression;
  final dart2js.Constant value;

  Constant(this.expression, this.value);

  accept(Visitor visitor) => visitor.visitConstant(this);
}

class This extends Primitive {
  This();

  accept(Visitor visitor) => visitor.visitThis(this);
}

/// Reify the given type variable as a [Type].
/// This depends on the current binding of 'this'.
class ReifyTypeVar extends Primitive {
  final TypeVariableElement typeVariable;

  ReifyTypeVar(this.typeVariable);

  dart2js.Constant get constant => null;

  accept(Visitor visitor) => visitor.visitReifyTypeVar(this);
}

class LiteralList extends Primitive {
  /// The List type being created; this is not the type argument.
  final GenericType type;
  final List<Reference> values;

  LiteralList(this.type, List<Primitive> values)
      : this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);
}

class LiteralMap extends Primitive {
  final GenericType type;
  final List<Reference> keys;
  final List<Reference> values;

  LiteralMap(this.type, List<Primitive> keys, List<Primitive> values)
      : this.keys = _referenceList(keys),
        this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralMap(this);
}

/// Create a non-recursive function.
class CreateFunction extends Primitive {
  final FunctionDefinition definition;

  CreateFunction(this.definition);

  accept(Visitor visitor) => visitor.visitCreateFunction(this);
}

class Parameter extends Primitive {
  Parameter(Element element) {
    super.hint = element;
  }

  accept(Visitor visitor) => visitor.visitParameter(this);
}

/// Continuations are normally bound by 'let cont'.  A continuation with no
/// parameter (or body) is used to represent a function's return continuation.
/// The return continuation is bound by the Function, not by 'let cont'.
class Continuation extends Definition {
  final List<Parameter> parameters;
  Expression body = null;

  // A continuation is recursive if it has any recursive invocations.
  bool isRecursive = false;

  Continuation(this.parameters);

  Continuation.retrn() : parameters = null;

  accept(Visitor visitor) => visitor.visitContinuation(this);
}

/// A function definition, consisting of parameters and a body.  The parameters
/// include a distinguished continuation parameter.
class FunctionDefinition extends Node {
  final FunctionElement element;
  final Continuation returnContinuation;
  final List<Parameter> parameters;
  final Expression body;
  final List<ConstDeclaration> localConstants;

  /// Values for optional parameters.
  final List<ConstExp> defaultParameterValues;

  FunctionDefinition(this.element, this.returnContinuation,
      this.parameters, this.body, this.localConstants,
      this.defaultParameterValues);

  accept(Visitor visitor) => visitor.visitFunctionDefinition(this);
}

List<Reference> _referenceList(List<Definition> definitions) {
  return definitions.map((e) => new Reference(e)).toList();
}

abstract class Visitor<T> {
  T visit(Node node) => node.accept(this);
  // Abstract classes.
  T visitNode(Node node) => null;
  T visitExpression(Expression node) => visitNode(node);
  T visitDefinition(Definition node) => visitNode(node);
  T visitPrimitive(Primitive node) => visitDefinition(node);
  T visitCondition(Condition node) => visitNode(node);

  // Concrete classes.
  T visitFunctionDefinition(FunctionDefinition node) => visitNode(node);

  // Expressions.
  T visitLetPrim(LetPrim node) => visitExpression(node);
  T visitLetCont(LetCont node) => visitExpression(node);
  T visitInvokeStatic(InvokeStatic node) => visitExpression(node);
  T visitInvokeContinuation(InvokeContinuation node) => visitExpression(node);
  T visitInvokeMethod(InvokeMethod node) => visitExpression(node);
  T visitInvokeSuperMethod(InvokeSuperMethod node) => visitExpression(node);
  T visitInvokeConstructor(InvokeConstructor node) => visitExpression(node);
  T visitConcatenateStrings(ConcatenateStrings node) => visitExpression(node);
  T visitBranch(Branch node) => visitExpression(node);
  T visitTypeOperator(TypeOperator node) => visitExpression(node);
  T visitSetClosureVariable(SetClosureVariable node) => visitExpression(node);
  T visitDeclareFunction(DeclareFunction node) => visitExpression(node);

  // Definitions.
  T visitLiteralList(LiteralList node) => visitPrimitive(node);
  T visitLiteralMap(LiteralMap node) => visitPrimitive(node);
  T visitConstant(Constant node) => visitPrimitive(node);
  T visitThis(This node) => visitPrimitive(node);
  T visitReifyTypeVar(ReifyTypeVar node) => visitPrimitive(node);
  T visitCreateFunction(CreateFunction node) => visitPrimitive(node);
  T visitGetClosureVariable(GetClosureVariable node) => visitPrimitive(node);
  T visitParameter(Parameter node) => visitPrimitive(node);
  T visitContinuation(Continuation node) => visitDefinition(node);

  // Conditions.
  T visitIsTrue(IsTrue node) => visitCondition(node);
}

abstract class RecursiveVisitor extends Visitor {
  // Ensures that RecursiveVisitor contains overrides for all relevant nodes.
  // As a rule of thumb, nodes with structure to traverse should be overridden
  // with the appropriate visits in this class (for example, visitLetCont),
  // while leaving other nodes for subclasses (i.e., visitLiteralList).
  visitNode(Node node) {
    throw "RecursiveVisitor is stale, add missing visit overrides";
  }

  visitFunctionDefinition(FunctionDefinition node) {
    visit(node.body);
  }

  // Expressions.

  visitLetPrim(LetPrim node) {
    visit(node.primitive);
    visit(node.body);
  }

  visitLetCont(LetCont node) {
    visit(node.continuation.body);
    visit(node.body);
  }

  visitInvokeStatic(InvokeStatic node) => null;
  visitInvokeContinuation(InvokeContinuation node) => null;
  visitInvokeMethod(InvokeMethod node) => null;
  visitInvokeSuperMethod(InvokeSuperMethod node) => null;
  visitInvokeConstructor(InvokeConstructor node) => null;
  visitConcatenateStrings(ConcatenateStrings node) => null;

  visitBranch(Branch node) {
    visit(node.condition);
  }

  visitTypeOperator(TypeOperator node) => null;

  visitSetClosureVariable(SetClosureVariable node) {
    visit(node.body);
  }

  visitDeclareFunction(DeclareFunction node) {
    visit(node.definition);
    visit(node.body);
  }

  // Definitions.

  visitLiteralList(LiteralList node) => null;
  visitLiteralMap(LiteralMap node) => null;
  visitConstant(Constant node) => null;
  visitThis(This node) => null;
  visitReifyTypeVar(ReifyTypeVar node) => null;

  visitCreateFunction(CreateFunction node) {
    visit(node.definition);
  }

  visitGetClosureVariable(GetClosureVariable node) => null;
  visitParameter(Parameter node) => null;
  visitContinuation(Continuation node) => null;

  // Conditions.

  visitIsTrue(IsTrue node) => null;
}

/// Keeps track of currently unused register indices.
class RegisterArray {
  int nextIndex = 0;
  final List<int> freeStack = <int>[];

  /// Returns an index that is currently unused.
  int makeIndex() {
    if (freeStack.isEmpty) {
      return nextIndex++;
    } else {
      return freeStack.removeLast();
    }
  }

  void releaseIndex(int index) {
    freeStack.add(index);
  }
}

/// Assigns indices to each primitive in the IR such that primitives that are
/// live simultaneously never get assigned the same index.
/// This information is used by the dart tree builder to generate fewer
/// redundant variables.
/// Currently, the liveness analysis is very simple and is often inadequate
/// for removing all of the redundant variables.
class RegisterAllocator extends Visitor {
  /// Separate register spaces for each source-level variable/parameter.
  /// Note that null is used as key for primitives without elements.
  final Map<Element, RegisterArray> elementRegisters =
      <Element, RegisterArray>{};

  RegisterArray getRegisterArray(Element element) {
    RegisterArray registers = elementRegisters[element];
    if (registers == null) {
      registers = new RegisterArray();
      elementRegisters[element] = registers;
    }
    return registers;
  }

  void allocate(Primitive primitive) {
    if (primitive.registerIndex == null) {
      primitive.registerIndex = getRegisterArray(primitive.hint).makeIndex();
    }
  }

  void release(Primitive primitive) {
    // Do not share indices for temporaries as this may obstruct inlining.
    if (primitive.hint == null) return;
    if (primitive.registerIndex != null) {
      getRegisterArray(primitive.hint).releaseIndex(primitive.registerIndex);
    }
  }

  void visitReference(Reference reference) {
    allocate(reference.definition);
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    visit(node.body);
    node.parameters.forEach(allocate); // Assign indices to unused parameters.
    elementRegisters.clear();
  }

  void visitLetPrim(LetPrim node) {
    visit(node.body);
    release(node.primitive);
    visit(node.primitive);
  }

  void visitLetCont(LetCont node) {
    visit(node.continuation);
    visit(node.body);
  }

  void visitInvokeStatic(InvokeStatic node) {
    node.arguments.forEach(visitReference);
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    node.arguments.forEach(visitReference);
  }

  void visitInvokeMethod(InvokeMethod node) {
    visitReference(node.receiver);
    node.arguments.forEach(visitReference);
  }

  void visitInvokeSuperMethod(InvokeSuperMethod node) {
    node.arguments.forEach(visitReference);
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    node.arguments.forEach(visitReference);
  }

  void visitConcatenateStrings(ConcatenateStrings node) {
    node.arguments.forEach(visitReference);
  }

  void visitBranch(Branch node) {
    visit(node.condition);
  }

  void visitLiteralList(LiteralList node) {
    node.values.forEach(visitReference);
  }

  void visitLiteralMap(LiteralMap node) {
    for (int i = 0; i < node.keys.length; ++i) {
      visitReference(node.keys[i]);
      visitReference(node.values[i]);
    }
  }

  void visitTypeOperator(TypeOperator node) {
    visitReference(node.receiver);
  }

  void visitConstant(Constant node) {
  }

  void visitThis(This node) {
  }

  void visitReifyTypeVar(ReifyTypeVar node) {
  }

  void visitCreateFunction(CreateFunction node) {
    new RegisterAllocator().visit(node.definition);
  }

  void visitGetClosureVariable(GetClosureVariable node) {
  }

  void visitSetClosureVariable(SetClosureVariable node) {
    visit(node.body);
    visitReference(node.value);
  }

  void visitDeclareFunction(DeclareFunction node) {
    new RegisterAllocator().visit(node.definition);
    visit(node.body);
  }

  void visitParameter(Parameter node) {
    throw "Parameters should not be visited by RegisterAllocator";
  }

  void visitContinuation(Continuation node) {
    visit(node.body);

    // Arguments get allocated left-to-right, so we release parameters
    // right-to-left. This increases the likelihood that arguments can be
    // transferred without intermediate assignments.
    for (int i = node.parameters.length - 1; i >= 0; --i) {
      release(node.parameters[i]);
    }
  }

  void visitIsTrue(IsTrue node) {
    visitReference(node.value);
  }

}

/// Eliminate redundant phis from the given [FunctionDefinition].
///
/// Phis in this case are [Continuations] together with corresponding
/// [InvokeContinuation]s. A [Continuation] parameter at position i is redundant
/// if for all [InvokeContinuation]s, the parameter at position i is identical
/// (except for feedback). Redundant parameters are removed from the
/// continuation signature, all invocations, and replaced within the
/// continuation body.
class RedundantPhiEliminator extends RecursiveVisitor {
  final Map<Continuation, List<InvokeContinuation>> cont2invokes =
      <Continuation, List<InvokeContinuation>>{};
  // For each reference r used in a continuation invocation i, stores the
  // corresponding continuation i.continuation. If required by other passes,
  // we could consider adding parent pointers to references instead.
  final Map<Reference, Continuation> ref2cont = <Reference, Continuation>{};
  final Set<Continuation> workSet = new Set<Continuation>();

  void rewrite(final FunctionDefinition root) {
    // Traverse the tree once to build the work set.
    visit(root);
    workSet.addAll(cont2invokes.keys);

    // Process each continuation one-by-one.
    while (workSet.isNotEmpty) {
      Continuation cont = workSet.first;
      workSet.remove(cont);

      if (cont.body == null) {
        continue; // Skip function return continuations.
      }

      List<InvokeContinuation> invokes = cont2invokes[cont];
      assert(invokes != null);

      _processContinuation(cont, invokes);
    }
  }

  /// Called for each continuation on the work set, together with its
  /// invocations.
  void _processContinuation(Continuation cont,
                            List<InvokeContinuation> invokes) {
    /// Returns the unique definition of parameter i if it exists and null
    /// otherwise. A definition is unique if it is the only value used to
    /// invoke the continuation, excluding feedback.
    Definition uniqueDefinitionOf(int i) {
      Definition value = null;
      for (InvokeContinuation invoke in invokes) {
        Definition def = invoke.arguments[i].definition;

        if (cont.parameters[i] == def) {
          // Invocation param == param in LetCont (i.e. a recursive call).
          continue;
        } else if (value == null) {
          value = def; // Set initial comparison value.
        } else if (value != def) {
          return null; // Differing invocation arguments.
        }
      }

      return value;
    }

    // Check if individual parameters are always called with a unique
    // definition, and remove them if that is the case. During each iteration,
    // we read the current parameter/argument from index `src` and copy it
    // to index `dst`.
    int dst = 0;
    for (int src = 0; src < cont.parameters.length; src++) {
      // Is the current phi redundant?
      Definition uniqueDefinition = uniqueDefinitionOf(src);
      if (uniqueDefinition == null) {
        // Reorganize parameters and arguments in case of deletions.
        cont.parameters[dst] = cont.parameters[src];
        for (InvokeContinuation invoke in invokes) {
            invoke.arguments[dst] = invoke.arguments[src];
        }

        dst++;
        continue;
      }

      Definition oldDefinition = cont.parameters[src];

      // Add continuations of about-to-be modified invokes to worklist since
      // we might introduce new optimization opportunities.
      for (Reference ref = oldDefinition.firstRef; ref != null;
           ref = ref.nextRef) {
        Continuation thatCont = ref2cont[ref];
        // thatCont is null if ref does not belong to a continuation invocation.
        if (thatCont != null && thatCont != cont) {
          workSet.add(thatCont);
        }
      }

      // Replace individual parameters:
      // * In the continuation body, replace occurrence of param with value,
      // * and implicitly remove param from continuation signature and
      //   invocations by not incrementing `dst`.
      uniqueDefinition.substituteFor(oldDefinition);
    }

    // Remove trailing items from parameter and argument lists.
    cont.parameters.length = dst;
    for (InvokeContinuation invoke in invokes) {
      invoke.arguments.length = dst;
    }
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    // Update the continuation map.
    Continuation cont = node.continuation.definition;
    assert(cont != null);
    cont2invokes.putIfAbsent(cont, () => <InvokeContinuation>[])
        .add(node);

    // And the reference map.
    node.arguments.forEach((Reference ref) {
      assert(!ref2cont.containsKey(ref));
      ref2cont[ref] = node.continuation.definition;
    });
  }
}
