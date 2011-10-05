// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/exceptions.h"

#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/stack_frame.h"

namespace dart {

DEFINE_FLAG(bool, print_stack_trace_at_throw, false,
    "Prints a stack trace everytime a throw occurs.");

// Iterate through the stack frames and try to find a frame with an
// exception handler. Once found, set the pc, sp and fp so that execution
// can continue in that frame.
static bool FindExceptionHandler(uword* handler_pc,
                                 uword* handler_sp,
                                 uword* handler_fp,
                                 GrowableArray<uword>* stack_frame_pcs) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);
  while (!frame->IsEntryFrame()) {
    if (frame->IsDartFrame()) {
      stack_frame_pcs->Add(frame->pc());
      DartFrame* dart_frame = reinterpret_cast<DartFrame*>(frame);
      if (dart_frame->FindExceptionHandler(handler_pc)) {
        *handler_sp = frame->sp();
        *handler_fp = frame->fp();
        return true;
      }
    }
    frame = frames.NextFrame();
    ASSERT(frame != NULL);
  }
  ASSERT(frame->IsEntryFrame());
  *handler_pc = frame->pc();
  *handler_sp = frame->sp();
  *handler_fp = frame->fp();
  return false;
}


static void ThrowExceptionHelper(const Instance& exception,
                                 const Instance& existing_stacktrace) {
  uword handler_pc = 0;
  uword handler_sp = 0;
  uword handler_fp = 0;
  GrowableArray<uword> stack_frame_pcs;
  bool handler_exists = FindExceptionHandler(&handler_pc,
                                             &handler_sp,
                                             &handler_fp,
                                             &stack_frame_pcs);
  // TODO(5411263): At some point we can optimize by figuring out if a
  // stack trace is needed based on whether the catch code specifies a
  // stack trace object or there is a rethrow in the catch clause.
  ASSERT(stack_frame_pcs.length() > 0);  // At least one dart frame must exist.
  Stacktrace& stacktrace = Stacktrace::Handle();
  if (existing_stacktrace.IsNull()) {
    stacktrace = Stacktrace::New(stack_frame_pcs);
  } else {
    stacktrace ^= existing_stacktrace.raw();
    stacktrace.Append(stack_frame_pcs);
  }
  if (FLAG_print_stack_trace_at_throw) {
    OS::Print("Exception '%s' thrown:\n", exception.ToCString());
    OS::Print("%s\n", stacktrace.ToCString());
  }
  if (handler_exists) {
    // Found a dart handler for the exception, jump to it.
    CPU::JumpToExceptionHandler(handler_pc,
                                handler_sp,
                                handler_fp,
                                exception,
                                stacktrace);
  } else {
    // No dart exception handler found in this invocation sequence,
    // so we create an unhandled exception object and return to the
    // invocation stub so that it returns this unhandled exception
    // object. The C++ code which invoked this dart sequence can check
    // and do the appropriate thing (rethrow the exception to the
    // dart invocation sequence above it, print diagnostics and terminate
    // the isolate etc.).
    const UnhandledException& unhandled_exception = UnhandledException::Handle(
        UnhandledException::New(exception, stacktrace));
    CPU::JumpToUnhandledExceptionHandler(handler_pc,
                                         handler_sp,
                                         handler_fp,
                                         unhandled_exception);
  }
  UNREACHABLE();
}


void Exceptions::Throw(const Instance& exception) {
  ASSERT(!exception.IsNull());
  ThrowExceptionHelper(exception, Instance::Handle());
}


void Exceptions::ReThrow(const Instance& exception,
                         const Instance& stacktrace) {
  ASSERT(!exception.IsNull());
  ThrowExceptionHelper(exception, stacktrace);
}


void Exceptions::ThrowByType(
    ExceptionType type, const GrowableArray<const Object*>& arguments) {
  const Instance& exception = Instance::Handle(Create(type, arguments));
  Throw(exception);
}


RawInstance* Exceptions::Create(
    ExceptionType type, const GrowableArray<const Object*>& arguments) {
  String& class_name = String::Handle();
  switch (type) {
    case kIndexOutOfRange:
      class_name = String::NewSymbol("IndexOutOfRangeException");
      break;
    case kIllegalArgument:
      class_name = String::NewSymbol("IllegalArgumentException");
      break;
    case kNoSuchMethod:
      class_name = String::NewSymbol("NoSuchMethodException");
      break;
    case kClosureArgumentMismatch:
      class_name = String::NewSymbol("ClosureArgumentMismatchException");
      break;
    case kObjectNotClosure:
      class_name = String::NewSymbol("ObjectNotClosureException");
      break;
    case kBadNumberFormat:
      class_name = String::NewSymbol("BadNumberFormatException");
      break;
    case kStackOverflow:
      class_name = String::NewSymbol("StackOverflowException");
      break;
    case kWrongArgumentCount:
      class_name = String::NewSymbol("WrongArgumentCountException");
      break;
    case kInternalError:
      class_name = String::NewSymbol("InternalError");
      break;
    case kNullPointer:
      class_name = String::NewSymbol("NullPointerException");
      break;
    case kIllegalJSRegExp:
      class_name = String::NewSymbol("IllegalJSRegExpException");
      break;
  }

  return DartLibraryCalls::ExceptionCreate(class_name, arguments);
}

}  // namespace dart
