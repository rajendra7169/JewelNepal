import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Email & Password Sign In
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Register with Email & Password
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);
      await result.user?.reload(); // Reload user data to refresh displayName

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // Add scopes if needed
        googleProvider.addScope(
          'https://www.googleapis.com/auth/contacts.readonly',
        );
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        // Sign in with popup for better user experience on web
        UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );

        // Refresh user data to ensure all profile info is loaded
        await userCredential.user?.reload();

        // Add user to Firestore if new
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'name': userCredential.user!.displayName,
                'email': userCredential.user!.email,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        return userCredential.user;
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // Refresh user data to ensure all profile info is loaded
        await userCredential.user?.reload();

        // Add user to Firestore if new
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'name': userCredential.user!.displayName,
                'email': userCredential.user!.email,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Sign in with Facebook
  Future<User?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // Web implementation
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        facebookProvider.setCustomParameters({'display': 'popup'});

        UserCredential userCredential = await _auth.signInWithPopup(
          facebookProvider,
        );

        // Refresh user data to ensure all profile info is loaded
        await userCredential.user?.reload();

        // Add user to Firestore if new
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'name': userCredential.user!.displayName,
                'email': userCredential.user!.email,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        return userCredential.user;
      } else {
        // Mobile implementation
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status != LoginStatus.success) return null;

        // Get access token
        final String accessToken = result.accessToken!.toString();

        // Create credential
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken,
        );

        // Sign in with credential
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // Refresh user data to ensure all profile info is loaded
        await userCredential.user?.reload();

        // Add user to Firestore if new
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'name': userCredential.user!.displayName,
                'email': userCredential.user!.email,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Error signing in with Facebook: $e");
      rethrow;
    }
  }

  // Sign out - UPDATED METHOD
  Future<void> signOut() async {
    try {
      // First, try to sign out from Firebase
      await _auth.signOut();

      // Then safely try to sign out from Google
      try {
        // Check if GoogleSignIn is available
        await _googleSignIn.signOut().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      } catch (e) {
        // Silently ignore Google sign out errors
        debugPrint('Google sign out error: $e');
      }

      // Finally, try to log out from Facebook
      try {
        // Check if FacebookAuth is available
        await FacebookAuth.instance.logOut().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      } catch (e) {
        // Silently ignore Facebook logout errors
        debugPrint('Facebook logout error: $e');
      }
    } catch (e) {
      // Log the error but don't throw it
      debugPrint('Error during sign out: $e');
      // Optionally rethrow if you want the UI to handle it
      // rethrow;
    }
  }

  // Helper method to handle Firebase Auth exceptions
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unknown error occurred';
    }
  }
}
