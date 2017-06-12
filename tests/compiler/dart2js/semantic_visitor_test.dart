// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.semantics_visitor_test;

import 'dart:async';
import 'dart:mirrors';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/diagnostics/spannable.dart';
import 'package:compiler/src/diagnostics/messages.dart' show MessageKind;
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/elements/operators.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/resolution/semantic_visitor.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/universe/call_structure.dart' show CallStructure;
import 'package:compiler/src/universe/selector.dart' show Selector;
import 'memory_compiler.dart';

part 'semantic_visitor_test_send_data.dart';
part 'semantic_visitor_test_send_visitor.dart';
part 'semantic_visitor_test_decl_data.dart';
part 'semantic_visitor_test_decl_visitor.dart';

class Visit {
  final VisitKind method;
  final element;
  final rhs;
  final arguments;
  final receiver;
  final name;
  final expression;
  final left;
  final right;
  final type;
  final operator;
  final index;
  final getter;
  final setter;
  final constant;
  final selector;
  final parameters;
  final body;
  final target;
  final targetType;
  final initializers;
  final error;

  const Visit(this.method,
      {this.element,
      this.rhs,
      this.arguments,
      this.receiver,
      this.name,
      this.expression,
      this.left,
      this.right,
      this.type,
      this.operator,
      this.index,
      this.getter,
      this.setter,
      this.constant,
      this.selector,
      this.parameters,
      this.body,
      this.target,
      this.targetType,
      this.initializers,
      this.error});

  int get hashCode => toString().hashCode;

  bool operator ==(other) => '$this' == '$other';

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('method=$method');
    if (element != null) {
      sb.write(',element=$element');
    }
    if (rhs != null) {
      sb.write(',rhs=$rhs');
    }
    if (arguments != null) {
      sb.write(',arguments=$arguments');
    }
    if (receiver != null) {
      sb.write(',receiver=$receiver');
    }
    if (name != null) {
      sb.write(',name=$name');
    }
    if (expression != null) {
      sb.write(',expression=$expression');
    }
    if (left != null) {
      sb.write(',left=$left');
    }
    if (right != null) {
      sb.write(',right=$right');
    }
    if (type != null) {
      sb.write(',type=$type');
    }
    if (operator != null) {
      sb.write(',operator=$operator');
    }
    if (index != null) {
      sb.write(',index=$index');
    }
    if (getter != null) {
      sb.write(',getter=$getter');
    }
    if (setter != null) {
      sb.write(',setter=$setter');
    }
    if (constant != null) {
      sb.write(',constant=$constant');
    }
    if (selector != null) {
      sb.write(',selector=$selector');
    }
    if (parameters != null) {
      sb.write(',parameters=$parameters');
    }
    if (body != null) {
      sb.write(',body=$body');
    }
    if (target != null) {
      sb.write(',target=$target');
    }
    if (targetType != null) {
      sb.write(',targetType=$targetType');
    }
    if (initializers != null) {
      sb.write(',initializers=$initializers');
    }
    if (error != null) {
      sb.write(',error=$error');
    }
    return sb.toString();
  }
}

class Test {
  final String codeByPrefix;
  final bool isDeferred;
  final String code;
  final /*Visit | List<Visit>*/ expectedVisits;
  final String cls;
  final String method;

  const Test(this.code, this.expectedVisits)
      : cls = null,
        method = 'm',
        codeByPrefix = null,
        isDeferred = false;
  const Test.clazz(this.code, this.expectedVisits,
      {this.cls: 'C', this.method: 'm'})
      : codeByPrefix = null,
        isDeferred = false;
  const Test.prefix(this.codeByPrefix, this.code, this.expectedVisits,
      {this.isDeferred: false})
      : cls = null,
        method = 'm';

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln();
    sb.writeln(code);
    if (codeByPrefix != null) {
      sb.writeln('imported by prefix:');
      sb.writeln(codeByPrefix);
    }
    return sb.toString();
  }
}

const List<VisitKind> UNTESTABLE_KINDS = const <VisitKind>[
  // A final field shadowing a non-final field is currently not supported in
  // resolution.
  VisitKind.VISIT_SUPER_FIELD_FIELD_COMPOUND,
  VisitKind.VISIT_SUPER_FIELD_FIELD_SET_IF_NULL,
  VisitKind.VISIT_SUPER_FIELD_FIELD_PREFIX,
  VisitKind.VISIT_SUPER_FIELD_FIELD_POSTFIX,
  // Combination of method and setter with the same name is currently not
  // supported by the element model.
  VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
  VisitKind.VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
  VisitKind.VISIT_STATIC_METHOD_SETTER_PREFIX,
  VisitKind.VISIT_STATIC_METHOD_SETTER_POSTFIX,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_COMPOUND,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_SET_IF_NULL,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_PREFIX,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_POSTFIX,
  VisitKind.VISIT_SUPER_METHOD_SETTER_COMPOUND,
  VisitKind.VISIT_SUPER_METHOD_SETTER_SET_IF_NULL,
  VisitKind.VISIT_SUPER_METHOD_SETTER_PREFIX,
  VisitKind.VISIT_SUPER_METHOD_SETTER_POSTFIX,
  // The only undefined unary, `+`, is currently handled and skipped in the
  // parser.
  VisitKind.ERROR_UNDEFINED_UNARY_EXPRESSION,
  // Constant expression are currently not computed during resolution.
  VisitKind.VISIT_CONSTANT_GET,
  VisitKind.VISIT_CONSTANT_INVOKE,
];

main(List<String> arguments) {
  Set<VisitKind> kinds = new Set<VisitKind>.from(VisitKind.values);
  asyncTest(() => Future.forEach([
        () {
          return test(kinds, arguments, SEND_TESTS,
              (elements) => new SemanticSendTestVisitor(elements));
        },
        () {
          return test(kinds, arguments, DECL_TESTS,
              (elements) => new SemanticDeclarationTestVisitor(elements));
        },
        () {
          Set<VisitKind> unvisitedKindSet = kinds.toSet()
            ..removeAll(UNTESTABLE_KINDS);
          List<VisitKind> unvisitedKindList = unvisitedKindSet.toList();
          unvisitedKindList..sort((a, b) => a.index.compareTo(b.index));

          Expect.isTrue(unvisitedKindList.isEmpty,
              "Untested visit kinds:\n  ${unvisitedKindList.join(',\n  ')},\n");

          Set<VisitKind> testedUntestableKinds = UNTESTABLE_KINDS.toSet()
            ..removeAll(kinds);
          Expect.isTrue(
              testedUntestableKinds.isEmpty,
              "Tested untestable visit kinds (remove from UNTESTABLE_KINDS):\n  "
              "${testedUntestableKinds.join(',\n  ')},\n");
        },
        () {
          ClassMirror mirror1 = reflectType(SemanticSendTestVisitor);
          Set<Symbol> symbols1 = mirror1.declarations.keys.toSet();
          ClassMirror mirror2 = reflectType(SemanticSendVisitor);
          Set<Symbol> symbols2 = mirror2.declarations.values
              .where((m) =>
                  m is MethodMirror &&
                  !m.isConstructor &&
                  m.simpleName != #apply)
              .map((m) => m.simpleName)
              .toSet();
          symbols2.removeAll(symbols1);
          Expect.isTrue(symbols2.isEmpty,
              "Untested visit methods:\n  ${symbols2.join(',\n  ')},\n");
        }
      ], (f) => f()));
}

Future test(
    Set<VisitKind> unvisitedKinds,
    List<String> arguments,
    Map<String, List<Test>> TESTS,
    SemanticTestVisitor createVisitor(TreeElements elements)) async {
  Map<String, String> sourceFiles = {};
  Map<String, Test> testMap = {};
  StringBuffer mainSource = new StringBuffer();
  int index = 0;
  TESTS.forEach((String group, List<Test> tests) {
    if (arguments.isNotEmpty && !arguments.contains(group)) return;

    tests.forEach((Test test) {
      StringBuffer testSource = new StringBuffer();
      if (test.codeByPrefix != null) {
        String prefixFilename = 'pre$index.dart';
        sourceFiles[prefixFilename] = test.codeByPrefix;
        if (test.isDeferred) {
          testSource.writeln("import '$prefixFilename' deferred as p;");
        } else {
          testSource.writeln("import '$prefixFilename' as p;");
        }
      }

      String filename = 'lib$index.dart';
      testSource.writeln(test.code);
      sourceFiles[filename] = testSource.toString();
      mainSource.writeln("import '$filename';");
      testMap[filename] = test;
      index++;
    });
  });
  mainSource.writeln("main() {}");
  sourceFiles['main.dart'] = mainSource.toString();

  CompilationResult result = await runCompiler(
      memorySourceFiles: sourceFiles,
      options: [Flags.analyzeAll, Flags.analyzeOnly]);
  Compiler compiler = result.compiler;
  testMap.forEach((String filename, Test test) {
    LibraryElement library =
        compiler.libraryLoader.lookupLibrary(Uri.parse('memory:$filename'));
    Element element;
    String cls = test.cls;
    String method = test.method;
    if (cls == null) {
      element = library.find(method);
    } else {
      ClassElement classElement = library.find(cls);
      Expect.isNotNull(
          classElement,
          "Class '$cls' not found in:\n"
          "${library.compilationUnit.script.text}");
      element = classElement.localLookup(method);
    }
    var expectedVisits = test.expectedVisits;
    if (expectedVisits == null) {
      Expect.isTrue(
          element.isMalformed,
          "Element '$method' expected to be have parse errors in:\n"
          "${library.compilationUnit.script.text}");
      return;
    } else if (expectedVisits is! List) {
      expectedVisits = [expectedVisits];
    }
    Expect.isFalse(
        element.isMalformed,
        "Element '$method' is not expected to be have parse errors in:\n"
        "${library.compilationUnit.script.text}");

    void testAstElement(AstElement astElement) {
      Expect.isNotNull(
          astElement,
          "Element '$method' not found in:\n"
          "${library.compilationUnit.script.text}");
      ResolvedAst resolvedAst = astElement.resolvedAst;
      SemanticTestVisitor visitor = createVisitor(resolvedAst.elements);
      try {
        compiler.reporter.withCurrentElement(resolvedAst.element, () {
          //print(resolvedAst.node.toDebugString());
          resolvedAst.node.accept(visitor);
        });
      } catch (e, s) {
        Expect.fail("$e:\n$s\nIn test:\n"
            "${library.compilationUnit.script.text}");
      }
      Expect.listEquals(
          expectedVisits,
          visitor.visits,
          "In test:\n"
          "${library.compilationUnit.script.text}\n\n"
          "Expected: $expectedVisits\n"
          "Found: ${visitor.visits}");
      unvisitedKinds.removeAll(visitor.visits.map((visit) => visit.method));
    }

    if (element.isAbstractField) {
      AbstractFieldElement abstractFieldElement = element;
      if (abstractFieldElement.getter != null) {
        testAstElement(abstractFieldElement.getter);
      } else if (abstractFieldElement.setter != null) {
        testAstElement(abstractFieldElement.setter);
      }
    } else {
      testAstElement(element);
    }
  });
}

abstract class SemanticTestVisitor extends TraversalVisitor {
  List<Visit> visits = <Visit>[];

  SemanticTestVisitor(TreeElements elements) : super(elements);

  apply(Node node, arg) => node.accept(this);

  internalError(Spannable spannable, String message) {
    throw new SpannableAssertionFailure(spannable, message);
  }
}

enum VisitKind {
  VISIT_PARAMETER_GET,
  VISIT_PARAMETER_SET,
  VISIT_PARAMETER_INVOKE,
  VISIT_PARAMETER_COMPOUND,
  VISIT_PARAMETER_SET_IF_NULL,
  VISIT_PARAMETER_PREFIX,
  VISIT_PARAMETER_POSTFIX,
  VISIT_FINAL_PARAMETER_SET,
  VISIT_FINAL_PARAMETER_COMPOUND,
  VISIT_FINAL_PARAMETER_SET_IF_NULL,
  VISIT_FINAL_PARAMETER_PREFIX,
  VISIT_FINAL_PARAMETER_POSTFIX,
  VISIT_LOCAL_VARIABLE_GET,
  VISIT_LOCAL_VARIABLE_SET,
  VISIT_LOCAL_VARIABLE_INVOKE,
  VISIT_LOCAL_VARIABLE_COMPOUND,
  VISIT_LOCAL_VARIABLE_SET_IF_NULL,
  VISIT_LOCAL_VARIABLE_PREFIX,
  VISIT_LOCAL_VARIABLE_POSTFIX,
  VISIT_LOCAL_VARIABLE_DECL,
  VISIT_LOCAL_CONSTANT_DECL,
  VISIT_FINAL_LOCAL_VARIABLE_SET,
  VISIT_FINAL_LOCAL_VARIABLE_COMPOUND,
  VISIT_FINAL_LOCAL_VARIABLE_SET_IF_NULL,
  VISIT_FINAL_LOCAL_VARIABLE_PREFIX,
  VISIT_FINAL_LOCAL_VARIABLE_POSTFIX,
  VISIT_LOCAL_FUNCTION_GET,
  VISIT_LOCAL_FUNCTION_INVOKE,
  VISIT_LOCAL_FUNCTION_INCOMPATIBLE_INVOKE,
  VISIT_LOCAL_FUNCTION_DECL,
  VISIT_CLOSURE_DECL,
  VISIT_LOCAL_FUNCTION_SET,
  VISIT_LOCAL_FUNCTION_COMPOUND,
  VISIT_LOCAL_FUNCTION_SET_IF_NULL,
  VISIT_LOCAL_FUNCTION_PREFIX,
  VISIT_LOCAL_FUNCTION_POSTFIX,
  VISIT_STATIC_FIELD_GET,
  VISIT_STATIC_FIELD_SET,
  VISIT_STATIC_FIELD_INVOKE,
  VISIT_STATIC_FIELD_COMPOUND,
  VISIT_STATIC_FIELD_SET_IF_NULL,
  VISIT_STATIC_FIELD_PREFIX,
  VISIT_STATIC_FIELD_POSTFIX,
  VISIT_STATIC_FIELD_DECL,
  VISIT_STATIC_CONSTANT_DECL,
  VISIT_STATIC_GETTER_GET,
  VISIT_STATIC_GETTER_SET,
  VISIT_STATIC_GETTER_INVOKE,
  VISIT_STATIC_SETTER_GET,
  VISIT_STATIC_SETTER_SET,
  VISIT_STATIC_SETTER_INVOKE,
  VISIT_STATIC_GETTER_SETTER_COMPOUND,
  VISIT_STATIC_GETTER_SETTER_SET_IF_NULL,
  VISIT_STATIC_METHOD_SETTER_COMPOUND,
  VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
  VISIT_STATIC_GETTER_SETTER_PREFIX,
  VISIT_STATIC_GETTER_SETTER_POSTFIX,
  VISIT_STATIC_GETTER_DECL,
  VISIT_STATIC_SETTER_DECL,
  VISIT_FINAL_STATIC_FIELD_SET,
  VISIT_STATIC_FINAL_FIELD_COMPOUND,
  VISIT_STATIC_FINAL_FIELD_SET_IF_NULL,
  VISIT_STATIC_FINAL_FIELD_POSTFIX,
  VISIT_STATIC_FINAL_FIELD_PREFIX,
  VISIT_STATIC_FUNCTION_GET,
  VISIT_STATIC_FUNCTION_SET,
  VISIT_STATIC_FUNCTION_INVOKE,
  VISIT_STATIC_FUNCTION_INCOMPATIBLE_INVOKE,
  VISIT_STATIC_FUNCTION_DECL,
  VISIT_STATIC_METHOD_SETTER_PREFIX,
  VISIT_STATIC_METHOD_SETTER_POSTFIX,
  VISIT_UNRESOLVED_STATIC_GETTER_COMPOUND,
  VISIT_UNRESOLVED_STATIC_GETTER_SET_IF_NULL,
  VISIT_UNRESOLVED_STATIC_SETTER_COMPOUND,
  VISIT_UNRESOLVED_STATIC_SETTER_SET_IF_NULL,
  VISIT_STATIC_METHOD_COMPOUND,
  VISIT_STATIC_METHOD_SET_IF_NULL,
  VISIT_UNRESOLVED_STATIC_GETTER_PREFIX,
  VISIT_UNRESOLVED_STATIC_SETTER_PREFIX,
  VISIT_STATIC_METHOD_PREFIX,
  VISIT_UNRESOLVED_STATIC_GETTER_POSTFIX,
  VISIT_UNRESOLVED_STATIC_SETTER_POSTFIX,
  VISIT_STATIC_METHOD_POSTFIX,
  VISIT_TOP_LEVEL_FIELD_GET,
  VISIT_TOP_LEVEL_FIELD_SET,
  VISIT_TOP_LEVEL_FIELD_INVOKE,
  VISIT_FINAL_TOP_LEVEL_FIELD_SET,
  VISIT_TOP_LEVEL_FIELD_COMPOUND,
  VISIT_TOP_LEVEL_FIELD_SET_IF_NULL,
  VISIT_TOP_LEVEL_FIELD_PREFIX,
  VISIT_TOP_LEVEL_FIELD_POSTFIX,
  VISIT_TOP_LEVEL_FIELD_DECL,
  VISIT_TOP_LEVEL_CONSTANT_DECL,
  VISIT_TOP_LEVEL_FINAL_FIELD_COMPOUND,
  VISIT_TOP_LEVEL_FINAL_FIELD_SET_IF_NULL,
  VISIT_TOP_LEVEL_FINAL_FIELD_POSTFIX,
  VISIT_TOP_LEVEL_FINAL_FIELD_PREFIX,
  VISIT_TOP_LEVEL_GETTER_GET,
  VISIT_TOP_LEVEL_GETTER_SET,
  VISIT_TOP_LEVEL_GETTER_INVOKE,
  VISIT_TOP_LEVEL_SETTER_GET,
  VISIT_TOP_LEVEL_SETTER_SET,
  VISIT_TOP_LEVEL_SETTER_INVOKE,
  VISIT_TOP_LEVEL_GETTER_SETTER_COMPOUND,
  VISIT_TOP_LEVEL_GETTER_SETTER_SET_IF_NULL,
  VISIT_TOP_LEVEL_GETTER_SETTER_PREFIX,
  VISIT_TOP_LEVEL_GETTER_SETTER_POSTFIX,
  VISIT_TOP_LEVEL_GETTER_DECL,
  VISIT_TOP_LEVEL_SETTER_DECL,
  VISIT_TOP_LEVEL_FUNCTION_GET,
  VISIT_TOP_LEVEL_FUNCTION_SET,
  VISIT_TOP_LEVEL_FUNCTION_INVOKE,
  VISIT_TOP_LEVEL_FUNCTION_INCOMPATIBLE_INVOKE,
  VISIT_TOP_LEVEL_FUNCTION_DECL,
  VISIT_TOP_LEVEL_METHOD_SETTER_COMPOUND,
  VISIT_TOP_LEVEL_METHOD_SETTER_SET_IF_NULL,
  VISIT_TOP_LEVEL_METHOD_SETTER_PREFIX,
  VISIT_TOP_LEVEL_METHOD_SETTER_POSTFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_COMPOUND,
  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_SET_IF_NULL,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_COMPOUND,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_SET_IF_NULL,
  VISIT_TOP_LEVEL_METHOD_COMPOUND,
  VISIT_TOP_LEVEL_METHOD_SET_IF_NULL,
  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_PREFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_PREFIX,
  VISIT_TOP_LEVEL_METHOD_PREFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_POSTFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_POSTFIX,
  VISIT_TOP_LEVEL_METHOD_POSTFIX,
  VISIT_DYNAMIC_PROPERTY_GET,
  VISIT_DYNAMIC_PROPERTY_SET,
  VISIT_DYNAMIC_PROPERTY_INVOKE,
  VISIT_DYNAMIC_PROPERTY_COMPOUND,
  VISIT_DYNAMIC_PROPERTY_SET_IF_NULL,
  VISIT_DYNAMIC_PROPERTY_PREFIX,
  VISIT_DYNAMIC_PROPERTY_POSTFIX,
  VISIT_THIS_GET,
  VISIT_THIS_INVOKE,
  VISIT_THIS_PROPERTY_GET,
  VISIT_THIS_PROPERTY_SET,
  VISIT_THIS_PROPERTY_INVOKE,
  VISIT_THIS_PROPERTY_COMPOUND,
  VISIT_THIS_PROPERTY_SET_IF_NULL,
  VISIT_THIS_PROPERTY_PREFIX,
  VISIT_THIS_PROPERTY_POSTFIX,
  VISIT_SUPER_FIELD_GET,
  VISIT_SUPER_FIELD_SET,
  VISIT_FINAL_SUPER_FIELD_SET,
  VISIT_SUPER_FIELD_INVOKE,
  VISIT_SUPER_FIELD_COMPOUND,
  VISIT_SUPER_FIELD_SET_IF_NULL,
  VISIT_SUPER_FIELD_PREFIX,
  VISIT_SUPER_FIELD_POSTFIX,
  VISIT_SUPER_FINAL_FIELD_COMPOUND,
  VISIT_SUPER_FINAL_FIELD_SET_IF_NULL,
  VISIT_SUPER_FINAL_FIELD_PREFIX,
  VISIT_SUPER_FINAL_FIELD_POSTFIX,
  VISIT_SUPER_FIELD_FIELD_COMPOUND,
  VISIT_SUPER_FIELD_FIELD_SET_IF_NULL,
  VISIT_SUPER_FIELD_FIELD_PREFIX,
  VISIT_SUPER_FIELD_FIELD_POSTFIX,
  VISIT_SUPER_GETTER_GET,
  VISIT_SUPER_GETTER_SET,
  VISIT_SUPER_GETTER_INVOKE,
  VISIT_SUPER_SETTER_GET,
  VISIT_SUPER_SETTER_SET,
  VISIT_SUPER_SETTER_INVOKE,
  VISIT_SUPER_GETTER_SETTER_COMPOUND,
  VISIT_SUPER_GETTER_SETTER_SET_IF_NULL,
  VISIT_SUPER_GETTER_FIELD_COMPOUND,
  VISIT_SUPER_GETTER_FIELD_SET_IF_NULL,
  VISIT_SUPER_FIELD_SETTER_COMPOUND,
  VISIT_SUPER_FIELD_SETTER_SET_IF_NULL,
  VISIT_SUPER_GETTER_SETTER_PREFIX,
  VISIT_SUPER_GETTER_FIELD_PREFIX,
  VISIT_SUPER_FIELD_SETTER_PREFIX,
  VISIT_SUPER_GETTER_SETTER_POSTFIX,
  VISIT_SUPER_GETTER_FIELD_POSTFIX,
  VISIT_SUPER_FIELD_SETTER_POSTFIX,
  VISIT_SUPER_METHOD_GET,
  VISIT_SUPER_METHOD_SET,
  VISIT_SUPER_METHOD_INVOKE,
  VISIT_SUPER_METHOD_INCOMPATIBLE_INVOKE,
  VISIT_SUPER_METHOD_SETTER_COMPOUND,
  VISIT_SUPER_METHOD_SETTER_SET_IF_NULL,
  VISIT_SUPER_METHOD_SETTER_PREFIX,
  VISIT_SUPER_METHOD_SETTER_POSTFIX,
  VISIT_SUPER_METHOD_COMPOUND,
  VISIT_SUPER_METHOD_SET_IF_NULL,
  VISIT_SUPER_METHOD_PREFIX,
  VISIT_SUPER_METHOD_POSTFIX,
  VISIT_UNRESOLVED_GET,
  VISIT_UNRESOLVED_SET,
  VISIT_UNRESOLVED_INVOKE,
  VISIT_UNRESOLVED_SUPER_GET,
  VISIT_UNRESOLVED_SUPER_INVOKE,
  VISIT_UNRESOLVED_SUPER_SET,
  VISIT_BINARY,
  VISIT_INDEX,
  VISIT_EQUALS,
  VISIT_NOT_EQUALS,
  VISIT_INDEX_PREFIX,
  VISIT_INDEX_POSTFIX,
  VISIT_SUPER_BINARY,
  VISIT_UNRESOLVED_SUPER_BINARY,
  VISIT_SUPER_INDEX,
  VISIT_UNRESOLVED_SUPER_INDEX,
  VISIT_SUPER_EQUALS,
  VISIT_SUPER_NOT_EQUALS,
  VISIT_SUPER_INDEX_PREFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND,
  VISIT_UNRESOLVED_SUPER_GETTER_SET_IF_NULL,
  VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND,
  VISIT_UNRESOLVED_SUPER_SETTER_SET_IF_NULL,
  VISIT_UNRESOLVED_SUPER_GETTER_PREFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_PREFIX,
  VISIT_UNRESOLVED_SUPER_INDEX_PREFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_INDEX_PREFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_INDEX_PREFIX,
  VISIT_SUPER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_POSTFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_POSTFIX,
  VISIT_UNRESOLVED_SUPER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_COMPOUND,
  VISIT_UNRESOLVED_SUPER_SET_IF_NULL,
  VISIT_UNRESOLVED_SUPER_PREFIX,
  VISIT_UNRESOLVED_SUPER_POSTFIX,
  VISIT_UNARY,
  VISIT_SUPER_UNARY,
  VISIT_UNRESOLVED_SUPER_UNARY,
  VISIT_NOT,
  VISIT_EXPRESSION_INVOKE,
  VISIT_CLASS_TYPE_LITERAL_GET,
  VISIT_CLASS_TYPE_LITERAL_SET,
  VISIT_CLASS_TYPE_LITERAL_INVOKE,
  VISIT_CLASS_TYPE_LITERAL_COMPOUND,
  VISIT_CLASS_TYPE_LITERAL_SET_IF_NULL,
  VISIT_CLASS_TYPE_LITERAL_PREFIX,
  VISIT_CLASS_TYPE_LITERAL_POSTFIX,
  VISIT_TYPEDEF_TYPE_LITERAL_GET,
  VISIT_TYPEDEF_TYPE_LITERAL_SET,
  VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
  VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
  VISIT_TYPEDEF_TYPE_LITERAL_SET_IF_NULL,
  VISIT_TYPEDEF_TYPE_LITERAL_PREFIX,
  VISIT_TYPEDEF_TYPE_LITERAL_POSTFIX,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_GET,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET_IF_NULL,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,
  VISIT_DYNAMIC_TYPE_LITERAL_GET,
  VISIT_DYNAMIC_TYPE_LITERAL_SET,
  VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
  VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
  VISIT_DYNAMIC_TYPE_LITERAL_SET_IF_NULL,
  VISIT_DYNAMIC_TYPE_LITERAL_PREFIX,
  VISIT_DYNAMIC_TYPE_LITERAL_POSTFIX,
  VISIT_INDEX_SET,
  VISIT_COMPOUND_INDEX_SET,
  VISIT_SUPER_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_INDEX_SET,
  VISIT_SUPER_COMPOUND_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_COMPOUND_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND_INDEX_SET,
  VISIT_INDEX_SET_IF_NULL,
  VISIT_SUPER_INDEX_SET_IF_NULL,
  VISIT_UNRESOLVED_SUPER_INDEX_SET_IF_NULL,
  VISIT_UNRESOLVED_SUPER_GETTER_INDEX_SET_IF_NULL,
  VISIT_UNRESOLVED_SUPER_SETTER_INDEX_SET_IF_NULL,
  VISIT_LOGICAL_AND,
  VISIT_LOGICAL_OR,
  VISIT_IS,
  VISIT_IS_NOT,
  VISIT_AS,
  VISIT_CONST_CONSTRUCTOR_INVOKE,
  VISIT_BOOL_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
  VISIT_INT_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
  VISIT_STRING_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
  VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
  VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
  VISIT_FACTORY_CONSTRUCTOR_INVOKE,
  VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
  VISIT_CONSTRUCTOR_INCOMPATIBLE_INVOKE,
  ERROR_NON_CONSTANT_CONSTRUCTOR_INVOKE,
  VISIT_SUPER_CONSTRUCTOR_INVOKE,
  VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
  VISIT_THIS_CONSTRUCTOR_INVOKE,
  VISIT_FIELD_INITIALIZER,
  VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
  VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
  VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
  VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
  VISIT_INSTANCE_GETTER_DECL,
  VISIT_INSTANCE_SETTER_DECL,
  VISIT_INSTANCE_METHOD_DECL,
  VISIT_ABSTRACT_GETTER_DECL,
  VISIT_ABSTRACT_SETTER_DECL,
  VISIT_ABSTRACT_METHOD_DECL,
  VISIT_INSTANCE_FIELD_DECL,
  VISIT_GENERATIVE_CONSTRUCTOR_DECL,
  VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_DECL,
  VISIT_FACTORY_CONSTRUCTOR_DECL,
  VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
  VISIT_REQUIRED_PARAMETER_DECL,
  VISIT_OPTIONAL_PARAMETER_DECL,
  VISIT_NAMED_PARAMETER_DECL,
  VISIT_REQUIRED_INITIALIZING_FORMAL_DECL,
  VISIT_OPTIONAL_INITIALIZING_FORMAL_DECL,
  VISIT_NAMED_INITIALIZING_FORMAL_DECL,
  VISIT_UNRESOLVED_COMPOUND,
  VISIT_UNRESOLVED_SET_IF_NULL,
  VISIT_UNRESOLVED_PREFIX,
  VISIT_UNRESOLVED_POSTFIX,
  VISIT_IF_NULL,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_GET,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_SET,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_INVOKE,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_COMPOUND,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_SET_IF_NULL,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_PREFIX,
  VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_POSTFIX,
  ERROR_UNDEFINED_UNARY_EXPRESSION,
  ERROR_UNDEFINED_BINARY_EXPRESSION,
  ERROR_INVALID_GET,
  ERROR_INVALID_INVOKE,
  ERROR_INVALID_SET,
  ERROR_INVALID_PREFIX,
  ERROR_INVALID_POSTFIX,
  ERROR_INVALID_COMPOUND,
  ERROR_INVALID_SET_IF_NULL,
  ERROR_INVALID_UNARY,
  ERROR_INVALID_EQUALS,
  ERROR_INVALID_NOT_EQUALS,
  ERROR_INVALID_BINARY,
  ERROR_INVALID_INDEX,
  ERROR_INVALID_INDEX_SET,
  ERROR_INVALID_COMPOUND_INDEX_SET,
  ERROR_INVALID_INDEX_PREFIX,
  ERROR_INVALID_INDEX_POSTFIX,
  VISIT_CONSTANT_GET,
  VISIT_CONSTANT_INVOKE,
  PREVISIT_DEFERRED_ACCESS,
}
