// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate_reload.h"

#include <memory>

#include "vm/bit_vector.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/hash.h"
#endif
#include "vm/hash_table.h"
#include "vm/heap/become.h"
#include "vm/heap/safepoint.h"
#include "vm/isolate.h"
#include "vm/kernel_isolate.h"
#include "vm/kernel_loader.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/runtime_entry.h"
#include "vm/service_event.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(int, reload_every, 0, "Reload every N stack overflow checks.");
DEFINE_FLAG(bool, trace_reload, false, "Trace isolate reloading");

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
DEFINE_FLAG(bool,
            trace_reload_verbose,
            false,
            "trace isolate reloading verbose");
DEFINE_FLAG(bool, identity_reload, false, "Enable checks for identity reload.");
DEFINE_FLAG(bool, reload_every_optimized, true, "Only from optimized code.");
DEFINE_FLAG(bool,
            reload_every_back_off,
            false,
            "Double the --reload-every value after each reload.");
DEFINE_FLAG(bool,
            reload_force_rollback,
            false,
            "Force all reloads to fail and rollback.");
DEFINE_FLAG(bool,
            check_reloaded,
            false,
            "Assert that an isolate has reloaded at least once.")
DEFINE_FLAG(bool, gc_during_reload, false, "Cause explicit GC during reload.");

DECLARE_FLAG(bool, trace_deoptimization);

#define IG (isolate_group())
#define Z zone_

#define TIMELINE_SCOPE(name)                                                   \
  TimelineBeginEndScope tbes##name(Thread::Current(),                          \
                                   Timeline::GetIsolateStream(), #name)

// The ObjectLocator is used for collecting instances that
// needs to be morphed.
class ObjectLocator : public ObjectVisitor {
 public:
  explicit ObjectLocator(IsolateGroupReloadContext* context)
      : context_(context), count_(0) {}

  void VisitObject(ObjectPtr obj) {
    InstanceMorpher* morpher =
        context_->instance_morpher_by_cid_.LookupValue(obj->GetClassId());
    if (morpher != NULL) {
      morpher->AddObject(obj);
      count_++;
    }
  }

  // Return the number of located objects for morphing.
  intptr_t count() { return count_; }

 private:
  IsolateGroupReloadContext* context_;
  intptr_t count_;
};

static bool HasNoTasks(Heap* heap) {
  MonitorLocker ml(heap->old_space()->tasks_lock());
  return heap->old_space()->tasks() == 0;
}

InstanceMorpher* InstanceMorpher::CreateFromClassDescriptors(
    Zone* zone,
    SharedClassTable* shared_class_table,
    const Class& from,
    const Class& to) {
  auto mapping = new (zone) ZoneGrowableArray<intptr_t>();
  auto new_fields_offsets = new (zone) ZoneGrowableArray<intptr_t>();

  if (from.NumTypeArguments() > 0) {
    // Add copying of the optional type argument field.
    intptr_t from_offset = from.host_type_arguments_field_offset();
    ASSERT(from_offset != Class::kNoTypeArguments);
    intptr_t to_offset = to.host_type_arguments_field_offset();
    ASSERT(to_offset != Class::kNoTypeArguments);
    mapping->Add(from_offset);
    mapping->Add(to_offset);
  }

  // Add copying of the instance fields if matching by name.
  // Note: currently the type of the fields are ignored.
  const Array& from_fields =
      Array::Handle(from.OffsetToFieldMap(true /* original classes */));
  const Array& to_fields = Array::Handle(to.OffsetToFieldMap());
  Field& from_field = Field::Handle();
  Field& to_field = Field::Handle();
  String& from_name = String::Handle();
  String& to_name = String::Handle();

  // Scan across all the fields in the new class definition.
  for (intptr_t i = 0; i < to_fields.Length(); i++) {
    if (to_fields.At(i) == Field::null()) {
      continue;  // Ignore non-fields.
    }

    // Grab the field's name.
    to_field = Field::RawCast(to_fields.At(i));
    ASSERT(to_field.is_instance());
    to_name = to_field.name();

    // Did this field not exist in the old class definition?
    bool new_field = true;

    // Find this field in the old class.
    for (intptr_t j = 0; j < from_fields.Length(); j++) {
      if (from_fields.At(j) == Field::null()) {
        continue;  // Ignore non-fields.
      }
      from_field = Field::RawCast(from_fields.At(j));
      ASSERT(from_field.is_instance());
      from_name = from_field.name();
      if (from_name.Equals(to_name)) {
        // Success
        mapping->Add(from_field.HostOffset());
        mapping->Add(to_field.HostOffset());
        // Field did exist in old class deifnition.
        new_field = false;
      }
    }

    if (new_field) {
      const Field& field = Field::Handle(to_field.ptr());
      field.set_needs_load_guard(true);
      field.set_is_unboxing_candidate_unsafe(false);
      new_fields_offsets->Add(field.HostOffset());
    }
  }

  ASSERT(from.id() == to.id());
  return new (zone) InstanceMorpher(zone, to.id(), shared_class_table, mapping,
                                    new_fields_offsets);
}

InstanceMorpher::InstanceMorpher(
    Zone* zone,
    classid_t cid,
    SharedClassTable* shared_class_table,
    ZoneGrowableArray<intptr_t>* mapping,
    ZoneGrowableArray<intptr_t>* new_fields_offsets)
    : zone_(zone),
      cid_(cid),
      shared_class_table_(shared_class_table),
      mapping_(mapping),
      new_fields_offsets_(new_fields_offsets),
      before_(zone, 16),
      after_(zone, 16) {}

void InstanceMorpher::AddObject(ObjectPtr object) {
  ASSERT(object->GetClassId() == cid_);
  const Instance& instance = Instance::Cast(Object::Handle(Z, object));
  before_.Add(&instance);
}

InstancePtr InstanceMorpher::Morph(const Instance& instance) const {
  // Code can reference constants / canonical objects either directly in the
  // instruction stream (ia32) or via an object pool.
  //
  // We have the following invariants:
  //
  //    a) Those canonical objects don't change state (i.e. are not mutable):
  //       our optimizer can e.g. execute loads of such constants at
  //       compile-time.
  //
  //       => We ensure that const-classes with live constants cannot be
  //          reloaded to become non-const classes (see Class::CheckReload).
  //
  //    b) Those canonical objects live in old space: e.g. on ia32 the scavenger
  //       does not make the RX pages writable and therefore cannot update
  //       pointers embedded in the instruction stream.
  //
  // In order to maintain these invariants we ensure to always morph canonical
  // objects to old space.
  const bool is_canonical = instance.IsCanonical();
  const Heap::Space space = is_canonical ? Heap::kOld : Heap::kNew;
  const auto& result = Instance::Handle(
      Z, Instance::NewFromCidAndSize(shared_class_table_, cid_, space));

  // We preserve the canonical bit of the object, since this object is present
  // in the class's constants.
  if (is_canonical) {
    result.SetCanonical();
  }
#if defined(HASH_IN_OBJECT_HEADER)
  const uint32_t hash = Object::GetCachedHash(instance.ptr());
  Object::SetCachedHashIfNotSet(result.ptr(), hash);
#endif

  // Morph the context from instance to result using mapping_.
  Object& value = Object::Handle(Z);
  for (intptr_t i = 0; i < mapping_->length(); i += 2) {
    intptr_t from_offset = mapping_->At(i);
    intptr_t to_offset = mapping_->At(i + 1);
    ASSERT(from_offset > 0);
    ASSERT(to_offset > 0);
    value = instance.RawGetFieldAtOffset(from_offset);
    result.RawSetFieldAtOffset(to_offset, value);
  }

  for (intptr_t i = 0; i < new_fields_offsets_->length(); i++) {
    const intptr_t field_offset = new_fields_offsets_->At(i);
    result.RawSetFieldAtOffset(field_offset, Object::sentinel());
  }

  // Convert the instance into a filler object.
  Become::MakeDummyObject(instance);
  return result.ptr();
}

void InstanceMorpher::CreateMorphedCopies() {
  for (intptr_t i = 0; i < before_.length(); i++) {
    const Instance& copy = Instance::Handle(Z, Morph(*before_.At(i)));
    after_.Add(&copy);
  }
}

void InstanceMorpher::Dump() const {
  LogBlock blocker;
  THR_Print("Morphing objects with cid: %d via this mapping: ", cid_);
  for (int i = 0; i < mapping_->length(); i += 2) {
    THR_Print(" %" Pd "->%" Pd, mapping_->At(i), mapping_->At(i + 1));
  }
  THR_Print("\n");
}

void InstanceMorpher::AppendTo(JSONArray* array) {
  JSONObject jsobj(array);
  jsobj.AddProperty("type", "ShapeChangeMapping");
  jsobj.AddProperty64("class-id", cid_);
  jsobj.AddProperty("instanceCount", before_.length());
  JSONArray map(&jsobj, "fieldOffsetMappings");
  for (int i = 0; i < mapping_->length(); i += 2) {
    JSONArray pair(&map);
    pair.AddValue(mapping_->At(i));
    pair.AddValue(mapping_->At(i + 1));
  }
}

void ReasonForCancelling::Report(IsolateGroupReloadContext* context) {
  const Error& error = Error::Handle(ToError());
  context->ReportError(error);
}

ErrorPtr ReasonForCancelling::ToError() {
  // By default create the error returned from ToString.
  const String& message = String::Handle(ToString());
  return LanguageError::New(message);
}

StringPtr ReasonForCancelling::ToString() {
  UNREACHABLE();
  return NULL;
}

void ReasonForCancelling::AppendTo(JSONArray* array) {
  JSONObject jsobj(array);
  jsobj.AddProperty("type", "ReasonForCancelling");
  const String& message = String::Handle(ToString());
  jsobj.AddProperty("message", message.ToCString());
}

ClassReasonForCancelling::ClassReasonForCancelling(Zone* zone,
                                                   const Class& from,
                                                   const Class& to)
    : ReasonForCancelling(zone),
      from_(Class::ZoneHandle(zone, from.ptr())),
      to_(Class::ZoneHandle(zone, to.ptr())) {}

void ClassReasonForCancelling::AppendTo(JSONArray* array) {
  JSONObject jsobj(array);
  jsobj.AddProperty("type", "ReasonForCancelling");
  jsobj.AddProperty("class", from_);
  const String& message = String::Handle(ToString());
  jsobj.AddProperty("message", message.ToCString());
}

ErrorPtr IsolateGroupReloadContext::error() const {
  ASSERT(!reasons_to_cancel_reload_.is_empty());
  // Report the first error to the surroundings.
  return reasons_to_cancel_reload_.At(0)->ToError();
}

class ScriptUrlSetTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "ScriptUrlSetTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    if (!a.IsString() || !b.IsString()) {
      return false;
    }

    return String::Cast(a).Equals(String::Cast(b));
  }

  static uword Hash(const Object& obj) { return String::Cast(obj).Hash(); }
};

class ClassMapTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "ClassMapTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    if (!a.IsClass() || !b.IsClass()) {
      return false;
    }
    return ProgramReloadContext::IsSameClass(Class::Cast(a), Class::Cast(b));
  }

  static uword Hash(const Object& obj) {
    uword class_name_hash = String::HashRawSymbol(Class::Cast(obj).Name());
    LibraryPtr raw_library = Class::Cast(obj).library();
    if (raw_library == Library::null()) {
      return class_name_hash;
    }
    return FinalizeHash(
        CombineHashes(class_name_hash,
                      String::Hash(Library::Handle(raw_library).private_key())),
        /* hashbits= */ 30);
  }
};

class LibraryMapTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "LibraryMapTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    if (!a.IsLibrary() || !b.IsLibrary()) {
      return false;
    }
    return ProgramReloadContext::IsSameLibrary(Library::Cast(a),
                                               Library::Cast(b));
  }

  static uword Hash(const Object& obj) { return Library::Cast(obj).UrlHash(); }
};

class BecomeMapTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "BecomeMapTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    return a.ptr() == b.ptr();
  }

  static uword Hash(const Object& obj) {
    if (obj.IsLibrary()) {
      return Library::Cast(obj).UrlHash();
    } else if (obj.IsClass()) {
      return String::HashRawSymbol(Class::Cast(obj).Name());
    } else if (obj.IsField()) {
      return String::HashRawSymbol(Field::Cast(obj).name());
    } else if (obj.IsClosure()) {
      return String::HashRawSymbol(
          Function::Handle(Closure::Cast(obj).function()).name());
    } else if (obj.IsLibraryPrefix()) {
      return String::HashRawSymbol(LibraryPrefix::Cast(obj).name());
    } else {
      FATAL1("Unexpected type in become: %s\n", obj.ToCString());
    }
    return 0;
  }
};

bool ProgramReloadContext::IsSameClass(const Class& a, const Class& b) {
  // TODO(turnidge): We need to look at generic type arguments for
  // synthetic mixin classes.  Their names are not necessarily unique
  // currently.
  const String& a_name = String::Handle(a.Name());
  const String& b_name = String::Handle(b.Name());

  if (!a_name.Equals(b_name)) {
    return false;
  }

  const Library& a_lib = Library::Handle(a.library());
  const Library& b_lib = Library::Handle(b.library());

  if (a_lib.IsNull() || b_lib.IsNull()) {
    return a_lib.ptr() == b_lib.ptr();
  }
  return (a_lib.private_key() == b_lib.private_key());
}

bool ProgramReloadContext::IsSameLibrary(const Library& a_lib,
                                         const Library& b_lib) {
  const String& a_lib_url =
      String::Handle(a_lib.IsNull() ? String::null() : a_lib.url());
  const String& b_lib_url =
      String::Handle(b_lib.IsNull() ? String::null() : b_lib.url());
  return a_lib_url.Equals(b_lib_url);
}

IsolateGroupReloadContext::IsolateGroupReloadContext(
    IsolateGroup* isolate_group,
    SharedClassTable* shared_class_table,
    JSONStream* js)
    : zone_(Thread::Current()->zone()),
      isolate_group_(isolate_group),
      shared_class_table_(shared_class_table),
      start_time_micros_(OS::GetCurrentMonotonicMicros()),
      reload_timestamp_(OS::GetCurrentTimeMillis()),
      js_(js),
      saved_size_table_(nullptr),
      instance_morphers_(zone_, 0),
      reasons_to_cancel_reload_(zone_, 0),
      instance_morpher_by_cid_(zone_),
      root_lib_url_(String::Handle(Z, String::null())),
      root_url_prefix_(String::null()),
      old_root_url_prefix_(String::null()) {}
IsolateGroupReloadContext::~IsolateGroupReloadContext() {}

ProgramReloadContext::ProgramReloadContext(
    std::shared_ptr<IsolateGroupReloadContext> group_reload_context,
    IsolateGroup* isolate_group)
    : zone_(Thread::Current()->zone()),
      group_reload_context_(group_reload_context),
      isolate_group_(isolate_group),
      saved_class_table_(nullptr),
      saved_tlc_class_table_(nullptr),
      old_classes_set_storage_(Array::null()),
      class_map_storage_(Array::null()),
      removed_class_set_storage_(Array::null()),
      old_libraries_set_storage_(Array::null()),
      library_map_storage_(Array::null()),
      become_map_storage_(Array::null()),
      become_enum_mappings_(GrowableObjectArray::null()),
      saved_root_library_(Library::null()),
      saved_libraries_(GrowableObjectArray::null()) {
  // NOTE: DO NOT ALLOCATE ANY RAW OBJECTS HERE. The ProgramReloadContext is not
  // associated with the isolate yet and if a GC is triggered here the raw
  // objects will not be properly accounted for.
  ASSERT(zone_ != NULL);
}

ProgramReloadContext::~ProgramReloadContext() {
  ASSERT(zone_ == Thread::Current()->zone());
  ASSERT(saved_class_table_.load(std::memory_order_relaxed) == nullptr);
  ASSERT(saved_tlc_class_table_.load(std::memory_order_relaxed) == nullptr);
}

void IsolateGroupReloadContext::ReportError(const Error& error) {
  IsolateGroup* isolate_group = IsolateGroup::Current();
  if (IsolateGroup::IsSystemIsolateGroup(isolate_group)) {
    return;
  }
  TIR_Print("ISO-RELOAD: Error: %s\n", error.ToErrorCString());
  ServiceEvent service_event(isolate_group, ServiceEvent::kIsolateReload);
  service_event.set_reload_error(&error);
  Service::HandleEvent(&service_event);
}

void IsolateGroupReloadContext::ReportSuccess() {
  IsolateGroup* isolate_group = IsolateGroup::Current();
  if (IsolateGroup::IsSystemIsolateGroup(isolate_group)) {
    return;
  }
  ServiceEvent service_event(isolate_group, ServiceEvent::kIsolateReload);
  Service::HandleEvent(&service_event);
}

class Aborted : public ReasonForCancelling {
 public:
  Aborted(Zone* zone, const Error& error)
      : ReasonForCancelling(zone),
        error_(Error::ZoneHandle(zone, error.ptr())) {}

 private:
  const Error& error_;

  ErrorPtr ToError() { return error_.ptr(); }
  StringPtr ToString() {
    return String::NewFormatted("%s", error_.ToErrorCString());
  }
};

static intptr_t CommonSuffixLength(const char* a, const char* b) {
  const intptr_t a_length = strlen(a);
  const intptr_t b_length = strlen(b);
  intptr_t a_cursor = a_length;
  intptr_t b_cursor = b_length;

  while ((a_cursor >= 0) && (b_cursor >= 0)) {
    if (a[a_cursor] != b[b_cursor]) {
      break;
    }
    a_cursor--;
    b_cursor--;
  }

  ASSERT((a_length - a_cursor) == (b_length - b_cursor));
  return (a_length - a_cursor);
}

static void AcceptCompilation(Thread* thread) {
  TransitionVMToNative transition(thread);
  Dart_KernelCompilationResult result = KernelIsolate::AcceptCompilation();
  if (result.status != Dart_KernelCompilationStatus_Ok) {
    FATAL1(
        "An error occurred in the CFE while accepting the most recent"
        " compilation results: %s",
        result.error);
  }
}

// If [root_script_url] is null, attempt to load from [kernel_buffer].
bool IsolateGroupReloadContext::Reload(bool force_reload,
                                       const char* root_script_url,
                                       const char* packages_url,
                                       const uint8_t* kernel_buffer,
                                       intptr_t kernel_buffer_size) {
  TIMELINE_SCOPE(Reload);

  Thread* thread = Thread::Current();

  Heap* heap = IG->heap();
  num_old_libs_ =
      GrowableObjectArray::Handle(Z, IG->object_store()->libraries()).Length();

  // Grab root library before calling CheckpointBeforeReload.
  GetRootLibUrl(root_script_url);

  std::unique_ptr<kernel::Program> kernel_program;

  // Reset stats.
  num_received_libs_ = 0;
  bytes_received_libs_ = 0;
  num_received_classes_ = 0;
  num_received_procedures_ = 0;

  bool did_kernel_compilation = false;
  bool skip_reload = false;
  {
    // Load the kernel program and figure out the modified libraries.
    intptr_t* p_num_received_classes = nullptr;
    intptr_t* p_num_received_procedures = nullptr;

    // ReadKernelFromFile checks to see if the file at
    // root_script_url is a valid .dill file. If that's the case, a Program*
    // is returned. Otherwise, this is likely a source file that needs to be
    // compiled, so ReadKernelFromFile returns NULL.
    kernel_program = kernel::Program::ReadFromFile(root_script_url);
    if (kernel_program != nullptr) {
      num_received_libs_ = kernel_program->library_count();
      bytes_received_libs_ = kernel_program->kernel_data_size();
      p_num_received_classes = &num_received_classes_;
      p_num_received_procedures = &num_received_procedures_;
    } else {
      if (kernel_buffer == NULL || kernel_buffer_size == 0) {
        char* error = CompileToKernel(force_reload, packages_url,
                                      &kernel_buffer, &kernel_buffer_size);
        did_kernel_compilation = true;
        if (error != nullptr) {
          TIR_Print("---- LOAD FAILED, ABORTING RELOAD\n");
          const auto& error_str = String::Handle(Z, String::New(error));
          free(error);
          const ApiError& error = ApiError::Handle(Z, ApiError::New(error_str));
          AddReasonForCancelling(new Aborted(Z, error));
          ReportReasonsForCancelling();
          CommonFinalizeTail(num_old_libs_);
          return false;
        }
      }
      const auto& typed_data = ExternalTypedData::Handle(
          Z, ExternalTypedData::NewFinalizeWithFree(
                 const_cast<uint8_t*>(kernel_buffer), kernel_buffer_size));
      kernel_program = kernel::Program::ReadFromTypedData(typed_data);
    }

    NoActiveIsolateScope no_active_isolate_scope;

    ExternalTypedData& external_typed_data =
        ExternalTypedData::Handle(Z, kernel_program.get()->typed_data()->ptr());
    IsolateGroupSource* source = IsolateGroup::Current()->source();
    source->add_loaded_blob(Z, external_typed_data);

    modified_libs_ = new (Z) BitVector(Z, num_old_libs_);
    kernel::KernelLoader::FindModifiedLibraries(
        kernel_program.get(), IG, modified_libs_, force_reload, &skip_reload,
        p_num_received_classes, p_num_received_procedures);
    modified_libs_transitive_ = new (Z) BitVector(Z, num_old_libs_);
    BuildModifiedLibrariesClosure(modified_libs_);

    ASSERT(num_saved_libs_ == -1);
    num_saved_libs_ = 0;
    for (intptr_t i = 0; i < modified_libs_->length(); i++) {
      if (!modified_libs_->Contains(i)) {
        num_saved_libs_++;
      }
    }
  }

  NoActiveIsolateScope no_active_isolate_scope;

  if (skip_reload) {
    ASSERT(modified_libs_->IsEmpty());
    reload_skipped_ = true;
    ReportOnJSON(js_, num_old_libs_);

    // If we use the CFE and performed a compilation, we need to notify that
    // we have accepted the compilation to clear some state in the incremental
    // compiler.
    if (did_kernel_compilation) {
      AcceptCompilation(thread);
    }
    TIR_Print("---- SKIPPING RELOAD (No libraries were modified)\n");
    return false;
  }

  TIR_Print("---- STARTING RELOAD\n");

  intptr_t number_of_isolates = 0;
  isolate_group_->ForEachIsolate(
      [&](Isolate* isolate) { number_of_isolates++; });

  // Disable the background compiler while we are performing the reload.
  NoBackgroundCompilerScope stop_bg_compiler(thread);

  // Wait for any concurrent marking tasks to finish and turn off the
  // concurrent marker during reload as we might be allocating new instances
  // (constants) when loading the new kernel file and this could cause
  // inconsistency between the saved class table and the new class table.
  const bool old_concurrent_mark_flag =
      heap->old_space()->enable_concurrent_mark();
  if (old_concurrent_mark_flag) {
    heap->WaitForMarkerTasks(thread);
    heap->old_space()->set_enable_concurrent_mark(false);
  }

  // Ensure all functions on the stack have unoptimized code.
  // Deoptimize all code that had optimizing decisions that are dependent on
  // assumptions from field guards or CHA or deferred library prefixes.
  // TODO(johnmccutchan): Deoptimizing dependent code here (before the reload)
  // is paranoid. This likely can be moved to the commit phase.
  IG->program_reload_context()->EnsuredUnoptimizedCodeForStack();
  IG->program_reload_context()->DeoptimizeDependentCode();
  IG->program_reload_context()->ReloadPhase1AllocateStorageMapsAndCheckpoint();

  // Renumbering the libraries has invalidated this.
  modified_libs_ = nullptr;
  modified_libs_transitive_ = nullptr;

  if (FLAG_gc_during_reload) {
    // We use kLowMemory to force the GC to compact, which is more likely to
    // discover untracked pointers (and other issues, like incorrect class
    // table).
    heap->CollectAllGarbage(Heap::kLowMemory);
  }

  // Copy the size table for isolate group & class tables for each isolate.
  {
    TIMELINE_SCOPE(CheckpointClasses);
    CheckpointSharedClassTable();
    IG->program_reload_context()->CheckpointClasses();
  }

  if (FLAG_gc_during_reload) {
    // We use kLowMemory to force the GC to compact, which is more likely to
    // discover untracked pointers (and other issues, like incorrect class
    // table).
    heap->CollectAllGarbage(Heap::kLowMemory);
  }

  // We synchronously load the hot-reload kernel diff (which includes changed
  // libraries and any libraries transitively depending on them).
  //
  // If loading the hot-reload diff succeeded we'll finalize the loading, which
  // will either commit or reject the reload request.
  auto& result = Object::Handle(Z);
  {
    // We need to set an active isolate while loading kernel. The kernel loader
    // itself is independent of the current isolate, but if the application
    // needs native extensions, the kernel loader calls out to the embedder to
    // load those, which requires currently an active isolate (since embedder
    // will callback into VM using Dart API).
    DisabledNoActiveIsolateScope active_isolate_scope(&no_active_isolate_scope);

    result = IG->program_reload_context()->ReloadPhase2LoadKernel(
        kernel_program.get(), root_lib_url_);
  }

  if (result.IsError()) {
    TIR_Print("---- LOAD FAILED, ABORTING RELOAD\n");

    const auto& error = Error::Cast(result);
    AddReasonForCancelling(new Aborted(Z, error));

    DiscardSavedClassTable(/*is_rollback=*/true);
    IG->program_reload_context()->ReloadPhase4Rollback();
    CommonFinalizeTail(num_old_libs_);
  } else {
    ASSERT(!reload_skipped_ && !reload_finalized_);
    TIR_Print("---- LOAD SUCCEEDED\n");

    IG->program_reload_context()->ReloadPhase3FinalizeLoading();

    if (FLAG_gc_during_reload) {
      // We use kLowMemory to force the GC to compact, which is more likely to
      // discover untracked pointers (and other issues, like incorrect class
      // table).
      heap->CollectAllGarbage(Heap::kLowMemory);
    }

    if (!FLAG_reload_force_rollback && !HasReasonsForCancelling()) {
      TIR_Print("---- COMMITTING RELOAD\n");
      isolate_group_->program_reload_context()->ReloadPhase4CommitPrepare();
      bool discard_class_tables = true;
      if (HasInstanceMorphers()) {
        // Find all objects that need to be morphed (reallocated to a new size).
        ObjectLocator locator(this);
        {
          HeapIterationScope iteration(Thread::Current());
          iteration.IterateObjects(&locator);
        }

        // We are still using the old class table at this point.
        if (FLAG_gc_during_reload) {
          // We use kLowMemory to force the GC to compact, which is more likely
          // to discover untracked pointers (and other issues, like incorrect
          // class table).
          heap->CollectAllGarbage(Heap::kLowMemory);
        }
        const intptr_t count = locator.count();
        if (count > 0) {
          TIMELINE_SCOPE(MorphInstances);

          // While we are reallocating instances to their new size, the heap
          // will contain a mix of instances with the old and new sizes that
          // have the same cid. This makes the heap unwalkable until the
          // "become" operation below replaces all the instances of the old
          // size with forwarding corpses. Force heap growth to prevent size
          // confusion during this period.
          NoHeapGrowthControlScope scope;
          // The HeapIterationScope above ensures no other GC tasks can be
          // active.
          ASSERT(HasNoTasks(heap));

          const Array& before = Array::Handle(Z, Array::New(count));
          const Array& after = Array::Handle(Z, Array::New(count));

          MorphInstancesPhase1Allocate(&locator, before, after);
          {
            // Apply the new class table before "become". Become will replace
            // all the instances of the old size with forwarding corpses, then
            // perform a heap walk to fix references to the forwarding corpses.
            // During this heap walk, it will encounter instances of the new
            // size, so it requires the new class table.
            ASSERT(HasNoTasks(heap));

            // We accepted the hot-reload and morphed instances. So now we can
            // commit to the changed class table and deleted the saved one.
            DiscardSavedClassTable(/*is_rollback=*/false);
            IG->program_reload_context()->DiscardSavedClassTable(
                /*is_rollback=*/false);
          }
          MorphInstancesPhase2Become(before, after);

          discard_class_tables = false;
        }
        // We are using the new class table now.
        if (FLAG_gc_during_reload) {
          // We use kLowMemory to force the GC to compact, which is more likely
          // to discover untracked pointers (and other issues, like incorrect
          // class table).
          heap->CollectAllGarbage(Heap::kLowMemory);
        }
      }
      if (discard_class_tables) {
        DiscardSavedClassTable(/*is_rollback=*/false);
        IG->program_reload_context()->DiscardSavedClassTable(
            /*is_rollback=*/false);
      }
      isolate_group_->program_reload_context()->ReloadPhase4CommitFinish();
      TIR_Print("---- DONE COMMIT\n");
      isolate_group_->set_last_reload_timestamp(reload_timestamp_);
    } else {
      TIR_Print("---- ROLLING BACK");
      DiscardSavedClassTable(/*is_rollback=*/true);
      isolate_group_->program_reload_context()->ReloadPhase4Rollback();
    }

    // ValidateReload mutates the direct subclass information and does
    // not remove dead subclasses.  Rebuild the direct subclass
    // information from scratch.
    {
      SafepointWriteRwLocker ml(thread, IG->program_lock());
      IG->program_reload_context()->RebuildDirectSubclasses();
    }
    const intptr_t final_library_count =
        GrowableObjectArray::Handle(Z, IG->object_store()->libraries())
            .Length();
    CommonFinalizeTail(final_library_count);

    // If we use the CFE and performed a compilation, we need to notify that
    // we have accepted the compilation to clear some state in the incremental
    // compiler.
    if (did_kernel_compilation) {
      AcceptCompilation(thread);
    }
  }

  // Reenable concurrent marking if it was initially on.
  if (old_concurrent_mark_flag) {
    heap->old_space()->set_enable_concurrent_mark(true);
  }

  bool success;
  if (!result.IsError() || HasReasonsForCancelling()) {
    ReportSuccess();
    success = true;
  } else {
    ReportReasonsForCancelling();
    success = false;
  }

  // Re-queue any shutdown requests so they can inform each isolate's own thread
  // to shut down.
  if (result.IsUnwindError()) {
    const auto& error = UnwindError::Cast(result);
    ForEachIsolate([&](Isolate* isolate) {
      Isolate::KillIfExists(isolate, error.is_user_initiated()
                                         ? Isolate::kKillMsg
                                         : Isolate::kInternalKillMsg);
    });
  }

  return success;
}

/// Copied in from https://dart-review.googlesource.com/c/sdk/+/77722.
static void PropagateLibraryModified(
    const ZoneGrowableArray<ZoneGrowableArray<intptr_t>*>* imported_by,
    intptr_t lib_index,
    BitVector* modified_libs) {
  ZoneGrowableArray<intptr_t>* dep_libs = (*imported_by)[lib_index];
  for (intptr_t i = 0; i < dep_libs->length(); i++) {
    intptr_t dep_lib_index = (*dep_libs)[i];
    if (!modified_libs->Contains(dep_lib_index)) {
      modified_libs->Add(dep_lib_index);
      PropagateLibraryModified(imported_by, dep_lib_index, modified_libs);
    }
  }
}

/// Copied in from https://dart-review.googlesource.com/c/sdk/+/77722.
void IsolateGroupReloadContext::BuildModifiedLibrariesClosure(
    BitVector* modified_libs) {
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(IG->object_store()->libraries());
  Library& lib = Library::Handle();
  intptr_t num_libs = libs.Length();

  // Construct the imported-by graph.
  ZoneGrowableArray<ZoneGrowableArray<intptr_t>*>* imported_by = new (zone_)
      ZoneGrowableArray<ZoneGrowableArray<intptr_t>*>(zone_, num_libs);
  imported_by->SetLength(num_libs);
  for (intptr_t i = 0; i < num_libs; i++) {
    (*imported_by)[i] = new (zone_) ZoneGrowableArray<intptr_t>(zone_, 0);
  }
  Array& ports = Array::Handle();
  Namespace& ns = Namespace::Handle();
  Library& target = Library::Handle();
  String& target_url = String::Handle();

  for (intptr_t lib_idx = 0; lib_idx < num_libs; lib_idx++) {
    lib ^= libs.At(lib_idx);
    ASSERT(lib_idx == lib.index());
    if (lib.is_dart_scheme()) {
      // We don't care about imports among dart scheme libraries.
      continue;
    }

    // Add imports to the import-by graph.
    ports = lib.imports();
    for (intptr_t import_idx = 0; import_idx < ports.Length(); import_idx++) {
      ns ^= ports.At(import_idx);
      if (!ns.IsNull()) {
        target = ns.target();
        target_url = target.url();
        if (!target_url.StartsWith(Symbols::DartExtensionScheme())) {
          (*imported_by)[target.index()]->Add(lib.index());
        }
      }
    }

    // Add exports to the import-by graph.
    ports = lib.exports();
    for (intptr_t export_idx = 0; export_idx < ports.Length(); export_idx++) {
      ns ^= ports.At(export_idx);
      if (!ns.IsNull()) {
        target = ns.target();
        (*imported_by)[target.index()]->Add(lib.index());
      }
    }

    // Add prefixed imports to the import-by graph.
    DictionaryIterator entries(lib);
    Object& entry = Object::Handle();
    LibraryPrefix& prefix = LibraryPrefix::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsLibraryPrefix()) {
        prefix ^= entry.ptr();
        ports = prefix.imports();
        for (intptr_t import_idx = 0; import_idx < ports.Length();
             import_idx++) {
          ns ^= ports.At(import_idx);
          if (!ns.IsNull()) {
            target = ns.target();
            (*imported_by)[target.index()]->Add(lib.index());
          }
        }
      }
    }
  }

  for (intptr_t lib_idx = 0; lib_idx < num_libs; lib_idx++) {
    lib ^= libs.At(lib_idx);
    if (lib.is_dart_scheme() || modified_libs_transitive_->Contains(lib_idx)) {
      // We don't consider dart scheme libraries during reload.  If
      // the modified libs set already contains this library, then we
      // have already visited it.
      continue;
    }
    if (modified_libs->Contains(lib_idx)) {
      modified_libs_transitive_->Add(lib_idx);
      PropagateLibraryModified(imported_by, lib_idx, modified_libs_transitive_);
    }
  }
}

void IsolateGroupReloadContext::GetRootLibUrl(const char* root_script_url) {
  const auto& old_root_lib =
      Library::Handle(IG->object_store()->root_library());
  ASSERT(!old_root_lib.IsNull());
  const auto& old_root_lib_url = String::Handle(old_root_lib.url());

  // Root library url.
  if (root_script_url != nullptr) {
    root_lib_url_ = String::New(root_script_url);
  } else {
    root_lib_url_ = old_root_lib_url.ptr();
  }

  // Check to see if the base url of the loaded libraries has moved.
  if (!old_root_lib_url.Equals(root_lib_url_)) {
    const char* old_root_library_url_c = old_root_lib_url.ToCString();
    const char* root_library_url_c = root_lib_url_.ToCString();
    const intptr_t common_suffix_length =
        CommonSuffixLength(root_library_url_c, old_root_library_url_c);
    root_url_prefix_ = String::SubString(
        root_lib_url_, 0, root_lib_url_.Length() - common_suffix_length + 1);
    old_root_url_prefix_ =
        String::SubString(old_root_lib_url, 0,
                          old_root_lib_url.Length() - common_suffix_length + 1);
  }
}

char* IsolateGroupReloadContext::CompileToKernel(bool force_reload,
                                                 const char* packages_url,
                                                 const uint8_t** kernel_buffer,
                                                 intptr_t* kernel_buffer_size) {
  Dart_SourceFile* modified_scripts = nullptr;
  intptr_t modified_scripts_count = 0;
  FindModifiedSources(force_reload, &modified_scripts, &modified_scripts_count,
                      packages_url);

  Dart_KernelCompilationResult retval = {};
  {
    const char* root_lib_url = root_lib_url_.ToCString();
    TransitionVMToNative transition(Thread::Current());
    retval = KernelIsolate::CompileToKernel(
        root_lib_url, nullptr, 0, modified_scripts_count, modified_scripts,
        true, false, nullptr);
  }
  if (retval.status != Dart_KernelCompilationStatus_Ok) {
    if (retval.kernel != nullptr) {
      free(retval.kernel);
    }
    return retval.error;
  }
  *kernel_buffer = retval.kernel;
  *kernel_buffer_size = retval.kernel_size;
  return nullptr;
}

void ProgramReloadContext::ReloadPhase1AllocateStorageMapsAndCheckpoint() {
  // Preallocate storage for maps.
  old_classes_set_storage_ =
      HashTables::New<UnorderedHashSet<ClassMapTraits> >(4);
  class_map_storage_ = HashTables::New<UnorderedHashMap<ClassMapTraits> >(4);
  removed_class_set_storage_ =
      HashTables::New<UnorderedHashSet<ClassMapTraits> >(4);
  old_libraries_set_storage_ =
      HashTables::New<UnorderedHashSet<LibraryMapTraits> >(4);
  library_map_storage_ =
      HashTables::New<UnorderedHashMap<LibraryMapTraits> >(4);
  become_map_storage_ = HashTables::New<UnorderedHashMap<BecomeMapTraits> >(4);
  // Keep a separate array for enum mappings to avoid having to invoke
  // hashCode on the instances.
  become_enum_mappings_ = GrowableObjectArray::New(Heap::kOld);

  // While reloading everything we do must be reversible so that we can abort
  // safely if the reload fails. This function stashes things to the side and
  // prepares the isolate for the reload attempt.
  {
    TIMELINE_SCOPE(Checkpoint);
    CheckpointLibraries();
  }
}

ObjectPtr ProgramReloadContext::ReloadPhase2LoadKernel(
    kernel::Program* program,
    const String& root_lib_url) {
  Thread* thread = Thread::Current();

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    const Object& tmp = kernel::KernelLoader::LoadEntireProgram(program);
    if (tmp.IsError()) {
      return tmp.ptr();
    }

    // If main method disappeared or were not there to begin with then
    // KernelLoader will return null. In this case lookup library by
    // URL.
    auto& lib = Library::Handle(Library::RawCast(tmp.ptr()));
    if (lib.IsNull()) {
      lib = Library::LookupLibrary(thread, root_lib_url);
    }
    IG->object_store()->set_root_library(lib);
    return Object::null();
  } else {
    return thread->StealStickyError();
  }
}

void ProgramReloadContext::ReloadPhase3FinalizeLoading() {
  BuildLibraryMapping();
  BuildRemovedClassesSet();
  ValidateReload();
}

void ProgramReloadContext::ReloadPhase4CommitPrepare() {
  CommitBeforeInstanceMorphing();
}

void ProgramReloadContext::ReloadPhase4CommitFinish() {
  CommitAfterInstanceMorphing();
  PostCommit();
}

void ProgramReloadContext::ReloadPhase4Rollback() {
  RollbackClasses();
  RollbackLibraries();
}

void ProgramReloadContext::RegisterClass(const Class& new_cls) {
  const Class& old_cls = Class::Handle(OldClassOrNull(new_cls));
  if (old_cls.IsNull()) {
    if (new_cls.IsTopLevel()) {
      IG->class_table()->RegisterTopLevel(new_cls);
    } else {
      IG->class_table()->Register(new_cls);
    }

    if (FLAG_identity_reload) {
      TIR_Print("Could not find replacement class for %s\n",
                new_cls.ToCString());
      UNREACHABLE();
    }

    // New class maps to itself.
    AddClassMapping(new_cls, new_cls);
    return;
  }
  VTIR_Print("Registering class: %s\n", new_cls.ToCString());
  new_cls.set_id(old_cls.id());
  IG->class_table()->SetAt(old_cls.id(), new_cls.ptr());
  if (!old_cls.is_enum_class()) {
    new_cls.CopyCanonicalConstants(old_cls);
  }
  new_cls.CopyDeclarationType(old_cls);
  AddBecomeMapping(old_cls, new_cls);
  AddClassMapping(new_cls, old_cls);
}

void IsolateGroupReloadContext::CommonFinalizeTail(
    intptr_t final_library_count) {
  RELEASE_ASSERT(!reload_finalized_);
  ReportOnJSON(js_, final_library_count);
  reload_finalized_ = true;
}

void IsolateGroupReloadContext::ReportOnJSON(JSONStream* stream,
                                             intptr_t final_library_count) {
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", "ReloadReport");
  jsobj.AddProperty("success", reload_skipped_ || !HasReasonsForCancelling());
  {
    if (HasReasonsForCancelling()) {
      // Reload was rejected.
      JSONArray array(&jsobj, "notices");
      for (intptr_t i = 0; i < reasons_to_cancel_reload_.length(); i++) {
        ReasonForCancelling* reason = reasons_to_cancel_reload_.At(i);
        reason->AppendTo(&array);
      }
      return;
    }

    JSONObject details(&jsobj, "details");
    details.AddProperty("finalLibraryCount", final_library_count);
    details.AddProperty("receivedLibraryCount", num_received_libs_);
    details.AddProperty("receivedLibrariesBytes", bytes_received_libs_);
    details.AddProperty("receivedClassesCount", num_received_classes_);
    details.AddProperty("receivedProceduresCount", num_received_procedures_);
    if (reload_skipped_) {
      // Reload was skipped.
      details.AddProperty("savedLibraryCount", final_library_count);
      details.AddProperty("loadedLibraryCount", static_cast<intptr_t>(0));
    } else {
      // Reload was successful.
      const intptr_t loaded_library_count =
          final_library_count - num_saved_libs_;
      details.AddProperty("savedLibraryCount", num_saved_libs_);
      details.AddProperty("loadedLibraryCount", loaded_library_count);
      JSONArray array(&jsobj, "shapeChangeMappings");
      for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
        instance_morphers_.At(i)->AppendTo(&array);
      }
    }
  }
}

void ProgramReloadContext::EnsuredUnoptimizedCodeForStack() {
  TIMELINE_SCOPE(EnsuredUnoptimizedCodeForStack);

  IG->ForEachIsolate([](Isolate* isolate) {
    auto thread = isolate->mutator_thread();
    StackFrameIterator it(ValidationPolicy::kDontValidateFrames, thread,
                          StackFrameIterator::kAllowCrossThreadIteration);

    Function& func = Function::Handle();
    while (it.HasNextFrame()) {
      StackFrame* frame = it.NextFrame();
      if (frame->IsDartFrame()) {
        func = frame->LookupDartFunction();
        ASSERT(!func.IsNull());
        // Force-optimized functions don't need unoptimized code because their
        // optimized code cannot deopt.
        if (!func.ForceOptimize()) {
          func.EnsureHasCompiledUnoptimizedCode();
        }
      }
    }
  });
}

void ProgramReloadContext::DeoptimizeDependentCode() {
  TIMELINE_SCOPE(DeoptimizeDependentCode);
  ClassTable* class_table = IG->class_table();

  const intptr_t bottom = Dart::vm_isolate_group()->class_table()->NumCids();
  const intptr_t top = IG->class_table()->NumCids();
  Class& cls = Class::Handle();
  Array& fields = Array::Handle();
  Field& field = Field::Handle();
  Thread* thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, IG->program_lock());
  for (intptr_t cls_idx = bottom; cls_idx < top; cls_idx++) {
    if (!class_table->HasValidClassAt(cls_idx)) {
      // Skip.
      continue;
    }

    // Deoptimize CHA code.
    cls = class_table->At(cls_idx);
    ASSERT(!cls.IsNull());

    cls.DisableAllCHAOptimizedCode();

    // Deoptimize field guard code.
    fields = cls.fields();
    ASSERT(!fields.IsNull());
    for (intptr_t field_idx = 0; field_idx < fields.Length(); field_idx++) {
      field = Field::RawCast(fields.At(field_idx));
      ASSERT(!field.IsNull());
      field.DeoptimizeDependentCode();
    }
  }

  DeoptimizeTypeTestingStubs();

  // TODO(rmacnak): Also call LibraryPrefix::InvalidateDependentCode.
}

void IsolateGroupReloadContext::CheckpointSharedClassTable() {
  // Copy the size table for isolate group.
  intptr_t* saved_size_table = nullptr;
  shared_class_table_->CopyBeforeHotReload(&saved_size_table, &saved_num_cids_);

  Thread* thread = Thread::Current();
  {
    NoSafepointScope no_safepoint_scope(thread);

    // The saved_size_table_ will now become source of truth for GC.
    saved_size_table_.store(saved_size_table, std::memory_order_release);
  }

  // But the concurrent sweeper may still be reading from the old table.
  thread->heap()->WaitForSweeperTasks(thread);

  // Now we can clear the old table. This satisfies asserts during class
  // registration and encourages fast failure if we use the wrong table
  // for GC during reload, but isn't strictly needed for correctness.
  shared_class_table_->ResetBeforeHotReload();
}

void ProgramReloadContext::CheckpointClasses() {
  TIR_Print("---- CHECKPOINTING CLASSES\n");
  // Checkpoint classes before a reload. We need to copy the following:
  // 1) The size of the class table.
  // 2) The class table itself.
  // For efficiency, we build a set of classes before the reload. This set
  // is used to pair new classes with old classes.

  // Copy the class table for isolate.
  ClassTable* class_table = IG->class_table();
  ClassPtr* saved_class_table = nullptr;
  ClassPtr* saved_tlc_class_table = nullptr;
  class_table->CopyBeforeHotReload(&saved_class_table, &saved_tlc_class_table,
                                   &saved_num_cids_, &saved_num_tlc_cids_);

  // Copy classes into saved_class_table_ first. Make sure there are no
  // safepoints until saved_class_table_ is filled up and saved so class raw
  // pointers in saved_class_table_ are properly visited by GC.
  {
    NoSafepointScope no_safepoint_scope(Thread::Current());

    // The saved_class_table_ is now source of truth for GC.
    saved_class_table_.store(saved_class_table, std::memory_order_release);
    saved_tlc_class_table_.store(saved_tlc_class_table,
                                 std::memory_order_release);

    // We can therefore wipe out all of the old entries (if that table is used
    // for GC during the hot-reload we have a bug).
    class_table->ResetBeforeHotReload();
  }

  // Add classes to the set. Set is stored in the Array, so adding an element
  // may allocate Dart object on the heap and trigger GC.
  Class& cls = Class::Handle();
  UnorderedHashSet<ClassMapTraits> old_classes_set(old_classes_set_storage_);
  for (intptr_t i = 0; i < saved_num_cids_; i++) {
    if (class_table->IsValidIndex(i) && class_table->HasValidClassAt(i)) {
      if (i != kFreeListElement && i != kForwardingCorpse) {
        cls = class_table->At(i);
        bool already_present = old_classes_set.Insert(cls);
        ASSERT(!already_present);
      }
    }
  }
  for (intptr_t i = 0; i < saved_num_tlc_cids_; i++) {
    const intptr_t cid = ClassTable::CidFromTopLevelIndex(i);
    if (class_table->IsValidIndex(cid) && class_table->HasValidClassAt(cid)) {
      cls = class_table->At(cid);
      bool already_present = old_classes_set.Insert(cls);
      ASSERT(!already_present);
    }
  }
  old_classes_set_storage_ = old_classes_set.Release().ptr();
  TIR_Print("---- System had %" Pd " classes\n", saved_num_cids_);
}

Dart_FileModifiedCallback IsolateGroupReloadContext::file_modified_callback_ =
    nullptr;

bool IsolateGroupReloadContext::ScriptModifiedSince(const Script& script,
                                                    int64_t since) {
  if (IsolateGroupReloadContext::file_modified_callback_ == NULL) {
    return true;
  }
  // We use the resolved url to determine if the script has been modified.
  const String& url = String::Handle(script.resolved_url());
  const char* url_chars = url.ToCString();
  return (*IsolateGroupReloadContext::file_modified_callback_)(url_chars,
                                                               since);
}

static bool ContainsScriptUri(const GrowableArray<const char*>& seen_uris,
                              const char* uri) {
  for (intptr_t i = 0; i < seen_uris.length(); i++) {
    const char* seen_uri = seen_uris.At(i);
    size_t seen_len = strlen(seen_uri);
    if (seen_len != strlen(uri)) {
      continue;
    } else if (strncmp(seen_uri, uri, seen_len) == 0) {
      return true;
    }
  }
  return false;
}

void IsolateGroupReloadContext::FindModifiedSources(
    bool force_reload,
    Dart_SourceFile** modified_sources,
    intptr_t* count,
    const char* packages_url) {
  const int64_t last_reload = isolate_group_->last_reload_timestamp();
  GrowableArray<const char*> modified_sources_uris;
  const auto& libs =
      GrowableObjectArray::Handle(IG->object_store()->libraries());
  Library& lib = Library::Handle(Z);
  Array& scripts = Array::Handle(Z);
  Script& script = Script::Handle(Z);
  String& uri = String::Handle(Z);

  for (intptr_t lib_idx = 0; lib_idx < libs.Length(); lib_idx++) {
    lib ^= libs.At(lib_idx);
    if (lib.is_dart_scheme()) {
      // We don't consider dart scheme libraries during reload.
      continue;
    }
    scripts = lib.LoadedScripts();
    for (intptr_t script_idx = 0; script_idx < scripts.Length(); script_idx++) {
      script ^= scripts.At(script_idx);
      uri = script.url();
      const bool dart_scheme = uri.StartsWith(Symbols::DartScheme());
      if (dart_scheme) {
        // If a user-defined class mixes in a mixin from dart:*, it's list of
        // scripts will have a dart:* script as well. We don't consider those
        // during reload.
        continue;
      }
      if (ContainsScriptUri(modified_sources_uris, uri.ToCString())) {
        // We've already accounted for this script in a prior library.
        continue;
      }

      if (force_reload || ScriptModifiedSince(script, last_reload)) {
        modified_sources_uris.Add(uri.ToCString());
      }
    }
  }

  // In addition to all sources, we need to check if the .packages file
  // contents have been modified.
  if (packages_url != NULL) {
    if (IsolateGroupReloadContext::file_modified_callback_ == NULL ||
        (*IsolateGroupReloadContext::file_modified_callback_)(packages_url,
                                                              last_reload)) {
      modified_sources_uris.Add(packages_url);
    }
  }

  *count = modified_sources_uris.length();
  if (*count == 0) {
    return;
  }

  *modified_sources = Z->Alloc<Dart_SourceFile>(*count);
  for (intptr_t i = 0; i < *count; ++i) {
    (*modified_sources)[i].uri = modified_sources_uris[i];
    (*modified_sources)[i].source = NULL;
  }
}

void ProgramReloadContext::CheckpointLibraries() {
  TIMELINE_SCOPE(CheckpointLibraries);
  TIR_Print("---- CHECKPOINTING LIBRARIES\n");
  // Save the root library in case we abort the reload.
  const Library& root_lib = Library::Handle(object_store()->root_library());
  saved_root_library_ = root_lib.ptr();

  // Save the old libraries array in case we abort the reload.
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());
  saved_libraries_ = libs.ptr();

  // Make a filtered copy of the old libraries array. Keep "clean" libraries
  // that we will use instead of reloading.
  const GrowableObjectArray& new_libs =
      GrowableObjectArray::Handle(GrowableObjectArray::New(Heap::kOld));
  Library& lib = Library::Handle();
  UnorderedHashSet<LibraryMapTraits> old_libraries_set(
      old_libraries_set_storage_);

  group_reload_context_->saved_libs_transitive_updated_ = new (Z)
      BitVector(Z, group_reload_context_->modified_libs_transitive_->length());
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    if (group_reload_context_->modified_libs_->Contains(i)) {
      // We are going to reload this library. Clear the index.
      lib.set_index(-1);
    } else {
      // We are preserving this library across the reload, assign its new index
      lib.set_index(new_libs.Length());
      new_libs.Add(lib, Heap::kOld);

      if (group_reload_context_->modified_libs_transitive_->Contains(i)) {
        // Remember the new index.
        group_reload_context_->saved_libs_transitive_updated_->Add(lib.index());
      }
    }
    // Add old library to old libraries set.
    bool already_present = old_libraries_set.Insert(lib);
    ASSERT(!already_present);
  }
  old_libraries_set_storage_ = old_libraries_set.Release().ptr();

  // Reset the registered libraries to the filtered array.
  Library::RegisterLibraries(Thread::Current(), new_libs);
  // Reset the root library to null.
  object_store()->set_root_library(Library::Handle());
}

void ProgramReloadContext::RollbackClasses() {
  TIR_Print("---- ROLLING BACK CLASS TABLE\n");
  ASSERT((saved_num_cids_ + saved_num_tlc_cids_) > 0);
  ASSERT(saved_class_table_.load(std::memory_order_relaxed) != nullptr);
  ASSERT(saved_tlc_class_table_.load(std::memory_order_relaxed) != nullptr);

  DiscardSavedClassTable(/*is_rollback=*/true);
}

void ProgramReloadContext::RollbackLibraries() {
  TIR_Print("---- ROLLING BACK LIBRARY CHANGES\n");
  Thread* thread = Thread::Current();
  Library& lib = Library::Handle();
  const auto& saved_libs = GrowableObjectArray::Handle(Z, saved_libraries_);
  if (!saved_libs.IsNull()) {
    for (intptr_t i = 0; i < saved_libs.Length(); i++) {
      lib = Library::RawCast(saved_libs.At(i));
      // Restore indexes that were modified in CheckpointLibraries.
      lib.set_index(i);
    }

    // Reset the registered libraries to the filtered array.
    Library::RegisterLibraries(thread, saved_libs);
  }

  Library& saved_root_lib = Library::Handle(Z, saved_root_library_);
  if (!saved_root_lib.IsNull()) {
    object_store()->set_root_library(saved_root_lib);
  }

  saved_root_library_ = Library::null();
  saved_libraries_ = GrowableObjectArray::null();
}

#ifdef DEBUG
void ProgramReloadContext::VerifyMaps() {
  TIMELINE_SCOPE(VerifyMaps);
  Class& cls = Class::Handle();
  Class& new_cls = Class::Handle();
  Class& cls2 = Class::Handle();

  // Verify that two old classes aren't both mapped to the same new
  // class. This could happen is the IsSameClass function is broken.
  UnorderedHashMap<ClassMapTraits> class_map(class_map_storage_);
  UnorderedHashMap<ClassMapTraits> reverse_class_map(
      HashTables::New<UnorderedHashMap<ClassMapTraits> >(
          class_map.NumOccupied()));
  {
    UnorderedHashMap<ClassMapTraits>::Iterator it(&class_map);
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      new_cls = Class::RawCast(class_map.GetKey(entry));
      cls = Class::RawCast(class_map.GetPayload(entry, 0));
      cls2 ^= reverse_class_map.GetOrNull(new_cls);
      if (!cls2.IsNull()) {
        OS::PrintErr(
            "Classes '%s' and '%s' are distinct classes but both map "
            " to class '%s'\n",
            cls.ToCString(), cls2.ToCString(), new_cls.ToCString());
        UNREACHABLE();
      }
      bool update = reverse_class_map.UpdateOrInsert(cls, new_cls);
      ASSERT(!update);
    }
  }
  class_map.Release();
  reverse_class_map.Release();
}
#endif

void ProgramReloadContext::CommitBeforeInstanceMorphing() {
  TIMELINE_SCOPE(Commit);

#ifdef DEBUG
  VerifyMaps();
#endif

  // Copy over certain properties of libraries, e.g. is the library
  // debuggable?
  {
    TIMELINE_SCOPE(CopyLibraryBits);
    Library& lib = Library::Handle();
    Library& new_lib = Library::Handle();

    UnorderedHashMap<LibraryMapTraits> lib_map(library_map_storage_);

    {
      // Reload existing libraries.
      UnorderedHashMap<LibraryMapTraits>::Iterator it(&lib_map);

      while (it.MoveNext()) {
        const intptr_t entry = it.Current();
        ASSERT(entry != -1);
        new_lib = Library::RawCast(lib_map.GetKey(entry));
        lib = Library::RawCast(lib_map.GetPayload(entry, 0));
        new_lib.set_debuggable(lib.IsDebuggable());
        // Native extension support.
        new_lib.set_native_entry_resolver(lib.native_entry_resolver());
        new_lib.set_native_entry_symbol_resolver(
            lib.native_entry_symbol_resolver());
      }
    }

    // Release the library map.
    lib_map.Release();
  }

  {
    TIMELINE_SCOPE(CopyStaticFieldsAndPatchFieldsAndFunctions);
    // Copy static field values from the old classes to the new classes.
    // Patch fields and functions in the old classes so that they retain
    // the old script.
    Class& old_cls = Class::Handle();
    Class& new_cls = Class::Handle();
    UnorderedHashMap<ClassMapTraits> class_map(class_map_storage_);

    {
      UnorderedHashMap<ClassMapTraits>::Iterator it(&class_map);
      while (it.MoveNext()) {
        const intptr_t entry = it.Current();
        new_cls = Class::RawCast(class_map.GetKey(entry));
        old_cls = Class::RawCast(class_map.GetPayload(entry, 0));
        if (new_cls.ptr() != old_cls.ptr()) {
          ASSERT(new_cls.is_enum_class() == old_cls.is_enum_class());
          if (new_cls.is_enum_class() && new_cls.is_finalized()) {
            new_cls.ReplaceEnum(this, old_cls);
          } else {
            new_cls.CopyStaticFieldValues(this, old_cls);
          }
          old_cls.PatchFieldsAndFunctions();
          old_cls.MigrateImplicitStaticClosures(this, new_cls);
        }
      }
    }

    class_map.Release();

    {
      UnorderedHashSet<ClassMapTraits> removed_class_set(
          removed_class_set_storage_);
      UnorderedHashSet<ClassMapTraits>::Iterator it(&removed_class_set);
      while (it.MoveNext()) {
        const intptr_t entry = it.Current();
        old_cls ^= removed_class_set.GetKey(entry);
        old_cls.PatchFieldsAndFunctions();
      }
      removed_class_set.Release();
    }
  }

  {
    TIMELINE_SCOPE(UpdateLibrariesArray);
    // Update the libraries array.
    Library& lib = Library::Handle();
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(IG->object_store()->libraries());
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib = Library::RawCast(libs.At(i));
      VTIR_Print("Lib '%s' at index %" Pd "\n", lib.ToCString(), i);
      lib.set_index(i);
    }

    // Initialize library side table.
    library_infos_.SetLength(libs.Length());
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib = Library::RawCast(libs.At(i));
      // Mark the library dirty if it comes after the libraries we saved.
      library_infos_[i].dirty =
          i >= group_reload_context_->num_saved_libs_ ||
          group_reload_context_->saved_libs_transitive_updated_->Contains(
              lib.index());
    }
  }
}

void ProgramReloadContext::CommitAfterInstanceMorphing() {
  {
    const GrowableObjectArray& become_enum_mappings =
        GrowableObjectArray::Handle(become_enum_mappings_);
    UnorderedHashMap<BecomeMapTraits> become_map(become_map_storage_);
    intptr_t replacement_count =
        become_map.NumOccupied() + become_enum_mappings.Length() / 2;
    const Array& before =
        Array::Handle(Array::New(replacement_count, Heap::kOld));
    const Array& after =
        Array::Handle(Array::New(replacement_count, Heap::kOld));
    Object& obj = Object::Handle();
    intptr_t replacement_index = 0;
    UnorderedHashMap<BecomeMapTraits>::Iterator it(&become_map);
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      obj = become_map.GetKey(entry);
      before.SetAt(replacement_index, obj);
      obj = become_map.GetPayload(entry, 0);
      after.SetAt(replacement_index, obj);
      replacement_index++;
    }
    for (intptr_t i = 0; i < become_enum_mappings.Length(); i += 2) {
      obj = become_enum_mappings.At(i);
      before.SetAt(replacement_index, obj);
      obj = become_enum_mappings.At(i + 1);
      after.SetAt(replacement_index, obj);
      replacement_index++;
    }
    ASSERT(replacement_index == replacement_count);
    become_map.Release();

    Become::ElementsForwardIdentity(before, after);
  }

  // Rehash constants map for all classes. Constants are hashed by content, and
  // content may have changed from fields being added or removed.
  {
    TIMELINE_SCOPE(RehashConstants);
    IG->RehashConstants();
  }

#ifdef DEBUG
  IG->ValidateConstants();
#endif

  if (FLAG_identity_reload) {
    if (saved_num_cids_ != IG->class_table()->NumCids()) {
      TIR_Print("Identity reload failed! B#C=%" Pd " A#C=%" Pd "\n",
                saved_num_cids_, IG->class_table()->NumCids());
    }
    if (saved_num_tlc_cids_ != IG->class_table()->NumTopLevelCids()) {
      TIR_Print("Identity reload failed! B#TLC=%" Pd " A#TLC=%" Pd "\n",
                saved_num_tlc_cids_, IG->class_table()->NumTopLevelCids());
    }
    const auto& saved_libs = GrowableObjectArray::Handle(saved_libraries_);
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(IG->object_store()->libraries());
    if (saved_libs.Length() != libs.Length()) {
      TIR_Print("Identity reload failed! B#L=%" Pd " A#L=%" Pd "\n",
                saved_libs.Length(), libs.Length());
    }
  }
}

bool ProgramReloadContext::IsDirty(const Library& lib) {
  const intptr_t index = lib.index();
  if (index == static_cast<classid_t>(-1)) {
    // Treat deleted libraries as dirty.
    return true;
  }
  ASSERT((index >= 0) && (index < library_infos_.length()));
  return library_infos_[index].dirty;
}

void ProgramReloadContext::PostCommit() {
  TIMELINE_SCOPE(PostCommit);
  saved_root_library_ = Library::null();
  saved_libraries_ = GrowableObjectArray::null();
  InvalidateWorld();
}

void IsolateGroupReloadContext::AddReasonForCancelling(
    ReasonForCancelling* reason) {
  reasons_to_cancel_reload_.Add(reason);
}

void IsolateGroupReloadContext::EnsureHasInstanceMorpherFor(
    classid_t cid,
    InstanceMorpher* instance_morpher) {
  for (intptr_t i = 0; i < instance_morphers_.length(); ++i) {
    if (instance_morphers_[i]->cid() == cid) {
      return;
    }
  }
  instance_morphers_.Add(instance_morpher);
  instance_morpher_by_cid_.Insert(instance_morpher);
  ASSERT(instance_morphers_[instance_morphers_.length() - 1]->cid() == cid);
}

void IsolateGroupReloadContext::ReportReasonsForCancelling() {
  ASSERT(FLAG_reload_force_rollback || HasReasonsForCancelling());
  for (int i = 0; i < reasons_to_cancel_reload_.length(); i++) {
    reasons_to_cancel_reload_.At(i)->Report(this);
  }
}

void IsolateGroupReloadContext::MorphInstancesPhase1Allocate(
    ObjectLocator* locator,
    const Array& before,
    const Array& after) {
  ASSERT(HasInstanceMorphers());

  if (FLAG_trace_reload) {
    LogBlock blocker;
    TIR_Print("MorphInstance: \n");
    for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
      instance_morphers_.At(i)->Dump();
    }
  }

  const intptr_t count = locator->count();
  TIR_Print("Found %" Pd " object%s subject to morphing.\n", count,
            (count > 1) ? "s" : "");

  for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
    instance_morphers_.At(i)->CreateMorphedCopies();
  }

  // Create the inputs for Become.
  intptr_t index = 0;
  for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
    InstanceMorpher* morpher = instance_morphers_.At(i);
    for (intptr_t j = 0; j < morpher->before()->length(); j++) {
      before.SetAt(index, *morpher->before()->At(j));
      after.SetAt(index, *morpher->after()->At(j));
      index++;
    }
  }
  ASSERT(index == count);
}

void IsolateGroupReloadContext::MorphInstancesPhase2Become(const Array& before,
                                                           const Array& after) {
  ASSERT(HasInstanceMorphers());

  Become::ElementsForwardIdentity(before, after);
  // The heap now contains only instances with the new size. Ordinary GC is safe
  // again.
}

void IsolateGroupReloadContext::ForEachIsolate(
    std::function<void(Isolate*)> callback) {
  isolate_group_->ForEachIsolate(callback);
}

void ProgramReloadContext::ValidateReload() {
  TIMELINE_SCOPE(ValidateReload);

  TIR_Print("---- VALIDATING RELOAD\n");

  // Validate libraries.
  {
    ASSERT(library_map_storage_ != Array::null());
    UnorderedHashMap<LibraryMapTraits> map(library_map_storage_);
    UnorderedHashMap<LibraryMapTraits>::Iterator it(&map);
    Library& lib = Library::Handle();
    Library& new_lib = Library::Handle();
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      new_lib = Library::RawCast(map.GetKey(entry));
      lib = Library::RawCast(map.GetPayload(entry, 0));
      if (new_lib.ptr() != lib.ptr()) {
        lib.CheckReload(new_lib, this);
      }
    }
    map.Release();
  }

  // Validate classes.
  {
    ASSERT(class_map_storage_ != Array::null());
    UnorderedHashMap<ClassMapTraits> map(class_map_storage_);
    UnorderedHashMap<ClassMapTraits>::Iterator it(&map);
    Class& cls = Class::Handle();
    Class& new_cls = Class::Handle();
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      new_cls = Class::RawCast(map.GetKey(entry));
      cls = Class::RawCast(map.GetPayload(entry, 0));
      if (new_cls.ptr() != cls.ptr()) {
        cls.CheckReload(new_cls, this);
      }
    }
    map.Release();
  }
}

ClassPtr ProgramReloadContext::GetClassForHeapWalkAt(intptr_t cid) {
  ClassPtr* class_table = nullptr;
  intptr_t index = -1;
  if (ClassTable::IsTopLevelCid(cid)) {
    class_table = saved_tlc_class_table_.load(std::memory_order_acquire);
    index = ClassTable::IndexFromTopLevelCid(cid);
    ASSERT(index < saved_num_tlc_cids_);
  } else {
    class_table = saved_class_table_.load(std::memory_order_acquire);
    index = cid;
    ASSERT(cid > 0 && cid < saved_num_cids_);
  }
  if (class_table != nullptr) {
    return class_table[index];
  }
  return IG->class_table()->At(cid);
}

intptr_t IsolateGroupReloadContext::GetClassSizeForHeapWalkAt(classid_t cid) {
  if (ClassTable::IsTopLevelCid(cid)) {
    return 0;
  }
  intptr_t* size_table = saved_size_table_.load(std::memory_order_acquire);
  if (size_table != nullptr) {
    ASSERT(cid < saved_num_cids_);
    return size_table[cid];
  } else {
    return shared_class_table_->SizeAt(cid);
  }
}

void ProgramReloadContext::DiscardSavedClassTable(bool is_rollback) {
  ClassPtr* local_saved_class_table =
      saved_class_table_.load(std::memory_order_relaxed);
  ClassPtr* local_saved_tlc_class_table =
      saved_tlc_class_table_.load(std::memory_order_relaxed);
  {
    auto thread = Thread::Current();
    SafepointWriteRwLocker sl(thread, thread->isolate_group()->program_lock());
    IG->class_table()->ResetAfterHotReload(
        local_saved_class_table, local_saved_tlc_class_table, saved_num_cids_,
        saved_num_tlc_cids_, is_rollback);
  }
  saved_class_table_.store(nullptr, std::memory_order_release);
  saved_tlc_class_table_.store(nullptr, std::memory_order_release);
}

void IsolateGroupReloadContext::DiscardSavedClassTable(bool is_rollback) {
  intptr_t* local_saved_size_table = saved_size_table_;
  shared_class_table_->ResetAfterHotReload(local_saved_size_table,
                                           saved_num_cids_, is_rollback);
  saved_size_table_.store(nullptr, std::memory_order_release);
}

void IsolateGroupReloadContext::VisitObjectPointers(
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(from(), to());
}

void ProgramReloadContext::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(from(), to());

  ClassPtr* saved_class_table =
      saved_class_table_.load(std::memory_order_relaxed);
  if (saved_class_table != NULL) {
    auto class_table = reinterpret_cast<ObjectPtr*>(&(saved_class_table[0]));
    visitor->VisitPointers(class_table, saved_num_cids_);
  }
  ClassPtr* saved_tlc_class_table =
      saved_tlc_class_table_.load(std::memory_order_relaxed);
  if (saved_tlc_class_table != NULL) {
    auto class_table =
        reinterpret_cast<ObjectPtr*>(&(saved_tlc_class_table[0]));
    visitor->VisitPointers(class_table, saved_num_tlc_cids_);
  }
}

ObjectStore* ProgramReloadContext::object_store() {
  return IG->object_store();
}

void ProgramReloadContext::ResetUnoptimizedICsOnStack() {
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();
  Code& code = Code::Handle(zone);
  Function& function = Function::Handle(zone);
  CallSiteResetter resetter(zone);

  IG->ForEachIsolate([&](Isolate* isolate) {
    DartFrameIterator iterator(isolate->mutator_thread(),
                               StackFrameIterator::kAllowCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    while (frame != nullptr) {
      code = frame->LookupDartCode();
      if (code.is_optimized() && !code.is_force_optimized()) {
        // If this code is optimized, we need to reset the ICs in the
        // corresponding unoptimized code, which will be executed when the stack
        // unwinds to the optimized code.
        function = code.function();
        code = function.unoptimized_code();
        ASSERT(!code.IsNull());
        resetter.ResetSwitchableCalls(code);
        resetter.ResetCaches(code);
      } else {
        resetter.ResetSwitchableCalls(code);
        resetter.ResetCaches(code);
      }
      frame = iterator.NextFrame();
    }
  });
}

void ProgramReloadContext::ResetMegamorphicCaches() {
  object_store()->set_megamorphic_cache_table(GrowableObjectArray::Handle());
  // Since any current optimized code will not make any more calls, it may be
  // better to clear the table instead of clearing each of the caches, allow
  // the current megamorphic caches get GC'd and any new optimized code allocate
  // new ones.
}

class InvalidationCollector : public ObjectVisitor {
 public:
  InvalidationCollector(Zone* zone,
                        GrowableArray<const Function*>* functions,
                        GrowableArray<const KernelProgramInfo*>* kernel_infos,
                        GrowableArray<const Field*>* fields,
                        GrowableArray<const Instance*>* instances)
      : zone_(zone),
        functions_(functions),
        kernel_infos_(kernel_infos),
        fields_(fields),
        instances_(instances) {}
  virtual ~InvalidationCollector() {}

  void VisitObject(ObjectPtr obj) {
    intptr_t cid = obj->GetClassId();
    if (cid == kFunctionCid) {
      const Function& func =
          Function::Handle(zone_, static_cast<FunctionPtr>(obj));
      if (!func.ForceOptimize()) {
        // Force-optimized functions cannot deoptimize.
        functions_->Add(&func);
      }
    } else if (cid == kKernelProgramInfoCid) {
      kernel_infos_->Add(&KernelProgramInfo::Handle(
          zone_, static_cast<KernelProgramInfoPtr>(obj)));
    } else if (cid == kFieldCid) {
      fields_->Add(&Field::Handle(zone_, static_cast<FieldPtr>(obj)));
    } else if (cid > kNumPredefinedCids) {
      instances_->Add(&Instance::Handle(zone_, static_cast<InstancePtr>(obj)));
    }
  }

 private:
  Zone* const zone_;
  GrowableArray<const Function*>* const functions_;
  GrowableArray<const KernelProgramInfo*>* const kernel_infos_;
  GrowableArray<const Field*>* const fields_;
  GrowableArray<const Instance*>* const instances_;
};

typedef UnorderedHashMap<SmiTraits> IntHashMap;

void ProgramReloadContext::RunInvalidationVisitors() {
  TIR_Print("---- RUNNING INVALIDATION HEAP VISITORS\n");
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  GrowableArray<const Function*> functions(4 * KB);
  GrowableArray<const KernelProgramInfo*> kernel_infos(KB);
  GrowableArray<const Field*> fields(4 * KB);
  GrowableArray<const Instance*> instances(4 * KB);

  {
    HeapIterationScope iteration(thread);
    InvalidationCollector visitor(zone, &functions, &kernel_infos, &fields,
                                  &instances);
    iteration.IterateObjects(&visitor);
  }

  InvalidateKernelInfos(zone, kernel_infos);
  InvalidateFunctions(zone, functions);
  InvalidateFields(zone, fields, instances);
}

void ProgramReloadContext::InvalidateKernelInfos(
    Zone* zone,
    const GrowableArray<const KernelProgramInfo*>& kernel_infos) {
  TIMELINE_SCOPE(InvalidateKernelInfos);
  HANDLESCOPE(Thread::Current());

  Array& data = Array::Handle(zone);
  Object& key = Object::Handle(zone);
  Smi& value = Smi::Handle(zone);
  for (intptr_t i = 0; i < kernel_infos.length(); i++) {
    const KernelProgramInfo& info = *kernel_infos[i];
    // Clear the libraries cache.
    {
      data = info.libraries_cache();
      ASSERT(!data.IsNull());
      IntHashMap table(&key, &value, &data);
      table.Clear();
      info.set_libraries_cache(table.Release());
    }
    // Clear the classes cache.
    {
      data = info.classes_cache();
      ASSERT(!data.IsNull());
      IntHashMap table(&key, &value, &data);
      table.Clear();
      info.set_classes_cache(table.Release());
    }
  }
}

void ProgramReloadContext::InvalidateFunctions(
    Zone* zone,
    const GrowableArray<const Function*>& functions) {
  TIMELINE_SCOPE(InvalidateFunctions);
  auto thread = Thread::Current();
  HANDLESCOPE(thread);

  CallSiteResetter resetter(zone);

  Class& owning_class = Class::Handle(zone);
  Library& owning_lib = Library::Handle(zone);
  Code& code = Code::Handle(zone);
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  for (intptr_t i = 0; i < functions.length(); i++) {
    const Function& func = *functions[i];

    // Switch to unoptimized code or the lazy compilation stub.
    func.SwitchToLazyCompiledUnoptimizedCode();

    // Grab the current code.
    code = func.CurrentCode();
    ASSERT(!code.IsNull());

    owning_class = func.Owner();
    owning_lib = owning_class.library();
    const bool clear_code = IsDirty(owning_lib);
    const bool stub_code = code.IsStubCode();

    // Zero edge counters, before clearing the ICDataArray, since that's where
    // they're held.
    resetter.ZeroEdgeCounters(func);

    if (stub_code) {
      // Nothing to reset.
    } else if (clear_code) {
      VTIR_Print("Marking %s for recompilation, clearing code\n",
                 func.ToCString());
      // Null out the ICData array and code.
      func.ClearICDataArray();
      func.ClearCode();
      func.SetWasCompiled(false);
    } else {
      // We are preserving the unoptimized code, reset instance calls and type
      // test caches.
      resetter.ResetSwitchableCalls(code);
      resetter.ResetCaches(code);
    }

    // Clear counters.
    func.set_usage_counter(0);
    func.set_deoptimization_counter(0);
    func.set_optimized_instruction_count(0);
    func.set_optimized_call_site_count(0);
  }
}

// Finds fields that are initialized or have a value that does not conform to
// the field's static type, setting Field::needs_load_guard(). Accessors for
// such fields are compiled with additional checks to handle lazy initialization
// and to preserve type soundness.
class FieldInvalidator {
 public:
  explicit FieldInvalidator(Zone* zone)
      : cls_(Class::Handle(zone)),
        cls_fields_(Array::Handle(zone)),
        entry_(Object::Handle(zone)),
        value_(Object::Handle(zone)),
        instance_(Instance::Handle(zone)),
        type_(AbstractType::Handle(zone)),
        cache_(SubtypeTestCache::Handle(zone)),
        entries_(Array::Handle(zone)),
        closure_function_(Function::Handle(zone)),
        instantiator_type_arguments_(TypeArguments::Handle(zone)),
        function_type_arguments_(TypeArguments::Handle(zone)),
        instance_cid_or_signature_(Object::Handle(zone)),
        instance_type_arguments_(TypeArguments::Handle(zone)),
        parent_function_type_arguments_(TypeArguments::Handle(zone)),
        delayed_function_type_arguments_(TypeArguments::Handle(zone)) {}

  void CheckStatics(const GrowableArray<const Field*>& fields) {
    Thread* thread = Thread::Current();
    const bool null_safety = thread->isolate_group()->null_safety();
    HANDLESCOPE(thread);
    instantiator_type_arguments_ = TypeArguments::null();
    for (intptr_t i = 0; i < fields.length(); i++) {
      const Field& field = *fields[i];
      if (!field.is_static()) {
        continue;
      }
      if (field.needs_load_guard()) {
        continue;  // Already guarding.
      }
      const intptr_t field_id = field.field_id();
      thread->isolate_group()->ForEachIsolate([&](Isolate* isolate) {
        auto field_table = isolate->field_table();
        // The isolate might've just been created and is now participating in
        // the reload request inside `IsolateGroup::RegisterIsolate()`.
        // At that point it doesn't have the field table setup yet.
        if (field_table->IsReadyToUse()) {
          value_ = field_table->At(field_id);
          if ((value_.ptr() != Object::sentinel().ptr()) &&
              (value_.ptr() != Object::transition_sentinel().ptr())) {
            CheckValueType(null_safety, value_, field);
          }
        }
      });
    }
  }

  void CheckInstances(const GrowableArray<const Instance*>& instances) {
    Thread* thread = Thread::Current();
    const bool null_safety = thread->isolate_group()->null_safety();
    HANDLESCOPE(thread);
    for (intptr_t i = 0; i < instances.length(); i++) {
      CheckInstance(null_safety, *instances[i]);
    }
  }

 private:
  DART_FORCE_INLINE
  void CheckInstance(bool null_safety, const Instance& instance) {
    cls_ = instance.clazz();
    if (cls_.NumTypeArguments() > 0) {
      instantiator_type_arguments_ = instance.GetTypeArguments();
    } else {
      instantiator_type_arguments_ = TypeArguments::null();
    }
    cls_fields_ = cls_.OffsetToFieldMap();
    for (intptr_t i = 0; i < cls_fields_.Length(); i++) {
      entry_ = cls_fields_.At(i);
      if (!entry_.IsField()) {
        continue;
      }
      const Field& field = Field::Cast(entry_);
      CheckInstanceField(null_safety, instance, field);
    }
  }

  DART_FORCE_INLINE
  void CheckInstanceField(bool null_safety,
                          const Instance& instance,
                          const Field& field) {
    if (field.needs_load_guard()) {
      return;  // Already guarding.
    }
    value_ = instance.GetField(field);
    if (value_.ptr() == Object::sentinel().ptr()) {
      if (field.is_late()) {
        // Late fields already have lazy initialization logic.
        return;
      }
      // Needs guard for initialization.
      ASSERT(!FLAG_identity_reload);
      field.set_needs_load_guard(true);
      return;
    }
    CheckValueType(null_safety, value_, field);
  }

  DART_FORCE_INLINE
  void CheckValueType(bool null_safety,
                      const Object& value,
                      const Field& field) {
    ASSERT(!value.IsSentinel());
    if (!null_safety && value.IsNull()) {
      return;
    }
    type_ = field.type();
    if (type_.IsDynamicType()) {
      return;
    }

    cls_ = value.clazz();
    const intptr_t cid = cls_.id();
    if (cid == kClosureCid) {
      const auto& closure = Closure::Cast(value);
      closure_function_ = closure.function();
      instance_cid_or_signature_ = closure_function_.signature();
      instance_type_arguments_ = closure.instantiator_type_arguments();
      parent_function_type_arguments_ = closure.function_type_arguments();
      delayed_function_type_arguments_ = closure.delayed_type_arguments();
    } else {
      instance_cid_or_signature_ = Smi::New(cid);
      if (cls_.NumTypeArguments() > 0) {
        instance_type_arguments_ = Instance::Cast(value).GetTypeArguments();
      } else {
        instance_type_arguments_ = TypeArguments::null();
      }
      parent_function_type_arguments_ = TypeArguments::null();
      delayed_function_type_arguments_ = TypeArguments::null();
    }

    cache_ = field.type_test_cache();
    if (cache_.IsNull()) {
      cache_ = SubtypeTestCache::New();
      field.set_type_test_cache(cache_);
    }
    entries_ = cache_.cache();

    bool cache_hit = false;
    for (intptr_t i = 0; entries_.At(i) != Object::null();
         i += SubtypeTestCache::kTestEntryLength) {
      if ((entries_.At(i + SubtypeTestCache::kInstanceCidOrSignature) ==
           instance_cid_or_signature_.ptr()) &&
          (entries_.At(i + SubtypeTestCache::kDestinationType) ==
           type_.ptr()) &&
          (entries_.At(i + SubtypeTestCache::kInstanceTypeArguments) ==
           instance_type_arguments_.ptr()) &&
          (entries_.At(i + SubtypeTestCache::kInstantiatorTypeArguments) ==
           instantiator_type_arguments_.ptr()) &&
          (entries_.At(i + SubtypeTestCache::kFunctionTypeArguments) ==
           function_type_arguments_.ptr()) &&
          (entries_.At(
               i + SubtypeTestCache::kInstanceParentFunctionTypeArguments) ==
           parent_function_type_arguments_.ptr()) &&
          (entries_.At(
               i + SubtypeTestCache::kInstanceDelayedFunctionTypeArguments) ==
           delayed_function_type_arguments_.ptr())) {
        cache_hit = true;
        if (entries_.At(i + SubtypeTestCache::kTestResult) !=
            Bool::True().ptr()) {
          ASSERT(!FLAG_identity_reload);
          field.set_needs_load_guard(true);
        }
        break;
      }
    }

    if (!cache_hit) {
      instance_ ^= value.ptr();
      if (!instance_.IsAssignableTo(type_, instantiator_type_arguments_,
                                    function_type_arguments_)) {
        ASSERT(!FLAG_identity_reload);
        field.set_needs_load_guard(true);
      } else {
        cache_.AddCheck(instance_cid_or_signature_, type_,
                        instance_type_arguments_, instantiator_type_arguments_,
                        function_type_arguments_,
                        parent_function_type_arguments_,
                        delayed_function_type_arguments_, Bool::True());
      }
    }
  }

  Class& cls_;
  Array& cls_fields_;
  Object& entry_;
  Object& value_;
  Instance& instance_;
  AbstractType& type_;
  SubtypeTestCache& cache_;
  Array& entries_;
  Function& closure_function_;
  TypeArguments& instantiator_type_arguments_;
  TypeArguments& function_type_arguments_;
  Object& instance_cid_or_signature_;
  TypeArguments& instance_type_arguments_;
  TypeArguments& parent_function_type_arguments_;
  TypeArguments& delayed_function_type_arguments_;
};

void ProgramReloadContext::InvalidateFields(
    Zone* zone,
    const GrowableArray<const Field*>& fields,
    const GrowableArray<const Instance*>& instances) {
  TIMELINE_SCOPE(InvalidateFields);
  SafepointMutexLocker ml(IG->subtype_test_cache_mutex());
  FieldInvalidator invalidator(zone);
  invalidator.CheckStatics(fields);
  invalidator.CheckInstances(instances);
}

void ProgramReloadContext::InvalidateWorld() {
  TIMELINE_SCOPE(InvalidateWorld);
  TIR_Print("---- INVALIDATING WORLD\n");
  ResetMegamorphicCaches();
  if (FLAG_trace_deoptimization) {
    THR_Print("Deopt for reload\n");
  }
  DeoptimizeFunctionsOnStack();
  ResetUnoptimizedICsOnStack();
  RunInvalidationVisitors();
}

ClassPtr ProgramReloadContext::OldClassOrNull(const Class& replacement_or_new) {
  UnorderedHashSet<ClassMapTraits> old_classes_set(old_classes_set_storage_);
  Class& cls = Class::Handle();
  cls ^= old_classes_set.GetOrNull(replacement_or_new);
  old_classes_set_storage_ = old_classes_set.Release().ptr();
  return cls.ptr();
}

StringPtr ProgramReloadContext::FindLibraryPrivateKey(
    const Library& replacement_or_new) {
  const Library& old = Library::Handle(OldLibraryOrNull(replacement_or_new));
  if (old.IsNull()) {
    return String::null();
  }
#if defined(DEBUG)
  VTIR_Print("`%s` is getting `%s`'s private key.\n",
             String::Handle(replacement_or_new.url()).ToCString(),
             String::Handle(old.url()).ToCString());
#endif
  return old.private_key();
}

LibraryPtr ProgramReloadContext::OldLibraryOrNull(
    const Library& replacement_or_new) {
  UnorderedHashSet<LibraryMapTraits> old_libraries_set(
      old_libraries_set_storage_);
  Library& lib = Library::Handle();
  lib ^= old_libraries_set.GetOrNull(replacement_or_new);
  old_libraries_set.Release();

  if (lib.IsNull() &&
      (group_reload_context_->root_url_prefix_ != String::null()) &&
      (group_reload_context_->old_root_url_prefix_ != String::null())) {
    return OldLibraryOrNullBaseMoved(replacement_or_new);
  }
  return lib.ptr();
}

// Attempt to find the pair to |replacement_or_new| with the knowledge that
// the base url prefix has moved.
LibraryPtr ProgramReloadContext::OldLibraryOrNullBaseMoved(
    const Library& replacement_or_new) {
  const String& url_prefix =
      String::Handle(group_reload_context_->root_url_prefix_);
  const String& old_url_prefix =
      String::Handle(group_reload_context_->old_root_url_prefix_);
  const intptr_t prefix_length = url_prefix.Length();
  const intptr_t old_prefix_length = old_url_prefix.Length();
  const String& new_url = String::Handle(replacement_or_new.url());
  const String& suffix =
      String::Handle(String::SubString(new_url, prefix_length));
  if (!new_url.StartsWith(url_prefix)) {
    return Library::null();
  }
  Library& old = Library::Handle();
  String& old_url = String::Handle();
  String& old_suffix = String::Handle();
  const auto& saved_libs = GrowableObjectArray::Handle(saved_libraries_);
  ASSERT(!saved_libs.IsNull());
  for (intptr_t i = 0; i < saved_libs.Length(); i++) {
    old = Library::RawCast(saved_libs.At(i));
    old_url = old.url();
    if (!old_url.StartsWith(old_url_prefix)) {
      continue;
    }
    old_suffix = String::SubString(old_url, old_prefix_length);
    if (old_suffix.IsNull()) {
      continue;
    }
    if (old_suffix.Equals(suffix)) {
      TIR_Print("`%s` is moving to `%s`\n", old_url.ToCString(),
                new_url.ToCString());
      return old.ptr();
    }
  }
  return Library::null();
}

void ProgramReloadContext::BuildLibraryMapping() {
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());

  Library& replacement_or_new = Library::Handle();
  Library& old = Library::Handle();
  for (intptr_t i = group_reload_context_->num_saved_libs_; i < libs.Length();
       i++) {
    replacement_or_new = Library::RawCast(libs.At(i));
    old = OldLibraryOrNull(replacement_or_new);
    if (old.IsNull()) {
      if (FLAG_identity_reload) {
        TIR_Print("Could not find original library for %s\n",
                  replacement_or_new.ToCString());
        UNREACHABLE();
      }
      // New library.
      AddLibraryMapping(replacement_or_new, replacement_or_new);
    } else {
      ASSERT(!replacement_or_new.is_dart_scheme());
      // Replaced class.
      AddLibraryMapping(replacement_or_new, old);

      AddBecomeMapping(old, replacement_or_new);
    }
  }
}

// Find classes that have been removed from the program.
// Instances of these classes may still be referenced from variables, so the
// functions of these class may still execute in the future, and they need to
// be given patch class owners still they correctly reference their (old) kernel
// data even after the library's kernel data is updated.
//
// Note that all such classes must belong to a library that has either been
// changed or removed.
void ProgramReloadContext::BuildRemovedClassesSet() {
  // Find all old classes [mapped_old_classes_set].
  UnorderedHashMap<ClassMapTraits> class_map(class_map_storage_);
  UnorderedHashSet<ClassMapTraits> mapped_old_classes_set(
      HashTables::New<UnorderedHashSet<ClassMapTraits> >(
          class_map.NumOccupied()));
  {
    UnorderedHashMap<ClassMapTraits>::Iterator it(&class_map);
    Class& cls = Class::Handle();
    Class& new_cls = Class::Handle();
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      new_cls = Class::RawCast(class_map.GetKey(entry));
      cls = Class::RawCast(class_map.GetPayload(entry, 0));
      mapped_old_classes_set.InsertOrGet(cls);
    }
  }
  class_map.Release();

  // Find all reloaded libraries [mapped_old_library_set].
  UnorderedHashMap<LibraryMapTraits> library_map(library_map_storage_);
  UnorderedHashMap<LibraryMapTraits>::Iterator it_library(&library_map);
  UnorderedHashSet<LibraryMapTraits> mapped_old_library_set(
      HashTables::New<UnorderedHashSet<LibraryMapTraits> >(
          library_map.NumOccupied()));
  {
    Library& old_library = Library::Handle();
    Library& new_library = Library::Handle();
    while (it_library.MoveNext()) {
      const intptr_t entry = it_library.Current();
      new_library ^= library_map.GetKey(entry);
      old_library ^= library_map.GetPayload(entry, 0);
      if (new_library.ptr() != old_library.ptr()) {
        mapped_old_library_set.InsertOrGet(old_library);
      }
    }
  }

  // For every old class, check if it's library was reloaded and if
  // the class was mapped. If the class wasn't mapped - add it to
  // [removed_class_set].
  UnorderedHashSet<ClassMapTraits> old_classes_set(old_classes_set_storage_);
  UnorderedHashSet<ClassMapTraits>::Iterator it(&old_classes_set);
  UnorderedHashSet<ClassMapTraits> removed_class_set(
      removed_class_set_storage_);
  Class& old_cls = Class::Handle();
  Class& new_cls = Class::Handle();
  Library& old_library = Library::Handle();
  Library& mapped_old_library = Library::Handle();
  while (it.MoveNext()) {
    const intptr_t entry = it.Current();
    old_cls ^= Class::RawCast(old_classes_set.GetKey(entry));
    old_library = old_cls.library();
    if (old_library.IsNull()) {
      continue;
    }
    mapped_old_library ^= mapped_old_library_set.GetOrNull(old_library);
    if (!mapped_old_library.IsNull()) {
      new_cls ^= mapped_old_classes_set.GetOrNull(old_cls);
      if (new_cls.IsNull()) {
        removed_class_set.InsertOrGet(old_cls);
      }
    }
  }
  removed_class_set_storage_ = removed_class_set.Release().ptr();

  old_classes_set.Release();
  mapped_old_classes_set.Release();
  mapped_old_library_set.Release();
  library_map.Release();
}

void ProgramReloadContext::AddClassMapping(const Class& replacement_or_new,
                                           const Class& original) {
  UnorderedHashMap<ClassMapTraits> map(class_map_storage_);
  bool update = map.UpdateOrInsert(replacement_or_new, original);
  ASSERT(!update);
  // The storage given to the map may have been reallocated, remember the new
  // address.
  class_map_storage_ = map.Release().ptr();
}

void ProgramReloadContext::AddLibraryMapping(const Library& replacement_or_new,
                                             const Library& original) {
  UnorderedHashMap<LibraryMapTraits> map(library_map_storage_);
  bool update = map.UpdateOrInsert(replacement_or_new, original);
  ASSERT(!update);
  // The storage given to the map may have been reallocated, remember the new
  // address.
  library_map_storage_ = map.Release().ptr();
}

void ProgramReloadContext::AddStaticFieldMapping(const Field& old_field,
                                                 const Field& new_field) {
  ASSERT(old_field.is_static());
  ASSERT(new_field.is_static());

  AddBecomeMapping(old_field, new_field);
}

void ProgramReloadContext::AddBecomeMapping(const Object& old,
                                            const Object& neu) {
  ASSERT(become_map_storage_ != Array::null());
  UnorderedHashMap<BecomeMapTraits> become_map(become_map_storage_);
  bool update = become_map.UpdateOrInsert(old, neu);
  ASSERT(!update);
  become_map_storage_ = become_map.Release().ptr();
}

void ProgramReloadContext::AddEnumBecomeMapping(const Object& old,
                                                const Object& neu) {
  const GrowableObjectArray& become_enum_mappings =
      GrowableObjectArray::Handle(become_enum_mappings_);
  become_enum_mappings.Add(old);
  become_enum_mappings.Add(neu);
  ASSERT((become_enum_mappings.Length() % 2) == 0);
}

void ProgramReloadContext::RebuildDirectSubclasses() {
  ClassTable* class_table = IG->class_table();
  intptr_t num_cids = class_table->NumCids();

  // Clear the direct subclasses for all classes.
  Class& cls = Class::Handle();
  const GrowableObjectArray& null_list = GrowableObjectArray::Handle();
  for (intptr_t i = 1; i < num_cids; i++) {
    if (class_table->HasValidClassAt(i)) {
      cls = class_table->At(i);
      if (!cls.is_declaration_loaded()) {
        continue;  // Can't have any subclasses or implementors yet.
      }
      // Testing for null to prevent attempting to write to read-only classes
      // in the VM isolate.
      if (cls.direct_subclasses() != GrowableObjectArray::null()) {
        cls.set_direct_subclasses(null_list);
      }
      if (cls.direct_implementors() != GrowableObjectArray::null()) {
        cls.set_direct_implementors(null_list);
      }
    }
  }

  // Recompute the direct subclasses / implementors.

  AbstractType& super_type = AbstractType::Handle();
  Class& super_cls = Class::Handle();

  Array& interface_types = Array::Handle();
  AbstractType& interface_type = AbstractType::Handle();
  Class& interface_class = Class::Handle();

  for (intptr_t i = 1; i < num_cids; i++) {
    if (class_table->HasValidClassAt(i)) {
      cls = class_table->At(i);
      if (!cls.is_declaration_loaded()) {
        continue;  // Will register itself later when loaded.
      }
      super_type = cls.super_type();
      if (!super_type.IsNull() && !super_type.IsObjectType()) {
        super_cls = cls.SuperClass();
        ASSERT(!super_cls.IsNull());
        super_cls.AddDirectSubclass(cls);
      }

      interface_types = cls.interfaces();
      if (!interface_types.IsNull()) {
        const intptr_t mixin_index = cls.is_transformed_mixin_application()
                                         ? interface_types.Length() - 1
                                         : -1;
        for (intptr_t j = 0; j < interface_types.Length(); ++j) {
          interface_type ^= interface_types.At(j);
          interface_class = interface_type.type_class();
          interface_class.AddDirectImplementor(
              cls, /* is_mixin = */ i == mixin_index);
        }
      }
    }
  }
}

void ReloadHandler::RegisterIsolate() {
  SafepointMonitorLocker ml(&monitor_);
  ParticipateIfReloadRequested(&ml, /*is_registered=*/false,
                               /*allow_later_retry=*/false);
  ASSERT(reloading_thread_ == nullptr);
  ++registered_isolate_count_;
}

void ReloadHandler::UnregisterIsolate() {
  SafepointMonitorLocker ml(&monitor_);
  ParticipateIfReloadRequested(&ml, /*is_registered=*/true,
                               /*allow_later_retry=*/false);
  ASSERT(reloading_thread_ == nullptr);
  --registered_isolate_count_;
}

void ReloadHandler::CheckForReload() {
  SafepointMonitorLocker ml(&monitor_);
  ParticipateIfReloadRequested(&ml, /*is_registered=*/true,
                               /*allow_later_retry=*/true);
}

void ReloadHandler::ParticipateIfReloadRequested(SafepointMonitorLocker* ml,
                                                 bool is_registered,
                                                 bool allow_later_retry) {
  if (reloading_thread_ != nullptr) {
    auto thread = Thread::Current();
    auto isolate = thread->isolate();

    // If the current thread is in a no reload scope, we'll not participate here
    // and instead delay to a point (further up the stack, namely in the main
    // message handling loop) where this isolate can participate.
    if (thread->IsInNoReloadScope()) {
      RELEASE_ASSERT(allow_later_retry);
      isolate->SendInternalLibMessage(Isolate::kCheckForReload, /*ignored=*/-1);
      return;
    }

    if (is_registered) {
      SafepointMonitorLocker ml(&checkin_monitor_);
      ++isolates_checked_in_;
      ml.NotifyAll();
    }
    // While we're waiting for the reload to be performed, we'll exit the
    // isolate. That will transition into a safepoint - which a blocking `Wait`
    // would also do - but it does something in addition: It will release it's
    // current TLAB and decrease the mutator count. We want this in order to let
    // all isolates in the group participate in the reload, despite our parallel
    // mutator limit.
    while (reloading_thread_ != nullptr) {
      SafepointMonitorUnlockScope ml_unlocker(ml);
      Thread::ExitIsolate(/*nested=*/true);
      {
        MonitorLocker ml(&monitor_);
        while (reloading_thread_ != nullptr) {
          ml.Wait();
        }
      }
      Thread::EnterIsolate(isolate, /*nested=*/true);
    }
    if (is_registered) {
      SafepointMonitorLocker ml(&checkin_monitor_);
      --isolates_checked_in_;
    }
  }
}

void ReloadHandler::PauseIsolatesForReloadLocked() {
  intptr_t registered = -1;
  {
    SafepointMonitorLocker ml(&monitor_);

    // Maybe participate in existing reload requested by another isolate.
    ParticipateIfReloadRequested(&ml, /*registered=*/true,
                                 /*allow_later_retry=*/false);

    // Now it's our turn to request reload.
    ASSERT(reloading_thread_ == nullptr);
    reloading_thread_ = Thread::Current();

    // At this point no isolate register/unregister, so we save the current
    // number of registered isolates.
    registered = registered_isolate_count_;
  }

  // Send OOB to a superset of all registered isolates and make them participate
  // in this reload.
  reloading_thread_->isolate_group()->ForEachIsolate([](Isolate* isolate) {
    isolate->SendInternalLibMessage(Isolate::kCheckForReload, /*ignored=*/-1);
  });

  {
    SafepointMonitorLocker ml(&checkin_monitor_);
    while (isolates_checked_in_ < (registered - /*reload_requester=*/1)) {
      ml.Wait();
    }
  }
}

void ReloadHandler::ResumeIsolatesLocked() {
  {
    SafepointMonitorLocker ml(&monitor_);
    ASSERT(reloading_thread_ == Thread::Current());
    reloading_thread_ = nullptr;
    ml.NotifyAll();
  }
}

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
