// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"

#include "vm/hash_table.h"
#include "vm/isolate_reload.h"
#include "vm/log.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, trace_reload_verbose);
DECLARE_FLAG(bool, two_args_smi_icd);

class ObjectReloadUtils : public AllStatic {
  static void DumpLibraryDictionary(const Library& lib) {
    DictionaryIterator it(lib);
    Object& entry = Object::Handle();
    String& name = String::Handle();
    TIR_Print("Dumping dictionary for %s\n", lib.ToCString());
    while (it.HasNext()) {
      entry = it.GetNext();
      name = entry.DictionaryName();
      TIR_Print("%s -> %s\n", name.ToCString(), entry.ToCString());
    }
  }
};

void Function::Reparent(const Class& new_cls) const {
  set_owner(new_cls);
}

void Function::ZeroEdgeCounters() const {
  const Array& saved_ic_data = Array::Handle(ic_data_array());
  if (saved_ic_data.IsNull()) {
    return;
  }
  const intptr_t saved_ic_datalength = saved_ic_data.Length();
  ASSERT(saved_ic_datalength > 0);
  const Array& edge_counters_array =
      Array::Handle(Array::RawCast(saved_ic_data.At(0)));
  ASSERT(!edge_counters_array.IsNull());
  // Fill edge counters array with zeros.
  const Smi& zero = Smi::Handle(Smi::New(0));
  for (intptr_t i = 0; i < edge_counters_array.Length(); i++) {
    edge_counters_array.SetAt(i, zero);
  }
}

void Code::ResetICDatas(Zone* zone) const {
// Iterate over the Code's object pool and reset all ICDatas.
#ifdef TARGET_ARCH_IA32
  // IA32 does not have an object pool, but, we can iterate over all
  // embedded objects by using the variable length data section.
  if (!is_alive()) {
    return;
  }
  const Instructions& instrs = Instructions::Handle(zone, instructions());
  ASSERT(!instrs.IsNull());
  uword base_address = instrs.PayloadStart();
  Object& object = Object::Handle(zone);
  intptr_t offsets_length = pointer_offsets_length();
  const int32_t* offsets = raw_ptr()->data();
  for (intptr_t i = 0; i < offsets_length; i++) {
    int32_t offset = offsets[i];
    RawObject** object_ptr =
        reinterpret_cast<RawObject**>(base_address + offset);
    RawObject* raw_object = *object_ptr;
    if (!raw_object->IsHeapObject()) {
      continue;
    }
    object = raw_object;
    if (object.IsICData()) {
      ICData::Cast(object).Reset(zone);
    }
  }
#else
  const ObjectPool& pool = ObjectPool::Handle(zone, object_pool());
  Object& object = Object::Handle(zone);
  ASSERT(!pool.IsNull());
  for (intptr_t i = 0; i < pool.Length(); i++) {
    ObjectPool::EntryType entry_type = pool.InfoAt(i);
    if (entry_type != ObjectPool::kTaggedObject) {
      continue;
    }
    object = pool.ObjectAt(i);
    if (object.IsICData()) {
      ICData::Cast(object).Reset(zone);
    }
  }
#endif
}

void Class::CopyStaticFieldValues(const Class& old_cls) const {
  // We only update values for non-enum classes.
  const bool update_values = !is_enum_class();

  IsolateReloadContext* reload_context = Isolate::Current()->reload_context();
  ASSERT(reload_context != NULL);

  const Array& old_field_list = Array::Handle(old_cls.fields());
  Field& old_field = Field::Handle();
  String& old_name = String::Handle();

  const Array& field_list = Array::Handle(fields());
  Field& field = Field::Handle();
  String& name = String::Handle();

  Instance& value = Instance::Handle();
  for (intptr_t i = 0; i < field_list.Length(); i++) {
    field = Field::RawCast(field_list.At(i));
    name = field.name();
    if (field.is_static()) {
      // Find the corresponding old field, if it exists, and migrate
      // over the field value.
      for (intptr_t j = 0; j < old_field_list.Length(); j++) {
        old_field = Field::RawCast(old_field_list.At(j));
        old_name = old_field.name();
        if (name.Equals(old_name)) {
          // We only copy values if requested and if the field is not a const
          // field. We let const fields be updated with a reload.
          if (update_values && !field.is_const()) {
            value = old_field.StaticValue();
            field.SetStaticValue(value);
          }
          reload_context->AddStaticFieldMapping(old_field, field);
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
    ASSERT(my_constants.Length() == 0);
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

void Class::CopyCanonicalType(const Class& old_cls) const {
  const Type& old_canonical_type = Type::Handle(old_cls.canonical_type());
  if (old_canonical_type.IsNull()) {
    return;
  }
  set_canonical_type(old_canonical_type);
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
void Class::ReplaceEnum(const Class& old_enum) const {
  // We only do this for finalized enum classes.
  ASSERT(is_enum_class());
  ASSERT(old_enum.is_enum_class());
  ASSERT(is_finalized());
  ASSERT(old_enum.is_finalized());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  IsolateReloadContext* reload_context = Isolate::Current()->reload_context();
  ASSERT(reload_context != NULL);

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

  const Array& funcs = Array::Handle(functions());
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
  const Array& funcs = Array::Handle(functions());
  Function& old_func = Function::Handle();
  String& selector = String::Handle();
  Function& new_func = Function::Handle();
  Instance& old_closure = Instance::Handle();
  Instance& new_closure = Instance::Handle();
  for (intptr_t i = 0; i < funcs.Length(); i++) {
    old_func ^= funcs.At(i);
    if (old_func.is_static() && old_func.HasImplicitClosureFunction()) {
      selector = old_func.name();
      new_func = new_cls.LookupFunction(selector);
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

  RawString* ToString() {
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

  RawString* ToString() {
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

  RawError* ToError() { return error_.raw(); }

  RawString* ToString() { return String::New(error_.ToErrorCString()); }
};

class NativeFieldsConflict : public ClassReasonForCancelling {
 public:
  NativeFieldsConflict(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

 private:
  RawString* ToString() {
    return String::NewFormatted("Number of native fields changed in %s",
                                from_.ToCString());
  }
};

class TypeParametersChanged : public ClassReasonForCancelling {
 public:
  TypeParametersChanged(Zone* zone, const Class& from, const Class& to)
      : ClassReasonForCancelling(zone, from, to) {}

  RawString* ToString() {
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
  RawString* ToString() {
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
  RawString* ToString() {
    return String::NewFormatted("Instance size mismatch between '%s' (%" Pd
                                ") and replacement "
                                "'%s' ( %" Pd ")",
                                from_.ToCString(), from_.instance_size(),
                                to_.ToCString(), to_.instance_size());
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

  RawString* ToString() {
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

  // Class cannot change enum property.
  if (is_enum_class() != replacement.is_enum_class()) {
    context->AddReasonForCancelling(new (context->zone()) EnumClassConflict(
        context->zone(), *this, replacement));
    return;
  }

  // Class cannot change typedef property.
  if (IsTypedefClass() != replacement.IsTypedefClass()) {
    context->AddReasonForCancelling(new (context->zone()) TypedefClassConflict(
        context->zone(), *this, replacement));
    return;
  }

  if (is_finalized()) {
    // Ensure the replacement class is also finalized.
    const Error& error =
        Error::Handle(replacement.EnsureIsFinalized(Thread::Current()));
    if (!error.IsNull()) {
      context->AddReasonForCancelling(
          new (context->zone())
              EnsureFinalizedError(context->zone(), *this, replacement, error));
      return;  // No reason to check other properties.
    }
    ASSERT(replacement.is_finalized());
    TIR_Print("Finalized replacement class for %s\n", ToCString());
  }

  // Native field count cannot change.
  if (num_native_fields() != replacement.num_native_fields()) {
    context->AddReasonForCancelling(new (context->zone()) NativeFieldsConflict(
        context->zone(), *this, replacement));
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
  ASSERT(is_finalized() == replacement.is_finalized());
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
  if (next_field_offset() != replacement.next_field_offset()) return true;

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
  // Make sure the declaration types matches for the two classes.
  // ex. class A<int,B> {} cannot be replace with class A<B> {}.

  const AbstractType& dt = AbstractType::Handle(DeclarationType());
  const AbstractType& replacement_dt =
      AbstractType::Handle(replacement.DeclarationType());
  if (!dt.Equals(replacement_dt)) {
    context->AddReasonForCancelling(new (context->zone()) TypeParametersChanged(
        context->zone(), *this, replacement));
    return false;
  }
  if (RequiresInstanceMorphing(replacement)) {
    context->AddInstanceMorpher(new (context->zone()) InstanceMorpher(
        context->zone(), *this, replacement));
  }
  return true;
}

bool Class::CanReloadPreFinalized(const Class& replacement,
                                  IsolateReloadContext* context) const {
  // The replacement class must also prefinalized.
  if (!replacement.is_prefinalized()) {
    context->AddReasonForCancelling(new (context->zone()) PreFinalizedConflict(
        context->zone(), *this, replacement));
    return false;
  }
  // Check the instance sizes are equal.
  if (instance_size() != replacement.instance_size()) {
    context->AddReasonForCancelling(new (context->zone()) InstanceSizeConflict(
        context->zone(), *this, replacement));
    return false;
  }
  return true;
}

void Library::CheckReload(const Library& replacement,
                          IsolateReloadContext* context) const {
  // TODO(26878): If the replacement library uses deferred loading,
  // reject it.  We do not yet support reloading deferred libraries.
  LibraryPrefix& prefix = LibraryPrefix::Handle();
  LibraryPrefixIterator it(replacement);
  while (it.HasNext()) {
    prefix = it.GetNext();
    if (prefix.is_deferred_load()) {
      const String& prefix_name = String::Handle(prefix.name());
      context->AddReasonForCancelling(
          new (context->zone()) UnimplementedDeferredLibrary(
              context->zone(), *this, replacement, prefix_name));
      return;
    }
  }
}

static const Function* static_call_target = NULL;

void ICData::Reset(Zone* zone) const {
  RebindRule rule = rebind_rule();
  if (rule == kInstance) {
    intptr_t num_args = NumArgsTested();
    if (num_args == 2) {
      ClearWithSentinel();
    } else {
      const Array& data_array =
          Array::Handle(zone, CachedEmptyICDataArray(num_args));
      set_ic_data_array(data_array);
    }
    return;
  } else if (rule == kNoRebind || rule == kNSMDispatch) {
    // TODO(30877) we should account for addition/removal of NSM.
    // Don't rebind dispatchers.
    return;
  } else if (rule == kStatic || rule == kSuper) {
    const Function& old_target = Function::Handle(zone, GetTargetAt(0));
    if (old_target.IsNull()) {
      FATAL("old_target is NULL.\n");
    }
    static_call_target = &old_target;

    const String& selector = String::Handle(zone, old_target.name());
    Function& new_target = Function::Handle(zone);

    if (rule == kStatic) {
      ASSERT(old_target.is_static() ||
             old_target.kind() == RawFunction::kConstructor);
      // This can be incorrect if the call site was an unqualified invocation.
      const Class& cls = Class::Handle(zone, old_target.Owner());
      new_target = cls.LookupStaticFunction(selector);
    } else {
      // Super call.
      Function& caller = Function::Handle(zone);
      caller ^= Owner();
      ASSERT(!caller.is_static());
      Class& cls = Class::Handle(zone, caller.Owner());
      cls = cls.SuperClass();
      while (!cls.IsNull()) {
        // TODO(rmacnak): Should use Resolver::ResolveDynamicAnyArgs to handle
        // method-extractors and call-through-getters, but we're in a no
        // safepoint scope here.
        new_target = cls.LookupDynamicFunction(selector);
        if (!new_target.IsNull()) {
          break;
        }
        cls = cls.SuperClass();
      }
    }
    const Array& args_desc_array = Array::Handle(zone, arguments_descriptor());
    ArgumentsDescriptor args_desc(args_desc_array);
    if (new_target.IsNull() || !new_target.AreValidArguments(args_desc, NULL)) {
      // TODO(rmacnak): Patch to a NSME stub.
      VTIR_Print("Cannot rebind static call to %s from %s\n",
                 old_target.ToCString(),
                 Object::Handle(zone, Owner()).ToCString());
      return;
    }
    ClearAndSetStaticTarget(new_target);
  } else {
    FATAL("Unexpected rebind rule.");
  }
}

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart.
