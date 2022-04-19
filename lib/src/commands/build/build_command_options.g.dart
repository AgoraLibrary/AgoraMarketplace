// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_command_options.dart';

// **************************************************************************
// CliGenerator
// **************************************************************************

BuildCommandOptions _$parseBuildCommandOptionsResult(ArgResults result) =>
    BuildCommandOptions(
      result['target'] as String?,
      result['verbose'] as bool?,
      result['format'] as String?,
      result['help'] as bool,
    );

ArgParser _$populateBuildCommandOptionsParser(ArgParser parser) => parser
  ..addOption(
    'target',
    abbr: 't',
    allowed: ['aar', 'apk', 'ios', 'ios-framework', 'ipa'],
    allowedHelp: <String, String>{
      'aar': 'Build a repository containing an AAR and a POM file.',
      'apk': 'Build an Android APK file from your app.',
      'ios': 'Build an iOS application bundle (Mac OS X host only).',
      'ios-framework':
          'Produces .xcframeworks for a Flutter project and its plugins for integration into existing, plain Xcode projects.',
      'ipa': 'Build an iOS archive bundle (Mac OS X host only).'
    },
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

final _$parserForBuildCommandOptions =
    _$populateBuildCommandOptionsParser(ArgParser());

BuildCommandOptions parseBuildCommandOptions(List<String> args) {
  final result = _$parserForBuildCommandOptions.parse(args);
  return _$parseBuildCommandOptionsResult(result);
}
