import 'dart:ui' as ui show TextDirection;
// ─────────────────────────────────────────────────────────────────────────────
// main.dart — App Entry Point
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/database/database_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/marriages/presentation/screens/marriage_list_screen.dart';
import 'features/agencies/presentation/screens/agency_list_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Platform-aware SQLite init ───────────────────────────────────────────
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ── Firebase init (with graceful fallback for offline/unconfigured) ───────
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // ── Local DB init ────────────────────────────────────────────────────────
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  // ── Notifications init (Android only) ────────────────────────────────────
  if (Platform.isAndroid) {
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint('NotificationService init notice: $e');
    }
    try {
      await BackgroundWorkerService.init();
    } catch (e) {
      debugPrint('BackgroundWorkerService init notice: $e');
    }
  }

  // ── Lock orientation on Android ──────────────────────────────────────────
  if (Platform.isAndroid) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('Orientation lock notice: $e');
    }
  }

  runApp(const ProviderScope(child: MarriageAgencyApp()));
}

class MarriageAgencyApp extends ConsumerWidget {
  const MarriageAgencyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'توثيق الزواجات والوكالات',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  static const List<Widget> _pages = [
    MarriageListScreen(),
    AgencyListScreen(),
  ];

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'إغلاق التطبيق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في الخروج من التطبيق؟',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (Platform.isAndroid || Platform.isIOS) {
                  SystemNavigator.pop();
                } else {
                  exit(0);
                }
              },
              child: Text(
                'تأكيد الخروج',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF131317) : Colors.white;
    final borderColor = isDark ? const Color(0xFF232329) : const Color(0xFFE5E7EB);
    final isMobilePlatform = Platform.isAndroid || Platform.isIOS;

    if (isMobilePlatform) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: borderColor, width: 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: isDark ? const Color(0xFF262630) : const Color(0xFFE5E7EB),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.diamond_outlined, size: 22),
                    selectedIcon: const Icon(Icons.diamond_rounded, color: Color(0xFFF59E0B), size: 24),
                    label: 'الزواجات',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.description_outlined, size: 22),
                    selectedIcon: const Icon(Icons.description_rounded, color: AppTheme.accentBlue, size: 24),
                    label: 'الوكالات',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Desktop / Tablet layout with Collapsible Sidebar ────────────────────
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            // ── Collapsible Sidebar ─────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: _isSidebarExpanded ? 240 : 72,
              decoration: BoxDecoration(
                color: navBg,
                border: Border(
                  left: BorderSide(color: borderColor, width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: ClipRect(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header & Toggle
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isSidebarExpanded ? 10 : 4,
                          vertical: 12,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isSidebarExpanded
                              ? Row(
                                  key: const ValueKey('expanded_header'),
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF262630)
                                                  : const Color(0xFF111111),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.balance_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              'المكتب الشرعي',
                                              style: GoogleFonts.cairo(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              overflow: TextOverflow.fade,
                                              softWrap: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'طي القائمة الجانبية',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      icon: const Icon(
                                        Icons.menu_open_rounded,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isSidebarExpanded = false;
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : Center(
                                  key: const ValueKey('collapsed_header'),
                                  child: IconButton(
                                    tooltip: 'توسيع القائمة الجانبية',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    icon: const Icon(
                                      Icons.menu_rounded,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSidebarExpanded = !_isSidebarExpanded;
                                      });
                                    },
                                  ),
                                ),
                        ),
                      ),
                      const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Navigation Items
                    _SidebarNavItem(
                      icon: Icons.diamond_outlined,
                      selectedIcon: Icons.diamond_rounded,
                      label: 'سجلات الزواج',
                      isSelected: _selectedIndex == 0,
                      isExpanded: _isSidebarExpanded,
                      activeColor: const Color(0xFFF59E0B),
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    const SizedBox(height: 6),
                    _SidebarNavItem(
                      icon: Icons.description_outlined,
                      selectedIcon: Icons.description_rounded,
                      label: 'الوكالات الشرعية',
                      isSelected: _selectedIndex == 1,
                      isExpanded: _isSidebarExpanded,
                      activeColor: AppTheme.accentBlue,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),

                    const Spacer(),

                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Theme Mode Switch Item
                    _SidebarActionItem(
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                      isExpanded: _isSidebarExpanded,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).state =
                            isDark ? ThemeMode.light : ThemeMode.dark;
                      },
                    ),
                    const SizedBox(height: 4),

                    // Exit App Button
                    _SidebarActionItem(
                      icon: Icons.logout_rounded,
                      label: 'إغلاق التطبيق',
                      isExpanded: _isSidebarExpanded,
                      iconColor: const Color(0xFFEF4444),
                      textColor: const Color(0xFFEF4444),
                      onTap: () => _confirmExit(context),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar Navigation Item ───────────────────────────────────────────────────

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    this.activeColor,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF22222B) : const Color(0xFFF3F4F6);
    final effectiveColor = isSelected
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Tooltip(
        message: !isExpanded ? label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 14 : 0,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? const Color(0xFF32323D)
                          : const Color(0xFFE5E7EB),
                      width: 1.2,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: effectiveColor,
                  size: 22,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF111827))
                            : effectiveColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sidebar Action Item ───────────────────────────────────────────────────────

class _SidebarActionItem extends StatelessWidget {
  const _SidebarActionItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Tooltip(
        message: !isExpanded ? label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 14 : 0,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment:
                  isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? defaultColor,
                  size: 20,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? defaultColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
