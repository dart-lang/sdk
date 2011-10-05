// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/ic_stubs.h"

#include "vm/object.h"

namespace dart {

RawCode* ICStubs::GetICStub(const GrowableArray<const Class*>& classes,
                            const GrowableArray<const Function*>& targets) {
  UNIMPLEMENTED();
  return Code::null();
}


bool ICStubs::RecognizeICStub(uword entry_point,
                              GrowableArray<const Class*>* classes,
                              GrowableArray<const Function*>* targets) {
  UNIMPLEMENTED();
  return false;
}

int ICStubs::IndexOfClass(const GrowableArray<const Class*>& classes,
                          const Class& cls) {
  UNIMPLEMENTED();
  return false;
}


void ICStubs::PatchTargets(uword ic_entry_point, uword from, uword to) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
