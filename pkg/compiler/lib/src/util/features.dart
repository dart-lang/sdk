// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Set of features used in annotations.
class Features {
  Map<String, Object> _features = {};

  void add(String key, {var value: ''}) {
    _features[key] = value.toString();
  }

  void addElement(String key, [var value]) {
    List<String> list = _features.putIfAbsent(key, () => <String>[]);
    if (value != null) {
      list.add(value.toString());
    }
  }

  bool containsKey(String key) {
    return _features.containsKey(key);
  }

  void operator []=(String key, String value) {
    _features[key] = value;
  }

  Object operator [](String key) => _features[key];

  Object remove(String key) => _features.remove(key);

  bool get isEmpty => _features.isEmpty;

  bool get isNotEmpty => _features.isNotEmpty;

  void forEach(void Function(String, Object) f) {
    _features.forEach(f);
  }

  /// Returns a string containing all features in a comma-separated list sorted
  /// by feature names.
  String getText() {
    StringBuffer sb = new StringBuffer();
    bool needsComma = false;
    for (String name in _features.keys.toList()..sort()) {
      dynamic value = _features[name];
      if (value != null) {
        if (needsComma) {
          sb.write(',');
        }
        sb.write(name);
        if (value is List<String>) {
          value = '[${(value..sort()).join(',')}]';
        }
        if (value != '') {
          sb.write('=');
          sb.write(value);
        }
        needsComma = true;
      }
    }
    return sb.toString();
  }

  @override
  String toString() => 'Features(${getText()})';

  /// Creates a [Features] object by parse the [text] encoding.
  ///
  /// Single features will be parsed as strings and list features (features
  /// encoded in `[...]` will be parsed as lists of strings.
  static Features fromText(String text) {
    Features features = new Features();
    if (text == null) return features;
    int index = 0;
    while (index < text.length) {
      int eqPos = text.indexOf('=', index);
      int commaPos = text.indexOf(',', index);
      String name;
      bool hasValue = false;
      if (eqPos != -1 && commaPos != -1) {
        if (eqPos < commaPos) {
          name = text.substring(index, eqPos);
          hasValue = true;
          index = eqPos + 1;
        } else {
          name = text.substring(index, commaPos);
          index = commaPos + 1;
        }
      } else if (eqPos != -1) {
        name = text.substring(index, eqPos);
        hasValue = true;
        index = eqPos + 1;
      } else if (commaPos != -1) {
        name = text.substring(index, commaPos);
        index = commaPos + 1;
      } else {
        name = text.substring(index);
        index = text.length;
      }
      if (hasValue) {
        const Map<String, String> delimiters = const {
          '[': ']',
          '{': '}',
          '(': ')',
          '<': '>'
        };
        List<String> endDelimiters = <String>[];
        bool isList = index < text.length && text.startsWith('[', index);
        if (isList) {
          features.addElement(name);
          endDelimiters.add(']');
          index++;
        }
        int valueStart = index;
        while (index < text.length) {
          String char = text.substring(index, index + 1);
          if (endDelimiters.isNotEmpty && endDelimiters.last == char) {
            endDelimiters.removeLast();
            index++;
          } else {
            String endDelimiter = delimiters[char];
            if (endDelimiter != null) {
              endDelimiters.add(endDelimiter);
              index++;
            } else if (char == ',') {
              if (endDelimiters.isEmpty) {
                break;
              } else if (endDelimiters.length == 1 && isList) {
                String value = text.substring(valueStart, index);
                features.addElement(name, value);
                index++;
                valueStart = index;
              } else {
                index++;
              }
            } else {
              index++;
            }
          }
        }
        if (isList) {
          String value = text.substring(valueStart, index - 1);
          if (value.isNotEmpty) {
            features.addElement(name, value);
          }
        } else {
          String value = text.substring(valueStart, index);
          features.add(name, value: value);
        }
        index++;
      } else {
        features.add(name);
      }
    }
    return features;
  }
}
