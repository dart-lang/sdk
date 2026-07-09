// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
   Generated with:
     dart pkg/vm/tool/generate_entry_point_shims.dart \
         out/ReleaseX64/gen/samples/embedder/timer_aot.dart.dill \
         samples/embedder/timer
*/

#include "timer.h"

#include <iostream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace {

Dart_Handle CheckError(Dart_Handle handle, std::string_view context = "") {
  if (Dart_IsError(handle)) {
    std::cerr << "Error " << context << ": " << Dart_GetError(handle)
              << std::endl;
    std::exit(1);
  }
  return handle;
}

int64_t IntFromHandle(Dart_Handle handle) {
  CheckError(handle, "IntFromHandle received an error");

  if (!Dart_IsInteger(handle)) {
    std::cerr << "IntFromHandle handle is not an int" << std::endl;
    std::exit(1);
  }

  int64_t result;
  Dart_Handle to_int64_result = Dart_IntegerToInt64(handle, &result);
  CheckError(to_int64_result, "Dart_IntegerToInt64");
  return result;
}

double DoubleFromHandle(Dart_Handle handle) {
  CheckError(handle, "DoubleFromHandle received an error");

  if (!Dart_IsDouble(handle)) {
    std::cerr << "DoubleFromHandle handle is not an double" << std::endl;
    std::exit(1);
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
      result = Dart_RootLibrary();
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

 private:
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
#define PACKAGE_EXPORT                                                         \
  PACKAGE_EXTERN_C __attribute__((visibility("default"))) __attribute((used))
#else
#error Tool chain not supported.
#endif
#endif

PACKAGE_EXPORT void Call_startTimer(Dart_Isolate dart_isolate,
                                    int64_t v_millis) {
  IsolateScope isolate_scope(dart_isolate);
  DartScope scope;
  std::vector parameter_list{Dart_NewInteger(v_millis)};
  CheckError(Dart_Invoke(PackageState::instance()->PackageLibrary(),
                         Dart_NewStringFromCString("startTimer"), 1,
                         parameter_list.data()));
}

PACKAGE_EXPORT void Call_stopTimer(Dart_Isolate dart_isolate) {
  IsolateScope isolate_scope(dart_isolate);
  DartScope scope;
  CheckError(Dart_Invoke(PackageState::instance()->PackageLibrary(),
                         Dart_NewStringFromCString("stopTimer"), 0, nullptr));
}

PACKAGE_EXPORT void Call_resetTimer(Dart_Isolate dart_isolate) {
  IsolateScope isolate_scope(dart_isolate);
  DartScope scope;
  CheckError(Dart_Invoke(PackageState::instance()->PackageLibrary(),
                         Dart_NewStringFromCString("resetTimer"), 0, nullptr));
}

PACKAGE_EXPORT int64_t Get_ticks(Dart_Isolate dart_isolate) {
  IsolateScope isolate_scope(dart_isolate);
  DartScope scope;
  return IntFromHandle(Dart_GetField(PackageState::instance()->PackageLibrary(),
                                     Dart_NewStringFromCString("ticks")));
}

#undef PACKAGE_EXPORT
#undef PACKAGE_EXTERN_C
