/*library: 
 constant=[
  {
  "id": "constant/B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n",
  "kind": "constant",
  "name": "",
  "size": 131,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n"
},
  {
  "id": "constant/B.C_JS_CONST0 = function() {\n  var toStringFunction = Object.prototype.toString;\n  function getTag(o) {\n    var s = toStringFunction.call(o);\n    return s.substring(8, s.length - 1);\n  }\n  function getUnknownTag(object, tag) {\n    if (/^HTML[A-Z].*Element$/.test(tag)) {\n      var name = toStringFunction.call(object);\n      if (name == \"[object Object]\") return null;\n      return \"HTMLElement\";\n    }\n  }\n  function getUnknownTagGenericBrowser(object, tag) {\n    if (object instanceof HTMLElement) return \"HTMLElement\";\n    return getUnknownTag(object, tag);\n  }\n  function prototypeForTag(tag) {\n    if (typeof window == \"undefined\") return null;\n    if (typeof window[tag] == \"undefined\") return null;\n    var constructor = window[tag];\n    if (typeof constructor != \"function\") return null;\n    return constructor.prototype;\n  }\n  function discriminator(tag) { return null; }\n  var isBrowser = typeof HTMLElement == \"function\";\n  return {\n    getTag: getTag,\n    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,\n    prototypeForTag: prototypeForTag,\n    discriminator: discriminator };\n};\n",
  "kind": "constant",
  "name": "",
  "size": 1117,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST0 = function() {\n  var toStringFunction = Object.prototype.toString;\n  function getTag(o) {\n    var s = toStringFunction.call(o);\n    return s.substring(8, s.length - 1);\n  }\n  function getUnknownTag(object, tag) {\n    if (/^HTML[A-Z].*Element$/.test(tag)) {\n      var name = toStringFunction.call(object);\n      if (name == \"[object Object]\") return null;\n      return \"HTMLElement\";\n    }\n  }\n  function getUnknownTagGenericBrowser(object, tag) {\n    if (object instanceof HTMLElement) return \"HTMLElement\";\n    return getUnknownTag(object, tag);\n  }\n  function prototypeForTag(tag) {\n    if (typeof window == \"undefined\") return null;\n    if (typeof window[tag] == \"undefined\") return null;\n    var constructor = window[tag];\n    if (typeof constructor != \"function\") return null;\n    return constructor.prototype;\n  }\n  function discriminator(tag) { return null; }\n  var isBrowser = typeof HTMLElement == \"function\";\n  return {\n    getTag: getTag,\n    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,\n    prototypeForTag: prototypeForTag,\n    discriminator: discriminator };\n};\n"
},
  {
  "id": "constant/B.C_JS_CONST1 = function(hooks) {\n  if (typeof dartExperimentalFixupGetTag != \"function\") return hooks;\n  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);\n};\n",
  "kind": "constant",
  "name": "",
  "size": 167,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST1 = function(hooks) {\n  if (typeof dartExperimentalFixupGetTag != \"function\") return hooks;\n  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);\n};\n"
},
  {
  "id": "constant/B.C_JS_CONST2 = function(hooks) {\n  var getTag = hooks.getTag;\n  var prototypeForTag = hooks.prototypeForTag;\n  function getTagFixed(o) {\n    var tag = getTag(o);\n    if (tag == \"Document\") {\n      if (!!o.xmlVersion) return \"!Document\";\n      return \"!HTMLDocument\";\n    }\n    return tag;\n  }\n  function prototypeForTagFixed(tag) {\n    if (tag == \"Document\") return null;\n    return prototypeForTag(tag);\n  }\n  hooks.getTag = getTagFixed;\n  hooks.prototypeForTag = prototypeForTagFixed;\n};\n",
  "kind": "constant",
  "name": "",
  "size": 491,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST2 = function(hooks) {\n  var getTag = hooks.getTag;\n  var prototypeForTag = hooks.prototypeForTag;\n  function getTagFixed(o) {\n    var tag = getTag(o);\n    if (tag == \"Document\") {\n      if (!!o.xmlVersion) return \"!Document\";\n      return \"!HTMLDocument\";\n    }\n    return tag;\n  }\n  function prototypeForTagFixed(tag) {\n    if (tag == \"Document\") return null;\n    return prototypeForTag(tag);\n  }\n  hooks.getTag = getTagFixed;\n  hooks.prototypeForTag = prototypeForTagFixed;\n};\n"
},
  {
  "id": "constant/B.C_JS_CONST3 = function(hooks) { return hooks; }\n;\n",
  "kind": "constant",
  "name": "",
  "size": 52,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST3 = function(hooks) { return hooks; }\n;\n"
},
  {
  "id": "constant/B.C_JS_CONST4 = function(hooks) {\n  if (typeof navigator != \"object\") return hooks;\n  var userAgent = navigator.userAgent;\n  if (typeof userAgent != \"string\") return hooks;\n  if (userAgent.indexOf(\"Trident/\") == -1) return hooks;\n  var getTag = hooks.getTag;\n  var quickMap = {\n    \"BeforeUnloadEvent\": \"Event\",\n    \"DataTransfer\": \"Clipboard\",\n    \"HTMLDDElement\": \"HTMLElement\",\n    \"HTMLDTElement\": \"HTMLElement\",\n    \"HTMLPhraseElement\": \"HTMLElement\",\n    \"Position\": \"Geoposition\"\n  };\n  function getTagIE(o) {\n    var tag = getTag(o);\n    var newTag = quickMap[tag];\n    if (newTag) return newTag;\n    if (tag == \"Object\") {\n      if (window.DataView && (o instanceof window.DataView)) return \"DataView\";\n    }\n    return tag;\n  }\n  function prototypeForTagIE(tag) {\n    var constructor = window[tag];\n    if (constructor == null) return null;\n    return constructor.prototype;\n  }\n  hooks.getTag = getTagIE;\n  hooks.prototypeForTag = prototypeForTagIE;\n};\n",
  "kind": "constant",
  "name": "",
  "size": 964,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST4 = function(hooks) {\n  if (typeof navigator != \"object\") return hooks;\n  var userAgent = navigator.userAgent;\n  if (typeof userAgent != \"string\") return hooks;\n  if (userAgent.indexOf(\"Trident/\") == -1) return hooks;\n  var getTag = hooks.getTag;\n  var quickMap = {\n    \"BeforeUnloadEvent\": \"Event\",\n    \"DataTransfer\": \"Clipboard\",\n    \"HTMLDDElement\": \"HTMLElement\",\n    \"HTMLDTElement\": \"HTMLElement\",\n    \"HTMLPhraseElement\": \"HTMLElement\",\n    \"Position\": \"Geoposition\"\n  };\n  function getTagIE(o) {\n    var tag = getTag(o);\n    var newTag = quickMap[tag];\n    if (newTag) return newTag;\n    if (tag == \"Object\") {\n      if (window.DataView && (o instanceof window.DataView)) return \"DataView\";\n    }\n    return tag;\n  }\n  function prototypeForTagIE(tag) {\n    var constructor = window[tag];\n    if (constructor == null) return null;\n    return constructor.prototype;\n  }\n  hooks.getTag = getTagIE;\n  hooks.prototypeForTag = prototypeForTagIE;\n};\n"
},
  {
  "id": "constant/B.C_JS_CONST5 = function(hooks) {\n  if (typeof navigator != \"object\") return hooks;\n  var userAgent = navigator.userAgent;\n  if (typeof userAgent != \"string\") return hooks;\n  if (userAgent.indexOf(\"Firefox\") == -1) return hooks;\n  var getTag = hooks.getTag;\n  var quickMap = {\n    \"BeforeUnloadEvent\": \"Event\",\n    \"DataTransfer\": \"Clipboard\",\n    \"GeoGeolocation\": \"Geolocation\",\n    \"Location\": \"!Location\",\n    \"WorkerMessageEvent\": \"MessageEvent\",\n    \"XMLDocument\": \"!Document\"};\n  function getTagFirefox(o) {\n    var tag = getTag(o);\n    return quickMap[tag] || tag;\n  }\n  hooks.getTag = getTagFirefox;\n};\n",
  "kind": "constant",
  "name": "",
  "size": 612,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST5 = function(hooks) {\n  if (typeof navigator != \"object\") return hooks;\n  var userAgent = navigator.userAgent;\n  if (typeof userAgent != \"string\") return hooks;\n  if (userAgent.indexOf(\"Firefox\") == -1) return hooks;\n  var getTag = hooks.getTag;\n  var quickMap = {\n    \"BeforeUnloadEvent\": \"Event\",\n    \"DataTransfer\": \"Clipboard\",\n    \"GeoGeolocation\": \"Geolocation\",\n    \"Location\": \"!Location\",\n    \"WorkerMessageEvent\": \"MessageEvent\",\n    \"XMLDocument\": \"!Document\"};\n  function getTagFirefox(o) {\n    var tag = getTag(o);\n    return quickMap[tag] || tag;\n  }\n  hooks.getTag = getTagFirefox;\n};\n"
},
  {
  "id": "constant/B.C_JS_CONST6 = function(getTagFallback) {\n  return function(hooks) {\n    if (typeof navigator != \"object\") return hooks;\n    var userAgent = navigator.userAgent;\n    if (typeof userAgent != \"string\") return hooks;\n    if (userAgent.indexOf(\"DumpRenderTree\") >= 0) return hooks;\n    if (userAgent.indexOf(\"Chrome\") >= 0) {\n      function confirm(p) {\n        return typeof window == \"object\" && window[p] && window[p].name == p;\n      }\n      if (confirm(\"Window\") && confirm(\"HTMLElement\")) return hooks;\n    }\n    hooks.getTag = getTagFallback;\n  };\n};\n",
  "kind": "constant",
  "name": "",
  "size": 555,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST6 = function(getTagFallback) {\n  return function(hooks) {\n    if (typeof navigator != \"object\") return hooks;\n    var userAgent = navigator.userAgent;\n    if (typeof userAgent != \"string\") return hooks;\n    if (userAgent.indexOf(\"DumpRenderTree\") >= 0) return hooks;\n    if (userAgent.indexOf(\"Chrome\") >= 0) {\n      function confirm(p) {\n        return typeof window == \"object\" && window[p] && window[p].name == p;\n      }\n      if (confirm(\"Window\") && confirm(\"HTMLElement\")) return hooks;\n    }\n    hooks.getTag = getTagFallback;\n  };\n};\n"
},
  {
  "id": "constant/B.Interceptor_methods = J.Interceptor.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 49,
  "outputUnit": "outputUnit/main",
  "code": "B.Interceptor_methods = J.Interceptor.prototype;\n"
},
  {
  "id": "constant/B.JSArray_methods = J.JSArray.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 41,
  "outputUnit": "outputUnit/main",
  "code": "B.JSArray_methods = J.JSArray.prototype;\n"
},
  {
  "id": "constant/B.JSString_methods = J.JSString.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 43,
  "outputUnit": "outputUnit/main",
  "code": "B.JSString_methods = J.JSString.prototype;\n"
},
  {
  "id": "constant/B.JavaScriptFunction_methods = J.JavaScriptFunction.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 63,
  "outputUnit": "outputUnit/main",
  "code": "B.JavaScriptFunction_methods = J.JavaScriptFunction.prototype;\n"
},
  {
  "id": "constant/B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 59,
  "outputUnit": "outputUnit/main",
  "code": "B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n"
},
  {
  "id": "constant/B.PlainJavaScriptObject_methods = J.PlainJavaScriptObject.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 69,
  "outputUnit": "outputUnit/main",
  "code": "B.PlainJavaScriptObject_methods = J.PlainJavaScriptObject.prototype;\n"
},
  {
  "id": "constant/B.UnknownJavaScriptObject_methods = J.UnknownJavaScriptObject.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 73,
  "outputUnit": "outputUnit/main",
  "code": "B.UnknownJavaScriptObject_methods = J.UnknownJavaScriptObject.prototype;\n"
}],
 deferredFiles=[{}],
 dependencies=[{}],
 library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "js_parameters_test",
  "size": 1891,
  "children": [
    "class/memory:sdk/tests/web/native/main.dart::Bar",
    "class/memory:sdk/tests/web/native/main.dart::Foo",
    "function/memory:sdk/tests/web/native/main.dart::main"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/main.dart"
}],
 outputUnits=[{
  "id": "outputUnit/main",
  "kind": "outputUnit",
  "name": "main",
  "filename": "out",
  "imports": []
}]
*/
@JS()
library js_parameters_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
/*class: Foo:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Foo",
  "kind": "class",
  "name": "Foo",
  "size": 54,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::Foo.mixedPositionalArgs",
    "function/memory:sdk/tests/web/native/main.dart::Foo.singleArg",
    "function/memory:sdk/tests/web/native/main.dart::Foo.singlePositionalArg"
  ],
  "supers": [
    "class/dart:_interceptors::LegacyJavaScriptObject"
  ]
}]*/
class Foo {
  external factory Foo();
  /*member: Foo.singleArg:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Foo.singleArg",
  "kind": "function",
  "name": "singleArg",
  "size": 70,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Foo",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": true
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null|subclass=Object]",
  "parameters": [
    {
      "name": "a",
      "type": "[exact=JSUInt31]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "singleArg$1(receiver, p0) {\n      return receiver.singleArg(p0);\n    }",
  "type": "dynamic Function(dynamic)",
  "functionKind": 2
}]*/
  external singleArg(a);
  /*member: Foo.singlePositionalArg:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Foo.singlePositionalArg",
  "kind": "function",
  "name": "singlePositionalArg",
  "size": 174,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Foo",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": true
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null|subclass=Object]",
  "parameters": [
    {
      "name": "a",
      "type": "[null|exact=JSUInt31]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "singlePositionalArg$1(receiver, p0) {\n      return receiver.singlePositionalArg(p0);\n    }\nsinglePositionalArg$0(receiver) {\n      return receiver.singlePositionalArg();\n    }",
  "type": "dynamic Function([dynamic])",
  "functionKind": 2
}]*/
  external singlePositionalArg([dynamic? a]);
  /*member: Foo.mixedPositionalArgs:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Foo.mixedPositionalArgs",
  "kind": "function",
  "name": "mixedPositionalArgs",
  "size": 188,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Foo",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": true
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null|subclass=Object]",
  "parameters": [
    {
      "name": "a",
      "type": "[exact=JSUInt31]",
      "declaredType": "dynamic"
    },
    {
      "name": "b",
      "type": "[null|exact=JSUInt31]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "mixedPositionalArgs$1(receiver, p0) {\n      return receiver.mixedPositionalArgs(p0);\n    }\nmixedPositionalArgs$2(receiver, p0, p1) {\n      return receiver.mixedPositionalArgs(p0, p1);\n    }",
  "type": "dynamic Function(dynamic,[dynamic])",
  "functionKind": 2
}]*/
  external mixedPositionalArgs(a, [dynamic? b]);
}

@JS()
/*class: Bar:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Bar",
  "kind": "class",
  "name": "Bar",
  "size": 54,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [],
  "supers": [
    "class/dart:_interceptors::LegacyJavaScriptObject"
  ]
}]*/
class Bar {
  external static singleArg(a);
  external static singlePositionalArg([dynamic? a]);
  external static mixedPositionalArgs(a, [dynamic? b]);
}

external singleArg(a);
external singlePositionalArg([dynamic? a]);
external mixedPositionalArgs(a, [dynamic? b]);

/*member: main:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 1783,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "main() {\n      var foo, t1;\n      self.eval(\"    function Foo() {}\\n    Foo.prototype.singleArg = function(a) {\\n      return a;\\n    }\\n    Foo.prototype.singlePositionalArg = singleArg;\\n    Foo.prototype.mixedPositionalArgs = function(a, b) {\\n      if (arguments.length == 0) return a;\\n      return arguments[arguments.length - 1];\\n    }\\n    var Bar = {\\n      singleArg: function(a) {\\n        return a;\\n      },\\n      singlePositionalArg: singleArg,\\n      mixedPositionalArgs: function(a, b) {\\n        if (arguments.length == 0) return a;\\n        return arguments[arguments.length - 1];\\n      },\\n    };\\n    function singleArg(a) {\\n      return a;\\n    }\\n    var singlePositionalArg = singleArg;\\n    function mixedPositionalArgs(a, b) {\\n      if (arguments.length == 0) return a;\\n      return arguments[arguments.length - 1];\\n    }\\n  \");\n      foo = new self.Foo();\n      t1 = J.getInterceptor$x(foo);\n      A.Expect_equals(t1.singleArg$1(foo, 2), 2);\n      A.Expect_equals(t1.singlePositionalArg$1(foo, 2), 2);\n      A.Expect_equals(t1.singlePositionalArg$0(foo), null);\n      A.Expect_equals(t1.mixedPositionalArgs$1(foo, 3), 3);\n      A.Expect_equals(t1.mixedPositionalArgs$2(foo, 3, 4), 4);\n      A.Expect_equals(self.Bar.singleArg(2), 2);\n      A.Expect_equals(self.Bar.singlePositionalArg(2), 2);\n      A.Expect_equals(self.Bar.singlePositionalArg(), null);\n      A.Expect_equals(self.Bar.mixedPositionalArgs(3), 3);\n      A.Expect_equals(self.Bar.mixedPositionalArgs(3, 4), 4);\n      A.Expect_equals(self.singleArg(2), 2);\n      A.Expect_equals(self.singlePositionalArg(2), 2);\n      A.Expect_equals(self.singlePositionalArg(), null);\n      A.Expect_equals(self.mixedPositionalArgs(3), 3);\n      A.Expect_equals(self.mixedPositionalArgs(3, 4), 4);\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
}],
 holding=[
  {"id":"function/dart:_interceptors::getNativeInterceptor"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.mixedPositionalArgs","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.mixedPositionalArgs","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.singleArg","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.singlePositionalArg","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.singlePositionalArg","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/package:expect/expect.dart::Expect.equals"}]
*/
main() {
  eval(r"""
    function Foo() {}
    Foo.prototype.singleArg = function(a) {
      return a;
    }
    Foo.prototype.singlePositionalArg = singleArg;
    Foo.prototype.mixedPositionalArgs = function(a, b) {
      if (arguments.length == 0) return a;
      return arguments[arguments.length - 1];
    }
    var Bar = {
      singleArg: function(a) {
        return a;
      },
      singlePositionalArg: singleArg,
      mixedPositionalArgs: function(a, b) {
        if (arguments.length == 0) return a;
        return arguments[arguments.length - 1];
      },
    };
    function singleArg(a) {
      return a;
    }
    var singlePositionalArg = singleArg;
    function mixedPositionalArgs(a, b) {
      if (arguments.length == 0) return a;
      return arguments[arguments.length - 1];
    }
  """);

  var foo = Foo();
  Expect.equals(foo.singleArg(2), 2);
  Expect.equals(foo.singlePositionalArg(2), 2);
  Expect.equals(foo.singlePositionalArg(), null);
  Expect.equals(foo.mixedPositionalArgs(3), 3);
  Expect.equals(foo.mixedPositionalArgs(3, 4), 4);

  Expect.equals(Bar.singleArg(2), 2);
  Expect.equals(Bar.singlePositionalArg(2), 2);
  Expect.equals(Bar.singlePositionalArg(), null);
  Expect.equals(Bar.mixedPositionalArgs(3), 3);
  Expect.equals(Bar.mixedPositionalArgs(3, 4), 4);

  Expect.equals(singleArg(2), 2);
  Expect.equals(singlePositionalArg(2), 2);
  Expect.equals(singlePositionalArg(), null);
  Expect.equals(mixedPositionalArgs(3), 3);
  Expect.equals(mixedPositionalArgs(3, 4), 4);
}
