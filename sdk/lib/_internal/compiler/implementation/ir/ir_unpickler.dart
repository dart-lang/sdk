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
   * This buffer is used in [readConstant] to reconstruct a double value from
   * a sequence of bytes.
   */
  ByteData doubleData = new ByteData(8);

  ConstantSystem get constantSystem => compiler.backend.constantSystem;

  ir.Function unpickle(List<int> data) {
    this.data = data;
    offset = 0;
    int numEntries = readInt();
    unpickled = new List<Object>(numEntries);
    index = 0;
    return readFunctionNode();
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
      compiler.internalError("Unexpected string tag: $tag");
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

  static ir.Expression addExpression(ir.Expression context,
                                     ir.Expression expr) {
    return (context == null) ? expr : context.plug(expr);
  }

  // Read a single expression and plug it into an outer context.  If the read
  // expression is not in tail position, return it.  Otherwise, return null.
  ir.Expression readExpressionNode(ir.Expression context) {
    int tag = readByte();
    switch (tag) {
      case Pickles.NODE_CONSTANT:
        ir.Trivial constant = readConstantNode();
        unpickled[index++] = constant;
        return addExpression(context, new ir.LetVal(constant));
      case Pickles.NODE_LET_CONT:
        ir.Parameter parameter = new ir.Parameter();
        ir.Continuation continuation = new ir.Continuation(parameter);
        unpickled[index++] = continuation;
        ir.Expression body = readDelimitedExpressionNode();
        unpickled[index++] = parameter;
        return addExpression(context, new ir.LetCont(continuation, body));
      case Pickles.NODE_INVOKE_STATIC:
        addExpression(context, readInvokeStaticNode());
        return null;
      case Pickles.NODE_INVOKE_CONTINUATION:
        addExpression(context, readInvokeContinuationNode());
        return null;
      default:
        compiler.internalError("Unexpected expression entry tag: $tag");
        return null;
    }
  }

  // Iteratively read expressions until an expression in a tail position
  // (e.g., an invocation) is found.
  ir.Expression readDelimitedExpressionNode() {
    ir.Expression root = readExpressionNode(null);
    ir.Expression context = root;
    while (context != null) {
      context = readExpressionNode(context);
    }
    return root;
  }

  Object readBackReference() {
    int indexDelta = readInt();
    int entryIndex = index - indexDelta;
    assert(unpickled[entryIndex] != null);
    return unpickled[entryIndex];
  }

  List<ir.Trivial> readBackReferenceList() {
    int length = readInt();
    List<ir.Trivial> result = new List<ir.Trivial>(length);
    for (int i = 0; i < length; i++) {
      result[i] = readBackReference();
    }
    return result;
  }

  ir.Function readFunctionNode() {
    int endOffset = readInt();
    int namePosition = readInt();
    // There is implicitly a return continuation which can be the target of
    // back references.
    ir.Continuation continuation = new ir.Continuation.retrn();
    unpickled[index++] = continuation;

    ir.Expression body = readDelimitedExpressionNode();
    return new ir.Function(endOffset, namePosition, continuation, body);
  }

  ir.Constant readConstantNode() {
    Constant constant = readConstant();
    return new ir.Constant(constant);
  }

  ir.InvokeStatic readInvokeStaticNode() {
    FunctionElement functionElement = readElement();
    Selector selector = readSelector();
    ir.Continuation continuation = readBackReference();
    List<ir.Trivial> arguments = readBackReferenceList();
    return new ir.InvokeStatic(functionElement, selector, continuation,
                               arguments);
  }

  ir.InvokeContinuation readInvokeContinuationNode() {
    ir.Continuation continuation = readBackReference();
    ir.Trivial argument = readBackReference();
    return new ir.InvokeContinuation(continuation, argument);
  }

  Constant readConstant() {
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
        compiler.internalError("Unexpected constant tag: $tag");
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
        compiler.internalError("Unexpected dart string tag: $tag");
        return null;
    }
  }
}
