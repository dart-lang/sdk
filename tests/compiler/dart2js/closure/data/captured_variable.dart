// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*readParameterInClosure:*/
readParameterInClosure(/**/ parameter) {
  /*captured=[parameter],free=[parameter]*/ func() => parameter;
  return func;
}

/*writeParameterInClosure:boxed=[parameter],captured=[parameter],requiresBox*/
writeParameterInClosure(/*boxed*/ parameter) {
  /*boxed=[parameter],captured=[parameter],free=[box,parameter]*/ func() {
    parameter = 42;
  }

  return func;
}

/*readLocalInClosure:*/
readLocalInClosure(/**/ parameter) {
  var /**/ local = parameter;
  /*captured=[local],free=[local]*/ func() => local;
  return func;
}

/*writeLocalInClosure:boxed=[local],captured=[local],requiresBox*/
writeLocalInClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  /*boxed=[local],captured=[local],free=[box,local]*/ func() {
    local = 42;
  }

  return func;
}

main() {
  readParameterInClosure(null);
  writeParameterInClosure(null);
  readLocalInClosure(null);
  writeLocalInClosure(null);
}
