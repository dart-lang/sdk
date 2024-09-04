// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_trace.h"

#include "vm/dart_api_impl.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace {

// Keep in sync with:
// - _StreamController._STATE_SUBSCRIBED.
const intptr_t k_StreamController__STATE_SUBSCRIBED = 1;
// - _StreamController._STATE_SUBSCRIPTION_MASK.
const intptr_t k_StreamController__STATE_SUBSCRIPTION_MASK = 3;
// - _StreamController._STATE_ADDSTREAM.
const intptr_t k_StreamController__STATE_ADDSTREAM = 8;
// - _BufferingStreamSubscription._STATE_HAS_ERROR_HANDLER.
const intptr_t k_BufferingStreamSubscription__STATE_HAS_ERROR_HANDLER = 1 << 5;
// - _Future._stateIgnoreError
const intptr_t k_Future__stateIgnoreError = 1;
// - _FutureListener.stateThen.
const intptr_t k_FutureListener_stateThen = 1;
// - _FutureListener.stateCatchError.
const intptr_t k_FutureListener_stateCatchError = 2;
// - _FutureListener.stateWhenComplete.
const intptr_t k_FutureListener_stateWhenComplete = 8;
// - sdk/lib/async/future_impl.dart:_FutureListener.maskAwait.
const intptr_t k_FutureListener_maskAwait = 16;

bool WasPreviouslySuspended(const Function& function,
                            const Object& suspend_state_var) {
  if (!suspend_state_var.IsSuspendState()) {
    return false;
  }
  if (function.IsAsyncFunction()) {
    // Error callback is set after both 'then' and 'error' callbacks are
    // registered with the Zone. Callback registration may query
    // stack trace and should still collect the synchronous stack trace.
    return SuspendState::Cast(suspend_state_var).error_callback() !=
           Object::null();
  } else if (function.IsAsyncGenerator()) {
    return true;
  } else {
    UNREACHABLE();
  }
}

bool TryGetAwaiterLink(const Closure& closure, Object* link) {
  *link = Object::null();
  const auto& function = Function::Handle(closure.function());
  const auto awaiter_link = function.awaiter_link();
  if (awaiter_link.depth != ClosureData::kNoAwaiterLinkDepth) {
    if (function.IsImplicitClosureFunction()) {
      ASSERT(awaiter_link.depth == 0 && awaiter_link.index == 0);
      *link = closure.GetImplicitClosureReceiver();
      return true;
    }

    auto& context = Context::Handle(closure.GetContext());
    intptr_t depth = awaiter_link.depth;
    while (depth-- > 0) {
      context = context.parent();
    }

    *link = context.At(awaiter_link.index);
    return true;
  }
  return false;
}

// Unwinder which starts by unwinding the synchronous portion of the stack
// until it reaches a frame which has an asynchronous awaiter (e.g. an
// activation of the async function which has a listener attached to the
// corresponding Future object) and then unwinds through the chain
// of awaiters.
class AsyncAwareStackUnwinder : public ValueObject {
 public:
  explicit AsyncAwareStackUnwinder(Thread* thread,
                                   bool* encountered_async_catch_error)
      : zone_(thread->zone()),
        sync_frames_(thread, StackFrameIterator::kNoCrossThreadIteration),
        sync_frame_(nullptr),
        awaiter_frame_{Closure::Handle(zone_), Object::Handle(zone_)},
        encountered_async_catch_error_(encountered_async_catch_error),
        closure_(Closure::Handle(zone_)),
        code_(Code::Handle(zone_)),
        bytecode_(Bytecode::Handle(zone_)),
        context_(Context::Handle(zone_)),
        function_(Function::Handle(zone_)),
        parent_function_(Function::Handle(zone_)),
        object_(Object::Handle(zone_)),
        result_future_(Object::Handle(zone_)),
        suspend_state_(SuspendState::Handle(zone_)),
        controller_(Object::Handle(zone_)),
        subscription_(Object::Handle(zone_)),
        stream_iterator_(Object::Handle(zone_)),
        async_lib_(Library::Handle(zone_, Library::AsyncLibrary())),
        null_closure_(Closure::Handle(zone_)),
        null_code_(Code::Handle(zone_)),
        null_bytecode_(Bytecode::Handle(zone_)) {
    if (encountered_async_catch_error_ != nullptr) {
      *encountered_async_catch_error_ = false;
    }
  }

  void Unwind(intptr_t skip_frames,
              std::function<void(const StackTraceUtils::Frame&)> handle_frame);

 private:
  bool HandleSynchronousFrame();

  void UnwindAwaiterFrame();

  // Returns either the `onData` or the Future awaiter.
  ObjectPtr FindCallerInAsyncStarStreamController(
      const Object& async_star_stream_controller);

  void InitializeAwaiterFrameFromSuspendState();

  void InitializeAwaiterFrameFromFutureListener(const Object& listener);

  void UnwindToAwaiter();

  // |frame.next| is a |_Future| instance. Unwind to the next frame.
  void UnwindFrameToFutureListener();

  // |frame.next| is an |_SyncStreamController| instance.
  void UnwindFrameToStreamController();

  // Follow awaiter-links from the given closure until the first
  // non-closure awaiter-link is encountered.
  //
  // |link| will contain the first non-closure awaiter-link or `null`.
  // |closure| will be updated to point to the last closure in the chain.
  void FollowAwaiterLinks(Closure* closure, Object* link);

  // Update |awaiter_frame| by unwinding awaiter links of the current closure.
  void ComputeNextFrameFromAwaiterLink();

  ObjectPtr GetReceiver() const;

  // Returns |true| if propagating an error to the listeners of this `_Future`
  // will always encounter an error handler. Future handles error iff:
  //
  // * It has no listeners and is marked as ignoring errors
  // * All of its listeners either have an error handler or corresponding
  //   result future handles error.
  //
  // Note: this ignores simple error forwarding/rethrow which occurs in `await`
  // or patterns like `fut.then(onError: c.completeError)`.
  bool WillFutureHandleError(const Object& future, intptr_t depth = 0);

  void MarkAsHandlingAsyncError() const {
    if (ShouldComputeIfAsyncErrorIsHandled()) {
      *encountered_async_catch_error_ = true;
    }
  }

  bool ShouldComputeIfAsyncErrorIsHandled() const {
    return encountered_async_catch_error_ != nullptr &&
           !*encountered_async_catch_error_;
  }

#define USED_CLASS_LIST(V)                                                     \
  V(_AsyncStarStreamController)                                                \
  V(_BufferingStreamSubscription)                                              \
  V(_Completer)                                                                \
  V(_AsyncCompleter)                                                           \
  V(_SyncCompleter)                                                            \
  V(_ControllerSubscription)                                                   \
  V(_Future)                                                                   \
  V(_FutureListener)                                                           \
  V(_StreamController)                                                         \
  V(_StreamIterator)                                                           \
  V(_SyncStreamController)                                                     \
  V(_StreamControllerAddStreamState)                                           \
  V(_AddStreamState)

  enum ClassId {
#define DECLARE_CONSTANT(symbol) k##symbol,
    USED_CLASS_LIST(DECLARE_CONSTANT)
#undef DECLARE_CONSTANT
  };

#define USED_FIELD_LIST(V)                                                     \
  V(_AsyncStarStreamController, asyncStarBody)                                 \
  V(_AsyncStarStreamController, controller)                                    \
  V(_BufferingStreamSubscription, _onData)                                     \
  V(_BufferingStreamSubscription, _onDone)                                     \
  V(_BufferingStreamSubscription, _onError)                                    \
  V(_BufferingStreamSubscription, _state)                                      \
  V(_Completer, future)                                                        \
  V(_Future, _resultOrListeners)                                               \
  V(_Future, _state)                                                           \
  V(_FutureListener, callback)                                                 \
  V(_FutureListener, result)                                                   \
  V(_FutureListener, state)                                                    \
  V(_FutureListener, _nextListener)                                            \
  V(_StreamController, _state)                                                 \
  V(_StreamController, _varData)                                               \
  V(_StreamControllerAddStreamState, _varData)                                 \
  V(_StreamIterator, _hasValue)                                                \
  V(_StreamIterator, _stateData)                                               \
  V(_AddStreamState, addStreamFuture)

  enum FieldId {
#define DECLARE_CONSTANT(class_symbol, field_symbol)                           \
  k##class_symbol##_##field_symbol,
    USED_FIELD_LIST(DECLARE_CONSTANT)
#undef DECLARE_CONSTANT
  };

#define PLUS_ONE(...) +1
  static constexpr intptr_t kUsedClassCount = 0 USED_CLASS_LIST(PLUS_ONE);
  static constexpr intptr_t kUsedFieldCount = 0 USED_FIELD_LIST(PLUS_ONE);
#undef PLUS_ONE

#define DECLARE_GETTER(symbol)                                                 \
  const Class& symbol() {                                                      \
    auto& cls = classes_[k##symbol];                                           \
    if (cls == nullptr) {                                                      \
      cls = &Class::Handle(                                                    \
          zone_, async_lib_.LookupClassAllowPrivate(Symbols::symbol()));       \
      ASSERT(!cls->IsNull());                                                  \
    }                                                                          \
    return *cls;                                                               \
  }
  USED_CLASS_LIST(DECLARE_GETTER)
#undef DECLARE_GETTER

#define DECLARE_GETTER(class_symbol, field_symbol)                             \
  ObjectPtr Get##class_symbol##_##field_symbol(const Object& obj) {            \
    auto& field = fields_[k##class_symbol##_##field_symbol];                   \
    if (field == nullptr) {                                                    \
      field = &Field::Handle(zone_, class_symbol().LookupFieldAllowPrivate(    \
                                        Symbols::field_symbol()));             \
      ASSERT(!field->IsNull());                                                \
    }                                                                          \
    return Instance::Cast(obj).GetField(*field);                               \
  }
  USED_FIELD_LIST(DECLARE_GETTER)
#undef DECLARE_GETTER

  struct AwaiterFrame {
    Closure& closure;
    Object& next;
  };

  Zone* zone_;
  DartFrameIterator sync_frames_;

  StackFrame* sync_frame_;
  AwaiterFrame awaiter_frame_;

  bool* encountered_async_catch_error_;

  Closure& closure_;
  Code& code_;
  Bytecode& bytecode_;
  Context& context_;
  Function& function_;
  Function& parent_function_;
  Object& object_;
  Object& result_future_;
  SuspendState& suspend_state_;

  Object& controller_;
  Object& subscription_;
  Object& stream_iterator_;

  const Library& async_lib_;
  Class* classes_[kUsedClassCount] = {};
  Field* fields_[kUsedFieldCount] = {};

  const Closure& null_closure_;
  const Code& null_code_;
  const Bytecode& null_bytecode_;

  DISALLOW_COPY_AND_ASSIGN(AsyncAwareStackUnwinder);
};

void AsyncAwareStackUnwinder::Unwind(
    intptr_t skip_frames,
    std::function<void(const StackTraceUtils::Frame&)> handle_frame) {
  // First skip the given number of synchronous frames.
  sync_frame_ = sync_frames_.NextFrame();
  while (skip_frames > 0 && sync_frame_ != nullptr) {
    sync_frame_ = sync_frames_.NextFrame();
    skip_frames--;
  }

  // Continue unwinding synchronous portion of the stack looking for
  // a synchronous frame which has an awaiter.
  while (sync_frame_ != nullptr && awaiter_frame_.closure.IsNull()) {
    const bool was_handled = HandleSynchronousFrame();
    if (!was_handled) {
      if (sync_frame_->is_interpreted()) {
        bytecode_ = sync_frame_->LookupDartBytecode();
        if (bytecode_.function() == Function::null()) {
          continue;
        }
        const uword pc_offset = sync_frame_->pc() - bytecode_.PayloadStart();
        handle_frame(
            {sync_frame_, null_code_, bytecode_, pc_offset, null_closure_});
      } else {
        code_ = sync_frame_->LookupDartCode();
        const uword pc_offset = sync_frame_->pc() - code_.PayloadStart();
        handle_frame(
            {sync_frame_, code_, null_bytecode_, pc_offset, null_closure_});
      }
    }
    sync_frame_ = sync_frames_.NextFrame();
  }

  const StackTraceUtils::Frame gap_frame = {
      nullptr, StubCode::AsynchronousGapMarker(), null_bytecode_,
      /*pc_offset=*/0, null_closure_};

  // Traverse awaiter frames.
  bool any_async = false;
  for (; !awaiter_frame_.closure.IsNull(); UnwindToAwaiter()) {
    function_ = awaiter_frame_.closure.function();
    if (function_.IsNull()) {
      continue;
    }

    any_async = true;
    uword pc_offset;
    if (awaiter_frame_.next.IsSuspendState()) {
      const uword pc = SuspendState::Cast(awaiter_frame_.next).pc();
      if (pc == 0) {
        // Async function is already resumed.
        continue;
      }

      code_ = SuspendState::Cast(awaiter_frame_.next).GetCodeObject();
      pc_offset = pc - code_.PayloadStart();
    } else {
      // This is an asynchronous continuation represented by a closure which
      // will handle successful completion. This function is not yet executing
      // so we have to use artificial marker offset (1).
      code_ = function_.EnsureHasCode();
      RELEASE_ASSERT(!code_.IsNull());
      pc_offset =
          (function_.entry_point() + StackTraceUtils::kFutureListenerPcOffset) -
          code_.PayloadStart();
    }

    handle_frame(gap_frame);
    handle_frame(
        {nullptr, code_, null_bytecode_, pc_offset, awaiter_frame_.closure});
  }

  if (any_async) {
    handle_frame(gap_frame);
  }
}

ObjectPtr AsyncAwareStackUnwinder::GetReceiver() const {
  return *(reinterpret_cast<ObjectPtr*>(sync_frame_->GetCallerSp()) +
           function_.num_fixed_parameters() - 1);
}

bool AsyncAwareStackUnwinder::HandleSynchronousFrame() {
  function_ = sync_frame_->LookupDartFunction();
  if (function_.IsNull()) {
    return false;
  }

  // This is an invocation of an `async` or `async*` function.
  if (function_.IsAsyncFunction() || function_.IsAsyncGenerator()) {
    InitializeAwaiterFrameFromSuspendState();
    return false;
  }

  // This is an invocation of a closure which has a variable marked
  // with `@pragma('vm:awaiter-link')` which points to the awaiter.
  if (function_.HasAwaiterLink()) {
    object_ = GetReceiver();
    if (object_.IsClosure() &&
        TryGetAwaiterLink(Closure::Cast(object_), &awaiter_frame_.next)) {
      if (awaiter_frame_.next.IsSuspendState()) {
        awaiter_frame_.closure ^= object_.ptr();
        return true;  // Hide this frame from the stack trace.
      } else if (awaiter_frame_.next.GetClassId() == _Future().id()) {
        UnwindFrameToFutureListener();
        return false;  // Do not hide this from the stack trace.
      }
    }
  }

  // This is `_FutureListener.handleValue(...)` invocation.
  if (function_.recognized_kind() ==
      MethodRecognizer::kFutureListenerHandleValue) {
    object_ = GetReceiver();
    InitializeAwaiterFrameFromFutureListener(object_);
    UnwindToAwaiter();
    return true;  // Hide this frame from the stack trace.
  }

  return false;
}

void AsyncAwareStackUnwinder::InitializeAwaiterFrameFromSuspendState() {
  if (function_.IsAsyncFunction() || function_.IsAsyncGenerator()) {
    // Check if we reached a resumed asynchronous function. In this case we
    // are going to start following async frames after we emit this frame.
    object_ = *reinterpret_cast<ObjectPtr*>(LocalVarAddress(
        sync_frame_->fp(), runtime_frame_layout.FrameSlotForVariableIndex(
                               SuspendState::kSuspendStateVarIndex)));

    awaiter_frame_.closure = Closure::null();
    if (WasPreviouslySuspended(function_, object_)) {
      awaiter_frame_.next = object_.ptr();
      UnwindToAwaiter();
    }
  }
}

void AsyncAwareStackUnwinder::UnwindToAwaiter() {
  do {
    UnwindAwaiterFrame();
  } while (awaiter_frame_.closure.IsNull() && !awaiter_frame_.next.IsNull());
}

void AsyncAwareStackUnwinder::FollowAwaiterLinks(Closure* closure,
                                                 Object* link) {
  *link = Object::null();
  while (!closure->IsNull() && TryGetAwaiterLink(*closure, link) &&
         link->IsClosure()) {
    *closure ^= link->ptr();
  }
}

void AsyncAwareStackUnwinder::ComputeNextFrameFromAwaiterLink() {
  FollowAwaiterLinks(&awaiter_frame_.closure, &object_);
  if (!object_.IsNull()) {
    awaiter_frame_.next = object_.ptr();
  }
}

void AsyncAwareStackUnwinder::UnwindAwaiterFrame() {
  if (awaiter_frame_.next.IsSuspendState()) {
    awaiter_frame_.next =
        SuspendState::Cast(awaiter_frame_.next).function_data();
  } else if (awaiter_frame_.next.GetClassId() == _SyncCompleter().id() ||
             awaiter_frame_.next.GetClassId() == _AsyncCompleter().id()) {
    awaiter_frame_.next = Get_Completer_future(awaiter_frame_.next);
  }

  if (awaiter_frame_.next.GetClassId() == _AsyncStarStreamController().id()) {
    awaiter_frame_.next =
        Get_AsyncStarStreamController_controller(awaiter_frame_.next);
  }

  if (awaiter_frame_.next.GetClassId() == _Future().id()) {
    UnwindFrameToFutureListener();
  } else if (awaiter_frame_.next.GetClassId() == _SyncStreamController().id()) {
    UnwindFrameToStreamController();
    ComputeNextFrameFromAwaiterLink();
  } else {
    awaiter_frame_.closure = Closure::null();
    awaiter_frame_.next = Object::null();
  }
}

void AsyncAwareStackUnwinder::UnwindFrameToFutureListener() {
  object_ = Get_Future__resultOrListeners(awaiter_frame_.next);
  if (object_.GetClassId() == _FutureListener().id()) {
    InitializeAwaiterFrameFromFutureListener(object_);
  } else {
    if (ShouldComputeIfAsyncErrorIsHandled()) {
      // Check if error on this future was ignored through |Future.ignore|.
      const auto state =
          Smi::Value(Smi::RawCast(Get_Future__state(awaiter_frame_.next)));
      if ((state & k_Future__stateIgnoreError) != 0) {
        MarkAsHandlingAsyncError();
      }
    }

    awaiter_frame_.closure = Closure::null();
    awaiter_frame_.next = Object::null();
  }
}

bool AsyncAwareStackUnwinder::WillFutureHandleError(const Object& future,
                                                    intptr_t depth /* = 0 */) {
  if (depth > 100 || future.GetClassId() != _Future().id()) {
    return true;  // Conservative.
  }

  if (Get_Future__resultOrListeners(future) == Object::null()) {
    // No listeners: check if future is simply ignoring errors.
    const auto state = Smi::Value(Smi::RawCast(Get_Future__state(future)));
    return (state & k_Future__stateIgnoreError) != 0;
  }

  for (auto& listener = Object::Handle(Get_Future__resultOrListeners(future));
       listener.GetClassId() == _FutureListener().id();
       listener = Get_FutureListener__nextListener(listener)) {
    const auto state =
        Smi::Value(Smi::RawCast(Get_FutureListener_state(listener)));
    if ((state & k_FutureListener_stateCatchError) == 0 &&
        !WillFutureHandleError(
            Object::Handle(Get_FutureListener_result(listener)), depth + 1)) {
      return false;
    }
  }

  return true;
}

void AsyncAwareStackUnwinder::InitializeAwaiterFrameFromFutureListener(
    const Object& listener) {
  if (listener.GetClassId() != _FutureListener().id()) {
    awaiter_frame_.closure = Closure::null();
    awaiter_frame_.next = Object::null();
    return;
  }

  const auto state =
      Smi::Value(Smi::RawCast(Get_FutureListener_state(listener)));
  if (state == k_FutureListener_stateThen ||
      state == k_FutureListener_stateCatchError ||
      state == k_FutureListener_stateWhenComplete ||
      state ==
          (k_FutureListener_stateThen | k_FutureListener_stateCatchError) ||
      state == (k_FutureListener_stateThen | k_FutureListener_stateCatchError |
                k_FutureListener_maskAwait)) {
    result_future_ = Get_FutureListener_result(listener);
  } else {
    result_future_ = Object::null();
  }
  awaiter_frame_.closure =
      Closure::RawCast(Get_FutureListener_callback(listener));
  awaiter_frame_.next = result_future_.ptr();

  ComputeNextFrameFromAwaiterLink();

  if (ShouldComputeIfAsyncErrorIsHandled() && !result_future_.IsNull() &&
      result_future_.ptr() != awaiter_frame_.next.ptr()) {
    // We have unwound through closure rather than followed result future, this
    // can be caused by unwinding through `await` or code like
    // `fut.whenComplete(c.complete)`. If the current future does not
    // catch the error then the error will be forwarded into result_future_.
    // Check if result_future_ handles it and set
    // encountered_async_catch_error_ respectively.
    if ((state & k_FutureListener_stateCatchError) == 0 &&
        WillFutureHandleError(result_future_)) {
      MarkAsHandlingAsyncError();
    }
  }

  // If the Future has catchError callback attached through either
  // `Future.catchError` or `Future.then(..., onError: ...)` then we should
  // treat this listener as a catch all exception handler. However we should
  // ignore the case when these callbacks are simply forwarding errors into a
  // suspended async function, because it will be represented by its own async
  // frame.
  //
  // However if we fail to unwind this frame (e.g. because there is some
  // Zone wrapping callbacks and obstructing unwinding) then we conservatively
  // treat this error handler as handling all errors to prevent user
  // unfriendly situations where debugger stops on handled exceptions.
  if ((state & k_FutureListener_stateCatchError) != 0 &&
      ((state & k_FutureListener_maskAwait) == 0 ||
       !awaiter_frame_.next.IsSuspendState())) {
    MarkAsHandlingAsyncError();
  }
}

void AsyncAwareStackUnwinder::UnwindFrameToStreamController() {
  controller_ = awaiter_frame_.next.ptr();

  // Clear the frame.
  awaiter_frame_.closure = Closure::null();
  awaiter_frame_.next = Object::null();

  const auto state =
      Smi::Value(Smi::RawCast(Get_StreamController__state(controller_)));

  if ((state & k_StreamController__STATE_SUBSCRIPTION_MASK) !=
      k_StreamController__STATE_SUBSCRIBED) {
    return;
  }

  subscription_ = Get_StreamController__varData(controller_);
  if ((state & k_StreamController__STATE_ADDSTREAM) != 0) {
    subscription_ = Get_StreamControllerAddStreamState__varData(subscription_);
  }

  closure_ ^= Get_BufferingStreamSubscription__onData(subscription_);

  const auto subscription_state = Smi::Value(
      Smi::RawCast(Get_BufferingStreamSubscription__state(subscription_)));

  const auto has_error_handler =
      ((subscription_state &
        k_BufferingStreamSubscription__STATE_HAS_ERROR_HANDLER) != 0);

  // If this is not the "_StreamIterator._onData" tear-off, we return the
  // callback we found.
  function_ = closure_.function();
  if (function_.IsImplicitClosureFunction()) {
    // Handle `await for` case. In this case onData is calling
    // _StreamIterator._onData which then notifies awaiter by completing
    // _StreamIterator.moveNextFuture.
    if (function_.Owner() == _StreamIterator().ptr()) {
      // All implicit closure functions (tear-offs) have the "this" receiver
      // captured in the context.
      stream_iterator_ = closure_.GetImplicitClosureReceiver();

      if (stream_iterator_.GetClassId() != _StreamIterator().id()) {
        UNREACHABLE();
      }

      // If `_hasValue` is true then the `StreamIterator._stateData` field
      // contains the iterator's value. In that case we cannot unwind anymore.
      //
      // Notice: With correct async* semantics this may never be true: the
      // async* generator should only be invoked to produce a value if there's
      // an in-progress `await streamIterator.moveNext()` call. Once such call
      // has finished the async* generator should be paused/yielded until the
      // next such call - and being paused/yielded means it should not appear
      // in stack traces.
      //
      // See dartbug.com/48695.
      if (Get_StreamIterator__hasValue(stream_iterator_) ==
          Object::bool_true().ptr()) {
        if (has_error_handler) {
          MarkAsHandlingAsyncError();
        }
        return;
      }

      // If we have an await'er for `await streamIterator.moveNext()` we
      // continue unwinding there.
      //
      // Notice: With correct async* semantics this may always contain a Future
      // See also comment above as well as dartbug.com/48695.
      object_ = Get_StreamIterator__stateData(stream_iterator_);
      if (object_.GetClassId() == _Future().id()) {
        awaiter_frame_.next = object_.ptr();
      } else {
        if (has_error_handler) {
          MarkAsHandlingAsyncError();
        }
      }
      return;
    }

    // Handle `yield*` case. Here one stream controller will be forwarding
    // to another one. If the destination controller is
    // _AsyncStarStreamController, then we should make sure to reflect
    // its asyncStarBody in the stack trace.
    if (function_.Owner() == _StreamController().ptr()) {
      // Get the controller to which we are forwarding and check if it is
      // in the ADD_STREAM state.
      object_ = closure_.GetImplicitClosureReceiver();
      const auto state =
          Smi::Value(Smi::RawCast(Get_StreamController__state(object_)));
      if ((state & k_StreamController__STATE_ADDSTREAM) != 0) {
        // Get to the addStreamFuture - if this is yield* internals we
        // will be able to get original _AsyncStarStreamController from
        // handler attached to that future.
        object_ = Get_StreamController__varData(object_);
        object_ = Get_AddStreamState_addStreamFuture(object_);
        object_ = Get_Future__resultOrListeners(object_);
        if (object_.GetClassId() == _FutureListener().id()) {
          const auto state =
              Smi::Value(Smi::RawCast(Get_FutureListener_state(object_)));
          if (state == k_FutureListener_stateThen) {
            auto& handler = Closure::Handle(
                Closure::RawCast(Get_FutureListener_callback(object_)));
            FollowAwaiterLinks(&handler, &object_);
            if (object_.GetClassId() == _AsyncStarStreamController().id()) {
              awaiter_frame_.closure = Closure::RawCast(
                  Get_AsyncStarStreamController_asyncStarBody(object_));
              return;
            }
          }
        }
      }
    }
  }

  awaiter_frame_.closure = closure_.ptr();

  bool found_awaiter_link_in_sibling_handler = false;

  if (!function_.HasAwaiterLink()) {
    // If we don't have awaiter-link in the `onData` handler, try checking
    // if either onError or onDone have an awaiter link.
    closure_ ^= Get_BufferingStreamSubscription__onError(subscription_);
    function_ = closure_.function();
    found_awaiter_link_in_sibling_handler = function_.HasAwaiterLink();
  }

  if (!function_.HasAwaiterLink()) {
    closure_ ^= Get_BufferingStreamSubscription__onDone(subscription_);
    function_ = closure_.function();
    found_awaiter_link_in_sibling_handler = function_.HasAwaiterLink();
  }

  if (has_error_handler || found_awaiter_link_in_sibling_handler) {
    FollowAwaiterLinks(&closure_, &object_);
  }

  if (has_error_handler && object_.GetClassId() != _Future().id() &&
      object_.GetClassId() != _SyncStreamController().id()) {
    MarkAsHandlingAsyncError();
  }

  if (found_awaiter_link_in_sibling_handler) {
    if (object_.GetClassId() == _AsyncStarStreamController().id() ||
        object_.GetClassId() == _SyncStreamController().id()) {
      // We can continue unwinding from here.
      awaiter_frame_.closure = closure_.ptr();
    } else {
      awaiter_frame_.next = object_.ptr();
    }
  }
}

}  // namespace

bool StackTraceUtils::IsPossibleAwaiterLink(const Class& cls) {
  if (cls.library() != Library::AsyncLibrary()) {
    return false;
  }

  String& class_name = String::Handle();
  const auto is_class = [&](const String& name) {
    class_name = cls.Name();
    return String::EqualsIgnoringPrivateKey(class_name, name);
  };

  return is_class(Symbols::_AsyncStarStreamController()) ||
         is_class(Symbols::_SyncStreamController()) ||
         is_class(Symbols::_StreamController()) ||
         is_class(Symbols::_Completer()) ||
         is_class(Symbols::_AsyncCompleter()) ||
         is_class(Symbols::_SyncCompleter()) || is_class(Symbols::_Future());
}

bool StackTraceUtils::IsNeededForAsyncAwareUnwinding(const Function& function) {
  // If this is a closure function which specifies an awaiter-link then
  // we need to retain both function and the corresponding code.
  if (function.HasAwaiterLink()) {
    return true;
  }

  if (function.recognized_kind() ==
      MethodRecognizer::kFutureListenerHandleValue) {
    return true;
  }

  return false;
}

void StackTraceUtils::CollectFrames(
    Thread* thread,
    int skip_frames,
    const std::function<void(const StackTraceUtils::Frame&)>& handle_frame,
    bool* has_async_catch_error /* = null */) {
  AsyncAwareStackUnwinder it(thread, has_async_catch_error);
  it.Unwind(skip_frames, handle_frame);
}

bool StackTraceUtils::GetSuspendState(const Closure& closure,
                                      Object* suspend_state) {
  if (TryGetAwaiterLink(closure, suspend_state)) {
    return suspend_state->IsSuspendState();
  }
  return false;
}

}  // namespace dart
