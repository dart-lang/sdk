// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        messageDartFfiLibraryInDart2Wasm,
        messageJsInteropDartJsInteropAnnotationForStaticInteropOnly,
        messageJsInteropEnclosingClassJSAnnotation,
        messageJsInteropEnclosingClassJSAnnotationContext,
        messageJsInteropExtensionTypeMemberNotInterop,
        messageJsInteropExtensionTypeUsedWithWrongJsAnnotation,
        messageJsInteropExternalExtensionMemberOnTypeInvalid,
        messageJsInteropExternalExtensionMemberWithStaticDisallowed,
        messageJsInteropExternalMemberNotJSAnnotated,
        messageJsInteropFunctionToJSTypeParameters,
        messageJsInteropInvalidStaticClassMemberName,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor,
        messageJsInteropNonExternalMember,
        messageJsInteropOperatorCannotBeRenamed,
        messageJsInteropOperatorsNotSupported,
        messageJsInteropStaticInteropGenerativeConstructor,
        messageJsInteropStaticInteropParameterInitializersAreIgnored,
        messageJsInteropStaticInteropSyntheticConstructor,
        templateJsInteropDartClassExtendsJSClass,
        templateJsInteropDisallowedInteropLibraryInDart2Wasm,
        templateJsInteropJSClassExtendsDartClass,
        templateJsInteropNonStaticWithStaticInteropSupertype,
        templateJsInteropStaticInteropNoJSAnnotation,
        templateJsInteropStaticInteropWithInstanceMembers,
        templateJsInteropStaticInteropWithNonStaticSupertype,
        templateJsInteropObjectLiteralConstructorPositionalParameters,
        templateJsInteropNativeClassInAnnotation,
        templateJsInteropStaticInteropTearOffsDisallowed,
        templateJsInteropStaticInteropTrustTypesUsageNotAllowed,
        templateJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop;
import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_js_interop_checks/src/transformations/export_checker.dart';
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart';
// Used for importing CFE utility functions for constructor tear-offs.
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/fasta/codes/fasta_codes.dart'
    show
        templateJsInteropExtensionTypeNotInterop,
        templateJsInteropFunctionToJSRequiresStaticType,
        templateJsInteropStaticInteropExternalAccessorTypeViolation,
        templateJsInteropStaticInteropExternalFunctionTypeViolation,
        templateJsInteropStaticInteropToJSFunctionTypeViolation;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide Pattern;
import 'package:kernel/src/printer.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor {
  final Set<Constant> _constantCache = {};
  final CoreTypes _coreTypes;
  late final ExtensionIndex extensionIndex;
  final Procedure _functionToJSTarget;
  // Errors on constants need source information, so we use the surrounding
  // `ConstantExpression` as the source.
  ConstantExpression? _lastConstantExpression;
  final Map<String, Class> _nativeClasses;
  final JsInteropDiagnosticReporter _reporter;
  final StatefulStaticTypeContext _staticTypeContext;
  final AstTextStrategy _textStrategy = const AstTextStrategy(
      showNullableOnly: true, useQualifiedTypeParameterNames: false);

  bool _classHasJSAnnotation = false;
  bool _classHasAnonymousAnnotation = false;
  bool _classHasStaticInteropAnnotation = false;
  bool _inTearoff = false;
  bool _libraryHasDartJSInteropAnnotation = false;
  bool _libraryHasJSAnnotation = false;
  bool _libraryIsGlobalNamespace = false;

  final ExportChecker exportChecker;
  final bool isDart2Wasm;

  /// Native tests to exclude from checks on external.
  // TODO(rileyporter): Use ExternalName from CFE to exclude native tests.
  static final List<Pattern> _allowedNativeTestPatterns = [
    RegExp(r'(?<!generated_)tests/web/native'),
    RegExp(r'(?<!generated_)tests/web/internal'),
    'generated_tests/web/native/native_test',
  ];

  static final List<Pattern> _allowedTrustTypesTestPatterns = [
    RegExp(r'(?<!generated_)tests/lib/js'),
  ];

  static final List<Pattern>
      _allowedUseOfDart2WasmDisallowedInteropLibrariesTestPatterns = [
    // Benchmarks.
    RegExp(r'BigIntParsePrint/dart/native_version_javascript.dart'),
    RegExp(r'JSInterop/dart/jsinterop_lib.dart'),
    // Tests.
    RegExp(r'(?<!generated_)tests/lib/js/export'),
    // Negative lookahead to test the violation.
    RegExp(
        r'(?<!generated_)tests/lib/js/static_interop_test(?!/disallowed_interop_libraries_test.dart)'),
    RegExp(r'(?<!generated_)tests/web/wasm'),
    // Flutter tests.
    RegExp(r'flutter/lib/web_ui/test'),
  ];

  // TODO(srujzs): Help migrate some of these away. Once we're done, we can
  // remove `dart:*` interop libraries from the check as they can be moved out
  // of `libraries.json`.
  static const _allowedInteropLibrariesInDart2WasmPackages = [
    // Both these packages re-export other interop libraries
    'js',
    'js_util',
    // Flutter/benchmarks.
    'flutter',
    'engine',
    'ui',
    // Non-SDK packages that have been migrated for the Wasm experiment but
    // still have references to older interop libraries.
    'package_info_plus',
    'test',
    'url_launcher_web',
  ];

  /// Interop libraries that cannot be used in dart2wasm.
  static const _disallowedInteropLibrariesInDart2Wasm = [
    'package:js/js.dart',
    'package:js/js_util.dart',
    'dart:js_util',
    'dart:js',
    'dart:ffi',
  ];

  /// Libraries that use `external` to exclude from checks on external.
  static const Iterable<String> _pathsWithAllowedDartExternalUsage = <String>[
    '_foreign_helper', // for foreign helpers
    '_late_helper', // for dart2js late variable utilities
    '_interceptors', // for ddc JS string
    '_native_typed_data',
    '_runtime', // for ddc types at runtime
    '_js_helper', // for ddc inlined helper methods
    'async',
    'core', // for environment constructors
    'html',
    'html_common',
    'indexed_db',
    'js',
    'js_interop',
    'js_util',
    'svg',
    'web_audio',
    'web_gl',
    'web_sql'
  ];

  JsInteropChecks(this._coreTypes, ClassHierarchy hierarchy, this._reporter,
      this._nativeClasses,
      {this.isDart2Wasm = false})
      : exportChecker = ExportChecker(_reporter, _coreTypes.objectClass),
        _functionToJSTarget = _coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {
    extensionIndex =
        ExtensionIndex(_coreTypes, _staticTypeContext.typeEnvironment);
  }

  /// Determines if given [member] is an external extension member that needs to
  /// be patched instead of lowered.
  static bool isPatchedMember(Member member) =>
      member.isExternal && hasPatchAnnotation(member);

  /// Extract all native class names from the [component].
  ///
  /// Returns a map from the name to the underlying Class node. This is a
  /// static method so that the result can be cached in the corresponding
  /// compiler target.
  static Map<String, Class> getNativeClasses(Component component) {
    final nativeClasses = <String, Class>{};
    for (final library in component.libraries) {
      for (final cls in library.classes) {
        final nativeNames = getNativeNames(cls);
        for (final nativeName in nativeNames) {
          nativeClasses[nativeName] = cls;
        }
      }
    }
    return nativeClasses;
  }

  @override
  void defaultMember(Member node) {
    _staticTypeContext.enterMember(node);
    _checkInstanceMemberJSAnnotation(node);
    if (!_isJSInteropMember(node)) _checkDisallowedExternal(node);
    // TODO(43530): Disallow having JS interop annotations on non-external
    // members (class members or otherwise). Currently, they're being ignored.
    exportChecker.visitMember(node);
    super.defaultMember(node);
    _staticTypeContext.leaveMember(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (hasPackageJSAnnotation(node)) {
      _reporter.report(messageJsInteropExtensionTypeUsedWithWrongJsAnnotation,
          node.fileOffset, node.name.length, node.fileUri);
    }
    if (hasDartJSInteropAnnotation(node) &&
        !extensionIndex.isInteropExtensionType(node)) {
      _reporter.report(
          templateJsInteropExtensionTypeNotInterop.withArguments(
              node.name, node.declaredRepresentationType),
          node.fileOffset,
          node.name.length,
          node.fileUri);
    }
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitClass(Class node) {
    _classHasJSAnnotation = hasJSInteropAnnotation(node);
    _classHasAnonymousAnnotation = hasAnonymousAnnotation(node);
    _classHasStaticInteropAnnotation = hasStaticInteropAnnotation(node);

    void report(Message message) => _reporter.report(
        message, node.fileOffset, node.name.length, node.fileUri);

    // @JS checks.
    var superclass = node.superclass;
    // Ignore the superclass if it is trivial.
    if (superclass == _coreTypes.objectClass) superclass = null;
    if (_classHasJSAnnotation) {
      if (!_classHasAnonymousAnnotation &&
          !_classHasStaticInteropAnnotation &&
          _libraryIsGlobalNamespace) {
        _checkJsInteropClassNotUsingNativeClass(node);
      }
      if (superclass != null && !hasJSInteropAnnotation(superclass)) {
        report(templateJsInteropJSClassExtendsDartClass.withArguments(
            node.name, superclass.name));
      }
    } else {
      if (superclass != null && hasJSInteropAnnotation(superclass)) {
        report(templateJsInteropDartClassExtendsJSClass.withArguments(
            node.name, superclass.name));
      }
    }

    // @staticInterop checks
    if (_classHasStaticInteropAnnotation) {
      if (!_classHasJSAnnotation) {
        report(templateJsInteropStaticInteropNoJSAnnotation
            .withArguments(node.name));
      }
      if (superclass != null && !hasStaticInteropAnnotation(superclass)) {
        report(templateJsInteropStaticInteropWithNonStaticSupertype
            .withArguments(node.name, superclass.name));
      }
      // Validate that superinterfaces are all valid supertypes as well. Note
      // that mixins are already disallowed and therefore are not checked here.
      for (final supertype in node.implementedTypes) {
        if (!hasStaticInteropAnnotation(supertype.classNode)) {
          report(templateJsInteropStaticInteropWithNonStaticSupertype
              .withArguments(node.name, supertype.classNode.name));
        }
      }
    } else {
      // For classes, `dart:js_interop`'s `@JS` can only be used with
      // `@staticInterop`.
      if (hasDartJSInteropAnnotation(node)) {
        report(messageJsInteropDartJsInteropAnnotationForStaticInteropOnly);
      }
      if (superclass != null && hasStaticInteropAnnotation(superclass)) {
        report(templateJsInteropNonStaticWithStaticInteropSupertype
            .withArguments(node.name, superclass.name));
      }
      // The converse of the above. If the class is not marked as static, it
      // should not implement a class that is.
      for (final supertype in node.implementedTypes) {
        if (hasStaticInteropAnnotation(supertype.classNode)) {
          report(templateJsInteropNonStaticWithStaticInteropSupertype
              .withArguments(node.name, supertype.classNode.name));
        }
      }
    }

    // @trustTypes checks.
    if (hasTrustTypesAnnotation(node)) {
      if (!_isAllowedTrustTypesUsage(node)) {
        report(templateJsInteropStaticInteropTrustTypesUsageNotAllowed
            .withArguments(node.name));
      }
      if (!_classHasStaticInteropAnnotation) {
        report(templateJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop
            .withArguments(node.name));
      }
    }

    super.visitClass(node);
    // Validate `@JSExport` usage after so we know if the members have the
    // annotation.
    exportChecker.visitClass(node);
    _classHasStaticInteropAnnotation = false;
    _classHasAnonymousAnnotation = false;
    _classHasJSAnnotation = false;
  }

  @override
  void visitLibrary(Library node) {
    _staticTypeContext.enterLibrary(node);
    _libraryHasDartJSInteropAnnotation = hasDartJSInteropAnnotation(node);
    _libraryHasJSAnnotation =
        _libraryHasDartJSInteropAnnotation || hasJSInteropAnnotation(node);
    _libraryIsGlobalNamespace = _isLibraryGlobalNamespace(node);

    if (isDart2Wasm) _checkDisallowedLibrariesForDart2Wasm(node);

    super.visitLibrary(node);
    exportChecker.visitLibrary(node);
    _staticTypeContext.leaveLibrary(node);
  }

  @override
  void visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    _inTearoff = isTearOffLowering(node);

    void report(Message message) => _reporter.report(
        message, node.fileOffset, node.name.text.length, node.fileUri);

    _checkInstanceMemberJSAnnotation(node);
    if (_classHasJSAnnotation &&
        !node.isExternal &&
        !node.isAbstract &&
        !node.isFactory &&
        !node.isStatic) {
      // If not one of few exceptions, member is not allowed to exclude
      // `external` inside of a JS interop class.
      report(messageJsInteropNonExternalMember);
    }

    if (!_isJSInteropMember(node)) {
      _checkDisallowedExternal(node);
    } else {
      _checkJsInteropOperator(node);

      // Check JS Interop positional and named parameters. Literal constructors
      // can only have named parameters, and every other interop member can only
      // have positional parameters.
      final isObjectLiteralConstructor = node.isExtensionTypeMember &&
          (extensionIndex.getExtensionTypeDescriptor(node)!.kind ==
                  ExtensionTypeMemberKind.Constructor ||
              extensionIndex.getExtensionTypeDescriptor(node)!.kind ==
                  ExtensionTypeMemberKind.Factory) &&
          node.function.namedParameters.isNotEmpty;
      final isAnonymousFactory = _classHasAnonymousAnnotation && node.isFactory;
      if (isObjectLiteralConstructor || isAnonymousFactory) {
        _checkLiteralConstructorHasNoPositionalParams(node,
            isAnonymousFactory: isAnonymousFactory);
      } else {
        _checkNoNamedParameters(node.function);
      }

      // JS static methods cannot use a JS name with dots.
      if (node.isStatic &&
          node.enclosingClass != null &&
          getJSName(node).contains('.')) {
        report(messageJsInteropInvalidStaticClassMemberName);
      }

      if (_classHasStaticInteropAnnotation ||
          node.isExtensionTypeMember ||
          node.isExtensionMember ||
          node.enclosingClass == null &&
              (hasDartJSInteropAnnotation(node) ||
                  _libraryHasDartJSInteropAnnotation)) {
        _checkNoParamInitializersForStaticInterop(node.function);
        final Annotatable? annotatable;
        if (node.isExtensionTypeMember) {
          annotatable = extensionIndex.getExtensionType(node);
        } else if (node.isExtensionMember) {
          annotatable = extensionIndex.getExtensionAnnotatable(node);
          if (annotatable != null) {
            // We do not support external extension members with the 'static'
            // keyword currently.
            if (extensionIndex.getExtensionDescriptor(node)!.isStatic) {
              report(
                  messageJsInteropExternalExtensionMemberWithStaticDisallowed);
            }
          }
        } else {
          annotatable = node.enclosingClass;
        }
        if (!isPatchedMember(node)) {
          if (annotatable == null ||
              ((hasDartJSInteropAnnotation(annotatable) ||
                  annotatable is ExtensionTypeDeclaration))) {
            // Checks for dart:js_interop APIs only.
            _reportExternalProcedureIfNotAllowedFunctionType(node);
          }
        }
      }
    }

    if (_classHasStaticInteropAnnotation &&
        node.isInstanceMember &&
        !node.isFactory &&
        !node.isSynthetic) {
      report(templateJsInteropStaticInteropWithInstanceMembers
          .withArguments(node.enclosingClass!.name));
    }

    super.visitProcedure(node);
    _inTearoff = false;
    _staticTypeContext.leaveMember(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    final target = node.target;
    if (target == _functionToJSTarget) {
      _checkFunctionToJSCall(node);
    } else {
      // Only check generated tear-offs in StaticInvocations.
      final tornOff = _getTornOffFromGeneratedTearOff(target);
      if (tornOff != null) _checkDisallowedTearoff(tornOff, node);
    }
    super.visitStaticInvocation(node);
  }

  @override
  void visitField(Field node) {
    if (_classHasStaticInteropAnnotation && node.isInstanceMember) {
      _reporter.report(
          templateJsInteropStaticInteropWithInstanceMembers
              .withArguments(node.enclosingClass!.name),
          node.fileOffset,
          node.name.text.length,
          node.fileUri);
    }
    super.visitField(node);
  }

  @override
  void visitConstructor(Constructor node) {
    void report(Message message) => _reporter.report(
        message, node.fileOffset, node.name.text.length, node.fileUri);

    _checkInstanceMemberJSAnnotation(node);
    if (!node.isSynthetic) {
      if (_classHasJSAnnotation && !node.isExternal) {
        // Non-synthetic constructors must be annotated with `external`.
        report(messageJsInteropNonExternalConstructor);
      }
      if (_classHasStaticInteropAnnotation) {
        // Can only have factory constructors on @staticInterop classes.
        report(messageJsInteropStaticInteropGenerativeConstructor);
      }
    }

    if (!_isJSInteropMember(node)) {
      _checkDisallowedExternal(node);
    } else {
      _checkNoNamedParameters(node.function);
    }
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    final constructor = node.target;
    if (constructor.isSynthetic &&
        // Synthetic tear-offs are created for synthetic constructors by
        // invoking them, so they need to be excluded here.
        !_inTearoff &&
        hasStaticInteropAnnotation(constructor.enclosingClass)) {
      _reporter.report(messageJsInteropStaticInteropSyntheticConstructor,
          node.fileOffset, node.name.text.length, node.location?.file);
    }
    super.visitConstructorInvocation(node);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    _lastConstantExpression = node;
    node.constant.acceptReference(this);
    _lastConstantExpression = null;
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    _checkDisallowedTearoff(
        _getTornOffFromGeneratedTearOff(node.target) ?? node.target, node);
  }

  @override
  void defaultConstantReference(Constant node) {
    if (_constantCache.add(node)) {
      node.visitChildren(this);
    }
  }

  @override
  void visitStaticTearOffConstantReference(StaticTearOffConstant node) {
    if (_constantCache.contains(node)) return;
    if (_checkDisallowedTearoff(
        _getTornOffFromGeneratedTearOff(node.target) ?? node.target,
        _lastConstantExpression)) {
      return;
    }
    // Only add to the cache if we don't find an error. This is to make sure
    // that multiple usages of the same constant can be caught if it's
    // disallowed.
    _constantCache.add(node);
  }

  // TODO(srujzs): Helper functions are organized according to node types, but
  // it would be nice to get nominal separation instead of just comments.
  // Extensions on the node types don't work well because there is a lot of
  // state that these helpers use. Mixins probably won't work well for a similar
  // reason. It's possible that named extensions on the visitor itself would
  // work.

  // JS interop library checks

  /// Check that [node] doesn't depend on any disallowed interop libraries in
  /// dart2wasm.
  ///
  /// We allowlist `dart:*` libraries, select packages, and test patterns.
  void _checkDisallowedLibrariesForDart2Wasm(Library node) {
    final uri = node.importUri;
    for (final dependency in node.dependencies) {
      final dependencyUriString = dependency.targetLibrary.importUri.toString();
      if (_disallowedInteropLibrariesInDart2Wasm
          .contains(dependencyUriString)) {
        // TODO(srujzs): While we allow these imports for all `dart:*`
        // libraries, we may want to restrict this further, as it may include
        // `dart:ui`.
        final allowedToImport = uri.isScheme('dart') ||
            (uri.isScheme('package') &&
                _allowedInteropLibrariesInDart2WasmPackages
                    .any((pkg) => uri.pathSegments.first == pkg)) ||
            _allowedUseOfDart2WasmDisallowedInteropLibrariesTestPatterns
                .any((pattern) => uri.path.contains(pattern));
        if (allowedToImport) return;
        final message = dependencyUriString == 'dart:ffi'
            ? messageDartFfiLibraryInDart2Wasm
            : templateJsInteropDisallowedInteropLibraryInDart2Wasm
                .withArguments(dependencyUriString);
        _reporter.report(message, dependency.fileOffset,
            dependencyUriString.length, node.fileUri);
      }
    }
  }

  /// Compute whether top-level nodes under [node] would be using the global
  /// JS namespace.
  bool _isLibraryGlobalNamespace(Library node) {
    if (_libraryHasJSAnnotation) {
      final libraryAnnotation = getJSName(node);
      final globalRegexp = RegExp(r'^(self|window)(\.(self|window))*$');
      if (libraryAnnotation.isEmpty ||
          globalRegexp.hasMatch(libraryAnnotation)) {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  // JS interop class checks

  /// Verifies that use of `@trustTypes` is allowed on [cls].
  bool _isAllowedTrustTypesUsage(Class cls) {
    final uri = cls.enclosingLibrary.importUri;
    return uri.isScheme('dart') && uri.path == 'ui' ||
        _allowedTrustTypesTestPatterns
            .any((pattern) => uri.path.contains(pattern));
  }

  /// Check that JS interop class [node], that only has an @JS annotation, is
  /// not bound to a type that is reserved by a @Native type.
  ///
  /// Trying to interop those types without @staticInterop results in errors.
  void _checkJsInteropClassNotUsingNativeClass(Class node) {
    // Since this is a breaking check, it is language-versioned.
    if (node.enclosingLibrary.languageVersion >= Version(2, 13)) {
      var jsClass = getJSName(node);
      if (jsClass.isEmpty) {
        // No rename, take the name of the class directly.
        jsClass = node.name;
      } else {
        // Remove any global prefixes. Regex here is greedy and will only return
        // a value for `className` that doesn't start with 'self.' or 'window.'.
        final classRegexp = RegExp(r'^((self|window)\.)*(?<className>.*)$');
        final matches = classRegexp.allMatches(jsClass);
        jsClass = matches.first.namedGroup('className')!;
      }
      final nativeClass = _nativeClasses[jsClass];
      if (nativeClass != null) {
        _reporter.report(
            templateJsInteropNativeClassInAnnotation.withArguments(
                node.name,
                nativeClass.name,
                nativeClass.enclosingLibrary.importUri.toString()),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
    }
  }

  // JS interop member checks

  /// Verifies given [member] is one of the allowed usages of external:
  /// a dart low level library, a foreign helper, a native test,
  /// or a from environment constructor.
  bool _isAllowedExternalUsage(Member member) {
    final uri = member.enclosingLibrary.importUri;
    return uri.isScheme('dart') &&
            _pathsWithAllowedDartExternalUsage.contains(uri.path) ||
        _allowedNativeTestPatterns.any((pattern) => uri.path.contains(pattern));
  }

  /// Assumes given [member] is not JS interop, and reports an error if
  /// [member] is `external` and not an allowed `external` usage.
  void _checkDisallowedExternal(Member member) {
    // TODO(joshualitt): These checks add value for our users, but unfortunately
    // some backends support multiple native APIs. We should really make a
    // neutral 'ExternalUsageVerifier` class, but until then we just disable
    // this check on Dart2Wasm.
    if (isDart2Wasm) return;
    if (member.isExternal) {
      if (_isAllowedExternalUsage(member)) return;
      if (member.isExtensionMember) {
        final annotatable = extensionIndex.getExtensionAnnotatable(member);
        if (annotatable == null) {
          _reporter.report(messageJsInteropExternalExtensionMemberOnTypeInvalid,
              member.fileOffset, member.name.text.length, member.fileUri);
        }
      } else if (member.isExtensionTypeMember) {
        final extensionType = extensionIndex.getExtensionType(member);
        if (extensionType == null) {
          _reporter.report(messageJsInteropExtensionTypeMemberNotInterop,
              member.fileOffset, member.name.text.length, member.fileUri);
        }
      } else if (!hasJSInteropAnnotation(member)) {
        // Member could be JS annotated and not considered a JS interop member
        // if inside a non-JS interop class. Should not report an error in this
        // case, since a different error will already be produced.
        _reporter.report(messageJsInteropExternalMemberNotJSAnnotated,
            member.fileOffset, member.name.text.length, member.fileUri);
      }
    }
  }

  /// Given a [member] and the [context] in which the use of it occurs,
  /// determines whether a tear-off of [member] can be used.
  ///
  /// Tear-offs of the following are disallowed when using dart:js_interop:
  ///
  /// - External extension type constructors and factories
  /// - External factories of @staticInterop classes
  /// - External interop extension type methods
  /// - External interop extension methods on @staticInterop or extension types
  /// - Synthetic generative @staticInterop constructors
  /// - External top-level methods
  ///
  /// Returns whether an error was triggered.
  bool _checkDisallowedTearoff(Member member, TreeNode? context) {
    if (context == null || context.location == null) return false;
    // TODO(srujzs): Delete the check for patched member once
    // https://github.com/dart-lang/sdk/issues/53367 is resolved.
    if (member.isExternal && !JsInteropChecks.isPatchedMember(member)) {
      final String memberKind;
      var memberName = '';
      if (member.isExtensionTypeMember) {
        // Extension type interop members can not be torn off.
        if (extensionIndex.getExtensionType(member) == null) {
          return false;
        }
        memberKind = 'extension type interop member';
        memberName =
            extensionIndex.getExtensionTypeDescriptor(member)!.name.text;
        if (memberName.isEmpty) memberName = 'new';
      } else if (member.isExtensionMember) {
        // JS interop members can not be torn off.
        if (extensionIndex.getExtensionAnnotatable(member) == null) {
          return false;
        }
        memberKind = 'extension interop member';
        memberName = extensionIndex.getExtensionDescriptor(member)!.name.text;
      } else if (member.enclosingClass != null) {
        // @staticInterop members can not be torn off.
        final enclosingClass = member.enclosingClass!;
        if (!hasStaticInteropAnnotation(enclosingClass)) return false;
        memberKind = '@staticInterop member';
        memberName = member.name.text;
        if (memberName.isEmpty) memberName = 'new';
      } else {
        // Top-levels with dart:js_interop can not be torn off.
        if (!hasDartJSInteropAnnotation(member) &&
            !hasDartJSInteropAnnotation(member.enclosingLibrary)) {
          return false;
        }
        memberKind = 'top-level member';
        memberName = member.name.text;
      }
      _reporter.report(
          templateJsInteropStaticInteropTearOffsDisallowed.withArguments(
              memberKind, memberName),
          context.fileOffset,
          1,
          context.location!.file);
      return true;
    } else if (member is Constructor &&
        member.isSynthetic &&
        hasStaticInteropAnnotation(member.enclosingClass)) {
      // Use of a synthetic generative constructor on @staticInterop class is
      // disallowed.
      _reporter.report(messageJsInteropStaticInteropSyntheticConstructor,
          context.fileOffset, 1, context.location!.file);
      return true;
    }
    return false;
  }

  /// Checks that [node], which is a call to 'Function.toJS', is called with a
  /// valid function type.
  void _checkFunctionToJSCall(StaticInvocation node) {
    void report(Message message) => _reporter.report(
        message, node.fileOffset, node.name.text.length, node.location?.file);

    final argument = node.arguments.positional.single;
    final functionType = argument.getStaticType(_staticTypeContext);
    if (functionType is! FunctionType) {
      report(templateJsInteropFunctionToJSRequiresStaticType
          .withArguments(functionType));
    } else {
      if (functionType.typeParameters.isNotEmpty) {
        report(messageJsInteropFunctionToJSTypeParameters);
      }
      _reportFunctionToJSInvocationIfNotAllowedFunctionType(functionType, node);
    }
  }

  /// Reports an error if given instance [member] is JS interop, but inside a
  /// non JS interop class.
  void _checkInstanceMemberJSAnnotation(Member member) {
    final enclosingClass = member.enclosingClass;

    if (!_classHasJSAnnotation &&
        enclosingClass != null &&
        hasJSInteropAnnotation(member)) {
      // If in a class that is not JS interop, this member is not allowed to be
      // JS interop.
      _reporter.report(messageJsInteropEnclosingClassJSAnnotation,
          member.fileOffset, member.name.text.length, member.fileUri,
          context: <LocatedMessage>[
            messageJsInteropEnclosingClassJSAnnotationContext.withLocation(
                enclosingClass.fileUri,
                enclosingClass.fileOffset,
                enclosingClass.name.length)
          ]);
    }
  }

  /// Given JS interop member [node], checks that it is not an operator that is
  /// disallowed, on a non-static interop type, or renamed.
  void _checkJsInteropOperator(Procedure node) {
    var isInvalidOperator = false;
    var operatorHasRenaming = false;
    if ((node.isExtensionTypeMember &&
            extensionIndex.getExtensionTypeDescriptor(node)?.kind ==
                ExtensionTypeMemberKind.Operator) ||
        (node.isExtensionMember &&
            extensionIndex.getExtensionDescriptor(node)?.kind ==
                ExtensionMemberKind.Operator)) {
      final operator =
          extensionIndex.getExtensionTypeDescriptor(node)?.name.text ??
              extensionIndex.getExtensionDescriptor(node)?.name.text;
      isInvalidOperator = operator != '[]' && operator != '[]=';
      operatorHasRenaming = getJSName(node).isNotEmpty;
    } else if (!node.isStatic && node.kind == ProcedureKind.Operator) {
      isInvalidOperator = true;
      operatorHasRenaming = getJSName(node).isNotEmpty;
    }
    if (isInvalidOperator) {
      _reporter.report(messageJsInteropOperatorsNotSupported, node.fileOffset,
          node.name.text.length, node.fileUri);
    }
    if (operatorHasRenaming) {
      _reporter.report(messageJsInteropOperatorCannotBeRenamed, node.fileOffset,
          node.name.text.length, node.fileUri);
    }
  }

  void _checkLiteralConstructorHasNoPositionalParams(Procedure node,
      {required bool isAnonymousFactory}) {
    final positionalParams = node.function.positionalParameters;
    if (positionalParams.isNotEmpty) {
      final firstPositionalParam = positionalParams[0];
      _reporter.report(
          templateJsInteropObjectLiteralConstructorPositionalParameters
              .withArguments(isAnonymousFactory
                  ? '@anonymous factories'
                  : 'Object literal constructors'),
          firstPositionalParam.fileOffset,
          firstPositionalParam.name!.length,
          firstPositionalParam.location!.file);
    }
  }

  /// Reports an error if [functionNode] has named parameters.
  void _checkNoNamedParameters(FunctionNode functionNode) {
    if (functionNode.namedParameters.isNotEmpty) {
      final firstNamedParam = functionNode.namedParameters[0];
      _reporter.report(
          messageJsInteropNamedParameters,
          firstNamedParam.fileOffset,
          firstNamedParam.name!.length,
          firstNamedParam.location!.file);
    }
  }

  /// Reports a warning if static interop function [node] has any parameters
  /// that have a declared initializer.
  void _checkNoParamInitializersForStaticInterop(FunctionNode node) {
    for (final param in [
      ...node.positionalParameters,
      ...node.namedParameters
    ]) {
      if (param.hasDeclaredInitializer) {
        _reporter.report(
            messageJsInteropStaticInteropParameterInitializersAreIgnored,
            param.fileOffset,
            param.name!.length,
            param.location!.file);
      }
    }
  }

  /// If [procedure] is a generated procedure that represents a relevant
  /// tear-off, return the torn-off member.
  ///
  /// Otherwise, return null.
  Member? _getTornOffFromGeneratedTearOff(Procedure procedure) {
    final tornOff =
        extensionIndex.getExtensionTypeMemberForTearOff(procedure) ??
            extensionIndex.getExtensionMemberForTearOff(procedure);
    if (tornOff != null) return tornOff.asMember;
    final name = extractConstructorNameFromTearOff(procedure.name);
    if (name == null) return null;
    final enclosingClass = procedure.enclosingClass;
    // To avoid processing every class' constructors again, we only check for
    // constructor tear-offs on relevant classes a.k.a. @staticInterop classes.
    if (enclosingClass == null || !hasStaticInteropAnnotation(enclosingClass)) {
      return null;
    }
    for (final constructor in enclosingClass.constructors) {
      if (constructor.name.text == name) {
        return constructor;
      }
    }
    for (final procedure in enclosingClass.procedures) {
      if (procedure.isFactory && procedure.name.text == name) {
        return procedure;
      }
    }
    return null;
  }

  /// Returns whether [member] is considered to be a JS interop member.
  ///
  /// A JS interop member is `external`, and is in a valid JS interop context,
  /// which can be:
  ///   - inside a JS interop class
  ///   - inside an extension on a JS interop or @Native annotatable
  ///   - inside a JS interop extension type
  ///   - a top level member that is JS interop annotated or in a package:js JS
  ///     interop library
  bool _isJSInteropMember(Member member) {
    if (member.isExternal) {
      if (_classHasJSAnnotation) return true;
      if (member.isExtensionMember) {
        return extensionIndex.getExtensionAnnotatable(member) != null;
      }
      if (member.isExtensionTypeMember) {
        return extensionIndex.getExtensionType(member) != null;
      }
      if (member.enclosingClass == null) {
        // dart:js_interop requires top-levels to be @JS-annotated. package:js
        // historically does not have this restriction. We add this restriction
        // to refuse confusion on what an external member does now that we can
        // have dart:ffi and dart:js_interop in the same code via dart2wasm.
        final libraryHasPkgJSAnnotation =
            _libraryHasJSAnnotation && !_libraryHasDartJSInteropAnnotation;
        return hasJSInteropAnnotation(member) || libraryHasPkgJSAnnotation;
      }
    }

    // Otherwise, not JS interop.
    return false;
  }

  /// Return whether [type] can be used on a `dart:js_interop` external member
  /// or in the signature of a function that is converted via `toJS`.
  bool _isAllowedExternalType(DartType type) {
    if (type is VoidType || type is NullType) return true;
    if (type is TypeParameterType || type is StructuralParameterType) {
      final bound = type.nonTypeVariableBound;
      // If it can be used as a representation type of an interop extension
      // type, it is okay to be used as a bound.
      // TODO(srujzs): We may want to support type parameters with primitive
      // bounds that are themselves allowed e.g. `num`. If so, we should handle
      // that change in dart2wasm.
      if (extensionIndex.isAllowedRepresentationType(bound)) return true;
    }
    // If it can be used as a representation type of an interop extension type,
    // it is okay to be used on an external member.
    if (extensionIndex.isAllowedRepresentationType(type)) return true;
    // ExternalDartReference is allowed on interop members even though it's not
    // an interop type.
    if (extensionIndex.isExternalDartReferenceType(type)) return true;
    if (type is InterfaceType) {
      final cls = type.classNode;
      // Primitive types are okay.
      if (cls == _coreTypes.boolClass ||
          cls == _coreTypes.numClass ||
          cls == _coreTypes.doubleClass ||
          cls == _coreTypes.intClass ||
          cls == _coreTypes.stringClass) {
        return true;
      }
    } else if (type is ExtensionType) {
      // Extension types that wrap other allowed types are also okay. Interop
      // extension types and ExternalDartReference are handled above, so this is
      // essentially for extension types on primitives.
      return _isAllowedExternalType(type.extensionTypeErasure);
    }
    return false;
  }

  bool _isAllowedExternalFunctionType(FunctionType type) =>
      _isAllowedExternalType(type.returnType) &&
      type.namedParameters.every((p) => _isAllowedExternalType(p.type)) &&
      type.positionalParameters.every((p) => _isAllowedExternalType(p));

  String _disallowedExternalFunctionTypeString(FunctionType functionType) {
    String typeStringToErrorTypeString(String type) => '*$type*';
    String typeToString(DartType type) {
      final string = type.toText(_textStrategy);
      return _isAllowedExternalType(type)
          ? string
          : typeStringToErrorTypeString(string);
    }

    String namedTypeToString(NamedType type) {
      final string = type.toText(_textStrategy);
      return _isAllowedExternalType(type.type)
          ? string
          : typeStringToErrorTypeString(string);
    }

    final positionalParameterTypeString =
        functionType.positionalParameters.map(typeToString).join(', ');
    final namedParameterTypeString =
        functionType.namedParameters.map(namedTypeToString).join(', ');
    String parameterTypeString;
    if (positionalParameterTypeString.isNotEmpty &&
        namedParameterTypeString.isNotEmpty) {
      parameterTypeString =
          '$positionalParameterTypeString, {$namedParameterTypeString}';
    } else {
      parameterTypeString = namedParameterTypeString.isNotEmpty
          ? '{$namedParameterTypeString}'
          : positionalParameterTypeString;
    }
    return '${typeToString(functionType.returnType)} '
        'Function($parameterTypeString)';
  }

  void _reportExternalProcedureIfNotAllowedFunctionType(Procedure node) {
    FunctionType functionType;
    if (node.isExtensionMember || node.isExtensionTypeMember) {
      functionType = extensionIndex.getFunctionType(node)!;
    } else {
      functionType = node.signatureType ??
          node.function.computeFunctionType(Nullability.nonNullable);
    }
    final isGetter = extensionIndex.isGetter(node);
    final isSetter = extensionIndex.isSetter(node);
    if (isGetter || isSetter) {
      // There's only one type, so only report that one type instead of a
      // function type. This also avoids duplication in reporting external
      // fields, which are just a getter and a setter.
      final accessorType = isGetter
          ? functionType.returnType
          : functionType.positionalParameters[0];
      if (!_isAllowedExternalType(accessorType)) {
        _reporter.report(
            templateJsInteropStaticInteropExternalAccessorTypeViolation
                .withArguments(accessorType),
            node.fileOffset,
            node.name.text.length,
            node.location?.file);
      }
    } else {
      // Methods, operators, constructors, factories.
      if (!_isAllowedExternalFunctionType(functionType)) {
        _reporter.report(
            templateJsInteropStaticInteropExternalFunctionTypeViolation
                .withArguments(
                    _disallowedExternalFunctionTypeString(functionType)),
            node.fileOffset,
            node.name.text.length,
            node.location?.file);
      }
    }
  }

  void _reportFunctionToJSInvocationIfNotAllowedFunctionType(
      FunctionType functionType, StaticInvocation invocation) {
    if (!_isAllowedExternalFunctionType(functionType)) {
      _reporter.report(
          templateJsInteropStaticInteropToJSFunctionTypeViolation.withArguments(
              _disallowedExternalFunctionTypeString(functionType)),
          invocation.fileOffset,
          invocation.name.text.length,
          invocation.location?.file);
    }
  }
}

class JsInteropDiagnosticReporter {
  bool hasJsInteropErrors = false;
  final DiagnosticReporter<Message, LocatedMessage> _reporter;
  JsInteropDiagnosticReporter(this._reporter);

  void report(Message message, int charOffset, int length, Uri? fileUri,
      {List<LocatedMessage>? context}) {
    if (context == null) {
      _reporter.report(message, charOffset, length, fileUri);
    } else {
      _reporter.report(message, charOffset, length, fileUri, context: context);
    }
    if (message.code.severity == Severity.error) hasJsInteropErrors = true;
  }
}
