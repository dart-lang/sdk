// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.loader;

import 'dart:collection' show Queue;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Class, DartType, Library, Version;
import 'package:package_config/package_config.dart';

import 'scope.dart';

import 'builder/class_builder.dart';
import 'builder/declaration_builder.dart';
import 'builder/library_builder.dart';
import 'builder/member_builder.dart';
import 'builder/modifier_builder.dart';
import 'builder/type_builder.dart';

import 'crash.dart' show firstSourceUri;

import 'kernel/body_builder.dart' show BodyBuilder;

import 'messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        noLength,
        SummaryTemplate,
        Template,
        messageLanguageVersionInvalidInDotPackages,
        messagePlatformPrivateLibraryAccess,
        templateInternalProblemContextSeverity,
        templateLanguageVersionTooHigh,
        templateSourceBodySummary;

import 'problems.dart' show internalProblem, unhandled;

import 'source/source_library_builder.dart' as src
    show
        LanguageVersion,
        InvalidLanguageVersion,
        ImplicitLanguageVersion,
        SourceLibraryBuilder;

import 'target_implementation.dart' show TargetImplementation;

import 'ticker.dart' show Ticker;

const String untranslatableUriScheme = "org-dartlang-untranslatable-uri";

abstract class Loader {
  final Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

  final Queue<LibraryBuilder> unparsedLibraries = new Queue<LibraryBuilder>();

  final List<Library> libraries = <Library>[];

  final TargetImplementation target;

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

  final Set<String> seenMessages = new Set<String>();
  bool _hasSeenError = false;

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
  LibraryBuilder? first;

  int byteCount = 0;

  Uri? currentUriForCrashReporting;

  Loader(this.target);

  LibraryBuilder get coreLibrary => _coreLibrary!;

  void set coreLibrary(LibraryBuilder value) {
    _coreLibrary = value;
  }

  Ticker get ticker => target.ticker;

  Template<SummaryTemplate> get outlineSummaryTemplate;

  bool get isSourceLoader => false;

  /// Look up a library builder by the name [uri], or if such doesn't
  /// exist, create one. The canonical URI of the library is [uri], and its
  /// actual location is [fileUri].
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
      LibraryBuilder? accessor,
      LibraryBuilder? origin,
      Library? referencesFrom,
      bool? referenceIsPartOwner}) {
    LibraryBuilder builder = builders.putIfAbsent(uri, () {
      if (fileUri != null &&
          (fileUri!.scheme == "dart" ||
              fileUri!.scheme == "package" ||
              fileUri!.scheme == "dart-ext")) {
        fileUri = null;
      }
      Package? packageForLanguageVersion;
      if (fileUri == null) {
        switch (uri.scheme) {
          case "package":
          case "dart":
            fileUri = target.translateUri(uri) ??
                new Uri(
                    scheme: untranslatableUriScheme,
                    path: Uri.encodeComponent("$uri"));
            if (uri.scheme == "package") {
              packageForLanguageVersion = target.uriTranslator.getPackage(uri);
            } else {
              packageForLanguageVersion =
                  target.uriTranslator.packages.packageOf(fileUri!);
            }
            break;

          default:
            fileUri = uri;
            packageForLanguageVersion =
                target.uriTranslator.packages.packageOf(fileUri!);
            break;
        }
      } else {
        packageForLanguageVersion =
            target.uriTranslator.packages.packageOf(fileUri!);
      }
      src.LanguageVersion? packageLanguageVersion;
      Uri? packageUri;
      Message? packageLanguageVersionProblem;
      if (packageForLanguageVersion != null) {
        Uri importUri = origin?.importUri ?? uri;
        if (importUri.scheme != 'dart' &&
            importUri.scheme != 'package' &&
            // ignore: unnecessary_null_comparison
            packageForLanguageVersion.name != null) {
          packageUri =
              new Uri(scheme: 'package', path: packageForLanguageVersion.name);
        }
        if (packageForLanguageVersion.languageVersion != null) {
          if (packageForLanguageVersion.languageVersion
              is InvalidLanguageVersion) {
            packageLanguageVersionProblem =
                messageLanguageVersionInvalidInDotPackages;
            packageLanguageVersion = new src.InvalidLanguageVersion(
                fileUri!, 0, noLength, target.currentSdkVersion, false);
          } else {
            Version version = new Version(
                packageForLanguageVersion.languageVersion!.major,
                packageForLanguageVersion.languageVersion!.minor);
            if (version > target.currentSdkVersion) {
              packageLanguageVersionProblem =
                  templateLanguageVersionTooHigh.withArguments(
                      target.currentSdkVersion.major,
                      target.currentSdkVersion.minor);
              packageLanguageVersion = new src.InvalidLanguageVersion(
                  fileUri!, 0, noLength, target.currentSdkVersion, false);
            } else {
              packageLanguageVersion = new src.ImplicitLanguageVersion(version);
            }
          }
        }
      }
      packageLanguageVersion ??=
          new src.ImplicitLanguageVersion(target.currentSdkVersion);

      LibraryBuilder? library = target.createLibraryBuilder(
          uri,
          fileUri!,
          packageUri,
          packageLanguageVersion,
          origin,
          referencesFrom,
          referenceIsPartOwner);
      if (library == null) {
        throw new StateError("createLibraryBuilder for uri $uri, "
            "fileUri $fileUri returned null.");
      }
      if (packageLanguageVersionProblem != null &&
          library is src.SourceLibraryBuilder) {
        library.addPostponedProblem(
            packageLanguageVersionProblem, 0, noLength, library.fileUri);
      }

      if (uri.scheme == "dart") {
        if (uri.path == "core") {
          _coreLibrary = library;
        } else if (uri.path == "typed_data") {
          typedDataLibrary = library;
        }
      }
      if (library.loader != this) {
        if (_coreLibrary == library) {
          target.loadExtraRequiredLibraries(this);
        }
        // This library isn't owned by this loader, so no further processing
        // should be attempted.
        return library;
      }

      {
        // Add any additional logic after this block. Setting the
        // firstSourceUri and first library should be done as early as
        // possible.
        firstSourceUri ??= uri;
        first ??= library;
      }
      if (_coreLibrary == library) {
        target.loadExtraRequiredLibraries(this);
      }
      Uri libraryUri = origin?.importUri ?? uri;
      if (target.backendTarget.mayDefineRestrictedType(libraryUri)) {
        library.mayImplementRestrictedTypes = true;
      }
      if (uri.scheme == "dart") {
        target.readPatchFiles(library);
      }
      unparsedLibraries.addLast(library);
      return library;
    });
    if (accessor == null) {
      if (builder.loader == this && first != builder && isSourceLoader) {
        unhandled("null", "accessor", charOffset, uri);
      }
    } else {
      builder.recordAccess(charOffset, noLength, accessor.fileUri);
      if (!accessor.isPatch &&
          !accessor.isPart &&
          !target.backendTarget
              .allowPlatformPrivateLibraryAccess(accessor.importUri, uri)) {
        accessor.addProblem(messagePlatformPrivateLibraryAccess, charOffset,
            noLength, accessor.fileUri);
      }
    }
    return builder;
  }

  void ensureCoreLibrary() {
    if (_coreLibrary == null) {
      read(Uri.parse("dart:core"), 0, accessor: first);
      // TODO(askesc): When all backends support set literals, we no longer
      // need to index dart:collection, as it is only needed for desugaring of
      // const sets. We can remove it from this list at that time.
      read(Uri.parse("dart:collection"), 0, accessor: first);
      assert(_coreLibrary != null);
    }
  }

  Future<Null> buildBodies() async {
    assert(_coreLibrary != null);
    for (LibraryBuilder library in builders.values) {
      if (library.loader == this) {
        currentUriForCrashReporting = library.importUri;
        await buildBody(library);
      }
    }
    currentUriForCrashReporting = null;
    logSummary(templateSourceBodySummary);
  }

  Future<Null> buildOutlines() async {
    ensureCoreLibrary();
    while (unparsedLibraries.isNotEmpty) {
      LibraryBuilder library = unparsedLibraries.removeFirst();
      currentUriForCrashReporting = library.importUri;
      await buildOutline(library);
    }
    currentUriForCrashReporting = null;
    logSummary(outlineSummaryTemplate);
  }

  void logSummary(Template<SummaryTemplate> template) {
    ticker.log((Duration elapsed, Duration sinceStart) {
      int libraryCount = 0;
      for (LibraryBuilder library in builders.values) {
        if (library.loader == this) libraryCount++;
      }
      double ms = elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;
      Message message = template.withArguments(
          libraryCount, byteCount, ms, byteCount / ms, ms / libraryCount);
      print("$sinceStart: ${message.message}");
    });
  }

  Future<Null> buildOutline(covariant LibraryBuilder library);

  /// Builds all the method bodies found in the given [library].
  Future<Null> buildBody(covariant LibraryBuilder library);

  /// Register [message] as a problem with a severity determined by the
  /// intrinsic severity of the message.
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
message: ${message.message}
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

  ClassBuilder computeClassBuilderFromTargetClass(Class cls);

  TypeBuilder computeTypeBuilder(DartType type);

  BodyBuilder createBodyBuilderForOutlineExpression(
      src.SourceLibraryBuilder library,
      DeclarationBuilder? declarationBuilder,
      ModifierBuilder member,
      Scope scope,
      Uri fileUri) {
    return new BodyBuilder.forOutlineExpression(
        library, declarationBuilder, member, scope, fileUri);
  }
}
