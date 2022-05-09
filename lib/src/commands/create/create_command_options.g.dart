// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_command_options.dart';

// **************************************************************************
// CliGenerator
// **************************************************************************

CreateCommandOptions _$parseCreateCommandOptionsResult(ArgResults result) =>
    CreateCommandOptions(
      result['overwrite'] as bool,
      result['description'] as String,
      result['org'] as String,
      result['project-name'] as String?,
      result['platforms'] as List<String>,
      result['verbose'] as bool?,
      result['format'] as String?,
      result['help'] as bool,
    );

ArgParser _$populateCreateCommandOptionsParser(ArgParser parser) => parser
  ..addFlag(
    'overwrite',
    help: 'When performing operations, overwrite existing files.',
  )
  ..addOption(
    'description',
    help:
        'The description to use for your new AgoraMarketplace project. This string ends up in the pubspec.yaml file.',
    defaultsTo: 'A new AgoraMarketplace project.',
  )
  ..addOption(
    'org',
    help:
        'The organization responsible for your new AgoraMarketplace project, in reverse domain name notation. This string isused in Java package names and as prefix in the iOS bundle identifier.',
    defaultsTo: 'com.example',
  )
  ..addOption(
    'project-name',
    help:
        'The project name for this new AgoraMarketplace project. This must be a valid dart package name.',
  )
  ..addMultiOption(
    'platforms',
    help:
        'The platforms supported by this project. Platform folders (e.g. android/) will be generated in the targetproject. This argument only works when "--template" is set to app or plugin. When adding platforms to aplugin project, the pubspec.yaml will be updated with the requested platform. Adding desktop platformsrequires the corresponding desktop config setting to be enabled.',
    defaultsTo: ['android', 'ios'],
    allowed: ['ios', 'android', 'windows', 'linux', 'macos', 'web'],
  )
  ..addFlag(
    'verbose',
    abbr: 'v',
    help: 'Print additional event types',
    defaultsTo: false,
  )
  ..addOption(
    'format',
    abbr: 'f',
    help:
        'The format to display. Defaults to "Friday, October 18 at 13:55 PM: <User> opened <URL>"',
    allowed: ['default', 'markdown'],
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Prints usage information.',
    negatable: false,
  );

final _$parserForCreateCommandOptions =
    _$populateCreateCommandOptionsParser(ArgParser());

CreateCommandOptions parseCreateCommandOptions(List<String> args) {
  final result = _$parserForCreateCommandOptions.parse(args);
  return _$parseCreateCommandOptionsResult(result);
}
