part of dart.core;

abstract class List<E> implements Iterable<E>, EfficientLength {
  factory List([int length = const _ListConstructorSentinel()]) {
    if (length == const _ListConstructorSentinel()) {
      return ((__x26) => DDC$RT.cast(__x26, dynamic,
          DDC$RT.type((List<E> _) {}), "CastExact",
          """line 79, column 14 of dart:core/list.dart: """, __x26 is List<E>,
          false))(new JSArray<E>.emptyGrowable());
    }
    return ((__x27) => DDC$RT.cast(__x27, dynamic, DDC$RT.type((List<E> _) {}),
        "CastExact", """line 81, column 12 of dart:core/list.dart: """,
        __x27 is List<E>, false))(new JSArray<E>.fixed(length));
  }
  factory List.filled(int length, E fill) {
    List result = ((__x28) => DDC$RT.cast(__x28, dynamic,
        DDC$RT.type((List<dynamic> _) {}), "CastExact",
        """line 93, column 19 of dart:core/list.dart: """,
        __x28 is List<dynamic>, true))(new JSArray<E>.fixed(length));
    if (length != 0 && fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return DDC$RT.cast(result, DDC$RT.type((List<dynamic> _) {}),
        DDC$RT.type((List<E> _) {}), "CastDynamic",
        """line 99, column 12 of dart:core/list.dart: """, result is List<E>,
        false);
  }
  factory List.from(Iterable elements, {bool growable: true}) {
    List<E> list = new List<E>();
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return ((__x29) => DDC$RT.cast(__x29, DDC$RT.type((List<dynamic> _) {}),
        DDC$RT.type((List<E> _) {}), "CastDynamic",
        """line 116, column 12 of dart:core/list.dart: """, __x29 is List<E>,
        false))(makeListFixedLength(list));
  }
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
