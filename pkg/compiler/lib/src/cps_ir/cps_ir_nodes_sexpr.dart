// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_nodes_sexpr;

import '../util/util.dart';
import 'cps_ir_nodes.dart';

/// A [Decorator] is a function used by [SExpressionStringifier] to augment the
/// output produced for a node.  It can be provided to the constructor.
typedef String Decorator(Node node, String s);

/// Generate a Lisp-like S-expression representation of an IR node as a string.
class SExpressionStringifier extends Visitor<String> with Indentation {
  final _Namer namer = new _Namer();

  String newValueName(Node node) => namer.defineValueName(node);
  String newContinuationName(Node node) => namer.defineContinuationName(node);
  final Decorator decorator;

  SExpressionStringifier([this.decorator]);

  String access(Reference<Definition> r) => namer.getName(r.definition);

  String visitParameter(Parameter node) {
    return namer.useElementName(node);
  }

  /// Main entry point for creating a [String] from a [Node].  All recursive
  /// calls must go through this method.
  String visit(Node node) {
    String s = super.visit(node);
    return (decorator == null) ? s : decorator(node, s);
  }

  String visitFunctionDefinition(FunctionDefinition node) {
    String name = node.element.name;
    namer.useReturnName(node.returnContinuation);
    String parameters = node.parameters.map(visit).join(' ');
    String body = indentBlock(() => visit(node.body));
    return '$indentation(FunctionDefinition $name ($parameters return)\n'
           '$body)';
  }

  String visitFieldDefinition(FieldDefinition node) {
    String name = node.element.name;
    if (node.hasInitializer) {
      namer.useReturnName(node.returnContinuation);
      String body = indentBlock(() => visit(node.body));
      return '$indentation(FieldDefinition $name (return)\n'
             '$body)';
    } else {
      return '$indentation(FieldDefinition $name)';
    }
  }

  String visitLetPrim(LetPrim node) {
    String name = newValueName(node.primitive);
    String value = visit(node.primitive);
    String body = visit(node.body);
    return '$indentation(LetPrim $name $value)\n$body';
  }

  String visitLetCont(LetCont node) {
    String cont = newContinuationName(node.continuation);
    // TODO(karlklose): this should be changed to `.map(visit).join(' ')`  and
    // should recurse to [visit].  Currently we can't do that, because the
    // unstringifier_test produces [LetConts] with dummy arguments on them.
    String parameters = node.continuation.parameters
        .map((p) => ' ${newValueName(p)}')
        .join('');
    String contBody = indentBlock(() => visit(node.continuation.body));
    String body = visit(node.body);
    String op = node.continuation.isRecursive ? 'LetCont*' : 'LetCont';
    return '$indentation($op ($cont$parameters)\n'
           '$contBody)\n'
           '$body';
  }

  String formatArguments(Invoke node) {
    int positionalArgumentCount = node.selector.positionalArgumentCount;
    List<String> args = new List<String>();
    args.addAll(
        node.arguments.getRange(0, positionalArgumentCount).map(access));
    for (int i = 0; i < node.selector.namedArgumentCount; ++i) {
      String name = node.selector.namedArguments[i];
      Definition arg = node.arguments[positionalArgumentCount + i].definition;
      args.add("($name: $arg)");
    }
    return args.join(' ');
  }

  String visitInvokeStatic(InvokeStatic node) {
    String name = node.target.name;
    String cont = access(node.continuation);
    String args = formatArguments(node);
    return '$indentation(InvokeStatic $name $args $cont)';
  }

  String visitInvokeMethod(InvokeMethod node) {
    String name = node.selector.name;
    String rcv = access(node.receiver);
    String cont = access(node.continuation);
    String args = formatArguments(node);
    return '$indentation(InvokeMethod $rcv $name $args $cont)';
  }

  String visitInvokeSuperMethod(InvokeSuperMethod node) {
    String name = node.selector.name;
    String cont = access(node.continuation);
    String args = formatArguments(node);
    return '$indentation(InvokeSuperMethod $name $args $cont)';
  }

  String visitInvokeConstructor(InvokeConstructor node) {
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${node.type}';
    } else {
      callName = '${node.type}.${node.target.name}';
    }
    String cont = access(node.continuation);
    String args = formatArguments(node);
    return '$indentation(InvokeConstructor $callName $args $cont)';
  }

  String visitConcatenateStrings(ConcatenateStrings node) {
    String cont = access(node.continuation);
    String args = node.arguments.map(access).join(' ');
    return '$indentation(ConcatenateStrings $args $cont)';
  }

  String visitInvokeContinuation(InvokeContinuation node) {
    String cont = access(node.continuation);
    String args = node.arguments.map(access).join(' ');
    String op =
        node.isRecursive ? 'InvokeContinuation*' : 'InvokeContinuation';
    return '$indentation($op $cont $args)';
  }

  String visitBranch(Branch node) {
    String condition = visit(node.condition);
    String trueCont = access(node.trueContinuation);
    String falseCont = access(node.falseContinuation);
    return '$indentation(Branch $condition $trueCont $falseCont)';
  }

  String visitConstant(Constant node) {
    return '(Constant ${node.expression.value.toStructuredString()})';
  }

  String visitThis(This node) {
    return '(This)';
  }

  String visitReifyTypeVar(ReifyTypeVar node) {
    return '$indentation(ReifyTypeVar ${node.typeVariable.name})';
  }

  String visitCreateFunction(CreateFunction node) {
    String function = indentBlock(() => visit(node.definition));
    return '(CreateFunction\n$function)';
  }

  String visitContinuation(Continuation node) {
    // Continuations are visited directly in visitLetCont.
    return '(Unexpected Continuation)';
  }

  String visitGetClosureVariable(GetClosureVariable node) {
    return '(GetClosureVariable ${node.variable.name})';
  }

  String visitSetClosureVariable(SetClosureVariable node) {
    String value = access(node.value);
    String body = indentBlock(() => visit(node.body));
    return '$indentation(SetClosureVariable ${node.variable.name} $value\n'
           '$body)';
  }

  String visitTypeOperator(TypeOperator node) {
    String receiver = access(node.receiver);
    String cont = access(node.continuation);
    String operator = node.isTypeTest ? 'is' : 'as';
    return '$indentation(TypeOperator $operator $receiver ${node.type} $cont)';
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

  String visitDeclareFunction(DeclareFunction node) {
    String function = indentBlock(() => visit(node.definition));
    String body = indentBlock(() => visit(node.body));
    return '$indentation(DeclareFunction ${node.variable.name} =\n'
           '$function in\n'
           '$body)';
  }

  String visitIsTrue(IsTrue node) {
    String value = access(node.value);
    return '(IsTrue $value)';
  }

  String visitIdentical(Identical node) {
    String left = access(node.left);
    String right = access(node.right);
    return '(Identical $left $right)';
  }
}

class _Namer {
  final Map<Node, String> _names = <Node, String>{};
  int _valueCounter = 0;
  int _continuationCounter = 0;

  String useElementName(Parameter parameter) {
    assert(!_names.containsKey(parameter));
    return _names[parameter] = parameter.hint.name;
  }

  String defineContinuationName(Node node) {
    assert(!_names.containsKey(node));
    return _names[node] = 'k${_continuationCounter++}';
  }

  String defineValueName(Node node) {
    assert(!_names.containsKey(node));
    return _names[node] = 'v${_valueCounter++}';
  }

  String useReturnName(Continuation node) {
    assert(!_names.containsKey(node) || _names[node] == 'return');
    return _names[node] = 'return';
  }

  String getName(Node node) {
    assert(_names.containsKey(node));
    return _names[node];
  }
}
