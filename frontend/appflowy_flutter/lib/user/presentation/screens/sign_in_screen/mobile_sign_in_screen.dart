import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/launch_settings_page.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_agreement.dart';
import 'package:appflowy/user/presentation/widgets/flowy_logo_title.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileSignInScreen extends StatelessWidget {
  const MobileSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        final theme = AppFlowyTheme.of(context);
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 40),
            child: Column(
              children: [
                const Spacer(),
                FlowyLogoTitle(title: LocaleKeys.welcomeText.tr()),
                VSpace(theme.spacing.xxl),
                AFFilledTextButton.primary(
                  size: AFButtonSize.l,
                  alignment: Alignment.center,
                  text: 'Sign in with Authentik',
                  onTap: () {
                    if (!state.isSubmitting) {
                      context.read<SignInBloc>().add(
                        const SignInEvent.signInWithOAuth(
                          platform: 'authentik',
                        ),
                      );
                    }
                  },
                  textStyle: theme.textStyle.body.enhanced(
                    color: theme.textColorScheme.onFill,
                  ),
                ),
                VSpace(theme.spacing.xxl),
                const SignInAgreement(),
                const Spacer(),
                _buildSettingsButton(context, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context, AppFlowyThemeData theme) {
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
      onTap: () => context.push(MobileLaunchSettingsPage.routeName),
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
