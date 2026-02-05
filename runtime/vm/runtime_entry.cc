// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include <memory>

#include "platform/address_sanitizer.h"
#include "platform/globals.h"
#include "platform/memory_sanitizer.h"
#include "platform/thread_sanitizer.h"
#include "vm/bootstrap.h"
#include "vm/code_descriptors.h"
#include "vm/code_patcher.h"
#include "vm/compiler/api/deopt_id.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/double_conversion.h"
#include "vm/exceptions.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/flags.h"
#include "vm/heap/verifier.h"
#include "vm/instructions.h"
#include "vm/interpreter.h"
#include "vm/kernel_isolate.h"
#include "vm/log.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/type_testing_stubs.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/marshaller.h"
#include "vm/deopt_instructions.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

static constexpr intptr_t kDefaultMaxSubtypeCacheEntries =
    SubtypeTestCache::MaxEntriesForCacheAllocatedFor(1000);
DEFINE_FLAG(
    int,
    max_subtype_cache_entries,
    kDefaultMaxSubtypeCacheEntries,
    "Maximum number of subtype cache entries (number of checks cached).");
DEFINE_FLAG(
    int,
    regexp_optimization_counter_threshold,
    1000,
    "RegExp's usage-counter value before it is optimized, -1 means never");
DEFINE_FLAG(int,
            reoptimization_counter_threshold,
            4000,
            "Counter threshold before a function gets reoptimized.");
DEFINE_FLAG(bool,
            runtime_allocate_old,
            false,
            "Use old-space for allocation via runtime calls.");
DEFINE_FLAG(bool,
            runtime_allocate_spill_tlab,
            false,
            "Ensure results of allocation via runtime calls are not in an "
            "active TLAB.");
DEFINE_FLAG(bool, trace_deoptimization, false, "Trace deoptimization");
DEFINE_FLAG(bool,
            trace_deoptimization_verbose,
            false,
            "Trace deoptimization verbose");

DECLARE_FLAG(int, max_deoptimization_counter_threshold);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(int, max_polymorphic_checks);

DEFINE_FLAG(bool, trace_osr, false, "Trace attempts at on-stack replacement.");

DEFINE_FLAG(int, gc_every, 0, "Run major GC on every N stack overflow checks");
DEFINE_FLAG(int,
            stacktrace_every,
            0,
            "Compute debugger stacktrace on every N stack overflow checks");
DEFINE_FLAG(charp,
            stacktrace_filter,
            nullptr,
            "Compute stacktrace in named function on stack overflow checks");
DEFINE_FLAG(charp,
            deoptimize_filter,
            nullptr,
            "Deoptimize in named function on stack overflow checks");
DEFINE_FLAG(charp,
            deoptimize_on_runtime_call_name_filter,
            nullptr,
            "Runtime call name filter for --deoptimize-on-runtime-call-every.");

DEFINE_FLAG(bool,
            unopt_monomorphic_calls,
            true,
            "Enable specializing monomorphic calls from unoptimized code.");
DEFINE_FLAG(bool,
            unopt_megamorphic_calls,
            true,
            "Enable specializing megamorphic calls from unoptimized code.");
DEFINE_FLAG(bool,
            verbose_stack_overflow,
            false,
            "Print additional details about stack overflow.");
DEFINE_FLAG(bool, gc_at_throw, false, "Run evacuating GC at throw and rethrow");

DECLARE_FLAG(int, reload_every);
DECLARE_FLAG(bool, reload_every_optimized);
DECLARE_FLAG(bool, reload_every_back_off);

uword RuntimeEntry::GetEntryPoint() const {
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(function());
#if defined(DART_INCLUDE_SIMULATOR)
  if (FLAG_use_simulator) {
    // Redirection to leaf runtime calls supports a maximum of 4 arguments
    // passed in registers (maximum 2 double arguments for leaf float runtime
    // calls).
    ASSERT(argument_count() >= 0);
    ASSERT(!is_leaf() || (!is_float() && (argument_count() <= 4)) ||
           (argument_count() <= 2));
    Simulator::CallKind call_kind =
        is_leaf() ? (is_float() ? Simulator::kLeafFloatRuntimeCall
                                : Simulator::kLeafRuntimeCall)
                  : Simulator::kRuntimeCall;
    entry = Simulator::RedirectExternalReference(entry, call_kind,
                                                 argument_count());
  }
#endif
  return entry;
}

#ifdef DEBUG
#define TRACE_RUNTIME_CALL(format, name)                                       \
  if (FLAG_trace_runtime_calls) {                                              \
    THR_Print("Runtime call: " format "\n", name);                             \
  }
#else
#define TRACE_RUNTIME_CALL(format, name)                                       \
  do {                                                                         \
  } while (0)
#endif

#if defined(DART_INCLUDE_SIMULATOR)
#define CHECK_SIMULATOR_STACK_OVERFLOW()                                       \
  if (FLAG_use_simulator && !OSThread::Current()->HasStackHeadroom()) {        \
    Exceptions::ThrowStackOverflow();                                          \
  }
#else
#define CHECK_SIMULATOR_STACK_OVERFLOW()
#endif  // defined(DART_INCLUDE_SIMULATOR)

void OnEveryRuntimeEntryCall(Thread* thread,
                             const char* runtime_call_name,
                             bool can_lazy_deopt);

#define DEFINE_RUNTIME_ENTRY_IMPL(name, argument_count, can_lazy_deopt)        \
  extern void DRT_##name(NativeArguments arguments);                           \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DRT_" #name, reinterpret_cast<const void*>(DRT_##name), argument_count, \
      false, false, can_lazy_deopt);                                           \
  static void DRT_Helper##name(Isolate* isolate, Thread* thread, Zone* zone,   \
                               NativeArguments arguments);                     \
  extern "C" void DRT_##name(NativeArguments arguments) {                      \
    CHECK_STACK_ALIGNMENT;                                                     \
    /* Tell MemorySanitizer 'arguments' is initialized by generated code. */   \
    MSAN_UNPOISON(&arguments, sizeof(arguments));                              \
    ASSERT(arguments.ArgCount() == argument_count);                            \
    TRACE_RUNTIME_CALL("%s", "" #name);                                        \
    {                                                                          \
      Thread* thread = arguments.thread();                                     \
      ASSERT(thread == Thread::Current());                                     \
      RuntimeCallDeoptScope runtime_call_deopt_scope(                          \
          thread, can_lazy_deopt ? RuntimeCallDeoptAbility::kCanLazyDeopt      \
                                 : RuntimeCallDeoptAbility::kCannotLazyDeopt); \
      Isolate* isolate = thread->isolate();                                    \
      TransitionGeneratedToVM transition(thread);                              \
      StackZone zone(thread);                                                  \
      CHECK_SIMULATOR_STACK_OVERFLOW();                                        \
      if (FLAG_deoptimize_on_runtime_call_every > 0) {                         \
        OnEveryRuntimeEntryCall(thread, "" #name, can_lazy_deopt);             \
      }                                                                        \
      DRT_Helper##name(isolate, thread, zone.GetZone(), arguments);            \
    }                                                                          \
  }                                                                            \
  static void DRT_Helper##name(Isolate* isolate, Thread* thread, Zone* zone,   \
                               NativeArguments arguments)

#define DEFINE_RUNTIME_ENTRY(name, argument_count)                             \
  DEFINE_RUNTIME_ENTRY_IMPL(name, argument_count, /*can_lazy_deopt=*/true)

#define DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(name, argument_count)               \
  DEFINE_RUNTIME_ENTRY_IMPL(name, argument_count, /*can_lazy_deopt=*/false)

DEFINE_RUNTIME_ENTRY(RangeError, 2) {
  const Instance& length = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& index = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  if (!index.IsInteger()) {
    // Throw: new ArgumentError.value(index, "index", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, index);
    args.SetAt(1, Symbols::Index());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  // Throw: new RangeError.range(index, 0, length - 1, "length");
  const Array& args = Array::Handle(zone, Array::New(4));
  args.SetAt(0, index);
  args.SetAt(1, Integer::Handle(zone, Integer::New(0)));
  args.SetAt(
      2, Integer::Handle(
             zone, Integer::Cast(length).ArithmeticOp(
                       Token::kSUB, Integer::Handle(zone, Integer::New(1)))));
  args.SetAt(3, Symbols::Length());
  Exceptions::ThrowByType(Exceptions::kRange, args);
}

DEFINE_RUNTIME_ENTRY(RangeErrorUnboxedInt64, 0) {
  int64_t unboxed_length = thread->unboxed_int64_runtime_arg();
  int64_t unboxed_index = thread->unboxed_int64_runtime_second_arg();
  const auto& length = Integer::Handle(zone, Integer::New(unboxed_length));
  const auto& index = Integer::Handle(zone, Integer::New(unboxed_index));
  // Throw: new RangeError.range(index, 0, length - 1, "length");
  const Array& args = Array::Handle(zone, Array::New(4));
  args.SetAt(0, index);
  args.SetAt(1, Integer::Handle(zone, Integer::New(0)));
  args.SetAt(
      2, Integer::Handle(
             zone, Integer::Cast(length).ArithmeticOp(
                       Token::kSUB, Integer::Handle(zone, Integer::New(1)))));
  args.SetAt(3, Symbols::Length());
  Exceptions::ThrowByType(Exceptions::kRange, args);
}

DEFINE_RUNTIME_ENTRY(WriteError, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Smi& kind = Smi::CheckedHandle(zone, arguments.ArgAt(1));
  auto& message = String::Handle(zone);
  switch (kind.Value()) {
    case 0:  // CheckWritableInstr::Kind::kWriteUnmodifiableTypedData:
      message = String::NewFormatted("Cannot modify an unmodifiable list: %s",
                                     receiver.ToCString());
      break;
    case 1:  // CheckWritableInstr::Kind::kDeeplyImmutableAttachNativeFinalizer:
      message = String::NewFormatted(
          "Cannot attach NativeFinalizer to deeply immutable object: %s",
          receiver.ToCString());
      break;
  }
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kUnsupported, args);
}

static void NullErrorHelper(Zone* zone,
                            const String& selector,
                            bool is_param_name = false) {
  if (is_param_name) {
    const String& error = String::Handle(
        selector.IsNull()
            ? String::New("argument value is null")
            : String::NewFormatted("argument value for '%s' is null",
                                   selector.ToCString()));
    Exceptions::ThrowArgumentError(error);
    return;
  }

  // If the selector is null, this must be a null check that wasn't due to a
  // method invocation, so was due to the null check operator.
  if (selector.IsNull()) {
    const Array& args = Array::Handle(zone, Array::New(4));
    args.SetAt(
        3, String::Handle(
               zone, String::New("Null check operator used on a null value")));
    Exceptions::ThrowByType(Exceptions::kType, args);
    return;
  }

  InvocationMirror::Kind kind = InvocationMirror::kMethod;
  if (Field::IsGetterName(selector)) {
    kind = InvocationMirror::kGetter;
  } else if (Field::IsSetterName(selector)) {
    kind = InvocationMirror::kSetter;
  }

  const Smi& invocation_type = Smi::Handle(
      zone,
      Smi::New(InvocationMirror::EncodeType(InvocationMirror::kDynamic, kind)));

  const Array& args = Array::Handle(zone, Array::New(7));
  args.SetAt(0, /* instance */ Object::null_object());
  args.SetAt(1, selector);
  args.SetAt(2, invocation_type);
  args.SetAt(3, /* func_type_args_length */ Object::smi_zero());
  args.SetAt(4, /* func_type_args */ Object::null_object());
  args.SetAt(5, /* func_args */ Object::null_object());
  args.SetAt(6, /* func_arg_names */ Object::null_object());
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, args);
}

static void DoThrowNullError(Thread* thread, Zone* zone, bool is_param) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  const StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  ASSERT(!caller_frame->is_interpreted());
  const Code& code = Code::Handle(zone, caller_frame->LookupDartCode());
  const uword pc_offset = caller_frame->pc() - code.PayloadStart();

  if (FLAG_shared_slow_path_triggers_gc) {
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }

  const CodeSourceMap& map =
      CodeSourceMap::Handle(zone, code.code_source_map());
  String& member_name = String::Handle(zone);
  if (!map.IsNull()) {
    CodeSourceMapReader reader(map, Array::null_array(),
                               Function::null_function());
    const intptr_t name_index = reader.GetNullCheckNameIndexAt(pc_offset);
    RELEASE_ASSERT(name_index >= 0);

    const ObjectPool& pool = ObjectPool::Handle(zone, code.GetObjectPool());
    member_name ^= pool.ObjectAt(name_index);
  } else {
    member_name = Symbols::OptimizedOut().ptr();
  }

  NullErrorHelper(zone, member_name, is_param);
}

DEFINE_RUNTIME_ENTRY(NullError, 0) {
  DoThrowNullError(thread, zone, /*is_param=*/false);
}

// Collects information about pointers within the top |kMaxSlotsCollected|
// slots on the stack.
// TODO(b/179632636) This code is added in attempt to better understand
// b/179632636 and should be removed in the future.
void ReportImpossibleNullError(intptr_t cid,
                               StackFrame* caller_frame,
                               Thread* thread) {
  TextBuffer buffer(512);
  buffer.Printf("hit null error with cid %" Pd ", caller context: ", cid);

  const intptr_t kMaxSlotsCollected = 5;
  const auto slots = reinterpret_cast<ObjectPtr*>(caller_frame->sp());
  const intptr_t num_slots_in_frame =
      reinterpret_cast<ObjectPtr*>(caller_frame->fp()) - slots;
  const auto num_slots_to_collect =
      Utils::Maximum(kMaxSlotsCollected, num_slots_in_frame);
  bool comma = false;
  for (intptr_t i = 0; i < num_slots_to_collect; i++) {
    const ObjectPtr ptr = slots[i];
    buffer.Printf("%s[sp+%" Pd "] %" Pp "", comma ? ", " : "", i,
                  static_cast<uword>(ptr));
    if (ptr->IsHeapObject() &&
        (Dart::vm_isolate_group()->heap()->Contains(
             UntaggedObject::ToAddr(ptr)) ||
         thread->heap()->Contains(UntaggedObject::ToAddr(ptr)))) {
      buffer.Printf("(%" Pp ")", static_cast<uword>(ptr->untag()->tags_));
    }
    comma = true;
  }

  const char* message = buffer.buffer();
  FATAL("%s", message);
}

DEFINE_RUNTIME_ENTRY(DispatchTableNullError, 1) {
  const Smi& cid = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  if (cid.Value() != kNullCid) {
    // We hit null error, but receiver is not null itself. This most likely
    // is a memory corruption. Crash the VM but provide some additional
    // information about the arguments on the stack.
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    RELEASE_ASSERT(caller_frame->IsDartFrame());
    ReportImpossibleNullError(cid.Value(), caller_frame, thread);
  }
  DoThrowNullError(thread, zone, /*is_param=*/false);
}

DEFINE_RUNTIME_ENTRY(NullErrorWithSelector, 1) {
  const String& selector = String::CheckedHandle(zone, arguments.ArgAt(0));
  NullErrorHelper(zone, selector);
}

DEFINE_RUNTIME_ENTRY(NullCastError, 0) {
  NullErrorHelper(zone, String::null_string());
}

DEFINE_RUNTIME_ENTRY(ArgumentNullError, 0) {
  DoThrowNullError(thread, zone, /*is_param=*/true);
}

DEFINE_RUNTIME_ENTRY(ArgumentError, 1) {
  const Instance& value = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowArgumentError(value);
}

DEFINE_RUNTIME_ENTRY(ArgumentErrorUnboxedInt64, 0) {
  // Unboxed value is passed through a dedicated slot in Thread.
  int64_t unboxed_value = arguments.thread()->unboxed_int64_runtime_arg();
  const Integer& value = Integer::Handle(zone, Integer::New(unboxed_value));
  Exceptions::ThrowArgumentError(value);
}

DEFINE_RUNTIME_ENTRY(DoubleToInteger, 1) {
  // Unboxed value is passed through a dedicated slot in Thread.
  double val = arguments.thread()->unboxed_double_runtime_arg();
  const Smi& recognized_kind = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  switch (recognized_kind.Value()) {
    case MethodRecognizer::kDoubleToInteger:
      break;
    case MethodRecognizer::kDoubleFloorToInt:
      val = floor(val);
      break;
    case MethodRecognizer::kDoubleCeilToInt:
      val = ceil(val);
      break;
    default:
      UNREACHABLE();
  }
  arguments.SetReturn(Integer::Handle(zone, DoubleToInteger(zone, val)));
}

DEFINE_RUNTIME_ENTRY(IntegerDivisionByZeroException, 0) {
  const Array& args = Array::Handle(zone, Array::New(0));
  Exceptions::ThrowByType(Exceptions::kIntegerDivisionByZeroException, args);
}

static Heap::Space SpaceForRuntimeAllocation() {
  return UNLIKELY(FLAG_runtime_allocate_old) ? Heap::kOld : Heap::kNew;
}

static void RuntimeAllocationEpilogue(Thread* thread) {
  if (UNLIKELY(FLAG_runtime_allocate_spill_tlab)) {
    static RelaxedAtomic<uword> count = 0;
    if ((count++ % 10) == 0) {
      thread->heap()->new_space()->AbandonRemainingTLAB(thread);
    }
  }
}

// Allocation of a fixed length array of given element type.
// This runtime entry is never called for allocating a List of a generic type,
// because a prior run time call instantiates the element type if necessary.
// Arg0: array length.
// Arg1: array type arguments, i.e. vector of 1 type, the element type.
// Return value: newly allocated array of length arg0.
DEFINE_RUNTIME_ENTRY(AllocateArray, 2) {
  const Instance& length = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  const int64_t len = Integer::Cast(length).Value();
  if (len < 0) {
    // Throw: new RangeError.range(length, 0, Array::kMaxElements, "length");
    Exceptions::ThrowRangeError("length", Integer::Cast(length), 0,
                                Array::kMaxElements);
  }
  if (len > Array::kMaxElements) {
    Exceptions::ThrowOOM();
  }

  const Array& array = Array::Handle(
      zone,
      Array::New(static_cast<intptr_t>(len), SpaceForRuntimeAllocation()));
  TypeArguments& element_type =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  // An Array is raw or takes one type argument. However, its type argument
  // vector may be longer than 1 due to a type optimization reusing the type
  // argument vector of the instantiator.
  ASSERT(element_type.IsNull() ||
         (element_type.Length() >= 1 && element_type.IsInstantiated()));
  array.SetTypeArguments(element_type);  // May be null.
  arguments.SetReturn(array);
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateDouble, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(
      Object::Handle(zone, Double::New(0.0, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(BoxDouble, 0) {
  const double val = thread->unboxed_double_runtime_arg();
  arguments.SetReturn(
      Object::Handle(zone, Double::New(val, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(BoxFloat32x4, 0) {
  const auto val = thread->unboxed_simd128_runtime_arg();
  arguments.SetReturn(
      Object::Handle(zone, Float32x4::New(val, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(BoxFloat64x2, 0) {
  const auto val = thread->unboxed_simd128_runtime_arg();
  arguments.SetReturn(
      Object::Handle(zone, Float64x2::New(val, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateMint, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(
      zone, Integer::New(kMaxInt64, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateFloat32x4, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(
      zone, Float32x4::New(0.0, 0.0, 0.0, 0.0, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateFloat64x2, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(
      zone, Float64x2::New(0.0, 0.0, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateInt32x4, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(
      zone, Int32x4::New(0, 0, 0, 0, SpaceForRuntimeAllocation())));
  RuntimeAllocationEpilogue(thread);
}

// Allocate typed data array of given class id and length.
// Arg0: class id.
// Arg1: number of elements.
// Return value: newly allocated typed data array.
DEFINE_RUNTIME_ENTRY(AllocateTypedData, 2) {
  const intptr_t cid = Smi::CheckedHandle(zone, arguments.ArgAt(0)).Value();
  const auto& length = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  if (!length.IsInteger()) {
    const Array& args = Array::Handle(zone, Array::New(1));
    args.SetAt(0, length);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  const int64_t len = Integer::Cast(length).Value();
  const intptr_t max = TypedData::MaxElements(cid);
  if (len < 0) {
    Exceptions::ThrowRangeError("length", Integer::Cast(length), 0, max);
  } else if (len > max) {
    Exceptions::ThrowOOM();
  }
  const auto& typed_data =
      TypedData::Handle(zone, TypedData::New(cid, static_cast<intptr_t>(len),
                                             SpaceForRuntimeAllocation()));
  arguments.SetReturn(typed_data);
  RuntimeAllocationEpilogue(thread);
}

// Helper returning the token position of the Dart caller.
static TokenPosition GetCallerLocation() {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  return caller_frame->GetTokenPos();
}

// Result of an invoke may be an unhandled exception, in which case we
// rethrow it.
static void ThrowIfError(const Object& result) {
  if (!result.IsNull() && result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
}

// Allocate a new object.
// Arg0: class of the object that needs to be allocated.
// Arg1: type arguments of the object that needs to be allocated.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObject, 2) {
  const Class& cls = Class::CheckedHandle(zone, arguments.ArgAt(0));
#if defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)
  if (!cls.is_allocate_finalized()) {
    const Error& error =
        Error::Handle(zone, cls.EnsureIsAllocateFinalized(thread));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
      UNREACHABLE();
    }
  }
#endif
  ASSERT(cls.is_allocate_finalized());
  const Instance& instance = Instance::Handle(
      zone, Instance::NewAlreadyFinalized(cls, SpaceForRuntimeAllocation()));
  if (cls.NumTypeArguments() == 0) {
    // No type arguments required for a non-parameterized type.
    ASSERT(Instance::CheckedHandle(zone, arguments.ArgAt(1)).IsNull());
  } else {
    const auto& type_arguments =
        TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
    // Unless null (for a raw type), the type argument vector may be longer than
    // necessary due to a type optimization reusing the type argument vector of
    // the instantiator.
    ASSERT(type_arguments.IsNull() ||
           (type_arguments.IsInstantiated() &&
            (type_arguments.Length() >= cls.NumTypeArguments())));
    instance.SetTypeArguments(type_arguments);
  }
  arguments.SetReturn(instance);
  RuntimeAllocationEpilogue(thread);
}

extern "C" uword /*ObjectPtr*/ DLRT_EnsureRememberedAndMarkingDeferred(
    uword /*ObjectPtr*/ object_in,
    Thread* thread) {
  ObjectPtr object = static_cast<ObjectPtr>(object_in);

  // If we eliminate the generational write barrier when writing into an object,
  // we need to ensure it's either a new-space object or it has been added to
  // the remembered set. If we eliminate the incremental write barrier, we need
  // to add the object to the deferred marking stack so it will be [re]scanned.
  //
  // NOTE: We use static_cast<>() instead of ::RawCast() to avoid handle
  // allocations in debug mode. Handle allocations in leaf runtimes can cause
  // memory leaks because they will allocate into a handle scope from the next
  // outermost runtime code (to which the generated Dart code might not return
  // in a long time).
  bool skips_barrier = true;
  if (object->IsArray()) {
    const intptr_t length = Array::LengthOf(static_cast<ArrayPtr>(object));
    skips_barrier = compiler::target::WillAllocateNewOrRememberedArray(length);
  } else if (object->IsContext()) {
    const intptr_t num_context_variables =
        Context::NumVariables(static_cast<ContextPtr>(object));
    skips_barrier = compiler::target::WillAllocateNewOrRememberedContext(
        num_context_variables);
  }

  if (skips_barrier) {
    if (object->IsOldObject()) {
      object->untag()->EnsureInRememberedSet(thread);
    }

    if (thread->is_marking()) {
      thread->DeferredMarkingStackAddObject(object);
    }
  }

  return static_cast<uword>(object);
}
DEFINE_LEAF_RUNTIME_ENTRY(EnsureRememberedAndMarkingDeferred,
                          2,
                          DLRT_EnsureRememberedAndMarkingDeferred);

extern "C" void DLRT_StoreBufferBlockProcess(Thread* thread) {
  thread->StoreBufferBlockProcess(StoreBuffer::kCheckThreshold);
}
DEFINE_LEAF_RUNTIME_ENTRY(StoreBufferBlockProcess,
                          1,
                          DLRT_StoreBufferBlockProcess);

extern "C" void DLRT_OldMarkingStackBlockProcess(Thread* thread) {
  thread->OldMarkingStackBlockProcess();
}
DEFINE_LEAF_RUNTIME_ENTRY(OldMarkingStackBlockProcess,
                          1,
                          DLRT_OldMarkingStackBlockProcess);

extern "C" void DLRT_NewMarkingStackBlockProcess(Thread* thread) {
  thread->NewMarkingStackBlockProcess();
}
DEFINE_LEAF_RUNTIME_ENTRY(NewMarkingStackBlockProcess,
                          1,
                          DLRT_NewMarkingStackBlockProcess);

// Instantiate type.
// Arg0: uninstantiated type.
// Arg1: instantiator type arguments.
// Arg2: function type arguments.
// Return value: instantiated type.
DEFINE_RUNTIME_ENTRY(InstantiateType, 3) {
  AbstractType& type = AbstractType::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  ASSERT(!type.IsNull());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsInstantiated());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsInstantiated());
  type = type.InstantiateFrom(instantiator_type_arguments,
                              function_type_arguments, kAllFree, Heap::kOld);
  ASSERT(!type.IsNull() && type.IsInstantiated());
  arguments.SetReturn(type);
}

// Instantiate type arguments.
// Arg0: uninstantiated type arguments.
// Arg1: instantiator type arguments.
// Arg2: function type arguments.
// Return value: instantiated type arguments.
DEFINE_RUNTIME_ENTRY(InstantiateTypeArguments, 3) {
  TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  ASSERT(!type_arguments.IsNull() && !type_arguments.IsInstantiated());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsInstantiated());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsInstantiated());
  // Code inlined in the caller should have optimized the case where the
  // instantiator can be reused as type argument vector.
  ASSERT(!type_arguments.IsUninstantiatedIdentity());
  type_arguments = type_arguments.InstantiateAndCanonicalizeFrom(
      instantiator_type_arguments, function_type_arguments);
  ASSERT(type_arguments.IsNull() || type_arguments.IsInstantiated());
  arguments.SetReturn(type_arguments);
}

// Helper routine for tracing a subtype check.
static void PrintSubtypeCheck(const AbstractType& subtype,
                              const AbstractType& supertype,
                              const bool result) {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);

  LogBlock lb;
  THR_Print("SubtypeCheck: '%s' %d %s '%s' %d (pc: %#" Px ").\n",
            subtype.NameCString(), subtype.type_class_id(),
            result ? "is" : "is !", supertype.NameCString(),
            supertype.type_class_id(), caller_frame->pc());

  const Function& function =
      Function::Handle(caller_frame->LookupDartFunction());
  if (function.HasSavedArgumentsDescriptor()) {
    const auto& args_desc_array = Array::Handle(function.saved_args_desc());
    const ArgumentsDescriptor args_desc(args_desc_array);
    THR_Print(" -> Function %s [%s]\n", function.ToFullyQualifiedCString(),
              args_desc.ToCString());
  } else {
    THR_Print(" -> Function %s\n", function.ToFullyQualifiedCString());
  }
}

// Instantiate type.
// Arg0: instantiator type arguments
// Arg1: function type arguments
// Arg2: type to be a subtype of the other
// Arg3: type to be a supertype of the other
// Arg4: variable name of the subtype parameter
// No return value.
DEFINE_RUNTIME_ENTRY(SubtypeCheck, 5) {
  const TypeArguments& instantiator_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& function_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  AbstractType& subtype = AbstractType::CheckedHandle(zone, arguments.ArgAt(2));
  AbstractType& supertype =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(3));
  const String& dst_name = String::CheckedHandle(zone, arguments.ArgAt(4));

  ASSERT(!supertype.IsNull());
  ASSERT(!subtype.IsNull());

  // Now that AssertSubtype may be checking types only available at runtime,
  // we can't guarantee the supertype isn't the top type.
  if (supertype.IsTopTypeForSubtyping()) return;

  // The supertype or subtype may not be instantiated.
  if (AbstractType::InstantiateAndTestSubtype(
          &subtype, &supertype, instantiator_type_args, function_type_args)) {
    if (FLAG_trace_type_checks) {
      // The supertype and subtype are now instantiated. Subtype check passed.
      PrintSubtypeCheck(subtype, supertype, true);
    }
    return;
  }
  if (FLAG_trace_type_checks) {
    // The supertype and subtype are now instantiated. Subtype check failed.
    PrintSubtypeCheck(subtype, supertype, false);
  }

  // Throw a dynamic type error.
  const TokenPosition location = GetCallerLocation();
  Exceptions::CreateAndThrowTypeError(location, subtype, supertype, dst_name);
  UNREACHABLE();
}

// Allocate a new closure and initializes its function, context,
// instantiator type arguments and delayed type arguments fields.
// Arg0: function.
// Arg1: context.
// Arg2: instantiator type arguments.
// Arg3: delayed type arguments.
// Return value: newly allocated closure.
DEFINE_RUNTIME_ENTRY(AllocateClosure, 4) {
  const auto& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  const auto& context = Object::Handle(zone, arguments.ArgAt(1));
  const auto& instantiator_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const auto& delayed_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  const Closure& closure = Closure::Handle(
      zone, Closure::New(instantiator_type_args, Object::null_type_arguments(),
                         delayed_type_args, function, context,
                         SpaceForRuntimeAllocation()));
  arguments.SetReturn(closure);
  RuntimeAllocationEpilogue(thread);
}

// Allocate a new context large enough to hold the given number of variables.
// Arg0: number of variables.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(AllocateContext, 1) {
  const Smi& num_variables = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  const Context& context = Context::Handle(
      zone, Context::New(num_variables.Value(), SpaceForRuntimeAllocation()));
  arguments.SetReturn(context);
  RuntimeAllocationEpilogue(thread);
}

// Make a copy of the given context, including the values of the captured
// variables.
// Arg0: the context to be cloned.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(CloneContext, 1) {
  const Context& ctx = Context::CheckedHandle(zone, arguments.ArgAt(0));
  Context& cloned_ctx = Context::Handle(
      zone, Context::New(ctx.num_variables(), SpaceForRuntimeAllocation()));
  cloned_ctx.set_parent(Context::Handle(zone, ctx.parent()));
  Object& inst = Object::Handle(zone);
  for (int i = 0; i < ctx.num_variables(); i++) {
    inst = ctx.At(i);
    cloned_ctx.SetAt(i, inst);
  }
  arguments.SetReturn(cloned_ctx);
  RuntimeAllocationEpilogue(thread);
}

// Allocate a new record instance.
// Arg0: record shape id.
// Return value: newly allocated record.
DEFINE_RUNTIME_ENTRY(AllocateRecord, 1) {
  const RecordShape shape(Smi::RawCast(arguments.ArgAt(0)));
  const Record& record =
      Record::Handle(zone, Record::New(shape, SpaceForRuntimeAllocation()));
  arguments.SetReturn(record);
  RuntimeAllocationEpilogue(thread);
}

// Allocate a new small record instance and initialize its fields.
// Arg0: record shape id.
// Arg1-Arg3: field values.
// Return value: newly allocated record.
DEFINE_RUNTIME_ENTRY(AllocateSmallRecord, 4) {
  const RecordShape shape(Smi::RawCast(arguments.ArgAt(0)));
  const auto& value0 = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const auto& value1 = Instance::CheckedHandle(zone, arguments.ArgAt(2));
  const auto& value2 = Instance::CheckedHandle(zone, arguments.ArgAt(3));
  const Record& record =
      Record::Handle(zone, Record::New(shape, SpaceForRuntimeAllocation()));
  const intptr_t num_fields = shape.num_fields();
  ASSERT(num_fields == 2 || num_fields == 3);
  record.SetFieldAt(0, value0);
  record.SetFieldAt(1, value1);
  if (num_fields > 2) {
    record.SetFieldAt(2, value2);
  }
  arguments.SetReturn(record);
  RuntimeAllocationEpilogue(thread);
}

// Allocate a SuspendState object.
// Arg0: frame size.
// Arg1: existing SuspendState object or function data.
// Return value: newly allocated object.
// No lazy deopt: the various suspend stubs need to save the real pc, not the
// lazy deopt stub entry, for pointer visiting of the suspend state to work. The
// resume stubs will do a check for disabled code.
DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateSuspendState, 2) {
  const intptr_t frame_size =
      Smi::CheckedHandle(zone, arguments.ArgAt(0)).Value();
  const Object& previous_state = Object::Handle(zone, arguments.ArgAt(1));
  SuspendState& result = SuspendState::Handle(zone);
  if (previous_state.IsSuspendState()) {
    const auto& suspend_state = SuspendState::Cast(previous_state);
    const auto& function_data =
        Instance::Handle(zone, suspend_state.function_data());
    ObjectStore* object_store = thread->isolate_group()->object_store();
    if (function_data.GetClassId() ==
        Class::Handle(zone, object_store->async_star_stream_controller())
            .id()) {
      // Reset _AsyncStarStreamController.asyncStarBody to null in order
      // to create a new callback closure during next yield.
      // The new callback closure will capture the reallocated SuspendState.
      //
      // Caveat: can't use [SetField] here because it will try to take program
      // lock (to update the state of guarded cid) and that requires us to
      // be at safepoint which permits lazy deopt. Instead bypass
      // field guard by making sure that guarded_cid allows our store here.
      // (See ObjectStore::InitKnownObjects which initializes it).
      function_data.SetFieldWithoutFieldGuard(
          Field::Handle(
              zone,
              object_store->async_star_stream_controller_async_star_body()),
          Object::null_object());
    }
    result = SuspendState::New(frame_size, function_data,
                               SpaceForRuntimeAllocation());
    if (function_data.GetClassId() ==
        Class::Handle(zone, object_store->sync_star_iterator_class()).id()) {
      // Refresh _SyncStarIterator._state with the new SuspendState object.
      //
      // Caveat: can't use [SetField] here because it will try to take program
      // lock (to update the state of guarded cid) and that requires us to
      // be at safepoint which permits lazy deopt. Instead bypass
      // field guard by making sure that guarded_cid allows our store here.
      // (See ObjectStore::InitKnownObjects which initializes it).
      function_data.SetFieldWithoutFieldGuard(
          Field::Handle(zone, object_store->sync_star_iterator_state()),
          result);
    }
  } else {
    result = SuspendState::New(frame_size, Instance::Cast(previous_state),
                               SpaceForRuntimeAllocation());
  }
  arguments.SetReturn(result);
  RuntimeAllocationEpilogue(thread);
}

// Makes a copy of the given SuspendState object, including the payload frame.
// Arg0: the SuspendState object to be cloned.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(CloneSuspendState, 1) {
  const SuspendState& src =
      SuspendState::CheckedHandle(zone, arguments.ArgAt(0));
  const SuspendState& dst = SuspendState::Handle(
      zone, SuspendState::Clone(thread, src, SpaceForRuntimeAllocation()));
  arguments.SetReturn(dst);
  RuntimeAllocationEpilogue(thread);
}

// Allocate a new SubtypeTestCache for use in interpreted implicit setters.
// Return value: newly allocated SubtypeTestCache.
DEFINE_RUNTIME_ENTRY(AllocateSubtypeTestCache, 0) {
#if defined(DART_DYNAMIC_MODULES)
  const auto& cache = SubtypeTestCache::Handle(
      zone, SubtypeTestCache::New(SubtypeTestCache::kMaxInputs));
  arguments.SetReturn(cache);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Invoke field getter before dispatch.
// Arg0: instance.
// Arg1: field name (may be demangled during call).
// Return value: field value.
DEFINE_RUNTIME_ENTRY(GetFieldForDispatch, 2) {
#if defined(DART_DYNAMIC_MODULES)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  String& name = String::CheckedHandle(zone, arguments.ArgAt(1));
  const Class& receiver_class = Class::Handle(zone, receiver.clazz());
  if (Function::IsDynamicInvocationForwarderName(name)) {
    name = Function::DemangleDynamicInvocationForwarderName(name);
    arguments.SetArgAt(1, name);  // Reflect change in arguments.
  }
  const String& getter_name = String::Handle(zone, Field::GetterName(name));
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& getter = Function::Handle(
      zone, Resolver::ResolveDynamicForReceiverClass(
                receiver_class, getter_name, args_desc, /*allow_add=*/true));
  ASSERT(!getter.IsNull());  // An InvokeFieldDispatcher function was created.
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(getter, args));
  ThrowIfError(result);
  arguments.SetReturn(result);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Converts arguments descriptor passed to an implicit closure
// into an arguments descriptor for the target function.
// Arg0: implicit closure arguments descriptor
// Arg1: target function
// Arg2: new type args length
// Return value: target arguments descriptor
DEFINE_RUNTIME_ENTRY(AdjustArgumentsDesciptorForImplicitClosure, 3) {
#if defined(DART_DYNAMIC_MODULES)
  const auto& descriptor = Array::CheckedHandle(zone, arguments.ArgAt(0));
  const auto& target = Function::CheckedHandle(zone, arguments.ArgAt(1));
  intptr_t type_args_len = Smi::CheckedHandle(zone, arguments.ArgAt(2)).Value();

  const ArgumentsDescriptor args_desc(descriptor);
  intptr_t num_arguments = args_desc.Count();

  if (target.is_static()) {
    if (target.IsFactory()) {
      // Factory always takes type arguments via a positional parameter.
      type_args_len = 0;
    } else {
      // Drop closure receiver.
      --num_arguments;
    }
  } else {
    if (target.IsGenerativeConstructor()) {
      // Type arguments are not passed to a generative constructor.
      type_args_len = 0;
    }
  }

  const auto& optional_arguments_names =
      Array::Handle(zone, args_desc.GetArgumentNames());
  const auto& result = Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(type_args_len, num_arguments,
                                          optional_arguments_names));
  arguments.SetReturn(result);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Converts type arguments passed to a constructor tear-off
// into an instance type arguments.
// Arg0: class to allocate
// Arg1: type arguments
// Return value: instance type arguments
DEFINE_RUNTIME_ENTRY(ConvertToInstanceTypeArguments, 2) {
#if defined(DART_DYNAMIC_MODULES)
  const auto& cls = Class::CheckedHandle(zone, arguments.ArgAt(0));
  const auto& type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const auto& result = TypeArguments::Handle(
      zone, cls.GetInstanceTypeArguments(thread, type_args));
  arguments.SetReturn(result);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Check that arguments are valid for the given closure.
// Arg0: closure
// Arg1: arguments descriptor
// Return value: whether the arguments are valid
DEFINE_RUNTIME_ENTRY(ClosureArgumentsValid, 2) {
#if defined(DART_DYNAMIC_MODULES)
  const auto& closure = Closure::CheckedHandle(zone, arguments.ArgAt(0));
  const auto& descriptor = Array::CheckedHandle(zone, arguments.ArgAt(1));

  const auto& function = Function::Handle(zone, closure.function());
  const ArgumentsDescriptor args_desc(descriptor);
  if (!function.AreValidArguments(args_desc, nullptr)) {
    arguments.SetReturn(Bool::False());
  } else if (!closure.IsGeneric() && args_desc.TypeArgsLen() > 0) {
    // The arguments may be valid for the closure function itself, but if the
    // closure has delayed type arguments, no type arguments should be provided.
    arguments.SetReturn(Bool::False());
  } else {
    arguments.SetReturn(Bool::True());
  }
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Resolve 'call' function of receiver.
// Arg0: receiver (not a closure).
// Arg1: arguments descriptor
// Return value: 'call' function'.
DEFINE_RUNTIME_ENTRY(ResolveCallFunction, 2) {
#if defined(DART_DYNAMIC_MODULES)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Array& descriptor = Array::CheckedHandle(zone, arguments.ArgAt(1));
  ArgumentsDescriptor args_desc(descriptor);
  ASSERT(!receiver.IsClosure());  // Interpreter tests for closure.
  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& call_function = Function::Handle(
      zone,
      Resolver::ResolveDynamicForReceiverClass(cls, Symbols::call(), args_desc,
                                               /*allow_add=*/false));
  arguments.SetReturn(call_function);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Resolve external method call from the interpreter.
// Arg0: function.
// Arg1: pool index to store resolved trampoline and native function.
DEFINE_RUNTIME_ENTRY(ResolveExternalCall, 2) {
#if defined(DART_DYNAMIC_MODULES)
  const auto& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  const intptr_t pool_index =
      Smi::CheckedHandle(zone, arguments.ArgAt(1)).Value();

  const Class& cls = Class::Handle(zone, function.Owner());
  const Library& library = Library::Handle(zone, cls.library());

  Dart_NativeEntryResolver resolver = library.native_entry_resolver();
  bool is_bootstrap_native = Bootstrap::IsBootstrapResolver(resolver);

  const String& native_name = String::Handle(zone, function.native_name());
  ASSERT(!native_name.IsNull());

  const intptr_t num_params =
      NativeArguments::ParameterCountForResolution(function);
  bool is_auto_scope = true;
  const NativeFunction target_function = NativeEntry::ResolveNative(
      library, native_name, num_params, &is_auto_scope);
  if (target_function == nullptr) {
    const auto& error = Error::Handle(LanguageError::NewFormatted(
        Error::Handle(),  // No previous error.
        Script::Handle(function.script()), function.token_pos(),
        Report::AtLocation, Report::kError, Heap::kOld,
        "native function '%s' (%" Pd " arguments) cannot be found",
        native_name.ToCString(), num_params));
    Exceptions::PropagateError(error);
  }

  NativeFunctionWrapper trampoline;
  if (is_bootstrap_native) {
    trampoline = NativeEntry::BootstrapNativeCallWrapper;
  } else if (is_auto_scope) {
    trampoline = NativeEntry::AutoScopeNativeCallWrapper;
  } else {
    trampoline = NativeEntry::NoScopeNativeCallWrapper;
  }

  const auto& bytecode = Bytecode::Handle(zone, function.GetBytecode());
  const auto& pool = ObjectPool::Handle(zone, bytecode.object_pool());
  pool.SetRawValueAt(pool_index, reinterpret_cast<uword>(trampoline));
  pool.SetRawValueAt(pool_index + 1, reinterpret_cast<uword>(target_function));
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

#if defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)

struct FfiCallArguments {
  uword stack_area;
  uword stack_area_end;
  uword cpu_registers[kNumberOfCpuRegisters];
  uword fpu_registers[kNumberOfFpuRegisters];
  uword target;
};

#if defined(HOST_ARCH_ARM64)
extern "C" void FfiCallTrampoline(FfiCallArguments* args);
#else
extern "C" typedef void (*ffiCallTrampoline)(FfiCallArguments* args);

void FfiCallTrampoline(FfiCallArguments* args) {
#if defined(HOST_ARCH_X64)
  reinterpret_cast<ffiCallTrampoline>(
      StubCode::FfiCallTrampoline().EntryPoint())(args);
#else
  UNIMPLEMENTED();
#endif
}
#endif

static int64_t TruncateFfiInt(int64_t value,
                              compiler::ffi::PrimitiveType type,
                              bool is_return) {
#if defined(HOST_ARCH_RISCV64)
  // 64-bit RISC-V represents C uint32 as sign-extended to 64 bits.
  if (!is_return && (type == compiler::ffi::kUint32)) {
    return static_cast<int32_t>(static_cast<uint32_t>(value));
  }
#endif
  switch (type) {
    case compiler::ffi::kInt8:
      return static_cast<int8_t>(value);
    case compiler::ffi::kUint8:
      return static_cast<uint8_t>(value);
    case compiler::ffi::kInt16:
      return static_cast<int16_t>(value);
    case compiler::ffi::kUint16:
      return static_cast<uint16_t>(value);
    case compiler::ffi::kInt32:
      return static_cast<int32_t>(value);
    case compiler::ffi::kUint32:
      return static_cast<uint32_t>(value);
    case compiler::ffi::kInt64:
    case compiler::ffi::kUint64:
      return value;
    default:
      UNREACHABLE();
  }
}

static void PassFfiCallArguments(
    Thread* thread,
    const compiler::ffi::CallMarshaller& marshaller,
    ObjectPtr* argv,
    FfiCallArguments* args) {
  Zone* zone = thread->zone();
  ApiLocalScope* scope = thread->api_top_scope();
  auto& arg = Object::Handle(zone);
  for (intptr_t i = 0; i < marshaller.num_args(); ++i) {
    if (marshaller.IsCompoundCType(i)) {
      UNIMPLEMENTED();
    } else {
      arg = argv[i];
      uword value;
      if (marshaller.IsHandleCType(i)) {
        LocalHandle* handle = scope->local_handles()->AllocateHandle();
        handle->set_ptr(arg.ptr());
        value = reinterpret_cast<uword>(handle);
      } else if (marshaller.IsPointerPointer(i)) {
        value = Pointer::Cast(arg).NativeAddress();
      } else if (marshaller.IsTypedDataPointer(i)) {
        value = reinterpret_cast<uword>(TypedDataBase::Cast(arg).DataAddr(0));
      } else if (marshaller.IsCompoundPointer(i)) {
        ObjectStore* object_store = thread->isolate_group()->object_store();
        auto& obj = Object::Handle(zone);
        obj = object_store->compound_offset_in_bytes_field();
        ASSERT(!obj.IsNull());
        obj = Instance::Cast(arg).GetField(Field::Cast(obj));
        const uword offset_in_bytes =
            static_cast<uword>(Integer::Cast(obj).Value());
        obj = object_store->compound_typed_data_base_field();
        ASSERT(!obj.IsNull());
        obj = Instance::Cast(arg).GetField(Field::Cast(obj));
        if (obj.IsPointer()) {
          value = Pointer::Cast(obj).NativeAddress() + offset_in_bytes;
        } else {
          ASSERT(obj.IsTypedDataBase());
          value = reinterpret_cast<uword>(
              TypedDataBase::Cast(obj).DataAddr(offset_in_bytes));
        }
      } else if (marshaller.IsBool(i)) {
        value = Bool::Cast(arg).value() ? static_cast<uword>(-1) : 0;
      } else {
        ASSERT(!marshaller.IsVoid(i));
        const auto rep = marshaller.RepInDart(i);
        if (RepresentationUtils::IsUnboxedInteger(rep)) {
          value = TruncateFfiInt(Integer::Cast(arg).Value(),
                                 marshaller.Location(i)
                                     .payload_type()
                                     .AsPrimitive()
                                     .representation(),
                                 /*is_return=*/false);
        } else if (rep == kUnboxedDouble) {
          value = bit_cast<uint64_t, double>(Double::Cast(arg).value());
        } else if (rep == kUnboxedFloat) {
          value = bit_cast<uint32_t, float>(
              static_cast<float>(Double::Cast(arg).value()));
        } else {
          UNREACHABLE();
        }
      }
      const auto& arg_target = marshaller.Location(i);
      if (!arg_target.payload_type().IsPrimitive()) {
        UNIMPLEMENTED();
      }
      if (arg_target.IsRegisters()) {
        const auto& dst = arg_target.AsRegisters();
        ASSERT(dst.num_regs() == 1);
        const auto dst_reg = dst.reg_at(0);
        ASSERT((dst_reg >= 0) && (dst_reg < kNumberOfCpuRegisters));
        args->cpu_registers[dst_reg] = value;
      } else if (arg_target.IsFpuRegisters()) {
        const FpuRegister dst_reg = arg_target.AsFpuRegisters().fpu_reg();
        ASSERT((dst_reg >= 0) && (dst_reg < kNumberOfFpuRegisters));
        args->fpu_registers[dst_reg] = value;
      } else if (arg_target.IsStack()) {
        const auto& dst = arg_target.AsStack();
        const intptr_t offset = dst.offset_in_bytes();
        ASSERT((offset >= 0) &&
               (args->stack_area + offset + kWordSize <= args->stack_area_end));
        *reinterpret_cast<uword*>(args->stack_area + offset) = value;
      }
    }
  }

#if defined(TARGET_ARCH_X64)
  if (marshaller.contains_varargs() &&
      CallingConventions::kVarArgFpuRegisterCount != kNoRegister) {
    // TODO(http://dartbug.com/38578): Use the number of used FPU registers.
    args->cpu_registers[CallingConventions::kVarArgFpuRegisterCount] =
        CallingConventions::kFpuArgumentRegisters;
  }
#endif  // defined(TARGET_ARCH_X64)
}

static ObjectPtr ReceiveFfiCallResult(
    Thread* thread,
    const compiler::ffi::CallMarshaller& marshaller,
    FfiCallArguments* args) {
  if (marshaller.ReturnsCompound()) {
    UNIMPLEMENTED();
  }
  const intptr_t arg_index = compiler::ffi::kResultIndex;
  if (marshaller.IsPointerPointer(arg_index)) {
    uword value = args->cpu_registers[CallingConventions::kReturnReg];
    return Pointer::New(value);
  } else if (marshaller.IsTypedDataPointer(arg_index)) {
    UNREACHABLE();  // Only supported for FFI call arguments.
  } else if (marshaller.IsCompoundPointer(arg_index)) {
    UNREACHABLE();  // Only supported for FFI call arguments.
  } else if (marshaller.IsHandleCType(arg_index)) {
    uword value = args->cpu_registers[CallingConventions::kReturnReg];
    return reinterpret_cast<LocalHandle*>(value)->ptr();
  } else if (marshaller.IsVoid(arg_index)) {
    return Object::null();
  } else if (marshaller.IsBool(arg_index)) {
    int64_t value =
        TruncateFfiInt(args->cpu_registers[CallingConventions::kReturnReg],
                       marshaller.Location(arg_index)
                           .payload_type()
                           .AsPrimitive()
                           .representation(),
                       /*is_return=*/true);
    return Bool::Get(value != 0).ptr();
  } else {
    const auto rep = marshaller.RepInDart(arg_index);
    if (RepresentationUtils::IsUnboxedInteger(rep)) {
      const int64_t value =
          TruncateFfiInt(args->cpu_registers[CallingConventions::kReturnReg],
                         marshaller.Location(arg_index)
                             .payload_type()
                             .AsPrimitive()
                             .representation(),
                         /*is_return=*/true);
      return Integer::New(value);
    } else if (rep == kUnboxedDouble) {
      double value = bit_cast<double, uint64_t>(
          args->fpu_registers[CallingConventions::kReturnFpuReg]);
      return Double::New(value);
    } else if (rep == kUnboxedFloat) {
      float value = bit_cast<float, uint32_t>(static_cast<uint32_t>(
          args->fpu_registers[CallingConventions::kReturnFpuReg]));
      return Double::New(static_cast<double>(value));
    } else {
      UNREACHABLE();
    }
  }
}

static uword ResolveFfiNativeTarget(Thread* thread, const Function& function) {
  Zone* zone = thread->zone();
  auto const& native = Instance::Handle(zone, function.GetNativeAnnotation());
  const auto& native_class = Class::Handle(zone, native.clazz());
  ASSERT(String::Handle(native_class.UserVisibleName())
             .Equals(Symbols::FfiNative()));
  const auto& symbol_field = Field::Handle(
      zone, native_class.LookupInstanceFieldAllowPrivate(Symbols::symbol()));
  ASSERT(!symbol_field.IsNull());
  const auto& asset_id_field = Field::Handle(
      zone, native_class.LookupInstanceFieldAllowPrivate(Symbols::assetId()));
  ASSERT(!asset_id_field.IsNull());
  const auto& symbol =
      String::Handle(zone, String::RawCast(native.GetField(symbol_field)));
  const auto& asset_id =
      String::Handle(zone, String::RawCast(native.GetField(asset_id_field)));
  const auto& type_args =
      TypeArguments::Handle(zone, native.GetTypeArguments());
  ASSERT(type_args.Length() == 1);
  const auto& native_type = AbstractType::Handle(zone, type_args.TypeAt(0));
  intptr_t arg_n;
  if (native_type.IsFunctionType()) {
    const auto& native_function_type = FunctionType::Cast(native_type);
    arg_n = native_function_type.NumParameters() -
            native_function_type.num_implicit_parameters();
  } else {
    // We're looking up the address of a native field.
    arg_n = 0;
  }
  const auto& ffi_resolver = Function::ZoneHandle(
      zone, thread->isolate_group()->object_store()->ffi_resolver_function());
  const auto& args = Array::Handle(zone, Array::New(3));
  args.SetAt(0, asset_id);
  args.SetAt(1, symbol);
  args.SetAt(2, Smi::Handle(zone, Smi::New(arg_n)));
  const auto& result =
      Object::Handle(zone, DartEntry::InvokeFunction(ffi_resolver, args));
  ThrowIfError(result);
  return static_cast<uword>(Integer::Cast(result).Value());
}

#endif  // defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)

// Perform FFI call from the interpreter.
// Arg0: function.
// Arg1: constant pool index to store resolved target.
DEFINE_RUNTIME_ENTRY(FfiCall, 2) {
#if defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)
  const auto& function = Function::CheckedZoneHandle(zone, arguments.ArgAt(0));
  const intptr_t pool_index =
      Smi::CheckedHandle(zone, arguments.ArgAt(1)).Value();
  ASSERT(function.is_ffi_native() || function.IsFfiCallClosure());

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  ASSERT(frame->IsExitFrame());
  frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  ASSERT(frame->IsDartFrame());
  ASSERT(frame->is_interpreted());

  const uword fp = frame->fp();
  const uword sp = arguments.GetCallerSP();
  ASSERT((fp < sp) && (sp <= frame->sp()));
  MSAN_UNPOISON(reinterpret_cast<uint8_t*>(fp), sp - fp);

  ObjectPtr* argv = reinterpret_cast<ObjectPtr*>(sp);
  uword target;
  if (function.is_ffi_native()) {
    const auto& bytecode = Bytecode::Handle(zone, function.GetBytecode());
    const auto& pool = ObjectPool::Handle(zone, bytecode.object_pool());
    target = pool.RawValueAt(pool_index);
    if (target == 0) {
      target = ResolveFfiNativeTarget(thread, function);
      ASSERT(target != 0);
      pool.SetRawValueAt(pool_index, target);
    }
  } else {
    target = Pointer::CheckedHandle(zone, argv[-1]).NativeAddress();
  }

  const intptr_t first_argument_parameter_offset =
      function.IsFfiCallClosure() ? 1 : 0;
  const auto& c_signature =
      FunctionType::ZoneHandle(zone, function.FfiCSignature());
  const bool is_leaf = function.FfiIsLeaf();

  // Used by compiler::ffi::CallMarshaller.
  CompilerState compiler_state(thread, /*is_aot=*/FLAG_precompiled_mode,
                               /*is_optimizing=*/false);

  const char* error = nullptr;
  const auto marshaller_ptr = compiler::ffi::CallMarshaller::FromFunction(
      zone, function, first_argument_parameter_offset, c_signature, &error);
  // AbiSpecificTypes can have an incomplete mapping.
  if (error != nullptr) {
    const auto& language_error = Error::Handle(
        LanguageError::New(String::Handle(String::New(error, Heap::kOld)),
                           Report::kError, Heap::kOld));
    Report::LongJump(language_error);
  }

  RELEASE_ASSERT(marshaller_ptr != nullptr);
  const auto& marshaller = *marshaller_ptr;
  const intptr_t stack_area_size =
      Utils::RoundUp(marshaller.RequiredStackSpaceInBytes(), kWordSize * 2);
  uint8_t* stack_area = zone->Alloc<uint8_t>(stack_area_size);

  FfiCallArguments args;
  memset(&args, 0, sizeof(args));
  args.stack_area = reinterpret_cast<uword>(stack_area);
  args.stack_area_end = reinterpret_cast<uword>(stack_area + stack_area_size);
  args.target = target;

  Api::Scope api_scope(thread);

  argv = argv - first_argument_parameter_offset - marshaller.num_args();

  if (is_leaf) {
    NoSafepointScope no_safepoint;

    PassFfiCallArguments(thread, marshaller, argv, &args);
    FfiCallTrampoline(&args);
  } else {
    PassFfiCallArguments(thread, marshaller, argv, &args);

    TransitionVMToNative transition(thread);
    FfiCallTrampoline(&args);
  }

  arguments.SetReturn(
      Object::Handle(zone, ReceiveFfiCallResult(thread, marshaller, &args)));
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES) && !defined(DART_PRECOMPILED_RUNTIME)
}

// Check that argument types are valid for the given function.
// Arg0: function
// Arg1: arguments descriptor
// Arg2: arguments
// Return value: whether the arguments are valid
DEFINE_RUNTIME_ENTRY(CheckFunctionArgumentTypes, 3) {
#if defined(DART_DYNAMIC_MODULES)
  const auto& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  const auto& descriptor = Array::CheckedHandle(zone, arguments.ArgAt(1));
  const auto& args = Array::CheckedHandle(zone, arguments.ArgAt(2));

  const ArgumentsDescriptor args_desc(descriptor);
  if (function.AreValidArguments(args_desc, nullptr)) {
    const auto& result =
        Object::Handle(zone, function.DoArgumentTypesMatch(args, args_desc));
    if (result.IsError()) {
      Exceptions::PropagateError(Error::Cast(result));
    }
    arguments.SetReturn(Bool::True());
  } else {
    arguments.SetReturn(Bool::False());
  }
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Helper routine for tracing a type check.
static void PrintTypeCheck(const char* message,
                           const Instance& instance,
                           const AbstractType& type,
                           const TypeArguments& instantiator_type_arguments,
                           const TypeArguments& function_type_arguments,
                           const Bool& result) {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);

  const AbstractType& instance_type =
      AbstractType::Handle(instance.GetType(Heap::kNew));
  ASSERT(instance_type.IsInstantiated() ||
         (instance.IsClosure() && instance_type.IsInstantiated(kCurrentClass)));
  LogBlock lb;
  if (type.IsInstantiated()) {
    THR_Print("%s: '%s' %d %s '%s' %d (pc: %#" Px ").\n", message,
              instance_type.NameCString(), instance_type.type_class_id(),
              (result.ptr() == Bool::True().ptr()) ? "is" : "is !",
              type.NameCString(), type.type_class_id(), caller_frame->pc());
  } else {
    // Instantiate type before printing.
    const AbstractType& instantiated_type = AbstractType::Handle(
        type.InstantiateFrom(instantiator_type_arguments,
                             function_type_arguments, kAllFree, Heap::kOld));
    THR_Print("%s: '%s' %s '%s' instantiated from '%s' (pc: %#" Px ").\n",
              message, instance_type.NameCString(),
              (result.ptr() == Bool::True().ptr()) ? "is" : "is !",
              instantiated_type.NameCString(), type.NameCString(),
              caller_frame->pc());
  }
  const Function& function =
      Function::Handle(caller_frame->LookupDartFunction());
  if (function.HasSavedArgumentsDescriptor()) {
    const auto& args_desc_array = Array::Handle(function.saved_args_desc());
    const ArgumentsDescriptor args_desc(args_desc_array);
    THR_Print(" -> Function %s [%s]\n", function.ToFullyQualifiedCString(),
              args_desc.ToCString());
  } else {
    THR_Print(" -> Function %s\n", function.ToFullyQualifiedCString());
  }
}

#if defined(TARGET_ARCH_IA32) || defined(DART_DYNAMIC_MODULES)
static BoolPtr CheckHashBasedSubtypeTestCache(
    Zone* zone,
    Thread* thread,
    const Instance& instance,
    const AbstractType& destination_type,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const SubtypeTestCache& cache) {
  ASSERT(cache.IsHash());
  // Record instances are not added to the cache as they don't have a valid
  // key (type of a record depends on types of all its fields).
  if (instance.IsRecord()) return Bool::null();
  Class& instance_class = Class::Handle(zone);
  if (instance.IsSmi()) {
    instance_class = Smi::Class();
  } else {
    instance_class = instance.clazz();
  }
  // If the type is uninstantiated and refers to parent function type
  // parameters, the function_type_arguments have been canonicalized
  // when concatenated.
  auto& instance_class_id_or_signature = Object::Handle(zone);
  auto& instance_type_arguments = TypeArguments::Handle(zone);
  auto& instance_parent_function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_delayed_type_arguments = TypeArguments::Handle(zone);
  if (instance_class.IsClosureClass()) {
    const auto& closure = Closure::Cast(instance);
    const auto& function = Function::Handle(zone, closure.function());
    instance_class_id_or_signature = function.signature();
    instance_type_arguments = closure.instantiator_type_arguments();
    instance_parent_function_type_arguments = closure.function_type_arguments();
    instance_delayed_type_arguments = closure.delayed_type_arguments();
  } else {
    instance_class_id_or_signature = Smi::New(instance_class.id());
    if (instance_class.NumTypeArguments() > 0) {
      instance_type_arguments = instance.GetTypeArguments();
    }
  }

  intptr_t index = -1;
  auto& result = Bool::Handle(zone);
  if (cache.HasCheck(instance_class_id_or_signature, destination_type,
                     instance_type_arguments, instantiator_type_arguments,
                     function_type_arguments,
                     instance_parent_function_type_arguments,
                     instance_delayed_type_arguments, &index, &result)) {
    return result.ptr();
  }

  return Bool::null();
}
#endif  // defined(TARGET_ARCH_IA32) || defined(DART_DYNAMIC_MODULES)

// This updates the type test cache, an array containing 8 elements:
// - instance class (or function if the instance is a closure)
// - instance type arguments (null if the instance class is not generic)
// - instantiator type arguments (null if the type is instantiated)
// - function type arguments (null if the type is instantiated)
// - instance parent function type arguments (null if instance is not a closure)
// - instance delayed type arguments (null if instance is not a closure)
// - destination type (null if the type was known at compile time)
// - test result
// It can be applied to classes with type arguments in which case it contains
// just the result of the class subtype test, not including the evaluation of
// type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
static void UpdateTypeTestCache(
    Zone* zone,
    Thread* thread,
    const Instance& instance,
    const AbstractType& destination_type,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const Bool& result,
    const SubtypeTestCache& new_cache) {
  ASSERT(!new_cache.IsNull());
  ASSERT(destination_type.IsCanonical());
  ASSERT(instantiator_type_arguments.IsCanonical());
  ASSERT(function_type_arguments.IsCanonical());
  if (instance.IsRecord()) {
    // Do not add record instances to cache as they don't have a valid
    // key (type of a record depends on types of all its fields).
    if (FLAG_trace_type_checks) {
      THR_Print("Not updating subtype test cache for the record instance.\n");
    }
    return;
  }
  Class& instance_class = Class::Handle(zone);
  if (instance.IsSmi()) {
    instance_class = Smi::Class();
  } else {
    instance_class = instance.clazz();
  }
  // If the type is uninstantiated and refers to parent function type
  // parameters, the function_type_arguments have been canonicalized
  // when concatenated.
  auto& instance_class_id_or_signature = Object::Handle(zone);
  auto& instance_type_arguments = TypeArguments::Handle(zone);
  auto& instance_parent_function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_delayed_type_arguments = TypeArguments::Handle(zone);
  if (instance_class.IsClosureClass()) {
    const auto& closure = Closure::Cast(instance);
    const auto& function = Function::Handle(zone, closure.function());
    instance_class_id_or_signature = function.signature();
    ASSERT(instance_class_id_or_signature.IsFunctionType());
    instance_type_arguments = closure.instantiator_type_arguments();
    instance_parent_function_type_arguments = closure.function_type_arguments();
    instance_delayed_type_arguments = closure.delayed_type_arguments();
    ASSERT(instance_class_id_or_signature.IsCanonical());
    ASSERT(instance_type_arguments.IsCanonical());
    ASSERT(instance_parent_function_type_arguments.IsCanonical());
    ASSERT(instance_delayed_type_arguments.IsCanonical());
  } else {
    instance_class_id_or_signature = Smi::New(instance_class.id());
    if (instance_class.NumTypeArguments() > 0) {
      instance_type_arguments = instance.GetTypeArguments();
      ASSERT(instance_type_arguments.IsCanonical());
    }
  }
  if (FLAG_trace_type_checks) {
    const auto& instance_class_name =
        String::Handle(zone, instance_class.Name());
    TextBuffer buffer(256);
    buffer.Printf("  Updating test cache %#" Px " with result %s for:\n",
                  static_cast<uword>(new_cache.ptr()), result.ToCString());
    if (instance.IsString()) {
      buffer.Printf("    instance: '%s'\n", instance.ToCString());
    } else {
      buffer.Printf("    instance: %s\n", instance.ToCString());
    }
    buffer.Printf("    class: %s (%" Pd ")\n", instance_class_name.ToCString(),
                  instance_class.id());
    buffer.Printf(
        "    raw entry: [ %#" Px ", %#" Px ", %#" Px ", %#" Px ", %#" Px
        ", %#" Px ", %#" Px ", %#" Px " ]\n",
        static_cast<uword>(instance_class_id_or_signature.ptr()),
        static_cast<uword>(instance_type_arguments.ptr()),
        static_cast<uword>(instantiator_type_arguments.ptr()),
        static_cast<uword>(function_type_arguments.ptr()),
        static_cast<uword>(instance_parent_function_type_arguments.ptr()),
        static_cast<uword>(instance_delayed_type_arguments.ptr()),
        static_cast<uword>(destination_type.ptr()),
        static_cast<uword>(result.ptr()));
    THR_Print("%s", buffer.buffer());
  }
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->subtype_test_cache_mutex());
    const intptr_t len = new_cache.NumberOfChecks();
    if (len >= FLAG_max_subtype_cache_entries) {
      if (FLAG_trace_type_checks) {
        THR_Print("Not updating subtype test cache as its length reached %d\n",
                  FLAG_max_subtype_cache_entries);
      }
      return;
    }
    intptr_t colliding_index = -1;
    auto& old_result = Bool::Handle(zone);
    if (new_cache.HasCheck(
            instance_class_id_or_signature, destination_type,
            instance_type_arguments, instantiator_type_arguments,
            function_type_arguments, instance_parent_function_type_arguments,
            instance_delayed_type_arguments, &colliding_index, &old_result)) {
      if (FLAG_trace_type_checks) {
        TextBuffer buffer(256);
        buffer.Printf("  Collision for test cache %#" Px " at index %" Pd ":\n",
                      static_cast<uword>(new_cache.ptr()), colliding_index);
        buffer.Printf("    entry: ");
        new_cache.WriteEntryToBuffer(zone, &buffer, colliding_index, "      ");
        THR_Print("%s\n", buffer.buffer());
      }
      if (old_result.ptr() != result.ptr()) {
        FATAL("Existing subtype test cache entry has result %s, not %s",
              old_result.ToCString(), result.ToCString());
      }
      // Some other isolate might have updated the cache between entry was
      // found missing and now.
      return;
    }
    const intptr_t new_index = new_cache.AddCheck(
        instance_class_id_or_signature, destination_type,
        instance_type_arguments, instantiator_type_arguments,
        function_type_arguments, instance_parent_function_type_arguments,
        instance_delayed_type_arguments, result);
    if (FLAG_trace_type_checks) {
      TextBuffer buffer(256);
      buffer.Printf("  Added new entry to test cache %#" Px " at index %" Pd
                    ":\n",
                    static_cast<uword>(new_cache.ptr()), new_index);
      buffer.Printf("    new entry: ");
      new_cache.WriteEntryToBuffer(zone, &buffer, new_index, "      ");
      THR_Print("%s\n", buffer.buffer());
    }
  }
}

// Check that the given instance is an instance of the given type.
// Tested instance may be null, because a null test cannot always be inlined,
// e.g 'null is T' yields true if T = Null, but false if T = bool.
// Arg0: instance being checked.
// Arg1: type.
// Arg2: type arguments of the instantiator of the type.
// Arg3: type arguments of the function of the type.
// Arg4: SubtypeTestCache.
// Return value: true or false.
DEFINE_RUNTIME_ENTRY(Instanceof, 5) {
  const Instance& instance = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(zone, arguments.ArgAt(4));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsDynamicType());  // No need to check assignment.
  ASSERT(!cache.IsNull());
#if defined(TARGET_ARCH_IA32)
  // Hash-based caches are still not handled by the stubs on IA32.
  if (cache.IsHash()) {
    const auto& result = Bool::Handle(
        zone, CheckHashBasedSubtypeTestCache(zone, thread, instance, type,
                                             instantiator_type_arguments,
                                             function_type_arguments, cache));
    if (!result.IsNull()) {
      // Early exit because an entry already exists in the cache.
      arguments.SetReturn(result);
      return;
    }
  }
#endif  // defined(TARGET_ARCH_IA32)
  const Bool& result = Bool::Get(instance.IsInstanceOf(
      type, instantiator_type_arguments, function_type_arguments));
  if (FLAG_trace_type_checks) {
    PrintTypeCheck("InstanceOf", instance, type, instantiator_type_arguments,
                   function_type_arguments, result);
  }
  UpdateTypeTestCache(zone, thread, instance, type, instantiator_type_arguments,
                      function_type_arguments, result, cache);
  arguments.SetReturn(result);
}

#if defined(TESTING)
// Used only in type_testing_stubs_test.cc. If DRT_TypeCheck is entered, then
// this flag is set to true.
thread_local bool TESTING_runtime_entered_on_TTS_invocation = false;
#endif

// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
// Tested instance may not be null, because a null test is always inlined.
// Arg0: instance being assigned.
// Arg1: type being assigned to.
// Arg2: type arguments of the instantiator of the type being assigned to.
// Arg3: type arguments of the function of the type being assigned to.
// Arg4: name of variable being assigned to.
// Arg5: SubtypeTestCache.
// Arg6: invocation mode (see TypeCheckMode)
// Return value: instance if a subtype, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 7) {
  const Instance& src_instance =
      Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const AbstractType& dst_type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  String& dst_name = String::Handle(zone);
  dst_name ^= arguments.ArgAt(4);
  ASSERT(dst_name.IsNull() || dst_name.IsString());

  SubtypeTestCache& cache = SubtypeTestCache::Handle(zone);
  cache ^= arguments.ArgAt(5);
  ASSERT(cache.IsNull() || cache.IsSubtypeTestCache());

  const TypeCheckMode mode = static_cast<TypeCheckMode>(
      Smi::CheckedHandle(zone, arguments.ArgAt(6)).Value());

#if defined(TESTING)
  TESTING_runtime_entered_on_TTS_invocation = true;
#endif

#if defined(TARGET_ARCH_IA32)
  ASSERT(mode == kTypeCheckFromInline);
#endif

#if defined(TARGET_ARCH_IA32) || defined(DART_DYNAMIC_MODULES)
  // Hash-based caches are not handled by the inline AssertAssignable
  // on IA32 and in the interpreter.
  if ((mode == kTypeCheckFromInline) && cache.IsHash()) {
    const auto& result = Bool::Handle(
        zone, CheckHashBasedSubtypeTestCache(
                  zone, thread, src_instance, dst_type,
                  instantiator_type_arguments, function_type_arguments, cache));
    if (!result.IsNull()) {
      // Early exit because an entry already exists in the cache.
      arguments.SetReturn(result);
      return;
    }
  }
#endif  // defined(TARGET_ARCH_IA32) || defined(DART_DYNAMIC_MODULES)

  // This is guaranteed on the calling side.
  ASSERT(!dst_type.IsDynamicType());

  const bool is_instance_of = src_instance.IsInstanceOf(
      dst_type, instantiator_type_arguments, function_type_arguments);

  if (FLAG_trace_type_checks) {
    PrintTypeCheck("TypeCheck", src_instance, dst_type,
                   instantiator_type_arguments, function_type_arguments,
                   Bool::Get(is_instance_of));
  }

  // Most paths through this runtime entry don't need to know what the
  // destination name was or if this was a dynamic assert assignable call,
  // so only walk the stack to find the stored destination name when necessary.
  auto resolve_dst_name = [&]() {
    if (!dst_name.IsNull()) return;
#if !defined(TARGET_ARCH_IA32)
    // Can only come here from type testing stub.
    ASSERT(mode != kTypeCheckFromInline);

    // Grab the [dst_name] from the pool.  It's stored at one pool slot after
    // the subtype-test-cache.
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    const Code& caller_code =
        Code::Handle(zone, caller_frame->LookupDartCode());
    const ObjectPool& pool =
        ObjectPool::Handle(zone, caller_code.GetObjectPool());
    TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
    const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();
    const intptr_t dst_name_idx = stc_pool_idx + 1;
    dst_name ^= pool.ObjectAt(dst_name_idx);
#else
    UNREACHABLE();
#endif
  };

  if (!is_instance_of) {
    resolve_dst_name();
    if (dst_name.ptr() ==
        Symbols::dynamic_assert_assignable_stc_check().ptr()) {
#if !defined(TARGET_ARCH_IA32)
      // Can only come here from type testing stub via dynamic AssertAssignable.
      ASSERT(mode != kTypeCheckFromInline);
#endif
      // This was a dynamic closure call where the destination name was not
      // known at compile-time. Thus, fetch the original arguments and arguments
      // descriptor and re-do the type check  in the runtime, which causes the
      // error with the proper destination name to be thrown.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      ASSERT(!caller_frame->is_interpreted());
      const auto& dispatcher =
          Function::Handle(zone, caller_frame->LookupDartFunction());
      ASSERT(dispatcher.IsInvokeFieldDispatcher());
      const auto& orig_arguments_desc =
          Array::Handle(zone, dispatcher.saved_args_desc());
      const ArgumentsDescriptor args_desc(orig_arguments_desc);
      const intptr_t arg_count = args_desc.CountWithTypeArgs();
      const auto& orig_arguments = Array::Handle(zone, Array::New(arg_count));
      auto& obj = Object::Handle(zone);
      for (intptr_t i = 0; i < arg_count; i++) {
        obj = *reinterpret_cast<ObjectPtr*>(
            ParamAddress(caller_frame->fp(), arg_count - i));
        orig_arguments.SetAt(i, obj);
      }
      const auto& receiver = Closure::CheckedHandle(
          zone, orig_arguments.At(args_desc.FirstArgIndex()));
      const auto& function = Function::Handle(zone, receiver.function());
      const auto& result = Object::Handle(
          zone, function.DoArgumentTypesMatch(orig_arguments, args_desc));
      if (result.IsError()) {
        Exceptions::PropagateError(Error::Cast(result));
      }
      // IsInstanceOf returned false, so we should have thrown a type
      // error in DoArgumentsTypesMatch.
      UNREACHABLE();
    }

    ASSERT(!dst_name.IsNull());
    // Throw a dynamic type error.
    const TokenPosition location = GetCallerLocation();
    const auto& src_type =
        AbstractType::Handle(zone, src_instance.GetType(Heap::kNew));
    auto& reported_type = AbstractType::Handle(zone, dst_type.ptr());
    if (!reported_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      reported_type = reported_type.InstantiateFrom(instantiator_type_arguments,
                                                    function_type_arguments,
                                                    kAllFree, Heap::kNew);
    }
    Exceptions::CreateAndThrowTypeError(location, src_type, reported_type,
                                        dst_name);
    UNREACHABLE();
  }

  bool should_update_cache = true;
#if !defined(TARGET_ARCH_IA32)
  bool would_update_cache_if_not_lazy = false;
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Checks against type parameters are done by loading the corresponding type
  // argument at runtime and calling the type argument's TTS. Thus, we install
  // specialized TTSes on the type argument, not the parameter itself.
  auto& tts_type = AbstractType::Handle(zone, dst_type.ptr());
  if (tts_type.IsTypeParameter()) {
    const auto& param = TypeParameter::Cast(tts_type);
    tts_type = param.GetFromTypeArguments(instantiator_type_arguments,
                                          function_type_arguments);
  }
  ASSERT(!tts_type.IsTypeParameter());

  if (mode == kTypeCheckFromLazySpecializeStub) {
    if (FLAG_trace_type_checks) {
      THR_Print("  Specializing type testing stub for %s\n",
                tts_type.ToCString());
    }
    const Code& code = Code::Handle(
        zone, TypeTestingStubGenerator::SpecializeStubFor(thread, tts_type));
    tts_type.SetTypeTestingStub(code);

    // Only create the cache if we failed to create a specialized TTS and doing
    // the same check would cause an update to the cache.
    would_update_cache_if_not_lazy =
        (!src_instance.IsNull() &&
         tts_type.type_test_stub() ==
             StubCode::DefaultNullableTypeTest().ptr()) ||
        tts_type.type_test_stub() == StubCode::DefaultTypeTest().ptr();
    should_update_cache = would_update_cache_if_not_lazy && cache.IsNull();
  }

  // Since dst_type is not a top type or type parameter, then the only default
  // stubs it can use are DefaultTypeTest or DefaultNullableTypeTest.
  if ((mode == kTypeCheckFromSlowStub) &&
      (tts_type.type_test_stub() != StubCode::DefaultNullableTypeTest().ptr() &&
       tts_type.type_test_stub() != StubCode::DefaultTypeTest().ptr())) {
    // The specialized type testing stub returned a false negative. That means
    // the specialization may have been generated using outdated cid ranges and
    // new classes appeared since the stub was generated. Try respecializing.
    if (FLAG_trace_type_checks) {
      THR_Print("  Rebuilding type testing stub for %s\n",
                tts_type.ToCString());
    }
    const auto& old_code = Code::Handle(zone, tts_type.type_test_stub());
    const auto& new_code = Code::Handle(
        zone, TypeTestingStubGenerator::SpecializeStubFor(thread, tts_type));
    ASSERT(old_code.ptr() != new_code.ptr());
    // A specialized stub should always respecialize to a non-default stub.
    ASSERT(new_code.ptr() != StubCode::DefaultNullableTypeTest().ptr() &&
           new_code.ptr() != StubCode::DefaultTypeTest().ptr());
    const auto& old_instructions =
        Instructions::Handle(old_code.instructions());
    const auto& new_instructions =
        Instructions::Handle(new_code.instructions());
    // Check if specialization produced exactly the same sequence of
    // instructions. If it did, then we have a false negative, which can
    // happen in some cases involving uninstantiated types. In these cases,
    // update the cache, because the only case in which these false negatives
    // could possibly turn into true positives is with reloads, which clear
    // all the SubtypeTestCaches.
    should_update_cache = old_instructions.Equals(new_instructions);
    if (FLAG_trace_type_checks) {
      THR_Print("  %s rebuilt type testing stub for %s\n",
                should_update_cache ? "Discarding" : "Installing",
                tts_type.ToCString());
    }
    if (!should_update_cache) {
      tts_type.SetTypeTestingStub(new_code);
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(TARGET_ARCH_IA32)

  if (should_update_cache) {
    if (cache.IsNull()) {
#if !defined(TARGET_ARCH_IA32)
      ASSERT(mode == kTypeCheckFromSlowStub ||
             (mode == kTypeCheckFromLazySpecializeStub &&
              would_update_cache_if_not_lazy));
      // We lazily create [SubtypeTestCache] for those call sites which actually
      // need one and will patch the pool entry.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      ASSERT(!caller_frame->is_interpreted());
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const ObjectPool& pool =
          ObjectPool::Handle(zone, caller_code.GetObjectPool());
      TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
      const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();
      // Ensure we do have a STC (lazily create it if not) and all threads use
      // the same STC.
      {
        SafepointMutexLocker ml(
            thread->isolate_group()->subtype_test_cache_mutex());
        cache ^= pool.ObjectAt<std::memory_order_acquire>(stc_pool_idx);
        if (cache.IsNull()) {
          resolve_dst_name();
          // If this is a dynamic AssertAssignable check, then we must assume
          // all inputs may be needed, as the type may vary from call to call.
          const intptr_t num_inputs =
              dst_name.ptr() ==
                      Symbols::dynamic_assert_assignable_stc_check().ptr()
                  ? SubtypeTestCache::kMaxInputs
                  : SubtypeTestCache::UsedInputsForType(dst_type);
          cache = SubtypeTestCache::New(num_inputs);
          pool.SetObjectAt<std::memory_order_release>(stc_pool_idx, cache);
          if (FLAG_trace_type_checks) {
            THR_Print("  Installed new subtype test cache %#" Px " with %" Pd
                      " inputs at index %" Pd " of pool for %s\n",
                      static_cast<uword>(cache.ptr()), num_inputs, stc_pool_idx,
                      caller_code.ToCString());
          }
        }
      }
#else
      UNREACHABLE();
#endif
    }

    UpdateTypeTestCache(zone, thread, src_instance, dst_type,
                        instantiator_type_arguments, function_type_arguments,
                        Bool::True(), cache);
  }

  arguments.SetReturn(src_instance);
}

DEFINE_RUNTIME_ENTRY(Throw, 1) {
  if (FLAG_gc_at_throw) {
    thread->isolate_group()->heap()->CollectGarbage(thread, GCType::kEvacuate,
                                                    GCReason::kDebugging);
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging,
                                                       /*compact=*/true);
  }

  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::Throw(thread, exception);
}

DEFINE_RUNTIME_ENTRY(ReThrow, 3) {
  if (FLAG_gc_at_throw) {
    thread->isolate_group()->heap()->CollectGarbage(thread, GCType::kEvacuate,
                                                    GCReason::kDebugging);
    thread->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging,
                                                       /*compact=*/true);
  }

  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const Smi& bypass_debugger = Smi::CheckedHandle(zone, arguments.ArgAt(2));
  Exceptions::ReThrow(thread, exception, stacktrace,
                      bypass_debugger.Value() != 0);
}

// Patches static call in optimized code with the target's entry point.
// Compiles target if necessary.
DEFINE_RUNTIME_ENTRY(PatchStaticCall, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  ASSERT(!caller_frame->is_interpreted());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(caller_frame->pc()));
  const Code& target_code = Code::Handle(zone, target_function.EnsureHasCode());
  // Before patching verify that we are not repeatedly patching to the same
  // target.
  if (target_code.ptr() !=
      CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code)) {
    GcSafepointOperationScope safepoint(thread);
    if (target_code.ptr() !=
        CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code)) {
      CodePatcher::PatchStaticCallAt(caller_frame->pc(), caller_code,
                                     target_code);
      caller_code.SetStaticCallTargetCodeAt(caller_frame->pc(), target_code);
      if (FLAG_trace_patching) {
        THR_Print("PatchStaticCall: patching caller pc %#" Px
                  ""
                  " to '%s' new entry point %#" Px " (%s)\n",
                  caller_frame->pc(), target_function.ToFullyQualifiedCString(),
                  target_code.EntryPoint(),
                  target_code.is_optimized() ? "optimized" : "unoptimized");
      }
    }
  }
  arguments.SetReturn(target_code);
#else
  UNREACHABLE();
#endif
}

#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  UNREACHABLE();
  return;
}
#else
// Gets called from debug stub when code reaches a breakpoint
// set on a runtime stub call.
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  Object& orig_value = Object::Handle(zone);
  if (!caller_frame->is_interpreted()) {
    orig_value = thread->isolate_group()->debugger()->GetPatchedStubAddress(
        caller_frame->pc());
  } else {
    orig_value = Smi::New(thread->isolate_group()->debugger()->GetPatchedOpcode(
        caller_frame->pc()));
  }
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseBreakpoint());
  ThrowIfError(error);
  arguments.SetReturn(orig_value);
}
#endif

DEFINE_RUNTIME_ENTRY(SingleStepHandler, 0) {
#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseStepping());
  ThrowIfError(error);
#endif
}

DEFINE_RUNTIME_ENTRY(ResumptionBreakpointHandler, 0) {
#if defined(DART_DYNAMIC_MODULES) && !defined(PRODUCT)
  isolate->debugger()->ResumptionBreakpoint();
#else
  UNREACHABLE();
#endif
}

// An instance call of the form o.f(...) could not be resolved.  Check if
// there is a getter with the same name.  If so, invoke it.  If the value is
// a closure, invoke it with the given arguments.  If the value is a
// non-closure, attempt to invoke "call" on it.
static bool ResolveCallThroughGetter(const Class& receiver_class,
                                     const String& target_name,
                                     const String& demangled,
                                     const Array& arguments_descriptor,
                                     Function* result) {
  const bool create_if_absent = !FLAG_precompiled_mode;
  const String& getter_name = String::Handle(Field::GetterName(demangled));
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& getter =
      Function::Handle(Resolver::ResolveDynamicForReceiverClass(
          receiver_class, getter_name, args_desc, create_if_absent));
  if (getter.IsNull() || getter.IsMethodExtractor()) {
    return false;
  }
  // We do this on the target_name, _not_ on the demangled name, so that
  // FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher can detect dynamic
  // calls from the dyn: tag on the name of the dispatcher.
  const String& dispatcher_name = Function::DropImplicitCallPrefix(target_name);
  const Function& target_function =
      Function::Handle(receiver_class.GetInvocationDispatcher(
          dispatcher_name, arguments_descriptor,
          UntaggedFunction::kInvokeFieldDispatcher, create_if_absent));
  ASSERT(!create_if_absent || !target_function.IsNull());
  if (FLAG_trace_ic) {
    OS::PrintErr(
        "InvokeField IC miss: adding <%s> id:%" Pd " -> <%s>\n",
        receiver_class.ToCString(), receiver_class.id(),
        target_function.IsNull() ? "null" : target_function.ToCString());
  }
  *result = target_function.ptr();
  return true;
}

// Handle other invocations (implicit closures, noSuchMethod).
FunctionPtr InlineCacheMissHelper(const Class& receiver_class,
                                  const Array& args_descriptor,
                                  const String& target_name) {
  // Create a demangled version of the target_name, if necessary, This is used
  // for the field getter in ResolveCallThroughGetter and as the target name
  // for the NoSuchMethod dispatcher (if needed).
  const String* demangled = &target_name;
  if (Function::IsDynamicInvocationForwarderName(target_name)) {
    demangled = &String::Handle(
        Function::DemangleDynamicInvocationForwarderName(target_name));
  }
  const bool is_getter = Field::IsGetterName(*demangled);
  const bool is_dyn_implicit_call =
      target_name.ptr() == Symbols::DynamicImplicitCall().ptr();
  Function& result = Function::Handle();
#if defined(DART_PRECOMPILED_RUNTIME)
  const bool create_if_absent = false;
#else
  const bool create_if_absent = true;
#endif
  if (is_getter || (is_dyn_implicit_call && !receiver_class.IsClosureClass()) ||
      !ResolveCallThroughGetter(receiver_class, target_name, *demangled,
                                args_descriptor, &result)) {
    ArgumentsDescriptor desc(args_descriptor);
    const Function& target_function =
        Function::Handle(receiver_class.GetInvocationDispatcher(
            *demangled, args_descriptor,
            UntaggedFunction::kNoSuchMethodDispatcher, create_if_absent));
    if (FLAG_trace_ic) {
      OS::PrintErr(
          "NoSuchMethod IC miss: adding <%s> id:%" Pd " -> <%s>\n",
          receiver_class.ToCString(), receiver_class.id(),
          target_function.IsNull() ? "null" : target_function.ToCString());
    }
    result = target_function.ptr();
  }
  // May be null if in the precompiled runtime, in which case dispatch will be
  // handled by NoSuchMethodFromCallStub.
  ASSERT(!create_if_absent || !result.IsNull());
  return result.ptr();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static void TrySwitchInstanceCall(Thread* thread,
                                  StackFrame* caller_frame,
                                  const Code& caller_code,
                                  const Function& caller_function,
                                  const ICData& ic_data,
                                  const Function& target_function) {
  ASSERT(!target_function.IsNull());
  auto zone = thread->zone();

  // Monomorphic/megamorphic calls only check the receiver CID.
  if (ic_data.NumArgsTested() != 1) return;

  ASSERT(ic_data.rebind_rule() == ICData::kInstance);

  // Monomorphic/megamorphic calls don't record exactness.
  if (ic_data.is_tracking_exactness()) return;

#if !defined(PRODUCT)
  // Monomorphic/megamorphic do not check the isolate's stepping flag.
  if (thread->isolate_group()->has_attempted_stepping()) return;
#endif

  // Monomorphic/megamorphic calls are only for unoptimized code.
  if (caller_frame->is_interpreted()) return;
  ASSERT(!caller_code.is_optimized());

  // Code is detached from its function. This will prevent us from resetting
  // the switchable call later because resets are function based and because
  // the ic_data_array belongs to the function instead of the code. This should
  // only happen because of reload, but it sometimes happens with KBC mixed mode
  // probably through a race between foreground and background compilation.
  if (caller_function.unoptimized_code() != caller_code.ptr()) {
    return;
  }
#if !defined(PRODUCT)
  // Skip functions that contain breakpoints or when debugger is in single
  // stepping mode.
  if (thread->isolate_group()->debugger()->IsDebugging(thread,
                                                       caller_function)) {
    return;
  }
#endif

  const intptr_t num_checks = ic_data.NumberOfChecks();

  // Monomorphic call.
  if (FLAG_unopt_monomorphic_calls && (num_checks == 1)) {
    // A call site in the monomorphic state does not load the arguments
    // descriptor, so do not allow transition to this state if the callee
    // needs it.
    if (target_function.PrologueNeedsArgumentsDescriptor()) {
      return;
    }

    const Array& data = Array::Handle(zone, ic_data.entries());
    const Code& target = Code::Handle(zone, target_function.EnsureHasCode());
    CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, data,
                                     target);
    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " switching to monomorphic dispatch, %s\n",
                   caller_frame->pc(), ic_data.ToCString());
    }
    return;  // Success.
  }

  // Megamorphic call.
  if (FLAG_unopt_megamorphic_calls &&
      (num_checks > FLAG_max_polymorphic_checks)) {
    const String& name = String::Handle(zone, ic_data.target_name());
    const Array& descriptor =
        Array::Handle(zone, ic_data.arguments_descriptor());
    const MegamorphicCache& cache = MegamorphicCache::Handle(
        zone, MegamorphicCacheTable::Lookup(thread, name, descriptor));
    ic_data.set_is_megamorphic(true);
    CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, cache,
                                     StubCode::MegamorphicCall());
    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " switching to megamorphic dispatch, %s\n",
                   caller_frame->pc(), ic_data.ToCString());
    }
    return;  // Success.
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Perform the subtype and return constant function based on the result.
static FunctionPtr ComputeTypeCheckTarget(const Instance& receiver,
                                          const AbstractType& type,
                                          const ArgumentsDescriptor& desc) {
  const bool result = receiver.IsInstanceOf(type, Object::null_type_arguments(),
                                            Object::null_type_arguments());
  const ObjectStore* store = IsolateGroup::Current()->object_store();
  const Function& target =
      Function::Handle(result ? store->simple_instance_of_true_function()
                              : store->simple_instance_of_false_function());
  ASSERT(!target.IsNull());
  return target.ptr();
}

static FunctionPtr Resolve(
    Thread* thread,
    Zone* zone,
    const GrowableArray<const Instance*>& caller_arguments,
    const Class& receiver_class,
    const String& name,
    const Array& descriptor) {
  ASSERT(name.IsSymbol());
  auto& target_function = Function::Handle(zone);
  ArgumentsDescriptor args_desc(descriptor);

  const bool allow_add = !FLAG_precompiled_mode;
  if (receiver_class.EnsureIsFinalized(thread) == Error::null()) {
    target_function = Resolver::ResolveDynamicForReceiverClass(
        receiver_class, name, args_desc, allow_add);
  }
  if (caller_arguments.length() == 2 &&
      target_function.ptr() == thread->isolate_group()
                                   ->object_store()
                                   ->simple_instance_of_function()) {
    // Replace the target function with constant function.
    const AbstractType& type = AbstractType::Cast(*caller_arguments[1]);
    target_function =
        ComputeTypeCheckTarget(*caller_arguments[0], type, args_desc);
  }

  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver_class, descriptor, name);
  }
  ASSERT(!allow_add || !target_function.IsNull());
  return target_function.ptr();
}

// Handles a static call in unoptimized code that has one argument type not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument.
// Arg1: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerOneArg, 2) {
  const Instance& arg = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(ic_data.NumberOfChecksIs(1));
  const Function& target = Function::Handle(zone, ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  ASSERT(!target.IsNull() && target.HasCode());
  ic_data.EnsureHasReceiverCheck(arg.GetClassId(), target, 1);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != nullptr);
    OS::PrintErr("StaticCallMissHandler at %#" Px " target %s (%" Pd ")\n",
                 caller_frame->pc(), target.ToCString(), arg.GetClassId());
  }
  arguments.SetReturn(target);
}

// Handles a static call in unoptimized code that has two argument types not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument 0.
// Arg1: argument 1.
// Arg2: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerTwoArgs, 3) {
  const Instance& arg0 = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& arg1 = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(!ic_data.NumberOfChecksIs(0));
  const Function& target = Function::Handle(zone, ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  GrowableArray<intptr_t> cids(2);
  cids.Add(arg0.GetClassId());
  cids.Add(arg1.GetClassId());
  ic_data.EnsureHasCheck(cids, target);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != nullptr);
    OS::PrintErr("StaticCallMissHandler at %#" Px " target %s (%" Pd ", %" Pd
                 ")\n",
                 caller_frame->pc(), target.ToCString(), cids[0], cids[1]);
  }
  arguments.SetReturn(target);
}

#if defined(DART_PRECOMPILED_RUNTIME)

static bool IsSingleTarget(IsolateGroup* isolate_group,
                           Zone* zone,
                           intptr_t lower_cid,
                           intptr_t upper_cid,
                           const Function& target,
                           const String& name) {
  Class& cls = Class::Handle(zone);
  ClassTable* table = isolate_group->class_table();
  Function& other_target = Function::Handle(zone);
  for (intptr_t cid = lower_cid; cid <= upper_cid; cid++) {
    if (!table->HasValidClassAt(cid)) continue;
    cls = table->At(cid);
    if (cls.is_abstract()) continue;
    if (!cls.is_allocated()) continue;
    other_target = Resolver::ResolveDynamicAnyArgs(zone, cls, name,
                                                   /*allow_add=*/false);
    if (other_target.ptr() != target.ptr()) {
      return false;
    }
  }
  return true;
}

class SavedUnlinkedCallMapKeyEqualsTraits : public AllStatic {
 public:
  static const char* Name() { return "SavedUnlinkedCallMapKeyEqualsTraits "; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& key1, const Object& key2) {
    if (!key1.IsInteger() || !key2.IsInteger()) return false;
    return Integer::Cast(key1).Equals(Integer::Cast(key2));
  }
  static uword Hash(const Object& key) {
    return Integer::Cast(key).CanonicalizeHash();
  }
};

using UnlinkedCallMap = UnorderedHashMap<SavedUnlinkedCallMapKeyEqualsTraits>;

static void SaveUnlinkedCall(Zone* zone,
                             IsolateGroup* isolate_group,
                             uword frame_pc,
                             const UnlinkedCall& unlinked_call) {
  SafepointMutexLocker ml(isolate_group->unlinked_call_map_mutex());
  if (isolate_group->saved_unlinked_calls() == Array::null()) {
    const auto& initial_map =
        Array::Handle(zone, HashTables::New<UnlinkedCallMap>(16, Heap::kOld));
    isolate_group->set_saved_unlinked_calls(initial_map);
  }

  UnlinkedCallMap unlinked_call_map(zone,
                                    isolate_group->saved_unlinked_calls());
  const auto& pc = Integer::Handle(zone, Integer::NewFromUint64(frame_pc));
  // Some other isolate might have updated unlinked_call_map[pc] too, but
  // their update should be identical to ours.
  const auto& new_or_old_value = UnlinkedCall::Handle(
      zone, UnlinkedCall::RawCast(
                unlinked_call_map.InsertOrGetValue(pc, unlinked_call)));
  RELEASE_ASSERT(new_or_old_value.ptr() == unlinked_call.ptr());
  isolate_group->set_saved_unlinked_calls(unlinked_call_map.Release());
}

static UnlinkedCallPtr LoadUnlinkedCall(Zone* zone,
                                        IsolateGroup* isolate_group,
                                        uword pc) {
  SafepointMutexLocker ml(isolate_group->unlinked_call_map_mutex());
  ASSERT(isolate_group->saved_unlinked_calls() != Array::null());
  UnlinkedCallMap unlinked_call_map(zone,
                                    isolate_group->saved_unlinked_calls());

  const auto& pc_integer = Integer::Handle(zone, Integer::NewFromUint64(pc));
  const auto& unlinked_call = UnlinkedCall::Cast(
      Object::Handle(zone, unlinked_call_map.GetOrDie(pc_integer)));
  isolate_group->set_saved_unlinked_calls(unlinked_call_map.Release());
  return unlinked_call.ptr();
}

// NOTE: Right now we never delete [UnlinkedCall] objects. They are needed while
// a call site is in Unlinked/Monomorphic/MonomorphicSmiable/SingleTarget
// states.
//
// Theoretically we could free the [UnlinkedCall] object once we transition the
// call site to use ICData/MegamorphicCache, but that would require careful
// coordination between the deleter and a possible concurrent reader.
//
// To simplify the code we decided not to do that atm (only a very small
// fraction of callsites in AOT use switchable calls, the name/args-descriptor
// objects are kept alive anyways -> there is little memory savings from
// freeing the [UnlinkedCall] objects).

#endif  // defined(DART_PRECOMPILED_RUNTIME)

enum class MissHandler {
  kInlineCacheMiss,
  kSwitchableCallMiss,
  kFixCallersTargetMonomorphic,
};

// Handles updating of type feedback and possible patching of instance calls.
//
// It works in 3 separate steps:
//   - resolve the actual target
//   - update type feedback & (optionally) perform call site transition
//   - return the right values
//
// Depending on the JIT/AOT mode we obtain current and patch new (target, data)
// differently:
//
//   - JIT calls must be patched with CodePatcher::PatchInstanceCallAt()
//   - AOT calls must be patched with CodePatcher::PatchSwitchableCallAt()
//
// Independent of which miss handler was used or how we will return, we look at
// current (target, data) and see if we need to transition the call site to a
// new (target, data). We do this while holding `IG->patchable_call_mutex()`.
//
// Depending on which miss handler got called we might need to return
// differently:
//
//   - SwitchableCallMiss will get get (stub, data) return value
//   - InlineCache*Miss will get get function as return value
//
class PatchableCallHandler {
 public:
  PatchableCallHandler(Thread* thread,
                       const GrowableArray<const Instance*>& caller_arguments,
                       MissHandler miss_handler,
                       NativeArguments arguments,
                       StackFrame* caller_frame,
                       const Code& caller_code,
                       const Function& caller_function)
      : isolate_group_(thread->isolate_group()),
        thread_(thread),
        zone_(thread->zone()),
        caller_arguments_(caller_arguments),
        miss_handler_(miss_handler),
        arguments_(arguments),
        caller_frame_(caller_frame),
        caller_code_(caller_code),
        caller_function_(caller_function),
        name_(String::Handle()),
        args_descriptor_(Array::Handle()) {
    // We only have two arg IC calls in JIT mode.
    ASSERT(caller_arguments_.length() == 1 || !FLAG_precompiled_mode);
  }

  void ResolveSwitchAndReturn(const Object& data);

 private:
  FunctionPtr ResolveTargetFunction(const Object& data);

#if defined(DART_PRECOMPILED_RUNTIME)
  void HandleMissAOT(const Object& old_data,
                     uword old_entry,
                     const Function& target_function);

  void DoUnlinkedCallAOT(const UnlinkedCall& unlinked,
                         const Function& target_function);
  void DoMonomorphicMissAOT(const Object& old_data,
                            const Function& target_function);
  void DoSingleTargetMissAOT(const SingleTargetCache& data,
                             const Function& target_function);
  void DoICDataMissAOT(const ICData& data, const Function& target_function);
  bool CanExtendSingleTargetRange(const String& name,
                                  const Function& old_target,
                                  const Function& target_function,
                                  intptr_t* lower,
                                  intptr_t* upper);
#else
  void HandleMissJIT(const Object& old_data,
                     const Code& old_target,
                     const Function& target_function);

  void DoMonomorphicMissJIT(const Object& old_data,
                            const Function& target_function);
  void DoICDataMissJIT(const ICData& data,
                       const Object& old_data,
                       const Function& target_function);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  void DoMegamorphicMiss(const MegamorphicCache& data,
                         const Function& target_function);

  void UpdateICDataWithTarget(const ICData& ic_data,
                              const Function& target_function);
  void TrySwitch(const ICData& ic_data, const Function& target_function);

  void ReturnAOT(const Code& stub, const Object& data);
  void ReturnJIT(const Code& stub, const Object& data, const Function& target);
  void ReturnJITorAOT(const Code& stub,
                      const Object& data,
                      const Function& target);

  const Instance& receiver() { return *caller_arguments_[0]; }

  bool should_consider_patching() {
    // In AOT we use switchable calls.
    if (FLAG_precompiled_mode) return true;

    // In JIT instance calls use a different calling sequence in unoptimized vs
    // optimized code (see [FlowGraphCompiler::EmitInstanceCallJIT] vs
    // [FlowGraphCompiler::EmitOptimizedInstanceCall]).
    //
    // The [CodePatcher::GetInstanceCallAt], [CodePatcher::PatchInstanceCallAt]
    // only recognize unoptimized call pattern.
    //
    // So we will not try to switch optimized instance calls.
    return !caller_code_.is_optimized();
  }

  ICDataPtr NewICData();
  ICDataPtr NewICDataWithTarget(intptr_t cid, const Function& target);

  IsolateGroup* isolate_group_;
  Thread* thread_;
  Zone* zone_;
  const GrowableArray<const Instance*>& caller_arguments_;
  MissHandler miss_handler_;
  NativeArguments arguments_;
  StackFrame* caller_frame_;
  const Code& caller_code_;
  const Function& caller_function_;

  // Call-site information populated during resolution.
  String& name_;
  Array& args_descriptor_;
  bool is_monomorphic_hit_ = false;
};

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoUnlinkedCallAOT(const UnlinkedCall& unlinked,
                                             const Function& target_function) {
  const auto& ic_data = ICData::Handle(
      zone_,
      target_function.IsNull()
          ? NewICData()
          : NewICDataWithTarget(receiver().GetClassId(), target_function));

  Object& object = Object::Handle(zone_, ic_data.ptr());
  Code& code = Code::Handle(zone_, StubCode::ICCallThroughCode().ptr());
  // If the target function has optional parameters or is generic, it's
  // prologue requires ARGS_DESC_REG to be populated. Yet the switchable calls
  // do not populate that on the call site, which is why we don't transition
  // those call sites to monomorphic, but rather directly to call via stub
  // (which will populate the ARGS_DESC_REG from the ICData).
  //
  // Because of this we also don't generate monomorphic checks for those
  // functions.
  if (!target_function.IsNull() &&
      !target_function.PrologueNeedsArgumentsDescriptor()) {
    // Patch to monomorphic call.
    ASSERT(target_function.HasCode());
    const Code& target_code =
        Code::Handle(zone_, target_function.CurrentCode());
    const Smi& expected_cid =
        Smi::Handle(zone_, Smi::New(receiver().GetClassId()));

    if (unlinked.can_patch_to_monomorphic()) {
      object = expected_cid.ptr();
      code = target_code.ptr();
      ASSERT(code.HasMonomorphicEntry());
    } else {
      object = MonomorphicSmiableCall::New(expected_cid.Value(), target_code);
      code = StubCode::MonomorphicSmiableCheck().ptr();
    }
  }
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, object,
                                     code);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
}

bool PatchableCallHandler::CanExtendSingleTargetRange(
    const String& name,
    const Function& old_target,
    const Function& target_function,
    intptr_t* lower,
    intptr_t* upper) {
  if (old_target.ptr() != target_function.ptr()) {
    return false;
  }
  intptr_t unchecked_lower, unchecked_upper;
  if (receiver().GetClassId() < *lower) {
    unchecked_lower = receiver().GetClassId();
    unchecked_upper = *lower - 1;
    *lower = receiver().GetClassId();
  } else {
    unchecked_upper = receiver().GetClassId();
    unchecked_lower = *upper + 1;
    *upper = receiver().GetClassId();
  }

  return IsSingleTarget(isolate_group_, zone_, unchecked_lower, unchecked_upper,
                        target_function, name);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoMonomorphicMissAOT(
    const Object& old_data,
    const Function& target_function) {
  classid_t old_expected_cid;
  if (old_data.IsSmi()) {
    old_expected_cid = Smi::Cast(old_data).Value();
  } else {
    RELEASE_ASSERT(old_data.IsMonomorphicSmiableCall());
    old_expected_cid = MonomorphicSmiableCall::Cast(old_data).expected_cid();
  }
  const bool is_monomorphic_hit = old_expected_cid == receiver().GetClassId();
  const auto& old_receiver_class =
      Class::Handle(zone_, isolate_group_->class_table()->At(old_expected_cid));
  const auto& old_target = Function::Handle(
      zone_, Resolve(thread_, zone_, caller_arguments_, old_receiver_class,
                     name_, args_descriptor_));

  const auto& ic_data = ICData::Handle(
      zone_, old_target.IsNull()
                 ? NewICData()
                 : NewICDataWithTarget(old_expected_cid, old_target));

  if (is_monomorphic_hit) {
    // The site just have been updated to monomorphic state with same
    // exact class id - do nothing in that case: stub will call through ic data.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  intptr_t lower = old_expected_cid;
  intptr_t upper = old_expected_cid;
  if (CanExtendSingleTargetRange(name_, old_target, target_function, &lower,
                                 &upper)) {
    const SingleTargetCache& cache =
        SingleTargetCache::Handle(zone_, SingleTargetCache::New());
    const Code& code = Code::Handle(zone_, target_function.CurrentCode());
    cache.set_target(code);
    cache.set_entry_point(code.EntryPoint());
    cache.set_lower_limit(lower);
    cache.set_upper_limit(upper);
    const Code& stub = StubCode::SingleTargetCall();
    CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, cache,
                                       stub);
    // Return the ICData. The miss stub will jump to continue in the IC call
    // stub.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  // Patch to call through stub.
  const Code& stub = StubCode::ICCallThroughCode();
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                     stub);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  ReturnAOT(stub, ic_data);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoMonomorphicMissJIT(
    const Object& old_data,
    const Function& target_function) {
  // Monomorphic calls use the ICData::entries() as their data.
  const auto& old_ic_data_entries = Array::Cast(old_data);
  // Any non-empty ICData::entries() has a backref to it's ICData.
  const auto& ic_data =
      ICData::Handle(zone_, ICData::ICDataOfEntriesArray(old_ic_data_entries));

  // The target didn't change, so we can stay inside monomorphic state.
  if (ic_data.NumberOfChecksIs(1) &&
      (ic_data.GetReceiverClassIdAt(0) == receiver().GetClassId())) {
    // No need to update ICData - it's already up-to-date.

    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " updating code (old code was disabled)\n",
                   caller_frame_->pc());
    }

    // We stay in monomorphic state, patch the code object and reload the icdata
    // entries array.
    const auto& code = Code::Handle(zone_, target_function.EnsureHasCode());
    const auto& data = Object::Handle(zone_, ic_data.entries());
    CodePatcher::PatchInstanceCallAt(caller_frame_->pc(), caller_code_, data,
                                     code);
    ReturnJIT(code, data, target_function);
    return;
  }

  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& stub = ic_data.is_tracking_exactness()
                         ? StubCode::OneArgCheckInlineCacheWithExactnessCheck()
                         : StubCode::OneArgCheckInlineCache();
  if (FLAG_trace_ic) {
    OS::PrintErr("Instance call at %" Px
                 " switching monomorphic to polymorphic dispatch, %s\n",
                 caller_frame_->pc(), ic_data.ToCString());
  }
  CodePatcher::PatchInstanceCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                   stub);

  ASSERT(caller_arguments_.length() == 1);
  UpdateICDataWithTarget(ic_data, target_function);
  ASSERT(should_consider_patching());
  TrySwitchInstanceCall(thread_, caller_frame_, caller_code_, caller_function_,
                        ic_data, target_function);
  ReturnJIT(stub, ic_data, target_function);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoSingleTargetMissAOT(
    const SingleTargetCache& data,
    const Function& target_function) {
  const Code& old_target_code = Code::Handle(zone_, data.target());
  const Function& old_target =
      Function::Handle(zone_, Function::RawCast(old_target_code.owner()));

  // We lost the original ICData when we patched to the monomorphic case.
  const auto& ic_data = ICData::Handle(
      zone_,
      target_function.IsNull()
          ? NewICData()
          : NewICDataWithTarget(receiver().GetClassId(), target_function));

  intptr_t lower = data.lower_limit();
  intptr_t upper = data.upper_limit();
  if (CanExtendSingleTargetRange(name_, old_target, target_function, &lower,
                                 &upper)) {
    data.set_lower_limit(lower);
    data.set_upper_limit(upper);
    // Return the ICData. The single target stub will jump to continue in the
    // IC call stub.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  // Call site is not single target, switch to call using ICData.
  const Code& stub = StubCode::ICCallThroughCode();
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                     stub);

  // Return the ICData. The single target stub will jump to continue in the
  // IC call stub.
  ReturnAOT(stub, ic_data);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoICDataMissAOT(const ICData& ic_data,
                                           const Function& target_function) {
  const String& name = String::Handle(zone_, ic_data.target_name());
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  ASSERT(!cls.IsNull());
  const Array& descriptor =
      Array::CheckedHandle(zone_, ic_data.arguments_descriptor());
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("ICData miss, class=%s, function<%" Pd ">=%s\n",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }

  if (target_function.IsNull()) {
    ReturnAOT(StubCode::NoSuchMethodDispatcher(), ic_data);
    return;
  }

  const intptr_t number_of_checks = ic_data.NumberOfChecks();

  if ((number_of_checks == 0) &&
      (!FLAG_precompiled_mode || ic_data.receiver_cannot_be_smi()) &&
      !target_function.PrologueNeedsArgumentsDescriptor()) {
    // This call site is unlinked: transition to a monomorphic direct call.
    // Note we cannot do this if the target has optional parameters because
    // the monomorphic direct call does not load the arguments descriptor.
    // We cannot do this if we are still in the middle of precompiling because
    // the monomorphic case hides a live instance selector from the
    // treeshaker.
    const Code& target_code =
        Code::Handle(zone_, target_function.EnsureHasCode());
    const Smi& expected_cid =
        Smi::Handle(zone_, Smi::New(receiver().GetClassId()));
    ASSERT(target_code.HasMonomorphicEntry());
    CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_,
                                       expected_cid, target_code);
    ReturnAOT(target_code, expected_cid);
  } else {
    ic_data.EnsureHasReceiverCheck(receiver().GetClassId(), target_function);
    if (number_of_checks > FLAG_max_polymorphic_checks) {
      // Switch to megamorphic call.
      const MegamorphicCache& cache = MegamorphicCache::Handle(
          zone_, MegamorphicCacheTable::Lookup(thread_, name, descriptor));
      const Code& stub = StubCode::MegamorphicCall();

      CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_,
                                         cache, stub);
      ReturnAOT(stub, cache);
    } else {
      ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    }
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoICDataMissJIT(const ICData& ic_data,
                                           const Object& old_code,
                                           const Function& target_function) {
  ASSERT(ic_data.NumArgsTested() == caller_arguments_.length());

  if (ic_data.NumArgsTested() == 1) {
    ASSERT(old_code.ptr() == StubCode::OneArgCheckInlineCache().ptr() ||
           old_code.ptr() ==
               StubCode::OneArgCheckInlineCacheWithExactnessCheck().ptr() ||
           old_code.ptr() ==
               StubCode::OneArgOptimizedCheckInlineCache().ptr() ||
           old_code.ptr() ==
               StubCode::OneArgOptimizedCheckInlineCacheWithExactnessCheck()
                   .ptr() ||
           old_code.ptr() == StubCode::ICCallBreakpoint().ptr() ||
           (old_code.IsNull() && !should_consider_patching()));
    UpdateICDataWithTarget(ic_data, target_function);
    if (should_consider_patching()) {
      TrySwitchInstanceCall(thread_, caller_frame_, caller_code_,
                            caller_function_, ic_data, target_function);
    }
    const Code& stub = Code::Handle(
        zone_, ic_data.is_tracking_exactness()
                   ? StubCode::OneArgCheckInlineCacheWithExactnessCheck().ptr()
                   : StubCode::OneArgCheckInlineCache().ptr());
    ReturnJIT(stub, ic_data, target_function);
  } else {
    ASSERT(old_code.ptr() == StubCode::TwoArgsCheckInlineCache().ptr() ||
           old_code.ptr() == StubCode::SmiAddInlineCache().ptr() ||
           old_code.ptr() == StubCode::SmiLessInlineCache().ptr() ||
           old_code.ptr() == StubCode::SmiEqualInlineCache().ptr() ||
           old_code.ptr() ==
               StubCode::TwoArgsOptimizedCheckInlineCache().ptr() ||
           old_code.ptr() == StubCode::ICCallBreakpoint().ptr() ||
           (old_code.IsNull() && !should_consider_patching()));
    UpdateICDataWithTarget(ic_data, target_function);
    ReturnJIT(StubCode::TwoArgsCheckInlineCache(), ic_data, target_function);
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void PatchableCallHandler::DoMegamorphicMiss(const MegamorphicCache& data,
                                             const Function& target_function) {
  const String& name = String::Handle(zone_, data.target_name());
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  ASSERT(!cls.IsNull());
  const Array& descriptor =
      Array::CheckedHandle(zone_, data.arguments_descriptor());
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("Megamorphic miss, class=%s, function<%" Pd ">=%s\n",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }
  if (target_function.IsNull()) {
    ReturnJITorAOT(StubCode::NoSuchMethodDispatcher(), data, target_function);
    return;
  }

  // Insert function found into cache.
  const Smi& class_id = Smi::Handle(zone_, Smi::New(cls.id()));
  data.EnsureContains(class_id, target_function);
  ReturnJITorAOT(StubCode::MegamorphicCall(), data, target_function);
}

void PatchableCallHandler::UpdateICDataWithTarget(
    const ICData& ic_data,
    const Function& target_function) {
  if (target_function.IsNull()) return;

  // If, upon return of the runtime, we will invoke the target directly we have
  // to increment the call count here in the ICData.
  // If we instead only insert a new ICData entry and will return to the IC stub
  // which will call the target, the stub will take care of the increment.
  const bool call_target_directly =
      miss_handler_ == MissHandler::kInlineCacheMiss;
  const intptr_t invocation_count = call_target_directly ? 1 : 0;

  if (caller_arguments_.length() == 1) {
    auto exactness = StaticTypeExactnessState::NotTracking();
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (ic_data.is_tracking_exactness()) {
      exactness = receiver().IsNull()
                      ? StaticTypeExactnessState::NotExact()
                      : StaticTypeExactnessState::Compute(
                            Type::Cast(AbstractType::Handle(
                                ic_data.receivers_static_type())),
                            receiver());
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
    ic_data.EnsureHasReceiverCheck(receiver().GetClassId(), target_function,
                                   invocation_count, exactness);
  } else {
    GrowableArray<intptr_t> class_ids(caller_arguments_.length());
    ASSERT(ic_data.NumArgsTested() == caller_arguments_.length());
    for (intptr_t i = 0; i < caller_arguments_.length(); i++) {
      class_ids.Add(caller_arguments_[i]->GetClassId());
    }
    ic_data.EnsureHasCheck(class_ids, target_function, invocation_count);
  }
}

void PatchableCallHandler::ReturnAOT(const Code& stub, const Object& data) {
  ASSERT(miss_handler_ == MissHandler::kSwitchableCallMiss);
  arguments_.SetArgAt(0, stub);  // Second return value.
  arguments_.SetReturn(data);
}

void PatchableCallHandler::ReturnJIT(const Code& stub,
                                     const Object& data,
                                     const Function& target) {
  // In JIT we can have two different miss handlers to which we return slightly
  // differently.
  switch (miss_handler_) {
    case MissHandler::kSwitchableCallMiss: {
      arguments_.SetArgAt(0, stub);  // Second return value.
      arguments_.SetReturn(data);
      break;
    }
    case MissHandler::kFixCallersTargetMonomorphic: {
      arguments_.SetArgAt(1, data);  // Second return value.
      arguments_.SetReturn(stub);
      break;
    }
    case MissHandler::kInlineCacheMiss: {
      arguments_.SetReturn(target);
      break;
    }
  }
}

void PatchableCallHandler::ReturnJITorAOT(const Code& stub,
                                          const Object& data,
                                          const Function& target) {
#if defined(DART_PRECOMPILED_MODE)
  ReturnAOT(stub, data);
#else
  ReturnJIT(stub, data, target);
#endif
}

ICDataPtr PatchableCallHandler::NewICData() {
  return ICData::New(caller_function_, name_, args_descriptor_, DeoptId::kNone,
                     /*num_args_tested=*/1, ICData::kInstance);
}

ICDataPtr PatchableCallHandler::NewICDataWithTarget(intptr_t cid,
                                                    const Function& target) {
  GrowableArray<intptr_t> cids(1);
  cids.Add(cid);
  return ICData::NewWithCheck(caller_function_, name_, args_descriptor_,
                              DeoptId::kNone, /*num_args_tested=*/1,
                              ICData::kInstance, &cids, target);
}

FunctionPtr PatchableCallHandler::ResolveTargetFunction(const Object& data) {
  switch (data.GetClassId()) {
    case kUnlinkedCallCid: {
      const auto& unlinked_call = UnlinkedCall::Cast(data);

#if defined(DART_PRECOMPILED_RUNTIME)
      // When transitioning out of UnlinkedCall to other states (e.g.
      // Monomorphic, MonomorphicSmiable, SingleTarget) we lose
      // name/arg-descriptor in AOT mode and cannot recover it.
      //
      // Even if we could recover an old target function (which was missed) -
      // which we cannot in AOT bare mode - we can still lose the name due to a
      // dyn:* call site potentially targeting non-dyn:* targets.
      //
      // => We will therefore retain the unlinked call here.
      //
      // In JIT mode we always use ICData from the call site, which has the
      // correct name/args-descriptor.
      SaveUnlinkedCall(zone_, isolate_group_, caller_frame_->pc(),
                       unlinked_call);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

      name_ = unlinked_call.target_name();
      args_descriptor_ = unlinked_call.arguments_descriptor();
      break;
    }
    case kMonomorphicSmiableCallCid:
      FALL_THROUGH;
#if defined(DART_PRECOMPILED_RUNTIME)
    case kSmiCid:
      FALL_THROUGH;
    case kSingleTargetCacheCid: {
      const auto& unlinked_call = UnlinkedCall::Handle(
          zone_, LoadUnlinkedCall(zone_, isolate_group_, caller_frame_->pc()));
      name_ = unlinked_call.target_name();
      args_descriptor_ = unlinked_call.arguments_descriptor();
      break;
    }
#else
    case kArrayCid: {
      // Monomorphic calls use the ICData::entries() as their data.
      const auto& ic_data_entries = Array::Cast(data);
      // Any non-empty ICData::entries() has a backref to it's ICData.
      const auto& ic_data =
          ICData::Handle(zone_, ICData::ICDataOfEntriesArray(ic_data_entries));
      args_descriptor_ = ic_data.arguments_descriptor();
      name_ = ic_data.target_name();
      break;
    }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
    case kICDataCid:
      FALL_THROUGH;
    case kMegamorphicCacheCid: {
      const CallSiteData& call_site_data = CallSiteData::Cast(data);
      name_ = call_site_data.target_name();
      args_descriptor_ = call_site_data.arguments_descriptor();
      break;
    }
    default:
      UNREACHABLE();
  }
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  return Resolve(thread_, zone_, caller_arguments_, cls, name_,
                 args_descriptor_);
}

void PatchableCallHandler::ResolveSwitchAndReturn(const Object& old_data) {
  // Find out actual target (which can be time consuming) without holding any
  // locks.
  const auto& target_function =
      Function::Handle(zone_, ResolveTargetFunction(old_data));

  auto& data = Object::Handle(zone_);

  // We ensure any transition in a patchable calls are done in an atomic
  // manner, we ensure we always transition forward (e.g. Monomorphic ->
  // Polymorphic).
  //
  // Mutators are only stopped if we actually need to patch a patchable call.
  // We may not do that if we e.g. just add one more check to an ICData.
  SafepointMutexLocker ml(isolate_group_->patchable_call_mutex());

#if defined(DART_PRECOMPILED_RUNTIME)
  data =
      CodePatcher::GetSwitchableCallDataAt(caller_frame_->pc(), caller_code_);
  uword target_entry = 0;
  DEBUG_ONLY(target_entry = CodePatcher::GetSwitchableCallTargetEntryAt(
                 caller_frame_->pc(), caller_code_));
  HandleMissAOT(data, target_entry, target_function);
#else
  auto& code = Code::Handle(zone_);
  if (should_consider_patching()) {
    code ^= CodePatcher::GetInstanceCallAt(caller_frame_->pc(), caller_code_,
                                           &data);
  } else {
    ASSERT(old_data.IsICData() || old_data.IsMegamorphicCache());
    data = old_data.ptr();
  }
  HandleMissJIT(data, code, target_function);
#endif
}

#if defined(DART_PRECOMPILED_RUNTIME)

void PatchableCallHandler::HandleMissAOT(const Object& old_data,
                                         uword old_entry,
                                         const Function& target_function) {
  switch (old_data.GetClassId()) {
    case kUnlinkedCallCid:
      ASSERT(old_entry ==
             StubCode::SwitchableCallMiss().MonomorphicEntryPoint());
      DoUnlinkedCallAOT(UnlinkedCall::Cast(old_data), target_function);
      break;
    case kMonomorphicSmiableCallCid:
      ASSERT(old_entry ==
             StubCode::MonomorphicSmiableCheck().MonomorphicEntryPoint());
      FALL_THROUGH;
    case kSmiCid:
      DoMonomorphicMissAOT(old_data, target_function);
      break;
    case kSingleTargetCacheCid:
      ASSERT(old_entry == StubCode::SingleTargetCall().MonomorphicEntryPoint());
      DoSingleTargetMissAOT(SingleTargetCache::Cast(old_data), target_function);
      break;
    case kICDataCid:
      ASSERT(old_entry ==
             StubCode::ICCallThroughCode().MonomorphicEntryPoint());
      DoICDataMissAOT(ICData::Cast(old_data), target_function);
      break;
    case kMegamorphicCacheCid:
      ASSERT(old_entry == StubCode::MegamorphicCall().MonomorphicEntryPoint());
      DoMegamorphicMiss(MegamorphicCache::Cast(old_data), target_function);
      break;
    default:
      UNREACHABLE();
  }
}

#else

void PatchableCallHandler::HandleMissJIT(const Object& old_data,
                                         const Code& old_code,
                                         const Function& target_function) {
  switch (old_data.GetClassId()) {
    case kArrayCid:
      // ICData three-element array: Smi(receiver CID), Smi(count),
      // Function(target). It is the Array from ICData::entries_.
      DoMonomorphicMissJIT(old_data, target_function);
      break;
    case kICDataCid:
      DoICDataMissJIT(ICData::Cast(old_data), old_code, target_function);
      break;
    case kMegamorphicCacheCid:
      ASSERT(old_code.ptr() == StubCode::MegamorphicCall().ptr() ||
             (old_code.IsNull() && !should_consider_patching()));
      DoMegamorphicMiss(MegamorphicCache::Cast(old_data), target_function);
      break;
    default:
      UNREACHABLE();
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

static void InlineCacheMissHandler(Thread* thread,
                                   Zone* zone,
                                   const GrowableArray<const Instance*>& args,
                                   const ICData& ic_data,
                                   NativeArguments native_arguments) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  const auto& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const auto& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  PatchableCallHandler handler(thread, args, MissHandler::kInlineCacheMiss,
                               native_arguments, caller_frame, caller_code,
                               caller_function);

  handler.ResolveSwitchAndReturn(ic_data);
#else
  UNREACHABLE();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
  RELEASE_ASSERT(!FLAG_precompiled_mode);
  GrowableArray<const Instance*> args(1);
  args.Add(&receiver);
  InlineCacheMissHandler(thread, zone, args, ic_data, arguments);
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: Argument after receiver.
//   Arg2: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs, 3) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& other = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  RELEASE_ASSERT(!FLAG_precompiled_mode);
  GrowableArray<const Instance*> args(2);
  args.Add(&receiver);
  args.Add(&other);
  InlineCacheMissHandler(thread, zone, args, ic_data, arguments);
}

// Handle the first use of an instance call
//   Arg1: Receiver.
//   Arg0: Stub out.
//   Returns: the ICData used to continue with the call.
DEFINE_RUNTIME_ENTRY(SwitchableCallMiss, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* exit_frame = iterator.NextFrame();
  ASSERT(exit_frame->IsExitFrame());
  StackFrame* miss_handler_frame = iterator.NextFrame();
  // This runtime entry can be called either from miss stub or from
  // switchable_call_miss "dart" stub/function set up in
  // [MegamorphicCacheTable::InitMissHandler].
  ASSERT(miss_handler_frame->IsStubFrame() ||
         miss_handler_frame->IsDartFrame());
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const Function& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  auto& old_data = Object::Handle(zone);
#if defined(DART_PRECOMPILED_RUNTIME)
  old_data =
      CodePatcher::GetSwitchableCallDataAt(caller_frame->pc(), caller_code);
#else
  CodePatcher::GetInstanceCallAt(caller_frame->pc(), caller_code, &old_data);
#endif

  GrowableArray<const Instance*> caller_arguments(1);
  caller_arguments.Add(&receiver);
  PatchableCallHandler handler(thread, caller_arguments,
                               MissHandler::kSwitchableCallMiss, arguments,
                               caller_frame, caller_code, caller_function);
  handler.ResolveSwitchAndReturn(old_data);
}

// Handles interpreted interface call cache miss.
//   Arg0: receiver
//   Arg1: target name
//   Arg2: arguments descriptor
//   Returns: target function (can only be null in AOT runtime)
// Modifies the instance call table in current interpreter.
DEFINE_RUNTIME_ENTRY(InterpretedInstanceCallMissHandler, 3) {
#if defined(DART_DYNAMIC_MODULES)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const String& target_name = String::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& arg_desc = Array::CheckedHandle(zone, arguments.ArgAt(2));

  ArgumentsDescriptor arguments_descriptor(arg_desc);
  const Class& receiver_class = Class::Handle(zone, receiver.clazz());
  Function& target_function = Function::Handle(zone);
  if (receiver_class.EnsureIsFinalized(thread) == Error::null()) {
    const Class& cls = Class::Handle(zone, receiver.clazz());
    const bool allow_add = !FLAG_precompiled_mode;
    target_function = Resolver::ResolveDynamicForReceiverClass(
        cls, target_name, arguments_descriptor, allow_add);
  }

  // TODO(regis): In order to substitute 'simple_instance_of_function', the 2nd
  // arg to the call, the type, is needed.

  if (target_function.IsNull()) {
    target_function =
        InlineCacheMissHelper(receiver_class, arg_desc, target_name);
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(!target_function.IsNull());
#endif
  arguments.SetReturn(target_function);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

#if defined(DART_PRECOMPILED_RUNTIME)
// Used to find the correct receiver and function to invoke or to fall back to
// invoking noSuchMethod when lazy dispatchers are disabled. Returns the
// result of the invocation or an Error.
static ObjectPtr InvokeCallThroughGetterOrNoSuchMethod(
    Thread* thread,
    Zone* zone,
    const Instance& receiver,
    const String& target_name,
    const Array& orig_arguments,
    const Array& orig_arguments_desc) {
  const bool is_dynamic_call =
      Function::IsDynamicInvocationForwarderName(target_name);
  const bool is_dyn_implicit_call =
      target_name.ptr() == Symbols::DynamicImplicitCall().ptr();
  String& demangled_target_name = String::Handle(zone, target_name.ptr());
  if (is_dynamic_call) {
    demangled_target_name =
        Function::DemangleDynamicInvocationForwarderName(target_name);
  }
  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& function = Function::Handle(zone);

  // Dart distinguishes getters and regular methods and allows their calls
  // to mix with conversions, and its selectors are independent of arity. So do
  // a zigzagged lookup to see if this call failed because of an arity mismatch,
  // need for conversion, or there really is no such method.

  const bool is_getter = Field::IsGetterName(demangled_target_name);
  if (is_getter) {
    // Tear-off of a method
    // o.foo (o.get:foo) failed, closurize o.foo() if it exists.
    const auto& function_name =
        String::Handle(zone, Field::NameFromGetter(demangled_target_name));
    while (!cls.IsNull()) {
      // We don't generate dyn:* forwarders for method extractors so there is no
      // need to try to find a dyn:get:foo first.
      if (function.IsNull()) {
        if (cls.EnsureIsFinalized(thread) == Error::null()) {
          function = Resolver::ResolveDynamicFunction(zone, cls, function_name);
        }
      }
      if (!function.IsNull()) {
        const Function& closure_function =
            Function::Handle(zone, function.ImplicitClosureFunction());
        const Object& result = Object::Handle(
            zone, closure_function.ImplicitInstanceClosure(receiver));
        return result.ptr();
      }
      cls = cls.SuperClass();
    }

    if (receiver.IsRecord()) {
      const Record& record = Record::Cast(receiver);
      const intptr_t field_index =
          record.GetFieldIndexByName(thread, function_name);
      if (field_index >= 0) {
        return record.FieldAt(field_index);
      }
    }

    // Fall through for noSuchMethod
  } else {
    // Call through field.
    // o.foo(...) failed, invoke noSuchMethod is foo exists but has the wrong
    // number of arguments, or try (o.foo).call(...)

    if ((demangled_target_name.ptr() == Symbols::call().ptr()) &&
        receiver.IsClosure()) {
      // Special case: closures are implemented with a call getter instead of a
      // call method and with lazy dispatchers the field-invocation-dispatcher
      // would perform the closure call.
      return DartEntry::InvokeClosure(thread, orig_arguments,
                                      orig_arguments_desc);
    }

    // Dynamic call sites have to use the dynamic getter as well (if it was
    // created), unless its a dynamic implicit call to 'call'.
    const auto& getter_name =
        String::Handle(zone, Field::GetterName(demangled_target_name));
    const auto& dyn_getter_name = String::Handle(
        zone, is_dynamic_call
                  ? Function::CreateDynamicInvocationForwarderName(getter_name)
                  : getter_name.ptr());
    ArgumentsDescriptor args_desc(orig_arguments_desc);
    while (!cls.IsNull()) {
      // If there is a function with the target name but mismatched arguments
      // we need to call `receiver.noSuchMethod()`.
      if (cls.EnsureIsFinalized(thread) == Error::null()) {
        function = Resolver::ResolveDynamicFunction(zone, cls, target_name);
      }
      if (!function.IsNull()) {
        ASSERT(!function.AreValidArguments(args_desc, nullptr));
        break;  // mismatch, invoke noSuchMethod
      }
      if (is_dynamic_call) {
        function =
            Resolver::ResolveDynamicFunction(zone, cls, demangled_target_name);
        if (!function.IsNull()) {
          ASSERT(!function.AreValidArguments(args_desc, nullptr));
          break;  // mismatch, invoke noSuchMethod
        }
      }

      if (!is_dyn_implicit_call) {
        // If there is a getter we need to call-through-getter.
        if (is_dynamic_call) {
          function =
              Resolver::ResolveDynamicFunction(zone, cls, dyn_getter_name);
        }
        if (function.IsNull()) {
          function = Resolver::ResolveDynamicFunction(zone, cls, getter_name);
        }
        if (!function.IsNull()) {
          const Array& getter_arguments = Array::Handle(Array::New(1));
          getter_arguments.SetAt(0, receiver);
          const Object& getter_result = Object::Handle(
              zone, DartEntry::InvokeFunction(function, getter_arguments));
          if (getter_result.IsError()) {
            return getter_result.ptr();
          }
          ASSERT(getter_result.IsNull() || getter_result.IsInstance());

          orig_arguments.SetAt(args_desc.FirstArgIndex(), getter_result);
          return DartEntry::InvokeClosure(thread, orig_arguments,
                                          orig_arguments_desc);
        }
      }
      cls = cls.SuperClass();
    }

    if (receiver.IsRecord() && !is_dyn_implicit_call) {
      const Record& record = Record::Cast(receiver);
      const intptr_t field_index =
          record.GetFieldIndexByName(thread, demangled_target_name);
      if (field_index >= 0) {
        const Object& getter_result =
            Object::Handle(zone, record.FieldAt(field_index));
        ASSERT(getter_result.IsNull() || getter_result.IsInstance());
        orig_arguments.SetAt(args_desc.FirstArgIndex(), getter_result);
        return DartEntry::InvokeClosure(thread, orig_arguments,
                                        orig_arguments_desc);
      }
    }
  }

  const Object& result = Object::Handle(
      zone,
      DartEntry::InvokeNoSuchMethod(thread, receiver, demangled_target_name,
                                    orig_arguments, orig_arguments_desc));
  return result.ptr();
}
#endif

// Invoke appropriate noSuchMethod or closure from getter.
// Arg0: receiver
// Arg1: ICData or MegamorphicCache
// Arg2: arguments descriptor array
// Arg3: arguments array
DEFINE_RUNTIME_ENTRY(NoSuchMethodFromCallStub, 4) {
  const Object& ic_data_or_cache = Object::Handle(zone, arguments.ArgAt(1));
  String& target_name = String::Handle(zone);
  if (ic_data_or_cache.IsICData()) {
    target_name = ICData::Cast(ic_data_or_cache).target_name();
  } else {
    ASSERT(ic_data_or_cache.IsMegamorphicCache());
    target_name = MegamorphicCache::Cast(ic_data_or_cache).target_name();
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));
  const auto& result =
      Object::Handle(zone, InvokeCallThroughGetterOrNoSuchMethod(
                               thread, zone, receiver, target_name,
                               orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
#else
  FATAL("Dispatcher for %s should have been lazily created",
        target_name.ToCString());
#endif
}

// Invoke appropriate noSuchMethod function.
// Arg0: receiver
// Arg1: function
// Arg1: arguments descriptor array.
// Arg3: arguments array.
DEFINE_RUNTIME_ENTRY(NoSuchMethodFromPrologue, 4) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));

  String& orig_function_name = String::Handle(zone);
  if ((function.kind() == UntaggedFunction::kClosureFunction) ||
      (function.kind() == UntaggedFunction::kImplicitClosureFunction)) {
    // For closure the function name is always 'call'. Replace it with the
    // name of the closurized function so that exception contains more
    // relevant information.
    orig_function_name = function.QualifiedUserVisibleName();
  } else {
    orig_function_name = function.name();
  }

  const Object& result = Object::Handle(
      zone, DartEntry::InvokeNoSuchMethod(thread, receiver, orig_function_name,
                                          orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

// Throw NoSuchMethodError with given arguments.
// Arg0: arguments of NoSuchMethodError._throwNew.
DEFINE_RUNTIME_ENTRY(NoSuchMethodError, 1) {
  const Array& args = Array::CheckedHandle(zone, arguments.ArgAt(0));
  const Library& libcore = Library::Handle(Library::CoreLibrary());
  const Class& cls =
      Class::Handle(libcore.LookupClass(Symbols::NoSuchMethodError()));
  ASSERT(!cls.IsNull());
  const auto& error = cls.EnsureIsFinalized(Thread::Current());
  ASSERT(error == Error::null());
  const Function& throwNew =
      Function::Handle(cls.LookupFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(args.Length() == throwNew.NumParameters());
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(throwNew, args));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

// Invoke appropriate noSuchMethod function (or in the case of no lazy
// dispatchers, walk the receiver to find the correct method to call).
// Arg0: receiver
// Arg1: function name.
// Arg2: arguments descriptor array.
// Arg3: arguments array.
DEFINE_RUNTIME_ENTRY(InvokeNoSuchMethod, 4) {
#if defined(DART_DYNAMIC_MODULES)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const String& original_function_name =
      String::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));

  auto& result = Object::Handle(zone);
#if defined(DART_PRECOMPILED_RUNTIME)
  // Failing to find the method could be due to the lack of lazy invoke field
  // dispatchers, so attempt a deeper search before calling noSuchMethod.
  result = InvokeCallThroughGetterOrNoSuchMethod(
      thread, zone, receiver, original_function_name, orig_arguments,
      orig_arguments_desc);
#else
  result =
      DartEntry::InvokeNoSuchMethod(thread, receiver, original_function_name,
                                    orig_arguments, orig_arguments_desc);
#endif
  ThrowIfError(result);
  arguments.SetReturn(result);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
// The following code is used to stress test
//  - deoptimization
//  - debugger stack tracing
//  - garbage collection
//  - hot reload
static void HandleStackOverflowTestCases(Thread* thread) {
  auto isolate_group = thread->isolate_group();

  if (FLAG_shared_slow_path_triggers_gc) {
    isolate_group->heap()->CollectAllGarbage(GCReason::kDebugging);
  }

  bool do_deopt = false;
  bool do_stacktrace = false;
  bool do_reload = false;
  bool do_gc = false;
  const intptr_t isolate_reload_every =
      isolate_group->reload_every_n_stack_overflow_checks();
  if ((FLAG_deoptimize_every > 0) || (FLAG_stacktrace_every > 0) ||
      (FLAG_gc_every > 0) || (isolate_reload_every > 0)) {
    if (!IsolateGroup::IsSystemIsolateGroup(isolate_group)) {
      // TODO(turnidge): To make --deoptimize_every and
      // --stacktrace-every faster we could move this increment/test to
      // the generated code.
      uint32_t count = thread->IncrementAndGetStackOverflowCount();
      if (FLAG_deoptimize_every > 0 && (count % FLAG_deoptimize_every) == 0) {
        do_deopt = true;
      }
      if (FLAG_stacktrace_every > 0 && (count % FLAG_stacktrace_every) == 0) {
        do_stacktrace = true;
      }
      if (FLAG_gc_every > 0 && (count % FLAG_gc_every) == 0) {
        do_gc = true;
      }
      if ((isolate_reload_every > 0) && (count % isolate_reload_every) == 0) {
        do_reload =
            isolate_group->CanReload() && !isolate_group->has_seen_oom();
      }
    }
  }
  if ((FLAG_deoptimize_filter != nullptr) ||
      (FLAG_stacktrace_filter != nullptr) || (FLAG_reload_every != 0)) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
    Code& code = Code::Handle();
    Function& function = Function::Handle();
    if (frame->is_interpreted()) {
      function = frame->LookupDartFunction();
    } else {
      code = frame->LookupDartCode();
      ASSERT(!code.IsNull());
      function = code.function();
    }
    ASSERT(!function.IsNull());
    const char* function_name = nullptr;
    if ((FLAG_deoptimize_filter != nullptr) ||
        (FLAG_stacktrace_filter != nullptr)) {
      function_name = function.ToFullyQualifiedCString();
      ASSERT(function_name != nullptr);
    }
    if (!code.IsNull()) {
      if (!code.is_optimized() && FLAG_reload_every_optimized) {
        // Don't do the reload if we aren't inside optimized code.
        do_reload = false;
      }
      if (code.is_optimized() && FLAG_deoptimize_filter != nullptr &&
          strstr(function_name, FLAG_deoptimize_filter) != nullptr &&
          !function.ForceOptimize()) {
        OS::PrintErr("*** Forcing deoptimization (%s)\n",
                     function.ToFullyQualifiedCString());
        do_deopt = true;
      }
    }
    if (FLAG_stacktrace_filter != nullptr &&
        strstr(function_name, FLAG_stacktrace_filter) != nullptr) {
      OS::PrintErr("*** Computing stacktrace (%s)\n",
                   function.ToFullyQualifiedCString());
      do_stacktrace = true;
    }
  }
  if (do_deopt) {
    // TODO(turnidge): Consider using DeoptimizeAt instead.
    DeoptimizeFunctionsOnStack();
  }
  if (do_reload) {
    // Maybe adjust the rate of future reloads.
    isolate_group->MaybeIncreaseReloadEveryNStackOverflowChecks();

    // Issue a reload.
    const char* script_uri = isolate_group->source()->script_uri;
    JSONStream js;
    const bool success =
        isolate_group->ReloadSources(&js, /*force_reload=*/true, script_uri);
    if (!success && !Dart::IsShuttingDown() && !isolate_group->has_seen_oom()) {
      FATAL("*** Isolate reload failed:\n%s\n", js.ToCString());
    }
  }
  if (do_stacktrace) {
    String& var_name = String::Handle();
    Instance& var_value = Instance::Handle();
    DebuggerStackTrace* stack = DebuggerStackTrace::Collect();
    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      int num_vars = 0;
      // Variable locations and number are unknown when precompiling.
#if !defined(DART_PRECOMPILED_RUNTIME)
      const auto& function = frame->function();
      if (!function.ForceOptimize()) {
        if (!function.is_declared_in_bytecode()) {
          // Ensure that we have unoptimized code.
          function.EnsureHasCompiledUnoptimizedCode();
        }
        num_vars = frame->NumLocalVariables();
      }
#endif
      TokenPosition unused = TokenPosition::kNoSource;
      for (intptr_t v = 0; v < num_vars; v++) {
        frame->VariableAt(v, &var_name, &unused, &unused, &unused, &var_value);
      }
    }
    if (FLAG_stress_async_stacks) {
      DebuggerStackTrace::CollectAsyncAwaiters();
    }
  }
  if (do_gc) {
    isolate_group->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
static void HandleOSRRequest(Thread* thread) {
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group->use_osr());
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  const Code& code = Code::ZoneHandle(frame->LookupDartCode());
  ASSERT(!code.IsNull());
  ASSERT(!code.is_optimized());
  const Function& function = Function::Handle(code.function());
  ASSERT(!function.IsNull());

  // If the code of the frame does not match the function's unoptimized code,
  // we bail out since the code was reset by an isolate reload.
  if (code.ptr() != function.unoptimized_code()) {
    return;
  }

  // Since the code is referenced from the frame and the ZoneHandle,
  // it cannot have been removed from the function.
  ASSERT(function.HasCode());
  // Don't do OSR on intrinsified functions: The intrinsic code expects to be
  // called like a regular function and can't be entered via OSR.
  if (!Compiler::CanOptimizeFunction(thread, function) ||
      function.is_intrinsic()) {
    return;
  }

  // The unoptimized code is on the stack and should never be detached from
  // the function at this point.
  ASSERT(function.unoptimized_code() != Object::null());
  intptr_t osr_id =
      Code::Handle(function.unoptimized_code()).GetDeoptIdForOsr(frame->pc());
  ASSERT(osr_id != Compiler::kNoOSRDeoptId);
  if (FLAG_trace_osr) {
    OS::PrintErr("Attempting OSR for %s at id=%" Pd ", count=%" Pd "\n",
                 function.ToFullyQualifiedCString(), osr_id,
                 function.usage_counter());
  }

  // Since the code is referenced from the frame and the ZoneHandle,
  // it cannot have been removed from the function.
  const Object& result = Object::Handle(
      Compiler::CompileOptimizedFunction(thread, function, osr_id));
  ThrowIfError(result);

  if (!result.IsNull()) {
    const Code& code = Code::Cast(result);
    uword optimized_entry = code.EntryPoint();
    frame->set_pc(optimized_entry);
    frame->set_pc_marker(code.ptr());
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DEFINE_RUNTIME_ENTRY(InterruptOrStackOverflow, 0) {
  uword stack_pos = OSThread::GetCurrentStackPointer();
#if defined(DART_INCLUDE_SIMULATOR)
  if (FLAG_use_simulator) {
    stack_pos = Simulator::Current()->get_sp();
    // If simulator was never called it may return 0 as a value of SPREG.
    if (stack_pos == 0) {
      // Use any reasonable value which would not be treated
      // as stack overflow.
      stack_pos = thread->saved_stack_limit();
    }
  }
#endif
  // Always clear the stack overflow flags.  They are meant for this
  // particular stack overflow runtime call and are not meant to
  // persist.
  uword stack_overflow_flags = thread->GetAndClearStackOverflowFlags();

  bool interpreter_stack_overflow = false;
#if defined(DART_DYNAMIC_MODULES)
  Interpreter* interpreter = thread->interpreter();
  if (interpreter != nullptr) {
    interpreter_stack_overflow =
        interpreter->get_sp() >= interpreter->overflow_stack_limit();
  }
#endif  // defined(DART_DYNAMIC_MODULES)

  // If an interrupt happens at the same time as a stack overflow, we
  // process the stack overflow now and leave the interrupt for next
  // time.
  if (interpreter_stack_overflow || !thread->os_thread()->HasStackHeadroom() ||
      IsCalleeFrameOf(thread->saved_stack_limit(), stack_pos)) {
    if (FLAG_verbose_stack_overflow) {
      OS::PrintErr("Stack overflow\n");
      OS::PrintErr("  Native SP = %" Px ", stack limit = %" Px "\n", stack_pos,
                   thread->saved_stack_limit());
#if defined(DART_DYNAMIC_MODULES)
      if (thread->interpreter() != nullptr) {
        OS::PrintErr("  Interpreter SP = %" Px ", stack limit = %" Px "\n",
                     thread->interpreter()->get_sp(),
                     thread->interpreter()->overflow_stack_limit());
      }
#endif  // defined(DART_DYNAMIC_MODULES)

      OS::PrintErr("Call stack:\n");
      OS::PrintErr("size | frame\n");
      StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                                StackFrameIterator::kNoCrossThreadIteration);
      uword fp = stack_pos;
      StackFrame* frame = frames.NextFrame();
      while (frame != nullptr) {
        uword delta = (frame->fp() - fp);
        fp = frame->fp();
        OS::PrintErr("%4" Pd " %s\n", delta, frame->ToCString());
        frame = frames.NextFrame();
      }
    }

    // Use the preallocated stack overflow exception to avoid calling
    // into dart code.
    const Instance& exception = Instance::Handle(
        thread->isolate_group()->object_store()->stack_overflow());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  HandleStackOverflowTestCases(thread);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  // Handle interrupts:
  //  - store buffer overflow
  //  - OOB message (vm-service or dart:isolate)
  //  - marking ready for finalization
  const Error& error = Error::Handle(thread->HandleInterrupts());
  ThrowIfError(error);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if ((stack_overflow_flags & Thread::kOsrRequest) != 0) {
    HandleOSRRequest(thread);
  }
#else
  ASSERT((stack_overflow_flags & Thread::kOsrRequest) == 0);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  ASSERT(thread->IsDartMutatorThread());

  {
    // Another isolate's mutator thread may have created [function] and
    // published it via an ICData, MegamorphicCache etc. Entering the lock below
    // is an acquire operation that pairs with the release operation when the
    // other isolate exited the lock, ensuring the initializing stores for
    // [function] are visible in the current thread.
    SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  }

  // After the barrier, since this will read the object's header.
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(0));

  // Will throw if compilation failed (e.g. with compile-time error).
  function.EnsureHasCode();
}

// This is called from function that needs to be optimized.
// The requesting function can be already optimized (reoptimization).
// Returns the Code object where to continue execution.
DEFINE_RUNTIME_ENTRY(OptimizeInvokedFunction, 1) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  ASSERT(!function.IsNull());
  ASSERT(function.HasCode());

  if (Compiler::CanOptimizeFunction(thread, function)) {
    auto isolate_group = thread->isolate_group();
    if (FLAG_background_compilation) {
      if (isolate_group->background_compiler()->EnqueueCompilation(function)) {
        // Reduce the chance of triggering a compilation while the function is
        // being compiled in the background. INT32_MIN should ensure that it
        // takes long time to trigger a compilation.
        // Note that the background compilation queue rejects duplicate entries.
        function.SetUsageCounter(INT32_MIN);
        // Continue in the same code.
        arguments.SetReturn(function);
        return;
      }
    }

    // Reset usage counter for reoptimization before calling optimizer to
    // prevent recursive triggering of function optimization.
    function.SetUsageCounter(0);
    if (FLAG_trace_compiler || FLAG_trace_optimizing_compiler) {
      if (function.HasOptimizedCode()) {
        THR_Print("ReCompiling function: '%s' \n",
                  function.ToFullyQualifiedCString());
      }
    }
    Object& result = Object::Handle(
        zone, Compiler::CompileOptimizedFunction(thread, function));
    ThrowIfError(result);
  }
  arguments.SetReturn(function);
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}

// The caller must be a static call in a Dart frame, or an entry frame.
// Patch static call to point to valid code's entry point.
DEFINE_RUNTIME_ENTRY(FixCallersTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  while (frame->IsStubFrame() || frame->IsExitFrame()) {
    frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
  }
  if (frame->IsEntryFrame()) {
    // Since function's current code is always unpatched, the entry frame always
    // calls to unpatched code.
    UNREACHABLE();
  }
  ASSERT(frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  RELEASE_ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(frame->pc()));

  const Code& current_target_code =
      Code::Handle(zone, target_function.EnsureHasCode());
  CodePatcher::PatchStaticCallAt(frame->pc(), caller_code, current_target_code);
  caller_code.SetStaticCallTargetCodeAt(frame->pc(), current_target_code);
  if (FLAG_trace_patching) {
    OS::PrintErr(
        "FixCallersTarget: caller %#" Px
        " "
        "target '%s' -> %#" Px " (%s)\n",
        frame->pc(), target_function.ToFullyQualifiedCString(),
        current_target_code.EntryPoint(),
        current_target_code.is_optimized() ? "optimized" : "unoptimized");
  }
  arguments.SetReturn(current_target_code);
#else
  UNREACHABLE();
#endif
}

// The caller must be a monomorphic call from unoptimized code.
// Patch call to point to new target.
DEFINE_RUNTIME_ENTRY(FixCallersTargetMonomorphic, 2) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Array& switchable_call_data =
      Array::CheckedHandle(zone, arguments.ArgAt(1));

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  const auto& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const auto& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  GrowableArray<const Instance*> caller_arguments(1);
  caller_arguments.Add(&receiver);
  PatchableCallHandler handler(
      thread, caller_arguments, MissHandler::kFixCallersTargetMonomorphic,
      arguments, caller_frame, caller_code, caller_function);
  handler.ResolveSwitchAndReturn(switchable_call_data);
#else
  UNREACHABLE();
#endif
}

// The caller tried to allocate an instance via an invalidated allocation
// stub.
DEFINE_RUNTIME_ENTRY(FixAllocationStubTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  while (frame->IsStubFrame() || frame->IsExitFrame()) {
    frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
  }
  if (frame->IsEntryFrame()) {
    // There must be a valid Dart frame.
    UNREACHABLE();
  }
  ASSERT(frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  const Code& stub = Code::Handle(
      CodePatcher::GetStaticCallTargetAt(frame->pc(), caller_code));
  Class& alloc_class = Class::ZoneHandle(zone);
  alloc_class ^= stub.owner();
  Code& alloc_stub = Code::Handle(zone, alloc_class.allocation_stub());
  if (alloc_stub.IsNull()) {
    alloc_stub = StubCode::GetAllocationStubForClass(alloc_class);
    ASSERT(!alloc_stub.IsDisabled());
  }
  CodePatcher::PatchStaticCallAt(frame->pc(), caller_code, alloc_stub);
  caller_code.SetStubCallTargetCodeAt(frame->pc(), alloc_stub);
  if (FLAG_trace_patching) {
    OS::PrintErr("FixAllocationStubTarget: caller %#" Px
                 " alloc-class %s "
                 " -> %#" Px "\n",
                 frame->pc(), alloc_class.ToCString(), alloc_stub.EntryPoint());
  }
  arguments.SetReturn(alloc_stub);
#else
  UNREACHABLE();
#endif
}

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason) {
  switch (deopt_reason) {
#define DEOPT_REASON_TO_TEXT(name)                                             \
  case ICData::kDeopt##name:                                                   \
    return #name;
    DEOPT_REASONS(DEOPT_REASON_TO_TEXT)
#undef DEOPT_REASON_TO_TEXT
    default:
      UNREACHABLE();
      return "";
  }
}

static bool IsSuspendedFrame(Zone* zone,
                             const Function& function,
                             StackFrame* frame) {
  if (!function.IsSuspendableFunction()) {
    return false;
  }
  auto& suspend_state = Object::Handle(
      zone, *reinterpret_cast<ObjectPtr*>(LocalVarAddress(
                frame->fp(), runtime_frame_layout.FrameSlotForVariableIndex(
                                 SuspendState::kSuspendStateVarIndex))));
  return suspend_state.IsSuspendState() &&
         (SuspendState::Cast(suspend_state).pc() != 0);
}

void DeoptimizeAt(Thread* mutator_thread,
                  const Code& optimized_code,
                  StackFrame* frame) {
  ASSERT(optimized_code.is_optimized());

  // Force-optimized code is optimized code which cannot deoptimize and doesn't
  // have unoptimized code to fall back to.
  ASSERT(!optimized_code.is_force_optimized());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Function& function = Function::Handle(zone, optimized_code.function());
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& unoptimized_code =
      Code::Handle(zone, function.unoptimized_code());
  ASSERT(!unoptimized_code.IsNull());
  // The switch to unoptimized code may have already occurred.
  if (function.HasOptimizedCode()) {
    function.SwitchToUnoptimizedCode();
  }

  if (IsSuspendedFrame(zone, function, frame)) {
    // Frame is suspended and going to be removed from the stack.
    if (FLAG_trace_deoptimization) {
      THR_Print("Not deoptimizing suspended frame, fp=%" Pp "\n", frame->fp());
    }
  } else if (frame->IsMarkedForLazyDeopt()) {
    // Deopt already scheduled.
    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt already scheduled for fp=%" Pp "\n", frame->fp());
    }
  } else {
    uword deopt_pc = frame->pc();
    ASSERT(optimized_code.ContainsInstructionAt(deopt_pc));

#if defined(DEBUG)
    ValidateFrames();
#endif

    // N.B.: Update the pending deopt table before updating the frame. The
    // profiler may attempt a stack walk in between.
    ASSERT(!frame->is_interpreted());
    mutator_thread->pending_deopts().AddPendingDeopt(frame->fp(), deopt_pc);
    frame->MarkForLazyDeopt();

    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt scheduled for fp=%" Pp ", pc=%" Pp "\n",
                frame->fp(), deopt_pc);
    }
  }

  // Mark code as dead (do not GC its embedded objects).
  optimized_code.set_is_alive(false);
}

// Currently checks only that all optimized frames have kDeoptIndex
// and unoptimized code has the kDeoptAfter.
void DeoptimizeFunctionsOnStack() {
  auto thread = Thread::Current();
  // Have to grab program_lock before stopping everybody else.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  auto isolate_group = thread->isolate_group();
  isolate_group->RunWithStoppedMutators([&]() {
    Code& optimized_code = Code::Handle();
    isolate_group->ForEachIsolate(
        [&](Isolate* isolate) {
          auto mutator_thread = isolate->mutator_thread();
          if (mutator_thread == nullptr) {
            return;
          }
          DartFrameIterator iterator(
              mutator_thread, StackFrameIterator::kAllowCrossThreadIteration);
          StackFrame* frame = iterator.NextFrame();
          while (frame != nullptr) {
            if (!frame->is_interpreted()) {
              optimized_code = frame->LookupDartCode();
              if (optimized_code.is_optimized() &&
                  !optimized_code.is_force_optimized()) {
                DeoptimizeAt(mutator_thread, optimized_code, frame);
              }
            }
            frame = iterator.NextFrame();
          }
        },
        /*at_safepoint=*/true);
  });
}

static void DeoptimizeLastDartFrameIfOptimized() {
  auto thread = Thread::Current();
  // Have to grab program_lock before stopping everybody else.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  auto isolate = thread->isolate();
  auto isolate_group = thread->isolate_group();
  isolate_group->RunWithStoppedMutators([&]() {
    auto mutator_thread = isolate->mutator_thread();
    if (mutator_thread == nullptr) {
      return;
    }
    DartFrameIterator iterator(mutator_thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    if (frame != nullptr && !frame->is_interpreted()) {
      const auto& optimized_code = Code::Handle(frame->LookupDartCode());
      if (optimized_code.is_optimized() &&
          !optimized_code.is_force_optimized()) {
        DeoptimizeAt(mutator_thread, optimized_code, frame);
      }
    }
  });
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static constexpr intptr_t kNumberOfSavedCpuRegisters = kNumberOfCpuRegisters;
static constexpr intptr_t kNumberOfSavedFpuRegisters = kNumberOfFpuRegisters;

static void CopySavedRegisters(uword saved_registers_address,
                               fpu_register_t** fpu_registers,
                               intptr_t** cpu_registers) {
  // Tell MemorySanitizer this region is initialized by generated code. This
  // region isn't already (fully) unpoisoned by FrameSetIterator::Unpoison
  // because it is in an exit frame and stack frame iteration doesn't have
  // access to true SP for exit frames.
  MSAN_UNPOISON(reinterpret_cast<void*>(saved_registers_address),
                kNumberOfSavedFpuRegisters * kFpuRegisterSize +
                    kNumberOfSavedCpuRegisters * kWordSize);

  ASSERT(sizeof(fpu_register_t) == kFpuRegisterSize);
  fpu_register_t* fpu_registers_copy =
      new fpu_register_t[kNumberOfSavedFpuRegisters];
  ASSERT(fpu_registers_copy != nullptr);
  for (intptr_t i = 0; i < kNumberOfSavedFpuRegisters; i++) {
    fpu_registers_copy[i] =
        *reinterpret_cast<fpu_register_t*>(saved_registers_address);
    saved_registers_address += kFpuRegisterSize;
  }
  *fpu_registers = fpu_registers_copy;

  ASSERT(sizeof(intptr_t) == kWordSize);
  intptr_t* cpu_registers_copy = new intptr_t[kNumberOfSavedCpuRegisters];
  ASSERT(cpu_registers_copy != nullptr);
  for (intptr_t i = 0; i < kNumberOfSavedCpuRegisters; i++) {
    cpu_registers_copy[i] =
        *reinterpret_cast<intptr_t*>(saved_registers_address);
    saved_registers_address += kWordSize;
  }
  *cpu_registers = cpu_registers_copy;
}
#endif

extern "C" bool DLRT_TryDoubleAsInteger(Thread* thread) {
  double value = thread->unboxed_double_runtime_arg();
  int64_t int_value = static_cast<int64_t>(value);
  double converted_double = static_cast<double>(int_value);
  if (converted_double != value) {
    return false;
  }
  thread->set_unboxed_int64_runtime_arg(int_value);
  return true;
}
DEFINE_LEAF_RUNTIME_ENTRY(TryDoubleAsInteger, 1, DLRT_TryDoubleAsInteger);

// Copies saved registers and caller's frame into temporary buffers.
// Returns the stack size of unoptimized frame.
// The calling code must be optimized, but its function may not have
// have optimized code if the code is OSR code, or if the code was invalidated
// through class loading/finalization or field guard.
extern "C" intptr_t DLRT_DeoptimizeCopyFrame(uword saved_registers_address,
                                             uword is_lazy_deopt) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  StackZone zone(thread);

  // All registers have been saved below last-fp as if they were locals.
  const uword last_fp =
      saved_registers_address + (kNumberOfSavedCpuRegisters * kWordSize) +
      (kNumberOfSavedFpuRegisters * kFpuRegisterSize) -
      ((runtime_frame_layout.first_local_from_fp + 1) * kWordSize);

  // Get optimized code and frame that need to be deoptimized.
  DartFrameIterator iterator(last_fp, thread,
                             StackFrameIterator::kNoCrossThreadIteration);

  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
  ASSERT(optimized_code.is_optimized());
  const Function& top_function =
      Function::Handle(thread->zone(), optimized_code.function());
  const bool deoptimizing_code = top_function.HasOptimizedCode();
  if (FLAG_trace_deoptimization) {
    const Function& function = Function::Handle(optimized_code.function());
    THR_Print("== Deoptimizing code for '%s', %s, %s\n",
              function.ToFullyQualifiedCString(),
              deoptimizing_code ? "code & frame" : "frame",
              (is_lazy_deopt != 0u) ? "lazy-deopt" : "");
  }

  if (is_lazy_deopt != 0u) {
    const uword deopt_pc =
        thread->pending_deopts().FindPendingDeopt(caller_frame->fp());

    // N.B.: Update frame before updating pending deopt table. The profiler
    // may attempt a stack walk in between.
    caller_frame->set_pc(deopt_pc);
    ASSERT(caller_frame->pc() == deopt_pc);
    ASSERT(optimized_code.ContainsInstructionAt(caller_frame->pc()));
    thread->pending_deopts().ClearPendingDeoptsAtOrBelow(
        caller_frame->fp(), PendingDeopts::kClearDueToDeopt);
  } else {
    if (FLAG_trace_deoptimization) {
      THR_Print("Eager deopt fp=%" Pp " pc=%" Pp "\n", caller_frame->fp(),
                caller_frame->pc());
    }
  }

  // Copy the saved registers from the stack.
  fpu_register_t* fpu_registers;
  intptr_t* cpu_registers;
  CopySavedRegisters(saved_registers_address, &fpu_registers, &cpu_registers);

  // Create the DeoptContext.
  DeoptContext* deopt_context = new DeoptContext(
      caller_frame, optimized_code, DeoptContext::kDestIsOriginalFrame,
      fpu_registers, cpu_registers, is_lazy_deopt != 0, deoptimizing_code);
  thread->set_deopt_context(deopt_context);

  // Stack size (FP - SP) in bytes.
  return deopt_context->DestStackAdjustment() * kWordSize;
#else
  UNREACHABLE();
  return 0;
#endif  // !DART_PRECOMPILED_RUNTIME
}
DEFINE_LEAF_RUNTIME_ENTRY(DeoptimizeCopyFrame, 2, DLRT_DeoptimizeCopyFrame);

// The stack has been adjusted to fit all values for unoptimized frame.
// Fill the unoptimized frame.
extern "C" intptr_t DLRT_DeoptimizeFillFrame(uword last_fp) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  StackZone zone(thread);

  DeoptContext* deopt_context = thread->deopt_context();
  DartFrameIterator iterator(last_fp, thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);

#if defined(DEBUG)
  {
    // The code from the deopt_context.
    const Code& code = Code::Handle(deopt_context->code());

    // The code from our frame.
    const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
    const Function& function = Function::Handle(optimized_code.function());
    ASSERT(!function.IsNull());

    // The code will be the same as before.
    ASSERT(code.ptr() == optimized_code.ptr());

    // Some sanity checking of the optimized code.
    ASSERT(!optimized_code.IsNull() && optimized_code.is_optimized());
  }
#endif

  deopt_context->set_dest_frame(caller_frame);
  intptr_t frame_count = deopt_context->FillDestFrame();
  ASSERT(frame_count > 0);
  if (FLAG_trace_deoptimization) {
    THR_Print("Deopt created %" Pd " frames\n", frame_count);
  }
  return frame_count;
#else
  UNREACHABLE();
  return 0;
#endif  // !DART_PRECOMPILED_RUNTIME
}
DEFINE_LEAF_RUNTIME_ENTRY(DeoptimizeFillFrame, 1, DLRT_DeoptimizeFillFrame);

// This is the last step in the deoptimization, GC can occur.
// Returns number of bytes to remove from the expression stack of the
// bottom-most deoptimized frame. Those arguments were artificially injected
// under return address to keep them discoverable by GC that can occur during
// materialization phase.
DEFINE_RUNTIME_ENTRY(DeoptimizeMaterialize, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DEBUG)
  {
    // We may rendezvous for a safepoint at entry or GC from the allocations
    // below. Check the stack is walkable.
    ValidateFrames();
  }
#endif
  DeoptContext* deopt_context = thread->deopt_context();
  intptr_t deopt_arg_count = deopt_context->MaterializeDeferredObjects();
  thread->set_deopt_context(nullptr);
  delete deopt_context;

  // Return value tells deoptimization stub to remove the given number of bytes
  // from the stack.
  arguments.SetReturn(Smi::Handle(Smi::New(deopt_arg_count * kWordSize)));
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}

DEFINE_RUNTIME_ENTRY(RewindPostDeopt, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
#if !defined(PRODUCT)
  isolate->debugger()->RewindPostDeopt();
#endif  // !PRODUCT
#endif  // !DART_PRECOMPILED_RUNTIME
  UNREACHABLE();
}

// Handle slow path actions for the resumed frame after it was
// copied back to the stack:
// 1) deoptimization;
// 2) breakpoint at resumption;
// 3) throwing an exception.
//
// Arg0: exception
// Arg1: stack trace
DEFINE_RUNTIME_ENTRY(ResumeFrame, 2) {
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(zone, arguments.ArgAt(1));

#if !defined(DART_PRECOMPILED_RUNTIME)
#if !defined(PRODUCT)
  if (isolate != nullptr) {
    if (isolate->has_resumption_breakpoints()) {
      isolate->debugger()->ResumptionBreakpoint();
    }
  }
#endif

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame->IsDartFrame());
  ASSERT(!frame->is_interpreted());
  ASSERT(Function::Handle(zone, frame->LookupDartFunction())
             .IsSuspendableFunction());
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  if (caller_code.IsDisabled() && caller_code.is_optimized() &&
      !caller_code.is_force_optimized()) {
    const uword deopt_pc = frame->pc();
    thread->pending_deopts().AddPendingDeopt(frame->fp(), deopt_pc);
    frame->MarkForLazyDeopt();

    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt scheduled for resumed frame fp=%" Pp ", pc=%" Pp
                "\n",
                frame->fp(), deopt_pc);
    }
  }
#endif

  if (!exception.IsNull()) {
    Exceptions::ReThrow(thread, exception, stacktrace);
  }
}

void OnEveryRuntimeEntryCall(Thread* thread,
                             const char* runtime_call_name,
                             bool can_lazy_deopt) {
  ASSERT(FLAG_deoptimize_on_runtime_call_every > 0);
  if (FLAG_precompiled_mode) {
    return;
  }
  if (IsolateGroup::IsSystemIsolateGroup(thread->isolate_group())) {
    return;
  }
  const bool is_deopt_related =
      strstr(runtime_call_name, "Deoptimize") != nullptr;
  if (is_deopt_related) {
    return;
  }
  // For --deoptimize-on-every-runtime-call we only consider runtime calls that
  // can lazy-deopt.
  if (can_lazy_deopt) {
    if (FLAG_deoptimize_on_runtime_call_name_filter != nullptr &&
        (strlen(runtime_call_name) !=
             strlen(FLAG_deoptimize_on_runtime_call_name_filter) ||
         strstr(runtime_call_name,
                FLAG_deoptimize_on_runtime_call_name_filter) == nullptr)) {
      return;
    }
    const uint32_t count = thread->IncrementAndGetRuntimeCallCount();
    if ((count % FLAG_deoptimize_on_runtime_call_every) == 0) {
      DeoptimizeLastDartFrameIfOptimized();
    }
  }
}

double DartModulo(double left, double right) {
  double remainder = fmod_ieee(left, right);
  if (remainder == 0.0) {
    // We explicitly switch to the positive 0.0 (just in case it was negative).
    remainder = +0.0;
  } else if (remainder < 0.0) {
    if (right < 0) {
      remainder -= right;
    } else {
      remainder += right;
    }
  }
  return remainder;
}

// Update global type feedback recorded for a field recording the assignment
// of the given value.
//   Arg0: Field object;
//   Arg1: Value that is being stored.
DEFINE_RUNTIME_ENTRY(UpdateFieldCid, 2) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  const Object& value = Object::Handle(arguments.ArgAt(1));
  field.RecordStore(value);
#else
  UNREACHABLE();
#endif
}

DEFINE_RUNTIME_ENTRY(InitInstanceField, 2) {
  const Instance& instance = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(1));
  Object& result = Object::Handle(zone, field.InitializeInstance(instance));
  ThrowIfError(result);
  result = instance.GetField(field);
  ASSERT(result.ptr() != Object::sentinel().ptr());
  arguments.SetReturn(result);
}

DEFINE_RUNTIME_ENTRY(InitStaticField, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Object& result = Object::Handle(zone, field.InitializeStatic());
  ThrowIfError(result);
  result = field.StaticValue();
  ASSERT(result.ptr() != Object::sentinel().ptr());
  arguments.SetReturn(result);
}

DEFINE_RUNTIME_ENTRY(CheckedStoreIntoShared, 2) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& value = Instance::CheckedHandle(zone, arguments.ArgAt(1));

  value.EnsureDeeplyImmutable(zone);

  field.SetStaticValue(value);
  arguments.SetReturn(field);
}

DEFINE_RUNTIME_ENTRY(StaticFieldAccessedWithoutIsolateError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowStaticFieldAccessedWithoutIsolate(
      String::Handle(field.name()));
  UNREACHABLE();
}

DEFINE_RUNTIME_ENTRY(LateFieldAlreadyInitializedError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldAlreadyInitialized(String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(LateFieldAssignedDuringInitializationError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldAssignedDuringInitialization(
      String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(LateFieldNotInitializedError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldNotInitialized(String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(NotLoaded, 0) {
  // We could just use a trap instruction in the stub, but we get better stack
  // traces when there is an exit frame.
  FATAL("Not loaded");
}

DEFINE_RUNTIME_ENTRY(FfiAsyncCallbackSend, 1) {
  Dart_Port target_port = thread->unboxed_int64_runtime_arg();
  TRACE_RUNTIME_CALL("FfiAsyncCallbackSend %p", (void*)target_port);
  const Object& message = Object::Handle(zone, arguments.ArgAt(0));
  const Array& msg_array = Array::Handle(zone, Array::New(3));
  msg_array.SetAt(0, message);
  PersistentHandle* handle =
      thread->isolate_group()->api_state()->AllocatePersistentHandle();
  handle->set_ptr(msg_array);
  PortMap::PostMessage(
      Message::New(target_port, handle, Message::kNormalPriority));
}

// Use expected function signatures to help MSVC compiler resolve overloading.
typedef double (*UnaryMathCFunction)(double x);
typedef double (*BinaryMathCFunction)(double x, double y);
typedef void* (*MemMoveCFunction)(void* dest, const void* src, size_t n);

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcPow,
                                /*argument_count=*/2,
                                static_cast<BinaryMathCFunction>(pow));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(DartModulo,
                                /*argument_count=*/2,
                                static_cast<BinaryMathCFunction>(DartModulo));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcFmod,
                                /*argument_count=*/2,
                                static_cast<BinaryMathCFunction>(fmod_ieee));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcAtan2,
                                /*argument_count=*/2,
                                static_cast<BinaryMathCFunction>(atan2_ieee));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcFloor,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(floor));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcCeil,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(ceil));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcTrunc,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(trunc));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcRound,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(round));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcCos,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(cos));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcSin,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(sin));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcAsin,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(asin));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcAcos,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(acos));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcTan,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(tan));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcAtan,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(atan));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcExp,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(exp));

DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(LibcLog,
                                /*argument_count=*/1,
                                static_cast<UnaryMathCFunction>(log));

DEFINE_LEAF_RUNTIME_ENTRY(MemoryMove,
                          /*argument_count=*/3,
                          static_cast<MemMoveCFunction>(memmove));

#if defined(DART_DYNAMIC_MODULES)
// Interpret a function call. Should be called only for non-jitted functions.
// argc indicates the number of arguments, including the type arguments.
// argv points to the first argument.
// If argc < 0, arguments are passed at decreasing memory addresses from argv.
extern "C" uword /*ObjectPtr*/ InterpretCall(uword /*FunctionPtr*/ function_in,
                                             uword /*ArrayPtr*/ argdesc_in,
                                             intptr_t argc,
                                             ObjectPtr* argv,
                                             Thread* thread) {
  FunctionPtr function = static_cast<FunctionPtr>(function_in);
  ArrayPtr argdesc = static_cast<ArrayPtr>(argdesc_in);
  Interpreter* interpreter = Interpreter::Current();
#if defined(DEBUG)
  uword exit_fp = thread->top_exit_frame_info();
  ASSERT(exit_fp != 0);
  ASSERT(thread == Thread::Current());
  // Caller is InterpretCall stub called from generated code.
  // We stay in "in generated code" execution state when interpreting code.
  ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
  ASSERT(Function::HasBytecode(function));
  ASSERT(Function::IsInterpreted(function));
  ASSERT(interpreter != nullptr);
#endif
  // Tell MemorySanitizer 'argv' is initialized by generated code.
  if (argc < 0) {
    MSAN_UNPOISON(argv - argc, -argc * sizeof(ObjectPtr));
  } else {
    MSAN_UNPOISON(argv, argc * sizeof(ObjectPtr));
  }
  ObjectPtr result =
      interpreter->Call(function, argdesc, argc, argv, Array::null(), thread);
  DEBUG_ASSERT(thread->top_exit_frame_info() == exit_fp);
  if (UNLIKELY(IsErrorClassId(result->GetClassId()))) {
    // Must not leak handles in the caller's zone.
    HANDLESCOPE(thread);
    // Protect the result in a handle before transitioning, which may trigger
    // GC.
    const Error& error = Error::Handle(Error::RawCast(result));
    // Propagating an error may cause allocation. Check if we need to block for
    // a safepoint by switching to "in VM" execution state.
    TransitionGeneratedToVM transition(thread);
    Exceptions::PropagateError(error);
  }
  return static_cast<uword>(result);
}
#endif  // defined(DART_DYNAMIC_MODULES)

uword RuntimeEntry::InterpretCallEntry() {
#if defined(DART_DYNAMIC_MODULES)
  uword entry = reinterpret_cast<uword>(InterpretCall);
#if defined(DART_INCLUDE_SIMULATOR)
  if (FLAG_use_simulator) {
    entry = Simulator::RedirectExternalReference(
        entry, Simulator::kLeafRuntimeCall, 5);
  }
#endif
  return entry;
#else
  return 0;
#endif  // defined(DART_DYNAMIC_MODULES)
}

// Restore suspended interpreter frame and resume execution.
//
// Arg0: return value (result of the suspension)
// Arg1: exception
// Arg2: stack trace
DEFINE_RUNTIME_ENTRY(ResumeInterpreter, 3) {
#if defined(DART_DYNAMIC_MODULES)
  const Instance& value = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const Instance& stack_trace =
      Instance::CheckedHandle(zone, arguments.ArgAt(2));

#if defined(DART_PRECOMPILED_RUNTIME)
  const auto& resume_stub = Code::Handle(
      zone, thread->isolate_group()->object_store()->resume_stub());
#else
  const auto& resume_stub = StubCode::Resume();
#endif

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  while (frame->IsExitFrame() ||
         (frame->IsStubFrame() &&
          !StubCode::ResumeInterpreter().ContainsInstructionAt(frame->pc()) &&
          !resume_stub.ContainsInstructionAt(frame->pc()))) {
    frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
  }
  RELEASE_ASSERT(frame->IsStubFrame());

  const uword fp = frame->fp();
  const uword sp = arguments.GetCallerSP();
  ASSERT((fp > sp) && (sp > frame->sp()));
  MSAN_UNPOISON(reinterpret_cast<uint8_t*>(sp), fp - sp);

  Interpreter* interpreter = Interpreter::Current();
  auto& result = Object::Handle(zone);

  {
    TransitionVMToGenerated transition(thread);
    result = interpreter->Resume(thread, fp, sp, value.ptr(), exception.ptr(),
                                 stack_trace.ptr());
  }
  if (UNLIKELY(IsErrorClassId(result.GetClassId()))) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  arguments.SetReturn(result);
#else
  UNREACHABLE();
#endif  // defined(DART_DYNAMIC_MODULES)
}

DEFINE_RUNTIME_ENTRY(FatalError, 1) {
  const String& message = String::CheckedHandle(zone, arguments.ArgAt(0));
  FATAL("%s", message.ToCString());
}

extern "C" void DLRT_EnterSafepoint() {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("%s", "EnterSafepoint");
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);
  ASSERT(thread->execution_state() == Thread::kThreadInNative);
  thread->EnterSafepointToNative();
  TRACE_RUNTIME_CALL("%s", "EnterSafepoint done");
}
DEFINE_LEAF_RUNTIME_ENTRY(EnterSafepoint,
                          /*argument_count=*/0,
                          DLRT_EnterSafepoint);

extern "C" void DLRT_ExitSafepoint() {
  CHECK_STACK_ALIGNMENT;
  Thread* thread = Thread::Current();
  TRACE_RUNTIME_CALL("ExitSafepoint thread %p", thread);
  ASSERT(thread->top_exit_frame_info() != 0);

  if (thread->is_unwind_in_progress()) {
    // Clean up safepoint unwind error marker to prevent safepoint tripping.
    // The safepoint marker will get restored just before jumping back
    // to generated code.
    TransitionToVM transition(thread);
    thread->SetUnwindErrorInProgress(false);
    NoSafepointScope no_safepoint;
    Exceptions::PropagateError(Object::unwind_error());
  }
  if (thread->execution_state() == Thread::kThreadInNative) {
    thread->ExitSafepointFromNative();
  } else {
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    thread->ExitSafepoint();
  }

  TRACE_RUNTIME_CALL("%s", "ExitSafepoint done");
}
DEFINE_LEAF_RUNTIME_ENTRY(ExitSafepoint,
                          /*argument_count=*/0,
                          DLRT_ExitSafepoint);

namespace {
Thread* HandleAsyncFfiCallback(FfiCallbackMetadata::Metadata metadata,
                               uword* out_entry_point,
                               uword* out_trampoline_type) {
  // NOTE: This is only thread safe if the user is using the API correctly.
  // Otherwise, the callback could have been deleted and replaced, in which case
  // IsLive would still be true. Or it could have been deleted after we looked
  // it up, and the target isolate could be shut down. We delay recycling
  // callbacks as long as possible, so this check is better than nothing, but
  // it's not infallible. Ultimately it's the user's responsibility to avoid use
  // after free errors. Trying to lock FfiCallbackMetadata::lock_, or any
  // similar lock, leads to deadlocks.

  *out_trampoline_type = static_cast<uword>(metadata.trampoline_type());
  *out_entry_point = metadata.target_entry_point();
  Isolate* target_isolate = metadata.target_isolate();

  Isolate* current_isolate = nullptr;
  Thread* current_thread = Thread::Current();
  if (current_thread != nullptr) {
    current_isolate = current_thread->isolate();
    if (current_thread->execution_state() != Thread::kThreadInNative) {
      FATAL("Cannot invoke native callback from a leaf call.");
    }
    current_thread->ExitSafepointFromNative();
    current_thread->set_execution_state(Thread::kThreadInVM);
  }

  // Enter the temporary isolate. If the current isolate is in the same group
  // as the target isolate, we can skip entering the temp isolate, and marshal
  // the args on the current isolate.
  if (current_isolate == nullptr ||
      current_isolate->group() != target_isolate->group()) {
    if (current_isolate != nullptr) {
      Thread::ExitIsolate(/*isolate_shutdown=*/false);
    }
    target_isolate->group()->EnterTemporaryIsolate();
  }
  Thread* const temp_thread = Thread::Current();
  ASSERT(temp_thread != nullptr);
  temp_thread->set_unboxed_int64_runtime_arg(metadata.send_port());
  temp_thread->set_unboxed_int64_runtime_second_arg(
      reinterpret_cast<intptr_t>(current_isolate));
  ASSERT(!temp_thread->IsAtSafepoint());
  return temp_thread;
}

Thread* HandleIsolateGroupBoundSyncFfiCallback(
    FfiCallbackMetadata::Metadata metadata,
    uword* out_entry_point,
    uword* out_trampoline_type) {
  Thread* current_thread = Thread::Current();

  *out_entry_point = metadata.target_entry_point();
  *out_trampoline_type = static_cast<uword>(metadata.trampoline_type());

  if (current_thread != nullptr) {
    current_thread->ExitSafepointFromNative();
    current_thread->set_execution_state(Thread::kThreadInVM);
  }

  Isolate* current_isolate =
      current_thread != nullptr ? current_thread->isolate() : nullptr;

  if (current_thread != nullptr) {
    Thread::ExitIsolate(/*isolate_shutdown=*/false);
  }
  Thread::EnterIsolateGroupAsMutator(metadata.target_isolate_group(),
                                     /*bypass_safepoint=*/false);
  auto new_thread = Thread::Current();
  new_thread->set_execution_state(Thread::kThreadInVM);
  // We need to go back to current thread after we come back from
  // the callback.
  new_thread->set_unboxed_int64_runtime_arg(
      reinterpret_cast<intptr_t>(current_thread));
  new_thread->set_unboxed_int64_runtime_second_arg(
      reinterpret_cast<intptr_t>(current_isolate));
  current_thread = new_thread;

  current_thread->set_unboxed_int64_runtime_arg(metadata.context());

  return current_thread;
}

void FfiCallbackThreadChecks(Thread* thread, Isolate* target_isolate) {
  if (thread->no_callback_scope_depth() != 0) {
    FATAL("Cannot invoke native callback when API callbacks are prohibited.");
  }
  if (thread->is_unwind_in_progress()) {
    FATAL("Cannot invoke native callback while unwind error propagates.");
  }
  if (!thread->IsDartMutatorThread()) {
    FATAL("Native callbacks must be invoked on the mutator thread.");
  }
  if (thread->isolate() != target_isolate) {
    FATAL("Cannot invoke native callback from a different isolate.");
  }
}

Thread* HandleIsolateBoundSyncFfiCallback(
    FfiCallbackMetadata::Metadata metadata,
    uword* out_entry_point,
    uword* out_trampoline_type) {
  Thread* current_thread = Thread::Current();

  *out_entry_point = metadata.target_entry_point();
  *out_trampoline_type = static_cast<uword>(metadata.trampoline_type());

  Isolate* target_isolate = metadata.target_isolate();
  if (current_thread == nullptr) {
    if (!PortMap::IsOwnedByCurrentThread(target_isolate->main_port())) {
      FATAL("Cannot invoke native callback outside an isolate.");
    }
    Thread::EnterIsolate(target_isolate);
    current_thread = Thread::Current();
    *out_trampoline_type |=
        FfiCallbackMetadata::kSyncCallbackIsolateOwnershipFlag;
    FfiCallbackThreadChecks(current_thread, target_isolate);
  } else {
    FfiCallbackThreadChecks(current_thread, target_isolate);
    if (current_thread->execution_state() != Thread::kThreadInNative) {
      FATAL("Cannot invoke native callback from a leaf call.");
    }
    current_thread->ExitSafepointFromNative();
  }

  current_thread->set_execution_state(Thread::kThreadInVM);
  current_thread->set_unboxed_int64_runtime_arg(metadata.context());

  return current_thread;
}
}  // namespace

// This is called by a native callback trampoline
// (see StubCodeCompiler::GenerateFfiCallbackTrampolineStub). Not registered as
// a runtime entry because we can't use Thread to look it up.
extern "C" Thread* DLRT_GetFfiCallbackMetadata(
    FfiCallbackMetadata::Trampoline trampoline,
    uword* out_entry_point,
    uword* out_trampoline_type) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata %p",
                     reinterpret_cast<void*>(trampoline));
  ASSERT(out_entry_point != nullptr);
  ASSERT(out_trampoline_type != nullptr);

  if (!Isolate::IsolateCreationEnabled()) {
    FATAL("GetFfiCallbackMetadata called after shutdown %p",
          reinterpret_cast<void*>(trampoline));
  }

  // NOTE: We access the metadata for `trampoline` without a lock. This is safe
  // because nobody will touch the metadata of the `trampoline` until it's
  // deleted and the `NativeCallable` API requires the isolate to keep the
  // trampoline (and therefore the metadata) alive until C code no longer
  // attempts to call it.
  //
  // If a user of the `NativeCallable` API violates this agreement, we may
  // have a use-after-free scenario here and therefore undefined behavior.
  // We make some best effort to `FATAL()` in obvious cases of undefined
  // behavior, but not all cases will be caught.
  auto metadata =
      FfiCallbackMetadata::Instance()->LookupMetadataForTrampolineUnlocked(
          trampoline);

  if (!metadata.IsLive()) {
    FATAL("Callback invoked after it has been deleted.");
  }

  Thread* thread = nullptr;
  if (metadata.trampoline_type() ==
      FfiCallbackMetadata::TrampolineType::kAsync) {
    thread =
        HandleAsyncFfiCallback(metadata, out_entry_point, out_trampoline_type);
  } else if (metadata.is_isolate_group_bound()) {
    thread = HandleIsolateGroupBoundSyncFfiCallback(metadata, out_entry_point,
                                                    out_trampoline_type);
  } else {
    thread = HandleIsolateBoundSyncFfiCallback(metadata, out_entry_point,
                                               out_trampoline_type);
  }

  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata thread %p", thread);
  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata entry_point %p",
                     (void*)*out_entry_point);
  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata trampoline_type %p",
                     (void*)*out_trampoline_type);
  return thread;
}

extern "C" void DLRT_ExitIsolateGroupBoundIsolate() {
  TRACE_RUNTIME_CALL("ExitIsolateGroupBoundIsolate%s", "");
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  Isolate* source_isolate =
      reinterpret_cast<Isolate*>(thread->unboxed_int64_runtime_second_arg());
  // Need to accommodate ExitIsolateGroupAsHelper assumptions.
  thread->set_execution_state(Thread::kThreadInVM);
  Thread::ExitIsolateGroupAsMutator(/*bypass_safepoint=*/false);
  if (source_isolate != nullptr) {
    Thread::EnterIsolate(source_isolate);
    Thread::Current()->EnterSafepoint();
  }
}

extern "C" void DLRT_ExitSyncCallbackTargetIsolate() {
  TRACE_RUNTIME_CALL("ExitSyncCallbackTargetIsolate%s", "");
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  thread->set_execution_state(Thread::kThreadInVM);
  Thread::ExitIsolate(/*isolate_shutdown=*/false);
}

extern "C" void DLRT_ExitTemporaryIsolate() {
  TRACE_RUNTIME_CALL("ExitTemporaryIsolate%s", "");
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  Isolate* source_isolate =
      reinterpret_cast<Isolate*>(thread->unboxed_int64_runtime_second_arg());

  // We're either inside a temp isolate, or inside the source_isolate.
  const bool inside_temp_isolate =
      source_isolate == nullptr || source_isolate != thread->isolate();
  if (inside_temp_isolate) {
    IsolateGroup::ExitTemporaryIsolate();
    if (source_isolate != nullptr) {
      TRACE_RUNTIME_CALL("ExitTemporaryIsolate re-entering source isolate %p",
                         source_isolate);
      Thread::EnterIsolate(source_isolate);
      Thread::Current()->EnterSafepoint();
    }
  } else {
    thread->EnterSafepoint();
  }
  TRACE_RUNTIME_CALL("ExitTemporaryIsolate %s", "done");
}

extern "C" ApiLocalScope* DLRT_EnterHandleScope(Thread* thread) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("EnterHandleScope %p", thread);
  thread->EnterApiScope();
  ApiLocalScope* return_value = thread->api_top_scope();
  TRACE_RUNTIME_CALL("EnterHandleScope returning %p", return_value);
  return return_value;
}
DEFINE_LEAF_RUNTIME_ENTRY(EnterHandleScope,
                          /*argument_count=*/1,
                          DLRT_EnterHandleScope);

extern "C" void DLRT_ExitHandleScope(Thread* thread) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("ExitHandleScope %p", thread);
  thread->ExitApiScope();
  TRACE_RUNTIME_CALL("ExitHandleScope %s", "done");
}
DEFINE_LEAF_RUNTIME_ENTRY(ExitHandleScope,
                          /*argument_count=*/1,
                          DLRT_ExitHandleScope);

extern "C" LocalHandle* DLRT_AllocateHandle(ApiLocalScope* scope) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("AllocateHandle %p", scope);
  LocalHandle* return_value = scope->local_handles()->AllocateHandle();
  // Don't return an uninitialised handle.
  return_value->set_ptr(Object::sentinel().ptr());
  TRACE_RUNTIME_CALL("AllocateHandle returning %p", return_value);
  return return_value;
}
DEFINE_LEAF_RUNTIME_ENTRY(AllocateHandle,
                          /*argument_count=*/1,
                          DLRT_AllocateHandle);

// Enables reusing `Dart_PropagateError` from `FfiCallInstr`.
// `Dart_PropagateError` requires the native state and transitions into the VM.
// So the flow is:
// - FfiCallInstr (slow path)
// - TransitionGeneratedToNative
// - DLRT_PropagateError (this)
// - Dart_PropagateError
// - TransitionNativeToVM
// - Throw
extern "C" void DLRT_PropagateError(Dart_Handle handle) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("PropagateError %p", handle);
  ASSERT(Thread::Current()->execution_state() == Thread::kThreadInNative);
  ASSERT(Dart_IsError(handle));
  Dart_PropagateError(handle);
  // We should never exit through normal control flow.
  UNREACHABLE();
}

// Not a leaf-function, throws error.
DEFINE_LEAF_RUNTIME_ENTRY(PropagateError,
                          /*argument_count=*/1,
                          DLRT_PropagateError);

DEFINE_RUNTIME_ENTRY(InitializeSharedField, 1) {
  // Running the initializer means running arbitrary Dart code that might yield
  // to a reload safepoint or have its active mutator slot stolen. Make sure we
  // likewise yield while waiting for the lock to avoid the holder of the lock
  // being blocked on locker-waiters for reload or a mutator slot.
  ReloadableStealableWriteRwLocker locker(
      thread, thread->isolate_group()->shared_field_initializer_rwlock());
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Object& result = Object::Handle(zone, field.StaticValue());
  if (result.ptr() == Object::sentinel().ptr()) {
    // Haven't lost a race to set the initial value.
    result = field.InitializeStatic();
    ThrowIfError(result);
    result = field.StaticValue();
    ASSERT(result.ptr() != Object::sentinel().ptr());
  }
  arguments.SetReturn(result);
}

// Throw if the value is not immutable.
//   Arg0: Value to check.
DEFINE_RUNTIME_ENTRY(EnsureDeeplyImmutable, 1) {
  const Instance& value = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  value.EnsureDeeplyImmutable(zone);
}

#if defined(USING_MEMORY_SANITIZER)
extern "C" void dart_msan_read1(void* addr) {
  __msan_check_mem_is_initialized(addr, 1);
}
extern "C" void dart_msan_read2(void* addr) {
  __msan_check_mem_is_initialized(addr, 2);
}
extern "C" void dart_msan_read4(void* addr) {
  __msan_check_mem_is_initialized(addr, 4);
}
extern "C" void dart_msan_read8(void* addr) {
  __msan_check_mem_is_initialized(addr, 8);
}
extern "C" void dart_msan_read16(void* addr) {
  __msan_check_mem_is_initialized(addr, 16);
}
extern "C" void dart_msan_write1(void* addr) {
  __msan_unpoison(addr, 1);
}
extern "C" void dart_msan_write2(void* addr) {
  __msan_unpoison(addr, 2);
}
extern "C" void dart_msan_write4(void* addr) {
  __msan_unpoison(addr, 4);
}
extern "C" void dart_msan_write8(void* addr) {
  __msan_unpoison(addr, 8);
}
extern "C" void dart_msan_write16(void* addr) {
  __msan_unpoison(addr, 16);
}
#else
extern "C" void __msan_unpoison(const volatile void*, size_t) {
  UNREACHABLE();
}
extern "C" void __msan_unpoison_param(size_t) {
  UNREACHABLE();
}
#endif

#if !defined(USING_THREAD_SANITIZER)
extern "C" uint32_t __tsan_atomic32_load(uint32_t* addr, int order) {
  UNREACHABLE();
}
extern "C" void __tsan_atomic32_store(uint32_t* addr,
                                      uint32_t value,
                                      int order) {
  UNREACHABLE();
}
extern "C" uint64_t __tsan_atomic64_load(uint64_t* addr, int order) {
  UNREACHABLE();
}
extern "C" void __tsan_atomic64_store(uint64_t* addr,
                                      uint64_t value,
                                      int order) {
  UNREACHABLE();
}
extern "C" void __tsan_read1(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_read2(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_read4(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_read8(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_read16(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_write1(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_write2(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_write4(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_write8(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_write16(void* addr) {
  UNREACHABLE();
}
extern "C" void __tsan_func_entry(void* pc) {
  UNREACHABLE();
}
extern "C" void __tsan_func_exit() {
  UNREACHABLE();
}
#else
#define CASE(x)                                                                \
  extern "C" NO_SANITIZE_THREAD DISABLE_SANITIZER_INSTRUMENTATION void         \
  dart_tsan_##x(void* addr) {                                                  \
    __tsan_##x##_pc(                                                           \
        addr, reinterpret_cast<void*>(                                         \
                  reinterpret_cast<uintptr_t>(__builtin_return_address(0)) |   \
                  kExternalPCBit));                                            \
  }

CASE(read1)
CASE(read2)
CASE(read4)
CASE(read8)
CASE(read16)
CASE(write1)
CASE(write2)
CASE(write4)
CASE(write8)
CASE(write16)
#undef CASE
extern "C" NO_SANITIZE_THREAD DISABLE_SANITIZER_INSTRUMENTATION void
dart_tsan_func_entry(void* pc) {
  __tsan_func_entry(reinterpret_cast<void*>(reinterpret_cast<uintptr_t>(pc) |
                                            kExternalPCBit));
}
#endif

// These runtime entries are defined even when not using ASAN / MSAN / TSAN to
// keep offsets on Thread consistent.
DEFINE_LEAF_RUNTIME_ENTRY(MsanUnpoison, 2, __msan_unpoison);
DEFINE_LEAF_RUNTIME_ENTRY(MsanUnpoisonParam, 1, __msan_unpoison_param);
DEFINE_LEAF_RUNTIME_ENTRY(TsanAtomic32Load, 2, __tsan_atomic32_load);
DEFINE_LEAF_RUNTIME_ENTRY(TsanAtomic32Store, 3, __tsan_atomic32_store);
DEFINE_LEAF_RUNTIME_ENTRY(TsanAtomic64Load, 2, __tsan_atomic64_load);
DEFINE_LEAF_RUNTIME_ENTRY(TsanAtomic64Store, 3, __tsan_atomic64_store);
#if defined(USING_ADDRESS_SANITIZER)
DEFINE_LEAF_RUNTIME_ENTRY(SanRead1, 1, __asan_load1);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead2, 1, __asan_load2);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead4, 1, __asan_load4);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead8, 1, __asan_load8);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead16, 1, __asan_load16);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite1, 1, __asan_store1);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite2, 1, __asan_store2);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite4, 1, __asan_store4);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite8, 1, __asan_store8);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite16, 1, __asan_store16);
#elif defined(USING_MEMORY_SANITIZER)
DEFINE_LEAF_RUNTIME_ENTRY(SanRead1, 1, dart_msan_read1);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead2, 1, dart_msan_read2);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead4, 1, dart_msan_read4);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead8, 1, dart_msan_read8);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead16, 1, dart_msan_read16);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite1, 1, dart_msan_write1);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite2, 1, dart_msan_write2);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite4, 1, dart_msan_write4);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite8, 1, dart_msan_write8);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite16, 1, dart_msan_write16);
#elif defined(USING_THREAD_SANITIZER) && !defined(DART_PRECOMPILED_RUNTIME)
DEFINE_LEAF_RUNTIME_ENTRY(SanRead1, 1, dart_tsan_read1);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead2, 1, dart_tsan_read2);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead4, 1, dart_tsan_read4);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead8, 1, dart_tsan_read8);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead16, 1, dart_tsan_read16);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite1, 1, dart_tsan_write1);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite2, 1, dart_tsan_write2);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite4, 1, dart_tsan_write4);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite8, 1, dart_tsan_write8);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite16, 1, dart_tsan_write16);
#else
DEFINE_LEAF_RUNTIME_ENTRY(SanRead1, 1, __tsan_read1);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead2, 1, __tsan_read2);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead4, 1, __tsan_read4);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead8, 1, __tsan_read8);
DEFINE_LEAF_RUNTIME_ENTRY(SanRead16, 1, __tsan_read16);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite1, 1, __tsan_write1);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite2, 1, __tsan_write2);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite4, 1, __tsan_write4);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite8, 1, __tsan_write8);
DEFINE_LEAF_RUNTIME_ENTRY(SanWrite16, 1, __tsan_write16);
#endif
#if defined(USING_THREAD_SANITIZER) && !defined(DART_PRECOMPILED_RUNTIME)
DEFINE_LEAF_RUNTIME_ENTRY(TsanFuncEntry, 1, dart_tsan_func_entry);
#else
DEFINE_LEAF_RUNTIME_ENTRY(TsanFuncEntry, 1, __tsan_func_entry);
#endif
DEFINE_LEAF_RUNTIME_ENTRY(TsanFuncExit, 0, __tsan_func_exit);

}  // namespace dart
