// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: readParameterInAnonymousClosure:*/
readParameterInAnonymousClosure(/**/ parameter) {
  return /*fields=[parameter],free=[parameter]*/ () => parameter;
}

/*element: readParameterInClosure:*/
readParameterInClosure(/**/ parameter) {
  /*fields=[parameter],free=[parameter]*/ func() => parameter;
  return func;
}

/*element: writeParameterInAnonymousClosure:box=(box0 which holds [parameter])*/
writeParameterInAnonymousClosure(/*boxed*/ parameter) {
  return /*fields=[box0],free=[box0,parameter]*/ () {
    parameter = 42;
  };
}

/*element: writeParameterInClosure:box=(box0 which holds [parameter])*/
writeParameterInClosure(/*boxed*/ parameter) {
  /*fields=[box0],free=[box0,parameter]*/ func() {
    parameter = 43;
  }

  return func;
}

/*element: readLocalInAnonymousClosure:*/
readLocalInAnonymousClosure(/**/ parameter) {
  var /**/ local = parameter;
  return /*fields=[local],free=[local]*/ () => local;
}

/*element: readLocalInClosure:*/
readLocalInClosure(/**/ parameter) {
  var /**/ local = parameter;
  /*fields=[local],free=[local]*/ func() => local;
  return func;
}

/*element: writeLocalInAnonymousClosure:box=(box0 which holds [local])*/
writeLocalInAnonymousClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  return /*fields=[box0],free=[box0,local]*/ () {
    local = 44;
  };
}

/*element: writeLocalInClosure:box=(box0 which holds [local])*/
writeLocalInClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  /*fields=[box0],free=[box0,local]*/ func() {
    local = 45;
  }

  return func;
}

/*element: Foo.:hasThis*/
class Foo {
  int /*element: Foo.bar:hasThis*/ bar = 4;

  /*element: Foo.baz:hasThis*/ baz() {
    /*fields=[this],free=[this],hasThis*/ func() => bar;
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
