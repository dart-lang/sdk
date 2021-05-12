// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/weak_code.h"

#include "platform/assert.h"

#include "vm/code_patcher.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/thread_registry.h"

namespace dart {

bool WeakCodeReferences::HasCodes() const {
  return !array_.IsNull() && (array_.Length() > 0);
}

void WeakCodeReferences::Register(const Code& value) {
  if (!array_.IsNull()) {
    // Try to find and reuse cleared WeakProperty to avoid allocating new one.
    WeakProperty& weak_property = WeakProperty::Handle();
    for (intptr_t i = 0; i < array_.Length(); i++) {
      weak_property ^= array_.At(i);
      if (weak_property.key() == Code::null()) {
        // Empty property found. Reuse it.
        weak_property.set_key(value);
        return;
      }
    }
  }

  const WeakProperty& weak_property =
      WeakProperty::Handle(WeakProperty::New(Heap::kOld));
  weak_property.set_key(value);

  intptr_t length = array_.IsNull() ? 0 : array_.Length();
  const Array& new_array =
      Array::Handle(Array::Grow(array_, length + 1, Heap::kOld));
  new_array.SetAt(length, weak_property);
  UpdateArrayTo(new_array);
}

bool WeakCodeReferences::IsOptimizedCode(const Array& dependent_code,
                                         const Code& code) {
  if (!code.is_optimized()) {
    return false;
  }
  WeakProperty& weak_property = WeakProperty::Handle();
  for (intptr_t i = 0; i < dependent_code.Length(); i++) {
    weak_property ^= dependent_code.At(i);
    if (code.ptr() == weak_property.key()) {
      return true;
    }
  }
  return false;
}

void WeakCodeReferences::DisableCode() {
  Thread* thread = Thread::Current();
  const Array& code_objects = Array::Handle(thread->zone(), array_.ptr());
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(code_objects.IsNull());
  return;
#else
  // Ensure mutators see empty code_objects only after code was deoptimized.
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());

  if (code_objects.IsNull()) {
    return;
  }

  auto isolate_group = IsolateGroup::Current();
  // Deoptimize stacks and disable code with mutators stopped.
  isolate_group->RunWithStoppedMutators([&]() {
    Code& code = Code::Handle();
    isolate_group->ForEachIsolate(
        [&](Isolate* isolate) {
          auto mutator_thread = isolate->mutator_thread();
          DartFrameIterator iterator(
              mutator_thread, StackFrameIterator::kAllowCrossThreadIteration);
          StackFrame* frame = iterator.NextFrame();
          while (frame != nullptr) {
            code = frame->LookupDartCode();
            if (IsOptimizedCode(code_objects, code)) {
              ReportDeoptimization(code);
              DeoptimizeAt(mutator_thread, code, frame);
            }
            frame = iterator.NextFrame();
          }
        },
        /*at_safepoint=*/true);

    // Switch functions that use dependent code to unoptimized code.
    WeakProperty& weak_property = WeakProperty::Handle();
    Object& owner = Object::Handle();
    Function& function = Function::Handle();
    for (intptr_t i = 0; i < code_objects.Length(); i++) {
      weak_property ^= code_objects.At(i);
      code ^= weak_property.key();
      if (code.IsNull()) {
        // Code was garbage collected already.
        continue;
      }
      owner = code.owner();
      if (owner.IsFunction()) {
        function ^= owner.ptr();
      } else if (owner.IsClass()) {
        Class& cls = Class::Handle();
        cls ^= owner.ptr();
        cls.DisableAllocationStub();
        continue;
      } else if (owner.IsNull()) {
        code.Print();
        continue;
      }

      // Only optimized code can make dependencies (assumptions) about CHA /
      // field guards and might need to be deoptimized if those assumptions no
      // longer hold.
      // See similar assertions when code gets registered in
      // `Field::RegisterDependentCode` and `Class::RegisterCHACode`.
      ASSERT(code.is_optimized());
      ASSERT(function.unoptimized_code() != code.ptr());

      // If function uses dependent code switch it to unoptimized.
      if (function.CurrentCode() == code.ptr()) {
        ReportSwitchingCode(code);
        function.SwitchToUnoptimizedCode();
      } else {
        // Make non-OSR code non-entrant.
        if (!code.IsDisabled()) {
          ReportSwitchingCode(code);
          code.DisableDartCode();
        }
      }
    }

    UpdateArrayTo(Object::null_array());
  });

#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart
