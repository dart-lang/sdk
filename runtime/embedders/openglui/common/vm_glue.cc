// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "embedders/openglui/common/extension.h"
#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/vm_glue.h"
#include "include/dart_api.h"

char* VMGlue::extension_script_ = NULL;

// snapshot_buffer points to a snapshot if we link in a snapshot otherwise
// it is initialized to NULL.

VMGlue::VMGlue(ISized* surface,
               const char* script_path,
               const char* extension_script,
               const char* main_script)
    : surface_(surface),
      isolate_(NULL),
      initialized_vm_(false),
      initialized_script_(false) {
  LOGI("Creating VMGlue");
  if (main_script == NULL) {
    main_script = "main.dart";
  }
  if (extension_script == NULL) {
    extension_script = "gl.dart";
  }
  size_t len = strlen(script_path) + strlen(main_script) + 2;
  main_script_ = new char[len];
  snprintf(main_script_, len, "%s/%s", script_path, main_script);
  len = strlen(script_path) + strlen(extension_script) + 2;
  extension_script_ = new char[len];
  snprintf(extension_script_, len, "%s/%s", script_path, extension_script);
}

int VMGlue::ErrorExit(const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  LOGE(format, arguments);
  va_end(arguments);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  LOGE("Shutdown isolate");
  return -1;
}

Dart_Handle VMGlue::CheckError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    LOGE("Unexpected Error Handle: %s", Dart_GetError(handle));
    Dart_PropagateError(handle);
  }
  return handle;
}

#define CHECK_RESULT(result)                   \
  if (Dart_IsError(result)) {                  \
    *error = strdup(Dart_GetError(result));    \
    LOGE("%s", *error);                        \
    Dart_ExitScope();                          \
    Dart_ShutdownIsolate();                    \
    return false;                              \
  }

Dart_Handle VMGlue::LibraryTagHandler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle urlHandle) {
  const char* url;
  Dart_StringToCString(urlHandle, &url);
  if (tag == kCanonicalizeUrl) {
    return urlHandle;
  }
  // TODO(vsm): Split this up into separate libraries for 3D, 2D,
  // Touch, Audio, etc.  All builtin libraries should be handled here
  // (or moved into a snapshot).
  if (strcmp(url, "gl.dart") == 0) {
    Dart_Handle source =
        VMGlue::LoadSourceFromFile(extension_script_);
    Dart_Handle library = CheckError(Dart_LoadLibrary(urlHandle, source));
    CheckError(Dart_SetNativeResolver(library, ResolveName));
    return library;
  }
  LOGE("UNIMPLEMENTED: load library %s\n", url);
  return NULL;
}

// Returns true on success, false on failure.
bool VMGlue::CreateIsolateAndSetupHelper(const char* script_uri,
                                         const char* main,
                                         void* data,
                                         char** error) {
  LOGI("Creating isolate %s, %s", script_uri, main);
  Dart_Isolate isolate =
      Dart_CreateIsolate(script_uri, main, NULL, data, error);
  if (isolate == NULL) {
    LOGE("Couldn't create isolate: %s", *error);
    return false;
  }

  LOGI("Entering scope");
  Dart_EnterScope();

  // Set up the library tag handler for this isolate.
  LOGI("Setting up library tag handler");
  Dart_Handle result = CheckError(Dart_SetLibraryTagHandler(LibraryTagHandler));
  CHECK_RESULT(result);

  Dart_ExitScope();
  return true;
}

bool VMGlue::CreateIsolateAndSetup(const char* script_uri,
  const char* main,
  void* data, char** error) {
  return CreateIsolateAndSetupHelper(script_uri,
                                     main,
                                     data,
                                     error);
}

const char* VM_FLAGS[] = {
  "--enable_type_checks",  // TODO(gram): This should be an option!
  "--trace_isolates",
  "--trace_natives",
};

int VMGlue::InitializeVM() {
  // We need the next call to get Dart_Initialize not to bail early.
  LOGI("Setting VM Options");
  Dart_SetVMFlags(sizeof(VM_FLAGS) / sizeof(VM_FLAGS[0]), VM_FLAGS);

  // Initialize the Dart VM, providing the callbacks to use for
  // creating and shutting down isolates.
  LOGI("Initializing Dart");
  if (!Dart_Initialize(CreateIsolateAndSetup,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL)) {
    LOGE("VM initialization failed\n");
    return -1;
  }
  initialized_vm_ = true;

  return 0;
}

Dart_Handle VMGlue::LoadSourceFromFile(const char* url) {
  FILE* file = fopen(url, "r");
  if (file == NULL) {
    LOGE("Main script not found at: %s\n", url);
    return NULL;
  }

  struct stat sb;
  int fd = fileno(file);
  fstat(fd, &sb);
  int length = sb.st_size;
  LOGI("Entry file %s is %d bytes.\n", url, length);

  char* buffer = new char[length+1];
  if (read(fd, buffer, length) < 0) {
    LOGE("Could not read script %s.\n", url);
    return NULL;
  }
  buffer[length] = 0;
  fclose(file);

  Dart_Handle contents = CheckError(Dart_NewStringFromCString(buffer));
  delete[] buffer;
  return contents;
}

int VMGlue::StartMainIsolate() {
  if (!initialized_vm_) {
    int rtn = InitializeVM();
    if (rtn != 0) return rtn;
  }

  // Create an isolate and loads up the application script.
  char* error = NULL;
  if (!CreateIsolateAndSetup(main_script_, "main", NULL, &error)) {
    LOGE("CreateIsolateAndSetup: %s\n", error);
    free(error);
    return -1;
  }
  LOGI("Created isolate");
  isolate_ = Dart_CurrentIsolate();
  Dart_EnterScope();

  Dart_Handle url = CheckError(Dart_NewStringFromCString(main_script_));
  Dart_Handle source = LoadSourceFromFile(main_script_);
  CheckError(Dart_LoadScript(url, source));

  Dart_ExitScope();
  Dart_ExitIsolate();
  return 0;
}

int VMGlue::CallSetup() {
  if (!initialized_script_) {
    initialized_script_ = true;
    LOGI("Invoking setup(0,0,%d,%d)", surface_->width(), surface_->height());
    Dart_EnterIsolate(isolate_);
    Dart_EnterScope();
    Dart_Handle args[2];
    args[0] = CheckError(Dart_NewInteger(surface_->width()));
    args[1] = CheckError(Dart_NewInteger(surface_->height()));
    int rtn = Invoke("setup", 2, args);

    if (rtn == 0) {
      // Plug in the print handler. It would be nice if we could do this
      // before calling setup, but the call to GetField blows up if we
      // haven't run anything yet.
      Dart_Handle library = CheckError(Dart_LookupLibrary(
          Dart_NewStringFromCString("gl.dart")));
      Dart_Handle print = CheckError(
          Dart_GetField(library, Dart_NewStringFromCString("_printClosure")));
      Dart_Handle corelib = CheckError(Dart_LookupLibrary(
          Dart_NewStringFromCString("dart:core")));
      CheckError(Dart_SetField(corelib,
        Dart_NewStringFromCString("_printClosure"), print));
    }

    Dart_ExitScope();
    Dart_ExitIsolate();
    LOGI("Done setup");
    return rtn;
  }
  return 0;
}

int VMGlue::CallUpdate() {
  if (initialized_script_) {
    LOGI("Invoking update");
    Dart_EnterIsolate(isolate_);
    Dart_EnterScope();
    int rtn = Invoke("update", 0, 0);
    Dart_ExitScope();
    Dart_ExitIsolate();
    LOGI("Done update");
    return rtn;
  }
  return -1;
}

int VMGlue::OnMotionEvent(const char* pFunction, int64_t pWhen,
  float pMoveX, float pMoveY) {
  if (initialized_script_) {
    LOGI("Invoking %s", pFunction);
    Dart_EnterIsolate(isolate_);
    Dart_EnterScope();
    Dart_Handle args[3];
    args[0] = CheckError(Dart_NewInteger(pWhen));
    args[1] = CheckError(Dart_NewDouble(pMoveX));
    args[2] = CheckError(Dart_NewDouble(pMoveY));
    int rtn = Invoke(pFunction, 3, args, false);
    Dart_ExitScope();
    Dart_ExitIsolate();
    LOGI("Done %s", pFunction);
    return rtn;
  }
  return -1;
}

int VMGlue::OnKeyEvent(const char* function, int64_t when, int32_t flags,
       int32_t key_code, int32_t meta_state, int32_t repeat) {
  if (initialized_script_) {
    LOGI("Invoking %s", function);
    Dart_EnterIsolate(isolate_);
    Dart_EnterScope();
    Dart_Handle args[5];
    args[0] = CheckError(Dart_NewInteger(when));
    args[1] = CheckError(Dart_NewInteger(flags));
    args[2] = CheckError(Dart_NewInteger(key_code));
    args[3] = CheckError(Dart_NewInteger(meta_state));
    args[4] = CheckError(Dart_NewInteger(repeat));
    int rtn = Invoke(function, 5, args, false);
    Dart_ExitScope();
    Dart_ExitIsolate();
    LOGI("Done %s", function);
    return rtn;
  }
  return -1;
}

int VMGlue::Invoke(const char* function,
                   int argc,
                   Dart_Handle* args,
                   bool failIfNotDefined) {
  LOGI("in invoke(%s)", function);

  // Lookup the library of the root script.
  LOGI("looking up the root library");
  Dart_Handle library = Dart_RootLibrary();
  if (Dart_IsNull(library)) {
     return ErrorExit("Unable to find root library\n");
  }

  Dart_Handle nameHandle = Dart_NewStringFromCString(function);

  LOGI("invoking %s", function);
  Dart_Handle result = Dart_Invoke(library, nameHandle, argc, args);

  if (Dart_IsError(result)) {
    if (failIfNotDefined) {
      return ErrorExit("Invoke %s: %s\n", function, Dart_GetError(result));
    } else {
      LOGE("Invoke %s: %s", function, Dart_GetError(result));
    }
  }

  // TODO(vsm): I don't think we need this.
  // Keep handling messages until the last active receive port is closed.
  LOGI("Entering Dart message loop");
  result = Dart_RunLoop();
  if (Dart_IsError(result)) {
    return ErrorExit("Dart_RunLoop: %s\n", Dart_GetError(result));
  }

  LOGI("out invoke");
  return 0;
}

void VMGlue::FinishMainIsolate() {
  LOGI("Finish main isolate");
  Dart_EnterIsolate(isolate_);
  // Shutdown the isolate.
  Dart_ShutdownIsolate();
  isolate_ = NULL;
  initialized_script_ = false;
}

