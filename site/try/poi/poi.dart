// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi;

import 'dart:async' show
    Future;

import 'dart:io' show
    Platform;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    reuseCompiler;

import 'package:compiler/implementation/source_file_provider.dart' show
    FormattingDiagnosticHandler,
    SourceFileProvider;

import 'package:compiler/compiler.dart' as api show
    Diagnostic;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler,
    Enqueuer,
    QueueFilter,
    WorkItem;

import 'package:compiler/implementation/elements/visitor.dart' show
    ElementVisitor;

import 'package:compiler/implementation/elements/elements.dart' show
    ClassElement,
    Element,
    ScopeContainerElement;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    PartialClassElement,
    PartialElement;

main(List<String> arguments) {
  Uri script = Uri.base.resolve(arguments.first);
  int position = int.parse(arguments[1]);
  return runPoi(script, position).then((Element element) {
    print('Found $element.');
  });
}

Future<Element> runPoi(Uri script, int position) {
  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();
  handler
      ..verbose = true
      ..enableColors = true;

  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${Platform.packageRoot}/'));

  var options = [
      '--analyze-main',
      '--analyze-only',
      '--no-source-maps',
      '--verbose',
      '--categories=Client,Server',
  ];

  Compiler cachedCompiler = null;
  cachedCompiler = reuseCompiler(
      diagnosticHandler: handler,
      inputProvider: handler.provider,
      options: options,
      cachedCompiler: cachedCompiler,
      libraryRoot: libraryRoot,
      packageRoot: packageRoot,
      packagesAreImmutable: true);

  cachedCompiler.enqueuerFilter = new ScriptOnlyFilter(script);

  return cachedCompiler.run(script).then((success) {
    if (success != true) {
      throw 'Compilation failed';
    }
    return poi(cachedCompiler, script, position);
  });
}

Element poi(Compiler compiler, Uri script, int offset) {
  compiler.handler(
      script, offset, offset + 1,
      'Point of interest.', api.Diagnostic.HINT);

  Element element = findPosition(offset, compiler.mainApp);

  return element;
}

Element findPosition(int position, Element element) {
  FindPositionVisitor visitor = new FindPositionVisitor(position, element);
  element.accept(visitor);
  return visitor.element;
}

class FindPositionVisitor extends ElementVisitor {
  final int position;
  Element element;

  FindPositionVisitor(this.position, this.element);

  visitElement(Element e) {
    if (e is! PartialElement) return;
    if (e.beginToken.charOffset <= position &&
        position < e.endToken.next.charOffset) {
      element = e;
    }
  }

  visitClassElement(ClassElement e) {
    if (e is! PartialClassElement) return;
    if (e.beginToken.charOffset <= position &&
        position < e.endToken.next.charOffset) {
      element = e;
      visitScopeContainerElement(e);
    }
  }

  visitScopeContainerElement(ScopeContainerElement e) {
    e.forEachLocalMember((Element element) => element.accept(this));
  }
}

class ScriptOnlyFilter implements QueueFilter {
  final Uri script;

  ScriptOnlyFilter(this.script);

  bool checkNoEnqueuedInvokedInstanceMethods(Enqueuer enqueuer) => true;

  void processWorkItem(void f(WorkItem work), WorkItem work) {
    if (work.element.library.canonicalUri == script) {
      f(work);
    }
  }
}
