// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
  static RawScript* LoadCoreScript(bool patch);
  static RawScript* LoadCoreImplScript(bool patch);
  static RawScript* LoadMathScript(bool patch);
  static RawScript* LoadIsolateScript(bool patch);
  static RawScript* LoadMirrorsScript(bool patch);
  static RawScript* LoadScalarlistScript(bool patch);
  static RawError* Compile(const Library& library, const Script& script);
  static void SetupNativeResolver();

 private:
  static RawScript* LoadScript(const char* url, const char* source, bool patch);

  static const char corelib_source_[];
  static const char corelib_patch_[];
  static const char corelib_impl_source_[];
  static const char corelib_impl_patch_[];
  static const char math_source_[];
  static const char math_patch_[];
  static const char isolate_source_[];
  static const char isolate_patch_[];
  static const char mirrors_source_[];
  static const char mirrors_patch_[];
  static const char scalarlist_source_[];
  static const char scalarlist_patch_[];
};

}  // namespace dart

#endif  // VM_BOOTSTRAP_H_
