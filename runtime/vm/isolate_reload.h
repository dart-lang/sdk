// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_RELOAD_H_
#define VM_ISOLATE_RELOAD_H_

#include "vm/hash_map.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/log.h"

DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, trace_reload_verbose);

// 'Trace Isolate Reload' TIR_Print
#if defined(_MSC_VER)
#define TIR_Print(format, ...) \
    if (FLAG_trace_reload) Log::Current()->Print(format, __VA_ARGS__)
#else
#define TIR_Print(format, ...) \
    if (FLAG_trace_reload) Log::Current()->Print(format, ##__VA_ARGS__)
#endif

// 'Verbose Trace Isolate Reload' VTIR_Print
#if defined(_MSC_VER)
#define VTIR_Print(format, ...) \
    if (FLAG_trace_reload_verbose) Log::Current()->Print(format, __VA_ARGS__)
#else
#define VTIR_Print(format, ...) \
    if (FLAG_trace_reload_verbose) Log::Current()->Print(format, ##__VA_ARGS__)
#endif

namespace dart {

class GrowableObjectArray;
class Isolate;
class Library;
class RawError;
class RawGrowableObjectArray;
class RawLibrary;
class RawObject;
class RawString;
class ObjectPointerVisitor;
class ObjectStore;
class UpdateClassesVisitor;


class InstanceMorpher : public ZoneAllocated {
 public:
  InstanceMorpher(const Class& from, const Class& to);
  virtual ~InstanceMorpher() {}

  // Called on each instance that needs to be morphed.
  RawInstance* Morph(const Instance& instance) const;

  // Adds an object to be morphed.
  void AddObject(RawObject* object) const;

  // Create the morphed objects based on the before() list.
  void CreateMorphedCopies() const;

  // Dump the state of the morpher.
  void Dump() const;

  // Returns the list of objects that need to be morphed.
  ZoneGrowableArray<const Instance*>* before() const { return before_; }
  // Returns the list of morphed objects (matches order in before()).
  ZoneGrowableArray<const Instance*>* after() const { return after_; }

  // Returns the cid associated with the from_ and to_ class.
  intptr_t cid() const { return cid_; }

 private:
  const Class& from_;
  const Class& to_;
  ZoneGrowableArray<intptr_t> mapping_;
  ZoneGrowableArray<const Instance*>* before_;
  ZoneGrowableArray<const Instance*>* after_;
  intptr_t cid_;

  void ComputeMapping();
  void DumpFormatFor(const Class& cls) const;
};


class ReasonForCancelling : public ZoneAllocated {
 public:
  ReasonForCancelling() {}
  virtual ~ReasonForCancelling() {}

  // Reports a reason for cancelling reload.
  void Report(IsolateReloadContext* context);

  // Conversion to a VM error object.
  // Default implementation calls ToString.
  virtual RawError* ToError();

  // Conversion to a string object.
  // Default implementation calls ToError.
  virtual RawString* ToString();

  // Concrete subclasses must override either ToError or ToString.
};


// Abstract class for also capturing the from_ and to_ class.
class ClassReasonForCancelling : public ReasonForCancelling {
 public:
  ClassReasonForCancelling(const Class& from, const Class& to)
      : from_(from), to_(to) { }

 protected:
  const Class& from_;
  const Class& to_;
};


class IsolateReloadContext {
 public:
  explicit IsolateReloadContext(Isolate* isolate);
  ~IsolateReloadContext();

  void StartReload();
  void FinishReload();
  void AbortReload(const Error& error);

  RawLibrary* saved_root_library() const;

  RawGrowableObjectArray* saved_libraries() const;

  // Report back through the observatory channels.
  void ReportError(const Error& error);
  void ReportSuccess();

  bool has_error() const { return HasReasonsForCancelling(); }
  RawError* error() const;

  static bool IsSameField(const Field& a, const Field& b);
  static bool IsSameLibrary(const Library& a_lib, const Library& b_lib);
  static bool IsSameClass(const Class& a, const Class& b);

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

  // Report all reasons for cancelling reload.
  void ReportReasonsForCancelling();

  // Store morphing operation.
  void AddInstanceMorpher(InstanceMorpher* morpher);

  // Tells whether instance in the heap must be morphed.
  bool HasInstanceMorphers() const {
    return !instance_morphers_.is_empty();
  }

 private:
  void set_saved_root_library(const Library& value);

  void set_saved_libraries(const GrowableObjectArray& value);

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  Isolate* isolate() { return isolate_; }
  ObjectStore* object_store();

  void EnsuredUnoptimizedCodeForStack();
  void DeoptimizeDependentCode();

  void Checkpoint();

  void CheckpointClasses();

  // Is |lib| a library whose sources have not changed?
  bool IsCleanLibrary(const Library& lib);
  void CheckpointLibraries();

  // Transforms the heap based on instance_morphers_.
  void MorphInstances();

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

  int64_t start_time_micros_;
  Isolate* isolate_;

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

  RawClass* OldClassOrNull(const Class& replacement_or_new);

  RawLibrary* OldLibraryOrNull(const Library& replacement_or_new);
  void BuildLibraryMapping();

  void AddClassMapping(const Class& replacement_or_new,
                       const Class& original);

  void AddLibraryMapping(const Library& replacement_or_new,
                         const Library& original);

  void AddStaticFieldMapping(const Field& old_field, const Field& new_field);

  void AddBecomeMapping(const Object& old, const Object& neu);
  void AddEnumBecomeMapping(const Object& old, const Object& neu);

  void RebuildDirectSubclasses();

  RawClass* MappedClass(const Class& replacement_or_new);
  RawLibrary* MappedLibrary(const Library& replacement_or_new);

  RawObject** from() { return reinterpret_cast<RawObject**>(&script_uri_); }
  RawString* script_uri_;
  RawError* error_;
  RawArray* old_classes_set_storage_;
  RawArray* class_map_storage_;
  RawArray* old_libraries_set_storage_;
  RawArray* library_map_storage_;
  RawArray* become_map_storage_;
  RawGrowableObjectArray* become_enum_mappings_;
  RawLibrary* saved_root_library_;
  RawGrowableObjectArray* saved_libraries_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&saved_libraries_); }

  friend class Isolate;
  friend class Class;  // AddStaticFieldMapping, AddEnumBecomeMapping.
  friend class ObjectLocator;
};

}  // namespace dart

#endif   // VM_ISOLATE_RELOAD_H_
