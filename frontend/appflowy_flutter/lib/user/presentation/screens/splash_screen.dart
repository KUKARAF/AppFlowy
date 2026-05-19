import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/splash_bloc.dart';
import 'package:appflowy/user/domain/auth_state.dart';
import 'package:appflowy/user/presentation/helpers/helpers.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

class SplashScreen extends StatelessWidget {
  /// Root Page of the app.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildChild(context);
  }

  BlocProvider<SplashBloc> _buildChild(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<SplashBloc>()..add(const SplashEvent.getUser()),
      child: Scaffold(
        body: BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            state.auth.map(
              authenticated: (r) => _handleAuthenticated(context, r),
              unauthenticated: (r) => _handleUnauthenticated(context, r),
              initial: (r) => {},
            );
          },
          child: const Body(),
        ),
      ),
    );
  }

  /// Handles the authentication flow once a user is authenticated.
  Future<void> _handleAuthenticated(
    BuildContext context,
    Authenticated authenticated,
  ) async {
    final result = await FolderEventGetCurrentWorkspaceSetting().send();
    result.fold(
      (workspaceSetting) {
        // After login, replace Splash screen by corresponding home screen
        getIt<SplashRouter>().goHomeScreen(
          context,
        );
      },
      (error) => handleOpenWorkspaceError(context, error),
    );
  }

  void _handleUnauthenticated(BuildContext context, Unauthenticated result) {
    // Replace splash screen with sign-in screen (Authentik SSO only)
    context.go(SignInScreen.routeName);
  }
}

class Body extends StatelessWidget {
  const Body({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: UniversalPlatform.isMobile
          ? const FlowySvg(FlowySvgs.app_logo_xl, blendMode: null)
          : const _DesktopSplashBody(),
    );
  }
}

class _DesktopSplashBody extends StatelessWidget {
  const _DesktopSplashBody();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            image: const AssetImage(
              'assets/images/appflowy_launch_splash.jpg',
            ),
          ),
          const CircularProgressIndicator.adaptive(),
        ],
      ),
    );
  }
}
