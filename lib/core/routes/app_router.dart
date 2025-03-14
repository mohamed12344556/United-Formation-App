import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:united_formation_app/features/settings/ui/cubits/library/library_cubit.dart';
import 'package:united_formation_app/features/settings/ui/cubits/orders/orders_cubit.dart';
import 'package:united_formation_app/features/settings/ui/screens/library_screen.dart';
import 'package:united_formation_app/features/settings/ui/screens/orders_screen.dart';
import 'package:united_formation_app/features/settings/ui/screens/profile_screen.dart';
import 'package:united_formation_app/features/settings/ui/screens/settings_screen.dart';
import '../di/dependency_injection.dart';
import 'routes.dart';
import '../utilities/enums/otp_purpose.dart';
import '../../features/auth/ui/cubits/learning_options/learning_options_cubit.dart';
import '../../features/auth/ui/cubits/login/login_cubit.dart';
import '../../features/auth/ui/cubits/otp/otp_cubit.dart';
import '../../features/auth/ui/cubits/password_reset/password_reset_cubit.dart';
import '../../features/auth/ui/cubits/register/register_cubit.dart';
import '../../features/auth/ui/pages/learning_options_page.dart';
import '../../features/auth/ui/pages/login_page.dart';
import '../../features/auth/ui/pages/otp_verification_page.dart';
import '../../features/auth/ui/pages/register_page.dart';
import '../../features/auth/ui/pages/request_otp_page.dart';
import '../../features/auth/ui/pages/reset_password_page.dart';
import '../../features/home/home_view.dart';
import '../../features/settings/ui/cubits/edit_profile/edit_profile_cubit.dart';
import '../../features/settings/ui/cubits/profile/profile_cubit.dart';
import '../../features/settings/ui/cubits/support/support_cubit.dart';
import '../../features/settings/ui/screens/edit_profile_screen.dart';
import '../../features/settings/ui/screens/support_screen.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    print(
      "Route: ${settings.name}, Arguments Type: ${arguments?.runtimeType}, Arguments: $arguments",
    );

    switch (settings.name) {
      case Routes.loginView:
        // تأكد من أن Cubit جديد يتم إنشاؤه في كل مرة
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) {
                  // استخدم sl<LoginCubit>() لإنشاء مثيل جديد في كل مرة
                  final cubit = sl<LoginCubit>();

                  // إذا كانت هناك وسيطات تشير إلى بدء جديد
                  if (arguments is Map &&
                      arguments.containsKey('fresh_start')) {
                    cubit.resetState();
                  }

                  return cubit;
                },
                child: const LoginPage(),
              ),
        );

      case Routes.registerView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<RegisterCubit>(),
                child: const RegisterPage(),
              ),
        );

      case Routes.learningOptionsView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<LearningOptionsCubit>(),
                child: const LearningOptionsPage(),
              ),
        );

      case Routes.requestOtpView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) {
                  // التأكد من تنظيف أي مؤقتات أو موارد قبل إنشاء جديد
                  final cubit = sl<PasswordResetCubit>();
                  return cubit;
                },
                child: const RequestOtpPage(),
              ),
        );

      case Routes.verifyOtpView:
        print("verifyOtpView Arguments Type: ${arguments.runtimeType}");
        String email;
        bool isFromRegister = false;

        if (arguments is String) {
          // Coming from registration
          email = arguments;
          isFromRegister = true;
          print("From Register with email: $email");
        } else if (arguments is Map) {
          // Coming from password reset
          email = arguments['email'] as String;
          isFromRegister = false;
          print("From ForgetPassword with email: $email");
        } else {
          // Unexpected arguments type
          print("Unexpected arguments type: ${arguments.runtimeType}");
          email = "example@email.com"; // Default value
          isFromRegister = true;
        }

        if (isFromRegister) {
          // If coming from registration, use OtpCubit
          return MaterialPageRoute(
            settings: settings,
            builder:
                (_) => BlocProvider(
                  create:
                      (context) => OtpCubit(
                        email: email,
                        verifyOtpUseCase: sl(),
                        sendOtpUseCase: sl(),
                        purpose: OtpPurpose.accountVerification,
                      ),
                  child: OtpVerificationPage(email: email),
                ),
          );
        } else {
          // If coming from password reset, use PasswordResetCubit
          print(
            "Creating PasswordResetCubit for OTP verification with email: $email",
          );
          return MaterialPageRoute(
            settings: settings,
            builder:
                (_) => BlocProvider(
                  create: (context) {
                    // إنشاء مثيل جديد تمامًا من PasswordResetCubit
                    final cubit = sl<PasswordResetCubit>();

                    // تعيين البريد الإلكتروني بشكل آمن
                    cubit.setEmail(email);

                    return cubit;
                  },
                  child: OtpVerificationPage(email: email),
                ),
          );
        }

      case Routes.resetPasswordView:
        print(
          "resetPasswordView Arguments: $arguments, Type: ${arguments.runtimeType}",
        );

        Map<String, String> parsedArgs = {};

        if (arguments is Map) {
          parsedArgs = Map<String, String>.from(
            arguments.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          );
        }

        String email = parsedArgs['email'] ?? "example@email.com";
        String otp = parsedArgs['otp'] ?? "0000";

        print("Creating ResetPasswordView with email: $email, otp: $otp");

        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) {
                  // إنشاء مثيل جديد كل مرة لتجنب استخدام cubit متخلص منه
                  final cubit = sl<PasswordResetCubit>();

                  // تعيين البيانات بشكل آمن
                  cubit.setEmail(email);
                  cubit.setVerifiedOtp(otp);

                  return cubit;
                },
                child: ResetPasswordPage(email: email, otp: otp),
              ),
        );

      // Profile Routes
      case Routes.settingsView:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      case Routes.profileView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<ProfileCubit>(),
                child: const ProfileScreen(),
              ),
        );

      case Routes.editProfileView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<EditProfileCubit>(),
                child: const EditProfileScreen(),
              ),
        );

      case Routes.ordersView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<OrdersCubit>(),
                child: const OrdersScreen(),
              ),
        );

      case Routes.libraryView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<LibraryCubit>(),
                child: const LibraryScreen(),
              ),
        );

      case Routes.supportView:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => BlocProvider(
                create: (context) => sl<SupportCubit>(),
                child: const SupportScreen(),
              ),
        );
      case Routes.homeView:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeView(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
