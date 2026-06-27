import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:our_community_fund/data/datasources/auth_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/theme_local_data_source.dart';
import 'package:our_community_fund/data/datasources/user_remote_data_source.dart';
import 'package:our_community_fund/data/repositories/auth_repository_impl.dart';
import 'package:our_community_fund/domain/repositories/auth_repository.dart';
import 'package:our_community_fund/domain/use_cases/auth/login_use_case.dart';
import 'package:our_community_fund/domain/use_cases/auth/register_use_case.dart';
import 'package:our_community_fund/domain/use_cases/auth/reset_password_use_case.dart';
import 'package:our_community_fund/domain/use_cases/auth/sign_out_use_case.dart';
import 'package:our_community_fund/domain/use_cases/user/get_current_user_use_case.dart';
import 'package:our_community_fund/domain/use_cases/user/update_user_profile_use_case.dart';
import 'package:our_community_fund/domain/use_cases/user/watch_user_data_use_case.dart';
import 'package:our_community_fund/presentation/providers/theme_provider.dart';
import 'package:our_community_fund/services/auth_service.dart';

/// Wires data sources, repository, use cases, and legacy [AuthService] facade.
List<SingleChildWidget> buildAppProviders(SharedPreferences prefs) {
  return [
    Provider<AuthRemoteDataSource>(
      create: (_) => AuthRemoteDataSourceImpl(),
    ),
    Provider<UserRemoteDataSource>(
      create: (_) => UserRemoteDataSourceImpl(),
    ),
    Provider<ThemeLocalDataSource>(
      create: (_) => ThemeLocalDataSourceImpl(prefs),
    ),
    Provider<AuthRepository>(
      create: (context) => AuthRepositoryImpl(
        authRemote: context.read<AuthRemoteDataSource>(),
        userRemote: context.read<UserRemoteDataSource>(),
      ),
    ),
    Provider<LoginUseCase>(
      create: (context) => LoginUseCase(context.read<AuthRepository>()),
    ),
    Provider<RegisterUseCase>(
      create: (context) => RegisterUseCase(context.read<AuthRepository>()),
    ),
    Provider<ResetPasswordUseCase>(
      create: (context) =>
          ResetPasswordUseCase(context.read<AuthRepository>()),
    ),
    Provider<SignOutUseCase>(
      create: (context) => SignOutUseCase(context.read<AuthRepository>()),
    ),
    Provider<GetCurrentUserUseCase>(
      create: (context) =>
          GetCurrentUserUseCase(context.read<AuthRepository>()),
    ),
    Provider<UpdateUserProfileUseCase>(
      create: (context) =>
          UpdateUserProfileUseCase(context.read<AuthRepository>()),
    ),
    Provider<WatchUserDataUseCase>(
      create: (context) =>
          WatchUserDataUseCase(context.read<AuthRepository>()),
    ),
    Provider<AuthService>(
      create: (context) => AuthService(
        repository: context.read<AuthRepository>(),
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
