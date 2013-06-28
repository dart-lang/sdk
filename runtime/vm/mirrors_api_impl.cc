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

// When we want to return a handle to a type to the user, we handle
// class-types differently than some other types.
static Dart_Handle TypeToHandle(Isolate* isolate,
                                const char* function_name,
                                const AbstractType& type) {
  if (type.IsMalformed()) {
    const Error& error = Error::Handle(type.malformed_error());
    return Api::NewError("%s: malformed type encountered: %s.",
        function_name, error.ToErrorCString());
  } else if (type.HasResolvedTypeClass()) {
    const Class& cls = Class::Handle(isolate, type.type_class());
#if defined(DEBUG)
    const Library& lib = Library::Handle(cls.library());
    if (lib.IsNull()) {
      ASSERT(cls.IsDynamicClass() || cls.IsVoidClass());
    }
#endif
    return Api::NewHandle(isolate, cls.raw());
  } else if (type.IsTypeParameter()) {
    return Api::NewHandle(isolate, type.raw());
  } else {
    return Api::NewError("%s: unexpected type '%s' encountered.",
                         function_name, type.ToCString());
  }
}


// --- Classes and Interfaces Reflection ---

DART_EXPORT Dart_Handle Dart_ClassName(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (obj.IsType() || obj.IsClass()) {
    const Class& cls = (obj.IsType()) ?
        Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
    return Api::NewHandle(isolate, cls.UserVisibleName());
  } else {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
}


DART_EXPORT Dart_Handle Dart_ClassGetLibrary(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);

#if defined(DEBUG)
  const Library& lib = Library::Handle(cls.library());
  if (lib.IsNull()) {
    // ASSERT(cls.IsDynamicClass() || cls.IsVoidClass());
    if (!cls.IsDynamicClass() && !cls.IsVoidClass()) {
      fprintf(stderr, "NO LIBRARY: %s\n", cls.ToCString());
    }
  }
#endif

  return Api::NewHandle(isolate, cls.library());
}


DART_EXPORT Dart_Handle Dart_ClassGetInterfaceCount(Dart_Handle object,
                                                    intptr_t* count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  const Array& interface_types = Array::Handle(isolate, cls.interfaces());
  if (interface_types.IsNull()) {
    *count = 0;
  } else {
    *count = interface_types.Length();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_ClassGetInterfaceAt(Dart_Handle object,
                                                 intptr_t index) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);

  // Finalize all classes.
  Dart_Handle state = Api::CheckIsolateState(isolate);
  if (::Dart_IsError(state)) {
    return state;
  }

  const Array& interface_types = Array::Handle(isolate, cls.interfaces());
  if (index < 0 || index >= interface_types.Length()) {
    return Api::NewError("%s: argument 'index' out of bounds.", CURRENT_FUNC);
  }
  Type& interface_type = Type::Handle(isolate);
  interface_type ^= interface_types.At(index);
  if (interface_type.HasResolvedTypeClass()) {
    return Api::NewHandle(isolate, interface_type.type_class());
  }
  const String& type_name =
      String::Handle(isolate, interface_type.TypeClassName());
  return Api::NewError("%s: internal error: found unresolved type class '%s'.",
                       CURRENT_FUNC, type_name.ToCString());
}


DART_EXPORT bool Dart_ClassIsTypedef(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  // For now we represent typedefs as non-canonical signature classes.
  // I anticipate this may change if we make typedefs more general.
  return cls.IsSignatureClass() && !cls.IsCanonicalSignatureClass();
}


DART_EXPORT Dart_Handle Dart_ClassGetTypedefReferent(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  if (!cls.IsSignatureClass() && !cls.IsCanonicalSignatureClass()) {
    const String& cls_name = String::Handle(cls.UserVisibleName());
    return Api::NewError("%s: class '%s' is not a typedef class. "
                         "See Dart_ClassIsTypedef.",
                         CURRENT_FUNC, cls_name.ToCString());
  }

  const Function& func = Function::Handle(isolate, cls.signature_function());
  return Api::NewHandle(isolate, func.signature_class());
}


DART_EXPORT bool Dart_ClassIsFunctionType(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  // A class represents a function type when it is a canonical
  // signature class.
  return cls.IsCanonicalSignatureClass();
}


DART_EXPORT Dart_Handle Dart_ClassGetFunctionTypeSignature(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  if (!cls.IsCanonicalSignatureClass()) {
    const String& cls_name = String::Handle(cls.UserVisibleName());
    return Api::NewError("%s: class '%s' is not a function-type class. "
                         "See Dart_ClassIsFunctionType.",
                         CURRENT_FUNC, cls_name.ToCString());
  }
  return Api::NewHandle(isolate, cls.signature_function());
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
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  Function& func = Function::Handle();
  String& name = String::Handle();

  if (obj.IsType() || obj.IsClass()) {
    // For backwards compatibility we allow class objects to be passed in
    // for now. This needs to be removed once all code that uses class
    // objects to invoke Dart_Invoke is removed.
    const Class& cls = (obj.IsType()) ?
        Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
    const Error& error = Error::Handle(isolate, cls.EnsureIsFinalized(isolate));
    if (!error.IsNull()) {
      return Api::NewHandle(isolate, error.raw());
    }
    const Array& func_array = Array::Handle(cls.functions());

    // Some special types like 'dynamic' have a null functions list.
    if (!func_array.IsNull()) {
      for (intptr_t i = 0; i < func_array.Length(); ++i) {
        func ^= func_array.At(i);

        // Skip implicit getters and setters.
        if (func.kind() == RawFunction::kImplicitGetter ||
            func.kind() == RawFunction::kImplicitSetter ||
            func.kind() == RawFunction::kConstImplicitGetter ||
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
        "%s expects argument 'target' to be a class or library.",
        CURRENT_FUNC);
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
}


DART_EXPORT Dart_Handle Dart_LookupFunction(Dart_Handle target,
                                            Dart_Handle function_name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }
  const String& func_name = Api::UnwrapStringHandle(isolate, function_name);
  if (func_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function_name, String);
  }

  Function& func = Function::Handle(isolate);
  String& tmp_name = String::Handle(isolate);
  if (obj.IsType() || obj.IsClass()) {
    // For backwards compatibility we allow class objects to be passed in
    // for now. This needs to be removed once all code that uses class
    // objects to invoke Dart_Invoke is removed.
    const Class& cls = (obj.IsType()) ?
        Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);

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

    // Case 3.  Lookup the funciton with the getter prefix prepended.
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
        "%s expects argument 'target' to be a class or library.",
        CURRENT_FUNC);
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
  return Api::NewHandle(isolate, func.raw());
}


DART_EXPORT Dart_Handle Dart_FunctionName(Dart_Handle function) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  return Api::NewHandle(isolate, func.UserVisibleName());
}


DART_EXPORT Dart_Handle Dart_FunctionOwner(Dart_Handle function) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  if (func.IsNonImplicitClosureFunction()) {
    RawFunction* parent_function = func.parent_function();
    return Api::NewHandle(isolate, parent_function);
  }
  const Class& owner = Class::Handle(func.Owner());
  ASSERT(!owner.IsNull());
  if (owner.IsTopLevel()) {
    // Top-level functions are implemented as members of a hidden class. We hide
    // that class here and instead answer the library.
#if defined(DEBUG)
    const Library& lib = Library::Handle(owner.library());
    if (lib.IsNull()) {
      ASSERT(owner.IsDynamicClass() || owner.IsVoidClass());
    }
#endif
    return Api::NewHandle(isolate, owner.library());
  } else {
    return Api::NewHandle(isolate, owner.raw());
  }
}


DART_EXPORT Dart_Handle Dart_FunctionIsAbstract(Dart_Handle function,
                                                bool* is_abstract) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_abstract == NULL) {
    RETURN_NULL_ERROR(is_abstract);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_abstract = func.is_abstract();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_FunctionIsStatic(Dart_Handle function,
                                              bool* is_static) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_static == NULL) {
    RETURN_NULL_ERROR(is_static);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_static = func.is_static();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_FunctionIsConstructor(Dart_Handle function,
                                                   bool* is_constructor) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_constructor == NULL) {
    RETURN_NULL_ERROR(is_constructor);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_constructor = func.kind() == RawFunction::kConstructor;
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_FunctionIsGetter(Dart_Handle function,
                                              bool* is_getter) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_getter == NULL) {
    RETURN_NULL_ERROR(is_getter);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_getter = func.IsGetterFunction();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_FunctionIsSetter(Dart_Handle function,
                                              bool* is_setter) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_setter == NULL) {
    RETURN_NULL_ERROR(is_setter);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_setter = (func.kind() == RawFunction::kSetterFunction);
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_FunctionReturnType(Dart_Handle function) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }

  if (func.kind() == RawFunction::kConstructor) {
    // Special case the return type for constructors.  Inside the vm
    // we mark them as returning dynamic, but for the purposes of
    // reflection, they return the type of the class being
    // constructed.
    return Api::NewHandle(isolate, func.Owner());
  } else {
    const AbstractType& return_type =
        AbstractType::Handle(isolate, func.result_type());
    return TypeToHandle(isolate, "Dart_FunctionReturnType", return_type);
  }
}


DART_EXPORT Dart_Handle Dart_FunctionParameterCounts(
    Dart_Handle function,
    int64_t* fixed_param_count,
    int64_t* opt_param_count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (fixed_param_count == NULL) {
    RETURN_NULL_ERROR(fixed_param_count);
  }
  if (opt_param_count == NULL) {
    RETURN_NULL_ERROR(opt_param_count);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }

  // We hide implicit parameters, such as a method's receiver. This is
  // consistent with Invoke or New, which don't expect their callers to
  // provide them in the argument lists they are handed.
  *fixed_param_count = func.num_fixed_parameters() -
                       func.NumImplicitParameters();
  // TODO(regis): Separately report named and positional optional param counts.
  *opt_param_count = func.NumOptionalParameters();

  ASSERT(*fixed_param_count >= 0);
  ASSERT(*opt_param_count >= 0);

  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_FunctionParameterType(Dart_Handle function,
                                                   int parameter_index) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }

  const intptr_t num_implicit_params = func.NumImplicitParameters();
  const intptr_t num_params = func.NumParameters() - num_implicit_params;
  if (parameter_index < 0 || parameter_index >= num_params) {
    return Api::NewError(
        "%s: argument 'parameter_index' out of range. "
        "Expected 0..%"Pd" but saw %d.",
        CURRENT_FUNC, num_params, parameter_index);
  }
  const AbstractType& param_type =
      AbstractType::Handle(isolate, func.ParameterTypeAt(
          num_implicit_params + parameter_index));
  return TypeToHandle(isolate, "Dart_FunctionParameterType", param_type);
}


DART_EXPORT Dart_Handle Dart_GetVariableNames(Dart_Handle target) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  Field& field = Field::Handle(isolate);
  String& name = String::Handle(isolate);

  if (obj.IsType() || obj.IsClass()) {
    // For backwards compatibility we allow class objects to be passed in
    // for now. This needs to be removed once all code that uses class
    // objects to invoke Dart_Invoke is removed.
    const Class& cls = (obj.IsType()) ?
        Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
    const Error& error = Error::Handle(isolate, cls.EnsureIsFinalized(isolate));
    if (!error.IsNull()) {
      return Api::NewHandle(isolate, error.raw());
    }
    const Array& field_array = Array::Handle(cls.fields());

    // Some special types like 'dynamic' have a null fields list.
    //
    // TODO(turnidge): Fix 'dynamic' so that it does not have a null
    // fields list.  This will have to wait until the empty array is
    // allocated in the vm isolate.
    if (!field_array.IsNull()) {
      for (intptr_t i = 0; i < field_array.Length(); ++i) {
        field ^= field_array.At(i);
        name = field.UserVisibleName();
        names.Add(name);
      }
    }
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    DictionaryIterator it(lib);
    Object& obj = Object::Handle(isolate);
    while (it.HasNext()) {
      obj = it.GetNext();
      if (obj.IsField()) {
        field ^= obj.raw();
        name = field.UserVisibleName();
        names.Add(name);
      }
    }
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be a class or library.",
        CURRENT_FUNC);
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
}


DART_EXPORT Dart_Handle Dart_LookupVariable(Dart_Handle target,
                                            Dart_Handle variable_name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }
  const String& var_name = Api::UnwrapStringHandle(isolate, variable_name);
  if (var_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable_name, String);
  }
  if (obj.IsType() || obj.IsClass()) {
    // For backwards compatibility we allow class objects to be passed in
    // for now. This needs to be removed once all code that uses class
    // objects to invoke Dart_Invoke is removed.
    const Class& cls = (obj.IsType()) ?
        Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
    return Api::NewHandle(isolate, cls.LookupField(var_name));
  }
  if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    return Api::NewHandle(isolate, lib.LookupFieldAllowPrivate(var_name));
  }
  return Api::NewError(
      "%s expects argument 'target' to be a class or library.",
      CURRENT_FUNC);
}


DART_EXPORT Dart_Handle Dart_VariableName(Dart_Handle variable) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }
  return Api::NewHandle(isolate, var.UserVisibleName());
}


DART_EXPORT Dart_Handle Dart_VariableIsStatic(Dart_Handle variable,
                                              bool* is_static) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_static == NULL) {
    RETURN_NULL_ERROR(is_static);
  }
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }
  *is_static = var.is_static();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_VariableIsFinal(Dart_Handle variable,
                                             bool* is_final) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_final == NULL) {
    RETURN_NULL_ERROR(is_final);
  }
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }
  *is_final = var.is_final();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_VariableType(Dart_Handle variable) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }

  const AbstractType& type = AbstractType::Handle(isolate, var.type());
  return TypeToHandle(isolate, "Dart_VariableType", type);
}


DART_EXPORT Dart_Handle Dart_GetTypeVariableNames(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  const intptr_t num_type_params = cls.NumTypeParameters();
  const TypeArguments& type_params =
      TypeArguments::Handle(cls.type_parameters());

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  TypeParameter& type_param = TypeParameter::Handle(isolate);
  String& name = String::Handle(isolate);
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    name = type_param.name();
    names.Add(name);
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
}


DART_EXPORT Dart_Handle Dart_LookupTypeVariable(
    Dart_Handle object,
    Dart_Handle type_variable_name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (!obj.IsType() && !obj.IsClass()) {
    RETURN_TYPE_ERROR(isolate, object, Class/Type);
  }
  const Class& cls = (obj.IsType()) ?
      Class::Handle(Type::Cast(obj).type_class()) : Class::Cast(obj);
  const String& var_name = Api::UnwrapStringHandle(isolate, type_variable_name);
  if (var_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, type_variable_name, String);
  }

  const intptr_t num_type_params = cls.NumTypeParameters();
  const TypeArguments& type_params =
      TypeArguments::Handle(cls.type_parameters());

  TypeParameter& type_param = TypeParameter::Handle(isolate);
  String& name = String::Handle(isolate);
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    name = type_param.name();
    if (name.Equals(var_name)) {
      return Api::NewHandle(isolate, type_param.raw());
    }
  }
  const String& cls_name = String::Handle(cls.UserVisibleName());
  return Api::NewError(
      "%s: Could not find type variable named '%s' for class %s.\n",
      CURRENT_FUNC, var_name.ToCString(), cls_name.ToCString());
}


DART_EXPORT Dart_Handle Dart_TypeVariableName(Dart_Handle type_variable) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const TypeParameter& type_var =
      Api::UnwrapTypeParameterHandle(isolate, type_variable);
  if (type_var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, type_variable, TypeParameter);
  }
  return Api::NewHandle(isolate, type_var.name());
}


DART_EXPORT Dart_Handle Dart_TypeVariableOwner(Dart_Handle type_variable) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const TypeParameter& type_var =
      Api::UnwrapTypeParameterHandle(isolate, type_variable);
  if (type_var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, type_variable, TypeParameter);
  }
  const Class& owner = Class::Handle(type_var.parameterized_class());
  ASSERT(!owner.IsNull() && owner.IsClass());
  return Api::NewHandle(isolate, owner.raw());
}


DART_EXPORT Dart_Handle Dart_TypeVariableUpperBound(Dart_Handle type_variable) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const TypeParameter& type_var =
      Api::UnwrapTypeParameterHandle(isolate, type_variable);
  if (type_var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, type_variable, TypeParameter);
  }
  const AbstractType& bound = AbstractType::Handle(type_var.bound());
  return TypeToHandle(isolate, "Dart_TypeVariableUpperBound", bound);
}


// --- Libraries Reflection ---

DART_EXPORT Dart_Handle Dart_LibraryName(Dart_Handle library) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  const String& name = String::Handle(isolate, lib.name());
  ASSERT(!name.IsNull());
  return Api::NewHandle(isolate, name.raw());
}


DART_EXPORT Dart_Handle Dart_LibraryGetClassNames(Dart_Handle library) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  ClassDictionaryIterator it(lib);
  Class& cls = Class::Handle();
  String& name = String::Handle();
  while (it.HasNext()) {
    cls = it.GetNextClass();
    if (cls.IsSignatureClass()) {
      if (!cls.IsCanonicalSignatureClass()) {
        // This is a typedef.  Add it to the list of class names.
        name = cls.UserVisibleName();
        names.Add(name);
      } else {
        // Skip canonical signature classes.  These are not named.
      }
    } else {
      name = cls.UserVisibleName();
      names.Add(name);
    }
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
}


// --- Closures Reflection ---

DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& closure_obj = Api::UnwrapInstanceHandle(isolate, closure);
  if (closure_obj.IsNull() || !closure_obj.IsClosure()) {
    RETURN_TYPE_ERROR(isolate, closure, Instance);
  }

  ASSERT(ClassFinalizer::AllClassesFinalized());

  RawFunction* rf = Closure::function(closure_obj);
  return Api::NewHandle(isolate, rf);
}


// --- Metadata Reflection ----

DART_EXPORT Dart_Handle Dart_GetMetadata(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  Class& cls = Class::Handle(isolate);
  if (obj.IsClass()) {
    cls ^= obj.raw();
  } else if (obj.IsFunction()) {
    cls = Function::Cast(obj).origin();
  } else if (obj.IsField()) {
    cls = Field::Cast(obj).origin();
  } else {
    return Api::NewHandle(isolate, Object::empty_array().raw());
  }
  const Library& lib = Library::Handle(cls.library());
  return Api::NewHandle(isolate, lib.GetMetadata(obj));
}

}  // namespace dart
