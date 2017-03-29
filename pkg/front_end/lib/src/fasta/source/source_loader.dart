// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_loader;

import 'dart:async' show Future;

import 'dart:io' show FileSystemException;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart' show Program;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../builder/builder.dart' show Builder, ClassBuilder, LibraryBuilder;

import '../compiler_context.dart' show CompilerContext;

import '../errors.dart' show inputError;

import '../export.dart' show Export;

import '../loader.dart' show Loader;

import '../parser/class_member_parser.dart' show ClassMemberParser;

import '../scanner.dart' show ErrorToken, ScannerResult, Token, scan;

import '../scanner/io.dart' show readBytesFromFile;

import '../target_implementation.dart' show TargetImplementation;

import 'diet_listener.dart' show DietListener;

import 'diet_parser.dart' show DietParser;

import 'outline_builder.dart' show OutlineBuilder;

import 'source_class_builder.dart' show SourceClassBuilder;

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceLoader<L> extends Loader<L> {
  final Map<Uri, List<int>> sourceBytes = <Uri, List<int>>{};
  final bool excludeSource = CompilerContext.current.options.excludeSource;

  // Used when building directly to kernel.
  ClassHierarchy hierarchy;
  CoreTypes coreTypes;

  SourceLoader(TargetImplementation target) : super(target);

  Future<Token> tokenize(SourceLibraryBuilder library,
      {bool suppressLexicalErrors: false}) async {
    Uri uri = library.fileUri;
    if (uri == null || uri.scheme != "file") {
      return inputError(library.uri, -1, "Not found: ${library.uri}.");
    }
    try {
      List<int> bytes = sourceBytes[uri];
      if (bytes == null) {
        bytes = sourceBytes[uri] = await readBytesFromFile(uri);
      }
      byteCount += bytes.length - 1;
      ScannerResult result = scan(bytes);
      Token token = result.tokens;
      if (!suppressLexicalErrors) {
        List<int> source = getSource(bytes);
        target.addSourceInformation(library.fileUri, result.lineStarts, source);
      }
      while (token is ErrorToken) {
        if (!suppressLexicalErrors) {
          ErrorToken error = token;
          library.addCompileTimeError(token.charOffset, error.assertionMessage,
              fileUri: uri);
        }
        token = token.next;
      }
      return token;
    } on FileSystemException catch (e) {
      String message = e.message;
      String osMessage = e.osError?.message;
      if (osMessage != null && osMessage.isNotEmpty) {
        message = osMessage;
      }
      return inputError(uri, -1, message);
    }
  }

  List<int> getSource(List<int> bytes) {
    if (excludeSource) return const <int>[];

    // bytes is 0-terminated. We don't want that included.
    if (bytes is Uint8List) {
      return new Uint8List.view(
          bytes.buffer, bytes.offsetInBytes, bytes.length - 1);
    }
    return bytes.sublist(0, bytes.length - 1);
  }

  Future<Null> buildOutline(SourceLibraryBuilder library) async {
    Token tokens = await tokenize(library);
    if (tokens == null) return;
    OutlineBuilder listener = new OutlineBuilder(library);
    new ClassMemberParser(listener).parseUnit(tokens);
  }

  Future<Null> buildBody(LibraryBuilder library) async {
    if (library is SourceLibraryBuilder) {
      // We tokenize source files twice to keep memory usage low. This is the
      // second time, and the first time was in [buildOutline] above. So this
      // time we suppress lexical errors.
      Token tokens = await tokenize(library, suppressLexicalErrors: true);
      if (tokens == null) return;
      DietListener listener = createDietListener(library);
      DietParser parser = new DietParser(listener);
      parser.parseUnit(tokens);
      for (SourceLibraryBuilder part in library.parts) {
        Token tokens = await tokenize(part);
        if (tokens != null) {
          listener.uri = part.fileUri;
          parser.parseUnit(tokens);
        }
      }
    }
  }

  DietListener createDietListener(LibraryBuilder library) {
    return new DietListener(library, hierarchy, coreTypes);
  }

  void resolveParts() {
    List<Uri> parts = <Uri>[];
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        if (library.isPart) {
          library.validatePart();
          parts.add(uri);
        } else {
          library.includeParts();
        }
      }
    });
    parts.forEach(builders.remove);
    ticker.logMs("Resolved parts");
  }

  void computeLibraryScopes() {
    Set<LibraryBuilder> exporters = new Set<LibraryBuilder>();
    Set<LibraryBuilder> exportees = new Set<LibraryBuilder>();
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        library.buildInitialScopes();
      }
      if (library.exporters.isNotEmpty) {
        exportees.add(library);
        for (Export exporter in library.exporters) {
          exporters.add(exporter.exporter);
        }
      }
    });
    Set<SourceLibraryBuilder> both = new Set<SourceLibraryBuilder>();
    for (LibraryBuilder exported in exportees) {
      if (exporters.contains(exported)) {
        both.add(exported);
      }
      for (Export export in exported.exporters) {
        exported.exports.forEach(export.addToExportScope);
      }
    }
    bool wasChanged = false;
    do {
      wasChanged = false;
      for (SourceLibraryBuilder exported in both) {
        for (Export export in exported.exporters) {
          SourceLibraryBuilder exporter = export.exporter;
          exported.exports.forEach((String name, Builder member) {
            if (exporter.addToExportScope(name, member)) {
              wasChanged = true;
            }
          });
        }
      }
    } while (wasChanged);
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        library.addImportsToScope();
      }
    });
    ticker.logMs("Computed library scopes");
    // debugPrintExports();
  }

  void debugPrintExports() {
    // TODO(sigmund): should be `covarint SourceLibraryBuilder`.
    builders.forEach((Uri uri, dynamic l) {
      SourceLibraryBuilder library = l;
      Set<Builder> members = new Set<Builder>();
      library.members.forEach((String name, Builder member) {
        while (member != null) {
          members.add(member);
          member = member.next;
        }
      });
      List<String> exports = <String>[];
      library.exports.forEach((String name, Builder member) {
        while (member != null) {
          if (!members.contains(member)) {
            exports.add(name);
          }
          member = member.next;
        }
      });
      if (exports.isNotEmpty) {
        print("$uri exports $exports");
      }
    });
  }

  void resolveTypes() {
    int typeCount = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      typeCount += library.resolveTypes(null);
    });
    ticker.logMs("Resolved $typeCount types");
  }

  void finishStaticInvocations() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      count += library.finishStaticInvocations();
    });
    ticker.logMs("Finished static invocations $count");
  }

  void resolveConstructors() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      count += library.resolveConstructors(null);
    });
    ticker.logMs("Resolved $count constructors");
  }

  void finishTypeVariables(ClassBuilder object) {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      count += library.finishTypeVariables(object);
    });
    ticker.logMs("Resolved $count type-variable bounds");
  }

  void finishNativeMethods() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      count += library.finishNativeMethods();
    });
    ticker.logMs("Finished $count native methods");
  }

  /// Returns all the supertypes (including interfaces) of [cls]
  /// transitively. Includes [cls].
  Set<ClassBuilder> allSupertypes(ClassBuilder cls) {
    int length = 0;
    Set<ClassBuilder> result = new Set<ClassBuilder>()..add(cls);
    while (length != result.length) {
      length = result.length;
      result.addAll(directSupertypes(result));
    }
    return result;
  }

  /// Returns the direct supertypes (including interface) of [classes]. A class
  /// from [classes] is only included if it is a supertype of one of the other
  /// classes in [classes].
  Set<ClassBuilder> directSupertypes(Iterable<ClassBuilder> classes) {
    Set<ClassBuilder> result = new Set<ClassBuilder>();
    for (ClassBuilder cls in classes) {
      target.addDirectSupertype(cls, result);
    }
    return result;
  }

  /// Computes a set of classes that may have cycles. The set is empty if there
  /// are no cycles. If the set isn't empty, it will include supertypes of
  /// classes with cycles, as well as the classes with cycles.
  ///
  /// It is assumed that [classes] is a transitive closure with respect to
  /// supertypes.
  Iterable<ClassBuilder> cyclicCandidates(Iterable<ClassBuilder> classes) {
    // The candidates are found by a fixed-point computation.
    //
    // On each iteration, the classes that have no supertypes in the input set
    // will be removed.
    //
    // If there are no cycles, eventually, the set will converge on Object, and
    // the next iteration will make the set empty (as Object has no
    // supertypes).
    //
    // On the other hand, if there is a cycle, the cycle will remain in the
    // set, and so will its supertypes, and eventually the input and output set
    // will have the same length.
    Iterable<ClassBuilder> input = const [];
    Iterable<ClassBuilder> output = classes;
    while (input.length != output.length) {
      input = output;
      output = directSupertypes(input);
    }
    return output;
  }

  void checkSemantics() {
    List<ClassBuilder> allClasses = target.collectAllClasses();
    Iterable<ClassBuilder> candidates = cyclicCandidates(allClasses);
    Map<ClassBuilder, Set<ClassBuilder>> realCycles =
        <ClassBuilder, Set<ClassBuilder>>{};
    for (ClassBuilder cls in candidates) {
      Set<ClassBuilder> cycles = cyclicCandidates(allSupertypes(cls));
      if (cycles.isNotEmpty) {
        realCycles[cls] = cycles;
      }
    }
    Set<ClassBuilder> reported = new Set<ClassBuilder>();
    realCycles.forEach((ClassBuilder cls, Set<ClassBuilder> cycles) {
      target.breakCycle(cls);
      if (reported.add(cls)) {
        List<ClassBuilder> involved = <ClassBuilder>[];
        for (ClassBuilder cls in cycles) {
          if (realCycles.containsKey(cls)) {
            involved.add(cls);
            reported.add(cls);
          }
        }
        cls.addCompileTimeError(
            cls.charOffset,
            "'${cls.name}' is a supertype of "
            "itself via '${involved.map((c) => c.name).join(' ')}'.");
      }
    });
    ticker.logMs("Found cycles");
  }

  void buildProgram() {
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        libraries.add(library.build());
      }
    });
    ticker.logMs("Built program");
  }

  void computeHierarchy(Program program) {
    hierarchy = new ClassHierarchy(program);
    ticker.logMs("Computed class hierarchy");
    coreTypes = new CoreTypes(program);
    ticker.logMs("Computed core types");
  }

  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    assert(hierarchy != null);
    for (SourceClassBuilder builder in sourceClasses) {
      builder.checkOverrides(hierarchy);
    }
    ticker.logMs("Checked overrides");
  }

  List<Uri> getDependencies() => sourceBytes.keys.toList();
}
