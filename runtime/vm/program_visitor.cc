// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/program_visitor.h"

#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

void ProgramVisitor::VisitClasses(ClassVisitor* visitor) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);

  for (intptr_t i = 0; i < libraries.Length(); i++) {
    lib ^= libraries.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }
      visitor->Visit(cls);
    }
  }
}


void ProgramVisitor::VisitFunctions(FunctionVisitor* visitor) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  Array& functions = Array::Handle(zone);
  Array& fields = Array::Handle(zone);
  Field& field = Field::Handle(zone);
  Object& object = Object::Handle(zone);
  Function& function = Function::Handle(zone);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(zone);

  for (intptr_t i = 0; i < libraries.Length(); i++) {
    lib ^= libraries.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      functions = cls.functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        visitor->Visit(function);
        if (function.HasImplicitClosureFunction()) {
          function = function.ImplicitClosureFunction();
          visitor->Visit(function);
        }
      }

      functions = cls.invocation_dispatcher_cache();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        object = functions.At(j);
        if (object.IsFunction()) {
          function ^= functions.At(j);
          visitor->Visit(function);
        }
      }
      fields = cls.fields();
      for (intptr_t j = 0; j < fields.Length(); j++) {
        field ^= fields.At(j);
        if (field.is_static() && field.HasPrecompiledInitializer()) {
          function ^= field.PrecompiledInitializer();
          visitor->Visit(function);
        }
      }
    }
  }
  closures = isolate->object_store()->closure_functions();
  for (intptr_t j = 0; j < closures.Length(); j++) {
    function ^= closures.At(j);
    visitor->Visit(function);
    ASSERT(!function.HasImplicitClosureFunction());
  }
}

}  // namespace dart
