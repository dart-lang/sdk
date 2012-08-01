// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <assert.h>
#include <errno.h>
#include <stdlib.h>

#include "dart_archive.h"
#include "messaging.h"

/** The enumeration of request types for communicating with Dart. */
enum RequestType {
  kArchiveReadNew = 0,
  kArchiveReadSupportFilterAll,
  kArchiveReadSupportFilterBzip2,
  kArchiveReadSupportFilterCompress,
  kArchiveReadSupportFilterGzip,
  kArchiveReadSupportFilterLzma,
  kArchiveReadSupportFilterXz,
  kArchiveReadSupportFilterProgram,
  kArchiveReadSupportFilterProgramSignature,
  kArchiveReadSupportFormatAll,
  kArchiveReadSupportFormatAr,
  kArchiveReadSupportFormatCpio,
  kArchiveReadSupportFormatEmpty,
  kArchiveReadSupportFormatIso9660,
  kArchiveReadSupportFormatMtree,
  kArchiveReadSupportFormatRaw,
  kArchiveReadSupportFormatTar,
  kArchiveReadSupportFormatZip,
  kArchiveReadSetFilterOptions,
  kArchiveReadSetFormatOptions,
  kArchiveReadSetOptions,
  kArchiveReadOpenFilename,
  kArchiveReadOpenMemory,
  kArchiveReadNextHeader,
  kArchiveReadDataBlock,
  kArchiveReadDataSkip,
  kArchiveReadClose,
  kArchiveReadFree,
  kNumberOfRequestTypes
};

/**
 * Dispatches a message from Dart to its native function equivalent.
 *
 * In addition to matching up a message with its respective function, this
 * parses out the standard archive struct argument from the message and resolves
 * it to an actual pointer to an archive struct.
 */
static void archiveDispatch(Dart_Port dest_port_id,
                            Dart_Port reply_port_id,
                            Dart_CObject* message) {
  if (message->type != kArray) {
    postInvalidArgument(reply_port_id, "Message was not an array.");
    return;
  } else if (message->value.as_array.length < 2) {
    postInvalidArgument(reply_port_id, "Message array had %d elements, " \
      "expected at least 2.", message->value.as_array.length);
    return;
  }

  Dart_CObject* wrapped_request_type = message->value.as_array.values[0];
  if (wrapped_request_type->type != kInt32) {
    postInvalidArgument(reply_port_id, "Invalid request type %d.",
      wrapped_request_type->type);
    return;
  }
  enum RequestType request_type = wrapped_request_type->value.as_int32;

  Dart_CObject* archive_id = message->value.as_array.values[1];
  struct archive* archive;
  if (archive_id->type == kNull) {
    archive = NULL;
  } else if (archive_id->type == kInt64 || archive_id->type == kInt32) {
    archive = (struct archive*) (intptr_t) getInteger(archive_id);
  } else {
    postInvalidArgument(reply_port_id, "Invalid archive id type %d.",
      archive_id->type);
    return;
  }

  switch (request_type) {
  case kArchiveReadNew:
    archiveReadNew(reply_port_id);
    break;
  case kArchiveReadSupportFilterAll:
    archiveReadSupportFilterAll(reply_port_id, archive);
    break;
  case kArchiveReadSupportFilterBzip2:
    archiveReadSupportFilterBzip2(reply_port_id, archive);
    break;
  case kArchiveReadSupportFilterCompress:
    archiveReadSupportFilterCompress(reply_port_id, archive);
    break;
  case kArchiveReadSupportFilterGzip:
    archiveReadSupportFilterGzip(reply_port_id, archive);
    break;
  case kArchiveReadSupportFilterLzma:
    archiveReadSupportFilterLzma(reply_port_id, archive);
    break;
  case kArchiveReadSupportFilterXz:
    archiveReadSupportFilterXz(reply_port_id, archive);
    break;
  case kArchiveReadSupportFilterProgram:
    archiveReadSupportFilterProgram(reply_port_id, archive, message);
    break;
  case kArchiveReadSupportFilterProgramSignature:
    archiveReadSupportFilterProgramSignature(
        reply_port_id, archive, message);
    break;
  case kArchiveReadSupportFormatAll:
    archiveReadSupportFormatAll(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatAr:
    archiveReadSupportFormatAr(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatCpio:
    archiveReadSupportFormatCpio(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatEmpty:
    archiveReadSupportFormatEmpty(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatIso9660:
    archiveReadSupportFormatIso9660(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatMtree:
    archiveReadSupportFormatMtree(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatRaw:
    archiveReadSupportFormatRaw(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatTar:
    archiveReadSupportFormatTar(reply_port_id, archive);
    break;
  case kArchiveReadSupportFormatZip:
    archiveReadSupportFormatZip(reply_port_id, archive);
    break;
  case kArchiveReadSetFilterOptions:
    archiveReadSetFilterOptions(reply_port_id, archive, message);
    break;
  case kArchiveReadSetFormatOptions:
    archiveReadSetFormatOptions(reply_port_id, archive, message);
    break;
  case kArchiveReadSetOptions:
    archiveReadSetOptions(reply_port_id, archive, message);
    break;
  case kArchiveReadOpenFilename:
    archiveReadOpenFilename(reply_port_id, archive, message);
    break;
  case kArchiveReadOpenMemory:
    archiveReadOpenMemory(reply_port_id, archive, message);
    break;
  case kArchiveReadNextHeader:
    archiveReadNextHeader(reply_port_id, archive);
    break;
  case kArchiveReadDataBlock:
    archiveReadDataBlock(reply_port_id, archive);
    break;
  case kArchiveReadDataSkip:
    archiveReadDataSkip(reply_port_id, archive);
    break;
  case kArchiveReadClose:
    archiveReadClose(reply_port_id, archive);
    break;
  case kArchiveReadFree:
    archiveReadFree(reply_port_id, archive);
    break;
  default:
    postInvalidArgument(reply_port_id, "Invalid request id %d.", request_type);
    break;
  }
}

/**
 * Checks if [handle] represents an error and, if so, propagates it to Dart.
 * Otherwise, returns [handle].
 */
static Dart_Handle handleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) Dart_PropagateError(handle);
  return handle;
}

/**
 * A function exposed to Dart that creates a [ServicePort] for two-way
 * communication between Dart and C.
 *
 * Takes no arguments and returns a [ServicePort].
 */
static void archiveServicePort(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_SetReturnValue(arguments, Dart_Null());
  Dart_Port service_port =
      Dart_NewNativePort("ArchiveService", archiveDispatch, false);
  if (service_port != ILLEGAL_PORT) {
    Dart_Handle send_port = handleError(Dart_NewSendPort(service_port));
    Dart_SetReturnValue(arguments, send_port);
  }
  Dart_ExitScope();
}

/**
 * A struct representing a function exposed to Dart and the name under which it
 * can be looked up.
 */
struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

/** The list of functions exposed to Dart. */
struct FunctionLookup function_list[] = {
  {"Archive_ServicePort", archiveServicePort},
  {NULL, NULL}
};

/**
 * Resolves a Dart name as provided in a `native` declaration and returns the
 * C function that should be invoked for that name.
 */
static Dart_NativeFunction resolveName(Dart_Handle name, int argc) {
  if (!Dart_IsString8(name)) return NULL;
  Dart_EnterScope();
  const char* cname;
  handleError(Dart_StringToCString(name, &cname));

  Dart_NativeFunction result = NULL;
  int i;
  for (i = 0; function_list[i].name != NULL; ++i) {
    if (strcmp(function_list[i].name, cname) == 0) {
      result = function_list[i].function;
      break;
    }
  }
  Dart_ExitScope();
  return result;
}

/** Initializes the C extension. */
DART_EXPORT Dart_Handle dart_archive_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library)) return parent_library;

  Dart_Handle result_code = Dart_SetNativeResolver(parent_library, resolveName);
  if (Dart_IsError(result_code)) return result_code;

  return Dart_Null();
}
