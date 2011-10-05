// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debuginfo.h"

namespace dart {

DebugInfo::DebugInfo() {
  handle_ = NULL;
}


DebugInfo::~DebugInfo() {
}


void DebugInfo::AddCode(uword pc, intptr_t size) {
  // Nothing to do as there is no support for this on macos.
}


void DebugInfo::AddCodeRegion(const char* name, uword pc, intptr_t size) {
  // Nothing to do as there is no support for this on macos.
}


bool DebugInfo::WriteToMemory(ByteArray* region) {
  // Nothing to do as there is no support for this on macos.
  return false;
}


DebugInfo* DebugInfo::NewGenerator() {
  return new DebugInfo();
}


void DebugInfo::RegisterSection(const char* name,
                                uword entry_point,
                                intptr_t size) {
  // Nothing to do as there is no support for this on macos.
}


void DebugInfo::UnregisterAllSections() {
  // Nothing to do as there is no support for this on macos.
}

}  // namespace dart
