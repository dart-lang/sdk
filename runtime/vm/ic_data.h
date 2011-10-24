// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for handling inline cache stubs

// The caller of an instance function passes the IC-data array in a specific
// register (ECX on ia32).
// That array contains information relevant for the call site: function name and
// inline cache data. Class ICData is a wrapper around that array.
// The array format is:
// 0: function-name
// 1: N, number of arguments checked.
// 2 .. (length - 1): group of checks, each check containing:
//   - N classes.
//   - 1 target function.
// Whenever first N arguments of an instance call have the same class as the
// check, jump to the target function.
// Array is null terminated (all classes and target are null objects).
// The array does not contain Null-Classes. Null objects cannot be added.

#ifndef VM_IC_DATA_H_
#define VM_IC_DATA_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

class Array;
class Class;
class Function;
class String;
class RawArray;
class RawString;

class ICData : public ValueObject {
 public:
  // Wrap IC data around 'array'.
  explicit ICData(const Array& array);

  // Create a new array with zero checks.
  ICData(const String& function_name, intptr_t num_args_checked);

  RawArray* data() const;

  RawString* FunctionName() const;

  intptr_t NumberOfArgumentsChecked() const;
  intptr_t NumberOfChecks() const;

  // Also updates the instance call at 'return_address_'.
  void AddCheck(const GrowableArray<const Class*>& classes,
                const Function& target);

  void SetCheckAt(intptr_t index,
                  const GrowableArray<const Class*>& classes,
                  const Function& target);

  void GetCheckAt(intptr_t index,
                  GrowableArray<const Class*>* classes,
                  Function* target) const;

  static const int kNameIndex = 0;

 private:
  intptr_t ArrayElementsPerCheck() const;

  const Array* data_;

  static const int kNumArgsCheckedIndex = 1;
  static const int kChecksStartIndex = 2;

  DISALLOW_COPY_AND_ASSIGN(ICData);
};

}  // namespace dart

#endif  // VM_IC_DATA_H_
