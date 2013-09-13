// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COVERAGE_H_
#define VM_COVERAGE_H_

#include "vm/allocation.h"
#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(bool, print_coverage);

// Forward declarations.
class Class;
class Isolate;
class JSONArray;

class CodeCoverage : public AllStatic {
 public:
  static void Print(Isolate* isolate);

 private:
  static void PrintClass(const Class& cls, const JSONArray& arr);
};

}  // namespace dart

#endif  // VM_COVERAGE_H_
