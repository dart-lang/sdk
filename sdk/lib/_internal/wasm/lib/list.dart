// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

const int _maxWasmArrayLength = 2147483647; // max i32

@pragma("wasm:entry-point")
abstract class _ListBase<E> extends ListBase<E> {
  @pragma("wasm:entry-point")
  int _length;
  @pragma("wasm:entry-point")
  WasmObjectArray<Object?> _data;

  _ListBase(int length, int capacity)
      : _length = length,
        _data = WasmObjectArray<Object?>(
            RangeError.checkValueInInterval(capacity, 0, _maxWasmArrayLength));

  _ListBase._withData(this._length, this._data);

  E operator [](int index) {
    IndexError.check(index, _length, indexable: this, name: "[]");
    return unsafeCast(_data.read(index));
  }

  int get length => _length;

  List<E> sublist(int start, [int? end]) {
    final int listLength = this.length;
    final int actualEnd = RangeError.checkValidRange(start, end, listLength);
    int length = actualEnd - start;
    if (length == 0) return <E>[];
    return _GrowableList<E>(length)..setRange(0, length, this, start);
  }

  void forEach(f(E element)) {
    final initialLength = length;
    for (int i = 0; i < initialLength; i++) {
      f(this[i]);
      if (length != initialLength) throw ConcurrentModificationError(this);
    }
  }

  List<E> toList({bool growable = true}) {
    return List.from(this, growable: growable);
  }
}

@pragma("wasm:entry-point")
abstract class _ModifiableList<E> extends _ListBase<E> {
  _ModifiableList(int length, int capacity) : super(length, capacity);

  _ModifiableList._withData(int length, WasmObjectArray<Object?> data)
      : super._withData(length, data);

  void operator []=(int index, E value) {
    IndexError.check(index, _length, indexable: this, name: "[]=");
    _data.write(index, value);
  }

  // List interface.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");
    if (identical(this, iterable)) {
      Lists.copy(this, skipCount, this, start, length);
    } else if (iterable is List<E>) {
      Lists.copy(iterable, skipCount, this, start, length);
    } else {
      Iterator<E> it = iterable.iterator;
      while (skipCount > 0) {
        if (!it.moveNext()) return;
        skipCount--;
      }
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) return;
        this[i] = it.current;
      }
    }
  }

  void setAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > this.length) {
      throw new RangeError.range(index, 0, this.length, "index");
    }
    List<E> iterableAsList;
    if (identical(this, iterable)) {
      iterableAsList = this;
    } else if (iterable is List<E>) {
      iterableAsList = iterable;
    } else {
      for (var value in iterable) {
        this[index++] = value;
      }
      return;
    }
    int length = iterableAsList.length;
    if (index + length > this.length) {
      throw new RangeError.range(index + length, 0, this.length);
    }
    Lists.copy(iterableAsList, 0, this, index, length);
  }
}

@pragma("wasm:entry-point")
class _List<E> extends _ModifiableList<E> with FixedLengthListMixin<E> {
  _List._(int length) : super(length, length);

  factory _List(int length) => _List._(length);

  // Specialization of List.empty constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory _List.empty() => _List<E>(0);

  // Specialization of List.filled constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory _List.filled(int length, E fill) {
    final result = _List<E>(length);
    if (fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory _List.generate(int length, E generator(int index)) {
    final result = _List<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == false.
  factory _List.of(Iterable<E> elements) {
    if (elements is _ListBase) {
      return _List._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return _List._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return _List._ofOther(elements);
  }

  factory _List._ofListBase(_ListBase<E> elements) {
    final int length = elements.length;
    final list = _List<E>(length);
    for (int i = 0; i < length; i++) {
      list[i] = elements[i];
    }
    return list;
  }

  factory _List._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = _List<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory _List._ofOther(Iterable<E> elements) {
    // The static type of `makeListFixedLength` is `List<E>`, not `_List<E>`,
    // but we know that is what it does.  `makeListFixedLength` is too generally
    // typed since it is available on the web platform which has different
    // system List types.
    return unsafeCast(makeListFixedLength(_GrowableList<E>._ofOther(elements)));
  }

  Iterator<E> get iterator {
    return new _FixedSizeListIterator<E>(this);
  }
}

@pragma("wasm:entry-point")
class _ImmutableList<E> extends _ListBase<E> with UnmodifiableListMixin<E> {
  factory _ImmutableList._uninstantiable() {
    throw new UnsupportedError(
        "_ImmutableList can only be allocated by the runtime");
  }

  Iterator<E> get iterator {
    return new _FixedSizeListIterator<E>(this);
  }
}

// Iterator for lists with fixed size.
class _FixedSizeListIterator<E> implements Iterator<E> {
  final _ListBase<E> _list;
  final int _length; // Cache list length for faster access.
  int _index;
  E? _current;

  _FixedSizeListIterator(_ListBase<E> list)
      : _list = list,
        _length = list.length,
        _index = 0 {
    assert(list is _List<E> || list is _ImmutableList<E>);
  }

  E get current => _current as E;

  bool moveNext() {
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = unsafeCast(_list._data.read(_index));
    _index++;
    return true;
  }
}
