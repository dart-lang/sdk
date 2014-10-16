// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/deferred_objects.h"

#include "vm/deopt_instructions.h"
#include "vm/flags.h"
#include "vm/object.h"

namespace dart {

DECLARE_FLAG(bool, trace_deoptimization_verbose);


void DeferredDouble::Materialize(DeoptContext* deopt_context) {
  RawDouble** double_slot = reinterpret_cast<RawDouble**>(slot());
  *double_slot = Double::New(value());

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing double at %" Px ": %g\n",
                 reinterpret_cast<uword>(slot()), value());
  }
}


void DeferredMint::Materialize(DeoptContext* deopt_context) {
  RawMint** mint_slot = reinterpret_cast<RawMint**>(slot());
  ASSERT(!Smi::IsValid(value()));
  Mint& mint = Mint::Handle();
  mint ^= Integer::New(value());
  *mint_slot = mint.raw();

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing mint at %" Px ": %" Pd64 "\n",
                 reinterpret_cast<uword>(slot()), value());
  }
}


void DeferredFloat32x4::Materialize(DeoptContext* deopt_context) {
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


void DeferredFloat64x2::Materialize(DeoptContext* deopt_context) {
  RawFloat64x2** float64x2_slot = reinterpret_cast<RawFloat64x2**>(slot());
  RawFloat64x2* raw_float64x2 = Float64x2::New(value());
  *float64x2_slot = raw_float64x2;

  if (FLAG_trace_deoptimization_verbose) {
    double x = raw_float64x2->x();
    double y = raw_float64x2->y();
    OS::PrintErr("materializing Float64x2 at %" Px ": %g,%g\n",
                 reinterpret_cast<uword>(slot()), x, y);
  }
}


void DeferredInt32x4::Materialize(DeoptContext* deopt_context) {
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


void DeferredObjectRef::Materialize(DeoptContext* deopt_context) {
  DeferredObject* obj = deopt_context->GetDeferredObject(index());
  *slot() = obj->object();
  if (FLAG_trace_deoptimization_verbose) {
    const Class& cls = Class::Handle(Isolate::Current()->class_table()->At(
        Object::Handle(obj->object()).GetClassId()));
    OS::PrintErr("writing instance of class %s ref at %" Px ".\n",
                 cls.ToCString(),
                 reinterpret_cast<uword>(slot()));
  }
}


RawInstance* DeferredObject::object() {
  if (object_ == NULL) {
    Create();
  }
  return object_->raw();
}


void DeferredObject::Create() {
  if (object_ != NULL) {
    return;
  }

  Class& cls = Class::Handle();
  cls ^= GetClass();

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing instance of %s (%" Px ", %" Pd " fields)\n",
                 cls.ToCString(),
                 reinterpret_cast<uword>(args_),
                 field_count_);
  }

  object_ = &Instance::ZoneHandle(Instance::New(cls));
}


void DeferredObject::Fill() {
  Create();  // Ensure instance is created.

  Class& cls = Class::Handle();
  cls ^= GetClass();

  const Instance& obj = *object_;

  Smi& offset = Smi::Handle();
  Field& field = Field::Handle();
  Object& value = Object::Handle();
  const Array& offset_map = Array::Handle(cls.OffsetToFieldMap());

  for (intptr_t i = 0; i < field_count_; i++) {
    offset ^= GetFieldOffset(i);
    field ^= offset_map.At(offset.Value() / kWordSize);
    value = GetValue(i);
    if (!field.IsNull()) {
      obj.SetField(field, value);
      if (FLAG_trace_deoptimization_verbose) {
        OS::PrintErr("    %s <- %s\n",
                     String::Handle(field.name()).ToCString(),
                     value.ToCString());
      }
    } else {
      ASSERT(cls.IsSignatureClass() ||
             (offset.Value() == cls.type_arguments_field_offset()));
      obj.SetFieldAtOffset(offset.Value(), value);
      if (FLAG_trace_deoptimization_verbose) {
        OS::PrintErr("    null Field @ offset(%" Pd ") <- %s\n",
                     offset.Value(),
                     value.ToCString());
      }
    }
  }
}

}  // namespace dart
