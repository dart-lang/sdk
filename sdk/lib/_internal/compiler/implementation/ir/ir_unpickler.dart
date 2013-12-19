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

  IrFunction unpickle(List<int> data) {
    this.data = data;
    offset = 0;
    int numEntries = readInt();
    unpickled = new List<Object>(numEntries);
    index = 0;
    return readNode();
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

  /**
   * Reads a [IrNode]. Expression nodes are added to the [unpickled] map to
   * enable unpickling back references.
   */
  IrNode readNode() {
    int tag = readByte();
    if (Pickles.isExpressionTag(tag)) {
      return readExpressionNode(tag);
    } else if (tag == Pickles.NODE_RETURN) {
      return readReturnNode();
    } else {
      compiler.internalError("Unexpected entry tag: $tag");
    }
  }

  IrExpression readExpressionNode(int tag) {
    int entryIndex = index++;
    IrExpression result;
    if (tag == Pickles.NODE_CONST) {
      result = readConstantNode();
    } else if (tag == Pickles.NODE_FUNCTION) {
      result = readFunctionNode();
    } else if (tag == Pickles.NODE_INVOKE_STATIC) {
      result = readInvokeStaticNode();
    } else {
      compiler.internalError("Unexpected expression entry tag: $tag");
    }
    return unpickled[entryIndex] = result;
  }

  Object readBackReference() {
    int indexDelta = readInt();
    int entryIndex = index - indexDelta;
    assert(unpickled[entryIndex] != null);
    return unpickled[entryIndex];
  }

  List<IrExpression> readExpressionBackReferenceList() {
    int length = readInt();
    List<IrExpression> result = new List<IrExpression>(length);
    for (int i = 0; i < length; i++) {
      result[i] = readBackReference();
    }
    return result;
  }

  List<IrNode> readNodeList() {
    int length = readInt();
    List<IrNode> nodes = new List<IrNode>(length);
    for (int i = 0; i < length; i++) {
      nodes[i] = readNode();
    }
    return nodes;
  }

  IrFunction readFunctionNode() {
    var position = readPosition();
    int endOffset = readInt();
    int namePosition = readInt();
    List<IrNode> statements = readNodeList();
    return new IrFunction(position, endOffset, namePosition, statements);
  }

  IrConstant readConstantNode() {
    var position = readPosition();
    Constant constant = readConstant();
    return new IrConstant(position, constant);
  }

  IrReturn readReturnNode() {
    var position = readPosition();
    IrExpression value = readBackReference();
    return new IrReturn(position, value);
  }

  IrInvokeStatic readInvokeStaticNode() {
    var position = readPosition();
    FunctionElement functionElement = readElement();
    Selector selector = readSelector();
    List<IrExpression> arguments = readExpressionBackReferenceList();
    return new IrInvokeStatic(position, functionElement, selector, arguments);
  }

  /* int | PositionWithIdentifierName */ readPosition() {
    if (readByte() == Pickles.POSITION_OFFSET) {
      return readInt();
    } else {
      String sourceName = readString();
      int offset = readInt();
      return new PositionWithIdentifierName(offset, sourceName);
    }
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
    }
  }

  DartString readDartString(int tag) {
    switch(tag) {
      case Pickles.CONST_STRING_LITERAL:
        return new LiteralDartString(readString());
      case Pickles.CONST_STRING_RAW:
        return new RawSourceDartString(readString(), readInt());
      case Pickles.CONST_STRING_ESCAPED:
        return new EscapedSourceDartString(readString(), readInt());
      case Pickles.CONST_STRING_CONS:
        return new ConsDartString(
            readDartString(readByte()), readDartString(readByte()));
      default:
        compiler.internalError("Unexpected dart string tag: $tag");
    }
  }
}
