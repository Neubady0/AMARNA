import 'dart:typed_data';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String name;
  final String email;
  final String mobilePhone;
  final String jobTitle;
  final String officeLocation;
  final String department;
  final Uint8List? profilePhoto;

  AuthSuccess(
    this.profilePhoto,
    this.name,
    this.email,
    this.mobilePhone,
    this.jobTitle,
    this.officeLocation,
    this.department,
  );
}

class AuthError extends AuthState {
  final String errorMessage;
  AuthError(this.errorMessage);
}
