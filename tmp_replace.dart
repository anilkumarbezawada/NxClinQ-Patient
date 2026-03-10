import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;
    
    if (content.contains('AppColors.tealDark')) {
      content = content.replaceAll('AppColors.tealDark', 'AppColors.success');
      changed = true;
    }
    if (content.contains('AppColors.teal')) {
      content = content.replaceAll('AppColors.teal', 'AppColors.success');
      changed = true;
    }
    if (content.contains('AppColors.gold')) {
      content = content.replaceAll('AppColors.gold', 'AppColors.warning');
      changed = true;
    }
    if (content.contains('AppColors.headerGradient')) {
      content = content.replaceAll('AppColors.headerGradient', 'AppColors.primaryGradient');
      changed = true;
    }
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
