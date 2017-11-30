import 'dart:io';

enum Platform { linux, win, mac }
enum BuildType { compile, existing, none }

void main(List<String> args) {
  print("This tool will help to generate a custom try build and run, that one "
      "can use for testing on different platforms.");
  print("");

  Platform builderPlatform = Platform.values[getIntegerStepInput(
          "Choose platform: (1) Linux, (2) Windows or (3) Mac") -
      1];

  BuildType buildType =
      BuildType.values[getIntegerStepInput("Do you want to: \n"
              "\t(1) Make a new build on the platform.\n"
              "\t(2) Use an existing build by using a file-set hash.\n"
              "\t(3) No build.") -
          1];

  String buildArgs = null;
  if (buildType == BuildType.compile) {
    buildArgs = getStepInput("Give the arguments to build.py, seperate by "
        "' '");
  } else if (buildType == BuildType.existing) {
    buildArgs = getStepInput("Input the fileset hash");
  }

  var testCommands = <TestCommand>[];
  var testCommandString = getStepInput("Write a command to execute. Use ' ' to "
      "separate arguments. If you only wish to build, just press <Enter>");
  while (testCommandString.isNotEmpty) {
    var testCommandRepeat = getIntegerStepInput("How many times would you like "
        "the command '${testCommandString} to be invoked?");
    testCommands.add(new TestCommand(testCommandString, testCommandRepeat));
    testCommandString = getStepInput("Write an additional command to execute. "
        "Use ' ' to separate arguments. If no additional commands should be run"
        ", press <Enter>");
  }

  print("Run the following command in a branch with a CL that you would like to"
      " test:");
  int commandIndex = 1;
  var allTestCommands = testCommands
      .expand((testCommand) => testCommand.toTryCommand(commandIndex++));
  print("git try cl -b ${getBuilderName(builderPlatform)} "
      "${getBuildProperties(buildType, buildArgs)}"
      "${allTestCommands.join(' ')}");
}

String getBuilderName(Platform builderPlatform) {
  switch (builderPlatform) {
    case Platform.linux:
      return "dart-linux-test-try";
    case Platform.win:
      return "dart-win-test-try";
    case Platform.mac:
      return "dart-mac-test-try";
  }
  return "dart-linux-test-try";
}

String getBuildProperties(BuildType buildType, String buildArgs) {
  switch (buildType) {
    case BuildType.compile:
      return "-p try_build_args='\"$buildArgs\"' ";
    case BuildType.existing:
      return "-p parent_fileset='\"$buildArgs\"' ";
    case BuildType.none:
      return "";
  }
  return "";
}

class TestCommand {
  final String command;
  final int repeat;

  TestCommand(this.command, this.repeat);

  List<String> toTryCommand(int index) {
    String commandSuffix = index.toString().padLeft(2, "0");
    return [
      "-p try_cmd_$commandSuffix='\"$command\"'",
      "-p try_cmd_${commandSuffix}_repeat='$repeat'"
    ];
  }
}

String getStepInput(String information) {
  print("$information:");
  var input = stdin.readLineSync();
  print("");
  return input;
}

int getIntegerStepInput(String information) {
  print("$information:");
  var input = stdin.readLineSync();
  var value = int.parse(input, onError: (source) => null);
  if (value == null) {
    print("Input could not be parsed as an integer.");
    return getIntegerStepInput(information);
  }
  print("");
  return value;
}
