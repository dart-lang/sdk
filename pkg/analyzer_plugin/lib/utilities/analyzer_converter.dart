// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;

/// An object used to convert between objects defined by the 'analyzer' package
/// and those defined by the plugin protocol.
///
/// Clients may not extend, implement or mix-in this class.
class AnalyzerConverter {
  /// Convert the analysis [error] from the 'analyzer' package to an analysis
  /// error defined by the plugin API. If a [lineInfo] is provided then the
  /// error's location will have a start line and start column. If a [severity]
  /// is provided, then it will override the severity defined by the error.
  plugin.AnalysisError convertAnalysisError(analyzer.AnalysisError error,
      {analyzer.LineInfo? lineInfo, analyzer.ErrorSeverity? severity}) {
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

  /// Convert the list of analysis [errors] from the 'analyzer' package to a
  /// list of analysis errors defined by the plugin API. If a [lineInfo] is
  /// provided then the resulting errors locations will have a start line and
  /// start column. If an analysis [options] is provided then the severities of
  /// the errors will be altered based on those options.
  List<plugin.AnalysisError> convertAnalysisErrors(
      List<analyzer.AnalysisError> errors,
      {analyzer.LineInfo? lineInfo,
      analyzer.AnalysisOptions? options}) {
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

  /// Convert the given [element] from the 'analyzer' package to an element
  /// defined by the plugin API.
  plugin.Element convertElement(analyzer.Element element) {
    var kind = _convertElementToElementKind(element);
    return plugin.Element(
      kind,
      element.displayName,
      plugin.Element.makeFlags(
        isPrivate: element.isPrivate,
        isDeprecated: element.hasDeprecated,
        isAbstract: _isAbstract(element),
        isConst: _isConst(element),
        isFinal: _isFinal(element),
        isStatic: _isStatic(element),
      ),
      location: locationFromElement(element),
      typeParameters: _getTypeParametersString(element),
      aliasedType: _getAliasedTypeString(element),
      parameters: _getParametersString(element),
      returnType: _getReturnTypeString(element),
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

  /// Convert the error [severity] from the 'analyzer' package to an analysis
  /// error severity defined by the plugin API.
  plugin.AnalysisErrorSeverity convertErrorSeverity(
          analyzer.ErrorSeverity severity) =>
      plugin.AnalysisErrorSeverity(severity.name);

  /// Convert the error [type] from the 'analyzer' package to an analysis error
  /// type defined by the plugin API.
  plugin.AnalysisErrorType convertErrorType(analyzer.ErrorType type) =>
      plugin.AnalysisErrorType(type.name);

  /// Create a location based on an the given [element].
  // TODO(srawlins): Deprecate this.
  plugin.Location? locationFromElement(analyzer.Element? element,
          {int? offset, int? length}) =>
      element.toLocation(offset: offset, length: length);

  /// Convert the element kind of the [element] from the 'analyzer' package to
  /// an element kind defined by the plugin API.
  plugin.ElementKind _convertElementToElementKind(analyzer.Element element) {
    if (element is analyzer.EnumElement) {
      return plugin.ElementKind.ENUM;
    } else if (element is analyzer.FieldElement && element.isEnumConstant
        // MyEnum.values and MyEnum.one.index return isEnumConstant = true
        // so these additional checks are necessary.
        // TODO(danrubel) MyEnum.values is constant, but is a list
        // so should it return isEnumConstant = true?
        // MyEnum.one.index is final but *not* constant
        // so should it return isEnumConstant = true?
        // Or should we return ElementKind.ENUM_CONSTANT here
        // in either or both of these cases?
        ) {
      final type = element.type;
      if (type is InterfaceType && type.element == element.enclosingElement) {
        return plugin.ElementKind.ENUM_CONSTANT;
      }
    }
    return convertElementKind(element.kind);
  }

  String? _getAliasedTypeString(analyzer.Element element) {
    if (element is analyzer.TypeAliasElement) {
      var aliasedType = element.aliasedType;
      return aliasedType.getDisplayString(withNullability: false);
    }
    return null;
  }

  /// Return a textual representation of the parameters of the given [element],
  /// or `null` if the element does not have any parameters.
  String? _getParametersString(analyzer.Element element) {
    // TODO(scheglov) expose the corresponding feature from ExecutableElement
    List<analyzer.ParameterElement> parameters;
    if (element is analyzer.ExecutableElement) {
      // valid getters don't have parameters
      if (element.kind == analyzer.ElementKind.GETTER &&
          element.parameters.isEmpty) {
        return null;
      }
      parameters = element.parameters;
    } else if (element is analyzer.TypeAliasElement) {
      var aliasedElement = element.aliasedElement;
      if (aliasedElement is analyzer.GenericFunctionTypeElement) {
        parameters = aliasedElement.parameters;
      } else {
        return null;
      }
    } else {
      return null;
    }
    var buffer = StringBuffer();
    var closeOptionalString = '';
    buffer.write('(');
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (i > 0) {
        buffer.write(', ');
      }
      if (closeOptionalString.isEmpty) {
        if (parameter.isNamed) {
          buffer.write('{');
          closeOptionalString = '}';
        } else if (parameter.isOptionalPositional) {
          buffer.write('[');
          closeOptionalString = ']';
        }
      }
      parameter.appendToWithoutDelimiters(buffer, withNullability: false);
    }
    buffer.write(closeOptionalString);
    buffer.write(')');
    return buffer.toString();
  }

  /// Return a textual representation of the return type of the given [element],
  /// or `null` if the element does not have a return type.
  String? _getReturnTypeString(analyzer.Element element) {
    if (element is analyzer.ExecutableElement) {
      if (element.kind == analyzer.ElementKind.SETTER) {
        return null;
      }
      return element.returnType.getDisplayString(withNullability: false);
    } else if (element is analyzer.VariableElement) {
      return element.type.getDisplayString(withNullability: false);
    } else if (element is analyzer.TypeAliasElement) {
      var aliasedType = element.aliasedType;
      if (aliasedType is FunctionType) {
        var returnType = aliasedType.returnType;
        return returnType.getDisplayString(withNullability: false);
      }
    }
    return null;
  }

  /// Return a textual representation of the type parameters of the given
  /// [element], or `null` if the element does not have type parameters.
  String? _getTypeParametersString(analyzer.Element element) {
    if (element is analyzer.TypeParameterizedElement) {
      var typeParameters = element.typeParameters;
      if (typeParameters.isEmpty) {
        return null;
      }
      return '<${typeParameters.join(', ')}>';
    }
    return null;
  }

  bool _isAbstract(analyzer.Element element) {
    // TODO(scheglov) add isAbstract to Element API
    if (element is analyzer.ClassElement) {
      return element.isAbstract;
    } else if (element is analyzer.MethodElement) {
      return element.isAbstract;
    } else if (element is analyzer.PropertyAccessorElement) {
      return element.isAbstract;
    }
    return false;
  }

  bool _isConst(analyzer.Element element) {
    // TODO(scheglov) add isConst to Element API
    if (element is analyzer.ConstructorElement) {
      return element.isConst;
    } else if (element is analyzer.VariableElement) {
      return element.isConst;
    }
    return false;
  }

  bool _isFinal(analyzer.Element element) {
    // TODO(scheglov) add isFinal to Element API
    if (element is analyzer.VariableElement) {
      return element.isFinal;
    }
    return false;
  }

  bool _isStatic(analyzer.Element element) {
    // TODO(scheglov) add isStatic to Element API
    if (element is analyzer.ExecutableElement) {
      return element.isStatic;
    } else if (element is analyzer.PropertyInducingElement) {
      return element.isStatic;
    }
    return false;
  }
}

// TODO(srawlins): Move this to a better location.
extension ElementExtensions on analyzer.Element? {
  /// Return the compilation unit containing the given [element].
  analyzer.CompilationUnitElement? get _unitElement {
    var currentElement = this;
    if (currentElement is analyzer.CompilationUnitElement) {
      return currentElement;
    }
    if (currentElement?.enclosingElement is analyzer.LibraryElement) {
      currentElement = currentElement?.enclosingElement;
    }
    if (currentElement is analyzer.LibraryElement) {
      return currentElement.definingCompilationUnit;
    }
    for (;
        currentElement != null;
        currentElement = currentElement.enclosingElement) {
      if (currentElement is analyzer.CompilationUnitElement) {
        return currentElement;
      }
    }
    return null;
  }

  /// Create a location based on an the given [element].
  plugin.Location? toLocation({int? offset, int? length}) {
    var self = this;
    if (self == null || self.source == null) {
      return null;
    }
    offset ??= self.nameOffset;
    length ??= self.nameLength;
    if (self is analyzer.CompilationUnitElement ||
        (self is analyzer.LibraryElement && offset < 0)) {
      offset = 0;
      length = 0;
    }
    return _locationForArgs(
        self._unitElement, analyzer.SourceRange(offset, length));
  }

  /// Create and return a location within the given [unitElement] at the given
  /// [range].
  plugin.Location? _locationForArgs(
      analyzer.CompilationUnitElement? unitElement,
      analyzer.SourceRange range) {
    if (unitElement == null) {
      return null;
    }

    var lineInfo = unitElement.lineInfo;
    var offsetLocation = lineInfo.getLocation(range.offset);
    var endLocation = lineInfo.getLocation(range.offset + range.length);
    var startLine = offsetLocation.lineNumber;
    var startColumn = offsetLocation.columnNumber;
    var endLine = endLocation.lineNumber;
    var endColumn = endLocation.columnNumber;

    return plugin.Location(unitElement.source.fullName, range.offset,
        range.length, startLine, startColumn,
        endLine: endLine, endColumn: endColumn);
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
