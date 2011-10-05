// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for handling inline cache stubs
//
// The initial target of an instance call is the resolving and patching runtime
// function 'ResolvePatchInstanceCall'. It resolves and compiles the
// target function and patches the instance call to jump to it
// via an inline cache stub.
// The inline cache stub checks receiver's class for a distinct set of classes
// and jumps to the appropriate target.
// An inline-cache-miss occurs if none of the classes match. As a consequence
// the old IC stub is replaced with a new one that adds the class check
// and target for the most recently seen receiver.

#ifndef VM_IC_STUBS_H_
#define VM_IC_STUBS_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Class;
class Code;
class Function;
class RawCode;

// Class that interprets the array stored in ICData::ic_data_.
// The array format is:
// - number of arguments checked, i.e.,  N number of classes in each check.
// - group of checks, each check containing:
//   - N classes.
//   - 1 target function.
// Whenever first N arguments of a dynamic call have the same class as the
// check, jump to the matching target function.
// Array is terminated with a null group (all classes and target are NULL).
// The array does not contain Null-Classes. Null objects cannot be added.
class ICData : public ValueObject {
 public:
  explicit ICData(const Code& ic_stub);

  intptr_t NumberOfClasses() const;
  intptr_t NumberOfChecks() const;

  // 'index' is 0..NumberOfChecks-1.
  void GetCheckAt(intptr_t index,
                  GrowableArray<const Class*>* classes,
                  Function* target) const;
  void SetCheckAt(intptr_t index,
                  const GrowableArray<const Class*>& classes,
                  const Function& target);

  // Changes all 'from' targets to 'to' targets.
  void ChangeTargets(const Function& from, const Function& to);

  // Create and set an ic_data array in ic_stub_.
  // Use 'SetCheckAt' to populate the array.
  void SetICDataArray(intptr_t num_classes, intptr_t num_checks);

  void AddCheck(const GrowableArray<const Class*>& classes,
                const Function& target);

  void Print();

  // Temporary helper method to check that the existing inline
  // cache information matches the ICData.
  // TODO(srdjan): Remove once transitioned to IC data.
  void CheckIsSame(const GrowableArray<const Class*>* classes,
                   const GrowableArray<const Function*>* targets) const;

 private:
  const Code& ic_stub_;
  DISALLOW_COPY_AND_ASSIGN(ICData);
};


class ICStubs : public AllStatic {
 public:
  // Returns an IC stub that jumps to targets' entry points if the receiver
  // matches a class contained in 'classes' array.
  static RawCode* GetICStub(const GrowableArray<const Class*>& classes,
                            const GrowableArray<const Function*>& targets);

  // Identify classes and their targets contained in the IC stub.
  // 'ic_entry_point' is the start of the IC stubs. 'classes' and 'targets'
  // are the implemented (class, target) tuples.
  // Returns false if the entry_point does not point to an IC stub.
  static bool RecognizeICStub(uword ic_entry_point,
                              GrowableArray<const Class*>* classes,
                              GrowableArray<const Function*>* targets);

  // Replace all 'from' targets with 'to' targets.
  static void PatchTargets(uword ic_entry_point, uword from, uword to);

  // Locate a class within the array. Return -1 if class object in 'cls'
  // is not in the array.
  // TODO(srdjan): Remove from ICStubs interface.
  static int IndexOfClass(const GrowableArray<const Class*>& classes,
                          const Class& cls);

 private:
  static RawCode* FindInCode(const Code& target,
                             const GrowableArray<const Class*>& classes);
  static void AppendICStubToTargets(
      const GrowableArray<const Function*>& targets,
      const GrowableArray<const Class*>& classes,
      const Code& ic_stub);
  static bool ParseICStub(uword ic_entry_point,
                          GrowableArray<const Class*>* classes,
                          GrowableArray<const Function*>* targets,
                          uword from,
                          uword to);
};

}  // namespace dart

#endif  // VM_IC_STUBS_H_
