/// Contains encoding, decoding and detection functionality for the
/// representation of program data at runtime.
///
/// This library is shared between the compiler and the runtime system.
library dart2js.runtime_data;


String encodeTypedefFieldDescriptor(int typeIndex) {
  return ":$typeIndex;";
}

bool isTypedefDescriptor(String descriptor) {
  return descriptor.startsWith(':');
}

int getTypeFromTypedef(String descriptor) {
  return int.parse(descriptor.substring(1, descriptor.length - 1));
}