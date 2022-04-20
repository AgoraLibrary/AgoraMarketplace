import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/cmd_run.dart' as cmd;
import 'package:tool/src/commands/build/build_command_options.dart';
import 'package:tool/src/commands/command.dart';
import 'package:tool/src/globals.dart' as globals;

class BuildCommand extends Command<BuildCommandOptions> {
  @override
  ArgResults parse(List<String> args) {
    commandOptions = parseBuildCommandOptions(args);

    if (commandOptions.help) {
      printUsage();
      exit(0);
    }

    if (commandOptions.target?.isEmpty ?? true) {
      printUsage();
      exit(0);
    }

    return commandOptions.getArgParser().parse(args);
  }

  @override
  String get description => '';

  @override
  String get name => 'build';

  @override
  Future<void> runCommand() async {
    print(globals.fs.currentDirectory);

    String platform = '';
    switch (commandOptions.target) {
      case 'aar':
        platform = 'android';
        break;
      case 'apk':
        platform = 'android';
        break;
      case 'framework':
        platform = 'ios';
        break;
      case 'app':
        platform = 'ios';
        break;
      case 'ipa':
        platform = 'ios';
        break;
    }

    var executable = globals.fs.path.join('build', platform, 'scripts',
        'build-${commandOptions.target}.${globals.platform.isWindows ? 'bat' : 'sh'}');
    await cmd.runExecutableArguments('sh', [executable], verbose: true);
  }
}
