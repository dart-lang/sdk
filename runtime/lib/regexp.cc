// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/regexp_parser.h"

#include "lib/regexp_jsc.h"

namespace dart {

DECLARE_FLAG(bool, trace_irregexp);
DEFINE_FLAG(bool, use_jscre, true, "Use the JSCRE regular expression engine");


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_factory, 4) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, pattern, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Instance, handle_multi_line, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Instance, handle_case_sensitive, arguments->NativeArgAt(3));
  bool ignore_case = handle_case_sensitive.raw() != Bool::True().raw();
  bool multi_line = handle_multi_line.raw() == Bool::True().raw();

  if (FLAG_use_jscre) {
    return Jscre::Compile(pattern, multi_line, ignore_case);
  }
  // Parse the pattern once in order to throw any format exceptions within
  // the factory constructor. It is parsed again upon compilation.
  RegExpCompileData compileData;
  if (!RegExpParser::ParseRegExp(pattern, multi_line, &compileData)) {
    // Parsing failures throw an exception.
    UNREACHABLE();
  }

  // Create a JSRegExp object containing only the initial parameters.
  return RegExpEngine::CreateJSRegExp(isolate,
                                      pattern,
                                      multi_line,
                                      ignore_case);
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getPattern, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return regexp.pattern();
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getIsMultiLine, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(regexp.is_multi_line()).raw();
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getIsCaseSensitive, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(!regexp.is_ignore_case()).raw();
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getGroupCount, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  if (regexp.is_initialized()) {
    return regexp.num_bracket_expressions();
  }
  const String& pattern = String::Handle(regexp.pattern());
  const String& errmsg = String::Handle(
      String::New("Regular expression is not initialized yet. "));
  const String& message = String::Handle(String::Concat(errmsg, pattern));
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kFormat, args);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_ExecuteMatch, 3) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, str, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_index, arguments->NativeArgAt(2));

  if (FLAG_use_jscre) {
    return Jscre::Execute(regexp, str, start_index.Value());
  }

  // This function is intrinsified. See Intrinsifier::JSRegExp_ExecuteMatch.
  const intptr_t cid = str.GetClassId();

  // Retrieve the cached function.
  const Function& fn = Function::Handle(regexp.function(cid));
  ASSERT(!fn.IsNull());

  // And finally call the generated code.
  return IRRegExpMacroAssembler::Execute(fn, str, start_index, isolate);
}

}  // namespace dart
