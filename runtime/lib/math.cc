// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <ctype.h>  // isspace.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Random_initialSeed, 0, 0) {
  return Integer::New(thread->random()->NextUInt64());
}

DEFINE_NATIVE_ENTRY(SecureRandom_getBytes, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, count, arguments->NativeArgAt(0));
  const intptr_t n = count.Value();
  ASSERT((n > 0) && (n <= 8));
  uint8_t buffer[8];
  Dart_EntropySource entropy_source = Dart::entropy_source_callback();
  if ((entropy_source == nullptr) || !entropy_source(buffer, n)) {
    const String& error = String::Handle(String::New(
        "No source of cryptographically secure random numbers available."));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
  }
  uint64_t result = 0;
  for (intptr_t i = 0; i < n; i++) {
    result = (result << 8) | buffer[i];
  }
  return Integer::New(result);
}

}  // namespace dart
