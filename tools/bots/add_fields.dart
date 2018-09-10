import 'dart:io';
import 'dart:convert';

/// This script reads the JSON object from the file at args[0] and
/// adds data to it from the environment.  Args[1] should be the timestamp
/// (as epoch seconds) of the current Git commit being tested.
void main(List<String> args) {
  Map<String, dynamic> map = jsonDecode(File(args[0]).readAsStringSync());
  final env = Platform.environment;
  map['commit_hash'] = env['BUILDBOT_REVISION'];
  map['commit_time'] = args[1];
  map['builder_name'] = env['SWARMING_BOT_ID'];
  map['bot_name'] = env['BUILDBOT_BUILDERNAME'];
  File(args[0]).writeAsStringSync(jsonEncode(map));
}
