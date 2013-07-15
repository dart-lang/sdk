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

namespace dart {

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


static void FreeVMReference(Dart_WeakPersistentHandle weak_ref, void* data) {
  Dart_PersistentHandle perm_handle =
      reinterpret_cast<Dart_PersistentHandle>(data);
  Dart_DeletePersistentHandle(perm_handle);
  Dart_DeleteWeakPersistentHandle(weak_ref);
}


static Dart_Handle CreateVMReference(Dart_Handle handle) {
  // Create the VMReference object.
  Dart_Handle cls_name = NewString("VMReference");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
  }
  Dart_Handle vm_ref =  Dart_New(type, Dart_Null(), 0, NULL);
  if (Dart_IsError(vm_ref)) {
    return vm_ref;
  }

  // Allocate a persistent handle.
  Dart_PersistentHandle perm_handle = Dart_NewPersistentHandle(handle);
  ASSERT(perm_handle != NULL);

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
  Dart_WeakPersistentHandle weak_ref =
      Dart_NewWeakPersistentHandle(vm_ref, perm_handle_data, FreeVMReference);
  ASSERT(weak_ref != NULL);

  // Success.
  return vm_ref;
}


// TODO(11742): Remove once there are no more users of the Dart_Handle-based
// VMReferences.
static Dart_Handle CreateMirrorReference(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& referent = Object::Handle(isolate, Api::UnwrapHandle(handle));
  const MirrorReference& reference =
       MirrorReference::Handle(MirrorReference::New());
  reference.set_referent(referent);
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
  Dart_Handle param_type = Dart_GetType(MirrorLib(), param_cls_name, 0, NULL);
  if (Dart_IsError(param_type)) {
    return param_type;
  }

  for (int64_t i = 0; i < param_count; i++) {
    Dart_Handle arg_type = Dart_FunctionParameterType(func, i);
    if (Dart_IsError(arg_type)) {
      return arg_type;
    }
    Dart_Handle args[] = {
      CreateLazyMirror(arg_type),
      Dart_NewBoolean(i >= fixed_param_count),  // optional param?
    };
    Dart_Handle param =
        Dart_New(param_type, Dart_Null(), ARRAY_SIZE(args), args);
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
        CreateParameterMirrorList(sig),
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


static Dart_Handle CreateTypeVariableMirror(Dart_Handle type_var,
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
    type_var_name,
    owner_mirror,
    CreateLazyMirror(upper_bound),
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
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
  Dart_Handle mirror_type = Dart_GetType(MirrorLib(), mirror_cls_name, 0, NULL);
  if (Dart_IsError(mirror_type)) {
    return mirror_type;
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
      Dart_New(mirror_type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateMemberMap(Dart_Handle owner, Dart_Handle owner_mirror);
static Dart_Handle CreateConstructorMap(Dart_Handle owner,
                                        Dart_Handle owner_mirror);


static Dart_Handle CreateClassMirror(Dart_Handle intf,
                                     Dart_Handle intf_name,
                                     Dart_Handle lib,
                                     Dart_Handle lib_mirror) {
  ASSERT(Dart_IsClass(intf));
  if (Dart_ClassIsTypedef(intf)) {
    // This class is actually a typedef.  Represent it specially in
    // reflection.
    return CreateTypedefMirror(intf, intf_name, lib, lib_mirror);
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
    CreateMirrorReference(intf),
    CreateVMReference(intf),
    Dart_Null(),  // "name"
    Dart_NewBoolean(Dart_IsClass(intf)),
    lib_mirror,
    CreateLazyMirror(super_class),
    CreateImplementsList(intf),
    CreateLazyMirror(default_class),
    member_map,
    constructor_map,
    type_var_map,
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateMethodMirror(Dart_Handle func,
                                      Dart_Handle owner_mirror) {
  ASSERT(Dart_IsFunction(func));
  Dart_Handle mirror_cls_name = NewString("_LocalMethodMirrorImpl");
  Dart_Handle mirror_type = Dart_GetType(MirrorLib(), mirror_cls_name, 0, NULL);
  if (Dart_IsError(mirror_type)) {
    return mirror_type;
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
    CreateMirrorReference(func),
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
      Dart_New(mirror_type, Dart_Null(), ARRAY_SIZE(args), args);
  return mirror;
}


static Dart_Handle CreateVariableMirror(Dart_Handle var,
                                        Dart_Handle var_name,
                                        Dart_Handle lib_mirror) {
  ASSERT(Dart_IsVariable(var));
  Dart_Handle cls_name = NewString("_LocalVariableMirrorImpl");
  Dart_Handle type = Dart_GetType(MirrorLib(), cls_name, 0, NULL);
  if (Dart_IsError(type)) {
    return type;
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

  Dart_Handle var_type = Dart_VariableType(var);
  if (Dart_IsError(var_type)) {
    return var_type;
  }

  Dart_Handle args[] = {
    var_name,
    lib_mirror,
    CreateLazyMirror(var_type),
    Dart_NewBoolean(is_static),
    Dart_NewBoolean(is_final),
  };
  Dart_Handle mirror = Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
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

    Dart_Handle func_mirror = CreateMethodMirror(func, owner_mirror);
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

    Dart_Handle func_mirror = CreateMethodMirror(func, owner_mirror);
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
    CreateVMReference(lib),
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
    Dart_Handle lib_mirror = CreateLibraryMirror(lib);
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
    CreateVMReference(Dart_Null()),
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
        CreateMethodMirror(func, Dart_Null());
    if (Dart_IsError(func_mirror)) {
      return func_mirror;
    }
    Dart_Handle args[] = {
      CreateVMReference(instance),
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
      CreateVMReference(instance),
      CreateLazyMirror(instance_cls),
      instance,
    };
    return Dart_New(type, Dart_Null(), ARRAY_SIZE(args), args);
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
  Dart_Handle lib_handle = Api::NewHandle(isolate, cls.library());
  if (Dart_IsError(lib_handle)) {
    Dart_PropagateError(lib_handle);
  }
  Dart_Handle lib_mirror = CreateLibraryMirror(lib_handle);
  if (Dart_IsError(lib_mirror)) {
    Dart_PropagateError(lib_mirror);
  }
  Dart_Handle result = CreateClassMirror(cls_handle,
                                         name_handle,
                                         lib_handle,
                                         lib_mirror);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  Dart_SetReturnValue(args, result);
  Dart_ExitScope();
}

void NATIVE_ENTRY_FUNCTION(Mirrors_metadata)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle mirror = Dart_GetNativeArgument(args, 0);

  Dart_Handle reflectee = UnwrapMirror(mirror);
  Dart_Handle result = Dart_GetMetadata(reflectee);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  ASSERT(Dart_IsList(result));
  Dart_SetReturnValue(args, result);
  Dart_ExitScope();
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


static RawFunction* ResolveConstructor(const char* current_func,
                                       const Class& cls,
                                       const String& class_name,
                                       const String& constr_name,
                                       int num_args) {
  // The constructor must be present in the interface.
  const Function& constructor =
      Function::Handle(cls.LookupFunctionAllowPrivate(constr_name));
  if (constructor.IsNull() ||
      (!constructor.IsConstructor() && !constructor.IsFactory())) {
    const String& lookup_class_name = String::Handle(cls.Name());
    if (!class_name.Equals(lookup_class_name)) {
      // When the class name used to build the constructor name is
      // different than the name of the class in which we are doing
      // the lookup, it can be confusing to the user to figure out
      // what's going on.  Be a little more explicit for these error
      // messages.
      const String& message = String::Handle(
          String::NewFormatted(
              "%s: could not find factory '%s' in class '%s'.",
              current_func,
              constr_name.ToCString(),
              lookup_class_name.ToCString()));
      ThrowMirroredCompilationError(message);
      UNREACHABLE();
    } else {
      const String& message = String::Handle(
          String::NewFormatted("%s: could not find constructor '%s'.",
                               current_func, constr_name.ToCString()));
      ThrowMirroredCompilationError(message);
      UNREACHABLE();
    }
  }
  int extra_args = (constructor.IsConstructor() ? 2 : 1);
  String& error_message = String::Handle();
  if (!constructor.AreValidArgumentCounts(num_args + extra_args,
                                          0,
                                          &error_message)) {
    const String& message = String::Handle(
        String::NewFormatted("%s: wrong argument count for "
                             "constructor '%s': %s.",
                             current_func,
                             constr_name.ToCString(),
                             error_message.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }
  return constructor.raw();
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
  const MirrorReference& klass_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(0));
  Class& klass = Class::Handle();
  klass ^= klass_ref.referent();
  return klass.Name();
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

  const Instance& reflectee =
      Instance::CheckedHandle(arguments->NativeArgAt(1));

  const String& function_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  const Array& positional_args =
      Array::CheckedHandle(arguments->NativeArgAt(3));
  intptr_t number_of_arguments = positional_args.Length();


  const intptr_t num_receiver = 1;  // 1 for instance methods
  const Array& args =
      Array::Handle(Array::New(number_of_arguments + num_receiver));
  Object& arg = Object::Handle();
  args.SetAt(0, reflectee);
  for (int i = 0; i < number_of_arguments; i++) {
    arg = positional_args.At(i);
    args.SetAt((i + num_receiver), arg);
  }

  // TODO(11771): This won't find private members.
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(reflectee,
                               function_name,
                               (number_of_arguments + 1),
                               Resolver::kIsQualified));

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           function,
                                           function_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.

  const Instance& reflectee =
      Instance::CheckedHandle(arguments->NativeArgAt(1));

  const String& getter_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

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

  const Instance& reflectee =
      Instance::CheckedHandle(arguments->NativeArgAt(1));

  const String& setter_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  const Instance& value = Instance::CheckedHandle(arguments->NativeArgAt(3));

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
  const Instance& closure = Instance::CheckedHandle(arguments->NativeArgAt(0));
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


DEFINE_NATIVE_ENTRY(ClassMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.

  const MirrorReference& klass_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(1));
  Class& klass = Class::Handle();
  klass ^= klass_ref.referent();

  const String& function_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  const Array& positional_args =
      Array::CheckedHandle(arguments->NativeArgAt(3));
  intptr_t number_of_arguments = positional_args.Length();

  // TODO(11771): This won't find private members.
  const Function& function = Function::Handle(
        Resolver::ResolveStatic(klass,
                                function_name,
                                number_of_arguments,
                                Object::empty_array(),
                                Resolver::kIsQualified));
  if (function.IsNull()) {
    const String& klass_name = String::Handle(klass.Name());
    const String& message = String::Handle(
      String::NewFormatted("%s: did not find static method '%s.%s'.",
                           "ClassMirror_invoke",
                           klass_name.ToCString(),
                           function_name.ToCString()));
    ThrowMirroredCompilationError(message);
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

  const MirrorReference& klass_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(1));
  Class& klass = Class::Handle();
  klass ^= klass_ref.referent();

  const String& getter_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  // Note static fields do not have implicit getters.
  const Field& field = Field::Handle(klass.LookupStaticField(getter_name));
  if (field.IsNull() || FieldIsUninitialized(field)) {
    const String& internal_getter_name = String::Handle(
        Field::GetterName(getter_name));
    const Function& getter = Function::Handle(
        klass.LookupStaticFunctionAllowPrivate(internal_getter_name));

    if (getter.IsNull()) {
      const String& message = String::Handle(
        String::NewFormatted("%s: did not find static getter '%s'.",
                             "ClassMirror_invokeGetter",
                             getter_name.ToCString()));
      ThrowMirroredCompilationError(message);
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

  const MirrorReference& klass_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(1));
  Class& klass = Class::Handle();
  klass ^= klass_ref.referent();

  const String& setter_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  const Instance& value = Instance::CheckedHandle(arguments->NativeArgAt(3));

  // Check for real fields and user-defined setters.
  const Field& field = Field::Handle(klass.LookupStaticField(setter_name));
  if (field.IsNull()) {
    const String& internal_setter_name = String::Handle(
      Field::SetterName(setter_name));
    const Function& setter = Function::Handle(
      klass.LookupStaticFunctionAllowPrivate(internal_setter_name));

    if (setter.IsNull()) {
      const String& message = String::Handle(
        String::NewFormatted("%s: did not find static setter '%s'.",
                             "ClassMirror_invokeSetter",
                             setter_name.ToCString()));
      ThrowMirroredCompilationError(message);
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
  const MirrorReference& klass_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(0));
  Class& klass = Class::Handle();
  klass ^= klass_ref.referent();

  const String& constructor_name =
      String::CheckedHandle(arguments->NativeArgAt(1));

  const Array& positional_args =
      Array::CheckedHandle(arguments->NativeArgAt(2));

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

  const Function& constructor =
      Function::Handle(ResolveConstructor("ClassMirror_invokeConstructor",
                                          klass,
                                          klass_name,
                                          internal_constructor_name,
                                          number_of_arguments));

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

  const MirrorReference& library_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(1));
  Library& library = Library::Handle();
  library ^= library_ref.referent();

  const String& function_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  const Array& positional_args =
      Array::CheckedHandle(arguments->NativeArgAt(3));
  intptr_t number_of_arguments = positional_args.Length();


  const Function& function = Function::Handle(
      library.LookupFunctionAllowPrivate(function_name));

  if (function.IsNull()) {
    const String& message = String::Handle(
      String::NewFormatted("%s: did not find top-level function '%s'.",
                           "LibraryMirror_invoke",
                           function_name.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }

  // LookupFunctionAllowPrivate does not check argument arity, so we
  // do it here.
  String& error_message = String::Handle();
  if (!function.AreValidArgumentCounts(number_of_arguments,
                                       /* num_named_args */ 0,
                                       &error_message)) {
    const String& message = String::Handle(
      String::NewFormatted("%s: wrong argument count for function '%s': %s.",
                           "LibraryMirror_invoke",
                           function_name.ToCString(),
                           error_message.ToCString()));
    ThrowMirroredCompilationError(message);
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

  const MirrorReference& library_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(1));
  Library& library = Library::Handle();
  library ^= library_ref.referent();

  const String& getter_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  // To access a top-level we may need to use the Field or the
  // getter Function.  The getter function may either be in the
  // library or in the field's owner class, depending.
  const Field& field =
      Field::Handle(library.LookupFieldAllowPrivate(getter_name));
  Function& getter = Function::Handle();
  if (field.IsNull()) {
    // No field found.  Check for a getter in the lib.
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = library.LookupFunctionAllowPrivate(internal_getter_name);
  } else if (FieldIsUninitialized(field)) {
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
  } else if (!field.IsNull()) {
    return field.value();
  } else {
    const String& message = String::Handle(
        String::NewFormatted("%s: did not find top-level variable '%s'.",
                             "LibraryMirror_invokeGetter",
                             getter_name.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
    return Instance::null();
  }
}


DEFINE_NATIVE_ENTRY(LibraryMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.

  const MirrorReference& library_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(1));
  Library& library = Library::Handle();
  library ^= library_ref.referent();

  const String& setter_name =
      String::CheckedHandle(arguments->NativeArgAt(2));

  const Instance& value = Instance::CheckedHandle(arguments->NativeArgAt(3));

  // To access a top-level we may need to use the Field or the
  // setter Function.  The setter function may either be in the
  // library or in the field's owner class, depending.
  const Field& field =
      Field::Handle(library.LookupFieldAllowPrivate(setter_name));

  if (field.IsNull()) {
    const String& internal_setter_name =
        String::Handle(Field::SetterName(setter_name));
    const Function& setter = Function::Handle(
        library.LookupFunctionAllowPrivate(internal_setter_name));

    if (setter.IsNull()) {
      const String& message = String::Handle(
        String::NewFormatted("%s: did not find top-level variable '%s'.",
                             "LibraryMirror_invokeSetter",
                             setter_name.ToCString()));
      ThrowMirroredCompilationError(message);
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
  const MirrorReference& func_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(0));
  Function& func = Function::Handle();
  func ^= func_ref.referent();
  return func.UserVisibleName();
}

}  // namespace dart
