// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/add_type_parameter.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/modify_parameters.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_extractor.dart';
import 'package:analysis_server/src/utilities/extensions/yaml.dart';
import 'package:analyzer/error/listener.dart';
import 'package:yaml/yaml.dart';

/// A parser used to read a transform set from a file.
class TransformSetParser {
  static const String _argumentValueKey = 'argumentValue';
  static const String _changesKey = 'changes';
  static const String _classKey = 'class';
  static const String _constantKey = 'constant';
  static const String _constructorKey = 'constructor';
  static const String _dateKey = 'date';
  static const String _elementKey = 'element';
  static const String _enumKey = 'enum';
  static const String _extensionKey = 'extension';
  static const String _fieldKey = 'field';
  static const String _functionKey = 'function';
  static const String _getterKey = 'getter';
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
  static const String _setterKey = 'setter';
  static const String _styleKey = 'style';
  static const String _titleKey = 'title';
  static const String _transformsKey = 'transforms';
  static const String _typedefKey = 'typedef';
  static const String _urisKey = 'uris';
  static const String _valueKey = 'value';
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
  static const String _argumentKind = 'argument';
  static const String _removeParameterKind = 'removeParameter';
  static const String _renameKind = 'rename';

  /// The valid values for the [_styleKey] in an [_addParameterKind] change.
  static const List<String> validStyles = [
    'optional_named',
    'optional_positional',
    'required_named',
    'required_positional'
  ];

  /// The highest file version supported by this parser. The version needs to be
  /// incremented any time the parser is updated to disallow input that would
  /// have been valid in the most recently published version of server. This
  /// includes removing support for keys and adding a new required key.
  static const int currentVersion = 1;

  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

  /// The parameter modifications associated with the current transform, or
  /// `null` if the current transform does not yet have any such modifications.
  List<ParameterModification> _parameterModifications;

  /// Initialize a newly created parser to report diagnostics to the
  /// [errorReporter].
  TransformSetParser(this.errorReporter);

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

  /// Report any keys in the [map] whose values are not in [validKeys].
  void _reportUnsupportedKeys(YamlMap map, Set<String> validKeys) {
    for (var keyNode in map.nodes.keys) {
      if (keyNode is YamlScalar && keyNode.value is String) {
        var key = keyNode.value as String;
        if (key != null && !validKeys.contains(key)) {
          _reportError(TransformSetErrorCode.unsupportedKey, keyNode, [key]);
        }
      } else {
        // TODO(brianwilkerson) Report the invalidKey.
        //  "Keys must be of type 'String' but found the type '{0}'."
      }
    }
  }

  /// Given a [map] and a set of [validKeys], ensure that only one of those keys
  /// is in the map and return it. If more than one of the keys is in the map,
  /// report a diagnostic.
  String _singleKey(YamlMap map, List<String> validKeys) {
    if (validKeys == null) {
      return null;
    }
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
      return null;
    }
    for (var i = 1; i < foundKeys.length; i++) {
      // var invalidNode = keyToNodeMap[foundKeys[i]];
      // TODO(brianwilkerson) Report the problem.
    }
    return foundKeys[0];
  }

  /// Translate the [node] into a add-parameter modification.
  void _translateAddParameterChange(YamlMap node) {
    _singleKey(node, [_indexKey, _nameKey]);
    _reportUnsupportedKeys(node,
        const {_argumentValueKey, _indexKey, _kindKey, _nameKey, _styleKey});
    var index = _translateInteger(node.valueAt(_indexKey), _indexKey);
    if (index == null) {
      return;
    }
    var name = _translateString(node.valueAt(_nameKey), _nameKey);
    if (name == null) {
      return;
    }
    var style = _translateString(node.valueAt(_styleKey), _styleKey);
    if (style == null) {
      return;
    } else if (!validStyles.contains(style)) {
      // TODO(brianwilkerson) Report the invalid style.
      return;
    }
    var isRequired = style.startsWith('required_');
    var isPositional = style.endsWith('_positional');
    var argumentValue = _translateValueExtractor(
        node.valueAt(_argumentValueKey), _argumentValueKey);
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
    }
    _parameterModifications ??= [];
    _parameterModifications.add(
        AddParameter(index, name, isRequired, isPositional, argumentValue));
  }

  /// Translate the [node] into an add-type-parameter change. Return the
  /// resulting change, or `null` if the [node] does not represent a valid
  /// add-type-parameter change.
  AddTypeParameter _translateAddTypeParameterChange(YamlMap node) {
    _reportUnsupportedKeys(
        node, const {_indexKey, _kindKey, _nameKey, _valueKey});
    var index = _translateInteger(node.valueAt(_indexKey), _indexKey);
    if (index == null) {
      return null;
    }
    var name = _translateString(node.valueAt(_nameKey), _nameKey);
    if (name == null) {
      return null;
    }
    var value = _translateValueExtractor(node.valueAt(_valueKey), _valueKey);
    if (value == null) {
      return null;
    }
    return AddTypeParameter(index: index, name: name, value: value);
  }

  /// Translate the [node] into a value extractor. Return the resulting
  /// extractor, or `null` if the [node] does not represent a valid value
  /// extractor.
  ValueExtractor _translateArgumentExtractor(YamlMap node) {
    var indexNode = node.valueAt(_indexKey);
    if (indexNode != null) {
      _reportUnsupportedKeys(node, const {_indexKey, _kindKey});
      var index = _translateInteger(indexNode, _indexKey);
      if (index == null) {
        // The error has already been reported.
        return null;
      }
      return ArgumentExtractor(PositionalParameterReference(index));
    }
    var nameNode = node.valueAt(_nameKey);
    if (nameNode != null) {
      _reportUnsupportedKeys(node, const {_nameKey, _kindKey});
      var name = _translateString(nameNode, _nameKey);
      if (name == null) {
        // The error has already been reported.
        return null;
      }
      return ArgumentExtractor(NamedParameterReference(name));
    }
    // TODO(brianwilkerson) Report the missing YAML.
    return null;
  }

  /// Translate the [node] into a change. Return the resulting change, or `null`
  /// if the [node] does not represent a valid change. If the [node] is not
  /// valid, use the name of the associated [key] to report the error.
  Change _translateChange(YamlNode node, String key) {
    if (node is YamlMap) {
      var kind = _translateString(node.valueAt(_kindKey), _kindKey);
      if (kind == _addTypeParameterKind) {
        return _translateAddTypeParameterChange(node);
      } else if (kind == _renameKind) {
        return _translateRenameChange(node);
      } else if (kind == _addParameterKind) {
        _translateAddParameterChange(node);
        return null;
      } else if (kind == _removeParameterKind) {
        _translateRemoveParameterChange(node);
        return null;
      }
      // TODO(brianwilkerson) Report the invalid change kind.
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'Map', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a date. Return the resulting date, or `null`
  /// if the [node] does not represent a valid date. If the [node] is not
  /// valid, use the name of the associated [key] to report the error.
  DateTime _translateDate(YamlNode node, String key) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } on FormatException {
          // Fall through to report the invalid value.
        }
      }
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'Date', _nodeType(node)]);
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'Date', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into an element descriptor. Return the resulting
  /// descriptor, or `null` if the [node] does not represent a valid element
  /// descriptor. If the [node] is not valid, use the name of the associated
  /// [key] to report the error.
  ElementDescriptor _translateElement(YamlNode node, String key) {
    if (node is YamlMap) {
      var uris =
          _translateList(node.valueAt(_urisKey), _urisKey, _translateString);
      if (uris == null) {
        // The error has already been reported.
        // TODO(brianwilkerson) Returning here prevents other errors from being
        //  reported.
        return null;
      }
      var elementKey = _singleKey(node, [
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
        _typedefKey
      ]);
      var elementName = _translateString(node.valueAt(elementKey), elementKey);
      if (elementName == null) {
        // The error has already been reported.
        return null;
      }
      var components = [elementName];
      var containerKey = _singleKey(node, _containerKeyMap[elementKey]);
      var containerName =
          _translateString(node.valueAt(containerKey), containerKey);
      if (containerName == null) {
        if ([_constructorKey, _constantKey, _methodKey, _fieldKey]
            .contains(elementKey)) {
          // TODO(brianwilkerson) Report that no container was found.
          return null;
        }
      } else {
        components.insert(0, containerName);
      }
      return ElementDescriptor(
          libraryUris: uris, kind: elementKey, components: components);
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'Map', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into an integer. Return the resulting integer, or
  /// `null` if the [node] does not represent a valid integer. If the [node] is
  /// not valid, use the name of the associated [key] to report the error.
  int _translateInteger(YamlNode node, String key) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is int) {
        return value;
      }
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'int', _nodeType(node)]);
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'int', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a list of objects using the [elementTranslator].
  /// Return the resulting list, or `null` if the [node] does not represent a
  /// valid list. If any of the elements of the list can't be translated, they
  /// will be omitted from the list, the name of the associated [key] will be
  /// used to report the error, and the valid elements will be returned.
  List<R> _translateList<R>(YamlNode node, String key,
      R Function(YamlNode, String) elementTranslator) {
    if (node is YamlList) {
      var translatedList = <R>[];
      for (var element in node.nodes) {
        var result = elementTranslator(element, key);
        if (result != null) {
          translatedList.add(result);
        }
      }
      return translatedList;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'List', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a remove-parameter modification.
  void _translateRemoveParameterChange(YamlMap node) {
    _singleKey(node, [_indexKey, _nameKey]);
    _reportUnsupportedKeys(node, const {_indexKey, _kindKey, _nameKey});
    ParameterReference reference;
    var index = _translateInteger(node.valueAt(_indexKey), _indexKey);
    if (index != null) {
      reference = PositionalParameterReference(index);
    } else {
      var name = _translateString(node.valueAt(_nameKey), _nameKey);
      if (name == null) {
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
    var newName = _translateString(node.valueAt(_newNameKey), _newNameKey);
    if (newName == null) {
      return null;
    }
    return Rename(newName: newName);
  }

  /// Translate the [node] into a string. Return the resulting string, or `null`
  /// if the [node] does not represent a valid string. If the [node] is not
  /// valid, use the name of the associated [key] to report the error.
  String _translateString(YamlNode node, String key) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        return value;
      }
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'String', _nodeType(node)]);
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'String', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a transform. Return the resulting transform, or
  /// `null` if the [node] does not represent a valid transform. If the [node]
  /// is not valid, use the name of the associated [key] to report the error.
  Transform _translateTransform(YamlNode node, String key) {
    if (node is YamlMap) {
      _reportUnsupportedKeys(
          node, const {_changesKey, _dateKey, _elementKey, _titleKey});
      var title = _translateString(node.valueAt(_titleKey), _titleKey);
      var date = _translateDate(node.valueAt(_dateKey), _dateKey);
      var element = _translateElement(node.valueAt(_elementKey), _elementKey);
      if (element == null) {
        // The error has already been reported.
        return null;
      }
      var changes = _translateList(
          node.valueAt(_changesKey), _changesKey, _translateChange);
      if (changes == null) {
        // The error has already been reported.
        return null;
      }
      if (_parameterModifications != null) {
        changes.add(ModifyParameters(modifications: _parameterModifications));
        _parameterModifications = null;
      }
      return Transform(
          title: title, date: date, element: element, changes: changes);
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'Map', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a transform set. Return the resulting transform
  /// set, or `null` if the [node] does not represent a valid transform set.
  TransformSet _translateTransformSet(YamlNode node) {
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {_transformsKey, _versionKey});
      var version = _translateInteger(node.valueAt(_versionKey), _versionKey);
      if (version == null) {
        // The error has already been reported.
        return null;
      } else if (version > currentVersion) {
        // TODO(brianwilkerson) Report that the version is unsupported.
        return null;
      }
      // TODO(brianwilkerson) Version information is currently being ignored,
      //  but needs to be used to select a translator.
      var transformations = _translateList(
          node.valueAt(_transformsKey), _transformsKey, _translateTransform);
      if (transformations == null) {
        // The error has already been reported.
        return null;
      }
      var set = TransformSet();
      for (var transform in transformations) {
        set.addTransform(transform);
      }
      return set;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          ['file', 'Map', _nodeType(node)]);
      return null;
    }
  }

  /// Translate the [node] into a value extractor. Return the resulting
  /// extractor, or `null` if the [node] does not represent a valid value
  /// extractor. If the [node] is not valid, use the name of the associated
  /// [key] to report the error.
  ValueExtractor _translateValueExtractor(YamlNode node, String key) {
    if (node is YamlMap) {
      var kind = _translateString(node.valueAt(_kindKey), _kindKey);
      if (kind == _argumentKind) {
        return _translateArgumentExtractor(node);
      }
      // TODO(brianwilkerson) Report the invalid extractor kind.
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      _reportError(TransformSetErrorCode.invalidValue, node,
          [key, 'Map', _nodeType(node)]);
      return null;
    }
  }
}
