// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/exceptions.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

// Allow the use of ASan (AddressSanitizer). This is needed as ASan needs to be
// told about areas where the VM does the equivalent of a long-jump.
#if defined(__has_feature)
#if __has_feature(address_sanitizer)
extern "C" void __asan_unpoison_memory_region(void *, size_t);
#else  // __has_feature(address_sanitizer)
void __asan_unpoison_memory_region(void* ignore1, size_t ignore2) {}
#endif  // __has_feature(address_sanitizer)
#else  // defined(__has_feature)
void __asan_unpoison_memory_region(void* ignore1, size_t ignore2) {}
#endif  // defined(__has_feature)


namespace dart {

DEFINE_FLAG(bool, print_stacktrace_at_throw, false,
            "Prints a stack trace everytime a throw occurs.");
DEFINE_FLAG(bool, heap_profile_out_of_memory, false,
            "Writes a heap profile on unhandled out-of-memory exceptions.");
DEFINE_FLAG(bool, verbose_stacktrace, false,
    "Stack traces will include methods marked invisible.");

const char* Exceptions::kCastErrorDstName = "type cast";


class StacktraceBuilder : public ValueObject {
 public:
  StacktraceBuilder() { }
  virtual ~StacktraceBuilder() { }

  virtual void AddFrame(const Function& func,
                        const Code& code,
                        const Smi& offset,
                        bool is_catch_frame) = 0;

  virtual bool FullStacktrace() const = 0;
};


class RegularStacktraceBuilder : public StacktraceBuilder {
 public:
  explicit RegularStacktraceBuilder(bool full_stacktrace)
      : func_list_(GrowableObjectArray::Handle(GrowableObjectArray::New())),
        code_list_(GrowableObjectArray::Handle(GrowableObjectArray::New())),
        pc_offset_list_(
            GrowableObjectArray::Handle(GrowableObjectArray::New())),
        catch_func_list_(
            full_stacktrace ?
                GrowableObjectArray::Handle(GrowableObjectArray::New()) :
                GrowableObjectArray::Handle()),
        catch_code_list_(
            full_stacktrace ?
                GrowableObjectArray::Handle(GrowableObjectArray::New()) :
                GrowableObjectArray::Handle()),
        catch_pc_offset_list_(
            full_stacktrace ?
                GrowableObjectArray::Handle(GrowableObjectArray::New()) :
                GrowableObjectArray::Handle()),
        full_stacktrace_(full_stacktrace) { }
  ~RegularStacktraceBuilder() { }

  const GrowableObjectArray& func_list() const { return func_list_; }
  const GrowableObjectArray& code_list() const { return code_list_; }
  const GrowableObjectArray& pc_offset_list() const { return pc_offset_list_; }
  const GrowableObjectArray& catch_func_list() const {
    return catch_func_list_;
  }
  const GrowableObjectArray& catch_code_list() const {
    return catch_code_list_;
  }
  const GrowableObjectArray& catch_pc_offset_list() const {
    return catch_pc_offset_list_;
  }
  virtual bool FullStacktrace() const { return full_stacktrace_; }

  virtual void AddFrame(const Function& func,
                        const Code& code,
                        const Smi& offset,
                        bool is_catch_frame) {
    if (is_catch_frame) {
      catch_func_list_.Add(func);
      catch_code_list_.Add(code);
      catch_pc_offset_list_.Add(offset);
    } else {
      func_list_.Add(func);
      code_list_.Add(code);
      pc_offset_list_.Add(offset);
    }
  }

 private:
  const GrowableObjectArray& func_list_;
  const GrowableObjectArray& code_list_;
  const GrowableObjectArray& pc_offset_list_;
  const GrowableObjectArray& catch_func_list_;
  const GrowableObjectArray& catch_code_list_;
  const GrowableObjectArray& catch_pc_offset_list_;
  bool full_stacktrace_;

  DISALLOW_COPY_AND_ASSIGN(RegularStacktraceBuilder);
};


class PreallocatedStacktraceBuilder : public StacktraceBuilder {
 public:
  explicit PreallocatedStacktraceBuilder(const Stacktrace& stacktrace)
      : stacktrace_(stacktrace),
        cur_index_(0) {
    ASSERT(stacktrace_.raw() ==
           Isolate::Current()->object_store()->preallocated_stack_trace());
  }
  ~PreallocatedStacktraceBuilder() { }

  virtual void AddFrame(const Function& func,
                        const Code& code,
                        const Smi& offset,
                        bool is_catch_frame);

  virtual bool FullStacktrace() const { return false; }

 private:
  static const int kNumTopframes = 3;

  const Stacktrace& stacktrace_;
  intptr_t cur_index_;

  DISALLOW_COPY_AND_ASSIGN(PreallocatedStacktraceBuilder);
};


void PreallocatedStacktraceBuilder::AddFrame(const Function& func,
                                             const Code& code,
                                             const Smi& offset,
                                             bool is_catch_frame) {
  if (cur_index_ >= Stacktrace::kPreallocatedStackdepth) {
    // The number of frames is overflowing the preallocated stack trace object.
    Function& frame_func = Function::Handle();
    Code& frame_code = Code::Handle();
    Smi& frame_offset = Smi::Handle();
    intptr_t start = Stacktrace::kPreallocatedStackdepth - (kNumTopframes - 1);
    intptr_t null_slot = start - 2;
    // Add an empty slot to indicate the overflow so that the toString
    // method can account for the overflow.
    if (stacktrace_.FunctionAtFrame(null_slot) != Function::null()) {
      stacktrace_.SetFunctionAtFrame(null_slot, frame_func);
      stacktrace_.SetCodeAtFrame(null_slot, frame_code);
    }
    // Move frames one slot down so that we can accomadate the new frame.
    for (intptr_t i = start; i < Stacktrace::kPreallocatedStackdepth; i++) {
      intptr_t prev = (i - 1);
      frame_func = stacktrace_.FunctionAtFrame(i);
      frame_code = stacktrace_.CodeAtFrame(i);
      frame_offset = stacktrace_.PcOffsetAtFrame(i);
      stacktrace_.SetFunctionAtFrame(prev, frame_func);
      stacktrace_.SetCodeAtFrame(prev, frame_code);
      stacktrace_.SetPcOffsetAtFrame(prev, frame_offset);
    }
    cur_index_ = (Stacktrace::kPreallocatedStackdepth - 1);
  }
  stacktrace_.SetFunctionAtFrame(cur_index_, func);
  stacktrace_.SetCodeAtFrame(cur_index_, code);
  stacktrace_.SetPcOffsetAtFrame(cur_index_, offset);
  cur_index_ += 1;
}


static bool ShouldShowFunction(const Function& function) {
  if (FLAG_verbose_stacktrace) {
    return true;
  }
  return function.is_visible();
}


static void BuildStackTrace(StacktraceBuilder* builder) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Function& func = Function::Handle();
  Code& code = Code::Handle();
  Smi& offset = Smi::Handle();
  bool dart_handler_found = false;
  bool handler_pc_set = false;
  while (frame != NULL) {
    while (!frame->IsEntryFrame()) {
      if (frame->IsDartFrame()) {
        code = frame->LookupDartCode();
        if (code.is_optimized()) {
          // For optimized frames, extract all the inlined functions if any
          // into the stack trace.
          for (InlinedFunctionsIterator it(frame); !it.Done(); it.Advance()) {
            func = it.function();
            code = it.code();
            uword pc = it.pc();
            ASSERT(pc != 0);
            ASSERT(code.EntryPoint() <= pc);
            ASSERT(pc < (code.EntryPoint() + code.Size()));
            if (ShouldShowFunction(func)) {
              offset = Smi::New(pc - code.EntryPoint());
              builder->AddFrame(func, code, offset, dart_handler_found);
            }
          }
        } else {
          offset = Smi::New(frame->pc() - code.EntryPoint());
          func = code.function();
          if (ShouldShowFunction(func)) {
            builder->AddFrame(func, code, offset, dart_handler_found);
          }
        }
        bool needs_stacktrace = false;
        bool is_catch_all = false;
        uword handler_pc = kUwordMax;
        if (!handler_pc_set &&
            frame->FindExceptionHandler(&handler_pc,
                                        &needs_stacktrace,
                                        &is_catch_all)) {
          handler_pc_set = true;
          dart_handler_found = true;
          if (!builder->FullStacktrace()) {
            return;
          }
        }
      }
      frame = frames.NextFrame();
      ASSERT(frame != NULL);
    }
    ASSERT(frame->IsEntryFrame());
    if (!handler_pc_set) {
      handler_pc_set = true;
      if (!builder->FullStacktrace()) {
        return;
      }
    }
    frame = frames.NextFrame();
  }
}


// Iterate through the stack frames and try to find a frame with an
// exception handler. Once found, set the pc, sp and fp so that execution
// can continue in that frame. Sets 'needs_stacktrace' if there is no
// cath-all handler or if a stack-trace is specified in the catch.
static bool FindExceptionHandler(uword* handler_pc,
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
      if (frame->FindExceptionHandler(&temp_handler_pc,
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


static void JumpToExceptionHandler(uword program_counter,
                                   uword stack_pointer,
                                   uword frame_pointer,
                                   const Object& exception_object,
                                   const Object& stacktrace_object) {
  // The no_gc StackResource is unwound through the tear down of
  // stack resources below.
  NoGCScope no_gc;
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
                                raw_exception, raw_stacktrace);
#else
  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }

  // Call a stub to set up the exception object in kExceptionObjectReg,
  // to set up the stacktrace object in kStackTraceObjectReg, and to
  // continue execution at the given pc in the given frame.
  typedef void (*ExcpHandler)(uword, uword, uword, RawObject*, RawObject*);
  ExcpHandler func = reinterpret_cast<ExcpHandler>(
      StubCode::JumpToExceptionHandlerEntryPoint());

  // Unpoison the stack before we tear it down in the generated stub code.
  uword current_sp = reinterpret_cast<uword>(&program_counter) - 1024;
  __asan_unpoison_memory_region(reinterpret_cast<void*>(current_sp),
                                stack_pointer - current_sp);
  func(program_counter, stack_pointer, frame_pointer,
       raw_exception, raw_stacktrace);
#endif
  UNREACHABLE();
}


static RawField* LookupStacktraceField(const Instance& instance) {
  Isolate* isolate = Isolate::Current();
  Class& error_class = Class::Handle(isolate,
                                     isolate->object_store()->error_class());
  if (error_class.IsNull()) {
    const Library& core_lib = Library::Handle(isolate, Library::CoreLibrary());
    error_class = core_lib.LookupClass(Symbols::Error(), NULL);
    ASSERT(!error_class.IsNull());
    isolate->object_store()->set_error_class(error_class);
  }
  const Class& instance_class = Class::Handle(isolate, instance.clazz());
  Error& malformed_type_error = Error::Handle(isolate);
  if (instance_class.IsSubtypeOf(Object::null_abstract_type_arguments(),
                                 error_class,
                                 Object::null_abstract_type_arguments(),
                                 &malformed_type_error)) {
    ASSERT(malformed_type_error.IsNull());
    return error_class.LookupInstanceField(Symbols::_stackTrace());
  }
  return Field::null();
}


static void ThrowExceptionHelper(const Instance& incoming_exception,
                                 const Instance& existing_stacktrace) {
  bool use_preallocated_stacktrace = false;
  Isolate* isolate = Isolate::Current();
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
  Stacktrace& stacktrace = Stacktrace::Handle(isolate);
  bool handler_exists = false;
  bool handler_needs_stacktrace = false;
  if (use_preallocated_stacktrace) {
    stacktrace ^= isolate->object_store()->preallocated_stack_trace();
    PreallocatedStacktraceBuilder frame_builder(stacktrace);
    handler_exists = FindExceptionHandler(&handler_pc,
                                          &handler_sp,
                                          &handler_fp,
                                          &handler_needs_stacktrace);
    if (handler_needs_stacktrace) {
      BuildStackTrace(&frame_builder);
    }
  } else {
    // Get stacktrace field of class Error.
    const Field& stacktrace_field =
        Field::Handle(isolate, LookupStacktraceField(exception));
    bool full_stacktrace = !stacktrace_field.IsNull();
    handler_exists = FindExceptionHandler(&handler_pc,
                                          &handler_sp,
                                          &handler_fp,
                                          &handler_needs_stacktrace);
    Array& func_array = Array::Handle(isolate, Object::empty_array().raw());
    Array& code_array = Array::Handle(isolate, Object::empty_array().raw());
    Array& pc_offset_array =
        Array::Handle(isolate, Object::empty_array().raw());
    if (handler_needs_stacktrace || full_stacktrace) {
      RegularStacktraceBuilder frame_builder(full_stacktrace);
      BuildStackTrace(&frame_builder);

      // Create arrays for function, code and pc_offset triplet of each frame.
      func_array = Array::MakeArray(frame_builder.func_list());
      code_array = Array::MakeArray(frame_builder.code_list());
      pc_offset_array = Array::MakeArray(frame_builder.pc_offset_list());
      if (!stacktrace_field.IsNull()) {
        // This is an error object and we need to capture the full stack trace
        // here implicitly, so we set up the stack trace. The stack trace field
        // is set only once, it is not overriden.
        const Array& catch_func_array = Array::Handle(isolate,
            Array::MakeArray(frame_builder.catch_func_list()));
        const Array& catch_code_array = Array::Handle(isolate,
            Array::MakeArray(frame_builder.catch_code_list()));
        const Array& catch_pc_offset_array = Array::Handle(isolate,
            Array::MakeArray(frame_builder.catch_pc_offset_list()));
        stacktrace = Stacktrace::New(func_array, code_array, pc_offset_array);
        stacktrace.SetCatchStacktrace(catch_func_array,
                                      catch_code_array,
                                      catch_pc_offset_array);
        if (exception.GetField(stacktrace_field) == Object::null()) {
          exception.SetField(stacktrace_field, stacktrace);
        }
      }  // if stacktrace needed.
    }
    if (existing_stacktrace.IsNull()) {
      stacktrace = Stacktrace::New(func_array, code_array, pc_offset_array);
    } else {
      stacktrace ^= existing_stacktrace.raw();
      if (pc_offset_array.Length() != 0) {
        stacktrace.Append(func_array, code_array, pc_offset_array);
      }
      // Since we are re throwing and appending to the existing stack trace
      // we clear out the catch trace collected in the existing stack trace
      // as that trace will not be valid anymore.
      stacktrace.SetCatchStacktrace(Object::empty_array(),
                                    Object::empty_array(),
                                    Object::empty_array());
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
    JumpToExceptionHandler(handler_pc,
                           handler_sp,
                           handler_fp,
                           exception,
                           stacktrace);
  } else {
    if (FLAG_heap_profile_out_of_memory) {
      if (exception.raw() == isolate->object_store()->out_of_memory()) {
        isolate->heap()->ProfileToFile("out-of-memory");
      }
    }
    // No dart exception handler found in this invocation sequence,
    // so we create an unhandled exception object and return to the
    // invocation stub so that it returns this unhandled exception
    // object. The C++ code which invoked this dart sequence can check
    // and do the appropriate thing (rethrow the exception to the
    // dart invocation sequence above it, print diagnostics and terminate
    // the isolate etc.).
    const UnhandledException& unhandled_exception = UnhandledException::Handle(
        UnhandledException::New(exception, stacktrace));
    stacktrace = Stacktrace::null();
    JumpToExceptionHandler(handler_pc,
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
  Class& cls = Class::Handle(core_lib.LookupClass(cls_name, NULL));
  ASSERT(!cls.IsNull());
  // There are no parameterized error types, so no need to set type arguments.
  return Instance::New(cls);
}


// Allocate, initialize, and throw a TypeError or CastError.
void Exceptions::CreateAndThrowTypeError(intptr_t location,
                                         const String& src_type_name,
                                         const String& dst_type_name,
                                         const String& dst_name,
                                         const String& malformed_error) {
  const Array& args = Array::Handle(Array::New(7));

  ExceptionType exception_type =
      dst_name.Equals(kCastErrorDstName) ? kCast : kType;

  DartFrameIterator iterator;
  const Script& script = Script::Handle(GetCallerScript(&iterator));
  intptr_t line, column;
  script.GetTokenLocation(location, &line, &column);
  // Initialize '_url', '_line', and '_column' arguments.
  args.SetAt(0, String::Handle(script.url()));
  args.SetAt(1, Smi::Handle(Smi::New(line)));
  args.SetAt(2, Smi::Handle(Smi::New(column)));

  // Initialize '_srcType', '_dstType', '_dstName', and '_malformedError'.
  args.SetAt(3, src_type_name);
  args.SetAt(4, dst_type_name);
  args.SetAt(5, dst_name);
  args.SetAt(6, malformed_error);

  // Type errors in the core library may be difficult to diagnose.
  // Print type error information before throwing the error when debugging.
  if (FLAG_print_stacktrace_at_throw) {
    if (!malformed_error.IsNull()) {
      OS::Print("%s\n", malformed_error.ToCString());
    }
    intptr_t line, column;
    script.GetTokenLocation(location, &line, &column);
    OS::Print("'%s': Failed type check: line %" Pd " pos %" Pd ": ",
              String::Handle(script.url()).ToCString(), line, column);
    if (!dst_name.IsNull() && (dst_name.Length() > 0)) {
      OS::Print("type '%s' is not a subtype of type '%s' of '%s'.\n",
                src_type_name.ToCString(),
                dst_type_name.ToCString(),
                dst_name.ToCString());
    } else {
      OS::Print("malformed type used.\n");
    }
  }
  // Throw TypeError or CastError instance.
  Exceptions::ThrowByType(exception_type, args);
  UNREACHABLE();
}


void Exceptions::Throw(const Instance& exception) {
  Isolate* isolate = Isolate::Current();
  isolate->debugger()->SignalExceptionThrown(exception);
  // Null object is a valid exception object.
  ThrowExceptionHelper(exception, Instance::Handle(isolate));
}


void Exceptions::ReThrow(const Instance& exception,
                         const Instance& stacktrace) {
  // Null object is a valid exception object.
  ThrowExceptionHelper(exception, stacktrace);
}


void Exceptions::PropagateError(const Error& error) {
  ASSERT(Isolate::Current()->top_exit_frame_info() != 0);
  if (error.IsUnhandledException()) {
    // If the error object represents an unhandled exception, then
    // rethrow the exception in the normal fashion.
    const UnhandledException& uhe = UnhandledException::Cast(error);
    const Instance& exc = Instance::Handle(uhe.exception());
    const Instance& stk = Instance::Handle(uhe.stacktrace());
    Exceptions::ReThrow(exc, stk);
  } else {
    // Return to the invocation stub and return this error object.  The
    // C++ code which invoked this dart sequence can check and do the
    // appropriate thing.
    uword handler_pc = 0;
    uword handler_sp = 0;
    uword handler_fp = 0;
    FindErrorHandler(&handler_pc, &handler_sp, &handler_fp);
    JumpToExceptionHandler(handler_pc, handler_sp, handler_fp, error,
                           Stacktrace::Handle());  // Null stacktrace.
  }
  UNREACHABLE();
}


void Exceptions::ThrowByType(ExceptionType type, const Array& arguments) {
  const Object& result = Object::Handle(Create(type, arguments));
  if (result.IsError()) {
    // We got an error while constructing the exception object.
    // Propagate the error instead of throwing the exception.
    PropagateError(Error::Cast(result));
  } else {
    ASSERT(result.IsInstance());
    Throw(Instance::Cast(result));
  }
}


void Exceptions::ThrowOOM() {
  Isolate* isolate = Isolate::Current();
  const Instance& oom = Instance::Handle(
      isolate, isolate->object_store()->out_of_memory());
  Throw(oom);
}


void Exceptions::ThrowStackOverflow() {
  Isolate* isolate = Isolate::Current();
  const Instance& stack_overflow = Instance::Handle(
      isolate, isolate->object_store()->stack_overflow());
  Throw(stack_overflow);
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
    case kArgument:
      library = Library::CoreLibrary();
      class_name = &Symbols::ArgumentError();
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
    case kInternalError:
      library = Library::CoreLibrary();
      class_name = &Symbols::InternalError();
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
    case kMirroredUncaughtExceptionError:
      library = Library::MirrorsLibrary();
      class_name = &Symbols::MirroredUncaughtExceptionError();
      break;
    case kMirroredCompilationError:
      library = Library::MirrorsLibrary();
      class_name = &Symbols::MirroredCompilationError();
      break;
  }

  return DartLibraryCalls::InstanceCreate(library,
                                          *class_name,
                                          *constructor_name,
                                          arguments);
}

}  // namespace dart
