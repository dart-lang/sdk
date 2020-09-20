// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/assembler/disassembler.h"
#include "vm/debugger.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/type_table.h"

namespace dart {

#ifndef PRODUCT

static void AddNameProperties(JSONObject* jsobj,
                              const char* name,
                              const char* vm_name) {
  jsobj->AddProperty("name", name);
  if (strcmp(name, vm_name) != 0) {
    jsobj->AddProperty("_vmName", vm_name);
  }
}

void Object::AddCommonObjectProperties(JSONObject* jsobj,
                                       const char* protocol_type,
                                       bool ref) const {
  const char* vm_type = JSONType();
  bool same_type = (strcmp(protocol_type, vm_type) == 0);
  if (ref) {
    jsobj->AddPropertyF("type", "@%s", protocol_type);
  } else {
    jsobj->AddProperty("type", protocol_type);
  }
  if (!same_type) {
    jsobj->AddProperty("_vmType", vm_type);
  }
  if (!ref || IsInstance() || IsNull()) {
    // TODO(turnidge): Provide the type arguments here too?
    const Class& cls = Class::Handle(this->clazz());
    jsobj->AddProperty("class", cls);
  }
  if (!ref) {
    if (raw()->IsHeapObject()) {
      jsobj->AddProperty("size", raw()->ptr()->HeapSize());
    } else {
      jsobj->AddProperty("size", (intptr_t)0);
    }
  }
}

void Object::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
}

void Object::PrintJSON(JSONStream* stream, bool ref) const {
  if (IsNull()) {
    JSONObject jsobj(stream);
    AddCommonObjectProperties(&jsobj, "Instance", ref);
    jsobj.AddProperty("kind", "Null");
    jsobj.AddFixedServiceId("objects/null");
    jsobj.AddProperty("valueAsString", "null");
  } else {
    PrintJSONImpl(stream, ref);
  }
}

void Class::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Isolate* isolate = Isolate::Current();
  JSONObject jsobj(stream);
  if ((raw() == Class::null()) || (id() == kFreeListElement)) {
    // TODO(turnidge): This is weird and needs to be changed.
    jsobj.AddProperty("type", "null");
    return;
  }
  AddCommonObjectProperties(&jsobj, "Class", ref);
  jsobj.AddFixedServiceId("classes/%" Pd "", id());
  const String& scrubbed_name = String::Handle(ScrubbedName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, scrubbed_name.ToCString(), vm_name.ToCString());
  if (ref) {
    return;
  }

  const Error& err = Error::Handle(EnsureIsFinalized(Thread::Current()));
  if (!err.IsNull()) {
    jsobj.AddProperty("error", err);
  }
  jsobj.AddProperty("abstract", is_abstract());
  jsobj.AddProperty("const", is_const());
  jsobj.AddProperty("_finalized", is_finalized());
  jsobj.AddProperty("_implemented", is_implemented());
  jsobj.AddProperty("_patch", false);
  jsobj.AddProperty("_traceAllocations", TraceAllocation(isolate));

  const Class& superClass = Class::Handle(SuperClass());
  if (!superClass.IsNull()) {
    jsobj.AddProperty("super", superClass);
  }
  const AbstractType& superType = AbstractType::Handle(super_type());
  if (!superType.IsNull()) {
    jsobj.AddProperty("superType", superType);
  }
  const Array& interface_array = Array::Handle(interfaces());
  if (is_transformed_mixin_application()) {
    Type& mix = Type::Handle();
    mix ^= interface_array.At(interface_array.Length() - 1);
    jsobj.AddProperty("mixin", mix);
  }
  jsobj.AddProperty("library", Object::Handle(library()));
  const Script& script = Script::Handle(this->script());
  if (!script.IsNull()) {
    jsobj.AddLocation(script, token_pos(), end_token_pos());
  }
  {
    JSONArray interfaces_array(&jsobj, "interfaces");
    Type& interface_type = Type::Handle();
    if (!interface_array.IsNull()) {
      for (intptr_t i = 0; i < interface_array.Length(); ++i) {
        interface_type ^= interface_array.At(i);
        interfaces_array.AddValue(interface_type);
      }
    }
  }
  {
    JSONArray fields_array(&jsobj, "fields");
    const Array& field_array = Array::Handle(fields());
    Field& field = Field::Handle();
    if (!field_array.IsNull()) {
      for (intptr_t i = 0; i < field_array.Length(); ++i) {
        field ^= field_array.At(i);
        fields_array.AddValue(field);
      }
    }
  }
  {
    JSONArray functions_array(&jsobj, "functions");
    const Array& function_array = Array::Handle(functions());
    Function& function = Function::Handle();
    if (!function_array.IsNull()) {
      for (intptr_t i = 0; i < function_array.Length(); i++) {
        function ^= function_array.At(i);
        functions_array.AddValue(function);
      }
    }
  }
  {
    JSONArray subclasses_array(&jsobj, "subclasses");
    const GrowableObjectArray& subclasses =
        GrowableObjectArray::Handle(direct_subclasses());
    if (!subclasses.IsNull()) {
      Class& subclass = Class::Handle();
      for (intptr_t i = 0; i < subclasses.Length(); ++i) {
        // TODO(turnidge): Use the Type directly once regis has added
        // types to the vmservice.
        subclass ^= subclasses.At(i);
        subclasses_array.AddValue(subclass);
      }
    }
  }
}

void TypeArguments::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  // The index in the canonical_type_arguments table cannot be used as part of
  // the object id (as in typearguments/id), because the indices are not
  // preserved when the table grows and the entries get rehashed. Use the ring.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();
  CanonicalTypeArgumentsSet typeargs_table(
      zone, object_store->canonical_type_arguments());
  const Array& table =
      Array::Handle(HashTables::ToArray(typeargs_table, false));
  typeargs_table.Release();
  ASSERT(table.Length() > 0);
  AddCommonObjectProperties(&jsobj, "TypeArguments", ref);
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(UserVisibleName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name.ToCString(), vm_name.ToCString());
  if (ref) {
    return;
  }
  {
    JSONArray jsarr(&jsobj, "types");
    AbstractType& type_arg = AbstractType::Handle();
    for (intptr_t i = 0; i < Length(); i++) {
      type_arg = TypeAt(i);
      jsarr.AddValue(type_arg);
    }
  }
  if (!IsInstantiated()) {
    JSONArray jsarr(&jsobj, "_instantiations");
    Array& prior_instantiations = Array::Handle(instantiations());
    ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
    TypeArguments& type_args = TypeArguments::Handle();
    intptr_t i = 0;
    while (prior_instantiations.At(i) !=
           Smi::New(TypeArguments::kNoInstantiator)) {
      JSONObject instantiation(&jsarr);
      type_args ^= prior_instantiations.At(
          i + TypeArguments::Instantiation::kInstantiatorTypeArgsIndex);
      instantiation.AddProperty("instantiatorTypeArguments", type_args, true);
      type_args ^= prior_instantiations.At(
          i + TypeArguments::Instantiation::kFunctionTypeArgsIndex);
      instantiation.AddProperty("functionTypeArguments", type_args, true);
      type_args ^= prior_instantiations.At(
          i + TypeArguments::Instantiation::kInstantiatedTypeArgsIndex);
      instantiation.AddProperty("instantiated", type_args, true);
      i += TypeArguments::Instantiation::kSizeInWords;
    }
  }
}

void PatchClass::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

static void AddFunctionServiceId(const JSONObject& jsobj,
                                 const Function& f,
                                 const Class& cls) {
  if (cls.IsNull()) {
    ASSERT(f.IsSignatureFunction());
    jsobj.AddServiceId(f);
    return;
  }
  // Special kinds of functions use indices in their respective lists.
  intptr_t id = -1;
  const char* selector = NULL;
  if (f.IsNonImplicitClosureFunction()) {
    id = Isolate::Current()->FindClosureIndex(f);
    selector = "closures";
  } else if (f.IsImplicitClosureFunction()) {
    id = cls.FindImplicitClosureFunctionIndex(f);
    selector = "implicit_closures";
  } else if (f.IsNoSuchMethodDispatcher() || f.IsInvokeFieldDispatcher()) {
    id = cls.FindInvocationDispatcherFunctionIndex(f);
    selector = "dispatchers";
  }
  if (id != -1) {
    ASSERT(selector != NULL);
    if (cls.IsTopLevel()) {
      const auto& library = Library::Handle(cls.library());
      const auto& private_key = String::Handle(library.private_key());
      jsobj.AddFixedServiceId("libraries/%s/%s/%" Pd "",
                              private_key.ToCString(), selector, id);
    } else {
      jsobj.AddFixedServiceId("classes/%" Pd "/%s/%" Pd "", cls.id(), selector,
                              id);
    }
    return;
  }
  // Regular functions known to their owner use their name (percent-encoded).
  String& name = String::Handle(f.name());
  if (cls.LookupFunction(name) == f.raw()) {
    const char* encoded_name = String::EncodeIRI(name);
    if (cls.IsTopLevel()) {
      const auto& library = Library::Handle(cls.library());
      const auto& private_key = String::Handle(library.private_key());
      jsobj.AddFixedServiceId("libraries/%s/functions/%s",
                              private_key.ToCString(), encoded_name);
    } else {
      jsobj.AddFixedServiceId("classes/%" Pd "/functions/%s", cls.id(),
                              encoded_name);
    }
    return;
  }
  // Oddball functions (not known to their owner) fall back to use the object
  // id ring. Current known examples are signature functions of closures
  // and stubs like 'megamorphic_call_miss'.
  jsobj.AddServiceId(f);
}

void Function::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Class& cls = Class::Handle(Owner());
  if (!cls.IsNull()) {
    Error& err = Error::Handle();
    err = cls.EnsureIsFinalized(Thread::Current());
    ASSERT(err.IsNull());
  } else {
    ASSERT(IsSignatureFunction());
  }
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Function", ref);
  AddFunctionServiceId(jsobj, *this, cls);
  const char* user_name = UserVisibleNameCString();
  const String& vm_name = String::Handle(name());
  AddNameProperties(&jsobj, user_name, vm_name.ToCString());
  const Function& parent = Function::Handle(parent_function());
  if (!parent.IsNull()) {
    jsobj.AddProperty("owner", parent);
  } else if (!cls.IsNull()) {
    if (cls.IsTopLevel()) {
      const Library& library = Library::Handle(cls.library());
      jsobj.AddProperty("owner", library);
    } else {
      jsobj.AddProperty("owner", cls);
    }
  }

  const char* kind_string = Function::KindToCString(kind());
  jsobj.AddProperty("_kind", kind_string);
  jsobj.AddProperty("static", is_static());
  jsobj.AddProperty("const", is_const());
  jsobj.AddProperty("_intrinsic", is_intrinsic());
  jsobj.AddProperty("_native", is_native());
  if (ref) {
    return;
  }
  Code& code = Code::Handle(CurrentCode());
  if (!code.IsNull()) {
    jsobj.AddProperty("code", code);
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  Bytecode& bytecode = Bytecode::Handle(this->bytecode());
  if (!bytecode.IsNull()) {
    jsobj.AddProperty("_bytecode", bytecode);
  }
#endif  // !DART_PRECOMPILED_RUNTIME
  Array& ics = Array::Handle(ic_data_array());
  if (!ics.IsNull()) {
    jsobj.AddProperty("_icDataArray", ics);
  }
  jsobj.AddProperty("_optimizable", is_optimizable());
  jsobj.AddProperty("_inlinable", is_inlinable());
  jsobj.AddProperty("_recognized", IsRecognized());
  code = unoptimized_code();
  if (!code.IsNull()) {
    jsobj.AddProperty("_unoptimizedCode", code);
  }
  jsobj.AddProperty("_usageCounter", usage_counter());
  jsobj.AddProperty("_optimizedCallSiteCount", optimized_call_site_count());
  jsobj.AddProperty("_deoptimizations",
                    static_cast<intptr_t>(deoptimization_counter()));
  if ((kind() == FunctionLayout::kImplicitGetter) ||
      (kind() == FunctionLayout::kImplicitSetter) ||
      (kind() == FunctionLayout::kImplicitStaticGetter) ||
      (kind() == FunctionLayout::kFieldInitializer)) {
    const Field& field = Field::Handle(accessor_field());
    if (!field.IsNull()) {
      jsobj.AddProperty("_field", field);
    }
  }

  const Script& script = Script::Handle(this->script());
  if (!script.IsNull()) {
    jsobj.AddLocation(script, token_pos(), end_token_pos());
  }
}

void RedirectionData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void FfiTrampolineData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void Field::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  Class& cls = Class::Handle(Owner());
  String& field_name = String::Handle(name());
  const char* encoded_field_name = String::EncodeIRI(field_name);
  AddCommonObjectProperties(&jsobj, "Field", ref);
  if (cls.IsTopLevel()) {
    const auto& library = Library::Handle(cls.library());
    const auto& private_key = String::Handle(library.private_key());
    jsobj.AddFixedServiceId("libraries/%s/fields/%s", private_key.ToCString(),
                            encoded_field_name);
  } else {
    jsobj.AddFixedServiceId("classes/%" Pd "/fields/%s", cls.id(),
                            encoded_field_name);
  }

  const char* user_name = UserVisibleNameCString();
  const String& vm_name = String::Handle(name());
  AddNameProperties(&jsobj, user_name, vm_name.ToCString());
  if (cls.IsTopLevel()) {
    const Library& library = Library::Handle(cls.library());
    jsobj.AddProperty("owner", library);
  } else {
    jsobj.AddProperty("owner", cls);
  }

  AbstractType& declared_type = AbstractType::Handle(type());
  jsobj.AddProperty("declaredType", declared_type);
  jsobj.AddProperty("static", is_static());
  jsobj.AddProperty("final", is_final());
  jsobj.AddProperty("const", is_const());
  if (ref) {
    return;
  }
  if (is_static()) {
    const Instance& valueObj = Instance::Handle(StaticValue());
    jsobj.AddProperty("staticValue", valueObj);
  }

  jsobj.AddProperty("_guardNullable", is_nullable());
  if (guarded_cid() == kIllegalCid) {
    jsobj.AddProperty("_guardClass", "unknown");
  } else if (guarded_cid() == kDynamicCid) {
    jsobj.AddProperty("_guardClass", "dynamic");
  } else {
    ClassTable* table = Isolate::Current()->class_table();
    ASSERT(table->IsValidIndex(guarded_cid()));
    cls = table->At(guarded_cid());
    jsobj.AddProperty("_guardClass", cls);
  }
  if (guarded_list_length() == kUnknownFixedLength) {
    jsobj.AddProperty("_guardLength", "unknown");
  } else if (guarded_list_length() == kNoFixedLength) {
    jsobj.AddProperty("_guardLength", "variable");
  } else {
    jsobj.AddPropertyF("_guardLength", "%" Pd, guarded_list_length());
  }
  const class Script& script = Script::Handle(Script());
  if (!script.IsNull()) {
    jsobj.AddLocation(script, token_pos());
  }
}

// See also Dart_ScriptGetTokenInfo.
void Script::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Script", ref);
  const String& uri = String::Handle(url());
  ASSERT(!uri.IsNull());
  const char* encoded_uri = String::EncodeIRI(uri);
  const Library& lib = Library::Handle(FindLibrary());
  if (lib.IsNull()) {
    jsobj.AddServiceId(*this);
  } else {
    const String& lib_id = String::Handle(lib.private_key());
    jsobj.AddFixedServiceId("libraries/%s/scripts/%s/%" Px64 "",
                            lib_id.ToCString(), encoded_uri, load_timestamp());
  }
  jsobj.AddPropertyStr("uri", uri);
  jsobj.AddProperty("_kind", "kernel");
  if (ref) {
    return;
  }
  jsobj.AddPropertyTimeMillis("_loadTime", load_timestamp());
  if (!lib.IsNull()) {
    jsobj.AddProperty("library", lib);
  }
  const String& source = String::Handle(Source());
  jsobj.AddProperty("lineOffset", line_offset());
  jsobj.AddProperty("columnOffset", col_offset());
  if (!source.IsNull()) {
    jsobj.AddPropertyStr("source", source);
  }

  // Print the line number table
  const GrowableObjectArray& lineNumberArray =
      GrowableObjectArray::Handle(GenerateLineNumberArray());
  if (!lineNumberArray.IsNull() && (lineNumberArray.Length() > 0)) {
    JSONArray tokenPosTable(&jsobj, "tokenPosTable");

    Object& value = Object::Handle();
    intptr_t pos = 0;

    // Skip leading null.
    ASSERT(lineNumberArray.Length() > 0);
    value = lineNumberArray.At(pos);
    ASSERT(value.IsNull());
    pos++;

    while (pos < lineNumberArray.Length()) {
      JSONArray lineInfo(&tokenPosTable);
      while (pos < lineNumberArray.Length()) {
        value = lineNumberArray.At(pos);
        pos++;
        if (value.IsNull()) {
          break;
        }
        const Smi& smi = Smi::Cast(value);
        lineInfo.AddValue(smi.Value());
      }
    }
  }
}

void Library::PrintJSONImpl(JSONStream* stream, bool ref) const {
  const String& id = String::Handle(private_key());
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Library", ref);
  jsobj.AddFixedServiceId("libraries/%s", id.ToCString());
  const String& vm_name = String::Handle(name());
  const char* scrubbed_name = String::ScrubName(vm_name);
  AddNameProperties(&jsobj, scrubbed_name, vm_name.ToCString());
  const String& library_url = String::Handle(url());
  jsobj.AddPropertyStr("uri", library_url);
  if (ref) {
    return;
  }
  jsobj.AddProperty("debuggable", IsDebuggable());
  {
    JSONArray jsarr(&jsobj, "classes");
    ClassDictionaryIterator class_iter(*this);
    Class& klass = Class::Handle();
    while (class_iter.HasNext()) {
      klass = class_iter.GetNextClass();
      jsarr.AddValue(klass);
    }
  }
  {
    JSONArray jsarr(&jsobj, "dependencies");

    Namespace& ns = Namespace::Handle();
    Library& target = Library::Handle();

    // Unprefixed imports.
    Array& imports = Array::Handle(this->imports());
    for (intptr_t i = 0; i < imports.Length(); i++) {
      ns ^= imports.At(i);
      if (ns.IsNull()) continue;

      JSONObject jsdep(&jsarr);
      jsdep.AddProperty("isDeferred", false);
      jsdep.AddProperty("isExport", false);
      jsdep.AddProperty("isImport", true);
      target = ns.library();
      jsdep.AddProperty("target", target);
    }

    // Exports.
    const Array& exports = Array::Handle(this->exports());
    for (intptr_t i = 0; i < exports.Length(); i++) {
      ns ^= exports.At(i);
      if (ns.IsNull()) continue;

      JSONObject jsdep(&jsarr);
      jsdep.AddProperty("isDeferred", false);
      jsdep.AddProperty("isExport", true);
      jsdep.AddProperty("isImport", false);
      target = ns.library();
      jsdep.AddProperty("target", target);
    }

    // Prefixed imports.
    DictionaryIterator entries(*this);
    Object& entry = Object::Handle();
    LibraryPrefix& prefix = LibraryPrefix::Handle();
    String& prefix_name = String::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsLibraryPrefix()) {
        prefix ^= entry.raw();
        imports = prefix.imports();
        if (!imports.IsNull()) {
          for (intptr_t i = 0; i < imports.Length(); i++) {
            ns ^= imports.At(i);
            if (ns.IsNull()) continue;

            JSONObject jsdep(&jsarr);
            jsdep.AddProperty("isDeferred", prefix.is_deferred_load());
            jsdep.AddProperty("isExport", false);
            jsdep.AddProperty("isImport", true);
            prefix_name = prefix.name();
            ASSERT(!prefix_name.IsNull());
            jsdep.AddProperty("prefix", prefix_name.ToCString());
            target = ns.library();
            jsdep.AddProperty("target", target);
          }
        }
      }
    }

    if (is_declared_in_bytecode()) {
      // Make sure top level class (containing annotations) is fully loaded.
      EnsureTopLevelClassIsFinalized();
      Array& metadata = Array::Handle(GetExtendedMetadata(*this, 1));
      if (metadata.Length() != 0) {
        // Library has the only element in the extended metadata.
        metadata ^= metadata.At(0);
        if (!metadata.IsNull()) {
          Thread* thread = Thread::Current();
          auto& desc = Array::Handle();
          auto& target_uri = String::Handle();
          auto& is_export = Bool::Handle();
          auto& is_deferred = Bool::Handle();
          for (intptr_t i = 0, n = metadata.Length(); i < n; ++i) {
            desc ^= metadata.At(i);
            // Each dependency is represented as an array with the following
            // layout:
            //  [0] = target library URI (String)
            //  [1] = is_export (bool)
            //  [2] = is_deferred (bool)
            //  [3] = prefix (String or null)
            //  ...
            // The library dependencies are encoded by getLibraryAnnotations(),
            // pkg/vm/lib/bytecode/gen_bytecode.dart.
            target_uri ^= desc.At(0);
            is_export ^= desc.At(1);
            is_deferred ^= desc.At(2);
            prefix_name ^= desc.At(3);

            target = Library::LookupLibrary(thread, target_uri);
            if (target.IsNull()) {
              continue;
            }

            JSONObject jsdep(&jsarr);
            jsdep.AddProperty("isDeferred", is_deferred.value());
            jsdep.AddProperty("isExport", is_export.value());
            jsdep.AddProperty("isImport", !is_export.value());
            if (!prefix_name.IsNull()) {
              jsdep.AddProperty("prefix", prefix_name.ToCString());
            }
            jsdep.AddProperty("target", target);
          }
        }
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "variables");
    DictionaryIterator entries(*this);
    Object& entry = Object::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsField()) {
        jsarr.AddValue(entry);
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "functions");
    DictionaryIterator entries(*this);
    Object& entry = Object::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsFunction()) {
        const Function& func = Function::Cast(entry);
        if (func.kind() == FunctionLayout::kRegularFunction ||
            func.kind() == FunctionLayout::kGetterFunction ||
            func.kind() == FunctionLayout::kSetterFunction) {
          jsarr.AddValue(func);
        }
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "scripts");
    Array& scripts = Array::Handle(LoadedScripts());
    Script& script = Script::Handle();
    for (intptr_t i = 0; i < scripts.Length(); i++) {
      script ^= scripts.At(i);
      jsarr.AddValue(script);
    }
  }
}

void LibraryPrefix::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void Namespace::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void KernelProgramInfo::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void Instructions::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
}

void InstructionsSection::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void WeakSerializationReference::PrintJSONImpl(JSONStream* stream,
                                               bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  if (ref) return;
  auto& obj = Object::Handle(target());
  jsobj.AddProperty("target", obj);
}

void ObjectPool::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }

  {
    JSONArray jsarr(&jsobj, "_entries");
    uword imm;
    Object& obj = Object::Handle();
    for (intptr_t i = 0; i < Length(); i++) {
      JSONObject jsentry(stream);
      jsentry.AddProperty("offset", OffsetFromIndex(i));
      switch (TypeAt(i)) {
        case ObjectPool::EntryType::kTaggedObject:
          obj = ObjectAt(i);
          jsentry.AddProperty("kind", "Object");
          jsentry.AddProperty("value", obj);
          break;
        case ObjectPool::EntryType::kImmediate:
          imm = RawValueAt(i);
          jsentry.AddProperty("kind", "Immediate");
          jsentry.AddProperty64("value", imm);
          break;
        case ObjectPool::EntryType::kNativeEntryData:
          obj = ObjectAt(i);
          jsentry.AddProperty("kind", "NativeEntryData");
          jsentry.AddProperty("value", obj);
          break;
        case ObjectPool::EntryType::kNativeFunction:
          imm = RawValueAt(i);
          jsentry.AddProperty("kind", "NativeFunction");
          jsentry.AddProperty64("value", imm);
          break;
        case ObjectPool::EntryType::kNativeFunctionWrapper:
          imm = RawValueAt(i);
          jsentry.AddProperty("kind", "NativeFunctionWrapper");
          jsentry.AddProperty64("value", imm);
          break;
        default:
          UNREACHABLE();
      }
    }
  }
}

void PcDescriptors::PrintToJSONObject(JSONObject* jsobj, bool ref) const {
  AddCommonObjectProperties(jsobj, "Object", ref);
  // TODO(johnmccutchan): Generate a stable id. PcDescriptors hang off a Code
  // object but do not have a back reference to generate an ID.
  jsobj->AddServiceId(*this);
  if (ref) {
    return;
  }
  JSONArray members(jsobj, "members");
  Iterator iter(*this, PcDescriptorsLayout::kAnyKind);
  while (iter.MoveNext()) {
    JSONObject descriptor(&members);
    descriptor.AddPropertyF("pcOffset", "%" Px "", iter.PcOffset());
    descriptor.AddProperty("kind", KindAsStr(iter.Kind()));
    descriptor.AddProperty("deoptId", iter.DeoptId());
    // TODO(turnidge): Use AddLocation instead.
    descriptor.AddProperty("tokenPos", iter.TokenPos());
    descriptor.AddProperty("tryIndex", iter.TryIndex());
  }
}

void PcDescriptors::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintToJSONObject(&jsobj, ref);
}

void CodeSourceMap::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void CompressedStackMaps::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void LocalVarDescriptors::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  // TODO(johnmccutchan): Generate a stable id. LocalVarDescriptors hang off
  // a Code object but do not have a back reference to generate an ID.
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
  JSONArray members(&jsobj, "members");
  String& var_name = String::Handle();
  for (intptr_t i = 0; i < Length(); i++) {
    LocalVarDescriptorsLayout::VarInfo info;
    var_name = GetName(i);
    GetInfo(i, &info);
    JSONObject var(&members);
    var.AddProperty("name", var_name.ToCString());
    var.AddProperty("index", static_cast<intptr_t>(info.index()));
    var.AddProperty("declarationTokenPos", info.declaration_pos);
    var.AddProperty("scopeStartTokenPos", info.begin_pos);
    var.AddProperty("scopeEndTokenPos", info.end_pos);
    var.AddProperty("scopeId", static_cast<intptr_t>(info.scope_id));
    var.AddProperty("kind", KindToCString(info.kind()));
  }
}

void ExceptionHandlers::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void ParameterTypeCheck::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void SingleTargetCache::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_target", Code::Handle(target()));
  if (ref) {
    return;
  }
  jsobj.AddProperty("_lowerLimit", lower_limit());
  jsobj.AddProperty("_upperLimit", upper_limit());
}

void UnlinkedCall::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_selector", String::Handle(target_name()).ToCString());
  if (ref) {
    return;
  }
  jsobj.AddProperty("_argumentsDescriptor",
                    Array::Handle(arguments_descriptor()));
}

void MonomorphicSmiableCall::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_expectedClassId", Smi::Handle(Smi::New(expected_cid())));
  if (ref) {
    return;
  }
  jsobj.AddProperty("_target", Code::Handle(target()));
}

void CallSiteData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}

void ICData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_owner", Object::Handle(Owner()));
  jsobj.AddProperty("_selector", String::Handle(target_name()).ToCString());
  if (ref) {
    return;
  }
  jsobj.AddProperty("_argumentsDescriptor",
                    Object::Handle(arguments_descriptor()));
  jsobj.AddProperty("_entries", Object::Handle(entries()));
}

void ICData::PrintToJSONArray(const JSONArray& jsarray,
                              TokenPosition token_pos) const {
  Isolate* isolate = Isolate::Current();
  Class& cls = Class::Handle();
  Function& func = Function::Handle();

  JSONObject jsobj(&jsarray);
  jsobj.AddProperty("name", String::Handle(target_name()).ToCString());
  jsobj.AddProperty("tokenPos", token_pos.value());
  // TODO(rmacnak): Figure out how to stringify DeoptReasons().
  // jsobj.AddProperty("deoptReasons", ...);

  JSONArray cache_entries(&jsobj, "cacheEntries");
  for (intptr_t i = 0; i < NumberOfChecks(); i++) {
    JSONObject cache_entry(&cache_entries);
    func = GetTargetAt(i);
    intptr_t count = GetCountAt(i);
    if (!is_static_call()) {
      intptr_t cid = GetReceiverClassIdAt(i);
      cls = isolate->class_table()->At(cid);
      cache_entry.AddProperty("receiver", cls);
    }
    cache_entry.AddProperty("target", func);
    cache_entry.AddProperty("count", count);
  }
}

void Code::PrintJSONImpl(JSONStream* stream, bool ref) const {
  // N.B. This is polymorphic with Bytecode.

  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Code", ref);
  jsobj.AddFixedServiceId("code/%" Px64 "-%" Px "", compile_timestamp(),
                          PayloadStart());
  const char* qualified_name = QualifiedName(
      NameFormattingParams(kUserVisibleName, NameDisambiguation::kNo));
  const char* vm_name = Name();
  AddNameProperties(&jsobj, qualified_name, vm_name);
  const bool is_stub =
      IsStubCode() || IsAllocationStubCode() || IsTypeTestStubCode();
  if (is_stub) {
    jsobj.AddProperty("kind", "Stub");
  } else {
    jsobj.AddProperty("kind", "Dart");
  }
  jsobj.AddProperty("_optimized", is_optimized());
  const Object& obj = Object::Handle(owner());
  if (obj.IsFunction()) {
    const Function& func = Function::Cast(obj);
    jsobj.AddProperty("_intrinsic", func.is_intrinsic());
    jsobj.AddProperty("_native", func.is_native());
  } else {
    jsobj.AddProperty("_intrinsic", false);
    jsobj.AddProperty("_native", false);
  }
  if (ref) {
    return;
  }
  if (obj.IsFunction()) {
    jsobj.AddProperty("function", obj);
  } else {
    // Generate a fake function reference.
    JSONObject func(&jsobj, "function");
    func.AddProperty("type", "@Function");
    func.AddProperty("_kind", "Stub");
    ASSERT(strcmp(qualified_name, vm_name) == 0);
    func.AddProperty("name", vm_name);
    AddNameProperties(&func, vm_name, vm_name);
  }
  jsobj.AddPropertyF("_startAddress", "%" Px "", PayloadStart());
  jsobj.AddPropertyF("_endAddress", "%" Px "", PayloadStart() + Size());
  jsobj.AddProperty("_alive", is_alive());
  const ObjectPool& object_pool = ObjectPool::Handle(GetObjectPool());
  jsobj.AddProperty("_objectPool", object_pool);
  {
    JSONArray jsarr(&jsobj, "_disassembly");
    if (is_alive()) {
      // Only disassemble alive code objects.
      DisassembleToJSONStream formatter(jsarr);
      Disassemble(&formatter);
    }
  }
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  if (!descriptors.IsNull()) {
    JSONObject desc(&jsobj, "_descriptors");
    descriptors.PrintToJSONObject(&desc, false);
  }

  PrintJSONInlineIntervals(&jsobj);
}

void Bytecode::PrintJSONImpl(JSONStream* stream, bool ref) const {
  // N.B. This is polymorphic with Code.

  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Code", ref);
  int64_t compile_timestamp = 0;
  jsobj.AddFixedServiceId("code/%" Px64 "-%" Px "", compile_timestamp,
                          PayloadStart());
  const char* qualified_name = QualifiedName();
  const char* vm_name = Name();
  AddNameProperties(&jsobj, qualified_name, vm_name);

  jsobj.AddProperty("kind", "Dart");
  jsobj.AddProperty("_optimized", false);
  jsobj.AddProperty("_intrinsic", false);
  jsobj.AddProperty("_native", false);
  if (ref) {
    return;
  }
  const Function& fun = Function::Handle(function());
  jsobj.AddProperty("function", fun);
  jsobj.AddPropertyF("_startAddress", "%" Px "", PayloadStart());
  jsobj.AddPropertyF("_endAddress", "%" Px "", PayloadStart() + Size());
  jsobj.AddProperty("_alive", true);
  const ObjectPool& obj_pool = ObjectPool::Handle(object_pool());
  jsobj.AddProperty("_objectPool", obj_pool);
  {
    JSONArray jsarr(&jsobj, "_disassembly");
    DisassembleToJSONStream formatter(jsarr);
    Disassemble(&formatter);
  }
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  if (!descriptors.IsNull()) {
    JSONObject desc(&jsobj, "_descriptors");
    descriptors.PrintToJSONObject(&desc, false);
  }

  { JSONArray inlined_functions(&jsobj, "_inlinedFunctions"); }
  { JSONArray inline_intervals(&jsobj, "_inlinedIntervals"); }
}

void Context::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  // TODO(turnidge): Should the user level type for Context be Context
  // or Object?
  AddCommonObjectProperties(&jsobj, "Context", ref);
  jsobj.AddServiceId(*this);

  jsobj.AddProperty("length", num_variables());

  if (ref) {
    return;
  }

  const Context& parent_context = Context::Handle(parent());
  if (!parent_context.IsNull()) {
    jsobj.AddProperty("parent", parent_context);
  }

  JSONArray jsarr(&jsobj, "variables");
  Object& var = Object::Handle();
  for (intptr_t index = 0; index < num_variables(); index++) {
    var = At(index);
    JSONObject jselement(&jsarr);
    jselement.AddProperty("value", var);
  }
}

void ContextScope::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void MegamorphicCache::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_selector", String::Handle(target_name()).ToCString());
  if (ref) {
    return;
  }
  jsobj.AddProperty("_buckets", Object::Handle(buckets()));
  jsobj.AddProperty("_mask", mask());
  jsobj.AddProperty("_argumentsDescriptor",
                    Object::Handle(arguments_descriptor()));
}

void SubtypeTestCache::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
  jsobj.AddProperty("_cache", Array::Handle(cache()));
}

void LoadingUnit::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
  jsobj.AddProperty("_parent", LoadingUnit::Handle(parent()));
  jsobj.AddProperty("_baseObjects", Array::Handle(base_objects()));
  jsobj.AddProperty("_id", static_cast<intptr_t>(id()));
  jsobj.AddProperty("_loaded", loaded());
  jsobj.AddProperty("_loadOutstanding", load_outstanding());
}

void Error::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}

void ApiError::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "InternalError");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
}

void LanguageError::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "LanguageError");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
}

void UnhandledException::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "UnhandledException");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
  if (ref) {
    return;
  }
  Instance& instance = Instance::Handle();
  instance = exception();
  jsobj.AddProperty("exception", instance);
  instance = stacktrace();
  jsobj.AddProperty("stacktrace", instance);
}

void UnwindError::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "TerminationError");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
  jsobj.AddProperty("_is_user_initiated", is_user_initiated());
}

void Instance::PrintSharedInstanceJSON(JSONObject* jsobj, bool ref) const {
  AddCommonObjectProperties(jsobj, "Instance", ref);
  if (ref) {
    return;
  }

  // Add all fields in layout order, from superclass to subclass.
  GrowableArray<Class*> classes;
  Class& cls = Class::Handle(this->clazz());
  if (IsClosure()) {
    // Closure fields are not instances. Skip them.
    cls = cls.SuperClass();
  }
  do {
    classes.Add(&Class::Handle(cls.raw()));
    cls = cls.SuperClass();
  } while (!cls.IsNull());

  Array& field_array = Array::Handle();
  Field& field = Field::Handle();
  Instance& field_value = Instance::Handle();
  {
    JSONArray jsarr(jsobj, "fields");
    for (intptr_t i = classes.length() - 1; i >= 0; i--) {
      field_array = classes[i]->fields();
      if (!field_array.IsNull()) {
        for (intptr_t j = 0; j < field_array.Length(); j++) {
          field ^= field_array.At(j);
          if (!field.is_static()) {
            field_value ^= GetField(field);
            JSONObject jsfield(&jsarr);
            jsfield.AddProperty("type", "BoundField");
            jsfield.AddProperty("decl", field);
            jsfield.AddProperty("value", field_value);
          }
        }
      }
    }
  }

  if (NumNativeFields() > 0) {
    JSONArray jsarr(jsobj, "_nativeFields");
    for (intptr_t i = 0; i < NumNativeFields(); i++) {
      intptr_t value = GetNativeField(i);
      JSONObject jsfield(&jsarr);
      jsfield.AddProperty("index", i);
      jsfield.AddProperty("value", value);
    }
  }
}

void Instance::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);

  // Handle certain special instance values.
  if (raw() == Object::sentinel().raw()) {
    jsobj.AddProperty("type", "Sentinel");
    jsobj.AddProperty("kind", "NotInitialized");
    jsobj.AddProperty("valueAsString", "<not initialized>");
    return;
  } else if (raw() == Object::transition_sentinel().raw()) {
    jsobj.AddProperty("type", "Sentinel");
    jsobj.AddProperty("kind", "BeingInitialized");
    jsobj.AddProperty("valueAsString", "<being initialized>");
    return;
  }

  PrintSharedInstanceJSON(&jsobj, ref);
  // TODO(regis): Wouldn't it be simpler to provide a Closure::PrintJSONImpl()?
  if (IsClosure()) {
    jsobj.AddProperty("kind", "Closure");
  } else {
    jsobj.AddProperty("kind", "PlainInstance");
  }
  jsobj.AddServiceId(*this);
  if (IsClosure()) {
    // TODO(regis): How about closureInstantiatorTypeArguments and
    // closureFunctionTypeArguments?
    jsobj.AddProperty("closureFunction",
                      Function::Handle(Closure::Cast(*this).function()));
    jsobj.AddProperty("closureContext",
                      Context::Handle(Closure::Cast(*this).context()));
  }
  if (ref) {
    return;
  }
  if (IsClosure()) {
    Debugger* debugger = Isolate::Current()->debugger();
    Breakpoint* bpt = debugger->BreakpointAtActivation(*this);
    if (bpt != NULL) {
      jsobj.AddProperty("_activationBreakpoint", bpt);
    }
  }
}

void AbstractType::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}

void Type::PrintJSONImpl(JSONStream* stream, bool ref) const {
  // TODO(regis): Function types are not handled properly.
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Type");
  const Class& type_cls = Class::Handle(type_class());
  if (type_cls.DeclarationType() == raw()) {
    intptr_t cid = type_cls.id();
    jsobj.AddFixedServiceId("classes/%" Pd "/types/%d", cid, 0);
  } else {
    jsobj.AddServiceId(*this);
  }
  jsobj.AddProperty("typeClass", type_cls);
  const String& user_name = String::Handle(UserVisibleName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name.ToCString(), vm_name.ToCString());
  if (ref) {
    return;
  }
  const TypeArguments& typeArgs = TypeArguments::Handle(arguments());
  if (!typeArgs.IsNull()) {
    jsobj.AddProperty("typeArguments", typeArgs);
  }
}

void TypeRef::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "TypeRef");
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(UserVisibleName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name.ToCString(), vm_name.ToCString());
  if (ref) {
    return;
  }
  jsobj.AddProperty("targetType", AbstractType::Handle(type()));
}

void TypeParameter::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "TypeParameter");
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(UserVisibleName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name.ToCString(), vm_name.ToCString());
  const Class& param_cls = Class::Handle(parameterized_class());
  jsobj.AddProperty("parameterizedClass", param_cls);
  if (ref) {
    return;
  }
  jsobj.AddProperty("parameterIndex", index());
  const AbstractType& upper_bound = AbstractType::Handle(bound());
  jsobj.AddProperty("bound", upper_bound);
}

void Number::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}

void Integer::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Int");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}

void Smi::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Int");
  jsobj.AddFixedServiceId("objects/int-%" Pd "", Value());
  jsobj.AddPropertyF("valueAsString", "%" Pd "", Value());
}

void Mint::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Integer::PrintJSONImpl(stream, ref);
}

void Double::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Double");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}

void String::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  if (raw() == Symbols::OptimizedOut().raw()) {
    // TODO(turnidge): This is a hack.  The user could have this
    // special string in their program.  Fixing this involves updating
    // the debugging api a bit.
    jsobj.AddProperty("type", "Sentinel");
    jsobj.AddProperty("kind", "OptimizedOut");
    jsobj.AddProperty("valueAsString", "<optimized out>");
    return;
  }
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "String");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    // String refs always truncate to a fixed count;
    const intptr_t kFixedCount = 128;
    if (jsobj.AddPropertyStr("valueAsString", *this, 0, kFixedCount)) {
      jsobj.AddProperty("count", kFixedCount);
      jsobj.AddProperty("valueAsStringIsTruncated", true);
    }
    return;
  }

  intptr_t offset;
  intptr_t count;
  stream->ComputeOffsetAndCount(Length(), &offset, &count);
  if (offset > 0) {
    jsobj.AddProperty("offset", offset);
  }
  if (count < Length()) {
    jsobj.AddProperty("count", count);
  }
  jsobj.AddPropertyStr("valueAsString", *this, offset, count);
}

void Bool::PrintJSONImpl(JSONStream* stream, bool ref) const {
  const char* str = ToCString();
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Bool");
  jsobj.AddFixedServiceId("objects/bool-%s", str);
  jsobj.AddPropertyF("valueAsString", "%s", str);
}

void Array::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "List");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  intptr_t offset;
  intptr_t count;
  stream->ComputeOffsetAndCount(Length(), &offset, &count);
  if (offset > 0) {
    jsobj.AddProperty("offset", offset);
  }
  if (count < Length()) {
    jsobj.AddProperty("count", count);
  }
  intptr_t limit = offset + count;
  ASSERT(limit <= Length());
  {
    JSONArray jsarr(&jsobj, "elements");
    Object& element = Object::Handle();
    for (intptr_t index = offset; index < limit; index++) {
      element = At(index);
      jsarr.AddValue(element);
    }
  }
}

void GrowableObjectArray::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "List");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  intptr_t offset;
  intptr_t count;
  stream->ComputeOffsetAndCount(Length(), &offset, &count);
  if (offset > 0) {
    jsobj.AddProperty("offset", offset);
  }
  if (count < Length()) {
    jsobj.AddProperty("count", count);
  }
  intptr_t limit = offset + count;
  ASSERT(limit <= Length());
  {
    JSONArray jsarr(&jsobj, "elements");
    Object& element = Object::Handle();
    for (intptr_t index = offset; index < limit; index++) {
      element = At(index);
      jsarr.AddValue(element);
    }
  }
}

void LinkedHashMap::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Map");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  intptr_t offset;
  intptr_t count;
  stream->ComputeOffsetAndCount(Length(), &offset, &count);
  if (offset > 0) {
    jsobj.AddProperty("offset", offset);
  }
  if (count < Length()) {
    jsobj.AddProperty("count", count);
  }
  intptr_t limit = offset + count;
  ASSERT(limit <= Length());
  {
    JSONArray jsarr(&jsobj, "associations");
    Object& object = Object::Handle();
    LinkedHashMap::Iterator iterator(*this);
    int i = 0;
    while (iterator.MoveNext() && i < limit) {
      if (i >= offset) {
        JSONObject jsassoc(&jsarr);
        object = iterator.CurrentKey();
        jsassoc.AddProperty("key", object);
        object = iterator.CurrentValue();
        jsassoc.AddProperty("value", object);
      }
      i++;
    }
  }
}

void Float32x4::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Float32x4");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}

void Int32x4::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Int32x4");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}

void Float64x2::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Float64x2");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}

void TypedDataBase::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}

void TypedData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  const Class& cls = Class::Handle(clazz());
  const char* kind = cls.UserVisibleNameCString();
  jsobj.AddProperty("kind", kind);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  intptr_t offset;
  intptr_t count;
  stream->ComputeOffsetAndCount(Length(), &offset, &count);
  if (offset > 0) {
    jsobj.AddProperty("offset", offset);
  }
  if (count < Length()) {
    jsobj.AddProperty("count", count);
  }
  if (count == 0) {
    jsobj.AddProperty("bytes", "");
  } else {
    NoSafepointScope no_safepoint;
    jsobj.AddPropertyBase64("bytes",
                            reinterpret_cast<const uint8_t*>(
                                DataAddr(offset * ElementSizeInBytes())),
                            count * ElementSizeInBytes());
  }
}

void TypedDataView::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void ExternalTypedData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  const Class& cls = Class::Handle(clazz());
  const char* kind = cls.UserVisibleNameCString();
  jsobj.AddProperty("kind", kind);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  intptr_t offset;
  intptr_t count;
  stream->ComputeOffsetAndCount(Length(), &offset, &count);
  if (offset > 0) {
    jsobj.AddProperty("offset", offset);
  }
  if (count < Length()) {
    jsobj.AddProperty("count", count);
  }
  if (count == 0) {
    jsobj.AddProperty("bytes", "");
  } else {
    NoSafepointScope no_safepoint;
    jsobj.AddPropertyBase64("bytes",
                            reinterpret_cast<const uint8_t*>(
                                DataAddr(offset * ElementSizeInBytes())),
                            count * ElementSizeInBytes());
  }
}

void Pointer::PrintJSONImpl(JSONStream* stream, bool ref) const {
  // TODO(dacoharkes): what is the JSONStream used for?
  // should it fail because it's not supported?
  // or should it print something reasonable as default?
  Instance::PrintJSONImpl(stream, ref);
}

void DynamicLibrary::PrintJSONImpl(JSONStream* stream, bool ref) const {
  // TODO(dacoharkes): what is the JSONStream used for?
  // should it fail because it's not supported?
  // or should it print something reasonable as default?
  Instance::PrintJSONImpl(stream, ref);
}

void Capability::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void ReceivePort::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void SendPort::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void TransferableTypedData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void ClosureData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void SignatureData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}

void Closure::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void StackTrace::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "StackTrace");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}

void RegExp::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "RegExp");
  jsobj.AddServiceId(*this);

  jsobj.AddProperty("pattern", String::Handle(pattern()));

  if (ref) {
    return;
  }

  jsobj.AddProperty("isCaseSensitive", !flags().IgnoreCase());
  jsobj.AddProperty("isMultiLine", flags().IsMultiLine());

  if (!FLAG_interpret_irregexp) {
    Function& func = Function::Handle();
    func = function(kOneByteStringCid, /*sticky=*/false);
    jsobj.AddProperty("_oneByteFunction", func);
    func = function(kTwoByteStringCid, /*sticky=*/false);
    jsobj.AddProperty("_twoByteFunction", func);
    func = function(kExternalOneByteStringCid, /*sticky=*/false);
    jsobj.AddProperty("_externalOneByteFunction", func);
    func = function(kExternalTwoByteStringCid, /*sticky=*/false);
    jsobj.AddProperty("_externalTwoByteFunction", func);
    func = function(kOneByteStringCid, /*sticky=*/true);
    jsobj.AddProperty("_oneByteFunctionSticky", func);
    func = function(kTwoByteStringCid, /*sticky=*/true);
    jsobj.AddProperty("_twoByteFunctionSticky", func);
    func = function(kExternalOneByteStringCid, /*sticky=*/true);
    jsobj.AddProperty("_externalOneByteFunctionSticky", func);
    func = function(kExternalTwoByteStringCid, /*sticky=*/true);
    jsobj.AddProperty("_externalTwoByteFunctionSticky", func);
  } else {
    TypedData& bc = TypedData::Handle();
    bc = bytecode(/*is_one_byte=*/true, /*sticky=*/false);
    jsobj.AddProperty("_oneByteBytecode", bc);
    bc = bytecode(/*is_one_byte=*/false, /*sticky=*/false);
    jsobj.AddProperty("_twoByteBytecode", bc);
    bc = bytecode(/*is_one_byte=*/true, /*sticky=*/true);
    jsobj.AddProperty("_oneByteBytecodeSticky", bc);
    bc = bytecode(/*is_one_byte=*/false, /*sticky=*/true);
    jsobj.AddProperty("_twoByteBytecodeSticky", bc);
  }
}

void WeakProperty::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "WeakProperty");
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }

  const Object& key_handle = Object::Handle(key());
  jsobj.AddProperty("propertyKey", key_handle);
  const Object& value_handle = Object::Handle(value());
  jsobj.AddProperty("propertyValue", value_handle);
}

void MirrorReference::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "MirrorReference");
  jsobj.AddServiceId(*this);

  if (ref) {
    return;
  }

  const Object& referent_handle = Object::Handle(referent());
  jsobj.AddProperty("mirrorReferent", referent_handle);
}

void UserTag::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

void FutureOr::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}

#endif

}  // namespace dart
