// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/canonical_tables.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/regexp/regexp_assembler_bytecode.h"
#include "vm/regexp/regexp_parser.h"
#include "vm/reusable_handles.h"
#include "vm/symbols.h"
#include "vm/thread.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/regexp/regexp_assembler_ir.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_NATIVE_ENTRY(RegExp_factory, 0, 6) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, pattern, arguments->NativeArgAt(1));

  bool multi_line = arguments->NativeArgAt(2) == Bool::True().ptr();
  bool ignore_case = arguments->NativeArgAt(3) != Bool::True().ptr();
  bool unicode = arguments->NativeArgAt(4) == Bool::True().ptr();
  bool dot_all = arguments->NativeArgAt(5) == Bool::True().ptr();

  RegExpFlags flags;
  flags.SetGlobal();  // All dart regexps are global.
  if (ignore_case) flags.SetIgnoreCase();
  if (multi_line) flags.SetMultiLine();
  if (unicode) flags.SetUnicode();
  if (dot_all) flags.SetDotAll();

  RegExpKey lookup_key(pattern, flags);
  RegExp& regexp = RegExp::Handle(thread->zone());
  {
    REUSABLE_OBJECT_HANDLESCOPE(thread);
    REUSABLE_SMI_HANDLESCOPE(thread);
    REUSABLE_WEAK_ARRAY_HANDLESCOPE(thread);
    Object& key = thread->ObjectHandle();
    Smi& value = thread->SmiHandle();
    WeakArray& data = thread->WeakArrayHandle();
    data = thread->isolate_group()->object_store()->regexp_table();
    CanonicalRegExpSet table(&key, &value, &data);
    regexp ^= table.GetOrNull(lookup_key);
    table.Release();
    if (!regexp.IsNull()) {
      return regexp.ptr();
    }
  }

  // Parse the pattern once in order to throw any format exceptions within
  // the factory constructor. It is parsed again upon compilation.
  RegExpCompileData compileData;
  // Throws an exception on parsing failure.
  RegExpParser::ParseRegExp(pattern, flags, &compileData);

  {
    RegExpKey lookup_symbol_key(String::Handle(Symbols::New(thread, pattern)),
                                flags);
    SafepointMutexLocker ml(thread->isolate_group()->symbols_mutex());
    CanonicalRegExpSet table(
        thread->zone(),
        thread->isolate_group()->object_store()->regexp_table());
    regexp ^= table.InsertNewOrGet(lookup_symbol_key);
    thread->isolate_group()->object_store()->set_regexp_table(table.Release());
  }

  ASSERT(regexp.flags() == flags);
  return regexp.ptr();
}

DEFINE_NATIVE_ENTRY(RegExp_getPattern, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return regexp.pattern();
}

DEFINE_NATIVE_ENTRY(RegExp_getIsMultiLine, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(regexp.flags().IsMultiLine()).ptr();
}

DEFINE_NATIVE_ENTRY(RegExp_getIsUnicode, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(regexp.flags().IsUnicode()).ptr();
}

DEFINE_NATIVE_ENTRY(RegExp_getIsDotAll, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(regexp.flags().IsDotAll()).ptr();
}

DEFINE_NATIVE_ENTRY(RegExp_getIsCaseSensitive, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  return Bool::Get(!regexp.flags().IgnoreCase()).ptr();
}

DEFINE_NATIVE_ENTRY(RegExp_getGroupCount, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  if (regexp.is_initialized()) {
    return Smi::New(regexp.num_bracket_expressions());
  }
  const String& pattern = String::Handle(regexp.pattern());
  const String& errmsg =
      String::Handle(String::New("Regular expression is not initialized yet."));
  const String& message = String::Handle(String::Concat(errmsg, pattern));
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kFormat, args);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(RegExp_getGroupNameMap, 0, 1) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  if (regexp.is_initialized()) {
    return regexp.capture_name_map();
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

static ObjectPtr ExecuteMatch(Zone* zone,
                              NativeArguments* arguments,
                              bool sticky) {
  const RegExp& regexp = RegExp::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(!regexp.IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, subject, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start_index, arguments->NativeArgAt(2));

  // Both generated code and the interpreter are using 32-bit registers and
  // 32-bit backtracking stack so they can't work with strings which are
  // larger than that. Validate these assumptions before running the regexp.
  if (!Utils::IsInt(32, subject.Length())) {
    Exceptions::ThrowRangeError("length",
                                Integer::Handle(Integer::New(subject.Length())),
                                0, kMaxInt32);
  }
  if (!Utils::IsInt(32, start_index.Value())) {
    Exceptions::ThrowRangeError("start_index", Integer::Cast(start_index),
                                kMinInt32, kMaxInt32);
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!FLAG_interpret_irregexp) {
    return IRRegExpMacroAssembler::Execute(regexp, subject, start_index,
                                           /*sticky=*/sticky, zone);
  }
#endif
  return BytecodeRegExpMacroAssembler::Interpret(regexp, subject, start_index,
                                                 /*sticky=*/sticky, zone);
}

DEFINE_NATIVE_ENTRY(RegExp_ExecuteMatch, 0, 3) {
  // This function is intrinsified. See Intrinsifier::RegExp_ExecuteMatch.
  return ExecuteMatch(zone, arguments, /*sticky=*/false);
}

DEFINE_NATIVE_ENTRY(RegExp_ExecuteMatchSticky, 0, 3) {
  // This function is intrinsified. See Intrinsifier::RegExp_ExecuteMatchSticky.
  return ExecuteMatch(zone, arguments, /*sticky=*/true);
}

}  // namespace dart
