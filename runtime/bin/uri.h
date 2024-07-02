// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_URI_H_
#define RUNTIME_BIN_URI_H_

#include <memory>
#include "platform/utils.h"

namespace dart {

class ParsedUri {
 public:
  CStringUniquePtr scheme;
  CStringUniquePtr userinfo;
  CStringUniquePtr host;
  CStringUniquePtr port;
  CStringUniquePtr path;
  CStringUniquePtr query;
  CStringUniquePtr fragment;
};

// Parses a uri into its parts.
//
// Returns nullptr if the parse fails.
std::unique_ptr<ParsedUri> ParseUri(const char* uri);

// Resolves some reference uri with respect to a base uri.
//
// Returns nullptr if the resolve fails.
CStringUniquePtr ResolveUri(const char* ref_uri, const char* base_uri);

}  // namespace dart

#endif  // RUNTIME_BIN_URI_H_
