// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/deferred_objects.h"

#include "vm/deopt_instructions.h"
#include "vm/flags.h"
#include "vm/object.h"

namespace dart {

DECLARE_FLAG(bool, trace_deoptimization_verbose);


void DeferredDouble::Materialize() {
  RawDouble** double_slot = reinterpret_cast<RawDouble**>(slot());
  *double_slot = Double::New(value());

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing double at %" Px ": %g\n",
                 reinterpret_cast<uword>(slot()), value());
  }
}


void DeferredMint::Materialize() {
  RawMint** mint_slot = reinterpret_cast<RawMint**>(slot());
  ASSERT(!Smi::IsValid64(value()));
  Mint& mint = Mint::Handle();
  mint ^= Integer::New(value());
  *mint_slot = mint.raw();

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing mint at %" Px ": %" Pd64 "\n",
                 reinterpret_cast<uword>(slot()), value());
  }
}


void DeferredFloat32x4::Materialize() {
  RawFloat32x4** float32x4_slot = reinterpret_cast<RawFloat32x4**>(slot());
  RawFloat32x4* raw_float32x4 = Float32x4::New(value());
  *float32x4_slot = raw_float32x4;

  if (FLAG_trace_deoptimization_verbose) {
    float x = raw_float32x4->x();
    float y = raw_float32x4->y();
    float z = raw_float32x4->z();
    float w = raw_float32x4->w();
    OS::PrintErr("materializing Float32x4 at %" Px ": %g,%g,%g,%g\n",
                 reinterpret_cast<uword>(slot()), x, y, z, w);
  }
}


void DeferredInt32x4::Materialize() {
  RawInt32x4** int32x4_slot = reinterpret_cast<RawInt32x4**>(slot());
  RawInt32x4* raw_int32x4 = Int32x4::New(value());
  *int32x4_slot = raw_int32x4;

  if (FLAG_trace_deoptimization_verbose) {
    uint32_t x = raw_int32x4->x();
    uint32_t y = raw_int32x4->y();
    uint32_t z = raw_int32x4->z();
    uint32_t w = raw_int32x4->w();
    OS::PrintErr("materializing Int32x4 at %" Px ": %x,%x,%x,%x\n",
                 reinterpret_cast<uword>(slot()), x, y, z, w);
  }
}


void DeferredObjectRef::Materialize() {
  // TODO(turnidge): Consider passing the deopt_context to materialize
  // instead of accessing it through the current isolate.  It would
  // make it easier to test deferred object materialization in a unit
  // test eventually.
  DeferredObject* obj =
      Isolate::Current()->deopt_context()->GetDeferredObject(index());
  *slot() = obj->object();
  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("writing instance ref at %" Px ": %s\n",
                 reinterpret_cast<uword>(slot()),
                 Instance::Handle(obj->object()).ToCString());
  }
}


RawInstance* DeferredObject::object() {
  if (object_ == NULL) {
    Materialize();
  }
  return object_->raw();
}


void DeferredObject::Materialize() {
  Class& cls = Class::Handle();
  cls ^= GetClass();

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing instance of %s (%" Px ", %" Pd " fields)\n",
                 cls.ToCString(),
                 reinterpret_cast<uword>(args_),
                 field_count_);
  }

  const Instance& obj = Instance::ZoneHandle(Instance::New(cls));

  Field& field = Field::Handle();
  Object& value = Object::Handle();
  for (intptr_t i = 0; i < field_count_; i++) {
    field ^= GetField(i);
    value = GetValue(i);
    obj.SetField(field, value);

    if (FLAG_trace_deoptimization_verbose) {
      OS::PrintErr("    %s <- %s\n",
                   String::Handle(field.name()).ToCString(),
                   value.ToCString());
    }
  }

  object_ = &obj;
}

}  // namespace dart
