// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:path/path.dart' as path;

import 'collector.dart' show EntryPointShimCollector;

class EntryPointShimWriter {
  final String _headerPath;
  final Library? _library;
  final EntryPointShimCollector _collector;

  EntryPointShimWriter(this._headerPath, this._library, this._collector);

  static final _guardRegExp = RegExp(r"[^A-Za-z0-9]");

  String get _headerGuardFromPath =>
      _headerPath.replaceAll(_guardRegExp, "_").toUpperCase();

  static const exportDirectiveDefinitions = '''

#ifdef __cplusplus
#define PACKAGE_EXTERN_C extern "C"
#else
#define PACKAGE_EXTERN_C extern
#endif

#if defined(__CYGWIN__)
#error Tool chain and platform not supported.
#elif defined(_WIN32)
#define PACKAGE_EXPORT PACKAGE_EXTERN_C __declspec(dllexport)
#else
#if __GNUC__ >= 4
#define PACKAGE_EXPORT PACKAGE_EXTERN_C __attribute__((visibility("default"))) __attribute((used))
#else
#error Tool chain not supported.
#endif
#endif
''';

  static const exportDirectiveRemovals = '''

#undef PACKAGE_EXPORT
#undef PACKAGE_EXTERN_C
''';

  void write(StringBuffer declarations, StringBuffer definitions) {
    // Output helpers used by shim methods.
    declarations.writeln('''
#ifndef $_headerGuardFromPath
#define $_headerGuardFromPath

#include "include/dart_engine.h"
''');
    declarations.writeln(exportDirectiveDefinitions);
    definitions.write('''
#include "${path.basename(_headerPath)}"

#include <cstdio>
#include <cstdlib>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace {

Dart_Handle CheckError(Dart_Handle handle, std::string_view context = "") {
  if (Dart_IsError(handle)) {
    std::string context_str(context);
    fprintf(stderr, "Error %s: %s\\n", context_str.c_str(), Dart_GetError(handle));
    exit(1);
  }
  return handle;
}

int64_t IntFromHandle(Dart_Handle handle) {
  CheckError(handle, "IntFromHandle received an error");

  if (!Dart_IsInteger(handle)) {
    fprintf(stderr, "IntFromHandle handle is not an int\\n");
    exit(1);
  }

  int64_t result;
  Dart_Handle to_int64_result = Dart_IntegerToInt64(handle, &result);
  CheckError(to_int64_result, "Dart_IntegerToInt64");
  return result;
}

double DoubleFromHandle(Dart_Handle handle) {
  CheckError(handle, "DoubleFromHandle received an error");

  if (!Dart_IsDouble(handle)) {
    fprintf(stderr, "DoubleFromHandle handle is not a double\\n");
    exit(1);
  }

  double result;
  Dart_Handle to_double_result = Dart_DoubleValue(handle, &result);
  CheckError(to_double_result, "Dart_DoubleValue");
  return result;
}

class PackageState {
 public:
  static PackageState* instance() {
    static PackageState* instance = new PackageState();
    return instance;
  }

  Dart_Handle PackageLibrary() {
    ValidateCurrentIsolate();
    Dart_Handle result = package_library_;
    if (package_library_ == nullptr) {
      result = ''');
    if (_library == null) {
      definitions.write('Dart_RootLibrary()');
    } else {
      definitions.write(
        'Dart_LookupLibrary(Dart_NewStringFromCString(kLibraryUri))',
      );
    }
    definitions.writeln(''';
      if (!Dart_IsError(result)) {
        package_library_ = Dart_NewPersistentHandle(result);
      }
    }
    return result;
  }

  Dart_Handle TypeWithDefaults(std::string name) {
    ValidateCurrentIsolate();
    auto search = default_types_.find(name);
    Dart_Handle result;
    if (search == default_types_.end()) {
      Dart_Handle lib = PackageLibrary();
      result = Dart_GetClass(lib, Dart_NewStringFromCString(name.c_str()));
      if (!Dart_IsError(result)) {
        Dart_PersistentHandle handle = Dart_NewPersistentHandle(result);
        default_types_.emplace(std::make_pair(name, handle));
      }
    } else {
      result = search->second;
    }
    return result;
  }

 private:''');
    if (_library != null) {
      definitions.writeln('''
  static constexpr char kLibraryUri[] = "${_library.importUri}";

''');
    }
    definitions.writeln('''
  PackageState() : default_types_() {}

  void ValidateCurrentIsolate() {
    Dart_Isolate current = Dart_CurrentIsolate();
    if (isolate_ != current) {
      isolate_ = current;
      if (package_library_ != nullptr) {
        Dart_DeletePersistentHandle(package_library_);
        package_library_ = nullptr;
      }
      for (const auto& [str, handle] : default_types_) {
        Dart_DeletePersistentHandle(handle);
      }
      default_types_.clear();
    }
  }

  // Ensure the helper methods defined above won't trigger unused
  // function warnings.
  template <typename T>
  static inline void USE(T&&) {}

  void UseHelperFunctions() {
    USE(IntFromHandle);
    USE(DoubleFromHandle);
  }

  Dart_Isolate isolate_ = nullptr;
  Dart_PersistentHandle package_library_ = nullptr;
  std::unordered_map<std::string, Dart_PersistentHandle> default_types_;
};

class DartScope {
 public:
  DartScope() { Dart_EnterScope(); }
  virtual ~DartScope() { Dart_ExitScope(); }

 private:
  DartScope(const DartScope&) = delete;
  void operator=(const DartScope&) = delete;
};

class IsolateScope {
 public:
  explicit IsolateScope(Dart_Isolate isolate) {
    DartEngine_AcquireIsolate(isolate);
  }
  virtual ~IsolateScope() { DartEngine_ReleaseIsolate(); }

 private:
  IsolateScope(const IsolateScope&) = delete;
  void operator=(const IsolateScope&) = delete;
};

}  // namespace
''');
    definitions.writeln(exportDirectiveDefinitions);
    for (final e in _collector.entries) {
      final r = e.key;
      declarations.write('''
// ${r.node!}
''');
      for (final shim in e.value) {
        shim.write(declarations, definitions);
      }
    }
    declarations.writeln(exportDirectiveRemovals);
    definitions.writeln(exportDirectiveRemovals);
    declarations.write('''

#endif  // $_headerGuardFromPath
''');
  }
}
