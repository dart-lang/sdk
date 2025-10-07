import 'dart:convert' show jsonDecode;
import 'dart:io' show File;

import '../record_use_internal.dart' show RecordedUsages;

RecordedUsages? parseFromFile(Uri? recordedUsagesFile) {
  if (recordedUsagesFile == null) {
    return null;
  }
  final usagesContent = File.fromUri(recordedUsagesFile).readAsStringSync();
  final usagesJson = jsonDecode(usagesContent) as Map<String, dynamic>;
  return RecordedUsages.fromJson(usagesJson);
}
