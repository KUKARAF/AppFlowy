import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_bloc.freezed.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this.authService) : super(SignInState.initial()) {
    deepLinkStateListener =
        getIt<AppFlowyCloudDeepLink>().subscribeDeepLinkLoadingState((value) {
      if (isClosed) return;
      add(SignInEvent.deepLinkStateChange(value));
    });

    on<SignInEvent>(
      (event, emit) async {
        await event.when(
          signInWithOAuth: (platform) async => _onSignInWithOAuth(
            emit,
            platform: platform,
          ),
          deepLinkStateChange: (result) => _onDeepLinkStateChange(emit, result),
        );
      },
    );
  }

  final AuthService authService;
  VoidCallback? deepLinkStateListener;

  @override
  Future<void> close() {
    deepLinkStateListener?.call();
    if (deepLinkStateListener != null) {
      getIt<AppFlowyCloudDeepLink>().unsubscribeDeepLinkLoadingState(
        deepLinkStateListener!,
      );
    }
    return super.close();
  }

  Future<void> _onDeepLinkStateChange(
    Emitter<SignInState> emit,
    DeepLinkResult result,
  ) async {
    switch (result.state) {
      case DeepLinkState.none:
        break;
      case DeepLinkState.loading:
        emit(state.copyWith(isSubmitting: true, successOrFail: null));
      case DeepLinkState.finish:
        final newState = result.result?.fold(
          (s) => state.copyWith(
            isSubmitting: false,
            successOrFail: FlowyResult.success(s),
          ),
          (f) => state.copyWith(
            isSubmitting: false,
            successOrFail: FlowyResult.failure(f),
          ),
        );
        if (newState != null) emit(newState);
      case DeepLinkState.error:
        emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onSignInWithOAuth(
    Emitter<SignInState> emit, {
    required String platform,
  }) async {
    emit(state.copyWith(isSubmitting: true, successOrFail: null));

    final result = await authService.signUpWithOAuth(platform: platform);
    emit(
      result.fold(
        (userProfile) => state.copyWith(
          isSubmitting: false,
          successOrFail: FlowyResult.success(userProfile),
        ),
        (error) {
          Log.error('Sign in with OAuth failed: ${error.msg}');
          return state.copyWith(
            isSubmitting: false,
            successOrFail: FlowyResult.failure(error),
          );
        },
      ),
    );
  }
}

@freezed
class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signInWithOAuth({
    required String platform,
  }) = SignInWithOAuth;

  const factory SignInEvent.deepLinkStateChange(DeepLinkResult result) =
      DeepLinkStateChange;
}

@freezed
class SignInState with _$SignInState {
  const factory SignInState({
    required bool isSubmitting,
    required FlowyResult<UserProfilePB, FlowyError>? successOrFail,
  }) = _SignInState;

  factory SignInState.initial() => const SignInState(
        isSubmitting: false,
        successOrFail: null,
      );
}
