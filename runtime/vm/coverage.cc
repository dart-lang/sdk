// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coverage.h"

#include "include/dart_api.h"

#include "vm/compiler.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(charp, coverage_dir, NULL,
            "Enable writing coverage data into specified directory.");


class CoverageFilterAll : public CoverageFilter {
 public:
  bool ShouldOutputCoverageFor(const Library& lib,
                               const String& script_url,
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
                                 const JSONArray& hits_arr,
                                 const GrowableArray<intptr_t>& pos_to_line) {
  Isolate* isolate = Isolate::Current();
  if (!function.HasCode()) {
    // If the function should not be compiled or if the compilation failed,
    // then just skip this method.
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
    const Error& err = Error::Handle(
        isolate, Compiler::CompileFunction(isolate, function));
    if (!err.IsNull()) {
      return;
    }
  }
  ASSERT(function.HasCode());

  // Print the hit counts for all IC datas.
  ZoneGrowableArray<const ICData*>* ic_data_array =
      new(isolate) ZoneGrowableArray<const ICData*>();
  function.RestoreICDataMap(ic_data_array);
  const Code& code = Code::Handle(function.unoptimized_code());
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      code.pc_descriptors());

  const intptr_t begin_pos = function.token_pos();
  const intptr_t end_pos = function.end_token_pos();
  intptr_t last_line = -1;
  intptr_t last_count = 0;
  // Only IC based calls have counting.
  PcDescriptors::Iterator iter(descriptors,
      RawPcDescriptors::kIcCall | RawPcDescriptors::kUnoptStaticCall);
  while (iter.HasNext()) {
    HANDLESCOPE(isolate);
    const RawPcDescriptors::PcDescriptorRec& rec = iter.Next();
    intptr_t deopt_id = rec.deopt_id;
    const ICData* ic_data = (*ic_data_array)[deopt_id];
    if (!ic_data->IsNull()) {
      intptr_t token_pos = rec.token_pos;
      // Filter out descriptors that do not map to tokens in the source code.
      if ((token_pos < begin_pos) || (token_pos > end_pos)) {
        continue;
      }
      intptr_t line = pos_to_line[token_pos];
#if defined(DEBUG)
      const Script& script = Script::Handle(function.script());
      intptr_t test_line = -1;
      script.GetTokenLocation(token_pos, &test_line, NULL);
      ASSERT(test_line == line);
#endif
      // Merge hit data where possible.
      if (last_line == line) {
        last_count += ic_data->AggregateCount();
      } else {
        if (last_line != -1) {
          hits_arr.AddValue(last_line);
          hits_arr.AddValue(last_count);
        }
        last_count = ic_data->AggregateCount();
        last_line = line;
      }
    }
  }
  // Write last hit value if needed.
  if (last_line != -1) {
    hits_arr.AddValue(last_line);
    hits_arr.AddValue(last_count);
  }
}


void CodeCoverage::PrintClass(const Library& lib,
                              const Class& cls,
                              const JSONArray& jsarr,
                              CoverageFilter* filter) {
  Isolate* isolate = Isolate::Current();
  if (cls.EnsureIsFinalized(isolate) != Error::null()) {
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
    HANDLESCOPE(isolate);
    function ^= functions.At(i);
    script = function.script();
    saved_url = script.url();
    if (!filter->ShouldOutputCoverageFor(lib, saved_url, cls, function)) {
      i++;
      continue;
    }
    ComputeTokenPosToLineNumberMap(script, &pos_to_line);
    JSONObject jsobj(&jsarr);
    jsobj.AddProperty("source", saved_url.ToCString());
    jsobj.AddProperty("script", script);
    JSONArray hits_arr(&jsobj, "hits");

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
      CompileAndAdd(function, hits_arr, pos_to_line);
      if (function.HasImplicitClosureFunction()) {
        function = function.ImplicitClosureFunction();
        CompileAndAdd(function, hits_arr, pos_to_line);
      }
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
      HANDLESCOPE(isolate);
      function ^= closures.At(i);
      script = function.script();
      saved_url = script.url();
      if (!filter->ShouldOutputCoverageFor(lib, saved_url, cls, function)) {
        i++;
        continue;
      }
      ComputeTokenPosToLineNumberMap(script, &pos_to_line);
      JSONObject jsobj(&jsarr);
      jsobj.AddProperty("source", saved_url.ToCString());
      jsobj.AddProperty("script", script);
      JSONArray hits_arr(&jsobj, "hits");

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
        CompileAndAdd(function, hits_arr, pos_to_line);
        i++;
      }
    }
  }
}


void CodeCoverage::Write(Isolate* isolate) {
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
  PrintJSON(isolate, &stream, NULL);

  const char* format = "%s/dart-cov-%" Pd "-%" Pd ".json";
  intptr_t pid = OS::ProcessId();
  intptr_t len = OS::SNPrint(NULL, 0, format,
                             FLAG_coverage_dir, pid, isolate->main_port());
  char* filename = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
  OS::SNPrint(filename, len + 1, format,
              FLAG_coverage_dir, pid, isolate->main_port());
  void* file = (*file_open)(filename, true);
  if (file == NULL) {
    OS::Print("Failed to write coverage file: %s\n", filename);
    return;
  }
  (*file_write)(stream.buffer()->buf(), stream.buffer()->length(), file);
  (*file_close)(file);
}


void CodeCoverage::PrintJSON(Isolate* isolate,
                             JSONStream* stream,
                             CoverageFilter* filter) {
  CoverageFilterAll default_filter;
  if (filter == NULL) {
    filter = &default_filter;
  }
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      isolate, isolate->object_store()->libraries());
  Library& lib = Library::Handle();
  Class& cls = Class::Handle();
  JSONObject coverage(stream);
  coverage.AddProperty("type", "CodeCoverage");
  coverage.AddProperty("id", "coverage");
  {
    JSONArray jsarr(&coverage, "coverage");
    for (int i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
      while (it.HasNext()) {
        cls = it.GetNextClass();
        ASSERT(!cls.IsNull());
        PrintClass(lib, cls, jsarr, filter);
      }
    }
  }
}


}  // namespace dart
