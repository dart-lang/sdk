// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/src/version.dart';

const String sdkRoot = '/sdk';

final MockSdkLibrary _LIB_ASYNC = MockSdkLibrary([
  MockSdkLibraryUnit(
    'dart:async',
    '$sdkRoot/lib/async/async.dart',
    '''
library dart.async;

import 'dart:math';

part 'stream.dart';

abstract class Future<T> {
  factory Future(FutureOr<T> computation()) {
    throw 0;
  }

  factory Future.delayed(Duration duration, [FutureOr<T> computation()?]) {
    throw 0;
  }

  factory Future.microtask(FutureOr<T> computation()) {
    throw 0;
  }

  factory Future.value([FutureOr<T>? result]) {
    throw 0;
  }

  Future<R> then<R>(FutureOr<R> onValue(T value));

  Future<T> whenComplete(action());

  static Future<List<T>> wait<T>(Iterable<Future<T>> futures) => throw 0;
}

abstract class FutureOr<T> {}

abstract class Completer<T> {
  factory Completer() {
    throw 0;
  }

  factory Completer.sync() {
    throw 0;
  }

  Future<T> get future;
  bool get isCompleted;

  void complete([FutureOr<T>? value]);
  void completeError(Object error, [StackTrace? stackTrace]);
}

abstract class Timer {
  static void run(void callback()) {}
}
''',
  ),
  MockSdkLibraryUnit(
    'dart:async/stream.dart',
    '$sdkRoot/lib/async/stream.dart',
    r'''
part of dart.async;

abstract class Stream<T> {
  Stream();
  factory Stream.fromIterable(Iterable<T> data) {
    throw 0;
  }

  Future<T> get first;

  StreamSubscription<T> listen(void onData(T event)?,
      {Function? onError, void onDone()?, bool? cancelOnError});
}

abstract class StreamIterator<T> {}

abstract class StreamSubscription<T> {
  bool get isPaused;

  Future<E> asFuture<E>([E? futureValue]);
  Future cancel();
  void onData(void handleData(T data)?);
  void onError(Function? handleError);
  void onDone(void handleDone()?);
  void pause([Future<void>? resumeSignal]);
  void resume();
}

abstract class StreamTransformer<S, T> {}
''',
  )
]);

final MockSdkLibrary _LIB_ASYNC2 = MockSdkLibrary([
  MockSdkLibraryUnit(
    'dart:async2',
    '$sdkRoot/lib/async2/async2.dart',
    '''
library dart.async2;

class Future {}
''',
  )
]);

final MockSdkLibrary _LIB_COLLECTION = MockSdkLibrary([
  MockSdkLibraryUnit(
    'dart:collection',
    '$sdkRoot/lib/collection/collection.dart',
    '''
library dart.collection;

abstract class HashMap<K, V> implements Map<K, V> {
  external factory HashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey});

  external factory HashMap.identity();

  factory HashMap.from(Map<dynamic, dynamic> other) {
    throw 0;
  }

  factory HashMap.of(Map<K, V> other) {
    throw 0;
  }

  factory HashMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key, V Function(dynamic element)? value}) {
    throw 0;
  }

  factory HashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    throw 0;
  }

  factory HashMap.fromEntries(Iterable<MapEntry<K, V>> entries) {
    throw 0;
  }
}

abstract class LinkedHashMap<K, V> implements Map<K, V> {
  external factory LinkedHashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey});

  external factory LinkedHashMap.identity();

  factory LinkedHashMap.from(Map<dynamic, dynamic> other) {
    throw 0;
  }

  factory LinkedHashMap.of(Map<K, V> other) {
    throw 0;
  }

  factory LinkedHashMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key, V Function(dynamic element)? value}) {
    throw 0;
  }

  factory LinkedHashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    throw 0;
  }

  factory LinkedHashMap.fromEntries(Iterable<MapEntry<K, V>> entries) {
    throw 0;
  }
}

abstract class LinkedHashSet<E> implements Set<E> {
  external factory LinkedHashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey});

  external factory LinkedHashSet.identity();

  factory LinkedHashSet.from(Iterable<dynamic> elements) {
    throw 0;
  }

  factory LinkedHashSet.of(Iterable<E> elements) {
    throw 0;
  }
}
''',
  )
]);

final MockSdkLibrary _LIB_CONVERT = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:convert',
      '$sdkRoot/lib/convert/convert.dart',
      '''
library dart.convert;

import 'dart:async';

abstract class Converter<S, T> implements StreamTransformer {}

abstract class Encoding {}

class JsonDecoder extends Converter<String, Object> {}
''',
    )
  ],
);

final MockSdkLibrary _LIB_CORE = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:core',
      '$sdkRoot/lib/core/core.dart',
      '''
library dart.core;

import 'dart:async'; // ignore: unused_import

export 'dart:async' show Future, Stream;

const deprecated = const Deprecated("next release");

const override = const _Override();

const proxy = const _Proxy();

external bool identical(Object? a, Object? b);

void print(Object? object) {}

class ArgumentError extends Error {
  ArgumentError([message]);

  static T checkNotNull<T>(T argument, [String, name]) => argument;
}

// In the SDK this is an abstract class.
class BigInt implements Comparable<BigInt> {
  static BigInt parse(String source, {int radix}) => BigInt();
}

abstract class bool extends Object {
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue: false});

  external const factory bool.hasEnvironment(String name);

  bool operator &(bool other);
  bool operator |(bool other);
  bool operator ^(bool other);
}

abstract class Comparable<T> {
  int compareTo(T other);
}

typedef Comparator<T> = int Function(T a, T b);

class DateTime extends Object {}

class Deprecated extends Object {
  final String expires;
  const Deprecated(this.expires);
}

class pragma {
  final String name;
  final Object? options;
  const pragma(this.name, [this.options]);
}

abstract class double extends num {
  static const double NAN = 0.0 / 0.0;
  static const double INFINITY = 1.0 / 0.0;
  static const double NEGATIVE_INFINITY = -INFINITY;
  static const double MIN_POSITIVE = 5e-324;
  static const double MAX_FINITE = 1.7976931348623157e+308;

  double get sign;
  double operator %(num other);
  double operator *(num other);
  double operator +(num other);
  double operator -(num other);
  double operator -();
  double operator /(num other);
  int operator ~/(num other);

  double abs();
  int ceil();
  double ceilToDouble();
  int floor();
  double floorToDouble();
  double remainder(num other);
  int round();
  double roundToDouble();
  int truncate();
  double truncateToDouble();

  external static double parse(String source,
      [@deprecated double onError(String source)?]);

  external static double? tryParse(String source);
}

class Duration implements Comparable<Duration> {}

class Error {
  Error();
  static String safeToString(Object? object) => '';
  external StackTrace? get stackTrace;
}

class Exception {
  factory Exception([var message]) {
    throw 0;
  }
}

class FormatException implements Exception {}

class Function {}

abstract class int extends num {
  external const factory int.fromEnvironment(String name,
      {int defaultValue = 0});

  bool get isEven => false;
  bool get isNegative;

  int operator &(int other);
  int operator -();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);
  int operator ^(int other);
  int operator |(int other);
  int operator ~();

  int abs();
  int gcd(int other);
  String toString();

  external static int parse(String source,
      {int? radix, @deprecated int onError(String source)?});

  external static int? tryParse(String source, {int? radix});
}

abstract class Invocation {}

abstract class Iterable<E> {
  E get first;
  bool get isEmpty;
  bool get isNotEmpty;
  Iterator<E> get iterator;
  int get length;

  bool contains(Object element);

  Iterable<T> expand<T>(Iterable<T> f(E element));

  E firstWhere(bool test(E element), {E orElse()?});

  R fold<R>(R initialValue, R combine(R previousValue, E element));

  void forEach(void f(E element));

  E lastWhere(bool test(E element), {E orElse()?});

  Iterable<R> map<R>(R f(E e));

  E singleWhere(bool test(E element), {E orElse()?});

  List<E> toList({bool growable = true});

  Set<E> toSet();

  Iterable<E> where(bool test(E element));
}

abstract class Iterator<E> {
  E get current;
  bool moveNext();
}

class List<E> implements Iterable<E> {
  external factory List([int? length]);
  external factory List.filled(int length, E fill, {bool growable = false});
  external factory List.empty({bool growable = false});
  external factory List.from(Iterable elements, {bool growable = true});
  external factory List.of(Iterable<E> elements, {bool growable = true});
  external factory List.generate(int length, E generator(int index),
      {bool growable = true});
  external factory List.unmodifiable(Iterable elements);

  E get last => throw 0;
  E operator [](int index) => throw 0;
  void operator []=(int index, E value) {}

  void add(E value) {}
  void addAll(Iterable<E> iterable) {}
  Map<int, E> asMap() {}
  void clear() {}
  int indexOf(Object element);
  E removeLast() {}

  noSuchMethod(Invocation invocation) => null;
}

abstract class Map<K, V> {
  external factory Map();
  external factory Map.from();
  external Map.of(Map<K, V> other);
  external factory Map.unmodifiable(Map<dynamic, dynamic> other);
  external factory Map.identity();

  external factory Map.fromIterable(Iterable iterable,
      {K key(element)?, V value(element)?});

  external factory Map.fromIterables(Iterable<K> keys, Iterable<V> values);
  external factory Map.fromEntries(Iterable<MapEntry<K, V>> entries);

  Iterable<K> get keys;
  bool get isEmpty;
  bool get isNotEmpty;
  int get length => 0;
  Iterable<V> get values;

  V? operator [](K key);
  void operator []=(K key, V value);

  Map<RK, RV> cast<RK, RV>();
  bool containsKey(Object? key);
}

class Null extends Object {
  factory Null._uninstantiable() {
    throw 0;
  }
}

class MapEntry<K, V> {
  final K key;
  final V value;
  const factory MapEntry(K key, V value) = MapEntry<K, V>._;
  const MapEntry._(this.key, this.value);
}

abstract class num implements Comparable<num> {
  num operator %(num other);
  num operator *(num other);
  num operator +(num other);
  num operator -(num other);
  num operator -();
  double operator /(num other);
  bool operator <(num other);
  int operator <<(int other);
  bool operator <=(num other);
  bool operator ==(Object other);
  bool operator >(num other);
  bool operator >=(num other);
  int operator >>(int other);
  int operator ^(int other);
  int operator |(int other);
  int operator ~();
  int operator ~/(num other);

  num abs();
  num clamp(num lowerLimit, num upperLimit);
  int floor();
  num remainder(num other);
  int round();
  double toDouble();
  int toInt();
}

abstract class Match {}

class Object {
  const Object();

  external int get hashCode;
  external Type get runtimeType;

  external bool operator ==(Object other);

  external String toString();
  external dynamic noSuchMethod(Invocation invocation);
}

abstract class Pattern {
  Iterable<Match> allMatches(String string, [int start = 0]);
}

abstract class RegExp implements Pattern {
  external factory RegExp(String source);
}

abstract class Set<E> implements Iterable<E> {
  external factory Set();
  external factory Set.identity();
  external factory Set.from(Iterable elements);
  external factory Set.of(Iterable<E> elements);

  Set<R> cast<R>();

  bool add(E value);
  void addAll(Iterable<E> elements);
  bool remove(Object? value);
  E? lookup(Object? object);
}

class StackTrace {}

abstract class String implements Comparable<String>, Pattern {
  external factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]);

  external factory String.fromCharCode(int charCode);

  external const factory String.fromEnvironment(String name,
      {String defaultValue = ""});

  List<int> get codeUnits;
  bool get isEmpty => false;
  bool get isNotEmpty => false;
  int get length => 0;

  bool operator ==(Object other);
  String operator [](int index);
  String operator +(String other);
  String operator *(int times);

  int codeUnitAt(int index);
  bool contains(String other, [int startIndex = 0]);
  int indexOf(Pattern pattern, [int start = 0]);
  int lastIndexOf(Pattern pattern, [int? start]);
  bool startsWith(Pattern pattern, [int index = 0]);
  List<String> split(Pattern pattern);
  String splitMapJoin(Pattern pattern,
      {String Function(Match)? onMatch, String Function(String)? onNonMatch});
  String substring(int startIndex, [int? endIndex]);
  String toLowerCase();
  String toUpperCase();
}

class Symbol {
  const factory Symbol(String name) = _SymbolImpl;
}

class Type {}

class Uri {
  static List<int> parseIPv6Address(String host, [int start = 0, int end]) {
    return null;
  }
}

class _Override {
  const _Override();
}

class _Proxy {
  const _Proxy();
}

class _SymbolImpl {
  const _SymbolImpl(String name);
}
''',
    )
  ],
);

final MockSdkLibrary _LIB_FFI = MockSdkLibrary([
  MockSdkLibraryUnit(
    'dart:ffi',
    '$sdkRoot/lib/ffi/ffi.dart',
    '''
library dart.ffi;

class NativeType {
  const NativeType();
}

class Void extends NativeType {}

class Int8 extends NativeType {
  const Int8();
}

class Uint8 extends NativeType {
  const Uint8();
}

class Int16 extends NativeType {
  const Int16();
}

class Uint16 extends NativeType {
  const Uint16();
}

class Int32 extends NativeType {
  const Int32();
}

class Uint32 extends NativeType {
  const Uint32();
}

class Int64 extends NativeType {
  const Int64();
}

class Uint64 extends NativeType {
  const Uint64();
}

class Float extends NativeType {
  const Float();
}

class Double extends NativeType {
  const Double();
}

class Pointer<T extends NativeType> extends NativeType {
  static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
      @DartRepresentationOf("T") Function f,
      [Object exceptionalReturn]) {}
}

extension NativeFunctionPointer<NF extends Function>
    on Pointer<NativeFunction<NF>> {
  external DF asFunction<DF extends Function>();
}

class Struct extends NativeType {}

abstract class DynamicLibrary {}

extension DynamicLibraryExtension on DynamicLibrary {
  external F lookupFunction<T extends Function, F extends Function>(
      String symbolName);
}

abstract class NativeFunction<T extends Function> extends NativeType {}

class DartRepresentationOf {
  const DartRepresentationOf(String nativeType);
}
''',
  )
]);

final MockSdkLibrary _LIB_HTML_DART2JS = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:html',
      '$sdkRoot/lib/html/dart2js/html_dart2js.dart',
      '''
library dart.dom.html;

import 'dart:async';

class Event {}

class MouseEvent extends Event {}

class FocusEvent extends Event {}

class KeyEvent extends Event {}

abstract class ElementStream<T extends Event> implements Stream<T> {}

abstract class Element {
  factory Element.html(String html,
          {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) =>
      new HtmlElement();

  /// Stream of `cut` events handled by this [Element].
  ElementStream<Event> get onCut => throw 0;

  String get id => throw 0;

  set id(String value) => throw 0;

  DocumentFragment createFragment(String html,
          {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) => null;

  void setInnerHtml(String html,
          {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {}
}

class HtmlElement extends Element {
  int tabIndex;
  ElementStream<Event> get onChange => throw 0;
  ElementStream<MouseEvent> get onClick => throw 0;
  ElementStream<KeyEvent> get onKeyUp => throw 0;
  ElementStream<KeyEvent> get onKeyDown => throw 0;

  bool get hidden => throw 0;
  set hidden(bool value) {}

  void set className(String s) {}
  void set readOnly(bool b) {}
  void set tabIndex(int i) {}

  String _innerHtml;
  String get innerHtml {
    throw 'not the real implementation';
  }

  set innerHtml(String value) {
    // stuff
  }
}

class AnchorElement extends HtmlElement {
  factory AnchorElement({String href}) {
    AnchorElement e = JS('returns:AnchorElement;creates:AnchorElement;new:true',
        '#.createElement(#)', document, "a");
    if (href != null) e.href = href;
    return e;
  }

  String href;
  String _privateField;
}

class BodyElement extends HtmlElement {
  factory BodyElement() => document.createElement("body");

  ElementStream<Event> get onUnload => throw 0;
}

class ButtonElement extends HtmlElement {
  factory ButtonElement._() {
    throw new UnsupportedError("Not supported");
  }
  factory ButtonElement() => document.createElement("button");

  bool autofocus;
}

class EmbedElement extends HtmlEment {
  String src;
}

class HeadingElement extends HtmlElement {
  factory HeadingElement._() {
    throw new UnsupportedError("Not supported");
  }
  factory HeadingElement.h1() => document.createElement("h1");
  factory HeadingElement.h2() => document.createElement("h2");
  factory HeadingElement.h3() => document.createElement("h3");
}

class ImageElement extends HtmlEment {
  String src;
}

class InputElement extends HtmlElement {
  factory InputElement._() {
    throw new UnsupportedError("Not supported");
  }
  factory InputElement() => document.createElement("input");

  String value;
  String validationMessage;
}

class IFrameElement extends HtmlElement {
  factory IFrameElement._() {
    throw new UnsupportedError("Not supported");
  }
  factory IFrameElement() => JS(
      'returns:IFrameElement;creates:IFrameElement;new:true',
      '#.createElement(#)',
      document,
      "iframe");

  String src;
}

class OptionElement extends HtmlElement {
  factory OptionElement(
      {String data: '', String value: '', bool selected: false}) {}

  factory OptionElement._(
      [String data, String value, bool defaultSelected, bool selected]) {}
}

class ScriptElement extends HtmlElement {
  String src;
  String type;
}

class TableSectionElement extends HtmlElement {
  List<TableRowElement> get rows => throw 0;

  TableRowElement addRow() {}

  TableRowElement insertRow(int index) => throw 0;

  factory TableSectionElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TableSectionElement.internal_() : super.internal_();
}

class TemplateElement extends HtmlElement {
  factory TemplateElement._() {
    throw new UnsupportedError("Not supported");
  }
  factory TemplateElement() => document.createElement("template");
}

class AudioElement extends MediaElement {
  factory AudioElement._([String src]) {
    if (src != null) {
      return AudioElement._create_1(src);
    }
    return AudioElement._create_2();
  }

  static AudioElement _create_1(src) => JS('AudioElement', 'new Audio(#)', src);
  static AudioElement _create_2() => JS('AudioElement', 'new Audio()');
  AudioElement.created() : super.created();

  factory AudioElement([String src]) => new AudioElement._(src);
}

class MediaElement extends Element {}

class WindowBase {}

class Window extends WindowBase {
  WindowBase open(String url, String name, [String options]) => null;
}

class NodeValidator {}

class NodeTreeSanitizer {}

class DocumentFragment {
  DocumentFragment.html(String html,
          {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {}
}

dynamic JS(a, b, c, d) {}
''',
    )
  ],
);

final MockSdkLibrary _LIB_INTERCEPTORS = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:_interceptors',
      '$sdkRoot/lib/_internal/js_runtime/lib/interceptors.dart',
      '''
library dart._interceptors;
''',
    )
  ],
);

final MockSdkLibrary _LIB_INTERNAL = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:_internal',
      '$sdkRoot/lib/_internal/internal.dart',
      '''
library dart._internal;

class Symbol {}

class ExternalName {
  final String name;
  const ExternalName(this.name);
}
''',
    )
  ],
);

final MockSdkLibrary _LIB_IO = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:io',
      '$sdkRoot/lib/io/io.dart',
      '''
library dart.io;

import 'dart:convert';

Never exit(int code) => throw code;

abstract class Directory implements FileSystemEntity {
  factory Directory(String path) {
    throw 0;
  }

  Future<bool> exists() async => true;
  bool existsSync() => true;

  Future<FileStat> stat() async => throw 0;
  FileStat statSync() => throw 0;
}

abstract class File implements FileSystemEntity {
  factory File(String path) {
    throw 0;
  }

  Future<DateTime> lastModified();
  DateTime lastModifiedSync();

  Future<bool> exists();
  bool existsSync();

  Future<FileStat> stat();
  FileStat statSync();
}

abstract class FileSystemEntity {
  static Future<bool> isDirectory(String path) async => true;
  static bool isDirectorySync(String path) => true;

  static Future<bool> isFile(String path) async => true;
  static bool isFileSync(String path) => true;

  static Future<bool> isLink(String path) async => true;
  static bool isLinkSync(String path) => true;

  static Future<FileSystemEntityType> type(String path,
          {bool followLinks: true}) =>
      throw 0;
  static FileSystemEntityType typeSync(String path, {bool followLinks: true}) =>
      throw 0;
}

enum ProcessStartMode {
  normal,
}

abstract class Process {
  external static Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    ProcessStartMode mode: ProcessStartMode.normal,
  });

  external static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  });
}
''',
    )
  ],
);

final MockSdkLibrary _LIB_ISOLATE = MockSdkLibrary([
  MockSdkLibraryUnit(
    'dart:isolate',
    '$sdkRoot/lib/isolate/isolate.dart',
    '''
library dart.isolate;

abstract class SendPort {}

class Isolate {
  external static Future<Isolate> spawnUri(
    Uri uri,
    List<String> args,
    var message, {
    bool paused = false,
    SendPort? onExit,
    SendPort? onError,
    bool errorsAreFatal = true,
    bool? checked,
    Map<String, String>? environment,
    @deprecated Uri? packageRoot,
    Uri? packageConfig,
    bool automaticPackageResolution = false,
    String? debugName,
  });
}
''',
  )
]);

final MockSdkLibrary _LIB_MATH = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:math',
      '$sdkRoot/lib/math/math.dart',
      '''
library dart.math;

const double e = 2.718281828459045;
const double pi = 3.1415926535897932;
const double ln10 = 2.302585092994046;

T min<T extends num>(T a, T b) => throw 0;
T max<T extends num>(T a, T b) => throw 0;

external double cos(num radians);
external double sin(num radians);
external double sqrt(num radians);
external double tan(num radians);

class Random {
  bool nextBool() => true;
  double nextDouble() => 2.0;
  int nextInt() => 1;
}

class Point<T extends num> {}
''',
    )
  ],
);

final List<SdkLibrary> _LIBRARIES = [
  _LIB_CORE,
  _LIB_ASYNC,
  _LIB_ASYNC2,
  _LIB_COLLECTION,
  _LIB_CONVERT,
  _LIB_FFI,
  _LIB_IO,
  _LIB_ISOLATE,
  _LIB_MATH,
  _LIB_HTML_DART2JS,
  _LIB_INTERCEPTORS,
  _LIB_INTERNAL,
];

final Map<String, String> _librariesDartEntries = {
  'async': 'const LibraryInfo("async/async.dart")',
  'collection': 'const LibraryInfo("collection/collection.dart")',
  'convert': 'const LibraryInfo("convert/convert.dart")',
  'core': 'const LibraryInfo("core/core.dart")',
  'ffi': 'const LibraryInfo("ffi/ffi.dart")',
  'html': 'const LibraryInfo("html/dart2js/html_dart2js.dart")',
  'io': 'const LibraryInfo("io/io.dart")',
  'isolate': 'const LibraryInfo("isolate/isolate.dart")',
  'math': 'const LibraryInfo("math/math.dart")',
  '_internal': 'const LibraryInfo("_internal/internal.dart", categories: "")',
};

class MockSdk implements DartSdk {
  final MemoryResourceProvider resourceProvider;

  final Map<String, String> uriMap = {};

  @override
  final List<SdkLibrary> sdkLibraries = [];

  File _versionFile;

  /// Optional [additionalLibraries] should have unique URIs, and paths in
  /// their units are relative (will be put into `sdkRoot/lib`).
  ///
  /// [nullSafePackages], if supplied, is a list of packages names that should
  /// be included in the null safety allow list.
  ///
  /// [sdkVersion], if supplied will override the version stored in the mock
  /// SDK's `version` file.
  MockSdk({
    @required this.resourceProvider,
    List<MockSdkLibrary> additionalLibraries = const [],
    List<String> nullSafePackages = const [],
    String sdkVersion,
  }) {
    sdkVersion ??= '${ExperimentStatus.currentVersion.major}.'
        '${ExperimentStatus.currentVersion.minor}.0';
    _versionFile = resourceProvider
        .getFolder(resourceProvider.convertPath(sdkRoot))
        .getChildAssumingFile('version');
    _versionFile.writeAsStringSync(sdkVersion);

    for (MockSdkLibrary library in _LIBRARIES) {
      var convertedLibrary = library._toProvider(resourceProvider);
      sdkLibraries.add(convertedLibrary);
    }
    for (MockSdkLibrary library in additionalLibraries) {
      sdkLibraries.add(
        MockSdkLibrary(
          library.units.map(
            (unit) {
              var pathContext = resourceProvider.pathContext;
              var absoluteUri = pathContext.join(sdkRoot, 'lib', unit.path);
              return MockSdkLibraryUnit(
                unit.uriStr,
                resourceProvider.convertPath(absoluteUri),
                unit.content,
              );
            },
          ).toList(),
        ),
      );
    }

    for (MockSdkLibrary library in sdkLibraries) {
      for (var unit in library.units) {
        resourceProvider.newFile(unit.path, unit.content);
        uriMap[unit.uriStr] = unit.path;
      }
    }

    {
      var buffer = StringBuffer();
      buffer.writeln('const Map<String, LibraryInfo> libraries = const {');
      for (var e in _librariesDartEntries.entries) {
        buffer.writeln('"${e.key}": ${e.value},');
      }
      for (var library in additionalLibraries) {
        for (var unit in library.units) {
          var name = unit.uriStr.substring(5);
          var libraryInfo = 'const LibraryInfo("${unit.path}")';
          buffer.writeln('"$name": $libraryInfo,');
        }
      }
      buffer.writeln('};');
      resourceProvider.newFile(
        resourceProvider.convertPath(
          '$sdkRoot/lib/_internal/sdk_library_metadata/lib/libraries.dart',
        ),
        buffer.toString(),
      );
    }

    resourceProvider.newFile(
      resourceProvider.convertPath(
        '$sdkRoot/lib/_internal/allowed_experiments.json',
      ),
      json.encode({
        'version': 1,
        'experimentSets': {
          'nullSafety': ['non-nullable']
        },
        'sdk': {
          'default': {'experimentSet': 'nullSafety'}
        },
        if (nullSafePackages.isNotEmpty)
          'packages': {
            for (var package in nullSafePackages)
              package: {'experimentSet': 'nullSafety'}
          }
      }),
    );
  }

  @override
  String get allowedExperimentsJson {
    try {
      var convertedRoot = resourceProvider.convertPath(sdkRoot);
      return resourceProvider
          .getFolder(convertedRoot)
          .getChildAssumingFolder('lib')
          .getChildAssumingFolder('_internal')
          .getChildAssumingFile('allowed_experiments.json')
          .readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  @override
  Version get languageVersion {
    var sdkVersionStr = _versionFile.readAsStringSync();
    return languageVersionFromSdkVersion(sdkVersionStr);
  }

  @override
  String get sdkVersion => throw UnimplementedError();

  @override
  List<String> get uris =>
      sdkLibraries.map((SdkLibrary library) => library.shortName).toList();

  @override
  Source fromFileUri(Uri uri) {
    String filePath = resourceProvider.pathContext.fromUri(uri);
    if (!filePath.startsWith(resourceProvider.convertPath('$sdkRoot/lib/'))) {
      return null;
    }
    for (SdkLibrary library in sdkLibraries) {
      String libraryPath = library.path;
      if (filePath == libraryPath) {
        try {
          File file = resourceProvider.getResource(filePath);
          Uri dartUri = Uri.parse(library.shortName);
          return file.createSource(dartUri);
        } catch (exception) {
          return null;
        }
      }
      String libraryRootPath =
          resourceProvider.pathContext.dirname(libraryPath) +
              resourceProvider.pathContext.separator;
      if (filePath.startsWith(libraryRootPath)) {
        String pathInLibrary = filePath.substring(libraryRootPath.length);
        String uriStr = '${library.shortName}/$pathInLibrary';
        try {
          File file = resourceProvider.getResource(filePath);
          Uri dartUri = Uri.parse(uriStr);
          return file.createSource(dartUri);
        } catch (exception) {
          return null;
        }
      }
    }
    return null;
  }

  @override
  SdkLibrary getSdkLibrary(String dartUri) {
    for (SdkLibrary library in _LIBRARIES) {
      if (library.shortName == dartUri) {
        return library;
      }
    }
    return null;
  }

  @override
  Source mapDartUri(String dartUri) {
    String path = uriMap[dartUri];
    if (path != null) {
      File file = resourceProvider.getResource(path);
      Uri uri = Uri(scheme: 'dart', path: dartUri.substring(5));
      return file.createSource(uri);
    }
    // If we reach here then we tried to use a dartUri that's not in the
    // table above.
    return null;
  }
}

class MockSdkLibrary implements SdkLibrary {
  final List<MockSdkLibraryUnit> units;

  MockSdkLibrary(this.units);

  @override
  String get category => throw UnimplementedError();

  @override
  bool get isDart2JsLibrary => throw UnimplementedError();

  @override
  bool get isDocumented => throw UnimplementedError();

  @override
  bool get isImplementation => throw UnimplementedError();

  @override
  bool get isInternal => shortName.startsWith('dart:_');

  @override
  bool get isShared => throw UnimplementedError();

  @override
  bool get isVmLibrary => throw UnimplementedError();

  @override
  String get path => units[0].path;

  @override
  String get shortName => units[0].uriStr;

  MockSdkLibrary _toProvider(MemoryResourceProvider provider) {
    return MockSdkLibrary(
      units.map((unit) => unit._toProvider(provider)).toList(),
    );
  }
}

class MockSdkLibraryUnit {
  final String uriStr;
  final String path;
  final String content;

  MockSdkLibraryUnit(this.uriStr, this.path, this.content);

  MockSdkLibraryUnit _toProvider(MemoryResourceProvider provider) {
    return MockSdkLibraryUnit(
      uriStr,
      provider.convertPath(path),
      content,
    );
  }
}
