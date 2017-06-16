// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.analyze_helpers.test;

import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart' show Diagnostic;
import 'package:compiler/src/apiimpl.dart' show CompilerImpl;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/constants/expressions.dart'
    show ConstructedConstantExpression;
import 'package:compiler/src/elements/resolution_types.dart'
    show ResolutionInterfaceType;
import 'package:compiler/src/diagnostics/source_span.dart' show SourceSpan;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart' show nativeToUriPath;
import 'package:compiler/src/resolution/semantic_visitor.dart';
import 'package:compiler/src/resolution/tree_elements.dart' show TreeElements;
import 'package:compiler/src/source_file_provider.dart'
    show FormattingDiagnosticHandler;
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/universe/call_structure.dart' show CallStructure;
import 'package:expect/expect.dart';

import 'memory_compiler.dart';

main(List<String> arguments) {
  bool verbose = arguments.contains('-v');

  List<String> options = <String>[
    Flags.analyzeOnly,
    Flags.analyzeMain,
    '--categories=Client,Server'
  ];
  if (verbose) {
    options.add(Flags.verbose);
  }
  asyncTest(() async {
    CompilerImpl compiler =
        compilerFor(options: options, showDiagnostics: verbose);
    FormattingDiagnosticHandler diagnostics =
        new FormattingDiagnosticHandler(compiler.provider);
    Directory dir =
        new Directory.fromUri(Uri.base.resolve('pkg/compiler/lib/'));
    String helpersUriPrefix = dir.uri.resolve('src/helpers/').toString();
    HelperAnalyzer analyzer = new HelperAnalyzer(diagnostics, helpersUriPrefix);
    LibraryElement helperLibrary;
    for (FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        Uri file = Uri.base.resolve(nativeToUriPath(entity.path));
        if (verbose) {
          print('---- analyzing $file ----');
        }
        LibraryElement library = await compiler.analyzeUri(file);
        if (library != null) {
          if (library.libraryName == 'dart2js.helpers') {
            helperLibrary = library;
          }
          library.forEachLocalMember((Element element) {
            if (element is ClassElement) {
              element.forEachLocalMember((_member) {
                AstElement member = _member;
                analyzer.analyze(member.resolvedAst);
              });
            } else if (element is MemberElement) {
              analyzer.analyze(element.resolvedAst);
            }
          });
        }
      }
    }
    Expect.isNotNull(helperLibrary, 'Helper library not found');
    Expect.isTrue(analyzer.isHelper(helperLibrary),
        "Helper library $helperLibrary is not considered a helper.");
    Expect.isTrue(analyzer.errors.isEmpty, "Errors found.");
  });
}

class HelperAnalyzer extends TraversalVisitor {
  final FormattingDiagnosticHandler diagnostics;
  final String helpersUriPrefix;
  List<SourceSpan> errors = <SourceSpan>[];

  ResolvedAst resolvedAst;

  @override
  TreeElements get elements => resolvedAst.elements;

  AnalyzableElement get analyzedElement => resolvedAst.element;

  HelperAnalyzer(this.diagnostics, this.helpersUriPrefix) : super(null);

  @override
  void apply(Node node, [_]) {
    node.accept(this);
  }

  void analyze(ResolvedAst resolvedAst) {
    if (resolvedAst.kind != ResolvedAstKind.PARSED) {
      // Skip synthesized members.
      return;
    }
    this.resolvedAst = resolvedAst;
    apply(resolvedAst.node);
    this.resolvedAst = null;
  }

  bool isHelper(Element element) {
    Uri uri = element.library.canonicalUri;
    return '$uri'.startsWith(helpersUriPrefix);
  }

  void checkAccess(Node node, MemberElement element) {
    if (isHelper(element) && !isHelper(analyzedElement)) {
      Uri uri = analyzedElement.implementation.sourcePosition.uri;
      SourceSpan span = new SourceSpan.fromNode(uri, node);
      diagnostics.report(null, span.uri, span.begin, span.end,
          "Helper used in production code.", Diagnostic.ERROR);
      errors.add(span);
    }
  }

  @override
  void visitTopLevelFieldInvoke(Send node, FieldElement field,
      NodeList arguments, CallStructure callStructure, _) {
    checkAccess(node, field);
    apply(arguments);
  }

  @override
  void visitTopLevelGetterInvoke(Send node, GetterElement getter,
      NodeList arguments, CallStructure callStructure, _) {
    checkAccess(node, getter);
    apply(arguments);
  }

  @override
  void visitTopLevelFunctionInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, _) {
    checkAccess(node, method);
    apply(arguments);
  }

  @override
  void visitTopLevelFieldGet(Send node, FieldElement field, _) {
    checkAccess(node, field);
  }

  @override
  void visitTopLevelGetterGet(Send node, GetterElement getter, _) {
    checkAccess(node, getter);
  }

  @override
  void visitTopLevelFunctionGet(Send node, MethodElement method, _) {
    checkAccess(node, method);
  }

  @override
  void visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    checkAccess(node, constructor);
    apply(arguments);
  }

  @override
  void visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    checkAccess(node, constructor);
    apply(arguments);
  }

  @override
  void visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    checkAccess(node, constructor);
    apply(arguments);
  }

  @override
  void visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      ConstructorElement effectiveTarget,
      ResolutionInterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    checkAccess(node, constructor);
    apply(arguments);
  }

  @override
  void visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, _) {
    ConstructorElement constructor = constant.target;
    checkAccess(node, constructor);
  }
}
