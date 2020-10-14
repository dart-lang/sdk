// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io'
    show Directory, File, FileSystemEntity, exitCode, stdin, stdout;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show CommentToken, Token;
import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:front_end/src/api_unstable/ddc.dart'
    show CompilerContext, IncrementalCompiler, ProcessedOptions, Severity;
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler, IncrementalKernelTarget;
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;
import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;
import 'package:front_end/src/fasta/source/source_loader.dart'
    show SourceLoader;
import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart' show TargetFlags;
import "package:vm/target/vm.dart" show VmTarget;

import "utils/io_utils.dart";

final Uri repoDir = computeRepoDirUri();

Set<Uri> libUris = {};

Component component;

Future<void> main(List<String> args) async {
  api.CompilerOptions compilerOptions = getOptions();

  Uri dotPackagesUri = repoDir.resolve(".packages");
  if (!new File.fromUri(dotPackagesUri).existsSync()) {
    throw "Couldn't find .packages";
  }
  compilerOptions.packagesFileUri = dotPackagesUri;

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
  component = await incrementalCompiler.computeDelta();

  for (Library library in component.libraries) {
    if (library.importUri.scheme == "dart") continue;
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
      if (edits[uri] != null && edits[uri].isNotEmpty) {
        String update;
        while (update != "y" &&
            update != "yes" &&
            update != "n" &&
            update != "no") {
          print("Do you want to update $uri? (y/n)");
          update = stdin.readLineSync();
        }
        if (update != "y" && update != "yes") continue;

        List<Edit> theseEdits = edits[uri];
        theseEdits.sort((a, b) => a.offset - b.offset);
        String content = utf8.decode(component.uriToSource[uri].source,
            allowMalformed: true);
        StringBuffer sb = new StringBuffer();
        int latest = 0;
        for (Edit edit in theseEdits) {
          sb.write(content.substring(latest, edit.offset));
          sb.write(edit.insertData);
          latest = edit.offset;
        }
        sb.write(content.substring(latest, content.length));
        new File.fromUri(uri).writeAsStringSync(sb.toString());
        editsPerformed.add(uri);
      }
    }
    if (editsPerformed.isNotEmpty) {
      print("\n\nYou should now probably run something like\n\n");
      stdout.write(r"tools/sdks/dart-sdk/bin/dartfmt -w");
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

class InvocationVisitor extends RecursiveVisitor<void> {
  void visitProcedure(Procedure node) {
    if (node.isNoSuchMethodForwarder) return;
    super.visitProcedure(node);
  }

  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (node.interfaceTargetReference?.node != null) {
      note(node.interfaceTargetReference?.node, node.arguments, node);
    }
  }

  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    super.visitSuperMethodInvocation(node);
    note(node.interfaceTargetReference.node, node.arguments, node);
  }

  void visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);
    note(node.targetReference.node, node.arguments, node);
  }

  void visitConstructorInvocation(ConstructorInvocation node) {
    super.visitConstructorInvocation(node);
    note(node.targetReference.node, node.arguments, node);
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
      if (arguments.positional[i] is NullLiteral ||
          arguments.positional[i] is BoolLiteral ||
          arguments.positional[i] is IntLiteral) {
        wantComment = true;
      } else if (arguments.positional[i] is MapLiteral) {
        MapLiteral literal = arguments.positional[i];
        if (literal.entries.isEmpty) wantComment = true;
      } else if (arguments.positional[i] is ListLiteral) {
        ListLiteral literal = arguments.positional[i];
        if (literal.expressions.isEmpty) wantComment = true;
      } else if (arguments.positional[i] is MethodInvocation) {
        MethodInvocation methodInvocation = arguments.positional[i];
        if (methodInvocation.receiver is NullLiteral ||
            methodInvocation.receiver is IntLiteral ||
            methodInvocation.receiver is BoolLiteral) {
          wantComment = true;
        }
      }
      if (wantComment) {
        check(arguments.positional[i], i, positionalParameters[i], node,
            "/* ${positionalParameters[i].name} = */");
      }
    }
  }
}

Map<Uri, Token> cache = {};

void check(
    Expression argumentExpression,
    int parameterNumber,
    VariableDeclaration parameter,
    NamedNode targetNode,
    String expectedComment) {
  if (targetNode is Procedure && targetNode.kind == ProcedureKind.Operator) {
    // Operator calls doesn't look like 'regular' method calls.
    return;
  }
  if (argumentExpression.fileOffset == -1) return;
  Location location = argumentExpression.location;
  Token token = cache[location.file];
  while (token.offset != argumentExpression.fileOffset) {
    token = token.next;
    if (token.isEof) {
      throw "Couldn't find token for $argumentExpression "
          "(${argumentExpression.fileOffset}).";
    }
  }
  bool foundComment = false;
  CommentToken commentToken = token.precedingComments;
  while (commentToken != null) {
    if (commentToken.lexeme == expectedComment) {
      // Exact match.
      foundComment = true;
      break;
    }
    if (commentToken.lexeme.replaceAll(" ", "") ==
        expectedComment.replaceAll(" ", "")) {
      // Close enough.
      foundComment = true;
      break;
    }
    commentToken = commentToken.next;
  }
  if (foundComment) {
    return;
  }
  Location calculatedLocation =
      component.getLocation(location.file, token.offset);
  print("Please add comment $expectedComment at "
      "${token.offset} => "
      "${calculatedLocation}");
  edits[location.file] ??= [];
  edits[location.file].add(new Edit(token.offset, expectedComment));
}

Map<Uri, List<Edit>> edits = {};

class Edit {
  final int offset;
  final String insertData;
  Edit(this.offset, this.insertData);
}

class TestIncrementalCompiler extends IncrementalCompiler {
  TestIncrementalCompiler(CompilerContext context) : super(context);

  IncrementalKernelTarget createIncrementalKernelTarget(
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator) {
    return new TestIncrementalKernelTarget(
        fileSystem, /* includeComments = */ true, dillTarget, uriTranslator);
  }
}

class TestIncrementalKernelTarget extends IncrementalKernelTarget {
  TestIncrementalKernelTarget(api.FileSystem fileSystem, bool includeComments,
      DillTarget dillTarget, UriTranslator uriTranslator)
      : super(fileSystem, includeComments, dillTarget, uriTranslator);

  SourceLoader createLoader() =>
      new TestSourceLoader(fileSystem, includeComments, this);

  void runBuildTransformations() {
    // Don't do any transformations!
  }
}

class TestSourceLoader extends SourceLoader {
  TestSourceLoader(
      api.FileSystem fileSystem, bool includeComments, KernelTarget target)
      : super(fileSystem, includeComments, target);

  Future<Token> tokenize(SourceLibraryBuilder library,
      {bool suppressLexicalErrors: false}) async {
    Token result = await super
        .tokenize(library, suppressLexicalErrors: suppressLexicalErrors);
    cache[library.fileUri] = result;
    return result;
  }
}
