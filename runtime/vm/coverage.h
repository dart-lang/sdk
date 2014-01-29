// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COVERAGE_H_
#define VM_COVERAGE_H_

#include "vm/allocation.h"
#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(charp, coverage_dir);

// Forward declarations.
class Class;
class Function;
class Isolate;
class JSONArray;
class JSONStream;

class CodeCoverage : public AllStatic {
 public:
  static void Write(Isolate* isolate);
  static void PrintToJSONStream(Isolate* isolate, JSONStream* stream);

 private:
  static void PrintClass(const Class& cls, const JSONArray& arr);
  static void CompileAndAdd(const Function& function,
                            const JSONArray& hits_arr);
};

}  // namespace dart

#endif  // VM_COVERAGE_H_
