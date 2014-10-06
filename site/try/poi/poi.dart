// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi;

import 'dart:async' show
    Completer,
    Future;

import 'dart:io' as io;

import 'dart:convert' show
    UTF8;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    reuseCompiler;

import 'package:dart2js_incremental/library_updater.dart' show
    LibraryUpdater;

import 'package:compiler/implementation/source_file_provider.dart' show
    FormattingDiagnosticHandler;

import 'package:compiler/compiler.dart' as api;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler,
    CompilerTask,
    Enqueuer,
    QueueFilter,
    WorkItem;

import 'package:compiler/implementation/elements/visitor.dart' show
    ElementVisitor;

import 'package:compiler/implementation/elements/elements.dart' show
    AbstractFieldElement,
    ClassElement,
    CompilationUnitElement,
    Element,
    ElementCategory,
    FunctionElement,
    LibraryElement,
    ScopeContainerElement;

import 'package:compiler/implementation/elements/modelx.dart' as modelx;

import 'package:compiler/implementation/elements/modelx.dart' show
    DeclarationSite;

import 'package:compiler/implementation/dart_types.dart' show
    DartType;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    EOF_TOKEN,
    IDENTIFIER_TOKEN,
    KEYWORD_TOKEN,
    PartialClassElement,
    PartialElement,
    Token;

import 'package:compiler/implementation/js/js.dart' show
    prettyPrint;

/// Enabled by the option --enable-dart-mind.  Controls if this program should
/// be querying Dart Mind.
bool isDartMindEnabled = false;

/// Iterator over lines from standard input (or the argument array).
Iterator<String> stdin;

/// Enabled by the option --simulate-mutation. When true, this program will
/// only prompt for one file name, and subsequent runs will read
/// FILENAME.N.dart, where N starts at 1, and is increased on each iteration.
/// For example, if the program is invoked as:
///
///   dart poi.dart --simulate-mutation test.dart 11 22 33 44
///
/// The program will first read the file 'test.dart' and compute scope
/// information about position 11, then position 22 in test.dart.1.dart, then
/// position 33 in test.dart.2.dart, and finally position 44 in
/// test.dart.3.dart.
bool isSimulateMutationEnabled = false;

/// Counts the number of times [runPoi] has been invoked.
int poiCount;

int globalCounter = 0;

/// Enabled by the option --verbose (or -v). Prints more information than you
/// really need.
bool isVerbose = false;

/// Enabled by the option --compile. Also compiles the program after analyzing
/// the POI.
bool isCompiler = false;

/// When true (the default value) print serialized scope information at the
/// provided position.
const bool PRINT_SCOPE_INFO =
    const bool.fromEnvironment('PRINT_SCOPE_INFO', defaultValue: true);

Stopwatch wallClock = new Stopwatch();

PoiTask poiTask;

Compiler cachedCompiler;

/// Iterator for reading lines from [io.stdin].
class StdinIterator implements Iterator<String> {
  String current;

  bool moveNext() {
    current = io.stdin.readLineSync();
    return true;
  }
}

printFormattedTime(message, int us) {
  String m = '$message${" " * 65}'.substring(0, 60);
  String i = '${" " * 10}${(us/1000).toStringAsFixed(3)}';
  i = i.substring(i.length - 10);
  print('$m ${i}ms');
}

printWallClock(message) {
  if (!isVerbose) return;
  if (wallClock.isRunning) {
    print('$message');
    printFormattedTime('--->>>', wallClock.elapsedMicroseconds);
    wallClock.reset();
  } else {
    print(message);
  }
}

printVerbose(message) {
  if (!isVerbose) return;
  print(message);
}

main(List<String> arguments) {
  poiCount = 0;
  wallClock.start();
  List<String> nonOptionArguments = [];
  for (String argument in arguments) {
    if (argument.startsWith('-')) {
      switch (argument) {
        case '--simulate-mutation':
          isSimulateMutationEnabled = true;
          break;
        case '--enable-dart-mind':
          isDartMindEnabled = true;
          break;
        case '-v':
        case '--verbose':
          isVerbose = true;
          break;
        case '--compile':
          isCompiler = true;
          break;
        default:
          throw 'Unknown option: $argument.';
      }
    } else {
      nonOptionArguments.add(argument);
    }
  }
  if (nonOptionArguments.isEmpty) {
    stdin = new StdinIterator();
  } else {
    stdin = nonOptionArguments.iterator;
  }

  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();
  handler
      ..verbose = false
      ..enableColors = true;
  api.CompilerInputProvider inputProvider = handler.provider;

  return prompt('Dart file: ').then((String fileName) {
    if (isSimulateMutationEnabled) {
      inputProvider = simulateMutation(fileName, inputProvider);
    }
    return prompt('Position: ').then((String position) {
      return parseUserInput(fileName, position, inputProvider, handler);
    });
  });
}

/// Create an input provider that implements the behavior documented at
/// [simulateMutation].
api.CompilerInputProvider simulateMutation(
    String fileName,
    api.CompilerInputProvider inputProvider) {
  Uri script = Uri.base.resolveUri(new Uri.file(fileName));
  int count = poiCount;
  Future cache;
  String cachedFileName = script.toFilePath();
  int counter = ++globalCounter;
  return (Uri uri) {
    if (counter != globalCounter) throw 'Using old provider';
    printVerbose('fake inputProvider#$counter($uri): $poiCount $count');
    if (uri == script) {
      if (poiCount == count) {
        cachedFileName = uri.toFilePath();
        if (count != 0) {
          cachedFileName = '$cachedFileName.$count.dart';
        }
        printVerbose('Not using cached version of $cachedFileName');
        cache = new io.File(cachedFileName).readAsBytes().then((data) {
          printVerbose(
              'Read file $cachedFileName: '
              '${UTF8.decode(data.sublist(0, 100), allowMalformed: true)}...');
          return data;
        });
        count++;
      } else {
        printVerbose('Using cached version of $cachedFileName');
      }
      return cache;
    } else {
      printVerbose('Using original provider for $uri');
      return inputProvider(uri);
    }
  };
}

Future<String> prompt(message) {
  if (stdin is StdinIterator) {
    io.stdout.write(message);
  }
  return io.stdout.flush().then((_) {
    stdin.moveNext();
    return stdin.current;
  });
}

Future queryDartMind(String prefix, String info) {
  // TODO(lukechurch): Use [info] for something.
  String encodedArg0 = Uri.encodeComponent('"$prefix"');
  String mindQuery =
      'http://dart-mind.appspot.com/rpc'
      '?action=GetExportingPubCompletions'
      '&arg0=$encodedArg0';
  Uri uri = Uri.parse(mindQuery);

  io.HttpClient client = new io.HttpClient();
  return client.getUrl(uri).then((io.HttpClientRequest request) {
    return request.close();
  }).then((io.HttpClientResponse response) {
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
    printFormattedTime('--->>>', wallClock.elapsedMicroseconds);
    wallClock.reset();

    return prompt('Position: ').then((String positionString) {
      wallClock.reset();
      return parseUserInput(fileName, positionString, inputProvider, handler);
    });
  }

  printWallClock("\n\n\nparseUserInput('$fileName', '$positionString')");

  Uri script = Uri.base.resolveUri(new Uri.file(fileName));
  if (positionString == null) return null;
  int position = int.parse(
      positionString, onError: (_) { print('Please enter an integer.'); });
  if (position == null) return repeat();

  inputProvider(script);
  if (isVerbose) {
    handler(
        script, position, position + 1,
        'Point of interest. '
        'Cursor is immediately before highlighted character.',
        api.Diagnostic.HINT);
  }

  Stopwatch sw = new Stopwatch()..start();

  Future future = runPoi(script, position, inputProvider, handler);
  return future.then((Element element) {
    if (isVerbose) {
      printFormattedTime('Resolving took', sw.elapsedMicroseconds);
    }
    sw.reset();
    String info = scopeInformation(element, position);
    sw.stop();
    if (PRINT_SCOPE_INFO) {
      print(info);
    }
    printVerbose('Scope information took ${sw.elapsedMicroseconds}us.');
    sw..reset()..start();
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
    sw.stop();
    printVerbose('Find token took ${sw.elapsedMicroseconds}us.');
    if (isDartMindEnabled && prefix != null) {
      sw..reset()..start();
      return queryDartMind(prefix, info).then((String dartMindSuggestion) {
        sw.stop();
        print('Dart Mind ($prefix): $dartMindSuggestion.');
        printVerbose('Dart Mind took ${sw.elapsedMicroseconds}us.');
        return repeat();
      });
    } else {
      if (isDartMindEnabled) {
        print("Didn't talk to Dart Mind, no identifier at POI ($token).");
      }
      return repeat();
    }
  });
}

/// Find the token corresponding to [position] in [element].  The method only
/// works for instances of [PartialElement] or [LibraryElement].  Support for
/// [LibraryElement] is currently limited, and works only for named libraries.
Token findToken(modelx.ElementX element, int position) {
  Token beginToken;
  DeclarationSite site = element.declarationSite;
  if (site is PartialElement) {
    beginToken = site.beginToken;
  } else if (element.isLibrary) {
    // TODO(ahe): Generalize support for library elements (and update above
    // documentation).
    modelx.LibraryElementX lib = element;
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

Future<Element> runPoi(
    Uri script,
    int position,
    api.CompilerInputProvider inputProvider,
    api.DiagnosticHandler handler) {
  Stopwatch sw = new Stopwatch()..start();
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${io.Platform.packageRoot}/'));

  var options = [
      '--analyze-main',
      '--no-source-maps',
      '--verbose',
      '--categories=Client,Server',
      '--incremental-support',
      '--disable-type-inference',
  ];

  if (!isCompiler) {
    options.add('--analyze-only');
  }

  LibraryUpdater updater =
      new LibraryUpdater(
          cachedCompiler, inputProvider, script, printWallClock, printVerbose);
  Future<bool> reuseLibrary(LibraryElement library) {
    return poiTask.measure(() => updater.reuseLibrary(library));
  }

  return reuseCompiler(
      diagnosticHandler: handler,
      inputProvider: inputProvider,
      options: options,
      cachedCompiler: cachedCompiler,
      libraryRoot: libraryRoot,
      packageRoot: packageRoot,
      packagesAreImmutable: true,
      reuseLibrary: reuseLibrary).then((Compiler newCompiler) {
    if (!isCompiler) {
      newCompiler.enqueuerFilter = new ScriptOnlyFilter(script);
    }
    return runPoiInternal(newCompiler, sw, updater, position);
  });
}

Future<Element> runPoiInternal(
    Compiler newCompiler,
    Stopwatch sw,
    LibraryUpdater updater,
    int position) {
  bool isFullCompile = cachedCompiler != newCompiler;
  cachedCompiler = newCompiler;
  if (poiTask == null || poiTask.compiler != cachedCompiler) {
    poiTask = new PoiTask(cachedCompiler);
    cachedCompiler.tasks.add(poiTask);
  }

  if (!isFullCompile) {
    printFormattedTime(
        'Analyzing changes and updating elements took', sw.elapsedMicroseconds);
  }
  sw.reset();

  Future<bool> compilation;

  if (updater.hasPendingUpdates) {
    List<Element> updatedElements = updater.applyUpdates();
    compilation = new Future(() {
      cachedCompiler.progress.reset();
      for (Element element in updatedElements) {
        cachedCompiler.enqueuer.resolution.addToWorkList(element);
      }
      cachedCompiler.processQueue(cachedCompiler.enqueuer.resolution, null);

      cachedCompiler.phase = Compiler.PHASE_DONE_RESOLVING;

      for (Element element in updatedElements) {
        cachedCompiler.enqueuer.codegen.addToWorkList(element);
      }
      cachedCompiler.processQueue(cachedCompiler.enqueuer.codegen, null);

      for (Element element in updatedElements) {
        var node = cachedCompiler.enqueuer.codegen.generatedCode[element];
        print(prettyPrint(node, cachedCompiler).getText());
      }

      return !cachedCompiler.compilationFailed;
    });
  } else {
    compilation = cachedCompiler.run(updater.uri);
  }

  return compilation.then((success) {
    printVerbose('Compiler queue processed in ${sw.elapsedMicroseconds}us');
    if (isVerbose) {
      for (final task in cachedCompiler.tasks) {
        int time = task.timingMicroseconds;
        if (time != 0) {
          printFormattedTime('${task.name} took', time);
        }
      }
    }

    if (poiCount != null) poiCount++;
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

  visitElement(modelx.ElementX e) {
    DeclarationSite site = e.declarationSite;
    if (site is PartialElement) {
      if (site.beginToken.charOffset <= position &&
          position < site.endToken.next.charOffset) {
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
      printWallClock('Processed ${work.element}.');
    } else {
      printWallClock('Skipped ${work.element}.');
    }
  }
}

/**
 * Serializes scope information about an element. This is accomplished by
 * calling the [serialize] method on each element. Some elements need special
 * treatment, as their enclosing scope must also be serialized.
 */
class ScopeInformationVisitor extends ElementVisitor/* <void> */ {
  // TODO(ahe): Include function parameters and local variables.

  final Element currentElement;
  final int position;
  final StringBuffer buffer = new StringBuffer();
  int indentationLevel = 0;
  ClassElement currentClass;

  ScopeInformationVisitor(this.currentElement, this.position);

  String get indentation => '  ' * indentationLevel;

  StringBuffer get indented => buffer..write(indentation);

  void visitElement(Element e) {
    serialize(e, omitEnclosing: false);
  }

  void visitLibraryElement(LibraryElement e) {
    bool isFirst = true;
    forEach(Element member) {
      if (!isFirst) {
        buffer.write(',');
      }
      buffer.write('\n');
      indented;
      serialize(member);
      isFirst = false;
    }
    serialize(
        e,
        // TODO(ahe): We omit the import scope if there is no current
        // class. That's wrong.
        omitEnclosing: currentClass == null,
        name: e.getLibraryName(),
        serializeEnclosing: () {
          // The enclosing scope of a library is a scope which contains all the
          // imported names.
          isFirst = true;
          buffer.write('{\n');
          indentationLevel++;
          indented.write('"kind": "imports",\n');
          indented.write('"members": [');
          indentationLevel++;
          importScope(e).importScope.values.forEach(forEach);
          indentationLevel--;
          buffer.write('\n');
          indented.write('],\n');
          // The enclosing scope of the imported names scope is the superclass
          // scope of the current class.
          indented.write('"enclosing": ');
          serializeClassSide(
              currentClass.superclass, isStatic: false, includeSuper: true);
          buffer.write('\n');
          indentationLevel--;
          indented.write('}');
        },
        serializeMembers: () {
          isFirst = true;
          localScope(e).values.forEach(forEach);
        });
  }

  void visitClassElement(ClassElement e) {
    currentClass = e;
    serializeClassSide(e, isStatic: true);
  }

  /// Serializes one of the "sides" a class. The sides of a class are "instance
  /// side" and "class side". These terms are from Smalltalk. The instance side
  /// is all the local instance members of the class (the members of the
  /// mixin), and the class side is the equivalent for static members and
  /// constructors.
  /// The scope chain is ordered so that the "class side" is searched before
  /// the "instance side".
  void serializeClassSide(
      ClassElement e,
      {bool isStatic: false,
       bool omitEnclosing: false,
       bool includeSuper: false}) {
    bool isFirst = true;
    var serializeEnclosing;
    String kind;
    if (isStatic) {
      kind = 'class side';
      serializeEnclosing = () {
        serializeClassSide(e, isStatic: false, omitEnclosing: omitEnclosing);
      };
    } else {
      kind = 'instance side';
    }
    if (includeSuper) {
      assert(!omitEnclosing && !isStatic);
      if (e.superclass == null) {
        omitEnclosing = true;
      } else {
        // Members of the superclass are represented as a separate scope.
        serializeEnclosing = () {
          serializeClassSide(
              e.superclass, isStatic: false, omitEnclosing: false,
              includeSuper: true);
        };
      }
    }
    serialize(
        e, omitEnclosing: omitEnclosing, serializeEnclosing: serializeEnclosing,
        kind: kind, serializeMembers: () {
      e.forEachLocalMember((Element member) {
        // Filter out members that don't belong to this "side".
        if (member.isConstructor) {
          // In dart2js, some constructors aren't static, but that isn't
          // convenient here.
          if (!isStatic) return;
        } else if (member.isStatic != isStatic) {
          return;
        }
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

  void visitAbstractFieldElement(AbstractFieldElement e) {
    throw new UnsupportedError('AbstractFieldElement cannot be serialized.');
  }

  void serialize(
      Element element,
      {bool omitEnclosing: true,
       void serializeMembers(),
       void serializeEnclosing(),
       String kind,
       String name}) {
    if (element.isAbstractField) {
      AbstractFieldElement field = element;
      FunctionElement getter = field.getter;
      FunctionElement setter = field.setter;
      if (getter != null) {
        serialize(
            getter,
            omitEnclosing: omitEnclosing,
            serializeMembers: serializeMembers,
            serializeEnclosing: serializeEnclosing,
            kind: kind,
            name: name);
      }
      if (setter != null) {
        if (getter != null) {
          buffer.write(',\n');
          indented;
        }
        serialize(
            getter,
            omitEnclosing: omitEnclosing,
            serializeMembers: serializeMembers,
            serializeEnclosing: serializeEnclosing,
            kind: kind,
            name: name);
      }
      return;
    }
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
    if (kind == null) {
      kind = '${element.kind}';
    }
    buffer.write('{\n');
    indentationLevel++;
    if (name != '') {
      indented
          ..write('"name": "')
          ..write(name)
          ..write('",\n');
    }
    indented
        ..write('"kind": "')
        ..write(kind)
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
      if (serializeEnclosing != null) {
        serializeEnclosing();
      } else {
        element.enclosingElement.accept(this);
      }
    }
    indentationLevel--;
    buffer.write('\n');
    indented.write('}');
  }
}

modelx.ScopeX localScope(modelx.LibraryElementX element) => element.localScope;

modelx.ImportScope importScope(modelx.LibraryElementX element) {
  return element.importScope;
}

class PoiTask extends CompilerTask {
  PoiTask(Compiler compiler) : super(compiler);

  String get name => 'POI';
}
