import 'vm_service_coverage.dart' as helper;

main(List<String> args) async {
  CoverageHelper coverageHelper = new CoverageHelper();

  List<String> allArgs = <String>[];
  allArgs.addAll([
    "--disable-dart-dev",
    "--enable-asserts",
    "--pause_isolates_on_exit",
  ]);
  allArgs.addAll(args);

  coverageHelper.start(allArgs);
}

class CoverageHelper extends helper.CoverageHelper {
  CoverageHelper() : super(printHits: false);

  bool includeCoverageFor(Uri uri) {
    if (uri.scheme != "package") return false;
    if (uri.path.startsWith("front_end/src/fasta/kernel/constant_")) {
      return true;
    }
    return false;
  }
}
