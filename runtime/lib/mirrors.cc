// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "platform/json.h"
#include "include/dart_api.h"
#include "include/dart_debugger_api.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/message.h"
#include "vm/port.h"
#include "vm/resolver.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Mirrors_isLocalPort, 1) {
  GET_NATIVE_ARGUMENT(Instance, port, arguments->At(0));

  // Get the port id from the SendPort instance.
  const Object& id_obj = Object::Handle(DartLibraryCalls::PortGetId(port));
  if (id_obj.IsError()) {
    Exceptions::PropagateError(id_obj);
    UNREACHABLE();
  }
  ASSERT(id_obj.IsSmi() || id_obj.IsMint());
  Integer& id = Integer::Handle();
  id ^= id_obj.raw();
  Dart_Port port_id = static_cast<Dart_Port>(id.AsInt64Value());
  const Bool& is_local = Bool::Handle(Bool::Get(PortMap::IsLocalPort(port_id)));
  arguments->SetReturn(is_local);
}


// TODO(turnidge): Add Map support to the dart embedding api instead
// of implementing it here.
static Dart_Handle CoreLib() {
  Dart_Handle core_lib_name = Dart_NewString("dart:core");
  return Dart_LookupLibrary(core_lib_name);
}


static Dart_Handle MapNew() {
  Dart_Handle cls = Dart_GetClass(CoreLib(), Dart_NewString("Map"));
  if (Dart_IsError(cls)) {
    return cls;
  }
  return Dart_New(cls, Dart_Null(), 0, NULL);
}


static Dart_Handle MapAdd(Dart_Handle map, Dart_Handle key, Dart_Handle value) {
  const int kNumArgs = 2;
  Dart_Handle args[kNumArgs];
  args[0] = key;
  args[1] = value;
  return Dart_Invoke(map, Dart_NewString("[]="), kNumArgs, args);
}


static Dart_Handle MapGet(Dart_Handle map, Dart_Handle key) {
  const int kNumArgs = 1;
  Dart_Handle args[kNumArgs];
  args[0] = key;
  return Dart_Invoke(map, Dart_NewString("[]"), kNumArgs, args);
}


static Dart_Handle MirrorLib() {
  Dart_Handle mirror_lib_name = Dart_NewString("dart:mirrors");
  return Dart_LookupLibrary(mirror_lib_name);
}


static Dart_Handle IsMirror(Dart_Handle object, bool* is_mirror) {
  Dart_Handle cls_name = Dart_NewString("Mirror");
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
  Dart_Handle cls_name = Dart_NewString("VMReference");
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
  Dart_Handle field_name = Dart_NewString("_reference");
  Dart_Handle vm_ref = Dart_GetField(mirror, field_name);
  if (Dart_IsError(vm_ref)) {
    return vm_ref;
  }
  return UnwrapVMReference(vm_ref);
}


static Dart_Handle UnwrapArgList(Dart_Handle arg_list,
                                 GrowableArray<Dart_Handle>* arg_array) {
  intptr_t len = 0;
  Dart_Handle result = Dart_ListLength(arg_list, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (int i = 0; i < len; i++) {
    Dart_Handle arg = Dart_ListGetAt(arg_list, i);
    if (Dart_IsError(arg)) {
      return arg;
    }
    bool is_mirror = false;
    result = IsMirror(arg, &is_mirror);
    if (Dart_IsError(result)) {
      return result;
    }
    if (is_mirror) {
      arg_array->Add(UnwrapMirror(arg));
    } else {
      // Simple value.
      ASSERT(IsSimpleValue(arg));
      arg_array->Add(arg);
    }
  }
  return Dart_True();
}


static Dart_Handle CreateLazyLibraryMirror(Dart_Handle lib) {
  if (Dart_IsNull(lib)) {
    return lib;
  }
  Dart_Handle cls_name = Dart_NewString("_LazyLibraryMirror");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  const int kNumArgs = 1;
  Dart_Handle args[kNumArgs];
  args[0] = Dart_LibraryName(lib);
  return Dart_New(cls, Dart_Null(), kNumArgs, args);
}


static Dart_Handle CreateLazyInterfaceMirror(Dart_Handle intf) {
  if (Dart_IsNull(intf)) {
    return intf;
  }
  Dart_Handle cls_name = Dart_NewString("_LazyInterfaceMirror");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  const int kNumArgs = 2;
  Dart_Handle args[kNumArgs];
  args[0] = Dart_LibraryName(Dart_ClassGetLibrary(intf));
  args[1] = Dart_ClassName(intf);
  return Dart_New(cls, Dart_Null(), kNumArgs, args);
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

  for (int i = 0; i < len; i++) {
    Dart_Handle interface = Dart_ClassGetInterfaceAt(intf, i);
    if (Dart_IsError(interface)) {
      return interface;
    }
    Dart_Handle mirror = CreateLazyInterfaceMirror(interface);
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


static Dart_Handle CreateInterfaceMirror(Dart_Handle intf,
                                         Dart_Handle intf_name,
                                         Dart_Handle lib) {
  ASSERT(Dart_IsClass(intf) || Dart_IsInterface(intf));
  Dart_Handle cls_name = Dart_NewString("_LocalInterfaceMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  // TODO(turnidge): Why am I getting Null when I expect Object?
  Dart_Handle super_class = Dart_GetSuperclass(intf);
  if (Dart_IsNull(super_class)) {
    super_class = Dart_GetClass(CoreLib(), Dart_NewString("Object"));
  }
  Dart_Handle default_class = Dart_ClassGetDefault(intf);

  const int kNumArgs = 7;
  Dart_Handle args[kNumArgs];
  args[0] = CreateVMReference(intf);
  args[1] = intf_name;
  args[2] = Dart_NewBoolean(Dart_IsClass(intf));
  args[3] = CreateLazyLibraryMirror(lib);
  args[4] = CreateLazyInterfaceMirror(super_class);
  args[5] = CreateImplementsList(intf);
  args[6] = CreateLazyInterfaceMirror(default_class);
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), kNumArgs, args);
  return mirror;
}


static Dart_Handle CreateLibraryMemberMap(Dart_Handle lib) {
  // TODO(turnidge): This should be an immutable map.
  Dart_Handle map = MapNew();

  Dart_Handle intf_names = Dart_LibraryGetClassNames(lib);
  if (Dart_IsError(intf_names)) {
    return intf_names;
  }
  intptr_t len;
  Dart_Handle result = Dart_ListLength(intf_names, &len);
  if (Dart_IsError(result)) {
    return result;
  }
  for (int i = 0; i < len; i++) {
    Dart_Handle intf_name = Dart_ListGetAt(intf_names, i);
    Dart_Handle intf = Dart_GetClass(lib, intf_name);
    if (Dart_IsError(intf)) {
      return intf;
    }
    Dart_Handle intf_mirror = CreateInterfaceMirror(intf, intf_name, lib);
    if (Dart_IsError(intf_mirror)) {
      return intf_mirror;
    }
    result = MapAdd(map, intf_name, intf_mirror);
  }
  return map;
}


static Dart_Handle CreateLibraryMirror(Dart_Handle lib) {
  Dart_Handle cls_name = Dart_NewString("_LocalLibraryMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  Dart_Handle member_map = CreateLibraryMemberMap(lib);
  if (Dart_IsError(member_map)) {
    return member_map;
  }
  const int kNumArgs = 4;
  Dart_Handle args[kNumArgs];
  args[0] = CreateVMReference(lib);
  args[1] = Dart_LibraryName(lib);
  args[2] = Dart_LibraryUrl(lib);
  args[3] = member_map;
  Dart_Handle lib_mirror = Dart_New(cls, Dart_Null(), kNumArgs, args);
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
  for (int i = 0; i < len; i++) {
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
  Dart_Handle cls_name = Dart_NewString("_LocalIsolateMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  Dart_Handle libraries = CreateLibrariesMap();
  if (Dart_IsError(libraries)) {
    return libraries;
  }

  // Lookup the root_lib_mirror from the library list to canonicalize it.
  Dart_Handle root_lib_name = Dart_LibraryName(Dart_RootLibrary());
  Dart_Handle root_lib_mirror = MapGet(libraries, root_lib_name);
  if (Dart_IsError(root_lib_mirror)) {
    return root_lib_mirror;
  }

  const int kNumArgs = 3;
  Dart_Handle args[kNumArgs];
  args[0] = Dart_DebugName();
  args[1] = root_lib_mirror;
  args[2] = libraries;
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), kNumArgs, args);
  if (Dart_IsError(mirror)) {
    return mirror;
  }

  return mirror;
}


static Dart_Handle CreateNullMirror() {
  Dart_Handle cls_name = Dart_NewString("_LocalInstanceMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }

  // TODO(turnidge): This is wrong.  The Null class is distinct from object.
  Dart_Handle object_class = Dart_GetClass(CoreLib(), Dart_NewString("Object"));

  const int kNumArgs = 4;
  Dart_Handle args[kNumArgs];
  args[0] = CreateVMReference(Dart_Null());
  args[1] = CreateLazyInterfaceMirror(object_class);
  args[2] = Dart_True();
  args[3] = Dart_Null();
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), kNumArgs, args);
  return mirror;
}


static Dart_Handle CreateInstanceMirror(Dart_Handle instance) {
  if (Dart_IsNull(instance)) {
    return CreateNullMirror();
  }
  ASSERT(Dart_IsInstance(instance));
  Dart_Handle cls_name = Dart_NewString("_LocalInstanceMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  Dart_Handle instance_cls = Dart_InstanceGetClass(instance);
  if (Dart_IsError(instance_cls)) {
    return instance_cls;
  }
  bool is_simple = IsSimpleValue(instance);
  const int kNumArgs = 4;
  Dart_Handle args[kNumArgs];
  args[0] = CreateVMReference(instance);
  args[1] = CreateLazyInterfaceMirror(instance_cls);
  args[2] = Dart_NewBoolean(is_simple);
  args[3] = (is_simple ? instance : Dart_Null());
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), kNumArgs, args);
  return mirror;
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
    Dart_Handle cls_name = Dart_NewString("MirroredUncaughtExceptionError");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    const int kNumArgs = 3;
    Dart_Handle args[kNumArgs];
    args[0] = CreateInstanceMirror(exc);
    args[1] = exc_string;
    args[2] = stack;
    Dart_Handle mirrored_exc = Dart_New(cls, Dart_Null(), kNumArgs, args);
    return Dart_NewUnhandledExceptionError(mirrored_exc);
  } else if (Dart_IsApiError(error) ||
             Dart_IsCompilationError(error)) {
    Dart_Handle cls_name = Dart_NewString("MirroredCompilationError");
    Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
    const int kNumArgs = 1;
    Dart_Handle args[kNumArgs];
    args[0] = Dart_NewString(Dart_GetError(error));
    Dart_Handle mirrored_exc = Dart_New(cls, Dart_Null(), kNumArgs, args);
    return Dart_NewUnhandledExceptionError(mirrored_exc);
  } else {
    ASSERT(Dart_IsFatalError(error));
    return error;
  }
}


void NATIVE_ENTRY_FUNCTION(Mirrors_makeLocalIsolateMirror)(
    Dart_NativeArguments args) {
  Dart_Handle mirror = CreateIsolateMirror();
  if (Dart_IsError(mirror)) {
    Dart_PropagateError(mirror);
  }
  Dart_SetReturnValue(args, mirror);
}

void NATIVE_ENTRY_FUNCTION(Mirrors_makeLocalInstanceMirror)(
    Dart_NativeArguments args) {
  Dart_Handle reflectee = Dart_GetNativeArgument(args, 0);
  Dart_Handle mirror = CreateInstanceMirror(reflectee);
  if (Dart_IsError(mirror)) {
    Dart_PropagateError(mirror);
  }
  Dart_SetReturnValue(args, mirror);
}

void NATIVE_ENTRY_FUNCTION(LocalObjectMirrorImpl_invoke)(
    Dart_NativeArguments args) {
  Dart_Handle mirror = Dart_GetNativeArgument(args, 0);
  Dart_Handle member = Dart_GetNativeArgument(args, 1);
  Dart_Handle raw_invoke_args = Dart_GetNativeArgument(args, 2);

  Dart_Handle reflectee = UnwrapMirror(mirror);
  GrowableArray<Dart_Handle> invoke_args;
  Dart_Handle result = UnwrapArgList(raw_invoke_args, &invoke_args);
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
}

void HandleMirrorsMessage(Isolate* isolate,
                          Dart_Port reply_port,
                          const Instance& message) {
  UNIMPLEMENTED();
}

}  // namespace dart
