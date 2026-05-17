import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingThirdPartyLogin extends StatelessWidget {
  const SettingThirdPartyLogin({
    super.key,
    required this.didLogin,
  });

  final VoidCallback didLogin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          final successOrFail = state.successOrFail;
          if (successOrFail != null) {
            _handleSuccessOrFail(successOrFail, context);
          }
        },
        builder: (_, state) {
          final theme = AppFlowyTheme.of(context);
          return Column(
            children: [
              if (state.isSubmitting) ...[
                const LinearProgressIndicator(minHeight: 1),
                const VSpace(6),
                FlowyText.medium(
                  LocaleKeys.signIn_syncPromptMessage.tr(),
                  maxLines: null,
                ),
                const VSpace(6),
              ],
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
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSuccessOrFail(
    FlowyResult<UserProfilePB, FlowyError> result,
    BuildContext context,
  ) async {
    result.fold(
      (user) async {
        didLogin();
        await runAppFlowy();
      },
      (error) => showSnapBar(context, error.msg),
    );
  }
}
