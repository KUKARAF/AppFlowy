import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/settings/show_settings.dart';
import 'package:appflowy/shared/window_title_bar.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_agreement.dart';
import 'package:appflowy/user/presentation/widgets/widgets.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

class DesktopSignInScreen extends StatefulWidget {
  const DesktopSignInScreen({super.key});

  @override
  State<DesktopSignInScreen> createState() => _DesktopSignInScreenState();
}

class _DesktopSignInScreenState extends State<DesktopSignInScreen>
    with WindowListener {
  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        final bottomPadding = UniversalPlatform.isDesktop ? 20.0 : 24.0;
        return Scaffold(
          appBar: _buildAppBar(),
          body: Center(
            child: AuthFormContainer(
              children: [
                const Spacer(),
                FlowyLogoTitle(
                  title: LocaleKeys.welcomeText.tr(),
                  logoSize: Size.square(36),
                ),
                VSpace(theme.spacing.xxl),
                AFFilledTextButton.primary(
                  size: AFButtonSize.l,
                  alignment: Alignment.center,
                  text: 'Sign in with Authentik',
                  onTap: state.isSubmitting
                      ? null
                      : () => context.read<SignInBloc>().add(
                            const SignInEvent.signInWithOAuth(
                              platform: 'authentik',
                            ),
                          ),
                  textStyle: theme.textStyle.body.enhanced(
                    color: theme.textColorScheme.onFill,
                  ),
                ),
                VSpace(theme.spacing.xxl),
                const SignInAgreement(),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DesktopSignInSettingsButton(),
                  ],
                ),
                VSpace(bottomPadding),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(UniversalPlatform.isWindows ? 40 : 60),
      child: UniversalPlatform.isWindows
          ? const WindowTitleBar()
          : const MoveWindowDetector(),
    );
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }
}

class DesktopSignInSettingsButton extends StatelessWidget {
  const DesktopSignInSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFGhostIconTextButton(
      text: LocaleKeys.signIn_settings.tr(),
      textColor: (context, isHovering, disabled) {
        return theme.textColorScheme.secondary;
      },
      size: AFButtonSize.s,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.xs,
      ),
      onTap: () => showSimpleSettingsDialog(context),
      iconBuilder: (context, isHovering, disabled) {
        return FlowySvg(
          FlowySvgs.settings_s,
          size: Size.square(20),
          color: theme.textColorScheme.secondary,
        );
      },
    );
  }
}
