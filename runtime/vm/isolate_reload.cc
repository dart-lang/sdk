// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate_reload.h"

#include "vm/become.h"
#include "vm/bit_vector.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/hash_table.h"
#include "vm/isolate.h"
#include "vm/kernel_isolate.h"
#include "vm/kernel_loader.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/runtime_entry.h"
#include "vm/safepoint.h"
#include "vm/service_event.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"
#include "vm/timeline.h"
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

#define I (isolate())
#define Z (thread->zone())

#define TIMELINE_SCOPE(name)                                                   \
  TimelineDurationScope tds##name(Thread::Current(),                           \
                                  Timeline::GetIsolateStream(), #name)

InstanceMorpher::InstanceMorpher(Zone* zone, const Class& from, const Class& to)
    : from_(Class::Handle(zone, from.raw())),
      to_(Class::Handle(zone, to.raw())),
      mapping_(zone, 0) {
  before_ = new (zone) ZoneGrowableArray<const Instance*>(zone, 0);
  after_ = new (zone) ZoneGrowableArray<const Instance*>(zone, 0);
  new_fields_ = new (zone) ZoneGrowableArray<const Field*>(zone, 0);
  ASSERT(from_.id() == to_.id());
  cid_ = from_.id();
  ComputeMapping();
}

void InstanceMorpher::AddObject(RawObject* object) const {
  ASSERT(object->GetClassId() == cid());
  const Instance& instance = Instance::Cast(Object::Handle(object));
  before_->Add(&instance);
}

void InstanceMorpher::ComputeMapping() {
  if (from_.NumTypeArguments()) {
    // Add copying of the optional type argument field.
    intptr_t from_offset = from_.type_arguments_field_offset();
    ASSERT(from_offset != Class::kNoTypeArguments);
    intptr_t to_offset = to_.type_arguments_field_offset();
    ASSERT(to_offset != Class::kNoTypeArguments);
    mapping_.Add(from_offset);
    mapping_.Add(to_offset);
  }

  // Add copying of the instance fields if matching by name.
  // Note: currently the type of the fields are ignored.
  const Array& from_fields =
      Array::Handle(from_.OffsetToFieldMap(true /* original classes */));
  const Array& to_fields = Array::Handle(to_.OffsetToFieldMap());
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
        mapping_.Add(from_field.Offset());
        mapping_.Add(to_field.Offset());
        // Field did exist in old class deifnition.
        new_field = false;
      }
    }

    if (new_field) {
      if (to_field.has_initializer()) {
        // This is a new field with an initializer.
        const Field& field = Field::Handle(to_field.raw());
        new_fields_->Add(&field);
      }
    }
  }
}

RawInstance* InstanceMorpher::Morph(const Instance& instance) const {
  const Instance& result = Instance::Handle(Instance::New(to_));
  // Morph the context from instance to result using mapping_.
  for (intptr_t i = 0; i < mapping_.length(); i += 2) {
    intptr_t from_offset = mapping_.At(i);
    intptr_t to_offset = mapping_.At(i + 1);
    const Object& value =
        Object::Handle(instance.RawGetFieldAtOffset(from_offset));
    result.RawSetFieldAtOffset(to_offset, value);
  }
  // Convert the instance into a filler object.
  Become::MakeDummyObject(instance);
  return result.raw();
}

void InstanceMorpher::RunNewFieldInitializers() const {
  if ((new_fields_->length() == 0) || (after_->length() == 0)) {
    return;
  }

  TIR_Print("Running new field initializers for class: %s\n", to_.ToCString());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  String& initializing_expression = String::Handle(zone);
  Function& eval_func = Function::Handle(zone);
  Object& result = Object::Handle(zone);
  Class& owning_class = Class::Handle(zone);
  // For each new field.
  for (intptr_t i = 0; i < new_fields_->length(); i++) {
    // Create a function that returns the expression.
    const Field* field = new_fields_->At(i);
    if (field->kernel_offset() > 0) {
      eval_func ^= kernel::CreateFieldInitializerFunction(thread, zone, *field);
    } else {
      owning_class ^= field->Owner();
      ASSERT(!owning_class.IsNull());
      // Extract the initializing expression.
      initializing_expression = field->InitializingExpression();
      TIR_Print("New `%s` has initializing expression `%s`\n",
                field->ToCString(), initializing_expression.ToCString());
      eval_func ^= Function::EvaluateHelper(
          owning_class, initializing_expression, Array::empty_array(), true);
    }

    for (intptr_t j = 0; j < after_->length(); j++) {
      const Instance* instance = after_->At(j);
      TIR_Print("Initializing instance %" Pd " / %" Pd "\n", j + 1,
                after_->length());
      // Run the function and assign the field.
      result = DartEntry::InvokeFunction(eval_func, Array::empty_array());
      if (result.IsError()) {
        // TODO(johnmccutchan): Report this error in the reload response?
        OS::PrintErr(
            "RELOAD: Running initializer for new field `%s` resulted in "
            "an error: %s\n",
            field->ToCString(), Error::Cast(result).ToErrorCString());
        continue;
      }
      instance->RawSetFieldAtOffset(field->Offset(), result);
    }
  }
}

void InstanceMorpher::CreateMorphedCopies() const {
  for (intptr_t i = 0; i < before()->length(); i++) {
    const Instance& copy = Instance::Handle(Morph(*before()->At(i)));
    after()->Add(&copy);
  }
}

void InstanceMorpher::DumpFormatFor(const Class& cls) const {
  THR_Print("%s\n", cls.ToCString());
  if (cls.NumTypeArguments()) {
    intptr_t field_offset = cls.type_arguments_field_offset();
    ASSERT(field_offset != Class::kNoTypeArguments);
    THR_Print("  - @%" Pd " <type arguments>\n", field_offset);
  }
  const Array& fields = Array::Handle(cls.OffsetToFieldMap());
  Field& field = Field::Handle();
  String& name = String::Handle();
  for (intptr_t i = 0; i < fields.Length(); i++) {
    if (fields.At(i) != Field::null()) {
      field = Field::RawCast(fields.At(i));
      ASSERT(field.is_instance());
      name = field.name();
      THR_Print("  - @%" Pd " %s\n", field.Offset(), name.ToCString());
    }
  }

  THR_Print("Mapping: ");
  for (int i = 0; i < mapping_.length(); i += 2) {
    THR_Print(" %" Pd "->%" Pd, mapping_.At(i), mapping_.At(i + 1));
  }
  THR_Print("\n");
}

void InstanceMorpher::Dump() const {
  LogBlock blocker;
  THR_Print("Morphing from ");
  DumpFormatFor(from_);
  THR_Print("To ");
  DumpFormatFor(to_);
  THR_Print("\n");
}

void InstanceMorpher::AppendTo(JSONArray* array) {
  JSONObject jsobj(array);
  jsobj.AddProperty("type", "ShapeChangeMapping");
  jsobj.AddProperty("class", to_);
  jsobj.AddProperty("instanceCount", before()->length());
  JSONArray map(&jsobj, "fieldOffsetMappings");
  for (int i = 0; i < mapping_.length(); i += 2) {
    JSONArray pair(&map);
    pair.AddValue(mapping_.At(i));
    pair.AddValue(mapping_.At(i + 1));
  }
}

void ReasonForCancelling::Report(IsolateReloadContext* context) {
  const Error& error = Error::Handle(ToError());
  context->ReportError(error);
}

RawError* ReasonForCancelling::ToError() {
  // By default create the error returned from ToString.
  const String& message = String::Handle(ToString());
  return LanguageError::New(message);
}

RawString* ReasonForCancelling::ToString() {
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
      from_(Class::ZoneHandle(zone, from.raw())),
      to_(Class::ZoneHandle(zone, to.raw())) {}

void ClassReasonForCancelling::AppendTo(JSONArray* array) {
  JSONObject jsobj(array);
  jsobj.AddProperty("type", "ReasonForCancelling");
  jsobj.AddProperty("class", from_);
  const String& message = String::Handle(ToString());
  jsobj.AddProperty("message", message.ToCString());
}

RawError* IsolateReloadContext::error() const {
  ASSERT(reload_aborted());
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
    return IsolateReloadContext::IsSameClass(Class::Cast(a), Class::Cast(b));
  }

  static uword Hash(const Object& obj) {
    return String::HashRawSymbol(Class::Cast(obj).Name());
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
    return IsolateReloadContext::IsSameLibrary(Library::Cast(a),
                                               Library::Cast(b));
  }

  static uword Hash(const Object& obj) { return Library::Cast(obj).UrlHash(); }
};

class BecomeMapTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "BecomeMapTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    return a.raw() == b.raw();
  }

  static uword Hash(const Object& obj) {
    if (obj.IsLibrary()) {
      return Library::Cast(obj).UrlHash();
    } else if (obj.IsClass()) {
      if (Class::Cast(obj).id() == kFreeListElement) {
        return 0;
      }
      return String::HashRawSymbol(Class::Cast(obj).Name());
    } else if (obj.IsField()) {
      return String::HashRawSymbol(Field::Cast(obj).name());
    } else if (obj.IsInstance()) {
      Object& hashObj = Object::Handle(Instance::Cast(obj).HashCode());
      if (hashObj.IsError()) {
        Exceptions::PropagateError(Error::Cast(hashObj));
      }
      return Smi::Cast(hashObj).Value();
    }
    return 0;
  }
};

bool IsolateReloadContext::IsSameField(const Field& a, const Field& b) {
  if (a.is_static() != b.is_static()) {
    return false;
  }
  const Class& a_cls = Class::Handle(a.Owner());
  const Class& b_cls = Class::Handle(b.Owner());

  if (!IsSameClass(a_cls, b_cls)) {
    return false;
  }

  const String& a_name = String::Handle(a.name());
  const String& b_name = String::Handle(b.name());

  return a_name.Equals(b_name);
}

bool IsolateReloadContext::IsSameClass(const Class& a, const Class& b) {
  if (a.is_patch() != b.is_patch()) {
    // TODO(johnmccutchan): Should we just check the class kind bits?
    return false;
  }

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
    return a_lib.raw() == b_lib.raw();
  }
  return (a_lib.private_key() == b_lib.private_key());
}

bool IsolateReloadContext::IsSameLibrary(const Library& a_lib,
                                         const Library& b_lib) {
  const String& a_lib_url =
      String::Handle(a_lib.IsNull() ? String::null() : a_lib.url());
  const String& b_lib_url =
      String::Handle(b_lib.IsNull() ? String::null() : b_lib.url());
  return a_lib_url.Equals(b_lib_url);
}

IsolateReloadContext::IsolateReloadContext(Isolate* isolate, JSONStream* js)
    : zone_(Thread::Current()->zone()),
      start_time_micros_(OS::GetCurrentMonotonicMicros()),
      reload_timestamp_(OS::GetCurrentTimeMillis()),
      isolate_(isolate),
      reload_skipped_(false),
      reload_aborted_(false),
      reload_finalized_(false),
      js_(js),
      saved_num_cids_(-1),
      saved_class_table_(NULL),
      num_saved_libs_(-1),
      instance_morphers_(zone_, 0),
      reasons_to_cancel_reload_(zone_, 0),
      cid_mapper_(),
      modified_libs_(NULL),
      script_url_(String::null()),
      error_(Error::null()),
      old_classes_set_storage_(Array::null()),
      class_map_storage_(Array::null()),
      old_libraries_set_storage_(Array::null()),
      library_map_storage_(Array::null()),
      become_map_storage_(Array::null()),
      become_enum_mappings_(GrowableObjectArray::null()),
      saved_root_library_(Library::null()),
      saved_libraries_(GrowableObjectArray::null()),
      root_url_prefix_(String::null()),
      old_root_url_prefix_(String::null()) {
  // NOTE: DO NOT ALLOCATE ANY RAW OBJECTS HERE. The IsolateReloadContext is not
  // associated with the isolate yet and if a GC is triggered here the raw
  // objects will not be properly accounted for.
  ASSERT(zone_ != NULL);
}

IsolateReloadContext::~IsolateReloadContext() {
  ASSERT(zone_ == Thread::Current()->zone());
  ASSERT(saved_class_table_ == NULL);
}

void IsolateReloadContext::ReportError(const Error& error) {
  if (FLAG_trace_reload) {
    THR_Print("ISO-RELOAD: Error: %s\n", error.ToErrorCString());
  }
  ServiceEvent service_event(I, ServiceEvent::kIsolateReload);
  service_event.set_reload_error(&error);
  Service::HandleEvent(&service_event);
}

void IsolateReloadContext::ReportSuccess() {
  ServiceEvent service_event(I, ServiceEvent::kIsolateReload);
  Service::HandleEvent(&service_event);
}

class Aborted : public ReasonForCancelling {
 public:
  Aborted(Zone* zone, const Error& error)
      : ReasonForCancelling(zone),
        error_(Error::ZoneHandle(zone, error.raw())) {}

 private:
  const Error& error_;

  RawError* ToError() { return error_.raw(); }
  RawString* ToString() {
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

template <class T>
class ResourceHolder : ValueObject {
  T* resource_;

 public:
  ResourceHolder() : resource_(NULL) {}
  void set(T* resource) { resource_ = resource; }
  T* get() { return resource_; }
  ~ResourceHolder() { delete (resource_); }
};

static void ReleaseFetchedBytes(uint8_t* buffer) {
  free(buffer);
}

static void AcceptCompilation(Thread* thread) {
  TransitionVMToNative transition(thread);
  if (KernelIsolate::AcceptCompilation().status !=
      Dart_KernelCompilationStatus_Ok) {
    FATAL(
        "An error occurred in the CFE while accepting the most recent"
        " compilation results.");
  }
}

// NOTE: This function returns *after* FinalizeLoading is called.
void IsolateReloadContext::Reload(bool force_reload,
                                  const char* root_script_url,
                                  const char* packages_url_) {
  TIMELINE_SCOPE(Reload);
  Thread* thread = Thread::Current();
  ASSERT(isolate() == thread->isolate());

  // Grab root library before calling CheckpointBeforeReload.
  const Library& old_root_lib = Library::Handle(object_store()->root_library());
  ASSERT(!old_root_lib.IsNull());
  const String& old_root_lib_url = String::Handle(old_root_lib.url());
  // Root library url.
  const String& root_lib_url =
      (root_script_url == NULL) ? old_root_lib_url
                                : String::Handle(String::New(root_script_url));
  bool root_lib_modified = false;

  // Check to see if the base url of the loaded libraries has moved.
  if (!old_root_lib_url.Equals(root_lib_url)) {
    root_lib_modified = true;
    const char* old_root_library_url_c = old_root_lib_url.ToCString();
    const char* root_library_url_c = root_lib_url.ToCString();
    const intptr_t common_suffix_length =
        CommonSuffixLength(root_library_url_c, old_root_library_url_c);
    root_url_prefix_ = String::SubString(
        root_lib_url, 0, root_lib_url.Length() - common_suffix_length + 1);
    old_root_url_prefix_ =
        String::SubString(old_root_lib_url, 0,
                          old_root_lib_url.Length() - common_suffix_length + 1);
  }

  Object& result = Object::Handle(thread->zone());
  ResourceHolder<kernel::Program> kernel_program;
  String& packages_url = String::Handle();
  if (packages_url_ != NULL) {
    packages_url = String::New(packages_url_);
  }

  bool did_kernel_compilation = false;
  if (isolate()->use_dart_frontend()) {
    // Load the kernel program and figure out the modified libraries.
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(object_store()->libraries());
    intptr_t num_libs = libs.Length();
    modified_libs_ = new (Z) BitVector(Z, num_libs);

    // ReadKernelFromFile checks to see if the file at
    // root_script_url is a valid .dill file. If that's the case, a Program*
    // is returned. Otherwise, this is likely a source file that needs to be
    // compiled, so ReadKernelFromFile returns NULL.
    kernel_program.set(kernel::Program::ReadFromFile(root_script_url));
    if (kernel_program.get() == NULL) {
      TransitionVMToNative transition(thread);
      Dart_SourceFile* modified_scripts = NULL;
      intptr_t modified_scripts_count = 0;

      FindModifiedSources(thread, force_reload, &modified_scripts,
                          &modified_scripts_count);

      Dart_KernelCompilationResult retval = KernelIsolate::CompileToKernel(
          root_lib_url.ToCString(), NULL, 0, modified_scripts_count,
          modified_scripts, true, NULL);

      if (retval.status != Dart_KernelCompilationStatus_Ok) {
        TIR_Print("---- LOAD FAILED, ABORTING RELOAD\n");
        const String& error_str = String::Handle(String::New(retval.error));
        free(retval.error);
        const ApiError& error = ApiError::Handle(ApiError::New(error_str));
        AddReasonForCancelling(new Aborted(zone_, error));
        ReportReasonsForCancelling();
        CommonFinalizeTail();
        return;
      }
      did_kernel_compilation = true;
      kernel_program.set(kernel::Program::ReadFromBuffer(
          retval.kernel, retval.kernel_size, true));
    }

    kernel_program.get()->set_release_buffer_callback(ReleaseFetchedBytes);
    kernel::KernelLoader::FindModifiedLibraries(kernel_program.get(), I,
                                                modified_libs_, force_reload);
  } else {
    // Check to see which libraries have been modified.
    modified_libs_ = FindModifiedLibraries(force_reload, root_lib_modified);
  }
  if (!modified_libs_->Contains(old_root_lib.index())) {
    ASSERT(modified_libs_->IsEmpty());
    reload_skipped_ = true;
    // Inform GetUnusedChangesInLastReload that a reload has happened.
    I->object_store()->set_changed_in_last_reload(
        GrowableObjectArray::Handle(GrowableObjectArray::New()));
    ReportOnJSON(js_);

    // If we use the CFE and performed a compilation, we need to notify that
    // we have accepted the compilation to clear some state in the incremental
    // compiler.
    if (isolate()->use_dart_frontend() && did_kernel_compilation) {
      AcceptCompilation(thread);
    }
    TIR_Print("---- SKIPPING RELOAD (No libraries were modified)\n");
    return;
  }

  TIR_Print("---- STARTING RELOAD\n");

  // Preallocate storage for maps.
  old_classes_set_storage_ =
      HashTables::New<UnorderedHashSet<ClassMapTraits> >(4);
  class_map_storage_ = HashTables::New<UnorderedHashMap<ClassMapTraits> >(4);
  old_libraries_set_storage_ =
      HashTables::New<UnorderedHashSet<LibraryMapTraits> >(4);
  library_map_storage_ =
      HashTables::New<UnorderedHashMap<LibraryMapTraits> >(4);
  become_map_storage_ = HashTables::New<UnorderedHashMap<BecomeMapTraits> >(4);
  // Keep a separate array for enum mappings to avoid having to invoke
  // hashCode on the instances.
  become_enum_mappings_ = GrowableObjectArray::New(Heap::kOld);

  // Disable the background compiler while we are performing the reload.
  BackgroundCompiler::Disable(I);

  // Ensure all functions on the stack have unoptimized code.
  EnsuredUnoptimizedCodeForStack();
  // Deoptimize all code that had optimizing decisions that are dependent on
  // assumptions from field guards or CHA or deferred library prefixes.
  // TODO(johnmccutchan): Deoptimizing dependent code here (before the reload)
  // is paranoid. This likely can be moved to the commit phase.
  DeoptimizeDependentCode();
  Checkpoint();

  // WEIRD CONTROL FLOW BEGINS.
  //
  // The flow of execution until we return from the tag handler can be complex.
  //
  // On a successful load, the following will occur:
  //   1) Tag Handler is invoked and the embedder is in control.
  //   2) All sources and libraries are loaded.
  //   3) Dart_FinalizeLoading is called by the embedder.
  //   4) Dart_FinalizeLoading invokes IsolateReloadContext::FinalizeLoading
  //      and we are temporarily back in control.
  //      This is where we validate the reload and commit or reject.
  //   5) Dart_FinalizeLoading invokes Dart code related to deferred libraries.
  //   6) The tag handler returns and we move on.
  //
  // Even after a successful reload the Dart code invoked in (5) can result
  // in an Unwind error or an UnhandledException error. This error will be
  // returned by the tag handler. The tag handler can return other errors,
  // for example, top level parse errors. We want to capture these errors while
  // propagating the UnwindError or an UnhandledException error.

  if (isolate()->use_dart_frontend()) {
    const Object& tmp =
        kernel::KernelLoader::LoadEntireProgram(kernel_program.get());
    if (!tmp.IsError()) {
      Library& lib = Library::Handle(thread->zone());
      lib ^= tmp.raw();
      isolate()->object_store()->set_root_library(lib);
      FinalizeLoading();
      result = Object::null();

      // If we use the CFE and performed a compilation, we need to notify that
      // we have accepted the compilation to clear some state in the incremental
      // compiler.
      if (did_kernel_compilation) {
        AcceptCompilation(thread);
      }
    } else {
      result = tmp.raw();
    }
  } else {
    TIR_Print("---- ENTERING TAG HANDLER\n");
    TransitionVMToNative transition(thread);
    Api::Scope api_scope(thread);

    Dart_Handle retval = (I->library_tag_handler())(
        Dart_kScriptTag, Api::NewHandle(thread, packages_url.raw()),
        Api::NewHandle(thread, root_lib_url.raw()));
    result = Api::UnwrapHandle(retval);
    TIR_Print("---- EXITED TAG HANDLER\n");
  }
  //
  // WEIRD CONTROL FLOW ENDS.

  // Re-enable the background compiler. Do this before propagating any errors.
  BackgroundCompiler::Enable(I);

  if (result.IsUnwindError()) {
    if (thread->top_exit_frame_info() == 0) {
      // We can only propagate errors when there are Dart frames on the stack.
      // In this case there are no Dart frames on the stack and we set the
      // thread's sticky error. This error will be returned to the message
      // handler.
      thread->set_sticky_error(Error::Cast(result));
    } else {
      // If the tag handler returns with an UnwindError error, propagate it and
      // give up.
      Exceptions::PropagateError(Error::Cast(result));
      UNREACHABLE();
    }
  }

  // Other errors (e.g. a parse error) are captured by the reload system.
  if (result.IsError()) {
    FinalizeFailedLoad(Error::Cast(result));
  }
}

void IsolateReloadContext::RegisterClass(const Class& new_cls) {
  const Class& old_cls = Class::Handle(OldClassOrNull(new_cls));
  if (old_cls.IsNull()) {
    I->class_table()->Register(new_cls);

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
  isolate()->class_table()->SetAt(old_cls.id(), new_cls.raw());
  if (!old_cls.is_enum_class()) {
    new_cls.CopyCanonicalConstants(old_cls);
  }
  new_cls.CopyCanonicalType(old_cls);
  AddBecomeMapping(old_cls, new_cls);
  AddClassMapping(new_cls, old_cls);
}

// FinalizeLoading will be called *before* Reload() returns but will not be
// called if the embedder fails to load sources.
void IsolateReloadContext::FinalizeLoading() {
  if (reload_skipped_ || reload_finalized_) {
    return;
  }
  BuildLibraryMapping();
  TIR_Print("---- LOAD SUCCEEDED\n");
  if (ValidateReload()) {
    Commit();
    PostCommit();
    isolate()->set_last_reload_timestamp(reload_timestamp_);
  } else {
    ReportReasonsForCancelling();
    Rollback();
  }
  // ValidateReload mutates the direct subclass information and does
  // not remove dead subclasses.  Rebuild the direct subclass
  // information from scratch.
  RebuildDirectSubclasses();
  CommonFinalizeTail();
}

// FinalizeFailedLoad will be called *before* Reload() returns and will only
// be called if the embedder fails to load sources.
void IsolateReloadContext::FinalizeFailedLoad(const Error& error) {
  TIR_Print("---- LOAD FAILED, ABORTING RELOAD\n");
  AddReasonForCancelling(new Aborted(zone_, error));
  ReportReasonsForCancelling();
  if (!reload_finalized_) {
    Rollback();
  }
  CommonFinalizeTail();
}

void IsolateReloadContext::CommonFinalizeTail() {
  ReportOnJSON(js_);
  reload_finalized_ = true;
}

void IsolateReloadContext::ReportOnJSON(JSONStream* stream) {
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", "ReloadReport");
  jsobj.AddProperty("success", reload_skipped_ || !HasReasonsForCancelling());
  {
    JSONObject details(&jsobj, "details");
    if (reload_skipped_) {
      // Reload was skipped.
      const GrowableObjectArray& libs =
          GrowableObjectArray::Handle(object_store()->libraries());
      const intptr_t final_library_count = libs.Length();
      details.AddProperty("savedLibraryCount", final_library_count);
      details.AddProperty("loadedLibraryCount", static_cast<intptr_t>(0));
      details.AddProperty("finalLibraryCount", final_library_count);
    } else if (HasReasonsForCancelling()) {
      // Reload was rejected.
      JSONArray array(&jsobj, "notices");
      for (intptr_t i = 0; i < reasons_to_cancel_reload_.length(); i++) {
        ReasonForCancelling* reason = reasons_to_cancel_reload_.At(i);
        reason->AppendTo(&array);
      }
    } else {
      // Reload was successful.
      const GrowableObjectArray& libs =
          GrowableObjectArray::Handle(object_store()->libraries());
      const intptr_t final_library_count = libs.Length();
      const intptr_t loaded_library_count =
          final_library_count - num_saved_libs_;
      details.AddProperty("savedLibraryCount", num_saved_libs_);
      details.AddProperty("loadedLibraryCount", loaded_library_count);
      details.AddProperty("finalLibraryCount", final_library_count);
      JSONArray array(&jsobj, "shapeChangeMappings");
      for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
        instance_morphers_.At(i)->AppendTo(&array);
      }
    }
  }
}

void IsolateReloadContext::EnsuredUnoptimizedCodeForStack() {
  TIMELINE_SCOPE(EnsuredUnoptimizedCodeForStack);
  StackFrameIterator it(StackFrameIterator::kDontValidateFrames,
                        Thread::Current(),
                        StackFrameIterator::kNoCrossThreadIteration);

  Function& func = Function::Handle();
  while (it.HasNextFrame()) {
    StackFrame* frame = it.NextFrame();
    if (frame->IsDartFrame()) {
      func = frame->LookupDartFunction();
      ASSERT(!func.IsNull());
      func.EnsureHasCompiledUnoptimizedCode();
    }
  }
}

void IsolateReloadContext::DeoptimizeDependentCode() {
  TIMELINE_SCOPE(DeoptimizeDependentCode);
  ClassTable* class_table = I->class_table();

  const intptr_t bottom = Dart::vm_isolate()->class_table()->NumCids();
  const intptr_t top = I->class_table()->NumCids();
  Class& cls = Class::Handle();
  Array& fields = Array::Handle();
  Field& field = Field::Handle();
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

  // TODO(johnmccutchan): Also call LibraryPrefix::InvalidateDependentCode.
}

void IsolateReloadContext::CheckpointClasses() {
  TIMELINE_SCOPE(CheckpointClasses);
  TIR_Print("---- CHECKPOINTING CLASSES\n");
  // Checkpoint classes before a reload. We need to copy the following:
  // 1) The size of the class table.
  // 2) The class table itself.
  // For efficiency, we build a set of classes before the reload. This set
  // is used to pair new classes with old classes.

  ClassTable* class_table = I->class_table();

  // Copy the size of the class table.
  saved_num_cids_ = I->class_table()->NumCids();

  // Copy of the class table.
  ClassAndSize* local_saved_class_table = reinterpret_cast<ClassAndSize*>(
      malloc(sizeof(ClassAndSize) * saved_num_cids_));

  Class& cls = Class::Handle();
  UnorderedHashSet<ClassMapTraits> old_classes_set(old_classes_set_storage_);
  for (intptr_t i = 0; i < saved_num_cids_; i++) {
    if (class_table->IsValidIndex(i) && class_table->HasValidClassAt(i)) {
      // Copy the class into the saved class table and add it to the set.
      local_saved_class_table[i] = class_table->PairAt(i);
      if (i != kFreeListElement && i != kForwardingCorpse) {
        cls = class_table->At(i);
        bool already_present = old_classes_set.Insert(cls);
        ASSERT(!already_present);
      }
    } else {
      // No class at this index, mark it as NULL.
      local_saved_class_table[i] = ClassAndSize(NULL);
    }
  }
  old_classes_set_storage_ = old_classes_set.Release().raw();
  // Assigning the field must be done after saving the class table.
  saved_class_table_ = local_saved_class_table;
  TIR_Print("---- System had %" Pd " classes\n", saved_num_cids_);
}

Dart_FileModifiedCallback IsolateReloadContext::file_modified_callback_ = NULL;

bool IsolateReloadContext::ScriptModifiedSince(const Script& script,
                                               int64_t since) {
  if (file_modified_callback_ == NULL) {
    return true;
  }
  // We use the resolved url to determine if the script has been modified.
  const String& url = String::Handle(script.resolved_url());
  const char* url_chars = url.ToCString();
  return (*file_modified_callback_)(url_chars, since);
}

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

void IsolateReloadContext::FindModifiedSources(
    Thread* thread,
    bool force_reload,
    Dart_SourceFile** modified_sources,
    intptr_t* count) {
  Zone* zone = thread->zone();
  int64_t last_reload = I->last_reload_timestamp();
  GrowableArray<const char*> modified_sources_uris;
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Array& scripts = Array::Handle(zone);
  Script& script = Script::Handle(zone);
  String& uri = String::Handle(zone);

  for (intptr_t lib_idx = 0; lib_idx < libs.Length(); lib_idx++) {
    lib ^= libs.At(lib_idx);
    if (lib.is_dart_scheme()) {
      // We don't consider dart scheme libraries during reload.
      continue;
    }
    scripts = lib.LoadedScripts();
    for (intptr_t script_idx = 0; script_idx < scripts.Length(); script_idx++) {
      script ^= scripts.At(script_idx);
      uri ^= script.url();
      if (ContainsScriptUri(modified_sources_uris, uri.ToCString())) {
        // We've already accounted for this script in a prior library.
        continue;
      }

      if (force_reload || ScriptModifiedSince(script, last_reload)) {
        modified_sources_uris.Add(uri.ToCString());
      }
    }
  }

  *count = modified_sources_uris.length();
  if (*count == 0) {
    return;
  }

  *modified_sources = new (zone_) Dart_SourceFile[*count];
  for (intptr_t i = 0; i < *count; ++i) {
    (*modified_sources)[i].uri = modified_sources_uris[i];
    (*modified_sources)[i].source = NULL;
  }
}

BitVector* IsolateReloadContext::FindModifiedLibraries(bool force_reload,
                                                       bool root_lib_modified) {
  Thread* thread = Thread::Current();
  int64_t last_reload = I->last_reload_timestamp();

  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());
  Library& lib = Library::Handle();
  Array& scripts = Array::Handle();
  Script& script = Script::Handle();
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
        target = ns.library();
        (*imported_by)[target.index()]->Add(lib.index());
      }
    }

    // Add exports to the import-by graph.
    ports = lib.exports();
    for (intptr_t export_idx = 0; export_idx < ports.Length(); export_idx++) {
      ns ^= ports.At(export_idx);
      if (!ns.IsNull()) {
        target = ns.library();
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
        prefix ^= entry.raw();
        ports = prefix.imports();
        for (intptr_t import_idx = 0; import_idx < ports.Length();
             import_idx++) {
          ns ^= ports.At(import_idx);
          if (!ns.IsNull()) {
            target = ns.library();
            (*imported_by)[target.index()]->Add(lib.index());
          }
        }
      }
    }
  }

  BitVector* modified_libs = new (Z) BitVector(Z, num_libs);

  if (root_lib_modified) {
    // The root library was either moved or replaced. Mark it as modified to
    // force a reload of the potential root library replacement.
    lib ^= object_store()->root_library();
    modified_libs->Add(lib.index());
  }

  for (intptr_t lib_idx = 0; lib_idx < num_libs; lib_idx++) {
    lib ^= libs.At(lib_idx);
    if (lib.is_dart_scheme() || modified_libs->Contains(lib_idx)) {
      // We don't consider dart scheme libraries during reload.  If
      // the modified libs set already contains this library, then we
      // have already visited it.
      continue;
    }
    scripts = lib.LoadedScripts();
    for (intptr_t script_idx = 0; script_idx < scripts.Length(); script_idx++) {
      script ^= scripts.At(script_idx);
      if (force_reload || ScriptModifiedSince(script, last_reload)) {
        modified_libs->Add(lib_idx);
        PropagateLibraryModified(imported_by, lib_idx, modified_libs);
        break;
      }
    }
  }

  return modified_libs;
}

void IsolateReloadContext::CheckpointLibraries() {
  TIMELINE_SCOPE(CheckpointLibraries);
  TIR_Print("---- CHECKPOINTING LIBRARIES\n");
  // Save the root library in case we abort the reload.
  const Library& root_lib = Library::Handle(object_store()->root_library());
  set_saved_root_library(root_lib);

  // Save the old libraries array in case we abort the reload.
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());
  set_saved_libraries(libs);

  // Make a filtered copy of the old libraries array. Keep "clean" libraries
  // that we will use instead of reloading.
  const GrowableObjectArray& new_libs =
      GrowableObjectArray::Handle(GrowableObjectArray::New(Heap::kOld));
  Library& lib = Library::Handle();
  UnorderedHashSet<LibraryMapTraits> old_libraries_set(
      old_libraries_set_storage_);
  num_saved_libs_ = 0;
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    if (modified_libs_->Contains(i)) {
      // We are going to reload this library. Clear the index.
      lib.set_index(-1);
    } else {
      // We are preserving this library across the reload, assign its new index
      lib.set_index(new_libs.Length());
      new_libs.Add(lib, Heap::kOld);
      num_saved_libs_++;
    }
    // Add old library to old libraries set.
    bool already_present = old_libraries_set.Insert(lib);
    ASSERT(!already_present);
  }
  modified_libs_ = NULL;  // Renumbering the libraries has invalidated this.
  old_libraries_set_storage_ = old_libraries_set.Release().raw();

  // Reset the registered libraries to the filtered array.
  Library::RegisterLibraries(Thread::Current(), new_libs);
  // Reset the root library to null.
  object_store()->set_root_library(Library::Handle());
}

// While reloading everything we do must be reversible so that we can abort
// safely if the reload fails. This function stashes things to the side and
// prepares the isolate for the reload attempt.
void IsolateReloadContext::Checkpoint() {
  TIMELINE_SCOPE(Checkpoint);
  CheckpointClasses();
  CheckpointLibraries();
}

void IsolateReloadContext::RollbackClasses() {
  TIR_Print("---- ROLLING BACK CLASS TABLE\n");
  ASSERT(saved_num_cids_ > 0);
  ASSERT(saved_class_table_ != NULL);
  ClassTable* class_table = I->class_table();
  class_table->SetNumCids(saved_num_cids_);
  // Overwrite classes in class table with the saved classes.
  for (intptr_t i = 0; i < saved_num_cids_; i++) {
    if (class_table->IsValidIndex(i)) {
      class_table->SetAt(i, saved_class_table_[i].get_raw_class());
    }
  }

  ClassAndSize* local_saved_class_table = saved_class_table_;
  saved_class_table_ = NULL;
  // Can't free this table immediately as another thread (e.g., the sweeper) may
  // be suspended between loading the table pointer and loading the table
  // element. Table will be freed at the next major GC or isolate shutdown.
  class_table->AddOldTable(local_saved_class_table);
}

void IsolateReloadContext::RollbackLibraries() {
  TIR_Print("---- ROLLING BACK LIBRARY CHANGES\n");
  Thread* thread = Thread::Current();
  Library& lib = Library::Handle();
  GrowableObjectArray& saved_libs =
      GrowableObjectArray::Handle(Z, saved_libraries());
  if (!saved_libs.IsNull()) {
    for (intptr_t i = 0; i < saved_libs.Length(); i++) {
      lib = Library::RawCast(saved_libs.At(i));
      // Restore indexes that were modified in CheckpointLibraries.
      lib.set_index(i);
    }

    // Reset the registered libraries to the filtered array.
    Library::RegisterLibraries(thread, saved_libs);
  }

  Library& saved_root_lib = Library::Handle(Z, saved_root_library());
  if (!saved_root_lib.IsNull()) {
    object_store()->set_root_library(saved_root_lib);
  }

  set_saved_root_library(Library::Handle());
  set_saved_libraries(GrowableObjectArray::Handle());
}

void IsolateReloadContext::Rollback() {
  TIR_Print("---- ROLLING BACK");
  RollbackClasses();
  RollbackLibraries();
}

#ifdef DEBUG
void IsolateReloadContext::VerifyMaps() {
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

static void RecordChanges(const GrowableObjectArray& changed_in_last_reload,
                          const Class& old_cls,
                          const Class& new_cls) {
  // All members of enum classes are synthetic, so nothing to report here.
  if (new_cls.is_enum_class()) {
    return;
  }

  // Don't report synthetic classes like the superclass of
  // `class MA extends S with M {}` or `class MA = S with M'. The relevant
  // changes with be reported as changes in M.
  if (new_cls.IsMixinApplication() || new_cls.is_mixin_app_alias()) {
    return;
  }

  // Don't report `typedef bool Predicate(Object o)` as unused. There is nothing
  // to execute.
  if (new_cls.IsTypedefClass()) {
    return;
  }

  if (new_cls.raw() == old_cls.raw()) {
    // A new class maps to itself. All its functions, field initizers, and so
    // on are new.
    changed_in_last_reload.Add(new_cls);
    return;
  }

  ASSERT(new_cls.is_finalized() == old_cls.is_finalized());
  if (!new_cls.is_finalized()) {
    if (new_cls.SourceFingerprint() == old_cls.SourceFingerprint()) {
      return;
    }
    // We don't know the members. Register interest in the whole class. Creates
    // false positives.
    changed_in_last_reload.Add(new_cls);
    return;
  }

  Zone* zone = Thread::Current()->zone();
  const Array& functions = Array::Handle(zone, new_cls.functions());
  const Array& fields = Array::Handle(zone, new_cls.fields());
  Function& new_function = Function::Handle(zone);
  Function& old_function = Function::Handle(zone);
  Field& new_field = Field::Handle(zone);
  Field& old_field = Field::Handle(zone);
  String& selector = String::Handle(zone);
  for (intptr_t i = 0; i < functions.Length(); i++) {
    new_function ^= functions.At(i);
    selector = new_function.name();
    old_function = old_cls.LookupFunction(selector);
    // If we made live changes with proper structed edits, this would just be
    // old != new.
    if (old_function.IsNull() || (new_function.SourceFingerprint() !=
                                  old_function.SourceFingerprint())) {
      ASSERT(!new_function.HasCode());
      ASSERT(new_function.usage_counter() == 0);
      changed_in_last_reload.Add(new_function);
    }
  }
  for (intptr_t i = 0; i < fields.Length(); i++) {
    new_field ^= fields.At(i);
    if (!new_field.is_static()) continue;
    selector = new_field.name();
    old_field = old_cls.LookupField(selector);
    if (old_field.IsNull() || !old_field.is_static()) {
      // New field.
      changed_in_last_reload.Add(new_field);
    } else if (new_field.SourceFingerprint() != old_field.SourceFingerprint()) {
      // Changed field.
      changed_in_last_reload.Add(new_field);
      if (!old_field.IsUninitialized()) {
        new_field.set_initializer_changed_after_initialization(true);
      }
    }
  }
}

void IsolateReloadContext::Commit() {
  TIMELINE_SCOPE(Commit);
  TIR_Print("---- COMMITTING RELOAD\n");

  // Note that the object heap contains before and after instances
  // used for morphing. It is therefore important that morphing takes
  // place prior to any heap walking.
  // So please keep this code at the top of Commit().
  if (!MorphInstances()) {
    free(saved_class_table_);
    saved_class_table_ = NULL;
  }

#ifdef DEBUG
  VerifyMaps();
#endif

  const GrowableObjectArray& changed_in_last_reload =
      GrowableObjectArray::Handle(GrowableObjectArray::New());

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
        if (new_cls.raw() != old_cls.raw()) {
          ASSERT(new_cls.is_enum_class() == old_cls.is_enum_class());
          if (new_cls.is_enum_class() && new_cls.is_finalized()) {
            new_cls.ReplaceEnum(old_cls);
          } else {
            new_cls.CopyStaticFieldValues(old_cls);
          }
          old_cls.PatchFieldsAndFunctions();
          old_cls.MigrateImplicitStaticClosures(this, new_cls);
        }
        RecordChanges(changed_in_last_reload, old_cls, new_cls);
      }
    }

    class_map.Release();
  }

  if (FLAG_identity_reload) {
    Object& changed = Object::Handle();
    for (intptr_t i = 0; i < changed_in_last_reload.Length(); i++) {
      changed = changed_in_last_reload.At(i);
      ASSERT(changed.IsClass());  // Only fuzzy from lazy finalization.
    }
  }
  I->object_store()->set_changed_in_last_reload(changed_in_last_reload);

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
    TIMELINE_SCOPE(UpdateLibrariesArray);
    // Update the libraries array.
    Library& lib = Library::Handle();
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(I->object_store()->libraries());
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
      library_infos_[i].dirty = i >= num_saved_libs_;
    }
  }

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
    I->RehashConstants();
  }

#ifdef DEBUG
  I->ValidateConstants();
#endif

  if (FLAG_identity_reload) {
    if (saved_num_cids_ != I->class_table()->NumCids()) {
      TIR_Print("Identity reload failed! B#C=%" Pd " A#C=%" Pd "\n",
                saved_num_cids_, I->class_table()->NumCids());
    }
    const GrowableObjectArray& saved_libs =
        GrowableObjectArray::Handle(saved_libraries());
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(I->object_store()->libraries());
    if (saved_libs.Length() != libs.Length()) {
      TIR_Print("Identity reload failed! B#L=%" Pd " A#L=%" Pd "\n",
                saved_libs.Length(), libs.Length());
    }
  }

  // Run the initializers for new instance fields.
  RunNewFieldInitializers();
}

bool IsolateReloadContext::IsDirty(const Library& lib) {
  const intptr_t index = lib.index();
  if (index == static_cast<classid_t>(-1)) {
    // Treat deleted libraries as dirty.
    return true;
  }
  ASSERT((index >= 0) && (index < library_infos_.length()));
  return library_infos_[index].dirty;
}

void IsolateReloadContext::PostCommit() {
  TIMELINE_SCOPE(PostCommit);
  set_saved_root_library(Library::Handle());
  set_saved_libraries(GrowableObjectArray::Handle());
  InvalidateWorld();
  TIR_Print("---- DONE COMMIT\n");
}

void IsolateReloadContext::AddReasonForCancelling(ReasonForCancelling* reason) {
  reload_aborted_ = true;
  reasons_to_cancel_reload_.Add(reason);
}

void IsolateReloadContext::AddInstanceMorpher(InstanceMorpher* morpher) {
  instance_morphers_.Add(morpher);
  cid_mapper_.Insert(morpher);
}

void IsolateReloadContext::ReportReasonsForCancelling() {
  ASSERT(FLAG_reload_force_rollback || HasReasonsForCancelling());
  for (int i = 0; i < reasons_to_cancel_reload_.length(); i++) {
    reasons_to_cancel_reload_.At(i)->Report(this);
  }
}

// The ObjectLocator is used for collecting instances that
// needs to be morphed.
class ObjectLocator : public ObjectVisitor {
 public:
  explicit ObjectLocator(IsolateReloadContext* context)
      : context_(context), count_(0) {}

  void VisitObject(RawObject* obj) {
    InstanceMorpher* morpher =
        context_->cid_mapper_.LookupValue(obj->GetClassId());
    if (morpher != NULL) {
      morpher->AddObject(obj);
      count_++;
    }
  }

  // Return the number of located objects for morphing.
  intptr_t count() { return count_; }

 private:
  IsolateReloadContext* context_;
  intptr_t count_;
};

bool IsolateReloadContext::MorphInstances() {
  TIMELINE_SCOPE(MorphInstances);
  if (!HasInstanceMorphers()) {
    return false;
  }

  if (FLAG_trace_reload) {
    LogBlock blocker;
    TIR_Print("MorphInstance: \n");
    for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
      instance_morphers_.At(i)->Dump();
    }
  }

  // Find all objects that need to be morphed.
  ObjectLocator locator(this);
  {
    HeapIterationScope iteration(Thread::Current());
    iteration.IterateObjects(&locator);
  }

  // Return if no objects are located.
  intptr_t count = locator.count();
  if (count == 0) {
    return false;
  }

  TIR_Print("Found %" Pd " object%s subject to morphing.\n", count,
            (count > 1) ? "s" : "");

  Array& before = Array::Handle();
  Array& after = Array::Handle();
  {  // Prevent GC to take place due object format confusion.
    // Hint: More than one class share the same cid.
    NoHeapGrowthControlScope scope;
    for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
      instance_morphers_.At(i)->CreateMorphedCopies();
    }
    // Create the inputs for Become.
    intptr_t index = 0;
    before = Array::New(count);
    after = Array::New(count);
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

  // This is important: The saved class table (describing before objects)
  // must be zapped to prevent the forwarding in GetClassSizeForHeapWalkAt.
  // Instance will from now be described by the isolate's class table.
  free(saved_class_table_);
  saved_class_table_ = NULL;
  Become::ElementsForwardIdentity(before, after);
  return true;
}

void IsolateReloadContext::RunNewFieldInitializers() {
  // Run new field initializers on all instances.
  for (intptr_t i = 0; i < instance_morphers_.length(); i++) {
    instance_morphers_.At(i)->RunNewFieldInitializers();
  }
}

bool IsolateReloadContext::ValidateReload() {
  TIMELINE_SCOPE(ValidateReload);
  if (reload_aborted()) return false;

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
      if (new_lib.raw() != lib.raw()) {
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
      if (new_cls.raw() != cls.raw()) {
        cls.CheckReload(new_cls, this);
      }
    }
    map.Release();
  }

  return !FLAG_reload_force_rollback && !HasReasonsForCancelling();
}

RawClass* IsolateReloadContext::FindOriginalClass(const Class& cls) {
  return MappedClass(cls);
}

RawClass* IsolateReloadContext::GetClassForHeapWalkAt(intptr_t cid) {
  ClassAndSize* class_table =
      AtomicOperations::LoadRelaxed(&saved_class_table_);
  if (class_table != NULL) {
    ASSERT(cid > 0);
    ASSERT(cid < saved_num_cids_);
    return class_table[cid].get_raw_class();
  } else {
    return isolate_->class_table()->At(cid);
  }
}

intptr_t IsolateReloadContext::GetClassSizeForHeapWalkAt(intptr_t cid) {
  ClassAndSize* class_table =
      AtomicOperations::LoadRelaxed(&saved_class_table_);
  if (class_table != NULL) {
    ASSERT(cid > 0);
    ASSERT(cid < saved_num_cids_);
    return class_table[cid].size();
  } else {
    return isolate_->class_table()->SizeAt(cid);
  }
}

RawLibrary* IsolateReloadContext::saved_root_library() const {
  return saved_root_library_;
}

void IsolateReloadContext::set_saved_root_library(const Library& value) {
  saved_root_library_ = value.raw();
}

RawGrowableObjectArray* IsolateReloadContext::saved_libraries() const {
  return saved_libraries_;
}

void IsolateReloadContext::set_saved_libraries(
    const GrowableObjectArray& value) {
  saved_libraries_ = value.raw();
}

void IsolateReloadContext::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointers(from(), to());
  if (saved_class_table_ != NULL) {
    visitor->VisitPointers(
        reinterpret_cast<RawObject**>(&saved_class_table_[0]), saved_num_cids_);
  }
}

ObjectStore* IsolateReloadContext::object_store() {
  return isolate_->object_store();
}

void IsolateReloadContext::ResetUnoptimizedICsOnStack() {
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  Code& code = Code::Handle(zone);
  Function& function = Function::Handle(zone);
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  while (frame != NULL) {
    code = frame->LookupDartCode();
    if (code.is_optimized()) {
      // If this code is optimized, we need to reset the ICs in the
      // corresponding unoptimized code, which will be executed when the stack
      // unwinds to the optimized code.
      function = code.function();
      code = function.unoptimized_code();
      ASSERT(!code.IsNull());
      code.ResetICDatas(zone);
    } else {
      code.ResetICDatas(zone);
    }
    frame = iterator.NextFrame();
  }
}

void IsolateReloadContext::ResetMegamorphicCaches() {
  object_store()->set_megamorphic_cache_table(GrowableObjectArray::Handle());
  // Since any current optimized code will not make any more calls, it may be
  // better to clear the table instead of clearing each of the caches, allow
  // the current megamorphic caches get GC'd and any new optimized code allocate
  // new ones.
}

class MarkFunctionsForRecompilation : public ObjectVisitor {
 public:
  MarkFunctionsForRecompilation(Isolate* isolate,
                                IsolateReloadContext* reload_context,
                                Zone* zone)
      : ObjectVisitor(),
        handle_(Object::Handle(zone)),
        owning_class_(Class::Handle(zone)),
        owning_lib_(Library::Handle(zone)),
        code_(Code::Handle(zone)),
        reload_context_(reload_context),
        zone_(zone) {}

  virtual void VisitObject(RawObject* obj) {
    if (obj->IsPseudoObject()) {
      // Cannot even be wrapped in handles.
      return;
    }
    handle_ = obj;
    if (handle_.IsFunction()) {
      const Function& func = Function::Cast(handle_);
      if (func.IsSignatureFunction()) {
        return;
      }

      // Switch to unoptimized code or the lazy compilation stub.
      func.SwitchToLazyCompiledUnoptimizedCode();

      // Grab the current code.
      code_ = func.CurrentCode();
      ASSERT(!code_.IsNull());
      const bool clear_code = IsFromDirtyLibrary(func);
      const bool stub_code = code_.IsStubCode();

      // Zero edge counters.
      func.ZeroEdgeCounters();

      if (!stub_code) {
        if (clear_code) {
          VTIR_Print("Marking %s for recompilation, clearning code\n",
                     func.ToCString());
          ClearAllCode(func);
        } else {
          PreserveUnoptimizedCode();
        }
      }

      // Clear counters.
      func.set_usage_counter(0);
      func.set_deoptimization_counter(0);
      func.set_optimized_instruction_count(0);
      func.set_optimized_call_site_count(0);
    }
  }

 private:
  void ClearAllCode(const Function& func) {
    // Null out the ICData array and code.
    func.ClearICDataArray();
    func.ClearCode();
    func.SetWasCompiled(false);
  }

  void PreserveUnoptimizedCode() {
    ASSERT(!code_.IsNull());
    // We are preserving the unoptimized code, fill all ICData arrays with
    // the sentinel values so that we have no stale type feedback.
    code_.ResetICDatas(zone_);
  }

  bool IsFromDirtyLibrary(const Function& func) {
    owning_class_ = func.Owner();
    owning_lib_ = owning_class_.library();
    return reload_context_->IsDirty(owning_lib_);
  }

  Object& handle_;
  Class& owning_class_;
  Library& owning_lib_;
  Code& code_;
  IsolateReloadContext* reload_context_;
  Zone* zone_;
};

void IsolateReloadContext::MarkAllFunctionsForRecompilation() {
  TIMELINE_SCOPE(MarkAllFunctionsForRecompilation);
  TIR_Print("---- MARKING ALL FUNCTIONS FOR RECOMPILATION\n");
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();
  HeapIterationScope iteration(thread);
  MarkFunctionsForRecompilation visitor(isolate_, this, zone);
  iteration.IterateObjects(&visitor);
}

void IsolateReloadContext::InvalidateWorld() {
  TIR_Print("---- INVALIDATING WORLD\n");
  ResetMegamorphicCaches();
  DeoptimizeFunctionsOnStack();
  ResetUnoptimizedICsOnStack();
  MarkAllFunctionsForRecompilation();
}

RawClass* IsolateReloadContext::MappedClass(const Class& replacement_or_new) {
  UnorderedHashMap<ClassMapTraits> map(class_map_storage_);
  Class& cls = Class::Handle();
  cls ^= map.GetOrNull(replacement_or_new);
  // No need to update storage address because no mutation occurred.
  map.Release();
  return cls.raw();
}

RawLibrary* IsolateReloadContext::MappedLibrary(
    const Library& replacement_or_new) {
  return Library::null();
}

RawClass* IsolateReloadContext::OldClassOrNull(
    const Class& replacement_or_new) {
  UnorderedHashSet<ClassMapTraits> old_classes_set(old_classes_set_storage_);
  Class& cls = Class::Handle();
  cls ^= old_classes_set.GetOrNull(replacement_or_new);
  old_classes_set_storage_ = old_classes_set.Release().raw();
  return cls.raw();
}

RawString* IsolateReloadContext::FindLibraryPrivateKey(
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

RawLibrary* IsolateReloadContext::OldLibraryOrNull(
    const Library& replacement_or_new) {
  UnorderedHashSet<LibraryMapTraits> old_libraries_set(
      old_libraries_set_storage_);
  Library& lib = Library::Handle();
  lib ^= old_libraries_set.GetOrNull(replacement_or_new);
  old_libraries_set.Release();
  if (lib.IsNull() && (root_url_prefix_ != String::null()) &&
      (old_root_url_prefix_ != String::null())) {
    return OldLibraryOrNullBaseMoved(replacement_or_new);
  }
  return lib.raw();
}

// Attempt to find the pair to |replacement_or_new| with the knowledge that
// the base url prefix has moved.
RawLibrary* IsolateReloadContext::OldLibraryOrNullBaseMoved(
    const Library& replacement_or_new) {
  const String& url_prefix = String::Handle(root_url_prefix_);
  const String& old_url_prefix = String::Handle(old_root_url_prefix_);
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
  GrowableObjectArray& saved_libs =
      GrowableObjectArray::Handle(saved_libraries());
  ASSERT(!saved_libs.IsNull());
  for (intptr_t i = 0; i < saved_libs.Length(); i++) {
    old = Library::RawCast(saved_libs.At(i));
    old_url = old.url();
    if (!old_url.StartsWith(old_url_prefix)) {
      continue;
    }
    old_suffix ^= String::SubString(old_url, old_prefix_length);
    if (old_suffix.IsNull()) {
      continue;
    }
    if (old_suffix.Equals(suffix)) {
      TIR_Print("`%s` is moving to `%s`\n", old_url.ToCString(),
                new_url.ToCString());
      return old.raw();
    }
  }
  return Library::null();
}

void IsolateReloadContext::BuildLibraryMapping() {
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());

  Library& replacement_or_new = Library::Handle();
  Library& old = Library::Handle();
  for (intptr_t i = num_saved_libs_; i < libs.Length(); i++) {
    replacement_or_new = Library::RawCast(libs.At(i));
    old ^= OldLibraryOrNull(replacement_or_new);
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

void IsolateReloadContext::AddClassMapping(const Class& replacement_or_new,
                                           const Class& original) {
  UnorderedHashMap<ClassMapTraits> map(class_map_storage_);
  bool update = map.UpdateOrInsert(replacement_or_new, original);
  ASSERT(!update);
  // The storage given to the map may have been reallocated, remember the new
  // address.
  class_map_storage_ = map.Release().raw();
}

void IsolateReloadContext::AddLibraryMapping(const Library& replacement_or_new,
                                             const Library& original) {
  UnorderedHashMap<LibraryMapTraits> map(library_map_storage_);
  bool update = map.UpdateOrInsert(replacement_or_new, original);
  ASSERT(!update);
  // The storage given to the map may have been reallocated, remember the new
  // address.
  library_map_storage_ = map.Release().raw();
}

void IsolateReloadContext::AddStaticFieldMapping(const Field& old_field,
                                                 const Field& new_field) {
  ASSERT(old_field.is_static());
  ASSERT(new_field.is_static());

  AddBecomeMapping(old_field, new_field);
}

void IsolateReloadContext::AddBecomeMapping(const Object& old,
                                            const Object& neu) {
  ASSERT(become_map_storage_ != Array::null());
  UnorderedHashMap<BecomeMapTraits> become_map(become_map_storage_);
  bool update = become_map.UpdateOrInsert(old, neu);
  ASSERT(!update);
  become_map_storage_ = become_map.Release().raw();
}

void IsolateReloadContext::AddEnumBecomeMapping(const Object& old,
                                                const Object& neu) {
  const GrowableObjectArray& become_enum_mappings =
      GrowableObjectArray::Handle(become_enum_mappings_);
  become_enum_mappings.Add(old);
  become_enum_mappings.Add(neu);
  ASSERT((become_enum_mappings.Length() % 2) == 0);
}

void IsolateReloadContext::RebuildDirectSubclasses() {
  ClassTable* class_table = I->class_table();
  intptr_t num_cids = class_table->NumCids();

  // Clear the direct subclasses for all classes.
  Class& cls = Class::Handle();
  GrowableObjectArray& subclasses = GrowableObjectArray::Handle();
  for (intptr_t i = 1; i < num_cids; i++) {
    if (class_table->HasValidClassAt(i)) {
      cls = class_table->At(i);
      subclasses = cls.direct_subclasses();
      if (!subclasses.IsNull()) {
        subclasses.SetLength(0);
      }
    }
  }

  // Recompute the direct subclasses.
  AbstractType& super_type = AbstractType::Handle();
  Class& super_cls = Class::Handle();
  for (intptr_t i = 1; i < num_cids; i++) {
    if (class_table->HasValidClassAt(i)) {
      cls = class_table->At(i);
      super_type = cls.super_type();
      if (!super_type.IsNull() && !super_type.IsObjectType()) {
        super_cls = cls.SuperClass();
        ASSERT(!super_cls.IsNull());
        super_cls.AddDirectSubclass(cls);
      }
    }
  }
}

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
