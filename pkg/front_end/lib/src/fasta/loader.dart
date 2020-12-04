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
        messagePlatformPrivateLibraryAccess,
        templateInternalProblemContextSeverity,
        templateSourceBodySummary;

import 'problems.dart' show internalProblem, unhandled;

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

  LibraryBuilder coreLibrary;

  /// The first library that we've been asked to compile. When compiling a
  /// program (aka script), this is the library that should have a main method.
  LibraryBuilder first;

  int byteCount = 0;

  Uri currentUriForCrashReporting;

  Loader(this.target);

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
      {Uri fileUri,
      LibraryBuilder accessor,
      LibraryBuilder origin,
      Library referencesFrom,
      bool referenceIsPartOwner}) {
    LibraryBuilder builder = builders.putIfAbsent(uri, () {
      if (fileUri != null &&
          (fileUri.scheme == "dart" ||
              fileUri.scheme == "package" ||
              fileUri.scheme == "dart-ext")) {
        fileUri = null;
      }
      Package packageForLanguageVersion;
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
      bool hasPackageSpecifiedLanguageVersion = false;
      Version version;
      Uri packageUri;
      if (packageForLanguageVersion != null) {
        Uri importUri = origin?.importUri ?? uri;
        if (importUri.scheme != 'dart' &&
            importUri.scheme != 'package' &&
            packageForLanguageVersion.name != null) {
          packageUri =
              new Uri(scheme: 'package', path: packageForLanguageVersion.name);
        }
        if (packageForLanguageVersion.languageVersion != null) {
          hasPackageSpecifiedLanguageVersion = true;
          if (packageForLanguageVersion.languageVersion
              is! InvalidLanguageVersion) {
            version = new Version(
                packageForLanguageVersion.languageVersion.major,
                packageForLanguageVersion.languageVersion.minor);
          }
        }
      }
      LibraryBuilder library = target.createLibraryBuilder(uri, fileUri,
          packageUri, origin, referencesFrom, referenceIsPartOwner);
      if (library == null) {
        throw new StateError("createLibraryBuilder for uri $uri, "
            "fileUri $fileUri returned null.");
      }
      if (hasPackageSpecifiedLanguageVersion) {
        library.setLanguageVersion(version, explicit: false);
      }
      if (uri.scheme == "dart" && uri.path == "core") {
        coreLibrary = library;
      }
      if (library.loader != this) {
        if (coreLibrary == library) {
          target.loadExtraRequiredLibraries(this);
        }
        // This library isn't owned by this loader, so not further processing
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
      if (coreLibrary == library) {
        target.loadExtraRequiredLibraries(this);
      }
      if (target.backendTarget
          .mayDefineRestrictedType(origin?.importUri ?? uri)) {
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
    if (coreLibrary == null) {
      read(Uri.parse("dart:core"), 0, accessor: first);
      // TODO(askesc): When all backends support set literals, we no longer
      // need to index dart:collection, as it is only needed for desugaring of
      // const sets. We can remove it from this list at that time.
      read(Uri.parse("dart:collection"), 0, accessor: first);
      assert(coreLibrary != null);
    }
  }

  Future<Null> buildBodies() async {
    assert(coreLibrary != null);
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
      builders.forEach((Uri uri, LibraryBuilder library) {
        if (library.loader == this) libraryCount++;
      });
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
  FormattedMessage addProblem(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity,
      bool problemOnLibrary: false,
      List<Uri> involvedFiles}) {
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
  FormattedMessage addMessage(Message message, int charOffset, int length,
      Uri fileUri, Severity severity,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      bool problemOnLibrary: false,
      List<Uri> involvedFiles}) {
    severity = target.fixSeverity(severity, message, fileUri);
    if (severity == Severity.ignored) return null;
    String trace = """
message: ${message.message}
charOffset: $charOffset
fileUri: $fileUri
severity: $severity
""";
    if (!seenMessages.add(trace)) return null;
    if (message.code.severity == Severity.context) {
      internalProblem(
          templateInternalProblemContextSeverity
              .withArguments(message.code.name),
          charOffset,
          fileUri);
    }
    target.context.report(
        message.withLocation(fileUri, charOffset, length), severity,
        context: context, involvedFiles: involvedFiles);
    if (severity == Severity.error) {
      (wasHandled ? handledErrors : unhandledErrors)
          .add(message.withLocation(fileUri, charOffset, length));
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
      LibraryBuilder library,
      DeclarationBuilder declarationBuilder,
      ModifierBuilder member,
      Scope scope,
      Uri fileUri) {
    return new BodyBuilder.forOutlineExpression(
        library, declarationBuilder, member, scope, fileUri);
  }
}
