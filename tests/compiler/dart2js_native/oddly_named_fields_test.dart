// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_helper';

// JavaScript reserved words:
//
// break
// case
// catch
// class
// const
// continue
// debugger
// default
// delete
// do
// else
// enum
// export
// extends
// false
// finally
// for
// function
// if
// implements
// import
// in
// instanceof
// interface
// let
// new
// null
// package
// private
// protected
// public
// return
// static
// super
// switch
// this
// throw
// true
// try
// typeof
// var
// void
// while
// with
// yield
//
// Funny thing in JavaScript: there are two syntactic categories:
// "Identifier" and "IdentifierName".  The latter includes reserved
// words.  This is legal JavaScript according to ECMA-262.5:
//
//    this.default
//
// See section 11.2 "Left-Hand-Side Expressions" which states that a
// "MemberExpression" includes: "MemberExpression . IdentifierName".

@Native("NativeClassWithOddNames")
class NativeClassWithOddNames {
  @JSName('break') bool breakValue;
  @JSName('case') bool caseValue;
  @JSName('catch') bool catchValue;
  @JSName('class') bool classValue;
  @JSName('const') bool constValue;
  @JSName('continue') bool continueValue;
  @JSName('debugger') bool debuggerValue;
  @JSName('default') bool defaultValue;
  @JSName('delete') bool deleteValue;
  @JSName('do') bool doValue;
  @JSName('else') bool elseValue;
  @JSName('enum') bool enumValue;
  @JSName('export') bool exportValue;
  @JSName('extends') bool extendsValue;
  @JSName('false') bool falseValue;
  @JSName('finally') bool finallyValue;
  @JSName('for') bool forValue;
  @JSName('function') bool functionValue;
  @JSName('if') bool ifValue;
  @JSName('implements') bool implementsValue;
  @JSName('import') bool importValue;
  @JSName('in') bool inValue;
  @JSName('instanceof') bool instanceofValue;
  @JSName('interface') bool interfaceValue;
  @JSName('let') bool letValue;
  @JSName('new') bool newValue;
  @JSName('null') bool nullValue;
  @JSName('package') bool packageValue;
  @JSName('private') bool privateValue;
  @JSName('protected') bool protectedValue;
  @JSName('public') bool publicValue;
  @JSName('return') bool returnValue;
  @JSName('static') bool staticValue;
  @JSName('super') bool superValue;
  @JSName('switch') bool switchValue;
  @JSName('this') bool thisValue;
  @JSName('throw') bool throwValue;
  @JSName('true') bool trueValue;
  @JSName('try') bool tryValue;
  @JSName('typeof') bool typeofValue;
  @JSName('var') bool varValue;
  @JSName('void') bool voidValue;
  @JSName('while') bool whileValue;
  @JSName('with') bool withValue;
  @JSName('yield') bool yieldValue;

  void testMyFields() {

    if (breakValue != null) throw 'incorrect initialization of "breakValue"';
    breakValue = true;
    if (!breakValue) throw 'incorrect value in "breakValue"';
    breakValue = false;
    if (breakValue) throw 'incorrect value in "breakValue"';

    if (caseValue != null) throw 'incorrect initialization of "caseValue"';
    caseValue = true;
    if (!caseValue) throw 'incorrect value in "caseValue"';
    caseValue = false;
    if (caseValue) throw 'incorrect value in "caseValue"';

    if (catchValue != null) throw 'incorrect initialization of "catchValue"';
    catchValue = true;
    if (!catchValue) throw 'incorrect value in "catchValue"';
    catchValue = false;
    if (catchValue) throw 'incorrect value in "catchValue"';

    if (classValue != null) throw 'incorrect initialization of "classValue"';
    classValue = true;
    if (!classValue) throw 'incorrect value in "classValue"';
    classValue = false;
    if (classValue) throw 'incorrect value in "classValue"';

    if (constValue != null) throw 'incorrect initialization of "constValue"';
    constValue = true;
    if (!constValue) throw 'incorrect value in "constValue"';
    constValue = false;
    if (constValue) throw 'incorrect value in "constValue"';

    if (continueValue != null)
      throw 'incorrect initialization of "continueValue"';
    continueValue = true;
    if (!continueValue) throw 'incorrect value in "continueValue"';
    continueValue = false;
    if (continueValue) throw 'incorrect value in "continueValue"';

    if (debuggerValue != null)
      throw 'incorrect initialization of "debuggerValue"';
    debuggerValue = true;
    if (!debuggerValue) throw 'incorrect value in "debuggerValue"';
    debuggerValue = false;
    if (debuggerValue) throw 'incorrect value in "debuggerValue"';

    if (defaultValue != null)
      throw 'incorrect initialization of "defaultValue"';
    defaultValue = true;
    if (!defaultValue) throw 'incorrect value in "defaultValue"';
    defaultValue = false;
    if (defaultValue) throw 'incorrect value in "defaultValue"';

    if (deleteValue != null) throw 'incorrect initialization of "deleteValue"';
    deleteValue = true;
    if (!deleteValue) throw 'incorrect value in "deleteValue"';
    deleteValue = false;
    if (deleteValue) throw 'incorrect value in "deleteValue"';

    if (doValue != null) throw 'incorrect initialization of "doValue"';
    doValue = true;
    if (!doValue) throw 'incorrect value in "doValue"';
    doValue = false;
    if (doValue) throw 'incorrect value in "doValue"';

    if (elseValue != null) throw 'incorrect initialization of "elseValue"';
    elseValue = true;
    if (!elseValue) throw 'incorrect value in "elseValue"';
    elseValue = false;
    if (elseValue) throw 'incorrect value in "elseValue"';

    if (enumValue != null) throw 'incorrect initialization of "enumValue"';
    enumValue = true;
    if (!enumValue) throw 'incorrect value in "enumValue"';
    enumValue = false;
    if (enumValue) throw 'incorrect value in "enumValue"';

    if (exportValue != null) throw 'incorrect initialization of "exportValue"';
    exportValue = true;
    if (!exportValue) throw 'incorrect value in "exportValue"';
    exportValue = false;
    if (exportValue) throw 'incorrect value in "exportValue"';

    if (extendsValue != null)
      throw 'incorrect initialization of "extendsValue"';
    extendsValue = true;
    if (!extendsValue) throw 'incorrect value in "extendsValue"';
    extendsValue = false;
    if (extendsValue) throw 'incorrect value in "extendsValue"';

    if (falseValue != null) throw 'incorrect initialization of "falseValue"';
    falseValue = true;
    if (!falseValue) throw 'incorrect value in "falseValue"';
    falseValue = false;
    if (falseValue) throw 'incorrect value in "falseValue"';

    if (finallyValue != null)
      throw 'incorrect initialization of "finallyValue"';
    finallyValue = true;
    if (!finallyValue) throw 'incorrect value in "finallyValue"';
    finallyValue = false;
    if (finallyValue) throw 'incorrect value in "finallyValue"';

    if (forValue != null) throw 'incorrect initialization of "forValue"';
    forValue = true;
    if (!forValue) throw 'incorrect value in "forValue"';
    forValue = false;
    if (forValue) throw 'incorrect value in "forValue"';

    if (functionValue != null)
      throw 'incorrect initialization of "functionValue"';
    functionValue = true;
    if (!functionValue) throw 'incorrect value in "functionValue"';
    functionValue = false;
    if (functionValue) throw 'incorrect value in "functionValue"';

    if (ifValue != null) throw 'incorrect initialization of "ifValue"';
    ifValue = true;
    if (!ifValue) throw 'incorrect value in "ifValue"';
    ifValue = false;
    if (ifValue) throw 'incorrect value in "ifValue"';

    if (implementsValue != null)
      throw 'incorrect initialization of "implementsValue"';
    implementsValue = true;
    if (!implementsValue) throw 'incorrect value in "implementsValue"';
    implementsValue = false;
    if (implementsValue) throw 'incorrect value in "implementsValue"';

    if (importValue != null) throw 'incorrect initialization of "importValue"';
    importValue = true;
    if (!importValue) throw 'incorrect value in "importValue"';
    importValue = false;
    if (importValue) throw 'incorrect value in "importValue"';

    if (inValue != null) throw 'incorrect initialization of "inValue"';
    inValue = true;
    if (!inValue) throw 'incorrect value in "inValue"';
    inValue = false;
    if (inValue) throw 'incorrect value in "inValue"';

    if (instanceofValue != null)
      throw 'incorrect initialization of "instanceofValue"';
    instanceofValue = true;
    if (!instanceofValue) throw 'incorrect value in "instanceofValue"';
    instanceofValue = false;
    if (instanceofValue) throw 'incorrect value in "instanceofValue"';

    if (interfaceValue != null)
      throw 'incorrect initialization of "interfaceValue"';
    interfaceValue = true;
    if (!interfaceValue) throw 'incorrect value in "interfaceValue"';
    interfaceValue = false;
    if (interfaceValue) throw 'incorrect value in "interfaceValue"';

    if (letValue != null) throw 'incorrect initialization of "letValue"';
    letValue = true;
    if (!letValue) throw 'incorrect value in "letValue"';
    letValue = false;
    if (letValue) throw 'incorrect value in "letValue"';

    if (newValue != null) throw 'incorrect initialization of "newValue"';
    newValue = true;
    if (!newValue) throw 'incorrect value in "newValue"';
    newValue = false;
    if (newValue) throw 'incorrect value in "newValue"';

    if (nullValue != null) throw 'incorrect initialization of "nullValue"';
    nullValue = true;
    if (!nullValue) throw 'incorrect value in "nullValue"';
    nullValue = false;
    if (nullValue) throw 'incorrect value in "nullValue"';

    if (packageValue != null)
      throw 'incorrect initialization of "packageValue"';
    packageValue = true;
    if (!packageValue) throw 'incorrect value in "packageValue"';
    packageValue = false;
    if (packageValue) throw 'incorrect value in "packageValue"';

    if (privateValue != null)
      throw 'incorrect initialization of "privateValue"';
    privateValue = true;
    if (!privateValue) throw 'incorrect value in "privateValue"';
    privateValue = false;
    if (privateValue) throw 'incorrect value in "privateValue"';

    if (protectedValue != null)
      throw 'incorrect initialization of "protectedValue"';
    protectedValue = true;
    if (!protectedValue) throw 'incorrect value in "protectedValue"';
    protectedValue = false;
    if (protectedValue) throw 'incorrect value in "protectedValue"';

    if (publicValue != null) throw 'incorrect initialization of "publicValue"';
    publicValue = true;
    if (!publicValue) throw 'incorrect value in "publicValue"';
    publicValue = false;
    if (publicValue) throw 'incorrect value in "publicValue"';

    if (returnValue != null) throw 'incorrect initialization of "returnValue"';
    returnValue = true;
    if (!returnValue) throw 'incorrect value in "returnValue"';
    returnValue = false;
    if (returnValue) throw 'incorrect value in "returnValue"';

    if (staticValue != null) throw 'incorrect initialization of "staticValue"';
    staticValue = true;
    if (!staticValue) throw 'incorrect value in "staticValue"';
    staticValue = false;
    if (staticValue) throw 'incorrect value in "staticValue"';

    if (superValue != null) throw 'incorrect initialization of "superValue"';
    superValue = true;
    if (!superValue) throw 'incorrect value in "superValue"';
    superValue = false;
    if (superValue) throw 'incorrect value in "superValue"';

    if (switchValue != null) throw 'incorrect initialization of "switchValue"';
    switchValue = true;
    if (!switchValue) throw 'incorrect value in "switchValue"';
    switchValue = false;
    if (switchValue) throw 'incorrect value in "switchValue"';

    if (thisValue != null) throw 'incorrect initialization of "thisValue"';
    thisValue = true;
    if (!thisValue) throw 'incorrect value in "thisValue"';
    thisValue = false;
    if (thisValue) throw 'incorrect value in "thisValue"';

    if (throwValue != null) throw 'incorrect initialization of "throwValue"';
    throwValue = true;
    if (!throwValue) throw 'incorrect value in "throwValue"';
    throwValue = false;
    if (throwValue) throw 'incorrect value in "throwValue"';

    if (trueValue != null) throw 'incorrect initialization of "trueValue"';
    trueValue = true;
    if (!trueValue) throw 'incorrect value in "trueValue"';
    trueValue = false;
    if (trueValue) throw 'incorrect value in "trueValue"';

    if (tryValue != null) throw 'incorrect initialization of "tryValue"';
    tryValue = true;
    if (!tryValue) throw 'incorrect value in "tryValue"';
    tryValue = false;
    if (tryValue) throw 'incorrect value in "tryValue"';

    if (typeofValue != null) throw 'incorrect initialization of "typeofValue"';
    typeofValue = true;
    if (!typeofValue) throw 'incorrect value in "typeofValue"';
    typeofValue = false;
    if (typeofValue) throw 'incorrect value in "typeofValue"';

    if (varValue != null) throw 'incorrect initialization of "varValue"';
    varValue = true;
    if (!varValue) throw 'incorrect value in "varValue"';
    varValue = false;
    if (varValue) throw 'incorrect value in "varValue"';

    if (voidValue != null) throw 'incorrect initialization of "voidValue"';
    voidValue = true;
    if (!voidValue) throw 'incorrect value in "voidValue"';
    voidValue = false;
    if (voidValue) throw 'incorrect value in "voidValue"';

    if (whileValue != null) throw 'incorrect initialization of "whileValue"';
    whileValue = true;
    if (!whileValue) throw 'incorrect value in "whileValue"';
    whileValue = false;
    if (whileValue) throw 'incorrect value in "whileValue"';

    if (withValue != null) throw 'incorrect initialization of "withValue"';
    withValue = true;
    if (!withValue) throw 'incorrect value in "withValue"';
    withValue = false;
    if (withValue) throw 'incorrect value in "withValue"';

    if (yieldValue != null) throw 'incorrect initialization of "yieldValue"';
    yieldValue = true;
    if (!yieldValue) throw 'incorrect value in "yieldValue"';
    yieldValue = false;
    if (yieldValue) throw 'incorrect value in "yieldValue"';

  }
}

class ClassWithOddNames {
  bool breakValue;
  bool caseValue;
  bool catchValue;
  bool classValue;
  bool constValue;
  bool continueValue;
  bool debuggerValue;
  bool defaultValue;
  bool deleteValue;
  bool doValue;
  bool elseValue;
  bool enumValue;
  bool exportValue;
  bool extendsValue;
  bool falseValue;
  bool finallyValue;
  bool forValue;
  bool functionValue;
  bool ifValue;
  bool implementsValue;
  bool importValue;
  bool inValue;
  bool instanceofValue;
  bool interfaceValue;
  bool letValue;
  bool newValue;
  bool nullValue;
  bool packageValue;
  bool privateValue;
  bool protectedValue;
  bool publicValue;
  bool returnValue;
  bool staticValue;
  bool superValue;
  bool switchValue;
  bool thisValue;
  bool throwValue;
  bool trueValue;
  bool tryValue;
  bool typeofValue;
  bool varValue;
  bool voidValue;
  bool whileValue;
  bool withValue;
  bool yieldValue;

  void testMyFields() {

    if (breakValue != null) throw 'incorrect initialization of "breakValue"';
    breakValue = true;
    if (!breakValue) throw 'incorrect value in "breakValue"';
    breakValue = false;
    if (breakValue) throw 'incorrect value in "breakValue"';

    if (caseValue != null) throw 'incorrect initialization of "caseValue"';
    caseValue = true;
    if (!caseValue) throw 'incorrect value in "caseValue"';
    caseValue = false;
    if (caseValue) throw 'incorrect value in "caseValue"';

    if (catchValue != null) throw 'incorrect initialization of "catchValue"';
    catchValue = true;
    if (!catchValue) throw 'incorrect value in "catchValue"';
    catchValue = false;
    if (catchValue) throw 'incorrect value in "catchValue"';

    if (classValue != null) throw 'incorrect initialization of "classValue"';
    classValue = true;
    if (!classValue) throw 'incorrect value in "classValue"';
    classValue = false;
    if (classValue) throw 'incorrect value in "classValue"';

    if (constValue != null) throw 'incorrect initialization of "constValue"';
    constValue = true;
    if (!constValue) throw 'incorrect value in "constValue"';
    constValue = false;
    if (constValue) throw 'incorrect value in "constValue"';

    if (continueValue != null)
      throw 'incorrect initialization of "continueValue"';
    continueValue = true;
    if (!continueValue) throw 'incorrect value in "continueValue"';
    continueValue = false;
    if (continueValue) throw 'incorrect value in "continueValue"';

    if (debuggerValue != null)
      throw 'incorrect initialization of "debuggerValue"';
    debuggerValue = true;
    if (!debuggerValue) throw 'incorrect value in "debuggerValue"';
    debuggerValue = false;
    if (debuggerValue) throw 'incorrect value in "debuggerValue"';

    if (defaultValue != null)
      throw 'incorrect initialization of "defaultValue"';
    defaultValue = true;
    if (!defaultValue) throw 'incorrect value in "defaultValue"';
    defaultValue = false;
    if (defaultValue) throw 'incorrect value in "defaultValue"';

    if (deleteValue != null) throw 'incorrect initialization of "deleteValue"';
    deleteValue = true;
    if (!deleteValue) throw 'incorrect value in "deleteValue"';
    deleteValue = false;
    if (deleteValue) throw 'incorrect value in "deleteValue"';

    if (doValue != null) throw 'incorrect initialization of "doValue"';
    doValue = true;
    if (!doValue) throw 'incorrect value in "doValue"';
    doValue = false;
    if (doValue) throw 'incorrect value in "doValue"';

    if (elseValue != null) throw 'incorrect initialization of "elseValue"';
    elseValue = true;
    if (!elseValue) throw 'incorrect value in "elseValue"';
    elseValue = false;
    if (elseValue) throw 'incorrect value in "elseValue"';

    if (enumValue != null) throw 'incorrect initialization of "enumValue"';
    enumValue = true;
    if (!enumValue) throw 'incorrect value in "enumValue"';
    enumValue = false;
    if (enumValue) throw 'incorrect value in "enumValue"';

    if (exportValue != null) throw 'incorrect initialization of "exportValue"';
    exportValue = true;
    if (!exportValue) throw 'incorrect value in "exportValue"';
    exportValue = false;
    if (exportValue) throw 'incorrect value in "exportValue"';

    if (extendsValue != null)
      throw 'incorrect initialization of "extendsValue"';
    extendsValue = true;
    if (!extendsValue) throw 'incorrect value in "extendsValue"';
    extendsValue = false;
    if (extendsValue) throw 'incorrect value in "extendsValue"';

    if (falseValue != null) throw 'incorrect initialization of "falseValue"';
    falseValue = true;
    if (!falseValue) throw 'incorrect value in "falseValue"';
    falseValue = false;
    if (falseValue) throw 'incorrect value in "falseValue"';

    if (finallyValue != null)
      throw 'incorrect initialization of "finallyValue"';
    finallyValue = true;
    if (!finallyValue) throw 'incorrect value in "finallyValue"';
    finallyValue = false;
    if (finallyValue) throw 'incorrect value in "finallyValue"';

    if (forValue != null) throw 'incorrect initialization of "forValue"';
    forValue = true;
    if (!forValue) throw 'incorrect value in "forValue"';
    forValue = false;
    if (forValue) throw 'incorrect value in "forValue"';

    if (functionValue != null)
      throw 'incorrect initialization of "functionValue"';
    functionValue = true;
    if (!functionValue) throw 'incorrect value in "functionValue"';
    functionValue = false;
    if (functionValue) throw 'incorrect value in "functionValue"';

    if (ifValue != null) throw 'incorrect initialization of "ifValue"';
    ifValue = true;
    if (!ifValue) throw 'incorrect value in "ifValue"';
    ifValue = false;
    if (ifValue) throw 'incorrect value in "ifValue"';

    if (implementsValue != null)
      throw 'incorrect initialization of "implementsValue"';
    implementsValue = true;
    if (!implementsValue) throw 'incorrect value in "implementsValue"';
    implementsValue = false;
    if (implementsValue) throw 'incorrect value in "implementsValue"';

    if (importValue != null) throw 'incorrect initialization of "importValue"';
    importValue = true;
    if (!importValue) throw 'incorrect value in "importValue"';
    importValue = false;
    if (importValue) throw 'incorrect value in "importValue"';

    if (inValue != null) throw 'incorrect initialization of "inValue"';
    inValue = true;
    if (!inValue) throw 'incorrect value in "inValue"';
    inValue = false;
    if (inValue) throw 'incorrect value in "inValue"';

    if (instanceofValue != null)
      throw 'incorrect initialization of "instanceofValue"';
    instanceofValue = true;
    if (!instanceofValue) throw 'incorrect value in "instanceofValue"';
    instanceofValue = false;
    if (instanceofValue) throw 'incorrect value in "instanceofValue"';

    if (interfaceValue != null)
      throw 'incorrect initialization of "interfaceValue"';
    interfaceValue = true;
    if (!interfaceValue) throw 'incorrect value in "interfaceValue"';
    interfaceValue = false;
    if (interfaceValue) throw 'incorrect value in "interfaceValue"';

    if (letValue != null) throw 'incorrect initialization of "letValue"';
    letValue = true;
    if (!letValue) throw 'incorrect value in "letValue"';
    letValue = false;
    if (letValue) throw 'incorrect value in "letValue"';

    if (newValue != null) throw 'incorrect initialization of "newValue"';
    newValue = true;
    if (!newValue) throw 'incorrect value in "newValue"';
    newValue = false;
    if (newValue) throw 'incorrect value in "newValue"';

    if (nullValue != null) throw 'incorrect initialization of "nullValue"';
    nullValue = true;
    if (!nullValue) throw 'incorrect value in "nullValue"';
    nullValue = false;
    if (nullValue) throw 'incorrect value in "nullValue"';

    if (packageValue != null)
      throw 'incorrect initialization of "packageValue"';
    packageValue = true;
    if (!packageValue) throw 'incorrect value in "packageValue"';
    packageValue = false;
    if (packageValue) throw 'incorrect value in "packageValue"';

    if (privateValue != null)
      throw 'incorrect initialization of "privateValue"';
    privateValue = true;
    if (!privateValue) throw 'incorrect value in "privateValue"';
    privateValue = false;
    if (privateValue) throw 'incorrect value in "privateValue"';

    if (protectedValue != null)
      throw 'incorrect initialization of "protectedValue"';
    protectedValue = true;
    if (!protectedValue) throw 'incorrect value in "protectedValue"';
    protectedValue = false;
    if (protectedValue) throw 'incorrect value in "protectedValue"';

    if (publicValue != null) throw 'incorrect initialization of "publicValue"';
    publicValue = true;
    if (!publicValue) throw 'incorrect value in "publicValue"';
    publicValue = false;
    if (publicValue) throw 'incorrect value in "publicValue"';

    if (returnValue != null) throw 'incorrect initialization of "returnValue"';
    returnValue = true;
    if (!returnValue) throw 'incorrect value in "returnValue"';
    returnValue = false;
    if (returnValue) throw 'incorrect value in "returnValue"';

    if (staticValue != null) throw 'incorrect initialization of "staticValue"';
    staticValue = true;
    if (!staticValue) throw 'incorrect value in "staticValue"';
    staticValue = false;
    if (staticValue) throw 'incorrect value in "staticValue"';

    if (superValue != null) throw 'incorrect initialization of "superValue"';
    superValue = true;
    if (!superValue) throw 'incorrect value in "superValue"';
    superValue = false;
    if (superValue) throw 'incorrect value in "superValue"';

    if (switchValue != null) throw 'incorrect initialization of "switchValue"';
    switchValue = true;
    if (!switchValue) throw 'incorrect value in "switchValue"';
    switchValue = false;
    if (switchValue) throw 'incorrect value in "switchValue"';

    if (thisValue != null) throw 'incorrect initialization of "thisValue"';
    thisValue = true;
    if (!thisValue) throw 'incorrect value in "thisValue"';
    thisValue = false;
    if (thisValue) throw 'incorrect value in "thisValue"';

    if (throwValue != null) throw 'incorrect initialization of "throwValue"';
    throwValue = true;
    if (!throwValue) throw 'incorrect value in "throwValue"';
    throwValue = false;
    if (throwValue) throw 'incorrect value in "throwValue"';

    if (trueValue != null) throw 'incorrect initialization of "trueValue"';
    trueValue = true;
    if (!trueValue) throw 'incorrect value in "trueValue"';
    trueValue = false;
    if (trueValue) throw 'incorrect value in "trueValue"';

    if (tryValue != null) throw 'incorrect initialization of "tryValue"';
    tryValue = true;
    if (!tryValue) throw 'incorrect value in "tryValue"';
    tryValue = false;
    if (tryValue) throw 'incorrect value in "tryValue"';

    if (typeofValue != null) throw 'incorrect initialization of "typeofValue"';
    typeofValue = true;
    if (!typeofValue) throw 'incorrect value in "typeofValue"';
    typeofValue = false;
    if (typeofValue) throw 'incorrect value in "typeofValue"';

    if (varValue != null) throw 'incorrect initialization of "varValue"';
    varValue = true;
    if (!varValue) throw 'incorrect value in "varValue"';
    varValue = false;
    if (varValue) throw 'incorrect value in "varValue"';

    if (voidValue != null) throw 'incorrect initialization of "voidValue"';
    voidValue = true;
    if (!voidValue) throw 'incorrect value in "voidValue"';
    voidValue = false;
    if (voidValue) throw 'incorrect value in "voidValue"';

    if (whileValue != null) throw 'incorrect initialization of "whileValue"';
    whileValue = true;
    if (!whileValue) throw 'incorrect value in "whileValue"';
    whileValue = false;
    if (whileValue) throw 'incorrect value in "whileValue"';

    if (withValue != null) throw 'incorrect initialization of "withValue"';
    withValue = true;
    if (!withValue) throw 'incorrect value in "withValue"';
    withValue = false;
    if (withValue) throw 'incorrect value in "withValue"';

    if (yieldValue != null) throw 'incorrect initialization of "yieldValue"';
    yieldValue = true;
    if (!yieldValue) throw 'incorrect value in "yieldValue"';
    yieldValue = false;
    if (yieldValue) throw 'incorrect value in "yieldValue"';

  }
}

/// Called once with an instance of NativeClassWithOddNames making it easy
/// to inline accessors.
testObjectStronglyTyped(object) {
  if (object.breakValue == null)
    throw 'incorrect initialization of "breakValue"';
  object.breakValue = true;
  if (!object.breakValue) throw 'incorrect value in "breakValue"';
  object.breakValue = false;
  if (object.breakValue) throw 'incorrect value in "breakValue"';

  if (object.caseValue == null)
    throw 'incorrect initialization of "caseValue"';
  object.caseValue = true;
  if (!object.caseValue) throw 'incorrect value in "caseValue"';
  object.caseValue = false;
  if (object.caseValue) throw 'incorrect value in "caseValue"';

  if (object.catchValue == null)
    throw 'incorrect initialization of "catchValue"';
  object.catchValue = true;
  if (!object.catchValue) throw 'incorrect value in "catchValue"';
  object.catchValue = false;
  if (object.catchValue) throw 'incorrect value in "catchValue"';

  if (object.classValue == null)
    throw 'incorrect initialization of "classValue"';
  object.classValue = true;
  if (!object.classValue) throw 'incorrect value in "classValue"';
  object.classValue = false;
  if (object.classValue) throw 'incorrect value in "classValue"';

  if (object.constValue == null)
    throw 'incorrect initialization of "constValue"';
  object.constValue = true;
  if (!object.constValue) throw 'incorrect value in "constValue"';
  object.constValue = false;
  if (object.constValue) throw 'incorrect value in "constValue"';

  if (object.continueValue == null)
    throw 'incorrect initialization of "continueValue"';
  object.continueValue = true;
  if (!object.continueValue) throw 'incorrect value in "continueValue"';
  object.continueValue = false;
  if (object.continueValue) throw 'incorrect value in "continueValue"';

  if (object.debuggerValue == null)
    throw 'incorrect initialization of "debuggerValue"';
  object.debuggerValue = true;
  if (!object.debuggerValue) throw 'incorrect value in "debuggerValue"';
  object.debuggerValue = false;
  if (object.debuggerValue) throw 'incorrect value in "debuggerValue"';

  if (object.defaultValue == null)
    throw 'incorrect initialization of "defaultValue"';
  object.defaultValue = true;
  if (!object.defaultValue) throw 'incorrect value in "defaultValue"';
  object.defaultValue = false;
  if (object.defaultValue) throw 'incorrect value in "defaultValue"';

  if (object.deleteValue == null)
    throw 'incorrect initialization of "deleteValue"';
  object.deleteValue = true;
  if (!object.deleteValue) throw 'incorrect value in "deleteValue"';
  object.deleteValue = false;
  if (object.deleteValue) throw 'incorrect value in "deleteValue"';

  if (object.doValue == null)
    throw 'incorrect initialization of "doValue"';
  object.doValue = true;
  if (!object.doValue) throw 'incorrect value in "doValue"';
  object.doValue = false;
  if (object.doValue) throw 'incorrect value in "doValue"';

  if (object.elseValue == null)
    throw 'incorrect initialization of "elseValue"';
  object.elseValue = true;
  if (!object.elseValue) throw 'incorrect value in "elseValue"';
  object.elseValue = false;
  if (object.elseValue) throw 'incorrect value in "elseValue"';

  if (object.enumValue == null)
    throw 'incorrect initialization of "enumValue"';
  object.enumValue = true;
  if (!object.enumValue) throw 'incorrect value in "enumValue"';
  object.enumValue = false;
  if (object.enumValue) throw 'incorrect value in "enumValue"';

  if (object.exportValue == null)
    throw 'incorrect initialization of "exportValue"';
  object.exportValue = true;
  if (!object.exportValue) throw 'incorrect value in "exportValue"';
  object.exportValue = false;
  if (object.exportValue) throw 'incorrect value in "exportValue"';

  if (object.extendsValue == null)
    throw 'incorrect initialization of "extendsValue"';
  object.extendsValue = true;
  if (!object.extendsValue) throw 'incorrect value in "extendsValue"';
  object.extendsValue = false;
  if (object.extendsValue) throw 'incorrect value in "extendsValue"';

  if (object.falseValue == null)
    throw 'incorrect initialization of "falseValue"';
  object.falseValue = true;
  if (!object.falseValue) throw 'incorrect value in "falseValue"';
  object.falseValue = false;
  if (object.falseValue) throw 'incorrect value in "falseValue"';

  if (object.finallyValue == null)
    throw 'incorrect initialization of "finallyValue"';
  object.finallyValue = true;
  if (!object.finallyValue) throw 'incorrect value in "finallyValue"';
  object.finallyValue = false;
  if (object.finallyValue) throw 'incorrect value in "finallyValue"';

  if (object.forValue == null)
    throw 'incorrect initialization of "forValue"';
  object.forValue = true;
  if (!object.forValue) throw 'incorrect value in "forValue"';
  object.forValue = false;
  if (object.forValue) throw 'incorrect value in "forValue"';

  if (object.functionValue == null)
    throw 'incorrect initialization of "functionValue"';
  object.functionValue = true;
  if (!object.functionValue) throw 'incorrect value in "functionValue"';
  object.functionValue = false;
  if (object.functionValue) throw 'incorrect value in "functionValue"';

  if (object.ifValue == null)
    throw 'incorrect initialization of "ifValue"';
  object.ifValue = true;
  if (!object.ifValue) throw 'incorrect value in "ifValue"';
  object.ifValue = false;
  if (object.ifValue) throw 'incorrect value in "ifValue"';

  if (object.implementsValue == null)
    throw 'incorrect initialization of "implementsValue"';
  object.implementsValue = true;
  if (!object.implementsValue) throw 'incorrect value in "implementsValue"';
  object.implementsValue = false;
  if (object.implementsValue) throw 'incorrect value in "implementsValue"';

  if (object.importValue == null)
    throw 'incorrect initialization of "importValue"';
  object.importValue = true;
  if (!object.importValue) throw 'incorrect value in "importValue"';
  object.importValue = false;
  if (object.importValue) throw 'incorrect value in "importValue"';

  if (object.inValue == null)
    throw 'incorrect initialization of "inValue"';
  object.inValue = true;
  if (!object.inValue) throw 'incorrect value in "inValue"';
  object.inValue = false;
  if (object.inValue) throw 'incorrect value in "inValue"';

  if (object.instanceofValue == null)
    throw 'incorrect initialization of "instanceofValue"';
  object.instanceofValue = true;
  if (!object.instanceofValue) throw 'incorrect value in "instanceofValue"';
  object.instanceofValue = false;
  if (object.instanceofValue) throw 'incorrect value in "instanceofValue"';

  if (object.interfaceValue == null)
    throw 'incorrect initialization of "interfaceValue"';
  object.interfaceValue = true;
  if (!object.interfaceValue) throw 'incorrect value in "interfaceValue"';
  object.interfaceValue = false;
  if (object.interfaceValue) throw 'incorrect value in "interfaceValue"';

  if (object.letValue == null)
    throw 'incorrect initialization of "letValue"';
  object.letValue = true;
  if (!object.letValue) throw 'incorrect value in "letValue"';
  object.letValue = false;
  if (object.letValue) throw 'incorrect value in "letValue"';

  if (object.newValue == null)
    throw 'incorrect initialization of "newValue"';
  object.newValue = true;
  if (!object.newValue) throw 'incorrect value in "newValue"';
  object.newValue = false;
  if (object.newValue) throw 'incorrect value in "newValue"';

  if (object.nullValue == null)
    throw 'incorrect initialization of "nullValue"';
  object.nullValue = true;
  if (!object.nullValue) throw 'incorrect value in "nullValue"';
  object.nullValue = false;
  if (object.nullValue) throw 'incorrect value in "nullValue"';

  if (object.packageValue == null)
    throw 'incorrect initialization of "packageValue"';
  object.packageValue = true;
  if (!object.packageValue) throw 'incorrect value in "packageValue"';
  object.packageValue = false;
  if (object.packageValue) throw 'incorrect value in "packageValue"';

  if (object.privateValue == null)
    throw 'incorrect initialization of "privateValue"';
  object.privateValue = true;
  if (!object.privateValue) throw 'incorrect value in "privateValue"';
  object.privateValue = false;
  if (object.privateValue) throw 'incorrect value in "privateValue"';

  if (object.protectedValue == null)
    throw 'incorrect initialization of "protectedValue"';
  object.protectedValue = true;
  if (!object.protectedValue) throw 'incorrect value in "protectedValue"';
  object.protectedValue = false;
  if (object.protectedValue) throw 'incorrect value in "protectedValue"';

  if (object.publicValue == null)
    throw 'incorrect initialization of "publicValue"';
  object.publicValue = true;
  if (!object.publicValue) throw 'incorrect value in "publicValue"';
  object.publicValue = false;
  if (object.publicValue) throw 'incorrect value in "publicValue"';

  if (object.returnValue == null)
    throw 'incorrect initialization of "returnValue"';
  object.returnValue = true;
  if (!object.returnValue) throw 'incorrect value in "returnValue"';
  object.returnValue = false;
  if (object.returnValue) throw 'incorrect value in "returnValue"';

  if (object.staticValue == null)
    throw 'incorrect initialization of "staticValue"';
  object.staticValue = true;
  if (!object.staticValue) throw 'incorrect value in "staticValue"';
  object.staticValue = false;
  if (object.staticValue) throw 'incorrect value in "staticValue"';

  if (object.superValue == null)
    throw 'incorrect initialization of "superValue"';
  object.superValue = true;
  if (!object.superValue) throw 'incorrect value in "superValue"';
  object.superValue = false;
  if (object.superValue) throw 'incorrect value in "superValue"';

  if (object.switchValue == null)
    throw 'incorrect initialization of "switchValue"';
  object.switchValue = true;
  if (!object.switchValue) throw 'incorrect value in "switchValue"';
  object.switchValue = false;
  if (object.switchValue) throw 'incorrect value in "switchValue"';

  if (object.thisValue == null)
    throw 'incorrect initialization of "thisValue"';
  object.thisValue = true;
  if (!object.thisValue) throw 'incorrect value in "thisValue"';
  object.thisValue = false;
  if (object.thisValue) throw 'incorrect value in "thisValue"';

  if (object.throwValue == null)
    throw 'incorrect initialization of "throwValue"';
  object.throwValue = true;
  if (!object.throwValue) throw 'incorrect value in "throwValue"';
  object.throwValue = false;
  if (object.throwValue) throw 'incorrect value in "throwValue"';

  if (object.trueValue == null)
    throw 'incorrect initialization of "trueValue"';
  object.trueValue = true;
  if (!object.trueValue) throw 'incorrect value in "trueValue"';
  object.trueValue = false;
  if (object.trueValue) throw 'incorrect value in "trueValue"';

  if (object.tryValue == null)
    throw 'incorrect initialization of "tryValue"';
  object.tryValue = true;
  if (!object.tryValue) throw 'incorrect value in "tryValue"';
  object.tryValue = false;
  if (object.tryValue) throw 'incorrect value in "tryValue"';

  if (object.typeofValue == null)
    throw 'incorrect initialization of "typeofValue"';
  object.typeofValue = true;
  if (!object.typeofValue) throw 'incorrect value in "typeofValue"';
  object.typeofValue = false;
  if (object.typeofValue) throw 'incorrect value in "typeofValue"';

  if (object.varValue == null)
    throw 'incorrect initialization of "varValue"';
  object.varValue = true;
  if (!object.varValue) throw 'incorrect value in "varValue"';
  object.varValue = false;
  if (object.varValue) throw 'incorrect value in "varValue"';

  if (object.voidValue == null)
    throw 'incorrect initialization of "voidValue"';
  object.voidValue = true;
  if (!object.voidValue) throw 'incorrect value in "voidValue"';
  object.voidValue = false;
  if (object.voidValue) throw 'incorrect value in "voidValue"';

  if (object.whileValue == null)
    throw 'incorrect initialization of "whileValue"';
  object.whileValue = true;
  if (!object.whileValue) throw 'incorrect value in "whileValue"';
  object.whileValue = false;
  if (object.whileValue) throw 'incorrect value in "whileValue"';

  if (object.withValue == null)
    throw 'incorrect initialization of "withValue"';
  object.withValue = true;
  if (!object.withValue) throw 'incorrect value in "withValue"';
  object.withValue = false;
  if (object.withValue) throw 'incorrect value in "withValue"';

  if (object.yieldValue == null)
    throw 'incorrect initialization of "yieldValue"';
  object.yieldValue = true;
  if (!object.yieldValue) throw 'incorrect value in "yieldValue"';
  object.yieldValue = false;
  if (object.yieldValue) throw 'incorrect value in "yieldValue"';
}

/// Called multiple times with arguments that are hard to track in type
/// inference making it hard to inline accessors.
testObjectWeaklyTyped(object) {
  object = object[0];
  if (object == 'fisk') return;
  if (object.breakValue == null)
    throw 'incorrect initialization of "breakValue"';
  object.breakValue = true;
  if (!object.breakValue) throw 'incorrect value in "breakValue"';
  object.breakValue = false;
  if (object.breakValue) throw 'incorrect value in "breakValue"';

  if (object.caseValue == null)
    throw 'incorrect initialization of "caseValue"';
  object.caseValue = true;
  if (!object.caseValue) throw 'incorrect value in "caseValue"';
  object.caseValue = false;
  if (object.caseValue) throw 'incorrect value in "caseValue"';

  if (object.catchValue == null)
    throw 'incorrect initialization of "catchValue"';
  object.catchValue = true;
  if (!object.catchValue) throw 'incorrect value in "catchValue"';
  object.catchValue = false;
  if (object.catchValue) throw 'incorrect value in "catchValue"';

  if (object.classValue == null)
    throw 'incorrect initialization of "classValue"';
  object.classValue = true;
  if (!object.classValue) throw 'incorrect value in "classValue"';
  object.classValue = false;
  if (object.classValue) throw 'incorrect value in "classValue"';

  if (object.constValue == null)
    throw 'incorrect initialization of "constValue"';
  object.constValue = true;
  if (!object.constValue) throw 'incorrect value in "constValue"';
  object.constValue = false;
  if (object.constValue) throw 'incorrect value in "constValue"';

  if (object.continueValue == null)
    throw 'incorrect initialization of "continueValue"';
  object.continueValue = true;
  if (!object.continueValue) throw 'incorrect value in "continueValue"';
  object.continueValue = false;
  if (object.continueValue) throw 'incorrect value in "continueValue"';

  if (object.debuggerValue == null)
    throw 'incorrect initialization of "debuggerValue"';
  object.debuggerValue = true;
  if (!object.debuggerValue) throw 'incorrect value in "debuggerValue"';
  object.debuggerValue = false;
  if (object.debuggerValue) throw 'incorrect value in "debuggerValue"';

  if (object.defaultValue == null)
    throw 'incorrect initialization of "defaultValue"';
  object.defaultValue = true;
  if (!object.defaultValue) throw 'incorrect value in "defaultValue"';
  object.defaultValue = false;
  if (object.defaultValue) throw 'incorrect value in "defaultValue"';

  if (object.deleteValue == null)
    throw 'incorrect initialization of "deleteValue"';
  object.deleteValue = true;
  if (!object.deleteValue) throw 'incorrect value in "deleteValue"';
  object.deleteValue = false;
  if (object.deleteValue) throw 'incorrect value in "deleteValue"';

  if (object.doValue == null)
    throw 'incorrect initialization of "doValue"';
  object.doValue = true;
  if (!object.doValue) throw 'incorrect value in "doValue"';
  object.doValue = false;
  if (object.doValue) throw 'incorrect value in "doValue"';

  if (object.elseValue == null)
    throw 'incorrect initialization of "elseValue"';
  object.elseValue = true;
  if (!object.elseValue) throw 'incorrect value in "elseValue"';
  object.elseValue = false;
  if (object.elseValue) throw 'incorrect value in "elseValue"';

  if (object.enumValue == null)
    throw 'incorrect initialization of "enumValue"';
  object.enumValue = true;
  if (!object.enumValue) throw 'incorrect value in "enumValue"';
  object.enumValue = false;
  if (object.enumValue) throw 'incorrect value in "enumValue"';

  if (object.exportValue == null)
    throw 'incorrect initialization of "exportValue"';
  object.exportValue = true;
  if (!object.exportValue) throw 'incorrect value in "exportValue"';
  object.exportValue = false;
  if (object.exportValue) throw 'incorrect value in "exportValue"';

  if (object.extendsValue == null)
    throw 'incorrect initialization of "extendsValue"';
  object.extendsValue = true;
  if (!object.extendsValue) throw 'incorrect value in "extendsValue"';
  object.extendsValue = false;
  if (object.extendsValue) throw 'incorrect value in "extendsValue"';

  if (object.falseValue == null)
    throw 'incorrect initialization of "falseValue"';
  object.falseValue = true;
  if (!object.falseValue) throw 'incorrect value in "falseValue"';
  object.falseValue = false;
  if (object.falseValue) throw 'incorrect value in "falseValue"';

  if (object.finallyValue == null)
    throw 'incorrect initialization of "finallyValue"';
  object.finallyValue = true;
  if (!object.finallyValue) throw 'incorrect value in "finallyValue"';
  object.finallyValue = false;
  if (object.finallyValue) throw 'incorrect value in "finallyValue"';

  if (object.forValue == null)
    throw 'incorrect initialization of "forValue"';
  object.forValue = true;
  if (!object.forValue) throw 'incorrect value in "forValue"';
  object.forValue = false;
  if (object.forValue) throw 'incorrect value in "forValue"';

  if (object.functionValue == null)
    throw 'incorrect initialization of "functionValue"';
  object.functionValue = true;
  if (!object.functionValue) throw 'incorrect value in "functionValue"';
  object.functionValue = false;
  if (object.functionValue) throw 'incorrect value in "functionValue"';

  if (object.ifValue == null)
    throw 'incorrect initialization of "ifValue"';
  object.ifValue = true;
  if (!object.ifValue) throw 'incorrect value in "ifValue"';
  object.ifValue = false;
  if (object.ifValue) throw 'incorrect value in "ifValue"';

  if (object.implementsValue == null)
    throw 'incorrect initialization of "implementsValue"';
  object.implementsValue = true;
  if (!object.implementsValue) throw 'incorrect value in "implementsValue"';
  object.implementsValue = false;
  if (object.implementsValue) throw 'incorrect value in "implementsValue"';

  if (object.importValue == null)
    throw 'incorrect initialization of "importValue"';
  object.importValue = true;
  if (!object.importValue) throw 'incorrect value in "importValue"';
  object.importValue = false;
  if (object.importValue) throw 'incorrect value in "importValue"';

  if (object.inValue == null)
    throw 'incorrect initialization of "inValue"';
  object.inValue = true;
  if (!object.inValue) throw 'incorrect value in "inValue"';
  object.inValue = false;
  if (object.inValue) throw 'incorrect value in "inValue"';

  if (object.instanceofValue == null)
    throw 'incorrect initialization of "instanceofValue"';
  object.instanceofValue = true;
  if (!object.instanceofValue) throw 'incorrect value in "instanceofValue"';
  object.instanceofValue = false;
  if (object.instanceofValue) throw 'incorrect value in "instanceofValue"';

  if (object.interfaceValue == null)
    throw 'incorrect initialization of "interfaceValue"';
  object.interfaceValue = true;
  if (!object.interfaceValue) throw 'incorrect value in "interfaceValue"';
  object.interfaceValue = false;
  if (object.interfaceValue) throw 'incorrect value in "interfaceValue"';

  if (object.letValue == null)
    throw 'incorrect initialization of "letValue"';
  object.letValue = true;
  if (!object.letValue) throw 'incorrect value in "letValue"';
  object.letValue = false;
  if (object.letValue) throw 'incorrect value in "letValue"';

  if (object.newValue == null)
    throw 'incorrect initialization of "newValue"';
  object.newValue = true;
  if (!object.newValue) throw 'incorrect value in "newValue"';
  object.newValue = false;
  if (object.newValue) throw 'incorrect value in "newValue"';

  if (object.nullValue == null)
    throw 'incorrect initialization of "nullValue"';
  object.nullValue = true;
  if (!object.nullValue) throw 'incorrect value in "nullValue"';
  object.nullValue = false;
  if (object.nullValue) throw 'incorrect value in "nullValue"';

  if (object.packageValue == null)
    throw 'incorrect initialization of "packageValue"';
  object.packageValue = true;
  if (!object.packageValue) throw 'incorrect value in "packageValue"';
  object.packageValue = false;
  if (object.packageValue) throw 'incorrect value in "packageValue"';

  if (object.privateValue == null)
    throw 'incorrect initialization of "privateValue"';
  object.privateValue = true;
  if (!object.privateValue) throw 'incorrect value in "privateValue"';
  object.privateValue = false;
  if (object.privateValue) throw 'incorrect value in "privateValue"';

  if (object.protectedValue == null)
    throw 'incorrect initialization of "protectedValue"';
  object.protectedValue = true;
  if (!object.protectedValue) throw 'incorrect value in "protectedValue"';
  object.protectedValue = false;
  if (object.protectedValue) throw 'incorrect value in "protectedValue"';

  if (object.publicValue == null)
    throw 'incorrect initialization of "publicValue"';
  object.publicValue = true;
  if (!object.publicValue) throw 'incorrect value in "publicValue"';
  object.publicValue = false;
  if (object.publicValue) throw 'incorrect value in "publicValue"';

  if (object.returnValue == null)
    throw 'incorrect initialization of "returnValue"';
  object.returnValue = true;
  if (!object.returnValue) throw 'incorrect value in "returnValue"';
  object.returnValue = false;
  if (object.returnValue) throw 'incorrect value in "returnValue"';

  if (object.staticValue == null)
    throw 'incorrect initialization of "staticValue"';
  object.staticValue = true;
  if (!object.staticValue) throw 'incorrect value in "staticValue"';
  object.staticValue = false;
  if (object.staticValue) throw 'incorrect value in "staticValue"';

  if (object.superValue == null)
    throw 'incorrect initialization of "superValue"';
  object.superValue = true;
  if (!object.superValue) throw 'incorrect value in "superValue"';
  object.superValue = false;
  if (object.superValue) throw 'incorrect value in "superValue"';

  if (object.switchValue == null)
    throw 'incorrect initialization of "switchValue"';
  object.switchValue = true;
  if (!object.switchValue) throw 'incorrect value in "switchValue"';
  object.switchValue = false;
  if (object.switchValue) throw 'incorrect value in "switchValue"';

  if (object.thisValue == null)
    throw 'incorrect initialization of "thisValue"';
  object.thisValue = true;
  if (!object.thisValue) throw 'incorrect value in "thisValue"';
  object.thisValue = false;
  if (object.thisValue) throw 'incorrect value in "thisValue"';

  if (object.throwValue == null)
    throw 'incorrect initialization of "throwValue"';
  object.throwValue = true;
  if (!object.throwValue) throw 'incorrect value in "throwValue"';
  object.throwValue = false;
  if (object.throwValue) throw 'incorrect value in "throwValue"';

  if (object.trueValue == null)
    throw 'incorrect initialization of "trueValue"';
  object.trueValue = true;
  if (!object.trueValue) throw 'incorrect value in "trueValue"';
  object.trueValue = false;
  if (object.trueValue) throw 'incorrect value in "trueValue"';

  if (object.tryValue == null)
    throw 'incorrect initialization of "tryValue"';
  object.tryValue = true;
  if (!object.tryValue) throw 'incorrect value in "tryValue"';
  object.tryValue = false;
  if (object.tryValue) throw 'incorrect value in "tryValue"';

  if (object.typeofValue == null)
    throw 'incorrect initialization of "typeofValue"';
  object.typeofValue = true;
  if (!object.typeofValue) throw 'incorrect value in "typeofValue"';
  object.typeofValue = false;
  if (object.typeofValue) throw 'incorrect value in "typeofValue"';

  if (object.varValue == null)
    throw 'incorrect initialization of "varValue"';
  object.varValue = true;
  if (!object.varValue) throw 'incorrect value in "varValue"';
  object.varValue = false;
  if (object.varValue) throw 'incorrect value in "varValue"';

  if (object.voidValue == null)
    throw 'incorrect initialization of "voidValue"';
  object.voidValue = true;
  if (!object.voidValue) throw 'incorrect value in "voidValue"';
  object.voidValue = false;
  if (object.voidValue) throw 'incorrect value in "voidValue"';

  if (object.whileValue == null)
    throw 'incorrect initialization of "whileValue"';
  object.whileValue = true;
  if (!object.whileValue) throw 'incorrect value in "whileValue"';
  object.whileValue = false;
  if (object.whileValue) throw 'incorrect value in "whileValue"';

  if (object.withValue == null)
    throw 'incorrect initialization of "withValue"';
  object.withValue = true;
  if (!object.withValue) throw 'incorrect value in "withValue"';
  object.withValue = false;
  if (object.withValue) throw 'incorrect value in "withValue"';

  if (object.yieldValue == null)
    throw 'incorrect initialization of "yieldValue"';
  object.yieldValue = true;
  if (!object.yieldValue) throw 'incorrect value in "yieldValue"';
  object.yieldValue = false;
  if (object.yieldValue) throw 'incorrect value in "yieldValue"';
}

NativeClassWithOddNames makeNativeClassWithOddNames() native;

setup() native """
function NativeClassWithOddNames() {}
makeNativeClassWithOddNames = function() { return new NativeClassWithOddNames; }
""";

main() {
  setup();
  var object = makeNativeClassWithOddNames();
  object.testMyFields();
  testObjectStronglyTyped(object);
  testObjectWeaklyTyped([object]);
  testObjectWeaklyTyped(['fisk']);
  testObjectWeaklyTyped([new ClassWithOddNames()..testMyFields()]);
}
