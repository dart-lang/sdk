// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_backend.sexpr_test;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2jslib.dart';
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart';
import 'package:compiler/src/cps_ir/cps_ir_nodes_sexpr.dart';
import 'package:expect/expect.dart';

import '../compiler_helper.dart' hide compilerFor;
import 'sexpr_unstringifier.dart';
import 'test_helper.dart';

const String CODE = """
class Foo {
  static int x = 1;
  foo() => 42;
}

class Bar extends Foo {
  int y = 2;
  Bar() {
    Foo.x = 2;
  }
  foo() =>  this.y + super.foo();
}

class FooBar<T> {
  bool foobar() => T is int;
}

main() {
  Foo foo;
  if (foo is Foo) {
    print("Surprise");
  }

  String inner() => "Inner function";
  print(inner());

  int j = 42;
  for (int i = 0; i < 2; i++) {
    print(i.toString());
  }

  print(Foo.x);

  String recursive(int h) {
    if (h < 1) {
      return j.toString();
    }
    j++;
    return "h\$\{recursive(h - 1)\}";
  }
  print(recursive(5));

  Bar bar = new Bar();
  print(bar.foo().toString());

  bar = foo as Bar;
  if (bar == null) {
    var list = [1, 2, 3, 4];
    var map  = { 1: "one"
               , 2: "two"
               , 3: "three"
               };
    var double = 3.14;
    list.forEach((i) => print(i.toString()));
    print("\$list \$map \$double");
  }

  print(new FooBar<int>().foobar());
}

""";

bool shouldOutput(Element element) {
  return (!element.library.isPlatformLibrary &&
          !element.isSynthesized &&
          element.kind == ElementKind.FUNCTION);
}

/// Compiles the given dart code (which must include a 'main' function) and
/// returns a list of all generated CPS IR definitions.
Future<List<FunctionDefinition>> compile(String code) {
  return compilerFor(code).then((Compiler compiler) {
    return compiler.enqueuer.resolution.resolvedElements
              .where(shouldOutput)
              .map(compiler.irBuilder.getIr)
              .toList();
  });
}

/// Returns an S-expression string for each compiled function.
List<String> stringifyAll(Iterable<FunctionDefinition> functions) {
  final stringifier = new SExpressionStringifier();
  return functions.map((f) => stringifier.visitFunctionDefinition(f)).toList();
}

Future<List<String>> testStringifier(String code,
                                     Iterable<String> expectedTokens) {
  return compile(code)
      .then((List<FunctionDefinition> functions) {
        List<String> sexprs = stringifyAll(functions);
        String combined = sexprs.join();
        String withoutNullConstants = combined.replaceAll("Constant null", "");

        Expect.isFalse(withoutNullConstants.contains("null"));
        for (String token in expectedTokens) {
          Expect.isTrue(combined.contains(token));
        }

        return sexprs;
      });
}

/// Checks if the generated S-expressions can be processed by the unstringifier,
/// returns the resulting definitions.
List<FunctionDefinition> testUnstringifier(List<String> sexprs) {
  return sexprs.map((String sexpr) {
    try {
      final function = new SExpressionUnstringifier().unstringify(sexpr);
      Expect.isNotNull(function, "Unstringification failed:\n\n$sexpr");
      return function;
    } catch (e, s) {
      print('$e\n$s');
      Expect.fail('Error unstringifying "$sexpr": $e');
    }
  }).toList();
}

void main() {
  final tokens =
          [ "FunctionDefinition"
          , "IsTrue"

          // Expressions
          , "Branch"
          , "ConcatenateStrings"
          , "DeclareFunction"
          , "InvokeConstructor"
          , "InvokeContinuation"
          , "InvokeMethod"
          , "InvokeStatic"
          , "InvokeSuperMethod"
          , "LetCont"
          , "LetPrim"
          , "SetClosureVariable"
          , "TypeOperator"

          // Primitives
          , "Constant"
          , "CreateFunction"
          , "GetClosureVariable"
          , "LiteralList"
          , "LiteralMap"
          // Parameters are encoded by name only and hence are not in this list.
          , "ReifyTypeVar"
          , "This"
          ];

  asyncTest(() => testStringifier(CODE, tokens).then((List<String> sexprs) {
    final functions = testUnstringifier(sexprs);

    // Ensure that
    // stringified(CODE) == stringified(unstringified(stringified(CODE)))
    Expect.listEquals(sexprs, stringifyAll(functions));
  }));
}
