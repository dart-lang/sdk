// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef LIB_REGEXP_JSC_H_
#define LIB_REGEXP_JSC_H_

#include "vm/object.h"


namespace dart {

class Jscre : public AllStatic {
 public:
  static RawJSRegExp* Compile(const String& pattern,
                              bool multi_line,
                              bool ignore_case);
  static RawArray* Execute(const JSRegExp& regex,
                           const String& str,
                           intptr_t index);
};

}  // namespace dart

#endif  // LIB_REGEXP_JSC_H_
