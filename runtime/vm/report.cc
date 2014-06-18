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

DEFINE_FLAG(int, stacktrace_depth_on_warning, 5,
            "Maximal number of stack frames to print after a runtime warning.");
DEFINE_FLAG(bool, silent_warnings, false, "Silence warnings.");
DEFINE_FLAG(bool, warn_on_javascript_compatibility, false,
            "Warn on incompatibilities between vm and dart2js.");
DEFINE_FLAG(bool, warning_as_error, false, "Treat warnings as errors.");


RawString* Report::PrependSnippet(Kind kind,
                                  const Script& script,
                                  intptr_t token_pos,
                                  const String& message) {
  const char* message_header;
  switch (kind) {
    case kWarning: message_header = "warning"; break;
    case kJSWarning: message_header = "javascript compatibility warning"; break;
    case kError: message_header = "error"; break;
    case kMalformedType: message_header = "malformed type"; break;
    case kMalboundedType: message_header = "malbounded type"; break;
    case kBailout: message_header = "bailout"; break;
    default: message_header = ""; UNREACHABLE();
  }
  String& result = String::Handle();
  if (!script.IsNull()) {
    const String& script_url = String::Handle(script.url());
    if (token_pos >= 0) {
      intptr_t line, column;
      script.GetTokenLocation(token_pos, &line, &column);
      // Only report the line position if we have the original source. We still
      // need to get a valid column so that we can report the ^ mark below the
      // snippet.
      if (script.HasSource()) {
        result = String::NewFormatted("'%s': %s: line %" Pd " pos %" Pd ": ",
                                      script_url.ToCString(),
                                      message_header,
                                      line,
                                      column);
      } else {
        result = String::NewFormatted("'%s': %s: line %" Pd ": ",
                                      script_url.ToCString(),
                                      message_header,
                                      line);
      }
      // Append the formatted error or warning message.
      result = String::Concat(result, message);
      // Append the source line.
      const String& script_line = String::Handle(script.GetLine(line));
      ASSERT(!script_line.IsNull());
      result = String::Concat(result, Symbols::NewLine());
      result = String::Concat(result, script_line);
      result = String::Concat(result, Symbols::NewLine());
      // Append the column marker.
      const String& column_line = String::Handle(
          String::NewFormatted("%*s\n", static_cast<int>(column), "^"));
      result = String::Concat(result, column_line);
    } else {
      // Token position is unknown.
      result = String::NewFormatted("'%s': %s: ",
                                    script_url.ToCString(),
                                    message_header);
      result = String::Concat(result, message);
    }
  } else {
    // Script is unknown.
    // Append the formatted error or warning message.
    result = String::NewFormatted("%s: ", message_header);
    result = String::Concat(result, message);
  }
  return result.raw();
}


void Report::LongJump(const Error& error) {
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Report::LongJumpF(const Error& prev_error,
                       const Script& script, intptr_t token_pos,
                       const char* format, ...) {
  va_list args;
  va_start(args, format);
  LongJumpV(prev_error, script, token_pos, format, args);
  va_end(args);
  UNREACHABLE();
}


void Report::LongJumpV(const Error& prev_error,
                       const Script& script, intptr_t token_pos,
                       const char* format, va_list args) {
  const Error& error = Error::Handle(LanguageError::NewFormattedV(
      prev_error, script, token_pos,
      kError, Heap::kNew,
      format, args));
  LongJump(error);
  UNREACHABLE();
}


void Report::MessageF(Kind kind, const Script& script, intptr_t token_pos,
                      const char* format, ...) {
  va_list args;
  va_start(args, format);
  MessageV(kind, script, token_pos, format, args);
  va_end(args);
}


void Report::MessageV(Kind kind, const Script& script, intptr_t token_pos,
                      const char* format, va_list args) {
  if (kind < kError) {
    // Reporting a warning.
    if (FLAG_silent_warnings) {
      return;
    }
    if (!FLAG_warning_as_error) {
      const String& msg = String::Handle(String::NewFormattedV(format, args));
      const String& snippet_msg = String::Handle(
          PrependSnippet(kind, script, token_pos, msg));
      OS::Print("%s", snippet_msg.ToCString());
      if (kind == kJSWarning) {
        TraceJSWarning(script, token_pos, msg);
        // Do not print stacktrace if we have not executed Dart code yet.
        if (Isolate::Current()->top_exit_frame_info() != 0) {
          const Stacktrace& stacktrace =
              Stacktrace::Handle(Exceptions::CurrentStacktrace());
          intptr_t idx = 0;
          OS::Print("%s", stacktrace.ToCStringInternal(
              &idx, FLAG_stacktrace_depth_on_warning));
        }
      }
      return;
    }
  }
  // Reporting an error (or a warning as error).
  const Error& error = Error::Handle(
      LanguageError::NewFormattedV(Error::Handle(),  // No previous error.
                                   script, token_pos,
                                   kind, Heap::kNew,
                                   format, args));
  if (kind == kJSWarning) {
    Exceptions::ThrowJavascriptCompatibilityError(error.ToErrorCString());
    UNREACHABLE();
  }
  LongJump(error);
  UNREACHABLE();
}


void Report::JSWarningFromNative(bool is_static_native, const char* msg) {
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  const Code& caller_code = Code::Handle(caller_frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  const uword caller_pc = caller_frame->pc();
  ICData& ic_data = ICData::Handle();
  if (is_static_native) {
    // Assume an unoptimized static call. Optimization was prevented.
    CodePatcher::GetUnoptimizedStaticCallAt(caller_pc, caller_code, &ic_data);
  } else {
    // Assume an instance call.
    CodePatcher::GetInstanceCallAt(caller_pc, caller_code, &ic_data);
  }
  ASSERT(!ic_data.IsNull());
  // Report warning only if not already reported at this location.
  if (!ic_data.IssuedJSWarning()) {
    ic_data.SetIssuedJSWarning();
    Report::JSWarningFromFrame(caller_frame, msg);
  }
}


void Report::JSWarningFromIC(const ICData& ic_data, const char* msg) {
  DartFrameIterator iterator;
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != NULL);
  // Report warning only if not already reported at this location.
  if (!ic_data.IssuedJSWarning()) {
    ic_data.SetIssuedJSWarning();
    JSWarningFromFrame(caller_frame, msg);
  }
}


void Report::JSWarningFromFrame(StackFrame* caller_frame, const char* msg) {
  ASSERT(caller_frame != NULL);
  ASSERT(FLAG_warn_on_javascript_compatibility);
  if (FLAG_silent_warnings) return;
  Isolate* isolate = Isolate::Current();
  const Code& caller_code = Code::Handle(isolate,
                                         caller_frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  const uword caller_pc = caller_frame->pc();
  const intptr_t token_pos = caller_code.GetTokenIndexOfPC(caller_pc);
  const Function& caller = Function::Handle(isolate, caller_code.function());
  const Script& script = Script::Handle(isolate, caller.script());
  MessageF(kJSWarning, script, token_pos, "%s", msg);
}


void Report::TraceJSWarning(const Script& script,
                            intptr_t token_pos,
                            const String& message) {
  const int64_t micros = OS::GetCurrentTimeMicros();
  Isolate* isolate = Isolate::Current();
  TraceBuffer* trace_buffer = isolate->trace_buffer();
  if (trace_buffer == NULL) {
    TraceBuffer::Init(isolate);
    trace_buffer = isolate->trace_buffer();
  }
  JSONStream js;
  {
    JSONObject trace_warning(&js);
    trace_warning.AddProperty("type", "JSCompatibilityWarning");
    trace_warning.AddProperty("script", script);
    trace_warning.AddProperty("tokenPos", token_pos);
    trace_warning.AddProperty("message", message);
  }
  trace_buffer->Trace(micros, js.ToCString(), true);  // Already escaped.
}

}  // namespace dart

