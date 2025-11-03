import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/hybrid_storage_service.dart';
import 'screens/splash_screen.dart';
import 'utils/firestore_status_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with error handling for development)
  try {
    print('🚀 Starting Firebase initialization...');
    final platform = defaultTargetPlatform;
    print('📱 Platform: $platform');
    
    final options = DefaultFirebaseOptions.currentPlatform;
    print('📋 Selected config - Project ID: ${options.projectId}');
    final apiKey = options.apiKey;
    if (apiKey.isNotEmpty && apiKey.length > 20) {
      print('📋 Selected config - API Key: ${apiKey.substring(0, 20)}...');
    } else {
      print('📋 Selected config - API Key: $apiKey');
    }
    
    await Firebase.initializeApp(
      options: options,
    );
    
    final app = Firebase.app();
    print('✅ Firebase initialized successfully');
    print('📋 App Name: ${app.name}');
    print('📋 Project ID: ${app.options.projectId}');
    print('📋 Storage Bucket: ${app.options.storageBucket}');
  } catch (e, stackTrace) {
    print('❌❌❌ Firebase initialization FAILED ❌❌❌');
    print('❌ Error: $e');
    print('❌ Error Type: ${e.runtimeType}');
    print('❌ Full Error: ${e.toString()}');
    print('❌ Stack trace: $stackTrace');
    print('⚠️ App will continue with local storage only');
    print('⚠️ Firebase features (auth, firestore) will NOT work');
    print('⚠️ Admin account creation will fail until this is fixed');
    // Continue even if Firebase fails - app should still work locally
  }

  // Initialize Hybrid Storage (Local + Firestore sync) - wrap in try-catch
  try {
    await HybridStorageService.init();
    print('Hybrid storage initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Hybrid Storage initialization failed: $e');
    print('❌ Stack trace: $stackTrace');
    // Continue anyway - app might work with basic functionality
  }
  
  // Check Firestore status (non-blocking)
  FirestoreStatusChecker.printStatus().catchError((e) {
    print('Status check error (non-critical): $e');
  });

  // Add error handler for uncaught errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🚨 FLUTTER ERROR: ${details.exception}');
    print('🚨 Stack trace: ${details.stack}');
  };
  
  // Run the app
  runApp(FortuMarsHRMApp());
}

class FortuMarsHRMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FortuMars HRM Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1976D2),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.outfitTextTheme(),
        primaryTextTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}