// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.element;

import 'package:analysis_server/src/protocol2.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;


/**
 * Returns a JSON correponding to the given Engine element.
 */
Map<String, Object> engineElementToJson(engine.Element element) {
  return new Element.fromEngine(element).toJson();
}


Element elementFromEngine(engine.Element element) {
  String name = element.displayName;
  String elementParameters = _getParametersString(element);
  String elementReturnType = _getReturnTypeString(element);
  return new Element(
    new ElementKind.fromEngine(element.kind),
    name,
    Element.makeFlags(isPrivate: element.isPrivate,
        isDeprecated: element.isDeprecated,
        isAbstract: _isAbstract(element),
        isConst: _isConst(element),
        isFinal: _isFinal(element),
        isStatic: _isStatic(element)),
    location: new Location.fromElement(element),
    parameters: elementParameters,
    returnType: elementReturnType);
}

String _getParametersString(engine.Element element) {
  // TODO(scheglov) expose the corresponding feature from ExecutableElement
  if (element is engine.ExecutableElement) {
    var sb = new StringBuffer();
    String closeOptionalString = '';
    for (var parameter in element.parameters) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      if (closeOptionalString.isEmpty) {
        if (parameter.kind == engine.ParameterKind.NAMED) {
          sb.write('{');
          closeOptionalString = '}';
        }
        if (parameter.kind == engine.ParameterKind.POSITIONAL) {
          sb.write('[');
          closeOptionalString = ']';
        }
      }
      sb.write(parameter.toString());
    }
    sb.write(closeOptionalString);
    return '(' + sb.toString() + ')';
  } else {
    return null;
  }
}

String _getReturnTypeString(engine.Element element) {
  if ((element is engine.ExecutableElement)) {
    return element.returnType.toString();
  } else {
    return null;
  }
}

bool _isAbstract(engine.Element element) {
  // TODO(scheglov) add isAbstract to Element API
  if (element is engine.ClassElement) {
    return element.isAbstract;
  }
  if (element is engine.MethodElement) {
    return element.isAbstract;
  }
  if (element is engine.PropertyAccessorElement) {
    return element.isAbstract;
  }
  return false;
}

bool _isConst(engine.Element element) {
  // TODO(scheglov) add isConst to Element API
  if (element is engine.ConstructorElement) {
    return element.isConst;
  }
  if (element is engine.VariableElement) {
    return element.isConst;
  }
  return false;
}

bool _isFinal(engine.Element element) {
  // TODO(scheglov) add isFinal to Element API
  if (element is engine.VariableElement) {
    return element.isFinal;
  }
  return false;
}

bool _isStatic(engine.Element element) {
  // TODO(scheglov) add isStatic to Element API
  if (element is engine.ExecutableElement) {
    return element.isStatic;
  }
  if (element is engine.PropertyInducingElement) {
    return element.isStatic;
  }
  return false;
}
