// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/utilities/extensions/yaml.dart';
import 'package:analyzer/error/listener.dart';
import 'package:yaml/yaml.dart';

/// A parser used to read a transform set from a file.
class TransformSetParser {
  static const String _changesKey = 'changes';

  static const String _classKey = 'class';

  static const String _constructorKey = 'constructor';

  static const String _elementKey = 'element';

  static const String _enumConstantKey = 'constant';

  static const String _enumKey = 'enum';

  static const String _extensionKey = 'extension';

  static const String _fieldKey = 'field';

  static const String _functionKey = 'function';

  static const String _getterKey = 'getter';

  static const String _inClassKey = 'inClass';

  static const String _inEnumKey = 'inEnum';

  static const String _inExtensionKey = 'inExtension';

  static const String _inMixinKey = 'inMixin';

  static const String _kindKey = 'kind';

  static const String _methodKey = 'method';

  static const String _mixinKey = 'mixin';

  static const String _newNameKey = 'newName';

  static const String _setterKey = 'setter';

  static const String _titleKey = 'title';

  static const String _transformsKey = 'transforms';

  static const String _typedefKey = 'typedef';

  static const String _urisKey = 'uris';

  static const String _versionKey = 'version';

  /// A table mapping top-level keys for member elements to the list of keys for
  /// the possible containers of that element.
  static const Map<String, List<String>> _containerKeyMap = {
    _constructorKey: [_inClassKey],
    _enumConstantKey: [_inEnumKey],
    _fieldKey: [_inClassKey, _inExtensionKey, _inMixinKey],
    _getterKey: [_inClassKey, _inExtensionKey, _inMixinKey],
    _methodKey: [_inClassKey, _inExtensionKey, _inMixinKey],
    _setterKey: [_inClassKey, _inExtensionKey, _inMixinKey],
  };

  static const String _renameKind = 'rename';

  static const int currentVersion = 1;

  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

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
      if (keyNode is YamlScalar) {
        var key = _translateString(keyNode);
        if (key != null && !validKeys.contains(key)) {
          _reportError(TransformSetErrorCode.unsupportedKey, keyNode, [key]);
        }
      } else {
        // TODO(brianwilkerson) Report the unsupported key.
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
      if (keyNode is YamlScalar) {
        var key = _translateString(keyNode);
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
      // TODO(brianwilkerson) Report the invalid key.
    }
    return foundKeys[0];
  }

  /// Translate the [node] into a change. Return the resulting change, or `null`
  /// if the [node] does not represent a valid change.
  Change _translateChange(YamlNode node) {
    if (node is YamlMap) {
      var kind = _translateString(node.valueAt(_kindKey));
      // TODO(brianwilkerson) Implement additional change kinds.
      if (kind == _renameKind) {
        return _translateRenameChange(node);
      }
      // TODO(brianwilkerson) Report the invalid change kind.
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML.
      return null;
    }
  }

  /// Translate the [node] into an element descriptor. Return the resulting
  /// descriptor, or `null` if the [node] does not represent a valid element
  /// descriptor.
  ElementDescriptor _translateElement(YamlNode node) {
    if (node is YamlMap) {
      var uris = _translateList(node.valueAt(_urisKey), _translateString);
      if (uris == null) {
        // TODO(brianwilkerson) Returning here prevents other errors from being
        //  reported.
        // The error has already been reported.
        return null;
      }
      var elementKey = _singleKey(node, [
        _classKey,
        _enumConstantKey,
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
      var elementName = _translateString(node.valueAt(elementKey));
      if (elementName == null) {
        // The error has already been reported.
        return null;
      }
      var components = [elementName];
      var containerKey = _singleKey(node, _containerKeyMap[elementKey]);
      var containerName = _translateString(node.valueAt(containerKey));
      if (containerName == null) {
        if ([_constructorKey, _enumConstantKey, _methodKey, _fieldKey]
            .contains(elementKey)) {
          // TODO(brianwilkerson) Report that no container was found.
          return null;
        }
      } else {
        components.insert(0, containerName);
      }
      return ElementDescriptor(libraryUris: uris, components: components);
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML.
      return null;
    }
  }

  /// Translate the [node] into an integer. Return the resulting integer, or
  /// `null` if the [node] does not represent a valid integer.
  int _translateInteger(YamlNode node) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is int) {
        return value;
      }
      // TODO(brianwilkerson) Report the invalid YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    }
  }

  /// Translate the [node] into a list of objects using the [elementTranslator].
  /// Return the resulting list, or `null` if the [node] does not represent a
  /// valid list. If any of the elements of the list can't be translated, they
  /// will be omitted from the list but the valid elements will be returned.
  List<R> _translateList<R>(
      YamlNode node, R Function(YamlNode) elementTranslator) {
    if (node is YamlList) {
      var translatedList = <R>[];
      for (var element in node.nodes) {
        var result = elementTranslator(element);
        if (result != null) {
          translatedList.add(result);
        }
      }
      return translatedList;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML.
      return null;
    }
  }

  /// Translate the [node] into a rename change. Return the resulting change, or
  /// `null` if the [node] does not represent a valid rename change.
  Change _translateRenameChange(YamlMap node) {
    _reportUnsupportedKeys(node, const {_kindKey, _newNameKey});
    var newName = _translateString(node.valueAt(_newNameKey));
    if (newName == null) {
      return null;
    }
    return Rename(newName: newName);
  }

  /// Translate the [node] into a string. Return the resulting string, or `null`
  /// if the [node] does not represent a valid string.
  String _translateString(YamlNode node) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        return value;
      }
      // TODO(brianwilkerson) Report the invalid YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML. For the best UX we
      //  probably need to pass in the code to report.
      return null;
    }
  }

  /// Translate the [node] into a transform. Return the resulting transform, or
  /// `null` if the [node] does not represent a valid transform.
  Transform _translateTransform(YamlNode node) {
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {_changesKey, _elementKey, _titleKey});
      var title = _translateString(node.valueAt(_titleKey));
      var element = _translateElement(node.valueAt(_elementKey));
      var changes =
          _translateList<Change>(node.valueAt(_changesKey), _translateChange);
      if (changes == null) {
        // The error has already been reported.
        return null;
      }
      return Transform(title: title, element: element, changes: changes);
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML.
      return null;
    }
  }

  /// Translate the [node] into a transform set. Return the resulting transform
  /// set, or `null` if the [node] does not represent a valid transform set.
  TransformSet _translateTransformSet(YamlNode node) {
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {_transformsKey, _versionKey});
      var set = TransformSet();
      // TODO(brianwilkerson) Version information is currently being ignored,
      //  but needs to be used to select a translator.
      var version = _translateInteger(node.valueAt(_versionKey));
      if (version != currentVersion) {
        // TODO(brianwilkerson) Report the unsupported version.
      }
      var transformations =
          _translateList(node.valueAt(_transformsKey), _translateTransform);
      if (transformations == null) {
        // The error has already been reported.
        return null;
      }
      for (var transform in transformations) {
        set.addTransform(transform);
      }
      return set;
    } else if (node == null) {
      // TODO(brianwilkerson) Report the missing YAML.
      return null;
    } else {
      // TODO(brianwilkerson) Report the invalid YAML.
      return null;
    }
  }
}
