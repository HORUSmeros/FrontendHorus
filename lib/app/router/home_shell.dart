import 'package:flutter/material.dart';

import '../../features/collectors/collectors_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/routes/routes_screen.dart';
import '../theme/app_colors.dart';

enum HomeSection { dashboard, routes, collectors }

class HorusHomeShell extends StatefulWidget {
  const HorusHomeShell({super.key});

  @override
  State<HorusHomeShell> createState() => _HorusHomeShellState();
}

class _HorusHomeShellState extends State<HorusHomeShell> {
  HomeSection _currentSection = HomeSection.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _NavigationPane(
              current: _currentSection,
              onChanged: (value) => setState(() => _currentSection = value),
            ),
            const VerticalDivider(width: 1, thickness: 0.5),
            Expanded(
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: switch (_currentSection) {
                        HomeSection.dashboard => const DashboardScreen(),
                        HomeSection.routes => const RoutesScreen(),
                        HomeSection.collectors => const CollectorsScreen(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationPane extends StatelessWidget {
  const _NavigationPane({
    required this.current,
    required this.onChanged,
  });

  final HomeSection current;
  final ValueChanged<HomeSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: MediaQuery.of(context).size.width > 1200,
      minWidth: 110,
      minExtendedWidth: 240,
      selectedIndex: current.index,
      groupAlignment: -0.8,
      indicatorShape: const StadiumBorder(),
      backgroundColor: AppColors.primaryDark,
      selectedIconTheme: const IconThemeData(color: Colors.white, size: 34),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
      unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 30),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
      onDestinationSelected: (index) => onChanged(HomeSection.values[index]),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0),
        child: _TrackMeLogo(showWordmark: true),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined, size: 34),
          selectedIcon: Icon(Icons.dashboard, size: 36),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.route_outlined, size: 34),
          selectedIcon: Icon(Icons.route, size: 36),
          label: Text('Rutas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.groups_2_outlined, size: 34),
          selectedIcon: Icon(Icons.groups_2, size: 36),
          label: Text('Recolectores'),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sistema de Supervisión',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('Swisscontact + Emacruz', style: textTheme.bodyMedium),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 180,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                hintText: '15/11/2025',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 12,
            children: const [
              _MacrorutaChip(label: 'Verde', color: Color(0xFF2DA754)),
              _MacrorutaChip(label: 'Roja', color: Color(0xFFE74C3C)),
              _MacrorutaChip(label: 'Naranja', color: Color(0xFFF39C12)),
              _MacrorutaChip(label: 'Lila', color: Color(0xFFB678F1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackMeLogo extends StatelessWidget {
  const _TrackMeLogo({this.size = 80, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final wordmarkStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: size,
                color: Colors.white.withValues(alpha: .25),
              ),
              Icon(
                Icons.location_on_rounded,
                size: size,
                color: AppColors.primary,
              ),
              Icon(
                Icons.location_on_rounded,
                size: size - 16,
                color: Colors.white,
              ),
              _WatchBadge(size: size * 0.42),
            ],
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          Text('TrackMe', style: wordmarkStyle),
        ],
      ],
    );
  }
}

class _WatchBadge extends StatelessWidget {
  const _WatchBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final strapWidth = size * 0.35;
    final strapHeight = size * 0.18;
    return SizedBox(
      width: size,
      height: size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: (size - strapHeight) / 2 - strapHeight,
            child: Container(
              width: strapWidth,
              height: strapHeight,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: (size - strapHeight) / 2 - strapHeight,
            child: Container(
              width: strapWidth,
              height: strapHeight,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Icon(Icons.check_rounded, color: AppColors.primary, size: size * 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrorutaChip extends StatelessWidget {
  const _MacrorutaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
