// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart' as resource;
import 'package:analyzer/file_system/memory_file_system.dart' as resource;
import 'package:analyzer/src/context/cache.dart'
    show AnalysisCache, CachePartition;
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, ChangeSet;
import 'package:analyzer/src/generated/sdk.dart' show DartSdk, SdkLibrary;
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, Source, SourceFactory;
import 'package:analyzer/src/summary/idl.dart';

/// Mock SDK for testing purposes.
class MockSdk implements DartSdk {
  static const _MockSdkLibrary LIB_CORE = const _MockSdkLibrary(
      'dart:core',
      '/lib/core/core.dart',
      '''
library dart.core;

import 'dart:async';

class Object {
  const Object();

  bool operator ==(other) => identical(this, other);
  String toString() => 'a string';
  int get hashCode => 0;
}

class Function {}
class StackTrace {}
class Symbol {}
class Type {}

abstract class Comparable<T> {
  int compareTo(T other);
}

abstract class String extends Object implements Comparable<String> {
  external factory String.fromCharCodes(Iterable<int> charCodes,
                                        [int start = 0, int end]);
  bool get isEmpty => false;
  bool get isNotEmpty => false;
  int get length => 0;
  bool contains(String other, [int startIndex = 0]);
  int indexOf(String other, [int start]);
  String toUpperCase();
  List<int> get codeUnits;
}

class bool extends Object {}
abstract class num extends Object implements Comparable<num> {
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator /(num other);
  int toInt();
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
class double extends num {}
class DateTime extends Object {
  DateTime.now() {}
  bool isBefore(DateTime other) => true;
}
class Null extends Object {}

class Deprecated extends Object {
  final String expires;
  const Deprecated(this.expires);
}
const Object deprecated = const Deprecated("next release");

class Error {
  Error();
  static String safeToString(Object object);
  external static String _stringToSafeString(String string);
  external static String _objectToString(Object object);
  external StackTrace get stackTrace;
}

class Iterator<E> {
  bool moveNext();
  E get current;
}

abstract class Iterable<E> {
  Iterator<E> get iterator;
  bool contains(Object element);
  bool get isEmpty;
  bool get isNotEmpty;
  E get first;
  E get last;
  int get length;
}

abstract class List<E> implements Iterable<E> {
  void add(E value);
  E operator [](int index);
  void operator []=(int index, E value);
  Iterator<E> get iterator => null;
  void clear();
  int indexOf(Object element);
  bool get isEmpty;
  bool get isNotEmpty;
}

abstract class Map<K, V> extends Object {
  Iterable<K> get keys;
  bool get isEmpty;
  bool get isNotEmpty;
  int get length;
}

external bool identical(Object a, Object b);

void print(Object object) {}

class _Override {
  const _Override();
}
const Object override = const _Override();


abstract class RegExp {
  external factory RegExp(String source, {bool multiLine: false,
                                          bool caseSensitive: true});
}
''');

  static const _MockSdkLibrary LIB_ASYNC = const _MockSdkLibrary(
      'dart:async',
      '/lib/async/async.dart',
      '''
library dart.async;

import 'dart:math';

part 'stream.dart';

class Future<T> {
  factory Future.delayed(Duration duration, [T computation()]) => null;
  factory Future.value([value]) => null;
  static Future wait(List<Future> futures) => null;
}

class FutureOr<T> {}
''',
      const <_MockSdkFile>[
        const _MockSdkFile(
            '/lib/async/stream.dart',
            r'''
part of dart.async;
class Stream<T> {}
abstract class StreamTransformer<S, T> {}
''')
      ]);

  static const _MockSdkLibrary LIB_COLLECTION = const _MockSdkLibrary(
      'dart:collection',
      '/lib/collection/collection.dart',
      '''
library dart.collection;

abstract class HashMap<K, V> implements Map<K, V> {}
abstract class LinkedHashMap<K, V> implements HashMap<K, V> {}
''');

  static const _MockSdkLibrary LIB_CONVERT = const _MockSdkLibrary(
      'dart:convert',
      '/lib/convert/convert.dart',
      '''
library dart.convert;

import 'dart:async';

abstract class Converter<S, T> implements StreamTransformer {}
class JsonDecoder extends Converter<String, Object> {}
''');

  static const _MockSdkLibrary LIB_IO = const _MockSdkLibrary(
      'dart:io',
      '/lib/io/io.dart',
      '''
library dart.io;

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
''');

  static const _MockSdkLibrary LIB_MATH = const _MockSdkLibrary(
      'dart:math',
      '/lib/math/math.dart',
      '''
library dart.math;
const double E = 2.718281828459045;
const double PI = 3.1415926535897932;
const double LN10 =  2.302585092994046;
num min(num a, num b) => 0;
num max(num a, num b) => 0;
external double cos(num x);
external double sin(num x);
external double sqrt(num x);
class Random {
  bool nextBool() => true;
  double nextDouble() => 2.0;
  int nextInt() => 1;
}
''');

  static const _MockSdkLibrary LIB_HTML = const _MockSdkLibrary(
      'dart:html',
      '/lib/html/dartium/html_dartium.dart',
      '''
library dart.html;
class HtmlElement {}
''');

  static const List<SdkLibrary> LIBRARIES = const [
    LIB_CORE,
    LIB_ASYNC,
    LIB_COLLECTION,
    LIB_CONVERT,
    LIB_IO,
    LIB_MATH,
    LIB_HTML,
  ];

  final resource.MemoryResourceProvider provider =
      new resource.MemoryResourceProvider();

  /// The [AnalysisContextImpl] which is used for all of the sources.
  AnalysisContextImpl _analysisContext;

  MockSdk() {
    LIBRARIES.forEach((SdkLibrary library) {
      if (library is _MockSdkLibrary) {
        provider.newFile(library.path, library.content);
        library.parts.forEach((file) {
          provider.newFile(file.path, file.content);
        });
      }
    });
  }

  @override
  AnalysisContextImpl get context {
    if (_analysisContext == null) {
      _analysisContext = new _SdkAnalysisContext(this);
      SourceFactory factory = new SourceFactory([new DartUriResolver(this)]);
      _analysisContext.sourceFactory = factory;
      ChangeSet changeSet = new ChangeSet();
      for (String uri in uris) {
        Source source = factory.forUri(uri);
        changeSet.addedSource(source);
      }
      _analysisContext.applyChanges(changeSet);
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
    String filePath = uri.path;
    String libPath = '/lib';
    if (!filePath.startsWith('$libPath/')) {
      return null;
    }
    for (SdkLibrary library in LIBRARIES) {
      String libraryPath = library.path;
      if (filePath.replaceAll('\\', '/') == libraryPath) {
        try {
          resource.File file = provider.getResource(uri.path);
          Uri dartUri = Uri.parse(library.shortName);
          return file.createSource(dartUri);
        } catch (exception) {
          return null;
        }
      }
      if (filePath.startsWith('$libraryPath/')) {
        String pathInLibrary = filePath.substring(libraryPath.length + 1);
        String path = '${library.shortName}/$pathInLibrary';
        try {
          resource.File file = provider.getResource(uri.path);
          Uri dartUri = new Uri(scheme: 'dart', path: path);
          return file.createSource(dartUri);
        } catch (exception) {
          return null;
        }
      }
    }
    return null;
  }

  @override
  PackageBundle getLinkedBundle() => null;

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
      'dart:core': '/lib/core/core.dart',
      'dart:html': '/lib/html/dartium/html_dartium.dart',
      'dart:async': '/lib/async/async.dart',
      'dart:async/stream.dart': '/lib/async/stream.dart',
      'dart:collection': '/lib/collection/collection.dart',
      'dart:convert': '/lib/convert/convert.dart',
      'dart:io': '/lib/io/io.dart',
      'dart:math': '/lib/math/math.dart'
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
}

class _MockSdkFile {
  final String path;
  final String content;

  const _MockSdkFile(this.path, this.content);
}

class _MockSdkLibrary implements SdkLibrary {
  @override
  final String shortName;
  @override
  final String path;
  final String content;
  final List<_MockSdkFile> parts;

  const _MockSdkLibrary(this.shortName, this.path, this.content,
      [this.parts = const <_MockSdkFile>[]]);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An [AnalysisContextImpl] that only contains sources for a Dart SDK.
class _SdkAnalysisContext extends AnalysisContextImpl {
  final DartSdk sdk;

  _SdkAnalysisContext(this.sdk);

  @override
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    if (factory == null) {
      return super.createCacheFromSourceFactory(factory);
    }
    return new AnalysisCache(
        <CachePartition>[AnalysisEngine.instance.partitionManager.forSdk(sdk)]);
  }
}
