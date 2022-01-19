import 'package:analyzer/dart/ast/ast.dart';
import 'package:code_generator/code_generator.dart';

import 'generator_result.dart';

/// Generates files for a given [CompilationUnitMember].
abstract class Generator<T extends CompilationUnitMember> {
  /// Verifies if should generate files for a given [CompilationUnitMember].
  ///
  /// [member] is a top-level declaration in a library, and [path] is the library's absolute path.
  bool shouldGenerateFor(CompilationUnitMember member, String path) =>
      member is T;

  /// Generates files for a given [CompilationUnitMember].
  ///
  /// [member] is any [CompilationUnitMember] that passes [shouldGenerateFor], and [path] is the absolute path to the library where this member is declared.
  GeneratorResult generate(T member, String path);
}

/// Generates files for [ClassDeclaration]s found in the package.
abstract class GeneratorForClass extends Generator<ClassDeclaration> {}

/// Generates files for [MixinDeclaration]s found in the package.
abstract class GeneratorForMixin extends Generator<MixinDeclaration> {}

/// Generates files for [FunctionDeclaration]s found in the package.
abstract class GeneratorForFunction extends Generator<FunctionDeclaration> {}

/// Generates files for [ExtensionDeclaration]s found in the package.
abstract class GeneratorForExtension extends Generator<ExtensionDeclaration> {}

/// Generates files for [EnumDeclaration]s found in the package.
abstract class GeneratorForEnum extends Generator<EnumDeclaration> {}

/// Generates files for [TypeAlias]s found in the package.
abstract class GeneratorForType extends Generator<TypeAlias> {}

/// Generates files for [TopLevelVariableDeclaration]s found in the package.
abstract class GeneratorForTopLevelVariable
    extends Generator<TopLevelVariableDeclaration> {}

/// Returns if a given [Annotation] matches a given criteria or criterias.
typedef AnnotationMatcher = bool Function(Annotation annotation);

/// Returns an [AnnotationMatcher] that matches the annotation name with a RegExp.
AnnotationMatcher nameAnnotationMatcher(RegExp nameMatcher) {
  return (annotation) => nameMatcher.hasMatch(annotation.name.name);
}

/// Generates files for [CompilationUnitMember]s found in the package that are annotated with a matching annotation.
abstract class GeneratorForAnnotatedElements<T extends CompilationUnitMember>
    extends Generator<T> {
  /// Annotation matcher that will be used in [shouldGenerateFor] to determine for which [CompilationUnitMember]s this generator should run.
  AnnotationMatcher get annotationMatcher;

  @override
  bool shouldGenerateFor(CompilationUnitMember member, String path) {
    return member is T && member.metadata.any(annotationMatcher);
  }
}
