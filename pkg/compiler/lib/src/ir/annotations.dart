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

  Map<ir.Member, List<PragmaAnnotationData>> _memberPragmaAnnotations = {};

  String getNativeClassName(ir.Class node) => _nativeClassNames[node];

  String getJsInteropLibraryName(ir.Library node) =>
      _jsInteropLibraryNames[node];

  String getJsInteropClassName(ir.Class node) => _jsInteropClassNames[node];

  bool isAnonymousJsInteropClass(ir.Class node) =>
      _anonymousJsInteropClasses.contains(node);

  String getJsInteropMemberName(ir.Member node) => _jsInteropMemberNames[node];

  List<PragmaAnnotationData> getMemberPragmaAnnotationData(ir.Member node) =>
      _memberPragmaAnnotations[node] ?? const [];
}

IrAnnotationData processAnnotations(ir.Component component) {
  IrAnnotationData data = new IrAnnotationData();

  void processMember(ir.Member member) {
    List<PragmaAnnotationData> pragmaAnnotations;
    for (ir.Expression annotation in member.annotations) {
      if (annotation is ir.ConstantExpression) {
        ir.Constant constant = annotation.constant;
        String jsName = _getJsInteropName(constant);
        if (jsName != null) {
          data._jsInteropMemberNames[member] = jsName;
        }
        PragmaAnnotationData pragmaAnnotation = _getPragmaAnnotation(constant);
        if (pragmaAnnotation != null) {
          if (pragmaAnnotations == null) {
            data._memberPragmaAnnotations[member] = pragmaAnnotations = [];
          }
          pragmaAnnotations.add(pragmaAnnotation);
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

class PragmaAnnotationData {
  // TODO(johnniwinther): Support non 'dart2js:' pragma names if necessary.
  final String suffix;

  // TODO(johnniwinther): Support options objects when necessary.
  final bool hasOptions;

  const PragmaAnnotationData(this.suffix, {this.hasOptions: false});

  String get name => 'dart2js:$suffix';

  String toString() => 'PragmaAnnotationData($name)';
}

PragmaAnnotationData _getPragmaAnnotation(ir.Constant constant) {
  if (constant is! ir.InstanceConstant) return null;
  ir.InstanceConstant value = constant;
  ir.Class cls = value.classNode;
  Uri uri = cls.enclosingLibrary.importUri;
  if (uri == Uris.package_meta_dart2js) {
    if (cls.name == '_NoInline') {
      return const PragmaAnnotationData('noInline');
    } else if (cls.name == '_TryInline') {
      return const PragmaAnnotationData('tryInline');
    }
  } else if (uri == Uris.dart_core && cls.name == 'pragma') {
    ir.Constant nameValue;
    ir.Constant optionsValue;
    value.fieldValues.forEach((ir.Reference reference, ir.Constant fieldValue) {
      ir.Field field = reference.asField;
      if (field.name.name == 'name') {
        nameValue = fieldValue;
      } else if (field.name.name == 'options') {
        optionsValue = fieldValue;
      }
    });
    if (nameValue is! ir.StringConstant) return null;
    ir.StringConstant stringValue = nameValue;
    String name = stringValue.value;
    String prefix = 'dart2js:';
    if (!name.startsWith(prefix)) return null;
    String suffix = name.substring(prefix.length);
    return new PragmaAnnotationData(suffix,
        hasOptions: optionsValue is! ir.NullConstant);
  }
  return null;
}

List<PragmaAnnotationData> computePragmaAnnotationDataFromIr(ir.Member member) {
  List<PragmaAnnotationData> annotations = [];
  for (ir.Expression metadata in member.annotations) {
    if (metadata is! ir.ConstantExpression) continue;
    ir.ConstantExpression constantExpression = metadata;
    ir.Constant constant = constantExpression.constant;
    PragmaAnnotationData data = _getPragmaAnnotation(constant);
    if (data != null) {
      annotations.add(data);
    }
  }
  return annotations;
}
