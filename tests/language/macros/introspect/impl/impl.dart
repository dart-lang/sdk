import 'package:macros/macros.dart';

/// Converts an object into primitives.
///
/// This allows test expectations for the object to be passed to the macro
/// application.
///
/// Conversion might not contain all the data in the object: there is a
/// tradeoff, more data makes the test more precise but also more brittle.
Object stringify(Object? object) {
  if (object is List) {
    return object.map(stringify).toList();
  } else if (object is ConstructorDeclaration) {
    return '${object.identifier.name}()';
  } else if (object is FieldDeclaration) {
    return '${stringify(object.type)} ${object.identifier.name}';
  } else if (object is Identifier) {
    return object.name;
  } else if (object is MethodDeclaration) {
    return '${stringify(object.returnType)} ${object.identifier.name}()';
  } else if (object is NamedTypeAnnotation) {
    return object.identifier.name;
  } else {
    throw new UnsupportedError('Don’t know how to stringify with type '
        '${object.runtimeType}: "$object"');
  }
}
