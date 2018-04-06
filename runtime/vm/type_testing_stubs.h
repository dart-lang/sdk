// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TYPE_TESTING_STUBS_H_
#define RUNTIME_VM_TYPE_TESTING_STUBS_H_

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il.h"

namespace dart {

class TypeTestingStubGenerator {
 public:
  // During bootstrapping it will return `null` for a whitelisted set of types,
  // otherwise it will return a default stub which tail-calls
  // subtypingtest/runtime code.
  static RawInstructions* DefaultCodeForType(const AbstractType& type);
};

class TypeTestingStubFinder {
 public:
  TypeTestingStubFinder();

  // When serializing an AOT snapshot via our clustered snapshot writer, we
  // write out references to the [Instructions] object for all the
  // [AbstractType] objects we encounter.
  //
  // This method is used for this mapping of stub entrypoint addresses to the
  // corresponding [Instructions] object.
  RawInstructions* LookupByAddresss(uword entry_point) const;

  // When generating an AOT snapshot as an assembly file (i.e. ".S" file) we
  // need to generate labels for the type testing stubs.
  //
  // This method maps stub entrypoint addresses to meaningful names.
  const char* StubNameFromAddresss(uword entry_point) const;

 private:
  Code& code_;
};

}  // namespace dart

#endif  // RUNTIME_VM_TYPE_TESTING_STUBS_H_
