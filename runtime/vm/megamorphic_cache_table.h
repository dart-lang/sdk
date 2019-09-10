// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_
#define RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_

#include "vm/allocation.h"

namespace dart {

namespace compiler {
class ObjectPoolBuilder;
}

class Array;
class Function;
class Isolate;
class ObjectPointerVisitor;
class RawArray;
class RawFunction;
class RawCode;
class RawMegamorphicCache;
class RawString;
class String;
class Thread;

class MegamorphicCacheTable : public AllStatic {
 public:
  static RawFunction* miss_handler(Isolate* isolate);
  NOT_IN_PRECOMPILED(static void InitMissHandler(Isolate* isolate));

  // Re-initializes the megamorphic miss handler function in the object store.
  //
  // Normally we initialize the megamorphic miss handler during isolate startup.
  // Though if we AOT compile with bare instructions support, we need to
  // re-generate the handler to ensure it uses the common object pool.
  NOT_IN_PRECOMPILED(
      static void ReInitMissHandlerCode(Isolate* isolate,
                                        compiler::ObjectPoolBuilder* wrapper));

  static RawMegamorphicCache* Lookup(Thread* thread,
                                     const String& name,
                                     const Array& descriptor);

  static void PrintSizes(Isolate* isolate);
};

}  // namespace dart

#endif  // RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_
