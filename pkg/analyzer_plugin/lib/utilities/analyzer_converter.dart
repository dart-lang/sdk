// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart' as analyzer;
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/exception/exception.dart' as analyzer;
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * An object used to convert between objects defined by the 'analyzer' package
 * and those defined by the plugin protocol.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyzerConverter {
  /**
   * Convert the analysis [error] from the 'analyzer' package to an analysis
   * error defined by the plugin API. If a [lineInfo] is provided then the
   * error's location will have a start line and start column. If a [severity]
   * is provided, then it will override the severity defined by the error.
   */
  plugin.AnalysisError convertAnalysisError(analyzer.AnalysisError error,
      {analyzer.LineInfo lineInfo, analyzer.ErrorSeverity severity}) {
    analyzer.ErrorCode errorCode = error.errorCode;
    severity ??= errorCode.errorSeverity;
    int offset = error.offset;
    int startLine = -1;
    int startColumn = -1;
    if (lineInfo != null) {
      analyzer.LineInfo_Location lineLocation = lineInfo.getLocation(offset);
      if (lineLocation != null) {
        startLine = lineLocation.lineNumber;
        startColumn = lineLocation.columnNumber;
      }
    }
    return new plugin.AnalysisError(
        convertErrorSeverity(severity),
        convertErrorType(errorCode.type),
        new plugin.Location(error.source.fullName, offset, error.length,
            startLine, startColumn),
        error.message,
        errorCode.name.toLowerCase(),
        correction: error.correction,
        hasFix: true);
  }

  /**
   * Convert the list of analysis [errors] from the 'analyzer' package to a list
   * of analysis errors defined by the plugin API. If a [lineInfo] is provided
   * then the resulting errors locations will have a start line and start column.
   * If an analysis [options] is provided then the severities of the errors will
   * be altered based on those options.
   */
  List<plugin.AnalysisError> convertAnalysisErrors(
      List<analyzer.AnalysisError> errors,
      {analyzer.LineInfo lineInfo,
      analyzer.AnalysisOptions options}) {
    List<plugin.AnalysisError> serverErrors = <plugin.AnalysisError>[];
    for (analyzer.AnalysisError error in errors) {
      analyzer.ErrorProcessor processor =
          analyzer.ErrorProcessor.getProcessor(options, error);
      if (processor != null) {
        analyzer.ErrorSeverity severity = processor.severity;
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

  /**
   * Convert the given [element] from the 'analyzer' package to an element
   * defined by the plugin API.
   */
  plugin.Element convertElement(analyzer.Element element) {
    plugin.ElementKind kind = _convertElementToElementKind(element);
    return new plugin.Element(
        kind,
        element.displayName,
        plugin.Element.makeFlags(
            isPrivate: element.isPrivate,
            isDeprecated: element.isDeprecated,
            isAbstract: _isAbstract(element),
            isConst: _isConst(element),
            isFinal: _isFinal(element),
            isStatic: _isStatic(element)),
        location: _locationFromElement(element),
        typeParameters: _getTypeParametersString(element),
        parameters: _getParametersString(element),
        returnType: _getReturnTypeString(element));
  }

  /**
   * Convert the element [kind] from the 'analyzer' package to an element kind
   * defined by the plugin API.
   *
   * This method does not take into account that an instance of [ClassElement]
   * can be an enum and an instance of [FieldElement] can be an enum constant.
   * Use [_convertElementToElementKind] where possible.
   */
  plugin.ElementKind convertElementKind(analyzer.ElementKind kind) {
    if (kind == analyzer.ElementKind.CLASS) {
      return plugin.ElementKind.CLASS;
    } else if (kind == analyzer.ElementKind.COMPILATION_UNIT) {
      return plugin.ElementKind.COMPILATION_UNIT;
    } else if (kind == analyzer.ElementKind.CONSTRUCTOR) {
      return plugin.ElementKind.CONSTRUCTOR;
    } else if (kind == analyzer.ElementKind.FIELD) {
      return plugin.ElementKind.FIELD;
    } else if (kind == analyzer.ElementKind.FUNCTION) {
      return plugin.ElementKind.FUNCTION;
    } else if (kind == analyzer.ElementKind.FUNCTION_TYPE_ALIAS) {
      return plugin.ElementKind.FUNCTION_TYPE_ALIAS;
    } else if (kind == analyzer.ElementKind.GETTER) {
      return plugin.ElementKind.GETTER;
    } else if (kind == analyzer.ElementKind.LABEL) {
      return plugin.ElementKind.LABEL;
    } else if (kind == analyzer.ElementKind.LIBRARY) {
      return plugin.ElementKind.LIBRARY;
    } else if (kind == analyzer.ElementKind.LOCAL_VARIABLE) {
      return plugin.ElementKind.LOCAL_VARIABLE;
    } else if (kind == analyzer.ElementKind.METHOD) {
      return plugin.ElementKind.METHOD;
    } else if (kind == analyzer.ElementKind.PARAMETER) {
      return plugin.ElementKind.PARAMETER;
    } else if (kind == analyzer.ElementKind.PREFIX) {
      return plugin.ElementKind.PREFIX;
    } else if (kind == analyzer.ElementKind.SETTER) {
      return plugin.ElementKind.SETTER;
    } else if (kind == analyzer.ElementKind.TOP_LEVEL_VARIABLE) {
      return plugin.ElementKind.TOP_LEVEL_VARIABLE;
    } else if (kind == analyzer.ElementKind.TYPE_PARAMETER) {
      return plugin.ElementKind.TYPE_PARAMETER;
    }
    return plugin.ElementKind.UNKNOWN;
  }

  /**
   * Convert the error [severity] from the 'analyzer' package to an analysis
   * error severity defined by the plugin API.
   */
  plugin.AnalysisErrorSeverity convertErrorSeverity(
          analyzer.ErrorSeverity severity) =>
      new plugin.AnalysisErrorSeverity(severity.name);

  /**
   *Convert the error [type] from the 'analyzer' package to an analysis error
   * type defined by the plugin API.
   */
  plugin.AnalysisErrorType convertErrorType(analyzer.ErrorType type) =>
      new plugin.AnalysisErrorType(type.name);

  /**
   * Convert the element kind of the [element] from the 'analyzer' package to an
   * element kind defined by the plugin API.
   */
  plugin.ElementKind _convertElementToElementKind(analyzer.Element element) {
    if (element is analyzer.ClassElement && element.isEnum) {
      return plugin.ElementKind.ENUM;
    } else if (element is analyzer.FieldElement &&
        element.isEnumConstant &&
        // MyEnum.values and MyEnum.one.index return isEnumConstant = true
        // so these additional checks are necessary.
        // TODO(danrubel) MyEnum.values is constant, but is a list
        // so should it return isEnumConstant = true?
        // MyEnum.one.index is final but *not* constant
        // so should it return isEnumConstant = true?
        // Or should we return ElementKind.ENUM_CONSTANT here
        // in either or both of these cases?
        element.type != null &&
        element.type.element == element.enclosingElement) {
      return plugin.ElementKind.ENUM_CONSTANT;
    }
    return convertElementKind(element.kind);
  }

  /**
   * Return a textual representation of the parameters of the given [element],
   * or `null` if the element does not have any parameters.
   */
  String _getParametersString(analyzer.Element element) {
    // TODO(scheglov) expose the corresponding feature from ExecutableElement
    List<analyzer.ParameterElement> parameters;
    if (element is analyzer.ExecutableElement) {
      // valid getters don't have parameters
      if (element.kind == analyzer.ElementKind.GETTER &&
          element.parameters.isEmpty) {
        return null;
      }
      parameters = element.parameters;
    } else if (element is analyzer.FunctionTypeAliasElement) {
      parameters = element.parameters;
    } else {
      return null;
    }
    StringBuffer buffer = new StringBuffer();
    String closeOptionalString = '';
    buffer.write('(');
    for (int i = 0; i < parameters.length; i++) {
      analyzer.ParameterElement parameter = parameters[i];
      if (i > 0) {
        buffer.write(', ');
      }
      if (closeOptionalString.isEmpty) {
        analyzer.ParameterKind kind = parameter.parameterKind;
        if (kind == analyzer.ParameterKind.NAMED) {
          buffer.write('{');
          closeOptionalString = '}';
        }
        if (kind == analyzer.ParameterKind.POSITIONAL) {
          buffer.write('[');
          closeOptionalString = ']';
        }
      }
      parameter.appendToWithoutDelimiters(buffer);
    }
    buffer.write(closeOptionalString);
    buffer.write(')');
    return buffer.toString();
  }

  /**
   * Return a textual representation of the return type of the given [element],
   * or `null` if the element does not have a return type.
   */
  String _getReturnTypeString(analyzer.Element element) {
    if (element is analyzer.ExecutableElement) {
      if (element.kind == analyzer.ElementKind.SETTER) {
        return null;
      }
      return element.returnType?.toString();
    } else if (element is analyzer.VariableElement) {
      analyzer.DartType type = element.type;
      return type != null ? type.displayName : 'dynamic';
    } else if (element is analyzer.FunctionTypeAliasElement) {
      return element.returnType.toString();
    }
    return null;
  }

  /**
   * Return a textual representation of the type parameters of the given
   * [element], or `null` if the element does not have type parameters.
   */
  String _getTypeParametersString(analyzer.Element element) {
    if (element is analyzer.TypeParameterizedElement) {
      List<analyzer.TypeParameterElement> typeParameters =
          element.typeParameters;
      if (typeParameters == null || typeParameters.isEmpty) {
        return null;
      }
      return '<${typeParameters.join(', ')}>';
    }
    return null;
  }

  /**
   * Return the compilation unit containing the given [element].
   */
  analyzer.CompilationUnitElement _getUnitElement(analyzer.Element element) {
    if (element is analyzer.CompilationUnitElement) {
      return element;
    }
    if (element?.enclosingElement is analyzer.LibraryElement) {
      element = element.enclosingElement;
    }
    if (element is analyzer.LibraryElement) {
      return element.definingCompilationUnit;
    }
    for (; element != null; element = element.enclosingElement) {
      if (element is analyzer.CompilationUnitElement) {
        return element;
      }
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

  /**
   * Create and return a location within the given [unitElement] at the given
   * [range].
   */
  plugin.Location _locationForArgs(
      analyzer.CompilationUnitElement unitElement, analyzer.SourceRange range) {
    int startLine = 0;
    int startColumn = 0;
    try {
      analyzer.LineInfo lineInfo = unitElement.lineInfo;
      if (lineInfo != null) {
        analyzer.LineInfo_Location offsetLocation =
            lineInfo.getLocation(range.offset);
        startLine = offsetLocation.lineNumber;
        startColumn = offsetLocation.columnNumber;
      }
    } on analyzer.AnalysisException {
      // Ignore exceptions
    }
    return new plugin.Location(unitElement.source.fullName, range.offset,
        range.length, startLine, startColumn);
  }

  /**
   * Create a location based on an the given [element].
   */
  plugin.Location _locationFromElement(analyzer.Element element) {
    if (element == null || element.source == null) {
      return null;
    }
    int offset = element.nameOffset;
    int length = element.nameLength;
    if (element is analyzer.CompilationUnitElement ||
        (element is analyzer.LibraryElement && offset < 0)) {
      offset = 0;
      length = 0;
    }
    analyzer.CompilationUnitElement unitElement = _getUnitElement(element);
    analyzer.SourceRange range = new analyzer.SourceRange(offset, length);
    return _locationForArgs(unitElement, range);
  }
}
