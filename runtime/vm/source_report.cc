// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#include "vm/globals.h"
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/source_report.h"

#include "vm/bit_vector.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/isolate.h"
#include "vm/kernel_loader.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/profiler.h"
#include "vm/profiler_service.h"

namespace dart {

const char* SourceReport::kCallSitesStr = "_CallSites";
const char* SourceReport::kCoverageStr = "Coverage";
const char* SourceReport::kPossibleBreakpointsStr = "PossibleBreakpoints";
const char* SourceReport::kProfileStr = "_Profile";

SourceReport::SourceReport(intptr_t report_set, CompileMode compile_mode)
    : report_set_(report_set),
      compile_mode_(compile_mode),
      thread_(NULL),
      script_(NULL),
      start_pos_(TokenPosition::kMinSource),
      end_pos_(TokenPosition::kMaxSource),
      profile_(Isolate::Current()),
      next_script_index_(0) {}

SourceReport::~SourceReport() {
  ClearScriptTable();
}

void SourceReport::ClearScriptTable() {
  for (intptr_t i = 0; i < script_table_entries_.length(); i++) {
    delete script_table_entries_[i];
    script_table_entries_[i] = NULL;
  }
  script_table_entries_.Clear();
  script_table_.Clear();
  next_script_index_ = 0;
}

void SourceReport::Init(Thread* thread,
                        const Script* script,
                        TokenPosition start_pos,
                        TokenPosition end_pos) {
  thread_ = thread;
  script_ = script;
  start_pos_ = TokenPosition::Max(start_pos, TokenPosition::kMinSource);
  end_pos_ = TokenPosition::Min(end_pos, TokenPosition::kMaxSource);
  ClearScriptTable();
  if (IsReportRequested(kProfile)) {
    // Build the profile.
    SampleFilter samplesForIsolate(thread_->isolate()->main_port(),
                                   Thread::kMutatorTask, -1, -1);
    profile_.Build(thread, &samplesForIsolate, Profiler::sample_buffer());
  }
}

bool SourceReport::IsReportRequested(ReportKind report_kind) {
  return (report_set_ & report_kind) != 0;
}

bool SourceReport::ShouldSkipFunction(const Function& func) {
  // TODO(32315): Verify that the check is still needed after the issue is
  // resolved.
  if (!func.token_pos().IsReal() || !func.end_token_pos().IsReal()) {
    // At least one of the token positions is not known.
    return true;
  }

  if (script_ != NULL && !script_->IsNull()) {
    if (func.script() != script_->raw()) {
      // The function is from the wrong script.
      return true;
    }
    if ((func.end_token_pos() < start_pos_) || (func.token_pos() > end_pos_)) {
      // The function does not intersect with the requested token range.
      return true;
    }
  }

  // These don't have unoptimized code and are only used for synthetic stubs.
  if (func.ForceOptimize()) return true;

  switch (func.kind()) {
    case FunctionLayout::kRegularFunction:
    case FunctionLayout::kClosureFunction:
    case FunctionLayout::kImplicitClosureFunction:
    case FunctionLayout::kImplicitStaticGetter:
    case FunctionLayout::kFieldInitializer:
    case FunctionLayout::kGetterFunction:
    case FunctionLayout::kSetterFunction:
    case FunctionLayout::kConstructor:
      break;
    default:
      return true;
  }
  if (func.is_abstract() || func.IsImplicitConstructor() ||
      func.is_synthetic()) {
    return true;
  }
  if (func.IsNonImplicitClosureFunction() &&
      (func.context_scope() == ContextScope::null())) {
    // TODO(iposva): This can arise if we attempt to compile an inner function
    // before we have compiled its enclosing function or if the enclosing
    // function failed to compile.
    return true;
  }
  return false;
}

bool SourceReport::ShouldSkipField(const Field& field) {
  if (!field.token_pos().IsReal() || !field.end_token_pos().IsReal()) {
    // At least one of the token positions is not known.
    return true;
  }

  if (script_ != NULL && !script_->IsNull()) {
    if (field.Script() != script_->raw()) {
      // The field is from the wrong script.
      return true;
    }
    if ((field.end_token_pos() < start_pos_) ||
        (field.token_pos() > end_pos_)) {
      // The field does not intersect with the requested token range.
      return true;
    }
  }
  return false;
}

intptr_t SourceReport::GetScriptIndex(const Script& script) {
  ScriptTableEntry wrapper;
  const String& url = String::Handle(zone(), script.url());
  wrapper.key = &url;
  wrapper.script = &Script::Handle(zone(), script.raw());
  ScriptTableEntry* pair = script_table_.LookupValue(&wrapper);
  if (pair != NULL) {
    return pair->index;
  }
  ScriptTableEntry* tmp = new ScriptTableEntry();
  tmp->key = &url;
  tmp->index = next_script_index_++;
  tmp->script = wrapper.script;
  script_table_entries_.Add(tmp);
  script_table_.Insert(tmp);
  ASSERT(script_table_entries_.length() == next_script_index_);
#if defined(DEBUG)
  VerifyScriptTable();
#endif
  return tmp->index;
}

#if defined(DEBUG)
void SourceReport::VerifyScriptTable() {
  for (intptr_t i = 0; i < script_table_entries_.length(); i++) {
    const String* url = script_table_entries_[i]->key;
    const Script* script = script_table_entries_[i]->script;
    intptr_t index = script_table_entries_[i]->index;
    ASSERT(i == index);
    const String& url2 = String::Handle(zone(), script->url());
    ASSERT(url2.Equals(*url));
    ScriptTableEntry wrapper;
    wrapper.key = &url2;
    wrapper.script = &Script::Handle(zone(), script->raw());
    ScriptTableEntry* pair = script_table_.LookupValue(&wrapper);
    ASSERT(i == pair->index);
  }
}
#endif

bool SourceReport::ScriptIsLoadedByLibrary(const Script& script,
                                           const Library& lib) {
  const Array& scripts = Array::Handle(zone(), lib.LoadedScripts());
  for (intptr_t j = 0; j < scripts.Length(); j++) {
    if (scripts.At(j) == script.raw()) {
      return true;
    }
  }
  return false;
}

void SourceReport::PrintCallSitesData(JSONObject* jsobj,
                                      const Function& function,
                                      const Code& code) {
  ASSERT(!code.IsNull());
  const TokenPosition& begin_pos = function.token_pos();
  const TokenPosition& end_pos = function.end_token_pos();
  ZoneGrowableArray<const ICData*>* ic_data_array =
      new (zone()) ZoneGrowableArray<const ICData*>();
  function.RestoreICDataMap(ic_data_array, false /* clone ic-data */);
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone(), code.pc_descriptors());

  JSONArray sites(jsobj, "callSites");

  PcDescriptors::Iterator iter(
      descriptors,
      PcDescriptorsLayout::kIcCall | PcDescriptorsLayout::kUnoptStaticCall);
  while (iter.MoveNext()) {
    HANDLESCOPE(thread());
    ASSERT(iter.DeoptId() < ic_data_array->length());
    const ICData* ic_data = (*ic_data_array)[iter.DeoptId()];
    if (ic_data != NULL) {
      const TokenPosition& token_pos = iter.TokenPos();
      if (!token_pos.IsWithin(begin_pos, end_pos)) {
        // Does not correspond to a valid source position.
        continue;
      }
      ic_data->PrintToJSONArray(sites, token_pos);
    }
  }
}

void SourceReport::PrintCoverageData(JSONObject* jsobj,
                                     const Function& function,
                                     const Code& code) {
  ASSERT(!code.IsNull());
  const TokenPosition& begin_pos = function.token_pos();
  const TokenPosition& end_pos = function.end_token_pos();

  ZoneGrowableArray<const ICData*>* ic_data_array =
      new (zone()) ZoneGrowableArray<const ICData*>();
  function.RestoreICDataMap(ic_data_array, false /* clone ic-data */);
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone(), code.pc_descriptors());

  const int kCoverageNone = 0;
  const int kCoverageMiss = 1;
  const int kCoverageHit = 2;

  intptr_t func_length = function.SourceSize() + 1;
  GrowableArray<char> coverage(func_length);
  coverage.SetLength(func_length);
  for (int i = 0; i < func_length; i++) {
    coverage[i] = kCoverageNone;
  }

  if (function.WasExecuted()) {
    coverage[0] = kCoverageHit;
  } else {
    coverage[0] = kCoverageMiss;
  }

  PcDescriptors::Iterator iter(
      descriptors,
      PcDescriptorsLayout::kIcCall | PcDescriptorsLayout::kUnoptStaticCall);
  while (iter.MoveNext()) {
    HANDLESCOPE(thread());
    ASSERT(iter.DeoptId() < ic_data_array->length());
    const ICData* ic_data = (*ic_data_array)[iter.DeoptId()];
    if (ic_data != NULL) {
      const TokenPosition& token_pos = iter.TokenPos();
      if (!token_pos.IsWithin(begin_pos, end_pos)) {
        // Does not correspond to a valid source position.
        continue;
      }
      intptr_t count = ic_data->AggregateCount();
      intptr_t token_offset = token_pos.Pos() - begin_pos.Pos();
      if (count > 0) {
        coverage[token_offset] = kCoverageHit;
      } else {
        if (coverage[token_offset] == kCoverageNone) {
          coverage[token_offset] = kCoverageMiss;
        }
      }
    }
  }

  JSONObject cov(jsobj, "coverage");
  {
    JSONArray hits(&cov, "hits");
    for (int i = 0; i < func_length; i++) {
      if (coverage[i] == kCoverageHit) {
        // Add the token position of the hit.
        hits.AddValue(begin_pos.Pos() + i);
      }
    }
  }
  {
    JSONArray misses(&cov, "misses");
    for (int i = 0; i < func_length; i++) {
      if (coverage[i] == kCoverageMiss) {
        // Add the token position of the miss.
        misses.AddValue(begin_pos.Pos() + i);
      }
    }
  }
}

void SourceReport::PrintPossibleBreakpointsData(JSONObject* jsobj,
                                                const Function& func,
                                                const Code& code) {
  const TokenPosition& begin_pos = func.token_pos();
  const TokenPosition& end_pos = func.end_token_pos();
  intptr_t func_length = func.SourceSize() + 1;

  BitVector possible(zone(), func_length);

  ASSERT(!code.IsNull());

  const uint8_t kSafepointKind =
      (PcDescriptorsLayout::kIcCall | PcDescriptorsLayout::kUnoptStaticCall |
       PcDescriptorsLayout::kRuntimeCall);

  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone(), code.pc_descriptors());

  PcDescriptors::Iterator iter(descriptors, kSafepointKind);
  while (iter.MoveNext()) {
    const TokenPosition& token_pos = iter.TokenPos();
    if (!token_pos.IsWithin(begin_pos, end_pos)) {
      // Does not correspond to a valid source position.
      continue;
    }
    intptr_t token_offset = token_pos.Pos() - begin_pos.Pos();
    possible.Add(token_offset);
  }

  JSONArray bpts(jsobj, "possibleBreakpoints");
  for (int i = 0; i < func_length; i++) {
    if (possible.Contains(i)) {
      // Add the token position.
      bpts.AddValue(begin_pos.Pos() + i);
    }
  }
}

void SourceReport::PrintProfileData(JSONObject* jsobj,
                                    ProfileFunction* profile_function) {
  ASSERT(profile_function != NULL);
  ASSERT(profile_function->NumSourcePositions() > 0);

  {
    JSONObject profile(jsobj, "profile");

    {
      JSONObject profileData(&profile, "metadata");
      profileData.AddProperty("sampleCount", profile_.sample_count());
    }

    // Positions.
    {
      JSONArray positions(&profile, "positions");
      for (intptr_t i = 0; i < profile_function->NumSourcePositions(); i++) {
        const ProfileFunctionSourcePosition& position =
            profile_function->GetSourcePosition(i);
        if (position.token_pos().IsReal()) {
          // Add as an integer.
          positions.AddValue(position.token_pos().Pos());
        } else {
          // Add as a string.
          positions.AddValue(position.token_pos().ToCString());
        }
      }
    }

    // Exclusive ticks.
    {
      JSONArray exclusiveTicks(&profile, "exclusiveTicks");
      for (intptr_t i = 0; i < profile_function->NumSourcePositions(); i++) {
        const ProfileFunctionSourcePosition& position =
            profile_function->GetSourcePosition(i);
        exclusiveTicks.AddValue(position.exclusive_ticks());
      }
    }
    // Inclusive ticks.
    {
      JSONArray inclusiveTicks(&profile, "inclusiveTicks");
      for (intptr_t i = 0; i < profile_function->NumSourcePositions(); i++) {
        const ProfileFunctionSourcePosition& position =
            profile_function->GetSourcePosition(i);
        inclusiveTicks.AddValue(position.inclusive_ticks());
      }
    }
  }
}

void SourceReport::PrintScriptTable(JSONArray* scripts) {
  for (intptr_t i = 0; i < script_table_entries_.length(); i++) {
    const Script* script = script_table_entries_[i]->script;
    scripts->AddValue(*script);
  }
}

void SourceReport::VisitFunction(JSONArray* jsarr, const Function& func) {
  if (ShouldSkipFunction(func)) {
    return;
  }

  const Script& script = Script::Handle(zone(), func.script());
  const TokenPosition begin_pos = func.token_pos();
  const TokenPosition end_pos = func.end_token_pos();

  Code& code = Code::Handle(zone(), func.unoptimized_code());
  if (code.IsNull()) {
    if (func.HasCode() || (compile_mode_ == kForceCompile)) {
      const Error& err =
          Error::Handle(Compiler::EnsureUnoptimizedCode(thread(), func));
      if (!err.IsNull()) {
        // Emit an uncompiled range for this function with error information.
        JSONObject range(jsarr);
        range.AddProperty("scriptIndex", GetScriptIndex(script));
        range.AddProperty("startPos", begin_pos);
        range.AddProperty("endPos", end_pos);
        range.AddProperty("compiled", false);
        range.AddProperty("error", err);
        return;
      }
      code = func.unoptimized_code();
    } else {
      // This function has not been compiled yet.
      JSONObject range(jsarr);
      range.AddProperty("scriptIndex", GetScriptIndex(script));
      range.AddProperty("startPos", begin_pos);
      range.AddProperty("endPos", end_pos);
      range.AddProperty("compiled", false);
      return;
    }
  }
  ASSERT(!code.IsNull());

  // We skip compiled async functions.  Once an async function has
  // been compiled, there is another function with the same range which
  // actually contains the user code.
  if (!func.IsAsyncFunction() && !func.IsAsyncGenerator() &&
      !func.IsSyncGenerator()) {
    JSONObject range(jsarr);
    range.AddProperty("scriptIndex", GetScriptIndex(script));
    range.AddProperty("startPos", begin_pos);
    range.AddProperty("endPos", end_pos);
    range.AddProperty("compiled", true);

    if (IsReportRequested(kCallSites)) {
      PrintCallSitesData(&range, func, code);
    }
    if (IsReportRequested(kCoverage)) {
      PrintCoverageData(&range, func, code);
    }
    if (IsReportRequested(kPossibleBreakpoints)) {
      PrintPossibleBreakpointsData(&range, func, code);
    }
    if (IsReportRequested(kProfile)) {
      ProfileFunction* profile_function = profile_.FindFunction(func);
      if ((profile_function != NULL) &&
          (profile_function->NumSourcePositions() > 0)) {
        PrintProfileData(&range, profile_function);
      }
    }
  }
}

void SourceReport::VisitField(JSONArray* jsarr, const Field& field) {
  if (ShouldSkipField(field) || !field.HasInitializerFunction()) return;
  const Function& func = Function::Handle(field.InitializerFunction());
  VisitFunction(jsarr, func);
}

void SourceReport::VisitLibrary(JSONArray* jsarr, const Library& lib) {
  Class& cls = Class::Handle(zone());
  Array& functions = Array::Handle(zone());
  Array& fields = Array::Handle(zone());
  Function& func = Function::Handle(zone());
  Field& field = Field::Handle(zone());
  Script& script = Script::Handle(zone());
  ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
  while (it.HasNext()) {
    cls = it.GetNextClass();
    if (!cls.is_finalized()) {
      if (compile_mode_ == kForceCompile) {
        Error& err = Error::Handle(cls.EnsureIsFinalized(thread()));
        if (!err.IsNull()) {
          // Emit an uncompiled range for this class with error information.
          JSONObject range(jsarr);
          script = cls.script();
          range.AddProperty("scriptIndex", GetScriptIndex(script));
          range.AddProperty("startPos", cls.token_pos());
          range.AddProperty("endPos", cls.end_token_pos());
          range.AddProperty("compiled", false);
          range.AddProperty("error", err);
          continue;
        }
        ASSERT(cls.is_finalized());
      } else {
        cls.EnsureDeclarationLoaded();
        // Emit one range for the whole uncompiled class.
        JSONObject range(jsarr);
        script = cls.script();
        range.AddProperty("scriptIndex", GetScriptIndex(script));
        range.AddProperty("startPos", cls.token_pos());
        range.AddProperty("endPos", cls.end_token_pos());
        range.AddProperty("compiled", false);
        continue;
      }
    }

    functions = cls.current_functions();
    for (int i = 0; i < functions.Length(); i++) {
      func ^= functions.At(i);
      // Skip getter functions of static const field.
      if (func.kind() == FunctionLayout::kImplicitStaticGetter) {
        field ^= func.accessor_field();
        if (field.is_const() && field.is_static()) {
          continue;
        }
      }
      VisitFunction(jsarr, func);
    }

    fields = cls.fields();
    for (intptr_t i = 0; i < fields.Length(); i++) {
      field ^= fields.At(i);
      VisitField(jsarr, field);
    }
  }
}

void SourceReport::VisitClosures(JSONArray* jsarr) {
  const GrowableObjectArray& closures = GrowableObjectArray::Handle(
      thread()->isolate()->object_store()->closure_functions());

  // We need to keep rechecking the length of the closures array, as handling
  // a closure potentially adds new entries to the end.
  Function& func = Function::Handle(zone());
  for (int i = 0; i < closures.Length(); i++) {
    func ^= closures.At(i);
    VisitFunction(jsarr, func);
  }
}

void SourceReport::PrintJSON(JSONStream* js,
                             const Script& script,
                             TokenPosition start_pos,
                             TokenPosition end_pos) {
  Init(Thread::Current(), &script, start_pos, end_pos);

  JSONObject report(js);
  report.AddProperty("type", "SourceReport");
  {
    JSONArray ranges(&report, "ranges");

    const GrowableObjectArray& libs = GrowableObjectArray::Handle(
        zone(), thread()->isolate()->object_store()->libraries());

    // We only visit the libraries which actually load the specified script.
    Library& lib = Library::Handle(zone());
    for (int i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      if (script.IsNull() || ScriptIsLoadedByLibrary(script, lib)) {
        VisitLibrary(&ranges, lib);
      }
    }

    // Visit all closures for this isolate.
    VisitClosures(&ranges);

    // Output constant coverage if coverage is requested.
    if (IsReportRequested(kCoverage)) {
      // Find all scripts. We need to go though all scripts because a script
      // (even one we don't want) can add coverage to another library (i.e.
      // potentially one we want).
      DirectChainedHashMap<ScriptTableTrait> local_script_table;
      GrowableArray<ScriptTableEntry*> local_script_table_entries;
      CollectAllScripts(&local_script_table, &local_script_table_entries);
      CollectConstConstructorCoverageFromScripts(&local_script_table_entries,
                                                 &ranges);
      CleanupCollectedScripts(&local_script_table, &local_script_table_entries);
    }
  }

  // Print the script table.
  JSONArray scripts(&report, "scripts");
  PrintScriptTable(&scripts);
}

void SourceReport::CollectAllScripts(
    DirectChainedHashMap<ScriptTableTrait>* local_script_table,
    GrowableArray<ScriptTableEntry*>* local_script_table_entries) {
  ScriptTableEntry wrapper;
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      zone(), thread()->isolate()->object_store()->libraries());
  Library& lib = Library::Handle(zone());
  Script& scriptRef = Script::Handle(zone());
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    const Array& scripts = Array::Handle(zone(), lib.LoadedScripts());
    for (intptr_t j = 0; j < scripts.Length(); j++) {
      scriptRef ^= scripts.At(j);
      const String& url = String::Handle(zone(), scriptRef.url());
      wrapper.key = &url;
      wrapper.script = &Script::Handle(zone(), scriptRef.raw());
      ScriptTableEntry* pair = local_script_table->LookupValue(&wrapper);
      if (pair != NULL) {
        // Existing one.
        continue;
      }
      // New one. Insert.
      ScriptTableEntry* tmp = new ScriptTableEntry();
      tmp->key = &url;
      tmp->index = next_script_index_++;
      tmp->script = wrapper.script;
      local_script_table_entries->Add(tmp);
      local_script_table->Insert(tmp);
    }
  }
}

void SourceReport::CleanupCollectedScripts(
    DirectChainedHashMap<ScriptTableTrait>* local_script_table,
    GrowableArray<ScriptTableEntry*>* local_script_table_entries) {
  for (intptr_t i = 0; i < local_script_table_entries->length(); i++) {
    delete local_script_table_entries->operator[](i);
    local_script_table_entries->operator[](i) = NULL;
  }
  local_script_table_entries->Clear();
  local_script_table->Clear();
}

void SourceReport::CollectConstConstructorCoverageFromScripts(
    GrowableArray<ScriptTableEntry*>* local_script_table_entries,
    JSONArray* ranges) {
  // Now output the wanted constant coverage.
  for (intptr_t i = 0; i < local_script_table_entries->length(); i++) {
    const Script* script = local_script_table_entries->At(i)->script;

    // Whether we want *this* script or not we need to look at the constant
    // constructor coverage. Any of those could be in a script we *do* want.
    {
      Script& scriptRef = Script::Handle(zone());
      const Array& constructors =
          Array::Handle(kernel::CollectConstConstructorCoverageFrom(*script));
      intptr_t constructors_count = constructors.Length();
      Function& constructor = Function::Handle(zone());
      Code& code = Code::Handle(zone());
      for (intptr_t i = 0; i < constructors_count; i++) {
        constructor ^= constructors.At(i);
        // Check if we want coverage for this constructor.
        if (ShouldSkipFunction(constructor)) {
          continue;
        }
        scriptRef ^= constructor.script();
        code ^= constructor.unoptimized_code();
        const TokenPosition begin_pos = constructor.token_pos();
        const TokenPosition end_pos = constructor.end_token_pos();
        JSONObject range(ranges);
        range.AddProperty("scriptIndex", GetScriptIndex(scriptRef));
        range.AddProperty("compiled",
                          !code.IsNull());  // Does this make a difference?
        range.AddProperty("startPos", begin_pos);
        range.AddProperty("endPos", end_pos);

        JSONObject cov(&range, "coverage");
        {
          JSONArray hits(&cov, "hits");
          hits.AddValue(begin_pos);
        }
        {
          JSONArray misses(&cov, "misses");
          // No misses
        }
      }
    }
  }
}

}  // namespace dart
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
