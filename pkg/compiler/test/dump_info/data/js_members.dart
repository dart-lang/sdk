/*library: library=[{
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
}]*/
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
  "type": "dynamic Function(dynamic)"
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
  "type": "dynamic Function([dynamic])"
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
  "type": "dynamic Function(dynamic,[dynamic])"
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
  "children": []
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
  "type": "dynamic Function()"
}],
 holding=[
  {"id":"function/dart:_interceptors::getNativeInterceptor","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.mixedPositionalArgs","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.mixedPositionalArgs","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.singleArg","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.singlePositionalArg","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Foo.singlePositionalArg","mask":"[subclass=LegacyJavaScriptObject]"},
  {"id":"function/package:expect/expect.dart::Expect.equals","mask":null}]
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
