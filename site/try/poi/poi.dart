// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi;

import 'dart:async' show
    Completer,
    Future,
    Stream;

import 'dart:io' show
    HttpClient,
    HttpClientRequest,
    HttpClientResponse,
    Platform,
    stdout;

import 'dart:io' as io;

import 'dart:convert' show
    LineSplitter,
    UTF8;

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
    ElementCategory,
    LibraryElement,
    ScopeContainerElement;

import 'package:compiler/implementation/dart_types.dart' show
    DartType;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    EOF_TOKEN,
    IDENTIFIER_TOKEN,
    KEYWORD_TOKEN,
    PartialClassElement,
    PartialElement,
    Token;

/// Controls if this program should be querying Dart Mind. Used by tests.
bool enableDartMind = true;

/// Iterator over lines from standard input (or the argument array).
Iterator<String> stdin;

/// Iterator for reading lines from [io.stdin].
class StdinIterator implements Iterator<String> {
  String current;

  bool moveNext() {
    current = io.stdin.readLineSync();
    return true;
  }
}

main(List<String> arguments) {
  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();
  handler
      ..verbose = false
      ..enableColors = true;
  api.CompilerInputProvider inputProvider = handler.provider;

  if (arguments.length == 0) {
    stdin = new StdinIterator();
  } else {
    stdin = arguments.where((String line) {
      print(line); // Simulates user input in terminal.
      return true;
    }).iterator;
  }

  return prompt('Dart file: ').then((String fileName) {
    return prompt('Position: ').then((String position) {
      return parseUserInput(fileName, position, inputProvider, handler);
    });
  });
}

Future<String> prompt(message) {
  stdout.write(message);
  return stdout.flush().then((_) {
    stdin.moveNext();
    return stdin.current;
  });
}

Future queryDartMind(String prefix, String info) {
  // TODO(lukechurch): Use [info] for something.
  if (!enableDartMind) return new Future.value("[]");
  String encodedArg0 = Uri.encodeComponent('"$prefix"');
  String mindQuery =
      'http://dart-mind.appspot.com/rpc'
      '?action=GetExportingPubCompletions'
      '&arg0=$encodedArg0';
  Uri uri = Uri.parse(mindQuery);

  HttpClient client = new HttpClient();
  return client.getUrl(uri).then((HttpClientRequest request) {
    return request.close();
  }).then((HttpClientResponse response) {
    Completer<String> completer = new Completer<String>();
    response.transform(UTF8.decoder).listen((contents) {
      completer.complete(contents);
    });
    return completer.future;
  });
}

Future parseUserInput(
    String fileName,
    String positionString,
    api.CompilerInputProvider inputProvider,
    api.DiagnosticHandler handler) {
  Future repeat() {
    return prompt('Position: ').then((String positionString) {
      return parseUserInput(fileName, positionString, inputProvider, handler);
    });
  }

  Uri script = Uri.base.resolveUri(new Uri.file(fileName));
  if (positionString == null) return null;
  int position = int.parse(
      positionString, onError: (_) => print('Please enter an integer.'));
  if (position == null) return repeat();

  inputProvider(script);
  handler(
      script, position, position + 1,
      'Point of interest. Cursor is immediately before highlighted character.',
      api.Diagnostic.HINT);

  Stopwatch sw = new Stopwatch()..start();

  Future future = runPoi(script, position, inputProvider, handler);
  return future.then((Element element) {
    print('Resolving took ${sw.elapsedMicroseconds}us.');
    sw.reset();
    String info = scopeInformation(element, position);
    print(info);
    print('Scope information took ${sw.elapsedMicroseconds}us.');
    sw.reset();
    Token token = findToken(element, position);
    String prefix;
    if (token != null) {
      if (token.charOffset + token.charCount <= position) {
        // After the token; in whitespace, or in the beginning of another token.
        prefix = "";
      } else if (token.kind == IDENTIFIER_TOKEN ||
                 token.kind == KEYWORD_TOKEN) {
        prefix = token.value.substring(0, position - token.charOffset);
      }
    }
    print('Find token took ${sw.elapsedMicroseconds}us.');
    sw.reset();
    if (prefix != null) {
      return queryDartMind(prefix, info).then((String dartMindSuggestion) {
        sw.stop();
        print('Dart Mind ($prefix): $dartMindSuggestion.');
        print('Dart Mind took ${sw.elapsedMicroseconds}us.');
        return repeat();
      });
    } else {
      print("Didn't talk to Dart Mind, no identifier at POI ($token).");
      return repeat();
    }
  });
}

/// Find the token corresponding to [position] in [element].  The method only
/// works for instances of [PartialElement] or [LibraryElement].  Support for
/// [LibraryElement] is currently limited, and works only for named libraries.
Token findToken(Element element, int position) {
  Token beginToken;
  if (element is PartialElement) {
    beginToken = element.beginToken;
  } else if (element is PartialClassElement) {
    beginToken = element.beginToken;
  } else if (element.isLibrary) {
    // TODO(ahe): Generalize support for library elements (and update above
    // documentation).
    LibraryElement lib = element;
    var tag = lib.libraryTag;
    if (tag != null) {
      beginToken = tag.libraryKeyword;
    }
  } else {
    beginToken = element.position;
  }
  if (beginToken == null) return null;
  for (Token token = beginToken; token.kind != EOF_TOKEN; token = token.next) {
    if (token.charOffset < position && position <= token.next.charOffset) {
      return token;
    }
  }
  return null;
}

Compiler cachedCompiler;

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
      '--incremental-support',
      '--disable-type-inference',
  ];

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
        name: e.getLibraryName(),
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
    DartType type;
    int category = element.kind.category;
    if (category == ElementCategory.FUNCTION ||
        category == ElementCategory.VARIABLE ||
        element.isConstructor) {
      type = element.computeType(cachedCompiler);
    }
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
    if (type != null) {
      buffer.write(',\n');
      indented
          ..write('"type": "')
          ..write(type)
          ..write('"');
    }
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
