// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/source/line_info.dart' as analyzer;
import 'package:analyzer/source/source_range.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;

/// An object used to convert between objects defined by the 'analyzer' package
/// and those defined by the plugin protocol.
///
/// Clients may not extend, implement or mix-in this class.
class AnalyzerConverter {
  /// Converts the analysis [error] from the 'analyzer' package to an analysis
  /// error defined by the plugin API.
  ///
  /// If a [lineInfo] is provided then the error's location will have a start
  /// line and start column. If a [severity] is provided, then it will override
  /// the severity defined by the error.
  plugin.AnalysisError convertAnalysisError(
    analyzer.AnalysisError error, {
    analyzer.LineInfo? lineInfo,
    analyzer.ErrorSeverity? severity,
  }) {
    var errorCode = error.errorCode;
    severity ??= errorCode.errorSeverity;
    var offset = error.offset;
    var startLine = -1;
    var startColumn = -1;
    var endLine = -1;
    var endColumn = -1;
    if (lineInfo != null) {
      var startLocation = lineInfo.getLocation(offset);
      startLine = startLocation.lineNumber;
      startColumn = startLocation.columnNumber;
      var endLocation = lineInfo.getLocation(offset + error.length);
      endLine = endLocation.lineNumber;
      endColumn = endLocation.columnNumber;
    }
    List<plugin.DiagnosticMessage>? contextMessages;
    if (error.contextMessages.isNotEmpty) {
      contextMessages = error.contextMessages
          .map((message) =>
              convertDiagnosticMessage(message, lineInfo: lineInfo))
          .toList();
    }
    return plugin.AnalysisError(
        convertErrorSeverity(severity),
        convertErrorType(errorCode.type),
        plugin.Location(
            error.source.fullName, offset, error.length, startLine, startColumn,
            endLine: endLine, endColumn: endColumn),
        error.message,
        errorCode.name.toLowerCase(),
        contextMessages: contextMessages,
        correction: error.correction,
        hasFix: true);
  }

  /// Converts the list of analysis [errors] from the 'analyzer' package to a
  /// list of analysis errors defined by the plugin API.
  ///
  /// The severities of the errors are altered based on [options].
  List<plugin.AnalysisError> convertAnalysisErrors(
    List<analyzer.AnalysisError> errors, {
    // TODO(srawlins): Make `lineInfo` required and non-nullable, in a breaking
    // change release.
    analyzer.LineInfo? lineInfo,
    // TODO(srawlins): Make `options` required and non-nullable, in a breaking
    // change release.
    analyzer.AnalysisOptions? options,
  }) {
    var serverErrors = <plugin.AnalysisError>[];
    for (var error in errors) {
      var processor = analyzer.ErrorProcessor.getProcessor(options, error);
      if (processor != null) {
        var severity = processor.severity;
        // Errors with null severity are filtered out.
        if (severity != null) {
          // Specified severities override.
          serverErrors.add(convertAnalysisError(error,
              lineInfo: lineInfo, severity: severity));
        }
      } else {
        serverErrors.add(convertAnalysisError(error, lineInfo: lineInfo));
      }
    }
    return serverErrors;
  }

  /// Convert the diagnostic [message] from the 'analyzer' package to an
  /// analysis error defined by the plugin API. If a [lineInfo] is provided then
  /// the error's location will have a start line and start column.
  plugin.DiagnosticMessage convertDiagnosticMessage(
      analyzer.DiagnosticMessage message,
      {analyzer.LineInfo? lineInfo}) {
    var file = message.filePath;
    var offset = message.offset;
    var length = message.length;
    var startLine = -1;
    var startColumn = -1;
    var endLine = -1;
    var endColumn = -1;
    if (lineInfo != null) {
      var lineLocation = lineInfo.getLocation(offset);
      startLine = lineLocation.lineNumber;
      startColumn = lineLocation.columnNumber;
      var endLocation = lineInfo.getLocation(offset + length);
      endLine = endLocation.lineNumber;
      endColumn = endLocation.columnNumber;
    }
    return plugin.DiagnosticMessage(
        message.messageText(includeUrl: true),
        plugin.Location(file, offset, length, startLine, startColumn,
            endLine: endLine, endColumn: endColumn));
  }

  Element convertElement(analyzer.Element2 element) {
    var kind = convertElementToElementKind(element);
    var name = getElementDisplayName(element);
    var elementTypeParameters = _getTypeParametersString(element);
    var aliasedType = _getAliasedTypeString(element);
    var elementParameters = _getParametersString(element);
    var elementReturnType = _getReturnTypeString(element);
    return Element(
      kind,
      name,
      Element.makeFlags(
        isPrivate: element.isPrivate,
        isDeprecated: (element is analyzer.Annotatable) &&
            (element as analyzer.Annotatable).metadata2.hasDeprecated,
        isAbstract: _isAbstract(element),
        isConst: _isConst(element),
        isFinal: _isFinal(element),
        isStatic: _isStatic(element),
      ),
      location: newLocation_fromElement(element),
      typeParameters: elementTypeParameters,
      aliasedType: aliasedType,
      parameters: elementParameters,
      returnType: elementReturnType,
    );
  }

  /// Convert the element [kind] from the 'analyzer' package to an element kind
  /// defined by the plugin API.
  ///
  /// This method does not take into account that an instance of [ClassElement]
  /// can be an enum and an instance of [FieldElement] can be an enum constant.
  /// Use [_convertElementToElementKind] where possible.
  // TODO(srawlins): Deprecate this.
  plugin.ElementKind convertElementKind(analyzer.ElementKind kind) =>
      kind.toPluginElementKind;

  /// Return an [ElementKind] corresponding to the given [analyzer.Element2].
  ElementKind convertElementToElementKind(analyzer.Element2 element) {
    if (element is analyzer.EnumElement2) {
      return ElementKind.ENUM;
    } else if (element is analyzer.MixinElement2) {
      return ElementKind.MIXIN;
    }
    if (element is analyzer.FieldElement2 && element.isEnumConstant) {
      return ElementKind.ENUM_CONSTANT;
    }
    return convertElementKind(element.kind);
  }

  /// Convert the error [severity] from the 'analyzer' package to an analysis
  /// error severity defined by the plugin API.
  plugin.AnalysisErrorSeverity convertErrorSeverity(
          analyzer.ErrorSeverity severity) =>
      plugin.AnalysisErrorSeverity.values.byName(severity.name);

  /// Convert the error [type] from the 'analyzer' package to an analysis error
  /// type defined by the plugin API.
  plugin.AnalysisErrorType convertErrorType(analyzer.ErrorType type) =>
      plugin.AnalysisErrorType.values.byName(type.name);

  String getElementDisplayName(analyzer.Element2 element) {
    if (element is analyzer.LibraryFragment) {
      return path
          .basename((element as analyzer.LibraryFragment).source.fullName);
    } else {
      return element.displayName;
    }
  }

  /// Create a Location based on an [analyzer.Element2].
  Location? newLocation_fromElement(analyzer.Element2? element) {
    if (element == null) {
      return null;
    }
    if (element is analyzer.FormalParameterElement &&
        element.enclosingElement2 == null) {
      return null;
    }
    var fragment = element.firstFragment;
    var offset = fragment.nameOffset2 ?? -1;
    var length = fragment.name2?.length ?? 0;
    var range = analyzer.SourceRange(offset, length);
    return _locationForArgs(fragment, range);
  }

  String? _getAliasedTypeString(analyzer.Element2 element) {
    if (element is analyzer.TypeAliasElement2) {
      var aliasedType = element.aliasedType;
      return aliasedType.getDisplayString();
    }
    return null;
  }

  String? _getParametersString(analyzer.Element2 element) {
    // TODO(scheglov): expose the corresponding feature from ExecutableElement
    List<analyzer.FormalParameterElement> parameters;
    if (element is analyzer.ExecutableElement2) {
      // valid getters don't have parameters
      if (element.kind == analyzer.ElementKind.GETTER &&
          element.formalParameters.isEmpty) {
        return null;
      }
      parameters = element.formalParameters.toList();
    } else if (element is analyzer.TypeAliasElement2) {
      var aliasedType = element.aliasedType;
      if (aliasedType is FunctionType) {
        parameters = aliasedType.formalParameters.toList();
      } else {
        return null;
      }
    } else {
      return null;
    }

    parameters.sort(_preferRequiredParams);

    var sb = StringBuffer();
    var closeOptionalString = '';
    for (var parameter in parameters) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      if (closeOptionalString.isEmpty) {
        if (parameter.isNamed) {
          sb.write('{');
          closeOptionalString = '}';
        } else if (parameter.isOptionalPositional) {
          sb.write('[');
          closeOptionalString = ']';
        }
      }
      if (parameter.isRequiredNamed) {
        sb.write('required ');
      } else if (parameter.metadata2.hasDeprecated) {
        sb.write('@required ');
      }
      parameter.appendToWithoutDelimiters2(sb);
    }
    sb.write(closeOptionalString);
    return '($sb)';
  }

  String? _getReturnTypeString(analyzer.Element2 element) {
    if (element is analyzer.ExecutableElement2) {
      if (element.kind == analyzer.ElementKind.SETTER) {
        return null;
      } else {
        return element.returnType.getDisplayString();
      }
    } else if (element is analyzer.VariableElement2) {
      var type = element.type;
      return type.getDisplayString();
    } else if (element is analyzer.TypeAliasElement2) {
      var aliasedType = element.aliasedType;
      if (aliasedType is FunctionType) {
        var returnType = aliasedType.returnType;
        return returnType.getDisplayString();
      }
    }
    return null;
  }

  String? _getTypeParametersString(analyzer.Element2 element) {
    List<analyzer.TypeParameterElement2>? typeParameters;
    if (element is analyzer.InterfaceElement2) {
      typeParameters = element.typeParameters2;
    } else if (element is analyzer.TypeAliasElement2) {
      typeParameters = element.typeParameters2;
    }
    if (typeParameters == null || typeParameters.isEmpty) {
      return null;
    }
    return '<${typeParameters.join(', ')}>';
  }

  bool _isAbstract(analyzer.Element2 element) {
    if (element is analyzer.ClassElement2) {
      return element.isAbstract;
    }
    if (element is analyzer.MethodElement2) {
      return element.isAbstract;
    }
    if (element is analyzer.MixinElement2) {
      return true;
    }
    return false;
  }

  bool _isConst(analyzer.Element2 element) {
    if (element is analyzer.ConstructorElement2) {
      return element.isConst;
    }
    if (element is analyzer.VariableElement2) {
      return element.isConst;
    }
    return false;
  }

  bool _isFinal(analyzer.Element2 element) {
    if (element is analyzer.VariableElement2) {
      return element.isFinal;
    }
    return false;
  }

  bool _isStatic(analyzer.Element2 element) {
    if (element is analyzer.ExecutableElement2) {
      return element.isStatic;
    }
    if (element is analyzer.PropertyInducingElement2) {
      return element.isStatic;
    }
    return false;
  }

  /// Creates a new [Location].
  Location? _locationForArgs(
    analyzer.Fragment fragment,
    analyzer.SourceRange range,
  ) {
    var libraryFragment = fragment.libraryFragment;
    if (libraryFragment == null) {
      return null;
    }
    var lineInfo = libraryFragment.lineInfo;

    var startLocation = lineInfo.getLocation(range.offset);
    var endLocation = lineInfo.getLocation(range.end);

    var startLine = startLocation.lineNumber;
    var startColumn = startLocation.columnNumber;
    var endLine = endLocation.lineNumber;
    var endColumn = endLocation.columnNumber;

    return Location(
      fragment.libraryFragment!.source.fullName,
      range.offset,
      range.length,
      startLine,
      startColumn,
      endLine: endLine,
      endColumn: endColumn,
    );
  }

  /// Sort required named parameters before optional ones.
  int _preferRequiredParams(
    analyzer.FormalParameterElement e1,
    analyzer.FormalParameterElement e2,
  ) {
    var rank1 = (e1.isRequiredNamed || e1.metadata2.hasRequired)
        ? 0
        : !e1.isNamed
            ? -1
            : 1;
    var rank2 = (e2.isRequiredNamed || e2.metadata2.hasRequired)
        ? 0
        : !e2.isNamed
            ? -1
            : 1;
    return rank1 - rank2;
  }
}

// TODO(srawlins): Move this to a better location.
extension ElementKindExtensions on analyzer.ElementKind {
  static const _kindMap = {
    analyzer.ElementKind.CLASS: plugin.ElementKind.CLASS,
    analyzer.ElementKind.COMPILATION_UNIT: plugin.ElementKind.COMPILATION_UNIT,
    analyzer.ElementKind.CONSTRUCTOR: plugin.ElementKind.CONSTRUCTOR,
    analyzer.ElementKind.FIELD: plugin.ElementKind.FIELD,
    analyzer.ElementKind.FUNCTION: plugin.ElementKind.FUNCTION,
    analyzer.ElementKind.FUNCTION_TYPE_ALIAS:
        plugin.ElementKind.FUNCTION_TYPE_ALIAS,
    analyzer.ElementKind.GENERIC_FUNCTION_TYPE:
        plugin.ElementKind.FUNCTION_TYPE_ALIAS,
    analyzer.ElementKind.GETTER: plugin.ElementKind.GETTER,
    analyzer.ElementKind.LABEL: plugin.ElementKind.LABEL,
    analyzer.ElementKind.LIBRARY: plugin.ElementKind.LIBRARY,
    analyzer.ElementKind.LOCAL_VARIABLE: plugin.ElementKind.LOCAL_VARIABLE,
    analyzer.ElementKind.METHOD: plugin.ElementKind.METHOD,
    analyzer.ElementKind.PARAMETER: plugin.ElementKind.PARAMETER,
    analyzer.ElementKind.PREFIX: plugin.ElementKind.PREFIX,
    analyzer.ElementKind.SETTER: plugin.ElementKind.SETTER,
    analyzer.ElementKind.TOP_LEVEL_VARIABLE:
        plugin.ElementKind.TOP_LEVEL_VARIABLE,
    analyzer.ElementKind.TYPE_ALIAS: plugin.ElementKind.TYPE_ALIAS,
    analyzer.ElementKind.TYPE_PARAMETER: plugin.ElementKind.TYPE_PARAMETER,
  };

  /// Convert the element [kind] from the 'analyzer' package to an element kind
  /// defined by the plugin API.
  ///
  /// This method does not take into account that an instance of [ClassElement]
  /// can be an enum and an instance of [FieldElement] can be an enum constant.
  /// Use [_convertElementToElementKind] where possible.
  plugin.ElementKind get toPluginElementKind =>
      _kindMap[this] ?? plugin.ElementKind.UNKNOWN;
}
