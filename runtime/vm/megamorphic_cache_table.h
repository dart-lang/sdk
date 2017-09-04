// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_
#define RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_

#include "vm/allocation.h"

namespace dart {

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

class MegamorphicCacheTable : public AllStatic {
 public:
  static RawFunction* miss_handler(Isolate* isolate);
  NOT_IN_PRECOMPILED(static void InitMissHandler(Isolate* isolate));

  static RawMegamorphicCache* Lookup(Isolate* isolate,
                                     const String& name,
                                     const Array& descriptor);

  static void PrintSizes(Isolate* isolate);
};

}  // namespace dart

#endif  // RUNTIME_VM_MEGAMORPHIC_CACHE_TABLE_H_
