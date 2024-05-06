import "dart:io";

String? toCheck;

// An assert that is not guaranteed to succeed is used in a non-conditionally
// const evaluated annotated member when asserts are turned on.
@pragma("vm:platform-const")
String get possibleAssert {
  assert(toCheck != null);
  return Platform.operatingSystem;
}

void main(List<String> args) {
  if (args.isNotEmpty) {
    toCheck = args.first;
  }
}
