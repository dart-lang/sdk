// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_loader;

import 'dart:collection' show Queue;
import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/macros/executor.dart'
    show MacroExecutor;
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
import 'package:front_end/src/fasta/source/source_type_alias_builder.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, HandleAmbiguousSupertypes;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/util/graph.dart';
import 'package:package_config/package_config.dart' as package_config;

import '../../api_prototype/experimental_flags.dart';
import '../../api_prototype/file_system.dart';
import '../../base/common.dart';
import '../../base/instrumentation.dart' show Instrumentation;
import '../../base/nnbd_mode.dart';
import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/field_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder_graph.dart';
import '../crash.dart' show firstSourceUri;
import '../denylisted_classes.dart'
    show denylistedCoreClasses, denylistedTypedDataClasses;
import '../dill/dill_library_builder.dart';
import '../export.dart' show Export;
import '../fasta_codes.dart';
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/delayed.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart'
    show SynthesizedFunctionNode, TypeDependency;
import '../kernel/kernel_target.dart' show KernelTarget;
import '../kernel/macro.dart';
import '../kernel/macro_annotation_parser.dart';
import '../kernel/transform_collections.dart' show CollectionTransformer;
import '../kernel/transform_set_literals.dart' show SetLiteralTransformer;
import '../kernel/type_builder_computer.dart' show TypeBuilderComputer;
import '../loader.dart' show Loader, untranslatableUriScheme;
import '../problems.dart' show internalProblem;
import '../scope.dart';
import '../ticker.dart' show Ticker;
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_inferrer.dart';
import '../util/helpers.dart';
import 'diet_listener.dart' show DietListener;
import 'diet_parser.dart' show DietParser, useImplicitCreationExpressionInCfe;
import 'name_scheme.dart';
import 'outline_builder.dart' show OutlineBuilder;
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart'
    show
        ImplicitLanguageVersion,
        InvalidLanguageVersion,
        LanguageVersion,
        SourceLibraryBuilder;
import 'source_procedure_builder.dart';
import 'stack_listener_impl.dart' show offsetForToken;

class SourceLoader extends Loader {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final Map<Uri, List<int>> sourceBytes = <Uri, List<int>>{};

  ClassHierarchyBuilder? _hierarchyBuilder;

  ClassMembersBuilder? _membersBuilder;

  ReferenceFromIndex? referenceFromIndex;

  /// Used when building directly to kernel.
  ClassHierarchy? _hierarchy;
  CoreTypes? _coreTypes;
  TypeEnvironment? _typeEnvironment;

  /// For builders created with a reference, this maps from that reference to
  /// that builder. This is used for looking up source builders when finalizing
  /// exports in dill builders.
  Map<Reference, Builder> buildersCreatedWithReferences = {};

  /// Used when checking whether a return type of an async function is valid.
  ///
  /// The said return type is valid if it's a subtype of [futureOfBottom].
  DartType? _futureOfBottom;

  DartType get futureOfBottom => _futureOfBottom!;

  /// Used when checking whether a return type of a sync* function is valid.
  ///
  /// The said return type is valid if it's a subtype of [iterableOfBottom].
  DartType? _iterableOfBottom;

  DartType get iterableOfBottom => _iterableOfBottom!;

  /// Used when checking whether a return type of an async* function is valid.
  ///
  /// The said return type is valid if it's a subtype of [streamOfBottom].
  DartType? _streamOfBottom;

  DartType get streamOfBottom => _streamOfBottom!;

  TypeInferenceEngineImpl? _typeInferenceEngine;

  Instrumentation? instrumentation;

  CollectionTransformer? collectionTransformer;

  SetLiteralTransformer? setLiteralTransformer;

  final SourceLoaderDataForTesting? dataForTesting;

  final Map<Uri, LibraryBuilder> _builders = <Uri, LibraryBuilder>{};

  List<SourceLibraryBuilder>? _sourceLibraryBuilders;

  final Queue<LibraryBuilder> _unparsedLibraries = new Queue<LibraryBuilder>();

  final List<Library> libraries = <Library>[];

  @override
  final KernelTarget target;

  /// List of all handled compile-time errors seen so far by libraries loaded
  /// by this loader.
  ///
  /// A handled error is an error that has been added to the generated AST
  /// already, for example, as a throw expression.
  final List<LocatedMessage> handledErrors = <LocatedMessage>[];

  /// List of all unhandled compile-time errors seen so far by libraries loaded
  /// by this loader.
  ///
  /// An unhandled error is an error that hasn't been handled, see
  /// [handledErrors].
  final List<LocatedMessage> unhandledErrors = <LocatedMessage>[];

  /// List of all problems seen so far by libraries loaded by this loader that
  /// does not belong directly to a library.
  final List<FormattedMessage> allComponentProblems = <FormattedMessage>[];

  /// The text of the messages that have been reported.
  ///
  /// This is used filter messages so that we don't report the same error twice.
  final Set<String> seenMessages = new Set<String>();

  /// Set to `true` if one of the reported errors had severity `Severity.error`.
  ///
  /// This is used for [hasSeenError].
  bool _hasSeenError = false;

  /// Clears the [seenMessages] and [hasSeenError] state.
  void resetSeenMessages() {
    seenMessages.clear();
    _hasSeenError = false;
  }

  /// Returns `true` if a compile time error has been reported.
  bool get hasSeenError => _hasSeenError;

  LibraryBuilder? _coreLibrary;
  LibraryBuilder? typedDataLibrary;

  /// The first library that we've been asked to compile. When compiling a
  /// program (aka script), this is the library that should have a main method.
  Uri? _firstUri;

  LibraryBuilder? get first => _builders[_firstUri];

  Uri? get firstUri => _firstUri;

  void set firstUri(Uri? value) {
    _firstUri = value;
  }

  int byteCount = 0;

  Uri? currentUriForCrashReporting;

  ClassBuilder? _macroClassBuilder;

  SourceLoader(this.fileSystem, this.includeComments, this.target)
      : dataForTesting =
            retainDataForTesting ? new SourceLoaderDataForTesting() : null;

  bool containsLibraryBuilder(Uri importUri) =>
      _builders.containsKey(importUri);

  @override
  LibraryBuilder? lookupLibraryBuilder(Uri importUri) => _builders[importUri];

  /// The [LibraryBuilder]s for libraries built from source or loaded from dill.
  ///
  /// Before [resolveParts] have been called, this includes parts and patches.
  Iterable<LibraryBuilder> get libraryBuilders => _builders.values;

  /// The [SourceLibraryBuilder]s for the libraries built from source by this
  /// source loader.
  ///
  /// This is available after [resolveParts] have been called and doesn't
  /// include parts or patches. Orphaned parts _are_ included.
  List<SourceLibraryBuilder> get sourceLibraryBuilders {
    assert(
        _sourceLibraryBuilders != null,
        "Source library builder hasn't been computed yet. "
        "The source libraries are in SourceLoader.resolveParts.");
    return _sourceLibraryBuilders!;
  }

  void clearSourceLibraryBuilders() {
    assert(
        _sourceLibraryBuilders != null,
        "Source library builder hasn't been computed yet. "
        "The source libraries are in SourceLoader.resolveParts.");
    _sourceLibraryBuilders!.clear();
  }

  Iterable<Uri> get libraryImportUris => _builders.keys;

  void registerLibraryBuilder(LibraryBuilder libraryBuilder) {
    Uri uri = libraryBuilder.importUri;
    if (uri.isScheme("dart") && uri.path == "core") {
      _coreLibrary = libraryBuilder;
    }
    _builders[uri] = libraryBuilder;
  }

  LibraryBuilder? deregisterLibraryBuilder(Uri importUri) {
    return _builders.remove(importUri);
  }

  void clearLibraryBuilders() {
    _builders.clear();
  }

  @override
  LibraryBuilder get coreLibrary => _coreLibrary!;

  Ticker get ticker => target.ticker;

  /// Creates a [SourceLibraryBuilder] corresponding to [importUri], if one
  /// doesn't exist already.
  ///
  /// [fileUri] must not be null and is a URI that can be passed to FileSystem
  /// to locate the corresponding file.
  ///
  /// [origin] is non-null if the created library is a patch to [origin].
  ///
  /// [packageUri] is the base uri for the package which the library belongs to.
  /// For instance 'package:foo'.
  ///
  /// This is used to associate libraries in for instance the 'bin' and 'test'
  /// folders of a package source with the package uri of the 'lib' folder.
  ///
  /// If the [packageUri] is `null` the package association of this library is
  /// based on its [importUri].
  ///
  /// For libraries with a 'package:' [importUri], the package path must match
  /// the path in the [importUri]. For libraries with a 'dart:' [importUri] the
  /// [packageUri] must be `null`.
  ///
  /// [packageLanguageVersion] is the language version defined by the package
  /// which the library belongs to, or the current sdk version if the library
  /// doesn't belong to a package.
  SourceLibraryBuilder createLibraryBuilder(
      {required Uri importUri,
      required Uri fileUri,
      Uri? packageUri,
      required LanguageVersion packageLanguageVersion,
      SourceLibraryBuilder? origin,
      Library? referencesFrom,
      bool? referenceIsPartOwner}) {
    return new SourceLibraryBuilder(
        importUri: importUri,
        fileUri: fileUri,
        packageUri: packageUri,
        packageLanguageVersion: packageLanguageVersion,
        loader: this,
        origin: origin,
        referencesFrom: referencesFrom,
        referenceIsPartOwner: referenceIsPartOwner,
        isUnsupported: origin?.library.isUnsupported ??
            importUri.isScheme('dart') &&
                !target.uriTranslator.isLibrarySupported(importUri.path));
  }

  /// Return `"true"` if the [dottedName] is a 'dart.library.*' qualifier for a
  /// supported dart:* library, and `""` otherwise.
  ///
  /// This is used to determine conditional imports and `bool.fromEnvironment`
  /// constant values for "dart.library.[libraryName]" values.
  String getLibrarySupportValue(String dottedName) {
    if (!DartLibrarySupport.isDartLibraryQualifier(dottedName)) {
      return "";
    }
    String libraryName = DartLibrarySupport.getDartLibraryName(dottedName);
    Uri uri = new Uri(scheme: "dart", path: libraryName);
    LibraryBuilder? library = lookupLibraryBuilder(uri);
    // TODO(johnniwinther): Why is the dill target sometimes not loaded at this
    // point? And does it matter?
    library ??= target.dillTarget.loader.lookupLibraryBuilder(uri);
    return DartLibrarySupport.getDartLibrarySupportValue(libraryName,
        libraryExists: library != null,
        isSynthetic: library?.isSynthetic ?? true,
        isUnsupported: library?.isUnsupported ?? true,
        dartLibrarySupport: target.backendTarget.dartLibrarySupport);
  }

  SourceLibraryBuilder _createSourceLibraryBuilder(
      Uri uri,
      Uri? fileUri,
      SourceLibraryBuilder? origin,
      Library? referencesFrom,
      bool? referenceIsPartOwner) {
    if (fileUri != null &&
        (fileUri.isScheme("dart") ||
            fileUri.isScheme("package") ||
            fileUri.isScheme("dart-ext"))) {
      fileUri = null;
    }
    package_config.Package? packageForLanguageVersion;
    if (fileUri == null) {
      switch (uri.scheme) {
        case "package":
        case "dart":
          fileUri = target.translateUri(uri) ??
              new Uri(
                  scheme: untranslatableUriScheme,
                  path: Uri.encodeComponent("$uri"));
          if (uri.isScheme("package")) {
            packageForLanguageVersion = target.uriTranslator.getPackage(uri);
          } else {
            packageForLanguageVersion =
                target.uriTranslator.packages.packageOf(fileUri);
          }
          break;

        default:
          fileUri = uri;
          packageForLanguageVersion =
              target.uriTranslator.packages.packageOf(fileUri);
          break;
      }
    } else {
      packageForLanguageVersion =
          target.uriTranslator.packages.packageOf(fileUri);
    }
    LanguageVersion? packageLanguageVersion;
    Uri? packageUri;
    Message? packageLanguageVersionProblem;
    if (packageForLanguageVersion != null) {
      Uri importUri = origin?.importUri ?? uri;
      if (!importUri.isScheme('dart') &&
          !importUri.isScheme('package') &&
          // ignore: unnecessary_null_comparison
          packageForLanguageVersion.name != null) {
        packageUri =
            new Uri(scheme: 'package', path: packageForLanguageVersion.name);
      }
      if (packageForLanguageVersion.languageVersion != null) {
        if (packageForLanguageVersion.languageVersion
            is package_config.InvalidLanguageVersion) {
          packageLanguageVersionProblem =
              messageLanguageVersionInvalidInDotPackages;
          packageLanguageVersion = new InvalidLanguageVersion(
              fileUri, 0, noLength, target.currentSdkVersion, false);
        } else {
          Version version = new Version(
              packageForLanguageVersion.languageVersion!.major,
              packageForLanguageVersion.languageVersion!.minor);
          if (version > target.currentSdkVersion) {
            packageLanguageVersionProblem =
                templateLanguageVersionTooHigh.withArguments(
                    target.currentSdkVersion.major,
                    target.currentSdkVersion.minor);
            packageLanguageVersion = new InvalidLanguageVersion(
                fileUri, 0, noLength, target.currentSdkVersion, false);
          } else {
            packageLanguageVersion = new ImplicitLanguageVersion(version);
          }
        }
      }
    }
    packageLanguageVersion ??=
        new ImplicitLanguageVersion(target.currentSdkVersion);

    SourceLibraryBuilder libraryBuilder = createLibraryBuilder(
        importUri: uri,
        fileUri: fileUri,
        packageUri: packageUri,
        packageLanguageVersion: packageLanguageVersion,
        origin: origin,
        referencesFrom: referencesFrom,
        referenceIsPartOwner: referenceIsPartOwner);
    if (packageLanguageVersionProblem != null) {
      libraryBuilder.addPostponedProblem(
          packageLanguageVersionProblem, 0, noLength, libraryBuilder.fileUri);
    }

    // Add any additional logic after this block. Setting the
    // firstSourceUri and first library should be done as early as
    // possible.
    firstSourceUri ??= uri;
    firstUri ??= libraryBuilder.importUri;

    _checkForDartCore(uri, libraryBuilder);

    Uri libraryUri = origin?.importUri ?? uri;
    if (target.backendTarget.mayDefineRestrictedType(libraryUri)) {
      libraryBuilder.mayImplementRestrictedTypes = true;
    }
    if (uri.isScheme("dart")) {
      target.readPatchFiles(libraryBuilder);
    }
    _unparsedLibraries.addLast(libraryBuilder);

    return libraryBuilder;
  }

  DillLibraryBuilder? _lookupDillLibraryBuilder(Uri uri) {
    DillLibraryBuilder? libraryBuilder =
        target.dillTarget.loader.lookupLibraryBuilder(uri);
    if (libraryBuilder != null) {
      _checkDillLibraryBuilderNnbdMode(libraryBuilder);
      _checkForDartCore(uri, libraryBuilder);
    }
    return libraryBuilder;
  }

  void _checkDillLibraryBuilderNnbdMode(DillLibraryBuilder libraryBuilder) {
    if (!libraryBuilder.isNonNullableByDefault &&
        (nnbdMode == NnbdMode.Strong || nnbdMode == NnbdMode.Agnostic)) {
      registerStrongOptOutLibrary(libraryBuilder);
    } else {
      NonNullableByDefaultCompiledMode libraryMode =
          libraryBuilder.library.nonNullableByDefaultCompiledMode;
      if (libraryMode == NonNullableByDefaultCompiledMode.Invalid) {
        registerNnbdMismatchLibrary(
            libraryBuilder, messageInvalidNnbdDillLibrary);
      } else {
        switch (nnbdMode) {
          case NnbdMode.Weak:
            if (libraryMode != NonNullableByDefaultCompiledMode.Agnostic &&
                libraryMode != NonNullableByDefaultCompiledMode.Weak) {
              registerNnbdMismatchLibrary(
                  libraryBuilder, messageWeakWithStrongDillLibrary);
            }
            break;
          case NnbdMode.Strong:
            if (libraryMode != NonNullableByDefaultCompiledMode.Agnostic &&
                libraryMode != NonNullableByDefaultCompiledMode.Strong) {
              registerNnbdMismatchLibrary(
                  libraryBuilder, messageStrongWithWeakDillLibrary);
            }
            break;
          case NnbdMode.Agnostic:
            if (libraryMode != NonNullableByDefaultCompiledMode.Agnostic) {
              if (libraryMode == NonNullableByDefaultCompiledMode.Strong) {
                registerNnbdMismatchLibrary(
                    libraryBuilder, messageAgnosticWithStrongDillLibrary);
              } else {
                registerNnbdMismatchLibrary(
                    libraryBuilder, messageAgnosticWithWeakDillLibrary);
              }
            }
            break;
        }
      }
    }
  }

  void _checkForDartCore(Uri uri, LibraryBuilder libraryBuilder) {
    if (uri.isScheme("dart")) {
      if (uri.path == "core") {
        _coreLibrary = libraryBuilder;
      } else if (uri.path == "typed_data") {
        typedDataLibrary = libraryBuilder;
      }
    }
    // TODO(johnniwinther): If we save the created library in [_builders]
    // here, i.e. before calling `target.loadExtraRequiredLibraries` below,
    // the order of the libraries change, making `dart:core` come before the
    // required arguments. Currently [DillLoader.appendLibrary] one works
    // when this is not the case.
    if (_coreLibrary == libraryBuilder) {
      target.loadExtraRequiredLibraries(this);
    }
  }

  /// Look up a library builder by the [uri], or if such doesn't exist, create
  /// one. The canonical URI of the library is [uri], and its actual location is
  /// [fileUri].
  ///
  /// Canonical URIs have schemes like "dart", or "package", and the actual
  /// location is often a file URI.
  ///
  /// The [accessor] is the library that's trying to import, export, or include
  /// as part [uri], and [charOffset] is the location of the corresponding
  /// directive. If [accessor] isn't allowed to access [uri], it's a
  /// compile-time error.
  LibraryBuilder read(Uri uri, int charOffset,
      {Uri? fileUri,
      required LibraryBuilder accessor,
      LibraryBuilder? origin,
      Library? referencesFrom,
      bool? referenceIsPartOwner}) {
    LibraryBuilder libraryBuilder = _read(uri,
        fileUri: fileUri,
        origin: origin,
        referencesFrom: referencesFrom,
        referenceIsPartOwner: referenceIsPartOwner);
    libraryBuilder.recordAccess(charOffset, noLength, accessor.fileUri);
    if (!_hasLibraryAccess(imported: uri, importer: accessor.importUri) &&
        !accessor.isPatch) {
      accessor.addProblem(messagePlatformPrivateLibraryAccess, charOffset,
          noLength, accessor.fileUri);
    }
    return libraryBuilder;
  }

  /// Reads the library [uri] as an entry point. This is used for reading the
  /// entry point library of a script or the explicitly mention libraries of
  /// a modular or incremental compilation.
  ///
  /// This differs from [read] in that there is no accessor library, meaning
  /// that access to platform private libraries cannot be granted.
  LibraryBuilder readAsEntryPoint(Uri uri,
      {Uri? fileUri, Library? referencesFrom}) {
    LibraryBuilder libraryBuilder =
        _read(uri, fileUri: fileUri, referencesFrom: referencesFrom);
    // TODO(johnniwinther): Avoid using the first library, if present, as the
    // accessor of [libraryBuilder]. Currently the incremental compiler doesn't
    // handle errors reported without an accessor, since the messages are not
    // associated with a library. This currently has the side effect that
    // the first library is the accessor of itself.
    LibraryBuilder? firstLibrary = first;
    if (firstLibrary != null) {
      libraryBuilder.recordAccess(-1, noLength, firstLibrary.fileUri);
    }
    if (!_hasLibraryAccess(imported: uri, importer: firstLibrary?.importUri)) {
      if (firstLibrary != null) {
        firstLibrary.addProblem(
            messagePlatformPrivateLibraryAccess, -1, noLength, firstUri);
      } else {
        addProblem(messagePlatformPrivateLibraryAccess, -1, noLength, null);
      }
    }
    return libraryBuilder;
  }

  bool _hasLibraryAccess({required Uri imported, required Uri? importer}) {
    if (imported.isScheme("dart") && imported.path.startsWith("_")) {
      if (importer == null) {
        return false;
      } else {
        return target.backendTarget
            .allowPlatformPrivateLibraryAccess(importer, imported);
      }
    }
    return true;
  }

  LibraryBuilder _read(Uri uri,
      {Uri? fileUri,
      LibraryBuilder? origin,
      Library? referencesFrom,
      bool? referenceIsPartOwner}) {
    LibraryBuilder? libraryBuilder = _builders[uri];
    if (libraryBuilder == null) {
      if (target.dillTarget.isLoaded) {
        libraryBuilder = _lookupDillLibraryBuilder(uri);
      }
      if (libraryBuilder == null) {
        libraryBuilder = _createSourceLibraryBuilder(
            uri,
            fileUri,
            origin as SourceLibraryBuilder?,
            referencesFrom,
            referenceIsPartOwner);
      }
      _builders[uri] = libraryBuilder;
    }
    return libraryBuilder;
  }

  void _ensureCoreLibrary() {
    if (_coreLibrary == null) {
      readAsEntryPoint(Uri.parse("dart:core"));
      // TODO(askesc): When all backends support set literals, we no longer
      // need to index dart:collection, as it is only needed for desugaring of
      // const sets. We can remove it from this list at that time.
      readAsEntryPoint(Uri.parse("dart:collection"));
      assert(_coreLibrary != null);
    }
  }

  Future<Null> buildBodies() async {
    assert(_coreLibrary != null);
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      currentUriForCrashReporting = library.importUri;
      await buildBody(library);
    }
    // Workaround: This will return right away but avoid a "semi leak"
    // where the latest library is saved in a context somewhere.
    await buildBody(null);
    currentUriForCrashReporting = null;
    logSummary(templateSourceBodySummary);
  }

  void logSummary(Template<SummaryTemplate> template) {
    ticker.log((Duration elapsed, Duration sinceStart) {
      int libraryCount = 0;
      for (LibraryBuilder library in libraryBuilders) {
        if (library.loader == this) {
          libraryCount++;
          if (library is SourceLibraryBuilder) {
            libraryCount += library.patchLibraries?.length ?? 0;
          }
        }
      }
      double ms = elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;
      Message message = template.withArguments(
          libraryCount, byteCount, ms, byteCount / ms, ms / libraryCount);
      print("$sinceStart: ${message.problemMessage}");
    });
  }

  /// Register [message] as a problem with a severity determined by the
  /// intrinsic severity of the message.
  @override
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled: false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary: false,
      List<Uri>? involvedFiles}) {
    return addMessage(message, charOffset, length, fileUri, severity,
        wasHandled: wasHandled,
        context: context,
        problemOnLibrary: problemOnLibrary,
        involvedFiles: involvedFiles);
  }

  /// All messages reported by the compiler (errors, warnings, etc.) are routed
  /// through this method.
  ///
  /// Returns a FormattedMessage if the message is new, that is, not previously
  /// reported. This is important as some parser errors may be reported up to
  /// three times by `OutlineBuilder`, `DietListener`, and `BodyBuilder`.
  /// If the message is not new, [null] is reported.
  ///
  /// If [severity] is `Severity.error`, the message is added to
  /// [handledErrors] if [wasHandled] is true or to [unhandledErrors] if
  /// [wasHandled] is false.
  FormattedMessage? addMessage(Message message, int charOffset, int length,
      Uri? fileUri, Severity? severity,
      {bool wasHandled: false,
      List<LocatedMessage>? context,
      bool problemOnLibrary: false,
      List<Uri>? involvedFiles}) {
    severity ??= message.code.severity;
    if (severity == Severity.ignored) return null;
    String trace = """
message: ${message.problemMessage}
charOffset: $charOffset
fileUri: $fileUri
severity: $severity
""";
    if (!seenMessages.add(trace)) return null;
    if (message.code.severity == Severity.error) {
      _hasSeenError = true;
    }
    if (message.code.severity == Severity.context) {
      internalProblem(
          templateInternalProblemContextSeverity
              .withArguments(message.code.name),
          charOffset,
          fileUri);
    }
    target.context.report(
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            : message.withoutLocation(),
        severity,
        context: context,
        involvedFiles: involvedFiles);
    if (severity == Severity.error) {
      (wasHandled ? handledErrors : unhandledErrors).add(fileUri != null
          ? message.withLocation(fileUri, charOffset, length)
          : message.withoutLocation());
    }
    FormattedMessage formattedMessage = target.createFormattedMessage(
        message, charOffset, length, fileUri, context, severity,
        involvedFiles: involvedFiles);
    if (!problemOnLibrary) {
      allComponentProblems.add(formattedMessage);
    }
    return formattedMessage;
  }

  MemberBuilder getAbstractClassInstantiationError() {
    return target.getAbstractClassInstantiationError(this);
  }

  MemberBuilder getCompileTimeError() => target.getCompileTimeError(this);

  MemberBuilder getDuplicatedFieldInitializerError() {
    return target.getDuplicatedFieldInitializerError(this);
  }

  MemberBuilder getNativeAnnotation() => target.getNativeAnnotation(this);

  BodyBuilder createBodyBuilderForOutlineExpression(
      SourceLibraryBuilder library,
      DeclarationBuilder? declarationBuilder,
      ModifierBuilder member,
      Scope scope,
      Uri fileUri,
      {Scope? formalParameterScope}) {
    return new BodyBuilder.forOutlineExpression(
        library, declarationBuilder, member, scope, fileUri,
        formalParameterScope: formalParameterScope);
  }

  NnbdMode get nnbdMode => target.context.options.nnbdMode;

  bool get enableUnscheduledExperiments =>
      target.context.options.enableUnscheduledExperiments;

  CoreTypes get coreTypes {
    assert(_coreTypes != null, "CoreTypes has not been computed.");
    return _coreTypes!;
  }

  ClassHierarchy get hierarchy => _hierarchy!;

  void set hierarchy(ClassHierarchy? value) {
    if (_hierarchy != value) {
      _hierarchy = value;
      _typeEnvironment = null;
    }
  }

  TypeEnvironment get typeEnvironment {
    return _typeEnvironment ??= new TypeEnvironment(coreTypes, hierarchy);
  }

  TypeInferenceEngineImpl get typeInferenceEngine => _typeInferenceEngine!;

  ClassHierarchyBuilder get hierarchyBuilder => _hierarchyBuilder!;

  ClassMembersBuilder get membersBuilder => _membersBuilder!;

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateSourceOutlineSummary;

  Future<Token> tokenize(SourceLibraryBuilder library,
      {bool suppressLexicalErrors: false}) async {
    Uri fileUri = library.fileUri;

    // Lookup the file URI in the cache.
    List<int>? bytes = sourceBytes[fileUri];

    if (bytes == null) {
      // Error recovery.
      if (fileUri.isScheme(untranslatableUriScheme)) {
        Message message =
            templateUntranslatableUri.withArguments(library.importUri);
        library.addProblemAtAccessors(message);
        bytes = synthesizeSourceForMissingFile(library.importUri, null);
      } else if (!fileUri.hasScheme) {
        return internalProblem(
            templateInternalProblemUriMissingScheme.withArguments(fileUri),
            -1,
            library.importUri);
      } else if (fileUri.isScheme(SourceLibraryBuilder.MALFORMED_URI_SCHEME)) {
        library.addProblemAtAccessors(messageExpectedUri);
        bytes = synthesizeSourceForMissingFile(library.importUri, null);
      }
      if (bytes != null) {
        Uint8List zeroTerminatedBytes = new Uint8List(bytes.length + 1);
        zeroTerminatedBytes.setRange(0, bytes.length, bytes);
        bytes = zeroTerminatedBytes;
        sourceBytes[fileUri] = bytes;
      }
    }

    if (bytes == null) {
      // If it isn't found in the cache, read the file read from the file
      // system.
      List<int> rawBytes;
      try {
        rawBytes = await fileSystem.entityForUri(fileUri).readAsBytes();
      } on FileSystemException catch (e) {
        Message message =
            templateCantReadFile.withArguments(fileUri, e.message);
        library.addProblemAtAccessors(message);
        rawBytes = synthesizeSourceForMissingFile(library.importUri, message);
      }
      Uint8List zeroTerminatedBytes = new Uint8List(rawBytes.length + 1);
      zeroTerminatedBytes.setRange(0, rawBytes.length, rawBytes);
      bytes = zeroTerminatedBytes;
      sourceBytes[fileUri] = bytes;
      byteCount += rawBytes.length;
    }

    ScannerResult result = scan(bytes,
        includeComments: includeComments,
        configuration: new ScannerConfiguration(
            enableTripleShift: target.isExperimentEnabledInLibraryByVersion(
                ExperimentalFlag.tripleShift,
                library.importUri,
                library.packageLanguageVersion.version),
            enableExtensionMethods:
                target.isExperimentEnabledInLibraryByVersion(
                    ExperimentalFlag.extensionMethods,
                    library.importUri,
                    library.packageLanguageVersion.version),
            enableNonNullable: target.isExperimentEnabledInLibraryByVersion(
                ExperimentalFlag.nonNullable,
                library.importUri,
                library.packageLanguageVersion.version)),
        languageVersionChanged:
            (Scanner scanner, LanguageVersionToken version) {
      if (!suppressLexicalErrors) {
        library.registerExplicitLanguageVersion(
            new Version(version.major, version.minor),
            offset: version.offset,
            length: version.length);
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
            new List<String>.of(importUri.pathSegments);
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
            lengthForToken(token), fileUri);
      }
      token = token.next!;
    }
    return token;
  }

  List<int> synthesizeSourceForMissingFile(Uri uri, Message? message) {
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
        return utf8
            .encode(message == null ? "" : "/* ${message.problemMessage} */");
    }
  }

  Set<LibraryBuilder>? _strongOptOutLibraries;

  void registerStrongOptOutLibrary(LibraryBuilder libraryBuilder) {
    _strongOptOutLibraries ??= {};
    _strongOptOutLibraries!.add(libraryBuilder);
    hasInvalidNnbdModeLibrary = true;
  }

  bool hasInvalidNnbdModeLibrary = false;

  Map<LibraryBuilder, Message>? _nnbdMismatchLibraries;

  void registerNnbdMismatchLibrary(
      LibraryBuilder libraryBuilder, Message message) {
    _nnbdMismatchLibraries ??= {};
    _nnbdMismatchLibraries![libraryBuilder] = message;
    hasInvalidNnbdModeLibrary = true;
  }

  void registerConstructorToBeInferred(
      Constructor constructor, DeclaredSourceConstructorBuilder builder) {
    _typeInferenceEngine!.toBeInferred[constructor] = builder;
  }

  void registerTypeDependency(Member member, TypeDependency typeDependency) {
    _typeInferenceEngine!.typeDependencies[member] = typeDependency;
  }

  Future<void> buildOutlines() async {
    _ensureCoreLibrary();
    while (_unparsedLibraries.isNotEmpty) {
      LibraryBuilder library = _unparsedLibraries.removeFirst();
      currentUriForCrashReporting = library.importUri;
      await buildOutline(library as SourceLibraryBuilder);
    }
    currentUriForCrashReporting = null;
    logSummary(outlineSummaryTemplate);

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
      giveCombinedErrorForNonStrongLibraries(_strongOptOutLibraries!,
          emitNonPackageErrors: true);
      _strongOptOutLibraries = null;
    }
    if (_nnbdMismatchLibraries != null) {
      for (MapEntry<LibraryBuilder, Message> entry
          in _nnbdMismatchLibraries!.entries) {
        addProblem(entry.value, -1, noLength, entry.key.fileUri);
      }
      _nnbdMismatchLibraries = null;
    }
  }

  FormattedMessage? giveCombinedErrorForNonStrongLibraries(
      Set<LibraryBuilder> libraries,
      {required bool emitNonPackageErrors}) {
    Map<String?, List<LibraryBuilder>> libraryByPackage = {};
    Map<package_config.Package, Version> enableNonNullableVersionByPackage = {};
    for (LibraryBuilder libraryBuilder in libraries) {
      final package_config.Package? package =
          target.uriTranslator.getPackage(libraryBuilder.importUri);

      if (package != null &&
          package.languageVersion != null &&
          package.languageVersion is! InvalidLanguageVersion) {
        Version enableNonNullableVersion =
            enableNonNullableVersionByPackage[package] ??=
                target.getExperimentEnabledVersionInLibrary(
                    ExperimentalFlag.nonNullable,
                    new Uri(scheme: 'package', path: package.name));
        Version version = new Version(
            package.languageVersion!.major, package.languageVersion!.minor);
        if (version < enableNonNullableVersion) {
          (libraryByPackage[package.name] ??= []).add(libraryBuilder);
          continue;
        }
      }
      if (libraryBuilder.importUri.isScheme('package')) {
        (libraryByPackage[null] ??= []).add(libraryBuilder);
      } else {
        if (emitNonPackageErrors) {
          // Emit a message that doesn't mention running 'pub'.
          addProblem(messageStrongModeNNBDButOptOut, -1, noLength,
              libraryBuilder.fileUri);
        }
      }
    }
    if (libraryByPackage.isNotEmpty) {
      List<Uri> involvedFiles = [];
      List<String> dependencies = [];
      libraryByPackage.forEach((String? name, List<LibraryBuilder> libraries) {
        if (name != null) {
          dependencies.add('package:$name');
          for (LibraryBuilder libraryBuilder in libraries) {
            involvedFiles.add(libraryBuilder.fileUri);
          }
        } else {
          for (LibraryBuilder libraryBuilder in libraries) {
            dependencies.add(libraryBuilder.importUri.toString());
            involvedFiles.add(libraryBuilder.fileUri);
          }
        }
      });
      // Emit a message that suggests to run 'pub' to check for opted in
      // versions of the packages.
      return addProblem(
          templateStrongModeNNBDPackageOptOut.withArguments(dependencies),
          -1,
          -1,
          null,
          involvedFiles: involvedFiles);
    }
    return null;
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
    // ignore: unnecessary_null_comparison
    if (tokens == null) return;
    OutlineBuilder listener = new OutlineBuilder(library);
    new ClassMemberParser(listener).parseUnit(tokens);
  }

  /// Builds all the method bodies found in the given [library].
  Future<Null> buildBody(SourceLibraryBuilder? library) async {
    // [library] is only nullable so we can call this a "dummy-time" to get rid
    // of a semi-leak.
    if (library == null) return;
    Iterable<SourceLibraryBuilder>? patches = library.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        await buildBody(patchLibrary);
      }
    }

    // We tokenize source files twice to keep memory usage low. This is the
    // second time, and the first time was in [buildOutline] above. So this
    // time we suppress lexical errors.
    Token tokens = await tokenize(library, suppressLexicalErrors: true);
    // ignore: unnecessary_null_comparison
    if (tokens == null) return;
    DietListener listener = createDietListener(library);
    DietParser parser = new DietParser(listener);
    parser.parseUnit(tokens);
    for (LibraryBuilder part in library.parts) {
      if (part.partOfLibrary != library) {
        // Part was included in multiple libraries. Skip it here.
        continue;
      }
      Token tokens = await tokenize(part as SourceLibraryBuilder,
          suppressLexicalErrors: true);
      // ignore: unnecessary_null_comparison
      if (tokens != null) {
        listener.uri = part.fileUri;
        parser.parseUnit(tokens);
      }
    }
  }

  Future<Expression> buildExpression(
      SourceLibraryBuilder libraryBuilder,
      String? enclosingClassOrExtension,
      bool isClassInstanceMember,
      FunctionNode parameters,
      VariableDeclaration? extensionThis) async {
    Token token = await tokenize(libraryBuilder, suppressLexicalErrors: false);
    DietListener dietListener = createDietListener(libraryBuilder);

    Builder parent = libraryBuilder;
    if (enclosingClassOrExtension != null) {
      Builder? cls = dietListener.memberScope
          .lookup(enclosingClassOrExtension, -1, libraryBuilder.fileUri);
      if (cls is ClassBuilder) {
        parent = cls;
        dietListener
          ..currentDeclaration = cls
          ..memberScope = cls.scope.copyWithParent(
              dietListener.memberScope.withTypeVariables(cls.typeVariables),
              "debugExpression in class $enclosingClassOrExtension");
      } else if (cls is ExtensionBuilder) {
        parent = cls;
        dietListener
          ..currentDeclaration = cls
          ..memberScope = cls.scope.copyWithParent(dietListener.memberScope,
              "debugExpression in extension $enclosingClassOrExtension");
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
        libraryBuilder,
        0,
        0,
        -1,
        -1,
        null,
        null,
        AsyncMarker.Sync,
        new NameScheme(
            className: null,
            extensionName: null,
            isExtensionMember: false,
            isInstanceMember: false,
            libraryReference: libraryBuilder.library.reference),
        isInstanceMember: false,
        isExtensionMember: false)
      ..parent = parent;
    BodyBuilder listener = dietListener.createListener(
        builder, dietListener.memberScope,
        isDeclarationInstanceMember: isClassInstanceMember,
        extensionThis: extensionThis);
    for (VariableDeclaration variable in parameters.positionalParameters) {
      listener.typeInferrer.assignedVariables.declare(variable);
    }

    return listener.parseSingleExpression(
        new Parser(listener,
            useImplicitCreationExpression: useImplicitCreationExpressionInCfe),
        token,
        parameters);
  }

  DietListener createDietListener(SourceLibraryBuilder library) {
    return new DietListener(library, hierarchy, coreTypes, typeInferenceEngine);
  }

  void resolveParts() {
    List<Uri> parts = <Uri>[];
    List<SourceLibraryBuilder> libraries = [];
    List<SourceLibraryBuilder> sourceLibraries = [];
    List<SourceLibraryBuilder> patchLibraries = [];
    _builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this && library is SourceLibraryBuilder) {
        if (library.isPart) {
          parts.add(uri);
        } else {
          if (library.isPatch) {
            patchLibraries.add(library);
          } else {
            sourceLibraries.add(library);
          }
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
        LibraryBuilder? part = _builders.remove(uri);
        if (_firstUri == uri) {
          firstUri = part!.partOfLibrary!.importUri;
        }
      } else {
        SourceLibraryBuilder part =
            lookupLibraryBuilder(uri) as SourceLibraryBuilder;
        part.addProblem(messagePartOrphan, 0, 1, part.fileUri);
        part.validatePart(null, null);
        sourceLibraries.add(part);
      }
    }
    ticker.logMs("Resolved parts");

    for (LibraryBuilder library in libraryBuilders) {
      if (library.loader == this) {
        library.applyPatches();
      }
    }
    for (SourceLibraryBuilder patchLibrary in patchLibraries) {
      _builders.remove(patchLibrary.fileUri);
      patchLibrary.origin.addPatchLibrary(patchLibrary);
    }
    _sourceLibraryBuilders = sourceLibraries;
    assert(
        libraryBuilders.every((library) => !library.isPatch),
        "Patch library found in libraryBuilders: "
        "${libraryBuilders.where((library) => library.isPatch)}.");
    assert(
        sourceLibraries.every((library) => !library.isPatch),
        "Patch library found in sourceLibraryBuilders: "
        "${sourceLibraries.where((library) => library.isPatch)}.");
    assert(
        libraryBuilders.every((library) =>
            library.loader != this || sourceLibraries.contains(library)),
        "Source library not found in sourceLibraryBuilders:"
        "${libraryBuilders.where((library) => // force line break
            library.loader == this && !sourceLibraries.contains(library))}");
    ticker.logMs("Applied patches");
  }

  void computeLibraryScopes() {
    Set<LibraryBuilder> exporters = new Set<LibraryBuilder>();
    Set<LibraryBuilder> exportees = new Set<LibraryBuilder>();
    for (LibraryBuilder library in libraryBuilders) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library as SourceLibraryBuilder;
        sourceLibrary.buildInitialScopes();
      }
      if (library.exporters.isNotEmpty) {
        exportees.add(library);
        for (Export exporter in library.exporters) {
          exporters.add(exporter.exporter);
        }
      }

      Iterable<SourceLibraryBuilder>? patches =
          library is SourceLibraryBuilder ? library.patchLibraries : null;
      if (patches != null) {
        for (SourceLibraryBuilder patchLibrary in patches) {
          if (patchLibrary.exporters.isNotEmpty) {
            exportees.add(patchLibrary);
            for (Export exporter in patchLibrary.exporters) {
              exporters.add(exporter.exporter);
            }
          }
        }
      }
    }
    Set<SourceLibraryBuilder> both = new Set<SourceLibraryBuilder>();
    for (LibraryBuilder exported in exportees) {
      if (exporters.contains(exported)) {
        both.add(exported as SourceLibraryBuilder);
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
    for (LibraryBuilder library in libraryBuilders) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library as SourceLibraryBuilder;
        sourceLibrary.addImportsToScope();
      }
    }
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
    _builders.forEach((Uri uri, dynamic l) {
      SourceLibraryBuilder library = l;
      Set<Builder> members = new Set<Builder>();
      Iterator<Builder> iterator = library.iterator;
      while (iterator.moveNext()) {
        members.add(iterator.current);
      }
      List<String> exports = <String>[];
      library.exportScope.forEach((String name, Builder? member) {
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
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      typeCount += library.resolveTypes();
    }
    ticker.logMs("Resolved $typeCount types");
  }

  /// Computes which macro declarations that needs to be precompiled in order
  /// to support macro application during compilation.
  ///
  /// If no macros need precompilation, `null` is returned.
  NeededPrecompilations? computeMacroDeclarations() {
    if (!enableMacros) return null;

    LibraryBuilder? macroLibraryBuilder = lookupLibraryBuilder(macroLibraryUri);
    if (macroLibraryBuilder == null) return null;

    Builder? macroClassBuilder =
        macroLibraryBuilder.lookupLocalMember(macroClassName);
    if (macroClassBuilder is! ClassBuilder) {
      // TODO(johnniwinther): Report this when the actual macro builder package
      // exists. It should at least be a warning.
      return null;
    }

    _macroClassBuilder = macroClassBuilder;
    if (retainDataForTesting) {
      dataForTesting!.macroDeclarationData.macrosAreAvailable = true;
    }

    /// Libraries containing macros that need compilation mapped to the
    /// [ClassBuilder]s for the macro classes.
    Map<Uri, List<ClassBuilder>> macroLibraries = {};

    /// Libraries containing precompiled macro classes.
    Set<Uri> precompiledMacroLibraries = {};

    Map<MacroClass, Uri> precompiledMacroUris =
        target.context.options.precompiledMacroUris;

    for (LibraryBuilder libraryBuilder in libraryBuilders) {
      Iterator<Builder> iterator = libraryBuilder.iterator;
      while (iterator.moveNext()) {
        Builder builder = iterator.current;
        if (builder is ClassBuilder && builder.isMacro) {
          Uri libraryUri = builder.library.importUri;
          MacroClass macroClass = new MacroClass(libraryUri, builder.name);
          if (!precompiledMacroUris.containsKey(macroClass)) {
            (macroLibraries[libraryUri] ??= []).add(builder);
            if (retainDataForTesting) {
              (dataForTesting!.macroDeclarationData
                      .macroDeclarations[libraryUri] ??= [])
                  .add(builder.name);
            }
          } else {
            precompiledMacroLibraries.add(libraryUri);
          }
        }
      }
    }

    if (macroLibraries.isEmpty) {
      return null;
    }

    List<List<Uri>> computeCompilationSequence(Graph<Uri> libraryGraph,
        {required bool Function(Uri) filter}) {
      List<List<Uri>> stronglyConnectedComponents =
          computeStrongComponents(libraryGraph);

      Graph<List<Uri>> strongGraph =
          new StrongComponentGraph(libraryGraph, stronglyConnectedComponents);
      List<List<List<Uri>>> componentLayers =
          topologicalSort(strongGraph).layers;
      List<List<Uri>> layeredComponents = [];
      List<Uri> currentLayer = [];
      for (List<List<Uri>> layer in componentLayers) {
        bool declaresMacro = false;
        for (List<Uri> component in layer) {
          for (Uri uri in component) {
            if (filter(uri)) continue;
            if (macroLibraries.containsKey(uri)) {
              declaresMacro = true;
            }
            currentLayer.add(uri);
          }
        }
        if (declaresMacro) {
          layeredComponents.add(currentLayer);
          currentLayer = [];
        }
      }
      if (currentLayer.isNotEmpty) {
        layeredComponents.add(currentLayer);
      }
      return layeredComponents;
    }

    Graph<Uri> graph = new BuilderGraph(_builders);

    /// Libraries that are considered precompiled. These are libraries that are
    /// either given as precompiled macro libraries, or libraries that these
    /// depend upon.
    // TODO(johnniwinther): Can we assume that the precompiled dills are
    // self-contained?
    Set<Uri> precompiledLibraries = {};

    void addPrecompiledLibrary(Uri uri) {
      if (precompiledLibraries.add(uri)) {
        for (Uri neighbor in graph.neighborsOf(uri)) {
          addPrecompiledLibrary(neighbor);
        }
      }
    }

    for (LibraryBuilder builder in _builders.values) {
      if (builder.loader != this) {
        addPrecompiledLibrary(builder.importUri);
      } else if (precompiledMacroLibraries.contains(builder.importUri)) {
        assert(
            !macroLibraries.containsKey(builder.importUri),
            "Macro library ${builder.importUri} is only partially "
            "precompiled.");
        addPrecompiledLibrary(builder.importUri);
      }
    }

    bool isPrecompiledLibrary(Uri uri) => precompiledLibraries.contains(uri);

    List<List<Uri>> compilationSteps =
        computeCompilationSequence(graph, filter: isPrecompiledLibrary);
    if (retainDataForTesting) {
      dataForTesting!.macroDeclarationData.compilationSequence =
          compilationSteps;
    }

    if (compilationSteps.length > 1) {
      // We have at least 1 layer of macros that need to be precompiled before
      // we can compile the program itself.
      Map<Uri, Map<String, List<String>>> neededPrecompilations = {};
      for (int i = 0; i < compilationSteps.length - 1; i++) {
        List<Uri> compilationStep = compilationSteps[i];
        for (Uri uri in compilationStep) {
          List<ClassBuilder>? macroClasses = macroLibraries[uri];
          // [uri] might not itself declare any macros but instead a part of the
          // libraries that macros depend upon.
          if (macroClasses != null) {
            Map<String, List<String>>? constructorMap;
            for (ClassBuilder macroClass in macroClasses) {
              List<String> constructors =
                  macroClass.constructors.local.keys.toList();
              if (constructors.isNotEmpty) {
                // TODO(johnniwinther): If there is no constructor here, it
                // means the macro had no _explicit_ constructors. Since macro
                // constructor are required to be const, this would be an error
                // case. We need to handle that precompilation could result in
                // errors like this. For this case we should probably add 'new'
                // in case of [constructors] being empty in expectation of
                // triggering the error during precompilation.
                (constructorMap ??= {})[macroClass.name] = constructors;
              }
            }
            if (constructorMap != null) {
              neededPrecompilations[uri] = constructorMap;
            }
          }
        }
        if (neededPrecompilations.isNotEmpty) {
          if (retainDataForTesting) {
            dataForTesting!.macroDeclarationData.neededPrecompilations
                .add(neededPrecompilations);
          }
          // We have found the first needed layer of precompilation. There might
          // be more layers but we'll compute these at the next attempt at
          // compilation, when this layer has been precompiled.
          // TODO(johnniwinther): Use this to trigger a precompile step.
          return new NeededPrecompilations(neededPrecompilations);
        }
      }
    }
    return null;
  }

  Future<MacroApplications?> computeMacroApplications() async {
    if (!enableMacros || _macroClassBuilder == null) return null;

    Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData = {};
    for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
      // TODO(johnniwinther): Handle patch libraries.
      LibraryMacroApplicationData libraryMacroApplicationData =
          new LibraryMacroApplicationData();
      Iterator<Builder> iterator = libraryBuilder.iterator;
      while (iterator.moveNext()) {
        Builder builder = iterator.current;
        if (builder is SourceClassBuilder) {
          SourceClassBuilder classBuilder = builder;
          ClassMacroApplicationData classMacroApplicationData =
              new ClassMacroApplicationData();
          classMacroApplicationData.classApplications = prebuildAnnotations(
              enclosingLibrary: libraryBuilder,
              scope: classBuilder.scope,
              fileUri: classBuilder.fileUri,
              metadataBuilders: classBuilder.metadata);
          classBuilder.forEach((String name, Builder memberBuilder) {
            if (memberBuilder is SourceProcedureBuilder) {
              List<MacroApplication>? macroApplications = prebuildAnnotations(
                  enclosingLibrary: libraryBuilder,
                  scope: classBuilder.scope,
                  fileUri: memberBuilder.fileUri,
                  metadataBuilders: memberBuilder.metadata);
              if (macroApplications != null) {
                classMacroApplicationData.memberApplications[memberBuilder] =
                    macroApplications;
              }
            } else if (memberBuilder is SourceFieldBuilder) {
              List<MacroApplication>? macroApplications = prebuildAnnotations(
                  enclosingLibrary: libraryBuilder,
                  scope: classBuilder.scope,
                  fileUri: memberBuilder.fileUri,
                  metadataBuilders: memberBuilder.metadata);
              if (macroApplications != null) {
                classMacroApplicationData.memberApplications[memberBuilder] =
                    macroApplications;
              }
            } else {
              throw new UnsupportedError("Unexpected class member "
                  "$memberBuilder (${memberBuilder.runtimeType})");
            }
          });
          classBuilder.forEachConstructor((String name, Builder memberBuilder) {
            if (memberBuilder is DeclaredSourceConstructorBuilder) {
              List<MacroApplication>? macroApplications = prebuildAnnotations(
                  enclosingLibrary: libraryBuilder,
                  scope: classBuilder.scope,
                  fileUri: memberBuilder.fileUri,
                  metadataBuilders: memberBuilder.metadata);
              if (macroApplications != null) {
                classMacroApplicationData.memberApplications[memberBuilder] =
                    macroApplications;
              }
            } else if (memberBuilder is SourceFactoryBuilder) {
              List<MacroApplication>? macroApplications = prebuildAnnotations(
                  enclosingLibrary: libraryBuilder,
                  scope: classBuilder.scope,
                  fileUri: memberBuilder.fileUri,
                  metadataBuilders: memberBuilder.metadata);
              if (macroApplications != null) {
                classMacroApplicationData.memberApplications[memberBuilder] =
                    macroApplications;
              }
            } else {
              throw new UnsupportedError("Unexpected constructor "
                  "$memberBuilder (${memberBuilder.runtimeType})");
            }
          });

          if (classMacroApplicationData.classApplications != null ||
              classMacroApplicationData.memberApplications.isNotEmpty) {
            libraryMacroApplicationData.classData[builder] =
                classMacroApplicationData;
          }
        } else if (builder is SourceProcedureBuilder) {
          List<MacroApplication>? macroApplications = prebuildAnnotations(
              enclosingLibrary: libraryBuilder,
              scope: libraryBuilder.scope,
              fileUri: builder.fileUri,
              metadataBuilders: builder.metadata);
          if (macroApplications != null) {
            libraryMacroApplicationData.memberApplications[builder] =
                macroApplications;
          }
        } else if (builder is SourceFieldBuilder) {
          List<MacroApplication>? macroApplications = prebuildAnnotations(
              enclosingLibrary: libraryBuilder,
              scope: libraryBuilder.scope,
              fileUri: builder.fileUri,
              metadataBuilders: builder.metadata);
          if (macroApplications != null) {
            libraryMacroApplicationData.memberApplications[builder] =
                macroApplications;
          }
        } else if (builder is PrefixBuilder ||
            builder is SourceExtensionBuilder ||
            builder is SourceTypeAliasBuilder) {
          // Macro applications are not supported.
        } else {
          throw new UnsupportedError("Unexpected library member "
              "$builder (${builder.runtimeType})");
        }
      }
      if (libraryMacroApplicationData.classData.isNotEmpty ||
          libraryMacroApplicationData.memberApplications.isNotEmpty) {
        libraryData[libraryBuilder] = libraryMacroApplicationData;
      }
    }
    if (libraryData.isNotEmpty) {
      MacroExecutor macroExecutor =
          await target.context.options.macroExecutorProvider();
      Map<MacroClass, Uri> precompiledMacroUris =
          target.context.options.precompiledMacroUris;
      return await MacroApplications.loadMacroIds(
          macroExecutor,
          precompiledMacroUris,
          libraryData,
          dataForTesting?.macroApplicationData);
    }
    return null;
  }

  void finishDeferredLoadTearoffs() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishDeferredLoadTearoffs();
    }
    ticker.logMs("Finished deferred load tearoffs $count");
  }

  void finishNoSuchMethodForwarders() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishForwarders();
    }
    ticker.logMs("Finished forwarders for $count procedures");
  }

  void resolveConstructors() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.resolveConstructors();
    }
    ticker.logMs("Resolved $count constructors");
  }

  void installTypedefTearOffs() {
    if (target.backendTarget.isTypedefTearOffLoweringEnabled) {
      for (SourceLibraryBuilder library in sourceLibraryBuilders) {
        library.installTypedefTearOffs();
      }
    }
  }

  void finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishTypeVariables(object, dynamicType);
    }
    ticker.logMs("Resolved $count type-variable bounds");
  }

  void computeVariances() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.computeVariances();
    }
    ticker.logMs("Computed variances of $count type variables");
  }

  void computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.computeDefaultTypes(
          dynamicType, nullType, bottomType, objectClass);
    }
    ticker.logMs("Computed default types for $count type variables");
  }

  void finishNativeMethods() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishNativeMethods();
    }
    ticker.logMs("Finished $count native methods");
  }

  void finishPatchMethods() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishPatchMethods();
    }
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

  /// Returns classes defined in libraries in this [SourceLoader].
  List<SourceClassBuilder> collectSourceClasses() {
    List<SourceClassBuilder> sourceClasses = <SourceClassBuilder>[];
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.collectSourceClasses(sourceClasses);
    }
    return sourceClasses;
  }

  /// Returns a list of all class builders declared in this loader.  As the
  /// classes are sorted, any cycles in the hierarchy are reported as
  /// errors. Recover by breaking the cycles. This means that the rest of the
  /// pipeline (including backends) can assume that there are no hierarchy
  /// cycles.
  List<SourceClassBuilder> handleHierarchyCycles(ClassBuilder objectClass) {
    Set<ClassBuilder> denyListedClasses = new Set<ClassBuilder>();
    for (int i = 0; i < denylistedCoreClasses.length; i++) {
      denyListedClasses.add(coreLibrary.lookupLocalMember(
          denylistedCoreClasses[i],
          required: true) as ClassBuilder);
    }
    ClassBuilder enumClass =
        coreLibrary.lookupLocalMember("Enum", required: true) as ClassBuilder;
    if (typedDataLibrary != null) {
      for (int i = 0; i < denylistedTypedDataClasses.length; i++) {
        // Allow the member to not exist. If it doesn't, nobody can extend it.
        Builder? member = typedDataLibrary!
            .lookupLocalMember(denylistedTypedDataClasses[i], required: false);
        if (member != null) denyListedClasses.add(member as ClassBuilder);
      }
    }

    // Sort the classes topologically.
    _SourceClassGraph classGraph =
        new _SourceClassGraph(collectSourceClasses(), objectClass);
    TopologicalSortResult<SourceClassBuilder> result =
        topologicalSort(classGraph);
    List<SourceClassBuilder> classes = result.sortedVertices;
    for (SourceClassBuilder cls in classes) {
      checkClassSupertypes(cls, classGraph.directSupertypeMap[cls]!,
          denyListedClasses, enumClass);
    }

    List<SourceClassBuilder> classesWithCycles = result.cyclicVertices;

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
                      constructor.fileUri!, constructor.charOffset, noLength)
            ]);
      }
    }
  }

  bool checkEnumSupertypeIsDenylisted(SourceClassBuilder cls) {
    if (!cls.library.enableEnhancedEnumsInLibrary) {
      cls.addProblem(
          templateEnumSupertypeOfNonAbstractClass.withArguments(cls.name),
          cls.charOffset,
          noLength);
      return true;
    }
    return false;
  }

  void checkClassSupertypes(
      SourceClassBuilder cls,
      Map<TypeDeclarationBuilder?, TypeAliasBuilder?> directSupertypeMap,
      Set<ClassBuilder> denyListedClasses,
      ClassBuilder enumClass) {
    // Check that the direct supertypes aren't deny-listed or enums.
    List<TypeDeclarationBuilder?> directSupertypes =
        directSupertypeMap.keys.toList();
    for (int i = 0; i < directSupertypes.length; i++) {
      TypeDeclarationBuilder? supertype = directSupertypes[i];
      if (supertype is SourceEnumBuilder) {
        cls.addProblem(templateExtendingEnum.withArguments(supertype.name),
            cls.charOffset, noLength);
      } else if (!cls.library.mayImplementRestrictedTypes &&
          (denyListedClasses.contains(supertype) ||
              identical(supertype, enumClass) &&
                  checkEnumSupertypeIsDenylisted(cls))) {
        TypeAliasBuilder? aliasBuilder = directSupertypeMap[supertype];
        if (aliasBuilder != null) {
          cls.addProblem(
              templateExtendingRestricted
                  .withArguments(supertype!.fullNameForErrors),
              cls.charOffset,
              noLength,
              context: [
                messageTypedefCause.withLocation(
                    aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
              ]);
        } else {
          cls.addProblem(
              templateExtendingRestricted
                  .withArguments(supertype!.fullNameForErrors),
              cls.charOffset,
              noLength);
        }
      }
    }

    // Check that the mixed-in type can be used as a mixin.
    final TypeBuilder? mixedInTypeBuilder = cls.mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      bool isClassBuilder = false;
      if (mixedInTypeBuilder is NamedTypeBuilder) {
        TypeDeclarationBuilder? builder = mixedInTypeBuilder.declaration;
        if (builder is TypeAliasBuilder) {
          TypeAliasBuilder aliasBuilder = builder;
          NamedTypeBuilder namedBuilder = mixedInTypeBuilder;
          builder = aliasBuilder.unaliasDeclaration(namedBuilder.arguments,
              isUsedAsClass: true,
              usedAsClassCharOffset: namedBuilder.charOffset,
              usedAsClassFileUri: namedBuilder.fileUri);
          if (builder is! ClassBuilder) {
            cls.addProblem(
                templateIllegalMixin.withArguments(builder!.fullNameForErrors),
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
    return handleHierarchyCycles(objectClass);
  }

  /// Builds the core AST structure needed for the outline of the component.
  void buildComponent() {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      Library target = library.build(coreLibrary);
      if (library.referencesFrom != null) {
        referenceFromIndex ??= new ReferenceFromIndex();
        referenceFromIndex!
            .addIndexedLibrary(target, library.referencesFromIndexed!);
      }
      libraries.add(target);
    }
    ticker.logMs("Built component");
  }

  Component computeFullComponent() {
    Set<Library> libraries = new Set<Library>();
    List<Library> workList = <Library>[];
    for (LibraryBuilder libraryBuilder in libraryBuilders) {
      if (!libraryBuilder.isPatch &&
          (libraryBuilder.loader == this ||
              libraryBuilder.importUri.isScheme("dart") ||
              libraryBuilder == this.first)) {
        if (libraries.add(libraryBuilder.library)) {
          workList.add(libraryBuilder.library);
        }
      }
    }
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
    List<AmbiguousTypesRecord>? ambiguousTypesRecords = [];
    HandleAmbiguousSupertypes onAmbiguousSupertypes =
        (Class cls, Supertype a, Supertype b) {
      if (ambiguousTypesRecords != null) {
        ambiguousTypesRecords.add(new AmbiguousTypesRecord(cls, a, b));
      }
    };
    if (_hierarchy == null) {
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

  void computeShowHideElements() {
    for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
      libraryBuilder.computeShowHideElements(membersBuilder);
    }
    ticker.logMs("Computed show and hide elements");
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
    _futureOfBottom = new InterfaceType(coreTypes.futureClass,
        Nullability.nonNullable, <DartType>[const NeverType.nonNullable()]);
    _iterableOfBottom = new InterfaceType(coreTypes.iterableClass,
        Nullability.nonNullable, <DartType>[const NeverType.nonNullable()]);
    _streamOfBottom = new InterfaceType(coreTypes.streamClass,
        Nullability.nonNullable, <DartType>[const NeverType.nonNullable()]);

    ticker.logMs("Computed core types");
  }

  void checkSupertypes(
      List<SourceClassBuilder> sourceClasses, Class enumClass) {
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this && !builder.isPatch) {
        builder.checkSupertypes(coreTypes, hierarchyBuilder, enumClass);
      }
    }
    ticker.logMs("Checked supertypes");
  }

  void checkTypes() {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.checkTypesInOutline(typeInferenceEngine.typeSchemaEnvironment);
    }
    ticker.logMs("Checked type arguments of supers against the bounds");
  }

  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    List<DelayedCheck> overrideChecks = membersBuilder.takeDelayedChecks();
    for (int i = 0; i < overrideChecks.length; i++) {
      overrideChecks[i].check(membersBuilder);
    }
    ticker.logMs("Checked ${overrideChecks.length} overrides");

    typeInferenceEngine.finishTopLevelInitializingFormals();
    ticker.logMs("Finished initializing formals");
  }

  void checkAbstractMembers(List<SourceClassBuilder> sourceClasses) {
    List<ClassMember> delayedMemberChecks =
        membersBuilder.takeDelayedMemberComputations();
    Set<Class> changedClasses = new Set<Class>();
    for (int i = 0; i < delayedMemberChecks.length; i++) {
      delayedMemberChecks[i].getMember(membersBuilder);
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

    List<Class> changedClasses = <Class>[];
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
        Class? mixedInClass = builder.cls.mixedInClass;
        if (mixedInClass != null && mixedInClass.isMixinDeclaration) {
          builder.checkMixinApplication(hierarchy, coreTypes);
        }
      }
    }
    ticker.logMs("Checked mixin declaration applications");
  }

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    List<DelayedActionPerformer> delayedActionPerformers =
        <DelayedActionPerformer>[];
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.buildOutlineExpressions(
          classHierarchy, synthesizedFunctionNodes, delayedActionPerformers);
    }
    for (DelayedActionPerformer delayedActionPerformer
        in delayedActionPerformers) {
      delayedActionPerformer.performDelayedActions();
    }
    ticker.logMs("Build outline expressions");
  }

  void buildClassHierarchy(
      List<SourceClassBuilder> sourceClasses, ClassBuilder objectClass) {
    ClassHierarchyBuilder hierarchyBuilder = _hierarchyBuilder =
        ClassHierarchyBuilder.build(
            objectClass, sourceClasses, this, coreTypes);
    typeInferenceEngine.hierarchyBuilder = hierarchyBuilder;
    ticker.logMs("Built class hierarchy");
  }

  void buildClassHierarchyMembers(List<SourceClassBuilder> sourceClasses) {
    ClassMembersBuilder membersBuilder = _membersBuilder =
        ClassMembersBuilder.build(hierarchyBuilder, sourceClasses);
    typeInferenceEngine.membersBuilder = membersBuilder;
    ticker.logMs("Built class hierarchy members");
  }

  void createTypeInferenceEngine() {
    _typeInferenceEngine = new TypeInferenceEngineImpl(instrumentation);
  }

  void performTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    /// The first phase of top level initializer inference, which consists of
    /// creating kernel objects for all fields and top level variables that
    /// might be subject to type inference, and records dependencies between
    /// them.
    typeInferenceEngine.prepareTopLevel(coreTypes, hierarchy);
    membersBuilder.computeTypes();

    List<SourceFieldBuilder> allImplicitlyTypedFields = [];
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.collectImplicitlyTypedFields(allImplicitlyTypedFields);
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
      collectionTransformer!.enterLibrary(clientLibrary);
      node.accept(collectionTransformer!);
      collectionTransformer!.exitLibrary();
    }
    if (transformSetLiterals) {
      setLiteralTransformer ??= new SetLiteralTransformer(this);
      setLiteralTransformer!.enterLibrary(clientLibrary);
      node.accept(setLiteralTransformer!);
      setLiteralTransformer!.exitLibrary();
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

  void _checkMainMethods(
      SourceLibraryBuilder libraryBuilder, DartType listOfString) {
    Iterable<SourceLibraryBuilder>? patches = libraryBuilder.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        _checkMainMethods(patchLibrary, listOfString);
      }
    }

    if (libraryBuilder.isNonNullableByDefault) {
      Builder? mainBuilder =
          libraryBuilder.exportScope.lookupLocalMember('main', setter: false);
      mainBuilder ??=
          libraryBuilder.exportScope.lookupLocalMember('main', setter: true);
      if (mainBuilder is MemberBuilder) {
        if (mainBuilder is InvalidTypeDeclarationBuilder) {
          // This is an ambiguous export, skip the check.
          return;
        }
        if (mainBuilder.isField ||
            mainBuilder.isGetter ||
            mainBuilder.isSetter) {
          if (mainBuilder.parent != libraryBuilder) {
            libraryBuilder.addProblem(messageMainNotFunctionDeclarationExported,
                libraryBuilder.charOffset, noLength, libraryBuilder.fileUri,
                context: [
                  messageExportedMain.withLocation(mainBuilder.fileUri!,
                      mainBuilder.charOffset, mainBuilder.name.length)
                ]);
          } else {
            libraryBuilder.addProblem(
                messageMainNotFunctionDeclaration,
                mainBuilder.charOffset,
                mainBuilder.name.length,
                mainBuilder.fileUri);
          }
        } else {
          Procedure procedure = mainBuilder.member as Procedure;
          if (procedure.function.requiredParameterCount > 2) {
            if (mainBuilder.parent != libraryBuilder) {
              libraryBuilder.addProblem(
                  messageMainTooManyRequiredParametersExported,
                  libraryBuilder.charOffset,
                  noLength,
                  libraryBuilder.fileUri,
                  context: [
                    messageExportedMain.withLocation(mainBuilder.fileUri!,
                        mainBuilder.charOffset, mainBuilder.name.length)
                  ]);
            } else {
              libraryBuilder.addProblem(
                  messageMainTooManyRequiredParameters,
                  mainBuilder.charOffset,
                  mainBuilder.name.length,
                  mainBuilder.fileUri);
            }
          } else if (procedure.function.namedParameters
              .any((parameter) => parameter.isRequired)) {
            if (mainBuilder.parent != libraryBuilder) {
              libraryBuilder.addProblem(
                  messageMainRequiredNamedParametersExported,
                  libraryBuilder.charOffset,
                  noLength,
                  libraryBuilder.fileUri,
                  context: [
                    messageExportedMain.withLocation(mainBuilder.fileUri!,
                        mainBuilder.charOffset, mainBuilder.name.length)
                  ]);
            } else {
              libraryBuilder.addProblem(
                  messageMainRequiredNamedParameters,
                  mainBuilder.charOffset,
                  mainBuilder.name.length,
                  mainBuilder.fileUri);
            }
          } else if (procedure.function.positionalParameters.length > 0) {
            DartType parameterType =
                procedure.function.positionalParameters.first.type;

            if (!typeEnvironment.isSubtypeOf(listOfString, parameterType,
                SubtypeCheckMode.withNullabilities)) {
              if (mainBuilder.parent != libraryBuilder) {
                libraryBuilder.addProblem(
                    templateMainWrongParameterTypeExported.withArguments(
                        parameterType,
                        listOfString,
                        libraryBuilder.isNonNullableByDefault),
                    libraryBuilder.charOffset,
                    noLength,
                    libraryBuilder.fileUri,
                    context: [
                      messageExportedMain.withLocation(mainBuilder.fileUri!,
                          mainBuilder.charOffset, mainBuilder.name.length)
                    ]);
              } else {
                libraryBuilder.addProblem(
                    templateMainWrongParameterType.withArguments(parameterType,
                        listOfString, libraryBuilder.isNonNullableByDefault),
                    mainBuilder.charOffset,
                    mainBuilder.name.length,
                    mainBuilder.fileUri);
              }
            }
          }
        }
      } else if (mainBuilder != null) {
        if (mainBuilder.parent != libraryBuilder) {
          libraryBuilder.addProblem(messageMainNotFunctionDeclarationExported,
              libraryBuilder.charOffset, noLength, libraryBuilder.fileUri,
              context: [
                messageExportedMain.withLocation(
                    mainBuilder.fileUri!, mainBuilder.charOffset, noLength)
              ]);
        } else {
          libraryBuilder.addProblem(messageMainNotFunctionDeclaration,
              mainBuilder.charOffset, noLength, mainBuilder.fileUri);
        }
      }
    }
  }

  void checkMainMethods() {
    DartType listOfString = new InterfaceType(coreTypes.listClass,
        Nullability.nonNullable, [coreTypes.stringNonNullableRawType]);

    for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
      _checkMainMethods(libraryBuilder, listOfString);
    }
  }

  void releaseAncillaryResources() {
    hierarchy = null;
    _hierarchyBuilder = null;
    _membersBuilder = null;
    _typeInferenceEngine = null;
    _builders.clear();
    libraries.clear();
    firstUri = null;
    sourceBytes.clear();
    target.releaseAncillaryResources();
    _coreTypes = null;
    instrumentation = null;
    collectionTransformer = null;
    setLiteralTransformer = null;
  }

  @override
  ClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    Library kernelLibrary = cls.enclosingLibrary;
    LibraryBuilder? library = lookupLibraryBuilder(kernelLibrary.importUri);
    if (library == null) {
      return target.dillTarget.loader.computeClassBuilderFromTargetClass(cls);
    }
    return library.lookupLocalMember(cls.name, required: true) as ClassBuilder;
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

bool identical(a, b) => false;

class Iterator<E> {
  bool moveNext() => null;
  E get current => null;
}

class Iterable<E> {
  Iterator<E> get iterator => null;
}

class List<E> extends Iterable<E> {
  factory List() => null;
  factory List.unmodifiable(elements) => null;
  factory List.empty({bool growable = false}) => null;
  factory List.filled(int length, E fill, {bool growable = false}) => null;
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) => null;
  factory List.of() => null;
  void add(E element) {}
  void addAll(Iterable<E> iterable) {}
  E operator [](int index) => null;
}

class _GrowableList<E> {
  factory _GrowableList(int length) => null;
  factory _GrowableList.empty() => null;
  factory _GrowableList.filled() => null;
  factory _GrowableList.generate(int length, E generator(int index)) => null;
  factory _GrowableList._literal1(E e0) => null;
  factory _GrowableList._literal2(E e0, E e1) => null;
  factory _GrowableList._literal3(E e0, E e1, E e2) => null;
  factory _GrowableList._literal4(E e0, E e1, E e2, E e3) => null;
  factory _GrowableList._literal5(E e0, E e1, E e2, E e3, E e4) => null;
  factory _GrowableList._literal6(E e0, E e1, E e2, E e3, E e4, E e5) => null;
  factory _GrowableList._literal7(E e0, E e1, E e2, E e3, E e4, E e5, E e6) => null;
  factory _GrowableList._literal8(E e0, E e1, E e2, E e3, E e4, E e5, E e6, E e7) => null;
}

class _List<E> {
  factory _List() => null;
  factory _List.empty() => null;
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

abstract class Enum {
  String get _name;
}

abstract class _Enum {
  final String _name;
}

class String {}

class Symbol {}

class Set<E> {
  factory Set() = Set<E>._;
  external factory Set._();
  factory Set.of(o) = Set<E>._of;
  external factory Set._of(o);
  bool add(E element) {}
  void addAll(Iterable<E> iterable) {}
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

void _asyncStarMoveNextHelper(var stream) {}

_asyncThenWrapperHelper(continuation) {}

_awaitHelper(object, thenCallback, errorCallback, awaiter) {}

_completeOnAsyncReturn(_future, value, async_jump_var) {}

_completeWithNoFutureOnAsyncReturn(_future, value, async_jump_var) {}

_completeOnAsyncError(_future, e, st, async_jump_var) {}

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

class _Future {
  void _completeError(Object error, StackTrace stackTrace) {}

  void _asyncCompleteError(Object error, StackTrace stackTrace) {}
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
abstract class LinkedHashMap<K, V> implements Map<K, V> {
  factory LinkedHashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey}) => null;
}

class _InternalLinkedHashMap<K, V> {
  _InternalLinkedHashMap();
}

abstract class LinkedHashSet<E> implements Set<E> {
  factory LinkedHashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey}) => null;
}

class _CompactLinkedHashSet<E> {
  _CompactLinkedHashSet();
}

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
class ReachabilityError {
  ReachabilityError([message]);
}
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

  final MacroDeclarationData macroDeclarationData = new MacroDeclarationData();

  final MacroApplicationDataForTesting macroApplicationData =
      new MacroApplicationDataForTesting();
}

class _SourceClassGraph implements Graph<SourceClassBuilder> {
  @override
  final List<SourceClassBuilder> vertices;
  final ClassBuilder _objectClass;
  final Map<SourceClassBuilder, Map<TypeDeclarationBuilder?, TypeAliasBuilder?>>
      directSupertypeMap = {};
  final Map<SourceClassBuilder, List<SourceClassBuilder>> _supertypeMap = {};

  _SourceClassGraph(this.vertices, this._objectClass);

  List<SourceClassBuilder> computeSuperClasses(SourceClassBuilder cls) {
    Map<TypeDeclarationBuilder?, TypeAliasBuilder?> directSupertypes =
        directSupertypeMap[cls] = cls.computeDirectSupertypes(_objectClass);
    List<SourceClassBuilder> superClasses = [];
    for (TypeDeclarationBuilder? directSupertype in directSupertypes.keys) {
      if (directSupertype is SourceClassBuilder) {
        superClasses.add(directSupertype);
      }
    }
    return superClasses;
  }

  @override
  Iterable<SourceClassBuilder> neighborsOf(SourceClassBuilder vertex) {
    return _supertypeMap[vertex] ??= computeSuperClasses(vertex);
  }
}
