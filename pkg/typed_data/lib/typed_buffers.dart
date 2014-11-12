// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Growable typed-data lists.
 *
 * These lists works just as a typed-data list, except that they are growable.
 * They use an underlying buffer, and when that buffer becomes too small, it
 * is replaced by a new buffer.
 *
 * That means that using the [TypedDataView.buffer] getter is not guaranteed
 * to return the same result each time it is used, and that the buffer may
 * be larger than what the list is using.
 */
library dart.pkg.typed_data.typed_buffers;

import "dart:collection" show ListBase;
import "dart:typed_data";

abstract class _TypedDataBuffer<E> extends ListBase<E> {
  static const int INITIAL_LENGTH = 8;

  /// This is a Uint8List for Uint8Buffer. It's both a List<E> and a TypedData,
  /// which we don't have a type for here.
  var _buffer;
  /// The length of the list being built.
  int _length;

  _TypedDataBuffer(List<E> buffer)
      : this._buffer = buffer, this._length = buffer.length;

  int get length => _length;
  E operator[](int index) {
    if (index >= length) throw new RangeError.index(index, this);
    return _buffer[index];
  }

  void operator[]=(int index, E value) {
    if (index >= length) throw new RangeError.index(index, this);
    _buffer[index] = value;
  }

  void set length(int newLength) {
    if (newLength < _length) {
      E defaultValue = _defaultValue;
      for (int i = newLength; i < _length; i++) {
        _buffer[i] = defaultValue;
      }
    } else if (newLength > _buffer.length) {
      List<E> newBuffer;
      if (_buffer.length == 0) {
        newBuffer = _createBuffer(newLength);
      } else {
        newBuffer = _createBiggerBuffer(newLength);
      }
      newBuffer.setRange(0, _length, _buffer);
      _buffer = newBuffer;
    }
    _length = newLength;
  }

  void _add(E value) {
    if (_length == _buffer.length) _grow();
    _buffer[_length++] = value;
  }

  // We override the default implementation of `add` and `addAll` because
  // they grow by setting the length in increments of one. We want to grow
  // by doubling capacity in most cases.
  void add(E value) { _add(value); }

  void addAll(Iterable<E> values) {
    for (E value in values) _add(value);
  }

  void insert(int index, E element) {
    if (index < 0 || index > _length) {
      throw new RangeError.range(index, 0, _length);
    }
    if (_length < _buffer.length) {
      _buffer.setRange(index + 1, _length + 1, _buffer, index);
      _buffer[index] = element;
      _length++;
      return;
    }
    List<E> newBuffer = _createBiggerBuffer(null);
    newBuffer.setRange(0, index, _buffer);
    newBuffer.setRange(index + 1, _length + 1, _buffer, index);
    newBuffer[index] = element;
    _length++;
    _buffer = newBuffer;
  }

  /**
   * Create a bigger buffer.
   *
   * This method determines how much bigger a bigger buffer should
   * be. If [requiredLength] is not null, it will be at least that
   * size. It will always have at least have double the capacity of
   * the current buffer.
   */
  List<E> _createBiggerBuffer(int requiredLength) {
    int newLength = _buffer.length * 2;
    if (requiredLength != null && newLength < requiredLength) {
      newLength = requiredLength;
    } else if (newLength < INITIAL_LENGTH) {
      newLength = INITIAL_LENGTH;
    }
    return _createBuffer(newLength);
  }

  void _grow() {
    _buffer = _createBiggerBuffer(null)..setRange(0, _length, _buffer);
  }

  void setRange(int start, int end, Iterable<E> source, [int skipCount = 0]) {
    if (end > _length) throw new RangeError.range(end, 0, _length);
    if (source is _TypedDataBuffer<E>) {
      _buffer.setRange(start, end, source._buffer, skipCount);
    } else {
      _buffer.setRange(start, end, source, skipCount);
    }
  }

  // TypedData.

  int get elementSizeInBytes => _buffer.elementSizeInBytes;

  int get lengthInBytes => _length * _buffer.elementSizeInBytes;

  int get offsetInBytes => _buffer.offsetInBytes;

  /**
    * Returns the underlying [ByteBuffer].
    *
    * The returned buffer may be replaced by operations that change the [length]
    * of this list.
    *
    * The buffer may be larger than [lengthInBytes] bytes, but never smaller.
    */
  ByteBuffer get buffer => _buffer.buffer;

  // Specialization for the specific type.

  // Return zero for integers, 0.0 for floats, etc.
  // Used to fill buffer when changing length.
  E get _defaultValue;

  // Create a new typed list to use as buffer.
  List<E> _createBuffer(int size);
}

abstract class _IntBuffer extends _TypedDataBuffer<int> {
  _IntBuffer(buffer): super(buffer);
  int get _defaultValue => 0;
}

abstract class _FloatBuffer extends _TypedDataBuffer<double> {
  _FloatBuffer(buffer): super(buffer);
  double get _defaultValue => 0.0;
}

class Uint8Buffer extends _IntBuffer {
  Uint8Buffer([int initialLength = 0]) : super(new Uint8List(initialLength));
  Uint8List _createBuffer(int size) => new Uint8List(size);
}

class Int8Buffer extends _IntBuffer {
  Int8Buffer([int initialLength = 0]) : super(new Int8List(initialLength));
  Int8List _createBuffer(int size) => new Int8List(size);
}

class Uint8ClampedBuffer extends _IntBuffer {
  Uint8ClampedBuffer([int initialLength = 0])
      : super(new Uint8ClampedList(initialLength));
  Uint8ClampedList _createBuffer(int size) => new Uint8ClampedList(size);
}

class Uint16Buffer extends _IntBuffer {
  Uint16Buffer([int initialLength = 0]) : super(new Uint16List(initialLength));
  Uint16List _createBuffer(int size) => new Uint16List(size);
}

class Int16Buffer extends _IntBuffer {
  Int16Buffer([int initialLength = 0]) : super(new Int16List(initialLength));
  Int16List _createBuffer(int size) => new Int16List(size);
}

class Uint32Buffer extends _IntBuffer {
  Uint32Buffer([int initialLength = 0]) : super(new Uint32List(initialLength));
  Uint32List _createBuffer(int size) => new Uint32List(size);
}

class Int32Buffer extends _IntBuffer {
  Int32Buffer([int initialLength = 0]) : super(new Int32List(initialLength));
  Int32List _createBuffer(int size) => new Int32List(size);
}

class Uint64Buffer extends _IntBuffer {
  Uint64Buffer([int initialLength = 0]) : super(new Uint64List(initialLength));
  Uint64List _createBuffer(int size) => new Uint64List(size);
}

class Int64Buffer extends _IntBuffer {
  Int64Buffer([int initialLength = 0]) : super(new Int64List(initialLength));
  Int64List _createBuffer(int size) => new Int64List(size);
}

class Float32Buffer extends _FloatBuffer {
  Float32Buffer([int initialLength = 0])
      : super(new Float32List(initialLength));
  Float32List _createBuffer(int size) => new Float32List(size);
}

class Float64Buffer extends _FloatBuffer {
  Float64Buffer([int initialLength = 0])
      : super(new Float64List(initialLength));
  Float64List _createBuffer(int size) => new Float64List(size);
}

class Int32x4Buffer extends _TypedDataBuffer<Int32x4> {
  static Int32x4 _zero = new Int32x4(0, 0, 0, 0);
  Int32x4Buffer([int initialLength = 0])
      : super(new Int32x4List(initialLength));
  Int32x4 get _defaultValue => _zero;
  Int32x4List _createBuffer(int size) => new Int32x4List(size);
}

class Float32x4Buffer extends _TypedDataBuffer<Float32x4> {
  Float32x4Buffer([int initialLength = 0])
      : super(new Float32x4List(initialLength));
  Float32x4 get _defaultValue => new Float32x4.zero();
  Float32x4List _createBuffer(int size) => new Float32x4List(size);
}
