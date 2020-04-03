// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_LIB_MIRRORS_H_
#define RUNTIME_LIB_MIRRORS_H_

#include "vm/allocation.h"

namespace dart {

class Mirrors : public AllStatic {
 public:
#define MIRRORS_KIND_SHIFT_LIST(V)                                             \
  V(kAbstract)                                                                 \
  V(kGetter)                                                                   \
  V(kSetter)                                                                   \
  V(kConstructor)                                                              \
  V(kConstCtor)                                                                \
  V(kGenerativeCtor)                                                           \
  V(kRedirectingCtor)                                                          \
  V(kFactoryCtor)                                                              \
  V(kExternal)                                                                 \
  V(kSynthetic)                                                                \
  V(kExtensionMember)

  // These offsets much be kept in sync with those in mirrors_impl.dart.
  enum KindShifts {
#define DEFINE_KIND_SHIFT_ENUM(name) name,
    MIRRORS_KIND_SHIFT_LIST(DEFINE_KIND_SHIFT_ENUM)
#undef DEFINE_KIND_SHIFT_ENUM
  };
};

}  // namespace dart

#endif  // RUNTIME_LIB_MIRRORS_H_
