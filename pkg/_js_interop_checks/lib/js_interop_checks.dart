// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Message,
        LocatedMessage,
        messageJsInteropAnonymousFactoryPositionalParameters,
        messageJsInteropDartJsInteropAnnotationForStaticInteropOnly,
        messageJsInteropEnclosingClassJSAnnotation,
        messageJsInteropEnclosingClassJSAnnotationContext,
        messageJsInteropExternalExtensionMemberOnTypeInvalid,
        messageJsInteropExternalMemberNotJSAnnotated,
        messageJsInteropInlineClassUsedWithWrongJsAnnotation,
        messageJsInteropInvalidStaticClassMemberName,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor,
        messageJsInteropNonExternalMember,
        messageJsInteropOperatorsNotSupported,
        messageJsInteropStaticInteropExternalExtensionMembersWithTypeParameters,
        messageJsInteropStaticInteropGenerativeConstructor,
        messageJsInteropStaticInteropSyntheticConstructor,
        templateJsInteropDartClassExtendsJSClass,
        templateJsInteropNonStaticWithStaticInteropSupertype,
        templateJsInteropStaticInteropNoJSAnnotation,
        templateJsInteropStaticInteropWithInstanceMembers,
        templateJsInteropStaticInteropWithNonStaticSupertype,
        templateJsInteropJSClassExtendsDartClass,
        templateJsInteropNativeClassInAnnotation,
        templateJsInteropStaticInteropTearOffsDisallowed,
        templateJsInteropStaticInteropTrustTypesUsageNotAllowed,
        templateJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop,
        templateJsInteropStrictModeForbiddenLibrary;
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
  final DiagnosticReporter<Message, LocatedMessage> _diagnosticsReporter;
  final ExportChecker exportChecker;
  final Procedure _functionToJSTarget;
  final InlineExtensionIndex _inlineExtensionIndex = InlineExtensionIndex();
  // Errors on constants need source information, so we use the surrounding
  // `ConstantExpression` as the source.
  ConstantExpression? _lastConstantExpression;
  final Map<String, Class> _nativeClasses;
  final _TypeParameterVisitor _typeParameterVisitor = _TypeParameterVisitor();
  final StatefulStaticTypeContext _staticTypeContext;
  bool _classHasJSAnnotation = false;
  bool _classHasAnonymousAnnotation = false;
  bool _classHasStaticInteropAnnotation = false;
  bool _inTearoff = false;
  bool _libraryHasJSAnnotation = false;
  // TODO(joshualitt): These checks add value for our users, but unfortunately
  // some backends support multiple native APIs. We should really make a neutral
  // 'ExternalUsageVerifier` class, but until then we just disable this check on
  // Dart2Wasm.
  final bool enableDisallowedExternalCheck;

  /// If [enableStrictMode] is true, then static interop methods must use JS
  /// types.
  final bool enableStrictMode;

  // TODO(joshualitt): Remove allow list and deprecate non-strict mode on
  // Dart2Wasm.
  bool _nonStrictModeIsAllowed = false;

  /// Libraries that use `external` to exclude from checks on external.
  static final Iterable<String> _pathsWithAllowedDartExternalUsage = <String>[
    '_foreign_helper', // for foreign helpers
    '_late_helper', // for dart2js late variable utilities
    '_interceptors', // for ddc JS string
    '_native_typed_data',
    '_runtime', // for ddc types at runtime
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

  /// Libraries that need to use external extension members with static interop
  /// types.
  static final Iterable<String> _customStaticInteropImplementations = [
    'js_interop',
  ];

  /// Native tests to exclude from checks on external.
  // TODO(rileyporter): Use ExternalName from CFE to exclude native tests.
  final List<Pattern> _allowedNativeTestPatterns = [
    RegExp(r'(?<!generated_)tests/web/native'),
    RegExp(r'(?<!generated_)tests/web/internal'),
    'generated_tests/web/native/native_test',
    RegExp(r'(?<!generated_)tests/web_2/native'),
    RegExp(r'(?<!generated_)tests/web_2/internal'),
    'generated_tests/web_2/native/native_test',
  ];

  final List<Pattern> _allowedTrustTypesTestPatterns = [
    RegExp(r'(?<!generated_)tests/lib/js'),
    RegExp(r'(?<!generated_)tests/lib_2/js'),
  ];

  bool _libraryIsGlobalNamespace = false;

  JsInteropChecks(this._coreTypes, ClassHierarchy hierarchy,
      this._diagnosticsReporter, this._nativeClasses,
      {this.enableDisallowedExternalCheck = true,
      this.enableStrictMode = false})
      : exportChecker =
            ExportChecker(_diagnosticsReporter, _coreTypes.objectClass),
        _functionToJSTarget = _coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy));

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
      _diagnosticsReporter.report(
          messageJsInteropInlineClassUsedWithWrongJsAnnotation,
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
    bool classHasTrustTypesAnnotation = hasTrustTypesAnnotation(node);
    if (classHasTrustTypesAnnotation) {
      if (!_isAllowedTrustTypesUsage(node)) {
        _diagnosticsReporter.report(
            templateJsInteropStaticInteropTrustTypesUsageNotAllowed
                .withArguments(node.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
      if (!_classHasStaticInteropAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropStaticInteropTrustTypesUsedWithoutStaticInterop
                .withArguments(node.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
    }
    var superclass = node.superclass;
    if (superclass != null && superclass != _coreTypes.objectClass) {
      var superHasJSAnnotation = hasJSInteropAnnotation(superclass);
      if (_classHasJSAnnotation && !superHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropJSClassExtendsDartClass.withArguments(
                node.name, superclass.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      } else if (!_classHasJSAnnotation && superHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropDartClassExtendsJSClass.withArguments(
                node.name, superclass.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      } else if (_classHasStaticInteropAnnotation &&
          !hasStaticInteropAnnotation(superclass)) {
        _diagnosticsReporter.report(
            templateJsInteropStaticInteropWithNonStaticSupertype.withArguments(
                node.name, superclass.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      } else if (!_classHasStaticInteropAnnotation &&
          hasStaticInteropAnnotation(superclass)) {
        _diagnosticsReporter.report(
            templateJsInteropNonStaticWithStaticInteropSupertype.withArguments(
                node.name, superclass.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
    }
    if (_classHasStaticInteropAnnotation) {
      if (!_classHasJSAnnotation) {
        _diagnosticsReporter.report(
            templateJsInteropStaticInteropNoJSAnnotation
                .withArguments(node.name),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
      // Validate that superinterfaces are all annotated as static as well. Note
      // that mixins are already disallowed and therefore are not checked here.
      for (var supertype in node.implementedTypes) {
        if (!hasStaticInteropAnnotation(supertype.classNode)) {
          _diagnosticsReporter.report(
              templateJsInteropStaticInteropWithNonStaticSupertype
                  .withArguments(node.name, supertype.classNode.name),
              node.fileOffset,
              node.name.length,
              node.fileUri);
        }
      }
    } else {
      // The converse of the above. If the class is not marked as static, it
      // should not implement a class that is.
      for (var supertype in node.implementedTypes) {
        if (hasStaticInteropAnnotation(supertype.classNode)) {
          _diagnosticsReporter.report(
              templateJsInteropNonStaticWithStaticInteropSupertype
                  .withArguments(node.name, supertype.classNode.name),
              node.fileOffset,
              node.name.length,
              node.fileUri);
        }
      }
      // For non-inline classes, `dart:js_interop`'s `@JS` can only be used
      // with `@staticInterop`.
      if (hasDartJSInteropAnnotation(node)) {
        _diagnosticsReporter.report(
            messageJsInteropDartJsInteropAnnotationForStaticInteropOnly,
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
    }
    // Since this is a breaking check, it is language-versioned.
    if (node.enclosingLibrary.languageVersion >= Version(2, 13) &&
        _classHasJSAnnotation &&
        !_classHasStaticInteropAnnotation &&
        !_classHasAnonymousAnnotation &&
        _libraryIsGlobalNamespace) {
      var jsClass = getJSName(node);
      if (jsClass.isEmpty) {
        // No rename, take the name of the class directly.
        jsClass = node.name;
      } else {
        // Remove any global prefixes. Regex here is greedy and will only return
        // a value for `className` that doesn't start with 'self.' or 'window.'.
        var classRegexp = RegExp(r'^((self|window)\.)*(?<className>.*)$');
        var matches = classRegexp.allMatches(jsClass);
        jsClass = matches.first.namedGroup('className')!;
      }
      var nativeClass = _nativeClasses[jsClass];
      if (nativeClass != null) {
        _diagnosticsReporter.report(
            templateJsInteropNativeClassInAnnotation.withArguments(
                node.name,
                nativeClass.name,
                nativeClass.enclosingLibrary.importUri.toString()),
            node.fileOffset,
            node.name.length,
            node.fileUri);
      }
    }
    super.visitClass(node);
    // Validate `@JSExport` usage after so we know if the members have the
    // annotation.
    exportChecker.visitClass(node);
    _classHasAnonymousAnnotation = false;
    _classHasJSAnnotation = false;
  }

  @override
  void visitLibrary(Library node) {
    _staticTypeContext.enterLibrary(node);
    _libraryHasJSAnnotation = hasJSInteropAnnotation(node);
    _libraryIsGlobalNamespace = false;
    // Allow only Flutter and package:test to opt out from strict mode on
    // Dart2Wasm.
    final isSDKLibrary = node.importUri.isScheme('dart');
    final importUriString = node.importUri.toString();
    _nonStrictModeIsAllowed = !enableStrictMode ||
        isSDKLibrary ||
        importUriString.startsWith('package:ui') ||
        importUriString.startsWith('package:js') ||
        importUriString.startsWith('package:flutter') ||
        importUriString.startsWith('package:flute') ||
        importUriString.startsWith('package:engine') ||
        importUriString.startsWith('package:test') ||
        importUriString.contains('/test/') ||
        (node.fileUri.toString().contains(RegExp(r'(?<!generated_)tests/')) &&
            !node.fileUri.toString().contains(RegExp(
                r'(?<!generated_)tests/lib/js/static_interop_test/strict_mode_test.dart')));

    // Disallow importing some libraries in non-SDK code when in strict mode.
    if (!_nonStrictModeIsAllowed && !isSDKLibrary) {
      for (final dependency in node.dependencies) {
        final dependencyUriString =
            dependency.targetLibrary.importUri.toString();
        if (dependencyUriString == 'package:js/js.dart' ||
            dependencyUriString == 'package:js/js_util.dart' ||
            dependencyUriString == 'dart:html' ||
            dependencyUriString == 'dart:js_util' ||
            dependencyUriString == 'dart:js') {
          _diagnosticsReporter.report(
              templateJsInteropStrictModeForbiddenLibrary
                  .withArguments(dependencyUriString),
              dependency.fileOffset,
              dependencyUriString.length,
              node.fileUri);
        }
      }
    }

    if (_libraryHasJSAnnotation) {
      var libraryAnnotation = getJSName(node);
      var globalRegexp = RegExp(r'^(self|window)(\.(self|window))*$');
      if (libraryAnnotation.isEmpty ||
          globalRegexp.hasMatch(libraryAnnotation)) {
        _libraryIsGlobalNamespace = true;
      }
    } else {
      _libraryIsGlobalNamespace = true;
    }
    super.visitLibrary(node);
    exportChecker.visitLibrary(node);
    _libraryIsGlobalNamespace = false;
    _libraryHasJSAnnotation = false;
    _staticTypeContext.leaveLibrary(node);
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
    if (!_nonStrictModeIsAllowed &&
        type is! VoidType &&
        type is! NullType &&
        (type is! InterfaceType || !hasJSInteropAnnotation(type.classNode))) {
      _diagnosticsReporter.report(
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

  @override
  void visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    // TODO(joshualitt): Add a check that only supported operators are allowed
    // in external extension members / inline classes.
    _checkInstanceMemberJSAnnotation(node);
    if (_classHasJSAnnotation && !node.isExternal) {
      // If not one of few exceptions, member is not allowed to exclude
      // `external` inside of a JS interop class.
      if (!(node.isAbstract || node.isFactory || node.isStatic)) {
        _diagnosticsReporter.report(messageJsInteropNonExternalMember,
            node.fileOffset, node.name.text.length, node.fileUri);
      }
    }

    if (!_isJSInteropMember(node)) {
      _checkDisallowedExternal(node);
    } else {
      // Check JS interop indexing.
      if (!node.isStatic && node.kind == ProcedureKind.Operator) {
        _diagnosticsReporter.report(messageJsInteropOperatorsNotSupported,
            node.fileOffset, node.name.text.length, node.fileUri);
      }

      // Check JS Interop positional and named parameters.
      final isObjectLiteralFactory =
          _classHasAnonymousAnnotation && node.isFactory ||
              node.isInlineClassMember && hasObjectLiteralAnnotation(node);
      if (isObjectLiteralFactory) {
        var positionalParams = node.function.positionalParameters;
        if (node.isInlineClassMember) {
          positionalParams = positionalParams.skip(1).toList();
        }
        if (node.function.positionalParameters.isNotEmpty) {
          final firstPositionalParam = positionalParams[0];
          _diagnosticsReporter.report(
              messageJsInteropAnonymousFactoryPositionalParameters,
              firstPositionalParam.fileOffset,
              firstPositionalParam.name!.length,
              firstPositionalParam.location!.file);
        }
      } else {
        // Only factory constructors for anonymous classes are allowed to have
        // named parameters.
        _checkNoNamedParameters(node.function);
      }

      // JS static methods cannot use a JS name with dots.
      if (node.isStatic && node.enclosingClass != null) {
        String name = getJSName(node);
        if (name.contains('.')) {
          _diagnosticsReporter.report(
              messageJsInteropInvalidStaticClassMemberName,
              node.fileOffset,
              node.name.text.length,
              node.fileUri);
        }
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
    }

    if (_classHasStaticInteropAnnotation &&
        node.isInstanceMember &&
        !node.isFactory &&
        !node.isSynthetic) {
      _diagnosticsReporter.report(
          templateJsInteropStaticInteropWithInstanceMembers
              .withArguments(node.enclosingClass!.name),
          node.fileOffset,
          node.name.text.length,
          node.fileUri);
    }

    if (node.isExternal && node.isExtensionMember) {
      final annotatable = _inlineExtensionIndex.getExtensionAnnotatable(node);
      if (annotatable != null &&
          hasStaticInteropAnnotation(annotatable) &&
          !_isAllowedCustomStaticInteropImplementation(node)) {
        // If the extension has type parameters of its own, it copies those type
        // parameters to the procedure's type parameters (in the front) as well.
        // Ignore these for the analysis.
        final extensionTypeParams =
            _inlineExtensionIndex.getExtension(node)!.typeParameters;
        final procedureTypeParams = List.from(node.function.typeParameters);
        procedureTypeParams.removeRange(0, extensionTypeParams.length);
        if (procedureTypeParams.isNotEmpty ||
            _typeParameterVisitor.usesTypeParameters(node)) {
          _diagnosticsReporter.report(
              messageJsInteropStaticInteropExternalExtensionMembersWithTypeParameters,
              node.fileOffset,
              node.name.text.length,
              node.fileUri);
        }
      }
    }
    _inTearoff = isTearOffLowering(node);
    super.visitProcedure(node);
    _inTearoff = false;
    _staticTypeContext.leaveMember(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    final target = node.target;
    if (target == _functionToJSTarget) {
      final argument = node.arguments.positional.single;
      final functionType = argument.getStaticType(_staticTypeContext);
      if (functionType is! FunctionType) {
        _diagnosticsReporter.report(
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
      _diagnosticsReporter.report(
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
    _checkInstanceMemberJSAnnotation(node);
    if (!node.isSynthetic) {
      if (_classHasJSAnnotation && !node.isExternal) {
        // Non-synthetic constructors must be annotated with `external`.
        _diagnosticsReporter.report(messageJsInteropNonExternalConstructor,
            node.fileOffset, node.name.text.length, node.fileUri);
      }
      if (_classHasStaticInteropAnnotation) {
        _diagnosticsReporter.report(
            messageJsInteropStaticInteropGenerativeConstructor,
            node.fileOffset,
            node.name.text.length,
            node.fileUri);
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
    var constructor = node.target;
    if (constructor.isSynthetic &&
        // Synthetic tear-offs are created for synthetic constructors by
        // invoking them, so they need to be excluded here.
        !_inTearoff &&
        hasStaticInteropAnnotation(constructor.enclosingClass)) {
      _diagnosticsReporter.report(
          messageJsInteropStaticInteropSyntheticConstructor,
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
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

  /// Reports an error if [functionNode] has named parameters.
  void _checkNoNamedParameters(FunctionNode functionNode) {
    // ignore: unnecessary_null_comparison
    if (functionNode != null && functionNode.namedParameters.isNotEmpty) {
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
    // Some backends have multiple native APIs.
    if (!enableDisallowedExternalCheck) return;
    if (member.isExternal) {
      if (_isAllowedExternalUsage(member)) return;
      if (member.isExtensionMember) {
        final annotatable =
            _inlineExtensionIndex.getExtensionAnnotatable(member);
        if (annotatable == null || !hasNativeAnnotation(annotatable)) {
          _diagnosticsReporter.report(
              messageJsInteropExternalExtensionMemberOnTypeInvalid,
              member.fileOffset,
              member.name.text.length,
              member.fileUri);
        }
      } else if (!hasJSInteropAnnotation(member)) {
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

  /// Verifies that use of `@trustTypes` is allowed.
  bool _isAllowedTrustTypesUsage(Class cls) {
    Uri uri = cls.enclosingLibrary.importUri;
    return uri.isScheme('dart') && uri.path == 'ui' ||
        _allowedTrustTypesTestPatterns
            .any((pattern) => uri.path.contains(pattern));
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

  /// Verifies given member is an external extension member on a static interop
  /// type that needs custom behavior.
  bool _isAllowedCustomStaticInteropImplementation(Member member) {
    Uri uri = member.enclosingLibrary.importUri;
    return uri.isScheme('dart') &&
            _customStaticInteropImplementations.contains(uri.path) ||
        _allowedNativeTestPatterns.any((pattern) => uri.path.contains(pattern));
  }

  /// Returns whether [member] is considered to be a JS interop member.
  ///
  /// A JS interop member is `external`, and is in a valid JS interop context,
  /// which can be:
  ///   - inside a JS interop class
  ///   - inside an extension on a JS interop annotatable
  ///   - inside a JS interop inline class
  ///   - a top level member that is JS interop annotated or in a JS interop
  ///     library
  /// If a member belongs to a class, the class must be JS interop annotated.
  bool _isJSInteropMember(Member member) {
    if (member.isExternal) {
      if (_classHasJSAnnotation) return true;
      if (member.isExtensionMember) {
        final annotatable =
            _inlineExtensionIndex.getExtensionAnnotatable(member);
        return annotatable != null && hasJSInteropAnnotation(annotatable);
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

  /// If [procedure] is a generated procedure that represents a relevant
  /// tear-off, return the torn-off member.
  ///
  /// Otherwise, return null.
  Member? _getTornOffFromGeneratedTearOff(Procedure procedure) {
    var tornOff = _inlineExtensionIndex.getInlineMemberForTearOff(procedure) ??
        _inlineExtensionIndex.getExtensionMemberForTearOff(procedure);
    if (tornOff != null) return tornOff.asMember;
    var name = extractConstructorNameFromTearOff(procedure.name);
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
      _diagnosticsReporter.report(
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
      _diagnosticsReporter.report(
          messageJsInteropStaticInteropSyntheticConstructor,
          context.fileOffset,
          1,
          context.location!.file);
      return true;
    }
    return false;
  }
}

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
