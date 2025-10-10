import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? email;

  void login(String email, String password) {
    this.email = email;
    notifyListeners();
  }

  void signup(String email, String password) {
    this.email = email;
    notifyListeners();
  }

  void logout() {
    email = null;
    notifyListeners();
  }
}
