// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_loader;

import 'dart:async' show Future;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/type_inference/interface_resolver.dart'
    show InterfaceResolver;

import 'package:kernel/ast.dart' show Arguments, Expression, Program;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/src/incremental_class_hierarchy.dart'
    show IncrementalClassHierarchy;

import '../../../file_system.dart';

import '../../base/instrumentation.dart' show Instrumentation;

import '../builder/builder.dart'
    show
        Builder,
        ClassBuilder,
        EnumBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder;

import '../compiler_context.dart' show CompilerContext;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../problems.dart' show internalProblem;

import '../export.dart' show Export;

import '../fasta_codes.dart'
    show
        Message,
        templateCyclicClassHierarchy,
        templateExtendingEnum,
        templateExtendingRestricted,
        templateIllegalMixin,
        templateIllegalMixinDueToConstructors,
        templateIllegalMixinDueToConstructorsCause,
        templateInternalProblemUriMissingScheme;

import '../kernel/kernel_shadow_ast.dart'
    show ShadowClass, ShadowTypeInferenceEngine;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../loader.dart' show Loader;

import '../parser/class_member_parser.dart' show ClassMemberParser;

import '../scanner.dart' show ErrorToken, ScannerResult, Token, scan;

import '../severity.dart' show Severity;

import '../type_inference/type_inference_engine.dart' show TypeInferenceEngine;

import 'diet_listener.dart' show DietListener;

import 'diet_parser.dart' show DietParser;

import 'outline_builder.dart' show OutlineBuilder;

import 'source_class_builder.dart' show SourceClassBuilder;

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceLoader<L> extends Loader<L> {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final Map<Uri, List<int>> sourceBytes = <Uri, List<int>>{};

  final bool excludeSource = !CompilerContext.current.options.embedSourceText;

  // Used when building directly to kernel.
  ClassHierarchy hierarchy;
  CoreTypes coreTypes;

  TypeInferenceEngine typeInferenceEngine;

  InterfaceResolver interfaceResolver;

  Instrumentation instrumentation;

  List<ClassBuilder> orderedClasses;

  SourceLoader(this.fileSystem, this.includeComments, KernelTarget target)
      : super(target);

  Future<Token> tokenize(SourceLibraryBuilder library,
      {bool suppressLexicalErrors: false}) async {
    Uri uri = library.fileUri;
    if (uri == null) {
      return deprecated_inputError(
          library.uri, -1, "Not found: ${library.uri}.");
    } else if (!uri.hasScheme) {
      return internalProblem(
          templateInternalProblemUriMissingScheme.withArguments(uri),
          -1,
          library.uri);
    }

    // Get the library text from the cache, or read from the file system.
    List<int> bytes = sourceBytes[uri];
    if (bytes == null) {
      try {
        List<int> rawBytes = await fileSystem.entityForUri(uri).readAsBytes();
        Uint8List zeroTerminatedBytes = new Uint8List(rawBytes.length + 1);
        zeroTerminatedBytes.setRange(0, rawBytes.length, rawBytes);
        bytes = zeroTerminatedBytes;
        sourceBytes[uri] = bytes;
      } on FileSystemException catch (e) {
        return deprecated_inputError(uri, -1, e.message);
      }
    }

    byteCount += bytes.length - 1;
    ScannerResult result = scan(bytes, includeComments: includeComments);
    Token token = result.tokens;
    if (!suppressLexicalErrors) {
      List<int> source = getSource(bytes);
      target.addSourceInformation(library.fileUri, result.lineStarts, source);
    }
    while (token is ErrorToken) {
      if (!suppressLexicalErrors) {
        ErrorToken error = token;
        library.addCompileTimeError(
            error.assertionMessage, token.charOffset, uri);
      }
      token = token.next;
    }
    return token;
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

  KernelTarget get target => super.target;

  DietListener createDietListener(LibraryBuilder library) {
    return new DietListener(library, hierarchy, coreTypes, typeInferenceEngine);
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
        exported.exportScope.forEach(export.addToExportScope);
      }
    }
    bool wasChanged = false;
    do {
      wasChanged = false;
      for (SourceLibraryBuilder exported in both) {
        for (Export export in exported.exporters) {
          exported.exportScope.forEach((String name, Builder member) {
            if (export.addToExportScope(name, member)) {
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
      library.forEach((String name, Builder member) {
        while (member != null) {
          members.add(member);
          member = member.next;
        }
      });
      List<String> exports = <String>[];
      library.exportScope.forEach((String name, Builder member) {
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
        String involvedString =
            involved.map((c) => c.fullNameForErrors).join("', '");
        cls.addCompileTimeError(
            templateCyclicClassHierarchy.withArguments(
                cls.fullNameForErrors, involvedString),
            cls.charOffset);
      }
    });
    ticker.logMs("Found cycles");
    Set<ClassBuilder> blackListedClasses = new Set<ClassBuilder>.from([
      coreLibrary["bool"],
      coreLibrary["int"],
      coreLibrary["num"],
      coreLibrary["double"],
      coreLibrary["String"],
    ]);
    for (ClassBuilder cls in allClasses) {
      if (cls.library.loader != this) continue;
      Set<ClassBuilder> directSupertypes = new Set<ClassBuilder>();
      target.addDirectSupertype(cls, directSupertypes);
      for (ClassBuilder supertype in directSupertypes) {
        if (supertype is EnumBuilder) {
          cls.addCompileTimeError(
              templateExtendingEnum.withArguments(supertype.name),
              cls.charOffset);
        } else if (!cls.library.mayImplementRestrictedTypes &&
            blackListedClasses.contains(supertype)) {
          cls.addCompileTimeError(
              templateExtendingRestricted.withArguments(supertype.name),
              cls.charOffset);
        }
      }
      TypeBuilder mixedInType = cls.mixedInType;
      if (mixedInType != null) {
        bool isClassBuilder = false;
        if (mixedInType is NamedTypeBuilder) {
          var builder = mixedInType.builder;
          if (builder is ClassBuilder) {
            isClassBuilder = true;
            for (Builder constructory in builder.constructors.local.values) {
              if (constructory.isConstructor && !constructory.isSynthetic) {
                cls.addCompileTimeError(
                    templateIllegalMixinDueToConstructors
                        .withArguments(builder.fullNameForErrors),
                    cls.charOffset);
                builder.addCompileTimeError(
                    templateIllegalMixinDueToConstructorsCause
                        .withArguments(builder.fullNameForErrors),
                    constructory.charOffset);
              }
            }
          }
        }
        if (!isClassBuilder) {
          cls.addCompileTimeError(
              templateIllegalMixin.withArguments(mixedInType.fullNameForErrors),
              cls.charOffset);
        }
      }
    }
    ticker.logMs("Checked restricted supertypes");
  }

  void buildProgram() {
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        libraries.add(library.build(coreLibrary));
      }
    });
    ticker.logMs("Built program");
  }

  void computeHierarchy(Program program) {
    hierarchy = new IncrementalClassHierarchy();
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

  void createTypeInferenceEngine() {
    typeInferenceEngine =
        new ShadowTypeInferenceEngine(instrumentation, target.strongMode);
  }

  /// Performs the first phase of top level initializer inference, which
  /// consists of creating kernel objects for all fields and top level variables
  /// that might be subject to type inference, and records dependencies between
  /// them.
  void prepareTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    typeInferenceEngine.prepareTopLevel(coreTypes, hierarchy);
    interfaceResolver = new InterfaceResolver(
        typeInferenceEngine,
        typeInferenceEngine.typeSchemaEnvironment,
        instrumentation,
        target.strongMode);
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        library.prepareTopLevelInference(library, null);
      }
    });
    // Note: we need to create a list before iterating, since calling
    // builder.prepareTopLevelInference causes further class hierarchy queries
    // to be made which would otherwise result in a concurrent modification
    // exception.
    orderedClasses = hierarchy
        .getOrderedClasses(sourceClasses.map((builder) => builder.target))
        .map((class_) => ShadowClass.getClassInferenceInfo(class_).builder)
        .toList();
    for (var builder in orderedClasses) {
      ShadowClass class_ = builder.target;
      builder.prepareTopLevelInference(builder.library, builder);
      class_.setupApiMembers(interfaceResolver);
    }
    typeInferenceEngine.isTypeInferencePrepared = true;
    ticker.logMs("Prepared top level inference");
  }

  /// Performs the second phase of top level initializer inference, which is to
  /// visit fields and top level variables in topologically-sorted order and
  /// assign their types.
  void performTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    typeInferenceEngine.finishTopLevelFields();
    for (var builder in orderedClasses) {
      ShadowClass class_ = builder.target;
      class_.finalizeCovariance(interfaceResolver);
      ShadowClass.clearClassInferenceInfo(class_);
    }
    orderedClasses = null;
    typeInferenceEngine.finishTopLevelInitializingFormals();
    if (instrumentation != null) {
      builders.forEach((Uri uri, LibraryBuilder library) {
        if (library is SourceLibraryBuilder) {
          library.instrumentTopLevelInference(instrumentation);
        }
      });
    }
    interfaceResolver = null;
    // Since finalization of covariance may have added forwarding stubs, we need
    // to recompute the class hierarchy so that method compilation will properly
    // target those forwarding stubs.
    // TODO(paulberry): could we make this unnecessary by not clearing class
    // inference info?
    typeInferenceEngine.classHierarchy =
        hierarchy = new IncrementalClassHierarchy();
    ticker.logMs("Performed top level inference");
  }

  List<Uri> getDependencies() => sourceBytes.keys.toList();

  Expression instantiateInvocation(Expression receiver, String name,
      Arguments arguments, int offset, bool isSuper) {
    return target.backendTarget.instantiateInvocation(
        coreTypes, receiver, name, arguments, offset, isSuper);
  }

  Expression instantiateNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    return target.backendTarget.instantiateNoSuchMethodError(
        coreTypes, receiver, name, arguments, offset,
        isMethod: isMethod,
        isGetter: isGetter,
        isSetter: isSetter,
        isField: isField,
        isLocalVariable: isLocalVariable,
        isDynamic: isDynamic,
        isSuper: isSuper,
        isStatic: isStatic,
        isConstructor: isConstructor,
        isTopLevel: isTopLevel);
  }

  Expression throwCompileConstantError(Expression error) {
    return target.backendTarget.throwCompileConstantError(coreTypes, error);
  }

  Expression buildCompileTimeError(Message message, int offset, Uri uri) {
    String text = target.context
        .format(message.withLocation(uri, offset), Severity.error);
    return target.backendTarget.buildCompileTimeError(coreTypes, text, offset);
  }
}
