import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:our_community_fund/data/datasources/auth_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/notification_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/payment_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/reports_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/theme_local_data_source.dart';
import 'package:our_community_fund/data/datasources/user_remote_data_source.dart';
import 'package:our_community_fund/data/repositories/auth_repository_impl.dart';
import 'package:our_community_fund/data/repositories/member_repository_impl.dart';
import 'package:our_community_fund/data/repositories/notification_repository_impl.dart';
import 'package:our_community_fund/data/repositories/payment_repository_impl.dart';
import 'package:our_community_fund/data/repositories/reports_repository_impl.dart';
import 'package:our_community_fund/domain/repositories/auth_repository.dart';
import 'package:our_community_fund/domain/repositories/member_repository.dart';
import 'package:our_community_fund/domain/repositories/notification_repository.dart';
import 'package:our_community_fund/domain/repositories/payment_repository.dart';
import 'package:our_community_fund/domain/repositories/reports_repository.dart';
import 'package:our_community_fund/domain/use_cases/auth/login_use_case.dart';
import 'package:our_community_fund/domain/use_cases/auth/register_use_case.dart';
import 'package:our_community_fund/domain/use_cases/auth/reset_password_use_case.dart';
import 'package:our_community_fund/domain/use_cases/auth/sign_out_use_case.dart';
import 'package:our_community_fund/domain/use_cases/member/watch_non_admin_members_use_case.dart';
import 'package:our_community_fund/domain/use_cases/notification/notification_use_cases.dart';
import 'package:our_community_fund/domain/use_cases/payment/payment_use_cases.dart';
import 'package:our_community_fund/domain/use_cases/reports/reports_use_cases.dart';
import 'package:our_community_fund/domain/use_cases/user/get_current_user_use_case.dart';
import 'package:our_community_fund/domain/use_cases/user/update_user_profile_use_case.dart';
import 'package:our_community_fund/domain/use_cases/user/watch_user_data_use_case.dart';
import 'package:our_community_fund/presentation/providers/theme_provider.dart';
import 'package:our_community_fund/services/auth_service.dart';
import 'package:our_community_fund/services/notification_service.dart';
import 'package:our_community_fund/services/payment_service.dart';
import 'package:our_community_fund/services/reports_service.dart';

/// Wires data sources, repositories, use cases, and legacy service facades.
List<SingleChildWidget> buildAppProviders(SharedPreferences prefs) {
  return [
    Provider<SharedPreferences>.value(value: prefs),
    Provider<AuthRemoteDataSource>(create: (_) => AuthRemoteDataSourceImpl()),
    Provider<UserRemoteDataSource>(create: (_) => UserRemoteDataSourceImpl()),
    Provider<PaymentRemoteDataSource>(
      create: (_) => PaymentRemoteDataSourceImpl(),
    ),
    Provider<ReportsRemoteDataSource>(
      create: (_) => ReportsRemoteDataSourceImpl(),
    ),
    Provider<NotificationRemoteDataSource>(
      create: (_) => NotificationRemoteDataSourceImpl(),
    ),
    Provider<ThemeLocalDataSource>(
      create: (_) => ThemeLocalDataSourceImpl(prefs),
    ),
    Provider<NotificationService>(
      create: (context) => NotificationService(context.read<SharedPreferences>()),
    ),
    Provider<AuthRepository>(
      create: (context) => AuthRepositoryImpl(
        authRemote: context.read<AuthRemoteDataSource>(),
        userRemote: context.read<UserRemoteDataSource>(),
      ),
    ),
    Provider<MemberRepository>(
      create: (context) => MemberRepositoryImpl(
        userRemote: context.read<UserRemoteDataSource>(),
      ),
    ),
    Provider<PaymentRepository>(
      create: (context) => PaymentRepositoryImpl(
        remote: context.read<PaymentRemoteDataSource>(),
        notificationService: context.read<NotificationService>(),
      ),
    ),
    Provider<ReportsRepository>(
      create: (context) => ReportsRepositoryImpl(
        remote: context.read<ReportsRemoteDataSource>(),
      ),
    ),
    Provider<NotificationRepository>(
      create: (context) => NotificationRepositoryImpl(
        remote: context.read<NotificationRemoteDataSource>(),
      ),
    ),
    // Auth use cases
    Provider(create: (c) => LoginUseCase(c.read<AuthRepository>())),
    Provider(create: (c) => RegisterUseCase(c.read<AuthRepository>())),
    Provider(create: (c) => ResetPasswordUseCase(c.read<AuthRepository>())),
    Provider(create: (c) => SignOutUseCase(c.read<AuthRepository>())),
    Provider(create: (c) => GetCurrentUserUseCase(c.read<AuthRepository>())),
    Provider(create: (c) => UpdateUserProfileUseCase(c.read<AuthRepository>())),
    Provider(create: (c) => WatchUserDataUseCase(c.read<AuthRepository>())),
    // Payment use cases
    Provider(create: (c) => RecordPaymentUseCase(c.read<PaymentRepository>())),
    Provider(
      create: (c) => RecordExtraContributionUseCase(c.read<PaymentRepository>()),
    ),
    Provider(create: (c) => WatchUserPaymentsUseCase(c.read<PaymentRepository>())),
    Provider(
      create: (c) => WatchRecentPaymentsUseCase(c.read<PaymentRepository>()),
    ),
    Provider(create: (c) => WatchMonthlyStatsUseCase(c.read<PaymentRepository>())),
    Provider(
      create: (c) => WatchPaymentRequestsUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => WatchUserPaymentRequestsUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) =>
          WatchPendingPaymentRequestCountUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => SubmitPaymentRequestUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => VerifyPaymentRequestUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => RejectPaymentRequestUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => GetPaymentSettingsUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => SavePaymentSettingsUseCase(c.read<PaymentRepository>()),
    ),
    Provider(
      create: (c) => DeleteAllCollectionsUseCase(c.read<PaymentRepository>()),
    ),
    // Reports use cases
    Provider(create: (c) => GetPaymentStatsUseCase(c.read<ReportsRepository>())),
    Provider(
      create: (c) => GetUserComplianceStatsUseCase(c.read<ReportsRepository>()),
    ),
    Provider(
      create: (c) => GetUserPaymentSummaryUseCase(c.read<ReportsRepository>()),
    ),
    Provider(create: (c) => ExportPaymentsCsvUseCase(c.read<ReportsRepository>())),
    Provider(
      create: (c) => ExportUserSummaryCsvUseCase(c.read<ReportsRepository>()),
    ),
    // Member use cases
    Provider(
      create: (c) => WatchNonAdminMembersUseCase(c.read<MemberRepository>()),
    ),
    // Notification use cases
    Provider(
      create: (c) => WatchNotificationsUseCase(c.read<NotificationRepository>()),
    ),
    Provider(
      create: (c) => MarkNotificationReadUseCase(c.read<NotificationRepository>()),
    ),
    Provider(
      create: (c) =>
          MarkAllNotificationsReadUseCase(c.read<NotificationRepository>()),
    ),
    // Legacy facades (delegate to repositories above)
    Provider<AuthService>(
      create: (context) => AuthService(
        repository: context.read<AuthRepository>(),
      ),
    ),
    Provider<PaymentService>(
      create: (context) => PaymentService(
        repository: context.read<PaymentRepository>(),
      ),
    ),
    Provider<ReportsService>(
      create: (context) => ReportsService(
        repository: context.read<ReportsRepository>(),
      ),
    ),
    StreamProvider<User?>(
      create: (context) => context.read<AuthService>().authStateChanges,
      initialData: null,
    ),
    ChangeNotifierProvider(
      create: (context) =>
          ThemeProvider(context.read<ThemeLocalDataSource>()),
    ),
  ];
}
