import 'dart:io';
binStubName(String name) {
  if (Platform.operatingSystem == "windows") return "$name.bat";
  return name;
}
