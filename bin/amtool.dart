import 'package:tool/src/commands/build/build_command.dart';
import 'package:tool/src/commands/command.dart';
import 'package:tool/src/commands/create/create_command.dart';

void main(List<String> arguments) {
  Command command = CreateCommand();
  switch (arguments[0]) {
    case 'create':
      command = CreateCommand();
      break;
    case 'build':
      command = BuildCommand();
      break;
  }
  command.run(List.of(arguments.skip(1)));
}
