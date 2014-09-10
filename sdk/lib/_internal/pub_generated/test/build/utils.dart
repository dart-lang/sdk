import 'dart:convert';
import '../descriptor.dart' as d;
import '../test_pub.dart';
void serveBrowserPackage() {
  serve([d.dir('api', [d.dir('packages', [d.file('browser', JSON.encode({
          'versions': [packageVersionApiMap(packageMap('browser', '1.0.0'))]
        })),
            d.dir(
                'browser',
                [
                    d.dir(
                        'versions',
                        [
                            d.file(
                                '1.0.0',
                                JSON.encode(
                                    packageVersionApiMap(packageMap('browser', '1.0.0'), full: true)))])])])]),
            d.dir(
                'packages',
                [
                    d.dir(
                        'browser',
                        [
                            d.dir(
                                'versions',
                                [
                                    d.tar(
                                        '1.0.0.tar.gz',
                                        [
                                            d.file('pubspec.yaml', yaml(packageMap("browser", "1.0.0"))),
                                            d.dir(
                                                'lib',
                                                [
                                                    d.file('dart.js', 'contents of dart.js'),
                                                    d.file('interop.js', 'contents of interop.js')])])])])])]);
}
