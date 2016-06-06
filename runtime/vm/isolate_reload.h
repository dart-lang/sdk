// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_RELOAD_H_
#define VM_ISOLATE_RELOAD_H_

#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/log.h"

DECLARE_FLAG(bool, trace_reload);

// 'Trace Isolate Reload' TIR_Print
#if defined(_MSC_VER)
#define TIR_Print(format, ...) \
    if (FLAG_trace_reload) Log::Current()->Print(format, __VA_ARGS__)
#else
#define TIR_Print(format, ...) \
    if (FLAG_trace_reload) Log::Current()->Print(format, ##__VA_ARGS__)
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

class IsolateReloadContext {
 public:
  explicit IsolateReloadContext(Isolate* isolate, bool test_mode = false);
  ~IsolateReloadContext();

  void StartReload();
  void FinishReload();
  void AbortReload(const Error& error);

  RawLibrary* saved_root_library() const;

  RawGrowableObjectArray* saved_libraries() const;

  void ReportError(const Error& error);
  void ReportError(const String& error_msg);
  void ReportSuccess();

  bool has_error() const { return has_error_; }
  RawError* error() const { return error_; }
  bool test_mode() const { return test_mode_; }

  static bool IsSameField(const Field& a, const Field& b);
  static bool IsSameLibrary(const Library& a_lib, const Library& b_lib);
  static bool IsSameClass(const Class& a, const Class& b);

  RawClass* FindOriginalClass(const Class& cls);

  bool IsDirty(const Library& lib);

  // Prefers old classes when we are in the middle of a reload.
  RawClass* GetClassForHeapWalkAt(intptr_t cid);

  void RegisterClass(const Class& new_cls);

  int64_t start_time_micros() const { return start_time_micros_; }

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

  void BuildCleanScriptSet();
  void FilterCompileTimeConstants();

  // atomic_install:
  void MarkAllFunctionsForRecompilation();
  void ResetUnoptimizedICsOnStack();
  void ResetMegamorphicCaches();
  void InvalidateWorld();

  int64_t start_time_micros_;
  Isolate* isolate_;
  bool test_mode_;
  bool has_error_;

  intptr_t saved_num_cids_;
  RawClass** saved_class_table_;

  intptr_t num_saved_libs_;
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

  void AddBecomeMapping(const Object& old, const Object& nue);

  void RebuildDirectSubclasses();

  RawClass* MappedClass(const Class& replacement_or_new);
  RawLibrary* MappedLibrary(const Library& replacement_or_new);

  RawObject** from() { return reinterpret_cast<RawObject**>(&script_uri_); }
  RawString* script_uri_;
  RawError* error_;
  RawArray* clean_scripts_set_storage_;
  RawArray* compile_time_constants_;
  RawArray* old_classes_set_storage_;
  RawArray* class_map_storage_;
  RawArray* old_libraries_set_storage_;
  RawArray* library_map_storage_;
  RawArray* become_map_storage_;
  RawLibrary* saved_root_library_;
  RawGrowableObjectArray* saved_libraries_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&saved_libraries_); }

  friend class Isolate;
  friend class Class;  // AddStaticFieldMapping.
};

}  // namespace dart

#endif   // VM_ISOLATE_RELOAD_H_
