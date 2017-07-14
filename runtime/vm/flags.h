// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FLAGS_H_
#define RUNTIME_VM_FLAGS_H_

#include "platform/assert.h"
#include "vm/flag_list.h"
#include "vm/globals.h"

typedef const char* charp;

#define DECLARE_FLAG(type, name) extern type FLAG_##name

#define DEFINE_FLAG(type, name, default_value, comment)                        \
  type FLAG_##name =                                                           \
      Flags::Register_##type(&FLAG_##name, #name, default_value, comment);

#define DEFINE_FLAG_HANDLER(handler, name, comment)                            \
  bool DUMMY_##name = Flags::Register_func(handler, #name, comment);

namespace dart {

typedef void (*FlagHandler)(bool value);

// Forward declarations.
class Flag;
class JSONArray;
class JSONStream;

class Flags {
 public:
  static bool Register_bool(bool* addr,
                            const char* name,
                            bool default_value,
                            const char* comment);

  static int Register_int(int* addr,
                          const char* name,
                          int default_value,
                          const char* comment);

  static uint64_t Register_uint64_t(uint64_t* addr,
                                    const char* name,
                                    uint64_t default_value,
                                    const char* comment);

  static const char* Register_charp(charp* addr,
                                    const char* name,
                                    const char* default_value,
                                    const char* comment);

  static bool Register_func(FlagHandler handler,
                            const char* name,
                            const char* comment);

  static bool ProcessCommandLineFlags(int argc, const char** argv);

  static Flag* Lookup(const char* name);

  static bool IsSet(const char* name);

  static bool Initialized() { return initialized_; }

#ifndef PRODUCT
  static void PrintJSON(JSONStream* js);
#endif  // !PRODUCT

  static bool SetFlag(const char* name, const char* value, const char** error);

 private:
  static Flag** flags_;
  static intptr_t capacity_;
  static intptr_t num_flags_;

  static bool initialized_;

  static void AddFlag(Flag* flag);

  static bool SetFlagFromString(Flag* flag, const char* argument);

  static void Parse(const char* option);

  static int CompareFlagNames(const void* left, const void* right);

  static void PrintFlags();

#ifndef PRODUCT
  static void PrintFlagToJSONArray(JSONArray* jsarr, const Flag* flag);
#endif  // !PRODUCT

  // Testing needs direct access to private methods.
  friend void Dart_TestParseFlags();

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Flags);
};

#define PRODUCT_FLAG_MARCO(name, type, default_value, comment)                 \
  extern type FLAG_##name;

#if defined(DEBUG)
#define DEBUG_FLAG_MARCO(name, type, default_value, comment)                   \
  extern type FLAG_##name;
#else  // defined(DEBUG)
#define DEBUG_FLAG_MARCO(name, type, default_value, comment)                   \
  const type FLAG_##name = default_value;
#endif  // defined(DEBUG)

#if defined(PRODUCT) && defined(DART_PRECOMPILED_RUNTIME)
#define RELEASE_FLAG_MARCO(name, product_value, type, default_value, comment)  \
  const type FLAG_##name = product_value;
#define PRECOMPILE_FLAG_MARCO(name, precompiled_value, product_value, type,    \
                              default_value, comment)                          \
  const type FLAG_##name = precompiled_value;

#elif defined(PRODUCT)  // !PRECOMPILED
#define RELEASE_FLAG_MARCO(name, product_value, type, default_value, comment)  \
  const type FLAG_##name = product_value;
#define PRECOMPILE_FLAG_MARCO(name, precompiled_value, product_value, type,    \
                              default_value, comment)                          \
  const type FLAG_##name = product_value;

#elif defined(DART_PRECOMPILED_RUNTIME)  // !PRODUCT
#define RELEASE_FLAG_MARCO(name, product_value, type, default_value, comment)  \
  extern type FLAG_##name;
#define PRECOMPILE_FLAG_MARCO(name, precompiled_value, product_value, type,    \
                              default_value, comment)                          \
  const type FLAG_##name = precompiled_value;

#else  // !PRODUCT && !PRECOMPILED
#define RELEASE_FLAG_MARCO(name, product_value, type, default_value, comment)  \
  extern type FLAG_##name;
#define PRECOMPILE_FLAG_MARCO(name, precompiled_value, product_value, type,    \
                              default_value, comment)                          \
  extern type FLAG_##name;

#endif

// Now declare all flags here.
FLAG_LIST(PRODUCT_FLAG_MARCO,
          RELEASE_FLAG_MARCO,
          DEBUG_FLAG_MARCO,
          PRECOMPILE_FLAG_MARCO)

#undef RELEASE_FLAG_MARCO
#undef DEBUG_FLAG_MARCO
#undef PRODUCT_FLAG_MARCO
#undef PRECOMPILE_FLAG_MARCO

}  // namespace dart

#endif  // RUNTIME_VM_FLAGS_H_
