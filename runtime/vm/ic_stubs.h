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
