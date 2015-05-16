library dromaeo.transformer;

import 'dart:async';
import 'package:barback/barback.dart';

/// Transformer used by `pub build` and `pub serve` to rewrite dromaeo html
/// files to run performance tests.
class DromaeoTransformer extends Transformer {

  final BarbackSettings settings;

  DromaeoTransformer.asPlugin(this.settings);

  /// The index.html file and the tests/dom-*-html.html files are the ones we
  /// apply this transform to.
  Future<bool> isPrimary(AssetId id) {
    var reg = new RegExp('(tests/dom-.+-html\.html\$)|(index\.html\$)');
    return new Future.value(reg.hasMatch(id.path));
  }

  Future apply(Transform transform) {
    Asset primaryAsset = transform.primaryInput;
    AssetId primaryAssetId = primaryAsset.id;

    return primaryAsset.readAsString().then((String fileContents) {
      var filename = primaryAssetId.toString();
      var outputFileContents = fileContents;

      if (filename.endsWith('index.html')) {
        var index = outputFileContents.indexOf(
            '<script src="packages/browser/dart.js">');
        outputFileContents = outputFileContents.substring(0, index) +
            '<script src="packages/browser_controller' +
            '/perf_test_controller.js"></script>\n' +
            outputFileContents.substring(index);
        transform.addOutput(new Asset.fromString(new AssetId.parse(
            primaryAssetId.toString().replaceAll('.html', '-dart.html')),
            outputFileContents));
      }

      outputFileContents = _sourceJsNotDart(outputFileContents);
      // Rename the script to take the JavaScript source.
      transform.addOutput(new Asset.fromString(new AssetId.parse(
          _appendJs(primaryAssetId.toString())),
          outputFileContents));
    });
  }

  String _appendJs(String path) => path.replaceAll('.html', '-js.html');

  /// Given an html file that sources a Dart file, rewrite the html to instead
  /// source the compiled JavaScript file.
  String _sourceJsNotDart(String fileContents) {
    var dartScript = new RegExp(
        '<script type="application/dart" src="([\\w-]+)\.dart">');
    var match = dartScript.firstMatch(fileContents);
    return fileContents.replaceAll(dartScript, '<script type="text/javascript"'
        ' src="${match.group(1)+ ".dart.js"}" defer>');
  }
}
