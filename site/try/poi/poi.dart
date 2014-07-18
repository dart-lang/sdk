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

import 'package:compiler/compiler.dart' as api;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler,
    Enqueuer,
    QueueFilter,
    WorkItem;

import 'package:compiler/implementation/elements/visitor.dart' show
    ElementVisitor;

import 'package:compiler/implementation/elements/elements.dart' show
    ClassElement,
    CompilationUnitElement,
    Element,
    LibraryElement,
    ScopeContainerElement;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    PartialClassElement,
    PartialElement;

import 'package:compiler/implementation/util/uri_extras.dart' show
    relativize;

main(List<String> arguments) {
  Uri script = Uri.base.resolve(arguments.first);
  int position = int.parse(arguments[1]);

  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();
  handler
      ..verbose = true
      ..enableColors = true;
  api.CompilerInputProvider inputProvider = handler.provider;

  inputProvider(script);
  handler(
      script, position, position + 1,
      'Point of interest.', api.Diagnostic.HINT);

  Future future = runPoi(script, position, inputProvider, handler);
  return future.then((Element element) {
    print(scopeInformation(element, position));
  });
}

Future<Element> runPoi(
    Uri script, int position,
    api.CompilerInputProvider inputProvider,
    api.DiagnosticHandler handler) {

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
      inputProvider: inputProvider,
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
    return findPosition(position, cachedCompiler.mainApp);
  });
}

Element findPosition(int position, Element element) {
  FindPositionVisitor visitor = new FindPositionVisitor(position, element);
  element.accept(visitor);
  return visitor.element;
}

String scopeInformation(Element element, int position) {
  ScopeInformationVisitor visitor =
      new ScopeInformationVisitor(element, position);
  element.accept(visitor);
  return '${visitor.buffer}';
}

class FindPositionVisitor extends ElementVisitor {
  final int position;
  Element element;

  FindPositionVisitor(this.position, this.element);

  visitElement(Element e) {
    if (e is PartialElement) {
      if (e.beginToken.charOffset <= position &&
          position < e.endToken.next.charOffset) {
        element = e;
      }
    }
  }

  visitClassElement(ClassElement e) {
    if (e is PartialClassElement) {
      if (e.beginToken.charOffset <= position &&
          position < e.endToken.next.charOffset) {
        element = e;
        visitScopeContainerElement(e);
      }
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

class ScopeInformationVisitor extends ElementVisitor/* <void> */ {
  // TODO(ahe): Include function parameters and local variables.

  final Element element;
  final int position;
  final StringBuffer buffer = new StringBuffer();
  int indentationLevel = 0;

  ScopeInformationVisitor(this.element, this.position);

  String get indentation => '  ' * indentationLevel;

  StringBuffer get indented => buffer..write(indentation);

  void visitElement(Element e) {
    serialize(e, omitEnclosing: false);
  }

  void visitLibraryElement(LibraryElement e) {
    bool isFirst = true;
    serialize(
        e, omitEnclosing: true,
        name: relativize(Uri.base, e.canonicalUri, false),
        serializeMembers: () {
          // TODO(ahe): Include imported elements in libraries.
          e.forEachLocalMember((Element member) {
            if (!isFirst) {
              buffer.write(',');
            }
            buffer.write('\n');
            indented;
            serialize(member);
            isFirst = false;
          });
        });
  }

  void visitScopeContainerElement(ScopeContainerElement e) {
    bool isFirst = true;
    serialize(e, omitEnclosing: false, serializeMembers: () {
      // TODO(ahe): Include inherited members in classes.
      e.forEachLocalMember((Element member) {
        if (!isFirst) {
          buffer.write(',');
        }
        buffer.write('\n');
        indented;
        serialize(member);
        isFirst = false;
      });
    });
  }

  void visitCompilationUnitElement(CompilationUnitElement e) {
    e.enclosingElement.accept(this);
  }

  void serialize(
      Element element,
      {bool omitEnclosing: true,
       void serializeMembers(),
       String name}) {
    if (name == null) {
      name = element.name;
    }
    buffer.write('{\n');
    indentationLevel++;
    indented
        ..write('"name": "')
        ..write(name)
        ..write('",\n');
    indented
        ..write('"kind": "')
        ..write(element.kind)
        ..write('"');
    // TODO(ahe): Add a type/signature field.
    if (serializeMembers != null) {
      buffer.write(',\n');
      indented.write('"members": [');
      indentationLevel++;
      serializeMembers();
      indentationLevel--;
      buffer.write('\n');
      indented.write(']');
    }
    if (!omitEnclosing) {
      buffer.write(',\n');
      indented.write('"enclosing": ');
      element.enclosingElement.accept(this);
    }
    indentationLevel--;
    buffer.write('\n');
    indented.write('}');
  }
}
