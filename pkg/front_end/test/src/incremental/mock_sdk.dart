// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/base/libraries_specification.dart';

final _ASYNC = r'''
library dart.async;

class Future<T> {
  factory Future(computation()) => null;
  factory Future.delayed(Duration duration, [T computation()]) => null;
  factory Future.microtask(FutureOr<T> computation()) => null;
  factory Future.value([value]) => null;

  static Future<List<T>> wait<T>(Iterable<Future<T>> futures) => null;
  Future<R> then<R>(FutureOr<R> onValue(T value)) => null;

  Future<T> whenComplete(action());
}


class FutureOr<T> {}
class Stream<T> {}
abstract class StreamIterator<T> {}

abstract class Completer<T> {
  factory Completer() => null;
  factory Completer.sync() => null;
  Future<T> get future;
  void complete([FutureOr<T> value]);
  void completeError(Object error, [StackTrace stackTrace]);
  bool get isCompleted;
}

class _StreamIterator<T> implements StreamIterator<T> {
  T get current;
  Future<bool> moveNext();
  Future cancel();
}

class _AsyncStarStreamController<T> {
  Stream<T> get stream;
  bool add(T event);
  bool addStream(Stream<T> stream);
  void addError(Object error, StackTrace stackTrace);
  close();
}

Object _asyncStackTraceHelper(Function async_op) { }
Function _asyncThenWrapperHelper(continuation) {}
Function _asyncErrorWrapperHelper(continuation) {}
Future _awaitHelper(
    object, Function thenCallback, Function errorCallback, var awaiter) {}
''';

final _CORE = r'''
library dart.core;
import 'dart:_internal';
import 'dart:async';

class Object {
  const Object();
  bool operator ==(other) => identical(this, other);
  String toString() => 'a string';
  int get hashCode => 0;
  Type get runtimeType => null;
  dynamic noSuchMethod(Invocation invocation) => null;
}

class Null {}

class Symbol {
  const factory Symbol(String name) {
    return null;
  }
}

class Type {}

abstract class Comparable<T> {
  int compareTo(T other);
}

abstract class Pattern {}

abstract class String implements Comparable<String>, Pattern {
  external factory String.fromCharCodes(Iterable<int> charCodes,
                                        [int start = 0, int end]);
  String operator +(String other) => null;
  bool get isEmpty => false;
  bool get isNotEmpty => false;
  int get length => 0;
  String substring(int len) => null;
  String toLowerCase();
  String toUpperCase();
  List<int> get codeUnits;
}

abstract class RegExp implements Pattern {
  external factory RegExp(String source);
}

class Function {}
class Invocation {}
class StackTrace {}

class bool extends Object {
  external const factory bool.fromEnvironment(String name,
                                              {bool defaultValue: false});
}

abstract class num implements Comparable<num> {
  bool operator ==(Object other);
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator /(num other);
  int operator ^(int other);
  int operator |(int other);
  int operator <<(int other);
  int operator >>(int other);
  int operator ~/(num other);
  num operator %(num other);
  int operator ~();
  num operator -();
  int toInt();
  double toDouble();
  num abs();
  int round();
}

abstract class int extends num {
  external const factory int.fromEnvironment(String name, {int defaultValue});

  bool get isNegative;
  bool get isEven => false;

  int operator &(int other);
  int operator |(int other);
  int operator ^(int other);
  int operator ~();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);

  int operator -();

  external static int parse(String source,
                            { int radix,
                              int onError(String source) });
}

abstract class double extends num {
  static const double NAN = 0.0 / 0.0;
  static const double INFINITY = 1.0 / 0.0;
  static const double NEGATIVE_INFINITY = -INFINITY;
  static const double MIN_POSITIVE = 5e-324;
  static const double MAX_FINITE = 1.7976931348623157e+308;

  double remainder(num other);
  double operator +(num other);
  double operator -(num other);
  double operator *(num other);
  double operator %(num other);
  double operator /(num other);
  int operator ~/(num other);
  double operator -();
  double abs();
  double get sign;
  int round();
  int floor();
  int ceil();
  int truncate();
  double roundToDouble();
  double floorToDouble();
  double ceilToDouble();
  double truncateToDouble();
  external static double parse(String source,
                               [double onError(String source)]);
}

class Iterator<E> {
  bool moveNext();
  E get current;
}

abstract class Iterable<E> {
  Iterator<E> get iterator;
  bool get isEmpty;
  E get first;

  Iterable<R> map<R>(R f(E e));

  R fold<R>(R initialValue, R combine(R previousValue, E element));

  Iterable<T> expand<T>(Iterable<T> f(E element));

  Iterable<E> where(bool test(E element));

  void forEach(void f(E element));

  List<E> toList();
}

class List<E> implements Iterable<E> {
  List();
  factory List.from(Iterable elements, {bool growable: true}) => null;
  void add(E value) {}
  void addAll(Iterable<E> iterable) {}
  E operator [](int index) => null;
  void operator []=(int index, E value) {}
  Iterator<E> get iterator => null;
  void clear() {}

  bool get isEmpty => false;
  E get first => null;
  E get last => null;

  R fold<R>(R initialValue, R combine(R previousValue, E element)) => null;
}

class Map<K, V> extends Object {
  V operator [](K key) => null;
  void operator []=(K key, V value) {}
  Iterable<K> get keys => null;
  int get length;
  Iterable<V> get values;
}

class Duration implements Comparable<Duration> {}

external bool identical(Object a, Object b);

void print(Object o) {}

abstract class _SyncIterable<T> implements Iterable<T> {}

class _SyncIterator<T> implements Iterator<T> {
  bool isYieldEach;
  T _current;
}

class _InvocationMirror {}
''';

/// Create SDK libraries which are used by Fasta to perform kernel generation.
/// The root of the SDK is `file:///sdk`, it will contain a libraries
/// specification file at `lib/libraries.json`.
///
/// Returns the [TargetLibrariesSpecification] whose contents are in
/// libraries.json.
TargetLibrariesSpecification createSdkFiles(MemoryFileSystem fileSystem) {
  Map<String, LibraryInfo> dartLibraries = {};
  void addSdkLibrary(String name, String contents) {
    String path = '$name/$name.dart';
    Uri uri = Uri.parse('file:///sdk/lib/$path');
    fileSystem.entityForUri(uri).writeAsStringSync(contents);
    dartLibraries[name] = new LibraryInfo(name, uri, const []);
  }

  fileSystem.entityForUri(Uri.parse('file:///sdk/')).createDirectory();

  addSdkLibrary('core', _CORE);
  addSdkLibrary('async', _ASYNC);

  addSdkLibrary('collection', 'library dart.collection;');
  addSdkLibrary('convert', 'library dart.convert;');
  addSdkLibrary('developer', 'library dart.developer;');
  addSdkLibrary('io', 'library dart.io;');
  addSdkLibrary('isolate', 'library dart.isolate;');
  addSdkLibrary('math', '''
library dart.math;
external double sin(num radians);
''');
  addSdkLibrary('mirrors', 'library dart.mirrors;');
  addSdkLibrary('nativewrappers', 'library dart.nativewrappers;');
  addSdkLibrary('profiler', 'library dart.profiler;');
  addSdkLibrary('typed_data', 'library dart.typed_data;');
  addSdkLibrary('_builtin', 'library dart._builtin;');
  addSdkLibrary('_internal', '''
library dart._internal;
class Symbol {}
class ExternalName {
  final String name;
  const ExternalName(this.name);
}
''');

  var targetSpec = new TargetLibrariesSpecification(null, dartLibraries);
  var spec = new LibrariesSpecification({'none': targetSpec, 'vm': targetSpec});

  Uri uri = Uri.parse('file:///sdk/lib/libraries.json');
  fileSystem.entityForUri(uri).writeAsStringSync(spec.toJsonString(uri));
  return targetSpec;
}
