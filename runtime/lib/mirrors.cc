// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_debugger_api.h"
#include "include/dart_mirrors_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"  // TODO(11742): Remove with CreateMirrorRef.
#include "vm/bootstrap_natives.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/message.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/symbols.h"
#include "lib/invocation_mirror.h"

namespace dart {

static RawInstance* CreateMirror(const String& mirror_class_name,
                                 const Array& constructor_arguments) {
  const Library& mirrors_lib = Library::Handle(Library::MirrorsLibrary());
  const String& constructor_name = Symbols::Dot();

  const Object& result = Object::Handle(
      DartLibraryCalls::InstanceCreate(mirrors_lib,
                                       mirror_class_name,
                                       constructor_name,
                                       constructor_arguments));
  ASSERT(result.IsInstance());
  return Instance::Cast(result).raw();
}


inline Dart_Handle NewString(const char* str) {
  return Dart_NewStringFromCString(str);
}


DEFINE_NATIVE_ENTRY(Mirrors_isLocalPort, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, port, arguments->NativeArgAt(0));

  // Get the port id from the SendPort instance.
  const Object& id_obj = Object::Handle(DartLibraryCalls::PortGetId(port));
  if (id_obj.IsError()) {
    Exceptions::PropagateError(Error::Cast(id_obj));
    UNREACHABLE();
  }
  ASSERT(id_obj.IsSmi() || id_obj.IsMint());
  Integer& id = Integer::Handle();
  id ^= id_obj.raw();
  Dart_Port port_id = static_cast<Dart_Port>(id.AsInt64Value());
  return Bool::Get(PortMap::IsLocalPort(port_id));
}


// TODO(turnidge): Add Map support to the dart embedding api instead
// of implementing it here.
static Dart_Handle CoreLib() {
  Dart_Handle core_lib_name = NewString("dart:core");
  return Dart_LookupLibrary(core_lib_name);
}


static Dart_Handle MapNew() {
  // TODO(turnidge): Switch to an order-preserving map type.
  Dart_Handle type = Dart_GetType(CoreLib(), NewString("Map"), 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }
  return Dart_New(type, Dart_Null(), 0, NULL);
}


static Dart_Handle MapAdd(Dart_Handle map, Dart_Handle key, Dart_Handle value) {
  Dart_Handle args[] = { key, value };
  return Dart_Invoke(map, NewString("[]="), ARRAY_SIZE(args), args);
}


static Dart_Handle MirrorLib() {
  Dart_Handle mirror_lib_name = NewString("dart:mirrors");
  return Dart_LookupLibrary(mirror_lib_name);
}


static Dart_Handle IsMethodMirror(Dart_Handle object, bool* is_mirror) {
  Dart_Handle cls_name = NewString("MethodMirror");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }
  Dart_Handle result = Dart_ObjectIsType(object, type, is_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  return Dart_True();  // Indicates success.  Result is in is_mirror.
}

static Dart_Handle IsVariableMirror(Dart_Handle object, bool* is_mirror) {
  Dart_Handle cls_name = NewString("VariableMirror");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }
  Dart_Handle result = Dart_ObjectIsType(object, type, is_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  return Dart_True();  // Indicates success.  Result is in is_mirror.
}


// TODO(11742): Remove once there are no more users of the Dart_Handle-based
// VMReferences.
static Dart_Handle CreateMirrorReference(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& referent = Object::Handle(isolate, Api::UnwrapHandle(handle));
  const MirrorReference& reference =
       MirrorReference::Handle(MirrorReference::New(referent));
  return Api::NewHandle(isolate, reference.raw());
}


static Dart_Handle StringFromSymbol(Dart_Handle symbol) {
  Dart_Handle result = Dart_Invoke(MirrorLib(), NewString("_n"), 1, &symbol);
  return result;
}


static Dart_Handle UnwrapVMReference(Dart_Handle vm_ref) {
  // Retrieve the persistent handle from the VMReference
  intptr_t perm_handle_value = 0;
  Dart_Handle result =
      Dart_GetNativeInstanceField(vm_ref, 0, &perm_handle_value);
  if (Dart_IsError(result)) {
    return result;
  }
  Dart_PersistentHandle perm_handle =
      reinterpret_cast<Dart_PersistentHandle>(perm_handle_value);
  ASSERT(perm_handle != NULL);
  Dart_Handle handle = Dart_HandleFromPersistent(perm_handle);
  ASSERT(handle != NULL);
  ASSERT(!Dart_IsError(handle));
  return handle;
}

static Dart_Handle UnwrapMirror(Dart_Handle mirror);

static Dart_Handle UnwrapObjectMirror(Dart_Handle mirror) {
  Dart_Handle field_name = NewString("_reference");
  Dart_Handle vm_ref = Dart_GetField(mirror, field_name);
  if (Dart_IsError(vm_ref)) {
    return vm_ref;
  }
  return UnwrapVMReference(vm_ref);
}


static Dart_Handle UnwrapMethodMirror(Dart_Handle methodMirror) {
  Dart_Handle namefield_name = NewString("simpleName");
  Dart_Handle name_ref = Dart_GetField(methodMirror, namefield_name);
  if (Dart_IsError(name_ref)) {
    return name_ref;
  }
  Dart_Handle ownerfield_name = NewString("_owner");
  Dart_Handle owner_mirror = Dart_GetField(methodMirror, ownerfield_name);
  if (Dart_IsError(owner_mirror)) {
    return owner_mirror;
  }
  Dart_Handle owner = UnwrapMirror(owner_mirror);
  if (Dart_IsError(owner)) {
    return owner;
  }
  Dart_Handle func = Dart_LookupFunction(owner, StringFromSymbol(name_ref));
  if (Dart_IsError(func)) {
    return func;
  }
  ASSERT(!Dart_IsNull(func));
  return func;
}

static Dart_Handle UnwrapVariableMirror(Dart_Handle variableMirror) {
  Dart_Handle namefield_name = NewString("simpleName");
  Dart_Handle name_ref = Dart_GetField(variableMirror, namefield_name);
  if (Dart_IsError(name_ref)) {
    return name_ref;
  }
  Dart_Handle ownerfield_name = NewString("_owner");
  Dart_Handle owner_mirror = Dart_GetField(variableMirror, ownerfield_name);
  ASSERT(!Dart_IsNull(owner_mirror));
  if (Dart_IsError(owner_mirror)) {
    return owner_mirror;
  }
  Dart_Handle owner = UnwrapMirror(owner_mirror);
  if (Dart_IsError(owner)) {
    return owner;
  }
  Dart_Handle variable =
  Dart_LookupVariable(owner, StringFromSymbol(name_ref));
  if (Dart_IsError(variable)) {
    return variable;
  }
  ASSERT(!Dart_IsNull(variable));
  return variable;
}

static Dart_Handle UnwrapMirror(Dart_Handle mirror) {
  // Caveat Emptor:
  // only works for ObjectMirrors, VariableMirrors and MethodMirrors
  // and their subtypes
  bool is_method_mirror = false;
  Dart_Handle result = IsMethodMirror(mirror, &is_method_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  if (is_method_mirror) {
    return UnwrapMethodMirror(mirror);
  }
  bool is_variable_mirror = false;
  result = IsVariableMirror(mirror, &is_variable_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  if (is_variable_mirror) {
    return UnwrapVariableMirror(mirror);
  }
  return UnwrapObjectMirror(mirror);
  // will return nonsense if mirror is not an ObjectMirror
}


static Dart_Handle CreateLazyMirror(Dart_Handle target);


static RawInstance* CreateParameterMirrorList(const Function& func) {
  HANDLESCOPE(Isolate::Current());
  const intptr_t param_cnt = func.num_fixed_parameters() -
                             func.NumImplicitParameters() +
                             func.NumOptionalParameters();
  const Array& results = Array::Handle(Array::New(param_cnt));
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(func)));
  Smi& pos = Smi::Handle();
  Instance& param = Instance::Handle();
  for (intptr_t i = 0; i < param_cnt; i++) {
    pos ^= Smi::New(i);
    args.SetAt(1, pos);
    args.SetAt(2, (i >= func.num_fixed_parameters()) ?
        Bool::True() : Bool::False());
    param ^= CreateMirror(Symbols::_LocalParameterMirrorImpl(), args);
    results.SetAt(i, param);
  }
  results.MakeImmutable();
  return results.raw();
}


static Dart_Handle CreateParameterMirrorListUsingApi(Dart_Handle func) {
  ASSERT(Dart_IsFunction(func));
  Isolate* isolate = Isolate::Current();
  return Api::NewHandle(
      isolate, CreateParameterMirrorList(Api::UnwrapFunctionHandle(
          isolate, func)));
}


static Dart_Handle CreateLazyMirror(Dart_Handle target) {
  if (Dart_IsNull(target) || Dart_IsError(target)) {
    return target;
  }

  if (Dart_IsLibrary(target)) {
    Dart_Handle cls_name = NewString("_LazyLibraryMirror");
    Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
    Dart_Handle args[] = { Dart_LibraryUrl(target) };
    return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  }

  if (Dart_IsClass(target)) {
    if (Dart_ClassIsFunctionType(target)) {
      Dart_Handle cls_name = NewString("_LazyFunctionTypeMirror");
      Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);

      Dart_Handle sig = Dart_ClassGetFunctionTypeSignature(target);
      Dart_Handle return_type = Dart_FunctionReturnType(sig);
      if (Dart_IsError(return_type)) {
        return return_type;
      }

      Dart_Handle args[] = {
        CreateLazyMirror(return_type),
        CreateParameterMirrorListUsingApi(sig),
      };
      return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
    } else {
      Dart_Handle cls_name = NewString("_LazyTypeMirror");
      Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
      Dart_Handle lib = Dart_ClassGetLibrary(target);
      Dart_Handle lib_url;
      if (Dart_IsNull(lib)) {
        lib_url = Dart_Null();
      } else {
        lib_url = Dart_LibraryUrl(lib);
      }
      Dart_Handle args[] = { lib_url, Dart_ClassName(target) };
      return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
    }
  }

  if (Dart_IsTypeVariable(target)) {
    Dart_Handle var_name = Dart_TypeVariableName(target);
    Dart_Handle owner = Dart_TypeVariableOwner(target);
    Dart_Handle owner_mirror = CreateLazyMirror(owner);

    Dart_Handle cls_name = NewString("_LazyTypeVariableMirror");
    Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);

    Dart_Handle args[] = { var_name, owner_mirror };
    return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  }

  UNREACHABLE();
  return Dart_Null();
}


static Dart_Handle CreateImplementsList(Dart_Handle intf) {
  intptr_t len = 0;
  Dart_Handle result = Dart_ClassGetInterfaceCount(intf, &len);
  if (Dart_IsError(result)) {
    return result;
  }

  Dart_Handle mirror_list = Dart_NewList(len);
  if (Dart_IsError(mirror_list)) {
    return mirror_list;
  }

  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle interface = Dart_ClassGetInterfaceAt(intf, i);
    if (Dart_IsError(interface)) {
      return interface;
    }
    Dart_Handle mirror = CreateLazyMirror(interface);
    if (Dart_IsError(mirror)) {
      return mirror;
    }
    Dart_Handle result = Dart_ListSetAt(mirror_list, i, mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return mirror_list;
}


static Dart_Handle CreateTypeVariableMirrorUsingApi(Dart_Handle type_var,
                                                    Dart_Handle type_var_name,
                                                    Dart_Handle owner_mirror) {
  ASSERT(Dart_IsTypeVariable(type_var));
  Dart_Handle cls_name = NewString("_LocalTypeVariableMirrorImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }

  Dart_Handle upper_bound = Dart_TypeVariableUpperBound(type_var);
  if (Dart_IsError(upper_bound)) {
    return upper_bound;
  }

  Dart_Handle args[] = {
    CreateMirrorReference(type_var),
    type_var_name,
    owner_mirror,
    CreateLazyMirror(upper_bound),
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static RawInstance* CreateTypeVariableMirror(const TypeParameter& param,
                                             const Instance& owner_mirror) {
  Instance& retvalue = Instance::Handle();
  Dart_EnterScope();
  Isolate* isolate = Isolate::Current();
  Dart_Handle param_handle = Api::NewHandle(isolate, param.raw());
  if (Dart_IsError(param_handle)) {
    Dart_PropagateError(param_handle);
  }
  Dart_Handle name_handle = Api::NewHandle(isolate, param.Name());
  if (Dart_IsError(name_handle)) {
    Dart_PropagateError(name_handle);
  }
  // Until we get rid of lazy mirrors, we must have owners.
  Dart_Handle owner_handle;
  if (owner_mirror.IsNull()) {
    owner_handle = Api::NewHandle(isolate, param.parameterized_class());
    if (Dart_IsError(owner_handle)) {
      Dart_PropagateError(owner_handle);
    }
    owner_handle = CreateLazyMirror(owner_handle);
    if (Dart_IsError(owner_handle)) {
      Dart_PropagateError(owner_handle);
    }
  } else {
    owner_handle = Api::NewHandle(isolate, owner_mirror.raw());
    if (Dart_IsError(owner_handle)) {
      Dart_PropagateError(owner_handle);
    }
  }
  // TODO(11742): At some point the handle calls will be replaced by inlined
  // functionality.
  Dart_Handle result =  CreateTypeVariableMirrorUsingApi(param_handle,
                                                         name_handle,
                                                         owner_handle);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  retvalue ^= Api::UnwrapHandle(result);
  Dart_ExitScope();
  return retvalue.raw();
}


static Dart_Handle CreateTypeVariableMap(Dart_Handle owner,
                                         Dart_Handle owner_mirror) {
  ASSERT(Dart_IsClass(owner));
  // TODO(turnidge): This should be an immutable map.
  Dart_Handle map = MapNew();
  if (Dart_IsError(map)) {
    return map;
  }

  Dart_Handle names = Dart_GetTypeVariableNames(owner);
  if (Dart_IsError(names)) {
    return names;
  }
  intptr_t len;
  Dart_Handle result = Dart_ListLength(names, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle type_var_name = Dart_ListGetAt(names, i);
    Dart_Handle type_var = Dart_LookupTypeVariable(owner, type_var_name);
    if (Dart_IsError(type_var)) {
      return type_var;
    }
    ASSERT(!Dart_IsNull(type_var));
    Dart_Handle type_var_mirror =
        CreateTypeVariableMirrorUsingApi(type_var, type_var_name, owner_mirror);
    if (Dart_IsError(type_var_mirror)) {
      return type_var_mirror;
    }
    result = MapAdd(map, type_var_name, type_var_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return map;
}


static Dart_Handle CreateTypedefMirror(Dart_Handle cls,
                                       Dart_Handle cls_name,
                                       Dart_Handle owner_mirror) {
  Dart_Handle mirror_cls_name = NewString("_LocalTypedefMirrorImpl");
  Dart_Handle mirror_type = Dart_GetType(MirrorLib(), mirror_cls_name, 0, NULL);
  if (Dart_IsError(mirror_type)) {
    return mirror_type;
  }

  Dart_Handle referent = Dart_ClassGetTypedefReferent(cls);
  if (Dart_IsError(referent)) {
    return referent;
  }

  Dart_Handle args[] = {
    CreateMirrorReference(cls),
    cls_name,
    owner_mirror,
    CreateLazyMirror(referent),
  };
  Dart_Handle mirror =
      Dart_New(mirror_type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateMemberMap(Dart_Handle owner, Dart_Handle owner_mirror);
static Dart_Handle CreateConstructorMap(Dart_Handle owner,
                                        Dart_Handle owner_mirror);

static Dart_Handle CreateClassMirrorUsingApi(Dart_Handle intf,
                                             Dart_Handle intf_name,
                                             Dart_Handle lib_mirror) {
  ASSERT(Dart_IsClass(intf));
  if (Dart_ClassIsTypedef(intf)) {
    // This class is actually a typedef.  Represent it specially in
    // reflection.
    return CreateTypedefMirror(intf, intf_name, lib_mirror);
  }

  Dart_Handle cls_name = NewString("_LocalClassMirrorImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }

  // TODO(turnidge): Why am I getting Null when I expect Object?
  // TODO(gbracha): this is probably the root of bug 7868
  Dart_Handle super_class = Dart_GetSuperclass(intf);
  if (Dart_IsNull(super_class)) {
    super_class = Dart_GetClass(CoreLib(), NewString("Object"));
  }
  // TODO(turnidge): Simplify code, now that default classes have been removed.
  Dart_Handle default_class = Dart_Null();

  Dart_Handle intf_mirror = CreateLazyMirror(intf);
  if (Dart_IsError(intf_mirror)) {
    return intf_mirror;
  }
  Dart_Handle constructor_map = CreateConstructorMap(intf, intf_mirror);
  if (Dart_IsError(constructor_map)) {
    return constructor_map;
  }
  Dart_Handle type_var_map = CreateTypeVariableMap(intf, intf_mirror);
  if (Dart_IsError(type_var_map)) {
    return type_var_map;
  }

  Dart_Handle args[] = {
    CreateMirrorReference(intf),
    Dart_Null(),  // "name"
    Dart_NewBoolean(Dart_IsClass(intf)),
    lib_mirror,
    CreateLazyMirror(super_class),
    CreateImplementsList(intf),
    CreateLazyMirror(default_class),
    constructor_map,
    type_var_map,
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateMethodMirrorUsingApi(Dart_Handle func,
                                              Dart_Handle owner_mirror) {
  // TODO(11742): Unwrapping is needed until the whole method is converted.
  Isolate* isolate = Isolate::Current();
  const Function& func_obj = Api::UnwrapFunctionHandle(isolate, func);

  Dart_Handle mirror_cls_name = NewString("_LocalMethodMirrorImpl");
  Dart_Handle mirror_type = Dart_GetType(MirrorLib(), mirror_cls_name, 0, NULL);
  if (Dart_IsError(mirror_type)) {
    return mirror_type;
  }

  // TODO(turnidge): Implement constructor kinds (arguments 7 - 10).
  Dart_Handle args[] = {
    CreateMirrorReference(func),
    owner_mirror,
    CreateParameterMirrorListUsingApi(func),
    func_obj.is_static() ? Api::True() : Api::False(),
    func_obj.is_abstract() ? Api::True() : Api::False(),
    func_obj.IsGetterFunction() ? Api::True() : Api::False(),
    func_obj.IsSetterFunction() ? Api::True() : Api::False(),
    func_obj.IsConstructor() ? Api::True() : Api::False(),
    Api::False(),
    Api::False(),
    Api::False(),
    Api::False()
  };
  Dart_Handle mirror =
      Dart_New(mirror_type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}

static RawInstance* CreateVariableMirror(const Field& field,
                                         const Instance& owner_mirror) {
  const MirrorReference& field_ref =
      MirrorReference::Handle(MirrorReference::New(field));

  const String& name = String::Handle(field.UserVisibleName());

  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, field_ref);
  args.SetAt(1, name);
  args.SetAt(2, owner_mirror);
  args.SetAt(3, Instance::Handle());  // Null for type.
  args.SetAt(4, field.is_static() ? Bool::True() : Bool::False());
  args.SetAt(5, field.is_final()  ? Bool::True() : Bool::False());

  return CreateMirror(Symbols::_LocalVariableMirrorImpl(), args);
}


static Dart_Handle AddMemberClasses(Dart_Handle map,
                                    Dart_Handle owner,
                                    Dart_Handle owner_mirror) {
  ASSERT(Dart_IsLibrary(owner));
  Dart_Handle result;
  Dart_Handle names = Dart_LibraryGetClassNames(owner);
  if (Dart_IsError(names)) {
    return names;
  }
  intptr_t len;
  result = Dart_ListLength(names, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle intf_name = Dart_ListGetAt(names, i);
    Dart_Handle intf = Dart_GetClass(owner, intf_name);
    if (Dart_IsError(intf)) {
      return intf;
    }
    Dart_Handle intf_mirror =
        CreateClassMirrorUsingApi(intf, intf_name, owner_mirror);
    if (Dart_IsError(intf_mirror)) {
      return intf_mirror;
    }
    result = MapAdd(map, intf_name, intf_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return Dart_True();
}


static Dart_Handle AddMemberFunctions(Dart_Handle map,
                                      Dart_Handle owner,
                                      Dart_Handle owner_mirror) {
  Dart_Handle result;
  Dart_Handle names = Dart_GetFunctionNames(owner);
  if (Dart_IsError(names)) {
    return names;
  }
  intptr_t len;
  result = Dart_ListLength(names, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle func_name = Dart_ListGetAt(names, i);
    Dart_Handle func = Dart_LookupFunction(owner, func_name);
    if (Dart_IsError(func)) {
      return func;
    }
    ASSERT(!Dart_IsNull(func));

    bool is_constructor = false;
    result = Dart_FunctionIsConstructor(func, &is_constructor);
    if (Dart_IsError(result)) {
      return result;
    }
    if (is_constructor) {
      // Skip constructors.
      continue;
    }

    Dart_Handle func_mirror = CreateMethodMirrorUsingApi(func, owner_mirror);
    if (Dart_IsError(func_mirror)) {
      return func_mirror;
    }
    result = MapAdd(map, func_name, func_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return Dart_True();
}


static Dart_Handle AddConstructors(Dart_Handle map,
                                   Dart_Handle owner,
                                   Dart_Handle owner_mirror) {
  Dart_Handle result;
  Dart_Handle names = Dart_GetFunctionNames(owner);
  if (Dart_IsError(names)) {
    return names;
  }
  intptr_t len;
  result = Dart_ListLength(names, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle func_name = Dart_ListGetAt(names, i);
    Dart_Handle func = Dart_LookupFunction(owner, func_name);
    if (Dart_IsError(func)) {
      return func;
    }
    ASSERT(!Dart_IsNull(func));

    bool is_constructor = false;
    result = Dart_FunctionIsConstructor(func, &is_constructor);
    if (Dart_IsError(result)) {
      return result;
    }
    if (!is_constructor) {
      // Skip non-constructors.
      continue;
    }

    Dart_Handle func_mirror = CreateMethodMirrorUsingApi(func, owner_mirror);
    if (Dart_IsError(func_mirror)) {
      return func_mirror;
    }
    result = MapAdd(map, func_name, func_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return Dart_True();
}


static Dart_Handle AddMemberVariables(Dart_Handle map,
                                      Dart_Handle owner,
                                      Dart_Handle owner_mirror) {
  Isolate* isolate = Isolate::Current();
  Dart_Handle result;
  Dart_Handle names = Dart_GetVariableNames(owner);
  if (Dart_IsError(names)) {
    return names;
  }
  intptr_t len;
  result = Dart_ListLength(names, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle var_name = Dart_ListGetAt(names, i);
    Dart_Handle var = Dart_LookupVariable(owner, var_name);
    if (Dart_IsError(var)) {
      return var;
    }
    ASSERT(!Dart_IsNull(var));
    ASSERT(Dart_IsVariable(var));
    const Field& field = Api::UnwrapFieldHandle(isolate, var);
    const Instance& owner_mirror_inst =
      Api::UnwrapInstanceHandle(isolate, owner_mirror);
    const Instance& var_mirror_inst =
      Instance::Handle(CreateVariableMirror(field, owner_mirror_inst));
    Dart_Handle var_mirror = Api::NewHandle(isolate, var_mirror_inst.raw());

    result = MapAdd(map, var_name, var_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return Dart_True();
}


static Dart_Handle CreateMemberMap(Dart_Handle owner,
                                   Dart_Handle owner_mirror) {
  // TODO(turnidge): This should be an immutable map.
  if (Dart_IsError(owner_mirror)) {
    return owner_mirror;
  }
  Dart_Handle result;
  Dart_Handle map = MapNew();
  if (Dart_IsLibrary(owner)) {
    result = AddMemberClasses(map, owner, owner_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  result = AddMemberFunctions(map, owner, owner_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  result = AddMemberVariables(map, owner, owner_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  return map;
}


static Dart_Handle CreateConstructorMap(Dart_Handle owner,
                                        Dart_Handle owner_mirror) {
  // TODO(turnidge): This should be an immutable map.
  if (Dart_IsError(owner_mirror)) {
    return owner_mirror;
  }
  Dart_Handle result;
  Dart_Handle map = MapNew();
  result = AddConstructors(map, owner, owner_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  return map;
}


static Dart_Handle CreateLibraryMirrorUsingApi(Dart_Handle lib) {
  Dart_Handle cls_name = NewString("_LocalLibraryMirrorImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }
  Dart_Handle lazy_lib_mirror = CreateLazyMirror(lib);
  if (Dart_IsError(lazy_lib_mirror)) {
    return lazy_lib_mirror;
  }
  Dart_Handle member_map = CreateMemberMap(lib, lazy_lib_mirror);
  if (Dart_IsError(member_map)) {
    return member_map;
  }
  Dart_Handle args[] = {
    CreateMirrorReference(lib),
    Dart_LibraryName(lib),
    Dart_LibraryUrl(lib),
    member_map,
  };
  Dart_Handle lib_mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  if (Dart_IsError(lib_mirror)) {
    return lib_mirror;
  }

  return lib_mirror;
}


static Dart_Handle CreateLibrariesMap() {
  // TODO(turnidge): This should be an immutable map.
  Dart_Handle map = MapNew();

  Dart_Handle lib_ids = Dart_GetLibraryIds();
  if (Dart_IsError(lib_ids)) {
    return lib_ids;
  }
  intptr_t len;
  Dart_Handle result = Dart_ListLength(lib_ids, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle lib_id = Dart_ListGetAt(lib_ids, i);
    int64_t id64;
    Dart_IntegerToInt64(lib_id, &id64);
    Dart_Handle lib_url = Dart_GetLibraryURL(id64);
    if (Dart_IsError(lib_url)) {
      return lib_url;
    }
    Dart_Handle lib = Dart_LookupLibrary(lib_url);
    if (Dart_IsError(lib)) {
      return lib;
    }
    Dart_Handle lib_mirror = CreateLibraryMirrorUsingApi(lib);
    if (Dart_IsError(lib_mirror)) {
      return lib_mirror;
    }
    result = MapAdd(map, lib_url, lib_mirror);
  }
  return map;
}


static Dart_Handle CreateIsolateMirror() {
  Dart_Handle cls_name = NewString("_LocalIsolateMirrorImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }
  Dart_Handle args[] = {
    Dart_DebugName(),
    CreateLazyMirror(Dart_RootLibrary()),
  };
  return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
}


static Dart_Handle CreateMirrorSystem() {
  Dart_Handle cls_name = NewString("_LocalMirrorSystemImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }

  Dart_Handle libraries = CreateLibrariesMap();
  if (Dart_IsError(libraries)) {
    return libraries;
  }

  Dart_Handle args[] = {
    libraries,
    CreateIsolateMirror(),
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  if (Dart_IsError(mirror)) {
    return mirror;
  }

  return mirror;
}


static Dart_Handle CreateNullMirror() {
  Dart_Handle cls_name = NewString("_LocalInstanceMirrorImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }

  // TODO(turnidge): This is wrong.  The Null class is distinct from object.
  Dart_Handle object_class = Dart_GetClass(CoreLib(), NewString("Object"));

  Dart_Handle args[] = {
    CreateLazyMirror(object_class),
    Dart_Null(),
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateInstanceMirror(Dart_Handle instance) {
  if (Dart_IsNull(instance)) {
    return CreateNullMirror();
  }
  ASSERT(Dart_IsInstance(instance));

  Dart_Handle instance_cls = Dart_InstanceGetClass(instance);
  if (Dart_IsError(instance_cls)) {
    return instance_cls;
  }

  if (Dart_IsClosure(instance)) {
    Dart_Handle cls_name = NewString("_LocalClosureMirrorImpl");
    Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
    if (Dart_IsError(type)) {
      return type;
    }
    // We set the function field of ClosureMirrors outside of the constructor
    // to break the mutual recursion.
    Dart_Handle func = Dart_ClosureFunction(instance);
    if (Dart_IsError(func)) {
      return func;
    }

    // TODO(turnidge): Why not use the real function name here?
    Dart_Handle func_owner = Dart_FunctionOwner(func);
    if (Dart_IsError(func_owner)) {
      return func_owner;
    }

    // TODO(turnidge): Pass the function owner here.  This will require
    // us to support functions in CreateLazyMirror.
    Dart_Handle func_mirror =
        CreateMethodMirrorUsingApi(func, Dart_Null());
    if (Dart_IsError(func_mirror)) {
      return func_mirror;
    }
    Dart_Handle args[] = {
      CreateLazyMirror(instance_cls),
      instance,
      func_mirror,
    };
    return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);

  } else {
    Dart_Handle cls_name = NewString("_LocalInstanceMirrorImpl");
    Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
    if (Dart_IsError(type)) {
      return type;
    }
    Dart_Handle args[] = {
      CreateLazyMirror(instance_cls),
      instance,
    };
    return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  }
}


static RawInstance* CreateClassMirror(const Class& cls,
                                      const Instance& owner_mirror) {
  Instance& retvalue = Instance::Handle();
  Dart_EnterScope();
  Isolate* isolate = Isolate::Current();
  Dart_Handle cls_handle = Api::NewHandle(isolate, cls.raw());
  if (Dart_IsError(cls_handle)) {
    Dart_PropagateError(cls_handle);
  }
  Dart_Handle name_handle = Api::NewHandle(isolate, cls.Name());
  if (Dart_IsError(name_handle)) {
    Dart_PropagateError(name_handle);
  }
  Dart_Handle lib_mirror = Api::NewHandle(isolate, owner_mirror.raw());
  // TODO(11742): At some point the handle calls will be replaced by inlined
  // functionality.
  Dart_Handle result =  CreateClassMirrorUsingApi(cls_handle,
                                                  name_handle,
                                                  lib_mirror);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  retvalue ^= Api::UnwrapHandle(result);
  Dart_ExitScope();
  return retvalue.raw();
}


static RawInstance* CreateLibraryMirror(const Library& lib) {
  Instance& retvalue = Instance::Handle();
  Dart_EnterScope();
  Isolate* isolate = Isolate::Current();
  Dart_Handle lib_handle = Api::NewHandle(isolate, lib.raw());
  // TODO(11742): At some point the handle calls will be replaced by inlined
  // functionality.
  Dart_Handle result = CreateLibraryMirrorUsingApi(lib_handle);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  retvalue ^= Api::UnwrapHandle(result);
  Dart_ExitScope();
  return retvalue.raw();
}


static RawInstance* CreateMethodMirror(const Function& func,
                                       const Instance& owner_mirror) {
  Instance& retvalue = Instance::Handle();
  Dart_EnterScope();
  Isolate* isolate = Isolate::Current();
  Dart_Handle func_handle = Api::NewHandle(isolate, func.raw());
  Dart_Handle owner_handle = Api::NewHandle(isolate, owner_mirror.raw());
  // TODO(11742): At some point the handle calls will be replaced by inlined
  // functionality.
  Dart_Handle result = CreateMethodMirrorUsingApi(func_handle, owner_handle);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  retvalue ^= Api::UnwrapHandle(result);
  Dart_ExitScope();
  return retvalue.raw();
}


static RawInstance* CreateTypeMirror(const AbstractType& type) {
  ASSERT(!type.IsMalformed());
  if (type.HasResolvedTypeClass()) {
    const Class& cls = Class::Handle(type.type_class());
    // Handle void and dynamic types.
    if (cls.IsVoidClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Void());
      // TODO(mlippautz): Create once in the VM isolate and retrieve from there.
      return CreateMirror(Symbols::_SpecialTypeMirrorImpl(), args);
    } else if (cls.IsDynamicClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Dynamic());
      // TODO(mlippautz): Create once in the VM isolate and retrieve from there.
      return CreateMirror(Symbols::_SpecialTypeMirrorImpl(), args);
    }
    return CreateClassMirror(cls, Object::null_instance());
  } else if (type.IsTypeParameter()) {
    return CreateTypeVariableMirror(TypeParameter::Cast(type),
                                    Object::null_instance());
  }
  UNREACHABLE();
  return Instance::null();
}


void NATIVE_ENTRY_FUNCTION(Mirrors_makeLocalMirrorSystem)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle mirrors = CreateMirrorSystem();
  if (Dart_IsError(mirrors)) {
    Dart_PropagateError(mirrors);
  }
  Dart_SetReturnValue(args, mirrors);
  Dart_ExitScope();
}


void NATIVE_ENTRY_FUNCTION(Mirrors_makeLocalInstanceMirror)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle reflectee = Dart_GetNativeArgument(args, 0);
  Dart_Handle mirror = CreateInstanceMirror(reflectee);
  if (Dart_IsError(mirror)) {
    Dart_PropagateError(mirror);
  }
  Dart_SetReturnValue(args, mirror);
  Dart_ExitScope();
}


void NATIVE_ENTRY_FUNCTION(Mirrors_makeLocalClassMirror)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Isolate* isolate = Isolate::Current();
  Dart_Handle key = Dart_GetNativeArgument(args, 0);
  if (Dart_IsError(key)) {
    Dart_PropagateError(key);
  }
  const Type& type = Api::UnwrapTypeHandle(isolate, key);
  const Class& cls = Class::Handle(type.type_class());
  Dart_Handle cls_handle = Api::NewHandle(isolate, cls.raw());
  if (Dart_IsError(cls_handle)) {
    Dart_PropagateError(cls_handle);
  }
  Dart_Handle name_handle = Api::NewHandle(isolate, cls.Name());
  if (Dart_IsError(name_handle)) {
    Dart_PropagateError(name_handle);
  }
  Dart_Handle lib_mirror = Dart_Null();
  Dart_Handle result = CreateClassMirrorUsingApi(cls_handle,
                                                 name_handle,
                                                 lib_mirror);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  Dart_SetReturnValue(args, result);
  Dart_ExitScope();
}


DEFINE_NATIVE_ENTRY(DeclarationMirror_metadata, 1) {
  const MirrorReference& decl_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(0));
  const Object& decl = Object::Handle(decl_ref.referent());

  Class& klass = Class::Handle();
  if (decl.IsClass()) {
    klass ^= decl.raw();
  } else if (decl.IsFunction()) {
    klass = Function::Cast(decl).origin();
  } else if (decl.IsField()) {
    klass = Field::Cast(decl).origin();
  } else {
    return Object::empty_array().raw();
  }

  const Library& library = Library::Handle(klass.library());
  return library.GetMetadata(decl);
}


void HandleMirrorsMessage(Isolate* isolate,
                          Dart_Port reply_port,
                          const Instance& message) {
  UNIMPLEMENTED();
}


// TODO(11742): This is transitional.
static RawInstance* Reflect(const Instance& reflectee) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Instance::RawCast(
      Api::UnwrapHandle(
          CreateInstanceMirror(
              Api::NewHandle(isolate, reflectee.raw()))));
}


static void ThrowMirroredUnhandledError(const Error& original_error) {
  const UnhandledException& unhandled_ex =
      UnhandledException::Cast(original_error);
  Instance& exc = Instance::Handle(unhandled_ex.exception());
  Instance& stack = Instance::Handle(unhandled_ex.stacktrace());

  Object& exc_string_or_error =
      Object::Handle(DartLibraryCalls::ToString(exc));
  String& exc_string = String::Handle();
  // Ignore any errors that might occur in toString.
  if (exc_string_or_error.IsString()) {
    exc_string ^= exc_string_or_error.raw();
  }

  Instance& mirror_on_exc = Instance::Handle(Reflect(exc));

  Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, mirror_on_exc);
  args.SetAt(1, exc_string);
  args.SetAt(2, stack);

  Exceptions::ThrowByType(Exceptions::kMirroredUncaughtExceptionError, args);
  UNREACHABLE();
}


static void ThrowMirroredCompilationError(const String& message) {
  Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);

  Exceptions::ThrowByType(Exceptions::kMirroredCompilationError, args);
  UNREACHABLE();
}


static void ThrowInvokeError(const Error& error) {
  if (error.IsUnhandledException()) {
    // An ordinary runtime error.
    ThrowMirroredUnhandledError(error);
  }
  if (error.IsLanguageError()) {
    // A compilation error that was delayed by lazy compilation.
    const LanguageError& compilation_error = LanguageError::Cast(error);
    String& message = String::Handle(compilation_error.message());
    ThrowMirroredCompilationError(message);
  }
  UNREACHABLE();
}


static bool FieldIsUninitialized(const Field& field) {
  ASSERT(!field.IsNull());

  // Return getter method for uninitialized fields, rather than the
  // field object, since the value in the field object will not be
  // initialized until the first time the getter is invoked.
  const Instance& value = Instance::Handle(field.value());
  ASSERT(value.raw() != Object::transition_sentinel().raw());
  return value.raw() == Object::sentinel().raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_name, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  return klass.Name();
}


DEFINE_NATIVE_ENTRY(ClassMirror_library, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  return CreateLibraryMirror(Library::Handle(klass.library()));
}


DEFINE_NATIVE_ENTRY(ClassMirror_members, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance,
                               owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());

  const Array& fields = Array::Handle(klass.fields());
  // Some special types like 'dynamic' have a null fields list, but they should
  // not wind up as the reflectees of ClassMirrors.
  ASSERT(!fields.IsNull());
  const intptr_t num_fields = fields.Length();

  const Array& functions = Array::Handle(klass.functions());
  // Some special types like 'dynamic' have a null functions list, but they
  // should not wind up as the reflectees of ClassMirrors.
  ASSERT(!functions.IsNull());
  const intptr_t num_functions = functions.Length();

  Instance& member_mirror = Instance::Handle();
  const GrowableObjectArray& member_mirrors = GrowableObjectArray::Handle(
      GrowableObjectArray::New(num_fields + num_functions));

  Field& field = Field::Handle();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= fields.At(i);
    member_mirror = CreateVariableMirror(field, owner_mirror);
    member_mirrors.Add(member_mirror);
  }

  Function& func = Function::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.kind() == RawFunction::kRegularFunction ||
        func.kind() == RawFunction::kGetterFunction ||
        func.kind() == RawFunction::kSetterFunction) {
      member_mirror = CreateMethodMirror(func, owner_mirror);
      member_mirrors.Add(member_mirror);
    }
  }

  return member_mirrors.raw();
}


// Invoke the function, or noSuchMethod if it is null. Propagate any unhandled
// exceptions. Wrap and propagate any compilation errors.
static RawObject* ReflectivelyInvokeDynamicFunction(const Instance& receiver,
                                                    const Function& function,
                                                    const String& target_name,
                                                    const Array& arguments) {
  // Note "arguments" is already the internal arguments with the receiver as
  // the first element.
  Object& result = Object::Handle();
  if (function.IsNull()) {
    const Array& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
    result = DartEntry::InvokeNoSuchMethod(receiver,
                                           target_name,
                                           arguments,
                                           arguments_descriptor);
  } else {
    result = DartEntry::InvokeFunction(function, arguments);
  }

  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.raw();
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, function_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(3));

  intptr_t number_of_arguments = positional_args.Length();

  const Array& args =
      Array::Handle(Array::New(number_of_arguments + 1));  // Plus receiver.
  Object& arg = Object::Handle();
  args.SetAt(0, reflectee);
  for (int i = 0; i < number_of_arguments; i++) {
    arg = positional_args.At(i);
    args.SetAt(i + 1, arg);  // Plus receiver.
  }

  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(args.Length())));
  // TODO(11771): This won't find private members.
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(reflectee,
                               function_name,
                               args_desc));

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           function,
                                           function_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));

  // Every instance field has a getter Function.  Try to find the
  // getter in any superclass and use that function to access the
  // field.
  // NB: We do not use Resolver::ResolveDynamic because we want to find private
  // members.
  Class& klass = Class::Handle(reflectee.clazz());
  String& internal_getter_name = String::Handle(Field::GetterName(getter_name));
  Function& getter = Function::Handle();
  while (!klass.IsNull()) {
    getter = klass.LookupDynamicFunctionAllowPrivate(internal_getter_name);
    if (!getter.IsNull()) {
      break;
    }
    klass = klass.SuperClass();
  }

  const int kNumArgs = 1;
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, reflectee);

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           getter,
                                           internal_getter_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  String& internal_setter_name =
      String::Handle(Field::SetterName(setter_name));
  Function& setter = Function::Handle();

  Class& klass = Class::Handle(reflectee.clazz());
  Field& field = Field::Handle();

  while (!klass.IsNull()) {
    field = klass.LookupInstanceField(setter_name);
    if (!field.IsNull() && field.is_final()) {
      const String& message = String::Handle(
          String::NewFormatted("%s: cannot set final field '%s'.",
                               "InstanceMirror_invokeSetter",
                               setter_name.ToCString()));
      ThrowMirroredCompilationError(message);
      UNREACHABLE();
    }
    setter = klass.LookupDynamicFunctionAllowPrivate(internal_setter_name);
    if (!setter.IsNull()) {
      break;
    }
    klass = klass.SuperClass();
  }

  // Invoke the setter and return the result.
  const int kNumArgs = 2;
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, reflectee);
  args.SetAt(1, value);

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           setter,
                                           internal_setter_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(ClosureMirror_apply, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  ASSERT(!closure.IsNull() && closure.IsCallable(NULL, NULL));

  const Array& positional_args =
      Array::CheckedHandle(arguments->NativeArgAt(1));
  intptr_t number_of_arguments = positional_args.Length();

  // Set up arguments to include the closure as the first argument.
  const Array& args = Array::Handle(Array::New(number_of_arguments + 1));
  Object& obj = Object::Handle();
  args.SetAt(0, closure);
  for (int i = 0; i < number_of_arguments; i++) {
    obj = positional_args.At(i);
    args.SetAt(i + 1, obj);
  }

  obj = DartEntry::InvokeClosure(args);
  if (obj.IsError()) {
    ThrowInvokeError(Error::Cast(obj));
    UNREACHABLE();
  }
  return obj.raw();
}


static void ThrowNoSuchMethod(const Instance& receiver,
                              const String& function_name,
                              const Function& function,
                              const InvocationMirror::Call call,
                              const InvocationMirror::Type type) {
  const Smi& invocation_type = Smi::Handle(Smi::New(
      InvocationMirror::EncodeType(call, type)));

  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, receiver);
  args.SetAt(1, function_name);
  args.SetAt(2, invocation_type);
  if (!function.IsNull()) {
    const int total_num_parameters = function.NumParameters();
    const Array& array = Array::Handle(Array::New(total_num_parameters));
    String& param_name = String::Handle();
    for (int i = 0; i < total_num_parameters; i++) {
      param_name = function.ParameterNameAt(i);
      array.SetAt(i, param_name);
    }
    args.SetAt(5, array);
  }

  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, args);
  UNREACHABLE();
}


static void ThrowNoSuchMethod(const Class& klass,
                              const String& function_name,
                              const Function& function,
                              const InvocationMirror::Call call,
                              const InvocationMirror::Type type) {
  AbstractTypeArguments& type_arguments = AbstractTypeArguments::Handle();
  Type& pre_type = Type::Handle(
      Type::New(klass, type_arguments, Scanner::kDummyTokenIndex));
  pre_type.SetIsFinalized();
  AbstractType& runtime_type = AbstractType::Handle(pre_type.Canonicalize());

  ThrowNoSuchMethod(runtime_type,
                    function_name,
                    function,
                    call,
                    type);
  UNREACHABLE();
}


static void ThrowNoSuchMethod(const Library& library,
                              const String& function_name,
                              const Function& function,
                              const InvocationMirror::Call call,
                              const InvocationMirror::Type type) {
  ThrowNoSuchMethod(Instance::null_instance(),
                    function_name,
                    function,
                    call,
                    type);
  UNREACHABLE();
}


DEFINE_NATIVE_ENTRY(ClassMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, function_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(3));

  intptr_t number_of_arguments = positional_args.Length();

  const Function& function = Function::Handle(
      klass.LookupStaticFunctionAllowPrivate(function_name));

  if (function.IsNull() ||
      !function.AreValidArgumentCounts(number_of_arguments,
                                       /* named_args */ 0,
                                       NULL)) {
    ThrowNoSuchMethod(klass,
                      function_name,
                      function,
                      InvocationMirror::kStatic,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  Object& result = Object::Handle(DartEntry::InvokeFunction(function,
                                                            positional_args));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));

  // Note static fields do not have implicit getters.
  const Field& field = Field::Handle(klass.LookupStaticField(getter_name));
  if (field.IsNull() || FieldIsUninitialized(field)) {
    const String& internal_getter_name = String::Handle(
        Field::GetterName(getter_name));
    const Function& getter = Function::Handle(
        klass.LookupStaticFunctionAllowPrivate(internal_getter_name));

    if (getter.IsNull()) {
      ThrowNoSuchMethod(klass,
                        getter_name,
                        getter,
                        InvocationMirror::kStatic,
                        InvocationMirror::kGetter);
      UNREACHABLE();
    }

    // Invoke the getter and return the result.
    Object& result = Object::Handle(
        DartEntry::InvokeFunction(getter, Object::empty_array()));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }
  return field.value();
}


DEFINE_NATIVE_ENTRY(ClassMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  // Check for real fields and user-defined setters.
  const Field& field = Field::Handle(klass.LookupStaticField(setter_name));
  if (field.IsNull()) {
    const String& internal_setter_name = String::Handle(
      Field::SetterName(setter_name));
    const Function& setter = Function::Handle(
      klass.LookupStaticFunctionAllowPrivate(internal_setter_name));

    if (setter.IsNull()) {
      ThrowNoSuchMethod(klass,
                        setter_name,
                        setter,
                        InvocationMirror::kStatic,
                        InvocationMirror::kSetter);
      UNREACHABLE();
    }

    // Invoke the setter and return the result.
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);

    Object& result = Object::Handle(
        DartEntry::InvokeFunction(setter, args));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }

  if (field.is_final()) {
    const String& message = String::Handle(
        String::NewFormatted("%s: cannot set final field '%s'.",
                             "ClassMirror_invokeSetter",
                             setter_name.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }

  field.set_value(value);
  return value.raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_invokeConstructor, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, constructor_name, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(2));

  intptr_t number_of_arguments = positional_args.Length();

  // By convention, the static function implementing a named constructor 'C'
  // for class 'A' is labeled 'A.C', and the static function implementing the
  // unnamed constructor for class 'A' is labeled 'A.'.
  // This convention prevents users from explicitly calling constructors.
  const String& klass_name = String::Handle(klass.Name());
  String& internal_constructor_name =
      String::Handle(String::Concat(klass_name, Symbols::Dot()));
  if (!constructor_name.IsNull()) {
    internal_constructor_name =
        String::Concat(internal_constructor_name, constructor_name);
  }

  Function& constructor = Function::Handle(
      klass.LookupFunctionAllowPrivate(internal_constructor_name));

  if (constructor.IsNull() ||
     (!constructor.IsConstructor() && !constructor.IsFactory()) ||
     !constructor.AreValidArgumentCounts(number_of_arguments +
                                         constructor.NumImplicitParameters(),
                                         /* named args */ 0,
                                         NULL)) {
    // Pretend we didn't find the constructor at all when the arity is wrong
    // so as to produce the same NoSuchMethodError as the non-reflective case.
    constructor = Function::null();
    ThrowNoSuchMethod(klass,
                      internal_constructor_name,
                      constructor,
                      InvocationMirror::kConstructor,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  const Object& result =
      Object::Handle(DartEntry::InvokeConstructor(klass,
                                                  constructor,
                                                  positional_args));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }
  // Factories may return null.
  ASSERT(result.IsInstance() || result.IsNull());
  return result.raw();
}


DEFINE_NATIVE_ENTRY(LibraryMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, function_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(3));

  intptr_t number_of_arguments = positional_args.Length();

  String& ambiguity_error_msg = String::Handle(isolate);
  const Function& function = Function::Handle(
      library.LookupFunctionAllowPrivate(function_name, &ambiguity_error_msg));

  if (function.IsNull() && !ambiguity_error_msg.IsNull()) {
    ThrowMirroredCompilationError(ambiguity_error_msg);
    UNREACHABLE();
  }

  if (function.IsNull() ||
     !function.AreValidArgumentCounts(number_of_arguments,
                                      0,
                                      NULL) ) {
    ThrowNoSuchMethod(library,
                      function_name,
                      function,
                      InvocationMirror::kTopLevel,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function, positional_args));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.raw();
}


DEFINE_NATIVE_ENTRY(LibraryMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));

  // To access a top-level we may need to use the Field or the
  // getter Function.  The getter function may either be in the
  // library or in the field's owner class, depending.
  String& ambiguity_error_msg = String::Handle(isolate);
  const Field& field = Field::Handle(
      library.LookupFieldAllowPrivate(getter_name, &ambiguity_error_msg));
  Function& getter = Function::Handle();
  if (field.IsNull() && ambiguity_error_msg.IsNull()) {
    // No field found and no ambiguity error.  Check for a getter in the lib.
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = library.LookupFunctionAllowPrivate(internal_getter_name,
                                                &ambiguity_error_msg);
  } else if (!field.IsNull() && FieldIsUninitialized(field)) {
    // A field was found.  Check for a getter in the field's owner classs.
    const Class& klass = Class::Handle(field.owner());
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = klass.LookupStaticFunctionAllowPrivate(internal_getter_name);
  }

  if (!getter.IsNull()) {
    // Invoke the getter and return the result.
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(getter, Object::empty_array()));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }
  if (!field.IsNull()) {
    return field.value();
  }
  if (ambiguity_error_msg.IsNull()) {
    ThrowNoSuchMethod(library,
                      getter_name,
                      getter,
                      InvocationMirror::kTopLevel,
                      InvocationMirror::kGetter);
  } else {
    ThrowMirroredCompilationError(ambiguity_error_msg);
  }
  UNREACHABLE();
  return Instance::null();
}


DEFINE_NATIVE_ENTRY(LibraryMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  // To access a top-level we may need to use the Field or the
  // setter Function.  The setter function may either be in the
  // library or in the field's owner class, depending.
  String& ambiguity_error_msg = String::Handle(isolate);
  const Field& field = Field::Handle(
      library.LookupFieldAllowPrivate(setter_name, &ambiguity_error_msg));

  if (field.IsNull() && ambiguity_error_msg.IsNull()) {
    const String& internal_setter_name =
        String::Handle(Field::SetterName(setter_name));
    const Function& setter = Function::Handle(
        library.LookupFunctionAllowPrivate(internal_setter_name,
                                           &ambiguity_error_msg));
    if (setter.IsNull()) {
      if (ambiguity_error_msg.IsNull()) {
        ThrowNoSuchMethod(library,
                          setter_name,
                          setter,
                          InvocationMirror::kTopLevel,
                          InvocationMirror::kSetter);
      } else {
        ThrowMirroredCompilationError(ambiguity_error_msg);
      }
      UNREACHABLE();
    }

    // Invoke the setter and return the result.
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(setter, args));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }

  if (field.is_final()) {
    const String& message = String::Handle(
      String::NewFormatted("%s: cannot set final top-level variable '%s'.",
                           "LibraryMirror_invokeSetter",
                           setter_name.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }

  field.set_value(value);
  return value.raw();
}


DEFINE_NATIVE_ENTRY(MethodMirror_name, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return func.UserVisibleName();
}


DEFINE_NATIVE_ENTRY(MethodMirror_owner, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  if (func.IsNonImplicitClosureFunction()) {
    return CreateMethodMirror(Function::Handle(
        func.parent_function()), Object::null_instance());
  }
  const Class& owner = Class::Handle(func.Owner());
  if (owner.IsTopLevel()) {
    return CreateLibraryMirror(Library::Handle(owner.library()));
  }
  return CreateClassMirror(owner, Object::null_instance());
}


DEFINE_NATIVE_ENTRY(MethodMirror_return_type, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  // We handle constructors in Dart code.
  ASSERT(!func.IsConstructor());
  const AbstractType& return_type = AbstractType::Handle(func.result_type());
  return CreateTypeMirror(return_type);
}


DEFINE_NATIVE_ENTRY(ParameterMirror_type, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, pos, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  const AbstractType& param_type = AbstractType::Handle(func.ParameterTypeAt(
      func.NumImplicitParameters() + pos.Value()));
  return CreateTypeMirror(param_type);
}


DEFINE_NATIVE_ENTRY(VariableMirror_type, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Field& field = Field::Handle(ref.GetFieldReferent());

  const AbstractType& type = AbstractType::Handle(field.type());
  return CreateTypeMirror(type);
}

}  // namespace dart
