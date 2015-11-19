// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the CPS IR code generator generates source information.

library source_information_tests;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/apiimpl.dart'
       show CompilerImpl;
import 'memory_compiler.dart';
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart' as ir;
import 'package:compiler/src/cps_ir/cps_ir_nodes_sexpr.dart' as ir;
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/elements/elements.dart';

const String TEST_MAIN_FILE = 'test.dart';

class TestEntry {
  final String source;
  final List<String> expectation;
  final String elementName;

  const TestEntry(this.source, this.expectation)
    : elementName = null;

  const TestEntry.forMethod(this.elementName,
      this.source, this.expectation);
}

String formatTest(Map test) {
  return test[TEST_MAIN_FILE];
}

js.Node getCodeForMain(CompilerImpl compiler) {
  Element mainFunction = compiler.mainFunction;
  return compiler.enqueuer.codegen.generatedCode[mainFunction];
}

js.Node getJsNodeForElement(CompilerImpl compiler, Element element) {
  return compiler.enqueuer.codegen.generatedCode[element];
}

String getCodeForMethod(CompilerImpl compiler, String name) {
  Element foundElement;
  for (Element element in compiler.enqueuer.codegen.generatedCode.keys) {
    if (element.toString() == name) {
      if (foundElement != null) {
        Expect.fail('Multiple compiled elements are called $name');
      }
      foundElement = element;
    }
  }

  if (foundElement == null) {
    Expect.fail('There is no compiled element called $name');
  }

  js.Node ast = compiler.enqueuer.codegen.generatedCode[foundElement];
  return js.prettyPrint(ast, compiler).getText();
}

runTests(List<TestEntry> tests) {
  for (TestEntry test in tests) {
    Map files = {TEST_MAIN_FILE: test.source};
    asyncTest(() {
      CompilerImpl compiler = compilerFor(
          memorySourceFiles: files, options: <String>['--use-cps-ir']);
      ir.FunctionDefinition irNodeForMain;

      void cacheIrNodeForMain(Element function, ir.FunctionDefinition irNode) {
        if (function == compiler.mainFunction) {
          assert(irNodeForMain == null);
          irNodeForMain = irNode;
        }
      }

      Uri uri = Uri.parse('memory:$TEST_MAIN_FILE');
      compiler.backend.functionCompiler.cpsBuilderTask.builderCallback =
          cacheIrNodeForMain;

      return compiler.run(uri).then((bool success) {
        Expect.isTrue(success);

        IrSourceInformationVisitor irVisitor = new IrSourceInformationVisitor();
        irNodeForMain.accept(irVisitor);

        js.Node jsNode = getJsNodeForElement(compiler, compiler.mainFunction);
        JsSourceInformationVisitor jsVisitor = new JsSourceInformationVisitor();
        jsNode.accept(jsVisitor);

        List<String> expectation = test.expectation;
        // Visiting of CPS is in structural order so we check for set equality.
        Expect.setEquals(expectation, irVisitor.sourceInformation,
              'Unexpected IR source information. '
              'Expected:\n$expectation\n'
              'but found\n${irVisitor.sourceInformation}\n'
              'in\n${test.source}'
              'CPS:\n${irNodeForMain.accept(new ir.SExpressionStringifier())}');
        Expect.listEquals(expectation, jsVisitor.sourceInformation,
              'Unexpected JS source information. '
              'Expected:\n$expectation\n'
              'but found\n${jsVisitor.sourceInformation}\n'
              'in\n${test.source}');
      }).catchError((e) {
        print(e);
        Expect.fail('The following test failed to compile:\n'
                    '${formatTest(files)}');
      });
    });
  }
}

class JsSourceInformationVisitor extends js.BaseVisitor {
  List<String> sourceInformation = <String>[];

  @override
  visitCall(js.Call node) {
    sourceInformation.add('${node.sourceInformation}');
    super.visitCall(node);
  }
}

class IrSourceInformationVisitor extends ir.TrampolineRecursiveVisitor {
  List<String> sourceInformation = <String>[];

  @override
  processInvokeStatic(ir.InvokeStatic node) {
    sourceInformation.add('${node.sourceInformation}');
  }
}

const List<TestEntry> tests = const [
  const TestEntry("""
main() { print('Hello World'); }
""", const ['memory:test.dart:[1,10]']),
const TestEntry("""
main() {
  print('Hello');
  print('World');
}
""", const ['memory:test.dart:[2,3]',
            'memory:test.dart:[3,3]']),
];

void main() {
  runTests(tests);
}
