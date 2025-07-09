// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc =
    'Do not expose implementation details through the analyzer public API.';

class AnalyzerPublicApi extends MultiAnalysisRule {
  static const ruleName = 'analyzer_public_api';

  /// Lint issued if a file in the analyzer public API contains a `part`
  /// directive that points to a file that's not in the analyzer public API.
  ///
  /// The rationale for this lint is that if such a `part` directive were to
  /// exist, it would cause all the members of the part file to become part of
  /// the analyzer's public API, even though they don't appear to be public API.
  ///
  /// Note that the analyzer doesn't make very much use of `part` directives,
  /// but it may do so in the future once augmentations and enhanced parts are
  /// supported.
  static const LintCode badPartDirective = LintCode(
    'analyzer_public_api_bad_part_directive',
    'Part directives in the analyzer public API should point to files in the '
        'analyzer public API.',
  );

  /// Lint issued if a method, function, getter, or setter in the analyzer
  /// public API makes use of a type that's not part of the analyzer public API,
  /// or if a non-public type appears in an `extends`, `implements`, `with`, or
  /// `on` clause.
  ///
  /// The reason this is a problem is that it makes it possible for analyzer
  /// clients to implicitly reference analyzer internal types. This can happen
  /// in many ways; here are some examples:
  ///
  /// - If `C` is a public API class that implements `B`, and `B` is a private
  ///   class with a getter called `x`, then a client can access `B.x` via `C`.
  ///
  /// - If `f` has return type `T`, and `T` is a private class with a getter
  ///   called `x`, then a client can access `T.x` via `f().x`.
  ///
  /// - If `f` has type `void Function(T)`, and `T` is a private class with a
  ///   getter called `x`, then a client can access `T.x` via
  ///   `var g = f; g = (t) { print(t.x); }`.
  ///
  /// This lint can be suppressed either with an `ignore` comment, or by marking
  /// the referenced type with `@AnalyzerPublicApi(...)`. The advantage of
  /// marking the referenced type with `@AnalyzerPublicApi(...)` is that it
  /// causes the members of referenced type to be checked by this lint.
  static const LintCode badType = LintCode(
    'analyzer_public_api_bad_type',
    'Element makes use of type(s) which is not part of the analyzer public '
        'API: {0}.',
  );

  /// Lint issued if a file in the analyzer public API contains an `export`
  /// directive that exports a name that's not part of the analyzer public API.
  ///
  /// This lint can be suppressed either with an `ignore` comment, or by marking
  /// the exported declaration with `@AnalyzerPublicApi(...)`. The advantage of
  /// marking the exported declaration with `@AnalyzerPublicApi(...)` is that it
  /// causes the members of the exported declaration to be checked by this lint.
  static const LintCode exportsNonPublicName = LintCode(
    'analyzer_public_api_exports_non_public_name',
    'Export directive exports element(s) that are not part of the analyzer '
        'public API: {0}.',
  );

  /// Lint issued if a top level declaration in the analyzer public API has a
  /// name ending in `Impl`.
  ///
  /// Such declarations are not meant to be members of the analyzer public API,
  /// so if they are either declared outside of `package:analyzer/src`, or
  /// marked with `@AnalyzerPublicApi(...)`, that is almost certainly a mistake.
  static const LintCode implInPublicApi = LintCode(
    'analyzer_public_api_impl_in_public_api',
    'Declarations in the analyzer public API should not end in "Impl".',
  );

  AnalyzerPublicApi()
    : super(
        name: ruleName,
        description: _desc,
        state: const RuleState.internal(),
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    badPartDirective,
    badType,
    exportsNonPublicName,
    implInPublicApi,
  ];

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addExportDirective(this, visitor);
    registry.addPartDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  /// Elements that are imported into the current compilation unit's import
  /// namespace via `import` directives that do *not* access a package's `src`
  /// directory.
  ///
  /// Elements in this set are part of the public APIs of their respective
  /// packages, so it is safe for a part of the analyzer public API to refer to
  /// them.
  late Set<Element> importedPublicElements;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    importedPublicElements = _computeImportedPublicElements(node);
    node.declaredFragment!.children.forEach(_checkTopLevelFragment);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    // Any export directive in the analyzer public `lib` is checked to make sure
    // that everything it re-exports is either also in the analyzer public `lib`
    // or is annotated `@AnalyzerPublicApi(...)`.
    var exportElement = node.libraryExport!;
    if (!exportElement.libraryFragment.source.uri.isInAnalyzerPublicLib) {
      return;
    }

    // Figure out which elements from the exported library are public and not
    // blocked by any of the export directive's combinators.
    // TODO(paulberry): consider adding something to the analyzer API that
    // computes which names are filtered by a sequence of combinators.
    Set<String>? badNames;
    var exportedLibrary = exportElement.exportedLibrary2!;
    for (var member in exportedLibrary.children) {
      var name = member.name;
      if (name == null) continue;
      if (exportElement.combinators.any(
        (combinator) => combinator.blocksName(name),
      )) {
        continue;
      }

      // The exported element must either be in the analyzer public `lib` or be
      // annotated `@AnalyzerPublicApi()`.
      if (!member.isOkForAnalyzerPublicApi) {
        (badNames ??= {}).add(name);
      }
    }

    if (badNames != null) {
      rule.reportAtNode(
        node,
        diagnosticCode: AnalyzerPublicApi.exportsNonPublicName,
        arguments: [badNames.join(', ')],
      );
    }
  }

  @override
  void visitPartDirective(PartDirective node) {
    // Any part directive in the analyzer public `lib` must point to a file in
    // the analyzer public `lib`.
    var partElement = node.partInclude!;
    if (!partElement.libraryFragment.source.uri.isInAnalyzerPublicLib) {
      return;
    }
    if (!partElement.includedFragment!.source.uri.isInAnalyzerPublicLib) {
      rule.reportAtNode(
        node,
        diagnosticCode: AnalyzerPublicApi.badPartDirective,
      );
    }
  }

  void _checkMember(Fragment fragment) {
    if (fragment is ConstructorFragment &&
        fragment.element.enclosingElement is EnumElement) {
      // Enum constructors aren't callable from outside of the enum, so they
      // aren't public API.
      return;
    }
    var name = fragment.name;
    if (name != null && !name.isPublic) {
      // Private member; no need to check.
      return;
    }
    if (fragment is ExecutableFragment) {
      _checkType(fragment.element.type, fragment: fragment);
    }
  }

  void _checkTopLevelFragment(Fragment fragment) {
    if (!fragment.element.isInAnalyzerPublicApi) return;
    var name = fragment.name;
    if (name != null && name.endsWith('Impl')) {
      // Nothing in the analyzer public API may have a name ending in `Impl`.
      rule.reportAtOffset(
        fragment.nameOffset2!,
        name.length,
        diagnosticCode: AnalyzerPublicApi.implInPublicApi,
      );
    }
    switch (fragment) {
      case ExtensionFragment(name: null):
        // Unnamed extensions are not public, so ignore.
        break;
      case InstanceFragment(:var typeParameters2, :var children):
        for (var typeParameter in typeParameters2) {
          _checkTypeParameter(typeParameter, fragment: fragment);
        }
        if (fragment case InterfaceFragment(
          :var supertype,
          :var interfaces,
          :var mixins,
        )) {
          _checkType(supertype, fragment: fragment);
          for (var t in interfaces) {
            _checkType(t, fragment: fragment);
          }
          for (var t in mixins) {
            _checkType(t, fragment: fragment);
          }
        }
        if (fragment case ExtensionFragment(:var element)) {
          _checkType(element.extendedType, fragment: fragment);
        }
        if (fragment case MixinFragment(:var superclassConstraints)) {
          for (var t in superclassConstraints) {
            _checkType(t, fragment: fragment);
          }
        }
        children.forEach(_checkMember);
      case ExecutableFragment():
        _checkType(fragment.element.type, fragment: fragment);
      case TypeAliasFragment(:var element, :var typeParameters2):
        var aliasedType = element.aliasedType;
        _checkType(element.aliasedType, fragment: fragment);
        if (typeParameters2.isNotEmpty &&
            aliasedType is FunctionType &&
            aliasedType.typeParameters.isEmpty) {
          // Sometimes `aliasedType` doesn't have the type parameters. Not sure
          // why.
          // TODO(paulberry): consider fixing this in the analyzer.
          for (var typeParameter in typeParameters2) {
            _checkTypeParameter(typeParameter, fragment: fragment);
          }
        }
    }
  }

  void _checkType(DartType? type, {required Fragment fragment}) {
    if (type == null) return;
    var problems = _problemsForAnalyzerPublicApi(type);
    if (problems.isEmpty) return;
    int offset;
    int length;
    while (true) {
      if (fragment.nameOffset2 != null) {
        offset = fragment.nameOffset2!;
        length = fragment.name!.length;
        break;
      } else if (fragment case PropertyAccessorFragment()
          when fragment.element.variable3!.firstFragment.nameOffset2 != null) {
        offset = fragment.element.variable3!.firstFragment.nameOffset2!;
        length = fragment.element.variable3!.name!.length;
        break;
      } else if (fragment is ConstructorFragment &&
          fragment.typeNameOffset != null) {
        offset = fragment.typeNameOffset!;
        length = fragment.enclosingFragment!.name!.length;
        break;
      } else if (fragment.enclosingFragment case var enclosingFragment?) {
        fragment = enclosingFragment;
      } else {
        // This should never happen. But if it does, make sure we generate a
        // lint anyway.
        offset = 0;
        length = 1;
        break;
      }
    }
    rule.reportAtOffset(
      offset,
      length,
      diagnosticCode: AnalyzerPublicApi.badType,
      arguments: [problems.join(', ')],
    );
  }

  void _checkTypeParameter(
    TypeParameterFragment typeParameter, {
    required Fragment fragment,
  }) {
    _checkType(typeParameter.element.bound, fragment: fragment);
  }

  Set<String> _problemsForAnalyzerPublicApi(DartType type) {
    switch (type) {
      case RecordType(:var positionalFields, :var namedFields):
        return {
          for (var f in positionalFields)
            ..._problemsForAnalyzerPublicApi(f.type),
          for (var f in namedFields) ..._problemsForAnalyzerPublicApi(f.type),
        };
      case InterfaceType(:var element, :var typeArguments):
        return {
          if (!importedPublicElements.contains(element) &&
              !element.isOkForAnalyzerPublicApi)
            element.name!,
          for (var t in typeArguments) ..._problemsForAnalyzerPublicApi(t),
        };
      case NeverType():
      case DynamicType():
      case VoidType():
      case InvalidType():
      case TypeParameterType():
        return const {};
      case FunctionType(
        :var returnType,
        :var typeParameters,
        :var formalParameters,
      ):
        return {
          ..._problemsForAnalyzerPublicApi(returnType),
          for (var p in typeParameters)
            if (p.bound != null) ..._problemsForAnalyzerPublicApi(p.bound!),
          for (var p in formalParameters)
            ..._problemsForAnalyzerPublicApi(p.type),
        };
      default:
        throw StateError('Unexpected type $runtimeType');
    }
  }

  /// Called during [visitCompilationUnit] to compute the value of
  /// [importedPublicElements].
  static Set<Element> _computeImportedPublicElements(
    CompilationUnit compilationUnit,
  ) {
    var elements = <Element>{};
    for (var directive in compilationUnit.directives) {
      if (directive is! ImportDirective) continue;
      var libraryImport = directive.libraryImport!;
      var importedLibrary = libraryImport.importedLibrary2;
      if (importedLibrary == null) {
        // Import was unresolved. Ignore.
        continue;
      }
      if (importedLibrary.uri.isPublic) {
        elements.addAll(libraryImport.namespace.definedNames2.values);
      }
    }
    return elements;
  }
}

extension on String {
  bool get isPublic => !startsWith('_');
}

extension on Element {
  bool get isInAnalyzerPublicApi {
    if (this case PropertyAccessorElement(
      isSynthetic: true,
      :var variable3?,
    ) when variable3.isInAnalyzerPublicApi) {
      return true;
    }
    if (this case PropertyInducingElement(
      isSynthetic: true,
      :var getter2?,
    ) when getter2.isInAnalyzerPublicApi) {
      return true;
    }
    if (this case PropertyInducingElement(
      isSynthetic: true,
      :var setter2?,
    ) when setter2.isInAnalyzerPublicApi) {
      return true;
    }
    if (this case Annotatable(
      metadata: Metadata(:var annotations),
    ) when annotations.any(_isPublicApiAnnotation)) {
      return true;
    }
    if (name case var name? when !name.isPublic) return false;
    if (library!.uri.isInAnalyzerPublicLib) return true;
    return false;
  }

  bool get isOkForAnalyzerPublicApi {
    if (kind == ElementKind.DYNAMIC ||
        kind == ElementKind.TYPE_PARAMETER ||
        kind == ElementKind.NEVER) {
      return true;
    }
    if (library!.uri.isDartUri) return true;
    return isInAnalyzerPublicApi;
  }

  bool _isPublicApiAnnotation(ElementAnnotation annotation) {
    if (annotation.computeConstantValue() case DartObject(
      type: InterfaceType(
        // Note: in principle we ought to check the URI of the element too, but
        // in practice it doesn't matter (we don't expect to have multiple
        // declarations of this annotation that we need to distinguish), and the
        // advantage of not checking the URI is that unit testing is easier.
        element: InterfaceElement(name: 'AnalyzerPublicApi'),
      ),
    )) {
      return true;
    } else {
      return false;
    }
  }
}

extension on Uri {
  bool get isDartUri => scheme == 'dart';

  bool get isInAnalyzerPublicLib =>
      scheme == 'package' &&
      switch (pathSegments) {
        ['analyzer', 'src', ...] => false,
        ['analyzer', ...] => true,
        _ => false,
      };

  bool get isPublic =>
      scheme == 'package' &&
      switch (pathSegments) {
        [_, 'src', ...] => false,
        [_, ...] => true,
        _ => false,
      };
}

extension on NamespaceCombinator {
  bool blocksName(String name) {
    switch (this) {
      case HideElementCombinator(:var hiddenNames):
        return hiddenNames.contains(name);
      case ShowElementCombinator(:var shownNames):
        return !shownNames.contains(name);
    }
  }
}
