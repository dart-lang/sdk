// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

readParameterInFinally(/*inTry*/ parameter) {
  try {
    if (parameter) {
      throw '';
    }
  } finally {}
}

writeParameterInFinally(/*inTry*/ parameter) {
  try {
    parameter = 42;
    throw '';
  } finally {}
}

readLocalInFinally(/**/ parameter) {
  var /*inTry*/ local = parameter;
  try {
    if (local) {
      throw '';
    }
  } finally {}
}

writeLocalInFinally(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*inTry*/ local = parameter;
  try {
    local = 42;
    throw '';
  } finally {}
}

main() {
  readParameterInFinally(null);
  writeParameterInFinally(null);
  readLocalInFinally(null);
  writeLocalInFinally(null);
}
