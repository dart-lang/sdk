// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.ir_pickler;

class Unpickler {
  final Compiler compiler;

  final IrConstantPool constantPool;

  Unpickler(this.compiler, this.constantPool);

  List<int> data;

  int offset;

  /** For each entry index, the corresponding unpickled object. */
  List<Object> unpickled;

  /** Counter for entries in [unpickled]. */
  int index;

  /**
   * This buffer is used in [readConstantValue] to reconstruct a double value
   * from a sequence of bytes.
   */
  ByteData doubleData = new ByteData(8);

  ConstantSystem get constantSystem => compiler.backend.constantSystem;

  // A partially constructed expression is one that has a single 'hole' where
  // there is an expression missing.  Just like the IR builder, the unpickler
  // represents such an expression by its root and by the 'current' expression
  // that immediately contains the hole.  If there is no hole (e.g., an
  // expression in tail position has been seen), then current is null.
  ir.Expression root;
  ir.Expression current;

  ir.FunctionDefinition unpickle(List<int> data) {
    this.data = data;
    offset = 0;
    int numEntries = readInt();
    unpickled = new List<Object>(numEntries);
    index = 0;
    root = current = null;
    return readFunctionDefinition();
  }

  int readByte() {
    return data[offset++];
  }

  int readInt() {
    int result = 0;
    int next;
    for (int i = 0; true; i += 7) {
      next = readByte();
      result |= (next >> 1) << i;
      if ((next & 1) == 0) break;
    }
    bool isNegative = (result & 1) == 1;
    result >>= 1;
    return isNegative ? -result : result;
  }

  String readString() {
    int tag = readByte();
    int length = readInt();
    List<int> bytes = new Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = readByte();
    }
    if (tag == Pickles.STRING_ASCII) {
      return new String.fromCharCodes(bytes);
    } else if (tag == Pickles.STRING_UTF8) {
      return UTF8.decode(bytes);
    } else {
      compiler.internalError(NO_LOCATION_SPANNABLE,
                             "Unexpected string tag: $tag");
      return null;
    }
  }

  Element readElement() {
    int elementIndex = readInt();
    return constantPool.get(elementIndex);
  }

  Selector readSelector() {
    int tag = readByte();
    if (tag == Pickles.BACKREFERENCE) {
      return readBackReference();
    }
    assert(tag == Pickles.SELECTOR_UNTYPED);
    int entryIndex = index++;
    SelectorKind kind = Pickles.selectorKindFromId[readInt()];
    String name = readString();
    Element library = readElement();
    int argumentsCount = readInt();
    int namedArgumentsCount = readInt();
    List<String> namedArguments = new List<String>(namedArgumentsCount);
    for (int i = 0; i < namedArgumentsCount; i++) {
      namedArguments[i] = readString();
    }
    Selector result = new Selector(
        kind, name, library, argumentsCount, namedArguments);
    unpickled[entryIndex] = result;
    return result;
  }

  void addExpression(ir.Expression expr) {
    if (root == null) {
      root = current = expr;
    } else {
      current = current.plug(expr);
    }
  }

  // Read a single expression and plug it into the outer context.
  ir.Expression readExpressionNode() {
    int tag = readByte();
    switch (tag) {
      // Nontail-position expressions.
      case Pickles.NODE_CONSTANT:
        ir.Definition constant = readConstant();
        unpickled[index++] = constant;
        addExpression(new ir.LetPrim(constant));
        break;
      case Pickles.NODE_LET_CONT:
        int parameterCount = readInt();
        List<ir.Parameter> parameters = new List<ir.Parameter>.generate(
            parameterCount, (i) => new ir.Parameter(null));
        ir.Continuation continuation = new ir.Continuation(parameters);
        unpickled[index++] = continuation;
        ir.Expression body = readDelimitedExpressionNode();
        parameters.forEach((p) => unpickled[index++] = p);
        addExpression(new ir.LetCont(continuation, body));
        break;

      // Tail-position expressions.
      case Pickles.NODE_INVOKE_STATIC:
        addExpression(readInvokeStatic());
        current = null;
        break;
      case Pickles.NODE_INVOKE_CONTINUATION:
        addExpression(readInvokeContinuation());
        current = null;
        break;
      case Pickles.NODE_BRANCH:
        addExpression(readBranch());
        current = null;
        break;

      default:
        compiler.internalError(NO_LOCATION_SPANNABLE,
                               "Unexpected expression entry tag: $tag");
        break;
    }
  }

  // Iteratively read expressions until an expression in a tail position
  // (e.g., an invocation) is found.  Do not change the outer context.
  ir.Expression readDelimitedExpressionNode() {
    ir.Expression previous_root = root;
    ir.Expression previous_current = current;
    root = current = null;
    do {
      readExpressionNode();
    } while (current != null);
    ir.Expression result = root;
    root = previous_root;
    current = previous_current;
    return result;
  }

  Object readBackReference() {
    int indexDelta = readInt();
    int entryIndex = index - indexDelta;
    assert(unpickled[entryIndex] != null);
    return unpickled[entryIndex];
  }

  List<ir.Definition> readBackReferenceList() {
    int length = readInt();
    List<ir.Definition> result = new List<ir.Definition>(length);
    for (int i = 0; i < length; ++i) {
      result[i] = readBackReference();
    }
    return result;
  }

  ir.FunctionDefinition readFunctionDefinition() {
    // There is implicitly a return continuation which can be the target of
    // back references.
    ir.Continuation continuation = new ir.Continuation.retrn();
    unpickled[index++] = continuation;

    int parameterCount = readInt();
    List<ir.Parameter> parameters = new List<ir.Parameter>.generate(
        parameterCount,
        (i) {
          ir.Parameter parameter = new ir.Parameter(readElement());
          unpickled[index++] = parameter;
          return parameter;
        });
    ir.Expression body = readDelimitedExpressionNode();
    return new ir.FunctionDefinition(continuation, parameters, body);
  }

  ir.Constant readConstant() {
    Constant constant = readConstantValue();
    return new ir.Constant(constant);
  }

  ir.InvokeStatic readInvokeStatic() {
    FunctionElement functionElement = readElement();
    Selector selector = readSelector();
    ir.Continuation continuation = readBackReference();
    List<ir.Definition> arguments = readBackReferenceList();
    return new ir.InvokeStatic(functionElement, selector, continuation,
                               arguments);
  }

  ir.InvokeContinuation readInvokeContinuation() {
    ir.Continuation continuation = readBackReference();
    List<ir.Definition> arguments = readBackReferenceList();
    return new ir.InvokeContinuation(continuation, arguments);
  }

  ir.Branch readBranch() {
    ir.Condition condition = readCondition();
    ir.Continuation trueContinuation = readBackReference();
    ir.Continuation falseContinuation = readBackReference();
    return new ir.Branch(condition, trueContinuation, falseContinuation);
  }

  ir.Condition readCondition() {
    int tag = readByte();
    assert(tag == Pickles.NODE_IS_TRUE);
    return readIsTrue();
  }

  ir.IsTrue readIsTrue() {
    ir.Definition value = readBackReference();
    return new ir.IsTrue(value);
  }

  Constant readConstantValue() {
    int tag = readByte();
    switch(tag) {
      case Pickles.CONST_BOOL:
        return constantSystem.createBool(readByte() == 1);
      case Pickles.CONST_INT:
        return constantSystem.createInt(readInt());
      case Pickles.CONST_DOUBLE:
        for (int i = 0; i < 8; i++) {
          doubleData.setUint8(i, readByte());
        }
        double value = doubleData.getFloat64(0, Endianness.BIG_ENDIAN);
        return constantSystem.createDouble(value);
      case Pickles.CONST_STRING_LITERAL:
      case Pickles.CONST_STRING_RAW:
      case Pickles.CONST_STRING_ESCAPED:
      case Pickles.CONST_STRING_CONS:
        return constantSystem.createString(readDartString(tag));
      case Pickles.CONST_NULL:
        return constantSystem.createNull();
      default:
        compiler.internalError(NO_LOCATION_SPANNABLE,
                               "Unexpected constant tag: $tag");
        return null;
    }
  }

  ast.DartString readDartString(int tag) {
    switch(tag) {
      case Pickles.CONST_STRING_LITERAL:
        return new ast.LiteralDartString(readString());
      case Pickles.CONST_STRING_RAW:
        return new ast.RawSourceDartString(readString(), readInt());
      case Pickles.CONST_STRING_ESCAPED:
        return new ast.EscapedSourceDartString(readString(), readInt());
      case Pickles.CONST_STRING_CONS:
        return new ast.ConsDartString(
            readDartString(readByte()), readDartString(readByte()));
      default:
        compiler.internalError(NO_LOCATION_SPANNABLE,
                               "Unexpected dart string tag: $tag");
        return null;
    }
  }
}
