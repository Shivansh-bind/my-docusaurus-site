import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/library/presentation/screens/items_screen.dart';
import '../../features/library/presentation/screens/sections_screen.dart';
import '../../features/library/presentation/screens/semesters_screen.dart';
import '../../features/library/presentation/screens/subjects_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'semesters',
        builder: (context, state) => const SemestersScreen(),
      ),
      GoRoute(
        path: '/semester/:semesterName',
        name: 'subjects',
        builder: (context, state) {
          final semesterName = state.pathParameters['semesterName']!;
          return SubjectsScreen(semesterName: semesterName);
        },
      ),
      GoRoute(
        path: '/semester/:semesterName/subject/:subjectName',
        name: 'sections',
        builder: (context, state) {
          final semesterName = state.pathParameters['semesterName']!;
          final subjectName = state.pathParameters['subjectName']!;
          return SectionsScreen(
            semesterName: semesterName,
            subjectName: subjectName,
          );
        },
      ),
      GoRoute(
        path:
            '/semester/:semesterName/subject/:subjectName/section/:sectionName',
        name: 'items',
        builder: (context, state) {
          final semesterName = state.pathParameters['semesterName']!;
          final subjectName = state.pathParameters['subjectName']!;
          final sectionName = state.pathParameters['sectionName']!;
          return ItemsScreen(
            semesterName: semesterName,
            subjectName: subjectName,
            sectionName: sectionName,
          );
        },
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) {
          return const ReaderScreen();
        },
      ),
    ],
  );
});
