// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_pickler;

import 'ir_nodes.dart';
import '../dart2jslib.dart' show
    Constant, FalseConstant, TrueConstant, IntConstant, DoubleConstant,
    StringConstant, NullConstant, ListConstant, MapConstant,
    InterceptorConstant, FunctionConstant, TypeConstant, ConstructedConstant,
    ConstantVisitor, ConstantSystem,
    Compiler;
import 'dart:typed_data' show ByteData, Endianness, Uint8List;
import 'dart:convert' show UTF8;
import '../tree/tree.dart' show
    DartString, LiteralDartString, RawSourceDartString, EscapedSourceDartString,
    ConsDartString;

part 'ir_unpickler.dart';

/* The elementCount only includes elements that might potentially be referred
 * to in back reference, for example nodes.
 *
 * pickle     ::= int(elementCount) node(function)
 *
 * int        ::= see [writeInt] for number encoding
 *
 * string     ::= byte(STRING_ASCII) int(length) {byte(ascii)}
 *              | byte(STRING_UTF8) int(length) {byte(utf8)}
 *
 * node       ::= byte(BACK_REFERENCE) int(index)
 *              | byte(NODE_FUNCTION) position int(endSourceOffset)
 *                    int(namePosition) int(statements) {node(statement)}
 *              | byte(NODE_RETURN) position node(value)
 *              | byte(NODE_CONST) position constant
 *
 * position   ::= byte(POSITION_WITH_ID) string(sourceName) int(sourceOffset)
 *              | byte(POSITION_OFFSET) int(sourceOffset)
 *
 * constant   ::= byte(CONST_BOOL) byte(0 or 1)
 *              | byte(CONST_DOUBLE) byte{8}
 *              | byte(CONST_INT) int(value)
 *              | byte(CONST_STRING_LITERAL) string
 *              | byte(CONST_STRING_RAW) string int(length)
 *              | byte(CONST_STRING_ESCAPED) string int(length)
 *              | byte(CONST_STRING_CONS) constant(left) constant(right)
 *              | byte(CONST_NULL)
 */
class Pickles {
  static const int BACK_REFERENCE = 1;

  static const int STRING_ASCII = BACK_REFERENCE + 1;
  static const int STRING_UTF8  = STRING_ASCII + 1;

  static const int BEGIN_NODE    = STRING_UTF8 + 1;
  static const int NODE_FUNCTION = BEGIN_NODE;
  static const int NODE_RETURN   = NODE_FUNCTION + 1;
  static const int NODE_CONST    = NODE_RETURN + 1;
  static const int END_NODE      = NODE_CONST;

  static const int BEGIN_POSITION   = END_NODE + 1;
  static const int POSITION_OFFSET  = BEGIN_POSITION;
  static const int POSITION_WITH_ID = POSITION_OFFSET + 1;
  static const int END_POSITION     = POSITION_WITH_ID;

  static const int BEGIN_CONST          = END_POSITION + 1;
  static const int CONST_BOOL           = BEGIN_CONST;
  static const int CONST_INT            = CONST_BOOL + 1;
  static const int CONST_DOUBLE         = CONST_INT + 1;
  static const int CONST_STRING_LITERAL = CONST_DOUBLE + 1;
  static const int CONST_STRING_RAW     = CONST_STRING_LITERAL + 1;
  static const int CONST_STRING_ESCAPED = CONST_STRING_RAW + 1;
  static const int CONST_STRING_CONS    = CONST_STRING_ESCAPED + 1;
  static const int CONST_NULL           = CONST_STRING_CONS + 1;
  static const int END_CONST            = CONST_NULL;

  static const int END_TAG = END_CONST;
}

/**
 * The [Pickler] serializes [IrNode]s to a byte array.
 */
class Pickler extends IrNodesVisitor {
  ConstantPickler constantPickler;

  Pickler() {
    assert(Pickles.END_TAG <= 0xff);
    constantPickler = new ConstantPickler(this);
  }

  static final int INITIAL_SIZE = 8;
  static final int MAX_GROW_RATE = 4096;

  List<int> data;

  /** Offset of the next byte that will be written. */
  int offset;

  /** Stores the intex for emitted elements that might be back-referenced. */
  Map<Object, int> emitted;

  /** A counter for emitted elements. */
  int index;

  /**
   * This buffer is used in [writeConstDouble] to obtain a byte representation
   * for doubles.
   */
  ByteData doubleData = new ByteData(8);

  List<int> pickle(IrNode node) {
    data = new Uint8List(INITIAL_SIZE);
    offset = 0;
    emitted = <Object, int>{};
    index = 0;
    node.accept(this);

    int sizeOffset = offset;
    writeInt(emitted.length);
    int sizeBytes = offset - sizeOffset;

    // The array is longer than necessary, create a copy with the actual size.
    Uint8List result = new Uint8List(offset);
    // Emit the number or elements in the beginning.
    for (int i = 0, j = sizeOffset; i < sizeBytes; i++, j++) {
      result[i] = data[j];
    }
    for (int i = sizeBytes, j = 0; i < offset; i++, j++) {
      result[i] = data[j];
    }
    return result;
  }

  void resize(int newSize) {
    Uint8List newData = new Uint8List(newSize);
    for (int i = 0; i < data.length; i++) {
      newData[i] = data[i];
    }
    data = newData;
  }

  void ensureCapacity() {
    // (offset == data.length-1) is still OK, the byte at [offset] has not yet
    // been written.
    int size = data.length;
    if (offset < size) return;
    if (size > MAX_GROW_RATE) {
      size += MAX_GROW_RATE;
    } else {
      size *= 2;
    }
    resize(size);
  }

  static isByte(int byte) => 0 <= byte && byte <= 0xff;

  void writeByte(int byte) {
    assert(isByte(byte));
    ensureCapacity();
    data[offset++] = byte;
  }

  /**
   * Writes integers to the buffer.
   *
   * The least significant bit of the serialized data encodes the sign. Each
   * byte contains 7 bits of data and one bit indicating if it is the last byte
   * of the number.
   */
  void writeInt(int n) {
    bool isNegative = n < 0;
    n = isNegative ? -n : n;
    // Least significant bit is the sign.
    int bits = (n << 1) | (isNegative ? 1 : 0);
    do {
      int next = bits & 0x7f;
      bits >>= 7;
      bool hasMore = bits != 0;
      next = (next << 1) | (hasMore ? 1 : 0);
      writeByte(next);
    } while (bits != 0);
  }

  void writeString(String s) {
    int startOffset = offset;
    writeByte(Pickles.STRING_ASCII);
    writeInt(s.length);
    for (int i = 0; i < s.length; i++) {
      int c = s.codeUnitAt(i);
      if (c < 0x80) {
        writeByte(c);
      } else {
        // Strings with non-ascii characters are encoded using UTF-8.
        writeUtf8String(s, startOffset);
        return;
      }
    }
  }

  void writeUtf8String(String s, int startOffset) {
    offset = startOffset;
    writeByte(Pickles.STRING_UTF8);
    List<int> bytes = UTF8.encode(s);
    writeInt(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      writeByte(bytes[i]);
    }
  }

  /**
   * If [element] has already been emitted, this function writes a back
   * reference to the buffer and returns [:true:]. Otherwise, it registers the
   * element in the [emitted] map and the [:false:].
   */
  bool writeBackrefIfEmitted(Object element) {
    int elementIndex = emitted[element];
    if (elementIndex != null) {
      writeByte(Pickles.BACK_REFERENCE);
      writeInt(elementIndex);
      return true;
    } else {
      emitted[element] = index++;
      return false;
    }
  }

  void writePosition(/* int | PositionWithIdentifierName */ position) {
    if (position is int) {
      writeByte(Pickles.POSITION_OFFSET);
      writeInt(position);
    } else {
      PositionWithIdentifierName namedPosition = position;
      writeByte(Pickles.POSITION_WITH_ID);
      writeString(namedPosition.sourceName);
      writeInt(namedPosition.offset);
    }
  }

  void writeConstBool(bool b) {
    writeByte(Pickles.CONST_BOOL);
    writeByte(b ? 1 : 0);
  }

  void writeConstInt(int n) {
    writeByte(Pickles.CONST_INT);
    writeInt(n);
  }

  void writeConstDouble(double d) {
    writeByte(Pickles.CONST_DOUBLE);
    doubleData.setFloat64(0, d, Endianness.BIG_ENDIAN);
    for (int i = 0; i < 8; i++) {
      writeByte(doubleData.getUint8(i));
    }
  }

  void writeDartString(DartString s) {
    if (s is LiteralDartString) {
      writeByte(Pickles.CONST_STRING_LITERAL);
      writeString(s.string);
    } else if (s is RawSourceDartString) {
      writeByte(Pickles.CONST_STRING_RAW);
      writeString(s.source);
      writeInt(s.length);
    } else if (s is EscapedSourceDartString) {
      writeByte(Pickles.CONST_STRING_ESCAPED);
      writeString(s.source);
      writeInt(s.length);
    } else if (s is ConsDartString) {
      writeByte(Pickles.CONST_STRING_CONS);
      writeDartString(s.left);
      writeDartString(s.right);
    } else {
      throw "Unexpected DartString: $s";
    }
  }

  void writeConstNull() {
    writeByte(Pickles.CONST_NULL);
  }

  void visitIrFunction(IrFunction node) {
    if (writeBackrefIfEmitted(node)) return;
    writeByte(Pickles.NODE_FUNCTION);
    writePosition(node.position);
    writeInt(node.endOffset);
    writeInt(node.namePosition);
    writeInt(node.statements.length);
    for (int i = 0; i < node.statements.length; i++) {
      node.statements[i].accept(this);
    }
  }

  void visitIrReturn(IrReturn node) {
    if (writeBackrefIfEmitted(node)) return;
    writeByte(Pickles.NODE_RETURN);
    writePosition(node.position);
    node.value.accept(this);
  }

  void visitIrConstant(IrConstant node) {
    if (writeBackrefIfEmitted(node)) return;
    writeByte(Pickles.NODE_CONST);
    writePosition(node.position);
    node.value.accept(constantPickler);
  }

  void visitNode(IrNode node) {
    throw "Unexpected $node in pickler.";
  }
}

/**
 * A visitor for constants which writes the constant values to its [Pickler].
 */
class ConstantPickler extends ConstantVisitor {

  final Pickler pickler;
  ConstantPickler(this.pickler);

  void visitFalse(FalseConstant constant) {
    pickler.writeConstBool(false);
  }

  void visitTrue(TrueConstant constant) {
    pickler.writeConstBool(true);
  }

  void visitInt(IntConstant constant) {
    pickler.writeConstInt(constant.value);
  }

  void visitDouble(DoubleConstant constant) {
    pickler.writeConstDouble(constant.value);
  }

  void visitString(StringConstant constant) {
    pickler.writeDartString(constant.value);
  }

  void visitNull(NullConstant constant) {
    pickler.writeConstNull();
  }

  void visitList(ListConstant constant) => abort(constant);
  void visitMap(MapConstant constant) => abort(constant);
  void visitInterceptor(InterceptorConstant constant) => abort(constant);
  void visitFunction(FunctionConstant constant) => abort(constant);
  void visitType(TypeConstant constant) => abort(constant);
  void visitConstructed(ConstructedConstant constant) => abort(constant);

  void abort(Constant value) => throw "Can not pickle constant $value";
}
