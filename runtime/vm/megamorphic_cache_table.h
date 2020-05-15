// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_
#define RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_

#include "vm/allocation.h"
#include "vm/tagged_pointer.h"

namespace dart {

class Array;
class Isolate;
class String;
class Thread;

class MegamorphicCacheTable : public AllStatic {
 public:
  static MegamorphicCachePtr Lookup(Thread* thread,
                                    const String& name,
                                    const Array& descriptor);

  static void PrintSizes(Isolate* isolate);
};

}  // namespace dart

#endif  // RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_
