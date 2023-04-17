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
  DoublePtr* double_slot = reinterpret_cast<DoublePtr*>(slot());
  *double_slot = Double::New(value());

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing double at %" Px ": %g\n",
                 reinterpret_cast<uword>(slot()), value());
  }
}

void DeferredMint::Materialize(DeoptContext* deopt_context) {
  MintPtr* mint_slot = reinterpret_cast<MintPtr*>(slot());
  ASSERT(!Smi::IsValid(value()));
  Mint& mint = Mint::Handle();
  mint ^= Integer::New(value());
  *mint_slot = mint.ptr();

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing mint at %" Px ": %" Pd64 "\n",
                 reinterpret_cast<uword>(slot()), value());
  }
}

void DeferredFloat32x4::Materialize(DeoptContext* deopt_context) {
  Float32x4Ptr* float32x4_slot = reinterpret_cast<Float32x4Ptr*>(slot());
  Float32x4Ptr raw_float32x4 = Float32x4::New(value());
  *float32x4_slot = raw_float32x4;

  if (FLAG_trace_deoptimization_verbose) {
    float x = raw_float32x4->untag()->x();
    float y = raw_float32x4->untag()->y();
    float z = raw_float32x4->untag()->z();
    float w = raw_float32x4->untag()->w();
    OS::PrintErr("materializing Float32x4 at %" Px ": %g,%g,%g,%g\n",
                 reinterpret_cast<uword>(slot()), x, y, z, w);
  }
}

void DeferredFloat64x2::Materialize(DeoptContext* deopt_context) {
  Float64x2Ptr* float64x2_slot = reinterpret_cast<Float64x2Ptr*>(slot());
  Float64x2Ptr raw_float64x2 = Float64x2::New(value());
  *float64x2_slot = raw_float64x2;

  if (FLAG_trace_deoptimization_verbose) {
    double x = raw_float64x2->untag()->x();
    double y = raw_float64x2->untag()->y();
    OS::PrintErr("materializing Float64x2 at %" Px ": %g,%g\n",
                 reinterpret_cast<uword>(slot()), x, y);
  }
}

void DeferredInt32x4::Materialize(DeoptContext* deopt_context) {
  Int32x4Ptr* int32x4_slot = reinterpret_cast<Int32x4Ptr*>(slot());
  Int32x4Ptr raw_int32x4 = Int32x4::New(value());
  *int32x4_slot = raw_int32x4;

  if (FLAG_trace_deoptimization_verbose) {
    uint32_t x = raw_int32x4->untag()->x();
    uint32_t y = raw_int32x4->untag()->y();
    uint32_t z = raw_int32x4->untag()->z();
    uint32_t w = raw_int32x4->untag()->w();
    OS::PrintErr("materializing Int32x4 at %" Px ": %x,%x,%x,%x\n",
                 reinterpret_cast<uword>(slot()), x, y, z, w);
  }
}

void DeferredObjectRef::Materialize(DeoptContext* deopt_context) {
  DeferredObject* obj = deopt_context->GetDeferredObject(index());
  *slot() = obj->object();
  if (FLAG_trace_deoptimization_verbose) {
    const Class& cls = Class::Handle(IsolateGroup::Current()->class_table()->At(
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

  uword continue_at_pc =
      code.GetPcForDeoptId(deopt_id_, UntaggedPcDescriptors::kDeopt);
  if (continue_at_pc == 0) {
    FATAL("Can't locate continuation PC for deoptid %" Pd " within %s\n",
          deopt_id_, function.ToFullyQualifiedCString());
  }
  uword* dest_addr = reinterpret_cast<uword*>(slot());
  *dest_addr = continue_at_pc;

  if (FLAG_trace_deoptimization_verbose) {
    OS::PrintErr("materializing return addr at 0x%" Px ": 0x%" Px "\n",
                 reinterpret_cast<uword>(slot()), continue_at_pc);
  }

  uword pc = code.GetPcForDeoptId(deopt_id_, UntaggedPcDescriptors::kIcCall);
  if (pc != 0) {
    // If the deoptimization happened at an IC call, update the IC data
    // to avoid repeated deoptimization at the same site next time around.
    // We cannot use CodePatcher::GetInstanceCallAt because the call site
    // may have switched to from referencing an ICData to a target Code or
    // MegamorphicCache.
    ICData& ic_data = ICData::Handle(zone, function.FindICData(deopt_id_));
    ic_data.AddDeoptReason(deopt_context->deopt_reason());
    // Propagate the reason to all ICData-s with same deopt_id since
    // only unoptimized-code ICData (IC calls) are propagated.
    function.SetDeoptReasonForAll(ic_data.deopt_id(),
                                  deopt_context->deopt_reason());
  } else {
    if (deopt_context->HasDeoptFlag(ICData::kHoisted)) {
      // Prevent excessive deoptimization.
      function.SetProhibitsInstructionHoisting(true);
    }

    if (deopt_context->HasDeoptFlag(ICData::kGeneralized)) {
      function.SetProhibitsBoundsCheckGeneralization(true);
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
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& code = Code::Handle(zone, function.unoptimized_code());
  ASSERT(!code.IsNull());
  ASSERT(function.HasCode());
  *reinterpret_cast<ObjectPtr*>(dest_addr) = code.ptr();

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
  function.SetUsageCounter(0);
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
                 static_cast<uword>(code.GetObjectPool()));
  }
}

ObjectPtr DeferredObject::object() {
  if (object_ == nullptr) {
    Create();
  }
  return object_->ptr();
}

void DeferredObject::Create() {
  if (object_ != nullptr) {
    return;
  }

  Class& cls = Class::Handle();
  cls ^= GetClass();

  switch (cls.id()) {
    case kContextCid: {
      const intptr_t num_variables =
          Smi::Cast(Object::Handle(GetLengthOrShape())).Value();
      if (FLAG_trace_deoptimization_verbose) {
        OS::PrintErr(
            "materializing context of length %" Pd " (%" Px ", %" Pd " vars)\n",
            num_variables, reinterpret_cast<uword>(args_), field_count_);
      }
      object_ = &Context::ZoneHandle(Context::New(num_variables));
    } break;
    case kArrayCid: {
      const intptr_t num_elements =
          Smi::Cast(Object::Handle(GetLengthOrShape())).Value();
      if (FLAG_trace_deoptimization_verbose) {
        OS::PrintErr("materializing array of length %" Pd " (%" Px ", %" Pd
                     " elements)\n",
                     num_elements, reinterpret_cast<uword>(args_),
                     field_count_);
      }
      object_ = &Array::ZoneHandle(Array::New(num_elements));
    } break;
    case kRecordCid: {
      const RecordShape shape(Smi::RawCast(GetLengthOrShape()));
      if (FLAG_trace_deoptimization_verbose) {
        OS::PrintErr(
            "materializing record of shape %" Px " (%" Px ", %" Pd " fields)\n",
            shape.AsInt(), reinterpret_cast<uword>(args_), field_count_);
      }
      object_ = &Record::ZoneHandle(Record::New(shape));
    } break;
    default:
      if (IsTypedDataClassId(cls.id())) {
        const intptr_t num_elements =
            Smi::Cast(Object::Handle(GetLengthOrShape())).Value();
        if (FLAG_trace_deoptimization_verbose) {
          OS::PrintErr("materializing typed data cid %" Pd " of length %" Pd
                       " (%" Px ", %" Pd " elements)\n",
                       cls.id(), num_elements, reinterpret_cast<uword>(args_),
                       field_count_);
        }
        object_ =
            &TypedData::ZoneHandle(TypedData::New(cls.id(), num_elements));

      } else {
        if (FLAG_trace_deoptimization_verbose) {
          OS::PrintErr(
              "materializing instance of %s (%" Px ", %" Pd " fields)\n",
              cls.ToCString(), reinterpret_cast<uword>(args_), field_count_);
        }

        object_ = &Instance::ZoneHandle(Instance::New(cls));
      }
  }
}

static intptr_t ToContextIndex(intptr_t offset_in_bytes) {
  intptr_t result = (offset_in_bytes - Context::variable_offset(0)) /
                    Context::kBytesPerElement;
  ASSERT(result >= 0);
  return result;
}

void DeferredObject::Fill() {
  Create();  // Ensure instance is created.

  Class& cls = Class::Handle();
  cls ^= GetClass();

  switch (cls.id()) {
    case kContextCid: {
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
                         offset.Value(), parent.ToCString());
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
    } break;
    case kArrayCid: {
      const Array& array = Array::Cast(*object_);

      Smi& offset = Smi::Handle();
      Object& value = Object::Handle();

      for (intptr_t i = 0; i < field_count_; i++) {
        offset ^= GetFieldOffset(i);
        if (offset.Value() == Array::type_arguments_offset()) {
          TypeArguments& type_args = TypeArguments::Handle();
          type_args ^= GetValue(i);
          array.SetTypeArguments(type_args);
          if (FLAG_trace_deoptimization_verbose) {
            OS::PrintErr("    array@type_args (offset %" Pd ") <- %s\n",
                         offset.Value(), type_args.ToCString());
          }
        } else {
          const intptr_t index = Array::index_at_offset(offset.Value());
          value = GetValue(i);
          array.SetAt(index, value);
          if (FLAG_trace_deoptimization_verbose) {
            OS::PrintErr("    array@%" Pd " (offset %" Pd ") <- %s\n", index,
                         offset.Value(), value.ToCString());
          }
        }
      }
    } break;
    case kRecordCid: {
      const Record& record = Record::Cast(*object_);

      Smi& offset = Smi::Handle();
      Object& value = Object::Handle();

      for (intptr_t i = 0; i < field_count_; i++) {
        offset ^= GetFieldOffset(i);
        const intptr_t index = Record::field_index_at_offset(offset.Value());
        value = GetValue(i);
        record.SetFieldAt(index, value);
        if (FLAG_trace_deoptimization_verbose) {
          OS::PrintErr("    record@%" Pd " (offset %" Pd ") <- %s\n", index,
                       offset.Value(), value.ToCString());
        }
      }
    } break;
    default:
      if (IsTypedDataClassId(cls.id())) {
        const TypedData& typed_data = TypedData::Cast(*object_);

        Smi& offset = Smi::Handle();
        Object& value = Object::Handle();
        const auto cid = cls.id();

        for (intptr_t i = 0; i < field_count_; i++) {
          offset ^= GetFieldOffset(i);
          const intptr_t element_offset = offset.Value();
          value = GetValue(i);
          switch (cid) {
            case kTypedDataInt8ArrayCid:
              typed_data.SetInt8(
                  element_offset,
                  static_cast<int8_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataUint8ArrayCid:
            case kTypedDataUint8ClampedArrayCid:
              typed_data.SetUint8(
                  element_offset,
                  static_cast<uint8_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataInt16ArrayCid:
              typed_data.SetInt16(
                  element_offset,
                  static_cast<int16_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataUint16ArrayCid:
              typed_data.SetUint16(
                  element_offset,
                  static_cast<uint16_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataInt32ArrayCid:
              typed_data.SetInt32(
                  element_offset,
                  static_cast<int32_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataUint32ArrayCid:
              typed_data.SetUint32(
                  element_offset,
                  static_cast<uint32_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataInt64ArrayCid:
              typed_data.SetInt64(element_offset,
                                  Integer::Cast(value).AsInt64Value());
              break;
            case kTypedDataUint64ArrayCid:
              typed_data.SetUint64(
                  element_offset,
                  static_cast<uint64_t>(Integer::Cast(value).AsInt64Value()));
              break;
            case kTypedDataFloat32ArrayCid:
              // Although element of Float32 array is represented with Double,
              // it is already converted to 32-bit float via DoubleToFloat
              // instruction before it was stored.
              // Reinterpret double value as float to get the value back.
              typed_data.SetFloat32(
                  element_offset,
                  bit_cast<float, uint32_t>(
                      static_cast<uint32_t>(bit_cast<uint64_t, double>(
                          Double::Cast(value).value()))));
              break;
            case kTypedDataFloat64ArrayCid:
              typed_data.SetFloat64(element_offset,
                                    Double::Cast(value).value());
              break;
            case kTypedDataFloat32x4ArrayCid:
              typed_data.SetFloat32x4(element_offset,
                                      Float32x4::Cast(value).value());
              break;
            case kTypedDataInt32x4ArrayCid:
              typed_data.SetInt32x4(element_offset,
                                    Int32x4::Cast(value).value());
              break;
            case kTypedDataFloat64x2ArrayCid:
              typed_data.SetFloat64x2(element_offset,
                                      Float64x2::Cast(value).value());
              break;
            default:
              UNREACHABLE();
          }
          if (FLAG_trace_deoptimization_verbose) {
            OS::PrintErr("    typed_data (offset %" Pd ") <- %s\n",
                         element_offset, value.ToCString());
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
          field ^= offset_map.At(offset.Value() / kCompressedWordSize);
          value = GetValue(i);
          ASSERT((value.ptr() != Object::sentinel().ptr()) ||
                 (!field.IsNull() && field.is_late()));
          if (!field.IsNull() && (value.ptr() != Object::sentinel().ptr())) {
            obj.SetField(field, value);
            if (FLAG_trace_deoptimization_verbose) {
              OS::PrintErr("    %s <- %s\n",
                           String::Handle(field.name()).ToCString(),
                           value.ToCString());
            }
          } else {
            // In addition to the type arguments vector we can also have lazy
            // materialization of e.g. _ByteDataView objects which don't have
            // explicit fields in Dart (all accesses to the fields are done via
            // recognized native methods).
            ASSERT(offset.Value() < cls.host_instance_size());
            obj.SetFieldAtOffset(offset.Value(), value);
            if (FLAG_trace_deoptimization_verbose) {
              OS::PrintErr(
                  "    %s @ offset(%" Pd ") <- %s\n",
                  (field.IsNull() ? "null Field"
                                  : String::Handle(field.name()).ToCString()),
                  offset.Value(), value.ToCString());
            }
          }
        }
      }
      break;
  }
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
