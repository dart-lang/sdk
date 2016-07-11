// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate_reload.h"

#include "vm/become.h"
#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/hash_table.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/safepoint.h"
#include "vm/service_event.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, trace_reload, false, "Trace isolate reloading");
DEFINE_FLAG(bool, identity_reload, false, "Enable checks for identity reload.");
DEFINE_FLAG(int, reload_every, 0, "Reload every N stack overflow checks.");
DEFINE_FLAG(bool, reload_every_optimized, true, "Only from optimized code.");
DEFINE_FLAG(bool, reload_every_back_off, false,
            "Double the --reload-every value after each reload.");
DEFINE_FLAG(bool, check_reloaded, false,
            "Assert that an isolate has reloaded at least once.")
#ifndef PRODUCT

#define I (isolate())
#define Z (thread->zone())

#define TIMELINE_SCOPE(name)                                                   \
    TimelineDurationScope tds##name(Thread::Current(),                         \
                                   Timeline::GetIsolateStream(),               \
                                   #name)


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

  static uword Hash(const Object& obj) {
    return String::Cast(obj).Hash();
  }
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
    return IsolateReloadContext::IsSameLibrary(
        Library::Cast(a), Library::Cast(b));
  }

  static uword Hash(const Object& obj) {
    return Library::Cast(obj).UrlHash();
  }
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
  const String& a_name = String::Handle(Class::Cast(a).Name());
  const String& b_name = String::Handle(Class::Cast(b).Name());

  if (!a_name.Equals(b_name)) {
    return false;
  }

  const Library& a_lib = Library::Handle(Class::Cast(a).library());
  const Library& b_lib = Library::Handle(Class::Cast(b).library());
  return IsSameLibrary(a_lib, b_lib);
}


bool IsolateReloadContext::IsSameLibrary(
    const Library& a_lib, const Library& b_lib) {
  const String& a_lib_url =
      String::Handle(a_lib.IsNull() ? String::null() : a_lib.url());
  const String& b_lib_url =
      String::Handle(b_lib.IsNull() ? String::null() : b_lib.url());
  return a_lib_url.Equals(b_lib_url);
}


IsolateReloadContext::IsolateReloadContext(Isolate* isolate, bool test_mode)
    : start_time_micros_(OS::GetCurrentMonotonicMicros()),
      isolate_(isolate),
      test_mode_(test_mode),
      has_error_(false),
      saved_num_cids_(-1),
      saved_class_table_(NULL),
      num_saved_libs_(-1),
      script_uri_(String::null()),
      error_(Error::null()),
      old_classes_set_storage_(Array::null()),
      class_map_storage_(Array::null()),
      old_libraries_set_storage_(Array::null()),
      library_map_storage_(Array::null()),
      become_map_storage_(Array::null()),
      saved_root_library_(Library::null()),
      saved_libraries_(GrowableObjectArray::null()) {
  // Preallocate storage for maps.
  old_classes_set_storage_ =
      HashTables::New<UnorderedHashSet<ClassMapTraits> >(4);
  class_map_storage_ =
      HashTables::New<UnorderedHashMap<ClassMapTraits> >(4);
  old_libraries_set_storage_ =
      HashTables::New<UnorderedHashSet<LibraryMapTraits> >(4);
  library_map_storage_ =
      HashTables::New<UnorderedHashMap<LibraryMapTraits> >(4);
  become_map_storage_ =
      HashTables::New<UnorderedHashMap<BecomeMapTraits> >(4);
}


IsolateReloadContext::~IsolateReloadContext() {
}


void IsolateReloadContext::ReportError(const Error& error) {
  has_error_ = true;
  error_ = error.raw();
  if (FLAG_trace_reload) {
    THR_Print("ISO-RELOAD: Error: %s\n", error.ToErrorCString());
  }
  ServiceEvent service_event(I, ServiceEvent::kIsolateReload);
  service_event.set_reload_error(&error);
  Service::HandleEvent(&service_event);
}


void IsolateReloadContext::ReportError(const String& error_msg) {
  ReportError(LanguageError::Handle(LanguageError::New(error_msg)));
}


void IsolateReloadContext::ReportSuccess() {
  ServiceEvent service_event(I, ServiceEvent::kIsolateReload);
  Service::HandleEvent(&service_event);
}


void IsolateReloadContext::StartReload() {
  TIMELINE_SCOPE(Reload);
  Thread* thread = Thread::Current();

  // Grab root library before calling CheckpointBeforeReload.
  const Library& root_lib = Library::Handle(object_store()->root_library());
  ASSERT(!root_lib.IsNull());
  const String& root_lib_url = String::Handle(root_lib.url());

  // Disable the background compiler while we are performing the reload.
  BackgroundCompiler::Disable();

  if (FLAG_write_protect_code) {
    // Disable code page write protection while we are reloading.
    I->heap()->WriteProtectCode(false);
  }

  // Ensure all functions on the stack have unoptimized code.
  EnsuredUnoptimizedCodeForStack();
  // Deoptimize all code that had optimizing decisions that are dependent on
  // assumptions from field guards or CHA or deferred library prefixes.
  // TODO(johnmccutchan): Deoptimizing dependent code here (before the reload)
  // is paranoid. This likely can be moved to the commit phase.
  DeoptimizeDependentCode();
  Checkpoint();

  Object& result = Object::Handle(thread->zone());
  {
    TransitionVMToNative transition(thread);
    Api::Scope api_scope(thread);

    Dart_Handle retval =
        (I->library_tag_handler())(Dart_kScriptTag,
                                   Api::NewHandle(thread, Library::null()),
                                   Api::NewHandle(thread, root_lib_url.raw()));
    result = Api::UnwrapHandle(retval);
  }
  if (result.IsError()) {
    ReportError(Error::Cast(result));
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
  new_cls.set_id(old_cls.id());
  isolate()->class_table()->SetAt(old_cls.id(), new_cls.raw());
  if (!old_cls.is_enum_class()) {
    new_cls.CopyCanonicalConstants(old_cls);
  }
  new_cls.CopyCanonicalType(old_cls);
  AddBecomeMapping(old_cls, new_cls);
  AddClassMapping(new_cls, old_cls);
}


void IsolateReloadContext::FinishReload() {
  BuildLibraryMapping();
  TIR_Print("---- DONE FINALIZING\n");
  if (ValidateReload()) {
    Commit();
    PostCommit();
  } else {
    Rollback();
  }
  // ValidateReload mutates the direct subclass information and does
  // not remove dead subclasses.  Rebuild the direct subclass
  // information from scratch.
  RebuildDirectSubclasses();

  if (FLAG_write_protect_code) {
    // Disable code page write protection while we are reloading.
    I->heap()->WriteProtectCode(true);
  }

  BackgroundCompiler::Enable();
}


void IsolateReloadContext::AbortReload(const Error& error) {
  ReportError(error);
  Rollback();
}


void IsolateReloadContext::EnsuredUnoptimizedCodeForStack() {
  TIMELINE_SCOPE(EnsuredUnoptimizedCodeForStack);
  StackFrameIterator it(StackFrameIterator::kDontValidateFrames);

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
  RawClass** local_saved_class_table =
      reinterpret_cast<RawClass**>(malloc(sizeof(RawClass*) * saved_num_cids_));

  Class& cls = Class::Handle();
  UnorderedHashSet<ClassMapTraits> old_classes_set(old_classes_set_storage_);
  for (intptr_t i = 0; i < saved_num_cids_; i++) {
    if (class_table->IsValidIndex(i) &&
        class_table->HasValidClassAt(i)) {
      // Copy the class into the saved class table and add it to the set.
      local_saved_class_table[i] = class_table->At(i);
      if (i != kFreeListElement && i != kForwardingCorpse) {
        cls = class_table->At(i);
        bool already_present = old_classes_set.Insert(cls);
        ASSERT(!already_present);
      }
    } else {
      // No class at this index, mark it as NULL.
      local_saved_class_table[i] = NULL;
    }
  }
  old_classes_set_storage_ = old_classes_set.Release().raw();
  // Assigning the field must be done after saving the class table.
  saved_class_table_ = local_saved_class_table;
  TIR_Print("---- System had %" Pd " classes\n", saved_num_cids_);
}


bool IsolateReloadContext::IsCleanLibrary(const Library& lib) {
  return lib.is_dart_scheme();
}


void IsolateReloadContext::CheckpointLibraries() {
  TIMELINE_SCOPE(CheckpointLibraries);

  // Save the root library in case we abort the reload.
  const Library& root_lib =
      Library::Handle(object_store()->root_library());
  set_saved_root_library(root_lib);

  // Save the old libraries array in case we abort the reload.
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());
  set_saved_libraries(libs);

  // Make a filtered copy of the old libraries array. Keep "clean" libraries
  // that we will use instead of reloading.
  const GrowableObjectArray& new_libs = GrowableObjectArray::Handle(
      GrowableObjectArray::New(Heap::kOld));
  Library& lib = Library::Handle();
  UnorderedHashSet<LibraryMapTraits>
      old_libraries_set(old_libraries_set_storage_);
  num_saved_libs_ = 0;
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    if (IsCleanLibrary(lib)) {
      // We are preserving this library across the reload, assign its new index
      lib.set_index(new_libs.Length());
      new_libs.Add(lib, Heap::kOld);
      num_saved_libs_++;
    } else {
      // We are going to reload this library. Clear the index.
      lib.set_index(-1);
    }
    // Add old library to old libraries set.
    bool already_present = old_libraries_set.Insert(lib);
    ASSERT(!already_present);
  }
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
      class_table->SetAt(i, saved_class_table_[i]);
    }
  }
  free(saved_class_table_);
  saved_class_table_ = NULL;
  saved_num_cids_ = 0;
}


void IsolateReloadContext::RollbackLibraries() {
  TIR_Print("---- ROLLING BACK LIBRARY CHANGES\n");
  Thread* thread = Thread::Current();
  Library& lib = Library::Handle();
  GrowableObjectArray& saved_libs = GrowableObjectArray::Handle(
      Z, saved_libraries());
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
        OS::PrintErr("Classes '%s' and '%s' are distinct classes but both map "
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


void IsolateReloadContext::Commit() {
  TIMELINE_SCOPE(Commit);
  TIR_Print("---- COMMITTING REVERSE MAP\n");

#ifdef DEBUG
  VerifyMaps();
#endif

  {
    TIMELINE_SCOPE(CopyStaticFieldsAndPatchFieldsAndFunctions);
    // Copy static field values from the old classes to the new classes.
    // Patch fields and functions in the old classes so that they retain
    // the old script.
    Class& cls = Class::Handle();
    Class& new_cls = Class::Handle();

    UnorderedHashMap<ClassMapTraits> class_map(class_map_storage_);

    {
      UnorderedHashMap<ClassMapTraits>::Iterator it(&class_map);
      while (it.MoveNext()) {
        const intptr_t entry = it.Current();
        new_cls = Class::RawCast(class_map.GetKey(entry));
        cls = Class::RawCast(class_map.GetPayload(entry, 0));
        if (new_cls.raw() != cls.raw()) {
          ASSERT(new_cls.is_enum_class() == cls.is_enum_class());
          if (new_cls.is_enum_class() && new_cls.is_finalized()) {
            new_cls.ReplaceEnum(cls);
          }
          new_cls.CopyStaticFieldValues(cls);
          cls.PatchFieldsAndFunctions();
        }
      }
    }

    class_map.Release();
  }

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
      }
    }

    // Release the library map.
    lib_map.Release();
  }

  {
    TIMELINE_SCOPE(UpdateLibrariesArray);
    // Update the libraries array.
    Library& lib = Library::Handle();
    const GrowableObjectArray& libs = GrowableObjectArray::Handle(
        I->object_store()->libraries());
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib = Library::RawCast(libs.At(i));
      TIR_Print("Lib '%s' at index %" Pd "\n", lib.ToCString(), i);
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
    UnorderedHashMap<BecomeMapTraits> become_map(become_map_storage_);
    intptr_t replacement_count = become_map.NumOccupied();
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
    ASSERT(replacement_index == replacement_count);
    become_map.Release();

    Become::ElementsForwardIdentity(before, after);
  }

  if (FLAG_identity_reload) {
    if (saved_num_cids_ != I->class_table()->NumCids()) {
      TIR_Print("Identity reload failed! B#C=%" Pd " A#C=%" Pd "\n",
                saved_num_cids_,
                I->class_table()->NumCids());
    }
    const GrowableObjectArray& saved_libs =
        GrowableObjectArray::Handle(saved_libraries());
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(I->object_store()->libraries());
    if (saved_libs.Length() != libs.Length()) {
     TIR_Print("Identity reload failed! B#L=%" Pd " A#L=%" Pd "\n",
               saved_libs.Length(),
               libs.Length());
    }
  }
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
}


bool IsolateReloadContext::ValidateReload() {
  TIMELINE_SCOPE(ValidateReload);
  if (has_error_) {
    return false;
  }

  // Already built.
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
      if (!cls.CanReload(new_cls)) {
        map.Release();
        return false;
      }
    }
  }
  map.Release();
  return true;
}


RawClass* IsolateReloadContext::FindOriginalClass(const Class& cls) {
  return MappedClass(cls);
}


RawClass* IsolateReloadContext::GetClassForHeapWalkAt(intptr_t cid) {
  if (saved_class_table_ != NULL) {
    ASSERT(cid > 0);
    ASSERT(cid < saved_num_cids_);
    return saved_class_table_[cid];
  } else {
    return isolate_->class_table()->At(cid);
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
  Code& code = Code::Handle();
  Function& function = Function::Handle();
  DartFrameIterator iterator;
  StackFrame* frame = iterator.NextFrame();
  while (frame != NULL) {
    code = frame->LookupDartCode();
    if (code.is_optimized()) {
      // If this code is optimized, we need to reset the ICs in the
      // corresponding unoptimized code, which will be executed when the stack
      // unwinds to the the optimized code.
      function = code.function();
      code = function.unoptimized_code();
      ASSERT(!code.IsNull());
      code.ResetICDatas();
    } else {
      code.ResetICDatas();
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
                                IsolateReloadContext* reload_context)
    : ObjectVisitor(),
      handle_(Object::Handle()),
      owning_class_(Class::Handle()),
      owning_lib_(Library::Handle()),
      code_(Code::Handle()),
      reload_context_(reload_context) {
  }

  virtual void VisitObject(RawObject* obj) {
    if (obj->IsPseudoObject()) {
      // Cannot even be wrapped in handles.
      return;
    }
    handle_ = obj;
    if (handle_.IsFunction()) {
      const Function& func = Function::Cast(handle_);

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
    func.set_was_compiled(false);
  }

  void PreserveUnoptimizedCode() {
    ASSERT(!code_.IsNull());
    // We are preserving the unoptimized code, fill all ICData arrays with
    // the sentinel values so that we have no stale type feedback.
    code_.ResetICDatas();
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
};


void IsolateReloadContext::MarkAllFunctionsForRecompilation() {
  TIMELINE_SCOPE(MarkAllFunctionsForRecompilation);
  NoSafepointScope no_safepoint;
  HeapIterationScope heap_iteration_scope;
  MarkFunctionsForRecompilation visitor(isolate_, this);
  isolate_->heap()->VisitObjects(&visitor);
}


void IsolateReloadContext::InvalidateWorld() {
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
  return old.private_key();
}


RawLibrary* IsolateReloadContext::OldLibraryOrNull(
    const Library& replacement_or_new) {
  UnorderedHashSet<LibraryMapTraits>
      old_libraries_set(old_libraries_set_storage_);
  Library& lib = Library::Handle();
  lib ^= old_libraries_set.GetOrNull(replacement_or_new);
  old_libraries_set.Release();
  return lib.raw();
}


void IsolateReloadContext::BuildLibraryMapping() {
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store()->libraries());

  Library& replacement_or_new = Library::Handle();
  Library& old = Library::Handle();
  for (intptr_t i = 0; i < libs.Length(); i++) {
    replacement_or_new = Library::RawCast(libs.At(i));
    if (IsCleanLibrary(replacement_or_new)) {
      continue;
    }
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


void IsolateReloadContext::AddStaticFieldMapping(
    const Field& old_field, const Field& new_field) {
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

#endif  // !PRODUCT

}  // namespace dart
