// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"

#include "platform/unaligned.h"
#include "vm/code_patcher.h"
#include "vm/hash_table.h"
#include "vm/isolate_reload.h"
#include "vm/log.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, trace_reload_verbose);
DECLARE_FLAG(bool, two_args_smi_icd);

void CallSiteResetter::ZeroEdgeCounters(const Function& function) {
  ic_data_array_ = function.ic_data_array();
  if (ic_data_array_.IsNull()) {
    return;
  }
  ASSERT(ic_data_array_.Length() > 0);
  edge_counters_ ^= ic_data_array_.At(0);
  if (edge_counters_.IsNull()) {
    return;
  }
  // Fill edge counters array with zeros.
  for (intptr_t i = 0; i < edge_counters_.Length(); i++) {
    edge_counters_.SetAt(i, Object::smi_zero());
  }
}

CallSiteResetter::CallSiteResetter(Zone* zone)
    : zone_(zone),
      instrs_(Instructions::Handle(zone)),
      pool_(ObjectPool::Handle(zone)),
      object_(Object::Handle(zone)),
      name_(String::Handle(zone)),
      new_cls_(Class::Handle(zone)),
      new_lib_(Library::Handle(zone)),
      new_function_(Function::Handle(zone)),
      new_field_(Field::Handle(zone)),
      entries_(Array::Handle(zone)),
      old_target_(Function::Handle(zone)),
      new_target_(Function::Handle(zone)),
      caller_(Function::Handle(zone)),
      args_desc_array_(Array::Handle(zone)),
      ic_data_array_(Array::Handle(zone)),
      edge_counters_(Array::Handle(zone)),
      descriptors_(PcDescriptors::Handle(zone)),
      ic_data_(ICData::Handle(zone)) {}

void CallSiteResetter::ResetCaches(const Code& code) {
  // Iterate over the Code's object pool and reset all ICDatas and
  // SubtypeTestCaches.
#ifdef TARGET_ARCH_IA32
  // IA32 does not have an object pool, but, we can iterate over all
  // embedded objects by using the variable length data section.
  if (!code.is_alive()) {
    return;
  }
  instrs_ = code.instructions();
  ASSERT(!instrs_.IsNull());
  uword base_address = instrs_.PayloadStart();
  intptr_t offsets_length = code.pointer_offsets_length();
  const int32_t* offsets = code.raw_ptr()->data();
  for (intptr_t i = 0; i < offsets_length; i++) {
    int32_t offset = offsets[i];
    ObjectPtr* object_ptr = reinterpret_cast<ObjectPtr*>(base_address + offset);
    ObjectPtr raw_object = LoadUnaligned(object_ptr);
    if (!raw_object->IsHeapObject()) {
      continue;
    }
    object_ = raw_object;
    if (object_.IsICData()) {
      Reset(ICData::Cast(object_));
    } else if (object_.IsSubtypeTestCache()) {
      SubtypeTestCache::Cast(object_).Reset();
    }
  }
#else
  pool_ = code.object_pool();
  ASSERT(!pool_.IsNull());
  ResetCaches(pool_);
#endif
}

static void FindICData(const Array& ic_data_array,
                       intptr_t deopt_id,
                       ICData* ic_data) {
  // ic_data_array is sorted because of how it is constructed in
  // Function::SaveICDataMap.
  intptr_t lo = 1;
  intptr_t hi = ic_data_array.Length() - 1;
  while (lo <= hi) {
    intptr_t mid = (hi - lo + 1) / 2 + lo;
    ASSERT(mid >= lo);
    ASSERT(mid <= hi);
    *ic_data ^= ic_data_array.At(mid);
    if (ic_data->deopt_id() == deopt_id) {
      return;
    } else if (ic_data->deopt_id() > deopt_id) {
      hi = mid - 1;
    } else {
      lo = mid + 1;
    }
  }
  FATAL1("Missing deopt id %" Pd "\n", deopt_id);
}

void CallSiteResetter::ResetSwitchableCalls(const Code& code) {
  if (code.is_optimized()) {
    return;  // No switchable calls in optimized code.
  }

  object_ = code.owner();
  if (!object_.IsFunction()) {
    return;  // No switchable calls in stub code.
  }
  const Function& function = Function::Cast(object_);

  if (function.kind() == FunctionLayout::kIrregexpFunction) {
    // Regex matchers do not support breakpoints or stepping, and they only call
    // core library functions that cannot change due to reload. As a performance
    // optimization, avoid this matching of ICData to PCs for these functions'
    // large number of instance calls.
    ASSERT(!function.is_debuggable());
    return;
  }

  ic_data_array_ = function.ic_data_array();
  if (ic_data_array_.IsNull()) {
    // The megamorphic miss stub and some recognized function doesn't populate
    // their ic_data_array. Check this only happens for functions without IC
    // calls.
#if defined(DEBUG)
    descriptors_ = code.pc_descriptors();
    PcDescriptors::Iterator iter(descriptors_, PcDescriptorsLayout::kIcCall);
    while (iter.MoveNext()) {
      FATAL1("%s has IC calls but no ic_data_array\n", object_.ToCString());
    }
#endif
    return;
  }

  descriptors_ = code.pc_descriptors();
  PcDescriptors::Iterator iter(descriptors_, PcDescriptorsLayout::kIcCall);
  while (iter.MoveNext()) {
    uword pc = code.PayloadStart() + iter.PcOffset();
    CodePatcher::GetInstanceCallAt(pc, code, &object_);
    // This check both avoids unnecessary patching to reduce log spam and
    // prevents patching over breakpoint stubs.
    if (!object_.IsICData()) {
      FindICData(ic_data_array_, iter.DeoptId(), &ic_data_);
      ASSERT(ic_data_.rebind_rule() == ICData::kInstance);
      ASSERT(ic_data_.NumArgsTested() == 1);
      const Code& stub =
          ic_data_.is_tracking_exactness()
              ? StubCode::OneArgCheckInlineCacheWithExactnessCheck()
              : StubCode::OneArgCheckInlineCache();
      CodePatcher::PatchInstanceCallAt(pc, code, ic_data_, stub);
      if (FLAG_trace_ic) {
        OS::PrintErr("Instance call at %" Px
                     " resetting to polymorphic dispatch, %s\n",
                     pc, ic_data_.ToCString());
      }
    }
  }
}

void CallSiteResetter::ResetCaches(const ObjectPool& pool) {
  for (intptr_t i = 0; i < pool.Length(); i++) {
    ObjectPool::EntryType entry_type = pool.TypeAt(i);
    if (entry_type != ObjectPool::EntryType::kTaggedObject) {
      continue;
    }
    object_ = pool.ObjectAt(i);
    if (object_.IsICData()) {
      Reset(ICData::Cast(object_));
    } else if (object_.IsSubtypeTestCache()) {
      SubtypeTestCache::Cast(object_).Reset();
    }
  }
}

void Class::CopyStaticFieldValues(IsolateReloadContext* reload_context,
                                  const Class& old_cls) const {
  // We only update values for non-enum classes.
  const bool update_values = !is_enum_class();

  const Array& old_field_list = Array::Handle(old_cls.fields());
  Field& old_field = Field::Handle();
  String& old_name = String::Handle();

  const Array& field_list = Array::Handle(fields());
  Field& field = Field::Handle();
  String& name = String::Handle();

  for (intptr_t i = 0; i < field_list.Length(); i++) {
    field = Field::RawCast(field_list.At(i));
    name = field.name();
    // Find the corresponding old field, if it exists, and migrate
    // over the field value.
    for (intptr_t j = 0; j < old_field_list.Length(); j++) {
      old_field = Field::RawCast(old_field_list.At(j));
      old_name = old_field.name();
      if (name.Equals(old_name)) {
        if (field.is_static()) {
          // We only copy values if requested and if the field is not a const
          // field. We let const fields be updated with a reload.
          if (update_values && !field.is_const()) {
            // Make new field point to the old field value so that both
            // old and new code see and update same value.
            //
            // TODO(https://dartbug.com/36097): Once we look into enabling
            // hot-reload with --enable-isolate-groups we have to do this
            // for all isolates.
            reload_context->isolate()->group()->initial_field_table()->Free(
                field.field_id());
            reload_context->isolate()->field_table()->Free(field.field_id());
            field.set_field_id(old_field.field_id());
          }
          reload_context->AddStaticFieldMapping(old_field, field);
        } else {
          if (old_field.needs_load_guard()) {
            ASSERT(!old_field.is_unboxing_candidate());
            field.set_needs_load_guard(true);
            field.set_is_unboxing_candidate_unsafe(false);
          }
        }
      }
    }
  }
}

void Class::CopyCanonicalConstants(const Class& old_cls) const {
  if (is_enum_class()) {
    // We do not copy enum classes's canonical constants because we explicitly
    // become the old enum values to the new enum values.
    return;
  }
#if defined(DEBUG)
  {
    // Class has no canonical constants allocated.
    const Array& my_constants = Array::Handle(constants());
    ASSERT(my_constants.IsNull() || my_constants.Length() == 0);
  }
#endif  // defined(DEBUG).
  // Copy old constants into new class.
  const Array& old_constants = Array::Handle(old_cls.constants());
  if (old_constants.IsNull() || old_constants.Length() == 0) {
    return;
  }
  TIR_Print("Copied %" Pd " canonical constants for class `%s`\n",
            old_constants.Length(), ToCString());
  set_constants(old_constants);
}

void Class::CopyDeclarationType(const Class& old_cls) const {
  const Type& old_declaration_type = Type::Handle(old_cls.declaration_type());
  if (old_declaration_type.IsNull()) {
    return;
  }
  set_declaration_type(old_declaration_type);
}

class EnumMapTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "EnumMapTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    return a.raw() == b.raw();
  }

  static uword Hash(const Object& obj) {
    ASSERT(obj.IsString());
    return String::Cast(obj).Hash();
  }
};

// Given an old enum class, add become mappings from old values to new values.
// Some notes about how we reload enums below:
//
// When an enum is reloaded the following three things can happen, possibly
// simultaneously.
//
// 1) A new enum value is added.
//   This case is handled automatically.
// 2) Enum values are reordered.
//   We pair old and new enums and the old enums 'become' the new ones so
//   the ordering is always correct (i.e. enum indices match slots in values
//   array)
// 3) An existing enum value is removed.
//   Each enum class has a canonical 'deleted' enum sentinel instance.
//   When an enum value is deleted, we 'become' all references to the 'deleted'
//   sentinel value. The index value is -1.
//
void Class::ReplaceEnum(IsolateReloadContext* reload_context,
                        const Class& old_enum) const {
  // We only do this for finalized enum classes.
  ASSERT(is_enum_class());
  ASSERT(old_enum.is_enum_class());
  ASSERT(is_finalized());
  ASSERT(old_enum.is_finalized());

  Zone* zone = Thread::Current()->zone();

  Array& enum_fields = Array::Handle(zone);
  Field& field = Field::Handle(zone);
  String& enum_ident = String::Handle();
  Instance& old_enum_value = Instance::Handle(zone);
  Instance& enum_value = Instance::Handle(zone);
  // The E.values array.
  Instance& old_enum_values = Instance::Handle(zone);
  // The E.values array.
  Instance& enum_values = Instance::Handle(zone);
  // The E._deleted_enum_sentinel instance.
  Instance& old_deleted_enum_sentinel = Instance::Handle(zone);
  // The E._deleted_enum_sentinel instance.
  Instance& deleted_enum_sentinel = Instance::Handle(zone);
  Array& enum_map_storage =
      Array::Handle(zone, HashTables::New<UnorderedHashMap<EnumMapTraits> >(4));
  ASSERT(!enum_map_storage.IsNull());

  TIR_Print("Replacing enum `%s`\n", String::Handle(Name()).ToCString());

  {
    UnorderedHashMap<EnumMapTraits> enum_map(enum_map_storage.raw());
    // Build a map of all enum name -> old enum instance.
    enum_fields = old_enum.fields();
    for (intptr_t i = 0; i < enum_fields.Length(); i++) {
      field = Field::RawCast(enum_fields.At(i));
      enum_ident = field.name();
      if (!field.is_static()) {
        // Enum instances are only held in static fields.
        continue;
      }
      if (enum_ident.Equals(Symbols::Values())) {
        old_enum_values = field.StaticValue();
        // Non-enum instance.
        continue;
      }
      if (enum_ident.Equals(Symbols::_DeletedEnumSentinel())) {
        old_deleted_enum_sentinel = field.StaticValue();
        // Non-enum instance.
        continue;
      }
      old_enum_value = field.StaticValue();
      ASSERT(!old_enum_value.IsNull());
      VTIR_Print("Element %s being added to mapping\n", enum_ident.ToCString());
      bool update = enum_map.UpdateOrInsert(enum_ident, old_enum_value);
      VTIR_Print("Element %s added to mapping\n", enum_ident.ToCString());
      ASSERT(!update);
    }
    // The storage given to the map may have been reallocated, remember the new
    // address.
    enum_map_storage = enum_map.Release().raw();
  }

  bool enums_deleted = false;
  {
    UnorderedHashMap<EnumMapTraits> enum_map(enum_map_storage.raw());
    // Add a become mapping from the old instances to the new instances.
    enum_fields = fields();
    for (intptr_t i = 0; i < enum_fields.Length(); i++) {
      field = Field::RawCast(enum_fields.At(i));
      enum_ident = field.name();
      if (!field.is_static()) {
        // Enum instances are only held in static fields.
        continue;
      }
      if (enum_ident.Equals(Symbols::Values())) {
        enum_values = field.StaticValue();
        // Non-enum instance.
        continue;
      }
      if (enum_ident.Equals(Symbols::_DeletedEnumSentinel())) {
        deleted_enum_sentinel = field.StaticValue();
        // Non-enum instance.
        continue;
      }
      enum_value = field.StaticValue();
      ASSERT(!enum_value.IsNull());
      old_enum_value ^= enum_map.GetOrNull(enum_ident);
      if (old_enum_value.IsNull()) {
        VTIR_Print("New element %s was not found in mapping\n",
                   enum_ident.ToCString());
      } else {
        VTIR_Print("Adding element `%s` to become mapping\n",
                   enum_ident.ToCString());
        bool removed = enum_map.Remove(enum_ident);
        ASSERT(removed);
        reload_context->AddEnumBecomeMapping(old_enum_value, enum_value);
      }
    }
    enums_deleted = enum_map.NumOccupied() > 0;
    // The storage given to the map may have been reallocated, remember the new
    // address.
    enum_map_storage = enum_map.Release().raw();
  }

  // Map the old E.values array to the new E.values array.
  ASSERT(!old_enum_values.IsNull());
  ASSERT(!enum_values.IsNull());
  reload_context->AddEnumBecomeMapping(old_enum_values, enum_values);

  // Map the old E._deleted_enum_sentinel to the new E._deleted_enum_sentinel.
  ASSERT(!old_deleted_enum_sentinel.IsNull());
  ASSERT(!deleted_enum_sentinel.IsNull());
  reload_context->AddEnumBecomeMapping(old_deleted_enum_sentinel,
                                       deleted_enum_sentinel);

  if (enums_deleted) {
    // Map all deleted enums to the deleted enum sentinel value.
    // TODO(johnmccutchan): Add this to the reload 'notices' list.
    VTIR_Print(
        "The following enum values were deleted from %s and will become the "
        "deleted enum sentinel:\n",
        old_enum.ToCString());
    UnorderedHashMap<EnumMapTraits> enum_map(enum_map_storage.raw());
    UnorderedHashMap<EnumMapTraits>::Iterator it(&enum_map);
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      enum_ident = String::RawCast(enum_map.GetKey(entry));
      ASSERT(!enum_ident.IsNull());
      old_enum_value ^= enum_map.GetOrNull(enum_ident);
      VTIR_Print("Element `%s` was deleted\n", enum_ident.ToCString());
      reload_context->AddEnumBecomeMapping(old_enum_value,
                                           deleted_enum_sentinel);
    }
    enum_map.Release();
  }
}

void Class::PatchFieldsAndFunctions() const {
  // Move all old functions and fields to a patch class so that they
  // still refer to their original script.
  const PatchClass& patch =
      PatchClass::Handle(PatchClass::New(*this, Script::Handle(script())));
  ASSERT(!patch.IsNull());
  const Library& lib = Library::Handle(library());
  patch.set_library_kernel_data(ExternalTypedData::Handle(lib.kernel_data()));
  patch.set_library_kernel_offset(lib.kernel_offset());

  const Array& funcs = Array::Handle(current_functions());
  Function& func = Function::Handle();
  Object& owner = Object::Handle();
  for (intptr_t i = 0; i < funcs.Length(); i++) {
    func = Function::RawCast(funcs.At(i));
    if ((func.token_pos() == TokenPosition::kMinSource) ||
        func.IsClosureFunction()) {
      // Eval functions do not need to have their script updated.
      //
      // Closure functions refer to the parent's script which we can
      // rely on being updated for us, if necessary.
      continue;
    }

    // If the source for this function is already patched, leave it alone.
    owner = func.RawOwner();
    ASSERT(!owner.IsNull());
    if (!owner.IsPatchClass()) {
      ASSERT(owner.raw() == this->raw());
      func.set_owner(patch);
    }
  }

  Thread* thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  const Array& field_list = Array::Handle(fields());
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < field_list.Length(); i++) {
    field = Field::RawCast(field_list.At(i));
    owner = field.RawOwner();
    ASSERT(!owner.IsNull());
    if (!owner.IsPatchClass()) {
      ASSERT(owner.raw() == this->raw());
      field.set_owner(patch);
    }
    field.ForceDynamicGuardedCidAndLength();
  }
}

void Class::MigrateImplicitStaticClosures(IsolateReloadContext* irc,
                                          const Class& new_cls) const {
  const Array& funcs = Array::Handle(current_functions());
  Thread* thread = Thread::Current();
  Function& old_func = Function::Handle();
  String& selector = String::Handle();
  Function& new_func = Function::Handle();
  Instance& old_closure = Instance::Handle();
  Instance& new_closure = Instance::Handle();
  for (intptr_t i = 0; i < funcs.Length(); i++) {
    old_func ^= funcs.At(i);
    if (old_func.is_static() && old_func.HasImplicitClosureFunction()) {
      selector = old_func.name();
      new_func = Resolver::ResolveFunction(thread->zone(), new_cls, selector);
      if (!new_func.IsNull() && new_func.is_static()) {
        old_func = old_func.ImplicitClosureFunction();
        old_closure = old_func.ImplicitStaticClosure();
        new_func = new_func.ImplicitClosureFunction();
        new_closure = new_func.ImplicitStaticClosure();
        if (old_closure.IsCanonical()) {
          new_closure.SetCanonical();
        }
        irc->AddBecomeMapping(old_closure, new_closure);
      }
    }
  }
}

class EnumClassConflict : public ClassReasonForCancelling {
 public:
  EnumClassConflict(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

  StringPtr ToString() {
    return String::NewFormatted(
        from_.is_enum_class()
            ? "Enum class cannot be redefined to be a non-enum class: %s"
            : "Class cannot be redefined to be a enum class: %s",
        from_.ToCString());
  }
};

class TypedefClassConflict : public ClassReasonForCancelling {
 public:
  TypedefClassConflict(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

  StringPtr ToString() {
    return String::NewFormatted(
        from_.IsTypedefClass()
            ? "Typedef class cannot be redefined to be a non-typedef class: %s"
            : "Class cannot be redefined to be a typedef class: %s",
        from_.ToCString());
  }
};

class EnsureFinalizedError : public ClassReasonForCancelling {
 public:
  EnsureFinalizedError(Zone* zone,
                       const Class& from,
                       const Class& to,
                       const Error& error)
      : ClassReasonForCancelling(zone, from, to), error_(error) {}

 private:
  const Error& error_;

  ErrorPtr ToError() { return error_.raw(); }

  StringPtr ToString() { return String::New(error_.ToErrorCString()); }
};

class ConstToNonConstClass : public ClassReasonForCancelling {
 public:
  ConstToNonConstClass(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

 private:
  StringPtr ToString() {
    return String::NewFormatted("Const class cannot become non-const: %s",
                                from_.ToCString());
  }
};

class ConstClassFieldRemoved : public ClassReasonForCancelling {
 public:
  ConstClassFieldRemoved(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

 private:
  StringPtr ToString() {
    return String::NewFormatted("Const class cannot remove fields: %s",
                                from_.ToCString());
  }
};

class NativeFieldsConflict : public ClassReasonForCancelling {
 public:
  NativeFieldsConflict(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

 private:
  StringPtr ToString() {
    return String::NewFormatted("Number of native fields changed in %s",
                                from_.ToCString());
  }
};

class TypeParametersChanged : public ClassReasonForCancelling {
 public:
  TypeParametersChanged(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

  StringPtr ToString() {
    return String::NewFormatted(
        "Limitation: type parameters have changed for %s", from_.ToCString());
  }

  void AppendTo(JSONArray* array) {
    JSONObject jsobj(array);
    jsobj.AddProperty("type", "ReasonForCancellingReload");
    jsobj.AddProperty("kind", "TypeParametersChanged");
    jsobj.AddProperty("class", to_);
    jsobj.AddProperty("message",
                      "Limitation: changing type parameters "
                      "does not work with hot reload.");
  }
};

class PreFinalizedConflict : public ClassReasonForCancelling {
 public:
  PreFinalizedConflict(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

 private:
  StringPtr ToString() {
    return String::NewFormatted(
        "Original class ('%s') is prefinalized and replacement class "
        "('%s') is not ",
        from_.ToCString(), to_.ToCString());
  }
};

class InstanceSizeConflict : public ClassReasonForCancelling {
 public:
  InstanceSizeConflict(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

 private:
  StringPtr ToString() {
    return String::NewFormatted("Instance size mismatch between '%s' (%" Pd
                                ") and replacement "
                                "'%s' ( %" Pd ")",
                                from_.ToCString(), from_.host_instance_size(),
                                to_.ToCString(), to_.host_instance_size());
  }
};

class UnimplementedDeferredLibrary : public ReasonForCancelling {
 public:
  UnimplementedDeferredLibrary(Zone* zone,
                               const Library& from,
                               const Library& to,
                               const String& name)
      : ReasonForCancelling(zone), from_(from), to_(to), name_(name) {}

 private:
  const Library& from_;
  const Library& to_;
  const String& name_;

  StringPtr ToString() {
    const String& lib_url = String::Handle(to_.url());
    from_.ToCString();
    return String::NewFormatted(
        "Reloading support for deferred loading has not yet been implemented:"
        " library '%s' has deferred import '%s'",
        lib_url.ToCString(), name_.ToCString());
  }
};

// This is executed before iterating over the instances.
void Class::CheckReload(const Class& replacement,
                        IsolateReloadContext* context) const {
  ASSERT(IsolateReloadContext::IsSameClass(*this, replacement));

  if (!is_declaration_loaded()) {
    // The old class hasn't been used in any meaningful way, so the VM is okay
    // with any change.
    return;
  }

  // Ensure is_enum_class etc have been set.
  replacement.EnsureDeclarationLoaded();

  // Class cannot change enum property.
  if (is_enum_class() != replacement.is_enum_class()) {
    context->group_reload_context()->AddReasonForCancelling(
        new (context->zone())
            EnumClassConflict(context->zone(), *this, replacement));
    return;
  }

  // Class cannot change typedef property.
  if (IsTypedefClass() != replacement.IsTypedefClass()) {
    context->group_reload_context()->AddReasonForCancelling(
        new (context->zone())
            TypedefClassConflict(context->zone(), *this, replacement));
    return;
  }

  if (is_finalized()) {
    // Ensure the replacement class is also finalized.
    const Error& error =
        Error::Handle(replacement.EnsureIsFinalized(Thread::Current()));
    if (!error.IsNull()) {
      context->group_reload_context()->AddReasonForCancelling(
          new (context->zone())
              EnsureFinalizedError(context->zone(), *this, replacement, error));
      return;  // No reason to check other properties.
    }
    ASSERT(replacement.is_finalized());
    TIR_Print("Finalized replacement class for %s\n", ToCString());
  }

  if (is_finalized() && is_const() && (constants() != Array::null()) &&
      (Array::LengthOf(constants()) > 0)) {
    // Consts can't become non-consts.
    if (!replacement.is_const()) {
      context->group_reload_context()->AddReasonForCancelling(
          new (context->zone())
              ConstToNonConstClass(context->zone(), *this, replacement));
      return;
    }

    // Consts can't lose fields.
    bool field_removed = false;
    const Array& old_fields =
        Array::Handle(OffsetToFieldMap(true /* original classes */));
    const Array& new_fields = Array::Handle(replacement.OffsetToFieldMap());
    if (new_fields.Length() < old_fields.Length()) {
      field_removed = true;
    } else {
      Field& old_field = Field::Handle();
      Field& new_field = Field::Handle();
      String& old_name = String::Handle();
      String& new_name = String::Handle();
      for (intptr_t i = 0, n = old_fields.Length(); i < n; i++) {
        old_field ^= old_fields.At(i);
        new_field ^= new_fields.At(i);
        if (old_field.IsNull() != new_field.IsNull()) {
          field_removed = true;
          break;
        }
        if (!old_field.IsNull()) {
          old_name = old_field.name();
          new_name = new_field.name();
          if (!old_name.Equals(new_name)) {
            field_removed = true;
            break;
          }
        }
      }
    }
    if (field_removed) {
      context->group_reload_context()->AddReasonForCancelling(
          new (context->zone())
              ConstClassFieldRemoved(context->zone(), *this, replacement));
      return;
    }
  }

  // Native field count cannot change.
  if (num_native_fields() != replacement.num_native_fields()) {
    context->group_reload_context()->AddReasonForCancelling(
        new (context->zone())
            NativeFieldsConflict(context->zone(), *this, replacement));
    return;
  }

  // Just checking.
  ASSERT(is_enum_class() == replacement.is_enum_class());
  ASSERT(num_native_fields() == replacement.num_native_fields());

  if (is_finalized()) {
    if (!CanReloadFinalized(replacement, context)) return;
  }
  if (is_prefinalized()) {
    if (!CanReloadPreFinalized(replacement, context)) return;
  }
  TIR_Print("Class `%s` can be reloaded (%" Pd " and %" Pd ")\n", ToCString(),
            id(), replacement.id());
}

bool Class::RequiresInstanceMorphing(const Class& replacement) const {
  // Get the field maps for both classes. These field maps walk the class
  // hierarchy.
  const Array& fields =
      Array::Handle(OffsetToFieldMap(true /* original classes */));
  const Array& replacement_fields =
      Array::Handle(replacement.OffsetToFieldMap());

  // Check that the size of the instance is the same.
  if (fields.Length() != replacement_fields.Length()) return true;

  // Check that we have the same next field offset. This check is not
  // redundant with the one above because the instance OffsetToFieldMap
  // array length is based on the instance size (which may be aligned up).
  if (host_next_field_offset() != replacement.host_next_field_offset()) {
    return true;
  }

  // Verify that field names / offsets match across the entire hierarchy.
  Field& field = Field::Handle();
  String& field_name = String::Handle();
  Field& replacement_field = Field::Handle();
  String& replacement_field_name = String::Handle();

  for (intptr_t i = 0; i < fields.Length(); i++) {
    if (fields.At(i) == Field::null()) {
      ASSERT(replacement_fields.At(i) == Field::null());
      continue;
    }
    field = Field::RawCast(fields.At(i));
    replacement_field = Field::RawCast(replacement_fields.At(i));
    field_name = field.name();
    replacement_field_name = replacement_field.name();
    if (!field_name.Equals(replacement_field_name)) return true;
  }
  return false;
}

bool Class::CanReloadFinalized(const Class& replacement,
                               IsolateReloadContext* context) const {
  // Make sure the declaration types argument count matches for the two classes.
  // ex. class A<int,B> {} cannot be replace with class A<B> {}.
  auto group_context = context->group_reload_context();
  auto shared_class_table =
      group_context->isolate_group()->shared_class_table();
  if (NumTypeArguments() != replacement.NumTypeArguments()) {
    group_context->AddReasonForCancelling(
        new (context->zone())
            TypeParametersChanged(context->zone(), *this, replacement));
    return false;
  }
  if (RequiresInstanceMorphing(replacement)) {
    ASSERT(id() == replacement.id());
    const classid_t cid = id();
    // We unconditionally create an instance morpher. As a side effect of
    // building the morpher, we will mark all new fields as late.
    auto instance_morpher = InstanceMorpher::CreateFromClassDescriptors(
        context->zone(), shared_class_table, *this, replacement);
    group_context->EnsureHasInstanceMorpherFor(cid, instance_morpher);
  }
  return true;
}

bool Class::CanReloadPreFinalized(const Class& replacement,
                                  IsolateReloadContext* context) const {
  // The replacement class must also prefinalized.
  if (!replacement.is_prefinalized()) {
    context->group_reload_context()->AddReasonForCancelling(
        new (context->zone())
            PreFinalizedConflict(context->zone(), *this, replacement));
    return false;
  }
  // Check the instance sizes are equal.
  if (host_instance_size() != replacement.host_instance_size()) {
    context->group_reload_context()->AddReasonForCancelling(
        new (context->zone())
            InstanceSizeConflict(context->zone(), *this, replacement));
    return false;
  }
  return true;
}

void Library::CheckReload(const Library& replacement,
                          IsolateReloadContext* context) const {
  // TODO(26878): If the replacement library uses deferred loading,
  // reject it.  We do not yet support reloading deferred libraries.
  Object& object = Object::Handle();
  LibraryPrefix& prefix = LibraryPrefix::Handle();
  DictionaryIterator it(replacement);
  while (it.HasNext()) {
    object = it.GetNext();
    if (!object.IsLibraryPrefix()) continue;
    prefix ^= object.raw();
    if (prefix.is_deferred_load()) {
      const String& prefix_name = String::Handle(prefix.name());
      context->group_reload_context()->AddReasonForCancelling(
          new (context->zone()) UnimplementedDeferredLibrary(
              context->zone(), *this, replacement, prefix_name));
      return;
    }
  }
}

void CallSiteResetter::Reset(const ICData& ic) {
  ICData::RebindRule rule = ic.rebind_rule();
  if (rule == ICData::kInstance) {
    const intptr_t num_args = ic.NumArgsTested();
    const bool tracking_exactness = ic.is_tracking_exactness();
    const intptr_t len = ic.Length();
    // We need at least one non-sentinel entry to require a check
    // for the smi fast path case.
    if (num_args == 2 && len >= 2) {
      if (ic.IsImmutable()) {
        return;
      }
      name_ = ic.target_name();
      const Class& smi_class = Class::Handle(zone_, Smi::Class());
      const Function& smi_op_target = Function::Handle(
          zone_, Resolver::ResolveDynamicAnyArgs(zone_, smi_class, name_));
      GrowableArray<intptr_t> class_ids(2);
      Function& target = Function::Handle(zone_);
      ic.GetCheckAt(0, &class_ids, &target);
      if ((target.raw() == smi_op_target.raw()) && (class_ids[0] == kSmiCid) &&
          (class_ids[1] == kSmiCid)) {
        // The smi fast path case, preserve the initial entry but reset the
        // count.
        ic.ClearCountAt(0, *this);
        ic.WriteSentinelAt(1, *this);
        entries_ = ic.entries();
        entries_.Truncate(2 * ic.TestEntryLength());
        return;
      }
      // Fall back to the normal behavior with cached empty ICData arrays.
    }
    entries_ = ICData::CachedEmptyICDataArray(num_args, tracking_exactness);
    ic.set_entries(entries_);
    ic.set_is_megamorphic(false);
    return;
  } else if (rule == ICData::kNoRebind || rule == ICData::kNSMDispatch) {
    // TODO(30877) we should account for addition/removal of NSM.
    // Don't rebind dispatchers.
    return;
  } else if (rule == ICData::kStatic || rule == ICData::kSuper) {
    old_target_ = ic.GetTargetAt(0);
    if (old_target_.IsNull()) {
      FATAL("old_target is NULL.\n");
    }
    name_ = old_target_.name();

    if (rule == ICData::kStatic) {
      ASSERT(old_target_.is_static() ||
             old_target_.kind() == FunctionLayout::kConstructor);
      // This can be incorrect if the call site was an unqualified invocation.
      new_cls_ = old_target_.Owner();
      new_target_ = Resolver::ResolveFunction(zone_, new_cls_, name_);
      if (new_target_.kind() != old_target_.kind()) {
        new_target_ = Function::null();
      }
    } else {
      // Super call.
      caller_ = ic.Owner();
      ASSERT(!caller_.is_static());
      new_cls_ = caller_.Owner();
      new_cls_ = new_cls_.SuperClass();
      new_target_ = Resolver::ResolveDynamicAnyArgs(zone_, new_cls_, name_,
                                                    /*allow_add=*/true);
    }
    args_desc_array_ = ic.arguments_descriptor();
    ArgumentsDescriptor args_desc(args_desc_array_);
    if (new_target_.IsNull() ||
        !new_target_.AreValidArguments(args_desc, NULL)) {
      // TODO(rmacnak): Patch to a NSME stub.
      VTIR_Print("Cannot rebind static call to %s from %s\n",
                 old_target_.ToCString(),
                 Object::Handle(zone_, ic.Owner()).ToCString());
      return;
    }
    ic.ClearAndSetStaticTarget(new_target_, *this);
  } else {
    FATAL("Unexpected rebind rule.");
  }
}

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
