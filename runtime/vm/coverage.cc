// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coverage.h"

#include "include/dart_api.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(charp, coverage_dir, NULL,
            "Enable writing coverage data into specified directory.");

void CodeCoverage::PrintClass(const Class& cls, const JSONArray& jsarr) {
  const Array& functions = Array::Handle(cls.functions());
  ASSERT(!functions.IsNull());
  Function& function = Function::Handle();
  Code& code = Code::Handle();
  Script& script = Script::Handle();
  String& url = String::Handle();
  String& name = String::Handle();
  PcDescriptors& descriptors = PcDescriptors::Handle();
  Array& ic_array = Array::Handle();
  ICData& ic_data = ICData::Handle();
  for (int i = 0; i < functions.Length(); i++) {
    function ^= functions.At(i);

    JSONObject jsobj(&jsarr);
    script = function.script();
    url = script.url();
    name = function.QualifiedUserVisibleName();
    jsobj.AddProperty("source", url.ToCString());
    jsobj.AddProperty("function", name.ToCString());

    JSONArray jsarr(&jsobj, "hits");

    if (function.HasCode()) {
      // Print the hit counts for all IC datas.
      code = function.unoptimized_code();
      ic_array = code.ExtractTypeFeedbackArray();
      descriptors = code.pc_descriptors();

      for (int j = 0; j < descriptors.Length(); j++) {
        PcDescriptors::Kind kind = descriptors.DescriptorKind(j);
        // Only IC based calls have counting.
        if ((kind == PcDescriptors::kIcCall) ||
            (kind == PcDescriptors::kUnoptStaticCall)) {
          intptr_t deopt_id = descriptors.DeoptId(j);
          ic_data ^= ic_array.At(deopt_id);
          if (!ic_data.IsNull()) {
            intptr_t token_pos = descriptors.TokenPos(j);
            intptr_t line = -1;
            intptr_t col = -1;
            script.GetTokenLocation(token_pos, &line, &col);
            JSONObject ic_info(&jsarr);
            ic_info.AddProperty("line", line);
            ic_info.AddProperty("col", col);
            ic_info.AddProperty("count", ic_data.AggregateCount());
          }
        }
      }
    } else {
      // The function has no code so it was never executed and thus we add one
      // zero count hit at the first token index.
      intptr_t line = -1;
      intptr_t col = -1;
      script.GetTokenLocation(function.token_pos(), &line, &col);
      JSONObject func_info(&jsarr);
      func_info.AddProperty("line", line);
      func_info.AddProperty("col", col);
      func_info.AddProperty("count", static_cast<intptr_t>(0));
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
  {
    const GrowableObjectArray& libs = GrowableObjectArray::Handle(
        isolate, isolate->object_store()->libraries());
    Library& lib = Library::Handle();
    Class& cls = Class::Handle();
    JSONArray jsarr(&stream);
    for (int i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
      while (it.HasNext()) {
        cls = it.GetNextClass();
        if (cls.is_finalized()) {
          // Only classes that have been finalized do have a meaningful list of
          // functions.
          PrintClass(cls, jsarr);
        }
      }
    }
  }

  const char* format = "%s/dart-cov-%"Pd"-%"Pd".json";
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

}  // namespace dart
