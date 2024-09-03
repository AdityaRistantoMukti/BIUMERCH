import '/modul1.2/utils/formatters/formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String firstName;
  String lastName;
  String idUser;
  String username;
  String email;
  String phoneNumber;
  String? profilePicture;
  int balance;
  bool isEmail;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.idUser,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.profilePicture,
    required this.balance,
    required this.isEmail,
  });

  /// Helper function to get the full name.
  String get fullName => '$firstName $lastName';

  /// Helper function to format phone number.
  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  static List<String> nameParts(fullname) => fullname.split(" ");

  static String generateUsername(fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : "";

    String camelCaseUsername = "$firstName$lastName";
    String usernameWithPrefix = "biuM_$camelCaseUsername";
    return usernameWithPrefix;
  }
UserModel copyWith({
    String? firstName,
    String? lastName,
    String? idUser,
    String? username,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    int? balance,
    bool? isEmail,
  }) {
    return UserModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      idUser: idUser ?? this.idUser,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      balance: balance ?? this.balance,
      isEmail: isEmail ?? this.isEmail,
    );
  }

  static UserModel empty() => UserModel(
      firstName: '',
      lastName: '',
      idUser: '',
      username: '',
      email: '',
      phoneNumber: '',
      profilePicture: '',
      balance: 0,
      isEmail: false,);


// from map
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data != null) {
      return UserModel(
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        idUser: data['idUser'] as String? ?? '',
        username: data['username'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phoneNumber: data['phoneNumber'] as String? ?? '',
        profilePicture: data['profilePicture'] as String?,
        balance: (data['balance'] as num?)?.toInt() ?? 0,
        isEmail: data['isEmail'] as bool? ?? false,
      );
    } else {
      throw Exception("Document data is null");
    }
  }

  // to map
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'idUser': idUser,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'balance': balance,
      'isEmail': isEmail,
    };
  }
}
