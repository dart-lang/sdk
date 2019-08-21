// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unicode.h"
#include "vm/bootstrap_natives.h"
#include "vm/dart_entry.h"

namespace dart {

int callWasm(const char* name, int n) {
  return 100 * n;
}

// This is a temporary API for prototyping.
DEFINE_NATIVE_ENTRY(Wasm_callFunction, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, fn_name, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, arg, arguments->NativeArgAt(1));

  intptr_t len = Utf8::Length(fn_name);
  std::unique_ptr<char> name = std::unique_ptr<char>(new char[len + 1]);
  fn_name.ToUTF8(reinterpret_cast<uint8_t*>(name.get()), len);
  name.get()[len] = 0;

  return Smi::New(callWasm(name.get(), arg.AsInt64Value()));
}

}  // namespace dart
