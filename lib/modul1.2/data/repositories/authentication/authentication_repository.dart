import '/modul1.2/features/authentication/view/login/login.dart';
import '/modul1.2/features/authentication/view/onboarding/onboarding.dart';
import '/modul1.2/features/authentication/view/singup/verify_email.dart';
import '/bottom_navigation.dart';
import '/modul1.2/utils/exceptions/firebase_auth_exceptions.dart';
import '/modul1.2/utils/exceptions/firebase_exceptions.dart';
import '/modul1.2/utils/exceptions/format_exceptions.dart';
import '/modul1.2/utils/exceptions/platform_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  /// Called from main.dart on app launch
  @override
  void onReady() {
    // Remove to the native splash screen
    FlutterNativeSplash.remove();
    screenRedirect();
  }

  /// Function to Show Relevant Screen
  screenRedirect() async {
    final user = _auth.currentUser;
    if (user != null) {
      if (user.emailVerified) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final isEmailVerified = docSnapshot['isEmail'] ?? false;
        if (isEmailVerified) {
          Get.offAll(() => BottomNavigation());
        } else {
          Get.offAll(() => VerifyEmailView(email: user.email));
        }
      } else {
        Get.offAll(() => VerifyEmailView(email: user.email));
      }
    } else {
      // Local Storage
      deviceStorage.writeIfNull('isFirstTime', true);
      // check if it's the first time launching the app
      deviceStorage.read('isFirstTime') != true
          ? Get.offAll(() => const LoginView())
          : Get.offAll(const OnboardingView());
    }
  }

  /*------------------------------------------- Email & Password sign-in -----------------------------------------------*/
  /// [EmailAuthentication] - LOGIN
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Terjadi kesalahan. Mohon coba lagi.';
    }
  }

  /// [EmailAuthentication] - Register
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Terjadi kesalahan. Mohon coba lagi.';
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Terjadi kesalahan. Mohon coba lagi.';
    }
  }

  Future<void> updateIsEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isEmail': true,
        });
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Gagal mengupdate status verifikasi email. Mohon coba lagi.';
    }
  }

  ///
  /*------------------------------------------- Federated identity & Social Sign-in -----------------------------------------------*/

Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return docSnapshot.data() as Map<String, dynamic>?;
      }
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Gagal mengambil data pengguna. Mohon coba lagi.';
    }
  }
  /// [GoogleAuthentication] - Google
  Future<UserCredential> signInWIthGoogle() async {
  try {
    // Trigger the authentication flow
    final GoogleSignInAccount? userAccount = await GoogleSignIn().signIn();
    
    if (userAccount == null) throw 'User cancelled the login process';

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await userAccount.authentication;
    
    // Create a new credential
    final credentials = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // Once signed in, return the UserCredential
    return await _auth.signInWithCredential(credentials);

  } on FirebaseAuthException catch (e) {
    throw TFirebaseAuthException(e.code).message;
  } on FirebaseException catch (e) {
    throw TFirebaseException(e.code).message;
  } on FormatException catch (_) {
    throw const TFormatException();
  } on PlatformException catch (e) {
    throw TPlatformException(e.code).message;
  } catch (e) {
    throw 'Terjadi kesalahan. Mohon coba lagi.';
  }
}

/// [EmailAuthentication] - FORGET PASSWORD
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Terjadi kesalahan. Mohon coba lagi.';
    }
  }
  

  /*------------------------------------------- ./end Federated identity & social sign-in -----------------------------------------------*/

  /// [LogoutUser] - valid for ant authentication.
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      Get.offAll(() => const LoginView());
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Terjadi kesalahan. Mohon coba lagi.';
    }
  }
}
