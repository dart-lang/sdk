library pub.rewrite_import_transformer;
import 'dart:async';
import 'package:barback/barback.dart';
import '../dart.dart';
class RewriteImportTransformer extends Transformer {
  String get allowedExtensions => '.dart';
  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var directives =
          parseImportsAndExports(contents, name: transform.primaryInput.id.toString());
      var buffer = new StringBuffer();
      var index = 0;
      for (var directive in directives) {
        var uri = Uri.parse(directive.uri.stringValue);
        if (uri.scheme != 'package') continue;
        buffer
            ..write(contents.substring(index, directive.uri.literal.offset))
            ..write('"/packages/${uri.path}"');
        index = directive.uri.literal.end;
      }
      buffer.write(contents.substring(index, contents.length));
      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, buffer.toString()));
    });
  }
}
