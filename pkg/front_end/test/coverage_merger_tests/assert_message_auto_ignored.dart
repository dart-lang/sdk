void main(List<String> args) {
  assert(
    args.isEmpty || args.isNotEmpty,
    "$args was neither empty nor not empty.",
  );
  print("The message above will never execute and is never covered.");
}
