// ignore: unused_import
// ignore_for_file: unawaited_futures

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo/core/domain/model/login_model.dart';
import 'package:flutter_demo/core/helpers.dart';
import 'package:flutter_demo/core/utils/either_extensions.dart';
import 'package:flutter_demo/core/utils/mvp_extensions.dart';
import 'package:flutter_demo/dependency_injection/app_component.dart';
import 'package:flutter_demo/features/auth/domain/use_cases/log_in_use_case.dart';
import 'package:flutter_demo/features/auth/login/login_presentation_model.dart';
import 'package:flutter_demo/features/auth/login/login_presenter.dart';
import 'package:flutter_demo/localization/app_localizations_utils.dart';

class LoginPage extends StatefulWidget with HasPresenter<LoginPresenter> {
  const LoginPage({
    required this.presenter,
    super.key,
  });

  @override
  final LoginPresenter presenter;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with PresenterStateMixin<LoginViewModel, LoginPresenter, LoginPage> {
  LoginModel userInfo = LoginModel(userName: '', password: '');
  final useCase = getIt<LogInUseCase>();

  final StreamController<bool> loadingController =
      StreamController<bool>.broadcast();

  Stream<bool> get loadingStream => loadingController.stream;

  Sink<bool> get loadingSink => loadingController.sink;

  final StreamController<LoginModel> streamController =
      StreamController<LoginModel>.broadcast();

  Stream<LoginModel> get userStream => streamController.stream;

  Sink<LoginModel> get userSink => streamController.sink;

  void userNameCheck(String text) {
    userInfo.userName = text;
    userSink.add(userInfo);
  }

  void userPasswordCheck(String text) {
    userInfo.password = text;
    userSink.add(userInfo);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: appLocalizations.usernameHint,
                ),
                onChanged: (text) => userNameCheck(text), //TODO
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: appLocalizations.passwordHint,
                ),
                onChanged: (text) => userPasswordCheck(text), //TODO
              ),
              const SizedBox(height: 16),
              stateObserver(
                builder: (context, state) => StreamBuilder<bool>(
                  initialData: false,
                  stream: loadingStream,
                  builder: (context, snapshot) {
                    if (snapshot.data != true) {
                      return StreamBuilder<LoginModel>(
                        initialData: userInfo,
                        stream: userStream,
                        builder: (context, snapshot) {
                          return ElevatedButton(
                            onPressed: snapshot.data!.userName!.isNotEmpty &&
                                    snapshot.data!.password!.isNotEmpty
                                ? () async {
                                    loadingSink.add(true);
                                    await useCase
                                        .execute(
                                          username: snapshot.data!.userName!,
                                          password: snapshot.data!.password!,
                                        )
                                        .asyncFold(
                                          (fail) => presenter.navigator
                                              .showError(
                                                  fail.displayableFailure(),),
                                          (success) =>
                                              presenter.navigator.showAlert(
                                            title: 'Login',
                                            message: 'You are logged in',
                                          ),
                                        );
                                    loadingSink.add(false);
                                  }
                                : null,
                            child: Text(appLocalizations.logInAction),
                          );
                        },
                      );
                    }
                    return const ElevatedButton(
                      onPressed: null,
                      child: SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
