// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Generates all the API files for Python.
 */
library codegen.python.core;

import 'package:analyzer/src/codegen/tools.dart';

String generateBaseClasses() {
  var content = '''
class RefactoringOptions(object):
    pass


class RefactoringFeedback(object):
    pass


class Request(object):
    def __init__(self, id, name, params):
        self.id = id
        self.name = name
        self.params = params

    def to_json(self):
        result = {}
        result["id"] = self.id
        result["method"] = self.name
        if self.params:
            result["params"] = self.params.to_json()
        return result


class Response(object):
    def __init__(self, id, result):
        self.id = id
        self._result = result


class Notification(object):
    def __init__(self, event, params):
        self.event = event
        self.params = params


class HasToJson(object):
    def to_json(self, json_data):
        pass
''';
  return content;
}

final GeneratedFile target = new GeneratedFile(
    'tool/spec/generated_python/core.py', (String pkgPath) {
  return generateBaseClasses();
});
