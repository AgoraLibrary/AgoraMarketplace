import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:tool/src/commands/command.dart';

part 'create_command_options.g.dart';

const List<String> _kAvailablePlatforms = <String>[
  'ios',
  'android',
  'windows',
  'linux',
  'macos',
  'web',
];

/// The command line options for this app
@CliOptions()
class CreateCommandOptions extends CommandOptions {
  @CliOption(
    defaultsTo: false,
    help: 'When performing operations, overwrite existing files.',
  )
  final bool overwrite;

  @CliOption(
    defaultsTo: 'A new AgoraMarketplace project.',
    help:
        'The description to use for your new AgoraMarketplace project. This string ends up in the pubspec.yaml file.',
  )
  final String description;

  @CliOption(
    name: 'org',
    defaultsTo: 'com.example',
    help:
        'The organization responsible for your new AgoraMarketplace project, in reverse domain name notation. This string is'
        'used in Java package names and as prefix in the iOS bundle identifier.',
  )
  final String organization;

  @CliOption(
    name: 'project-name',
    help:
        'The project name for this new AgoraMarketplace project. This must be a valid dart package name.',
  )
  final String? projectName;

  @CliOption(
    help:
        'The platforms supported by this project. Platform folders (e.g. android/) will be generated in the target'
        'project. This argument only works when "--template" is set to app or plugin. When adding platforms to a'
        'plugin project, the pubspec.yaml will be updated with the requested platform. Adding desktop platforms'
        'requires the corresponding desktop config setting to be enabled.',
    allowed: _kAvailablePlatforms,
    defaultsTo: ["android", "ios"],
  )
  final List<String>? platforms;

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

  CreateCommandOptions(
    this.overwrite,
    this.description,
    this.organization,
    this.projectName,
    this.platforms,
    this.verbose,
    this.format,
    this.help,
  );

  @override
  ArgParser getArgParser() {
    return _$parserForCreateCommandOptions;
  }
}
