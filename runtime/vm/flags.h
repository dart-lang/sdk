// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLAGS_H_
#define VM_FLAGS_H_

#include "vm/assert.h"
#include "vm/globals.h"

typedef const char* charp;

#define DECLARE_FLAG(type, name)                                               \
  extern type FLAG_##name

#define DEFINE_FLAG(type, name, default_value, comment)                        \
  type FLAG_##name = Flags::Register_##type(&FLAG_##name,                      \
                                            #name,                             \
                                            default_value,                     \
                                            comment)


#if defined(DEBUG)
#define DECLARE_DEBUG_FLAG(type, name) DECLARE_FLAG(type, name)
#define DEFINE_DEBUG_FLAG(type, name, default_value, comment)                  \
  DEFINE_FLAG(type, name, default_value, comment)
#else
#define DECLARE_DEBUG_FLAG(type, name)
#define DEFINE_DEBUG_FLAG(type, name, default_value, comment)
#endif

namespace dart {

// Forward declaration.
class Flag;

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

  static const char* Register_charp(charp* addr,
                                    const char* name,
                                    const char* default_value,
                                    const char* comment);

  static bool ProcessCommandLineFlags(int argc, const char** argv);

  static Flag* Lookup(const char* name);

  static bool Initialized() { return initialized_; }

 private:
  static Flag* flags_;

  static bool initialized_;

  static void Parse(const char* option);

  // Testing needs direct access to private methods.
  friend void Dart_TestParseFlags();

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Flags);
};

}  // namespace dart

#endif  // VM_FLAGS_H_
