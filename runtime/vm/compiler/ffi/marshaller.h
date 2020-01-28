// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_
#define RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_

#include <platform/globals.h>

#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/object.h"

namespace dart {

namespace compiler {

namespace ffi {

// This classes translates the ABI location of arguments into the locations they
// will inhabit after entry-frame setup in the invocation of a native callback.
//
// Native -> Dart callbacks must push all the arguments before executing any
// Dart code because the reading the Thread from TLS requires calling a native
// stub, and the argument registers are volatile on all ABIs we support.
//
// To avoid complicating initial definitions, all callback arguments are read
// off the stack from their pushed locations, so this class updates the argument
// positions to account for this.
//
// See 'NativeEntryInstr::EmitNativeCode' for details.
class CallbackArgumentTranslator : public ValueObject {
 public:
  static ZoneGrowableArray<Location>* TranslateArgumentLocations(
      const ZoneGrowableArray<Location>& arg_locs);

 private:
  void AllocateArgument(Location arg);
  Location TranslateArgument(Location arg);

  intptr_t argument_slots_used_ = 0;
  intptr_t argument_slots_required_ = 0;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_
