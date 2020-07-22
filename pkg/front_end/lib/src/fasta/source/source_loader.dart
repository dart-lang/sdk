// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_loader;

import 'dart:async' show Future;

import 'dart:convert' show utf8;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/class_member_parser.dart'
    show ClassMemberParser;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show Parser, lengthForToken;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show
        ErrorToken,
        LanguageVersionToken,
        Scanner,
        ScannerConfiguration,
        ScannerResult,
        Token,
        scan;
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
        BottomType,
        Class,
        Component,
        DartType,
        Expression,
        FunctionNode,
        InterfaceType,
        Library,
        LibraryDependency,
        Nullability,
        ProcedureKind,
        Reference,
        Supertype,
        TreeNode,
        Version;

import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, HandleAmbiguousSupertypes;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;

import 'package:package_config/package_config.dart';

import '../../api_prototype/file_system.dart';

import '../../base/common.dart';

import '../../base/instrumentation.dart' show Instrumentation;

import '../../base/nnbd_mode.dart';

import '../denylisted_classes.dart' show denylistedCoreClasses;

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/enum_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/field_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';

import '../export.dart' show Export;

import '../import.dart' show Import;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        SummaryTemplate,
        Template,
        messageObjectExtends,
        messageObjectImplements,
        messageObjectMixesIn,
        messagePartOrphan,
        messageStrongModeNNBDButOptOut,
        messageTypedefCause,
        messageTypedefUnaliasedTypeCause,
        noLength,
        templateAmbiguousSupertypes,
        templateCantReadFile,
        templateCyclicClassHierarchy,
        templateDuplicatedLibraryExport,
        templateDuplicatedLibraryExportContext,
        templateDuplicatedLibraryImport,
        templateDuplicatedLibraryImportContext,
        templateExtendingEnum,
        templateExtendingRestricted,
        templateIllegalMixin,
        templateIllegalMixinDueToConstructors,
        templateIllegalMixinDueToConstructorsCause,
        templateInternalProblemUriMissingScheme,
        templateSourceOutlineSummary,
        templateStrongModeNNBDPackageOptOut,
        templateUntranslatableUri;

import '../kernel/kernel_builder.dart'
    show ClassHierarchyBuilder, ClassMember, DelayedOverrideCheck;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/transform_collections.dart' show CollectionTransformer;

import '../kernel/transform_set_literals.dart' show SetLiteralTransformer;

import '../kernel/type_builder_computer.dart' show TypeBuilderComputer;

import '../loader.dart' show Loader, untranslatableUriScheme;

import '../problems.dart' show internalProblem;

import '../source/stack_listener_impl.dart' show offsetForToken;

import '../type_inference/type_inference_engine.dart';

import '../type_inference/type_inferrer.dart';

import 'diet_listener.dart' show DietListener;

import 'diet_parser.dart' show DietParser;

import 'outline_builder.dart' show OutlineBuilder;

import 'source_class_builder.dart' show SourceClassBuilder;

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceLoader extends Loader {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final Map<Uri, List<int>> sourceBytes = <Uri, List<int>>{};

  ClassHierarchyBuilder builderHierarchy;

  ReferenceFromIndex referenceFromIndex;

  /// Used when building directly to kernel.
  ClassHierarchy hierarchy;
  CoreTypes _coreTypes;

  /// For builders created with a reference, this maps from that reference to
  /// that builder. This is used for looking up source builders when finalizing
  /// exports in dill builders.
  Map<Reference, Builder> buildersCreatedWithReferences = {};

  /// Used when checking whether a return type of an async function is valid.
  ///
  /// The said return type is valid if it's a subtype of [futureOfBottom].
  DartType futureOfBottom;

  /// Used when checking whether a return type of a sync* function is valid.
  ///
  /// The said return type is valid if it's a subtype of [iterableOfBottom].
  DartType iterableOfBottom;

  /// Used when checking whether a return type of an async* function is valid.
  ///
  /// The said return type is valid if it's a subtype of [streamOfBottom].
  DartType streamOfBottom;

  TypeInferenceEngineImpl typeInferenceEngine;

  Instrumentation instrumentation;

  CollectionTransformer collectionTransformer;

  SetLiteralTransformer setLiteralTransformer;

  final SourceLoaderDataForTesting dataForTesting;

  SourceLoader(this.fileSystem, this.includeComments, KernelTarget target)
      : dataForTesting =
            retainDataForTesting ? new SourceLoaderDataForTesting() : null,
        super(target);

  NnbdMode get nnbdMode => target.context.options.nnbdMode;

  CoreTypes get coreTypes {
    assert(_coreTypes != null, "CoreTypes has not been computed.");
    return _coreTypes;
  }

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateSourceOutlineSummary;

  bool get isSourceLoader => true;

  Future<Token> tokenize(SourceLibraryBuilder library,
      {bool suppressLexicalErrors: false}) async {
    Uri uri = library.fileUri;

    // Lookup the file URI in the cache.
    List<int> bytes = sourceBytes[uri];

    if (bytes == null) {
      // Error recovery.
      if (uri.scheme == untranslatableUriScheme) {
        Message message =
            templateUntranslatableUri.withArguments(library.importUri);
        library.addProblemAtAccessors(message);
        bytes = synthesizeSourceForMissingFile(library.importUri, null);
      } else if (!uri.hasScheme) {
        return internalProblem(
            templateInternalProblemUriMissingScheme.withArguments(uri),
            -1,
            library.importUri);
      } else if (uri.scheme == SourceLibraryBuilder.MALFORMED_URI_SCHEME) {
        bytes = synthesizeSourceForMissingFile(library.importUri, null);
      }
      if (bytes != null) {
        Uint8List zeroTerminatedBytes = new Uint8List(bytes.length + 1);
        zeroTerminatedBytes.setRange(0, bytes.length, bytes);
        bytes = zeroTerminatedBytes;
        sourceBytes[uri] = bytes;
      }
    }

    if (bytes == null) {
      // If it isn't found in the cache, read the file read from the file
      // system.
      List<int> rawBytes;
      try {
        rawBytes = await fileSystem.entityForUri(uri).readAsBytes();
      } on FileSystemException catch (e) {
        Message message = templateCantReadFile.withArguments(uri, e.message);
        library.addProblemAtAccessors(message);
        rawBytes = synthesizeSourceForMissingFile(library.importUri, message);
      }
      Uint8List zeroTerminatedBytes = new Uint8List(rawBytes.length + 1);
      zeroTerminatedBytes.setRange(0, rawBytes.length, rawBytes);
      bytes = zeroTerminatedBytes;
      sourceBytes[uri] = bytes;
      byteCount += rawBytes.length;
    }

    ScannerResult result = scan(bytes,
        includeComments: includeComments,
        configuration: new ScannerConfiguration(
            enableTripleShift: library.enableTripleShiftInLibrary,
            enableExtensionMethods: library.enableExtensionMethodsInLibrary,
            enableNonNullable: library.isNonNullableByDefault),
        languageVersionChanged:
            (Scanner scanner, LanguageVersionToken version) {
      if (!suppressLexicalErrors) {
        library.setLanguageVersion(new Version(version.major, version.minor),
            offset: version.offset, length: version.length, explicit: true);
      }
      scanner.configuration = new ScannerConfiguration(
          enableTripleShift: library.enableTripleShiftInLibrary,
          enableExtensionMethods: library.enableExtensionMethodsInLibrary,
          enableNonNullable: library.isNonNullableByDefault);
    });
    Token token = result.tokens;
    if (!suppressLexicalErrors) {
      List<int> source = getSource(bytes);
      Uri importUri = library.importUri;
      if (library.isPatch) {
        // For patch files we create a "fake" import uri.
        // We cannot use the import uri from the patched library because
        // several different files would then have the same import uri,
        // and the VM does not support that. Also, what would, for instance,
        // setting a breakpoint on line 42 of some import uri mean, if the uri
        // represented several files?
        List<String> newPathSegments =
            new List<String>.from(importUri.pathSegments);
        newPathSegments.add(library.fileUri.pathSegments.last);
        newPathSegments[0] = "${newPathSegments[0]}-patch";
        importUri = importUri.replace(pathSegments: newPathSegments);
      }
      target.addSourceInformation(
          importUri, library.fileUri, result.lineStarts, source);
    }
    library.issuePostponedProblems();
    library.markLanguageVersionFinal();
    while (token is ErrorToken) {
      if (!suppressLexicalErrors) {
        ErrorToken error = token;
        library.addProblem(error.assertionMessage, offsetForToken(token),
            lengthForToken(token), uri);
      }
      token = token.next;
    }
    return token;
  }

  List<int> synthesizeSourceForMissingFile(Uri uri, Message message) {
    switch ("$uri") {
      case "dart:core":
        return utf8.encode(defaultDartCoreSource);

      case "dart:async":
        return utf8.encode(defaultDartAsyncSource);

      case "dart:collection":
        return utf8.encode(defaultDartCollectionSource);

      case "dart:_internal":
        return utf8.encode(defaultDartInternalSource);

      case "dart:typed_data":
        return utf8.encode(defaultDartTypedDataSource);

      default:
        return utf8.encode(message == null ? "" : "/* ${message.message} */");
    }
  }

  Set<LibraryBuilder> _strongOptOutLibraries;

  void registerStrongOptOutLibrary(LibraryBuilder libraryBuilder) {
    _strongOptOutLibraries ??= {};
    _strongOptOutLibraries.add(libraryBuilder);
  }

  @override
  Future<Null> buildOutlines() async {
    await super.buildOutlines();

    if (_strongOptOutLibraries != null) {
      // We have libraries that are opted out in strong mode "non-explicitly",
      // that is, either implicitly through the package version or loaded from
      // .dill as opt out.
      //
      // To reduce the verbosity of the error messages we try to reduce the
      // message to only include the package name once for packages that are
      // opted out.
      //
      // We use the current package config to retrieve the package based
      // language version to determine whether the package as a whole is opted
      // out. If so, we only include the package name and not the library uri
      // in the message. For package libraries with no corresponding package
      // config we include each library uri in the message. For non-package
      // libraries with no corresponding package config we generate a message
      // per library.
      Map<String, List<LibraryBuilder>> libraryByPackage = {};
      for (LibraryBuilder libraryBuilder in _strongOptOutLibraries) {
        Package package =
            target.uriTranslator.getPackage(libraryBuilder.importUri);

        if (package != null &&
            package.languageVersion != null &&
            package.languageVersion is! InvalidLanguageVersion) {
          Version version = new Version(
              package.languageVersion.major, package.languageVersion.minor);
          if (version < enableNonNullableVersion) {
            (libraryByPackage[package?.name] ??= []).add(libraryBuilder);
            continue;
          }
        }
        if (libraryBuilder.importUri.scheme == 'package') {
          (libraryByPackage[null] ??= []).add(libraryBuilder);
        } else {
          // Emit a message that doesn't mention running 'pub'.
          addProblem(messageStrongModeNNBDButOptOut, -1, noLength,
              libraryBuilder.fileUri);
        }
      }
      if (libraryByPackage.isNotEmpty) {
        List<String> dependencies = [];
        libraryByPackage.forEach((String name, List<LibraryBuilder> libraries) {
          if (name != null) {
            dependencies.add('package:$name');
          } else {
            for (LibraryBuilder libraryBuilder in libraries) {
              dependencies.add(libraryBuilder.importUri.toString());
            }
          }
        });
        // Emit a message that suggests to run 'pub' to check for opted in
        // versions of the packages.
        addProblem(
            templateStrongModeNNBDPackageOptOut.withArguments(dependencies),
            -1,
            -1,
            null);
        _strongOptOutLibraries = null;
      }
    }
  }

  List<int> getSource(List<int> bytes) {
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
        if (part.partOfLibrary != library) {
          // Part was included in multiple libraries. Skip it here.
          continue;
        }
        Token tokens = await tokenize(part, suppressLexicalErrors: true);
        if (tokens != null) {
          listener.uri = part.fileUri;
          parser.parseUnit(tokens);
        }
      }
    }
  }

  // TODO(johnniwinther,jensj): Handle expression in extensions?
  Future<Expression> buildExpression(
      SourceLibraryBuilder library,
      String enclosingClass,
      bool isClassInstanceMember,
      FunctionNode parameters) async {
    Token token = await tokenize(library, suppressLexicalErrors: false);
    if (token == null) return null;
    DietListener dietListener = createDietListener(library);

    Builder parent = library;
    if (enclosingClass != null) {
      Builder cls = dietListener.memberScope.lookup(enclosingClass, -1, null);
      if (cls is ClassBuilder) {
        parent = cls;
        dietListener
          ..currentDeclaration = cls
          ..memberScope = cls.scope.copyWithParent(
              dietListener.memberScope.withTypeVariables(cls.typeVariables),
              "debugExpression in $enclosingClass");
      }
    }
    ProcedureBuilder builder = new SourceProcedureBuilder(
        null,
        0,
        null,
        "debugExpr",
        null,
        null,
        ProcedureKind.Method,
        library,
        0,
        0,
        -1,
        -1,
        null,
        null,
        AsyncMarker.Sync)
      ..parent = parent;
    BodyBuilder listener = dietListener.createListener(
        builder, dietListener.memberScope,
        isDeclarationInstanceMember: isClassInstanceMember);

    return listener.parseSingleExpression(
        new Parser(listener), token, parameters);
  }

  KernelTarget get target => super.target;

  DietListener createDietListener(SourceLibraryBuilder library) {
    return new DietListener(library, hierarchy, coreTypes, typeInferenceEngine);
  }

  void resolveParts() {
    List<Uri> parts = <Uri>[];
    List<SourceLibraryBuilder> libraries = <SourceLibraryBuilder>[];
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        if (library.isPart) {
          parts.add(uri);
        } else {
          libraries.add(library);
        }
      }
    });
    Set<Uri> usedParts = new Set<Uri>();
    for (SourceLibraryBuilder library in libraries) {
      library.includeParts(usedParts);
    }
    for (Uri uri in parts) {
      if (usedParts.contains(uri)) {
        builders.remove(uri);
      } else {
        SourceLibraryBuilder part = builders[uri];
        part.addProblem(messagePartOrphan, 0, 1, part.fileUri);
        part.validatePart(null, null);
      }
    }
    ticker.logMs("Resolved parts");

    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        library.applyPatches();
      }
    });
    ticker.logMs("Applied patches");
  }

  void computeLibraryScopes() {
    Set<LibraryBuilder> exporters = new Set<LibraryBuilder>();
    Set<LibraryBuilder> exportees = new Set<LibraryBuilder>();
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        sourceLibrary.buildInitialScopes();
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
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        sourceLibrary.addImportsToScope();
      }
    });
    for (LibraryBuilder exportee in exportees) {
      // TODO(ahe): Change how we track exporters. Currently, when a library
      // (exporter) exports another library (exportee) we add a reference to
      // exporter to exportee. This creates a reference in the wrong direction
      // and can lead to memory leaks.
      exportee.exporters.clear();
    }
    ticker.logMs("Computed library scopes");
    // debugPrintExports();
  }

  void debugPrintExports() {
    // TODO(sigmund): should be `covariant SourceLibraryBuilder`.
    builders.forEach((Uri uri, dynamic l) {
      SourceLibraryBuilder library = l;
      Set<Builder> members = new Set<Builder>();
      Iterator<Builder> iterator = library.iterator;
      while (iterator.moveNext()) {
        members.add(iterator.current);
      }
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
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        typeCount += sourceLibrary.resolveTypes();
      }
    });
    ticker.logMs("Resolved $typeCount types");
  }

  void finishDeferredLoadTearoffs() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishDeferredLoadTearoffs();
      }
    });
    ticker.logMs("Finished deferred load tearoffs $count");
  }

  void finishNoSuchMethodForwarders() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishForwarders();
      }
    });
    ticker.logMs("Finished forwarders for $count procedures");
  }

  void resolveConstructors() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.resolveConstructors(null);
      }
    });
    ticker.logMs("Resolved $count constructors");
  }

  void finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishTypeVariables(object, dynamicType);
      }
    });
    ticker.logMs("Resolved $count type-variable bounds");
  }

  void computeVariances() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.computeVariances();
      }
    });
    ticker.logMs("Computed variances of $count type variables");
  }

  void computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.computeDefaultTypes(
            dynamicType, nullType, bottomType, objectClass);
      }
    });
    ticker.logMs("Computed default types for $count type variables");
  }

  void finishNativeMethods() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishNativeMethods();
      }
    });
    ticker.logMs("Finished $count native methods");
  }

  void finishPatchMethods() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishPatchMethods();
      }
    });
    ticker.logMs("Finished $count patch methods");
  }

  /// Check that [objectClass] has no supertypes. Recover by removing any
  /// found.
  void checkObjectClassHierarchy(ClassBuilder objectClass) {
    if (objectClass is SourceClassBuilder &&
        objectClass.library.loader == this) {
      if (objectClass.supertypeBuilder != null) {
        objectClass.supertypeBuilder = null;
        objectClass.addProblem(
            messageObjectExtends, objectClass.charOffset, noLength);
      }
      if (objectClass.interfaceBuilders != null) {
        objectClass.addProblem(
            messageObjectImplements, objectClass.charOffset, noLength);
        objectClass.interfaceBuilders = null;
      }
      if (objectClass.mixedInTypeBuilder != null) {
        objectClass.addProblem(
            messageObjectMixesIn, objectClass.charOffset, noLength);
        objectClass.mixedInTypeBuilder = null;
      }
    }
  }

  /// Returns a list of all class builders declared in this loader.  As the
  /// classes are sorted, any cycles in the hierarchy are reported as
  /// errors. Recover by breaking the cycles. This means that the rest of the
  /// pipeline (including backends) can assume that there are no hierarchy
  /// cycles.
  List<SourceClassBuilder> handleHierarchyCycles(ClassBuilder objectClass) {
    // Compute the initial work list of all classes declared in this loader.
    List<SourceClassBuilder> workList = <SourceClassBuilder>[];
    for (LibraryBuilder library in builders.values) {
      if (library.loader == this) {
        Iterator<Builder> members = library.iterator;
        while (members.moveNext()) {
          Builder member = members.current;
          if (member is SourceClassBuilder) {
            workList.add(member);
          }
        }
      }
    }

    Set<ClassBuilder> denyListedClasses = new Set<ClassBuilder>();
    for (int i = 0; i < denylistedCoreClasses.length; i++) {
      denyListedClasses.add(coreLibrary
          .lookupLocalMember(denylistedCoreClasses[i], required: true));
    }

    // Sort the classes topologically.
    Set<SourceClassBuilder> topologicallySortedClasses =
        new Set<SourceClassBuilder>();
    List<SourceClassBuilder> previousWorkList;
    do {
      previousWorkList = workList;
      workList = <SourceClassBuilder>[];
      for (int i = 0; i < previousWorkList.length; i++) {
        SourceClassBuilder cls = previousWorkList[i];
        Map<TypeDeclarationBuilder, TypeAliasBuilder> directSupertypeMap =
            cls.computeDirectSupertypes(objectClass);
        List<TypeDeclarationBuilder> directSupertypes =
            directSupertypeMap.keys.toList();
        bool allSupertypesProcessed = true;
        for (int i = 0; i < directSupertypes.length; i++) {
          Builder supertype = directSupertypes[i];
          if (supertype is SourceClassBuilder &&
              supertype.library.loader == this &&
              !topologicallySortedClasses.contains(supertype)) {
            allSupertypesProcessed = false;
            break;
          }
        }
        if (allSupertypesProcessed && cls.isPatch) {
          allSupertypesProcessed =
              topologicallySortedClasses.contains(cls.origin);
        }
        if (allSupertypesProcessed) {
          topologicallySortedClasses.add(cls);
          checkClassSupertypes(cls, directSupertypeMap, denyListedClasses);
        } else {
          workList.add(cls);
        }
      }
    } while (previousWorkList.length != workList.length);
    List<SourceClassBuilder> classes = topologicallySortedClasses.toList();
    List<SourceClassBuilder> classesWithCycles = previousWorkList;

    // Once the work list doesn't change in size, it's either empty, or
    // contains all classes with cycles.

    // Sort the classes to ensure consistent output.
    classesWithCycles.sort();
    for (int i = 0; i < classesWithCycles.length; i++) {
      SourceClassBuilder cls = classesWithCycles[i];
      target.breakCycle(cls);
      classes.add(cls);
      cls.addProblem(
          templateCyclicClassHierarchy.withArguments(cls.fullNameForErrors),
          cls.charOffset,
          noLength);
    }

    ticker.logMs("Checked class hierarchy");
    return classes;
  }

  void _checkConstructorsForMixin(
      SourceClassBuilder cls, ClassBuilder builder) {
    for (Builder constructor in builder.constructors.local.values) {
      if (constructor.isConstructor && !constructor.isSynthetic) {
        cls.addProblem(
            templateIllegalMixinDueToConstructors
                .withArguments(builder.fullNameForErrors),
            cls.charOffset,
            noLength,
            context: [
              templateIllegalMixinDueToConstructorsCause
                  .withArguments(builder.fullNameForErrors)
                  .withLocation(
                      constructor.fileUri, constructor.charOffset, noLength)
            ]);
      }
    }
  }

  void checkClassSupertypes(
      SourceClassBuilder cls,
      Map<TypeDeclarationBuilder, TypeAliasBuilder> directSupertypeMap,
      Set<ClassBuilder> denyListedClasses) {
    // Check that the direct supertypes aren't deny-listed or enums.
    List<TypeDeclarationBuilder> directSupertypes =
        directSupertypeMap.keys.toList();
    for (int i = 0; i < directSupertypes.length; i++) {
      TypeDeclarationBuilder supertype = directSupertypes[i];
      if (supertype is EnumBuilder) {
        cls.addProblem(templateExtendingEnum.withArguments(supertype.name),
            cls.charOffset, noLength);
      } else if (!cls.library.mayImplementRestrictedTypes &&
          denyListedClasses.contains(supertype)) {
        TypeAliasBuilder aliasBuilder = directSupertypeMap[supertype];
        if (aliasBuilder != null) {
          cls.addProblem(
              templateExtendingRestricted
                  .withArguments(supertype.fullNameForErrors),
              cls.charOffset,
              noLength,
              context: [
                messageTypedefCause.withLocation(
                    aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
              ]);
        } else {
          cls.addProblem(
              templateExtendingRestricted
                  .withArguments(supertype.fullNameForErrors),
              cls.charOffset,
              noLength);
        }
      }
    }

    // Check that the mixed-in type can be used as a mixin.
    final TypeBuilder mixedInTypeBuilder = cls.mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      bool isClassBuilder = false;
      if (mixedInTypeBuilder is NamedTypeBuilder) {
        TypeDeclarationBuilder builder = mixedInTypeBuilder.declaration;
        if (builder is TypeAliasBuilder) {
          TypeAliasBuilder aliasBuilder = builder;
          NamedTypeBuilder namedBuilder = mixedInTypeBuilder;
          builder = aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
          if (builder is! ClassBuilder) {
            cls.addProblem(
                templateIllegalMixin.withArguments(builder.fullNameForErrors),
                cls.charOffset,
                noLength,
                context: [
                  messageTypedefCause.withLocation(
                      aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
                ]);
            return;
          } else if (!cls.library.mayImplementRestrictedTypes &&
              denyListedClasses.contains(builder)) {
            cls.addProblem(
                templateExtendingRestricted
                    .withArguments(mixedInTypeBuilder.fullNameForErrors),
                cls.charOffset,
                noLength,
                context: [
                  messageTypedefUnaliasedTypeCause.withLocation(
                      builder.fileUri, builder.charOffset, noLength),
                ]);
            return;
          }
        }
        if (builder is ClassBuilder) {
          isClassBuilder = true;
          _checkConstructorsForMixin(cls, builder);
        }
      }
      if (!isClassBuilder) {
        // TODO(ahe): Either we need to check this for superclass and
        // interfaces, or this shouldn't be necessary (or handled elsewhere).
        cls.addProblem(
            templateIllegalMixin
                .withArguments(mixedInTypeBuilder.fullNameForErrors),
            cls.charOffset,
            noLength);
      }
    }
  }

  List<SourceClassBuilder> checkSemantics(ClassBuilder objectClass) {
    checkObjectClassHierarchy(objectClass);
    List<SourceClassBuilder> classes = handleHierarchyCycles(objectClass);

    // Check imports and exports for duplicate names.
    // This is rather silly, e.g. it makes importing 'foo' and exporting another
    // 'foo' ok.
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder && library.loader == this) {
        // Check exports.
        if (library.exports.isNotEmpty) {
          Map<String, List<Export>> nameToExports;
          bool errorExports = false;
          for (Export export in library.exports) {
            String name = export.exported?.name ?? '';
            if (name != '') {
              nameToExports ??= new Map<String, List<Export>>();
              List<Export> exports = nameToExports[name] ??= <Export>[];
              exports.add(export);
              if (exports[0].exported != export.exported) errorExports = true;
            }
          }
          if (errorExports) {
            for (String name in nameToExports.keys) {
              List<Export> exports = nameToExports[name];
              if (exports.length < 2) continue;
              List<LocatedMessage> context = <LocatedMessage>[];
              for (Export export in exports.skip(1)) {
                context.add(templateDuplicatedLibraryExportContext
                    .withArguments(name)
                    .withLocation(uri, export.charOffset, noLength));
              }
              library.addProblem(
                  templateDuplicatedLibraryExport.withArguments(name),
                  exports[0].charOffset,
                  noLength,
                  uri,
                  context: context);
            }
          }
        }

        // Check imports.
        if (library.imports.isNotEmpty) {
          Map<String, List<Import>> nameToImports;
          bool errorImports;
          for (Import import in library.imports) {
            String name = import.imported?.name ?? '';
            if (name != '') {
              nameToImports ??= new Map<String, List<Import>>();
              List<Import> imports = nameToImports[name] ??= <Import>[];
              imports.add(import);
              if (imports[0].imported != import.imported) errorImports = true;
            }
          }
          if (errorImports != null) {
            for (String name in nameToImports.keys) {
              List<Import> imports = nameToImports[name];
              if (imports.length < 2) continue;
              List<LocatedMessage> context = <LocatedMessage>[];
              for (Import import in imports.skip(1)) {
                context.add(templateDuplicatedLibraryImportContext
                    .withArguments(name)
                    .withLocation(uri, import.charOffset, noLength));
              }
              library.addProblem(
                  templateDuplicatedLibraryImport.withArguments(name),
                  imports[0].charOffset,
                  noLength,
                  uri,
                  context: context);
            }
          }
        }
      }
    });
    ticker.logMs("Checked imports and exports for duplicate names");
    return classes;
  }

  void buildComponent() {
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        Library target = sourceLibrary.build(coreLibrary);
        if (!library.isPatch) {
          if (sourceLibrary.referencesFrom != null) {
            referenceFromIndex ??= new ReferenceFromIndex();
            referenceFromIndex.addIndexedLibrary(
                target, sourceLibrary.referencesFromIndexed);
          }
          libraries.add(target);
        }
      }
    });
    ticker.logMs("Built component");
  }

  Component computeFullComponent() {
    Set<Library> libraries = new Set<Library>();
    List<Library> workList = <Library>[];
    builders.forEach((Uri uri, LibraryBuilder libraryBuilder) {
      if (!libraryBuilder.isPatch &&
          (libraryBuilder.loader == this ||
              libraryBuilder.importUri.scheme == "dart" ||
              libraryBuilder == this.first)) {
        if (libraries.add(libraryBuilder.library)) {
          workList.add(libraryBuilder.library);
        }
      }
    });
    while (workList.isNotEmpty) {
      Library library = workList.removeLast();
      for (LibraryDependency dependency in library.dependencies) {
        if (libraries.add(dependency.targetLibrary)) {
          workList.add(dependency.targetLibrary);
        }
      }
    }
    return new Component()..libraries.addAll(libraries);
  }

  void computeHierarchy() {
    List<AmbiguousTypesRecord> ambiguousTypesRecords = [];
    HandleAmbiguousSupertypes onAmbiguousSupertypes =
        (Class cls, Supertype a, Supertype b) {
      if (ambiguousTypesRecords != null) {
        ambiguousTypesRecords.add(new AmbiguousTypesRecord(cls, a, b));
      }
    };
    if (hierarchy == null) {
      hierarchy = new ClassHierarchy(computeFullComponent(), coreTypes,
          onAmbiguousSupertypes: onAmbiguousSupertypes);
    } else {
      hierarchy.onAmbiguousSupertypes = onAmbiguousSupertypes;
      Component component = computeFullComponent();
      hierarchy.coreTypes = coreTypes;
      hierarchy.applyTreeChanges(const [], component.libraries, const [],
          reissueAmbiguousSupertypesFor: component);
    }
    for (AmbiguousTypesRecord record in ambiguousTypesRecords) {
      handleAmbiguousSupertypes(record.cls, record.a, record.b);
    }
    ambiguousTypesRecords = null;
    ticker.logMs("Computed class hierarchy");
  }

  void handleAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {
    addProblem(
        templateAmbiguousSupertypes.withArguments(cls.name, a.asInterfaceType,
            b.asInterfaceType, cls.enclosingLibrary.isNonNullableByDefault),
        cls.fileOffset,
        noLength,
        cls.fileUri);
  }

  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}

  void computeCoreTypes(Component component) {
    assert(_coreTypes == null, "CoreTypes has already been computed");
    _coreTypes = new CoreTypes(component);

    // These types are used on the left-hand side of the is-subtype-of relation
    // to check if the return types of functions with async, sync*, and async*
    // bodies are correct.  It's valid to use the non-nullable types on the
    // left-hand side in both opt-in and opt-out code.
    futureOfBottom = new InterfaceType(coreTypes.futureClass,
        Nullability.nonNullable, <DartType>[const BottomType()]);
    iterableOfBottom = new InterfaceType(coreTypes.iterableClass,
        Nullability.nonNullable, <DartType>[const BottomType()]);
    streamOfBottom = new InterfaceType(coreTypes.streamClass,
        Nullability.nonNullable, <DartType>[const BottomType()]);

    ticker.logMs("Computed core types");
  }

  void checkSupertypes(List<SourceClassBuilder> sourceClasses) {
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        builder.checkSupertypes(coreTypes);
      }
    }
    ticker.logMs("Checked supertypes");
  }

  void checkTypes() {
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        if (library.loader == this) {
          library
              .checkTypesInOutline(typeInferenceEngine.typeSchemaEnvironment);
        }
      }
    });
    ticker.logMs("Checked type arguments of supers against the bounds");
  }

  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    List<DelayedOverrideCheck> overrideChecks =
        builderHierarchy.takeDelayedOverrideChecks();
    for (int i = 0; i < overrideChecks.length; i++) {
      overrideChecks[i].check(builderHierarchy);
    }
    ticker.logMs("Checked ${overrideChecks.length} overrides");

    typeInferenceEngine?.finishTopLevelInitializingFormals();
    ticker.logMs("Finished initializing formals");
  }

  void checkAbstractMembers(List<SourceClassBuilder> sourceClasses) {
    List<ClassMember> delayedMemberChecks =
        builderHierarchy.takeDelayedMemberChecks();
    Set<Class> changedClasses = new Set<Class>();
    for (int i = 0; i < delayedMemberChecks.length; i++) {
      delayedMemberChecks[i].getMember(builderHierarchy);
      changedClasses.add(delayedMemberChecks[i].classBuilder.cls);
    }
    ticker.logMs(
        "Computed ${delayedMemberChecks.length} combined member signatures");

    hierarchy.applyMemberChanges(changedClasses, findDescendants: false);
    ticker
        .logMs("Updated ${changedClasses.length} classes in kernel hierarchy");
  }

  void checkRedirectingFactories(List<SourceClassBuilder> sourceClasses) {
    // TODO(ahe): Move this to [ClassHierarchyBuilder].
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        builder.checkRedirectingFactories(
            typeInferenceEngine.typeSchemaEnvironment);
      }
    }
    ticker.logMs("Checked redirecting factories");
  }

  void addNoSuchMethodForwarders(List<SourceClassBuilder> sourceClasses) {
    // TODO(ahe): Move this to [ClassHierarchyBuilder].
    if (!target.backendTarget.enableNoSuchMethodForwarders) return;

    List<Class> changedClasses = new List<Class>();
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        if (builder.addNoSuchMethodForwarders(target, hierarchy)) {
          changedClasses.add(builder.cls);
        }
      }
    }
    hierarchy.applyMemberChanges(changedClasses, findDescendants: true);
    ticker.logMs("Added noSuchMethod forwarders");
  }

  void checkMixins(List<SourceClassBuilder> sourceClasses) {
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        Class mixedInClass = builder.cls.mixedInClass;
        if (mixedInClass != null && mixedInClass.isMixinDeclaration) {
          builder.checkMixinApplication(hierarchy, coreTypes);
        }
      }
    }
    ticker.logMs("Checked mixin declaration applications");
  }

  void buildOutlineExpressions(CoreTypes coreTypes) {
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        library.buildOutlineExpressions();
        Iterator<Builder> iterator = library.iterator;
        while (iterator.moveNext()) {
          Builder declaration = iterator.current;
          if (declaration is ClassBuilder) {
            declaration.buildOutlineExpressions(library, coreTypes);
          } else if (declaration is ExtensionBuilder) {
            declaration.buildOutlineExpressions(library, coreTypes);
          } else if (declaration is MemberBuilder) {
            declaration.buildOutlineExpressions(library, coreTypes);
          }
        }
      }
    });
    ticker.logMs("Build outline expressions");
  }

  void buildClassHierarchy(
      List<SourceClassBuilder> sourceClasses, ClassBuilder objectClass) {
    builderHierarchy = ClassHierarchyBuilder.build(
        objectClass, sourceClasses, this, coreTypes);
    typeInferenceEngine?.hierarchyBuilder = builderHierarchy;
    ticker.logMs("Built class hierarchy");
  }

  void createTypeInferenceEngine() {
    typeInferenceEngine = new TypeInferenceEngineImpl(instrumentation);
  }

  void performTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    /// The first phase of top level initializer inference, which consists of
    /// creating kernel objects for all fields and top level variables that
    /// might be subject to type inference, and records dependencies between
    /// them.
    typeInferenceEngine.prepareTopLevel(coreTypes, hierarchy);
    builderHierarchy.computeTypes();

    List<FieldBuilder> allImplicitlyTypedFields = <FieldBuilder>[];
    for (LibraryBuilder library in builders.values) {
      if (library.loader == this) {
        List<FieldBuilder> implicitlyTypedFields =
            library.takeImplicitlyTypedFields();
        if (implicitlyTypedFields != null) {
          allImplicitlyTypedFields.addAll(implicitlyTypedFields);
        }
      }
    }

    for (int i = 0; i < allImplicitlyTypedFields.length; i++) {
      // TODO(ahe): This can cause a crash for parts that failed to get
      // included, see for example,
      // tests/standalone_2/io/http_cookie_date_test.dart.
      allImplicitlyTypedFields[i].inferType();
    }

    typeInferenceEngine.isTypeInferencePrepared = true;

    // Since finalization of covariance may have added forwarding stubs, we need
    // to recompute the class hierarchy so that method compilation will properly
    // target those forwarding stubs.
    hierarchy.onAmbiguousSupertypes = ignoreAmbiguousSupertypes;
    ticker.logMs("Performed top level inference");
  }

  void transformPostInference(TreeNode node, bool transformSetLiterals,
      bool transformCollections, Library clientLibrary) {
    if (transformCollections) {
      collectionTransformer ??= new CollectionTransformer(this);
      collectionTransformer.enterLibrary(clientLibrary);
      node.accept(collectionTransformer);
      collectionTransformer.exitLibrary();
    }
    if (transformSetLiterals) {
      setLiteralTransformer ??= new SetLiteralTransformer(this);
      setLiteralTransformer.enterLibrary(clientLibrary);
      node.accept(setLiteralTransformer);
      setLiteralTransformer.exitLibrary();
    }
  }

  void transformListPostInference(
      List<TreeNode> list,
      bool transformSetLiterals,
      bool transformCollections,
      Library clientLibrary) {
    if (transformCollections) {
      CollectionTransformer transformer =
          collectionTransformer ??= new CollectionTransformer(this);
      transformer.enterLibrary(clientLibrary);
      for (int i = 0; i < list.length; ++i) {
        list[i] = list[i].accept(transformer);
      }
      transformer.exitLibrary();
    }
    if (transformSetLiterals) {
      SetLiteralTransformer transformer =
          setLiteralTransformer ??= new SetLiteralTransformer(this);
      transformer.enterLibrary(clientLibrary);
      for (int i = 0; i < list.length; ++i) {
        list[i] = list[i].accept(transformer);
      }
      transformer.exitLibrary();
    }
  }

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

  void releaseAncillaryResources() {
    hierarchy = null;
    builderHierarchy = null;
    typeInferenceEngine = null;
    builders?.clear();
    libraries?.clear();
    first = null;
    sourceBytes?.clear();
    target?.releaseAncillaryResources();
    _coreTypes = null;
    instrumentation = null;
    collectionTransformer = null;
    setLiteralTransformer = null;
  }

  @override
  ClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    Library kernelLibrary = cls.enclosingLibrary;
    LibraryBuilder library = builders[kernelLibrary.importUri];
    if (library == null) {
      return target.dillTarget.loader.computeClassBuilderFromTargetClass(cls);
    }
    return library.lookupLocalMember(cls.name, required: true);
  }

  @override
  TypeBuilder computeTypeBuilder(DartType type) {
    return type.accept(new TypeBuilderComputer(this));
  }

  BodyBuilder createBodyBuilderForField(
      FieldBuilder field, TypeInferrer typeInferrer) {
    return new BodyBuilder.forField(field, typeInferrer);
  }
}

/// A minimal implementation of dart:core that is sufficient to create an
/// instance of [CoreTypes] and compile a program.
const String defaultDartCoreSource = """
import 'dart:_internal';
import 'dart:async';

export 'dart:async' show Future, Stream;

print(object) {}

class Iterator<E> {
  bool moveNext() => null;
  E get current => null;
}

class Iterable<E> {
  Iterator<E> get iterator => null;
}

class List<E> extends Iterable {
  factory List() => null;
  factory List.unmodifiable(elements) => null;
  factory List.filled(int length, E fill, {bool growable = false}) => null;
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) => null;
  void add(E) {}
  E operator [](int index) => null;
}

class _GrowableList<E> {
  factory _GrowableList() => null;
  factory _GrowableList.filled() => null;
  factory _GrowableList.generate(int length, E generator(int index)) => null;
}

class _List<E> {
  factory _List() => null;
  factory _List.filled() => null;
  factory _List.generate(int length, E generator(int index)) => null;
}

class MapEntry<K, V> {
  K key;
  V value;
}

abstract class Map<K, V> extends Iterable {
  factory Map.unmodifiable(other) => null;
  Iterable<MapEntry<K, V>> get entries;
  void operator []=(K key, V value) {}
}

abstract class _ImmutableMap<K, V> implements Map<K, V> {
  dynamic _kvPairs;
}

abstract class pragma {
  String name;
  Object options;
}

class AbstractClassInstantiationError {}

class NoSuchMethodError {
  NoSuchMethodError.withInvocation(receiver, invocation);
}

class StackTrace {}

class Null {}

class Object {
  const Object();
  noSuchMethod(invocation) => null;
  bool operator==(dynamic) {}
}

class String {}

class Symbol {}

class Set<E> {
  factory Set() = Set<E>._fake;
  external factory Set._fake();
  void add(E) {}
}

class Type {}

class _InvocationMirror {
  _InvocationMirror._withType(_memberName, _type, _typeArguments,
      _positionalArguments, _namedArguments);
}

class bool {}

class double extends num {}

class int extends num {}

class num {}

class _SyncIterable {}

class _SyncIterator {
  var _current;
  var _yieldEachIterable;
}

class Function {}
""";

/// A minimal implementation of dart:async that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartAsyncSource = """
_asyncErrorWrapperHelper(continuation) {}

void _asyncStarListenHelper(var object, var awaiter) {}

void _asyncStarMoveNextHelper(var stream) {}

_asyncStackTraceHelper(async_op) {}

_asyncThenWrapperHelper(continuation) {}

_awaitHelper(object, thenCallback, errorCallback, awaiter) {}

_completeOnAsyncReturn(completer, value) {}

class _AsyncStarStreamController {
  add(event) {}

  addError(error, stackTrace) {}

  addStream(stream) {}

  close() {}

  get stream => null;
}

abstract class Completer {
  factory Completer.sync() => null;

  get future;

  complete([value]);

  completeError(error, [stackTrace]);
}

class Future<T> {
  factory Future.microtask(computation) => null;
}

class FutureOr {
}

class _AsyncAwaitCompleter implements Completer {
  get future => null;

  complete([value]) {}

  completeError(error, [stackTrace]) {}

  void start(void Function() f) {}
}

class Stream {}

class _StreamIterator {
  get current => null;

  moveNext() {}

  cancel() {}
}
""";

/// A minimal implementation of dart:collection that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartCollectionSource = """
class _UnmodifiableSet {
  final Map _map;
  const _UnmodifiableSet(this._map);
}
""";

/// A minimal implementation of dart:_internal that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartInternalSource = """
class Symbol {
  const Symbol(String name);
}

T unsafeCast<T>(Object v) {}
""";

/// A minimal implementation of dart:typed_data that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartTypedDataSource = """
class Endian {
  static const Endian little = null;
  static const Endian big = null;
  static final Endian host = null;
}
""";

class AmbiguousTypesRecord {
  final Class cls;
  final Supertype a;
  final Supertype b;

  const AmbiguousTypesRecord(this.cls, this.a, this.b);
}

class SourceLoaderDataForTesting {
  final Map<TreeNode, TreeNode> _aliasMap = {};

  /// Registers that [original] has been replaced by [alias] in the generated
  /// AST.
  void registerAlias(TreeNode original, TreeNode alias) {
    _aliasMap[alias] = original;
  }

  /// Returns the original node for [alias] or [alias] if it was not registered
  /// as an alias.
  TreeNode toOriginal(TreeNode alias) {
    return _aliasMap[alias] ?? alias;
  }
}
