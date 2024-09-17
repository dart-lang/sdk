// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io'
    show Directory, File, FileSystemEntity, exitCode, stdin, stdout;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show CommentToken, Token;
import 'package:front_end/src/api_prototype/compiler_options.dart' as api
    show CompilerOptions, DiagnosticMessage;
import 'package:front_end/src/api_prototype/file_system.dart' as api
    show FileSystem;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/base/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/base/incremental_compiler.dart'
    show IncrementalCompiler, IncrementalKernelTarget;
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/base/uri_translator.dart' show UriTranslator;
import 'package:front_end/src/builder/library_builder.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/kernel/kernel_target.dart' show KernelTarget;
import 'package:front_end/src/source/source_loader.dart' show SourceLoader;
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart' show TargetFlags;
import "package:vm/modular/target/vm.dart" show VmTarget;

import "utils/io_utils.dart" show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

Set<Uri> libUris = {};

late Component component;

Future<void> main(List<String> args) async {
  api.CompilerOptions compilerOptions = getOptions();

  Uri packageConfigUri = repoDir.resolve(".dart_tool/package_config.json");
  if (!new File.fromUri(packageConfigUri).existsSync()) {
    throw "Couldn't find .dart_tool/package_config.json";
  }
  compilerOptions.packagesFileUri = packageConfigUri;

  ProcessedOptions options = new ProcessedOptions(options: compilerOptions);

  libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/src/parser"));
  libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/src/scanner"));
  for (Uri uri in libUris) {
    List<FileSystemEntity> entities =
        new Directory.fromUri(uri).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File && entity.path.endsWith(".dart")) {
        options.inputs.add(entity.uri);
      }
    }
  }
  CompilerContext context = new CompilerContext(options);
  IncrementalCompiler incrementalCompiler =
      new TestIncrementalCompiler(context);
  IncrementalCompilerResult incrementalCompilerResult =
      await incrementalCompiler.computeDelta();
  component = incrementalCompilerResult.component;

  for (Library library in component.libraries) {
    if (library.importUri.isScheme("dart")) continue;
    // This isn't perfect because of parts, but (for now) it'll do.
    for (Uri uri in libUris) {
      if (library.fileUri.toString().startsWith(uri.toString())) {
        library.accept(new InvocationVisitor());
        break;
      }
    }
  }

  if (args.isNotEmpty && args[0] == "--interactive") {
    List<Uri> editsPerformed = [];
    for (Uri uri in edits.keys) {
      print("\n\n\n");
      List<Edit>? theseEdits = edits[uri];
      if (theseEdits != null && theseEdits.isNotEmpty) {
        String? update;
        while (update != "y" &&
            update != "yes" &&
            update != "n" &&
            update != "no") {
          print("Do you want to update $uri? (y/n)");
          update = stdin.readLineSync();
        }
        if (update != "y" && update != "yes") continue;

        theseEdits.sort();
        String content = utf8.decode(component.uriToSource[uri]!.source,
            allowMalformed: true);
        StringBuffer sb = new StringBuffer();
        int latest = 0;
        for (Edit edit in theseEdits) {
          sb.write(content.substring(latest, edit.offset));
          switch (edit.editType) {
            case EditType.Insert:
              print(edit);
              sb.write(edit.insertData);
              latest = edit.offset;
              break;
            case EditType.Delete:
              print(edit);
              // We "delete" by skipping...
              latest = edit.offset + edit.length!;
              break;
          }
        }
        sb.write(content.substring(latest, content.length));
        new File.fromUri(uri).writeAsStringSync(sb.toString());
        editsPerformed.add(uri);
      }
    }
    if (editsPerformed.isNotEmpty) {
      print("\n\nYou should now probably run something like\n\n");
      stdout.write("dart format");
      for (Uri uri in editsPerformed) {
        File f = new File.fromUri(uri);
        Directory relative = new Directory.fromUri(Uri.base.resolve("."));
        if (!f.path.startsWith(relative.path)) {
          throw "${f.path} vs ${relative.path}";
        }
        String relativePath = f.path.substring(relative.path.length);
        stdout.write(" ${relativePath}");
      }
      stdout.write("\n\n");
    }
  }

  if (edits.isNotEmpty) {
    exitCode = 1;
  }

  int totalSuggestedEdits = edits.values
      .fold(0, (previousValue, element) => previousValue + element.length);
  print("Done. Suggested ${totalSuggestedEdits} edits "
      "in ${edits.length} files.");
}

int errorCount = 0;

api.CompilerOptions getOptions() {
  // Compile sdk because when this is run from a lint it uses the checked-in sdk
  // and we might not have a suitable compiled platform.dill file.
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = true
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (api.DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        print(message.plainTextFormatted.join('\n'));
        errorCount++;
      }
    }
    ..environmentDefines = const {};
  return options;
}

class InvocationVisitor extends RecursiveVisitor {
  @override
  void visitProcedure(Procedure node) {
    if (node.isNoSuchMethodForwarder) return;
    super.visitProcedure(node);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    super.visitSuperMethodInvocation(node);
    note(node.interfaceTargetReference.node!, node.arguments, node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);
    note(node.targetReference.node!, node.arguments, node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    super.visitConstructorInvocation(node);
    note(node.targetReference.node!, node.arguments, node);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    super.visitInstanceInvocation(node);
    note(node.interfaceTargetReference.node!, node.arguments, node);
  }

  void note(
      NamedNode node, Arguments arguments, InvocationExpression invocation) {
    List<VariableDeclaration> positionalParameters;
    if (node is Procedure) {
      positionalParameters = node.function.positionalParameters;
    } else if (node is Constructor) {
      positionalParameters = node.function.positionalParameters;
    } else {
      throw "Unexpected node: ${node.runtimeType}";
    }

    for (int i = 0; i < arguments.positional.length; i++) {
      bool wantComment = false;
      Expression argument = arguments.positional[i];
      if (argument is NullLiteral ||
          argument is BoolLiteral ||
          argument is IntLiteral) {
        wantComment = true;
      } else if (argument is MapLiteral) {
        if (argument.entries.isEmpty) wantComment = true;
      } else if (argument is ListLiteral) {
        if (argument.expressions.isEmpty) wantComment = true;
      } else if (argument is InstanceInvocation) {
        if (argument.receiver is NullLiteral ||
            argument.receiver is IntLiteral ||
            argument.receiver is BoolLiteral) {
          wantComment = true;
        }
      } else if (argument is DynamicInvocation) {
        if (argument.receiver is NullLiteral ||
            argument.receiver is IntLiteral ||
            argument.receiver is BoolLiteral) {
          wantComment = true;
        }
      } else if (argument is Not) {
        if (argument.operand is EqualsNull) {
          wantComment = true;
        }
      } else if (argument is EqualsNull) {
        wantComment = true;
      }
      if (wantComment) {
        check(arguments.positional[i], positionalParameters[i], node,
            "/* ${positionalParameters[i].name} = */");
      }
    }
  }
}

class LocationFinder extends RecursiveVisitor {
  int lowestOffsetFound = -1;

  @override
  void defaultNode(Node node) {
    // Stop here. We only want to recurse expressions.
  }

  @override
  void defaultExpression(Expression node) {
    if (lowestOffsetFound == -1 ||
        (node.fileOffset >= 0 && node.fileOffset < lowestOffsetFound)) {
      lowestOffsetFound = node.fileOffset;
    }
    node.visitChildren(this);
  }
}

Map<Uri, Token> cache = {};

void check(Expression argumentExpression, VariableDeclaration parameter,
    NamedNode targetNode, String expectedComment) {
  if (targetNode is Procedure && targetNode.kind == ProcedureKind.Operator) {
    // Operator calls doesn't look like 'regular' method calls.
    return;
  }
  int fileOffset = argumentExpression.fileOffset;
  if (fileOffset == -1) return;

  LocationFinder locationFinder = new LocationFinder();
  argumentExpression.accept(locationFinder);
  if (locationFinder.lowestOffsetFound != fileOffset) {
    fileOffset = locationFinder.lowestOffsetFound;
  }
  Location location = argumentExpression.location!;
  Token token = cache[location.file]!;
  while (token.offset != fileOffset) {
    token = token.next!;
    if (token.isEof) {
      throw "Couldn't find token for $argumentExpression "
          "(${fileOffset}).";
    }
  }
  bool foundComment = false;
  List<CommentToken> badComments = [];
  CommentToken? commentToken = token.precedingComments;
  while (commentToken != null) {
    if (commentToken.lexeme == expectedComment) {
      // Exact match.
      foundComment = true;
      break;
    }
    if (commentToken.lexeme.startsWith("/*") &&
        (commentToken.lexeme.endsWith("= */") ||
            commentToken.lexeme.endsWith("=*/"))) {
      badComments.add(commentToken);
    }
    commentToken = commentToken.next as CommentToken?;
  }
  if (badComments.isNotEmpty) {
    for (CommentToken comment in badComments) {
      Location calculatedLocation =
          component.getLocation(location.file, comment.offset)!;
      print("Please remove comment of length ${comment.lexeme.length} at "
          "${comment.offset} => "
          "${calculatedLocation}");
      (edits[location.file] ??= [])
          .add(new Edit.delete(comment.offset, comment.lexeme.length));
    }
  }
  if (foundComment) {
    return;
  }
  Location calculatedLocation =
      component.getLocation(location.file, token.offset)!;
  print("Please add comment $expectedComment at "
      "${token.offset} => "
      "${calculatedLocation}");
  (edits[location.file] ??= [])
      .add(new Edit.insert(token.offset, expectedComment));
}

Map<Uri, List<Edit>> edits = {};

enum EditType { Insert, Delete }

class Edit implements Comparable<Edit> {
  final int offset;
  final int? length;
  final String? insertData;
  final EditType editType;
  Edit.insert(this.offset, this.insertData)
      : editType = EditType.Insert,
        length = null;
  Edit.delete(this.offset, this.length)
      : editType = EditType.Delete,
        insertData = null;

  @override
  int compareTo(Edit other) {
    if (offset != other.offset) {
      return offset - other.offset;
    }
    throw "Why did this happen?";
  }

  @override
  String toString() {
    return "Edit[$editType @ $offset]";
  }
}

class TestIncrementalCompiler extends IncrementalCompiler {
  TestIncrementalCompiler(CompilerContext context) : super(context);

  @override
  IncrementalKernelTarget createIncrementalKernelTarget(
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator) {
    return new TestIncrementalKernelTarget(context, fileSystem,
        /* includeComments = */ true, dillTarget, uriTranslator);
  }
}

class TestIncrementalKernelTarget extends IncrementalKernelTarget {
  TestIncrementalKernelTarget(
      CompilerContext compilerContext,
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator)
      : super(compilerContext, fileSystem, includeComments, dillTarget,
            uriTranslator);

  @override
  SourceLoader createLoader() =>
      new TestSourceLoader(fileSystem, includeComments, this);

  @override
  void runBuildTransformations() {
    // Don't do any transformations!
  }
}

class TestSourceLoader extends SourceLoader {
  TestSourceLoader(
      api.FileSystem fileSystem, bool includeComments, KernelTarget target)
      : super(fileSystem, includeComments, target);

  @override
  Future<Token> tokenize(SourceCompilationUnit sourceCompilationUnit,
      {bool suppressLexicalErrors = false,
      bool allowLazyStrings = true}) async {
    Token result = await super.tokenize(sourceCompilationUnit,
        suppressLexicalErrors: suppressLexicalErrors,
        allowLazyStrings: allowLazyStrings);
    cache[sourceCompilationUnit.fileUri] = result;
    return result;
  }
}
