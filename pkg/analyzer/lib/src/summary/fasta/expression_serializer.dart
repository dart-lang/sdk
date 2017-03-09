// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Algorithm to serialize expressions into the format used by summaries.
library summary.src.expression_serializer;

import 'package:front_end/src/fasta/scanner/token_constants.dart';

import 'model.dart';

/// Translate a parser binary operation into an operation in the summary format.
UnlinkedExprOperation _binaryOpFor(int operatorKind) {
  switch (operatorKind) {
    case AMPERSAND_TOKEN:
      return UnlinkedExprOperation.bitAnd;
    case AMPERSAND_AMPERSAND_TOKEN:
      return UnlinkedExprOperation.and;
    case BANG_EQ_TOKEN:
      return UnlinkedExprOperation.notEqual;
    case BAR_TOKEN:
      return UnlinkedExprOperation.bitOr;
    case BAR_BAR_TOKEN:
      return UnlinkedExprOperation.or;
    case CARET_TOKEN:
      return UnlinkedExprOperation.bitXor;
    case EQ_EQ_TOKEN:
      return UnlinkedExprOperation.equal;
    case GT_TOKEN:
      return UnlinkedExprOperation.greater;
    case GT_EQ_TOKEN:
      return UnlinkedExprOperation.greaterEqual;
    case GT_GT_TOKEN:
      return UnlinkedExprOperation.bitShiftRight;
    case LT_TOKEN:
      return UnlinkedExprOperation.less;
    case LT_EQ_TOKEN:
      return UnlinkedExprOperation.lessEqual;
    case LT_LT_TOKEN:
      return UnlinkedExprOperation.bitShiftLeft;
    case MINUS_TOKEN:
      return UnlinkedExprOperation.subtract;
    case PERCENT_TOKEN:
      return UnlinkedExprOperation.modulo;
    case PERIOD_TOKEN:
      return UnlinkedExprOperation.extractProperty;
    case PLUS_TOKEN:
      return UnlinkedExprOperation.add;
    case QUESTION_QUESTION_TOKEN:
      return UnlinkedExprOperation.ifNull;
    case SLASH_TOKEN:
      return UnlinkedExprOperation.divide;
    case STAR_TOKEN:
      return UnlinkedExprOperation.multiply;
    case TILDE_SLASH_TOKEN:
      return UnlinkedExprOperation.floorDivide;
    default:
      throw "Unhandled openratorKind $operatorKind";
  }
}

/// Translate a parser unary operation into an operation in the summary format.
UnlinkedExprOperation _unaryOpFor(int operatorKind) {
  switch (operatorKind) {
    case BANG_TOKEN:
      return UnlinkedExprOperation.not;
    case MINUS_TOKEN:
      return UnlinkedExprOperation.negate;
    default:
      throw "Unhandled operator kind $operatorKind";
  }
}

/// Visitor over the minimal expression AST to convert them into stack-like
/// expressions used in the summary format.
class Serializer extends RecursiveVisitor {
  UnlinkedExprBuilder expression;
  final Scope scope;
  final bool forConst;

  Serializer(this.scope, this.forConst);

  handleAs(As n) {
    throw new UnimplementedError(); // TODO(paulberry): fix the code below.
    // handleType(a.type);
    // expression.operations.add(UnlinkedExprOperation.typeCast);
  }

  handleBinary(Binary n) {
    expression.operations.add(_binaryOpFor(n.operator));
  }

  handleBool(BoolLiteral n) {
    expression.operations.add(n.value
        ? UnlinkedExprOperation.pushTrue
        : UnlinkedExprOperation.pushFalse);
  }

  handleConditional(Conditional n) {
    expression.operations.add(UnlinkedExprOperation.conditional);
  }

  handleConstCreation(ConstCreation n) {
    var ctor = n.constructor;
    var type = handleType(ctor.type);
    if (ctor.name != null) {
      throw new UnimplementedError(); // TODO(paulberry): fix the code below.
      //var classRef = handleRef(ctor.type.name, push: false);
      //var top = scope.top;
      //var ref = new LazyEntityRef(ctor.name, top)
      //  ..reference = (scope.serializeReference(classRef.reference, ctor.name))
      //  ..typeArguments = type.typeArguments
      //  ..wasExpanded = true;
      //expression.references.add(ref);
    } else {
      expression.references.add(type);
    }
    expression.ints.add(n.namedArgs.length);
    expression.ints.add(n.positionalArgs.length);
    expression.strings.addAll(n.namedArgs.map((a) => a.name));
    expression.operations.add(UnlinkedExprOperation.invokeConstructor);
  }

  handleDouble(DoubleLiteral n) {
    expression.operations.add(UnlinkedExprOperation.pushDouble);
    expression.doubles.add(n.value);
  }

  handleIdentical(Identical n) {
    expression.references.add(handleRef(new Ref('identical'), push: false));
    expression.ints.add(0);
    expression.ints.add(2);
    expression.ints.add(0);
    expression.operations.add(UnlinkedExprOperation.invokeMethodRef);
  }

  handleInt(IntLiteral n) {
    var ints = expression.ints;
    var operations = expression.operations;
    int value = n.value;
    assert(value >= 0);
    if (value >= (1 << 32)) {
      int numOfComponents = 0;
      expression.ints.add(numOfComponents);
      void pushComponents(int value) {
        if (value >= (1 << 32)) {
          pushComponents(value >> 32);
        }
        numOfComponents++;
        ints.add(value & 0xFFFFFFFF);
      }

      pushComponents(value);
      ints[ints.length - 1 - numOfComponents] = numOfComponents;
      operations.add(UnlinkedExprOperation.pushLongInt);
    } else {
      operations.add(UnlinkedExprOperation.pushInt);
      ints.add(value);
    }
  }

  handleInvalid(Invalid n) {
    expression.isValidConst = false;
    throw new UnimplementedError(); // TODO(paulberry): fix the code below.
    // expression.operations.add(UnlinkedExprOperation.pushInvalidor);
  }

  handleIs(Is n) {
    throw new UnimplementedError(); // TODO(paulberry): fix the code below.
    // handleType(i.type);
    // expression.operations.add(UnlinkedExprOperation.typeCheck);
  }

  handleList(ListLiteral n) {
    expression.ints.add(n.values.length);
    if (n.elementType == null) {
      expression.operations.add(UnlinkedExprOperation.makeUntypedList);
    } else {
      handleType(n.elementType);
      expression.operations.add(UnlinkedExprOperation.makeTypedList);
    }
  }

  handleLoad(Load n) {
    expression.strings.add(n.name);
    expression.operations.add(UnlinkedExprOperation.extractProperty);
  }

  handleMap(MapLiteral n) {
    expression.ints.add(n.values.length);
    if (n.types.isEmpty) {
      expression.operations.add(UnlinkedExprOperation.makeUntypedMap);
    } else {
      n.types.forEach(handleType);
      expression.operations.add(UnlinkedExprOperation.makeTypedMap);
    }
  }

  handleNull(NullLiteral n) {
    expression.operations.add(UnlinkedExprOperation.pushNull);
  }

  handleOpaque(Opaque n) {
    if (n.type != null) {
      handleType(n.type);
      expression.operations.add(UnlinkedExprOperation.pushTypedAbstract);
    } else {
      expression.operations.add(UnlinkedExprOperation.pushUntypedAbstract);
    }
  }

  handleOpaqueOp(OpaqueOp n) {
    // nothing to do, recursive visitor serialized subexpression.
  }

  handleRef(Ref n, {push: true}) {
    var ref = n.prefix == null
        ? new LazyEntityRef(n.name, scope)
        : new NestedLazyEntityRef(
            handleRef(n.prefix, push: false), n.name, scope);
    if (push) {
      expression.references.add(ref);
      expression.operations.add(UnlinkedExprOperation.pushReference);
    }
    return ref;
  }

  handleString(StringLiteral n) {
    expression.strings.add(n.value);
    expression.operations.add(UnlinkedExprOperation.pushString);
  }

  handleSymbol(SymbolLiteral n) {
    expression.strings.add(n.value);
    expression.operations.add(UnlinkedExprOperation.makeSymbol);
  }

  handleType(TypeRef n) {
    var t = handleRef(n.name, push: false);
    var args = n.typeArguments ?? [];
    t.typeArguments = args.map((a) => handleType(a)).toList();
    return t;
  }

  handleUnary(Unary n) {
    expression.operations.add(_unaryOpFor(n.operator));
  }

  run(Expression root) {
    expression = new UnlinkedExprBuilder(
        isValidConst: forConst,
        operations: [],
        assignmentOperators: [],
        ints: [],
        doubles: [],
        strings: [],
        references: []);
    root.accept(this);
    expression.references.forEach((r) => (r as LazyEntityRef).expand());
    return expression;
  }
}
