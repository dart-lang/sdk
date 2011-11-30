// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DARTUTILS_H_
#define BIN_DARTUTILS_H_

#include "bin/builtin.h"
#include "bin/globals.h"

#include "include/dart_api.h"

class CommandLineOptions {
 public:
  explicit CommandLineOptions(int max_count)
      : count_(0), max_count_(max_count), arguments_(NULL) {
    static const int kWordSize = sizeof(intptr_t);
    arguments_ = reinterpret_cast<const char **>(malloc(max_count * kWordSize));
    if (arguments_ == NULL) {
      max_count_ = 0;
    }
  }
  ~CommandLineOptions() {
    free(arguments_);
    count_ = 0;
    max_count_ = 0;
    arguments_ = NULL;
  }

  int count() const { return count_; }
  const char** arguments() const { return arguments_; }

  const char* GetArgument(int index) const {
    return (index >= 0 && index < count_) ? arguments_[index] : NULL;
  }
  void AddArgument(const char* argument) {
    if (count_ < max_count_) {
      arguments_[count_] = argument;
      count_ += 1;
    } else {
      abort();  // We should never get into this situation.
    }
  }

  void operator delete(void* pointer) { abort(); }

 private:
  void* operator new(size_t size);
  CommandLineOptions(const CommandLineOptions&);
  void operator=(const CommandLineOptions&);

  int count_;
  int max_count_;
  const char** arguments_;
};


class DartUtils {
 public:
  static int64_t GetIntegerValue(Dart_Handle value_obj);
  static const char* GetStringValue(Dart_Handle str_obj);
  static bool GetBooleanValue(Dart_Handle bool_obj);
  static void SetIntegerInstanceField(Dart_Handle handle,
                                      const char* name,
                                      intptr_t val);
  static intptr_t GetIntegerInstanceField(Dart_Handle handle,
                                          const char* name);
  static void SetStringInstanceField(Dart_Handle handle,
                                     const char* name,
                                     const char* val);
  static bool IsDartSchemeURL(const char* url_name);
  static Dart_Handle CanonicalizeURL(CommandLineOptions* url_mapping,
                                     Dart_Handle library,
                                     const char* url_str);
  static Dart_Handle ReadStringFromFile(const char* filename);
  static Dart_Handle LoadSource(CommandLineOptions* url_mapping,
                                Dart_Handle library,
                                Dart_Handle url,
                                Dart_LibraryTag tag,
                                const char* filename);

  static const char* kDartScheme;
  static const char* kBuiltinLibURL;
  static const char* kCoreLibURL;
  static const char* kCoreImplLibURL;
  static const char* kCoreNativeWrappersLibURL;

  static const char* kIdFieldName;

 private:
  static const char* GetCanonicalPath(const char* reference_dir,
                                      const char* filename);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartUtils);
};

#endif  // BIN_DARTUTILS_H_
