// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes for representing information about the program structure.
library vm.snapshot.program_info;

/// Represents information about compiled program.
class ProgramInfo<T> {
  final Map<String, LibraryInfo<T>> libraries = {};
  final Map<String, T> stubs = {};

  /// Recursively visit all function nodes, which have [FunctionInfo.info]
  /// populated.
  void visit(
      void Function(String lib, String cls, String fun, T info) callback) {
    void recurse(String lib, String cls, String name, FunctionInfo<T> fun) {
      if (fun.info != null) {
        callback(lib, cls, name, fun.info);
      }

      for (var clo in fun.closures.entries) {
        recurse(lib, cls, '$name.${clo.key}', clo.value);
      }
    }

    for (var stub in stubs.entries) {
      callback(null, null, stub.key, stub.value);
    }

    for (var lib in libraries.entries) {
      for (var cls in lib.value.classes.entries) {
        for (var fun in cls.value.functions.entries) {
          recurse(lib.key, cls.key, fun.key, fun.value);
        }
      }
    }
  }

  /// Convert this program info to a JSON map using [infoToJson] to convert
  /// data attached to [FunctioInfo] nodes into its JSON representation.
  Map<String, dynamic> toJson(Object Function(T) infoToJson) {
    Map<String, dynamic> recurse(FunctionInfo<T> fun) {
      return {
        if (fun.info != null) 'info': infoToJson(fun.info),
        if (fun.closures.isNotEmpty)
          'closures': {
            for (var clo in fun.closures.entries) clo.key: recurse(clo.value)
          }
      };
    }

    return {
      'stubs': {
        for (var stub in stubs.entries) stub.key: infoToJson(stub.value)
      },
      'libraries': {
        for (var lib in libraries.entries)
          lib.key: {
            for (var cls in lib.value.classes.entries)
              cls.key: {
                for (var fun in cls.value.functions.entries)
                  fun.key: recurse(fun.value)
              }
          }
      }
    };
  }
}

class LibraryInfo<T> {
  final Map<String, ClassInfo<T>> classes = {};
}

class ClassInfo<T> {
  final Map<String, FunctionInfo<T>> functions = {};
}

class FunctionInfo<T> {
  final Map<String, FunctionInfo<T>> closures = {};

  T info;
}

/// Computes the size difference between two [ProgramInfo<int>].
ProgramInfo<SymbolDiff> computeDiff(
    ProgramInfo<int> oldInfo, ProgramInfo<int> newInfo) {
  final programDiff = ProgramInfo<SymbolDiff>();

  void recursiveDiff(FunctionInfo<SymbolDiff> Function() functionInfo,
      String fun, FunctionInfo<int> newFun, FunctionInfo<int> oldFun) {
    if (newFun?.info != oldFun?.info) {
      final funDiff = functionInfo();
      final diff = funDiff.info ??= SymbolDiff();
      diff.oldTotal += oldFun?.info ?? 0;
      diff.newTotal += newFun?.info ?? 0;
    }

    for (var clo in _allKeys(newFun?.closures, oldFun?.closures)) {
      final newClo = newFun != null ? newFun.closures[clo] : null;
      final oldClo = oldFun != null ? oldFun.closures[clo] : null;
      recursiveDiff(() {
        return functionInfo().closures.putIfAbsent(clo, () => FunctionInfo());
      }, clo, newClo, oldClo);
    }
  }

  for (var stub in _allKeys(newInfo.stubs, oldInfo.stubs)) {
    final newSize = newInfo.stubs[stub];
    final oldSize = oldInfo.stubs[stub];
    if (newSize != oldSize) {
      programDiff.stubs[stub] = SymbolDiff()
        ..oldTotal = oldSize ?? 0
        ..newTotal = newSize ?? 0;
    }
  }

  for (var lib in _allKeys(newInfo.libraries, oldInfo.libraries)) {
    final newLib = newInfo.libraries[lib];
    final oldLib = oldInfo.libraries[lib];
    for (var cls in _allKeys(newLib?.classes, oldLib?.classes)) {
      final newCls = newLib != null ? newLib.classes[cls] : null;
      final oldCls = oldLib != null ? oldLib.classes[cls] : null;
      for (var fun in _allKeys(newCls?.functions, oldCls?.functions)) {
        final newFun = newCls != null ? newCls.functions[fun] : null;
        final oldFun = oldCls != null ? oldCls.functions[fun] : null;
        recursiveDiff(() {
          return programDiff.libraries
              .putIfAbsent(lib, () => LibraryInfo())
              .classes
              .putIfAbsent(cls, () => ClassInfo())
              .functions
              .putIfAbsent(fun, () => FunctionInfo());
        }, fun, newFun, oldFun);
      }
    }
  }

  return programDiff;
}

class SymbolDiff {
  int oldTotal = 0;
  int newTotal = 0;

  int get inBytes {
    return newTotal - oldTotal;
  }
}

Iterable<T> _allKeys<T>(Map<T, dynamic> a, Map<T, dynamic> b) {
  return <T>{...?a?.keys, ...?b?.keys};
}

/// Histogram of sizes based on a [ProgramInfo] bucketted using one of the
/// [HistogramType] rules.
class SizesHistogram {
  /// Rule used to produce this histogram. Specifies how bucket names
  /// are constructed given (library-uri,class-name,function-name) tuples and
  /// how these bucket names can be deconstructed back into human readable form.
  final Bucketing bucketing;

  /// Histogram buckets.
  final Map<String, int> buckets;

  /// Bucket names sorted by the size of the corresponding bucket in descending
  /// order.
  final List<String> bySize;

  SizesHistogram._(this.bucketing, this.buckets, this.bySize);

  /// Construct the histogram of specific [type] given a [ProgramInfo<T>] and
  /// function [toSize] for  computing an integer value based on the datum of
  /// type [T] attached to program nodes.
  static SizesHistogram from<T>(
      ProgramInfo<T> info, int Function(T) toSize, HistogramType type) {
    final buckets = <String, int>{};
    final bucketing = Bucketing._forType[type];

    info.visit((lib, cls, fun, info) {
      final bucket = bucketing.bucketFor(lib ?? '<stubs>', cls ?? '', fun);
      buckets[bucket] = (buckets[bucket] ?? 0) + toSize(info);
    });

    final bySize = buckets.keys.toList(growable: false);
    bySize.sort((a, b) => buckets[b] - buckets[a]);

    return SizesHistogram._(bucketing, buckets, bySize);
  }
}

enum HistogramType {
  bySymbol,
  byClass,
  byLibrary,
  byPackage,
}

abstract class Bucketing {
  /// Specifies which human readable name components can be extracted from
  /// the bucket name.
  List<String> get nameComponents;

  /// Constructs the bucket name from the given library name [lib], class name
  /// [cls] and function name [fun].
  String bucketFor(String lib, String cls, String fun);

  /// Deconstructs bucket name into human readable components (the order matches
  /// one returned by [nameComponents]).
  List<String> namesFromBucket(String bucket);

  const Bucketing();

  static const _forType = {
    HistogramType.bySymbol: _BucketBySymbol(),
    HistogramType.byClass: _BucketByClass(),
    HistogramType.byLibrary: _BucketByLibrary(),
    HistogramType.byPackage: _BucketByPackage(),
  };
}

/// A combination of characters that is unlikely to occur in the symbol name.
const String _nameSeparator = ';;;';

class _BucketBySymbol extends Bucketing {
  @override
  List<String> get nameComponents => const ['Library', 'Method'];

  @override
  String bucketFor(String lib, String cls, String fun) =>
      '$lib${_nameSeparator}${cls}${cls != '' ? '.' : ''}${fun}';

  @override
  List<String> namesFromBucket(String bucket) => bucket.split(_nameSeparator);

  const _BucketBySymbol();
}

class _BucketByClass extends Bucketing {
  @override
  List<String> get nameComponents => ['Library', 'Class'];

  @override
  String bucketFor(String lib, String cls, String fun) =>
      '$lib${_nameSeparator}${cls}';

  @override
  List<String> namesFromBucket(String bucket) => bucket.split(_nameSeparator);

  const _BucketByClass();
}

class _BucketByLibrary extends Bucketing {
  @override
  List<String> get nameComponents => ['Library'];

  @override
  String bucketFor(String lib, String cls, String fun) => '$lib';

  @override
  List<String> namesFromBucket(String bucket) => [bucket];

  const _BucketByLibrary();
}

class _BucketByPackage extends Bucketing {
  @override
  List<String> get nameComponents => ['Package'];

  @override
  String bucketFor(String lib, String cls, String fun) => _packageOf(lib);

  @override
  List<String> namesFromBucket(String bucket) => [bucket];

  const _BucketByPackage();

  String _packageOf(String lib) {
    if (lib.startsWith('package:')) {
      final separatorPos = lib.indexOf('/');
      return lib.substring(0, separatorPos);
    } else {
      return lib;
    }
  }
}
