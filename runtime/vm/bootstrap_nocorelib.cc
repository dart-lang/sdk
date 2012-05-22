// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#include "vm/dart_api_impl.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, print_bootstrap, false, "Print the bootstrap source.");


RawScript* Bootstrap::LoadScript() {
  UNREACHABLE();
  return Script::null();
}


RawScript* Bootstrap::LoadImplScript() {
  UNREACHABLE();
  return Script::null();
}


RawScript* Bootstrap::LoadMathScript() {
  UNREACHABLE();
  return Script::null();
}


RawScript* Bootstrap::LoadIsolateScript() {
  UNREACHABLE();
  return Script::null();
}


RawScript* Bootstrap::LoadMirrorsScript() {
  UNREACHABLE();
  return Script::null();
}


RawError* Bootstrap::Compile(const Library& library, const Script& script) {
  UNREACHABLE();
  return Error::null();
}

}  // namespace dart
