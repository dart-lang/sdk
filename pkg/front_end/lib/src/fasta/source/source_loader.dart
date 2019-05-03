// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_loader;

import 'dart:async' show Future;

import 'dart:convert' show utf8;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart'
    show
        Arguments,
        BottomType,
        Class,
        Component,
        DartType,
        Expression,
        FunctionNode,
        InterfaceType,
        Library,
        LibraryDependency,
        ProcedureKind,
        Supertype,
        TreeNode;

import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, HandleAmbiguousSupertypes;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../../api_prototype/file_system.dart';

import '../../base/instrumentation.dart' show Instrumentation;

import '../blacklisted_classes.dart' show blacklistedCoreClasses;

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
        templateUntranslatableUri;

import '../kernel/kernel_shadow_ast.dart'
    show ShadowClass, ShadowTypeInferenceEngine;

import '../kernel/kernel_builder.dart'
    show
        ClassBuilder,
        ClassHierarchyBuilder,
        Declaration,
        EnumBuilder,
        KernelClassBuilder,
        KernelFieldBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/transform_collections.dart' show CollectionTransformer;

import '../kernel/transform_set_literals.dart' show SetLiteralTransformer;

import '../kernel/type_builder_computer.dart' show TypeBuilderComputer;

import '../loader.dart' show Loader, untranslatableUriScheme;

import '../parser/class_member_parser.dart' show ClassMemberParser;

import '../parser.dart' show Parser, lengthForToken, offsetForToken;

import '../problems.dart' show internalProblem;

import '../scanner.dart' show ErrorToken, ScannerResult, Token, scan;

import '../type_inference/interface_resolver.dart' show InterfaceResolver;

import 'diet_listener.dart' show DietListener;

import 'diet_parser.dart' show DietParser;

import 'outline_builder.dart' show OutlineBuilder;

import 'source_class_builder.dart' show SourceClassBuilder;

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceLoader extends Loader<Library> {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final Map<Uri, List<int>> sourceBytes = <Uri, List<int>>{};

  // Used when building directly to kernel.
  ClassHierarchy hierarchy;
  CoreTypes coreTypes;
  // Used when checking whether a return type of an async function is valid.
  DartType futureOfBottom;
  DartType iterableOfBottom;
  DartType streamOfBottom;

  ShadowTypeInferenceEngine typeInferenceEngine;

  InterfaceResolver interfaceResolver;

  Instrumentation instrumentation;

  CollectionTransformer collectionTransformer;

  SetLiteralTransformer setLiteralTransformer;

  SourceLoader(this.fileSystem, this.includeComments, KernelTarget target)
      : super(target);

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
        Message message = templateUntranslatableUri.withArguments(library.uri);
        library.addProblemAtAccessors(message);
        bytes = synthesizeSourceForMissingFile(library.uri, null);
      } else if (!uri.hasScheme) {
        return internalProblem(
            templateInternalProblemUriMissingScheme.withArguments(uri),
            -1,
            library.uri);
      } else if (uri.scheme == SourceLibraryBuilder.MALFORMED_URI_SCHEME) {
        bytes = synthesizeSourceForMissingFile(library.uri, null);
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
        rawBytes = synthesizeSourceForMissingFile(library.uri, message);
      }
      Uint8List zeroTerminatedBytes = new Uint8List(rawBytes.length + 1);
      zeroTerminatedBytes.setRange(0, rawBytes.length, rawBytes);
      bytes = zeroTerminatedBytes;
      sourceBytes[uri] = bytes;
      byteCount += rawBytes.length;
    }

    ScannerResult result = scan(bytes, includeComments: includeComments);
    Token token = result.tokens;
    if (!suppressLexicalErrors) {
      List<int> source = getSource(bytes);
      Uri importUri = library.uri;
      if (library.isPatch) {
        // For patch files we create a "fake" import uri.
        // We cannot use the import uri from the patched libarary because
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

      default:
        return utf8.encode(message == null ? "" : "/* ${message.message} */");
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
        Token tokens = await tokenize(part);
        if (tokens != null) {
          listener.uri = part.fileUri;
          listener.partDirectiveIndex = 0;
          parser.parseUnit(tokens);
        }
      }
    }
  }

  Future<Expression> buildExpression(
      SourceLibraryBuilder library,
      String enclosingClass,
      bool isInstanceMember,
      FunctionNode parameters) async {
    Token token = await tokenize(library, suppressLexicalErrors: false);
    if (token == null) return null;
    DietListener dietListener = createDietListener(library);

    Declaration parent = library;
    if (enclosingClass != null) {
      Declaration cls =
          dietListener.memberScope.lookup(enclosingClass, -1, null);
      if (cls is ClassBuilder) {
        parent = cls;
        dietListener
          ..currentClass = cls
          ..memberScope = cls.scope.copyWithParent(
              dietListener.memberScope.withTypeVariables(cls.typeVariables),
              "debugExpression in $enclosingClass");
      }
    }
    KernelProcedureBuilder builder = new KernelProcedureBuilder(null, 0, null,
        "debugExpr", null, null, ProcedureKind.Method, library, 0, 0, -1, -1)
      ..parent = parent;
    BodyBuilder listener = dietListener.createListener(
        builder, dietListener.memberScope, isInstanceMember);

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
          exported.exportScope.forEach((String name, Declaration member) {
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
    // TODO(sigmund): should be `covarint SourceLibraryBuilder`.
    builders.forEach((Uri uri, dynamic l) {
      SourceLibraryBuilder library = l;
      Set<Declaration> members = new Set<Declaration>();
      Iterator<Declaration> iterator = library.iterator;
      while (iterator.moveNext()) {
        members.add(iterator.current);
      }
      List<String> exports = <String>[];
      library.exportScope.forEach((String name, Declaration member) {
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

  void finalizeInitializingFormals() {
    int formalCount = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        formalCount += sourceLibrary.finalizeInitializingFormals();
      }
    });
    ticker.logMs("Finalized $formalCount initializing formals");
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

  void computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder bottomType,
      ClassBuilder objectClass) {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count +=
            library.computeDefaultTypes(dynamicType, bottomType, objectClass);
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
      if (objectClass.supertype != null) {
        objectClass.supertype = null;
        objectClass.addProblem(
            messageObjectExtends, objectClass.charOffset, noLength);
      }
      if (objectClass.interfaces != null) {
        objectClass.addProblem(
            messageObjectImplements, objectClass.charOffset, noLength);
        objectClass.interfaces = null;
      }
      if (objectClass.mixedInType != null) {
        objectClass.addProblem(
            messageObjectMixesIn, objectClass.charOffset, noLength);
        objectClass.mixedInType = null;
      }
    }
  }

  /// Returns a list of all class builders declared in this loader.  As the
  /// classes are sorted, any cycles in the hiearchy are reported as
  /// errors. Recover by breaking the cycles. This means that the rest of the
  /// pipeline (including backends) can assume that there are no hierarchy
  /// cycles.
  List<SourceClassBuilder> handleHierarchyCycles(ClassBuilder objectClass) {
    // Compute the initial work list of all classes declared in this loader.
    List<SourceClassBuilder> workList = <SourceClassBuilder>[];
    for (LibraryBuilder library in builders.values) {
      if (library.loader == this) {
        Iterator<Declaration> members = library.iterator;
        while (members.moveNext()) {
          Declaration member = members.current;
          if (member is SourceClassBuilder) {
            workList.add(member);
          }
        }
      }
    }

    Set<ClassBuilder> blackListedClasses = new Set<ClassBuilder>();
    for (int i = 0; i < blacklistedCoreClasses.length; i++) {
      blackListedClasses.add(coreLibrary[blacklistedCoreClasses[i]]);
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
        List<Declaration> directSupertypes =
            cls.computeDirectSupertypes(objectClass);
        bool allSupertypesProcessed = true;
        for (int i = 0; i < directSupertypes.length; i++) {
          Declaration supertype = directSupertypes[i];
          if (supertype is SourceClassBuilder &&
              supertype.library.loader == this &&
              !topologicallySortedClasses.contains(supertype)) {
            allSupertypesProcessed = false;
            break;
          }
        }
        if (allSupertypesProcessed) {
          topologicallySortedClasses.add(cls);
          checkClassSupertypes(cls, directSupertypes, blackListedClasses);
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

  void checkClassSupertypes(
      SourceClassBuilder cls,
      List<Declaration> directSupertypes,
      Set<ClassBuilder> blackListedClasses) {
    // Check that the direct supertypes aren't black-listed or enums.
    for (int i = 0; i < directSupertypes.length; i++) {
      Declaration supertype = directSupertypes[i];
      if (supertype is EnumBuilder) {
        cls.addProblem(templateExtendingEnum.withArguments(supertype.name),
            cls.charOffset, noLength);
      } else if (!cls.library.mayImplementRestrictedTypes &&
          blackListedClasses.contains(supertype)) {
        cls.addProblem(
            templateExtendingRestricted
                .withArguments(supertype.fullNameForErrors),
            cls.charOffset,
            noLength);
      }
    }

    // Check that the mixed-in type can be used as a mixin.
    final TypeBuilder mixedInType = cls.mixedInType;
    if (mixedInType != null) {
      bool isClassBuilder = false;
      if (mixedInType is NamedTypeBuilder) {
        var builder = mixedInType.declaration;
        if (builder is ClassBuilder) {
          isClassBuilder = true;
          for (Declaration constructory in builder.constructors.local.values) {
            if (constructory.isConstructor && !constructory.isSynthetic) {
              cls.addProblem(
                  templateIllegalMixinDueToConstructors
                      .withArguments(builder.fullNameForErrors),
                  cls.charOffset,
                  noLength,
                  context: [
                    templateIllegalMixinDueToConstructorsCause
                        .withArguments(builder.fullNameForErrors)
                        .withLocation(constructory.fileUri,
                            constructory.charOffset, noLength)
                  ]);
            }
          }
        }
      }
      if (!isClassBuilder) {
        // TODO(ahe): Either we need to check this for superclass and
        // interfaces, or this shouldn't be necessary (or handled elsewhere).
        cls.addProblem(
            templateIllegalMixin.withArguments(mixedInType.fullNameForErrors),
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
          libraries.add(target);
        }
      }
    });
    ticker.logMs("Built component");
  }

  Component computeFullComponent() {
    Set<Library> libraries = new Set<Library>();
    List<Library> workList = <Library>[];
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (!library.isPatch &&
          (library.loader == this ||
              library.uri.scheme == "dart" ||
              library == this.first)) {
        if (libraries.add(library.target)) {
          workList.add(library.target);
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
    List<List> ambiguousTypesRecords = [];
    HandleAmbiguousSupertypes onAmbiguousSupertypes =
        (Class cls, Supertype a, Supertype b) {
      if (ambiguousTypesRecords != null) {
        ambiguousTypesRecords.add([cls, a, b]);
      }
    };
    if (hierarchy == null) {
      hierarchy = new ClassHierarchy(computeFullComponent(),
          onAmbiguousSupertypes: onAmbiguousSupertypes);
    } else {
      hierarchy.onAmbiguousSupertypes = onAmbiguousSupertypes;
      Component component = computeFullComponent();
      hierarchy.applyTreeChanges(const [], component.libraries,
          reissueAmbiguousSupertypesFor: component);
    }
    for (List record in ambiguousTypesRecords) {
      handleAmbiguousSupertypes(record[0], record[1], record[2]);
    }
    ambiguousTypesRecords = null;
    ticker.logMs("Computed class hierarchy");
  }

  void handleAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {
    addProblem(
        templateAmbiguousSupertypes.withArguments(
            cls.name, a.asInterfaceType, b.asInterfaceType),
        cls.fileOffset,
        noLength,
        cls.fileUri);
  }

  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}

  void computeCoreTypes(Component component) {
    coreTypes = new CoreTypes(component);

    futureOfBottom = new InterfaceType(
        coreTypes.futureClass, <DartType>[const BottomType()]);
    iterableOfBottom = new InterfaceType(
        coreTypes.iterableClass, <DartType>[const BottomType()]);
    streamOfBottom = new InterfaceType(
        coreTypes.streamClass, <DartType>[const BottomType()]);

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

  void checkBounds() {
    if (target.legacyMode) return;

    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library is SourceLibraryBuilder) {
        if (library.loader == this) {
          library
              .checkBoundsInOutline(typeInferenceEngine.typeSchemaEnvironment);
        }
      }
    });
    ticker.logMs("Checked type arguments of supers against the bounds");
  }

  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    assert(hierarchy != null);
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        builder.checkOverrides(
            hierarchy, typeInferenceEngine?.typeSchemaEnvironment);
      }
    }
    ticker.logMs("Checked overrides");
  }

  void checkAbstractMembers(List<SourceClassBuilder> sourceClasses) {
    // TODO(ahe): Move this to [ClassHierarchyBuilder].
    if (target.legacyMode) return;
    assert(hierarchy != null);
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        builder.checkAbstractMembers(
            coreTypes, hierarchy, typeInferenceEngine.typeSchemaEnvironment);
      }
    }
    ticker.logMs("Checked abstract members");
  }

  void checkRedirectingFactories(List<SourceClassBuilder> sourceClasses) {
    // TODO(ahe): Move this to [ClassHierarchyBuilder].
    if (target.legacyMode) return;
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
          changedClasses.add(builder.target);
        }
      }
    }
    hierarchy.applyMemberChanges(changedClasses, findDescendants: true);
    ticker.logMs("Added noSuchMethod forwarders");
  }

  void checkMixins(List<SourceClassBuilder> sourceClasses) {
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        if (builder.isMixinDeclaration) {
          builder.checkMixinDeclaration();
        }

        Class mixedInClass = builder.cls.mixedInClass;
        if (mixedInClass != null && mixedInClass.isMixinDeclaration) {
          builder.checkMixinApplication(hierarchy);
        }
      }
    }
    ticker.logMs("Checked mixin declaration applications");
  }

  ClassHierarchyBuilder buildClassHierarchy(
      List<SourceClassBuilder> sourceClasses, ClassBuilder objectClass) {
    ClassHierarchyBuilder hierarchy = ClassHierarchyBuilder.build(
        objectClass, sourceClasses, this, coreTypes);
    ticker.logMs("Built class hierarchy");
    return hierarchy;
  }

  void createTypeInferenceEngine() {
    if (target.legacyMode) return;
    typeInferenceEngine = new ShadowTypeInferenceEngine(instrumentation);
  }

  void performTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    if (target.legacyMode) return;

    /// The first phase of top level initializer inference, which consists of
    /// creating kernel objects for all fields and top level variables that
    /// might be subject to type inference, and records dependencies between
    /// them.
    typeInferenceEngine.prepareTopLevel(coreTypes, hierarchy);
    interfaceResolver = new InterfaceResolver(typeInferenceEngine,
        typeInferenceEngine.typeSchemaEnvironment, instrumentation);
    for (LibraryBuilder library in builders.values) {
      if (library.loader == this) {
        Iterator<Declaration> iterator = library.iterator;
        while (iterator.moveNext()) {
          Declaration member = iterator.current;
          if (member is KernelFieldBuilder) {
            member.prepareTopLevelInference();
          }
        }
      }
    }
    for (int i = 0; i < sourceClasses.length; i++) {
      sourceClasses[i].prepareTopLevelInference();
    }
    typeInferenceEngine.isTypeInferencePrepared = true;
    ticker.logMs("Prepared top level inference");

    /// The second phase of top level initializer inference, which is to visit
    /// fields and top level variables in topologically-sorted order and assign
    /// their types.
    typeInferenceEngine.finishTopLevelFields();
    List<Class> changedClasses = new List<Class>();
    for (var builder in sourceClasses) {
      if (builder.isPatch) continue;
      ShadowClass class_ = builder.target;
      int memberCount = class_.fields.length +
          class_.constructors.length +
          class_.procedures.length +
          class_.redirectingFactoryConstructors.length;
      class_.finalizeCovariance(interfaceResolver);
      ShadowClass.clearClassInferenceInfo(class_);
      int newMemberCount = class_.fields.length +
          class_.constructors.length +
          class_.procedures.length +
          class_.redirectingFactoryConstructors.length;
      if (newMemberCount != memberCount) {
        // The inference potentially adds new members (but doesn't otherwise
        // change the classes), so if the member count has changed we need to
        // update the class in the class hierarchy.
        changedClasses.add(class_);
      }
    }

    typeInferenceEngine.finishTopLevelInitializingFormals();
    interfaceResolver = null;
    // Since finalization of covariance may have added forwarding stubs, we need
    // to recompute the class hierarchy so that method compilation will properly
    // target those forwarding stubs.
    hierarchy.onAmbiguousSupertypes = ignoreAmbiguousSupertypes;
    hierarchy.applyMemberChanges(changedClasses, findDescendants: true);
    ticker.logMs("Performed top level inference");
  }

  void transformPostInference(
      TreeNode node, bool transformSetLiterals, bool transformCollections) {
    if (transformCollections) {
      node.accept(collectionTransformer ??= new CollectionTransformer(this));
    }
    if (transformSetLiterals) {
      node.accept(setLiteralTransformer ??= new SetLiteralTransformer(this,
          transformConst: !target.enableConstantUpdate2018));
    }
  }

  void transformListPostInference(List<TreeNode> list,
      bool transformSetLiterals, bool transformCollections) {
    if (transformSetLiterals) {
      SetLiteralTransformer transformer = setLiteralTransformer ??=
          new SetLiteralTransformer(this,
              transformConst: !target.enableConstantUpdate2018);
      for (int i = 0; i < list.length; ++i) {
        list[i] = list[i].accept(transformer);
      }
    }
    if (transformCollections) {
      CollectionTransformer transformer =
          collectionTransformer ??= new CollectionTransformer(this);
      for (int i = 0; i < list.length; ++i) {
        list[i] = list[i].accept(transformer);
      }
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
    typeInferenceEngine = null;
  }

  @override
  KernelClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    Library kernelLibrary = cls.enclosingLibrary;
    LibraryBuilder library = builders[kernelLibrary.importUri];
    if (library == null) {
      return target.dillTarget.loader.computeClassBuilderFromTargetClass(cls);
    }
    return library[cls.name];
  }

  @override
  KernelTypeBuilder computeTypeBuilder(DartType type) {
    return type.accept(new TypeBuilderComputer(this));
  }
}

/// A minimal implementation of dart:core that is sufficient to create an
/// instance of [CoreTypes] and compile a program.
const String defaultDartCoreSource = """
import 'dart:_internal';
import 'dart:async';

export 'dart:async' show Future, Stream;

print(object) {}

class Iterator {}

class Iterable {}

class List extends Iterable {
  factory List.unmodifiable(elements) => null;
}

class Map extends Iterable {
  factory Map.unmodifiable(other) => null;
}

class NoSuchMethodError {
  NoSuchMethodError.withInvocation(receiver, invocation);
}

class Null {}

class Object {
  noSuchMethod(invocation) => null;
}

class String {}

class Symbol {}

class Set {}

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

class Completer {
  factory Completer.sync() => null;

  get future;

  complete([value]);

  completeError(error, [stackTrace]);
}

class Future {
  factory Future.microtask(computation) => null;
}

class FutureOr {
}

class _AsyncAwaitCompleter implements Completer {
  get future => null;

  complete([value]) {}

  completeError(error, [stackTrace]) {}
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

/// A minimal implementation of dart:_internel that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartInternalSource = """
class Symbol {
  const Symbol(String name);
}
""";
