// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// This file encapsulates all the interaction with the
// JSC regular expression library also referred to as pcre

#include "lib/regexp_jsc.h"

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "third_party/jscre/pcre.h"

namespace dart {

static uint16_t* GetTwoByteData(const String& str) {
  StackZone* zone = Isolate::Current()->current_zone();
  uint16_t* two_byte_str = zone->Alloc<uint16_t>(str.Length());
  for (intptr_t i = 0; i < str.Length(); i++) {
    two_byte_str[i] = str.CharAt(i);
  }
  return two_byte_str;
}


static void* JSREMalloc(size_t size) {
  intptr_t regexp_size = static_cast<intptr_t>(size);
  ASSERT(regexp_size > 0);
  const JSRegExp& new_regex = JSRegExp::Handle(JSRegExp::New(size));
  return new_regex.GetDataStartAddress();
}


static void JSREFree(void* ptr) {
  USE(ptr);  // Do nothing, memory is garbage collected.
}


static void ThrowExceptionOnError(const String& pattern,
                                  const char* error_msg) {
  if (error_msg == NULL) {
    error_msg = "Unknown regexp compile error";
  }
  const String& errmsg = String::Handle(String::New(error_msg));
  GrowableArray<const Object*> args;
  args.Add(&pattern);
  args.Add(&errmsg);
  Exceptions::ThrowByType(Exceptions::kIllegalJSRegExp, args);
}


RawJSRegExp* Jscre::Compile(const String& pattern,
                            bool multi_line,
                            bool ignore_case) {
  // First convert the pattern to UTF16 format as the jscre library expects
  // strings to be in UTF16 encoding.
  uint16_t* two_byte_pattern = GetTwoByteData(pattern);

  // A Dart regexp is always global.
  bool is_global = true;
  // Parse the flags.
  jscre::JSRegExpIgnoreCaseOption jscre_ignore_case = ignore_case ?
      jscre::JSRegExpIgnoreCase : jscre::JSRegExpDoNotIgnoreCase;
  jscre::JSRegExpMultilineOption jscre_multi_line = multi_line ?
      jscre::JSRegExpMultiline : jscre::JSRegExpSingleLine;

  // Compile the regex by calling into the jscre library.
  uint32_t num_bracket_expressions = 0;
  const char* error_msg = NULL;
  jscre::JSRegExp* jscregexp = jscre::jsRegExpCompile(two_byte_pattern,
                                                      pattern.Length(),
                                                      jscre_ignore_case,
                                                      jscre_multi_line,
                                                      &num_bracket_expressions,
                                                      &error_msg,
                                                      &JSREMalloc,
                                                      &JSREFree);

  if (jscregexp == NULL) {
    // There was an error compiling the regex, Throw an exception.
    ThrowExceptionOnError(pattern, error_msg);
    UNREACHABLE();
    return JSRegExp::null();
  } else {
    // Setup the compiled regex object and return it.
    JSRegExp& regexp =
        JSRegExp::Handle(JSRegExp::FromDataStartAddress(jscregexp));
    regexp.set_pattern(pattern);
    if (jscre_multi_line == jscre::JSRegExpMultiline) {
      regexp.set_is_multi_line();
    }
    if (jscre_ignore_case == jscre::JSRegExpIgnoreCase) {
      regexp.set_is_ignore_case();
    }
    if (is_global) {
      regexp.set_is_global();
    }
    regexp.set_is_complex();  // Always use jscre library.
    regexp.set_num_bracket_expressions(num_bracket_expressions);
    return regexp.raw();
  }
}


RawArray* Jscre::Execute(const JSRegExp& regex,
                         const String& str,
                         intptr_t start_index) {
  // First convert the input str to UTF16 format as the jscre library expects
  // strings to be in UTF16 encoding.
  uint16_t* two_byte_str = GetTwoByteData(str);

  // Execute a regex match by calling into the jscre library.
  jscre::JSRegExp* jscregexp =
      reinterpret_cast<jscre::JSRegExp*>(regex.GetDataStartAddress());
  ASSERT(jscregexp != NULL);
  const Smi& num_bracket_exprs = Smi::Handle(regex.num_bracket_expressions());
  intptr_t num_bracket_expressions = num_bracket_exprs.Value();
  StackZone* zone = Isolate::Current()->current_zone();
  // The jscre library rounds the passed in size to a multiple of 3 in order
  // to reuse the passed in offsets array as a temporary chunk of working
  // storage during matching, so we just pass in a size which is a multiple
  // of 3.
  const int kJscreMultiple = 3;
  int offsets_length = (num_bracket_expressions + 1) * kJscreMultiple;
  int* offsets = NULL;
  offsets = zone->Alloc<int>(offsets_length);
  int retval = jscre::jsRegExpExecute(jscregexp,
                                      two_byte_str,
                                      str.Length(),
                                      start_index,
                                      offsets,
                                      offsets_length);

  // The KJS JavaScript engine returns null (ie, a failed match) when
  // JSRE's internal match limit is exceeded.  We duplicate that behavior here.
  if (retval == jscre::JSRegExpErrorNoMatch
      || retval == jscre::JSRegExpErrorHitLimit) {
    return Array::null();
  }

  // Other JSRE errors:
  if (retval < 0) {
    const String& pattern = String::Handle(regex.pattern());
    const int kErrorLength = 256;
    char error_msg[kErrorLength];
    OS::SNPrint(error_msg, kErrorLength,
                "jscre::jsRegExpExecute error : %d", retval);
    ThrowExceptionOnError(pattern, error_msg);
    UNREACHABLE();
    return Array::null();
  }

  const int kMatchPair = 2;
  Array& array =
      Array::Handle(Array::New(kMatchPair * (num_bracket_expressions + 1)));
  // The matches come in (start, end + 1) pairs for each bracketted expression.
  Smi& start = Smi::Handle();
  Smi& end = Smi::Handle();
  for (intptr_t i = 0;
       i < (kMatchPair * (num_bracket_expressions + 1));
       i += kMatchPair) {
    start = Smi::New(offsets[i]);
    end = Smi::New(offsets[i + 1]);
    array.SetAt(i, start);
    array.SetAt(i+1, end);
  }
  return array.raw();
}

}  // namespace dart
