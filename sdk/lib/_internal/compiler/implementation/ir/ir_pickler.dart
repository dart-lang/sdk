// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_pickler;

import 'ir_nodes.dart';
import '../dart2jslib.dart' show
    Constant, FalseConstant, TrueConstant, IntConstant, DoubleConstant,
    StringConstant, NullConstant, ListConstant, MapConstant,
    InterceptorConstant, DummyReceiverConstant, FunctionConstant, TypeConstant,
    ConstructedConstant,
    ConstantVisitor, ConstantSystem,
    Compiler;
import 'dart:typed_data' show ByteData, Endianness, Uint8List;
import 'dart:convert' show UTF8;
import '../tree/tree.dart' show
    DartString, LiteralDartString, RawSourceDartString, EscapedSourceDartString,
    ConsDartString;
import '../elements/elements.dart' show
    Element, LibraryElement, FunctionElement;
import '../universe/universe.dart' show Selector, TypedSelector, SelectorKind;

part 'ir_unpickler.dart';

/* The int(entries) counts expression nodes, which might potentially be
 * referred to in a back reference.
 *
 * pickle     ::= int(entries) node(function)
 *
 * int        ::= see [writeInt] for number encoding
 *
 * string     ::= byte(STRING_ASCII) int(length) {byte(ascii)}
 *              | byte(STRING_UTF8) int(length) {byte(utf8)}
 *
 * node       ::= byte(NODE_FUNCTION) position int(endSourceOffset)
 *                    int(namePosition) int(statements) {node(statement)}
 *              | byte(NODE_RETURN) position reference(value)
 *              | byte(NODE_CONST) position constant
 *              | byte(NODE_INVOKE_STATIC) position element selector
 *                    int(arguments) {reference(argument)}
 *
 * reference  ::= int(indexDelta)
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
 *
 * selector   ::= byte(BACKREFERENCE) reference
 *              | byte(SELECTOR_UNTYPED) int(kind) string(name) element(library)
 *                    int(argumentsCount) int(namedArgumentsCount)
 *                    {string(parameterName)}
 *
 * element    ::= int(constantPoolIndex)
 */
class Pickles {
  static const int BACKREFERENCE = 1;

  static const int STRING_ASCII = BACKREFERENCE + 1;
  static const int STRING_UTF8  = STRING_ASCII + 1;

  static const int BEGIN_STATEMENT_NODE = STRING_UTF8 + 1;
  static const int NODE_RETURN          = BEGIN_STATEMENT_NODE;
  static const int END_STATEMENT_NODE   = NODE_RETURN;

  static const int BEGIN_EXPRESSION_NODE = END_STATEMENT_NODE + 1;
  static const int NODE_FUNCTION         = BEGIN_EXPRESSION_NODE;
  static const int NODE_CONST            = NODE_FUNCTION + 1;
  static const int NODE_INVOKE_STATIC    = NODE_CONST + 1;
  static const int END_EXPRESSION_NODE   = NODE_INVOKE_STATIC;

  static const int BEGIN_POSITION   = END_EXPRESSION_NODE + 1;
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

  static const int BEGIN_SELECTOR   = END_CONST + 1;
  static const int SELECTOR_UNTYPED = BEGIN_SELECTOR;
  static const int END_SELECTOR     = SELECTOR_UNTYPED + 1;

  static const int END_TAG = END_SELECTOR;

  static bool isExpressionTag(int tag) {
    return BEGIN_EXPRESSION_NODE <= tag && tag <= END_EXPRESSION_NODE;
  }

  static final List<SelectorKind> selectorKindFromId = _selectorKindFromId();

  static List<SelectorKind> _selectorKindFromId() {
    List<SelectorKind> result = <SelectorKind>[
        SelectorKind.GETTER,
        SelectorKind.SETTER,
        SelectorKind.CALL,
        SelectorKind.OPERATOR,
        SelectorKind.INDEX];
    for (int i = 0; i < result.length; i++) {
      assert(result[i].hashCode == i);
    }
    return result;
  }

}

class IrConstantPool {
  static Map<LibraryElement, IrConstantPool> _constantPools =
      <LibraryElement, IrConstantPool>{};

  static IrConstantPool forLibrary(LibraryElement library) {
    return _constantPools.putIfAbsent(library, () => new IrConstantPool());
  }

  /**
   * The entries of the constant pool. Method [add] ensures that an object
   * is only added once to this list.
   */
  List<Object> entries = <Object>[];

  /**
   * This map is the inverse of [entries], it stores the index of each object.
   */
  Map<Object, int> entryIndex = <Object, int>{};

  int add(Object o) {
    return entryIndex.putIfAbsent(o, () {
      entries.add(o);
      return entries.length - 1;
    });
  }

  Object get(int index) => entries[index];
}

/**
 * The [Pickler] serializes [IrNode]s to a byte array.
 */
class Pickler extends IrNodesVisitor {
  ConstantPickler constantPickler;

  IrConstantPool constantPool;

  Pickler(this.constantPool) {
    assert(Pickles.END_TAG <= 0xff);
    constantPickler = new ConstantPickler(this);
  }

  static final int INITIAL_SIZE = 8;
  static final int MAX_GROW_RATE = 4096;

  List<int> data;

  /** Offset of the next byte that will be written. */
  int offset;

  /** Stores the index for emitted entries that might be back-referenced. */
  Map<Object, int> emitted;

  /** A counter for entries in the [emitted] map. */
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
    // Emit the number or entries in the beginning.
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
   * This function records [entry] in the [emitted] table. It needs to be
   * invoked when pickling an object which might later on be used in a back
   * reference, for example expression nodes or selectors.
   */
  void recordForBackReference(Object entry) {
    assert(emitted[entry] == null);
    emitted[entry] = index++;
  }

  void writeBackReference(Object entry) {
    int entryIndex = emitted[entry];
    writeInt(index - entryIndex);
  }

  void writeBackReferenceList(List entries) {
    writeInt(entries.length);
    for (int i = 0; i < entries.length; i++) {
      writeBackReference(entries[i]);
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

  void writeElement(Element element) {
    writeInt(constantPool.add(element));
  }

  void writeSelector(Selector selector) {
    if (emitted.containsKey(selector)) {
      writeByte(Pickles.BACKREFERENCE);
      writeBackReference(selector);
    } else {
      recordForBackReference(selector);
      assert(selector is !TypedSelector);
      writeByte(Pickles.SELECTOR_UNTYPED);
      writeInt(selector.kind.hashCode);
      writeString(selector.name);
      writeElement(selector.library);
      writeInt(selector.argumentCount);
      int namedArgumentsCount = selector.namedArguments.length;
      writeInt(namedArgumentsCount);
      for (int i = 0; i < namedArgumentsCount; i++) {
        writeString(selector.namedArguments[i]);
      }
    }
  }

  void writeNodeList(List<IrNode> nodes) {
    writeInt(nodes.length);
    for (int i = 0; i < nodes.length; i++) {
      nodes[i].accept(this);
    }
  }

  void visitIrFunction(IrFunction node) {
    recordForBackReference(node);
    writeByte(Pickles.NODE_FUNCTION);
    writePosition(node.position);
    writeInt(node.endOffset);
    writeInt(node.namePosition);
    writeNodeList(node.statements);
  }

  void visitIrReturn(IrReturn node) {
    writeByte(Pickles.NODE_RETURN);
    writePosition(node.position);
    writeBackReference(node.value);
  }

  void visitIrConstant(IrConstant node) {
    recordForBackReference(node);
    writeByte(Pickles.NODE_CONST);
    writePosition(node.position);
    node.value.accept(constantPickler);
  }

  void visitIrInvokeStatic(IrInvokeStatic node) {
    recordForBackReference(node);
    writeByte(Pickles.NODE_INVOKE_STATIC);
    writePosition(node.position);
    writeElement(node.target);
    writeSelector(node.selector);
    // TODO(lry): compact encoding when the arity of the selector and the
    // arguments list are the same
    writeBackReferenceList(node.arguments);
  }

  void visitIrNode(IrNode node) {
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
  void visitDummyReceiver(DummyReceiverConstant constant) => abort(constant);
  void visitFunction(FunctionConstant constant) => abort(constant);
  void visitType(TypeConstant constant) => abort(constant);
  void visitConstructed(ConstructedConstant constant) => abort(constant);

  void abort(Constant value) => throw "Can not pickle constant $value";
}
