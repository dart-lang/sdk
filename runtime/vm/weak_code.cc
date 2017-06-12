// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/weak_code.h"

#include "platform/assert.h"

#include "vm/code_patcher.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"

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
    if (code.raw() == weak_property.key()) {
      return true;
    }
  }
  return false;
}


void WeakCodeReferences::DisableCode() {
  Thread* thread = Thread::Current();
  const Array& code_objects = Array::Handle(thread->zone(), array_.raw());
  if (code_objects.IsNull()) {
    return;
  }
  ASSERT(!FLAG_precompiled_runtime);
  UpdateArrayTo(Object::null_array());
  // Disable all code on stack.
  Code& code = Code::Handle();
  {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    while (frame != NULL) {
      code = frame->LookupDartCode();
      if (IsOptimizedCode(code_objects, code)) {
        ReportDeoptimization(code);
        DeoptimizeAt(code, frame);
      }
      frame = iterator.NextFrame();
    }
  }

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
      function ^= owner.raw();
    } else if (owner.IsClass()) {
      Class& cls = Class::Handle();
      cls ^= owner.raw();
      cls.DisableAllocationStub();
      continue;
    } else if (owner.IsNull()) {
      code.Print();
      continue;
    }

    // If function uses dependent code switch it to unoptimized.
    if (code.is_optimized() && (function.CurrentCode() == code.raw())) {
      ReportSwitchingCode(code);
      function.SwitchToUnoptimizedCode();
    } else if (function.unoptimized_code() == code.raw()) {
      ReportSwitchingCode(code);
      function.set_was_compiled(false);
      function.ClearICDataArray();
      // Remove the code object from the function. The next time the
      // function is invoked, it will be compiled again.
      function.ClearCode();
      // Invalidate the old code object so existing references to it
      // (from optimized code) will be patched when invoked.
      if (!code.IsDisabled()) {
        code.DisableDartCode();
      }
    } else {
      // Make non-OSR code non-entrant.
      if (!code.IsDisabled()) {
        ReportSwitchingCode(code);
        code.DisableDartCode();
      }
    }
  }
}

}  // namespace dart
