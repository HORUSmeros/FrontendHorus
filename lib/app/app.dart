import 'package:flutter/material.dart';

import '../core/repositories/api_horus_repository.dart';
import '../core/repositories/horus_repository.dart';
import 'router/home_shell.dart';
import 'theme/app_theme.dart';

class HorusApp extends StatelessWidget {
  const HorusApp({super.key, HorusRepository? repository})
      : _repository = repository;

  final HorusRepository? _repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Supervisión',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HorusRepositoryScope(
        repository: _repository ?? ApiHorusRepository(),
        child: const HorusHomeShell(),
      ),
    );
  }
}
