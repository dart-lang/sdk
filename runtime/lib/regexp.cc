// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

#include "lib/regexp_jsc.h"

namespace dart {

DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_factory, 4) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, pattern, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Instance, handle_multi_line, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Instance, handle_case_sensitive, arguments->NativeArgAt(3));
  bool ignore_case = handle_case_sensitive.raw() != Bool::True().raw();
  bool multi_line = handle_multi_line.raw() == Bool::True().raw();
  return Jscre::Compile(pattern, multi_line, ignore_case);
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getPattern, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return regexp.pattern();
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getIsMultiLine, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(regexp.is_multi_line());
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getIsCaseSensitive, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(!regexp.is_ignore_case());
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getGroupCount, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  if (regexp.is_initialized()) {
    return regexp.num_bracket_expressions();
  }
  const String& pattern = String::Handle(regexp.pattern());
  const String& errmsg =
      String::Handle(String::New("Regular expression is not initialized yet"));
  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, pattern);
  args.SetAt(1, errmsg);
  Exceptions::ThrowByType(Exceptions::kIllegalJSRegExp, args);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_ExecuteMatch, 3) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, str, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_index, arguments->NativeArgAt(2));
  return Jscre::Execute(regexp, str, start_index.Value());
}

}  // namespace dart
