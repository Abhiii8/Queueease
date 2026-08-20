import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/main/main_layout.dart';
import '../features/organization/home_screen.dart';
import '../features/organization/organization_detail_screen.dart';
import '../features/organization/create_organization_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/organization/manage_businesses_screen.dart';
import '../features/organization/queue_admin_dashboard_screen.dart';
import '../features/organization/qr_scanner_screen.dart';
import '../features/queue/queue_booking_screen.dart';
import '../features/queue/live_tracking_screen.dart';
import '../features/queue/booking_history_screen.dart';
import '../features/organization/counter_agent_screen.dart';
import '../features/analytics/analytics_dashboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainLayoutScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingHistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/org/:id',
            builder: (context, state) => OrganizationDetailScreen(
              orgId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/manage_businesses',
            builder: (context, state) => const ManageBusinessesScreen(),
          ),
          GoRoute(
            path: '/create_org',
            builder: (context, state) => const CreateOrganizationScreen(),
          ),
          GoRoute(
            path: '/admin_queue/:id',
            builder: (context, state) => QueueAdminDashboardScreen(
              orgId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/scan_qr/:id',
            builder: (context, state) => QRScannerScreen(
              orgId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/queue/:id',
            builder: (context, state) => QueueBookingScreen(
              serviceId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/counter/:serviceId',
            builder: (context, state) => CounterAgentScreen(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: '/analytics/:id',
            builder: (context, state) => AnalyticsDashboardScreen(
              orgId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/tracking',
            builder: (context, state) => const LiveTrackingScreen(),
          ),
        ],
      ),
    ],
  );
}

// Temporary placeholder for unbuilt screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}
