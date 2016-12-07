// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SPACES_H_
#define RUNTIME_VM_SPACES_H_

// This file contains utilities shared by old and new space.
// TODO(koda): Create Space base class with Space::CurrentUsage().

namespace dart {

// Usage statistics for a space/generation at a particular moment in time.
struct SpaceUsage {
  SpaceUsage() : capacity_in_words(0), used_in_words(0), external_in_words(0) {}
  intptr_t capacity_in_words;
  intptr_t used_in_words;
  intptr_t external_in_words;
};

}  // namespace dart

#endif  // RUNTIME_VM_SPACES_H_
