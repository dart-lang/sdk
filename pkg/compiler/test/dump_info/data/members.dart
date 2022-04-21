class C {
  /*member: C.value:function=[{
    "id": "field/memory:sdk/tests/web/native/main.dart::C.value",
    "kind": "field",
    "name": "value",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::C",
    "children": [],
    "inferredType": "[exact=Error]",
    "code": "",
    "type": "dynamic"
}]*/
  final value;
  /*member: C.counter:function=[{
    "id": "field/memory:sdk/tests/web/native/main.dart::C.counter",
    "kind": "field",
    "name": "counter",
    "size": 18,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::C",
    "children": [],
    "inferredType": "[subclass=JSPositiveInt]",
    "code": "$.C_counter = 0;\n",
    "type": "int"
}]*/
  static int counter = 0;
  /*member: C.y:function=[{
    "id": "field/memory:sdk/tests/web/native/main.dart::C.y",
    "kind": "field",
    "name": "y",
    "size": 124,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::C",
    "children": [],
    "inferredType": "[null|exact=JSBool]",
    "code": "_lazy($, \"C_y\", \"$get$C_y\", () => {\n      var t1 = $.C_counter + 1;\n      $.C_counter = t1;\n      return t1 === 4;\n    });\n",
    "type": "bool"
}]*/
  static bool y = C.compute();
  /*member: C.compute:function=[{
    "id": "function/memory:sdk/tests/web/native/main.dart::C.compute",
    "kind": "function",
    "name": "compute",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::C",
    "children": [],
    "modifiers": {
        "static": true,
        "const": false,
        "factory": false,
        "external": false
    },
    "returnType": "bool",
    "inferredReturnType": "[exact=JSBool]",
    "parameters": [],
    "sideEffects": "SideEffects(reads static; writes static)",
    "inlinedCount": 1,
    "code": "",
    "type": "bool Function()"
}]*/
  static bool compute() {
    C.counter += 1;
    return counter == 4;
  }

  /*member: C._default:function=[{
    "id": "function/memory:sdk/tests/web/native/main.dart::C.C._default",
    "kind": "function",
    "name": "C._default",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::C",
    "children": [],
    "modifiers": {
        "static": false,
        "const": false,
        "factory": false,
        "external": false
    },
    "returnType": "dynamic",
    "inferredReturnType": "[exact=C]",
    "parameters": [
        {
            "name": "message",
            "type": "[exact=Error]",
            "declaredType": "Object"
        }
    ],
    "sideEffects": "SideEffects(reads nothing; writes nothing)",
    "inlinedCount": 1,
    "code": "",
    "type": "dynamic Function(Object)"
}]*/
  C._default(Object message) : value = message;

  /*member: C.create:function=[{
    "id": "function/memory:sdk/tests/web/native/main.dart::C.C.create",
    "kind": "function",
    "name": "C.create",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::C",
    "children": [],
    "modifiers": {
        "static": false,
        "const": false,
        "factory": true,
        "external": false
    },
    "returnType": "C",
    "inferredReturnType": "[exact=C]",
    "parameters": [
        {
            "name": "object",
            "type": "[exact=JSUInt31]",
            "declaredType": "dynamic"
        }
    ],
    "sideEffects": "SideEffects(reads nothing; writes nothing)",
    "inlinedCount": 1,
    "code": "",
    "type": "C Function(dynamic)"
}]*/
  factory C.create(object) {
    return C._default(Error());
  }
}

/*member: F:function=[{
    "id": "function/memory:sdk/tests/web/native/main.dart::F",
    "kind": "function",
    "name": "F",
    "size": 52,
    "outputUnit": "outputUnit/main",
    "parent": "library/memory:sdk/tests/web/native/main.dart::",
    "children": [],
    "modifiers": {
        "static": false,
        "const": false,
        "factory": false,
        "external": false
    },
    "returnType": "void",
    "inferredReturnType": "[null]",
    "parameters": [],
    "sideEffects": "SideEffects(reads nothing; writes nothing)",
    "inlinedCount": 0,
    "code": "F() {\n    }\n_static_0(A, \"main__F$closure\", \"F\", 0);\n",
    "type": "void Function()"
}]*/
void F() {}

class B {
  static void M() {}
  static const int a = 2123;
}

class A {
  /*member: A.a:function=[{
    "id": "field/memory:sdk/tests/web/native/main.dart::A.a",
    "kind": "field",
    "name": "a",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::A",
    "children": [],
    "inferredType": "Value([exact=JSString], value: \"hello\")",
    "code": "",
    "type": "dynamic"
}]*/
  final a;

/*member: A.:function=[{
    "id": "function/memory:sdk/tests/web/native/main.dart::A.A",
    "kind": "function",
    "name": "A",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "class/memory:sdk/tests/web/native/main.dart::A",
    "children": [],
    "modifiers": {
        "static": false,
        "const": true,
        "factory": false,
        "external": false
    },
    "returnType": "dynamic",
    "inferredReturnType": "[exact=A]",
    "parameters": [],
    "sideEffects": "SideEffects(reads nothing; writes nothing)",
    "inlinedCount": 1,
    "code": "",
    "type": "dynamic Function()"
}]*/
  const A() : a = "hello";
}

/*member: constList:function=[{
    "id": "field/memory:sdk/tests/web/native/main.dart::constList",
    "kind": "field",
    "name": "constList",
    "size": 0,
    "outputUnit": "outputUnit/main",
    "parent": "library/memory:sdk/tests/web/native/main.dart::",
    "children": [],
    "inferredType": "Container([exact=JSUnmodifiableArray], element: [exact=A], length: 1)",
    "code": "",
    "type": "List<A>"
}]*/
final constList = const [
  const A(),
];

/*member: main:function=[{
    "id": "function/memory:sdk/tests/web/native/main.dart::main",
    "kind": "function",
    "name": "main",
    "size": 199,
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
    "code": "main() {\n      null.add$1(0, [B.List_A, B.C_A, 2123, 2133, A.main__F$closure(), $.$get$C_y(), \"hello\"]);\n      null.add$1(0, B.C_A);\n      null.add$1(0, new A.C());\n      A.printString(\"null\");\n    }",
    "type": "dynamic Function()"
}]*/
main() {
  dynamic l = [constList, const A(), B.a, B.a + 10, F, C.y, A().a];
  dynamic r;
  r.add(l);
  r.add(const A());
  r.add(C.create(10));
  print(r);
}
