import 'package:dtd/dtd.dart';

void main() {
  // ignore: unused_local_variable
  final dtdConnection = DartToolingDaemon.connect(
    Uri.parse(
      'wss://127.0.0.1:51906',
    ),
  );
}
