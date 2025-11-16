import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horusfront/app/app.dart';
import 'package:horusfront/core/repositories/mock_horus_repository.dart';

void main() {
  group('HorusApp smoke test', () {
    testWidgets('renders root widget', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        HorusApp(repository: MockHorusRepository()),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
