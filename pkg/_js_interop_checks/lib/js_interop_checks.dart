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
        messageJsInteropExternalExtensionMemberOnTypeInvalid,
        messageJsInteropExternalMemberNotJSAnnotated,
        messageJsInteropIndexNotSupported,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor,
        messageJsInteropNonExternalMember,
        templateJsInteropDartClassExtendsJSClass,
        templateJsInteropStaticInteropWithInstanceMembers,
        templateJsInteropStaticInteropWithNonStaticSupertype,
        templateJsInteropJSClassExtendsDartClass,
        templateJsInteropNativeClassInAnnotation;

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor {
  final CoreTypes _coreTypes;
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticsReporter;
  final Map<String, Class> _nativeClasses;
  bool _classHasJSAnnotation = false;
  bool _classHasAnonymousAnnotation = false;
  bool _classHasStaticInteropAnnotation = false;
  bool _libraryHasJSAnnotation = false;
  Map<Reference, Extension>? _libraryExtensionsIndex;

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
    RegExp(r'(?<!generated_)tests/web/native'),
    RegExp(r'(?<!generated_)tests/web/internal'),
    'generated_tests/web/native/native_test',
    RegExp(r'(?<!generated_)tests/web_2/native'),
    RegExp(r'(?<!generated_)tests/web_2/internal'),
    'generated_tests/web_2/native/native_test',
  ];

  bool _libraryIsGlobalNamespace = false;

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
    _checkInstanceMemberJSAnnotation(member);
    if (!_isJSInteropMember(member)) _checkDisallowedExternal(member);
    // TODO(43530): Disallow having JS interop annotations on non-external
    // members (class members or otherwise). Currently, they're being ignored.
    super.defaultMember(member);
  }

  @override
  void visitClass(Class cls) {
    _classHasJSAnnotation = hasJSInteropAnnotation(cls);
    _classHasAnonymousAnnotation = hasAnonymousAnnotation(cls);
    _classHasStaticInteropAnnotation = hasStaticInteropAnnotation(cls);
    var superclass = cls.superclass;
    if (superclass != null && superclass != _coreTypes.objectClass) {
      var superHasJSAnnotation = hasJSInteropAnnotation(superclass);
      if (_classHasJSAnnotation && !superHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropJSClassExtendsDartClass.withArguments(
                cls.name, superclass.name),
            cls.fileOffset,
            cls.name.length,
            cls.fileUri);
      } else if (!_classHasJSAnnotation && superHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropDartClassExtendsJSClass.withArguments(
                cls.name, superclass.name),
            cls.fileOffset,
            cls.name.length,
            cls.fileUri);
      } else if (_classHasStaticInteropAnnotation) {
        if (!hasStaticInteropAnnotation(superclass)) {
          _diagnosticsReporter.report(
              templateJsInteropStaticInteropWithNonStaticSupertype
                  .withArguments(cls.name, superclass.name),
              cls.fileOffset,
              cls.name.length,
              cls.fileUri);
        }
      }
    }
    // Validate that superinterfaces are all annotated as static as well. Note
    // that mixins are already disallowed and therefore are not checked here.
    if (_classHasStaticInteropAnnotation) {
      for (var supertype in cls.implementedTypes) {
        if (!hasStaticInteropAnnotation(supertype.classNode)) {
          _diagnosticsReporter.report(
              templateJsInteropStaticInteropWithNonStaticSupertype
                  .withArguments(cls.name, supertype.classNode.name),
              cls.fileOffset,
              cls.name.length,
              cls.fileUri);
        }
      }
    }
    // Since this is a breaking check, it is language-versioned.
    if (cls.enclosingLibrary.languageVersion >= Version(2, 13) &&
        _classHasJSAnnotation &&
        !_classHasStaticInteropAnnotation &&
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
        jsClass = matches.first.namedGroup('className')!;
      }
      var nativeClass = _nativeClasses[jsClass];
      if (nativeClass != null) {
        _diagnosticsReporter.report(
            templateJsInteropNativeClassInAnnotation.withArguments(
                cls.name,
                nativeClass.name,
                nativeClass.enclosingLibrary.importUri.toString()),
            cls.fileOffset,
            cls.name.length,
            cls.fileUri);
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
    _libraryExtensionsIndex = null;
  }

  @override
  void visitProcedure(Procedure procedure) {
    _checkInstanceMemberJSAnnotation(procedure);
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
            procedure.fileUri);
      }
    }

    if (!_isJSInteropMember(procedure)) {
      _checkDisallowedExternal(procedure);
    } else {
      // Check JS interop indexing.
      if (!procedure.isStatic &&
          (procedure.name.text == '[]=' || procedure.name.text == '[]')) {
        _diagnosticsReporter.report(
            messageJsInteropIndexNotSupported,
            procedure.fileOffset,
            procedure.name.text.length,
            procedure.fileUri);
      }

      // Check JS Interop positional and named parameters.
      var isAnonymousFactory =
          _classHasAnonymousAnnotation && procedure.isFactory;
      if (isAnonymousFactory) {
        // ignore: unnecessary_null_comparison
        if (procedure.function != null &&
            !procedure.function.positionalParameters.isEmpty) {
          var firstPositionalParam = procedure.function.positionalParameters[0];
          _diagnosticsReporter.report(
              messageJsInteropAnonymousFactoryPositionalParameters,
              firstPositionalParam.fileOffset,
              firstPositionalParam.name!.length,
              firstPositionalParam.location!.file);
        }
      } else {
        // Only factory constructors for anonymous classes are allowed to have
        // named parameters.
        _checkNoNamedParameters(procedure.function);
      }
    }

    if (_classHasStaticInteropAnnotation &&
        procedure.isInstanceMember &&
        !procedure.isFactory &&
        !procedure.isSynthetic) {
      _diagnosticsReporter.report(
          templateJsInteropStaticInteropWithInstanceMembers
              .withArguments(procedure.enclosingClass!.name),
          procedure.fileOffset,
          procedure.name.text.length,
          procedure.fileUri);
    }
  }

  @override
  void visitField(Field field) {
    if (_classHasStaticInteropAnnotation && field.isInstanceMember) {
      _diagnosticsReporter.report(
          templateJsInteropStaticInteropWithInstanceMembers
              .withArguments(field.enclosingClass!.name),
          field.fileOffset,
          field.name.text.length,
          field.fileUri);
    }
    super.visitField(field);
  }

  @override
  void visitConstructor(Constructor constructor) {
    _checkInstanceMemberJSAnnotation(constructor);
    if (_classHasJSAnnotation &&
        !constructor.isExternal &&
        !constructor.isSynthetic) {
      // Non-synthetic constructors must be annotated with `external`.
      _diagnosticsReporter.report(
          messageJsInteropNonExternalConstructor,
          constructor.fileOffset,
          constructor.name.text.length,
          constructor.fileUri);
    }

    if (!_isJSInteropMember(constructor)) {
      _checkDisallowedExternal(constructor);
    } else {
      _checkNoNamedParameters(constructor.function);
    }
  }

  /// Reports an error if [functionNode] has named parameters.
  void _checkNoNamedParameters(FunctionNode functionNode) {
    // ignore: unnecessary_null_comparison
    if (functionNode != null && !functionNode.namedParameters.isEmpty) {
      var firstNamedParam = functionNode.namedParameters[0];
      _diagnosticsReporter.report(
          messageJsInteropNamedParameters,
          firstNamedParam.fileOffset,
          firstNamedParam.name!.length,
          firstNamedParam.location!.file);
    }
  }

  /// Reports an error if given instance [member] is JS interop, but inside a
  /// non JS interop class.
  void _checkInstanceMemberJSAnnotation(Member member) {
    var enclosingClass = member.enclosingClass;

    if (!_classHasJSAnnotation &&
        enclosingClass != null &&
        hasJSInteropAnnotation(member)) {
      // If in a class that is not JS interop, this member is not allowed to be
      // JS interop.
      _diagnosticsReporter.report(messageJsInteropEnclosingClassJSAnnotation,
          member.fileOffset, member.name.text.length, member.fileUri,
          context: <LocatedMessage>[
            messageJsInteropEnclosingClassJSAnnotationContext.withLocation(
                enclosingClass.fileUri,
                enclosingClass.fileOffset,
                enclosingClass.name.length)
          ]);
    }
  }

  /// Assumes given [member] is not JS interop, and reports an error if
  /// [member] is `external` and not an allowed `external` usage.
  void _checkDisallowedExternal(Member member) {
    if (member.isExternal) {
      if (member.isExtensionMember) {
        if (!_isNativeExtensionMember(member)) {
          _diagnosticsReporter.report(
              messageJsInteropExternalExtensionMemberOnTypeInvalid,
              member.fileOffset,
              member.name.text.length,
              member.fileUri);
        }
      } else if (!hasJSInteropAnnotation(member) &&
          !_isAllowedExternalUsage(member)) {
        // Member could be JS annotated and not considered a JS interop member
        // if inside a non-JS interop class. Should not report an error in this
        // case, since a different error will already be produced.
        _diagnosticsReporter.report(
            messageJsInteropExternalMemberNotJSAnnotated,
            member.fileOffset,
            member.name.text.length,
            member.fileUri);
      }
    }
  }

  /// Verifies given member is one of the allowed usages of external:
  /// a dart low level library, a foreign helper, a native test,
  /// or a from environment constructor.
  bool _isAllowedExternalUsage(Member member) {
    Uri uri = member.enclosingLibrary.importUri;
    return uri.isScheme('dart') &&
            _pathsWithAllowedDartExternalUsage.contains(uri.path) ||
        _allowedNativeTestPatterns.any((pattern) => uri.path.contains(pattern));
  }

  /// Returns whether [member] is considered to be a JS interop member.
  ///
  /// A JS interop member is `external`, and is in a valid JS interop context,
  /// which can be:
  ///   - inside a JS interop class
  ///   - inside an extension on a JS interop class
  ///   - a top level member that is JS interop annotated or in a JS interop
  ///     library
  /// If a member belongs to a class, the class must be JS interop annotated.
  bool _isJSInteropMember(Member member) {
    if (member.isExternal) {
      if (_classHasJSAnnotation) return true;
      if (member.isExtensionMember) return _isJSExtensionMember(member);
      if (member.enclosingClass == null) {
        return hasJSInteropAnnotation(member) || _libraryHasJSAnnotation;
      }
    }

    // Otherwise, not JS interop.
    return false;
  }

  /// Returns whether given extension [member] is in an extension that is on a
  /// JS interop class.
  bool _isJSExtensionMember(Member member) {
    return _checkExtensionMember(member, hasJSInteropAnnotation);
  }

  /// Returns whether given extension [member] is in an extension on a Native
  /// class.
  bool _isNativeExtensionMember(Member member) {
    return _checkExtensionMember(member, _nativeClasses.containsValue);
  }

  /// Returns whether given extension [member] is on a class that passses the
  /// given [validateExtensionClass].
  bool _checkExtensionMember(Member member, Function validateExtensionClass) {
    assert(member.isExtensionMember);
    if (_libraryExtensionsIndex == null) {
      _libraryExtensionsIndex = {};
      member.enclosingLibrary.extensions.forEach((extension) =>
          extension.members.forEach((memberDescriptor) =>
              _libraryExtensionsIndex![memberDescriptor.member] = extension));
    }

    var onType = _libraryExtensionsIndex![member.reference]!.onType;
    return onType is InterfaceType && validateExtensionClass(onType.classNode);
  }
}
