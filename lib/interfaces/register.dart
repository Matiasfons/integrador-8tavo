import 'dart:core';

class UserData {
  final String email;
  final String password;
  final String? name;
  final String? phone;

  UserData({
    required this.email,
    required this.password,
    this.name,
    this.phone,
  });


}
