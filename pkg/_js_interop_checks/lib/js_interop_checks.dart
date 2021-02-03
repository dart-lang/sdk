// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        messageJsInteropAnonymousFactoryPositionalParameters,
        messageJsInteropEnclosingClassJSAnnotation,
        messageJsInteropEnclosingClassJSAnnotationContext,
        messageJsInteropExternalMemberNotJSAnnotated,
        messageJsInteropIndexNotSupported,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor,
        messageJsInteropNonExternalMember,
        templateJsInteropDartClassExtendsJSClass,
        templateJsInteropJSClassExtendsDartClass,
        templateJsInteropNativeClassInAnnotation;

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor<void> {
  final CoreTypes _coreTypes;
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticsReporter;
  final Map<String, Class> _nativeClasses;
  bool _classHasJSAnnotation = false;
  bool _classHasAnonymousAnnotation = false;
  bool _libraryHasJSAnnotation = false;

  /// Libraries that use `external` to exclude from checks on external.
  static final Iterable<String> _pathsWithAllowedDartExternalUsage = <String>[
    '_foreign_helper', // for foreign helpers
    '_interceptors', // for ddc JS string
    '_native_typed_data',
    '_runtime', // for ddc types at runtime
    'async',
    'core', // for environment constructors
    'html',
    'html_common',
    'indexed_db',
    'js',
    'js_util',
    'svg',
    'web_audio',
    'web_gl',
    'web_sql'
  ];

  /// Native tests to exclude from checks on external.
  // TODO(rileyporter): Use ExternalName from CFE to exclude native tests.
  List<Pattern> _allowedNativeTestPatterns = [
    RegExp(r'(?<!generated_)tests/dart2js/native'),
    RegExp(r'(?<!generated_)tests/dart2js/internal'),
    'generated_tests/dart2js/native/native_test',
    RegExp(r'(?<!generated_)tests/dart2js_2/native'),
    RegExp(r'(?<!generated_)tests/dart2js_2/internal'),
    'generated_tests/dart2js_2/native/native_test',
  ];

  bool _libraryIsGlobalNamespace = false;
  // TODO(srujzs): This currently disables this check always. This check should
  // instead only be disabled up until a given language version.
  bool _disableJSNativeClassConflict = true;

  JsInteropChecks(
      this._coreTypes, this._diagnosticsReporter, this._nativeClasses);

  /// Extract all native class names from the [component].
  ///
  /// Returns a map from the name to the underlying Class node. This is a
  /// static method so that the result can be cached in the corresponding
  /// compiler target.
  static Map<String, Class> getNativeClasses(Component component) {
    Map<String, Class> nativeClasses = {};
    for (var library in component.libraries) {
      for (var cls in library.classes) {
        var nativeNames = getNativeNames(cls);
        for (var nativeName in nativeNames) {
          nativeClasses[nativeName] = cls;
        }
      }
    }
    return nativeClasses;
  }

  @override
  void defaultMember(Member member) {
    _checkJSInteropAnnotation(member);
    // TODO(43530): Disallow having JS interop annotations on non-external
    // members (class members or otherwise). Currently, they're being ignored.
    super.defaultMember(member);
  }

  @override
  void visitClass(Class cls) {
    _classHasJSAnnotation = hasJSInteropAnnotation(cls);
    _classHasAnonymousAnnotation = hasAnonymousAnnotation(cls);
    var superclass = cls.superclass;
    if (superclass != null && superclass != _coreTypes.objectClass) {
      var superHasJSAnnotation = hasJSInteropAnnotation(superclass);
      if (_classHasJSAnnotation && !superHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropJSClassExtendsDartClass.withArguments(
                cls.name, superclass.name),
            cls.fileOffset,
            cls.name.length,
            cls.location.file);
      } else if (!_classHasJSAnnotation && superHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropDartClassExtendsJSClass.withArguments(
                cls.name, superclass.name),
            cls.fileOffset,
            cls.name.length,
            cls.location.file);
      }
    }
    if (!_disableJSNativeClassConflict &&
        _classHasJSAnnotation &&
        !_classHasAnonymousAnnotation &&
        _libraryIsGlobalNamespace) {
      var jsClass = getJSName(cls);
      if (jsClass.isEmpty) {
        // No rename, take the name of the class directly.
        jsClass = cls.name;
      } else {
        // Remove any global prefixes. Regex here is greedy and will only return
        // a value for `className` that doesn't start with 'self.' or 'window.'.
        var classRegexp = new RegExp(r'^((self|window)\.)*(?<className>.*)$');
        var matches = classRegexp.allMatches(jsClass);
        jsClass = matches.first.namedGroup('className');
      }
      if (_nativeClasses.containsKey(jsClass)) {
        var nativeClass = _nativeClasses[jsClass];
        _diagnosticsReporter.report(
            templateJsInteropNativeClassInAnnotation.withArguments(
                cls.name,
                nativeClass.name,
                nativeClass.enclosingLibrary.importUri.toString()),
            cls.fileOffset,
            cls.name.length,
            cls.location.file);
      }
    }
    super.visitClass(cls);
    _classHasAnonymousAnnotation = false;
    _classHasJSAnnotation = false;
  }

  @override
  void visitLibrary(Library lib) {
    _libraryHasJSAnnotation = hasJSInteropAnnotation(lib);
    _libraryIsGlobalNamespace = false;
    if (_libraryHasJSAnnotation) {
      var libraryAnnotation = getJSName(lib);
      var globalRegexp = new RegExp(r'^(self|window)(\.(self|window))*$');
      if (libraryAnnotation.isEmpty ||
          globalRegexp.hasMatch(libraryAnnotation)) {
        _libraryIsGlobalNamespace = true;
      }
    } else {
      _libraryIsGlobalNamespace = true;
    }
    super.visitLibrary(lib);
    _libraryIsGlobalNamespace = false;
    _libraryHasJSAnnotation = false;
  }

  @override
  void visitProcedure(Procedure procedure) {
    _checkJSInteropAnnotation(procedure);
    if (_classHasJSAnnotation && !procedure.isExternal) {
      // If not one of few exceptions, member is not allowed to exclude
      // `external` inside of a JS interop class.
      if (!(procedure.isAbstract ||
          procedure.isFactory ||
          procedure.isStatic)) {
        _diagnosticsReporter.report(
            messageJsInteropNonExternalMember,
            procedure.fileOffset,
            procedure.name.text.length,
            procedure.location.file);
      }
    }
    if (!_isJSInteropMember(procedure)) return;

    if (!procedure.isStatic &&
        (procedure.name.text == '[]=' || procedure.name.text == '[]')) {
      _diagnosticsReporter.report(
          messageJsInteropIndexNotSupported,
          procedure.fileOffset,
          procedure.name.text.length,
          procedure.location.file);
    }

    var isAnonymousFactory =
        _classHasAnonymousAnnotation && procedure.isFactory;

    if (isAnonymousFactory) {
      if (procedure.function != null &&
          !procedure.function.positionalParameters.isEmpty) {
        var firstPositionalParam = procedure.function.positionalParameters[0];
        _diagnosticsReporter.report(
            messageJsInteropAnonymousFactoryPositionalParameters,
            firstPositionalParam.fileOffset,
            firstPositionalParam.name.length,
            firstPositionalParam.location.file);
      }
    } else {
      // Only factory constructors for anonymous classes are allowed to have
      // named parameters.
      _checkNoNamedParameters(procedure.function);
    }
  }

  @override
  void visitConstructor(Constructor constructor) {
    _checkJSInteropAnnotation(constructor);
    if (_classHasJSAnnotation &&
        !constructor.isExternal &&
        !constructor.isSynthetic) {
      // Non-synthetic constructors must be annotated with `external`.
      _diagnosticsReporter.report(
          messageJsInteropNonExternalConstructor,
          constructor.fileOffset,
          constructor.name.text.length,
          constructor.location.file);
    }
    if (!_isJSInteropMember(constructor)) return;

    _checkNoNamedParameters(constructor.function);
  }

  /// Reports an error if [functionNode] has named parameters.
  void _checkNoNamedParameters(FunctionNode functionNode) {
    if (functionNode != null && !functionNode.namedParameters.isEmpty) {
      var firstNamedParam = functionNode.namedParameters[0];
      _diagnosticsReporter.report(
          messageJsInteropNamedParameters,
          firstNamedParam.fileOffset,
          firstNamedParam.name.length,
          firstNamedParam.location.file);
    }
  }

  /// Reports an error if [member] does not correctly use the JS interop
  /// annotation or the keyword `external`.
  void _checkJSInteropAnnotation(Member member) {
    var enclosingClass = member.enclosingClass;

    if (!_classHasJSAnnotation &&
        enclosingClass != null &&
        hasJSInteropAnnotation(member)) {
      // If in a class that is not JS interop, this member is not allowed to be
      // JS interop.
      _diagnosticsReporter.report(messageJsInteropEnclosingClassJSAnnotation,
          member.fileOffset, member.name.text.length, member.location.file,
          context: <LocatedMessage>[
            messageJsInteropEnclosingClassJSAnnotationContext.withLocation(
                enclosingClass.location.file,
                enclosingClass.fileOffset,
                enclosingClass.name.length)
          ]);
    }

    // Check for correct `external` usage.
    if (member.isExternal &&
        !_isAllowedExternalUsage(member) &&
        !hasJSInteropAnnotation(member)) {
      if (member.enclosingClass != null && !_classHasJSAnnotation ||
          member.enclosingClass == null && !_libraryHasJSAnnotation) {
        _diagnosticsReporter.report(
            messageJsInteropExternalMemberNotJSAnnotated,
            member.fileOffset,
            member.name.text.length,
            member.location.file);
      }
    }
  }

  /// Verifies given member is one of the allowed usages of external:
  /// a dart low level library, a foreign helper, a native test,
  /// or a from environment constructor.
  bool _isAllowedExternalUsage(Member member) {
    Uri uri = member.enclosingLibrary.importUri;
    return uri.scheme == 'dart' &&
            _pathsWithAllowedDartExternalUsage.contains(uri.path) ||
        _allowedNativeTestPatterns.any((pattern) => uri.path.contains(pattern));
  }

  /// Returns whether [member] is considered to be a JS interop member.
  bool _isJSInteropMember(Member member) {
    if (member.isExternal) {
      if (_classHasJSAnnotation) return true;
      if (member.enclosingClass == null) {
        // In the case where the member does not belong to any class, a JS
        // annotation is not needed on the library to be considered JS interop
        // as long as the member has an annotation.
        return hasJSInteropAnnotation(member) || _libraryHasJSAnnotation;
      }
    }

    // Otherwise, not JS interop.
    return false;
  }
}
