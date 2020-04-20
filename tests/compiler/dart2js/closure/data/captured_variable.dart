// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: boxedLoopVariableExample:*/
boxedLoopVariableExample() {
  var input = [1, 2, 3];
  var fs = [];
  for (var /*boxed*/ x in input) {
    fs.add(/*fields=[box0],free=[box0,x]*/ () {
      return x;
    });
    x++;
  }
  return fs;
}

/*member: readParameterInAnonymousClosure:*/
readParameterInAnonymousClosure(/**/ parameter) {
  return /*fields=[parameter],free=[parameter]*/ () => parameter;
}

/*member: readParameterInClosure:*/
readParameterInClosure(/**/ parameter) {
  /*fields=[parameter],free=[parameter]*/ func() => parameter;
  return func;
}

/*member: writeParameterInAnonymousClosure:box=(box0 which holds [parameter])*/
writeParameterInAnonymousClosure(/*boxed*/ parameter) {
  return /*fields=[box0],free=[box0,parameter]*/ () {
    parameter = 42;
  };
}

/*member: writeParameterInClosure:box=(box0 which holds [parameter])*/
writeParameterInClosure(/*boxed*/ parameter) {
  /*fields=[box0],free=[box0,parameter]*/ func() {
    parameter = 43;
  }

  return func;
}

/*member: readLocalInAnonymousClosure:*/
readLocalInAnonymousClosure(/**/ parameter) {
  var /**/ local = parameter;
  return /*fields=[local],free=[local]*/ () => local;
}

/*member: readLocalInClosure:*/
readLocalInClosure(/**/ parameter) {
  var /**/ local = parameter;
  /*fields=[local],free=[local]*/ func() => local;
  return func;
}

/*member: writeLocalInAnonymousClosure:box=(box0 which holds [local])*/
writeLocalInAnonymousClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  return /*fields=[box0],free=[box0,local]*/ () {
    local = 44;
  };
}

/*member: writeLocalInClosure:box=(box0 which holds [local])*/
writeLocalInClosure(/**/ parameter) {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*boxed*/ local = parameter;
  /*fields=[box0],free=[box0,local]*/ func() {
    local = 45;
  }

  return func;
}

/*member: Foo.:hasThis*/
class Foo {
  int /*member: Foo.bar:hasThis*/ bar = 4;

  /*member: Foo.baz:hasThis*/ baz() {
    /*fields=[this],free=[this],hasThis*/ func() => bar;
    return func;
  }
}

/*member: Repro.:hasThis*/
class Repro {
  /*member: Repro.qux:hasThis*/ qux() {
    /*fields=[this],free=[this],hasThis*/ threeNested(foo) =>
        /*fields=[this],free=[this],hasThis*/ (bar) => someFunction();
    return threeNested;
  }

  /*member: Repro.someFunction:hasThis*/ someFunction() => 3;
}

main() {
  boxedLoopVariableExample();
  readParameterInAnonymousClosure(null);
  readParameterInClosure(null);
  writeParameterInAnonymousClosure(null);
  writeParameterInClosure(null);
  readLocalInAnonymousClosure(null);
  readLocalInClosure(null);
  writeLocalInAnonymousClosure(null);
  writeLocalInClosure(null);
  new Foo().baz();
  new Repro().qux();
}
