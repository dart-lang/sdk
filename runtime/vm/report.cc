// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/report.h"

#include "vm/code_patcher.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, silent_warnings, false, "Silence warnings.");
DEFINE_FLAG(bool, warning_as_error, false, "Treat warnings as errors.");

RawString* Report::PrependSnippet(Kind kind,
                                  const Script& script,
                                  TokenPosition token_pos,
                                  bool report_after_token,
                                  const String& message) {
  const char* message_header;
  switch (kind) {
    case kWarning:
      message_header = "warning";
      break;
    case kError:
      message_header = "error";
      break;
    case kMalformedType:
      message_header = "malformed type";
      break;
    case kMalboundedType:
      message_header = "malbounded type";
      break;
    case kBailout:
      message_header = "bailout";
      break;
    default:
      message_header = "";
      UNREACHABLE();
  }
  String& result = String::Handle();
  if (!script.IsNull()) {
    const String& script_url = String::Handle(script.url());
    if (token_pos.IsReal()) {
      intptr_t line, column, token_len;
      script.GetTokenLocation(token_pos, &line, &column, &token_len);
      if (report_after_token) {
        column += token_len;
      }
      // Only report the line position if we have the original source. We still
      // need to get a valid column so that we can report the ^ mark below the
      // snippet.
      // Allocate formatted strings in old space as they may be created during
      // optimizing compilation. Those strings are created rarely and should not
      // polute old space.
      if (script.HasSource()) {
        result = String::NewFormatted(
            Heap::kOld, "'%s': %s: line %" Pd " pos %" Pd ": ",
            script_url.ToCString(), message_header, line, column);
      } else {
        result =
            String::NewFormatted(Heap::kOld, "'%s': %s: line %" Pd ": ",
                                 script_url.ToCString(), message_header, line);
      }
      // Append the formatted error or warning message.
      const Array& strs = Array::Handle(Array::New(6, Heap::kOld));
      strs.SetAt(0, result);
      strs.SetAt(1, message);
      // Append the source line.
      const String& script_line =
          String::Handle(script.GetLine(line, Heap::kOld));
      ASSERT(!script_line.IsNull());
      strs.SetAt(2, Symbols::NewLine());
      strs.SetAt(3, script_line);
      strs.SetAt(4, Symbols::NewLine());
      // Append the column marker.
      const String& column_line = String::Handle(String::NewFormatted(
          Heap::kOld, "%*s\n", static_cast<int>(column), "^"));
      strs.SetAt(5, column_line);
      result = String::ConcatAll(strs, Heap::kOld);
    } else {
      // Token position is unknown.
      result = String::NewFormatted(
          Heap::kOld, "'%s': %s: ", script_url.ToCString(), message_header);
      result = String::Concat(result, message, Heap::kOld);
    }
  } else {
    // Script is unknown.
    // Append the formatted error or warning message.
    result = String::NewFormatted(Heap::kOld, "%s: ", message_header);
    result = String::Concat(result, message, Heap::kOld);
  }
  return result.raw();
}

void Report::LongJump(const Error& error) {
  Thread::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}

void Report::LongJumpF(const Error& prev_error,
                       const Script& script,
                       TokenPosition token_pos,
                       const char* format,
                       ...) {
  va_list args;
  va_start(args, format);
  LongJumpV(prev_error, script, token_pos, format, args);
  va_end(args);
  UNREACHABLE();
}

void Report::LongJumpV(const Error& prev_error,
                       const Script& script,
                       TokenPosition token_pos,
                       const char* format,
                       va_list args) {
  const Error& error = Error::Handle(LanguageError::NewFormattedV(
      prev_error, script, token_pos, Report::AtLocation, kError, Heap::kOld,
      format, args));
  LongJump(error);
  UNREACHABLE();
}

void Report::MessageF(Kind kind,
                      const Script& script,
                      TokenPosition token_pos,
                      bool report_after_token,
                      const char* format,
                      ...) {
  va_list args;
  va_start(args, format);
  MessageV(kind, script, token_pos, report_after_token, format, args);
  va_end(args);
}

void Report::MessageV(Kind kind,
                      const Script& script,
                      TokenPosition token_pos,
                      bool report_after_token,
                      const char* format,
                      va_list args) {
  if (kind < kError) {
    // Reporting a warning.
    if (FLAG_silent_warnings) {
      return;
    }
    if (!FLAG_warning_as_error) {
      const String& msg = String::Handle(String::NewFormattedV(format, args));
      const String& snippet_msg = String::Handle(
          PrependSnippet(kind, script, token_pos, report_after_token, msg));
      OS::Print("%s", snippet_msg.ToCString());
      return;
    }
  }
  // Reporting an error (or a warning as error).
  const Error& error = Error::Handle(LanguageError::NewFormattedV(
      Error::Handle(),  // No previous error.
      script, token_pos, report_after_token, kind, Heap::kOld, format, args));
  LongJump(error);
  UNREACHABLE();
}

}  // namespace dart
