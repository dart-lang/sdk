// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        messageJsInteropDartJsInteropAnnotationForStaticInteropOnly,
        messageJsInteropEnclosingClassJSAnnotation,
        messageJsInteropEnclosingClassJSAnnotationContext,
        messageJsInteropExternalExtensionMemberOnTypeInvalid,
        messageJsInteropExternalExtensionMemberWithStaticDisallowed,
        messageJsInteropExternalMemberNotJSAnnotated,
        messageJsInteropInlineClassMemberNotInterop,
        messageJsInteropInlineClassUsedWithWrongJsAnnotation,
        messageJsInteropInvalidStaticClassMemberName,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor,
        messageJsInteropNonExternalMember,
        messageJsInteropOperatorCannotBeRenamed,
        messageJsInteropOperatorsNotSupported,
        messageJsInteropStaticInteropExternalExtensionMembersWithTypeParameters,
        messageJsInteropStaticInteropGenerativeConstructor,
        messageJsInteropStaticInteropParameterInitializersAreIgnored,
        messageJsInteropStaticInteropSyntheticConstructor,
        templateJsInteropDartClassExtendsJSClass,
        templateJsInteropInlineClassNotInterop,
        templateJsInteropJSClassExtendsDartClass,
        templateJsInteropNonStaticWithStaticInteropSupertype,
        templateJsInteropStaticInteropNoJSAnnotation,
        templateJsInteropStaticInteropWithInstanceMembers,
        templateJsInteropStaticInteropWithNonStaticSupertype,
        templateJsInteropObjectLiteralConstructorPositionalParameters,
        templateJsInteropNativeClassInAnnotation,
        templateJsInteropStaticInteropTearOffsDisallowed,
        templateJsInteropStaticInteropTrustTypesUsageNotAllowed,
        templateJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
        templateJsInteropStrictModeForbiddenLibrary;
import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_js_interop_checks/src/transformations/export_checker.dart';
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart';
// Used for importing CFE utility functions for constructor tear-offs.
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        templateJsInteropFunctionToJSRequiresStaticType,
        templateJsInteropStrictModeViolation;

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide Pattern;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor {
  final Set<Constant> _constantCache = {};
  final CoreTypes _coreTypes;
  final Procedure _functionToJSTarget;
  late final InlineExtensionIndex _inlineExtensionIndex;
  // Errors on constants need source information, so we use the surrounding
  // `ConstantExpression` as the source.
  ConstantExpression? _lastConstantExpression;
  final Map<String, Class> _nativeClasses;
  final JsInteropDiagnosticReporter _reporter;
  final StatefulStaticTypeContext _staticTypeContext;
  final _TypeParameterVisitor _typeParameterVisitor = _TypeParameterVisitor();
  bool _classHasJSAnnotation = false;
  bool _classHasAnonymousAnnotation = false;
  bool _classHasStaticInteropAnnotation = false;
  bool _inTearoff = false;
  bool _libraryHasDartJSInteropAnnotation = false;
  bool _libraryHasJSAnnotation = false;
  bool _libraryIsGlobalNamespace = false;

  // TODO(joshualitt): Today strict mode is just for testing, but we should find
  // a way to expose this to users who want strict mode guarantees.
  bool _enforceStrictMode = false;

  /// If [enableStrictMode] is true, then static interop methods must use JS
  /// types.
  final bool enableStrictMode;
  final ExportChecker exportChecker;
  final bool isDart2Wasm;

  /// Native tests to exclude from checks on external.
  // TODO(rileyporter): Use ExternalName from CFE to exclude native tests.
  static final List<Pattern> _allowedNativeTestPatterns = [
    RegExp(r'(?<!generated_)tests/web/native'),
    RegExp(r'(?<!generated_)tests/web/internal'),
    'generated_tests/web/native/native_test',
    RegExp(r'(?<!generated_)tests/web_2/native'),
    RegExp(r'(?<!generated_)tests/web_2/internal'),
    'generated_tests/web_2/native/native_test',
  ];

  static final List<Pattern> _allowedTrustTypesTestPatterns = [
    RegExp(r'(?<!generated_)tests/lib/js'),
    RegExp(r'(?<!generated_)tests/lib_2/js'),
  ];

  /// Libraries that need to use external extension members with static interop
  /// types.
  static const Iterable<String> _customStaticInteropImplementations = [
    'js_interop',
    'js_interop_unsafe',
  ];

  /// Libraries that cannot be used when [_enforceStrictMode] is true.
  static const _disallowedLibrariesInStrictMode = [
    'package:js/js.dart',
    'package:js/js_util.dart',
    'dart:html',
    'dart:js_util',
    'dart:js'
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
      {this.isDart2Wasm = false, this.enableStrictMode = false})
      : exportChecker = ExportChecker(_reporter, _coreTypes.objectClass),
        _functionToJSTarget = _coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {
    _inlineExtensionIndex =
        InlineExtensionIndex(_coreTypes, _staticTypeContext.typeEnvironment);
  }

  /// Verifies given [member] is an external extension member on a static
  /// interop type that needs custom behavior.
  static bool isAllowedCustomStaticInteropImplementation(Member member) {
    Uri uri = member.enclosingLibrary.importUri;
    return uri.isScheme('dart') &&
        _customStaticInteropImplementations.contains(uri.path);
  }

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
  void visitInlineClass(InlineClass node) {
    if (hasPackageJSAnnotation(node)) {
      _reporter.report(messageJsInteropInlineClassUsedWithWrongJsAnnotation,
          node.fileOffset, node.name.length, node.fileUri);
    }
    if (hasDartJSInteropAnnotation(node) &&
        !_inlineExtensionIndex.isInteropInlineClass(node)) {
      _reporter.report(
          templateJsInteropInlineClassNotInterop.withArguments(
              node.name, node.declaredRepresentationType.toString()),
          node.fileOffset,
          node.name.length,
          node.fileUri);
    }
    super.visitInlineClass(node);
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
      // Validate that superinterfaces are all annotated as static as well. Note
      // that mixins are already disallowed and therefore are not checked here.
      for (final supertype in node.implementedTypes) {
        if (!hasStaticInteropAnnotation(supertype.classNode)) {
          report(templateJsInteropStaticInteropWithNonStaticSupertype
              .withArguments(node.name, supertype.classNode.name));
        }
      }
    } else {
      // For non-inline classes, `dart:js_interop`'s `@JS` can only be used
      // with `@staticInterop`.
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
    _enforceStrictMode = _shouldEnforceStrictMode(node);

    if (_enforceStrictMode && !node.importUri.isScheme('dart')) {
      _checkDisallowedLibrariesInStrictMode(node);
    }

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

    // TODO(joshualitt): Add a check that only supported operators are allowed
    // in external extension members / inline classes.
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
      _checkJsInteropMemberNotOperator(node);

      // Check JS Interop positional and named parameters. Literal constructors
      // can only have named parameters, and every other interop member can only
      // have positional parameters.
      final isObjectLiteralConstructor = node.isInlineClassMember &&
          (_inlineExtensionIndex.getInlineDescriptor(node)!.kind ==
                  InlineClassMemberKind.Constructor ||
              _inlineExtensionIndex.getInlineDescriptor(node)!.kind ==
                  InlineClassMemberKind.Factory) &&
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

      // In strict mode, check all types are JS types.
      if (enableStrictMode) {
        final function = node.function;
        _reportProcedureIfNotJSType(function.returnType, node);
        for (final parameter in function.positionalParameters) {
          _reportProcedureIfNotJSType(parameter.type, node);
        }
        for (final parameter in function.namedParameters) {
          _reportProcedureIfNotJSType(parameter.type, node);
        }
      }

      if (_classHasStaticInteropAnnotation ||
          node.isInlineClassMember ||
          node.isExtensionMember ||
          node.enclosingClass == null &&
              (hasDartJSInteropAnnotation(node) ||
                  _libraryHasDartJSInteropAnnotation)) {
        _checkNoParamInitializersForStaticInterop(node.function);
        if (node.isExtensionMember) {
          final annotatable =
              _inlineExtensionIndex.getExtensionAnnotatable(node);
          if (annotatable != null) {
            // If a @staticInterop member, check that it uses no type
            // parameters.
            if (hasStaticInteropAnnotation(annotatable) &&
                !isAllowedCustomStaticInteropImplementation(node)) {
              _checkStaticInteropMemberUsesNoTypeParameters(node);
            }
            // We do not support external extension members with the 'static'
            // keyword currently.
            if (_inlineExtensionIndex.getExtensionDescriptor(node)!.isStatic) {
              report(
                  messageJsInteropExternalExtensionMemberWithStaticDisallowed);
            }
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

  /// Determine if [node] enforces strict mode checking. This is currently only
  /// enabled for testing.
  bool _shouldEnforceStrictMode(Library node) {
    return node.fileUri.toString().contains(RegExp(
        r'(?<!generated_)tests/lib/js/static_interop_test/strict_mode_test.dart'));
  }

  void _checkDisallowedLibrariesInStrictMode(Library node) {
    for (final dependency in node.dependencies) {
      final dependencyUriString = dependency.targetLibrary.importUri.toString();
      if (_disallowedLibrariesInStrictMode.contains(dependencyUriString)) {
        _reporter.report(
            templateJsInteropStrictModeForbiddenLibrary
                .withArguments(dependencyUriString),
            dependency.fileOffset,
            dependencyUriString.length,
            node.fileUri);
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
    Uri uri = member.enclosingLibrary.importUri;
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
        final annotatable =
            _inlineExtensionIndex.getExtensionAnnotatable(member);
        if (annotatable == null) {
          _reporter.report(messageJsInteropExternalExtensionMemberOnTypeInvalid,
              member.fileOffset, member.name.text.length, member.fileUri);
        }
      } else if (member.isInlineClassMember) {
        final inlineClass = _inlineExtensionIndex.getInlineClass(member);
        if (inlineClass == null) {
          _reporter.report(messageJsInteropInlineClassMemberNotInterop,
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
  /// - External inline class constructors and factories (TODO(srujzs): Add
  /// checks for factories once they're added.)
  /// - External factories of @staticInterop classes
  /// - External interop inline methods
  /// - External interop extension methods on @staticInterop or inline classes
  /// - Synthetic generative @staticInterop constructors
  /// - External top-level methods
  ///
  /// Returns whether an error was triggered.
  bool _checkDisallowedTearoff(Member member, TreeNode? context) {
    if (context == null || context.location == null) return false;
    if (member.isExternal) {
      var memberKind = '';
      var memberName = '';
      if (member.isInlineClassMember) {
        // Inline class interop members can not be torn off.
        if (_inlineExtensionIndex.getInlineClass(member) == null) {
          return false;
        }
        memberKind = 'inline class interop member';
        memberName =
            _inlineExtensionIndex.getInlineDescriptor(member)!.name.text;
        if (memberName.isEmpty) memberName = 'new';
      } else if (member.isExtensionMember) {
        // JS interop members can not be torn off.
        if (_inlineExtensionIndex.getExtensionAnnotatable(member) == null) {
          return false;
        }
        memberKind = 'extension interop member';
        memberName =
            _inlineExtensionIndex.getExtensionDescriptor(member)!.name.text;
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
    final argument = node.arguments.positional.single;
    final functionType = argument.getStaticType(_staticTypeContext);
    if (functionType is! FunctionType) {
      _reporter.report(
          templateJsInteropFunctionToJSRequiresStaticType.withArguments(
              functionType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
    } else {
      _reportStaticInvocationIfNotJSType(functionType.returnType, node);
      for (final parameter in functionType.positionalParameters) {
        _reportStaticInvocationIfNotJSType(parameter, node);
      }
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
  /// disallowed.
  ///
  /// Also checks that no renaming is done on interop operators.
  void _checkJsInteropMemberNotOperator(Procedure node) {
    var isInvalidOperator = false;
    var operatorHasRenaming = false;
    if ((node.isInlineClassMember &&
            _inlineExtensionIndex.getInlineDescriptor(node)?.kind ==
                InlineClassMemberKind.Operator) ||
        (node.isExtensionMember &&
            _inlineExtensionIndex.getExtensionDescriptor(node)?.kind ==
                ExtensionMemberKind.Operator)) {
      final operator =
          _inlineExtensionIndex.getInlineDescriptor(node)?.name.text ??
              _inlineExtensionIndex.getExtensionDescriptor(node)?.name.text;
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

  void _checkStaticInteropMemberUsesNoTypeParameters(Procedure node) {
    // If the extension has type parameters of its own, it copies those type
    // parameters to the procedure's type parameters (in the front) as well.
    // Ignore these for the analysis.
    final extensionTypeParams =
        _inlineExtensionIndex.getExtension(node)!.typeParameters;
    final procedureTypeParams = List.from(node.function.typeParameters);
    procedureTypeParams.removeRange(0, extensionTypeParams.length);
    if (procedureTypeParams.isNotEmpty ||
        _typeParameterVisitor.usesTypeParameters(node)) {
      _reporter.report(
          messageJsInteropStaticInteropExternalExtensionMembersWithTypeParameters,
          node.fileOffset,
          node.name.text.length,
          node.fileUri);
    }
  }

  /// If [procedure] is a generated procedure that represents a relevant
  /// tear-off, return the torn-off member.
  ///
  /// Otherwise, return null.
  Member? _getTornOffFromGeneratedTearOff(Procedure procedure) {
    final tornOff =
        _inlineExtensionIndex.getInlineMemberForTearOff(procedure) ??
            _inlineExtensionIndex.getExtensionMemberForTearOff(procedure);
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
  ///   - inside a JS interop inline class
  ///   - a top level member that is JS interop annotated or in a JS interop
  ///     library
  bool _isJSInteropMember(Member member) {
    if (member.isExternal) {
      if (_classHasJSAnnotation) return true;
      if (member.isExtensionMember) {
        return _inlineExtensionIndex.getExtensionAnnotatable(member) != null;
      }
      if (member.isInlineClassMember) {
        return _inlineExtensionIndex.getInlineClass(member) != null;
      }
      if (member.enclosingClass == null) {
        return hasJSInteropAnnotation(member) || _libraryHasJSAnnotation;
      }
    }

    // Otherwise, not JS interop.
    return false;
  }

  void _reportIfNotJSType(
      DartType type, TreeNode node, Name name, Uri? fileUri) {
    // TODO(joshualitt): We allow only JS types on external JS interop APIs with
    // two exceptions: `void` and `Null`. Both of these exceptions exist largely
    // to support passing Dart functions to JS as callbacks.  Furthermore, both
    // of these types mean no actual values needs to be returned to JS. That
    // said, for completeness, we may restrict these two types someday, and
    // provide JS types equivalents, but likely only if we have implicit
    // conversions between Dart types and JS types.
    if (_enforceStrictMode &&
        !(type is VoidType ||
            type is NullType ||
            (type is InterfaceType &&
                hasStaticInteropAnnotation(type.classNode)) ||
            (type is InlineType &&
                hasDartJSInteropAnnotation(type.inlineClass)))) {
      _reporter.report(
          templateJsInteropStrictModeViolation.withArguments(type, true),
          node.fileOffset,
          name.text.length,
          fileUri);
    }
  }

  void _reportProcedureIfNotJSType(DartType type, Procedure node) =>
      _reportIfNotJSType(type, node, node.name, node.fileUri);

  void _reportStaticInvocationIfNotJSType(
          DartType type, StaticInvocation node) =>
      _reportIfNotJSType(type, node, node.name, node.location?.file);
}

/// Visitor used to check if a particular node uses a type parameter type.
class _TypeParameterVisitor extends RecursiveVisitor {
  bool _visitedTypeParameterType = false;

  bool usesTypeParameters(Node node) {
    _visitedTypeParameterType = false;
    node.accept(this);
    return _visitedTypeParameterType;
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    _visitedTypeParameterType = true;
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
