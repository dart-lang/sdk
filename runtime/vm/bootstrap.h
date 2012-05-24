// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BOOTSTRAP_H_
#define VM_BOOTSTRAP_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class Library;
class RawError;
class RawScript;
class Script;

class Bootstrap : public AllStatic {
 public:
  static RawScript* LoadScript();
  static RawScript* LoadImplScript();
  static RawScript* LoadMathScript();
  static RawScript* LoadIsolateScript();
  static RawScript* LoadMirrorsScript();
  static RawError* Compile(const Library& library, const Script& script);
  static void SetupNativeResolver();

 private:
  static const char corelib_source_[];
  static const char corelib_impl_source_[];
  static const char math_source_[];
  static const char isolate_source_[];
  static const char mirrors_source_[];
};

}  // namespace dart

#endif  // VM_BOOTSTRAP_H_
