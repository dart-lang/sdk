// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coverage.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, print_coverage, false, "Print code coverage.");

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
    if (function.HasCode()) {
      JSONObject jsobj(&jsarr);

      script = function.script();
      url = script.url();
      name = function.QualifiedUserVisibleName();
      jsobj.AddProperty("source", url.ToCString());
      jsobj.AddProperty("function", name.ToCString());

      code = function.unoptimized_code();
      ic_array = code.ExtractTypeFeedbackArray();
      descriptors = code.pc_descriptors();

      JSONArray jsarr(&jsobj, "hits");
      for (int j = 0; j < descriptors.Length(); j++) {
        PcDescriptors::Kind kind = descriptors.DescriptorKind(j);
        // Only IC based calls have counting.
        if ((kind == PcDescriptors::kIcCall) ||
            (kind == PcDescriptors::kUnoptStaticCall)) {
          intptr_t deopt_id = descriptors.DeoptId(j);
          ic_data ^= ic_array.At(deopt_id);
          if (!ic_data.IsNull() && (ic_data.AggregateCount() > 0)) {
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
    }
  }
}


void CodeCoverage::Print(Isolate* isolate) {
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

  OS::Print("### COVERAGE DATA ###\n"
            "%s\n"
            "### END ###\n", stream.ToCString());
}

}  // namespace dart
