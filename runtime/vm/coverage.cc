// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coverage.h"

#include "include/dart_api.h"

#include "vm/compiler.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(charp, coverage_dir, NULL,
            "Enable writing coverage data into specified directory.");


class CoverageFilterAll : public CoverageFilter {
 public:
  bool ShouldOutputCoverageFor(const Library& lib,
                               const Script& script,
                               const Class& cls,
                               const Function& func) const {
    return true;
  }
};


// map[token_pos] -> line-number.
static void ComputeTokenPosToLineNumberMap(const Script& script,
                                           GrowableArray<intptr_t>* map) {
  const TokenStream& tkns = TokenStream::Handle(script.tokens());
  const intptr_t len = ExternalTypedData::Handle(tkns.GetStream()).Length();
  map->SetLength(len);
#if defined(DEBUG)
  for (intptr_t i = 0; i < len; i++) {
    (*map)[i] = -1;
  }
#endif
  TokenStream::Iterator tkit(tkns, 0, TokenStream::Iterator::kAllTokens);
  intptr_t cur_line = script.line_offset() + 1;
  while (tkit.CurrentTokenKind() != Token::kEOS) {
    (*map)[tkit.CurrentPosition()] = cur_line;
    if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
      cur_line++;
    }
    tkit.Advance();
  }
}


void CodeCoverage::CompileAndAdd(const Function& function,
                                 const JSONArray& hits_or_sites,
                                 const GrowableArray<intptr_t>& pos_to_line,
                                 bool as_call_sites) {
  // If the function should not be compiled for coverage analysis, then just
  // skip this method.
  // TODO(iposva): Maybe we should skip synthesized methods in general too.
  if (function.is_abstract() || function.IsRedirectingFactory()) {
    return;
  }
  if (function.IsNonImplicitClosureFunction() &&
      (function.context_scope() == ContextScope::null())) {
    // TODO(iposva): This can arise if we attempt to compile an inner function
    // before we have compiled its enclosing function or if the enclosing
    // function failed to compile.
    return;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // Make sure we have the unoptimized code for this function available.
  if (Compiler::EnsureUnoptimizedCode(thread, function) != Error::null()) {
    // Ignore the error and this function entirely.
    return;
  }
  const Code& code = Code::Handle(zone, function.unoptimized_code());
  ASSERT(!code.IsNull());

  // Print the hit counts for all IC datas.
  ZoneGrowableArray<const ICData*>* ic_data_array =
      new(zone) ZoneGrowableArray<const ICData*>();
  function.RestoreICDataMap(ic_data_array, false /* clone descriptors */);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      zone, code.pc_descriptors());

  const intptr_t begin_pos = function.token_pos();
  const intptr_t end_pos = function.end_token_pos();
  intptr_t last_line = -1;
  intptr_t last_count = 0;
  // Only IC based calls have counting.
  PcDescriptors::Iterator iter(descriptors,
      RawPcDescriptors::kIcCall | RawPcDescriptors::kUnoptStaticCall);
  while (iter.MoveNext()) {
    HANDLESCOPE(thread);
    const ICData* ic_data = (*ic_data_array)[iter.DeoptId()];
    if (!ic_data->IsNull()) {
      const intptr_t token_pos = iter.TokenPos();
      // Filter out descriptors that do not map to tokens in the source code.
      if ((token_pos < begin_pos) || (token_pos > end_pos)) {
        continue;
      }
      if (as_call_sites) {
        bool is_static_call = iter.Kind() == RawPcDescriptors::kUnoptStaticCall;
        ic_data->PrintToJSONArray(hits_or_sites, token_pos, is_static_call);
      } else {
        intptr_t line = pos_to_line[token_pos];
#if defined(DEBUG)
        const Script& script = Script::Handle(zone, function.script());
        intptr_t test_line = -1;
        script.GetTokenLocation(token_pos, &test_line, NULL);
        ASSERT(test_line == line);
#endif
        // Merge hit data where possible.
        if (last_line == line) {
          last_count += ic_data->AggregateCount();
        } else {
          if ((last_line != -1)) {
            hits_or_sites.AddValue(last_line);
            hits_or_sites.AddValue(last_count);
          }
          last_count = ic_data->AggregateCount();
          last_line = line;
        }
      }
    }
  }
  // Write last hit value if needed.
  if (!as_call_sites && (last_line != -1)) {
    hits_or_sites.AddValue(last_line);
    hits_or_sites.AddValue(last_count);
  }
}


void CodeCoverage::PrintClass(const Library& lib,
                              const Class& cls,
                              const JSONArray& jsarr,
                              CoverageFilter* filter,
                              bool as_call_sites) {
  Thread* thread = Thread::Current();
  if (cls.EnsureIsFinalized(thread) != Error::null()) {
    // Only classes that have been finalized do have a meaningful list of
    // functions.
    return;
  }
  Array& functions = Array::Handle(cls.functions());
  ASSERT(!functions.IsNull());
  Function& function = Function::Handle();
  Script& script = Script::Handle();
  String& saved_url = String::Handle();
  String& url = String::Handle();
  GrowableArray<intptr_t> pos_to_line;
  int i = 0;
  while (i < functions.Length()) {
    HANDLESCOPE(thread);
    function ^= functions.At(i);
    script = function.script();
    saved_url = script.url();
    if (!filter->ShouldOutputCoverageFor(lib, script, cls, function)) {
      i++;
      continue;
    }
    if (!as_call_sites) {
      ComputeTokenPosToLineNumberMap(script, &pos_to_line);
    }
    JSONObject jsobj(&jsarr);
    jsobj.AddProperty("source", saved_url.ToCString());
    jsobj.AddProperty("script", script);
    JSONArray hits_or_sites(&jsobj, as_call_sites ? "callSites" : "hits");

    // We stay within this loop while we are seeing functions from the same
    // source URI.
    while (i < functions.Length()) {
      function ^= functions.At(i);
      script = function.script();
      url = script.url();
      if (!url.Equals(saved_url)) {
        pos_to_line.Clear();
        break;
      }
      if (!filter->ShouldOutputCoverageFor(lib, script, cls, function)) {
        i++;
        continue;
      }
      CompileAndAdd(function, hits_or_sites, pos_to_line, as_call_sites);
      i++;
    }
  }

  GrowableObjectArray& closures =
      GrowableObjectArray::Handle(cls.closures());
  if (!closures.IsNull()) {
    i = 0;
    pos_to_line.Clear();
    // We need to keep rechecking the length of the closures array, as handling
    // a closure potentially adds new entries to the end.
    while (i < closures.Length()) {
      HANDLESCOPE(thread);
      function ^= closures.At(i);
      script = function.script();
      saved_url = script.url();
      if (!filter->ShouldOutputCoverageFor(lib, script, cls, function)) {
        i++;
        continue;
      }
      ComputeTokenPosToLineNumberMap(script, &pos_to_line);
      JSONObject jsobj(&jsarr);
      jsobj.AddProperty("source", saved_url.ToCString());
      jsobj.AddProperty("script", script);
      JSONArray hits_or_sites(&jsobj, as_call_sites ? "callSites" : "hits");

      // We stay within this loop while we are seeing functions from the same
      // source URI.
      while (i < closures.Length()) {
        function ^= closures.At(i);
        script = function.script();
        url = script.url();
        if (!url.Equals(saved_url)) {
          pos_to_line.Clear();
          break;
        }
        CompileAndAdd(function, hits_or_sites, pos_to_line, as_call_sites);
        i++;
      }
    }
  }
}


void CodeCoverage::Write(Thread* thread) {
  if (FLAG_coverage_dir == NULL) {
    return;
  }

  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  Dart_FileWriteCallback file_write = Isolate::file_write_callback();
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  if ((file_open == NULL) || (file_write == NULL) || (file_close == NULL)) {
    return;
  }

  JSONStream stream;
  PrintJSON(thread, &stream, NULL, false);

  intptr_t pid = OS::ProcessId();
  char* filename = OS::SCreate(thread->zone(),
      "%s/dart-cov-%" Pd "-%" Pd64 ".json",
      FLAG_coverage_dir, pid, thread->isolate()->main_port());
  void* file = (*file_open)(filename, true);
  if (file == NULL) {
    OS::Print("Failed to write coverage file: %s\n", filename);
    return;
  }
  (*file_write)(stream.buffer()->buf(), stream.buffer()->length(), file);
  (*file_close)(file);
}


void CodeCoverage::PrintJSON(Thread* thread,
                             JSONStream* stream,
                             CoverageFilter* filter,
                             bool as_call_sites) {
  CoverageFilterAll default_filter;
  if (filter == NULL) {
    filter = &default_filter;
  }
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      thread->zone(),
      thread->isolate()->object_store()->libraries());
  Library& lib = Library::Handle();
  Class& cls = Class::Handle();
  JSONObject coverage(stream);
  coverage.AddProperty("type", "CodeCoverage");
  {
    JSONArray jsarr(&coverage, "coverage");
    for (int i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
      while (it.HasNext()) {
        cls = it.GetNextClass();
        ASSERT(!cls.IsNull());
        PrintClass(lib, cls, jsarr, filter, as_call_sites);
      }
    }
  }
}


}  // namespace dart
