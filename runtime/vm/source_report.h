// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SOURCE_REPORT_H_
#define RUNTIME_VM_SOURCE_REPORT_H_

#include "vm/globals.h"
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/profiler_service.h"
#include "vm/token_position.h"

namespace dart {

// A SourceReport object is used to generate reports about the program
// source code, with information associated with source token
// positions.  There are multiple possible kinds of reports.
class SourceReport {
 public:
  enum ReportKind {
    kCallSites = 0x1,
    kCoverage = 0x2,
    kPossibleBreakpoints = 0x4,
    kProfile = 0x8,
  };

  static const char* kCallSitesStr;
  static const char* kCoverageStr;
  static const char* kPossibleBreakpointsStr;
  static const char* kProfileStr;

  enum CompileMode { kNoCompile, kForceCompile };

  // report_set is a bitvector indicating which reports to generate
  // (e.g. kCallSites | kCoverage).
  explicit SourceReport(intptr_t report_set, CompileMode compile = kNoCompile);
  ~SourceReport();

  // Generate a source report for (some subrange of) a script.
  //
  // If script is null, then the report is generated for all scripts
  // in the isolate.
  void PrintJSON(JSONStream* js,
                 const Script& script,
                 TokenPosition start_pos = TokenPosition::kMinSource,
                 TokenPosition end_pos = TokenPosition::kMaxSource);

 private:
  void ClearScriptTable();
  void Init(Thread* thread,
            const Script* script,
            TokenPosition start_pos,
            TokenPosition end_pos);

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }
  Isolate* isolate() const { return thread_->isolate(); }

  bool IsReportRequested(ReportKind report_kind);
  bool ShouldSkipFunction(const Function& func);
  bool ShouldSkipField(const Field& field);
  intptr_t GetScriptIndex(const Script& script);
  bool ScriptIsLoadedByLibrary(const Script& script, const Library& lib);

  void PrintCallSitesData(JSONObject* jsobj,
                          const Function& func,
                          const Code& code);
  void PrintCoverageData(JSONObject* jsobj,
                         const Function& func,
                         const Code& code);
  void PrintPossibleBreakpointsData(JSONObject* jsobj,
                                    const Function& func,
                                    const Code& code);
  void PrintProfileData(JSONObject* jsobj, ProfileFunction* profile_function);
#if defined(DEBUG)
  void VerifyScriptTable();
#endif
  void PrintScriptTable(JSONArray* jsarr);

  void VisitFunction(JSONArray* jsarr, const Function& func);
  void VisitField(JSONArray* jsarr, const Field& field);
  void VisitLibrary(JSONArray* jsarr, const Library& lib);
  void VisitClosures(JSONArray* jsarr);
  // An entry in the script table.
  struct ScriptTableEntry {
    ScriptTableEntry() : key(NULL), index(-1), script(NULL) {}

    const String* key;
    intptr_t index;
    const Script* script;
  };

  // Needed for DirectChainedHashMap.
  struct ScriptTableTrait {
    typedef ScriptTableEntry* Value;
    typedef const ScriptTableEntry* Key;
    typedef ScriptTableEntry* Pair;

    static Key KeyOf(Pair kv) { return kv; }

    static Value ValueOf(Pair kv) { return kv; }

    static inline intptr_t Hashcode(Key key) { return key->key->Hash(); }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return kv->script->raw() == key->script->raw();
    }
  };

  void CollectAllScripts(
      DirectChainedHashMap<ScriptTableTrait>* local_script_table,
      GrowableArray<ScriptTableEntry*>* local_script_table_entries);

  void CleanupCollectedScripts(
      DirectChainedHashMap<ScriptTableTrait>* local_script_table,
      GrowableArray<ScriptTableEntry*>* local_script_table_entries);

  void CollectConstConstructorCoverageFromScripts(
      GrowableArray<ScriptTableEntry*>* local_script_table_entries,
      JSONArray* ranges);

  intptr_t report_set_;
  CompileMode compile_mode_;
  Thread* thread_;
  const Script* script_;
  TokenPosition start_pos_;
  TokenPosition end_pos_;
  Profile profile_;
  GrowableArray<ScriptTableEntry*> script_table_entries_;
  DirectChainedHashMap<ScriptTableTrait> script_table_;
  intptr_t next_script_index_;
};

}  // namespace dart

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_SOURCE_REPORT_H_
