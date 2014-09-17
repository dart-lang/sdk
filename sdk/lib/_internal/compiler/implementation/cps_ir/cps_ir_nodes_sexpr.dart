// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_nodes_sexpr;

import '../util/util.dart';
import 'cps_ir_nodes.dart';

/// Generate a Lisp-like S-expression representation of an IR node as a string.
class SExpressionStringifier extends Visitor<String> with Indentation {
  final Map<Definition, String> names = <Definition, String>{};

  int _valueCounter = 0;
  int _continuationCounter = 0;

  String newValueName() => 'v${_valueCounter++}';
  String newContinuationName() => 'k${_continuationCounter++}';

  String visitFunctionDefinition(FunctionDefinition node) {
    String name = node.element.name;
    names[node.returnContinuation] = 'return';
    String parameters = node.parameters
        .map((Parameter p) {
          String name = p.hint.name;
          names[p] = name;
          return name;
        })
        .join(' ');
    String body = indentBlock(() => visit(node.body));
    return '$indentation(FunctionDefinition $name ($parameters return)\n' +
                 '$body)';
  }

  String visitLetPrim(LetPrim node) {
    String name = newValueName();
    names[node.primitive] = name;
    String value = visit(node.primitive);
    String body = visit(node.body);
    return '$indentation(LetPrim $name $value)\n$body';
  }

  String visitLetCont(LetCont node) {
    String cont = newContinuationName();
    names[node.continuation] = cont;
    String parameters = node.continuation.parameters
        .map((Parameter p) {
          String name = newValueName();
          names[p] = name;
          return ' $name';
        })
       .join('');
    String contBody = indentBlock(() => visit(node.continuation.body));
    String body = visit(node.body);
    String op = node.continuation.isRecursive ? 'LetCont*' : 'LetCont';
    return '$indentation($op ($cont$parameters)\n' +
               '$contBody)\n' +
           '$body';
  }

  String formatArguments(Invoke node) {
    int positionalArgumentCount = node.selector.positionalArgumentCount;
    List<String> args = new List<String>();
    args.addAll(node.arguments.getRange(0, positionalArgumentCount)
        .map((v) => names[v.definition]));
    for (int i = 0; i < node.selector.namedArgumentCount; ++i) {
      String name = node.selector.namedArguments[i];
      Definition arg = node.arguments[positionalArgumentCount + i].definition;
      args.add("($name: $arg)");
    }
    return args.join(' ');
  }

  String visitInvokeStatic(InvokeStatic node) {
    String name = node.target.name;
    String cont = names[node.continuation.definition];
    String args = formatArguments(node);
    return '$indentation(InvokeStatic $name $args $cont)';
  }

  String visitInvokeMethod(InvokeMethod node) {
    String name = node.selector.name;
    String rcv = names[node.receiver.definition];
    String cont = names[node.continuation.definition];
    String args = formatArguments(node);
    return '$indentation(InvokeMethod $rcv $name $args $cont)';
  }

  String visitInvokeSuperMethod(InvokeSuperMethod node) {
    String name = node.selector.name;
    String cont = names[node.continuation.definition];
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
    String cont = names[node.continuation.definition];
    String args = formatArguments(node);
    return '$indentation(InvokeConstructor $callName $args $cont)';
  }

  String visitConcatenateStrings(ConcatenateStrings node) {
    String cont = names[node.continuation.definition];
    String args = node.arguments.map((v) => names[v.definition]).join(' ');
    return '$indentation(ConcatenateStrings $args $cont)';
  }

  String visitInvokeContinuation(InvokeContinuation node) {
    String cont = names[node.continuation.definition];
    String args = node.arguments.map((v) => names[v.definition]).join(' ');
    String op =
        node.isRecursive ? 'InvokeContinuation*' : 'InvokeContinuation';
    return '$indentation($op $cont $args)';
  }

  String visitBranch(Branch node) {
    String condition = visit(node.condition);
    String trueCont = names[node.trueContinuation.definition];
    String falseCont = names[node.falseContinuation.definition];
    return '$indentation(Branch $condition $trueCont $falseCont)';
  }

  String visitConstant(Constant node) {
    return '(Constant ${node.expression.value})';
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

  String visitParameter(Parameter node) {
    // Parameters are visited directly in visitLetCont.
    return '(Unexpected Parameter)';
  }

  String visitContinuation(Continuation node) {
    // Continuations are visited directly in visitLetCont.
    return '(Unexpected Continuation)';
  }

  String visitGetClosureVariable(GetClosureVariable node) {
    return '(GetClosureVariable ${node.variable.name})';
  }

  String visitSetClosureVariable(SetClosureVariable node) {
    String value = names[node.value.definition];
    String body = indentBlock(() => visit(node.body));
    return '$indentation(SetClosureVariable ${node.variable.name} $value\n' +
                '$body)';
  }

  String visitTypeOperator(TypeOperator node) {
    String receiver = names[node.receiver.definition];
    String cont = names[node.continuation.definition];
    return '$indentation(TypeOperator ${node.operator} $receiver ' +
                        '${node.type} $cont)';
  }

  String visitLiteralList(LiteralList node) {
    String values = node.values.map((v) => names[v.definition]).join(' ');
    return '(LiteralList ($values))';
  }

  String visitLiteralMap(LiteralMap node) {
    String keys = node.keys.map((v) => names[v.definition]).join(' ');
    String values = node.values.map((v) => names[v.definition]).join(' ');
    return '(LiteralMap ($keys) ($values))';
  }

  String visitDeclareFunction(DeclareFunction node) {
    String function = indentBlock(() => visit(node.definition));
    String body = indentBlock(() => visit(node.body));
    return '$indentation(DeclareFunction ${node.variable.name} =\n' +
                '$function in\n' +
                '$body)';
  }

  String visitIsTrue(IsTrue node) {
    String value = names[node.value.definition];
    return '(IsTrue $value)';
  }
}
