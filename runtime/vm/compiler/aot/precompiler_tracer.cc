// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/aot/precompiler_tracer.h"

#include "vm/compiler/aot/precompiler.h"
#include "vm/zone_text_buffer.h"

namespace dart {

#if defined(DART_PRECOMPILER)

DEFINE_FLAG(charp,
            trace_precompiler_to,
            nullptr,
            "Output machine readable precompilation trace into the given file");

PrecompilerTracer* PrecompilerTracer::StartTracingIfRequested(
    Precompiler* precompiler) {
  if (FLAG_trace_precompiler_to != nullptr &&
      Dart::file_write_callback() != nullptr &&
      Dart::file_open_callback() != nullptr &&
      Dart::file_close_callback() != nullptr) {
    return new PrecompilerTracer(
        precompiler, Dart::file_open_callback()(FLAG_trace_precompiler_to,
                                                /*write=*/true));
  }
  return nullptr;
}

PrecompilerTracer::PrecompilerTracer(Precompiler* precompiler, void* stream)
    : zone_(Thread::Current()->zone()),
      precompiler_(precompiler),
      buffer_(1024),
      stream_(stream),
      strings_(HashTables::New<StringTable>(1024)),
      entities_(HashTables::New<EntityTable>(1024)),
      object_(Object::Handle()),
      cls_(Class::Handle()) {
  Write("{\"trace\":[\"R\",");
}

void PrecompilerTracer::Finalize() {
  Write("\"E\"],");
  WriteEntityTable();
  Write(",");
  WriteStringTable();
  Write("}\n");

  const intptr_t output_length = buffer_.length();
  char* output = buffer_.Steal();
  Dart::file_write_callback()(output, output_length, stream_);
  free(output);
  Dart::file_close_callback()(stream_);

  strings_.Release();
  entities_.Release();
}

void PrecompilerTracer::WriteEntityTable() {
  Write("\"entities\":[");
  const auto& entities_by_id =
      Array::Handle(zone_, Array::New(entities_.NumOccupied()));

  EntityTable::Iterator it(&entities_);
  while (it.MoveNext()) {
    object_ = entities_.GetPayload(it.Current(), 0);
    const intptr_t index = Smi::Cast(object_).Value();
    object_ = entities_.GetKey(it.Current());
    entities_by_id.SetAt(index, object_);
  }

  auto& obj = Object::Handle(zone_);
  auto& lib = Library::Handle(zone_);
  auto& str = String::Handle(zone_);
  for (intptr_t i = 0; i < entities_by_id.Length(); i++) {
    if (i > 0) {
      Write(",");
    }
    obj = entities_by_id.At(i);
    if (obj.IsFunction()) {
      const auto& fun = Function::Cast(obj);
      cls_ = fun.Owner();
      const intptr_t selector_id =
          FLAG_use_bare_instructions && FLAG_use_table_dispatch
              ? precompiler_->selector_map()->SelectorId(fun)
              : -1;
      Write("\"%c\",%" Pd ",%" Pd ",%" Pd "",
            fun.IsDynamicFunction() ? 'F' : 'S', InternEntity(cls_),
            InternString(NameForTrace(fun)), selector_id);
    } else if (obj.IsField()) {
      const auto& field = Field::Cast(obj);
      cls_ = field.Owner();
      str = field.name();
      Write("\"V\",%" Pd ",%" Pd ",0", InternEntity(cls_), InternString(str));
    } else if (obj.IsClass()) {
      const auto& cls = Class::Cast(obj);
      lib = cls.library();
      str = lib.url();
      const auto url_id = InternString(str);
      str = cls.ScrubbedName();
      const auto name_id = InternString(str);
      Write("\"C\",%" Pd ",%" Pd ",0", url_id, name_id);
    } else {
      UNREACHABLE();
    }
  }
  Write("]");
}

void PrecompilerTracer::WriteStringTable() {
  Write("\"strings\":[");
  GrowableArray<const char*> strings_by_id(strings_.NumOccupied());
  strings_by_id.EnsureLength(strings_.NumOccupied(), nullptr);
  StringTable::Iterator it(&strings_);
  while (it.MoveNext()) {
    object_ = strings_.GetPayload(it.Current(), 0);
    const auto index = Smi::Cast(object_).Value();
    object_ = strings_.GetKey(it.Current());
    strings_by_id[index] = String::Cast(object_).ToCString();
  }
  auto comma = false;
  for (auto str : strings_by_id) {
    Write("%s\"%s\"", comma ? "," : "", str);
    comma = true;
  }
  Write("]");
}

intptr_t PrecompilerTracer::InternString(const CString& cstr) {
  object_ = Smi::New(strings_.NumOccupied());
  object_ = strings_.InsertNewOrGetValue(cstr, object_);
  return Smi::Cast(object_).Value();
}

intptr_t PrecompilerTracer::InternString(const String& str) {
  object_ = Smi::New(strings_.NumOccupied());
  object_ = strings_.InsertOrGetValue(str, object_);
  return Smi::Cast(object_).Value();
}

intptr_t PrecompilerTracer::InternEntity(const Object& obj) {
  ASSERT(obj.IsFunction() || obj.IsClass() || obj.IsField());
  const auto num_occupied = entities_.NumOccupied();
  object_ = Smi::New(num_occupied);
  object_ = entities_.InsertOrGetValue(obj, object_);
  const auto id = Smi::Cast(object_).Value();
  if (id == num_occupied) {
    cls_ = Class::null();
    if (obj.IsFunction()) {
      cls_ = Function::Cast(obj).Owner();
    } else if (obj.IsField()) {
      cls_ = Field::Cast(obj).Owner();
    }
    if (cls_.raw() != Class::null()) {
      InternEntity(cls_);
    }
  }
  return id;
}

PrecompilerTracer::CString PrecompilerTracer::NameForTrace(const Function& f) {
  ZoneTextBuffer buffer(zone_);
  f.PrintName(NameFormattingParams::DisambiguatedWithoutClassName(
                  Object::NameVisibility::kInternalName),
              &buffer);
  return {buffer.buffer(), buffer.length(),
          String::Hash(buffer.buffer(), buffer.length())};
}

#endif  // defined(DART_PRECOMPILER)

}  // namespace dart
