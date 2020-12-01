// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/add_type_parameter.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/changes_selector.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_fragment_parser.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/expression.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/modify_parameters.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename_parameter.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_generator.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/variable_scope.dart';
import 'package:analysis_server/src/utilities/extensions/yaml.dart';
import 'package:analyzer/error/listener.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Information used to report errors when translating a node.
class ErrorContext {
  /// The name of the key used to identify the node that has an error associated
  /// with it.
  final String key;

  /// The node that should be used to compute the highlight region for the
  /// diagnostic.
  final YamlNode parentNode;

  /// Initialize a newly created error context.
  ErrorContext({@required this.key, @required this.parentNode});
}

/// A parser used to read a transform set from a file.
class TransformSetParser {
  static const String _argumentValueKey = 'argumentValue';
  static const String _bulkApplyKey = 'bulkApply';
  static const String _changesKey = 'changes';
  static const String _classKey = 'class';
  static const String _constantKey = 'constant';
  static const String _constructorKey = 'constructor';
  static const String _dateKey = 'date';
  static const String _elementKey = 'element';
  static const String _enumKey = 'enum';
  static const String _expressionKey = 'expression';
  static const String _extendsKey = 'extends';
  static const String _extensionKey = 'extension';
  static const String _fieldKey = 'field';
  static const String _functionKey = 'function';
  static const String _getterKey = 'getter';
  static const String _ifKey = 'if';
  static const String _inClassKey = 'inClass';
  static const String _inEnumKey = 'inEnum';
  static const String _inExtensionKey = 'inExtension';
  static const String _indexKey = 'index';
  static const String _inMixinKey = 'inMixin';
  static const String _kindKey = 'kind';
  static const String _methodKey = 'method';
  static const String _mixinKey = 'mixin';
  static const String _nameKey = 'name';
  static const String _newNameKey = 'newName';
  static const String _oldNameKey = 'oldName';
  static const String _oneOfKey = 'oneOf';
  static const String _requiredIfKey = 'requiredIf';
  static const String _setterKey = 'setter';
  static const String _styleKey = 'style';
  static const String _titleKey = 'title';
  static const String _transformsKey = 'transforms';
  static const String _typedefKey = 'typedef';
  static const String _urisKey = 'uris';
  static const String _valueKey = 'value';
  static const String _variableKey = 'variable';
  static const String _variablesKey = 'variables';
  static const String _versionKey = 'version';

  /// A table mapping top-level keys for member elements to the list of keys for
  /// the possible containers of that element.
  static const Map<String, List<String>> _containerKeyMap = {
    _constructorKey: [_inClassKey],
    _constantKey: [_inEnumKey],
    _fieldKey: [_inClassKey, _inExtensionKey, _inMixinKey],
    _getterKey: [_inClassKey, _inExtensionKey, _inMixinKey],
    _methodKey: [_inClassKey, _inExtensionKey, _inMixinKey],
    _setterKey: [_inClassKey, _inExtensionKey, _inMixinKey],
  };

  static const String _addParameterKind = 'addParameter';
  static const String _addTypeParameterKind = 'addTypeParameter';
  static const String _fragmentKind = 'fragment';
  static const String _importKind = 'import';
  static const String _removeParameterKind = 'removeParameter';
  static const String _renameKind = 'rename';
  static const String _renameParameterKind = 'renameParameter';

  /// The valid values for the [_styleKey] in an [_addParameterKind] change.
  static const List<String> validStyles = [
    'optional_named',
    'optional_positional',
    'required_named',
    'required_positional'
  ];

  static const String _openComponent = '{%';
  static const String _closeComponent = '%}';

  /// The lowest file version supported by this parser.
  static const int oldestVersion = 1;

  /// The highest file version supported by this parser. The version needs to be
  /// incremented any time the parser is updated to disallow input that would
  /// have been valid in the most recently published version of server. This
  /// includes removing support for keys and adding a new required key.
  static const int currentVersion = 1;

  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

  /// The name of the package from which the data file being translated was
  /// found.
  final String packageName;

  /// The variable scope defined for the current transform.
  VariableScope transformVariableScope = VariableScope.empty;

  /// The parameter modifications associated with the current transform, or
  /// `null` if the current transform does not yet have any such modifications.
  List<ParameterModification> _parameterModifications;

  /// Initialize a newly created parser to report diagnostics to the
  /// [errorReporter].
  TransformSetParser(this.errorReporter, this.packageName);

  /// Return the result of parsing the file [content] into a transform set, or
  /// `null` if the content does not represent a valid transform set.
  TransformSet parse(String content) {
    assert(content != null);
    var map = _parseYaml(content);
    if (map == null) {
      // The error has already been reported.
      return null;
    }
    return _translateTransformSet(map);
  }

  /// Convert the given [template] into a list of components. Variable
  /// references in the template are looked up in the map of [generators].
  List<TemplateComponent> _extractTemplateComponents(
      String template, VariableScope variableScope, int templateOffset) {
    var components = <TemplateComponent>[];
    var textStart = 0;
    var variableStart = template.indexOf(_openComponent);
    while (variableStart >= 0) {
      if (textStart < variableStart) {
        // TODO(brianwilkerson) Check for an end brace without a start brace.
        components
            .add(TemplateText(template.substring(textStart, variableStart)));
      }
      var endIndex = template.indexOf(_closeComponent, variableStart + 2);
      if (endIndex < 0) {
        errorReporter.reportErrorForOffset(
            TransformSetErrorCode.missingTemplateEnd,
            templateOffset + variableStart,
            2);
        // Ignore the invalid component, treating it as if it extended to the
        // end of the template.
        return components;
      } else {
        var name = template.substring(variableStart + 2, endIndex).trim();
        var generator = variableScope.lookup(name);
        if (generator == null) {
          errorReporter.reportErrorForOffset(
              TransformSetErrorCode.undefinedVariable,
              templateOffset + template.indexOf(name, variableStart),
              name.length,
              [name]);
          // Ignore the invalid component.
        } else {
          components.add(TemplateVariable(generator));
        }
      }
      textStart = endIndex + 2;
      variableStart = template.indexOf(_openComponent, textStart);
    }
    if (textStart < template.length) {
      // TODO(brianwilkerson) Check for an end brace without a start brace.
      components.add(TemplateText(template.substring(textStart)));
    }
    // TODO(brianwilkerson) If there are no other errors, then report
    //  unreferenced variables.
    return components;
  }

  /// Return a textual description of the type of value represented by the
  /// [node].
  String _nodeType(YamlNode node) {
    if (node is YamlScalar) {
      return node.value.runtimeType.toString();
    } else if (node is YamlList) {
      return 'List';
    } else if (node is YamlMap) {
      return 'Map';
    }
    // We shouldn't get here.
    return node.runtimeType.toString();
  }

  /// Return the offset of the first character in the [string], exclusive of any
  /// surrounding quotes.
  int _offsetOfString(YamlScalar string) {
    if (string.style == ScalarStyle.PLAIN) {
      return string.span.start.offset;
    }
    return string.span.start.offset + 1;
  }

  /// Return the result of parsing the file [content] into a YAML node.
  YamlNode _parseYaml(String content) {
    try {
      return loadYamlNode(content);
    } on YamlException catch (e) {
      var span = e.span;
      errorReporter.reportErrorForOffset(TransformSetErrorCode.yamlSyntaxError,
          span.start.offset, span.length, [e.message]);
    }
    return null;
  }

  /// Report a diagnostic with the given [code] associated with the given
  /// [node]. A list of [arguments] should be provided if the diagnostic message
  /// has parameters.
  void _reportError(TransformSetErrorCode code, YamlNode node,
      [List<String> arguments]) {
    var span = node.span;
    errorReporter.reportErrorForOffset(
        code, span.start.offset, span.length, arguments);
  }

  /// Report that the value represented by the [node] does not have the
  /// [expectedType], using the [context] to get the key to use in the message.
  Null _reportInvalidValue(
      YamlNode node, ErrorContext context, String expectedType) {
    _reportError(TransformSetErrorCode.invalidValue, node,
        [context.key, expectedType, _nodeType(node)]);
    return null;
  }

  /// Report that the value represented by the [node] does not have the
  /// [expectedType], using the [context] to get the key to use in the message.
  Null _reportInvalidValueOneOf(
      YamlNode node, ErrorContext context, List<String> allowedValues) {
    _reportError(TransformSetErrorCode.invalidValueOneOf, node,
        [context.key, allowedValues.join(', ')]);
    return null;
  }

  /// Report that a required key is missing, using the [context] to locate the
  /// node associated with the diagnostic and the key to use in the message.
  Null _reportMissingKey(ErrorContext context) {
    _reportError(
        TransformSetErrorCode.missingKey, context.parentNode, [context.key]);
    return null;
  }

  /// Report any keys in the [map] whose values are not in [validKeys].
  void _reportUnsupportedKeys(YamlMap map, Set<String> validKeys) {
    for (var keyNode in map.nodes.keys) {
      var key = _translateKey(keyNode);
      if (key != null && !validKeys.contains(key)) {
        _reportError(TransformSetErrorCode.unsupportedKey, keyNode, [key]);
      }
    }
  }

  /// Given a [map] and a set of [validKeys], ensure that exactly one of those
  /// keys is in the map and return it. If more than one of the keys is in the
  /// map, report a diagnostic for each extra key. If [required] is `true` and
  /// none of the keys is in the map, report a diagnostic at the [errorNode].
  String _singleKey(YamlMap map, List<String> validKeys, YamlNode errorNode,
      {bool required = true}) {
    assert(validKeys != null);
    var foundKeys = <String>[];
    var keyToNodeMap = <String, YamlNode>{};
    for (var keyNode in map.nodes.keys) {
      if (keyNode is YamlScalar && keyNode.value is String) {
        var key = keyNode.value as String;
        if (key != null && validKeys.contains(key)) {
          foundKeys.add(key);
          keyToNodeMap[key] = keyNode;
        }
      }
    }
    if (foundKeys.isEmpty) {
      if (required) {
        var validKeysList = validKeys.map((key) => "'$key'").join(', ');
        _reportError(TransformSetErrorCode.missingOneOfMultipleKeys, errorNode,
            [validKeysList]);
      }
      return null;
    }
    var firstKey = foundKeys[0];
    for (var i = 1; i < foundKeys.length; i++) {
      var foundKey = foundKeys[i];
      var invalidNode = keyToNodeMap[foundKey];
      _reportError(TransformSetErrorCode.conflictingKey, invalidNode,
          [foundKey, firstKey]);
    }
    return firstKey;
  }

  /// Translate the [node] into a add-parameter modification.
  void _translateAddParameterChange(YamlMap node) {
    _reportUnsupportedKeys(node,
        const {_argumentValueKey, _indexKey, _kindKey, _nameKey, _styleKey});
    var index = _translateInteger(node.valueAt(_indexKey),
        ErrorContext(key: _indexKey, parentNode: node));
    if (index == null) {
      // The error has already been reported.
      return;
    }
    var name = _translateString(
        node.valueAt(_nameKey), ErrorContext(key: _nameKey, parentNode: node));
    if (name == null) {
      // The error has already been reported.
      return;
    }
    var styleNode = node.valueAt(_styleKey);
    var style = _translateString(
        styleNode, ErrorContext(key: _styleKey, parentNode: node));
    if (style == null) {
      // The error has already been reported.
      return;
    }
    if (!validStyles.contains(style)) {
      var validStylesList = validStyles.map((style) => "'$style'").join(', ');
      _reportError(TransformSetErrorCode.invalidParameterStyle, styleNode,
          [validStylesList]);
      return;
    }
    var isRequired = style.startsWith('required_');
    var isPositional = style.endsWith('_positional');
    var argumentValueNode = node.valueAt(_argumentValueKey);
    var argumentValue = _translateCodeTemplate(argumentValueNode,
        ErrorContext(key: _argumentValueKey, parentNode: node),
        canBeConditionallyRequired: true);
    // TODO(brianwilkerson) We really ought to require an argument value for
    //  optional positional parameters too for the case where the added
    //  parameter is being added before the end of the list and call sites might
    //  already be providing a value for subsequent parameters. Unfortunately we
    //  can't know at this point whether there are subsequent parameters in
    //  order to require it only when it's potentially necessary.
    if (isRequired && argumentValue == null) {
      // TODO(brianwilkerson) Report that required parameters must have an
      //  argument value.
      return;
    } else if (argumentValue != null &&
        argumentValue.requiredIfCondition != null) {
      if (style != 'optional_named') {
        var valueNode = argumentValueNode as YamlMap;
        _reportError(TransformSetErrorCode.invalidRequiredIf,
            valueNode.keyAtValue(valueNode.valueAt(_requiredIfKey)));
        return;
      } else if (argumentValue == null) {
        // TODO(brianwilkerson) Report that conditionally required parameters must
        //  have an argument value.
        return;
      }
    }
    _parameterModifications ??= [];
    _parameterModifications.add(
        AddParameter(index, name, isRequired, isPositional, argumentValue));
  }

  /// Translate the [node] into an add-type-parameter change. Return the
  /// resulting change, or `null` if the [node] does not represent a valid
  /// add-type-parameter change.
  AddTypeParameter _translateAddTypeParameterChange(YamlMap node) {
    _reportUnsupportedKeys(node,
        const {_extendsKey, _indexKey, _kindKey, _nameKey, _argumentValueKey});
    var index = _translateInteger(node.valueAt(_indexKey),
        ErrorContext(key: _indexKey, parentNode: node));
    var name = _translateString(
        node.valueAt(_nameKey), ErrorContext(key: _nameKey, parentNode: node));
    var extendedType = _translateCodeTemplate(node.valueAt(_extendsKey),
        ErrorContext(key: _extendsKey, parentNode: node),
        required: false);
    var argumentValue = _translateCodeTemplate(node.valueAt(_argumentValueKey),
        ErrorContext(key: _argumentValueKey, parentNode: node));
    if (index == null || name == null || argumentValue == null) {
      // The error has already been reported.
      return null;
    }
    // In order to support adding multiple type parameters we might need to
    // introduce a `TypeParameterModification` change, similar to
    // `ParameterModification`. That becomes more likely if we add support for
    // removing type parameters.
    return AddTypeParameter(
        index: index,
        name: name,
        extendedType: extendedType,
        argumentValue: argumentValue);
  }

  /// Translate the [node] into a bool. Return the resulting bool, or `null`
  /// if the [node] doesn't represent a valid bool. If the [node] isn't valid,
  /// use the [context] to report the error. If the [node] doesn't exist and
  /// [required] is `true`, then report an error.
  bool _translateBool(YamlNode node, ErrorContext context,
      {bool required = true}) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is bool) {
        return value;
      }
      return _reportInvalidValue(node, context, 'boolean');
    } else if (node == null) {
      if (required) {
        return _reportMissingKey(context);
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'boolean');
    }
  }

  /// Translate the [node] into a change. Return the resulting change, or `null`
  /// if the [node] does not represent a valid change. If the [node] is not
  /// valid, use the [context] to report the error.
  Change _translateChange(YamlNode node, ErrorContext context) {
    assert(node != null);
    if (node is YamlMap) {
      var kindNode = node.valueAt(_kindKey);
      var kindContext = ErrorContext(key: _kindKey, parentNode: node);
      var kind = _translateString(kindNode, kindContext);
      if (kind == null) {
        return null;
      } else if (kind == _addParameterKind) {
        _translateAddParameterChange(node);
        return null;
      } else if (kind == _addTypeParameterKind) {
        return _translateAddTypeParameterChange(node);
      } else if (kind == _removeParameterKind) {
        _translateRemoveParameterChange(node);
        return null;
      } else if (kind == _renameKind) {
        return _translateRenameChange(node);
      } else if (kind == _renameParameterKind) {
        return _translateRenameParameterChange(node);
      }
      return _reportInvalidValueOneOf(kindNode, kindContext, [
        _addParameterKind,
        _addTypeParameterKind,
        _removeParameterKind,
        _renameKind,
        _renameParameterKind,
      ]);
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }

  /// Translate the [node] into a value generator. Return the resulting
  /// generator, or `null` if the [node] does not represent a valid value
  /// extractor.
  ValueGenerator _translateCodeFragment(YamlMap node) {
    _reportUnsupportedKeys(node, const {_kindKey, _valueKey});
    var valueNode = node.valueAt(_valueKey);
    var value = _translateString(
        valueNode, ErrorContext(key: _valueKey, parentNode: node));
    if (value == null) {
      // The error has already been reported.
      return null;
    }
    var accessors = CodeFragmentParser(errorReporter)
        .parseAccessors(value, _offsetOfString(valueNode));
    if (accessors == null) {
      // The error has already been reported.
      return null;
    }
    return CodeFragment(accessors);
  }

  /// Translate the [node] into a code template. Return the resulting template,
  /// or `null` if the [node] doesn't represent a valid code template. If the
  /// [node] isn't valid, use the [context] to report the error. If the [node]
  /// doesn't exist and [required] is `true`, then report an error.
  CodeTemplate _translateCodeTemplate(YamlNode node, ErrorContext context,
      {bool canBeConditionallyRequired = false, bool required = true}) {
    if (node is YamlMap) {
      if (canBeConditionallyRequired) {
        _reportUnsupportedKeys(
            node, const {_expressionKey, _requiredIfKey, _variablesKey});
      } else {
        _reportUnsupportedKeys(node, const {_expressionKey, _variablesKey});
      }
      var expressionNode = node.valueAt(_expressionKey);
      var template = _translateString(
          expressionNode, ErrorContext(key: _expressionKey, parentNode: node));
      var variableScope = _translateTemplateVariables(
          node.valueAt(_variablesKey),
          ErrorContext(key: _variablesKey, parentNode: node));
      Expression requiredIfCondition;
      if (canBeConditionallyRequired) {
        var requiredIfNode = node.valueAt(_requiredIfKey);
        var requiredIfText = _translateString(
            requiredIfNode, ErrorContext(key: _requiredIfKey, parentNode: node),
            required: false);
        if (requiredIfText != null) {
          requiredIfCondition = CodeFragmentParser(errorReporter,
                  scope: variableScope)
              .parseCondition(requiredIfText, _offsetOfString(requiredIfNode));
          if (requiredIfCondition == null) {
            // The error has already been reported.
            return null;
          }
        }
      }
      if (template == null) {
        // The error has already been reported.
        return null;
      }
      var templateOffset = _offsetOfString(expressionNode);
      var components =
          _extractTemplateComponents(template, variableScope, templateOffset);
      return CodeTemplate(
          CodeTemplateKind.expression, components, requiredIfCondition);
    } else if (node == null) {
      if (required) {
        _reportMissingKey(context);
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }

  void _translateConditionalChange(YamlNode node, ErrorContext context,
      Map<Expression, List<Change>> changeMap) {
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {_ifKey, _changesKey});
      var expressionNode = node.valueAt(_ifKey);
      var expressionText = _translateString(
          expressionNode, ErrorContext(key: _ifKey, parentNode: node));
      var changes = _translateList(node.valueAt(_changesKey),
          ErrorContext(key: _changesKey, parentNode: node), _translateChange);
      if (_parameterModifications != null) {
        if (changes != null) {
          changes.add(ModifyParameters(modifications: _parameterModifications));
        }
        _parameterModifications = null;
      }
      if (expressionText != null && changes != null) {
        var expression = CodeFragmentParser(errorReporter,
                scope: transformVariableScope)
            .parseCondition(expressionText, _offsetOfString(expressionNode));
        if (expression != null) {
          changeMap[expression] = changes;
        }
      }
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }

  ChangesSelector _translateConditionalChanges(
      YamlNode node, ErrorContext context) {
    if (node is YamlList) {
      var changeMap = <Expression, List<Change>>{};
      for (var element in node.nodes) {
        _translateConditionalChange(element, context, changeMap);
      }
      return ConditionalChangesSelector(changeMap);
    } else {
      return _reportInvalidValue(node, context, 'List');
    }
  }

  /// Translate the [node] into a date. Return the resulting date, or `null`
  /// if the [node] does not represent a valid date. If the [node] is not
  /// valid, use the [context] to report the error.
  DateTime _translateDate(YamlNode node, ErrorContext context) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } on FormatException {
          // Fall through to report the invalid value.
        }
      }
      return _reportInvalidValue(node, context, 'Date');
    } else if (node == null) {
      return _reportMissingKey(context);
    } else {
      return _reportInvalidValue(node, context, 'Date');
    }
  }

  /// Translate the [node] into an element descriptor. Return the resulting
  /// descriptor, or `null` if the [node] does not represent a valid element
  /// descriptor. If the [node] is not valid, use the [context] to report the
  /// error.
  ElementDescriptor _translateElement(YamlNode node, ErrorContext context) {
    if (node is YamlMap) {
      var urisNode = node.valueAt(_urisKey);
      var uris = _translateList(urisNode,
          ErrorContext(key: _urisKey, parentNode: node), _translateUri);
      var elementKey = _singleKey(
          node,
          const [
            _classKey,
            _constantKey,
            _constructorKey,
            _enumKey,
            _extensionKey,
            _fieldKey,
            _functionKey,
            _getterKey,
            _methodKey,
            _mixinKey,
            _setterKey,
            _typedefKey,
            _variableKey
          ],
          node);
      if (elementKey == null) {
        // The error has already been reported.
        return null;
      }
      var elementName = _translateString(node.valueAt(elementKey),
          ErrorContext(key: elementKey, parentNode: node));
      if (elementName == null) {
        // The error has already been reported.
        return null;
      }
      var components = [elementName];
      if (_containerKeyMap.containsKey(elementKey)) {
        var validContainerKeys = _containerKeyMap[elementKey];
        var containerKey =
            _singleKey(node, validContainerKeys, node, required: false);
        var containerName = _translateString(node.valueAt(containerKey),
            ErrorContext(key: containerKey, parentNode: node),
            required: false);
        if (containerName == null) {
          if ([_constructorKey, _constantKey, _methodKey, _fieldKey]
              .contains(elementKey)) {
            var validKeysList =
                validContainerKeys.map((key) => "'$key'").join(', ');
            _reportError(TransformSetErrorCode.missingOneOfMultipleKeys, node,
                [validKeysList]);
            return null;
          }
        } else {
          components.insert(0, containerName);
        }
      }
      if (uris == null) {
        // The error has already been reported.
        return null;
      }
      if (uris.isEmpty) {
        if ((urisNode as YamlList).isEmpty) {
          _reportError(TransformSetErrorCode.missingUri, urisNode);
        }
        return null;
      }
      return ElementDescriptor(
          libraryUris: uris,
          kind: ElementKindUtilities.fromName(elementKey),
          components: components);
    } else if (node == null) {
      return _reportMissingKey(context);
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }

  /// Translate the [node] into a value generator. Return the resulting
  /// generator, or `null` if the [node] does not represent a valid value
  /// extractor.
  ValueGenerator _translateImportValue(YamlMap node) {
    _reportUnsupportedKeys(node, const {_kindKey, _nameKey, _urisKey});
    var urisNode = node.valueAt(_urisKey);
    var uris = _translateList(
        urisNode, ErrorContext(key: _urisKey, parentNode: node), _translateUri);
    var name = _translateString(
        node.valueAt(_nameKey), ErrorContext(key: _nameKey, parentNode: node));
    if (uris == null || name == null) {
      // The error has already been reported.
      return null;
    }
    if (uris.isEmpty) {
      if ((urisNode as YamlList).isEmpty) {
        _reportError(TransformSetErrorCode.missingUri, urisNode);
      }
      return null;
    }
    return ImportedName(uris, name);
  }

  /// Translate the [node] into an integer. Return the resulting integer, or
  /// `null` if the [node] does not represent a valid integer. If the [node] is
  /// not valid, use the [context] to report the error.
  int _translateInteger(YamlNode node, ErrorContext context) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is int) {
        return value;
      }
      return _reportInvalidValue(node, context, 'int');
    } else if (node == null) {
      return _reportMissingKey(context);
    } else {
      return _reportInvalidValue(node, context, 'int');
    }
  }

  /// Translate the given [node] as a key.
  String _translateKey(YamlNode node) {
    String type;
    if (node is YamlScalar) {
      if (node.value is String) {
        return node.value as String;
      }
      type = node.value.runtimeType.toString();
    } else if (node is YamlList) {
      type = 'List';
    } else if (node is YamlMap) {
      type = 'Map';
    } else {
      type = node.runtimeType.toString();
    }
    _reportError(TransformSetErrorCode.invalidKey, node, [type]);
    return null;
  }

  /// Translate the [node] into a list of objects using the [elementTranslator].
  /// Return the resulting list, or `null` if the [node] does not represent a
  /// valid list. If any of the elements of the list can't be translated, they
  /// will be omitted from the list, the [context] will be used to report the
  /// error, and the valid elements will be returned.
  List<R> _translateList<R>(YamlNode node, ErrorContext context,
      R Function(YamlNode, ErrorContext) elementTranslator) {
    if (node is YamlList) {
      var translatedList = <R>[];
      for (var element in node.nodes) {
        var result = elementTranslator(element, context);
        if (result != null) {
          translatedList.add(result);
        }
      }
      return translatedList;
    } else if (node == null) {
      return _reportMissingKey(context);
    } else {
      return _reportInvalidValue(node, context, 'List');
    }
  }

  /// Translate the [node] into a remove-parameter modification.
  void _translateRemoveParameterChange(YamlMap node) {
    _reportUnsupportedKeys(node, const {_indexKey, _kindKey, _nameKey});
    var parameterSpecKey = _singleKey(node, const [_nameKey, _indexKey], node);
    if (parameterSpecKey == null) {
      // The error has already been reported.
      return null;
    }
    ParameterReference reference;
    if (parameterSpecKey == _indexKey) {
      var index = _translateInteger(node.valueAt(_indexKey),
          ErrorContext(key: _indexKey, parentNode: node));
      if (parameterSpecKey == null) {
        // The error has already been reported.
        return null;
      }
      reference = PositionalParameterReference(index);
    } else {
      var name = _translateString(node.valueAt(_nameKey),
          ErrorContext(key: _nameKey, parentNode: node));
      if (name == null) {
        // The error has already been reported.
        return;
      }
      reference = NamedParameterReference(name);
    }
    _parameterModifications ??= [];
    _parameterModifications.add(RemoveParameter(reference));
  }

  /// Translate the [node] into a rename change. Return the resulting change, or
  /// `null` if the [node] does not represent a valid rename change.
  Rename _translateRenameChange(YamlMap node) {
    _reportUnsupportedKeys(node, const {_kindKey, _newNameKey});
    var newName = _translateString(node.valueAt(_newNameKey),
        ErrorContext(key: _newNameKey, parentNode: node));
    if (newName == null) {
      // The error has already been reported.
      return null;
    }
    return Rename(newName: newName);
  }

  /// Translate the [node] into a rename parameter change. Return the resulting
  /// change, or `null` if the [node] does not represent a valid rename change.
  RenameParameter _translateRenameParameterChange(YamlMap node) {
    _reportUnsupportedKeys(node, const {_kindKey, _newNameKey, _oldNameKey});
    var oldName = _translateString(node.valueAt(_oldNameKey),
        ErrorContext(key: _oldNameKey, parentNode: node));
    var newName = _translateString(node.valueAt(_newNameKey),
        ErrorContext(key: _newNameKey, parentNode: node));
    if (oldName == null || newName == null) {
      // The error has already been reported.
      return null;
    }
    return RenameParameter(newName: newName, oldName: oldName);
  }

  /// Translate the [node] into a string. Return the resulting string, or `null`
  /// if the [node] doesn't represent a valid string. If the [node] isn't valid,
  /// use the [context] to report the error. If the [node] doesn't exist and
  /// [required] is `true`, then report an error.
  String _translateString(YamlNode node, ErrorContext context,
      {bool required = true}) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        return value;
      }
      return _reportInvalidValue(node, context, 'String');
    } else if (node == null) {
      if (required) {
        return _reportMissingKey(context);
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'String');
    }
  }

  /// Translate the [node] into a variable scope. Return the resulting scope, or
  /// the enclosing scope if the [node] does not represent a valid variables
  /// map. If the [node] is not valid, use the [context] to report the error.
  VariableScope _translateTemplateVariables(
      YamlNode node, ErrorContext context) {
    if (node is YamlMap) {
      var generators = <String, ValueGenerator>{};
      for (var entry in node.nodes.entries) {
        var name = _translateKey(entry.key);
        if (name != null) {
          var value = _translateValueGenerator(
              entry.value, ErrorContext(key: name, parentNode: node));
          if (value != null) {
            generators[name] = value;
          }
        }
      }
      return VariableScope(transformVariableScope, generators);
    } else if (node == null) {
      return transformVariableScope;
    } else {
      _reportInvalidValue(node, context, 'Map');
      return transformVariableScope;
    }
  }

  /// Translate the [node] into a transform. Return the resulting transform, or
  /// `null` if the [node] does not represent a valid transform. If the [node]
  /// is not valid, use the [context] to report the error.
  Transform _translateTransform(YamlNode node, ErrorContext context) {
    assert(node != null);
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {
        _bulkApplyKey,
        _changesKey,
        _dateKey,
        _elementKey,
        _oneOfKey,
        _titleKey,
        _variablesKey
      });
      var title = _translateString(node.valueAt(_titleKey),
          ErrorContext(key: _titleKey, parentNode: node));
      var date = _translateDate(node.valueAt(_dateKey),
          ErrorContext(key: _dateKey, parentNode: node));
      var bulkApply = _translateBool(node.valueAt(_bulkApplyKey),
              ErrorContext(key: _bulkApplyKey, parentNode: node),
              required: false) ??
          true;
      var element = _translateElement(node.valueAt(_elementKey),
          ErrorContext(key: _elementKey, parentNode: node));
      transformVariableScope = _translateTemplateVariables(
          node.valueAt(_variablesKey),
          ErrorContext(key: _variablesKey, parentNode: node));
      ChangesSelector selector;
      var key = _singleKey(
          node, const [_changesKey, _oneOfKey], context.parentNode,
          required: true);
      if (key == _oneOfKey) {
        selector = _translateConditionalChanges(node.valueAt(_oneOfKey),
            ErrorContext(key: _oneOfKey, parentNode: node));
      } else if (key == _changesKey) {
        var changes = _translateList(node.valueAt(_changesKey),
            ErrorContext(key: _changesKey, parentNode: node), _translateChange);
        if (changes == null) {
          // The error has already been reported.
          _parameterModifications = null;
          return null;
        }
        if (_parameterModifications != null) {
          changes.add(ModifyParameters(modifications: _parameterModifications));
          _parameterModifications = null;
        }
        selector = UnconditionalChangesSelector(changes);
      } else {
        // The error has already been reported.
        return null;
      }
      transformVariableScope = VariableScope.empty;
      if (title == null ||
          date == null ||
          element == null ||
          selector == null) {
        // The error has already been reported.
        return null;
      }
      return Transform(
          title: title,
          date: date,
          bulkApply: bulkApply,
          element: element,
          changesSelector: selector);
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }

  /// Translate the [node] into a transform set. Return the resulting transform
  /// set, or `null` if the [node] does not represent a valid transform set.
  TransformSet _translateTransformSet(YamlNode node) {
    assert(node != null);
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {_transformsKey, _versionKey});
      var versionNode = node.valueAt(_versionKey);
      var version = _translateInteger(
          versionNode, ErrorContext(key: _versionKey, parentNode: node));
      if (version == null) {
        // The error has already been reported.
        return null;
      } else if (version < 1 || version > currentVersion) {
        _reportError(TransformSetErrorCode.unsupportedVersion, versionNode);
        return null;
      }
      // TODO(brianwilkerson) Version information is currently being ignored,
      //  but needs to be used to select a translator.
      var transforms = _translateList(
          node.valueAt(_transformsKey),
          ErrorContext(key: _transformsKey, parentNode: node),
          _translateTransform);
      if (transforms == null) {
        // The error has already been reported.
        return null;
      }
      transforms.sort((first, second) => first.date.compareTo(second.date));
      var set = TransformSet();
      for (var transform in transforms) {
        set.addTransform(transform);
      }
      return set;
    } else {
      // TODO(brianwilkerson) Consider having a different error code for the
      //  top-level node (instead of using 'file' as the "key").
      _reportError(TransformSetErrorCode.invalidValue, node,
          ['file', 'Map', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a URI. Return the resulting URI, or `null` if
  /// the [node] doesn't represent a valid URI. If the [node] isn't valid, use
  /// the [context] to report the error. If the [node] doesn't exist and
  /// [required] is `true`, then report an error.
  Uri _translateUri(YamlNode node, ErrorContext context,
      {bool required = true}) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        if (!(value.startsWith('dart:') || value.startsWith('package:'))) {
          value = 'package:$packageName/$value';
        }
        return Uri.parse(value);
      }
      return _reportInvalidValue(node, context, 'URI');
    } else if (node == null) {
      if (required) {
        return _reportMissingKey(context);
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'URI');
    }
  }

  /// Translate the [node] into a value extractor. Return the resulting
  /// extractor, or `null` if the [node] does not represent a valid value
  /// extractor. If the [node] is not valid, use the [context] to report the
  /// error.
  ValueGenerator _translateValueGenerator(YamlNode node, ErrorContext context) {
    if (node is YamlMap) {
      var kindNode = node.valueAt(_kindKey);
      var kindContext = ErrorContext(key: _kindKey, parentNode: node);
      var kind = _translateString(kindNode, kindContext);
      if (kind == null) {
        return null;
      } else if (kind == _fragmentKind) {
        return _translateCodeFragment(node);
      } else if (kind == _importKind) {
        return _translateImportValue(node);
      }
      return _reportInvalidValueOneOf(kindNode, kindContext, [
        _fragmentKind,
        _importKind,
      ]);
    } else if (node == null) {
      return _reportMissingKey(context);
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }
}
