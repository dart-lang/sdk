// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../common/names.dart';
import 'modular.dart';

class IrAnnotationData {
  Map<ir.Class, String> _nativeClassNames = {};
  Set<ir.Member> _nativeMembers = {};
  Map<ir.Member, String> _nativeMemberNames = {};
  Map<ir.Member, List<String>> _createsAnnotations = {};
  Map<ir.Member, List<String>> _returnsAnnotations = {};

  Map<ir.Library, String> _jsInteropLibraryNames = {};
  Map<ir.Class, String> _jsInteropClassNames = {};
  Set<ir.Class> _anonymousJsInteropClasses = {};
  Map<ir.Member, String> _jsInteropMemberNames = {};

  Map<ir.Member, List<PragmaAnnotationData>> _memberPragmaAnnotations = {};

  // Returns the text from the `@Native(<text>)` annotation of [node], if any.
  String getNativeClassName(ir.Class node) => _nativeClassNames[node];

  // Returns `true` if [node] has a native body, as in `method() native;`.
  bool hasNativeBody(ir.Member node) => _nativeMembers.contains(node);

  // Returns the text from the `@JSName(<text>)` annotation of [node], if any.
  String getNativeMemberName(ir.Member node) => _nativeMemberNames[node];

  // Returns a list of the text from the `@Creates(<text>)` annotation of
  // [node].
  List<String> getCreatesAnnotations(ir.Member node) =>
      _createsAnnotations[node] ?? const [];

  // Returns a list of the text from the `@Returns(<text>)` annotation of
  // [node].
  List<String> getReturnsAnnotations(ir.Member node) =>
      _returnsAnnotations[node] ?? const [];

  // Returns the text from the `@JS(<text>)` annotation of [node], if any.
  String getJsInteropLibraryName(ir.Library node) =>
      _jsInteropLibraryNames[node];

  // Returns the text from the `@JS(<text>)` annotation of [node], if any.
  String getJsInteropClassName(ir.Class node) => _jsInteropClassNames[node];

  // Returns `true` if [node] is annotated with `@anonymous`.
  bool isAnonymousJsInteropClass(ir.Class node) =>
      _anonymousJsInteropClasses.contains(node);

  // Returns the text from the `@JS(<text>)` annotation of [node], if any.
  String getJsInteropMemberName(ir.Member node) => _jsInteropMemberNames[node];

  // Returns a list of the `@pragma('dart2js:<suffix>')` annotations on [node].
  List<PragmaAnnotationData> getMemberPragmaAnnotationData(ir.Member node) =>
      _memberPragmaAnnotations[node] ?? const [];

  void forEachNativeClass(void Function(ir.Class, String) f) {
    _nativeClassNames.forEach(f);
  }

  void forEachJsInteropLibrary(void Function(ir.Library, String) f) {
    _jsInteropLibraryNames.forEach(f);
  }

  void forEachJsInteropClass(
      void Function(ir.Class, String, {bool isAnonymous}) f) {
    _jsInteropClassNames.forEach((ir.Class node, String name) {
      f(node, name, isAnonymous: isAnonymousJsInteropClass(node));
    });
  }

  void forEachJsInteropMember(void Function(ir.Member, String) f) {
    _jsInteropLibraryNames.forEach((ir.Library library, _) {
      for (ir.Member member in library.members) {
        if (member.isExternal) {
          f(member, _jsInteropMemberNames[member] ?? member.name.text);
        }
      }
    });
    _jsInteropClassNames.forEach((ir.Class cls, _) {
      for (ir.Member member in cls.members) {
        if (member is ir.Field) continue;
        String name = _jsInteropMemberNames[member];
        if (member.isExternal) {
          name ??= member.name.text;
        }
        f(member, name);
      }
    });
  }

  void forEachNativeMethodData(
      void Function(ir.Member, String name, Iterable<String> createsAnnotations,
              Iterable<String> returnsAnnotations)
          f) {
    for (ir.Member node in _nativeMembers) {
      if (node is! ir.Field) {
        String name = _nativeMemberNames[node] ?? node.name.text;
        f(node, name, getCreatesAnnotations(node), getReturnsAnnotations(node));
      }
    }
  }

  void forEachNativeFieldData(
      void Function(ir.Member, String name, Iterable<String> createsAnnotations,
              Iterable<String> returnsAnnotations)
          f) {
    for (ir.Class cls in _nativeClassNames.keys) {
      for (ir.Field field in cls.fields) {
        if (field.isInstanceMember) {
          String name = _nativeMemberNames[field] ?? field.name.text;
          f(field, name, getCreatesAnnotations(field),
              getReturnsAnnotations(field));
        }
      }
    }
  }
}

IrAnnotationData processAnnotations(ModularCore modularCore) {
  ir.Component component = modularCore.component;
  IrAnnotationData data = new IrAnnotationData();

  void processMember(ir.Member member) {
    ir.StaticTypeContext staticTypeContext = new ir.StaticTypeContext(
        member, modularCore.constantEvaluator.typeEnvironment);
    List<PragmaAnnotationData> pragmaAnnotations;
    List<String> createsAnnotations;
    List<String> returnsAnnotations;
    for (ir.Expression annotation in member.annotations) {
      if (annotation is ir.ConstantExpression) {
        ir.Constant constant = modularCore.constantEvaluator
            .evaluate(staticTypeContext, annotation);

        String jsName = _getJsInteropName(constant);
        if (jsName != null) {
          data._jsInteropMemberNames[member] = jsName;
        }

        bool isNativeMember = _isNativeMember(constant);
        if (isNativeMember) {
          data._nativeMembers.add(member);
        }

        String nativeName = _getNativeMemberName(constant);
        if (nativeName != null) {
          data._nativeMemberNames[member] = nativeName;
        }

        String creates = _getCreatesAnnotation(constant);
        if (creates != null) {
          if (createsAnnotations == null) {
            data._createsAnnotations[member] = createsAnnotations = [];
          }
          createsAnnotations.add(creates);
        }

        String returns = _getReturnsAnnotation(constant);
        if (returns != null) {
          if (returnsAnnotations == null) {
            data._returnsAnnotations[member] = returnsAnnotations = [];
          }
          returnsAnnotations.add(returns);
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
    ir.StaticTypeContext staticTypeContext =
        new ir.StaticTypeContext.forAnnotations(
            library, modularCore.constantEvaluator.typeEnvironment);
    for (ir.Expression annotation in library.annotations) {
      if (annotation is ir.ConstantExpression) {
        ir.Constant constant = modularCore.constantEvaluator
            .evaluate(staticTypeContext, annotation);

        String jsName = _getJsInteropName(constant);
        if (jsName != null) {
          data._jsInteropLibraryNames[library] = jsName;
        }
      }
    }
    for (ir.Class cls in library.classes) {
      for (ir.Expression annotation in cls.annotations) {
        if (annotation is ir.ConstantExpression) {
          ir.Constant constant = modularCore.constantEvaluator
              .evaluate(staticTypeContext, annotation);

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
    // TODO(johnniwinther): Add an IrCommonElements for these queries; i.e.
    // `commonElements.isNativeAnnotationClass(constant.classNode)`.
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

bool _isNativeMember(ir.Constant constant) {
  return constant is ir.InstanceConstant &&
      constant.classNode.name == 'ExternalName' &&
      constant.classNode.enclosingLibrary.importUri == Uris.dart__internal;
}

String _getNativeMemberName(ir.Constant constant) {
  if (constant is ir.InstanceConstant &&
      constant.classNode.name == 'JSName' &&
      constant.classNode.enclosingLibrary.importUri == Uris.dart__js_helper) {
    assert(constant.fieldValues.length == 1);
    ir.Constant fieldValue = constant.fieldValues.values.single;
    if (fieldValue is ir.StringConstant) {
      return fieldValue.value;
    }
  }
  return null;
}

String _getCreatesAnnotation(ir.Constant constant) {
  if (constant is ir.InstanceConstant &&
      constant.classNode.name == 'Creates' &&
      constant.classNode.enclosingLibrary.importUri == Uris.dart__js_helper) {
    assert(constant.fieldValues.length == 1);
    ir.Constant fieldValue = constant.fieldValues.values.single;
    if (fieldValue is ir.StringConstant) {
      return fieldValue.value;
    }
  }
  return null;
}

String _getReturnsAnnotation(ir.Constant constant) {
  if (constant is ir.InstanceConstant &&
      constant.classNode.name == 'Returns' &&
      constant.classNode.enclosingLibrary.importUri == Uris.dart__js_helper) {
    assert(constant.fieldValues.length == 1);
    ir.Constant fieldValue = constant.fieldValues.values.single;
    if (fieldValue is ir.StringConstant) {
      return fieldValue.value;
    }
  }
  return null;
}

String _getJsInteropName(ir.Constant constant) {
  if (constant is ir.InstanceConstant &&
      constant.classNode.name == 'JS' &&
      (constant.classNode.enclosingLibrary.importUri == Uris.package_js ||
          constant.classNode.enclosingLibrary.importUri ==
              Uris.dart__js_annotations)) {
    assert(constant.fieldValues.length == 1);
    ir.Constant fieldValue = constant.fieldValues.values.single;
    if (fieldValue is ir.NullConstant) {
      return '';
    } else if (fieldValue is ir.StringConstant) {
      return fieldValue.value;
    }
  }
  return null;
}

bool _isAnonymousJsInterop(ir.Constant constant) {
  return constant is ir.InstanceConstant &&
      constant.classNode.name == '_Anonymous' &&
      (constant.classNode.enclosingLibrary.importUri == Uris.package_js ||
          constant.classNode.enclosingLibrary.importUri ==
              Uris.dart__js_annotations);
}

class PragmaAnnotationData {
  // TODO(johnniwinther): Support non 'dart2js:' pragma names if necessary.
  final String suffix;

  // TODO(johnniwinther): Support options objects when necessary.
  final bool hasOptions;

  const PragmaAnnotationData(this.suffix, {this.hasOptions: false});

  String get name => 'dart2js:$suffix';

  @override
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
      if (field.name.text == 'name') {
        nameValue = fieldValue;
      } else if (field.name.text == 'options') {
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
    assert(constant is! ir.UnevaluatedConstant,
        "Unexpected unevaluated constant on $member: $metadata");
    PragmaAnnotationData data = _getPragmaAnnotation(constant);
    if (data != null) {
      annotations.add(data);
    }
  }
  return annotations;
}
