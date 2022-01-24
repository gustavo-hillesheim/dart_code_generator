import 'package:code_generator/code_generator.dart';
import 'package:equatable/equatable.dart';

/// Represents a step of the generation process.
abstract class GenerationStep extends Equatable {
  String get message;
}

class AnalyzingPackageStep extends GenerationStep {
  @override
  String get message => 'Analyzing package source code...';

  @override
  List<Object?> get props => [message];
}

class RunningGeneratorsStep extends GenerationStep {
  @override
  String get message => 'Running generators...';

  @override
  List<Object?> get props => [message];
}

class RunningGeneratorStep extends GenerationStep {
  final String generatorDescription;

  RunningGeneratorStep(this.generatorDescription);

  @override
  String get message => 'Running $generatorDescription...';

  @override
  List<Object?> get props => [message];
}

class CodeGenerationResult extends GenerationStep {
  final List<GeneratedFile> files;

  CodeGenerationResult(this.files);

  @override
  String get message =>
      'Finished code generation with ${files.length} generated files';

  @override
  List<Object?> get props => [files, message];
}
