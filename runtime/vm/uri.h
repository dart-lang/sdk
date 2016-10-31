// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_URI_H_
#define RUNTIME_VM_URI_H_

#include "platform/utils.h"
#include "vm/globals.h"

namespace dart {

struct ParsedUri {
  const char* scheme;
  const char* userinfo;
  const char* host;
  const char* port;
  const char* path;
  const char* query;
  const char* fragment;
};

// Parses a uri into its parts.  Returns false if the parse fails.
bool ParseUri(const char* uri, ParsedUri* parsed_uri);

// Resolves some reference uri with respect to a base uri.
bool ResolveUri(const char* ref_uri,
                const char* base_uri,
                const char** target_uri);

}  // namespace dart

#endif  // RUNTIME_VM_URI_H_
