import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:tool/src/commands/command.dart';

part 'build_command_options.g.dart';

@CliOptions()
class BuildCommandOptions extends CommandOptions {
  @CliOption(
    abbr: 't',
    allowed: ['aar', 'apk', 'ios', 'ios-framework', 'ipa'],
    allowedHelp: {
      'aar': 'Build a repository containing an AAR and a POM file.',
      'apk': 'Build an Android APK file from your app.',
      'ios': 'Build an iOS application bundle (Mac OS X host only).',
      'ios-framework':
          'Produces .xcframeworks for a Flutter project and its plugins for integration into existing, plain Xcode projects.',
      'ipa': 'Build an iOS archive bundle (Mac OS X host only).',
    },
  )
  final String? target;

  @CliOption(abbr: 'v', defaultsTo: false, help: 'Print additional event types')
  final bool? verbose;

  @CliOption(
      abbr: 'f',
      help: 'The format to display. Defaults to '
          '"Friday, October 18 at 13:55 PM: <User> opened <URL>"',
      allowed: ['default', 'markdown'])
  final String? format;

  @CliOption(abbr: 'h', negatable: false, help: 'Prints usage information.')
  final bool help;

  BuildCommandOptions(
    this.target,
    this.verbose,
    this.format,
    this.help,
  );

  @override
  ArgParser getArgParser() {
    return _$parserForBuildCommandOptions;
  }
}
