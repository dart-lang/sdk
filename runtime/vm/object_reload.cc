// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"

#include "vm/isolate_reload.h"
#include "vm/log.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, two_args_smi_icd);

#define IRC (Isolate::Current()->reload_context())

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


static void ClearICs(const Function& function, const Code& code) {
  if (function.ic_data_array() == Array::null()) {
    return;  // Already reset in an earlier round.
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  ZoneGrowableArray<const ICData*>* ic_data_array =
      new(zone) ZoneGrowableArray<const ICData*>();
  function.RestoreICDataMap(ic_data_array, false /* clone ic-data */);
  if (ic_data_array->length() == 0) {
    return;
  }
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kIcCall |
                                            RawPcDescriptors::kUnoptStaticCall);
  while (iter.MoveNext()) {
    const ICData* ic_data = (*ic_data_array)[iter.DeoptId()];
    if (ic_data == NULL) {
      continue;
    }
    bool is_static_call = iter.Kind() == RawPcDescriptors::kUnoptStaticCall;
    ic_data->Reset(is_static_call);
  }
}


void Function::FillICDataWithSentinels(const Code& code) const {
  ASSERT(code.raw() == CurrentCode());
  ClearICs(*this, code);
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
          if (update_values) {
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
            old_constants.Length(),
            ToCString());
  set_constants(old_constants);
}


void Class::CopyCanonicalTypes(const Class& old_cls) const {
  const Object& old_canonical_types = Object::Handle(old_cls.canonical_types());
  if (old_canonical_types.IsNull()) {
    return;
  }
  set_canonical_types(old_canonical_types);
}


static intptr_t IndexOfEnum(const Array& enum_names, const String& name) {
  ASSERT(!enum_names.IsNull());
  ASSERT(!name.IsNull());
  String& enum_name = String::Handle();
  for (intptr_t i = 0; i < enum_names.Length(); i++) {
    enum_name = String::RawCast(enum_names.At(i));
    ASSERT(!enum_name.IsNull());
    if (enum_name.Equals(name)) {
      return i;
    }
  }

  return -1;
}


static void UpdateEnumIndex(const Instance& enum_value,
                            const Field& enum_index_field,
                            const intptr_t index) {
  enum_value.SetField(enum_index_field, Smi::Handle(Smi::New(index)));
}


// TODO(johnmccutchan): The code in the class finalizer canonicalizes all
// instances and the values array. We probably should do the same thing.
void Class::ReplaceEnum(const Class& old_enum) const {
  // We only do this for finalized enum classes.
  ASSERT(is_enum_class());
  ASSERT(old_enum.is_enum_class());
  ASSERT(is_finalized());
  ASSERT(old_enum.is_finalized());

  Thread* thread = Thread::Current();
  IsolateReloadContext* reload_context = Isolate::Current()->reload_context();
  ASSERT(reload_context != NULL);

  TIR_Print("ReplaceEnum `%s` (%" Pd " and %" Pd ")\n",
            ToCString(), id(), old_enum.id());

  // Grab '_enum_names' from |old_enum|.
  const Field& old_enum_names_field = Field::Handle(
      old_enum.LookupStaticFieldAllowPrivate(Symbols::_EnumNames()));
  ASSERT(!old_enum_names_field.IsNull());
  const Array& old_enum_names =
      Array::Handle(Array::RawCast(old_enum_names_field.StaticValue()));
  ASSERT(!old_enum_names.IsNull());

  // Grab 'values' from |old_enum|.
  const Field& old_enum_values_field = Field::Handle(
      old_enum.LookupStaticField(Symbols::Values()));
  ASSERT(!old_enum_values_field.IsNull());
  const Array& old_enum_values =
      Array::Handle(Array::RawCast(old_enum_values_field.StaticValue()));
  ASSERT(!old_enum_values.IsNull());

  // Grab _enum_names from |this|.
  const Field& enum_names_field = Field::Handle(
      LookupStaticFieldAllowPrivate(Symbols::_EnumNames()));
  ASSERT(!enum_names_field.IsNull());
  Array& enum_names =
      Array::Handle(Array::RawCast(enum_names_field.StaticValue()));
  ASSERT(!enum_names.IsNull());

  // Grab values from |this|.
  const Field& enum_values_field = Field::Handle(
      LookupStaticField(Symbols::Values()));
  ASSERT(!enum_values_field.IsNull());
  Array& enum_values =
      Array::Handle(Array::RawCast(enum_values_field.StaticValue()));
  ASSERT(!enum_values.IsNull());

  // Grab the |index| field.
  const Field& index_field =
      Field::Handle(old_enum.LookupInstanceField(Symbols::Index()));
  ASSERT(!index_field.IsNull());

  // Build list of enum from |old_enum| that aren't present in |this|.
  // This array holds pairs: (name, value).
  const GrowableObjectArray& to_add =
      GrowableObjectArray::Handle(GrowableObjectArray::New(Heap::kOld));
  const String& enum_class_name = String::Handle(UserVisibleName());
  String& enum_name = String::Handle();
  String& enum_field_name = String::Handle();
  Object& enum_value = Object::Handle();
  Field& enum_field = Field::Handle();

  TIR_Print("New version of enum has %" Pd " elements\n",
            enum_values.Length());
  TIR_Print("Old version of enum had %" Pd " elements\n",
            old_enum_values.Length());

  for (intptr_t i = 0; i < old_enum_names.Length(); i++) {
    enum_name = String::RawCast(old_enum_names.At(i));
    const intptr_t index_in_new_cls = IndexOfEnum(enum_names, enum_name);
    if (index_in_new_cls < 0) {
      // Doesn't exist in new enum, add.
      TIR_Print("Adding enum value `%s` to %s\n",
                enum_name.ToCString(),
                this->ToCString());
      enum_value = old_enum_values.At(i);
      ASSERT(!enum_value.IsNull());
      to_add.Add(enum_name);
      to_add.Add(enum_value);
    } else {
      // Exists in both the new and the old.
      TIR_Print("Moving enum value `%s` to %" Pd "\n",
                enum_name.ToCString(),
                index_in_new_cls);
      // Grab old value.
      enum_value = old_enum_values.At(i);
      // Update index to the be new index.
      UpdateEnumIndex(Instance::Cast(enum_value),
                      index_field,
                      index_in_new_cls);
      // Chop off the 'EnumClass.'
      enum_field_name = String::SubString(enum_name,
                                          enum_class_name.Length() + 1);
      ASSERT(!enum_field_name.IsNull());
      // Grab the static field.
      enum_field = LookupStaticField(enum_field_name);
      ASSERT(!enum_field.IsNull());
      // Use old value with updated index.
      enum_field.SetStaticValue(Instance::Cast(enum_value), true);
      enum_values.SetAt(index_in_new_cls, enum_value);
      enum_names.SetAt(index_in_new_cls, enum_name);
    }
  }

  if (to_add.Length() == 0) {
    // Nothing to do.
    TIR_Print("Found no missing enums in %s\n", ToCString());
    return;
  }

  // Grow the values and enum_names arrays.
  const intptr_t offset = enum_names.Length();
  const intptr_t num_to_add = to_add.Length() / 2;
  ASSERT(offset == enum_values.Length());
  enum_names = Array::Grow(enum_names,
                           enum_names.Length() + num_to_add,
                           Heap::kOld);
  enum_values = Array::Grow(enum_values,
                            enum_values.Length() + num_to_add,
                            Heap::kOld);

  // Install new names and values into the grown arrays. Also, update
  // the index of the new enum values and add static fields for the new
  // enum values.
  Field& enum_value_field = Field::Handle();
  for (intptr_t i = 0; i < num_to_add; i++) {
    const intptr_t target_index = offset + i;
    enum_name = String::RawCast(to_add.At(i * 2));
    enum_value = to_add.At(i * 2 + 1);

    // Update the enum value's index into the new arrays.
    TIR_Print("Updating index of %s in %s to %" Pd "\n",
              enum_name.ToCString(),
              ToCString(),
              target_index);
    UpdateEnumIndex(Instance::Cast(enum_value), index_field, target_index);

    enum_names.SetAt(target_index, enum_name);
    enum_values.SetAt(target_index, enum_value);

    // Install new static field into class.
    // Chop off the 'EnumClass.'
    enum_field_name = String::SubString(enum_name,
                                        enum_class_name.Length() + 1);
    ASSERT(!enum_field_name.IsNull());
    enum_field_name = Symbols::New(thread, enum_field_name);
    enum_value_field = Field::New(enum_field_name,
                                  /* is_static = */ true,
                                  /* is_final = */ true,
                                  /* is_const = */ true,
                                  /* is_reflectable = */ true,
                                  *this,
                                  Object::dynamic_type(),
                                  token_pos());
    enum_value_field.set_has_initializer(false);
    enum_value_field.SetStaticValue(Instance::Cast(enum_value), true);
    enum_value_field.RecordStore(Instance::Cast(enum_value));
    AddField(enum_value_field);
  }

  // Replace the arrays stored in the static fields.
  enum_names_field.SetStaticValue(enum_names, true);
  enum_values_field.SetStaticValue(enum_values, true);
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


bool Class::CanReload(const Class& replacement) const {
  ASSERT(IsolateReloadContext::IsSameClass(*this, replacement));

  if (is_enum_class() && !replacement.is_enum_class()) {
    IRC->ReportError(String::Handle(String::NewFormatted(
        "Enum class cannot be redefined to be a non-enum class: %s",
        ToCString())));
    return false;
  }

  if (!is_enum_class() && replacement.is_enum_class()) {
    IRC->ReportError(String::Handle(String::NewFormatted(
        "Class cannot be redefined to be a enum class: %s",
        ToCString())));
    return false;
  }

  if (is_finalized()) {
    const Error& error =
        Error::Handle(replacement.EnsureIsFinalized(Thread::Current()));
    if (!error.IsNull()) {
      IRC->ReportError(error);
      return false;
    }
    TIR_Print("Finalized replacement class for %s\n", ToCString());
  }

  if (is_finalized()) {
    // Get the field maps for both classes. These field maps walk the class
    // hierarchy.
    const Array& fields =
        Array::Handle(OffsetToFieldMap());
    const Array& replacement_fields =
        Array::Handle(replacement.OffsetToFieldMap());

    // Check that we have the same number of fields.
    if (fields.Length() != replacement_fields.Length()) {
      IRC->ReportError(String::Handle(String::NewFormatted(
          "Number of instance fields changed in %s", ToCString())));
      return false;
    }

    if (NumTypeArguments() != replacement.NumTypeArguments()) {
      IRC->ReportError(String::Handle(String::NewFormatted(
          "Number of type arguments changed in %s", ToCString())));
      return false;
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
      if (!field_name.Equals(replacement_field_name)) {
        IRC->ReportError(String::Handle(String::NewFormatted(
            "Name of instance field changed ('%s' vs '%s') in '%s'",
            field_name.ToCString(),
            replacement_field_name.ToCString(),
            ToCString())));
        return false;
      }
    }
  } else if (is_prefinalized()) {
    if (!replacement.is_prefinalized()) {
      IRC->ReportError(String::Handle(String::NewFormatted(
          "Original class ('%s') is prefinalized and replacement class ('%s')",
          ToCString(), replacement.ToCString())));
      return false;
    }
    if (instance_size() != replacement.instance_size()) {
     IRC->ReportError(String::Handle(String::NewFormatted(
         "Instance size mismatch between '%s' (%" Pd ") and replacement "
         "'%s' ( %" Pd ")",
         ToCString(),
         instance_size(),
         replacement.ToCString(),
         replacement.instance_size())));
     return false;
    }
  }

  // native field count check.
  if (num_native_fields() != replacement.num_native_fields()) {
    IRC->ReportError(String::Handle(String::NewFormatted(
        "Number of native fields changed in %s", ToCString())));
    return false;
  }

  // TODO(johnmccutchan) type parameter count check.

  TIR_Print("Class `%s` can be reloaded (%" Pd " and %" Pd ")\n",
            ToCString(),
            id(),
            replacement.id());
  return true;
}


bool Library::CanReload(const Library& replacement) const {
  return true;
}


static const Function* static_call_target = NULL;

void ICData::Reset(bool is_static_call) const {
  // TODO(johnmccutchan): ICData should know whether or not it's for a
  // static call.
  if (is_static_call) {
    const Function& old_target = Function::Handle(GetTargetAt(0));
    if (old_target.IsNull()) {
      FATAL("old_target is NULL.\n");
    }
    static_call_target = &old_target;
    if (!old_target.is_static()) {
      // TODO(johnmccutchan): Improve this.
      TIR_Print("Cannot rebind super-call to %s from %s\n",
                old_target.ToCString(),
                Object::Handle(Owner()).ToCString());
      return;
    }
    const String& selector = String::Handle(old_target.name());
    const Class& cls = Class::Handle(old_target.Owner());
    const Function& new_target =
        Function::Handle(cls.LookupStaticFunction(selector));
    if (new_target.IsNull()) {
      // TODO(johnmccutchan): Improve this.
      TIR_Print("Cannot rebind static call to %s from %s\n",
                old_target.ToCString(),
                Object::Handle(Owner()).ToCString());
      return;
    }
    ClearAndSetStaticTarget(new_target);
  } else {
    ClearWithSentinel();
  }
}

#endif  // !PRODUCT

}   // namespace dart.
