// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:path/path.dart' show relative;

import 'schema.dart' as schema;

/// Returns the name of the [constructor].
///
/// This is either `<class-name>` or `<class-name>.<constructor-name>`,
/// depending on whether the constructor is a named constructor.
String _computeConstructorElementName(ConstructorElement constructor) {
  var name = constructor.enclosingElement.name!;
  var constructorName = constructor.name;
  if (constructorName != null && constructorName != 'new') {
    name = '$name.$constructorName';
  }
  return name;
}

String? _getNodeKind(Element e) {
  if (e is FieldElement && e.isEnumConstant) {
    // FieldElement is a kind of VariableElement, so this test case must be
    // before the e is VariableElement check.
    return schema.constantKind;
  } else if (e is VariableElement || e is PrefixElement) {
    return schema.variableKind;
  } else if (e is ExecutableElement) {
    return schema.functionKind;
  } else if (e is InterfaceElement || e is TypeParameterElement) {
    // TODO(jwren): this should be using absvar instead, see
    // https://kythe.io/docs/schema/#absvar
    return schema.recordKind;
  }
  return null;
}

String _getPath(
  ResourceProvider provider,
  Element? e, {
  String? sdkRootPath,
  String? corpus,
}) {
  // TODO(jwren): This method simply serves to provide the WORKSPACE relative
  // path for sources in Elements, it needs to be written in a more robust way.
  // TODO(jwren): figure out what source generates a e != null, but
  // e.source == null to ensure that it is not a bug somewhere in the stack.
  var source = e?.firstFragment.libraryFragment!.source;
  if (source == null) {
    // null sometimes when the element is used to generate the node type
    // "dynamic"
    return '';
  }
  if (sdkRootPath != null) {
    var uri = source.uri;
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.length == 1) {
        var libraryName = pathSegments.single;
        return '$sdkRootPath/lib/$libraryName/$libraryName.dart';
      } else {
        return '$sdkRootPath/lib/${uri.path}';
      }
    }
    return relative(source.fullName, from: '/$corpus/');
  }

  var path = source.fullName;
  var blazeWorkspace = BlazeWorkspace.find(provider, path);
  if (blazeWorkspace != null) {
    return provider.pathContext.relative(path, from: blazeWorkspace.root);
  }
  if (path.lastIndexOf('CORPUS_NAME') != -1) {
    return path.substring(path.lastIndexOf('CORPUS_NAME') + 12);
  }

  return path;
}

/// If a non-null element is passed, the [_SignatureElementVisitor] is used to
/// generate and return a [String] signature, otherwise [schema.dynamicKind] is
/// returned.
String _getSignature(
  ResourceProvider provider,
  Element? element,
  String nodeKind,
  String corpus, {
  String? sdkRootPath,
}) {
  assert(nodeKind != schema.anchorKind); // Call _getAnchorSignature instead
  if (element == null) {
    return schema.dynamicKind;
  }
  if (element is LibraryElement) {
    return _getPath(
      provider,
      element,
      sdkRootPath: sdkRootPath,
      corpus: corpus,
    );
  }
  var builder = _SignatureBuilder.instance;
  return '$nodeKind:${builder.signatureFor(element)}';
}

/// A helper class for getting the Kythe uri's for elements for querying
/// Kythe from Cider.
class CiderKytheHelper {
  final String sdkRootPath;
  final String corpus;
  final ResourceProvider resourceProvider;

  CiderKytheHelper(this.resourceProvider, this.corpus, this.sdkRootPath);

  /// Returns a URI that can be used to query Kythe.
  String toKytheUri(Element e) {
    var nodeKind = _getNodeKind(e) ?? schema.recordKind;
    var vname = _vNameFromElement(e, nodeKind);
    return 'kythe://$corpus?lang=dart?path=${vname.path}#${vname.signature}';
  }

  /// Returns the Kythe name for the [element].
  _KytheVName _vNameFromElement(Element? e, String nodeKind) {
    assert(nodeKind != schema.fileKind);
    // general case
    return _KytheVName(
      path: _getPath(
        resourceProvider,
        e,
        sdkRootPath: sdkRootPath,
        corpus: corpus,
      ),
      signature: _getSignature(
        resourceProvider,
        e,
        nodeKind,
        corpus,
        sdkRootPath: sdkRootPath,
      ),
    );
  }
}

class _KytheVName {
  final String path;
  final String signature;

  _KytheVName({required this.path, required this.signature});
}

/// An objects that builds up a string signature for an element.
///
/// Uniqueness is guaranteed within the enclosing file.
class _SignatureBuilder {
  static _SignatureBuilder instance = _SignatureBuilder();

  StringBuffer signatureFor(Element element) {
    var buffer = StringBuffer();
    _appendSignatureTo(buffer, element);
    return buffer;
  }

  void _appendSignatureTo(StringBuffer buffer, Element element) {
    if (element is LibraryElement) {
      buffer.write('library:${element.displayName}');
    } else if (element is TypeParameterElement) {
      // It is legal to have a named constructor with the same name as a type
      // parameter.  So we distinguish them by using '.' between the class (or
      // typedef) name and the type parameter name.
      _appendSignatureTo(buffer, element.enclosingElement!);
      buffer
        ..write('.')
        ..write(element.name!);
    } else {
      var enclosingElt = element.enclosingElement!;
      _appendSignatureTo(buffer, enclosingElt);
      if (buffer.isNotEmpty) {
        buffer.write('#');
      }
      if (element is MethodElement &&
          element.name == '-' &&
          element.formalParameters.length == 1) {
        buffer.write('unary-');
      } else if (element is ConstructorElement) {
        buffer.write(_computeConstructorElementName(element));
      } else {
        buffer.write(element.name);
      }
      if (enclosingElt is ExecutableElement) {
        buffer
          ..write('@')
          ..write(
            element.firstFragment.nameOffset! -
                enclosingElt.firstFragment.nameOffset!,
          );
      }
    }
  }
}
