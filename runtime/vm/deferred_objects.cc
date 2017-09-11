// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/deferred_objects.h"

#include "vm/code_patcher.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/deopt_instructions.h"
#include "vm/flags.h"
#include "vm/object.h"

namespace dart {

DECLARE_FLAG(bool, trace_deoptimization);
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
                 cls.ToCString(), reinterpret_cast<uword>(slot()));
  }
}

void DeferredRetAddr::Materialize(DeoptContext* deopt_context) {
  Thread* thread = deopt_context->thread();
  Zone* zone = deopt_context->zone();
  Function& function = Function::Handle(zone);
  function ^= deopt_context->ObjectAt(index_);
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& code = Code::Handle(zone, function.unoptimized_code());
// Check that deopt_id exists.
// TODO(vegorov): verify after deoptimization targets as well.
#ifdef DEBUG
  ASSERT(Thread::IsDeoptAfter(deopt_id_) ||
         (code.GetPcForDeoptId(deopt_id_, RawPcDescriptors::kDeopt) != 0));
#endif

  uword continue_at_pc =
      code.GetPcForDeoptId(deopt_id_, RawPcDescriptors::kDeopt);
  ASSERT(continue_at_pc != 0);
  uword* dest_addr = reinterpret_cast<uword*>(slot());
  *dest_addr = continue_at_pc;

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing return addr at 0x%" Px ": 0x%" Px "\n",
                 reinterpret_cast<uword>(slot()), continue_at_pc);
  }

  uword pc = code.GetPcForDeoptId(deopt_id_, RawPcDescriptors::kIcCall);
  if (pc != 0) {
    // If the deoptimization happened at an IC call, update the IC data
    // to avoid repeated deoptimization at the same site next time around.
    ICData& ic_data = ICData::Handle(zone);
    CodePatcher::GetInstanceCallAt(pc, code, &ic_data);
    if (!ic_data.IsNull()) {
      ic_data.AddDeoptReason(deopt_context->deopt_reason());
      // Propagate the reason to all ICData-s with same deopt_id since
      // only unoptimized-code ICData (IC calls) are propagated.
      function.SetDeoptReasonForAll(ic_data.deopt_id(),
                                    deopt_context->deopt_reason());
    }
  } else {
    if (deopt_context->HasDeoptFlag(ICData::kHoisted)) {
      // Prevent excessive deoptimization.
      function.set_allows_hoisting_check_class(false);
    }

    if (deopt_context->HasDeoptFlag(ICData::kGeneralized)) {
      function.set_allows_bounds_check_generalization(false);
    }
  }
}

void DeferredPcMarker::Materialize(DeoptContext* deopt_context) {
  Thread* thread = deopt_context->thread();
  Zone* zone = deopt_context->zone();
  uword* dest_addr = reinterpret_cast<uword*>(slot());
  Function& function = Function::Handle(zone);
  function ^= deopt_context->ObjectAt(index_);
  ASSERT(!function.IsNull());
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& code = Code::Handle(zone, function.unoptimized_code());
  ASSERT(!code.IsNull());
  ASSERT(function.HasCode());
  *reinterpret_cast<RawObject**>(dest_addr) = code.raw();

  if (FLAG_trace_deoptimization_verbose) {
    THR_Print("materializing pc marker at 0x%" Px ": %s, %s\n",
              reinterpret_cast<uword>(slot()), code.ToCString(),
              function.ToCString());
  }

  // Increment the deoptimization counter. This effectively increments each
  // function occurring in the optimized frame.
  if (deopt_context->deoptimizing_code()) {
    function.set_deoptimization_counter(function.deoptimization_counter() + 1);
  }
  if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
    THR_Print("Deoptimizing '%s' (count %d)\n",
              function.ToFullyQualifiedCString(),
              function.deoptimization_counter());
  }
  // Clear invocation counter so that hopefully the function gets reoptimized
  // only after more feedback has been collected.
  function.set_usage_counter(0);
  if (function.HasOptimizedCode()) {
    function.SwitchToUnoptimizedCode();
  }
}

void DeferredPp::Materialize(DeoptContext* deopt_context) {
  Thread* thread = deopt_context->thread();
  Zone* zone = deopt_context->zone();
  Function& function = Function::Handle(zone);
  function ^= deopt_context->ObjectAt(index_);
  ASSERT(!function.IsNull());
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& code = Code::Handle(zone, function.unoptimized_code());
  ASSERT(!code.IsNull());
  ASSERT(code.GetObjectPool() != Object::null());
  *slot() = code.GetObjectPool();

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing pp at 0x%" Px ": 0x%" Px "\n",
                 reinterpret_cast<uword>(slot()),
                 reinterpret_cast<uword>(code.GetObjectPool()));
  }
}

RawObject* DeferredObject::object() {
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

  if (cls.raw() == Object::context_class()) {
    intptr_t num_variables = Smi::Cast(Object::Handle(GetLength())).Value();
    if (FLAG_trace_deoptimization_verbose) {
      OS::PrintErr("materializing context of length %" Pd " (%" Px ", %" Pd
                   " vars)\n",
                   num_variables, reinterpret_cast<uword>(args_), field_count_);
    }
    object_ = &Context::ZoneHandle(Context::New(num_variables));

  } else {
    if (FLAG_trace_deoptimization_verbose) {
      OS::PrintErr("materializing instance of %s (%" Px ", %" Pd " fields)\n",
                   cls.ToCString(), reinterpret_cast<uword>(args_),
                   field_count_);
    }

    object_ = &Instance::ZoneHandle(Instance::New(cls));
  }
}

static intptr_t ToContextIndex(intptr_t offset_in_bytes) {
  intptr_t result = (offset_in_bytes - Context::variable_offset(0)) / kWordSize;
  ASSERT(result >= 0);
  return result;
}

void DeferredObject::Fill() {
  Create();  // Ensure instance is created.

  Class& cls = Class::Handle();
  cls ^= GetClass();

  if (cls.raw() == Object::context_class()) {
    const Context& context = Context::Cast(*object_);

    Smi& offset = Smi::Handle();
    Object& value = Object::Handle();

    for (intptr_t i = 0; i < field_count_; i++) {
      offset ^= GetFieldOffset(i);
      if (offset.Value() == Context::parent_offset()) {
        // Copy parent.
        Context& parent = Context::Handle();
        parent ^= GetValue(i);
        context.set_parent(parent);
        if (FLAG_trace_deoptimization_verbose) {
          OS::PrintErr("    ctx@parent (offset %" Pd ") <- %s\n",
                       offset.Value(), value.ToCString());
        }
      } else {
        intptr_t context_index = ToContextIndex(offset.Value());
        value = GetValue(i);
        context.SetAt(context_index, value);
        if (FLAG_trace_deoptimization_verbose) {
          OS::PrintErr("    ctx@%" Pd " (offset %" Pd ") <- %s\n",
                       context_index, offset.Value(), value.ToCString());
        }
      }
    }
  } else {
    const Instance& obj = Instance::Cast(*object_);

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
        ASSERT(offset.Value() == cls.type_arguments_field_offset());
        obj.SetFieldAtOffset(offset.Value(), value);
        if (FLAG_trace_deoptimization_verbose) {
          OS::PrintErr("    null Field @ offset(%" Pd ") <- %s\n",
                       offset.Value(), value.ToCString());
        }
      }
    }
  }
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
