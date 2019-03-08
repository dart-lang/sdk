// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import '../common/names.dart';

class IrAnnotationData {
  Map<ir.Class, String> _nativeClassNames = {};

  Map<ir.Library, String> _jsInteropLibraryNames = {};
  Map<ir.Class, String> _jsInteropClassNames = {};
  Set<ir.Class> _anonymousJsInteropClasses = {};
  Map<ir.Member, String> _jsInteropMemberNames = {};

  String getNativeClassName(ir.Class node) => _nativeClassNames[node];

  String getJsInteropLibraryName(ir.Library node) =>
      _jsInteropLibraryNames[node];
  String getJsInteropClassName(ir.Class node) => _jsInteropClassNames[node];
  bool isAnonymousJsInteropClass(ir.Class node) =>
      _anonymousJsInteropClasses.contains(node);
  String getJsInteropMemberName(ir.Member node) => _jsInteropMemberNames[node];
}

IrAnnotationData processAnnotations(ir.Component component) {
  IrAnnotationData data = new IrAnnotationData();

  void processMember(ir.Member member) {
    for (ir.Expression annotation in member.annotations) {
      if (annotation is ir.ConstantExpression) {
        ir.Constant constant = annotation.constant;
        String jsName = _getJsInteropName(constant);
        if (jsName != null) {
          data._jsInteropMemberNames[member] = jsName;
        }
      }
    }
  }

  for (ir.Library library in component.libraries) {
    for (ir.Expression annotation in library.annotations) {
      if (annotation is ir.ConstantExpression) {
        ir.Constant constant = annotation.constant;

        String jsName = _getJsInteropName(constant);
        if (jsName != null) {
          data._jsInteropLibraryNames[library] = jsName;
        }
      }
    }
    for (ir.Class cls in library.classes) {
      for (ir.Expression annotation in cls.annotations) {
        if (annotation is ir.ConstantExpression) {
          ir.Constant constant = annotation.constant;

          String nativeClassName = _getNativeClassName(constant);
          if (nativeClassName != null) {
            data._nativeClassNames[cls] = nativeClassName;
          }

          String jsName = _getJsInteropName(constant);
          if (jsName != null) {
            data._jsInteropClassNames[cls] = jsName;
          }

          bool isAnonymousJsInteropClass = _isAnonymousJsInterop(constant);
          if (isAnonymousJsInteropClass) {
            data._anonymousJsInteropClasses.add(cls);
          }
        }
      }
      for (ir.Member member in cls.members) {
        processMember(member);
      }
    }
    for (ir.Member member in library.members) {
      processMember(member);
    }
  }
  return data;
}

String _getNativeClassName(ir.Constant constant) {
  if (constant is ir.InstanceConstant) {
    if (constant.classNode.name == 'Native' &&
        constant.classNode.enclosingLibrary.importUri == Uris.dart__js_helper) {
      if (constant.fieldValues.length == 1) {
        ir.Constant fieldValue = constant.fieldValues.values.single;
        String name;
        if (fieldValue is ir.StringConstant) {
          name = fieldValue.value;
        }
        if (name != null) {
          return name;
        }
      }
    }
  }
  return null;
}

String _getJsInteropName(ir.Constant constant) {
  if (constant is ir.InstanceConstant) {
    if (constant.classNode.name == 'JS' &&
        constant.classNode.enclosingLibrary.importUri == Uris.package_js) {
      if (constant.fieldValues.length == 1) {
        ir.Constant fieldValue = constant.fieldValues.values.single;
        String name;
        if (fieldValue is ir.NullConstant) {
          name = '';
        } else if (fieldValue is ir.StringConstant) {
          name = fieldValue.value;
        }
        if (name != null) {
          return name;
        }
      }
    }
  }
  return null;
}

bool _isAnonymousJsInterop(ir.Constant constant) {
  if (constant is ir.InstanceConstant) {
    return constant.classNode.name == '_Anonymous' &&
        constant.classNode.enclosingLibrary.importUri == Uris.package_js;
  }
  return false;
}
