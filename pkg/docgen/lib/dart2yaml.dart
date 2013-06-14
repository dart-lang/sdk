// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library is used to convert data from a map to a YAML string.
 */
library dart2yaml;

/**
 * Gets a String representing the input Map in YAML format.
 */
String getYamlString(Map documentData) {
  StringBuffer yaml = new StringBuffer();
  _addLevel(yaml, documentData, 0);
  return yaml.toString();
}

/**
 * This recursive function adds to its input StringBuffer and builds
 * a YAML string from the input Map.
 */
// TODO(tmandel): Fix quotes with String objects.
void _addLevel(StringBuffer yaml, Map documentData, int level) {
  documentData.keys.forEach( (key) {
    _calcSpaces(level, yaml);
    yaml.write("\"$key\" : ");

    if (documentData[key] is Map) {
      yaml.write("\n");
      _addLevel(yaml, documentData[key], level + 1);

    } else if (documentData[key] is List) {
      var elements = documentData[key];
      yaml.write("\n");
      elements.forEach( (element) {
        if (element is Map) {
          _addLevel(yaml, element, level + 1);
        } else {
          _calcSpaces(level + 1, yaml);
          yaml.write("- ${_processElement(element)}");
        }
      });
      
    } else {
      yaml.write(_processElement(documentData[key]));
    }
  });
}

/**
 * Returns an escaped String form of the inputted element.
 */
String _processElement(var element) {
  return "\"${element.toString().replaceAll("\"", "\\\"")}\"\n";
}

/**
 * Based on the depth in the file, this function returns the correct spacing
 * for an element in the YAML output.
 */
void _calcSpaces(int spaceLevel, StringBuffer yaml) {
  for (int i = 0; i < spaceLevel; i++) {
    yaml.write("  ");
  }
}