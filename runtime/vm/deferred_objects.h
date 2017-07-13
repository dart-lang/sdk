// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DEFERRED_OBJECTS_H_
#define RUNTIME_VM_DEFERRED_OBJECTS_H_

#include "platform/globals.h"

namespace dart {

// Forward declarations.
class Object;
class RawObject;
class RawObject;
class DeoptContext;

// Used by the deoptimization infrastructure to defer allocation of
// unboxed objects until frame is fully rewritten and GC is safe.
// Describes a stack slot that should be populated with a reference to
// the materialized object.
class DeferredSlot {
 public:
  DeferredSlot(RawObject** slot, DeferredSlot* next)
      : slot_(slot), next_(next) {}
  virtual ~DeferredSlot() {}

  RawObject** slot() const { return slot_; }
  DeferredSlot* next() const { return next_; }

  virtual void Materialize(DeoptContext* deopt_context) = 0;

 private:
  RawObject** const slot_;
  DeferredSlot* const next_;

  DISALLOW_COPY_AND_ASSIGN(DeferredSlot);
};

class DeferredDouble : public DeferredSlot {
 public:
  DeferredDouble(double value, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) {}

  virtual void Materialize(DeoptContext* deopt_context);

  double value() const { return value_; }

 private:
  const double value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredDouble);
};

class DeferredMint : public DeferredSlot {
 public:
  DeferredMint(int64_t value, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) {}

  virtual void Materialize(DeoptContext* deopt_context);

  int64_t value() const { return value_; }

 private:
  const int64_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredMint);
};

class DeferredFloat32x4 : public DeferredSlot {
 public:
  DeferredFloat32x4(simd128_value_t value, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) {}

  virtual void Materialize(DeoptContext* deopt_context);

  simd128_value_t value() const { return value_; }

 private:
  const simd128_value_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredFloat32x4);
};

class DeferredFloat64x2 : public DeferredSlot {
 public:
  DeferredFloat64x2(simd128_value_t value, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) {}

  virtual void Materialize(DeoptContext* deopt_context);

  simd128_value_t value() const { return value_; }

 private:
  const simd128_value_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredFloat64x2);
};

class DeferredInt32x4 : public DeferredSlot {
 public:
  DeferredInt32x4(simd128_value_t value, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), value_(value) {}

  virtual void Materialize(DeoptContext* deopt_context);

  simd128_value_t value() const { return value_; }

 private:
  const simd128_value_t value_;

  DISALLOW_COPY_AND_ASSIGN(DeferredInt32x4);
};

// Describes a slot that contains a reference to an object that had its
// allocation removed by AllocationSinking pass.
// Object itself is described and materialized by DeferredObject.
class DeferredObjectRef : public DeferredSlot {
 public:
  DeferredObjectRef(intptr_t index, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), index_(index) {}

  virtual void Materialize(DeoptContext* deopt_context);

  intptr_t index() const { return index_; }

 private:
  const intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(DeferredObjectRef);
};

class DeferredRetAddr : public DeferredSlot {
 public:
  DeferredRetAddr(intptr_t index,
                  intptr_t deopt_id,
                  RawObject** slot,
                  DeferredSlot* next)
      : DeferredSlot(slot, next), index_(index), deopt_id_(deopt_id) {}

  virtual void Materialize(DeoptContext* deopt_context);

  intptr_t index() const { return index_; }

 private:
  const intptr_t index_;
  const intptr_t deopt_id_;

  DISALLOW_COPY_AND_ASSIGN(DeferredRetAddr);
};

class DeferredPcMarker : public DeferredSlot {
 public:
  DeferredPcMarker(intptr_t index, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), index_(index) {}

  virtual void Materialize(DeoptContext* deopt_context);

  intptr_t index() const { return index_; }

 private:
  const intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(DeferredPcMarker);
};

class DeferredPp : public DeferredSlot {
 public:
  DeferredPp(intptr_t index, RawObject** slot, DeferredSlot* next)
      : DeferredSlot(slot, next), index_(index) {}

  virtual void Materialize(DeoptContext* deopt_context);

  intptr_t index() const { return index_; }

 private:
  const intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(DeferredPp);
};

// Describes an object which allocation was removed by AllocationSinking pass.
// Arguments for materialization are stored as a part of expression stack
// for the bottommost deoptimized frame so that GC could discover them.
// They will be removed from the stack at the very end of deoptimization.
class DeferredObject {
 public:
  DeferredObject(intptr_t field_count, intptr_t* args)
      : field_count_(field_count),
        args_(reinterpret_cast<RawObject**>(args)),
        object_(NULL) {}

  intptr_t ArgumentCount() const {
    return kFieldsStartIndex + kFieldEntrySize * field_count_;
  }

  RawObject* object();

  // Fill object with actual field values.
  void Fill();

 private:
  enum {
    kClassIndex = 0,
    kLengthIndex,  // Number of context variables for contexts, -1 otherwise.
    kFieldsStartIndex
  };

  enum {
    kOffsetIndex = 0,
    kValueIndex,
    kFieldEntrySize,
  };

  // Allocate the object but keep its fields null-initialized. Actual field
  // values will be filled later by the Fill method. This separation between
  // allocation and filling is needed because dematerialized objects form
  // a graph which can contain cycles.
  void Create();

  RawObject* GetArg(intptr_t index) const {
#if !defined(TARGET_ARCH_DBC)
    return args_[index];
#else
    return args_[-index];
#endif
  }

  RawObject* GetClass() const { return GetArg(kClassIndex); }

  RawObject* GetLength() const { return GetArg(kLengthIndex); }

  RawObject* GetFieldOffset(intptr_t index) const {
    return GetArg(kFieldsStartIndex + kFieldEntrySize * index + kOffsetIndex);
  }

  RawObject* GetValue(intptr_t index) const {
    return GetArg(kFieldsStartIndex + kFieldEntrySize * index + kValueIndex);
  }

  // Amount of fields that have to be initialized.
  const intptr_t field_count_;

  // Pointer to the first materialization argument on the stack.
  // The first argument is Class of the instance to materialize followed by
  // Field, value pairs.
  RawObject** args_;

  // Object materialized from this description.
  const Object* object_;

  DISALLOW_COPY_AND_ASSIGN(DeferredObject);
};

}  // namespace dart

#endif  // RUNTIME_VM_DEFERRED_OBJECTS_H_
