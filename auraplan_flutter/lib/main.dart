import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

const _authChannel = MethodChannel('com.auraplan/auth');

// ─────────────────────────────────────────────────────────────────
//  AdMob Unit IDs
//  TEST IDs are used below — replace with your real IDs from
//  https://apps.admob.com before submitting to Google Play.
// ─────────────────────────────────────────────────────────────────
const String _kBannerAdUnitIdAndroid =
    'ca-app-pub-3940256099942544/6300978111'; // ← replace with real ID
const String _kBannerAdUnitIdIOS =
    'ca-app-pub-3940256099942544/2934735716'; // ← replace with real ID

const String _kInterstitialAdUnitIdAndroid =
    'ca-app-pub-3940256099942544/1033173712'; // ← replace with real ID
const String _kInterstitialAdUnitIdIOS =
    'ca-app-pub-3940256099942544/4411468910'; // ← replace with real ID

String get _bannerAdUnitId =>
    (!kIsWeb && Platform.isAndroid) ? _kBannerAdUnitIdAndroid : _kBannerAdUnitIdIOS;
String get _interstitialAdUnitId =>
    (!kIsWeb && Platform.isAndroid) ? _kInterstitialAdUnitIdAndroid : _kInterstitialAdUnitIdIOS;

// ─────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar (immersive look)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init AdMob SDK (mobile only)
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Request mic + location permissions on Android before app starts
  if (!kIsWeb && Platform.isAndroid) {
    await [
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();
  }

  runApp(const AuraPlanApp());
}

// ─────────────────────────────────────────────────────────────────
//  Root App
// ─────────────────────────────────────────────────────────────────
class AuraPlanApp extends StatelessWidget {
  const AuraPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraPlan AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5a53b0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const AuraPlanHome(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Home — WebView + AdMob Banner
// ─────────────────────────────────────────────────────────────────
class AuraPlanHome extends StatefulWidget {
  const AuraPlanHome({super.key});

  @override
  State<AuraPlanHome> createState() => _AuraPlanHomeState();
}

class _AuraPlanHomeState extends State<AuraPlanHome> {
  InAppWebViewController? _webViewController;

  // ── Banner ad ──────────────────────────────────
  BannerAd? _bannerAd;
  bool _bannerAdLoaded = false;

  // ── Interstitial ad ──────────────────────────
  InterstitialAd? _interstitialAd;
  int _pageViewCount = 0; // show interstitial every N page views

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  // ── Banner ─────────────────────────────────────
  void _loadBannerAd() {
    if (kIsWeb) return;
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  // ── Interstitial ───────────────────────────────
  void _loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed: ${error.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _maybeShowInterstitial() {
    _pageViewCount++;
    // Show interstitial every 4 screen navigations
    if (_pageViewCount % 4 == 0 && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd(); // preload next
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── WebView (takes all remaining space) ──
            Expanded(
              child: InAppWebView(
                // Load app HTML from Flutter assets bundle
                initialFile: kIsWeb ? null : 'assets/index.html',
                initialUrlRequest: kIsWeb
                    ? URLRequest(url: WebUri('assets/index.html'))
                    : null,

                initialSettings: InAppWebViewSettings(
                  // JavaScript must be on
                  javaScriptEnabled: true,

                  // Allow Web Speech API audio without gesture
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,

                  // Hybrid composition renders WebView in Flutter's layer tree
                  useHybridComposition: true,

                  // Persistent storage for app state (tasks, settings)
                  domStorageEnabled: true,
                  databaseEnabled: true,

                  // Geolocation API (location on home screen)
                  geolocationEnabled: true,

                  // Allow local file cross-origin (needed to load from assets)
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,

                  // Transparent background so splash doesn't flash
                  transparentBackground: true,

                  // Allow mixed content (HTTP API calls from file://)
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

                  // Smooth scrolling
                  overScrollMode: OverScrollMode.NEVER,

                  // Disable zoom (it's a mobile app, not a browser)
                  supportZoom: false,
                  builtInZoomControls: false,
                  displayZoomControls: false,

                  // User agent
                  userAgent:
                      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                ),

                // ── Grant mic + camera + geolocation from WebView ──
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },

                onGeolocationPermissionsShowPrompt:
                    (controller, origin) async {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },

                onWebViewCreated: (controller) {
                  _webViewController = controller;

                  // JS handlers are not supported on web platform
                  if (kIsWeb) return;

                  // ── GoogleSignIn handler ────────────────────────
                  controller.addJavaScriptHandler(
                    handlerName: 'GoogleSignIn',
                    callback: (args) async {
                      try {
                        final result = await _authChannel
                            .invokeMapMethod<String, dynamic>('GoogleSignIn');
                        if (result != null) {
                          final uid = jsonEncode(result['uid'] ?? '');
                          final name = jsonEncode(result['displayName'] ?? '');
                          final email = jsonEncode(result['email'] ?? '');
                          final photo = jsonEncode(result['photoUrl'] ?? '');
                          await controller.evaluateJavascript(
                            source: 'window.onGoogleSignInSuccess($uid,$name,$email,$photo)',
                          );
                        }
                      } on PlatformException catch (e) {
                        final code = jsonEncode(e.code);
                        final msg = jsonEncode(e.message ?? 'Unknown error');
                        await controller.evaluateJavascript(
                          source: 'window.onGoogleSignInError($code,$msg)',
                        );
                      }
                      return null;
                    },
                  );

                  // ── SignOut handler ─────────────────────────────
                  controller.addJavaScriptHandler(
                    handlerName: 'SignOut',
                    callback: (args) async {
                      try {
                        await _authChannel.invokeMethod('SignOut');
                      } catch (_) {}
                      return null;
                    },
                  );
                },

                // Show interstitial on WebView navigations
                onUpdateVisitedHistory: (controller, url, isReload) {
                  if (!isReload!) _maybeShowInterstitial();
                },

                // Handle back button — go back in WebView history first
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url.toString();
                  // Block external navigation attempts (security)
                  if (!url.startsWith('file://') &&
                      !url.startsWith('about:') &&
                      !url.contains('localhost')) {
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
            ),

            // ── AdMob Banner (at the bottom) ──────────
            if (!kIsWeb && _bannerAdLoaded && _bannerAd != null)
              SafeArea(
                top: false,
                child: Container(
                  color: const Color(0xFF0a0818),
                  width: double.infinity,
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Android back button handling ──────────────────────────────────
class BackButtonHandler extends StatelessWidget {
  final InAppWebViewController? webViewController;
  final Widget child;

  const BackButtonHandler({
    super.key,
    required this.webViewController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (webViewController != null) {
          final canGoBack = await webViewController!.canGoBack();
          if (canGoBack) {
            webViewController!.goBack();
            return;
          }
        }
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}
