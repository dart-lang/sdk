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


static Dart_Handle CreateLibraryMirror(Dart_Handle lib) {
  Dart_Handle cls_name = Dart_NewString("_LocalLibraryMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  const int kNumArgs = 3;
  Dart_Handle args[kNumArgs];
  args[0] = CreateVMReference(lib);
  args[1] = Dart_LibraryName(lib);
  args[2] = Dart_LibraryUrl(lib);
  return Dart_New(cls, Dart_Null(), kNumArgs, args);
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


static Dart_Handle CreateLocalIsolateMirror() {
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
  return mirror;
}


static Dart_Handle CreateLocalInstanceMirror(Dart_Handle instance) {
  // ASSERT(Dart_IsInstance(instance));
  Dart_Handle cls_name = Dart_NewString("_LocalInstanceMirrorImpl");
  Dart_Handle cls = Dart_GetClass(MirrorLib(), cls_name);
  if (Dart_IsError(cls)) {
    return cls;
  }
  const int kNumArgs = 2;
  Dart_Handle args[kNumArgs];
  args[0] = CreateVMReference(instance);
  if (IsSimpleValue(instance)) {
    args[1] = instance;
  } else {
    args[1] = Dart_Null();
  }
  Dart_Handle mirror = Dart_New(cls, Dart_Null(), kNumArgs, args);
  return mirror;
}


void NATIVE_ENTRY_FUNCTION(Mirrors_makeLocalIsolateMirror)(
    Dart_NativeArguments args) {
  Dart_Handle mirror = CreateLocalIsolateMirror();
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
    Dart_PropagateError(result);
  }
  Dart_Handle wrapped_result = CreateLocalInstanceMirror(result);
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
