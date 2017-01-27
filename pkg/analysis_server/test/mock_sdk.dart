// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.mock_sdk;

import 'package:analyzer/file_system/file_system.dart' as resource;
import 'package:analyzer/file_system/memory_file_system.dart' as resource;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:analyzer/src/summary/summary_file_builder.dart';

class MockSdk implements DartSdk {
  static const MockSdkLibrary LIB_CORE = const MockSdkLibrary(
      'dart:core',
      '/lib/core/core.dart',
      '''
library dart.core;

import 'dart:async';
import 'dart:_internal';

class Object {
  const Object() {}
  bool operator ==(other) => identical(this, other);
  String toString() => 'a string';
  int get hashCode => 0;
  Type get runtimeType => null;
  dynamic noSuchMethod(Invocation invocation) => null;
}

class Function {}
class StackTrace {}
class Symbol {}
class Type {}

abstract class Comparable<T> {
  int compareTo(T other);
}

abstract class String implements Comparable<String> {
  external factory String.fromCharCodes(Iterable<int> charCodes,
                                        [int start = 0, int end]);
  bool get isEmpty => false;
  bool get isNotEmpty => false;
  int get length => 0;
  String toUpperCase();
  List<int> get codeUnits;
}

class bool extends Object {}

abstract class num implements Comparable<num> {
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator /(num other);
  int operator ^(int other);
  int operator &(int other);
  int operator |(int other);
  int operator <<(int other);
  int operator >>(int other);
  int operator ~/(num other);
  num operator %(num other);
  int operator ~();
  int toInt();
  double toDouble();
  num abs();
  int round();
}

abstract class int extends num {
  bool get isEven => false;
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

class DateTime extends Object {}
class Null extends Object {}

class Deprecated extends Object {
  final String expires;
  const Deprecated(this.expires);
}
const Object deprecated = const Deprecated("next release");

class Iterator<E> {
  bool moveNext();
  E get current;
}

abstract class Iterable<E> {
  Iterator<E> get iterator;
  bool get isEmpty;
  Iterable/*<R>*/ map/*<R>*/(/*=R*/ f(E e));
}

class List<E> implements Iterable<E> {
  List();
  void add(E value) {}
  void addAll(Iterable<E> iterable) {}
  E operator [](int index) => null;
  void operator []=(int index, E value) {}
  Iterator<E> get iterator => null;
  void clear() {}

  bool get isEmpty => false;
  E get first => null;
  E get last => null;

  Iterable/*<R>*/ map/*<R>*/(/*=R*/ f(E e)) => null;

  /*=R*/ fold/*<R>*/(/*=R*/ initialValue,
      /*=R*/ combine(/*=R*/ previousValue, E element)) => null;

}

abstract class Map<K, V> extends Object {
  bool containsKey(Object key);
  Iterable<K> get keys;
}

external bool identical(Object a, Object b);

void print(Object object) {}

class Uri {
  static List<int> parseIPv6Address(String host, [int start = 0, int end]) {
    int parseHex(int start, int end) {
      return 0;
    }
    return null;
  }
}
''');

  static const MockSdkLibrary LIB_ASYNC = const MockSdkLibrary(
      'dart:async',
      '/lib/async/async.dart',
      '''
library dart.async;

import 'dart:math';

class Future<T> {
  factory Future(computation()) => null;
  factory Future.delayed(Duration duration, [T computation()]) => null;
  factory Future.value([value]) => null;
  static Future wait(List<Future> futures) => null;
}

class FutureOr<T> {}

class Stream<T> {}
abstract class StreamTransformer<S, T> {}
''');

  static const MockSdkLibrary LIB_COLLECTION = const MockSdkLibrary(
      'dart:collection',
      '/lib/collection/collection.dart',
      '''
library dart.collection;

abstract class HashMap<K, V> implements Map<K, V> {}
''');

  static const MockSdkLibrary LIB_CONVERT = const MockSdkLibrary(
      'dart:convert',
      '/lib/convert/convert.dart',
      '''
library dart.convert;

import 'dart:async';

abstract class Converter<S, T> implements StreamTransformer {}
class JsonDecoder extends Converter<String, Object> {}
''');

  static const MockSdkLibrary LIB_MATH = const MockSdkLibrary(
      'dart:math',
      '/lib/math/math.dart',
      '''
library dart.math;
const double E = 2.718281828459045;
const double PI = 3.1415926535897932;
const double LN10 =  2.302585092994046;
T min<T extends num>(T a, T b) => null;
T max<T extends num>(T a, T b) => null;
external double cos(num x);
external num pow(num x, num exponent);
external double sin(num x);
external double sqrt(num x);
class Random {
  bool nextBool() => true;
  double nextDouble() => 2.0;
  int nextInt() => 1;
}
''');

  static const MockSdkLibrary LIB_HTML = const MockSdkLibrary(
      'dart:html',
      '/lib/html/dartium/html_dartium.dart',
      '''
library dart.html;
class HtmlElement {}
''');

  static const MockSdkLibrary LIB_INTERNAL = const MockSdkLibrary(
      'dart:_internal',
      '/lib/internal/internal.dart',
      '''
library dart._internal;
external void printToConsole(String line);
''');

  static const List<SdkLibrary> LIBRARIES = const [
    LIB_CORE,
    LIB_ASYNC,
    LIB_COLLECTION,
    LIB_CONVERT,
    LIB_MATH,
    LIB_HTML,
    LIB_INTERNAL,
  ];

  static const String librariesContent = r'''
const Map<String, LibraryInfo> libraries = const {
  "async": const LibraryInfo("async/async.dart"),
  "collection": const LibraryInfo("collection/collection.dart"),
  "convert": const LibraryInfo("convert/convert.dart"),
  "core": const LibraryInfo("core/core.dart"),
  "html": const LibraryInfo("html/dartium/html_dartium.dart"),
  "math": const LibraryInfo("math/math.dart"),
  "_internal": const LibraryInfo("internal/internal.dart"),
};
''';

  final resource.MemoryResourceProvider provider;

  /**
   * The [AnalysisContext] which is used for all of the sources.
   */
  InternalAnalysisContext _analysisContext;

  /**
   * The cached linked bundle of the SDK.
   */
  PackageBundle _bundle;

  MockSdk(
      {bool generateSummaryFiles: false,
      resource.ResourceProvider resourceProvider})
      : provider = resourceProvider ?? new resource.MemoryResourceProvider() {
    LIBRARIES.forEach((SdkLibrary library) {
      provider.newFile(library.path, (library as MockSdkLibrary).content);
    });
    provider.newFile(
        provider.convertPath(
            '/lib/_internal/sdk_library_metadata/lib/libraries.dart'),
        librariesContent);
    if (generateSummaryFiles) {
      List<int> bytes = _computeLinkedBundleBytes();
      provider.newFileWithBytes(
          provider.convertPath('/lib/_internal/spec.sum'), bytes);
      provider.newFileWithBytes(
          provider.convertPath('/lib/_internal/strong.sum'), bytes);
    }
  }

  @override
  AnalysisContext get context {
    if (_analysisContext == null) {
      _analysisContext = new SdkAnalysisContext(null);
      SourceFactory factory = new SourceFactory([new DartUriResolver(this)]);
      _analysisContext.sourceFactory = factory;
    }
    return _analysisContext;
  }

  @override
  List<SdkLibrary> get sdkLibraries => LIBRARIES;

  @override
  String get sdkVersion => throw unimplemented;

  UnimplementedError get unimplemented => new UnimplementedError();

  @override
  List<String> get uris {
    List<String> uris = <String>[];
    for (SdkLibrary library in LIBRARIES) {
      uris.add(library.shortName);
    }
    return uris;
  }

  @override
  Source fromFileUri(Uri uri) {
    String filePath = provider.pathContext.fromUri(uri);
    for (SdkLibrary library in sdkLibraries) {
      String libraryPath = provider.convertPath(library.path);
      if (filePath == libraryPath) {
        try {
          resource.File file = provider.getResource(filePath);
          Uri dartUri = Uri.parse(library.shortName);
          return file.createSource(dartUri);
        } catch (exception) {
          return null;
        }
      }
      String libraryRootPath = provider.pathContext.dirname(libraryPath) +
          provider.pathContext.separator;
      if (filePath.startsWith(libraryRootPath)) {
        String pathInLibrary = filePath.substring(libraryRootPath.length);
        String uriStr = '${library.shortName}/$pathInLibrary';
        try {
          resource.File file = provider.getResource(filePath);
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
      resource.File summaryFile =
          provider.getFile(provider.convertPath('/lib/_internal/spec.sum'));
      List<int> bytes;
      if (summaryFile.exists) {
        bytes = summaryFile.readAsBytesSync();
      } else {
        bytes = _computeLinkedBundleBytes();
      }
      _bundle = new PackageBundle.fromBuffer(bytes);
    }
    return _bundle;
  }

  @override
  SdkLibrary getSdkLibrary(String dartUri) {
    // getSdkLibrary() is only used to determine whether a library is internal
    // to the SDK.  The mock SDK doesn't have any internals, so it's safe to
    // return null.
    return null;
  }

  @override
  Source mapDartUri(String dartUri) {
    const Map<String, String> uriToPath = const {
      "dart:core": "/lib/core/core.dart",
      "dart:html": "/lib/html/dartium/html_dartium.dart",
      "dart:async": "/lib/async/async.dart",
      "dart:collection": "/lib/collection/collection.dart",
      "dart:convert": "/lib/convert/convert.dart",
      "dart:math": "/lib/math/math.dart",
      "dart:_internal": "/lib/internal/internal.dart",
    };

    String path = uriToPath[dartUri];
    if (path != null) {
      resource.File file = provider.getResource(path);
      Uri uri = new Uri(scheme: 'dart', path: dartUri.substring(5));
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
    return new SummaryBuilder(
            librarySources, context, context.analysisOptions.strongMode)
        .build();
  }
}

class MockSdkLibrary implements SdkLibrary {
  final String shortName;
  final String path;
  final String content;

  const MockSdkLibrary(this.shortName, this.path, this.content);

  @override
  String get category => throw unimplemented;

  @override
  bool get isDart2JsLibrary => throw unimplemented;

  @override
  bool get isDocumented => throw unimplemented;

  @override
  bool get isImplementation => false;

  @override
  bool get isInternal => shortName.startsWith('dart:_');

  @override
  bool get isShared => throw unimplemented;

  @override
  bool get isVmLibrary => throw unimplemented;

  UnimplementedError get unimplemented => new UnimplementedError();
}
