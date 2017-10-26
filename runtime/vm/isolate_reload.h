// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ISOLATE_RELOAD_H_
#define RUNTIME_VM_ISOLATE_RELOAD_H_

#include "include/dart_tools_api.h"

#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/log.h"
#include "vm/object.h"

DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, trace_reload_verbose);

// 'Trace Isolate Reload' TIR_Print
#if defined(_MSC_VER)
#define TIR_Print(format, ...)                                                 \
  if (FLAG_trace_reload) Log::Current()->Print(format, __VA_ARGS__)
#else
#define TIR_Print(format, ...)                                                 \
  if (FLAG_trace_reload) Log::Current()->Print(format, ##__VA_ARGS__)
#endif

// 'Verbose Trace Isolate Reload' VTIR_Print
#if defined(_MSC_VER)
#define VTIR_Print(format, ...)                                                \
  if (FLAG_trace_reload_verbose) Log::Current()->Print(format, __VA_ARGS__)
#else
#define VTIR_Print(format, ...)                                                \
  if (FLAG_trace_reload_verbose) Log::Current()->Print(format, ##__VA_ARGS__)
#endif

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

class BitVector;
class GrowableObjectArray;
class Isolate;
class Library;
class ObjectPointerVisitor;
class ObjectStore;
class RawError;
class RawGrowableObjectArray;
class RawLibrary;
class RawObject;
class RawString;
class Script;
class UpdateClassesVisitor;

class InstanceMorpher : public ZoneAllocated {
 public:
  InstanceMorpher(Zone* zone, const Class& from, const Class& to);
  virtual ~InstanceMorpher() {}

  // Called on each instance that needs to be morphed.
  RawInstance* Morph(const Instance& instance) const;

  void RunNewFieldInitializers() const;

  // Adds an object to be morphed.
  void AddObject(RawObject* object) const;

  // Create the morphed objects based on the before() list.
  void CreateMorphedCopies() const;

  // Dump the state of the morpher.
  void Dump() const;

  // Append the morper info to JSON array.
  void AppendTo(JSONArray* array);

  // Returns the list of objects that need to be morphed.
  ZoneGrowableArray<const Instance*>* before() const { return before_; }
  // Returns the list of morphed objects (matches order in before()).
  ZoneGrowableArray<const Instance*>* after() const { return after_; }
  // Returns the list of new fields.
  ZoneGrowableArray<const Field*>* new_fields() const { return new_fields_; }

  // Returns the cid associated with the from_ and to_ class.
  intptr_t cid() const { return cid_; }

 private:
  const Class& from_;
  const Class& to_;
  ZoneGrowableArray<intptr_t> mapping_;
  ZoneGrowableArray<const Instance*>* before_;
  ZoneGrowableArray<const Instance*>* after_;
  ZoneGrowableArray<const Field*>* new_fields_;
  intptr_t cid_;

  void ComputeMapping();
  void DumpFormatFor(const Class& cls) const;
};

class ReasonForCancelling : public ZoneAllocated {
 public:
  explicit ReasonForCancelling(Zone* zone) {}
  virtual ~ReasonForCancelling() {}

  // Reports a reason for cancelling reload.
  void Report(IsolateReloadContext* context);

  // Conversion to a VM error object.
  // Default implementation calls ToString.
  virtual RawError* ToError();

  // Conversion to a string object.
  // Default implementation calls ToError.
  virtual RawString* ToString();

  // Append the reason to JSON array.
  virtual void AppendTo(JSONArray* array);

  // Concrete subclasses must override either ToError or ToString.
};

// Abstract class for also capturing the from_ and to_ class.
class ClassReasonForCancelling : public ReasonForCancelling {
 public:
  ClassReasonForCancelling(Zone* zone, const Class& from, const Class& to);
  void AppendTo(JSONArray* array);

 protected:
  const Class& from_;
  const Class& to_;
};

class IsolateReloadContext {
 public:
  explicit IsolateReloadContext(Isolate* isolate, JSONStream* js);
  ~IsolateReloadContext();

  void Reload(bool force_reload,
              const char* root_script_url = NULL,
              const char* packages_url = NULL);

  // All zone allocated objects must be allocated from this zone.
  Zone* zone() const { return zone_; }

  bool reload_skipped() const { return reload_skipped_; }
  bool reload_aborted() const { return reload_aborted_; }
  RawError* error() const;
  int64_t reload_timestamp() const { return reload_timestamp_; }

  static Dart_FileModifiedCallback file_modified_callback() {
    return file_modified_callback_;
  }
  static void SetFileModifiedCallback(Dart_FileModifiedCallback callback) {
    file_modified_callback_ = callback;
  }

  static bool IsSameField(const Field& a, const Field& b);
  static bool IsSameLibrary(const Library& a_lib, const Library& b_lib);
  static bool IsSameClass(const Class& a, const Class& b);

 private:
  RawLibrary* saved_root_library() const;

  RawGrowableObjectArray* saved_libraries() const;

  RawClass* FindOriginalClass(const Class& cls);

  bool IsDirty(const Library& lib);

  // Prefers old classes when we are in the middle of a reload.
  RawClass* GetClassForHeapWalkAt(intptr_t cid);

  void RegisterClass(const Class& new_cls);

  // Finds the library private key for |replacement_or_new| or return null
  // if |replacement_or_new| is new.
  RawString* FindLibraryPrivateKey(const Library& replacement_or_new);

  int64_t start_time_micros() const { return start_time_micros_; }

  // Tells whether there are reasons for cancelling the reload.
  bool HasReasonsForCancelling() const {
    return !reasons_to_cancel_reload_.is_empty();
  }

  // Record problem for this reload.
  void AddReasonForCancelling(ReasonForCancelling* reason);

  // Reports all reasons for cancelling reload.
  void ReportReasonsForCancelling();

  // Reports the details of a reload operation.
  void ReportOnJSON(JSONStream* stream);

  // Store morphing operation.
  void AddInstanceMorpher(InstanceMorpher* morpher);

  // Tells whether instance in the heap must be morphed.
  bool HasInstanceMorphers() const { return !instance_morphers_.is_empty(); }

  // NOTE: FinalizeLoading will be called *before* Reload() returns. This
  // function will not be called if the embedder does not call
  // Dart_FinalizeLoading.
  void FinalizeLoading();

  // NOTE: FinalizeFailedLoad will be called *before* Reload returns. This
  // function will not be called if the embedder calls Dart_FinalizeLoading.
  void FinalizeFailedLoad(const Error& error);

  // Called by both FinalizeLoading and FinalizeFailedLoad.
  void CommonFinalizeTail();

  // Report back through the observatory channels.
  void ReportError(const Error& error);
  void ReportSuccess();

  void set_saved_root_library(const Library& value);

  void set_saved_libraries(const GrowableObjectArray& value);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  Isolate* isolate() { return isolate_; }
  ObjectStore* object_store();

  void EnsuredUnoptimizedCodeForStack();
  void DeoptimizeDependentCode();

  void Checkpoint();

  void CheckpointClasses();

  bool ScriptModifiedSince(const Script& script, int64_t since);
  BitVector* FindModifiedLibraries(bool force_reload);

  void CheckpointLibraries();

  // Transforms the heap based on instance_morphers_.
  void MorphInstances();

  void RunNewFieldInitializers();

  bool ValidateReload();

  void Rollback();

  void RollbackClasses();
  void RollbackLibraries();

#ifdef DEBUG
  void VerifyMaps();
#endif

  void Commit();

  void PostCommit();

  void ClearReplacedObjectBits();

  // atomic_install:
  void MarkAllFunctionsForRecompilation();
  void ResetUnoptimizedICsOnStack();
  void ResetMegamorphicCaches();
  void InvalidateWorld();

  // The zone used for all reload related allocations.
  Zone* zone_;

  int64_t start_time_micros_;
  int64_t reload_timestamp_;
  Isolate* isolate_;
  bool reload_skipped_;
  bool reload_aborted_;
  bool reload_finalized_;
  JSONStream* js_;

  intptr_t saved_num_cids_;
  RawClass** saved_class_table_;
  intptr_t num_saved_libs_;

  // Collect the necessary instance transformation for schema changes.
  ZoneGrowableArray<InstanceMorpher*> instance_morphers_;

  // Collects the reasons for cancelling the reload.
  ZoneGrowableArray<ReasonForCancelling*> reasons_to_cancel_reload_;

  // Required trait for the cid_mapper_;
  struct MorpherTrait {
    typedef InstanceMorpher* Value;
    typedef intptr_t Key;
    typedef InstanceMorpher* Pair;

    static Key KeyOf(Pair kv) { return kv->cid(); }
    static Value ValueOf(Pair kv) { return kv; }
    static intptr_t Hashcode(Key key) { return key; }
    static bool IsKeyEqual(Pair kv, Key key) { return kv->cid() == key; }
  };

  // Hash map from cid to InstanceMorpher.
  DirectChainedHashMap<MorpherTrait> cid_mapper_;

  struct LibraryInfo {
    bool dirty;
  };
  MallocGrowableArray<LibraryInfo> library_infos_;

  // A bit vector indicating which of the original libraries were modified.
  BitVector* modified_libs_;

  RawClass* OldClassOrNull(const Class& replacement_or_new);

  RawLibrary* OldLibraryOrNull(const Library& replacement_or_new);

  RawLibrary* OldLibraryOrNullBaseMoved(const Library& replacement_or_new);

  void BuildLibraryMapping();

  void AddClassMapping(const Class& replacement_or_new, const Class& original);

  void AddLibraryMapping(const Library& replacement_or_new,
                         const Library& original);

  void AddStaticFieldMapping(const Field& old_field, const Field& new_field);

  void AddBecomeMapping(const Object& old, const Object& neu);
  void AddEnumBecomeMapping(const Object& old, const Object& neu);

  void RebuildDirectSubclasses();

  RawClass* MappedClass(const Class& replacement_or_new);
  RawLibrary* MappedLibrary(const Library& replacement_or_new);

  RawObject** from() { return reinterpret_cast<RawObject**>(&script_url_); }
  RawString* script_url_;
  RawError* error_;
  RawArray* old_classes_set_storage_;
  RawArray* class_map_storage_;
  RawArray* old_libraries_set_storage_;
  RawArray* library_map_storage_;
  RawArray* become_map_storage_;
  RawGrowableObjectArray* become_enum_mappings_;
  RawLibrary* saved_root_library_;
  RawGrowableObjectArray* saved_libraries_;
  RawString* root_url_prefix_;
  RawString* old_root_url_prefix_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&old_root_url_prefix_);
  }

  friend class Isolate;
  friend class Class;  // AddStaticFieldMapping, AddEnumBecomeMapping.
  friend class Library;
  friend class ObjectLocator;
  friend class MarkFunctionsForRecompilation;  // IsDirty.
  friend class ReasonForCancelling;

  static Dart_FileModifiedCallback file_modified_callback_;
};

}  // namespace dart

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#endif  // RUNTIME_VM_ISOLATE_RELOAD_H_
