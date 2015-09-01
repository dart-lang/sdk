// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/exceptions.h"

#include "platform/address_sanitizer.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"

namespace dart {

DEFINE_FLAG(bool, print_stacktrace_at_throw, false,
            "Prints a stack trace everytime a throw occurs.");


const char* Exceptions::kCastErrorDstName = "type cast";


class StacktraceBuilder : public ValueObject {
 public:
  StacktraceBuilder() { }
  virtual ~StacktraceBuilder() { }

  virtual void AddFrame(const Code& code, const Smi& offset) = 0;
};


class RegularStacktraceBuilder : public StacktraceBuilder {
 public:
  explicit RegularStacktraceBuilder(Isolate* isolate)
      : code_list_(
          GrowableObjectArray::Handle(isolate, GrowableObjectArray::New())),
        pc_offset_list_(
          GrowableObjectArray::Handle(isolate, GrowableObjectArray::New())) { }
  ~RegularStacktraceBuilder() { }

  const GrowableObjectArray& code_list() const { return code_list_; }
  const GrowableObjectArray& pc_offset_list() const { return pc_offset_list_; }

  virtual void AddFrame(const Code& code, const Smi& offset) {
    code_list_.Add(code);
    pc_offset_list_.Add(offset);
  }

 private:
  const GrowableObjectArray& code_list_;
  const GrowableObjectArray& pc_offset_list_;

  DISALLOW_COPY_AND_ASSIGN(RegularStacktraceBuilder);
};


class PreallocatedStacktraceBuilder : public StacktraceBuilder {
 public:
  explicit PreallocatedStacktraceBuilder(const Instance& stacktrace)
  : stacktrace_(Stacktrace::Cast(stacktrace)),
        cur_index_(0) {
    ASSERT(stacktrace_.raw() ==
           Isolate::Current()->object_store()->preallocated_stack_trace());
  }
  ~PreallocatedStacktraceBuilder() { }

  virtual void AddFrame(const Code& code, const Smi& offset);

 private:
  static const int kNumTopframes = Stacktrace::kPreallocatedStackdepth / 2;

  const Stacktrace& stacktrace_;
  intptr_t cur_index_;

  DISALLOW_COPY_AND_ASSIGN(PreallocatedStacktraceBuilder);
};


void PreallocatedStacktraceBuilder::AddFrame(const Code& code,
                                             const Smi& offset) {
  if (cur_index_ >= Stacktrace::kPreallocatedStackdepth) {
    // The number of frames is overflowing the preallocated stack trace object.
    Code& frame_code = Code::Handle();
    Smi& frame_offset = Smi::Handle();
    intptr_t start = Stacktrace::kPreallocatedStackdepth - (kNumTopframes - 1);
    intptr_t null_slot = start - 2;
    // Add an empty slot to indicate the overflow so that the toString
    // method can account for the overflow.
    if (stacktrace_.FunctionAtFrame(null_slot) != Function::null()) {
      stacktrace_.SetCodeAtFrame(null_slot, frame_code);
    }
    // Move frames one slot down so that we can accomodate the new frame.
    for (intptr_t i = start; i < Stacktrace::kPreallocatedStackdepth; i++) {
      intptr_t prev = (i - 1);
      frame_code = stacktrace_.CodeAtFrame(i);
      frame_offset = stacktrace_.PcOffsetAtFrame(i);
      stacktrace_.SetCodeAtFrame(prev, frame_code);
      stacktrace_.SetPcOffsetAtFrame(prev, frame_offset);
    }
    cur_index_ = (Stacktrace::kPreallocatedStackdepth - 1);
  }
  stacktrace_.SetCodeAtFrame(cur_index_, code);
  stacktrace_.SetPcOffsetAtFrame(cur_index_, offset);
  cur_index_ += 1;
}


static void BuildStackTrace(Isolate* isolate, StacktraceBuilder* builder) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle();
  Smi& offset = Smi::Handle();
  while (frame != NULL) {
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      offset = Smi::New(frame->pc() - code.EntryPoint());
      builder->AddFrame(code, offset);
    }
    frame = frames.NextFrame();
  }
}


// Iterate through the stack frames and try to find a frame with an
// exception handler. Once found, set the pc, sp and fp so that execution
// can continue in that frame. Sets 'needs_stacktrace' if there is no
// cath-all handler or if a stack-trace is specified in the catch.
static bool FindExceptionHandler(Isolate* isolate,
                                 uword* handler_pc,
                                 uword* handler_sp,
                                 uword* handler_fp,
                                 bool* needs_stacktrace) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  bool handler_pc_set = false;
  *needs_stacktrace = false;
  bool is_catch_all = false;
  uword temp_handler_pc = kUwordMax;
  while (!frame->IsEntryFrame()) {
    if (frame->IsDartFrame()) {
      if (frame->FindExceptionHandler(isolate,
                                      &temp_handler_pc,
                                      needs_stacktrace,
                                      &is_catch_all)) {
        if (!handler_pc_set) {
          handler_pc_set = true;
          *handler_pc = temp_handler_pc;
          *handler_sp = frame->sp();
          *handler_fp = frame->fp();
        }
        if (*needs_stacktrace || is_catch_all) {
          return true;
        }
      }
    }  // if frame->IsDartFrame
    frame = frames.NextFrame();
    ASSERT(frame != NULL);
  }  // while !frame->IsEntryFrame
  ASSERT(frame->IsEntryFrame());
  if (!handler_pc_set) {
    *handler_pc = frame->pc();
    *handler_sp = frame->sp();
    *handler_fp = frame->fp();
  }
  // No catch-all encountered, needs stacktrace.
  *needs_stacktrace = true;
  return handler_pc_set;
}


static void FindErrorHandler(uword* handler_pc,
                             uword* handler_sp,
                             uword* handler_fp) {
  // TODO(turnidge): Is there a faster way to get the next entry frame?
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);
  while (!frame->IsEntryFrame()) {
    frame = frames.NextFrame();
    ASSERT(frame != NULL);
  }
  ASSERT(frame->IsEntryFrame());
  *handler_pc = frame->pc();
  *handler_sp = frame->sp();
  *handler_fp = frame->fp();
}


static void JumpToExceptionHandler(Thread* thread,
                                   uword program_counter,
                                   uword stack_pointer,
                                   uword frame_pointer,
                                   const Object& exception_object,
                                   const Object& stacktrace_object) {
  // The no_gc StackResource is unwound through the tear down of
  // stack resources below.
  NoSafepointScope no_safepoint;
  RawObject* raw_exception = exception_object.raw();
  RawObject* raw_stacktrace = stacktrace_object.raw();

#if defined(USING_SIMULATOR)
  // Unwinding of the C++ frames and destroying of their stack resources is done
  // by the simulator, because the target stack_pointer is a simulated stack
  // pointer and not the C++ stack pointer.

  // Continue simulating at the given pc in the given frame after setting up the
  // exception object in the kExceptionObjectReg register and the stacktrace
  // object (may be raw null) in the kStackTraceObjectReg register.

  Simulator::Current()->Longjmp(program_counter, stack_pointer, frame_pointer,
                                raw_exception, raw_stacktrace, thread);
#else
  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  StackResource::Unwind(thread);

  // Call a stub to set up the exception object in kExceptionObjectReg,
  // to set up the stacktrace object in kStackTraceObjectReg, and to
  // continue execution at the given pc in the given frame.
  typedef void (*ExcpHandler)(uword, uword, uword, RawObject*, RawObject*,
                              Thread*);
  ExcpHandler func = reinterpret_cast<ExcpHandler>(
      StubCode::JumpToExceptionHandler_entry()->EntryPoint());

  // Unpoison the stack before we tear it down in the generated stub code.
  uword current_sp = Isolate::GetCurrentStackPointer() - 1024;
  ASAN_UNPOISON(reinterpret_cast<void*>(current_sp),
                stack_pointer - current_sp);

  func(program_counter, stack_pointer, frame_pointer,
       raw_exception, raw_stacktrace, thread);
#endif
  UNREACHABLE();
}


static RawField* LookupStacktraceField(const Instance& instance) {
  if (instance.GetClassId() < kNumPredefinedCids) {
    // 'class Error' is not a predefined class.
    return Field::null();
  }
  Isolate* isolate = Isolate::Current();
  Class& error_class = Class::Handle(isolate,
                                     isolate->object_store()->error_class());
  if (error_class.IsNull()) {
    const Library& core_lib = Library::Handle(isolate, Library::CoreLibrary());
    error_class = core_lib.LookupClass(Symbols::Error());
    ASSERT(!error_class.IsNull());
    isolate->object_store()->set_error_class(error_class);
  }
  // If instance class extends 'class Error' return '_stackTrace' field.
  Class& test_class = Class::Handle(isolate, instance.clazz());
  AbstractType& type = AbstractType::Handle(isolate, AbstractType::null());
  while (true) {
    if (test_class.raw() == error_class.raw()) {
      return error_class.LookupInstanceField(Symbols::_stackTrace());
    }
    type = test_class.super_type();
    if (type.IsNull()) return Field::null();
    test_class = type.type_class();
  }
  UNREACHABLE();
  return Field::null();
}


RawStacktrace* Exceptions::CurrentStacktrace() {
  Isolate* isolate = Isolate::Current();
  RegularStacktraceBuilder frame_builder(isolate);
  BuildStackTrace(isolate, &frame_builder);

  // Create arrays for code and pc_offset tuples of each frame.
  const Array& full_code_array = Array::Handle(isolate,
      Array::MakeArray(frame_builder.code_list()));
  const Array& full_pc_offset_array = Array::Handle(isolate,
      Array::MakeArray(frame_builder.pc_offset_list()));
  const Stacktrace& full_stacktrace = Stacktrace::Handle(
      Stacktrace::New(full_code_array, full_pc_offset_array));
  return full_stacktrace.raw();
}


static void ThrowExceptionHelper(Thread* thread,
                                 const Instance& incoming_exception,
                                 const Instance& existing_stacktrace,
                                 const bool is_rethrow) {
  Isolate* isolate = thread->isolate();
  bool use_preallocated_stacktrace = false;
  Instance& exception = Instance::Handle(isolate, incoming_exception.raw());
  if (exception.IsNull()) {
    exception ^= Exceptions::Create(Exceptions::kNullThrown,
                                    Object::empty_array());
  } else if (exception.raw() == isolate->object_store()->out_of_memory() ||
             exception.raw() == isolate->object_store()->stack_overflow()) {
    use_preallocated_stacktrace = true;
  }
  uword handler_pc = 0;
  uword handler_sp = 0;
  uword handler_fp = 0;
  Instance& stacktrace = Instance::Handle(isolate);
  bool handler_exists = false;
  bool handler_needs_stacktrace = false;
  if (use_preallocated_stacktrace) {
    stacktrace ^= isolate->object_store()->preallocated_stack_trace();
    PreallocatedStacktraceBuilder frame_builder(stacktrace);
    handler_exists = FindExceptionHandler(isolate,
                                          &handler_pc,
                                          &handler_sp,
                                          &handler_fp,
                                          &handler_needs_stacktrace);
    if (handler_needs_stacktrace) {
      BuildStackTrace(isolate, &frame_builder);
    }
  } else {
    // Get stacktrace field of class Error. This is needed to determine whether
    // we have a subclass of Error which carries around its stack trace.
    const Field& stacktrace_field =
        Field::Handle(isolate, LookupStacktraceField(exception));

    // Find the exception handler and determine if the handler needs a
    // stacktrace.
    handler_exists = FindExceptionHandler(isolate,
                                          &handler_pc,
                                          &handler_sp,
                                          &handler_fp,
                                          &handler_needs_stacktrace);
    if (!existing_stacktrace.IsNull()) {
      // If we have an existing stack trace then this better be a rethrow. The
      // reverse is not necessarily true (e.g. Dart_PropagateError can cause
      // a rethrow being called without an existing stacktrace.)
      ASSERT(is_rethrow);
      ASSERT(stacktrace_field.IsNull() ||
             (exception.GetField(stacktrace_field) != Object::null()));
      stacktrace = existing_stacktrace.raw();
    } else if (!stacktrace_field.IsNull() || handler_needs_stacktrace) {
      // Collect the stacktrace if needed.
      ASSERT(existing_stacktrace.IsNull());
      stacktrace = Exceptions::CurrentStacktrace();
      // If we have an Error object, then set its stackTrace field only if it
      // not yet initialized.
      if (!stacktrace_field.IsNull() &&
          (exception.GetField(stacktrace_field) == Object::null())) {
        exception.SetField(stacktrace_field, stacktrace);
      }
    }
  }
  // We expect to find a handler_pc, if the exception is unhandled
  // then we expect to at least have the dart entry frame on the
  // stack as Exceptions::Throw should happen only after a dart
  // invocation has been done.
  ASSERT(handler_pc != 0);

  if (FLAG_print_stacktrace_at_throw) {
    OS::Print("Exception '%s' thrown:\n", exception.ToCString());
    OS::Print("%s\n", stacktrace.ToCString());
  }
  if (handler_exists) {
    // Found a dart handler for the exception, jump to it.
    JumpToExceptionHandler(thread,
                           handler_pc,
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
        isolate, UnhandledException::New(exception, stacktrace));
    stacktrace = Stacktrace::null();
    JumpToExceptionHandler(thread,
                           handler_pc,
                           handler_sp,
                           handler_fp,
                           unhandled_exception,
                           stacktrace);
  }
  UNREACHABLE();
}


// Static helpers for allocating, initializing, and throwing an error instance.

// Return the script of the Dart function that called the native entry or the
// runtime entry. The frame iterator points to the callee.
RawScript* Exceptions::GetCallerScript(DartFrameIterator* iterator) {
  StackFrame* caller_frame = iterator->NextFrame();
  ASSERT(caller_frame != NULL && caller_frame->IsDartFrame());
  const Function& caller = Function::Handle(caller_frame->LookupDartFunction());
  ASSERT(!caller.IsNull());
  return caller.script();
}


// Allocate a new instance of the given class name.
// TODO(hausner): Rename this NewCoreInstance to call out the fact that
// the class name is resolved in the core library implicitly?
RawInstance* Exceptions::NewInstance(const char* class_name) {
  const String& cls_name = String::Handle(Symbols::New(class_name));
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  // No ambiguity error expected: passing NULL.
  Class& cls = Class::Handle(core_lib.LookupClass(cls_name));
  ASSERT(!cls.IsNull());
  // There are no parameterized error types, so no need to set type arguments.
  return Instance::New(cls);
}


// Allocate, initialize, and throw a TypeError or CastError.
// If error_msg is not null, throw a TypeError, even for a type cast.
void Exceptions::CreateAndThrowTypeError(intptr_t location,
                                         const String& src_type_name,
                                         const String& dst_type_name,
                                         const String& dst_name,
                                         const String& error_msg) {
  const Array& args = Array::Handle(Array::New(7));

  ExceptionType exception_type =
      (error_msg.IsNull() && dst_name.Equals(kCastErrorDstName)) ?
          kCast : kType;

  DartFrameIterator iterator;
  const Script& script = Script::Handle(GetCallerScript(&iterator));
  intptr_t line;
  intptr_t column = -1;
  if (script.HasSource()) {
    script.GetTokenLocation(location, &line, &column);
  } else {
    script.GetTokenLocation(location, &line, NULL);
  }
  // Initialize '_url', '_line', and '_column' arguments.
  args.SetAt(0, String::Handle(script.url()));
  args.SetAt(1, Smi::Handle(Smi::New(line)));
  args.SetAt(2, Smi::Handle(Smi::New(column)));

  // Initialize '_srcType', '_dstType', '_dstName', and '_errorMsg'.
  args.SetAt(3, src_type_name);
  args.SetAt(4, dst_type_name);
  args.SetAt(5, dst_name);
  args.SetAt(6, error_msg);

  // Type errors in the core library may be difficult to diagnose.
  // Print type error information before throwing the error when debugging.
  if (FLAG_print_stacktrace_at_throw) {
    if (!error_msg.IsNull()) {
      OS::Print("%s\n", error_msg.ToCString());
    }
    OS::Print("'%s': Failed type check: line %" Pd " pos %" Pd ": ",
              String::Handle(script.url()).ToCString(), line, column);
    if (!dst_name.IsNull() && (dst_name.Length() > 0)) {
      OS::Print("type '%s' is not a subtype of type '%s' of '%s'.\n",
                src_type_name.ToCString(),
                dst_type_name.ToCString(),
                dst_name.ToCString());
    } else {
      OS::Print("type error.\n");
    }
  }
  // Throw TypeError or CastError instance.
  Exceptions::ThrowByType(exception_type, args);
  UNREACHABLE();
}


void Exceptions::Throw(Thread* thread, const Instance& exception) {
  // Do not notify debugger on stack overflow and out of memory exceptions.
  // The VM would crash when the debugger calls back into the VM to
  // get values of variables.
  Isolate* isolate = thread->isolate();
  if (exception.raw() != isolate->object_store()->out_of_memory() &&
      exception.raw() != isolate->object_store()->stack_overflow()) {
    isolate->debugger()->SignalExceptionThrown(exception);
  }
  // Null object is a valid exception object.
  ThrowExceptionHelper(thread, exception, Stacktrace::Handle(isolate), false);
}

void Exceptions::ReThrow(Thread* thread,
                         const Instance& exception,
                         const Instance& stacktrace) {
  // Null object is a valid exception object.
  ThrowExceptionHelper(thread, exception, stacktrace, true);
}


void Exceptions::PropagateError(const Error& error) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->top_exit_frame_info() != 0);
  if (error.IsUnhandledException()) {
    // If the error object represents an unhandled exception, then
    // rethrow the exception in the normal fashion.
    const UnhandledException& uhe = UnhandledException::Cast(error);
    const Instance& exc = Instance::Handle(isolate, uhe.exception());
    const Instance& stk = Instance::Handle(isolate, uhe.stacktrace());
    Exceptions::ReThrow(thread, exc, stk);
  } else {
    // Return to the invocation stub and return this error object.  The
    // C++ code which invoked this dart sequence can check and do the
    // appropriate thing.
    uword handler_pc = 0;
    uword handler_sp = 0;
    uword handler_fp = 0;
    FindErrorHandler(&handler_pc, &handler_sp, &handler_fp);
    JumpToExceptionHandler(thread, handler_pc, handler_sp, handler_fp, error,
                           Stacktrace::Handle(isolate));  // Null stacktrace.
  }
  UNREACHABLE();
}


void Exceptions::ThrowByType(ExceptionType type, const Array& arguments) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const Object& result = Object::Handle(isolate, Create(type, arguments));
  if (result.IsError()) {
    // We got an error while constructing the exception object.
    // Propagate the error instead of throwing the exception.
    PropagateError(Error::Cast(result));
  } else {
    ASSERT(result.IsInstance());
    Throw(thread, Instance::Cast(result));
  }
}


void Exceptions::ThrowOOM() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const Instance& oom = Instance::Handle(
      isolate, isolate->object_store()->out_of_memory());
  Throw(thread, oom);
}


void Exceptions::ThrowStackOverflow() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const Instance& stack_overflow = Instance::Handle(
      isolate, isolate->object_store()->stack_overflow());
  Throw(thread, stack_overflow);
}


void Exceptions::ThrowArgumentError(const Instance& arg) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, arg);
  Exceptions::ThrowByType(Exceptions::kArgument, args);
}


void Exceptions::ThrowRangeError(const char* argument_name,
                                 const Integer& argument_value,
                                 intptr_t expected_from,
                                 intptr_t expected_to) {
  const Array& args = Array::Handle(Array::New(4));
  args.SetAt(0, argument_value);
  args.SetAt(1, Integer::Handle(Integer::New(expected_from)));
  args.SetAt(2, Integer::Handle(Integer::New(expected_to)));
  args.SetAt(3, String::Handle(String::New(argument_name)));
  Exceptions::ThrowByType(Exceptions::kRangeRange, args);
}


RawObject* Exceptions::Create(ExceptionType type, const Array& arguments) {
  Library& library = Library::Handle();
  const String* class_name = NULL;
  const String* constructor_name = &Symbols::Dot();
  switch (type) {
    case kNone:
    case kStackOverflow:
    case kOutOfMemory:
      UNREACHABLE();
      break;
    case kRange:
      library = Library::CoreLibrary();
      class_name = &Symbols::RangeError();
      break;
    case kRangeRange:
      library = Library::CoreLibrary();
      class_name = &Symbols::RangeError();
      constructor_name = &Symbols::DotRange();
      break;
    case kArgument:
      library = Library::CoreLibrary();
      class_name = &Symbols::ArgumentError();
      break;
    case kArgumentValue:
      library = Library::CoreLibrary();
      class_name = &Symbols::ArgumentError();
      constructor_name = &Symbols::DotValue();
      break;
    case kNoSuchMethod:
      library = Library::CoreLibrary();
      class_name = &Symbols::NoSuchMethodError();
      constructor_name = &Symbols::DotWithType();
      break;
    case kFormat:
      library = Library::CoreLibrary();
      class_name = &Symbols::FormatException();
      break;
    case kUnsupported:
      library = Library::CoreLibrary();
      class_name = &Symbols::UnsupportedError();
      break;
    case kNullThrown:
      library = Library::CoreLibrary();
      class_name = &Symbols::NullThrownError();
      break;
    case kIsolateSpawn:
      library = Library::IsolateLibrary();
      class_name = &Symbols::IsolateSpawnException();
      break;
    case kIsolateUnhandledException:
      library = Library::IsolateLibrary();
      class_name = &Symbols::IsolateUnhandledException();
      break;
    case kJavascriptIntegerOverflowError:
      library = Library::CoreLibrary();
      class_name = &Symbols::JavascriptIntegerOverflowError();
      break;
    case kJavascriptCompatibilityError:
      library = Library::CoreLibrary();
      class_name = &Symbols::JavascriptCompatibilityError();
      break;
    case kAssertion:
      library = Library::CoreLibrary();
      class_name = &Symbols::AssertionError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kCast:
      library = Library::CoreLibrary();
      class_name = &Symbols::CastError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kType:
      library = Library::CoreLibrary();
      class_name = &Symbols::TypeError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kFallThrough:
      library = Library::CoreLibrary();
      class_name = &Symbols::FallThroughError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kAbstractClassInstantiation:
      library = Library::CoreLibrary();
      class_name = &Symbols::AbstractClassInstantiationError();
      constructor_name = &Symbols::DotCreate();
      break;
    case kCyclicInitializationError:
      library = Library::CoreLibrary();
      class_name = &Symbols::CyclicInitializationError();
  }

  return DartLibraryCalls::InstanceCreate(library,
                                          *class_name,
                                          *constructor_name,
                                          arguments);
}


// Throw JavascriptCompatibilityError exception.
void Exceptions::ThrowJavascriptCompatibilityError(const char* msg) {
  const Array& exc_args = Array::Handle(Array::New(1));
  const String& msg_str = String::Handle(String::New(msg));
  exc_args.SetAt(0, msg_str);
  Exceptions::ThrowByType(Exceptions::kJavascriptCompatibilityError, exc_args);
}

}  // namespace dart
