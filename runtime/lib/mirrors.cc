// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_debugger_api.h"
#include "platform/json.h"
#include "vm/bootstrap_natives.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/message.h"
#include "vm/port.h"
#include "vm/resolver.h"

namespace dart {

inline Dart_Handle NewString(const char* str) {
  return Dart_NewStringFromCString(str);
}


DEFINE_NATIVE_ENTRY(Mirrors_isLocalPort, 1) {
  GET_NATIVE_ARGUMENT(Instance, port, arguments->NativeArgAt(0));

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
  Dart_Handle cls = Dart_GetClass(CoreLib(), NewString("Map"));
  if (Dart_IsError(cls)) {
    return cls;
  }
  return Dart_New(cls, Dart_Null(), 0, NULL);
}


static Dart_Handle MapAdd(Dart_Handle map, Dart_Handle key, Dart_Handle value) {
  Dart_Handle args[] = { key, value };
  return Dart_Invoke(map, NewString("[]="), ARRAY_SIZE(args), args);
}


static Dart_Handle MirrorLib() {
  Dart_Handle mirror_lib_name = NewString("dart:mirrors");
  return Dart_LookupLibrary(mirror_lib_name);
}


static Dart_Handle IsMirror(Dart_Handle object, bool* is_mirror) {
  Dart_Handle cls_name = NewString("Mirror");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  Dart_Handle result = Dart_ObjectIsType(object, cls, is_mirror);
  if (Dart_IsError(result)) {
    return result;
  }
  return Dart_True();  // Indicates success.  Result is in is_mirror.
}


static bool IsSimpleValue(Dart_Handle object) {
  return (Dart_IsNull(object) ||
          Dart_IsNumber(object) ||
          Dart_IsString(object) ||
          Dart_IsBoolean(object));
}


static void FreeVMReference(Dart_Handle weak_ref, void* data) {
  Dart_Handle perm_handle = reinterpret_cast<Dart_Handle>(data);
  Dart_DeletePersistentHandle(perm_handle);
  Dart_DeletePersistentHandle(weak_ref);
}


static Dart_Handle CreateVMReference(Dart_Handle handle) {
  // Create the VMReference object.
  Dart_Handle cls_name = NewString("VMReference");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  Dart_Handle vm_ref =  Dart_New(cls, Dart_Null(), 0, NULL);
  if (Dart_IsError(vm_ref)) {
    return vm_ref;
  }

  // Allocate a persistent handle.
  Dart_Handle perm_handle = Dart_NewPersistentHandle(handle);
  if (Dart_IsError(perm_handle)) {
    return perm_handle;
  }

  // Store the persistent handle in the VMReference.
  intptr_t perm_handle_value = reinterpret_cast<intptr_t>(perm_handle);
  Dart_Handle result =
      Dart_SetNativeInstanceField(vm_ref, 0, perm_handle_value);
  if (Dart_IsError(result)) {
    Dart_DeletePersistentHandle(perm_handle);
    return result;
  }

  // Create a weak reference.  We use the callback to be informed when
  // the VMReference is collected, so we can release the persistent
  // handle.
  void* perm_handle_data = reinterpret_cast<void*>(perm_handle);
  Dart_Handle weak_ref =
      Dart_NewWeakPersistentHandle(vm_ref, perm_handle_data, FreeVMReference);
  if (Dart_IsError(weak_ref)) {
    Dart_DeletePersistentHandle(perm_handle);
    return weak_ref;
  }

  // Success.
  return vm_ref;
}


static Dart_Handle UnwrapVMReference(Dart_Handle vm_ref) {
  // Retrieve the persistent handle from the VMReference
  intptr_t perm_handle_value = 0;
  Dart_Handle result =
      Dart_GetNativeInstanceField(vm_ref, 0, &perm_handle_value);
  if (Dart_IsError(result)) {
    return result;
  }
  Dart_Handle perm_handle = reinterpret_cast<Dart_Handle>(perm_handle_value);
  ASSERT(!Dart_IsError(perm_handle));
  return perm_handle;
}


static Dart_Handle UnwrapMirror(Dart_Handle mirror) {
  Dart_Handle field_name = NewString("_reference");
  Dart_Handle vm_ref = Dart_GetField(mirror, field_name);
  if (Dart_IsError(vm_ref)) {
    return vm_ref;
  }
  return UnwrapVMReference(vm_ref);
}


static Dart_Handle UnwrapArg(Dart_Handle arg) {
    if (Dart_IsError(arg)) {
      return arg;
    }
    bool is_mirror = false;
    Dart_Handle result = IsMirror(arg, &is_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
    if (is_mirror) {
      return UnwrapMirror(arg);
    } else {
      // Simple value.
      ASSERT(IsSimpleValue(arg));
      return arg;
    }
}

static Dart_Handle UnwrapArgList(Dart_Handle arg_list,
                                 GrowableArray<Dart_Handle>* arg_array) {
  intptr_t len = 0;
  Dart_Handle result = Dart_ListLength(arg_list, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle arg = Dart_ListGetAt(arg_list, i);
    Dart_Handle unwrapped_arg = UnwrapArg(arg);
    if (Dart_IsError(unwrapped_arg)) {
      return unwrapped_arg;
    }
    arg_array->Add(unwrapped_arg);
  }
  return Dart_True();
}


static Dart_Handle CreateLazyMirror(Dart_Handle target);


static Dart_Handle CreateParameterMirrorList(Dart_Handle func) {
  int64_t fixed_param_count;
  int64_t opt_param_count;
  Dart_Handle result = Dart_FunctionParameterCounts(func,
                                                    &fixed_param_count,
                                                    &opt_param_count);
  if (Dart_IsError(result)) {
    return result;
  }

  int64_t param_count = fixed_param_count + opt_param_count;
  Dart_Handle parameter_list = Dart_NewList(param_count);
  if (Dart_IsError(parameter_list)) {
    return result;
  }

  Dart_Handle param_cls_name = NewString("_LocalParameterMirrorImpl");
  Dart_Handle param_cls = Dart_GetClass(MirrorLib(), param_cls_name);
  if (Dart_IsError(param_cls)) {
    return param_cls;
  }

  for (int64_t i = 0; i < param_count; i++) {
    Dart_Handle param_type = Dart_FunctionParameterType(func, i);
    if (Dart_IsError(param_type)) {
      return param_type;
    }
    Dart_Handle args[] = {
      CreateLazyMirror(param_type),
      Dart_NewBoolean(i >= fixed_param_count),  // optional param?
    };
    Dart_Handle param =
        Dart_New(param_cls, Dart_Null(), ARRAY_SIZE(args), args);
    if (Dart_IsError(param)) {
      return param;
    }
    result = Dart_ListSetAt(parameter_list, i, param);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return parameter_list;
}


static Dart_Handle CreateLazyMirror(Dart_Handle target) {
  if (Dart_IsNull(target) || Dart_IsError(target)) {
    return target;
  }

  if (Dart_IsLibrary(target)) {
    Dart_Handle cls_name = NewString("_LazyLibraryMirror");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    Dart_Handle args[] = { Dart_LibraryName(target) };
    return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  }

  if (Dart_IsClass(target) || Dart_IsInterface(target)) {
    if (Dart_ClassIsFunctionType(target)) {
      Dart_Handle cls_name = NewString("_LazyFunctionTypeMirror");
      Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);

      Dart_Handle sig = Dart_ClassGetFunctionTypeSignature(target);
      Dart_Handle return_type = Dart_FunctionReturnType(sig);
      if (Dart_IsError(return_type)) {
        return return_type;
      }

      Dart_Handle args[] = {
        CreateLazyMirror(return_type),
        CreateParameterMirrorList(sig),
      };
      return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
    } else {
      Dart_Handle cls_name = NewString("_LazyTypeMirror");
      Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
      Dart_Handle lib = Dart_ClassGetLibrary(target);
      Dart_Handle lib_name;
      if (Dart_IsNull(lib)) {
        lib_name = Dart_Null();
      } else {
        lib_name = Dart_LibraryName(lib);
      }
      Dart_Handle args[] = { lib_name, Dart_ClassName(target) };
      return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
    }
  }

  if (Dart_IsTypeVariable(target)) {
    Dart_Handle var_name = Dart_TypeVariableName(target);
    Dart_Handle owner = Dart_TypeVariableOwner(target);
    Dart_Handle owner_mirror = CreateLazyMirror(owner);

    Dart_Handle cls_name = NewString("_LazyTypeVariableMirror");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);

    Dart_Handle args[] = { var_name, owner_mirror };
    return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
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


static Dart_Handle CreateTypeVariableMirror(Dart_Handle type_var,
                                            Dart_Handle type_var_name,
                                            Dart_Handle owner_mirror) {
  ASSERT(Dart_IsTypeVariable(type_var));
  Dart_Handle cls_name = NewString("_LocalTypeVariableMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  Dart_Handle upper_bound = Dart_TypeVariableUpperBound(type_var);
  if (Dart_IsError(upper_bound)) {
    return upper_bound;
  }

  Dart_Handle args[] = {
    type_var_name,
    owner_mirror,
    CreateLazyMirror(upper_bound),
  };
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateTypeVariableMap(Dart_Handle owner,
                                         Dart_Handle owner_mirror) {
  ASSERT(Dart_IsClass(owner) || Dart_IsInterface(owner));
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
        CreateTypeVariableMirror(type_var, type_var_name, owner_mirror);
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
                                       Dart_Handle owner,
                                       Dart_Handle owner_mirror) {
  Dart_Handle mirror_cls_name = NewString("_LocalTypedefMirrorImpl");
  Dart_Handle mirror_cls = Dart_GetClass(MirrorLib(), mirror_cls_name);
  if (Dart_IsError(mirror_cls)) {
    return mirror_cls;
  }

  Dart_Handle referent = Dart_ClassGetTypedefReferent(cls);
  if (Dart_IsError(referent)) {
    return referent;
  }

  Dart_Handle args[] = {
    cls_name,
    owner_mirror,
    CreateLazyMirror(referent),
  };
  Dart_Handle mirror =
      Dart_New(mirror_cls, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateMemberMap(Dart_Handle owner, Dart_Handle owner_mirror);
static Dart_Handle CreateConstructorMap(Dart_Handle owner,
                                        Dart_Handle owner_mirror);


static Dart_Handle CreateClassMirror(Dart_Handle intf,
                                     Dart_Handle intf_name,
                                     Dart_Handle lib,
                                     Dart_Handle lib_mirror) {
  ASSERT(Dart_IsClass(intf) || Dart_IsInterface(intf));
  if (Dart_ClassIsTypedef(intf)) {
    // This class is actually a typedef.  Represent it specially in
    // reflection.
    return CreateTypedefMirror(intf, intf_name, lib, lib_mirror);
  }

  Dart_Handle cls_name = NewString("_LocalClassMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  // TODO(turnidge): Why am I getting Null when I expect Object?
  Dart_Handle super_class = Dart_GetSuperclass(intf);
  if (Dart_IsNull(super_class)) {
    super_class = Dart_GetClass(CoreLib(), NewString("Object"));
  }
  Dart_Handle default_class = Dart_ClassGetDefault(intf);

  Dart_Handle intf_mirror = CreateLazyMirror(intf);
  if (Dart_IsError(intf_mirror)) {
    return intf_mirror;
  }
  Dart_Handle member_map = CreateMemberMap(intf, intf_mirror);
  if (Dart_IsError(member_map)) {
    return member_map;
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
    CreateVMReference(intf),
    intf_name,
    Dart_NewBoolean(Dart_IsClass(intf)),
    lib_mirror,
    CreateLazyMirror(super_class),
    CreateImplementsList(intf),
    CreateLazyMirror(default_class),
    member_map,
    constructor_map,
    type_var_map,
  };
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateMethodMirror(Dart_Handle func,
                                      Dart_Handle func_name,
                                      Dart_Handle owner_mirror) {
  ASSERT(Dart_IsFunction(func));
  Dart_Handle mirror_cls_name = NewString("_LocalMethodMirrorImpl");
  Dart_Handle mirror_cls = Dart_GetClass(MirrorLib(), mirror_cls_name);
  if (Dart_IsError(mirror_cls)) {
    return mirror_cls;
  }

  bool is_static = false;
  bool is_abstract = false;
  bool is_getter = false;
  bool is_setter = false;
  bool is_constructor = false;

  Dart_Handle result = Dart_FunctionIsStatic(func, &is_static);
  if (Dart_IsError(result)) {
    return result;
  }
  result = Dart_FunctionIsAbstract(func, &is_abstract);
  if (Dart_IsError(result)) {
    return result;
  }
  result = Dart_FunctionIsGetter(func, &is_getter);
  if (Dart_IsError(result)) {
    return result;
  }
  result = Dart_FunctionIsSetter(func, &is_setter);
  if (Dart_IsError(result)) {
    return result;
  }
  result = Dart_FunctionIsConstructor(func, &is_constructor);
  if (Dart_IsError(result)) {
    return result;
  }

  Dart_Handle return_type = Dart_FunctionReturnType(func);
  if (Dart_IsError(return_type)) {
    return return_type;
  }

  int64_t fixed_param_count;
  int64_t opt_param_count;
  result = Dart_FunctionParameterCounts(func,
                                        &fixed_param_count,
                                        &opt_param_count);
  if (Dart_IsError(result)) {
    return result;
  }

  // TODO(turnidge): Implement constructor kinds (arguments 7 - 10).
  Dart_Handle args[] = {
    func_name,
    owner_mirror,
    CreateParameterMirrorList(func),
    CreateLazyMirror(return_type),
    Dart_NewBoolean(is_static),
    Dart_NewBoolean(is_abstract),
    Dart_NewBoolean(is_getter),
    Dart_NewBoolean(is_setter),
    Dart_NewBoolean(is_constructor),
    Dart_False(),
    Dart_False(),
    Dart_False(),
    Dart_False(),
  };
  Dart_Handle mirror =
      Dart_New(mirror_cls, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateVariableMirror(Dart_Handle var,
                                        Dart_Handle var_name,
                                        Dart_Handle lib_mirror) {
  ASSERT(Dart_IsVariable(var));
  Dart_Handle cls_name = NewString("_LocalVariableMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  bool is_static = false;
  bool is_final = false;

  Dart_Handle result = Dart_VariableIsStatic(var, &is_static);
  if (Dart_IsError(result)) {
    return result;
  }
  result = Dart_VariableIsFinal(var, &is_final);
  if (Dart_IsError(result)) {
    return result;
  }

  Dart_Handle type = Dart_VariableType(var);
  if (Dart_IsError(type)) {
    return type;
  }

  Dart_Handle args[] = {
    var_name,
    lib_mirror,
    CreateLazyMirror(type),
    Dart_NewBoolean(is_static),
    Dart_NewBoolean(is_final),
  };
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
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
        CreateClassMirror(intf, intf_name, owner, owner_mirror);
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

    Dart_Handle func_mirror = CreateMethodMirror(func, func_name, owner_mirror);
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

    Dart_Handle func_mirror = CreateMethodMirror(func, func_name, owner_mirror);
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
    Dart_Handle var_mirror = CreateVariableMirror(var, var_name, owner_mirror);
    if (Dart_IsError(var_mirror)) {
      return var_mirror;
    }
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


static Dart_Handle CreateLibraryMirror(Dart_Handle lib) {
  Dart_Handle cls_name = NewString("_LocalLibraryMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
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
    CreateVMReference(lib),
    Dart_LibraryName(lib),
    Dart_LibraryUrl(lib),
    member_map,
  };
  Dart_Handle lib_mirror = Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  if (Dart_IsError(lib_mirror)) {
    return lib_mirror;
  }

  return lib_mirror;
}


static Dart_Handle CreateLibrariesMap() {
  // TODO(turnidge): This should be an immutable map.
  Dart_Handle map = MapNew();

  Dart_Handle lib_urls = Dart_GetLibraryURLs();
  if (Dart_IsError(lib_urls)) {
    return lib_urls;
  }
  intptr_t len;
  Dart_Handle result = Dart_ListLength(lib_urls, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (intptr_t i = 0; i < len; i++) {
    Dart_Handle lib_url = Dart_ListGetAt(lib_urls, i);
    Dart_Handle lib = Dart_LookupLibrary(lib_url);
    if (Dart_IsError(lib)) {
      return lib;
    }
    Dart_Handle lib_key = Dart_LibraryName(lib);
    Dart_Handle lib_mirror = CreateLibraryMirror(lib);
    if (Dart_IsError(lib_mirror)) {
      return lib_mirror;
    }
    // TODO(turnidge): Check for duplicate library names.
    result = MapAdd(map, lib_key, lib_mirror);
  }
  return map;
}


static Dart_Handle CreateIsolateMirror() {
  Dart_Handle cls_name = NewString("_LocalIsolateMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  Dart_Handle args[] = {
    Dart_DebugName(),
    CreateLazyMirror(Dart_RootLibrary()),
  };
  return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
}


static Dart_Handle CreateMirrorSystem() {
  Dart_Handle cls_name = NewString("_LocalMirrorSystemImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  Dart_Handle libraries = CreateLibrariesMap();
  if (Dart_IsError(libraries)) {
    return libraries;
  }

  Dart_Handle args[] = {
    libraries,
    CreateIsolateMirror(),
  };
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  if (Dart_IsError(mirror)) {
    return mirror;
  }

  return mirror;
}


static Dart_Handle CreateNullMirror() {
  Dart_Handle cls_name = NewString("_LocalInstanceMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  // TODO(turnidge): This is wrong.  The Null class is distinct from object.
  Dart_Handle object_class = Dart_GetClass(CoreLib(), NewString("Object"));

  Dart_Handle args[] = {
    CreateVMReference(Dart_Null()),
    CreateLazyMirror(object_class),
    Dart_Null(),
  };
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
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
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    if (Dart_IsError(cls)) {
      return cls;
    }
    // We set the function field of ClosureMirrors outside of the constructor
    // to break the mutual recursion.
    Dart_Handle func = Dart_ClosureFunction(instance);
    if (Dart_IsError(func)) {
      return func;
    }

    // TODO(turnidge): Why not use the real function name here?
    Dart_Handle func_name = NewString("call");
    Dart_Handle func_owner = Dart_FunctionOwner(func);
    if (Dart_IsError(func_owner)) {
      return func_owner;
    }

    // TODO(turnidge): Pass the function owner here.  This will require
    // us to support functions in CreateLazyMirror.
    Dart_Handle func_mirror =
        CreateMethodMirror(func, func_name, Dart_Null());
    if (Dart_IsError(func_mirror)) {
      return func_mirror;
    }
    Dart_Handle args[] = {
      CreateVMReference(instance),
      CreateLazyMirror(instance_cls),
      instance,
      func_mirror,
    };
    return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);

  } else {
    Dart_Handle cls_name = NewString("_LocalInstanceMirrorImpl");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    if (Dart_IsError(cls)) {
      return cls;
    }
    Dart_Handle args[] = {
      CreateVMReference(instance),
      CreateLazyMirror(instance_cls),
      instance,
    };
    return Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
  }
}


static Dart_Handle CreateMirroredError(Dart_Handle error) {
  ASSERT(Dart_IsError(error));
  if (Dart_IsUnhandledExceptionError(error)) {
    Dart_Handle exc = Dart_ErrorGetException(error);
    if (Dart_IsError(exc)) {
      return exc;
    }
    Dart_Handle exc_string = Dart_ToString(exc);
    if (Dart_IsError(exc_string)) {
      // Only propagate fatal errors from exc.toString().  Ignore the rest.
      if (Dart_IsFatalError(exc_string)) {
        return exc_string;
      }
      exc_string = Dart_Null();
    }

    Dart_Handle stack = Dart_ErrorGetStacktrace(error);
    if (Dart_IsError(stack)) {
      return stack;
    }
    Dart_Handle cls_name = NewString("MirroredUncaughtExceptionError");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    Dart_Handle args[] = {
      CreateInstanceMirror(exc),
      exc_string,
      stack,
    };
    Dart_Handle mirrored_exc =
        Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
    return Dart_NewUnhandledExceptionError(mirrored_exc);
  } else if (Dart_IsApiError(error) ||
             Dart_IsCompilationError(error)) {
    Dart_Handle cls_name = NewString("MirroredCompilationError");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    Dart_Handle args[] = { NewString(Dart_GetError(error)) };
    Dart_Handle mirrored_exc =
        Dart_New(cls, Dart_Null(), ARRAY_SIZE(args), args);
    return Dart_NewUnhandledExceptionError(mirrored_exc);
  } else {
    ASSERT(Dart_IsFatalError(error));
    return error;
  }
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


void NATIVE_ENTRY_FUNCTION(LocalObjectMirrorImpl_invoke)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle mirror = Dart_GetNativeArgument(args, 0);
  Dart_Handle member = Dart_GetNativeArgument(args, 1);
  // The wrapped arguments are either simple values or instance mirrors.
  Dart_Handle wrapped_invoke_args = Dart_GetNativeArgument(args, 2);

  Dart_Handle reflectee = UnwrapMirror(mirror);
  GrowableArray<Dart_Handle> invoke_args;
  Dart_Handle result = UnwrapArgList(wrapped_invoke_args, &invoke_args);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  result =
      Dart_Invoke(reflectee, member, invoke_args.length(), invoke_args.data());
  if (Dart_IsError(result)) {
    // Instead of propagating the error from an invoke directly, we
    // provide reflective access to the error.
    Dart_PropagateError(CreateMirroredError(result));
  }

  Dart_Handle wrapped_result = CreateInstanceMirror(result);
  if (Dart_IsError(wrapped_result)) {
    Dart_PropagateError(wrapped_result);
  }
  Dart_SetReturnValue(args, wrapped_result);
  Dart_ExitScope();
}


void NATIVE_ENTRY_FUNCTION(LocalObjectMirrorImpl_getField)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle mirror = Dart_GetNativeArgument(args, 0);
  Dart_Handle fieldName = Dart_GetNativeArgument(args, 1);

  Dart_Handle reflectee = UnwrapMirror(mirror);
  Dart_Handle result = Dart_GetField(reflectee, fieldName);
  if (Dart_IsError(result)) {
    // Instead of propagating the error from a GetField directly, we
    // provide reflective access to the error.
    Dart_PropagateError(CreateMirroredError(result));
  }

  Dart_Handle wrapped_result = CreateInstanceMirror(result);
  if (Dart_IsError(wrapped_result)) {
    Dart_PropagateError(wrapped_result);
  }
  Dart_SetReturnValue(args, wrapped_result);
  Dart_ExitScope();
}


void NATIVE_ENTRY_FUNCTION(LocalObjectMirrorImpl_setField)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle mirror = Dart_GetNativeArgument(args, 0);
  Dart_Handle fieldName = Dart_GetNativeArgument(args, 1);
  // The wrapped argument is either a simple value or instance mirror.
  Dart_Handle wrapped_arg = Dart_GetNativeArgument(args, 2);

  Dart_Handle reflectee = UnwrapMirror(mirror);
  Dart_Handle set_arg = UnwrapArg(wrapped_arg);
  if (Dart_IsError(set_arg)) {
    Dart_PropagateError(set_arg);
  }
  Dart_Handle result = Dart_SetField(reflectee, fieldName, set_arg);
  if (Dart_IsError(result)) {
    // Instead of propagating the error from a SetField directly, we
    // provide reflective access to the error.
    Dart_PropagateError(CreateMirroredError(result));
  }

  Dart_Handle wrapped_result = CreateInstanceMirror(result);
  if (Dart_IsError(wrapped_result)) {
    Dart_PropagateError(wrapped_result);
  }
  Dart_SetReturnValue(args, wrapped_result);
  Dart_ExitScope();
}


void NATIVE_ENTRY_FUNCTION(LocalClosureMirrorImpl_apply)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle mirror = Dart_GetNativeArgument(args, 0);
  // The wrapped arguments are either simple values or instance mirrors.
  Dart_Handle wrapped_invoke_args = Dart_GetNativeArgument(args, 1);

  Dart_Handle reflectee = UnwrapMirror(mirror);
  GrowableArray<Dart_Handle> invoke_args;
  Dart_Handle result = UnwrapArgList(wrapped_invoke_args, &invoke_args);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  result =
      Dart_InvokeClosure(reflectee, invoke_args.length(), invoke_args.data());
  if (Dart_IsError(result)) {
    // Instead of propagating the error from an apply directly, we
    // provide reflective access to the error.
    Dart_PropagateError(CreateMirroredError(result));
  }

  Dart_Handle wrapped_result = CreateInstanceMirror(result);
  if (Dart_IsError(wrapped_result)) {
    Dart_PropagateError(wrapped_result);
  }
  Dart_SetReturnValue(args, wrapped_result);
  Dart_ExitScope();
}


void NATIVE_ENTRY_FUNCTION(LocalClassMirrorImpl_invokeConstructor)(
    Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle klass_mirror = Dart_GetNativeArgument(args, 0);
  Dart_Handle constructor_name = Dart_GetNativeArgument(args, 1);
  // The wrapped arguments are either simple values or instance mirrors.
  Dart_Handle wrapped_invoke_args = Dart_GetNativeArgument(args, 2);

  Dart_Handle klass = UnwrapMirror(klass_mirror);
  GrowableArray<Dart_Handle> invoke_args;
  Dart_Handle result = UnwrapArgList(wrapped_invoke_args, &invoke_args);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  result = Dart_New(klass,
                    constructor_name,
                    invoke_args.length(),
                    invoke_args.data());
  if (Dart_IsError(result)) {
    // Instead of propagating the error from an invoke directly, we
    // provide reflective access to the error.
    Dart_PropagateError(CreateMirroredError(result));
  }

  Dart_Handle wrapped_result = CreateInstanceMirror(result);
  if (Dart_IsError(wrapped_result)) {
    Dart_PropagateError(wrapped_result);
  }
  Dart_SetReturnValue(args, wrapped_result);
  Dart_ExitScope();
}


void HandleMirrorsMessage(Isolate* isolate,
                          Dart_Port reply_port,
                          const Instance& message) {
  UNIMPLEMENTED();
}

}  // namespace dart
