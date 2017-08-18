// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_mirrors_api.h"

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

// Facilitate quick access to the current zone once we have the current thread.
#define Z (T->zone())

// --- Classes and Interfaces Reflection ---

DART_EXPORT Dart_Handle Dart_TypeName(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  if (obj.IsType()) {
    const Class& cls = Class::Handle(Type::Cast(obj).type_class());
    return Api::NewHandle(T, cls.UserVisibleName());
  } else {
    RETURN_TYPE_ERROR(Z, object, Class / Type);
  }
}

DART_EXPORT Dart_Handle Dart_QualifiedTypeName(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  if (obj.IsType() || obj.IsClass()) {
    const Class& cls = (obj.IsType())
                           ? Class::Handle(Z, Type::Cast(obj).type_class())
                           : Class::Cast(obj);
    const char* str = cls.ToCString();
    if (str == NULL) {
      RETURN_NULL_ERROR(str);
    }
    CHECK_CALLBACK_STATE(T);
    return Api::NewHandle(T, String::New(str));
  } else {
    RETURN_TYPE_ERROR(Z, object, Class / Type);
  }
}

// --- Function and Variable Reflection ---

// Outside of the vm, we expose setter names with a trailing '='.
static bool HasExternalSetterSuffix(const String& name) {
  return name.CharAt(name.Length() - 1) == '=';
}

static RawString* RemoveExternalSetterSuffix(const String& name) {
  ASSERT(HasExternalSetterSuffix(name));
  return String::SubString(name, 0, name.Length() - 1);
}

DART_EXPORT Dart_Handle Dart_GetFunctionNames(Dart_Handle target) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  Function& func = Function::Handle(Z);
  String& name = String::Handle(Z);

  if (obj.IsType()) {
    const Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());
    const Error& error = Error::Handle(Z, cls.EnsureIsFinalized(T));
    if (!error.IsNull()) {
      return Api::NewHandle(T, error.raw());
    }
    const Array& func_array = Array::Handle(Z, cls.functions());

    // Some special types like 'dynamic' have a null functions list.
    if (!func_array.IsNull()) {
      for (intptr_t i = 0; i < func_array.Length(); ++i) {
        func ^= func_array.At(i);

        // Skip implicit getters and setters.
        if (func.kind() == RawFunction::kImplicitGetter ||
            func.kind() == RawFunction::kImplicitSetter ||
            func.kind() == RawFunction::kImplicitStaticFinalGetter ||
            func.kind() == RawFunction::kMethodExtractor ||
            func.kind() == RawFunction::kNoSuchMethodDispatcher) {
          continue;
        }

        name = func.UserVisibleName();
        names.Add(name);
      }
    }
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    DictionaryIterator it(lib);
    Object& obj = Object::Handle();
    while (it.HasNext()) {
      obj = it.GetNext();
      if (obj.IsFunction()) {
        func ^= obj.raw();
        name = func.UserVisibleName();
        names.Add(name);
      }
    }
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be a class or library.", CURRENT_FUNC);
  }
  return Api::NewHandle(T, Array::MakeFixedLength(names));
}

DART_EXPORT Dart_Handle Dart_LookupFunction(Dart_Handle target,
                                            Dart_Handle function_name) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }
  const String& func_name = Api::UnwrapStringHandle(Z, function_name);
  if (func_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, function_name, String);
  }

  Function& func = Function::Handle(Z);
  String& tmp_name = String::Handle(Z);
  if (obj.IsType()) {
    const Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());

    // Case 1.  Lookup the unmodified function name.
    func = cls.LookupFunctionAllowPrivate(func_name);

    // Case 2.  Lookup the function without the external setter suffix
    // '='.  Make sure to do this check after the regular lookup, so
    // that we don't interfere with operator lookups (like ==).
    if (func.IsNull() && HasExternalSetterSuffix(func_name)) {
      tmp_name = RemoveExternalSetterSuffix(func_name);
      tmp_name = Field::SetterName(tmp_name);
      func = cls.LookupFunctionAllowPrivate(tmp_name);
    }

    // Case 3.  Lookup the function with the getter prefix prepended.
    if (func.IsNull()) {
      tmp_name = Field::GetterName(func_name);
      func = cls.LookupFunctionAllowPrivate(tmp_name);
    }

    // Case 4.  Lookup the function with a . appended to find the
    // unnamed constructor.
    if (func.IsNull()) {
      tmp_name = String::Concat(func_name, Symbols::Dot());
      func = cls.LookupFunctionAllowPrivate(tmp_name);
    }
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);

    // Case 1.  Lookup the unmodified function name.
    func = lib.LookupFunctionAllowPrivate(func_name);

    // Case 2.  Lookup the function without the external setter suffix
    // '='.  Make sure to do this check after the regular lookup, so
    // that we don't interfere with operator lookups (like ==).
    if (func.IsNull() && HasExternalSetterSuffix(func_name)) {
      tmp_name = RemoveExternalSetterSuffix(func_name);
      tmp_name = Field::SetterName(tmp_name);
      func = lib.LookupFunctionAllowPrivate(tmp_name);
    }

    // Case 3.  Lookup the function with the getter prefix prepended.
    if (func.IsNull()) {
      tmp_name = Field::GetterName(func_name);
      func = lib.LookupFunctionAllowPrivate(tmp_name);
    }
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be a class or library.", CURRENT_FUNC);
  }

#if defined(DEBUG)
  if (!func.IsNull()) {
    // We only provide access to a subset of function kinds.
    RawFunction::Kind func_kind = func.kind();
    ASSERT(func_kind == RawFunction::kRegularFunction ||
           func_kind == RawFunction::kGetterFunction ||
           func_kind == RawFunction::kSetterFunction ||
           func_kind == RawFunction::kConstructor);
  }
#endif
  return Api::NewHandle(T, func.raw());
}

DART_EXPORT Dart_Handle Dart_FunctionName(Dart_Handle function) {
  DARTSCOPE(Thread::Current());
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  return Api::NewHandle(T, func.UserVisibleName());
}

DART_EXPORT Dart_Handle Dart_FunctionOwner(Dart_Handle function) {
  DARTSCOPE(Thread::Current());
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  if (func.IsNonImplicitClosureFunction()) {
    RawFunction* parent_function = func.parent_function();
    return Api::NewHandle(T, parent_function);
  }
  const Class& owner = Class::Handle(Z, func.Owner());
  ASSERT(!owner.IsNull());
  if (owner.IsTopLevel()) {
// Top-level functions are implemented as members of a hidden class. We hide
// that class here and instead answer the library.
#if defined(DEBUG)
    const Library& lib = Library::Handle(Z, owner.library());
    if (lib.IsNull()) {
      ASSERT(owner.IsDynamicClass() || owner.IsVoidClass());
    }
#endif
    return Api::NewHandle(T, owner.library());
  } else {
    return Api::NewHandle(T, owner.RareType());
  }
}

DART_EXPORT Dart_Handle Dart_FunctionIsStatic(Dart_Handle function,
                                              bool* is_static) {
  DARTSCOPE(Thread::Current());
  if (is_static == NULL) {
    RETURN_NULL_ERROR(is_static);
  }
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  *is_static = func.is_static();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_FunctionIsConstructor(Dart_Handle function,
                                                   bool* is_constructor) {
  DARTSCOPE(Thread::Current());
  if (is_constructor == NULL) {
    RETURN_NULL_ERROR(is_constructor);
  }
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  *is_constructor = func.kind() == RawFunction::kConstructor;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_FunctionIsGetter(Dart_Handle function,
                                              bool* is_getter) {
  DARTSCOPE(Thread::Current());
  if (is_getter == NULL) {
    RETURN_NULL_ERROR(is_getter);
  }
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  *is_getter = func.IsGetterFunction();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_FunctionIsSetter(Dart_Handle function,
                                              bool* is_setter) {
  DARTSCOPE(Thread::Current());
  if (is_setter == NULL) {
    RETURN_NULL_ERROR(is_setter);
  }
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  *is_setter = (func.kind() == RawFunction::kSetterFunction);
  return Api::Success();
}

// --- Libraries Reflection ---

DART_EXPORT Dart_Handle Dart_LibraryName(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& name = String::Handle(Z, lib.name());
  ASSERT(!name.IsNull());
  return Api::NewHandle(T, name.raw());
}

DART_EXPORT Dart_Handle Dart_LibraryGetClassNames(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  ClassDictionaryIterator it(lib);
  Class& cls = Class::Handle(Z);
  String& name = String::Handle(Z);
  while (it.HasNext()) {
    cls = it.GetNextClass();
    name = cls.UserVisibleName();
    names.Add(name);
  }
  return Api::NewHandle(T, Array::MakeFixedLength(names));
}

// --- Closures Reflection ---

DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure) {
  DARTSCOPE(Thread::Current());
  const Instance& closure_obj = Api::UnwrapInstanceHandle(Z, closure);
  if (closure_obj.IsNull() || !closure_obj.IsClosure()) {
    RETURN_TYPE_ERROR(Z, closure, Instance);
  }

  ASSERT(ClassFinalizer::AllClassesFinalized());

  RawFunction* rf = Closure::Cast(closure_obj).function();
  return Api::NewHandle(T, rf);
}

}  // namespace dart
