// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:analyzer/src/summary/summary_file_builder.dart';
import 'package:meta/meta.dart';

const String sdkRoot = '/sdk';

final MockSdkLibrary _LIB_ASYNC = MockSdkLibrary([
  MockSdkLibraryUnit(
    'dart:async',
    '$sdkRoot/lib/async/async.dart',
    '''
library dart.async;

import 'dart:math';

part 'stream.dart';

class Future<T> {
  factory Future(computation()) => null;
  factory Future.delayed(Duration duration, [T computation()]) => null;
  factory Future.microtask(FutureOr<T> computation()) => null;
  factory Future.value([FutureOr<T> result]) => null;

  Future<R> then<R>(FutureOr<R> onValue(T value)) => null;
  Future<T> whenComplete(action());

  static Future<List<T>> wait<T>(Iterable<Future<T>> futures) => null;
}

class FutureOr<T> {}

abstract class Completer<T> {
  factory Completer() => null;
  factory Completer.sync() => null;

  Future<T> get future;
  bool get isCompleted;

  void complete([value]);
  void completeError(Object error, [StackTrace stackTrace]);
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
  factory Stream.fromIterable(Iterable<T> data) => null;

  Future<T> get first;

  StreamSubscription<T> listen(void onData(T event),
                               { Function onError,
                                 void onDone(),
                                 bool cancelOnError});
}

abstract class StreamIterator<T> {}

abstract class StreamSubscription<T> {
  bool get isPaused;

  Future<E> asFuture<E>([E futureValue]);
  Future cancel();
  void onData(void handleData(T data));
  void onError(Function handleError);
  void onDone(void handleDone());
  void pause([Future resumeSignal]);
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
      {bool equals(K key1, K key2),
      int hashCode(K key),
      bool isValidKey(potentialKey)});

  external factory HashMap.identity();

  factory HashMap.from(Map other) => null;

  factory HashMap.of(Map<K, V> other) => null;

  factory HashMap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) => null;

  factory HashMap.fromIterables(Iterable<K> keys, Iterable<V> values) => null;

  factory HashMap.fromEntries(Iterable<MapEntry<K, V>> entries) => null;
}

abstract class LinkedHashMap<K, V> implements Map<K, V> {
  external factory LinkedHashMap(
      {bool equals(K key1, K key2),
      int hashCode(K key),
      bool isValidKey(potentialKey)});

  external factory LinkedHashMap.identity();

  factory LinkedHashMap.from(Map other) => null;

  factory LinkedHashMap.of(Map<K, V> other) => null;

  factory LinkedHashMap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) => null;

  factory LinkedHashMap.fromIterables(Iterable<K> keys, Iterable<V> values)
      => null;

  factory LinkedHashMap.fromEntries(Iterable<MapEntry<K, V>> entries) => null;
}

abstract class LinkedHashSet<E> implements Set<E> {
  external factory LinkedHashSet(
      {bool equals(E e1, E e2),
      int hashCode(E e),
      bool isValidKey(potentialKey)});

  external factory LinkedHashSet.identity();

  factory LinkedHashSet.from(Iterable elements) => null;

  factory LinkedHashSet.of(Iterable<E> elements) => null;
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

external bool identical(Object a, Object b);

void print(Object object) {}

abstract class bool extends Object {
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue: false});

  bool operator &(bool other);
  bool operator |(bool other);
  bool operator ^(bool other);
}

abstract class Comparable<T> {
  int compareTo(T other);
}

class DateTime extends Object {}

class Deprecated extends Object {
  final String expires;
  const Deprecated(this.expires);
}

class pragma {
  final String name;
  final Object options;
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

  external static double parse(String source, [double onError(String source)]);
}

class Duration implements Comparable<Duration> {}

class Error {
  Error();
  static String safeToString(Object object) => '';
  external StackTrace get stackTrace;
}

class Exception {
  factory Exception([var message]) => null;
}

class FormatException implements Exception {}

class Function {}

abstract class int extends num {
  external const factory int.fromEnvironment(String name, {int defaultValue});

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
      {int radix, int onError(String source)});
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

  E firstWhere(bool test(E element), { E orElse()});

  R fold<R>(R initialValue, R combine(R previousValue, E element)) => null;

  void forEach(void f(E element));

  Iterable<R> map<R>(R f(E e));

  List<E> toList();

  Set<E> toSet();

  Iterable<E> where(bool test(E element));
}

abstract class Iterator<E> {
  E get current;
  bool moveNext();
}

class List<E> implements Iterable<E> {
  List([int length]);
  external factory List.from(Iterable elements, {bool growable: true});
  external factory List.filled(int length, E fill, {bool growable = false});
  external factory List.from(Iterable elements, {bool growable = true});
  external factory List.of(Iterable<E> elements, {bool growable = true});
  external factory List.generate(int length, E generator(int index),
      {bool growable = true});
  external factory List.unmodifiable(Iterable elements);

  E get last => null;
  E operator [](int index) => null;
  void operator []=(int index, E value) {}

  void add(E value) {}
  void addAll(Iterable<E> iterable) {}
  Map<int, E> asMap() {}
  void clear() {}
  int indexOf(Object element);
  E removeLast() {}

  noSuchMethod(Invocation invocation) => null;
}

class Map<K, V> {
  factory Map() => null;

  factory Map.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) => null;

  Iterable<K> get keys => null;
  bool get isEmpty;
  bool get isNotEmpty;
  int get length => 0;
  Iterable<V> get values => null;

  V operator [](K key) => null;
  void operator []=(K key, V value) {}

  Map<RK, RV> cast<RK, RV>() => null;
  bool containsKey(Object key) => false;
}

class Null extends Object {
  factory Null._uninstantiable() => null;
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
  int floor();
  int round();
  double toDouble();
  int toInt();
}

class Object {
  const Object();

  int get hashCode => 0;
  Type get runtimeType => null;

  bool operator ==(Object other) => identical(this, other);

  String toString() => 'a string';
  dynamic noSuchMethod(Invocation invocation) => null;
}

abstract class Pattern {}

abstract class RegExp implements Pattern {
  external factory RegExp(String source);
}

abstract class Set<E> implements Iterable<E> {
  factory Set() => null;
  factory Set.identity() => null;
  factory Set.from(Iterable elements) => null;
  factory Set.of(Iterable<E> elements) => null;

  Set<R> cast<R>();
}

class StackTrace {}

abstract class String implements Comparable<String>, Pattern {
  external factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int end]);

  List<int> get codeUnits;
  int indexOf(Pattern pattern, [int start]);
  bool get isEmpty => false;
  bool get isNotEmpty => false;
  int get length => 0;

  String operator +(String other) => null;
  bool operator ==(Object other);

  int codeUnitAt(int index);
  bool contains(String other, [int startIndex = 0]);
  String substring(int len) => null;
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
      [Object exceptionalReturn]);
  R asFunction<@DartRepresentationOf("T") R extends Function>();
}
class Struct extends NativeType {}

abstract class DynamicLibrary {
  F lookupFunction<T extends Function, F extends Function>(String symbolName);
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
  /// Stream of `cut` events handled by this [Element].
  ElementStream<Event> get onCut => null;

  String get id => null;

  set id(String value) => null;
}

class HtmlElement extends Element {
  int tabIndex;
  ElementStream<Event> get onChange => null;
  ElementStream<MouseEvent> get onClick => null;
  ElementStream<KeyEvent> get onKeyUp => null;
  ElementStream<KeyEvent> get onKeyDown => null;

  bool get hidden => null;
  set hidden(bool value) => null;

  void set className(String s){}
  void set readOnly(bool b){}
  void set tabIndex(int i){}

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

  ElementStream<Event> get onUnload => null;
}

class ButtonElement extends HtmlElement {
  factory ButtonElement._() { throw new UnsupportedError("Not supported"); }
  factory ButtonElement() => document.createElement("button");

  bool autofocus;
}

class EmbedElement extends HtmlEment {
  String src;
}

class HeadingElement extends HtmlElement {
  factory HeadingElement._() { throw new UnsupportedError("Not supported"); }
  factory HeadingElement.h1() => document.createElement("h1");
  factory HeadingElement.h2() => document.createElement("h2");
  factory HeadingElement.h3() => document.createElement("h3");
}

class InputElement extends HtmlElement {
  factory InputElement._() { throw new UnsupportedError("Not supported"); }
  factory InputElement() => document.createElement("input");

  String value;
  String validationMessage;
}

class IFrameElement extends HtmlElement {
  factory IFrameElement._() { throw new UnsupportedError("Not supported"); }
  factory IFrameElement() => JS(
      'returns:IFrameElement;creates:IFrameElement;new:true',
      '#.createElement(#)',
      document,
      "iframe");

  String src;
}

class ImageElement extends HtmlEment {
  String src;
}

class OptionElement extends HtmlElement {
  factory OptionElement({String data: '', String value : '', bool selected: false}) {
  }

  factory OptionElement._([String data, String value, bool defaultSelected, bool selected]) {
  }
}

class ScriptElement extends HtmlElement {
  String src;
  String type;
}

class TableSectionElement extends HtmlElement {

  List<TableRowElement> get rows => null;

  TableRowElement addRow() {
  }

  TableRowElement insertRow(int index) => null;

  factory TableSectionElement._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TableSectionElement.internal_() : super.internal_();
}

class TemplateElement extends HtmlElement {
  factory TemplateElement._() { throw new UnsupportedError("Not supported"); }
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

abstract class Directory implements FileSystemEntity {
  factory Directory(String path) => null;

  Future<bool> exists() async => true;
  bool existsSync() => true;

  Future<FileStat> stat() async => null;
  FileStat statSync() => null;
}

abstract class File implements FileSystemEntity {
  factory File(String path) => null;

  Future<DateTime> lastModified();
  DateTime lastModifiedSync();

  Future<bool> exists() async => true;
  bool existsSync() => true;

  Future<FileStat> stat() async => null;
  FileStat statSync() => null;
}

abstract class FileSystemEntity {
  static Future<bool> isDirectory(String path) => true;
  static bool isDirectorySync(String path) => true;

  static Future<bool> isFile(String path) => true;
  static bool isFileSync(String path) => true;

  static Future<bool> isLink(String path) => true;
  static bool isLinkSync(String path) => true;

  static Future<FileSystemEntityType> type(
    String path, {bool followLinks: true}) async => null;
  static FileSystemEntityType typeSync(
    String path, {bool followLinks: true}) => null;
}
''',
    )
  ],
);

final MockSdkLibrary _LIB_MATH = MockSdkLibrary(
  [
    MockSdkLibraryUnit(
      'dart:math',
      '$sdkRoot/lib/math/math.dart',
      '''
library dart.math;

const double E = 2.718281828459045;
const double PI = 3.1415926535897932;
const double LN10 =  2.302585092994046;

T min<T extends num>(T a, T b) => null;
T max<T extends num>(T a, T b) => null;

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
  'math': 'const LibraryInfo("math/math.dart")',
};

class MockSdk implements DartSdk {
  final MemoryResourceProvider resourceProvider;

  final Map<String, String> uriMap = {};

  final AnalysisOptionsImpl _analysisOptions;

  /**
   * The [AnalysisContextImpl] which is used for all of the sources.
   */
  AnalysisContextImpl _analysisContext;

  @override
  final List<SdkLibrary> sdkLibraries = [];

  /**
   * The cached linked bundle of the SDK.
   */
  PackageBundle _bundle;

  /// Optional [additionalLibraries] should have unique URIs, and paths in
  /// their units are relative (will be put into `sdkRoot/lib`).
  MockSdk({
    bool generateSummaryFiles = false,
    @required this.resourceProvider,
    AnalysisOptionsImpl analysisOptions,
    List<MockSdkLibrary> additionalLibraries = const [],
  }) : _analysisOptions = analysisOptions ?? AnalysisOptionsImpl() {
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
              var absoluteUri = pathContext.join(sdkRoot, unit.path);
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
      buffer.writeln('};');
      resourceProvider.newFile(
        resourceProvider.convertPath(
          '$sdkRoot/lib/_internal/sdk_library_metadata/lib/libraries.dart',
        ),
        buffer.toString(),
      );
    }

    if (generateSummaryFiles) {
      List<int> bytes = _computeLinkedBundleBytes();
      resourceProvider.newFileWithBytes(
          resourceProvider.convertPath('/lib/_internal/strong.sum'), bytes);
    }
  }

  @override
  AnalysisContextImpl get context {
    if (_analysisContext == null) {
      var factory = SourceFactory([DartUriResolver(this)]);
      _analysisContext = SdkAnalysisContext(_analysisOptions, factory);
    }
    return _analysisContext;
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
  PackageBundle getLinkedBundle() {
    if (_bundle == null) {
      File summaryFile = resourceProvider
          .getFile(resourceProvider.convertPath('/lib/_internal/strong.sum'));
      List<int> bytes;
      if (summaryFile.exists) {
        bytes = summaryFile.readAsBytesSync();
      } else {
        bytes = _computeLinkedBundleBytes();
      }
      _bundle = PackageBundle.fromBuffer(bytes);
    }
    return _bundle;
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

  /**
   * Compute the bytes of the linked bundle associated with this SDK.
   */
  List<int> _computeLinkedBundleBytes() {
    List<Source> librarySources = sdkLibraries
        .map((SdkLibrary library) => mapDartUri(library.shortName))
        .toList();
    var featureSet = FeatureSet.fromEnableFlags([]);
    return SummaryBuilder(librarySources, context).build(
      featureSet: featureSet,
    );
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
