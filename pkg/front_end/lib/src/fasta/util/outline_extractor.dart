// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/fasta/util/parser_ast_helper.dart';
import 'package:front_end/src/fasta/util/textual_outline.dart';
import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';
import 'package:kernel/target/targets.dart';

import "parser_ast.dart";
import "abstracted_ast_nodes.dart";

// Overall TODO(s):
// * If entry is given as fileuri but exists as different import uri...
//   Does that matter?
// * Setters vs non-setters with naming conflicts.
// * -> also these might be found on "different levels", e.g. the setter might
//      be in the class and the getter might be in an import.
// * show/hide on imports and exports.
// * Handle importing/exporting non-existing files.
// * Tests.
// * Maybe bypass the direct-from-parser-ast stuff for speed?
// * Probably some of the special classes can be combined if we want to
//   (e.g. Class and Mixin).
// * Extensions --- we currently basically mark all we see.
//    => Could be perhaps only include them if the class they're talking about
//       is included? (or we don't know).
// * E.g. "factory Abc.b() => Abc3();" is the same as
//   "factory Abc.b() { return Abc3(); }" and Abc3 shouldn't be marked by it.
//    -> This is basically a rough edge on the textual outline though.
//    -> Also, the same applies to other instances of "=>".
// * It shouldn't lookup private stuff in other libraries.
// * Could there be made a distinction between for instance
//   `IdentifierContext.typeReference` and `IdentifierContext.expression`?
//   => one might not have to include content of classes that only talk about
//      typeReference I think.

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw "Needs 2 arguments: packages file/dir and file to process.";
  }
  Uri packages = Uri.base.resolve(args[0]);
  Uri file = Uri.base.resolve(args[1]);
  for (int i = 0; i < 1; i++) {
    Stopwatch stopwatch = new Stopwatch()..start();
    await extractOutline([file], packages: packages, verbosityLevel: 40);
    print("Finished in ${stopwatch.elapsedMilliseconds} ms "
        "(textual outline was "
        "${latestProcessor!.textualOutlineStopwatch.elapsedMilliseconds} ms)"
        "(get ast was "
        "${latestProcessor!.getAstStopwatch.elapsedMilliseconds} ms)"
        "(extract identifier was "
        "${latestProcessor!.extractIdentifierStopwatch.elapsedMilliseconds} ms)"
        "");
  }
}

_Processor? latestProcessor;

Future<Map<Uri, String>> extractOutline(List<Uri> entryPointUris,
    {Uri? sdk,
    required Uri? packages,
    Uri? platform,
    Target? target,
    int verbosityLevel = 0}) {
  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..packagesFileUri = packages
    ..sdkSummary = platform
    ..sdkRoot = sdk;
  ProcessedOptions processedOptions =
      new ProcessedOptions(options: options, inputs: entryPointUris);
  return extractOutlineWithProcessedOptions(entryPointUris,
      verbosityLevel: verbosityLevel, processedOptions: processedOptions);
}

Future<Map<Uri, String>> extractOutlineWithProcessedOptions(
    List<Uri> entryPointUris,
    {int verbosityLevel = 0,
    required ProcessedOptions processedOptions}) {
  return CompilerContext.runWithOptions(processedOptions,
      (CompilerContext c) async {
    FileSystem fileSystem = c.options.fileSystem;
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    _Processor processor =
        new _Processor(verbosityLevel, fileSystem, uriTranslator);
    latestProcessor = processor;
    List<TopLevel> entryPoints = [];
    for (Uri entryPointUri in entryPointUris) {
      TopLevel entryPoint = await processor.preprocessUri(entryPointUri);
      entryPoints.add(entryPoint);
    }
    return await processor.calculate(entryPoints);
  });
}

class _Processor {
  final FileSystem fileSystem;
  final UriTranslator uriTranslator;
  final int verbosityLevel;

  final Stopwatch textualOutlineStopwatch = new Stopwatch();
  final Stopwatch getAstStopwatch = new Stopwatch();
  final Stopwatch extractIdentifierStopwatch = new Stopwatch();

  Map<Uri, TopLevel> parsed = {};

  _Processor(this.verbosityLevel, this.fileSystem, this.uriTranslator);

  void log(String s) {
    if (verbosityLevel <= 0) return;
    print(s);
  }

  Future<TopLevel> preprocessUri(Uri importUri, {Uri? partOf}) async {
    if (verbosityLevel >= 20) log("$importUri =>");
    Uri fileUri = importUri;
    if (importUri.isScheme("package")) {
      fileUri = uriTranslator.translate(importUri)!;
    }
    if (verbosityLevel >= 20) log("$fileUri");
    final List<int> bytes =
        await fileSystem.entityForUri(fileUri).readAsBytes();
    // TODO: Support updating the configuration; also default it to match
    // the package version.
    final ScannerConfiguration configuration = new ScannerConfiguration(
        enableExtensionMethods: true,
        enableNonNullable: true,
        enableTripleShift: true);
    textualOutlineStopwatch.start();
    final String? outlined =
        textualOutline(bytes, configuration, enablePatterns: true);
    textualOutlineStopwatch.stop();
    if (outlined == null) throw "Textual outline returned null";
    final List<int> bytes2 = utf8.encode(outlined);
    getAstStopwatch.start();
    List<Token> languageVersionsSeen = [];
    final ParserAstNode ast = getAST(bytes2,
        enableExtensionMethods: configuration.enableExtensionMethods,
        enableNonNullable: configuration.enableNonNullable,
        enableTripleShift: configuration.enableTripleShift,
        languageVersionsSeen: languageVersionsSeen);
    getAstStopwatch.stop();

    _ParserAstVisitor visitor = new _ParserAstVisitor(
        verbosityLevel, outlined, importUri, partOf, ast, languageVersionsSeen);
    TopLevel topLevel = visitor.currentContainer as TopLevel;
    if (parsed[importUri] != null) throw "$importUri already set?!?";
    parsed[importUri] = topLevel;
    visitor.accept(ast);
    topLevel.buildScope();

    _IdentifierExtractor identifierExtractor = new _IdentifierExtractor();
    extractIdentifierStopwatch.start();
    identifierExtractor.extract(ast);
    extractIdentifierStopwatch.stop();
    for (IdentifierHandle identifier in identifierExtractor.identifiers) {
      if (identifier.context == IdentifierContext.typeVariableDeclaration) {
        // Hack: Put type variable declarations into scope so any overlap in
        // name doesn't mark usages (e.g. a class E shouldn't be marked if we're
        // talking about the type variable E).
        ParserAstNode content = identifier;
        AstNode? nearestAstNode = visitor.map[content];
        while (nearestAstNode == null && content.parent != null) {
          content = content.parent!;
          nearestAstNode = visitor.map[content];
        }
        if (nearestAstNode == null) {
          content = identifier;
          nearestAstNode = visitor.map[content];
          while (nearestAstNode == null && content.parent != null) {
            content = content.parent!;
            nearestAstNode = visitor.map[content];
          }

          StringBuffer sb = new StringBuffer();
          Token t = identifier.token;
          // for(int i = 0; i < 10; i++) {
          //   t = t.previous!;
          // }
          for (int i = 0; i < 20; i++) {
            sb.write("$t ");
            t = t.next!;
          }
          throw "$fileUri --- couldn't even find nearest ast node for "
              "${identifier.token} :( -- context $sb";
        }
        (nearestAstNode.scope[identifier.token.lexeme] ??= [])
            .add(nearestAstNode);
      }
    }

    return topLevel;
  }

  Future<void> _premarkTopLevel(List<_TopLevelAndAstNode> worklist,
      Set<TopLevel> closed, TopLevel entrypointish) async {
    if (!closed.add(entrypointish)) return;

    for (AstNode child in entrypointish.children) {
      child.marked = Coloring.Marked;
      worklist.add(new _TopLevelAndAstNode(entrypointish, child));

      if (child is Part) {
        if (!child.uri.isScheme("dart")) {
          TopLevel partTopLevel = parsed[child.uri] ??
              await preprocessUri(child.uri, partOf: entrypointish.uri);
          await _premarkTopLevel(worklist, closed, partTopLevel);
        }
      } else if (child is Export) {
        for (Uri exportedUri in child.uris) {
          if (exportedUri.isScheme("dart")) continue;
          // E.g. conditional exports could point to non-existing files.
          if (!await _exists(exportedUri)) continue;
          TopLevel exportTopLevel =
              parsed[exportedUri] ?? await preprocessUri(exportedUri);
          await _premarkTopLevel(worklist, closed, exportTopLevel);
        }
      }
    }
  }

  Future<bool> _exists(Uri uri) {
    Uri fileUri = uri;
    if (fileUri.isScheme("package")) {
      fileUri = uriTranslator.translate(fileUri)!;
    }
    return fileSystem.entityForUri(fileUri).exists();
  }

  Future<List<TopLevel>> _preprocessImportsAsNeeded(
      Map<TopLevel, List<TopLevel>> imports, TopLevel topLevel) async {
    List<TopLevel>? imported = imports[topLevel];
    if (imported == null) {
      // Process all imports.
      imported = [];
      imports[topLevel] = imported;
      for (AstNode child in topLevel.children) {
        if (child is Import) {
          child.marked = Coloring.Marked;
          for (Uri importedUri in child.uris) {
            if (importedUri.isScheme("dart")) continue;
            // E.g. conditional imports could point to non-existing files.
            if (!await _exists(importedUri)) continue;

            TopLevel importedTopLevel =
                parsed[importedUri] ?? await preprocessUri(importedUri);
            imported.add(importedTopLevel);
          }
        } else if (child is PartOf) {
          child.marked = Coloring.Marked;
          if (!child.partOfUri.isScheme("dart")) {
            TopLevel part = parsed[child.partOfUri]!;
            List<TopLevel> importsFromPart =
                await _preprocessImportsAsNeeded(imports, part);
            imported.addAll(importsFromPart);
          }
        }
      }
    }
    return imported;
  }

  Future<Map<Uri, String>> calculate(List<TopLevel> entryPoints) async {
    List<_TopLevelAndAstNode> worklist = [];
    Map<TopLevel, List<TopLevel>> imports = {};

    // Mark all top-level in entry point. Also include parts and exports (and
    // exports exports etc) of the entry point.
    Set<TopLevel> closed = {};
    for (TopLevel entryPoint in entryPoints) {
      await _premarkTopLevel(worklist, closed, entryPoint);
    }

    Map<TopLevel, Set<String>> lookupsAll = {};
    Map<TopLevel, List<String>> lookupsWorklist = {};
    while (worklist.isNotEmpty || lookupsWorklist.isNotEmpty) {
      while (worklist.isNotEmpty) {
        _TopLevelAndAstNode entry = worklist.removeLast();
        if (verbosityLevel >= 20) {
          log("\n-----\nProcessing ${entry.entry.node.toString()}");
        }
        _IdentifierExtractor identifierExtractor = new _IdentifierExtractor();
        identifierExtractor.extract(entry.entry.node);
        if (verbosityLevel >= 20) {
          log("Found ${identifierExtractor.identifiers}");
        }
        List<AstNode>? prevLookupResult;
        nextIdentifier:
        for (IdentifierHandle identifier in identifierExtractor.identifiers) {
          ParserAstNode content = identifier;
          AstNode? nearestAstNode = entry.topLevel.map[content];
          while (nearestAstNode == null && content.parent != null) {
            content = content.parent!;
            nearestAstNode = entry.topLevel.map[content];
          }
          if (nearestAstNode == null) {
            throw "couldn't even find nearest ast node for "
                "${identifier.token} :(";
          }

          if (identifier.context == IdentifierContext.typeReference ||
              identifier.context == IdentifierContext.prefixedTypeReference ||
              identifier.context ==
                  IdentifierContext.typeReferenceContinuation ||
              identifier.context == IdentifierContext.constructorReference ||
              identifier.context ==
                  IdentifierContext.constructorReferenceContinuation ||
              identifier.context == IdentifierContext.expression ||
              identifier.context == IdentifierContext.expressionContinuation ||
              identifier.context == IdentifierContext.metadataReference ||
              identifier.context == IdentifierContext.metadataContinuation) {
            bool lookupInThisScope = true;
            if (!identifier.context.isContinuation) {
              prevLookupResult = null;
            } else if (prevLookupResult != null) {
              // In continuation.
              // either 0 or all should be imports.
              for (AstNode prevResult in prevLookupResult) {
                if (prevResult is Import) {
                  lookupInThisScope = false;
                } else {
                  continue nextIdentifier;
                }
              }
            } else {
              // Still in continuation --- but prev lookup didn't yield
              // anything. We shouldn't search for the continuation part in this
              // scope (and thus skip looking in imports).
              lookupInThisScope = false;
            }
            if (verbosityLevel >= 20) {
              log("${identifier.token} (${identifier.context})");
            }

            // Now we need parts at this point. Either we're in the entry point
            // in which case parts was read by [_premarkTopLevel], or we're here
            // via lookups on an import, where parts were read too.
            List<AstNode>? lookedUp;
            if (lookupInThisScope) {
              lookedUp = findInScope(
                  identifier.token.lexeme, nearestAstNode, entry.topLevel);
              prevLookupResult = lookedUp;
            }
            if (lookedUp != null) {
              for (AstNode found in lookedUp) {
                if (verbosityLevel >= 20) log(" => found $found");
                if (found.marked == Coloring.Untouched) {
                  found.marked = Coloring.Marked;
                  TopLevel foundTopLevel = entry.topLevel;
                  if (found.parent is TopLevel) {
                    foundTopLevel = found.parent as TopLevel;
                  }
                  worklist.add(new _TopLevelAndAstNode(foundTopLevel, found));
                }
              }
            } else {
              if (verbosityLevel >= 20) {
                log("=> Should find this via an import probably?");
              }

              List<TopLevel> imported =
                  await _preprocessImportsAsNeeded(imports, entry.topLevel);

              Set<Uri>? wantedImportUrls;
              if (!lookupInThisScope && prevLookupResult != null) {
                for (AstNode castMeAsImport in prevLookupResult) {
                  Import import = castMeAsImport as Import;
                  assert(import.asName != null);
                  (wantedImportUrls ??= {}).addAll(import.uris);
                }
              }

              for (TopLevel other in imported) {
                if (!lookupInThisScope && prevLookupResult != null) {
                  assert(wantedImportUrls != null);
                  if (!wantedImportUrls!.contains(other.uri)) continue;
                }

                Set<String> lookupStrings = lookupsAll[other] ??= {};
                if (lookupStrings.add(identifier.token.lexeme)) {
                  List<String> lookupStringsWorklist =
                      lookupsWorklist[other] ??= [];
                  lookupStringsWorklist.add(identifier.token.lexeme);
                }
              }
            }
          } else {
            if (verbosityLevel >= 30) {
              log("Ignoring ${identifier.token} as it's a "
                  "${identifier.context}");
            }
          }
        }
      }
      Map<TopLevel, List<String>> lookupsWorklistTmp = {};
      for (MapEntry<TopLevel, List<String>> lookups
          in lookupsWorklist.entries) {
        TopLevel topLevel = lookups.key;
        // We have to make the same lookups in parts and exports too.
        for (AstNode child in topLevel.children) {
          TopLevel? other;
          if (child is Part) {
            child.marked = Coloring.Marked;
            // do stuff to part.
            if (!child.uri.isScheme("dart")) {
              other = parsed[child.uri] ??
                  await preprocessUri(child.uri, partOf: topLevel.uri);
            }
          } else if (child is Export) {
            child.marked = Coloring.Marked;
            // do stuff to export.
            for (Uri exportedUri in child.uris) {
              if (exportedUri.isScheme("dart")) continue;
              // E.g. conditional exports could point to non-existing files.
              if (!await _exists(exportedUri)) continue;
              other = parsed[exportedUri] ?? await preprocessUri(exportedUri);
            }
          } else if (child is Extension) {
            // TODO: Maybe put on a list to process later and only include if
            // the on-class is included?
            if (child.marked == Coloring.Untouched) {
              child.marked = Coloring.Marked;
              worklist.add(new _TopLevelAndAstNode(topLevel, child));
            }
          }
          if (other != null) {
            Set<String> lookupStrings = lookupsAll[other] ??= {};
            for (String identifier in lookups.value) {
              if (lookupStrings.add(identifier)) {
                List<String> lookupStringsWorklist =
                    lookupsWorklistTmp[other] ??= [];
                lookupStringsWorklist.add(identifier);
              }
            }
          }
        }

        for (String identifier in lookups.value) {
          List<AstNode>? foundInScope = topLevel.findInScope(identifier);
          if (foundInScope != null) {
            for (AstNode found in foundInScope) {
              if (found.marked == Coloring.Untouched) {
                found.marked = Coloring.Marked;
                worklist.add(new _TopLevelAndAstNode(topLevel, found));
              }
              if (verbosityLevel >= 20) {
                log(" => found $found via import (${found.marked})");
              }
            }
          }
        }
      }
      lookupsWorklist = lookupsWorklistTmp;
    }

    if (verbosityLevel >= 40) {
      log("\n\n---------\n\n");
      log(parsed.toString());
      log("\n\n---------\n\n");
    }

    // Extract.
    int count = 0;
    Map<Uri, String> result = {};
    // We only read imports if we need to lookup in them, but if a import
    // statement is included in the output the file has to exist if it actually
    // exists to not get a compilation error.
    Set<Uri> imported = {};
    for (MapEntry<Uri, TopLevel> entry in parsed.entries) {
      if (verbosityLevel >= 40) log("${entry.key}:");
      StringBuffer sb = new StringBuffer();
      for (AstNode child in entry.value.children) {
        if (child.marked == Coloring.Marked) {
          String substring = entry.value.sourceText.substring(
              child.startInclusive.charOffset, child.endInclusive.charEnd);
          sb.writeln(substring);
          if (verbosityLevel >= 40) {
            log(substring);
          }
          if (child is Import) {
            for (Uri importedUri in child.uris) {
              if (!importedUri.isScheme("dart")) {
                imported.add(importedUri);
              }
            }
          }
        }
      }
      if (sb.isNotEmpty) count++;
      Uri uri = entry.key;
      Uri fileUri = uri;
      if (uri.isScheme("package")) {
        fileUri = uriTranslator.translate(uri)!;
      }
      result[fileUri] = sb.toString();
    }
    for (Uri uri in imported) {
      TopLevel? topLevel = parsed[uri];
      if (topLevel != null) continue;
      // uri imports a file we haven't read. Check if it exists and include it
      // as an empty file if it does.
      Uri fileUri = uri;
      if (uri.isScheme("package")) {
        fileUri = uriTranslator.translate(uri)!;
      }
      if (await fileSystem.entityForUri(fileUri).exists()) {
        result[fileUri] = "";
      }
    }

    print("=> Long story short got it to $count non-empty files...");

    return result;
  }

  List<AstNode>? findInScope(
      String name, AstNode nearestAstNode, TopLevel topLevel,
      {Set<TopLevel>? visited}) {
    List<AstNode>? result;
    result = nearestAstNode.findInScope(name);
    if (result != null) return result;
    for (AstNode child in topLevel.children) {
      if (child is Part) {
        visited ??= {topLevel};
        TopLevel partTopLevel = parsed[child.uri]!;
        if (visited.add(partTopLevel)) {
          result =
              findInScope(name, partTopLevel, partTopLevel, visited: visited);
          if (result != null) return result;
        }
      } else if (child is PartOf) {
        visited ??= {topLevel};
        TopLevel partOwnerTopLevel = parsed[child.partOfUri]!;
        if (visited.add(partOwnerTopLevel)) {
          result = findInScope(name, partOwnerTopLevel, partOwnerTopLevel,
              visited: visited);
          if (result != null) return result;
        }
      }
    }
    return null;
  }
}

class _TopLevelAndAstNode {
  final TopLevel topLevel;
  final AstNode entry;

  _TopLevelAndAstNode(this.topLevel, this.entry);
}

class _IdentifierExtractor {
  List<IdentifierHandle> identifiers = [];

  void extract(ParserAstNode ast) {
    if (ast is IdentifierHandle) {
      identifiers.add(ast);
    }
    List<ParserAstNode>? children = ast.children;
    if (children != null) {
      for (ParserAstNode child in children) {
        extract(child);
      }
    }
  }
}

class _ParserAstVisitor extends ParserAstVisitor {
  final Uri uri;
  final Uri? partOfUri;
  late Container currentContainer;
  final Map<ParserAstNode, AstNode> map = {};
  final int verbosityLevel;
  final List<Token> languageVersionsSeen;

  _ParserAstVisitor(this.verbosityLevel, String sourceText, this.uri,
      this.partOfUri, ParserAstNode rootAst, this.languageVersionsSeen) {
    currentContainer = new TopLevel(sourceText, uri, rootAst, map);
    if (languageVersionsSeen.isNotEmpty) {
      // Use first one.
      Token languageVersion = languageVersionsSeen.first;
      ParserAstNode dummyNode = new NoInitializersHandle(ParserAstType.HANDLE);
      LanguageVersion version =
          new LanguageVersion(dummyNode, languageVersion, languageVersion);
      version.marked = Coloring.Marked;
      currentContainer.addChild(version, map);
    }
  }

  void log(String s) {
    if (verbosityLevel <= 0) return;
    Container? x = currentContainer.parent;
    int level = 0;
    while (x != null) {
      level++;
      x = x.parent;
    }
    print(" " * level + s);
  }

  @override
  void visitClass(
      ClassDeclarationEnd node, Token startInclusive, Token endInclusive) {
    TopLevelDeclarationEnd parent = node.parent! as TopLevelDeclarationEnd;
    IdentifierHandle identifier = parent.getIdentifier();

    log("Hello from class ${identifier.token}");

    Class cls = new Class(
        parent, identifier.token.lexeme, startInclusive, endInclusive);
    currentContainer.addChild(cls, map);

    Container previousContainer = currentContainer;
    currentContainer = cls;
    super.visitClass(node, startInclusive, endInclusive);
    currentContainer = previousContainer;
  }

  @override
  void visitClassConstructor(
      ClassConstructorEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Class);
    List<IdentifierHandle> ids = node.getIdentifiers();
    if (ids.length == 1) {
      ClassConstructor classConstructor = new ClassConstructor(
          node, ids.single.token.lexeme, startInclusive, endInclusive);
      currentContainer.addChild(classConstructor, map);
      log("Hello from constructor ${ids.single.token}");
    } else if (ids.length == 2) {
      ClassConstructor classConstructor = new ClassConstructor(node,
          "${ids.first.token}.${ids.last.token}", startInclusive, endInclusive);
      map[node] = classConstructor;
      currentContainer.addChild(classConstructor, map);
      log("Hello from constructor ${ids.first.token}.${ids.last.token}");
    } else {
      throw "Unexpected identifiers in class constructor";
    }

    super.visitClassConstructor(node, startInclusive, endInclusive);
  }

  @override
  void visitClassFactoryMethod(
      ClassFactoryMethodEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Class);
    List<IdentifierHandle> ids = node.getIdentifiers();
    if (ids.length == 1) {
      ClassFactoryMethod classFactoryMethod = new ClassFactoryMethod(
          node, ids.single.token.lexeme, startInclusive, endInclusive);
      currentContainer.addChild(classFactoryMethod, map);
      log("Hello from factory method ${ids.single.token}");
    } else if (ids.length == 2) {
      ClassFactoryMethod classFactoryMethod = new ClassFactoryMethod(node,
          "${ids.first.token}.${ids.last.token}", startInclusive, endInclusive);
      map[node] = classFactoryMethod;
      currentContainer.addChild(classFactoryMethod, map);
      log("Hello from factory method ${ids.first.token}.${ids.last.token}");
    } else {
      debugDumpSource(
          startInclusive,
          endInclusive,
          node,
          "Unexpected identifiers in class factory method: $ids "
          "(${ids.map((e) => e.token.lexeme).toList()}).");
    }

    super.visitClassFactoryMethod(node, startInclusive, endInclusive);
  }

  @override
  void visitClassFields(
      ClassFieldsEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Class);
    List<String> fields =
        node.getFieldIdentifiers().map((e) => e.token.lexeme).toList();
    ClassFields classFields =
        new ClassFields(node, fields, startInclusive, endInclusive);
    currentContainer.addChild(classFields, map);
    log("Hello from class fields ${fields.join(", ")}");
    super.visitClassFields(node, startInclusive, endInclusive);
  }

  @override
  void visitClassMethod(
      ClassMethodEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Class);

    String identifier = node.getNameIdentifier();
    ClassMethod classMethod =
        new ClassMethod(node, identifier, startInclusive, endInclusive);
    currentContainer.addChild(classMethod, map);
    log("Hello from class method $identifier");
    super.visitClassMethod(node, startInclusive, endInclusive);
  }

  @override
  void visitEnum(EnumEnd node, Token startInclusive, Token endInclusive) {
    TopLevelDeclarationEnd parent = node.parent! as TopLevelDeclarationEnd;
    IdentifierHandle identifier = parent.getIdentifier();
    List<IdentifierHandle> ids = node.getIdentifiers();

    Enum e = new Enum(node, identifier.token.lexeme,
        ids.map((e) => e.token.lexeme).toList(), startInclusive, endInclusive);
    currentContainer.addChild(e, map);

    log("Hello from enum ${identifier.token} with content "
        "${ids.map((e) => e.token).join(", ")}");
    super.visitEnum(node, startInclusive, endInclusive);
  }

  @override
  void visitExport(ExportEnd node, Token startInclusive, Token endInclusive) {
    String uriString = node.getExportUriString();
    Uri exportUri = uri.resolve(uriString);
    List<String>? conditionalUriStrings = node.getConditionalExportUriStrings();
    List<Uri>? conditionalUris;
    if (conditionalUriStrings != null) {
      conditionalUris = [];
      for (String conditionalUri in conditionalUriStrings) {
        conditionalUris.add(uri.resolve(conditionalUri));
      }
    }
    // TODO: Use 'show' and 'hide' stuff.
    Export e = new Export(
        node, exportUri, conditionalUris, startInclusive, endInclusive);
    currentContainer.addChild(e, map);
    log("Hello export");
  }

  @override
  void visitExtension(
      ExtensionDeclarationEnd node, Token startInclusive, Token endInclusive) {
    ExtensionDeclarationBegin begin =
        node.children!.first as ExtensionDeclarationBegin;
    TopLevelDeclarationEnd parent = node.parent! as TopLevelDeclarationEnd;
    log("Hello from extension ${begin.name}");
    Extension extension =
        new Extension(parent, begin.name?.lexeme, startInclusive, endInclusive);
    currentContainer.addChild(extension, map);

    Container previousContainer = currentContainer;
    currentContainer = extension;
    super.visitExtension(node, startInclusive, endInclusive);
    currentContainer = previousContainer;
  }

  @override
  void visitExtensionConstructor(
      ExtensionConstructorEnd node, Token startInclusive, Token endInclusive) {
    // TODO: implement visitExtensionConstructor
    throw node;
  }

  @override
  void visitExtensionFactoryMethod(ExtensionFactoryMethodEnd node,
      Token startInclusive, Token endInclusive) {
    // TODO: implement visitExtensionFactoryMethod
    throw node;
  }

  @override
  void visitExtensionFields(
      ExtensionFieldsEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Extension);
    List<String> fields =
        node.getFieldIdentifiers().map((e) => e.token.lexeme).toList();
    ExtensionFields classFields =
        new ExtensionFields(node, fields, startInclusive, endInclusive);
    currentContainer.addChild(classFields, map);
    log("Hello from extension fields ${fields.join(", ")}");
    super.visitExtensionFields(node, startInclusive, endInclusive);
  }

  @override
  void visitExtensionMethod(
      ExtensionMethodEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Extension);
    ExtensionMethod extensionMethod = new ExtensionMethod(
        node, node.getNameIdentifier(), startInclusive, endInclusive);
    currentContainer.addChild(extensionMethod, map);
    log("Hello from extension method ${node.getNameIdentifier()}");
    super.visitExtensionMethod(node, startInclusive, endInclusive);
  }

  void debugDumpSource(Token startInclusive, Token endInclusive,
      ParserAstNode node, String message) {
    Container findTopLevel = currentContainer;
    while (findTopLevel is! TopLevel) {
      findTopLevel = findTopLevel.parent!;
    }
    String src = findTopLevel.sourceText
        .substring(startInclusive.charOffset, endInclusive.charEnd);
    throw "Error on source ${src} --- \n\n"
        "$message ---\n\n"
        "${node.children}";
  }

  @override
  void visitImport(ImportEnd node, Token startInclusive, Token? endInclusive) {
    IdentifierHandle? prefix = node.getImportPrefix();
    String uriString = node.getImportUriString();
    Uri importUri = uri.resolve(uriString);
    List<String>? conditionalUriStrings = node.getConditionalImportUriStrings();
    List<Uri>? conditionalUris;
    if (conditionalUriStrings != null) {
      conditionalUris = [];
      for (String conditionalUri in conditionalUriStrings) {
        conditionalUris.add(uri.resolve(conditionalUri));
      }
    }
    // TODO: Use 'show' and 'hide' stuff.

    // endInclusive can be null on syntax errors and there's recovery of the
    // import. For now we'll ignore this.
    Import i = new Import(node, importUri, conditionalUris,
        prefix?.token.lexeme, startInclusive, endInclusive!);
    currentContainer.addChild(i, map);
    if (prefix == null) {
      log("Hello import");
    } else {
      log("Hello import as '${prefix.token}'");
    }
  }

  @override
  void visitLibraryName(
      LibraryNameEnd node, Token startInclusive, Token endInclusive) {
    LibraryName name = new LibraryName(node, startInclusive, endInclusive);
    name.marked = Coloring.Marked;
    currentContainer.addChild(name, map);
  }

  @override
  void visitMetadata(
      MetadataEnd node, Token startInclusive, Token endInclusive) {
    Metadata m = new Metadata(node, startInclusive, endInclusive);
    currentContainer.addChild(m, map);
  }

  @override
  void visitMixin(
      MixinDeclarationEnd node, Token startInclusive, Token endInclusive) {
    TopLevelDeclarationEnd parent = node.parent! as TopLevelDeclarationEnd;
    IdentifierHandle identifier = parent.getIdentifier();
    log("Hello from mixin ${identifier.token}");

    Mixin mixin = new Mixin(
        parent, identifier.token.lexeme, startInclusive, endInclusive);
    currentContainer.addChild(mixin, map);

    Container previousContainer = currentContainer;
    currentContainer = mixin;
    super.visitMixin(node, startInclusive, endInclusive);
    currentContainer = previousContainer;
  }

  @override
  void visitMixinFields(
      MixinFieldsEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Mixin);
    List<String> fields =
        node.getFieldIdentifiers().map((e) => e.token.lexeme).toList();
    MixinFields mixinFields =
        new MixinFields(node, fields, startInclusive, endInclusive);
    currentContainer.addChild(mixinFields, map);
    log("Hello from mixin fields ${fields.join(", ")}");
    super.visitMixinFields(node, startInclusive, endInclusive);
  }

  @override
  void visitMixinMethod(
      MixinMethodEnd node, Token startInclusive, Token endInclusive) {
    assert(currentContainer is Mixin);
    MixinMethod classMethod = new MixinMethod(
        node, node.getNameIdentifier(), startInclusive, endInclusive);
    currentContainer.addChild(classMethod, map);
    log("Hello from mixin method ${node.getNameIdentifier()}");
    super.visitMixinMethod(node, startInclusive, endInclusive);
  }

  @override
  void visitNamedMixin(
      NamedMixinApplicationEnd node, Token startInclusive, Token endInclusive) {
    TopLevelDeclarationEnd parent = node.parent! as TopLevelDeclarationEnd;
    IdentifierHandle identifier = parent.getIdentifier();
    log("Hello from named mixin ${identifier.token}");

    Mixin mixin = new Mixin(
        parent, identifier.token.lexeme, startInclusive, endInclusive);
    currentContainer.addChild(mixin, map);

    Container previousContainer = currentContainer;
    currentContainer = mixin;
    super.visitNamedMixin(node, startInclusive, endInclusive);
    currentContainer = previousContainer;
  }

  @override
  void visitPart(PartEnd node, Token startInclusive, Token endInclusive) {
    String uriString = node.getPartUriString();
    Uri partUri = uri.resolve(uriString);

    Part i = new Part(node, partUri, startInclusive, endInclusive);
    currentContainer.addChild(i, map);
    log("Hello part");
  }

  @override
  void visitPartOf(PartOfEnd node, Token startInclusive, Token endInclusive) {
    // We'll assume we've gotten here via a "part" so we'll ignore that for now.
    // TODO: partOfUri could - in an error case - be null.
    if (partOfUri == null) throw "partOfUri is null -- uri $uri";
    PartOf partof = new PartOf(node, partOfUri!, startInclusive, endInclusive);
    partof.marked = Coloring.Marked;
    currentContainer.addChild(partof, map);
  }

  @override
  void visitTopLevelFields(
      TopLevelFieldsEnd node, Token startInclusive, Token endInclusive) {
    List<String> fields =
        node.getFieldIdentifiers().map((e) => e.token.lexeme).toList();
    TopLevelFields f =
        new TopLevelFields(node, fields, startInclusive, endInclusive);
    currentContainer.addChild(f, map);
    log("Hello from top level fields ${fields.join(", ")}");
    super.visitTopLevelFields(node, startInclusive, endInclusive);
  }

  @override
  void visitTopLevelMethod(
      TopLevelMethodEnd node, Token startInclusive, Token endInclusive) {
    TopLevelMethod m = new TopLevelMethod(node,
        node.getNameIdentifier().token.lexeme, startInclusive, endInclusive);
    currentContainer.addChild(m, map);
    log("Hello from top level method ${node.getNameIdentifier().token}");
    super.visitTopLevelMethod(node, startInclusive, endInclusive);
  }

  @override
  void visitTypedef(TypedefEnd node, Token startInclusive, Token endInclusive) {
    Typedef t = new Typedef(node, node.getNameIdentifier().token.lexeme,
        startInclusive, endInclusive);
    currentContainer.addChild(t, map);
    log("Hello from typedef ${node.getNameIdentifier().token}");
    super.visitTypedef(node, startInclusive, endInclusive);
  }
}
