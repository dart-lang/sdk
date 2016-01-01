// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_nodes_sexpr;

import '../constants/values.dart';
import '../util/util.dart';
import 'cps_ir_nodes.dart';
import '../universe/call_structure.dart' show
    CallStructure;

/// A [Decorator] is a function used by [SExpressionStringifier] to augment the
/// output produced for a node or reference.  It can be provided to the
/// constructor.
typedef String Decorator(node, String s);

/// Generate a Lisp-like S-expression representation of an IR node as a string.
class SExpressionStringifier extends Indentation implements Visitor<String> {
  final _Namer namer = new _Namer();

  String newValueName(Primitive node) => namer.nameValue(node);
  String newContinuationName(Continuation node) => namer.nameContinuation(node);
  Decorator decorator;

  SExpressionStringifier([this.decorator]) {
    if (this.decorator == null) {
      this.decorator = (node, String s) => s;
    }
  }

  String access(Reference<Definition> r) {
    return decorator(r, namer.getName(r.definition));
  }

  String optionalAccess(Reference<Definition> reference) {
    return reference == null ? '()' : '(${access(reference)})';
  }

  String visitParameter(Parameter node) {
    return namer.nameParameter(node);
  }

  String visitMutableVariable(MutableVariable node) {
    return namer.nameMutableVariable(node);
  }

  /// Main entry point for creating a [String] from a [Node].  All recursive
  /// calls must go through this method.
  String visit(Node node) {
    if (node == null) return '**** NULL ****';
    String s = node.accept(this);
    return decorator(node, s);
  }

  String formatThisParameter(Parameter thisParameter) {
    return thisParameter == null ? '()' : '(${visit(thisParameter)})';
  }

  String visitFunctionDefinition(FunctionDefinition node) {
    String name = node.element.name;
    String thisParameter = formatThisParameter(node.thisParameter);
    String parameters = node.parameters.map(visit).join(' ');
    namer.setReturnContinuation(node.returnContinuation);
    String body = indentBlock(() => visit(node.body));
    return '$indentation'
        '(FunctionDefinition $name $thisParameter ($parameters) return\n'
        '$body)';
  }

  String visitLetPrim(LetPrim node) {
    String name = newValueName(node.primitive);
    String value = visit(node.primitive);
    String body = indentBlock(() => visit(node.body));
    return '$indentation(LetPrim ($name $value)\n$body)';
  }

  String visitLetCont(LetCont node) {
    String conts;
    bool first = true;
    for (Continuation continuation in node.continuations) {
      if (first) {
        first = false;
        conts = visit(continuation);
      } else {
        // Each subsequent line is indented additional spaces to align it
        // with the previous continuation.
        String indent = '$indentation${' ' * '(LetCont ('.length}';
        conts = '$conts\n$indent${visit(continuation)}';
      }
    }
    String body = indentBlock(() => visit(node.body));
    return '$indentation(LetCont ($conts)\n$body)';
  }

  String visitLetHandler(LetHandler node) {
    // There are no explicit references to the handler, so we leave it
    // anonymous in the printed representation.
    String parameters = node.handler.parameters
        .map((p) => '${decorator(p, newValueName(p))}')
        .join(' ');
    String handlerBody =
        indentBlock(() => indentBlock(() => visit(node.handler.body)));
    String body = indentBlock(() => visit(node.body));
    return '$indentation(LetHandler (($parameters)\n$handlerBody)\n$body)';
  }

  String visitLetMutable(LetMutable node) {
    String name = visit(node.variable);
    String value = access(node.value);
    String body = indentBlock(() => visit(node.body));
    return '$indentation(LetMutable ($name $value)\n$body)';
  }

  String formatArguments(CallStructure call,
      List<Reference<Primitive>> arguments,
      [CallingConvention callingConvention = CallingConvention.Normal]) {
    int positionalArgumentCount = call.positionalArgumentCount;
    if (callingConvention == CallingConvention.Intercepted ||
        callingConvention == CallingConvention.DummyIntercepted) {
      ++positionalArgumentCount;
    }
    List<String> args =
        arguments.take(positionalArgumentCount).map(access).toList();
    List<String> argumentNames = call.getOrderedNamedArguments();
    for (int i = 0; i < argumentNames.length; ++i) {
      String name = argumentNames[i];
      String arg = access(arguments[positionalArgumentCount + i]);
      args.add("($name: $arg)");
    }
    // Constructors can have type parameter after the named arguments.
    args.addAll(
        arguments.skip(positionalArgumentCount + argumentNames.length)
            .map(access));
    return '(${args.join(' ')})';
  }

  String visitInvokeStatic(InvokeStatic node) {
    String name = node.target.name;
    String args = formatArguments(node.selector.callStructure, node.arguments);
    return '(InvokeStatic $name $args)';
  }

  String visitInvokeMethod(InvokeMethod node) {
    String name = node.selector.name;
    String rcv = access(node.receiver);
    String args = formatArguments(node.selector.callStructure, node.arguments,
        node.callingConvention);
    return '(InvokeMethod $rcv $name $args)';
  }

  String visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    String receiver = access(node.receiver);
    String name = node.selector.name;
    String args = formatArguments(node.selector.callStructure, node.arguments,
        node.callingConvention);
    return '(InvokeMethodDirectly $receiver $name $args)';
  }

  String visitInvokeConstructor(InvokeConstructor node) {
    // TODO(karlklose): for illegal nodes constructed for tests or unresolved
    // constructor calls in the DartBackend, we get an element with no enclosing
    // class.  Clean this up by introducing a name field to the node and
    // removing [ErroneousElement]s from the IR.
    String name = node.dartType != null
        ? node.dartType.toString()
        : node.target.enclosingClass.name;
    if (!node.target.name.isEmpty) {
      name = '${name}.${node.target.name}';
    }
    String args = formatArguments(node.selector.callStructure, node.arguments);
    return '(InvokeConstructor $name $args)';
  }

  String visitInvokeContinuation(InvokeContinuation node) {
    String name = access(node.continuation);
    if (node.isRecursive) name = 'rec $name';
    String args = node.arguments.map(access).join(' ');
    String escaping = node.isEscapingTry ? ' escape' : '';
    return '$indentation(InvokeContinuation $name ($args)$escaping)';
  }

  String visitThrow(Throw node) {
    String value = access(node.value);
    return '$indentation(Throw $value)';
  }

  String visitRethrow(Rethrow node) {
    return '$indentation(Rethrow)';
  }

  String visitBranch(Branch node) {
    String condition = access(node.condition);
    String trueCont = access(node.trueContinuation);
    String falseCont = access(node.falseContinuation);
    String strict = node.isStrictCheck ? 'Strict' : 'NonStrict';
    return '$indentation(Branch $condition $trueCont $falseCont $strict)';
  }

  String visitUnreachable(Unreachable node) {
    return '$indentation(Unreachable)';
  }

  String visitConstant(Constant node) {
    String value = node.value.accept(new ConstantStringifier(), null);
    return '(Constant $value)';
  }

  String visitContinuation(Continuation node) {
    String name = newContinuationName(node);
    if (node.isRecursive) name = 'rec $name';
    // TODO(karlklose): this should be changed to `.map(visit).join(' ')`  and
    // should recurse to [visit].  Currently we can't do that, because the
    // unstringifier_test produces [LetConts] with dummy arguments on them.
    String parameters = node.parameters
        .map((p) => '${decorator(p, newValueName(p))}')
        .join(' ');
    String body = indentBlock(() => indentBlock(() => visit(node.body)));
    return '($name ($parameters)\n$body)';
  }

  String visitGetMutable(GetMutable node) {
    return '(GetMutable ${access(node.variable)})';
  }

  String visitSetMutable(SetMutable node) {
    String value = access(node.value);
    return '(SetMutable ${access(node.variable)} $value)';
  }

  String visitTypeCast(TypeCast node) {
    String value = access(node.value);
    String typeArguments = node.typeArguments.map(access).join(' ');
    return '(TypeCast $value ${node.dartType} ($typeArguments))';
  }

  String visitTypeTest(TypeTest node) {
    String value = access(node.value);
    String typeArguments = node.typeArguments.map(access).join(' ');
    return '(TypeTest $value ${node.dartType} ($typeArguments))';
  }

  String visitTypeTestViaFlag(TypeTestViaFlag node) {
    String interceptor = access(node.interceptor);
    return '(TypeTestViaFlag $interceptor ${node.dartType})';
  }

  String visitLiteralList(LiteralList node) {
    String values = node.values.map(access).join(' ');
    return '(LiteralList ($values))';
  }

  String visitLiteralMap(LiteralMap node) {
    String keys = node.entries.map((e) => access(e.key)).join(' ');
    String values = node.entries.map((e) => access(e.value)).join(' ');
    return '(LiteralMap ($keys) ($values))';
  }

  String visitSetField(SetField node) {
    String object = access(node.object);
    String field = node.field.name;
    String value = access(node.value);
    return '(SetField $object $field $value)';
  }

  String visitGetField(GetField node) {
    String object = access(node.object);
    String field = node.field.name;
    return '(GetField $object $field)';
  }

  String visitGetStatic(GetStatic node) {
    String element = node.element.name;
    return '(GetStatic $element)';
  }

  String visitSetStatic(SetStatic node) {
    String element = node.element.name;
    String value = access(node.value);
    return '(SetStatic $element $value)';
  }

  String visitGetLazyStatic(GetLazyStatic node) {
    String element = node.element.name;
    return '(GetLazyStatic $element)';
  }

  String visitCreateBox(CreateBox node) {
    return '(CreateBox)';
  }

  String visitCreateInstance(CreateInstance node) {
    String className = node.classElement.name;
    String arguments = node.arguments.map(access).join(' ');
    String typeInformation = node.typeInformation.map(access).join(' ');
    return '(CreateInstance $className ($arguments) ($typeInformation))';
  }

  String visitInterceptor(Interceptor node) {
    return '(Interceptor ${access(node.input)})';
  }

  String visitReifyRuntimeType(ReifyRuntimeType node) {
    return '(ReifyRuntimeType ${access(node.value)})';
  }

  String visitReadTypeVariable(ReadTypeVariable node) {
    return '(ReadTypeVariable ${access(node.target)}.${node.variable})';
  }

  String visitTypeExpression(TypeExpression node) {
    String args = node.arguments.map(access).join(' ');
    return '(TypeExpression ${node.dartType} ($args))';
  }

  String visitCreateInvocationMirror(CreateInvocationMirror node) {
    String selector = node.selector.name;
    String args = node.arguments.map(access).join(' ');
    return '(CreateInvocationMirror $selector ($args))';
  }

  String visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    String operator = node.operator.toString();
    String args = node.arguments.map(access).join(' ');
    return '(ApplyBuiltinOperator $operator ($args))';
  }

  String visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    String method = node.method.toString();
    String receiver = access(node.receiver);
    String args = node.arguments.map(access).join(' ');
    return '(ApplyBuiltinMethod $method $receiver ($args))';
  }

  String visitForeignCode(ForeignCode node) {
    String arguments = node.arguments.map(access).join(' ');
    return '(JS "${node.codeTemplate.source}" ($arguments))';
  }

  String visitGetLength(GetLength node) {
    String object = access(node.object);
    return '(GetLength $object)';
  }

  String visitGetIndex(GetIndex node) {
    String object = access(node.object);
    String index = access(node.index);
    return '(GetIndex $object $index)';
  }

  String visitSetIndex(SetIndex node) {
    String object = access(node.object);
    String index = access(node.index);
    String value = access(node.value);
    return '(SetIndex $object $index $value)';
  }

  @override
  String visitAwait(Await node) {
    String value = access(node.input);
    return '(Await $value)';
  }

  @override
  String visitYield(Yield node) {
    String value = access(node.input);
    return '(Yield $value)';
  }

  String visitRefinement(Refinement node) {
    String value = access(node.value);
    return '(Refinement $value ${node.type})';
  }

  String visitBoundsCheck(BoundsCheck node) {
    String object = access(node.object);
    String index = optionalAccess(node.index);
    String length = optionalAccess(node.length);
    return '(BoundsCheck $object $index $length ${node.checkString})';
  }

  String visitNullCheck(NullCheck node) {
    String value = access(node.value);
    String condition = optionalAccess(node.condition);
    return '(NullCheck $value $condition (${node.selector ?? ""}))';
  }
}

class ConstantStringifier extends ConstantValueVisitor<String, Null> {
  // Some of these methods are unimplemented because we haven't had a need
  // to print such constants.  When printing is implemented, the corresponding
  // parsing support should be added to SExpressionUnstringifier.parseConstant
  // in the dart2js tests (currently in the file
  // tests/compiler/dart2js/backend_dart/sexpr_unstringifier.dart).

  String _failWith(ConstantValue constant) {
    throw 'Stringification not supported for ${constant.toStructuredString()}';
  }

  String visitFunction(FunctionConstantValue constant, _) {
    return '(Function "${constant.unparse()}")';
  }

  String visitNull(NullConstantValue constant, _) {
    return '(Null)';
  }

  String visitInt(IntConstantValue constant, _) {
    return '(Int ${constant.unparse()})';
  }

  String visitDouble(DoubleConstantValue constant, _) {
    return '(Double ${constant.unparse()})';
  }

  String visitBool(BoolConstantValue constant, _) {
    return '(Bool ${constant.unparse()})';
  }

  String visitString(StringConstantValue constant, _) {
    return '(String ${constant.unparse()})';
  }

  String visitList(ListConstantValue constant, _) {
    String entries =
      constant.entries.map((entry) => entry.accept(this, _)).join(' ');
    return '(List $entries)';
  }

  String visitMap(MapConstantValue constant, _) {
    List<String> elements = <String>[];
    for (int i = 0; i < constant.keys.length; ++i) {
      ConstantValue key = constant.keys[i];
      ConstantValue value = constant.values[i];
      elements.add('(${key.accept(this, _)} . ${value.accept(this, _)})');
    }
    return '(Map (${elements.join(' ')}))';
  }

  String visitConstructed(ConstructedConstantValue constant, _) {
    return '(Constructed "${constant.unparse()}")';
  }

  String visitType(TypeConstantValue constant, _) {
    return '(Type "${constant.representedType}")';
  }

  String visitInterceptor(InterceptorConstantValue constant, _) {
    return '(Interceptor "${constant.unparse()}")';
  }

  String visitSynthetic(SyntheticConstantValue constant, _) {
    return '(Synthetic "${constant.unparse()}")';
  }

  String visitDeferred(DeferredConstantValue constant, _) {
    return _failWith(constant);
  }
}

class _Namer {
  final Map<Node, String> _names = <Node, String>{};
  int _valueCounter = 0;
  int _continuationCounter = 0;

  // TODO(sra): Make the methods not assert and print something indicating an
  // error, so printer can be used to inspect broken terms.

  String nameParameter(Parameter parameter) {
    assert(!_names.containsKey(parameter));
    String name =
        parameter.hint != null ? parameter.hint.name : nameValue(parameter);
    return _names[parameter] = name;
  }

  String nameMutableVariable(MutableVariable variable) {
    assert(!_names.containsKey(variable));
    return _names[variable] = variable.hint.name;
  }

  String nameContinuation(Continuation node) {
    assert(!_names.containsKey(node));
    return _names[node] = 'k${_continuationCounter++}';
  }

  String nameValue(Primitive node) {
    assert(!_names.containsKey(node));
    return _names[node] = 'v${_valueCounter++}';
  }

  void setReturnContinuation(Continuation node) {
    assert(!_names.containsKey(node) || _names[node] == 'return');
    _names[node] = 'return';
  }

  String getName(Node node) {
    if (!_names.containsKey(node)) return 'MISSING_NAME';
    return _names[node];
  }
}
