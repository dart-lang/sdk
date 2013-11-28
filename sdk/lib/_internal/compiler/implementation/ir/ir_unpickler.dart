// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.ir_pickler;

class Unpickler {
  final Compiler compiler;

  Unpickler(this.compiler);

  List<int> data;

  int offset;

  /** For each element index, the corresponding unpickled element. */
  List<Object> unpickled;

  /** Counter for elements in [unpickled]. */
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
    int numElements = readInt();
    unpickled = new List<Object>(numElements);
    index = 0;
    return readElement();
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

  /**
   * Read an element that might be a back reference, or that might be used
   * in a back reference.
   */
  Object readElement() {
    // Obtain the index of the element before reading its content to ensure
    // that elements are placed in consecutive order in [unpickled].
    int elementIndex = index++;
    int tag = readByte();
    if (tag == Pickles.BACK_REFERENCE) {
      int backIndex = readInt();
      assert(unpickled[backIndex] != null);
      return unpickled[backIndex];
    }
    Object result;
    if (tag == Pickles.NODE_CONST) {
      result = readConstantNode();
    } else if (tag == Pickles.NODE_FUNCTION) {
      result = readFunctionNode();
    } else if (tag == Pickles.NODE_RETURN) {
      result = readReturnNode();
    } else {
      compiler.internalError("Unexpected element tag: $tag");
    }
    unpickled[elementIndex] = result;
    return result;
  }

  IrFunction readFunctionNode() {
    var position = readPosition();
    int endOffset = readInt();
    int namePosition = readInt();
    int numStatements = readInt();
    List<IrNode> statements = new List<IrNode>(numStatements);
    for (int i = 0; i < numStatements; i++) {
      statements[i] = readElement();
    }
    return new IrFunction(position, endOffset, namePosition, statements);
  }

  IrConstant readConstantNode() {
    var position = readPosition();
    Constant constant = readConstant();
    return new IrConstant(position, constant);
  }

  IrReturn readReturnNode() {
    var position = readPosition();
    IrNode value = readElement();
    return new IrReturn(position, value);
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
