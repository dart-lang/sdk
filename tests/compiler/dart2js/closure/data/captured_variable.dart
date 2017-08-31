// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*readParameterInAnonymousClosure:*/
readParameterInAnonymousClosure(/**/ parameter) {
  return /*free=[parameter]*/ () => parameter;
}

/*readParameterInClosure:*/
readParameterInClosure(/**/ parameter) {
  /*free=[parameter]*/ func() => parameter;
  return func;
}

/*writeParameterInAnonymousClosure:box=(box0 which holds [parameter])*/
writeParameterInAnonymousClosure(/*boxed*/ parameter) {
  return /*free=[box0,parameter]*/ () {
    parameter = 42;
  };
}

/*writeParameterInClosure:box=(box0 which holds [parameter])*/
writeParameterInClosure(/*boxed*/ parameter) {
  /*free=[box0,parameter]*/ func() {
    parameter = 43;
  }

  return func;
}

/*readLocalInAnonymousClosure:*/
readLocalInAnonymousClosure(/**/ parameter) {
  var /**/ local = parameter;
  return /*free=[local]*/ () => local;
}

/*readLocalInClosure:*/
readLocalInClosure(/**/ parameter) {
  var /**/ local = parameter;
  /*free=[local]*/ func() => local;
  return func;
}

/*writeLocalInAnonymousClosure:box=(box0 which holds [local])*/
writeLocalInAnonymousClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  return /*free=[box0,local]*/ () {
    local = 44;
  };
}

/*writeLocalInClosure:box=(box0 which holds [local])*/
writeLocalInClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  /*free=[box0,local]*/ func() {
    local = 45;
  }

  return func;
}

class Foo {
  int /*Foo.bar:hasThis*/ bar = 4;

  /*Foo.baz:hasThis*/ baz() {
    /*free=[this],hasThis*/ func() => bar;
    return func;
  }
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
  new Foo().baz();
}
