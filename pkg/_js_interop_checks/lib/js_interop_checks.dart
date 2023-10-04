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
        messageJsInteropExtensionTypeMemberNotInterop,
        messageJsInteropExtensionTypeUsedWithWrongJsAnnotation,
        messageJsInteropExternalExtensionMemberOnTypeInvalid,
        messageJsInteropExternalExtensionMemberWithStaticDisallowed,
        messageJsInteropExternalMemberNotJSAnnotated,
        messageJsInteropInvalidStaticClassMemberName,
        messageJsInteropNamedParameters,
        messageJsInteropNonExternalConstructor,
        messageJsInteropNonExternalMember,
        messageJsInteropOperatorCannotBeRenamed,
        messageJsInteropOperatorsNotSupported,
        messageJsInteropStaticInteropExternalMemberWithInvalidTypeParameters,
        messageJsInteropStaticInteropGenerativeConstructor,
        messageJsInteropStaticInteropParameterInitializersAreIgnored,
        messageJsInteropStaticInteropSyntheticConstructor,
        templateJsInteropDartClassExtendsJSClass,
        templateJsInteropJSClassExtendsDartClass,
        templateJsInteropNonStaticWithStaticInteropSupertype,
        templateJsInteropStaticInteropNoJSAnnotation,
        templateJsInteropStaticInteropWithInstanceMembers,
        templateJsInteropStaticInteropWithInvalidJsTypesSupertype,
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
        templateJsInteropExtensionTypeNotInterop,
        templateJsInteropFunctionToJSRequiresStaticType,
        templateJsInteropStaticInteropExternalTypeViolation;

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide Pattern;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';

import 'src/js_interop.dart';

class JsInteropChecks extends RecursiveVisitor {
  final Set<Constant> _constantCache = {};
  final CoreTypes _coreTypes;
  late final ExtensionIndex _extensionIndex;
  final Procedure _functionToJSTarget;
  // Errors on constants need source information, so we use the surrounding
  // `ConstantExpression` as the source.
  ConstantExpression? _lastConstantExpression;
  final Map<String, Class> _nativeClasses;
  final JsInteropDiagnosticReporter _reporter;
  final StatefulStaticTypeContext _staticTypeContext;
  late _TypeParameterBoundChecker _typeParameterBoundChecker;
  bool _classHasJSAnnotation = false;
  bool _classHasAnonymousAnnotation = false;
  bool _classHasStaticInteropAnnotation = false;
  final _checkDisallowedInterop = false;
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
    RegExp(r'(?<!generated_)tests/web_2/native'),
    RegExp(r'(?<!generated_)tests/web_2/internal'),
    'generated_tests/web_2/native/native_test',
  ];

  static final List<Pattern> _allowedTrustTypesTestPatterns = [
    RegExp(r'(?<!generated_)tests/lib/js'),
    RegExp(r'(?<!generated_)tests/lib_2/js'),
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
      {this.isDart2Wasm = false})
      : exportChecker = ExportChecker(_reporter, _coreTypes.objectClass),
        _functionToJSTarget = _coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {
    _extensionIndex =
        ExtensionIndex(_coreTypes, _staticTypeContext.typeEnvironment);
    _typeParameterBoundChecker = _TypeParameterBoundChecker(_extensionIndex);
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
        !_extensionIndex.isInteropExtensionType(node)) {
      _reporter.report(
          templateJsInteropExtensionTypeNotInterop.withArguments(
              node.name, node.declaredRepresentationType, true),
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
      if (superclass != null) {
        _checkSuperclassOfStaticInteropClass(node, superclass);
      }
      // Validate that superinterfaces are all valid supertypes as well. Note
      // that mixins are already disallowed and therefore are not checked here.
      for (final supertype in node.implementedTypes) {
        _checkSuperclassOfStaticInteropClass(node, supertype.classNode);
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

    // TODO(srujzs): Should we still keep around this check? Currently, it's
    // unused since we allow the old interop on dart2wasm, but we should
    // disallow them eventually.
    if (_checkDisallowedInterop) _checkDisallowedLibrariesForDart2Wasm(node);

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
    // in external extension members and extension types.
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
      final isObjectLiteralConstructor = node.isExtensionTypeMember &&
          (_extensionIndex.getExtensionTypeDescriptor(node)!.kind ==
                  ExtensionTypeMemberKind.Constructor ||
              _extensionIndex.getExtensionTypeDescriptor(node)!.kind ==
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
        late Annotatable? annotatable;
        if (node.isExtensionTypeMember) {
          annotatable = _extensionIndex.getExtensionType(node);
        } else if (node.isExtensionMember) {
          annotatable = _extensionIndex.getExtensionAnnotatable(node);
          if (annotatable != null) {
            // We do not support external extension members with the 'static'
            // keyword currently.
            if (_extensionIndex.getExtensionDescriptor(node)!.isStatic) {
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
            _checkStaticInteropMemberUsesValidTypeParameters(node);
            final function = node.function;
            _reportProcedureIfNotAllowedType(function.returnType, node);
            for (final parameter in function.positionalParameters) {
              _reportProcedureIfNotAllowedType(parameter.type, node);
            }
            for (final parameter in function.namedParameters) {
              _reportProcedureIfNotAllowedType(parameter.type, node);
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

  void _checkDisallowedLibrariesForDart2Wasm(Library node) {
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
        final annotatable = _extensionIndex.getExtensionAnnotatable(member);
        if (annotatable == null) {
          _reporter.report(messageJsInteropExternalExtensionMemberOnTypeInvalid,
              member.fileOffset, member.name.text.length, member.fileUri);
        }
      } else if (member.isExtensionTypeMember) {
        final extensionType = _extensionIndex.getExtensionType(member);
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
    if (member.isExternal) {
      var memberKind = '';
      var memberName = '';
      if (member.isExtensionTypeMember) {
        // Extension type interop members can not be torn off.
        if (_extensionIndex.getExtensionType(member) == null) {
          return false;
        }
        memberKind = 'extension type interop member';
        memberName =
            _extensionIndex.getExtensionTypeDescriptor(member)!.name.text;
        if (memberName.isEmpty) memberName = 'new';
      } else if (member.isExtensionMember) {
        // JS interop members can not be torn off.
        if (_extensionIndex.getExtensionAnnotatable(member) == null) {
          return false;
        }
        memberKind = 'extension interop member';
        memberName = _extensionIndex.getExtensionDescriptor(member)!.name.text;
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
      _reportStaticInvocationIfNotAllowedType(functionType.returnType, node);
      for (final parameter in functionType.positionalParameters) {
        _reportStaticInvocationIfNotAllowedType(parameter, node);
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
    if ((node.isExtensionTypeMember &&
            _extensionIndex.getExtensionTypeDescriptor(node)?.kind ==
                ExtensionTypeMemberKind.Operator) ||
        (node.isExtensionMember &&
            _extensionIndex.getExtensionDescriptor(node)?.kind ==
                ExtensionMemberKind.Operator)) {
      final operator =
          _extensionIndex.getExtensionTypeDescriptor(node)?.name.text ??
              _extensionIndex.getExtensionDescriptor(node)?.name.text;
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

  void _checkStaticInteropMemberUsesValidTypeParameters(Procedure node) {
    if (_typeParameterBoundChecker.containsInvalidTypeBound(node)) {
      _reporter.report(
          messageJsInteropStaticInteropExternalMemberWithInvalidTypeParameters,
          node.fileOffset,
          node.name.text.length,
          node.fileUri);
    }
  }

  /// Reports an error if @staticInterop classes extends or implements a
  /// non-@staticInterop type or an invalid dart:_js_types type.
  void _checkSuperclassOfStaticInteropClass(Class node, Class superclass) {
    void report(Message message) => _reporter.report(
        message, node.fileOffset, node.name.length, node.fileUri);
    if (!hasStaticInteropAnnotation(superclass)) {
      report(templateJsInteropStaticInteropWithNonStaticSupertype.withArguments(
          node.name, superclass.name));
    } else {
      // dart:_js_types @staticInterop types are special. They are custom-erased
      // to different types at runtime. User @staticInterop types are always
      // erased to JavaScriptObject. As such, this means that we should only
      // allow users to subtype dart:_js_types types that erase to a
      // T >: JavaScriptObject. Currently, this is only JSObject and JSAny.
      // TODO(srujzs): This error should be temporary. In the future, once we
      // have extension types that can implement concrete classes, we can move
      // all the dart:_js_types that aren't JSObject and JSAny to extension
      // types. Then, this error becomes redundant. This would also allow us to
      // idiomatically add type parameters to JSArray and JSPromise.
      final superclassUri = superclass.enclosingLibrary.importUri;
      // Make an exception for some internal libraries.
      final allowList = {'_js_types', '_js_helper'};
      if (superclassUri.isScheme('dart') &&
          superclassUri.path == '_js_types' &&
          !allowList.contains(node.enclosingLibrary.importUri.path) &&
          superclass.name != 'JSAny' &&
          superclass.name != 'JSObject') {
        report(templateJsInteropStaticInteropWithInvalidJsTypesSupertype
            .withArguments(node.name, superclass.name));
      }
    }
  }

  /// If [procedure] is a generated procedure that represents a relevant
  /// tear-off, return the torn-off member.
  ///
  /// Otherwise, return null.
  Member? _getTornOffFromGeneratedTearOff(Procedure procedure) {
    final tornOff =
        _extensionIndex.getExtensionTypeMemberForTearOff(procedure) ??
            _extensionIndex.getExtensionMemberForTearOff(procedure);
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
        return _extensionIndex.getExtensionAnnotatable(member) != null;
      }
      if (member.isExtensionTypeMember) {
        return _extensionIndex.getExtensionType(member) != null;
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

  bool _isAllowedExternalType(DartType type) {
    // TODO(joshualitt): We allow only JS types on external JS interop APIs with
    // two exceptions: `void` and `Null`. Both of these exceptions exist largely
    // to support passing Dart functions to JS as callbacks.  Furthermore, both
    // of these types mean no actual values needs to be returned to JS. That
    // said, for completeness, we may restrict these two types someday, and
    // provide JS types equivalents, but likely only if we have implicit
    // conversions between Dart types and JS types.

    // Type parameter types are checked elsewhere.
    if (type is VoidType || type is NullType || type is TypeParameterType) {
      return true;
    }
    if (type is InterfaceType) {
      final cls = type.classNode;
      if (cls == _coreTypes.boolClass ||
          cls == _coreTypes.numClass ||
          cls == _coreTypes.doubleClass ||
          cls == _coreTypes.intClass ||
          cls == _coreTypes.stringClass) {
        return true;
      }
      if (hasStaticInteropAnnotation(cls)) return true;
    }
    if (type is ExtensionType) {
      if (_extensionIndex
          .isInteropExtensionType(type.extensionTypeDeclaration)) {
        return true;
      }
      // Extension types where the representation type is allowed are okay.
      // TODO(srujzs): Once the CFE pre-computes the concrete type, don't
      // recurse.
      return _isAllowedExternalType(type.typeErasure);
    }
    return false;
  }

  void _reportIfNotAllowedExternalType(
      DartType type, TreeNode node, Name name, Uri? fileUri) {
    if (!_isAllowedExternalType(type)) {
      _reporter.report(
          templateJsInteropStaticInteropExternalTypeViolation.withArguments(
              type, true),
          node.fileOffset,
          name.text.length,
          fileUri);
    }
  }

  void _reportProcedureIfNotAllowedType(DartType type, Procedure node) =>
      _reportIfNotAllowedExternalType(type, node, node.name, node.fileUri);

  void _reportStaticInvocationIfNotAllowedType(
          DartType type, StaticInvocation node) =>
      _reportIfNotAllowedExternalType(
          type, node, node.name, node.location?.file);
}

/// Visitor used to check that all usages of type parameter types of an external
/// static interop member is a valid static interop type.
class _TypeParameterBoundChecker extends RecursiveVisitor {
  final ExtensionIndex _extensionIndex;

  _TypeParameterBoundChecker(this._extensionIndex);

  bool _containsInvalidTypeBound = false;

  bool containsInvalidTypeBound(Procedure node) {
    _containsInvalidTypeBound = false;
    final function = node.function;
    for (final param in function.positionalParameters) {
      param.accept(this);
    }
    function.returnType.accept(this);
    return _containsInvalidTypeBound;
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    final cls = node.classNode;
    if (hasStaticInteropAnnotation(cls)) return;
    super.visitInterfaceType(node);
  }

  @override
  void visitExtensionType(ExtensionType node) {
    if (_extensionIndex.isInteropExtensionType(node.extensionTypeDeclaration)) {
      return;
    }
    super.visitExtensionType(node);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    final bound = node.bound;
    if (bound is ExtensionType &&
        !_extensionIndex
            .isInteropExtensionType(bound.extensionTypeDeclaration)) {
      _containsInvalidTypeBound = true;
    }
    if (bound is InterfaceType &&
        !hasStaticInteropAnnotation(bound.classNode)) {
      _containsInvalidTypeBound = true;
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
