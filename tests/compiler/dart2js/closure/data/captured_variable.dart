// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*readParameterInAnonymousClosure:*/
readParameterInAnonymousClosure(/**/ parameter) {
  return /*captured=[parameter],free=[parameter]*/ () => parameter;
}

/*readParameterInClosure:*/
readParameterInClosure(/**/ parameter) {
  /*captured=[parameter],free=[parameter]*/ func() => parameter;
  return func;
}

/*writeParameterInAnonymousClosure:boxed=[parameter],captured=[parameter],requiresBox*/
writeParameterInAnonymousClosure(/*boxed*/ parameter) {
  return /*boxed=[parameter],captured=[parameter],free=[box,parameter]*/ () {
    parameter = 42;
  };
}

/*writeParameterInClosure:boxed=[parameter],captured=[parameter],requiresBox*/
writeParameterInClosure(/*boxed*/ parameter) {
  /*boxed=[parameter],captured=[parameter],free=[box,parameter]*/ func() {
    parameter = 42;
  }

  return func;
}

/*readLocalInAnonymousClosure:*/
readLocalInAnonymousClosure(/**/ parameter) {
  var /**/ local = parameter;
  return /*captured=[local],free=[local]*/ () => local;
}

/*readLocalInClosure:*/
readLocalInClosure(/**/ parameter) {
  var /**/ local = parameter;
  /*captured=[local],free=[local]*/ func() => local;
  return func;
}

/*writeLocalInAnonymousClosure:boxed=[local],captured=[local],requiresBox*/
writeLocalInAnonymousClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  return /*boxed=[local],captured=[local],free=[box,local]*/ () {
    local = 42;
  };
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
  readParameterInAnonymousClosure(null);
  readParameterInClosure(null);
  writeParameterInAnonymousClosure(null);
  writeParameterInClosure(null);
  readLocalInAnonymousClosure(null);
  readLocalInClosure(null);
  writeLocalInAnonymousClosure(null);
  writeLocalInClosure(null);
}
