// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../diagnostic.dart' as diag;

const _desc =
    'Do not expose implementation details through the analyzer public API.';

class AnalyzerPublicApi extends MultiAnalysisRule {
  static const ruleName = 'analyzer_public_api';

  AnalyzerPublicApi()
    : super(
        name: ruleName,
        description: _desc,
        state: const RuleState.internal(),
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.analyzerPublicApiBadPartDirective,
    diag.analyzerPublicApiBadType,
    diag.analyzerPublicApiExperimentalInconsistency,
    diag.analyzerPublicApiExportsNonPublicName,
    diag.analyzerPublicApiImplInPublicApi,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addExportDirective(this, visitor);
    registry.addPartDirective(this, visitor);
  }
}

/// Types of problematic uses of types that can be detected by this lint.
enum _ProblematicTypeUseKind {
  /// Use of a non-public type by a part of the analyzer public API.
  useOfNonPublicType,

  /// Use of an experimental type by a non-experimental part of the analyzer
  /// public API.
  useOfExperimentalType,
}

/// Lightweight object representing a public import.
class _PublicImport {
  final Element? Function(String name) lookup;

  _PublicImport({required this.lookup});
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  /// Public imports of the current unit.
  List<_PublicImport> _publicImports = [];

  /// Cache for [_isPubliclyImported].
  Map<Element, bool> _isImportedMemo = Map.identity();

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _publicImports = _getPublicImports(node);
    _isImportedMemo = Map.identity();
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
    var exportedLibrary = exportElement.exportedLibrary!;
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
        diagnosticCode: diag.analyzerPublicApiExportsNonPublicName,
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
        diagnosticCode: diag.analyzerPublicApiBadPartDirective,
      );
    }
  }

  void _checkMember(Fragment fragment, {required bool isParentExperimental}) {
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
      _checkType(
        fragment.element.type,
        fragment: fragment,
        isUsageSiteExperimental:
            isParentExperimental || fragment.element.metadata.hasExperimental,
      );
    }
  }

  void _checkTopLevelFragment(Fragment fragment) {
    if (!fragment.element.isInAnalyzerPublicApi) return;
    var name = fragment.name;
    if (name != null && name.endsWith('Impl')) {
      // Nothing in the analyzer public API may have a name ending in `Impl`.
      rule.reportAtOffset(
        fragment.nameOffset!,
        name.length,
        diagnosticCode: diag.analyzerPublicApiImplInPublicApi,
      );
    }
    var isUsageSiteExperimental = fragment.element.metadata.hasExperimental;
    switch (fragment) {
      case ExtensionFragment(name: null):
        // Unnamed extensions are not public, so ignore.
        break;
      case InstanceFragment(:var typeParameters, :var children):
        for (var typeParameter in typeParameters) {
          _checkTypeParameter(
            typeParameter,
            fragment: fragment,
            isUsageSiteExperimental: isUsageSiteExperimental,
          );
        }
        if (fragment is InterfaceFragment) {
          var element = fragment.element;
          _checkType(
            element.supertype,
            fragment: fragment,
            isUsageSiteExperimental: isUsageSiteExperimental,
          );
          for (var t in element.interfaces) {
            _checkType(
              t,
              fragment: fragment,
              isUsageSiteExperimental: isUsageSiteExperimental,
            );
          }
          for (var t in element.mixins) {
            _checkType(
              t,
              fragment: fragment,
              isUsageSiteExperimental: isUsageSiteExperimental,
            );
          }
        }
        if (fragment case ExtensionFragment(:var element)) {
          _checkType(
            element.extendedType,
            fragment: fragment,
            isUsageSiteExperimental: isUsageSiteExperimental,
          );
        }
        if (fragment case MixinFragment(:var superclassConstraints)) {
          for (var t in superclassConstraints) {
            _checkType(
              t,
              fragment: fragment,
              isUsageSiteExperimental: isUsageSiteExperimental,
            );
          }
        }
        for (var child in children) {
          _checkMember(child, isParentExperimental: isUsageSiteExperimental);
        }
      case ExecutableFragment():
        _checkType(
          fragment.element.type,
          fragment: fragment,
          isUsageSiteExperimental: isUsageSiteExperimental,
        );
      case TypeAliasFragment(:var element, :var typeParameters):
        var aliasedType = element.aliasedType;
        _checkType(
          aliasedType,
          fragment: fragment,
          isUsageSiteExperimental: isUsageSiteExperimental,
        );
        if (typeParameters.isNotEmpty &&
            aliasedType is FunctionType &&
            aliasedType.typeParameters.isEmpty) {
          // Sometimes `aliasedType` doesn't have the type parameters. Not sure
          // why.
          // TODO(paulberry): consider fixing this in the analyzer.
          for (var typeParameter in typeParameters) {
            _checkTypeParameter(
              typeParameter,
              fragment: fragment,
              isUsageSiteExperimental: isUsageSiteExperimental,
            );
          }
        }
    }
  }

  void _checkType(
    DartType? type, {
    required Fragment fragment,
    required bool isUsageSiteExperimental,
  }) {
    if (type == null) return;
    var nonPublicProblems = _problemsForAnalyzerPublicApi(
      type,
      kind: _ProblematicTypeUseKind.useOfNonPublicType,
    );
    var experimentalProblems = isUsageSiteExperimental
        ? const <String>{}
        : _problemsForAnalyzerPublicApi(
            type,
            kind: _ProblematicTypeUseKind.useOfExperimentalType,
          );
    var offsetAndLength = _offsetAndLengthForFragment(fragment);
    if (nonPublicProblems.isNotEmpty) {
      rule.reportAtOffset(
        offsetAndLength.offset,
        offsetAndLength.length,
        diagnosticCode: diag.analyzerPublicApiBadType,
        arguments: [nonPublicProblems.join(', ')],
      );
    }
    if (experimentalProblems.isNotEmpty) {
      rule.reportAtOffset(
        offsetAndLength.offset,
        offsetAndLength.length,
        diagnosticCode: diag.analyzerPublicApiExperimentalInconsistency,
        arguments: [nonPublicProblems.join(', ')],
      );
    }
  }

  void _checkTypeParameter(
    TypeParameterFragment typeParameter, {
    required Fragment fragment,
    required bool isUsageSiteExperimental,
  }) {
    _checkType(
      typeParameter.element.bound,
      fragment: fragment,
      isUsageSiteExperimental: isUsageSiteExperimental,
    );
  }

  /// Whether [element] is visible through at least one public import.
  bool _isPubliclyImported(Element element) {
    var lookupName = element.lookupName;
    if (lookupName == null) return false;

    if (_isImportedMemo[element] case var cached?) {
      return cached;
    }

    for (var import in _publicImports) {
      var lookedUp = import.lookup(lookupName);
      if (lookedUp?.baseElement == element.baseElement) {
        _isImportedMemo[element] = true;
        return true;
      }
    }

    _isImportedMemo[element] = false;
    return false;
  }

  ({int length, int offset}) _offsetAndLengthForFragment(Fragment fragment) {
    while (true) {
      if (fragment.element case PropertyAccessorElement element) {
        if (element.isOriginVariable) {
          // ignore: parameter_assignments
          fragment = element.variable.firstFragment;
        }
      }
      if (fragment.element case FieldElement element) {
        if (element.isOriginDeclaringFormalParameter) {
          // ignore:parameter_assignments
          fragment = element.declaringFormalParameter!.firstFragment;
        }
      }

      if (fragment.nameOffset != null) {
        return (offset: fragment.nameOffset!, length: fragment.name!.length);
      } else if (fragment case PropertyAccessorFragment()
          when fragment.element.variable.firstFragment.nameOffset != null) {
        return (
          offset: fragment.element.variable.firstFragment.nameOffset!,
          length: fragment.element.variable.name!.length,
        );
      } else if (fragment is ConstructorFragment &&
          fragment.typeNameOffset != null) {
        return (
          offset: fragment.typeNameOffset!,
          length: fragment.enclosingFragment!.name!.length,
        );
      } else if (fragment.enclosingFragment case var enclosingFragment?) {
        // ignore: parameter_assignments
        fragment = enclosingFragment;
      } else {
        // This should never happen. But if it does, make sure we generate a
        // lint anyway.
        return (offset: 0, length: 1);
      }
    }
  }

  Set<String> _problemsForAnalyzerPublicApi(
    DartType type, {
    required _ProblematicTypeUseKind kind,
  }) {
    switch (type) {
      case RecordType(:var positionalFields, :var namedFields):
        return {
          for (var f in positionalFields)
            ..._problemsForAnalyzerPublicApi(f.type, kind: kind),
          for (var f in namedFields)
            ..._problemsForAnalyzerPublicApi(f.type, kind: kind),
        };
      case InterfaceType(:var element, :var typeArguments):
        var isProblematicElement = switch (kind) {
          _ProblematicTypeUseKind.useOfNonPublicType =>
            !_isPubliclyImported(element) && !element.isOkForAnalyzerPublicApi,
          _ProblematicTypeUseKind.useOfExperimentalType =>
            element.metadata.hasExperimental,
        };
        return {
          if (isProblematicElement) element.name!,
          for (var t in typeArguments)
            ..._problemsForAnalyzerPublicApi(t, kind: kind),
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
          ..._problemsForAnalyzerPublicApi(returnType, kind: kind),
          for (var p in typeParameters)
            if (p.bound != null)
              ..._problemsForAnalyzerPublicApi(p.bound!, kind: kind),
          for (var p in formalParameters)
            ..._problemsForAnalyzerPublicApi(p.type, kind: kind),
        };
      default:
        throw StateError('Unexpected type $runtimeType');
    }
  }

  static List<_PublicImport> _getPublicImports(CompilationUnit unit) {
    var result = <_PublicImport>[];
    for (var directive in unit.directives) {
      if (directive is! ImportDirective) continue;
      var libraryImport = directive.libraryImport!;
      var importedLibrary = libraryImport.importedLibrary;
      if (importedLibrary == null) continue;
      if (!importedLibrary.uri.isPublic) continue;
      var combinators = libraryImport.combinators;
      result.add(
        _PublicImport(
          lookup: (lookupName) {
            var baseName = lookupName.endsWith('=')
                ? lookupName.substring(0, lookupName.length - 1)
                : lookupName;
            if (combinators.any((c) => c.blocksName(baseName))) {
              return null;
            }
            return importedLibrary.exportNamespace.get2(lookupName);
          },
        ),
      );
    }
    return result;
  }
}

extension on String {
  bool get isPublic => !startsWith('_');
}

extension on Element {
  bool get isInAnalyzerPublicApi {
    if (this case PropertyAccessorElement(
      isOriginVariable: true,
      :var variable,
    ) when variable.isInAnalyzerPublicApi) {
      return true;
    }
    if (this case PropertyInducingElement(
      isOriginGetterSetter: true,
      :var getter?,
    ) when getter.isInAnalyzerPublicApi) {
      return true;
    }
    if (this case PropertyInducingElement(
      isOriginGetterSetter: true,
      :var setter?,
    ) when setter.isInAnalyzerPublicApi) {
      return true;
    }
    if (metadata.annotations.any(_isPublicApiAnnotation)) {
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
