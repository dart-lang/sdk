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
 * This recursive function builds a YAML string from [documentData] and
 * adds it to [yaml].
 * The [level] input determines the indentation of the block being processed.
 * The [isList] input determines whether [documentData] is a member of an outer
 * lists of maps. A map must be preceeded with a '-' if it is to exist at the
 * same level of indentation in the YAML output as other members of the list.
 */
void _addLevel(StringBuffer yaml, Map documentData, int level,
               {bool isList: false}) {
  // The order of the keys could be nondeterministic, but it is insufficient
  // to just sort the keys no matter what, as their order could be significant
  // (i.e. parameters to a method). The order of the keys should be enforced
  // by the caller of this function.
  var keys = documentData.keys.toList();
  keys.forEach((key) {
    _calcSpaces(level, yaml);
    // Only the first entry of the map should be preceeded with a '-' since
    // the map is a member of an outer list and the map as a whole must be
    // marked as a single member of that list. See example 2.4 at
    // http://www.yaml.org/spec/1.2/spec.html#id2759963
    if (isList && key == keys.first) {
      yaml.write("- ");
      level++;
    }
    yaml.write("\"$key\" : ");
    if (documentData[key] is Map) {
      yaml.write("\n");
      _addLevel(yaml, documentData[key], level + 1);
    } else if (documentData[key] is List) {
      var elements = documentData[key];
      yaml.write("\n");
      elements.forEach( (element) {
        if (element is Map) {
          _addLevel(yaml, element, level + 1, isList: true);
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
  var contents = element.toString()
      .replaceAll('\\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return '"$contents"\n';
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