// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/memory_file_system.dart';

/// Create SDK libraries which are used by Fasta to perform kernel generation.
/// Return the mapping from the simple names of these library to the URIs
/// in the given [fileSystem].  The root of the SDK is `file:///sdk`.
Map<String, Uri> createSdkFiles(MemoryFileSystem fileSystem) {
  Map<String, Uri> dartLibraries = {};

  void addSdkLibrary(String name, String contents) {
    String path = '$name/$name.dart';
    Uri uri = Uri.parse('file:///sdk/lib/$path');
    fileSystem.entityForUri(uri).writeAsStringSync(contents);
    dartLibraries[name] = uri;
  }

  addSdkLibrary(
      'core',
      r'''
library dart.core;
import 'dart:_internal';
import 'dart:async';

class Object {
  const Object();
}

class Null {}
class Symbol {}
class Type {}
class Function {}
class Invocation {}
class StackTrace {}
class bool {}
class String {}
class num {}
class int extends num {}
class double {}
class Iterable<T> {}
class Iterator<T> {}
class List<T> extends Iterable<T> {}
class Map<K, V> {}

void print(Object o) {}

abstract class _SyncIterable implements Iterable {}
''');

  addSdkLibrary(
      'async',
      r'''
library dart.async;

class Future<T> {
  factory Future.microtask(FutureOr<T> computation()) => null;
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

class _StreamIterator<T> implements StreamIterator<T> {}
class _AsyncStarStreamController {}
Function _asyncThenWrapperHelper(continuation) {}
Function _asyncErrorWrapperHelper(continuation) {}
Future _awaitHelper(
    object, Function thenCallback, Function errorCallback, var awaiter) {}
''');

  addSdkLibrary('collection', 'library dart.collection;');
  addSdkLibrary('convert', 'library dart.convert;');
  addSdkLibrary('developer', 'library dart.developer;');
  addSdkLibrary('io', 'library dart.io;');
  addSdkLibrary('isolate', 'library dart.isolate;');
  addSdkLibrary(
      'math',
      '''
library dart.math;
double sin(num radians) => _sin(radians.toDouble());
double _sin(double x) native "Math_sin";
''');
  addSdkLibrary('mirrors', 'library dart.mirrors;');
  addSdkLibrary('nativewrappers', 'library dart.nativewrappers;');
  addSdkLibrary('profiler', 'library dart.profiler;');
  addSdkLibrary('typed_data', 'library dart.typed_data;');
  addSdkLibrary('vmservice_io', 'library dart.vmservice_io;');
  addSdkLibrary('_builtin', 'library dart._builtin;');
  addSdkLibrary(
      '_internal',
      '''
library dart._internal;
class Symbol {}
class ExternalName {
  final String name;
  const ExternalName(this.name);
}
''');
  addSdkLibrary('_vmservice', 'library dart._vmservice;');

  return dartLibraries;
}
