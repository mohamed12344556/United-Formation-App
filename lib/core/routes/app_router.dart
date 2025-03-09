import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:united_formation_app/core/routes/routes.dart';
import 'package:united_formation_app/core/utilities/enums/otp_purpose.dart';
import 'package:united_formation_app/features/auth/ui/cubits/learning_options/learning_options_cubit.dart';
import 'package:united_formation_app/features/auth/ui/cubits/login/login_cubit.dart';
import 'package:united_formation_app/features/auth/ui/cubits/otp/otp_cubit.dart';
import 'package:united_formation_app/features/auth/ui/cubits/password_reset/password_reset_cubit.dart';
import 'package:united_formation_app/features/auth/ui/cubits/register/register_cubit.dart';
import 'package:united_formation_app/features/auth/ui/pages/learning_options_page.dart';
import 'package:united_formation_app/features/auth/ui/pages/login_page.dart';
import 'package:united_formation_app/features/auth/ui/pages/otp_verification_page.dart';
import 'package:united_formation_app/features/auth/ui/pages/register_page.dart';
import 'package:united_formation_app/features/auth/ui/pages/request_otp_page.dart';
import 'package:united_formation_app/features/auth/ui/pages/reset_password_page.dart';
import 'package:united_formation_app/features/home/ui/pages/admin_edit_product.dart';
import 'package:united_formation_app/features/home/ui/pages/home_page.dart';
import 'package:united_formation_app/features/home/ui/pages/product_details_page.dart';

import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/home/data/product_model.dart';
import '../../features/home/ui/pages/host_screen.dart';

final sl = GetIt.instance;

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
          builder: (_) => BlocProvider(
            create: (context) {
              // استخدم sl<LoginCubit>() لإنشاء مثيل جديد في كل مرة
              final cubit = sl<LoginCubit>();
              
              // إذا كانت هناك وسيطات تشير إلى بدء جديد
              if (arguments is Map && arguments.containsKey('fresh_start')) {
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
          builder: (_) => BlocProvider(
            create: (context) => sl<RegisterCubit>(),
            child: const RegisterPage(),
          ),
        );

      case Routes.learningOptionsView:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider(
            create: (context) => sl<LearningOptionsCubit>(),
            child: const LearningOptionsPage(),
          ),
        );

      case Routes.requestOtpView:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider(
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
            builder: (_) => BlocProvider(
              create: (context) => OtpCubit(
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
            builder: (_) => BlocProvider(
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
          "resetPasswordView Arguments: $arguments, Type: ${arguments.runtimeType}");

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
          builder: (_) => BlocProvider(
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

      case Routes.adminEditProductView:
        ProductModel product = arguments as ProductModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>  AdminEditProductPage(product: product),
        );

      case Routes.hostView:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HostPage(),
        );

      case Routes.productDetailsView:
        ProductModel product = arguments as ProductModel;

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProductDetailsPage(product: product),
        );


      case Routes.cartView:
        ProductModel product = arguments as ProductModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>  CartPage(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}