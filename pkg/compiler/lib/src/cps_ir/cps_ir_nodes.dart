// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../constants/expressions.dart';
import '../constants/values.dart' as values show ConstantValue;
import '../cps_ir/optimizers.dart';
import '../dart_types.dart' show DartType, GenericType;
import '../dart2jslib.dart' as dart2js show invariant;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../universe/universe.dart' show Selector, SelectorKind;

abstract class Node {
  /// A pointer to the parent node. Is null until set by optimization passes.
  Node parent;

  accept(Visitor visitor);
}

abstract class Expression extends Node {
  Expression plug(Expression expr) => throw 'impossible';
}

/// The base class of things that variables can refer to: primitives,
/// continuations, function and continuation parameters, etc.
abstract class Definition<T extends Definition<T>> extends Node {
  // The head of a linked-list of occurrences, in no particular order.
  Reference<T> firstRef;

  bool get hasAtMostOneUse  => firstRef == null || firstRef.next == null;
  bool get hasExactlyOneUse => firstRef != null && firstRef.next == null;
  bool get hasAtLeastOneUse => firstRef != null;
  bool get hasMultipleUses  => !hasAtMostOneUse;

  void substituteFor(Definition<T> other) {
    if (other.firstRef == null) return;
    Reference<T> previous, current = other.firstRef;
    do {
      current.definition = this;
      previous = current;
      current = current.next;
    } while (current != null);
    previous.next = firstRef;
    if (firstRef != null) firstRef.previous = previous;
    firstRef = other.firstRef;
  }
}

/// An expression that cannot throw or diverge and has no side-effects.
/// All primitives are named using the identity of the [Primitive] object.
///
/// Primitives may allocate objects, this is not considered side-effect here.
///
/// Although primitives may not mutate state, they may depend on state.
abstract class Primitive extends Definition<Primitive> {
  /// The [VariableElement] or [ParameterElement] from which the primitive
  /// binding originated.
  Entity hint;

  /// Register in which the variable binding this primitive can be allocated.
  /// Separate register spaces are used for primitives with different [element].
  /// Assigned by [RegisterAllocator], is null before that phase.
  int registerIndex;

  /// Use the given element as a hint for naming this primitive.
  ///
  /// Has no effect if this primitive already has a non-null [element].
  void useElementAsHint(Entity hint) {
    if (this.hint == null) {
      this.hint = hint;
    }
  }
}

/// Operands to invocations and primitives are always variables.  They point to
/// their definition and are doubly-linked into a list of occurrences.
class Reference<T extends Definition<T>> {
  T definition;
  Reference<T> previous;
  Reference<T> next;

  /// A pointer to the parent node. Is null until set by optimization passes.
  Node parent;

  Reference(this.definition) {
    next = definition.firstRef;
    if (next != null) next.previous = this;
    definition.firstRef = this;
  }

  /// Unlinks this reference from the list of occurrences.
  void unlink() {
    if (previous == null) {
      assert(definition.firstRef == this);
      definition.firstRef = next;
    } else {
      previous.next = next;
    }
    if (next != null) next.previous = previous;
  }
}

/// Binding a value (primitive or constant): 'let val x = V in E'.  The bound
/// value is in scope in the body.
/// During one-pass construction a LetVal with an empty body is used to
/// represent the one-hole context 'let val x = V in []'.
class LetPrim extends Expression implements InteriorNode {
  final Primitive primitive;
  Expression body;

  LetPrim(this.primitive, [this.body = null]);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetPrim(this);
}


/// Binding continuations.
///
/// let cont k0(v0 ...) = E0
///          k1(v1 ...) = E1
///          ...
///   in E
///
/// The bound continuations are in scope in the body and the continuation
/// parameters are in scope in the respective continuation bodies.
/// During one-pass construction a LetCont whose first continuation has an empty
/// body is used to represent the one-hole context
/// 'let cont ... k(v) = [] ... in E'.
class LetCont extends Expression implements InteriorNode {
  List<Continuation> continuations;
  Expression body;

  LetCont(Continuation continuation, this.body)
      : continuations = <Continuation>[continuation];

  LetCont.many(this.continuations, this.body);

  Expression plug(Expression expr) {
    assert(continuations != null &&
           continuations.isNotEmpty &&
           continuations.first.body == null);
    return continuations.first.body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetCont(this);
}

// Binding an exception handler.
//
// let handler h(v0, v1) = E0 in E1
//
// The handler is a two-argument (exception, stack trace) continuation which
// is implicitly the error continuation of all the code in its body E1.
// [LetHandler] differs from a [LetCont] binding in that it (1) has the
// runtime semantics of pushing/popping a handler from the dynamic exception
// handler stack and (2) it does not have any explicit invocations.
class LetHandler extends Expression implements InteriorNode {
  Continuation handler;
  Expression body;

  LetHandler(this.handler, this.body);

  accept(Visitor visitor) => visitor.visitLetHandler(this);
}

/// Binding mutable variables.
///
/// let mutable v = P in E
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  They are therefore not [Primitive]s and not bound by [LetPrim]
/// to prevent unrestricted use of references to them.  During one-pass
/// construction, a [LetMutable] with an empty body is use to represent the
/// one-hole context 'let mutable v = P in []'.
class LetMutable extends Expression implements InteriorNode {
  final MutableVariable variable;
  final Reference<Primitive> value;
  Expression body;

  LetMutable(this.variable, Primitive value)
      : this.value = new Reference<Primitive>(value);

  Expression plug(Expression expr) {
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetMutable(this);
}

abstract class Invoke {
  Selector get selector;
  List<Reference<Primitive>> get arguments;
}

/// Represents a node with a child node, which can be accessed through the
/// `body` member. A typical usage is when removing a node from the CPS graph:
///
///     Node child          = node.body;
///     InteriorNode parent = node.parent;
///
///     child.parent = parent;
///     parent.body  = child;
abstract class InteriorNode extends Node {
  Expression body;
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

  final Reference<Continuation> continuation;
  final List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  InvokeStatic(this.target,
               this.selector,
               Continuation cont,
               List<Primitive> args,
               this.sourceInformation)
      : continuation = new Reference<Continuation>(cont),
        arguments = _referenceList(args) {
    assert(target is ErroneousElement || selector.name == target.name);
  }

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/// A [CallingConvention] codifies how arguments are matched to parameters when
/// emitting code for a function call.
class CallingConvention {
  final String name;
  const CallingConvention(this.name);
  /// The normal way of calling a Dart function: Positional arguments are
  /// matched with (mandatory and optional) positionals parameters from left to
  /// right and named arguments are matched by name.
  static const CallingConvention DART = const CallingConvention("Dart call");
  /// Intercepted calls have an additional first argument that is the actual
  /// receiver of the call.  See the documentation of [Interceptor] for more
  /// information.
  static const CallingConvention JS_INTERCEPTED =
      const CallingConvention("intercepted JavaScript call");
}

/// Invoke a method, operator, getter, setter, or index getter/setter.
/// Converting a method to a function object is treated as a getter invocation.
class InvokeMethod extends Expression implements Invoke {
  Reference<Primitive> receiver;
  Selector selector;
  CallingConvention callingConvention;
  final Reference<Continuation> continuation;
  final List<Reference<Primitive>> arguments;

  InvokeMethod(Primitive receiver,
               Selector selector,
               Continuation continuation,
               List<Primitive> arguments)
      : this.internal(new Reference<Primitive>(receiver),
                      selector,
                      new Reference<Continuation>(continuation),
                      _referenceList(arguments));

  InvokeMethod.internal(this.receiver,
                        this.selector,
                        this.continuation,
                        this.arguments,
                        [this.callingConvention = CallingConvention.DART]) {
    assert(isValid);
  }

  /// Returns whether the arguments match the selector under the given calling
  /// convention.
  ///
  /// This check is designed to be used in an assert, as it also checks that the
  /// selector, arguments, and calling convention have meaningful values.
  bool get isValid {
    if (selector == null || callingConvention == null) return false;
    if (callingConvention != CallingConvention.DART &&
        callingConvention != CallingConvention.JS_INTERCEPTED) {
      return false;
    }
    int numberOfArguments =
        callingConvention == CallingConvention.JS_INTERCEPTED
            ? arguments.length - 1
            : arguments.length;
    return selector.kind == SelectorKind.CALL ||
           selector.kind == SelectorKind.OPERATOR ||
           (selector.kind == SelectorKind.GETTER && numberOfArguments == 0) ||
           (selector.kind == SelectorKind.SETTER && numberOfArguments == 1) ||
           (selector.kind == SelectorKind.INDEX && numberOfArguments == 1) ||
           (selector.kind == SelectorKind.INDEX && numberOfArguments == 2);
  }

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);
}

/// Invoke [target] on [receiver], bypassing dispatch and override semantics.
///
/// That is, if [receiver] is an instance of a class that overrides [target]
/// with a different implementation, the overriding implementation is bypassed
/// and [target]'s implementation is invoked.
///
/// As with [InvokeMethod], this can be used to invoke a method, operator,
/// getter, setter, or index getter/setter.
///
/// If it is known that [target] does not use its receiver argument, then
/// [receiver] may refer to a null constant primitive. This happens for direct
/// invocations to intercepted methods, where the effective receiver is instead
/// passed as a formal parameter.
///
/// When targeting Dart, this instruction is used to represent super calls.
/// Here, [receiver] must always be a reference to `this`, and [target] must be
/// a method that is available in the super class.
class InvokeMethodDirectly extends Expression implements Invoke {
  Reference<Primitive> receiver;
  final Element target;
  final Selector selector;
  final Reference<Continuation> continuation;
  final List<Reference<Primitive>> arguments;

  InvokeMethodDirectly(Primitive receiver,
                       this.target,
                       this.selector,
                       Continuation cont,
                       List<Primitive> args)
      : this.receiver = new Reference<Primitive>(receiver),
        continuation = new Reference<Continuation>(cont),
        arguments = _referenceList(args) {
    assert(selector != null);
    assert(selector.kind == SelectorKind.CALL ||
           selector.kind == SelectorKind.OPERATOR ||
           (selector.kind == SelectorKind.GETTER && arguments.isEmpty) ||
           (selector.kind == SelectorKind.SETTER && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 2));
  }

  accept(Visitor visitor) => visitor.visitInvokeMethodDirectly(this);
}

/// Non-const call to a constructor. The [target] may be a generative
/// constructor, factory, or redirecting factory.
class InvokeConstructor extends Expression implements Invoke {
  final DartType type;
  final FunctionElement target;
  final Reference<Continuation> continuation;
  final List<Reference<Primitive>> arguments;
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
                    List<Primitive> args)
      : continuation = new Reference<Continuation>(cont),
        arguments = _referenceList(args) {
    assert(dart2js.invariant(target,
        target.isErroneous || target.isConstructor,
        message: "Constructor invocation target is not a constructor: "
                 "$target."));
    assert(dart2js.invariant(target,
        target.isErroneous ||
        type.isDynamic ||
        type.element == target.enclosingClass.declaration,
        message: "Constructor invocation type ${type} does not match enclosing "
                 "class of target ${target}."));
  }

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

/// "as" casts and "is" checks.
// We might want to turn "is"-checks into a [Primitive] as it can never diverge.
// But then we need to special-case for is-checks with an erroneous .type as
// these will throw.
class TypeOperator extends Expression {
  final Reference<Primitive> receiver;
  final DartType type;
  final Reference<Continuation> continuation;
  // TODO(johnniwinther): Use `Operator` class to encapsule the operator type.
  final bool isTypeTest;

  TypeOperator(Primitive receiver,
               this.type,
               Continuation cont,
               {bool this.isTypeTest})
      : this.receiver = new Reference<Primitive>(receiver),
        this.continuation = new Reference<Continuation>(cont) {
    assert(isTypeTest != null);
  }

  bool get isTypeCast => !isTypeTest;

  accept(Visitor visitor) => visitor.visitTypeOperator(this);
}

/// Invoke [toString] on each argument and concatenate the results.
class ConcatenateStrings extends Expression {
  final Reference<Continuation> continuation;
  final List<Reference<Primitive>> arguments;

  ConcatenateStrings(Continuation cont, List<Primitive> args)
      : continuation = new Reference<Continuation>(cont),
        arguments = _referenceList(args);

  accept(Visitor visitor) => visitor.visitConcatenateStrings(this);
}

/// Gets the value from a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  A [LetPrim] with a [GetMutableVariable] can then be seen as:
///
///   let prim p = ![variable] in [body]
///
class GetMutableVariable extends Primitive {
  final Reference<MutableVariable> variable;

  GetMutableVariable(MutableVariable variable)
      : this.variable = new Reference<MutableVariable>(variable);

  accept(Visitor visitor) => visitor.visitGetMutableVariable(this);
}

/// Assign a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  This can be seen as a dereferencing assignment:
///
///   { [variable] := [value]; [body] }
class SetMutableVariable extends Expression implements InteriorNode {
  final Reference<MutableVariable> variable;
  final Reference<Primitive> value;
  Expression body;

  SetMutableVariable(MutableVariable variable, Primitive value)
      : this.variable = new Reference<MutableVariable>(variable),
        this.value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetMutableVariable(this);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }
}

/// Create a potentially recursive function and store it in a [MutableVariable].
/// The function can access itself using [GetMutableVariable] on [variable].
/// There must not exist a [SetMutableVariable] to [variable].
///
/// This can be seen as a let rec binding:
///
///   let rec [variable] = [definition] in [body]
///
class DeclareFunction extends Expression
                      implements InteriorNode, DartSpecificNode {
  final MutableVariable variable;
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
  Reference<Continuation> continuation;
  List<Reference<Primitive>> arguments;

  // An invocation of a continuation is recursive if it occurs in the body of
  // the continuation itself.
  bool isRecursive;

  InvokeContinuation(Continuation cont, List<Primitive> args,
                     {recursive: false})
      : continuation = new Reference<Continuation>(cont),
        arguments = _referenceList(args),
        isRecursive = recursive {
    assert(cont.parameters == null ||
        cont.parameters.length == args.length);
    if (recursive) cont.isRecursive = true;
  }

  /// A continuation invocation whose target and arguments will be filled
  /// in later.
  ///
  /// Used as a placeholder for a jump whose target is not yet created
  /// (e.g., in the translation of break and continue).
  InvokeContinuation.uninitialized({recursive: false})
      : continuation = null,
        arguments = null,
        isRecursive = recursive;

  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

/// The base class of things which can be tested and branched on.
abstract class Condition extends Node {
}

class IsTrue extends Condition {
  final Reference<Primitive> value;

  IsTrue(Primitive val) : value = new Reference<Primitive>(val);

  accept(Visitor visitor) => visitor.visitIsTrue(this);
}

/// Choose between a pair of continuations based on a condition value.
class Branch extends Expression {
  final Condition condition;
  final Reference<Continuation> trueContinuation;
  final Reference<Continuation> falseContinuation;

  Branch(this.condition, Continuation trueCont, Continuation falseCont)
      : trueContinuation = new Reference<Continuation>(trueCont),
        falseContinuation = new Reference<Continuation>(falseCont);

  accept(Visitor visitor) => visitor.visitBranch(this);
}

/// Marker interface for nodes that are only handled in the JavaScript backend.
///
/// These nodes are generated by the unsugar step or the [JsIrBuilder] and need
/// special translation to the Tree IR, which is implemented in JsTreeBuilder.
abstract class JsSpecificNode implements Node {}

/// Marker interface for nodes that are only handled inthe Dart backend.
abstract class DartSpecificNode implements Node {}

/// Directly assigns to a field on a given object.
class SetField extends Expression implements InteriorNode, JsSpecificNode {
  final Reference<Primitive> object;
  Element field;
  final Reference<Primitive> value;
  Expression body;

  SetField(Primitive object, this.field, Primitive value)
      : this.object = new Reference<Primitive>(object),
        this.value = new Reference<Primitive>(value);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitSetField(this);
}

/// Directly reads from a field on a given object.
class GetField extends Primitive implements JsSpecificNode {
  final Reference<Primitive> object;
  Element field;

  GetField(Primitive object, this.field)
      : this.object = new Reference<Primitive>(object);

  accept(Visitor visitor) => visitor.visitGetField(this);
}

/// Creates an object for holding boxed variables captured by a closure.
class CreateBox extends Primitive implements JsSpecificNode {
  accept(Visitor visitor) => visitor.visitCreateBox(this);
}

/// Creates an instance of a class and initializes its fields.
class CreateInstance extends Primitive implements JsSpecificNode {
  final ClassElement classElement;

  /// Initial values for the fields on the class.
  /// The order corresponds to the order of fields on the class.
  final List<Reference<Primitive>> arguments;

  CreateInstance(this.classElement, List<Primitive> arguments)
      : this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitCreateInstance(this);
}

class Identical extends Primitive implements JsSpecificNode {
  final Reference<Primitive> left;
  final Reference<Primitive> right;
  Identical(Primitive left, Primitive right)
      : left = new Reference<Primitive>(left),
        right = new Reference<Primitive>(right);
  accept(Visitor visitor) => visitor.visitIdentical(this);
}

class Interceptor extends Primitive implements JsSpecificNode {
  final Reference<Primitive> input;
  final Set<ClassElement> interceptedClasses;
  Interceptor(Primitive input, this.interceptedClasses)
      : this.input = new Reference<Primitive>(input);
  accept(Visitor visitor) => visitor.visitInterceptor(this);
}

class Constant extends Primitive {
  final ConstantExpression expression;

  Constant(this.expression);

  values.ConstantValue get value => expression.value;

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

  values.ConstantValue get constant => null;

  accept(Visitor visitor) => visitor.visitReifyTypeVar(this);
}

class LiteralList extends Primitive {
  /// The List type being created; this is not the type argument.
  final GenericType type;
  final List<Reference<Primitive>> values;

  LiteralList(this.type, Iterable<Primitive> values)
      : this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);
}

class LiteralMapEntry {
  final Reference<Primitive> key;
  final Reference<Primitive> value;

  LiteralMapEntry(Primitive key, Primitive value)
      : this.key = new Reference<Primitive>(key),
        this.value = new Reference<Primitive>(value);
}

class LiteralMap extends Primitive {
  final GenericType type;
  final List<LiteralMapEntry> entries;

  LiteralMap(this.type, this.entries);

  accept(Visitor visitor) => visitor.visitLiteralMap(this);
}

/// Create a non-recursive function.
class CreateFunction extends Primitive implements DartSpecificNode {
  final FunctionDefinition definition;

  CreateFunction(this.definition);

  accept(Visitor visitor) => visitor.visitCreateFunction(this);
}

class Parameter extends Primitive {
  Parameter(Entity hint) {
    super.hint = hint;
  }

  // In addition to a parent pointer to the containing Continuation or
  // FunctionDefinition, parameters have an index into the list of parameters
  // bound by the parent.  This gives constant-time access to the continuation
  // from the parent.
  int parentIndex;

  accept(Visitor visitor) => visitor.visitParameter(this);
}

/// Continuations are normally bound by 'let cont'.  A continuation with one
/// parameter and no body is used to represent a function's return continuation.
/// The return continuation is bound by the Function, not by 'let cont'.
class Continuation extends Definition<Continuation> implements InteriorNode {
  final List<Parameter> parameters;
  Expression body = null;

  // In addition to a parent pointer to the containing LetCont, continuations
  // have an index into the list of continuations bound by the LetCont.  This
  // gives constant-time access to the continuation from the parent.
  int parent_index;

  // A continuation is recursive if it has any recursive invocations.
  bool isRecursive = false;

  bool get isReturnContinuation => body == null;

  Continuation(this.parameters);

  Continuation.retrn() : parameters = <Parameter>[new Parameter(null)];

  accept(Visitor visitor) => visitor.visitContinuation(this);
}

abstract class ExecutableDefinition implements Node {
  RunnableBody get body;

  applyPass(Pass pass);
}

// This is basically a function definition with an empty parameter list and a
// field element instead of a function element and no const declarations, and
// never a getter or setter, though that's less important.
class FieldDefinition extends Node implements ExecutableDefinition {
  final FieldElement element;
  RunnableBody body;

  FieldDefinition(this.element, this.body);

  FieldDefinition.withoutInitializer(this.element)
      : this.body = null;

  accept(Visitor visitor) => visitor.visitFieldDefinition(this);
  applyPass(Pass pass) => pass.rewriteFieldDefinition(this);

  /// `true` if this field has no initializer.
  ///
  /// If `true` [body] is `null`.
  ///
  /// This is different from a initializer that is `null`. Consider this class:
  ///
  ///     class Class {
  ///       final field;
  ///       Class.a(this.field);
  ///       Class.b() : this.field = null;
  ///       Class.c();
  ///     }
  ///
  /// If `field` had an initializer, possibly `null`, constructors `Class.a` and
  /// `Class.b` would be invalid, and since `field` has no initializer
  /// constructor `Class.c` is invalid. We therefore need to distinguish the two
  /// cases.
  bool get hasInitializer => body != null;
}

/// Identifies a mutable variable.
class MutableVariable extends Definition {
  /// Body of source code that declares this mutable variable.
  ExecutableElement host;
  Entity hint;

  MutableVariable(this.host, this.hint);

  accept(Visitor v) => v.visitMutableVariable(this);
}

class RunnableBody extends InteriorNode {
  Expression body;
  final Continuation returnContinuation;
  RunnableBody(this.body, this.returnContinuation);
  accept(Visitor visitor) => visitor.visitRunnableBody(this);
}

/// A function definition, consisting of parameters and a body.  The parameters
/// include a distinguished continuation parameter (held by the body).
class FunctionDefinition extends Node
    implements ExecutableDefinition {
  final FunctionElement element;
  /// Mixed list of [Parameter]s and [MutableVariable]s.
  final List<Definition> parameters;
  final RunnableBody body;
  final List<ConstDeclaration> localConstants;

  /// Values for optional parameters.
  final List<ConstantExpression> defaultParameterValues;

  FunctionDefinition(this.element,
      this.parameters,
      this.body,
      this.localConstants,
      this.defaultParameterValues);

  FunctionDefinition.abstract(this.element,
                              this.parameters,
                              this.defaultParameterValues)
      : body = null,
        localConstants = const <ConstDeclaration>[];

  accept(Visitor visitor) => visitor.visitFunctionDefinition(this);
  applyPass(Pass pass) => pass.rewriteFunctionDefinition(this);

  /// Returns `true` if this function is abstract or external.
  ///
  /// If `true`, [body] is `null` and [localConstants] is empty.
  bool get isAbstract => body == null;
}

abstract class Initializer extends Node implements DartSpecificNode {}

class FieldInitializer extends Initializer {
  final FieldElement element;
  final RunnableBody body;

  FieldInitializer(this.element, this.body);
  accept(Visitor visitor) => visitor.visitFieldInitializer(this);
}

class SuperInitializer extends Initializer {
  final ConstructorElement target;
  final List<RunnableBody> arguments;
  final Selector selector;
  SuperInitializer(this.target, this.arguments, this.selector);
  accept(Visitor visitor) => visitor.visitSuperInitializer(this);
}

class ConstructorDefinition extends FunctionDefinition {
  final List<Initializer> initializers;

  ConstructorDefinition(ConstructorElement element,
                        List<Definition> parameters,
                        RunnableBody body,
                        this.initializers,
                        List<ConstDeclaration> localConstants,
                        List<ConstantExpression> defaultParameterValues)
      : super(element, parameters, body, localConstants,
              defaultParameterValues);

  // 'Abstract' here means "has no body" and is used to represent external
  // constructors.
  ConstructorDefinition.abstract(
      ConstructorElement element,
      List<Definition> parameters,
      List<ConstantExpression> defaultParameterValues)
      : initializers = null,
        super.abstract(element, parameters, defaultParameterValues);

  accept(Visitor visitor) => visitor.visitConstructorDefinition(this);
  applyPass(Pass pass) => pass.rewriteConstructorDefinition(this);
}

List<Reference<Primitive>> _referenceList(Iterable<Primitive> definitions) {
  return definitions.map((e) => new Reference<Primitive>(e)).toList();
}

abstract class Visitor<T> {
  const Visitor();

  T visit(Node node) => node.accept(this);
  // Abstract classes.
  T visitNode(Node node) => null;
  T visitExpression(Expression node) => visitNode(node);
  T visitDefinition(Definition node) => visitNode(node);
  T visitPrimitive(Primitive node) => visitDefinition(node);
  T visitCondition(Condition node) => visitNode(node);
  T visitRunnableBody(RunnableBody node) => visitNode(node);

  // Concrete classes.
  T visitFieldDefinition(FieldDefinition node) => visitNode(node);
  T visitFunctionDefinition(FunctionDefinition node) => visitNode(node);
  T visitConstructorDefinition(ConstructorDefinition node) {
    return visitFunctionDefinition(node);
  }

  // Initializers
  T visitInitializer(Initializer node) => visitNode(node);
  T visitFieldInitializer(FieldInitializer node) => visitInitializer(node);
  T visitSuperInitializer(SuperInitializer node) => visitInitializer(node);

  // Expressions.
  T visitLetPrim(LetPrim node) => visitExpression(node);
  T visitLetCont(LetCont node) => visitExpression(node);
  T visitLetHandler(LetHandler node) => visitExpression(node);
  T visitLetMutable(LetMutable node) => visitExpression(node);
  T visitInvokeStatic(InvokeStatic node) => visitExpression(node);
  T visitInvokeContinuation(InvokeContinuation node) => visitExpression(node);
  T visitInvokeMethod(InvokeMethod node) => visitExpression(node);
  T visitInvokeMethodDirectly(InvokeMethodDirectly node) => visitExpression(node);
  T visitInvokeConstructor(InvokeConstructor node) => visitExpression(node);
  T visitConcatenateStrings(ConcatenateStrings node) => visitExpression(node);
  T visitBranch(Branch node) => visitExpression(node);
  T visitTypeOperator(TypeOperator node) => visitExpression(node);
  T visitSetMutableVariable(SetMutableVariable node) => visitExpression(node);
  T visitDeclareFunction(DeclareFunction node) => visitExpression(node);
  T visitSetField(SetField node) => visitExpression(node);

  // Definitions.
  T visitLiteralList(LiteralList node) => visitPrimitive(node);
  T visitLiteralMap(LiteralMap node) => visitPrimitive(node);
  T visitConstant(Constant node) => visitPrimitive(node);
  T visitThis(This node) => visitPrimitive(node);
  T visitReifyTypeVar(ReifyTypeVar node) => visitPrimitive(node);
  T visitCreateFunction(CreateFunction node) => visitPrimitive(node);
  T visitGetMutableVariable(GetMutableVariable node) => visitPrimitive(node);
  T visitParameter(Parameter node) => visitPrimitive(node);
  T visitContinuation(Continuation node) => visitDefinition(node);
  T visitMutableVariable(MutableVariable node) => visitDefinition(node);
  T visitGetField(GetField node) => visitDefinition(node);
  T visitCreateBox(CreateBox node) => visitDefinition(node);
  T visitCreateInstance(CreateInstance node) => visitDefinition(node);

  // Conditions.
  T visitIsTrue(IsTrue node) => visitCondition(node);

  // JavaScript specific nodes.
  T visitIdentical(Identical node) => visitPrimitive(node);
  T visitInterceptor(Interceptor node) => visitPrimitive(node);
}

/// Recursively visits the entire CPS term, and calls abstract `process*`
/// (i.e. `processLetPrim`) functions in pre-order.
abstract class RecursiveVisitor extends Visitor {
  const RecursiveVisitor();

  // Ensures that RecursiveVisitor contains overrides for all relevant nodes.
  // As a rule of thumb, nodes with structure to traverse should be overridden
  // with the appropriate visits in this class (for example, visitLetCont),
  // while leaving other nodes for subclasses (i.e., visitLiteralList).
  visitNode(Node node) {
    throw "$this is stale, add missing visit override for $node";
  }

  processReference(Reference ref) {}

  processRunnableBody(RunnableBody node) {}
  visitRunnableBody(RunnableBody node) {
    processRunnableBody(node);
    visit(node.returnContinuation);
    visit(node.body);
  }

  processFieldDefinition(FieldDefinition node) {}
  visitFieldDefinition(FieldDefinition node) {
    processFieldDefinition(node);
    if (node.hasInitializer) {
      visit(node.body);
    }
  }

  processFunctionDefinition(FunctionDefinition node) {}
  visitFunctionDefinition(FunctionDefinition node) {
    processFunctionDefinition(node);
    node.parameters.forEach(visit);
    if (!node.isAbstract) {
      visit(node.body);
    }
  }

  processConstructorDefinition(ConstructorDefinition node) {}
  visitConstructorDefinition(ConstructorDefinition node) {
    processConstructorDefinition(node);
    node.parameters.forEach(visit);
    node.initializers.forEach(visit);
    visit(node.body);
  }

  processFieldInitializer(FieldInitializer node) {}
  visitFieldInitializer(FieldInitializer node) {
    processFieldInitializer(node);
    visit(node.body.body);
  }

  processSuperInitializer(SuperInitializer node) {}
  visitSuperInitializer(SuperInitializer node) {
    processSuperInitializer(node);
    node.arguments.forEach(
        (RunnableBody argument) => visit(argument.body));
  }

  // Expressions.

  processLetPrim(LetPrim node) {}
  visitLetPrim(LetPrim node) {
    processLetPrim(node);
    visit(node.primitive);
    visit(node.body);
  }

  processLetCont(LetCont node) {}
  visitLetCont(LetCont node) {
    processLetCont(node);
    node.continuations.forEach(visit);
    visit(node.body);
  }

  processLetHandler(LetHandler node) {}
  visitLetHandler(LetHandler node) {
    processLetHandler(node);
    visit(node.handler);
    visit(node.body);
  }

  processLetMutable(LetMutable node) {}
  visitLetMutable(LetMutable node) {
    processLetMutable(node);
    visit(node.variable);
    processReference(node.value);
    visit(node.body);
  }

  processInvokeStatic(InvokeStatic node) {}
  visitInvokeStatic(InvokeStatic node) {
    processInvokeStatic(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeContinuation(InvokeContinuation node) {}
  visitInvokeContinuation(InvokeContinuation node) {
    processInvokeContinuation(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeMethod(InvokeMethod node) {}
  visitInvokeMethod(InvokeMethod node) {
    processInvokeMethod(node);
    processReference(node.receiver);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {}
  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    processInvokeMethodDirectly(node);
    processReference(node.receiver);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeConstructor(InvokeConstructor node) {}
  visitInvokeConstructor(InvokeConstructor node) {
    processInvokeConstructor(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processConcatenateStrings(ConcatenateStrings node) {}
  visitConcatenateStrings(ConcatenateStrings node) {
    processConcatenateStrings(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processBranch(Branch node) {}
  visitBranch(Branch node) {
    processBranch(node);
    processReference(node.trueContinuation);
    processReference(node.falseContinuation);
    visit(node.condition);
  }

  processTypeOperator(TypeOperator node) {}
  visitTypeOperator(TypeOperator node) {
    processTypeOperator(node);
    processReference(node.continuation);
    processReference(node.receiver);
  }

  processSetMutableVariable(SetMutableVariable node) {}
  visitSetMutableVariable(SetMutableVariable node) {
    processSetMutableVariable(node);
    processReference(node.variable);
    processReference(node.value);
    visit(node.body);
  }

  processDeclareFunction(DeclareFunction node) {}
  visitDeclareFunction(DeclareFunction node) {
    processDeclareFunction(node);
    visit(node.variable);
    visit(node.definition);
    visit(node.body);
  }

  // Definitions.

  processLiteralList(LiteralList node) {}
  visitLiteralList(LiteralList node) {
    processLiteralList(node);
    node.values.forEach(processReference);
  }

  processLiteralMap(LiteralMap node) {}
  visitLiteralMap(LiteralMap node) {
    processLiteralMap(node);
    for (LiteralMapEntry entry in node.entries) {
      processReference(entry.key);
      processReference(entry.value);
    }
  }

  processConstant(Constant node) {}
  visitConstant(Constant node) => processConstant(node);

  processThis(This node) {}
  visitThis(This node) => processThis(node);

  processReifyTypeVar(ReifyTypeVar node) {}
  visitReifyTypeVar(ReifyTypeVar node) => processReifyTypeVar(node);

  processCreateFunction(CreateFunction node) {}
  visitCreateFunction(CreateFunction node) {
    processCreateFunction(node);
    visit(node.definition);
  }

  processMutableVariable(node) {}
  visitMutableVariable(MutableVariable node) {
    processMutableVariable(node);
  }

  processGetMutableVariable(GetMutableVariable node) {}
  visitGetMutableVariable(GetMutableVariable node) {
    processGetMutableVariable(node);
  }

  processParameter(Parameter node) {}
  visitParameter(Parameter node) => processParameter(node);

  processContinuation(Continuation node) {}
  visitContinuation(Continuation node) {
    processContinuation(node);
    node.parameters.forEach(visitParameter);
    if (node.body != null) visit(node.body);
  }

  // Conditions.

  processIsTrue(IsTrue node) {}
  visitIsTrue(IsTrue node) {
    processIsTrue(node);
    processReference(node.value);
  }

  // JavaScript specific nodes.
  processIdentical(Identical node) {}
  visitIdentical(Identical node) {
    processIdentical(node);
    processReference(node.left);
    processReference(node.right);
  }

  processInterceptor(Interceptor node) {}
  visitInterceptor(Interceptor node) {
    processInterceptor(node);
    processReference(node.input);
  }

  processCreateInstance(CreateInstance node) {}
  visitCreateInstance(CreateInstance node) {
    processCreateInstance(node);
    node.arguments.forEach(processReference);
  }

  processSetField(SetField node) {}
  visitSetField(SetField node) {
    processSetField(node);
    processReference(node.object);
    processReference(node.value);
    visit(node.body);
  }

  processGetField(GetField node) {}
  visitGetField(GetField node) {
    processGetField(node);
    processReference(node.object);
  }

  processCreateBox(CreateBox node) {}
  visitCreateBox(CreateBox node) {
    processCreateBox(node);
  }
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
  /// Note that null is used as key for primitives without hints.
  final Map<Local, RegisterArray> elementRegisters = <Local, RegisterArray>{};

  RegisterArray getRegisterArray(Local local) {
    RegisterArray registers = elementRegisters[local];
    if (registers == null) {
      registers = new RegisterArray();
      elementRegisters[local] = registers;
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

  void visitFieldDefinition(FieldDefinition node) {
    if (node.hasInitializer) {
      visit(node.body);
    }
  }

  void visitRunnableBody(RunnableBody node) {
    visit(node.body);
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    if (!node.isAbstract) {
      visit(node.body);
    }
    // Assign indices to unused parameters.
    for (Definition param in node.parameters) {
      if (param is Primitive) {
        allocate(param);
      }
    }
  }

  void visitConstructorDefinition(ConstructorDefinition node) {
    if (!node.isAbstract) {
      node.initializers.forEach(visit);
      visit(node.body);
    }
    // Assign indices to unused parameters.
    for (Definition param in node.parameters) {
      if (param is Primitive) {
        allocate(param);
      }
    }
  }

  void visitFieldInitializer(FieldInitializer node) {
    visit(node.body.body);
  }

  void visitSuperInitializer(SuperInitializer node) {
    node.arguments.forEach(visit);
  }

  void visitLetPrim(LetPrim node) {
    visit(node.body);
    release(node.primitive);
    visit(node.primitive);
  }

  void visitLetCont(LetCont node) {
    node.continuations.forEach(visit);
    visit(node.body);
  }

  void visitLetHandler(LetHandler node) {
    visit(node.handler);
    // Handler parameters that were not used in the handler body will not have
    // had register indexes assigned.  Assign them here, otherwise they will
    // be eliminated later and they should not be (i.e., a catch clause that
    // does not use the exception parameter should not have the exception
    // parameter eliminated, because it would not be well-formed anymore).
    // In any case release the parameter indexes because the parameters are
    // not live in the try block.
    node.handler.parameters.forEach((Parameter parameter) {
      allocate(parameter);
      release(parameter);
    });
    visit(node.body);
  }

  void visitLetMutable(LetMutable node) {
    visit(node.body);
    visitReference(node.value);
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

  void visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    visitReference(node.receiver);
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
    for (LiteralMapEntry entry in node.entries) {
      visitReference(entry.key);
      visitReference(entry.value);
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

  void visitGetMutableVariable(GetMutableVariable node) {
  }

  void visitSetMutableVariable(SetMutableVariable node) {
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

  // JavaScript specific nodes.

  void visitSetField(SetField node) {
    visit(node.body);
    visitReference(node.value);
    visitReference(node.object);
  }

  void visitGetField(GetField node) {
    visitReference(node.object);
  }

  void visitCreateBox(CreateBox node) {
  }

  void visitCreateInstance(CreateInstance node) {
    node.arguments.forEach(visitReference);
  }

  void visitIdentical(Identical node) {
    visitReference(node.left);
    visitReference(node.right);
  }

  void visitInterceptor(Interceptor node) {
    visitReference(node.input);
  }
}
