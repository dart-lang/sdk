// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ISOLATE_RELOAD_H_
#define RUNTIME_VM_ISOLATE_RELOAD_H_

#include <functional>
#include <memory>

#include "include/dart_tools_api.h"

#include "vm/compiler/jit/compiler.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/heap/become.h"
#include "vm/heap/safepoint.h"
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
class ObjectLocator;
class ObjectPointerVisitor;
class ObjectStore;
class Script;
class UpdateClassesVisitor;

struct FieldMapping {
  intptr_t offset;
  intptr_t box_cid;  // kIllegalCid if field is boxed
};

using FieldMappingArray = ZoneGrowableArray<FieldMapping>;
using FieldOffsetArray = ZoneGrowableArray<intptr_t>;

class InstanceMorpher : public ZoneAllocated {
 public:
  // Creates a new [InstanceMorpher] based on the [from]/[to] class
  // descriptions.
  static InstanceMorpher* CreateFromClassDescriptors(Zone* zone,
                                                     ClassTable* class_table,
                                                     const Class& from,
                                                     const Class& to);

  InstanceMorpher(Zone* zone,
                  classid_t cid,
                  const Class& old_class,
                  const Class& new_class,
                  FieldMappingArray* mapping,
                  FieldOffsetArray* new_fields_offsets);
  virtual ~InstanceMorpher() {}

  // Adds an object to be morphed.
  void AddObject(ObjectPtr object);

  // Create the morphed objects based on the before() list.
  void CreateMorphedCopies(Become* become);

  // Append the morper info to JSON array.
  void AppendTo(JSONArray* array);

  // Returns the cid associated with the from_ and to_ class.
  intptr_t cid() const { return cid_; }

  // Dumps the field mappings for the [cid()] class.
  void Dump() const;

 private:
  Zone* zone_;
  classid_t cid_;
  const Class& old_class_;
  const Class& new_class_;
  FieldMappingArray* mapping_;
  FieldOffsetArray* new_fields_offsets_;

  GrowableArray<const Instance*> before_;
};

class ReasonForCancelling : public ZoneAllocated {
 public:
  explicit ReasonForCancelling(Zone* zone) {}
  virtual ~ReasonForCancelling() {}

  // Reports a reason for cancelling reload.
  void Report(IsolateGroupReloadContext* context);

  // Conversion to a VM error object.
  // Default implementation calls ToString.
  virtual ErrorPtr ToError();

  // Conversion to a string object.
  // Default implementation calls ToError.
  virtual StringPtr ToString();

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

class IsolateGroupReloadContext {
 public:
  IsolateGroupReloadContext(IsolateGroup* isolate,
                            ClassTable* class_table,
                            JSONStream* js);
  ~IsolateGroupReloadContext();

  // If kernel_buffer is provided, the VM takes ownership when Reload is called.
  bool Reload(bool force_reload,
              const char* root_script_url = nullptr,
              const char* packages_url = nullptr,
              const uint8_t* kernel_buffer = nullptr,
              intptr_t kernel_buffer_size = 0);

  // All zone allocated objects must be allocated from this zone.
  Zone* zone() const { return zone_; }

  IsolateGroup* isolate_group() const { return isolate_group_; }
  bool reload_aborted() const { return HasReasonsForCancelling(); }
  bool reload_skipped() const { return reload_skipped_; }
  ErrorPtr error() const;
  int64_t start_time_micros() const { return start_time_micros_; }
  int64_t reload_timestamp() const { return reload_timestamp_; }

  static Dart_FileModifiedCallback file_modified_callback() {
    return file_modified_callback_;
  }
  static void SetFileModifiedCallback(Dart_FileModifiedCallback callback) {
    file_modified_callback_ = callback;
  }

 private:
  // Tells whether there are reasons for cancelling the reload.
  bool HasReasonsForCancelling() const {
    return !reasons_to_cancel_reload_.is_empty();
  }

  // Record problem for this reload.
  void AddReasonForCancelling(ReasonForCancelling* reason);

  // Reports all reasons for cancelling reload.
  void ReportReasonsForCancelling();

  // Reports the details of a reload operation.
  void ReportOnJSON(JSONStream* stream, intptr_t final_library_count);

  // Ensures there is a instance morpher for [cid], if not it will use
  // [instance_morpher]
  void EnsureHasInstanceMorpherFor(classid_t cid,
                                   InstanceMorpher* instance_morpher);

  // Tells whether instance in the heap must be morphed.
  bool HasInstanceMorphers() const { return !instance_morphers_.is_empty(); }

  // Called by both FinalizeLoading and FinalizeFailedLoad.
  void CommonFinalizeTail(intptr_t final_library_count);

  // Report back through the observatory channels.
  void ReportError(const Error& error);
  void ReportSuccess();

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  void GetRootLibUrl(const char* root_script_url);
  char* CompileToKernel(bool force_reload,
                        const char* packages_url,
                        const uint8_t** kernel_buffer,
                        intptr_t* kernel_buffer_size);
  void BuildModifiedLibrariesClosure(BitVector* modified_libs);
  void FindModifiedSources(bool force_reload,
                           Dart_SourceFile** modified_sources,
                           intptr_t* count,
                           const char* packages_url);
  bool ScriptModifiedSince(const Script& script, int64_t since);

  void MorphInstancesPhase1Allocate(ObjectLocator* locator, Become* become);
  void MorphInstancesPhase2Become(Become* become);

  void ForEachIsolate(std::function<void(Isolate*)> callback);

  // The zone used for all reload related allocations.
  Zone* zone_;

  IsolateGroup* isolate_group_;
  ClassTable* class_table_;

  int64_t start_time_micros_ = -1;
  int64_t reload_timestamp_ = -1;
  bool reload_skipped_ = false;
  bool reload_finalized_ = false;
  JSONStream* js_;
  intptr_t num_old_libs_ = -1;

  intptr_t num_received_libs_ = -1;
  intptr_t bytes_received_libs_ = -1;
  intptr_t num_received_classes_ = -1;
  intptr_t num_received_procedures_ = -1;
  intptr_t num_saved_libs_ = -1;

  // Required trait for the instance_morpher_by_cid_;
  struct MorpherTrait {
    typedef InstanceMorpher* Value;
    typedef intptr_t Key;
    typedef InstanceMorpher* Pair;

    static Key KeyOf(Pair kv) { return kv->cid(); }
    static Value ValueOf(Pair kv) { return kv; }
    static uword Hash(Key key) { return Utils::WordHash(key); }
    static bool IsKeyEqual(Pair kv, Key key) { return kv->cid() == key; }
  };

  // Collect the necessary instance transformation for schema changes.
  GrowableArray<InstanceMorpher*> instance_morphers_;

  // Collects the reasons for cancelling the reload.
  GrowableArray<ReasonForCancelling*> reasons_to_cancel_reload_;

  // Hash map from cid to InstanceMorpher.
  DirectChainedHashMap<MorpherTrait> instance_morpher_by_cid_;

  // A bit vector indicating which of the original libraries were modified.
  BitVector* modified_libs_ = nullptr;

  // A bit vector indicating which of the original libraries were modified,
  // or where a transitive dependency was modified.
  BitVector* modified_libs_transitive_ = nullptr;

  // A bit vector indicating which of the saved libraries that transitively
  // depend on a modified library.
  BitVector* saved_libs_transitive_updated_ = nullptr;

  String& root_lib_url_;
  ObjectPtr* from() { return reinterpret_cast<ObjectPtr*>(&root_url_prefix_); }
  StringPtr root_url_prefix_;
  StringPtr old_root_url_prefix_;
  ObjectPtr* to() {
    return reinterpret_cast<ObjectPtr*>(&old_root_url_prefix_);
  }

  friend class Isolate;
  friend class Class;  // AddStaticFieldMapping, AddEnumBecomeMapping.
  friend class Library;
  friend class ObjectLocator;
  friend class ReasonForCancelling;
  friend class ProgramReloadContext;
  friend class IsolateGroup;

  static Dart_FileModifiedCallback file_modified_callback_;
};

class ProgramReloadContext {
 public:
  ProgramReloadContext(
      std::shared_ptr<IsolateGroupReloadContext> group_reload_context,
      IsolateGroup* isolate_group);
  ~ProgramReloadContext();

  // All zone allocated objects must be allocated from this zone.
  Zone* zone() const { return zone_; }

  IsolateGroupReloadContext* group_reload_context() {
    return group_reload_context_.get();
  }

  static bool IsSameLibrary(const Library& a_lib, const Library& b_lib);
  static bool IsSameClass(const Class& a, const Class& b);

 private:
  bool IsDirty(const Library& lib);

  void RegisterClass(const Class& new_cls);

  // Finds the library private key for |replacement_or_new| or return null
  // if |replacement_or_new| is new.
  StringPtr FindLibraryPrivateKey(const Library& replacement_or_new);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  IsolateGroup* isolate_group() { return isolate_group_; }
  ObjectStore* object_store();

  void EnsuredUnoptimizedCodeForStack();
  void DeoptimizeDependentCode();

  void ReloadPhase1AllocateStorageMapsAndCheckpoint();
  void CheckpointClasses();
  ObjectPtr ReloadPhase2LoadKernel(kernel::Program* program,
                                   const String& root_lib_url);
  void ReloadPhase3FinalizeLoading();
  void ReloadPhase4CommitPrepare();
  void ReloadPhase4CommitFinish();
  void ReloadPhase4Rollback();

  void CheckpointLibraries();

  void RollbackLibraries();

#ifdef DEBUG
  void VerifyMaps();
#endif

  void CommitBeforeInstanceMorphing();
  void CommitAfterInstanceMorphing();
  void PostCommit();

  void RunInvalidationVisitors();
  void InvalidateKernelInfos(
      Zone* zone,
      const GrowableArray<const KernelProgramInfo*>& kernel_infos);
  void InvalidateFunctions(Zone* zone,
                           const GrowableArray<const Function*>& functions);
  void InvalidateSuspendStates(
      Zone* zone,
      const GrowableArray<const SuspendState*>& suspend_states);
  void InvalidateFields(Zone* zone,
                        const GrowableArray<const Field*>& fields,
                        const GrowableArray<const Instance*>& instances);
  void ResetUnoptimizedICsOnStack();
  void ResetMegamorphicCaches();
  void InvalidateWorld();

  struct LibraryInfo {
    bool dirty;
  };

  // The zone used for all reload related allocations.
  Zone* zone_;
  std::shared_ptr<IsolateGroupReloadContext> group_reload_context_;
  IsolateGroup* isolate_group_;
  MallocGrowableArray<LibraryInfo> library_infos_;

  ClassPtr OldClassOrNull(const Class& replacement_or_new);
  LibraryPtr OldLibraryOrNull(const Library& replacement_or_new);
  LibraryPtr OldLibraryOrNullBaseMoved(const Library& replacement_or_new);

  void BuildLibraryMapping();
  void BuildRemovedClassesSet();
  void ValidateReload();

  void AddClassMapping(const Class& replacement_or_new, const Class& original);
  void AddLibraryMapping(const Library& replacement_or_new,
                         const Library& original);
  void AddStaticFieldMapping(const Field& old_field, const Field& new_field);
  void AddBecomeMapping(const Object& old, const Object& neu);
  void RebuildDirectSubclasses();

  Become become_;

  ObjectPtr* from() {
    return reinterpret_cast<ObjectPtr*>(&old_classes_set_storage_);
  }
  ArrayPtr old_classes_set_storage_;
  ArrayPtr class_map_storage_;
  ArrayPtr removed_class_set_storage_;
  ArrayPtr old_libraries_set_storage_;
  ArrayPtr library_map_storage_;
  LibraryPtr saved_root_library_;
  GrowableObjectArrayPtr saved_libraries_;
  ObjectPtr* to() { return reinterpret_cast<ObjectPtr*>(&saved_libraries_); }

  friend class Isolate;
  friend class IsolateGroup;
  friend class Class;  // AddStaticFieldMapping, AddEnumBecomeMapping.
  friend class Library;
  friend class ObjectLocator;
  friend class ReasonForCancelling;
  friend class IsolateGroupReloadContext;
};

class CallSiteResetter : public ValueObject {
 public:
  explicit CallSiteResetter(Zone* zone);

  void ZeroEdgeCounters(const Function& function);
  void ResetCaches(const Code& code);
  void ResetCaches(const ObjectPool& pool);
  void Reset(const ICData& ic);
  void ResetSwitchableCalls(const Code& code);

 private:
  Zone* zone_;
  Instructions& instrs_;
  ObjectPool& pool_;
  Object& object_;
  String& name_;
  Class& new_cls_;
  Library& new_lib_;
  Function& new_function_;
  Field& new_field_;
  Array& entries_;
  Function& old_target_;
  Function& new_target_;
  Function& caller_;
  Array& args_desc_array_;
  Array& ic_data_array_;
  Array& edge_counters_;
  PcDescriptors& descriptors_;
  ICData& ic_data_;
};

// Ensures all other mutators are stopped at a well-defined place where reload
// is allowed.
class ReloadOperationScope : public StackResource {
 public:
  explicit ReloadOperationScope(Thread* thread);
  ~ReloadOperationScope() {}

 private:
  // As the background compiler is a mutator it participates in safepoint
  // operations. Though the BG compiler won't check into reload safepoint
  // requests - as it's not a well-defined place to do reload.
  // So we ensure the background compiler is stopped before we get all other
  // mutators to reload safepoints.
  NoBackgroundCompilerScope stop_bg_compiler_;

  // This will enable the current thread to perform reload operations (as well
  // as check-in with other thread's reload operations).
  ReloadParticipationScope allow_reload_;

  // The actual reload operation that will ensure all other mutators are stopped
  // at well-defined places where reload can happen.
  ReloadSafepointOperationScope safepoint_operation_;
};

}  // namespace dart

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#endif  // RUNTIME_VM_ISOLATE_RELOAD_H_
