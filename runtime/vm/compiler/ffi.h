// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_H_
#define RUNTIME_VM_COMPILER_FFI_H_

#include <platform/globals.h>

#include "../class_id.h"
#include "../object.h"
#include "../raw_object.h"
#include "backend/locations.h"

namespace dart {

namespace ffi {

// Native data types sizes in bytes

size_t ElementSizeInBytes(intptr_t class_id);

bool ElementIsSigned(intptr_t class_id);

Representation TypeRepresentation(const AbstractType& result_type);

Representation WordRep();

ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature);

ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps);

}  // namespace ffi

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_H_
