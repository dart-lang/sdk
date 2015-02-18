part of dart.core;

abstract class List<E> implements Iterable<E>, EfficientLength {
  external factory List([int length]);
  external factory List.filled(int length, E fill);
  external factory List.from(Iterable elements, {bool growable: true});
  factory List.generate(int length, E generator(int index),
      {bool growable: true}) {
    List<E> result;
    if (growable) {
      result = <E>[]..length = length;
    } else {
      result = new List<E>(length);
    }
    for (int i = 0; i < length; i++) {
      result[i] = generator(i);
    }
    return result;
  }
  E operator [](int index);
  void operator []=(int index, E value);
  int get length;
  void set length(int newLength);
  void add(E value);
  void addAll(Iterable<E> iterable);
  Iterable<E> get reversed;
  void sort([int compare(E a, E b)]);
  void shuffle([Random random]);
  int indexOf(E element, [int start = 0]);
  int lastIndexOf(E element, [int start]);
  void clear();
  void insert(int index, E element);
  void insertAll(int index, Iterable<E> iterable);
  void setAll(int index, Iterable<E> iterable);
  bool remove(Object value);
  E removeAt(int index);
  E removeLast();
  void removeWhere(bool test(E element));
  void retainWhere(bool test(E element));
  List<E> sublist(int start, [int end]);
  Iterable<E> getRange(int start, int end);
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]);
  void removeRange(int start, int end);
  void fillRange(int start, int end, [E fillValue]);
  void replaceRange(int start, int end, Iterable<E> replacement);
  Map<int, E> asMap();
}
