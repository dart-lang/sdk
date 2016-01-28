// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SOURCE_REPORT_H_
#define VM_SOURCE_REPORT_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/hash_map.h"
#include "vm/object.h"

namespace dart {

// A SourceReport object is used to generate reports about the program
// source code, with information associated with source token
// positions.  There are multiple possible kinds of reports.
class SourceReport {
 public:
  enum ReportKind {
    kCallSites = 0x1,
    kCoverage  = 0x2,
  };

  enum CompileMode {
    kNoCompile,
    kForceCompile
  };

  // report_set is a bitvector indicating which reports to generate
  // (e.g. kCallSites | kCoverage).
  explicit SourceReport(intptr_t report_set,
                        CompileMode compile = kNoCompile);

  // Generate a source report for (some subrange of) a script.
  //
  // If script is null, then the report is generated for all scripts
  // in the isolate.
  void PrintJSON(JSONStream* js, const Script& script,
                 intptr_t start_pos = -1, intptr_t end_pos = -1);

 private:
  void Init(Thread* thread, const Script* script,
            intptr_t start_pos, intptr_t end_pos);

  Thread* thread() const { return thread_; }
  Zone* zone() const { return thread_->zone(); }

  bool IsReportRequested(ReportKind report_kind);
  bool ShouldSkipFunction(const Function& func);
  intptr_t GetScriptIndex(const Script& script);
  bool ScriptIsLoadedByLibrary(const Script& script, const Library& lib);

  void PrintCallSitesData(JSONObject* jsobj,
                          const Function& func, const Code& code);
  void PrintCoverageData(JSONObject* jsobj,
                         const Function& func, const Code& code);
  void PrintScriptTable(JSONArray* jsarr);

  void VisitFunction(JSONArray* jsarr, const Function& func);
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
    typedef const String* Key;
    typedef ScriptTableEntry* Pair;

    static Key KeyOf(Pair kv) {
      return kv->key;
    }

    static Value ValueOf(Pair kv) {
      return kv;
    }

    static inline intptr_t Hashcode(Key key) {
      return key->Hash();
    }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return kv->key->Equals(*key);
    }
  };

  intptr_t report_set_;
  CompileMode compile_mode_;
  Thread* thread_;
  const Script* script_;
  intptr_t start_pos_;
  intptr_t end_pos_;
  GrowableArray<ScriptTableEntry> script_table_entries_;
  DirectChainedHashMap<ScriptTableTrait> script_table_;
  intptr_t next_script_index_;
};

}  // namespace dart

#endif  // VM_SOURCE_REPORT_H_
