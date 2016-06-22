// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_nodes_sexpr;

import '../constants/values.dart';
import '../util/util.dart';
import 'cps_ir_nodes.dart';
import '../universe/call_structure.dart' show CallStructure;

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

  /// Create a stringifier with an extra layer of decoration.
  SExpressionStringifier withDecorator(Decorator subDecorator) {
    return new SExpressionStringifier((node, String s) {
      return subDecorator(node, decorator(node, s));
    });
  }

  /// Create a stringifier that displays type information.
  SExpressionStringifier withTypes() => withDecorator(typeDecorator);

  /// Creates a stringifier that adds annotations from a map;
  /// see [Node.debugString].
  SExpressionStringifier withAnnotations(Map annotations) {
    return withDecorator(decoratorFromMap(annotations));
  }

  static Decorator decoratorFromMap(Map annotations) {
    Map<Node, String> nodeMap = {};
    for (var key in annotations.keys) {
      if (key is Node) {
        nodeMap[key] = '${annotations[key]}';
      } else {
        String text = key;
        Node node = annotations[key];
        if (nodeMap.containsKey(node)) {
          // In case two annotations belong to the same node,
          // put both annotations on that node.
          nodeMap[node] += ' $text';
        } else {
          nodeMap[node] = text;
        }
      }
    }
    return (node, string) {
      String text = nodeMap[node];
      if (text != null) return '***$string*** $text';
      return string;
    };
  }

  static String typeDecorator(node, String string) {
    return node is Variable ? '$string:${node.type}' : string;
  }

  String access(Reference<Definition> r) {
    if (r == null) return '**** NULL ****';
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

  String formatOptionalParameter(Parameter parameter) {
    return parameter == null ? '()' : '(${visit(parameter)})';
  }

  String visitFunctionDefinition(FunctionDefinition node) {
    String name = node.element.name;
    String interceptorParameter =
        formatOptionalParameter(node.interceptorParameter);
    String thisParameter = formatOptionalParameter(node.receiverParameter);
    String parameters = node.parameters.map(visit).join(' ');
    namer.setReturnContinuation(node.returnContinuation);
    String body = indentBlock(() => visit(node.body));
    return '$indentation'
        '(FunctionDefinition $name $interceptorParameter $thisParameter '
        '($parameters) return\n'
        '$body)';
  }

  String visitLetPrim(LetPrim node) {
    String name = newValueName(node.primitive);
    String value = visit(node.primitive);
    String bindings = '($name $value)';
    String skip = ' ' * '(LetPrim ('.length;
    while (node.body is LetPrim) {
      node = node.body;
      name = newValueName(node.primitive);
      value = visit(node.primitive);
      String binding = decorator(node, '($name $value)');
      bindings += '\n${indentation}$skip$binding';
    }
    String body = indentBlock(() => visit(node.body));
    return '$indentation(LetPrim ($bindings)\n$body)';
  }

  bool isBranchTarget(Continuation cont) {
    return cont.hasExactlyOneUse && cont.firstRef.parent is Branch;
  }

  String visitLetCont(LetCont node) {
    String conts;
    bool first = true;
    String skip = ' ' * '(LetCont ('.length;
    for (Continuation continuation in node.continuations) {
      // Branch continuations will be printed at their use site.
      if (isBranchTarget(continuation)) continue;
      if (first) {
        first = false;
        conts = visit(continuation);
      } else {
        // Each subsequent line is indented additional spaces to align it
        // with the previous continuation.
        conts += '\n${indentation}$skip${visit(continuation)}';
      }
    }
    // If there were no continuations printed, just print the body.
    if (first) return visit(node.body);

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
    String value = access(node.valueRef);
    String body = indentBlock(() => visit(node.body));
    return '$indentation(LetMutable ($name $value)\n$body)';
  }

  String formatArguments(
      CallStructure call, List<Reference<Primitive>> arguments,
      [CallingConvention callingConvention = CallingConvention.Normal]) {
    int positionalArgumentCount = call.positionalArgumentCount;
    List<String> args =
        arguments.take(positionalArgumentCount).map(access).toList();
    List<String> argumentNames = call.getOrderedNamedArguments();
    for (int i = 0; i < argumentNames.length; ++i) {
      String name = argumentNames[i];
      String arg = access(arguments[positionalArgumentCount + i]);
      args.add("($name: $arg)");
    }
    // Constructors can have type parameter after the named arguments.
    args.addAll(arguments
        .skip(positionalArgumentCount + argumentNames.length)
        .map(access));
    return '(${args.join(' ')})';
  }

  String visitInvokeStatic(InvokeStatic node) {
    String name = node.target.name;
    String args =
        formatArguments(node.selector.callStructure, node.argumentRefs);
    return '(InvokeStatic $name $args)';
  }

  String visitInvokeMethod(InvokeMethod node) {
    String name = node.selector.name;
    String interceptor = optionalAccess(node.interceptorRef);
    String receiver = access(node.receiverRef);
    String arguments = formatArguments(
        node.selector.callStructure, node.argumentRefs, node.callingConvention);
    return '(InvokeMethod $interceptor $receiver $name $arguments)';
  }

  String visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    String interceptor = optionalAccess(node.interceptorRef);
    String receiver = access(node.receiverRef);
    String name = node.selector.name;
    String arguments = formatArguments(
        node.selector.callStructure, node.argumentRefs, node.callingConvention);
    return '(InvokeMethodDirectly $interceptor $receiver $name $arguments)';
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
    String args =
        formatArguments(node.selector.callStructure, node.argumentRefs);
    return '(InvokeConstructor $name $args)';
  }

  String visitInvokeContinuation(InvokeContinuation node) {
    String name = access(node.continuationRef);
    if (node.isRecursive) name = 'rec $name';
    String args = node.argumentRefs == null
        ? '**** NULL ****'
        : node.argumentRefs.map(access).join(' ');
    String escaping = node.isEscapingTry ? ' escape' : '';
    return '$indentation(InvokeContinuation $name ($args)$escaping)';
  }

  String visitThrow(Throw node) {
    String value = access(node.valueRef);
    return '$indentation(Throw $value)';
  }

  String visitRethrow(Rethrow node) {
    return '$indentation(Rethrow)';
  }

  String visitBranch(Branch node) {
    String condition = access(node.conditionRef);
    assert(isBranchTarget(node.trueContinuation));
    assert(isBranchTarget(node.falseContinuation));
    String trueCont = indentBlock(() => visit(node.trueContinuation));
    String falseCont = indentBlock(() => visit(node.falseContinuation));
    String strict = node.isStrictCheck ? 'Strict' : 'NonStrict';
    return '$indentation(Branch $strict $condition\n$trueCont\n$falseCont)';
  }

  String visitUnreachable(Unreachable node) {
    return '$indentation(Unreachable)';
  }

  String visitConstant(Constant node) {
    String value = node.value.accept(new ConstantStringifier(), null);
    return '(Constant $value)';
  }

  String visitContinuation(Continuation node) {
    if (isBranchTarget(node)) {
      assert(node.parameters.isEmpty);
      assert(!node.isRecursive);
      return indentBlock(() => visit(node.body));
    }
    String name = newContinuationName(node);
    if (node.isRecursive) name = 'rec $name';
    // TODO(karlklose): this should be changed to `.map(visit).join(' ')`
    // and should recurse to [visit].  Currently we can't do that, because
    // the unstringifier_test produces [LetConts] with dummy arguments on
    // them.
    String parameters = node.parameters
        .map((p) => '${decorator(p, newValueName(p))}')
        .join(' ');
    String body = indentBlock(() => indentBlock(() => visit(node.body)));
    return '($name ($parameters)\n$body)';
  }

  String visitGetMutable(GetMutable node) {
    return '(GetMutable ${access(node.variableRef)})';
  }

  String visitSetMutable(SetMutable node) {
    String value = access(node.valueRef);
    return '(SetMutable ${access(node.variableRef)} $value)';
  }

  String visitTypeCast(TypeCast node) {
    String value = access(node.valueRef);
    String typeArguments = node.typeArgumentRefs.map(access).join(' ');
    return '(TypeCast $value ${node.dartType} ($typeArguments))';
  }

  String visitTypeTest(TypeTest node) {
    String value = access(node.valueRef);
    String typeArguments = node.typeArgumentRefs.map(access).join(' ');
    return '(TypeTest $value ${node.dartType} ($typeArguments))';
  }

  String visitTypeTestViaFlag(TypeTestViaFlag node) {
    String interceptor = access(node.interceptorRef);
    return '(TypeTestViaFlag $interceptor ${node.dartType})';
  }

  String visitLiteralList(LiteralList node) {
    String values = node.valueRefs.map(access).join(' ');
    return '(LiteralList ($values))';
  }

  String visitSetField(SetField node) {
    String object = access(node.objectRef);
    String field = node.field.name;
    String value = access(node.valueRef);
    return '(SetField $object $field $value)';
  }

  String visitGetField(GetField node) {
    String object = access(node.objectRef);
    String field = node.field.name;
    return '(GetField $object $field)';
  }

  String visitGetStatic(GetStatic node) {
    String element = node.element.name;
    return '(GetStatic $element)';
  }

  String visitSetStatic(SetStatic node) {
    String element = node.element.name;
    String value = access(node.valueRef);
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
    String arguments = node.argumentRefs.map(access).join(' ');
    String typeInformation = optionalAccess(node.typeInformationRef);
    return '(CreateInstance $className ($arguments) ($typeInformation))';
  }

  String visitInterceptor(Interceptor node) {
    return '(Interceptor ${access(node.inputRef)})';
  }

  String visitReifyRuntimeType(ReifyRuntimeType node) {
    return '(ReifyRuntimeType ${access(node.valueRef)})';
  }

  String visitReadTypeVariable(ReadTypeVariable node) {
    return '(ReadTypeVariable ${access(node.targetRef)}.${node.variable})';
  }

  String visitTypeExpression(TypeExpression node) {
    String args = node.argumentRefs.map(access).join(' ');
    return '(TypeExpression ${node.kindAsString} ${node.dartType} ($args))';
  }

  String visitCreateInvocationMirror(CreateInvocationMirror node) {
    String selector = node.selector.name;
    String args = node.argumentRefs.map(access).join(' ');
    return '(CreateInvocationMirror $selector ($args))';
  }

  String visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    String operator = node.operator.toString();
    String args = node.argumentRefs.map(access).join(' ');
    return '(ApplyBuiltinOperator $operator ($args))';
  }

  String visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    String method = node.method.toString();
    String receiver = access(node.receiverRef);
    String args = node.argumentRefs.map(access).join(' ');
    return '(ApplyBuiltinMethod $method $receiver ($args))';
  }

  String visitForeignCode(ForeignCode node) {
    String arguments = node.argumentRefs.map(access).join(' ');
    return '(JS "${node.codeTemplate.source}" ($arguments))';
  }

  String visitGetLength(GetLength node) {
    String object = access(node.objectRef);
    return '(GetLength $object)';
  }

  String visitGetIndex(GetIndex node) {
    String object = access(node.objectRef);
    String index = access(node.indexRef);
    return '(GetIndex $object $index)';
  }

  String visitSetIndex(SetIndex node) {
    String object = access(node.objectRef);
    String index = access(node.indexRef);
    String value = access(node.valueRef);
    return '(SetIndex $object $index $value)';
  }

  @override
  String visitAwait(Await node) {
    String value = access(node.inputRef);
    return '(Await $value)';
  }

  @override
  String visitYield(Yield node) {
    String value = access(node.inputRef);
    return '(Yield $value)';
  }

  String visitRefinement(Refinement node) {
    String value = access(node.value);
    return '(Refinement $value ${node.type})';
  }

  String visitBoundsCheck(BoundsCheck node) {
    String object = access(node.objectRef);
    String index = optionalAccess(node.indexRef);
    String length = optionalAccess(node.lengthRef);
    return '(BoundsCheck $object $index $length ${node.checkString})';
  }

  String visitReceiverCheck(ReceiverCheck node) {
    String value = access(node.valueRef);
    String condition = optionalAccess(node.conditionRef);
    return '(ReceiverCheck $value ${node.selector} $condition '
        '${node.flagString}))';
  }
}

class ConstantStringifier extends ConstantValueVisitor<String, Null> {
  // Some of these methods are unimplemented because we haven't had a need
  // to print such constants.  When printing is implemented, the corresponding
  // parsing support should be added to SExpressionUnstringifier.parseConstant
  // in the dart2js tests (currently in the file
  // tests/compiler/dart2js/backend_dart/sexpr_unstringifier.dart).

  String _failWith(ConstantValue constant) {
    throw 'Stringification not supported for ${constant.toStructuredText()}';
  }

  String visitFunction(FunctionConstantValue constant, _) {
    return '(Function "${constant.toDartText()}")';
  }

  String visitNull(NullConstantValue constant, _) {
    return '(Null)';
  }

  String visitNonConstant(NonConstantValue constant, _) {
    return '(NonConstant)';
  }

  String visitInt(IntConstantValue constant, _) {
    return '(Int ${constant.toDartText()})';
  }

  String visitDouble(DoubleConstantValue constant, _) {
    return '(Double ${constant.toDartText()})';
  }

  String visitBool(BoolConstantValue constant, _) {
    return '(Bool ${constant.toDartText()})';
  }

  String visitString(StringConstantValue constant, _) {
    return '(String ${constant.toDartText()})';
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
    return '(Constructed "${constant.toDartText()}")';
  }

  String visitType(TypeConstantValue constant, _) {
    return '(Type "${constant.representedType}")';
  }

  String visitInterceptor(InterceptorConstantValue constant, _) {
    return '(Interceptor "${constant.toDartText()}")';
  }

  String visitSynthetic(SyntheticConstantValue constant, _) {
    return '(Synthetic "${constant.toDartText()}")';
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
