// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TestJsUtils;

import 'dart:html';
import 'dart:indexed_db' show IdbFactory, KeyRange;
import 'dart:js';

import 'package:expect/minitest.dart';

injectJs() {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = r"""
var x = 42;

var _x = 123;

var myArray = ["value1"];

var foreignDoc = (function(){
  var doc = document.implementation.createDocument("", "root", null);
  var element = doc.createElement('element');
  element.setAttribute('id', 'abc');
  doc.documentElement.appendChild(element);
  return doc;
})();

function razzle() {
  return x;
}

function returnThis() {
  return this;
}

function getTypeOf(o) {
  return typeof(o);
}

function varArgs() {
  var args = arguments;
  var sum = 0;
  for (var i = 0; i < args.length; ++i) {
    sum += args[i];
  }
  return sum;
}

function Foo(a) {
  this.a = a;
}

Foo.b = 38;

Foo.prototype.bar = function() {
  return this.a;
}
Foo.prototype.toString = function() {
  return "I'm a Foo a=" + this.a;
}

var container = new Object();
container.Foo = Foo;

function isArray(a) {
  return a instanceof Array;
}

function checkMap(m, key, value) {
  if (m.hasOwnProperty(key))
    return m[key] == value;
  else
    return false;
}

function invokeCallback() {
  return callback();
}

function invokeCallbackWith11params() {
  return callbackWith11params(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
}

function returnElement(element) {
  return element;
}

function getElementAttribute(element, attr) {
  return element.getAttribute(attr);
}

function addClassAttributes(list) {
  var result = "";
  for (var i=0; i < list.length; i++) {
    result += list[i].getAttribute("class");
  }
  return result;
}

function getNewDate() {
  return new Date(1995, 11, 17);
}

function getNewDivElement() {
  return document.createElement("div");
}

function getNewEvent() {
  return new CustomEvent('test');
}

function getNewBlob() {
  var fileParts = ['<a id="a"><b id="b">hey!</b></a>'];
  return new Blob(fileParts, {type : 'text/html'});
}

function getNewIDBKeyRange() {
  return IDBKeyRange.only(1);
}

function getNewImageData() {
  var canvas = document.createElement('canvas');
  var context = canvas.getContext('2d');
  return context.createImageData(1, 1);
}

function getNewInt32Array() {
  return new Int32Array([1, 2, 3, 4, 5, 6, 7, 8]);
}

function getNewArrayBuffer() {
  return new ArrayBuffer(8);
}

function isPropertyInstanceOf(property, type) {
  return window[property] instanceof type;
}

function testJsMap(callback) {
  var result = callback();
  return result['value'];
}

function addTestProperty(o) {
  o.testProperty = "test";
}

function fireClickEvent(w) {
  var event = w.document.createEvent('Events');
  event.initEvent('click', true, false);
  w.document.dispatchEvent(event);
}

function Bar() {
  return "ret_value";
}
Bar.foo = "property_value";

function Baz(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11) {
  this.f1 = p1;
  this.f2 = p2;
  this.f3 = p3;
  this.f4 = p4;
  this.f5 = p5;
  this.f6 = p6;
  this.f7 = p7;
  this.f8 = p8;
  this.f9 = p9;
  this.f10 = p10;
  this.f11 = p11;
}

function Liar(){}

Liar.prototype.toString = function() {
  return 1;
}

function identical(o1, o2) {
  return o1 === o2;
}

var someProto = { role: "proto" };
var someObject = Object.create(someProto);
someObject.role = "object";

""";
  document.body.append(script);
}

typedef bool StringToBool(String s);

// Some test are either causing other test to fail in IE9, or they are failing
// for unknown reasons
// useHtmlConfiguration+ImageData bug: dartbug.com/14355
skipIE9_test(String description, t()) {
  if (Platform.supportsTypedData) {
    test(description, t);
  }
}

class Foo {
  final JsObject _proxy;

  Foo(num a) : this._proxy = new JsObject(context['Foo'], [a]);

  JsObject toJs() => _proxy;

  num get a => _proxy['a'];
  num bar() => _proxy.callMethod('bar');
}

class Color {
  static final RED = new Color._("red");
  static final BLUE = new Color._("blue");
  String _value;
  Color._(this._value);
  String toJs() => this._value;
}

class TestDartObject {}

class Callable {
  call() => 'called';
}
