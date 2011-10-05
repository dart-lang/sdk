// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/assert.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

#include "lib/regexp_jsc.h"

namespace dart {

DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_factory, 3) {
  ASSERT(TypeArguments::CheckedHandle(arguments->At(0)).IsNull());
  const String& pattern = String::CheckedHandle(arguments->At(1));
  const String& flags = String::CheckedHandle(arguments->At(2));
  const JSRegExp& new_regex = JSRegExp::Handle(Jscre::Compile(pattern, flags));
  arguments->SetReturn(new_regex);
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getPattern, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->At(0));
  const String& result = String::Handle(regexp.pattern());
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getFlags, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->At(0));
  const String& result = String::Handle(String::New(regexp.Flags()));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_getGroupCount, 1) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->At(0));
  if (regexp.is_initialized()) {
    const Smi& result = Smi::Handle(regexp.num_bracket_expressions());
    arguments->SetReturn(result);
    return;
  }
  const String& pattern = String::Handle(regexp.pattern());
  const String& errmsg =
      String::Handle(String::New("Regular expression is not initialized yet"));
  GrowableArray<const Object*> args;
  args.Add(&pattern);
  args.Add(&errmsg);
  Exceptions::ThrowByType(Exceptions::kIllegalJSRegExp, args);
}


DEFINE_NATIVE_ENTRY(JSSyntaxRegExp_ExecuteMatch, 3) {
  const JSRegExp& regexp = JSRegExp::CheckedHandle(arguments->At(0));
  const String& str = String::CheckedHandle(arguments->At(1));
  const Smi& start_index = Smi::CheckedHandle(arguments->At(2));
  const Array& result =
      Array::Handle(Jscre::Execute(regexp, str, start_index.Value()));
  arguments->SetReturn(result);
}

}  // namespace dart
