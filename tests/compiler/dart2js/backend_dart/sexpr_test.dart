// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compiler_helper.dart';
import 'dart:async';
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import 'package:compiler/implementation/dart2jslib.dart';
import 'package:compiler/implementation/cps_ir/cps_ir_nodes.dart';
import 'package:compiler/implementation/dart_backend/dart_backend.dart';

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
  MockCompiler compiler = new MockCompiler.internal(
      emitJavaScript: false,
      enableMinification: false);

  return compiler.init().then((_) {
    compiler.parseScript(code);

    Element element = compiler.mainApp.find('main');
    if (element == null) return null;

    compiler.mainFunction = element;
    compiler.phase = Compiler.PHASE_RESOLVING;
    compiler.backend.enqueueHelpers(compiler.enqueuer.resolution,
                                    compiler.globalDependencies);
    compiler.processQueue(compiler.enqueuer.resolution, element);
    compiler.world.populate();
    compiler.backend.onResolutionComplete();

    compiler.irBuilder.buildNodes(useNewBackend: true);

    return compiler.enqueuer.resolution.resolvedElements
              .where(shouldOutput)
              .map(compiler.irBuilder.getIr)
              .toList();
  });
}

Future<String> testStringifier(String code, List<String> expectedTokens) {
  return compile(code)
      .then((List<FunctionDefinition> functions) {
        final stringifier = new SExpressionStringifier();
        List<String> sexprs = functions.map((f) {
          String sexpr = stringifier.visitFunctionDefinition(f);
          Expect.isNotNull(sexpr, "S-expression generation failed");
          return sexpr;
        });
        return sexprs.join("\n");
      })
      .then((String sexpr) {
        Expect.isFalse(sexpr.replaceAll("Constant null", "").contains("null"),
                       "Output contains 'null':\n\n$sexpr");

        expectedTokens.forEach((String token) {
          Expect.isTrue(sexpr.contains(token),
                        "Expected token '$token' not present:\n\n$sexpr");
        });

        return sexpr;
      });
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

  asyncTest(() => testStringifier(CODE, tokens));
}
