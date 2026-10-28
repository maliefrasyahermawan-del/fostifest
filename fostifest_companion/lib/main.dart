import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FostifestApp());

// Palet FOSTIFEST: hijau-putih, bersih, dan mudah dibaca di layar ponsel.
const _brandYellow = Color(0xFF0B5D3B);
const _softYellow = Color(0xFF8FE388);
const _gold = Color(0xFF35A565);
const _cream = Color(0xFFEAF7EE);
const _warmWhite = Color(0xFFFFFFFF);
const _divider = Color(0xFFDDE9E2);
const _ink = Color(0xFF123126);
const _muted = Color(0xFF5F766C);
const _error = Color(0xFFFF6F76);
const _deepGold = Color(0xFF063A27);

class BusinessProfile {
  const BusinessProfile({
    this.name = 'Batik Sekar',
    this.description = 'Batik & busana khas Indonesia',
    this.location = 'Surakarta, Jawa Tengah',
    this.category = 'Fashion & kerajinan',
    this.photoPath,
  });

  final String name;
  final String description;
  final String location;
  final String category;
  final String? photoPath;

  static Future<BusinessProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return BusinessProfile(
      name: prefs.getString('business_name') ?? 'Batik Sekar',
      description: prefs.getString('business_description') ??
          'Batik & busana khas Indonesia',
      location:
          prefs.getString('business_location') ?? 'Surakarta, Jawa Tengah',
      category: prefs.getString('business_category') ?? 'Fashion & kerajinan',
      photoPath: prefs.getString('business_photo'),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', name);
    await prefs.setString('business_description', description);
    await prefs.setString('business_location', location);
    await prefs.setString('business_category', category);
    if (photoPath != null) {
      await prefs.setString('business_photo', photoPath!);
    }
  }
}

class FostifestAccount {
  const FostifestAccount({
    required this.fullName,
    required this.identifier,
    required this.password,
  });

  final String fullName;
  final String identifier;
  final String password;

  static Future<FostifestAccount?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString('account_identifier');
    final password = prefs.getString('account_password');
    if (identifier == null || password == null) return null;
    return FostifestAccount(
      fullName: prefs.getString('account_full_name') ?? 'Pemilik Usaha',
      identifier: identifier,
      password: password,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_full_name', fullName);
    await prefs.setString('account_identifier', identifier.trim().toLowerCase());
    await prefs.setString('account_password', password);
  }
}

ImageProvider<Object> _businessPhoto(BusinessProfile profile) {
  final path = profile.photoPath;
  if (path != null && File(path).existsSync()) {
    return FileImage(File(path));
  }
  return const AssetImage('assets/images/batik-store-avatar.jpg');
}

class TransactionItem {
  TransactionItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.source,
  });

  final String name;
  final int amount;
  final DateTime date;
  final String source;
}

class FostifestApp extends StatefulWidget {
  const FostifestApp({super.key});

  @override
  State<FostifestApp> createState() => _FostifestAppState();
}

class _FostifestAppState extends State<FostifestApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  BusinessProfile _profile = const BusinessProfile();
  bool _showSplash = true;
  bool _signedIn = false;
  bool _darkMode = false;
  FostifestAccount? _account;
  int _tab = 0;
  final List<TransactionItem> _transactions = [
    TransactionItem(
        name: 'Batik motif Sekar',
        amount: 480000,
        date: DateTime.now(),
        source: 'Manual'),
    TransactionItem(
        name: 'Kemeja linen',
        amount: 275000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        source: 'Scan struk'),
    TransactionItem(
        name: 'Tas anyam',
        amount: 190000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        source: 'Tempel chat'),
  ];

  int get _revenue => _transactions.fold(0, (sum, item) => sum + item.amount);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  Future<void> _loadProfile() async {
    final profile = await BusinessProfile.load();
    final account = await FostifestAccount.load();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profile = profile;
        _account = account;
        _darkMode = prefs.getBool('dark_mode') ?? false;
      });
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
    if (mounted) setState(() => _darkMode = enabled);
  }

  void _logout() => setState(() {
        _signedIn = false;
        _tab = 0;
      });

  Future<String?> _login(String identifier, String password) async {
    final account = _account ?? await FostifestAccount.load();
    if (account == null) {
      return 'Akun belum terdaftar. Silakan daftar terlebih dahulu.';
    }
    if (account.identifier != identifier.trim().toLowerCase() ||
        account.password != password) {
      return 'Email/nomor WhatsApp atau kata sandi tidak sesuai.';
    }
    if (mounted) setState(() => _signedIn = true);
    return null;
  }

  Future<void> _register(FostifestAccount account) async {
    await account.save();
    if (mounted) {
      setState(() {
        _account = account;
        _signedIn = true;
      });
    }
  }

  Future<void> _saveProfile(BusinessProfile profile) async {
    await profile.save();
    if (mounted) setState(() => _profile = profile);
  }

  void _addTransaction(TransactionItem item) {
    setState(() {
      _transactions.insert(0, item);
      _tab = 1;
    });
  }

  void _openAdd() => setState(() => _tab = 2);

  void _openFosti() {
    _navigatorKey.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title:
              const Text('Fosti', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: FostiPage(
            revenue: _revenue,
            transactionCount: _transactions.length,
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
          profile: _profile,
          items: _transactions,
          revenue: _revenue,
          transactionCount: _transactions.length,
          onAdd: _openAdd,
          onInsight: () => setState(() => _tab = 3),
          onProfile: () => setState(() => _tab = 4)),
      LedgerPage(profile: _profile, items: _transactions, onAdd: _openAdd),
      AddTransactionPage(onSave: _addTransaction),
      EligibilityPage(
          profile: _profile,
          revenue: _revenue,
          transactionCount: _transactions.length,
          onAdd: _openAdd),
      ProfilePage(
          profile: _profile,
          onSave: _saveProfile,
          darkMode: _darkMode,
          onDarkModeChanged: _setDarkMode,
          onLogout: _logout),
    ];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FOSTIFEST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _brandYellow,
          onPrimary: _ink,
          secondary: _softYellow,
          onSecondary: _ink,
          surface: _warmWhite,
          onSurface: _ink,
          error: _error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0),
        cardTheme: CardThemeData(
          color: _warmWhite,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _divider),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _warmWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _gold, width: 2),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _brandYellow,
          onPrimary: _ink,
          secondary: _softYellow,
          surface: Color(0xFF202020),
          onSurface: Colors.white,
          error: _error,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: const Color(0xFF202020),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF383838)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF202020),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: _showSplash
          ? const FostifestSplashScreen()
          : !_signedIn
              ? FostifestLoginScreen(
                  onEnter: () => setState(() => _signedIn = true),
                  onLogin: _login,
                  onRegister: _register,
                )
              : Scaffold(
                  appBar: _tab == 2
                      ? AppBar(
                          title: const Text('Catat Cerdas',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                        )
                      : null,
                  body: SafeArea(top: _tab != 2, child: pages[_tab]),
                  floatingActionButton: _tab == 2
                      ? null
                      : FloatingActionButton.extended(
                          onPressed: _openFosti,
                          backgroundColor: _ink,
                          foregroundColor: Colors.white,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Fosti'),
                        ),
                  bottomNavigationBar: FostifestBottomBar(
                    selectedIndex: _tab,
                    onSelected: (index) => setState(() => _tab = index),
                  ),
                ),
    );
  }
}

class FostifestSplashScreen extends StatelessWidget {
  const FostifestSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _brandYellow,
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x24000000),
                        blurRadius: 24,
                        offset: Offset(0, 12)),
                  ],
                ),
                child:
                    const Icon(Icons.storefront_rounded, size: 58, color: _ink),
              ),
              const SizedBox(height: 24),
              const Text('FOSTIFEST',
                  style: TextStyle(
                      fontSize: 28,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                      color: _ink)),
              const SizedBox(height: 8),
              const Text('Tumbuhkan arah usahamu.',
                  style: TextStyle(color: _ink, fontSize: 15)),
            ]),
          ),
        ),
      );
}

class FostifestLoginScreen extends StatefulWidget {
  const FostifestLoginScreen({
    super.key,
    required this.onEnter,
    required this.onLogin,
    required this.onRegister,
  });
  final VoidCallback onEnter;
  final Future<String?> Function(String identifier, String password) onLogin;
  final Future<void> Function(FostifestAccount account) onRegister;

  @override
  State<FostifestLoginScreen> createState() => _FostifestLoginScreenState();
}

class _FostifestLoginScreenState extends State<FostifestLoginScreen> {
  bool _obscure = true;
  bool _submitting = false;
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Isi email/nomor WhatsApp dan kata sandi.')));
      return;
    }
    setState(() => _submitting = true);
    final error = await widget.onLogin(_identifier.text, _password.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _openRegistration() {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FostifestRegistrationScreen(
              onRegister: widget.onRegister,
            )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 236,
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: _brandYellow,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(34)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.storefront_rounded,
                            color: _ink, size: 34),
                      ),
                      const SizedBox(height: 14),
                      const Text('FOSTIFEST',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      const SizedBox(height: 4),
                      const Text('Masuk untuk melihat arah usahamu.',
                          style: TextStyle(color: _ink)),
                    ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email atau nomor WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                       TextField(
                           controller: _identifier,
                           keyboardType: TextInputType.emailAddress,
                          decoration:
                               const InputDecoration(hintText: 'contoh@usaha.id')),
                      const SizedBox(height: 18),
                      const Text('Kata sandi',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      TextField(
                         controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Minimal 6 karakter',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () {},
                            child: const Text('Lupa kata sandi?',
                                style: TextStyle(color: _ink))),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                         onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: _brandYellow,
                          foregroundColor: _ink,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                         child: Text(_submitting ? 'Memeriksa…' : 'Masuk',
                             style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 20),
                      Center(
                          child: TextButton(
                               onPressed: _openRegistration,
                              child: const Text('Belum punya akun? Daftar',
                                  style: TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w800)))),
                      const Row(children: [
                        Expanded(child: Divider(color: _divider)),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child:
                                Text('atau', style: TextStyle(color: _muted))),
                        Expanded(child: Divider(color: _divider))
                      ]),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: widget.onEnter,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Lihat sebagai tamu'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: _ink,
                            side: const BorderSide(color: _gold)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: widget.onEnter,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Masuk ke akun demo FOSTIFEST'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: _ink,
                            side: const BorderSide(color: _ink)),
                      ),
                    ]),
              ),
            ],
          ),
        ),
      );
}

class FostifestRegistrationScreen extends StatefulWidget {
  const FostifestRegistrationScreen({super.key, required this.onRegister});

  final Future<void> Function(FostifestAccount account) onRegister;

  @override
  State<FostifestRegistrationScreen> createState() =>
      _FostifestRegistrationScreenState();
}

class _FostifestRegistrationScreenState extends State<FostifestRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    await widget.onRegister(FostifestAccount(
      fullName: _name.text.trim(),
      identifier: _identifier.text.trim(),
      password: _password.text,
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _brandYellow,
          title: const Text('Daftar akun FOSTIFEST',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                const Text('Mulai kelola usahamu',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                    'Buat akun untuk menyimpan akses FOSTIFEST di perangkat ini.',
                    style: TextStyle(color: _muted, height: 1.4)),
                const SizedBox(height: 24),
                const Text('Nama lengkap',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: _required,
                  decoration: const InputDecoration(hintText: 'Nama sesuai KTP'),
                ),
                const SizedBox(height: 18),
                const Text('Nomor WhatsApp atau email',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_identifier'),
                  controller: _identifier,
                  keyboardType: TextInputType.emailAddress,
                  validator: _required,
                  decoration:
                      const InputDecoration(hintText: '08xx atau nama@usaha.id'),
                ),
                const SizedBox(height: 18),
                const Text('Kata sandi',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_password'),
                  controller: _password,
                  obscureText: _obscure,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Gunakan minimal 6 karakter.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Ulangi kata sandi',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_confirmation'),
                  controller: _confirmation,
                  obscureText: _obscure,
                  validator: (value) => value != _password.text
                      ? 'Kata sandi belum sama.'
                      : null,
                  decoration:
                      const InputDecoration(hintText: 'Ketik ulang kata sandi'),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold),
                  ),
                  child: const Row(children: [
                    CircleAvatar(
                        backgroundColor: _brandYellow,
                        child: Icon(Icons.storefront_rounded, color: _ink)),
                    SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Pemilik UMKM',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                          Text('Kelola transaksi, laporan, dan arah usaha.',
                              style: TextStyle(fontSize: 12, color: _muted)),
                        ])),
                    Icon(Icons.check_circle, color: _deepGold),
                  ]),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('register_submit'),
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _brandYellow,
                    foregroundColor: _ink,
                  ),
                  child: Text(_submitting ? 'Menyimpan…' : 'Daftar & masuk',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Sudah punya akun? Masuk')),
              ],
            ),
          ),
        ),
      );
}

class FostifestBottomBar extends StatelessWidget {
  const FostifestBottomBar(
      {super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(top: BorderSide(color: _divider))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                  index: 0,
                  selected: selectedIndex,
                  onSelected: onSelected),
              _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Catatan',
                  index: 1,
                  selected: selectedIndex,
                  onSelected: onSelected),
              _CenterNavItem(
                  selected: selectedIndex == 2, onPressed: () => onSelected(2)),
              _NavItem(
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights_rounded,
                  label: 'Kelayakan',
                  index: 3,
                  selected: selectedIndex,
                  onSelected: onSelected),
              _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  index: 4,
                  selected: selectedIndex,
                  onSelected: onSelected),
            ],
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.index,
      required this.selected,
      required this.onSelected});
  final IconData icon, activeIcon;
  final String label;
  final int index, selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return Expanded(
        child: InkWell(
            onTap: () => onSelected(index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(active ? activeIcon : icon,
                    color: active ? _ink : _muted, size: 30),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                        color: active ? _ink : _muted)),
              ]),
            )));
  }
}

class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({required this.selected, required this.onPressed});
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Expanded(
          child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(36),
        child: Transform.translate(
          offset: const Offset(0, -18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: _brandYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 12,
                          offset: Offset(0, 5))
                    ]),
                child: Stack(
                  key: const Key('smart_record_icon'),
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: _ink, size: 31),
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _brandYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text('\$',
                            style: TextStyle(
                                color: _ink,
                                fontSize: 15,
                                height: 1,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 3),
            Text('Catat Cerdas',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: selected ? _ink : _muted)),
          ]),
        ),
      ));
}

class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    required this.profile,
    this.onOpenProfile,
  });
  final BusinessProfile profile;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: Row(children: [
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              key: const Key('home_avatar'),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _brandYellow,
                borderRadius: BorderRadius.circular(13),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image(image: _businessPhoto(profile), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('FOSTIFEST',
                    key: Key('home_brand'),
                    style: TextStyle(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                        color: _ink)),
                const Text('Kenali usahamu, tentukan arah.',
                    style: TextStyle(fontSize: 12, color: _ink)),
              ])),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded)),
          ),
        ]),
      );
}

class _HeroCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 34)
    ..quadraticBezierTo(
        size.width / 2, size.height + 24, size.width, size.height - 34)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.profile,
    required this.revenue,
    required this.transactionCount,
    required this.onProfile,
  });

  final BusinessProfile profile;
  final int revenue;
  final int transactionCount;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 314,
        child: Stack(children: [
          ClipPath(
            clipper: _HeroCurveClipper(),
            child: Container(height: 266, color: _brandYellow),
          ),
          Positioned(
            top: 14,
            left: 20,
            right: 20,
            child: MobileHeader(profile: profile, onOpenProfile: onProfile),
          ),
          Positioned(
            top: 104,
            left: 20,
            right: 20,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Halo, ${profile.name} 👋',
                  key: const Key('home_greeting'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(height: 5),
              const Text('Ringkasan hari ini dari pembukuan FOSTIFEST.',
                  key: Key('home_subtitle'), style: TextStyle(color: _ink)),
            ]),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 2,
            child: Container(
              key: const Key('home_summary_card'),
              height: 112,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A252525),
                      blurRadius: 20,
                      offset: Offset(0, 9))
                ],
              ),
              child: Row(children: [
                const Icon(Icons.storefront_rounded, size: 34, color: _ink),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usaha bulan ini',
                        style: TextStyle(fontSize: 12, color: _muted)),
                    Text(formatRupiah(revenue),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _ink)),
                    Text('$transactionCount transaksi tercatat',
                        style: const TextStyle(fontSize: 11, color: _muted)),
                  ],
                )),
                const Icon(Icons.trending_up_rounded, color: _deepGold),
              ]),
            ),
          ),
        ]),
      );
}

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key,
      required this.profile,
      required this.items,
      required this.revenue,
      required this.transactionCount,
      required this.onAdd,
      required this.onInsight,
      required this.onProfile});
  final int revenue;
  final BusinessProfile profile;
  final List<TransactionItem> items;
  final int transactionCount;
  final VoidCallback onAdd;
  final VoidCallback onInsight;
  final VoidCallback onProfile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _periodDays = 30;

  List<TransactionItem> get _periodItems {
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays));
    return widget.items.where((item) => !item.date.isBefore(cutoff)).toList();
  }

  List<MapEntry<String, int>> get _topProducts {
    final totals = <String, int>{};
    for (final item in _periodItems) {
      totals[item.name] = (totals[item.name] ?? 0) + item.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _HomeHero(
              profile: widget.profile,
              revenue: widget.revenue,
              transactionCount: widget.transactionCount,
              onProfile: widget.onProfile),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  MetricCard(
                      label: 'OMZET BULAN INI',
                      value: formatRupiah(widget.revenue),
                      note: '${widget.transactionCount} transaksi',
                      accent: _deepGold),
                  const SizedBox(width: 12),
                  const MetricCard(
                      label: 'LABA BERSIH',
                      value: 'Rp 635.000',
                      note: 'Naik 12% dari bulan lalu',
                      accent: _deepGold),
                  const SizedBox(width: 12),
                  const MetricCard(
                      label: 'SKOR KESIAPAN',
                      value: '72 / 100',
                      note: 'Naik 5 poin minggu ini',
                      accent: _deepGold),
                ]),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Catat transaksi sekarang'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _brandYellow,
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)))),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 0,
              color: _cream,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onInsight,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: _brandYellow,
                            borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.insights_rounded, color: _ink)),
                    const SizedBox(width: 13),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Arah usaha minggu ini',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, color: _ink)),
                          SizedBox(height: 3),
                          Text('Lengkapi NIB untuk menaikkan skor kesiapanmu.',
                              style: TextStyle(fontSize: 13, color: _ink)),
                        ])),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            ),
          ),
          const SectionTitle(title: 'Langkah paling berdampak'),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ActionCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Lengkapi legalitas usaha',
                  subtitle: 'NIB dapat menambah 10 poin kesiapan.',
                  action: 'Mulai')),
          const SizedBox(height: 10),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ActionCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Catat transaksi selama 7 hari',
                  subtitle: 'Konsistensi membuat insight makin akurat.',
                  action: 'Lihat')),
          const SectionTitle(title: 'Tren omzet'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _RevenueTrendCard(
              items: _periodItems,
              selectedDays: _periodDays,
              onChanged: (days) => setState(() => _periodDays = days),
            ),
          ),
          const SectionTitle(title: 'Produk terlaris'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TopProductsCard(products: _topProducts),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.verified_user_outlined, color: _deepGold),
                const SizedBox(width: 12),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Kelengkapan legalitas',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: _ink)),
                      Text('2/3 dokumen lengkap',
                          style: TextStyle(color: _ink, fontSize: 12)),
                    ])),
                TextButton(
                    onPressed: widget.onInsight,
                    child: const Text('Lengkapi',
                        style: TextStyle(
                            color: _ink, fontWeight: FontWeight.w900))),
              ]),
            ),
          ),
        ],
      );
}

class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard(
      {required this.items,
      required this.selectedDays,
      required this.onChanged});
  final List<TransactionItem> items;
  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final buckets = List<int>.filled(4, 0);
    final now = DateTime.now();
    for (final item in items) {
      final age = now.difference(item.date).inDays.clamp(0, selectedDays - 1);
      final index = 3 - ((age * 4) ~/ selectedDays).clamp(0, 3);
      buckets[index] += item.amount;
    }
    final maxValue = math.max(1, buckets.reduce(math.max));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: const {
              7: '1 Minggu',
              21: '3 Minggu',
              30: '1 Bulan',
              90: '3 Bulan'
            }
                .entries
                .map((entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: selectedDays == entry.key,
                      onSelected: (_) => onChanged(entry.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                  4,
                  (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                    buckets[index] == 0
                                        ? ''
                                        : formatCompactRupiah(buckets[index]),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: math.max(
                                      5, 105 * buckets[index] / maxValue),
                                  decoration: BoxDecoration(
                                      color: _brandYellow,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(8))),
                                ),
                                const SizedBox(height: 5),
                                Text('P${index + 1}',
                                    style: const TextStyle(
                                        fontSize: 10, color: _muted)),
                              ]),
                        ),
                      )),
            ),
          ),
          const SizedBox(height: 12),
          Text('${items.length} transaksi dalam periode ini',
              style: const TextStyle(color: _muted, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});
  final List<MapEntry<String, int>> products;
  @override
  Widget build(BuildContext context) => Card(
      child: products.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Belum ada transaksi pada periode ini.',
                  style: TextStyle(color: _muted)))
          : Column(
              children: List.generate(products.length, (index) {
              final product = products[index];
              return Column(children: [
                ListTile(
                  leading: CircleAvatar(
                      backgroundColor: _cream,
                      foregroundColor: _deepGold,
                      child: Text('${index + 1}')),
                  title: Text(product.key,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: Text(formatRupiah(product.value),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (index < products.length - 1)
                  const Divider(height: 1, color: _divider),
              ]);
            })));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage(
      {super.key,
      required this.profile,
      required this.onSave,
      required this.darkMode,
      required this.onDarkModeChanged,
      required this.onLogout});

  final BusinessProfile profile;
  final Future<void> Function(BusinessProfile) onSave;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push<BusinessProfile>(
      MaterialPageRoute(
          builder: (_) => EditBusinessProfilePage(profile: profile)),
    );
    if (updated == null) return;
    await onSave(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil usaha berhasil disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 108),
        children: [
          Text('Profil usaha',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Kelola identitas dan kesiapan usahamu.',
              style: TextStyle(color: _muted)),
          const SizedBox(height: 22),
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _brandYellow, width: 4),
                image: DecorationImage(
                  image: _businessPhoto(profile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(profile.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(profile.description,
              textAlign: TextAlign.center, style: TextStyle(color: _muted)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  _ProfileRow(
                      icon: Icons.storefront_outlined,
                      label: 'Nama usaha',
                      value: profile.name),
                  const Divider(color: _divider, height: 26),
                  _ProfileRow(
                      icon: Icons.location_on_outlined,
                      label: 'Lokasi usaha',
                      value: profile.location),
                  const Divider(color: _divider, height: 26),
                  _ProfileRow(
                      icon: Icons.category_outlined,
                      label: 'Kategori',
                      value: profile.category),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _edit(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _brandYellow,
              foregroundColor: _ink,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profil usaha'),
          ),
          const SizedBox(height: 20),
          const Text('PENGATURAN',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _muted,
                  letterSpacing: .7)),
          const SizedBox(height: 10),
          Card(
              child: Column(children: [
            const ListTile(
                leading: Icon(Icons.help_outline_rounded),
                title: Text('Panduan FOSTIFEST'),
                trailing: Icon(Icons.chevron_right_rounded)),
            const Divider(color: _divider, height: 1),
            const ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Privasi dan data usaha'),
                trailing: Icon(Icons.chevron_right_rounded)),
            const Divider(color: _divider, height: 1),
            SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Mode gelap'),
                value: darkMode,
                activeThumbColor: _brandYellow,
                onChanged: onDarkModeChanged),
            const Divider(color: _divider, height: 1),
            ListTile(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const AboutFostifestPage())),
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Tentang FOSTIFEST'),
                trailing: const Icon(Icons.chevron_right_rounded)),
            const Divider(color: _divider, height: 1),
            ListTile(
                onTap: onLogout,
                leading: const Icon(Icons.logout_rounded, color: _error),
                title: const Text('Keluar',
                    style:
                        TextStyle(color: _error, fontWeight: FontWeight.w800)),
                trailing: const Icon(Icons.chevron_right_rounded)),
          ])),
        ],
      );
}

class AboutFostifestPage extends StatelessWidget {
  const AboutFostifestPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tentang FOSTIFEST')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: const [
          Text('FOSTIFEST',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _deepGold,
                  letterSpacing: 2)),
          SizedBox(height: 4),
          Text('Kenali usahamu, tentukan arah.',
              style: TextStyle(fontStyle: FontStyle.italic, color: _muted)),
          SizedBox(height: 24),
          Text(
              'FOSTIFEST membantu pelaku UMKM mengubah bukti penjualan, foto struk, dan catatan manual menjadi pembukuan yang terstruktur. Data tersebut dipakai untuk membaca tren usaha, menghitung kesiapan, dan menyiapkan dokumen pendukung pembiayaan.',
              style: TextStyle(height: 1.55)),
          SizedBox(height: 18),
          Card(
              color: _cream,
              child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                      'Hasil OCR, skor, dan simulasi merupakan alat bantu. Pengguna tetap dapat memeriksa serta memperbaiki data sebelum digunakan.',
                      style: TextStyle(height: 1.45, color: _ink)))),
          SizedBox(height: 22),
          Text('Yang FOSTIFEST lakukan:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          SizedBox(height: 12),
          _AboutPoint(
              text:
                  'Mencatat penjualan manual, dari chat, atau foto bukti transaksi.'),
          _AboutPoint(text: 'Membaca tren omzet dan produk terlaris.'),
          _AboutPoint(text: 'Menghitung skor kelayakan dan simulasi KUR.'),
          _AboutPoint(
              text: 'Menyusun laporan laba rugi dan paket dokumen PDF.'),
          SizedBox(height: 20),
          Text('Versi 1.5.0', style: TextStyle(color: _muted)),
        ])),
      );
}

class _AboutPoint extends StatelessWidget {
  const _AboutPoint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 7, color: _deepGold)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4)))
      ]));
}

class EditBusinessProfilePage extends StatefulWidget {
  const EditBusinessProfilePage({super.key, required this.profile});
  final BusinessProfile profile;

  @override
  State<EditBusinessProfilePage> createState() =>
      _EditBusinessProfilePageState();
}

class _EditBusinessProfilePageState extends State<EditBusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _category;
  String? _photoPath;
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _description = TextEditingController(text: widget.profile.description);
    _location = TextEditingController(text: widget.profile.location);
    _category = TextEditingController(text: widget.profile.category);
    _photoPath = widget.profile.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    setState(() => _pickingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final suffix = picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path =
          '${directory.path}/business-avatar-${DateTime.now().millisecondsSinceEpoch}.$suffix';
      await File(picked.path).copy(path);
      if (mounted) setState(() => _photoPath = path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto belum bisa dipilih. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(BusinessProfile(
      name: _name.text.trim(),
      description: _description.text.trim(),
      location: _location.text.trim(),
      category: _category.text.trim(),
      photoPath: _photoPath,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit profil usaha')),
        body: SafeArea(
            child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
                child: CircleAvatar(
              radius: 51,
              backgroundImage:
                  _businessPhoto(BusinessProfile(photoPath: _photoPath)),
            )),
            const SizedBox(height: 8),
            Center(
                child: TextButton.icon(
              onPressed: _pickingPhoto ? null : _choosePhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_pickingPhoto ? 'Memilih foto…' : 'Ganti foto usaha'),
            )),
            const SizedBox(height: 20),
            TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama usaha'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama usaha wajib diisi'
                    : null),
            const SizedBox(height: 14),
            TextFormField(
                controller: _description,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi singkat')),
            const SizedBox(height: 14),
            TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Lokasi usaha')),
            const SizedBox(height: 14),
            TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Kategori usaha')),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan profil'),
              style: FilledButton.styleFrom(
                backgroundColor: _brandYellow,
                foregroundColor: _ink,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ]),
        )),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              const BoxDecoration(color: _cream, shape: BoxShape.circle),
          child: Icon(icon, color: _ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      ]);
}

class LedgerPage extends StatefulWidget {
  const LedgerPage({
    super.key,
    required this.profile,
    required this.items,
    required this.onAdd,
  });
  final BusinessProfile profile;
  final List<TransactionItem> items;
  final VoidCallback onAdd;

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  int _tab = 0;
  int _reportTab = 1;
  late DateTime _month;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  List<TransactionItem> get _monthlyItems => widget.items
      .where((item) =>
          item.date.year == _month.year && item.date.month == _month.month)
      .toList();
  int get _income => _monthlyItems.fold(0, (sum, item) => sum + item.amount);
  int get _expense => 0;
  int get _tax => (_income * .005).round();

  void _changeMonth(int direction) {
    setState(() {
      _month = DateTime(_month.year, _month.month + direction);
      final now = DateTime.now();
      _selectedDate = now.year == _month.year && now.month == _month.month
          ? DateTime(now.year, now.month, now.day)
          : DateTime(_month.year, _month.month);
    });
  }

  Future<void> _shareFinancePdf() async {
    final document = pw.Document();
    document.addPage(pw.MultiPage(
        build: (context) => [
              pw.Header(level: 0, child: pw.Text('FOSTIFEST — Laporan Laba Rugi')),
              pw.Paragraph(text: 'Usaha: ${widget.profile.name}'),
              pw.Paragraph(text: 'Periode: ${formatMonthYear(_month)}'),
              pw.SizedBox(height: 8),
              pw.Text('Rincian pendapatan',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (_monthlyItems.isEmpty)
                pw.Paragraph(
                    text: 'Belum ada transaksi tercatat pada periode ini.')
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Tanggal', 'Produk', 'Sumber', 'Nominal'],
                  data: _monthlyItems
                      .map((item) => [
                            formatDate(item.date),
                            item.name,
                            item.source,
                            formatRupiah(item.amount)
                          ])
                      .toList(),
                ),
              pw.SizedBox(height: 14),
              pw.Text('Ringkasan laba rugi',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Total pendapatan: ${formatRupiah(_income)}'),
              pw.Bullet(text: 'Total beban: ${formatRupiah(_expense)}'),
              pw.Bullet(
                  text: 'Laba bersih: ${formatRupiah(_income - _expense)}'),
              pw.Bullet(text: 'Estimasi PPh final 0,5%: ${formatRupiah(_tax)}'),
              pw.SizedBox(height: 12),
              pw.Text(
                  'Laporan ini merupakan rangkuman pencatatan internal FOSTIFEST dan bukan laporan yang diaudit.'),
            ]));
    await Printing.sharePdf(
      bytes: await document.save(),
      filename:
          'laporan-laba-rugi-${_month.year}-${_month.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Catatan keuangan',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  const Text('Transaksi dan laporan usaha dalam satu tempat.',
                      style: TextStyle(color: _muted)),
                ])),
            IconButton(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_circle, color: _gold, size: 31)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  label: Text('Transaksi'),
                  icon: Icon(Icons.receipt_long_outlined)),
              ButtonSegment(
                  value: 1,
                  label: Text('Kalender'),
                  icon: Icon(Icons.calendar_month_outlined)),
              ButtonSegment(
                  value: 2,
                  label: Text('Laporan'),
                  icon: Icon(Icons.description_outlined)),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
            child: switch (_tab) {
          0 => _buildTransactions(),
          1 => _buildCalendar(),
          _ => _buildReport(),
        }),
      ]);

  Widget _buildTransactions() => ListView(
        key: const Key('finance_transactions_page'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          _MonthPicker(
              month: _month,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1)),
          const SizedBox(height: 14),
          if (_monthlyItems.isEmpty)
            const _EmptyMonth(message: 'Belum ada transaksi pada bulan ini.')
          else
            ..._monthlyItems.map((item) => Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                        backgroundColor: _cream,
                        child: Icon(
                            item.source == 'Scan struk'
                                ? Icons.document_scanner_outlined
                                : Icons.shopping_bag_outlined,
                            color: _ink)),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${formatDate(item.date)} · ${item.source}'),
                    trailing: Text(formatRupiah(item.amount),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                )),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Catat transaksi baru'),
              style: FilledButton.styleFrom(
                  backgroundColor: _brandYellow,
                  foregroundColor: _ink,
                  minimumSize: const Size.fromHeight(52))),
        ],
      );

  Widget _buildCalendar() {
    final selectedItems = _monthlyItems
        .where((item) =>
            item.date.year == _selectedDate.year &&
            item.date.month == _selectedDate.month &&
            item.date.day == _selectedDate.day)
        .toList();
    final selectedIncome =
        selectedItems.fold<int>(0, (sum, item) => sum + item.amount);

    return ListView(
      key: const Key('finance_calendar_page'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        _MonthPicker(
            month: _month,
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1)),
        const SizedBox(height: 10),
        _FinanceCalendar(
          month: _month,
          items: _monthlyItems,
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 16),
        Text('Catatan ${formatDate(_selectedDate)}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child: _CalendarTotal(
                      label: 'Pemasukan',
                      value: selectedIncome,
                      color: const Color(0xFF2E7D32))),
              Container(width: 1, height: 42, color: _divider),
              const Expanded(
                  child: _CalendarTotal(
                      label: 'Pengeluaran', value: 0, color: _error)),
              Container(width: 1, height: 42, color: _divider),
              Expanded(
                  child: _CalendarTotal(
                      label: 'Saldo', value: selectedIncome, color: _deepGold)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedItems.isEmpty)
          const _EmptyMonth(message: 'Belum ada transaksi pada tanggal ini.')
        else
          ...selectedItems.map((item) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: _cream,
                      child: Icon(Icons.arrow_downward_rounded,
                          color: Color(0xFF2E7D32))),
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(item.source),
                  trailing: Text('+${formatRupiah(item.amount)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E7D32))),
                ),
              )),
        const SizedBox(height: 14),
        FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Catat transaksi pada tanggal ini'),
            style: FilledButton.styleFrom(
                backgroundColor: _brandYellow,
                foregroundColor: _ink,
                minimumSize: const Size.fromHeight(52))),
      ],
    );
  }

  Widget _buildReport() => ListView(
        key: const Key('finance_report_page'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          _MonthPicker(
              month: _month,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1)),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Pengeluaran')),
              ButtonSegment(value: 1, label: Text('Laba Rugi')),
            ],
            selected: {_reportTab},
            onSelectionChanged: (value) =>
                setState(() => _reportTab = value.first),
          ),
          const SizedBox(height: 18),
          if (_reportTab == 0) ...[
            const Text('Rincian beban usaha',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const _EmptyMonth(message: 'Belum ada pengeluaran pada bulan ini.'),
            const SizedBox(height: 10),
            _ReportTotal(label: 'Total beban', value: _expense, negative: true),
          ] else ...[
            const Text('Rincian pendapatan (penjualan)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (_monthlyItems.isEmpty)
              const _EmptyMonth(message: 'Belum ada penjualan pada bulan ini.')
            else
              ..._monthlyItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text('${formatDate(item.date)} · ${item.source}',
                                style: const TextStyle(
                                    color: _muted, fontSize: 12))
                          ])),
                      Text(formatRupiah(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  )),
            _ReportTotal(label: 'Total pendapatan', value: _income),
            const SizedBox(height: 18),
            const Text('Rincian beban usaha',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const _EmptyMonth(message: 'Belum ada pengeluaran pada bulan ini.'),
            _ReportTotal(label: 'Total beban', value: _expense, negative: true),
            const SizedBox(height: 18),
            const Text('Ringkasan laba rugi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _ProfitSummary(income: _income, expense: _expense),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _cream, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  const Icon(Icons.receipt_long_outlined, color: _deepGold),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Estimasi PPh Final (0,5%)',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(formatRupiah(_tax),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _deepGold))
                      ]))
                ])),
            const SizedBox(height: 9),
            const Text(
                'Estimasi dari omzet bulan ini untuk UMKM. Bukan pengganti perhitungan pajak atau pelaporan resmi.',
                style: TextStyle(fontSize: 12, color: _muted, height: 1.35)),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
              onPressed: _shareFinancePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Unduh / bagikan PDF'),
              style: FilledButton.styleFrom(
                  backgroundColor: _brandYellow,
                  foregroundColor: _ink,
                  minimumSize: const Size.fromHeight(54))),
          const SizedBox(height: 9),
          const Text(
              'Format merangkum pendapatan, beban, laba rugi, dan estimasi pajak dari catatan FOSTIFEST.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.35)),
        ],
      );
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker(
      {required this.month, required this.onPrevious, required this.onNext});
  final DateTime month;
  final VoidCallback onPrevious, onNext;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded)),
        SizedBox(
            width: 170,
            child: Text(formatMonthYear(month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 17))),
        IconButton(
            onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
      ]);
}

class _FinanceCalendar extends StatelessWidget {
  const _FinanceCalendar({
    required this.month,
    required this.items,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime month;
  final List<TransactionItem> items;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final leadingCells = first.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((leadingCells + days + 6) ~/ 7) * 7;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child: Column(children: [
          Row(
              children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                  .map((day) => Expanded(
                      child: Text(day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800))))
                  .toList()),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: .82),
            itemBuilder: (context, index) {
              final day = index - leadingCells + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              final total = items
                  .where((item) => item.date.day == day)
                  .fold<int>(0, (sum, item) => sum + item.amount);
              final selected = selectedDate.year == date.year &&
                  selectedDate.month == date.month &&
                  selectedDate.day == date.day;
              return Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  key: Key('calendar_day_$day'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelected(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? _brandYellow
                          : total > 0
                              ? (isDark
                                  ? const Color(0xFF3A3213)
                                  : const Color(0xFFFFF7D7))
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? _gold : _divider, width: 1),
                    ),
                    child: Column(children: [
                      Text('$day',
                          style: TextStyle(
                              fontWeight: selected || total > 0
                                  ? FontWeight.w900
                                  : FontWeight.w500,
                              color: selected ? _ink : null)),
                      const Spacer(),
                      if (total > 0)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle),
                        ),
                    ]),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
            SizedBox(width: 6),
            Text('Tanggal dengan transaksi',
                style: TextStyle(fontSize: 11, color: _muted)),
          ]),
        ]),
      ),
    );
  }
}

class _CalendarTotal extends StatelessWidget {
  const _CalendarTotal(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _muted)),
        const SizedBox(height: 5),
        Text(formatCompactRupiah(value),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: color)),
      ]);
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _warmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider)),
      child: Text(message, style: const TextStyle(color: _muted)));
}

class _ReportTotal extends StatelessWidget {
  const _ReportTotal(
      {required this.label, required this.value, this.negative = false});
  final String label;
  final int value;
  final bool negative;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(negative ? '(${formatRupiah(value)})' : formatRupiah(value),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: negative ? _error : _deepGold))
      ]));
}

class _ProfitSummary extends StatelessWidget {
  const _ProfitSummary({required this.income, required this.expense});
  final int income, expense;
  @override
  Widget build(BuildContext context) => Card(
          child: Column(children: [
        _SummaryRow(label: 'Total pendapatan', value: formatRupiah(income)),
        const Divider(height: 1, color: _divider),
        _SummaryRow(label: 'Total beban', value: '(${formatRupiah(expense)})'),
        const Divider(height: 1, color: _divider),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: _cream,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LABA BERSIH',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  Text(formatRupiah(income - expense),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _deepGold))
                ])),
      ]));
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
      ]));
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, required this.onSave});
  final ValueChanged<TransactionItem> onSave;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  int _mode = 0;
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _customer = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _ocr = TextRecognizer(script: TextRecognitionScript.latin);
  DateTime _date = DateTime.now();
  String _unit = 'pcs';
  String _payment = 'Lunas';
  XFile? _receipt;
  String? _ocrRawText;
  bool _readingReceipt = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _customer.dispose();
    _quantity.dispose();
    _ocr.close();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2048,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _receipt = picked;
        _ocrRawText = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kamera atau galeri belum bisa dibuka. Coba lagi.')));
      }
    }
  }

  Future<void> _showReceiptSource() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Pilih foto bukti pembayaran',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: _cream,
                  child: Icon(Icons.camera_alt_outlined, color: _ink)),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto struk atau bukti transfer'),
              onTap: () {
                Navigator.pop(context);
                _pickReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: _cream,
                  child: Icon(Icons.photo_library_outlined, color: _ink)),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih foto yang sudah ada'),
              onTap: () {
                Navigator.pop(context);
                _pickReceipt(ImageSource.gallery);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _readReceipt() async {
    if (_receipt == null) return;
    setState(() => _readingReceipt = true);
    try {
      final result =
          await _ocr.processImage(InputImage.fromFilePath(_receipt!.path));
      final raw = result.text.trim();
      final lines = raw
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final numericValues = RegExp(
              r'(?<!\d)(?:Rp\.?\s*)?\d{1,3}(?:[.,]\d{3})+(?!\d)|(?<!\d)\d{4,}(?!\d)',
              caseSensitive: false)
          .allMatches(raw)
          .map((match) => match.group(0)!.replaceAll(RegExp(r'[^0-9]'), ''))
          .map(int.tryParse)
          .whereType<int>();
      if (!mounted) return;
      setState(() {
        _ocrRawText = raw.isEmpty
            ? 'Teks tidak terbaca. Isi transaksi secara manual.'
            : raw;
        if (lines.isNotEmpty && _name.text.trim().isEmpty) {
          _name.text = lines.first.trim();
        }
        if (numericValues.isNotEmpty) {
          _amount.text =
              numericValues.reduce((a, b) => a > b ? a : b).toString();
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Teks pada foto belum bisa dibaca. Kamu tetap bisa mengisi data manual.')));
      }
    } finally {
      if (mounted) setState(() => _readingReceipt = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (_name.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Isi nama produk dan nominal transaksi.')));
      return;
    }
    widget.onSave(TransactionItem(
        name: _name.text.trim(),
        amount: amount,
        date: _date,
        source: _mode == 0
            ? 'Manual'
            : _mode == 1
                ? 'Tempel chat'
                : 'Scan struk'));
    _name.clear();
    _amount.clear();
    _customer.clear();
    _quantity.text = '1';
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi tersimpan ke pembukuan.')));
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), children: [
        const Text('Catat transaksi',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        const SizedBox(height: 4),
        const Text('Pilih cara yang paling nyaman untuk usaha kamu.',
            style: TextStyle(color: _muted)),
        const SizedBox(height: 16),
        SegmentedButton<int>(segments: const [
          ButtonSegment(
              value: 0, label: Text('Manual'), icon: Icon(Icons.edit_outlined)),
          ButtonSegment(
              value: 1,
              label: Text('Chat'),
              icon: Icon(Icons.chat_bubble_outline)),
          ButtonSegment(
              value: 2,
              label: Text('Struk'),
              icon: Icon(Icons.document_scanner_outlined))
        ], selected: {
          _mode
        }, onSelectionChanged: (value) => setState(() => _mode = value.first)),
        const SizedBox(height: 20),
        if (_mode == 2) ...[
          const _ReceiptScanIntro(),
          const SizedBox(height: 16),
          _ReceiptPicker(
            receipt: _receipt,
            reading: _readingReceipt,
            onPick: _showReceiptSource,
            onRead: _readReceipt,
          ),
          if (_ocrRawText != null) ...[
            const SizedBox(height: 18),
            _OcrResultHeader(rawText: _ocrRawText!),
          ],
          const SizedBox(height: 18),
        ],
        if (_mode == 1)
          const Card(
              color: _cream,
              elevation: 0,
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Tempel chat penjualan untuk diparsing. Pada versi awal, konfirmasi nama produk dan nominalnya di bawah.'))),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Tanggal'),
            child: Row(children: [
              Expanded(child: Text(formatDate(_date))),
              const Icon(Icons.calendar_today_outlined,
                  size: 19, color: _muted),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Nama produk atau keterangan',
                hintText: 'Contoh: Batik motif Sekar',
                border: OutlineInputBorder())),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: const ['pcs', 'set', 'meter', 'kg']
                  .map((unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit)))
                  .toList(),
              onChanged: (value) => setState(() => _unit = value ?? 'pcs'),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Total transaksi',
                prefixText: 'Rp ',
                hintText: '480000',
                border: OutlineInputBorder())),
        const SizedBox(height: 14),
        TextField(
          controller: _customer,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(labelText: 'Nama pelanggan (opsional)'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _payment,
          decoration: const InputDecoration(labelText: 'Status pembayaran'),
          items: const ['Lunas', 'Belum lunas']
              .map((status) =>
                  DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) => setState(() => _payment = value ?? 'Lunas'),
        ),
        const SizedBox(height: 10),
        if (_ocrRawText != null)
          TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Teks hasil OCR'),
                content: SingleChildScrollView(child: Text(_ocrRawText!)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'))
                ],
              ),
            ),
            icon: const Icon(Icons.text_snippet_outlined),
            label: const Text('Lihat teks hasil OCR mentah'),
          ),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _brandYellow,
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: const Text('Simpan transaksi')),
      ]);
}

class _ReceiptScanIntro extends StatelessWidget {
  const _ReceiptScanIntro();

  @override
  Widget build(BuildContext context) => const Card(
        color: _cream,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: _ink),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unggah bukti pembayaran masuk atau struk penjualan. Periksa hasil pembacaan sebelum menyimpan transaksi.',
                style: TextStyle(height: 1.4),
              ),
            ),
          ]),
        ),
      );
}

class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker(
      {required this.receipt,
      required this.reading,
      required this.onPick,
      required this.onRead});
  final XFile? receipt;
  final bool reading;
  final VoidCallback onPick;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) => Column(children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 190,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _divider),
            ),
            child: receipt == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 48, color: _muted),
                        SizedBox(height: 8),
                        Text('Pilih foto bukti pembayaran',
                            style: TextStyle(color: _muted)),
                      ])
                : Image.file(File(receipt!.path), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(receipt == null
                  ? Icons.camera_alt_outlined
                  : Icons.refresh_rounded),
              label: Text(receipt == null ? 'Kamera / Galeri' : 'Ganti foto'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
          ),
          if (receipt != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: reading ? null : onRead,
                icon: reading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _ink))
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(reading ? 'Membaca…' : 'Proses OCR'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _brandYellow,
                  foregroundColor: _ink,
                ),
              ),
            ),
          ],
        ]),
      ]);
}

class _OcrResultHeader extends StatelessWidget {
  const _OcrResultHeader({required this.rawText});
  final String rawText;

  @override
  Widget build(BuildContext context) => Card(
        color: _warmWhite,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: _deepGold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rawText.startsWith('Teks tidak')
                    ? 'OCR belum menemukan teks. Lengkapi form secara manual.'
                    : 'Hasil OCR sudah dimasukkan ke form. Periksa kembali sebelum menyimpan.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
      );
}

class EligibilityPage extends StatefulWidget {
  const EligibilityPage({
    super.key,
    required this.profile,
    required this.revenue,
    required this.transactionCount,
    required this.onAdd,
  });
  final BusinessProfile profile;
  final int revenue;
  final int transactionCount;
  final VoidCallback onAdd;

  @override
  State<EligibilityPage> createState() => _EligibilityPageState();
}

class _EligibilityPageState extends State<EligibilityPage> {
  int _tab = 0;
  int _months = 24;
  bool _nib = true;
  bool _brand = true;
  bool _halal = false;

  int get _legalCount => [_nib, _brand, _halal].where((value) => value).length;
  int get _consistency => (widget.transactionCount * 18).clamp(18, 90);
  int get _volume => (widget.revenue ~/ 20000).clamp(20, 95);
  int get _legalScore => (_legalCount * 33).clamp(0, 100);
  int get _score =>
      ((_consistency * .38) + (_volume * .34) + (_legalScore * .28)).round();
  int get _averageMonthlyRevenue => math.max(1, widget.revenue ~/ 6);
  int get _loanLimit =>
      math.max(500000, math.min(20000000, _averageMonthlyRevenue * 3));

  int get _monthlyInstallment {
    const monthlyRate = .06 / 12;
    final factor = math.pow(1 + monthlyRate, _months);
    return (_loanLimit * monthlyRate * factor / (factor - 1)).round();
  }

  Future<void> _shareDocumentPackage() async {
    final document = pw.Document();
    document.addPage(pw.MultiPage(
        build: (context) => [
              pw.Header(
                  level: 0, child: pw.Text('FOSTIFEST — Paket Kelayakan Usaha')),
              pw.Paragraph(text: 'Usaha: ${widget.profile.name}'),
              pw.Paragraph(text: 'Kategori: ${widget.profile.category}'),
              pw.Paragraph(
                  text: 'Omzet tercatat: ${formatRupiah(widget.revenue)}'),
              pw.Paragraph(
                  text: 'Transaksi tercatat: ${widget.transactionCount}'),
              pw.Paragraph(text: 'Skor kelayakan FOSTIFEST: $_score / 100'),
              pw.Paragraph(
                  text: 'Estimasi plafon: ${formatRupiah(_loanLimit)}'),
              pw.Paragraph(text: 'Tenor simulasi: $_months bulan'),
              pw.Paragraph(
                  text:
                      'Estimasi cicilan: ${formatRupiah(_monthlyInstallment)} per bulan'),
              pw.SizedBox(height: 12),
              pw.Text('Checklist legalitas',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'NIB: ${_nib ? 'Lengkap' : 'Belum ada'}'),
              pw.Bullet(
                  text: 'P-IRT / Merek: ${_brand ? 'Lengkap' : 'Belum ada'}'),
              pw.Bullet(
                  text:
                      'Sertifikasi Halal: ${_halal ? 'Lengkap' : 'Belum ada'}'),
              pw.SizedBox(height: 12),
              pw.Text(
                  'Dokumen ini adalah rangkuman pencatatan internal FOSTIFEST, bukan persetujuan kredit dari lembaga keuangan.'),
            ]));
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'paket-kelayakan-fostifest.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kelayakan usaha',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    const Text('Skor dan kesiapan akses pembiayaan.',
                        style: TextStyle(color: _muted)),
                  ]),
            ),
            const Icon(Icons.verified_user_outlined, color: _deepGold),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  label: Text('Skor'),
                  icon: Icon(Icons.donut_large_outlined)),
              ButtonSegment(
                  value: 1,
                  label: Text('KUR'),
                  icon: Icon(Icons.account_balance_outlined)),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _tab == 0 ? _buildScore() : _buildKur(),
        ),
      ]);

  Widget _buildScore() => ListView(
        key: const Key('eligibility_score_page'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(child: _ScoreRing(score: _score)),
          const SizedBox(height: 12),
          Center(child: _ScorePill(score: _score)),
          const SizedBox(height: 20),
          Card(
            color: _cream,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Skor $_score/100 dihitung dari konsistensi pencatatan, volume penjualan, dan legalitas yang kamu isi. Tambahkan catatan transaksi dan lengkapi dokumen untuk menaikkan kesiapan.',
                style: const TextStyle(height: 1.45),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Rincian faktor skor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FactorTile(
              label: 'Konsistensi transaksi',
              value: _consistency,
              color: _brandYellow),
          FactorTile(label: 'Volume penjualan', value: _volume, color: _gold),
          FactorTile(
              label: 'Legalitas usaha', value: _legalScore, color: _deepGold),
          const SizedBox(height: 4),
          OutlinedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Catat transaksi untuk menaikkan skor')),
        ],
      );

  Widget _buildKur() => ListView(
        key: const Key('eligibility_kur_page'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.profile.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              _KurMetric(
                  label: 'Omzet tercatat', value: formatRupiah(widget.revenue)),
              _KurMetric(
                  label: 'Rata-rata / bulan',
                  value: formatRupiah(_averageMonthlyRevenue)),
              _KurMetric(
                  label: 'Total transaksi',
                  value: '${widget.transactionCount}'),
              _KurMetric(
                  label: 'Skor kelayakan saat ini', value: '$_score / 100'),
            ]),
          )),
          const SizedBox(height: 16),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SIMULASI PLAFON',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900,
                      color: _muted)),
              const SizedBox(height: 5),
              Text(formatRupiah(_loanLimit),
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                  children: [12, 24, 36]
                      .map((months) => Expanded(
                              child: Padding(
                            padding:
                                EdgeInsets.only(right: months == 36 ? 0 : 8),
                            child: ChoiceChip(
                                label: Text('$months bln'),
                                selected: _months == months,
                                onSelected: (_) =>
                                    setState(() => _months = months)),
                          )))
                      .toList()),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: _cream, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('Estimasi cicilan per bulan',
                      style: TextStyle(color: _muted)),
                  const SizedBox(height: 5),
                  Text(formatRupiah(_monthlyInstallment),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _deepGold)),
                ]),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Simulasi memakai asumsi bunga efektif 6% per tahun. Nilai akhir mengikuti kebijakan penyalur KUR.',
                  style: TextStyle(fontSize: 12, color: _muted, height: 1.35)),
            ]),
          )),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _shareDocumentPackage,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Buat & bagikan paket dokumen (PDF)'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _brandYellow,
                foregroundColor: _ink),
          ),
          const SizedBox(height: 26),
          const Text('Jalur legalitas usaha',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Centang dokumen yang sudah kamu punya. Ini catatan internal FOSTIFEST, bukan verifikasi resmi.',
              style: TextStyle(color: _muted, height: 1.35)),
          const SizedBox(height: 12),
          _LegalTile(
              label: 'NIB (Nomor Induk Berusaha)',
              complete: _nib,
              onChanged: (value) => setState(() => _nib = value)),
          const SizedBox(height: 10),
          _LegalTile(
              label: 'P-IRT / Merek',
              complete: _brand,
              onChanged: (value) => setState(() => _brand = value)),
          const SizedBox(height: 10),
          _LegalTile(
              label: 'Sertifikasi Halal',
              complete: _halal,
              onChanged: (value) => setState(() => _halal = value)),
          TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Panduan legalitas disiapkan di pembaruan berikutnya.'))),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Lihat panduan singkat')),
        ],
      );
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 186,
      height: 186,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 16,
            backgroundColor: _cream,
            color: _gold),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$score',
              style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w900, color: _ink)),
          const Text('DARI 100',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800, color: _muted)),
        ]),
      ]));
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
            color: _cream, borderRadius: BorderRadius.circular(20)),
        child: Text(score >= 70 ? 'Siap berkembang' : 'Perlu peningkatan',
            style:
                const TextStyle(fontWeight: FontWeight.w800, color: _deepGold)),
      );
}

class _KurMetric extends StatelessWidget {
  const _KurMetric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: _muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
        ]),
      );
}

class _LegalTile extends StatelessWidget {
  const _LegalTile(
      {required this.label, required this.complete, required this.onChanged});
  final String label;
  final bool complete;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Card(
          child: CheckboxListTile(
        value: complete,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: _brandYellow,
        checkColor: _ink,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        secondary: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
              color: complete ? const Color(0xFFE5F5E9) : _cream,
              borderRadius: BorderRadius.circular(12)),
          child: Text(complete ? 'Lengkap' : 'Belum punya',
              style: TextStyle(
                  fontSize: 11,
                  color: complete ? const Color(0xFF347347) : _deepGold,
                  fontWeight: FontWeight.w700)),
        ),
      ));
}

class FostiPage extends StatefulWidget {
  const FostiPage(
      {super.key, required this.revenue, required this.transactionCount});
  final int revenue;
  final int transactionCount;
  @override
  State<FostiPage> createState() => _FostiPageState();
}

class _FostiPageState extends State<FostiPage> {
  final _input = TextEditingController();
  final List<_Chat> _messages = [
    _Chat(false,
        'Halo, aku Fosti. Aku bisa membantu membaca kondisi usahamu dari data FOSTIFEST. Kamu mau bahas omzet, skor kesiapan, atau langkah berikutnya?')
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _ask([String? value]) {
    final question = (value ?? _input.text).trim();
    if (question.isEmpty) return;
    setState(() {
      _messages.add(_Chat(true, question));
      _messages.add(_Chat(false,
          'Dari ${widget.transactionCount} transaksi yang tercatat, omzetmu saat ini ${formatRupiah(widget.revenue)}. Prioritas terbaikmu adalah menjaga pencatatan harian dan melengkapi legalitas usaha agar skor kesiapan naik.'));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(children: [
              CircleAvatar(
                  backgroundColor: _brandYellow,
                  child: Icon(Icons.auto_awesome, color: _ink)),
              SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Fosti',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text('Asisten usaha FOSTIFEST',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ]),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                        color: message.mine ? _brandYellow : _warmWhite,
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(message.text,
                        style: TextStyle(color: _ink, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                children: [
              'Bagaimana omzetku?',
              'Cara naikkan skor?',
              'Apa langkah berikutnya?'
            ]
                    .map((text) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                            label: Text(text), onPressed: () => _ask(text))))
                    .toList()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _ask(),
                      decoration: const InputDecoration(
                          hintText: 'Tanya Fosti…',
                          filled: true,
                          fillColor: _warmWhite,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                              borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              IconButton.filled(
                  onPressed: _ask,
                  style: IconButton.styleFrom(backgroundColor: _brandYellow),
                  icon: const Icon(Icons.arrow_upward, color: _ink)),
            ]),
          ),
        ],
      );
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.note,
      required this.accent});
  final String label, value, note;
  final Color accent;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 220,
      child: Card(
          elevation: 0,
          color: accent,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const Spacer(),
                    Text(value,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(note,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white))
                  ]))));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: _ink)));
}

class ActionCard extends StatelessWidget {
  const ActionCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.action});
  final IconData icon;
  final String title, subtitle, action;
  @override
  Widget build(BuildContext context) => Card(
      elevation: 0,
      child: ListTile(
          leading: CircleAvatar(
              backgroundColor: _cream, child: Icon(icon, color: _ink)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: Text(action,
              style:
                  const TextStyle(color: _ink, fontWeight: FontWeight.w800))));
}

class FactorTile extends StatelessWidget {
  const FactorTile(
      {super.key,
      required this.label,
      required this.value,
      required this.color});
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
          elevation: 0,
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('$value',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: color))
                    ]),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: color,
                    backgroundColor: _cream)
              ]))));
}

class _Chat {
  _Chat(this.mine, this.text);
  final bool mine;
  final String text;
}

String formatRupiah(int amount) {
  final digits = amount.toString();
  final reversed = digits.split('').reversed.toList();
  final chunks = <String>[];
  for (var i = 0; i < reversed.length; i += 3) {
    chunks.add(reversed.skip(i).take(3).toList().reversed.join());
  }
  return 'Rp ${chunks.reversed.join('.')}';
}

String formatCompactRupiah(int amount) {
  if (amount >= 1000000) {
    final value = amount / 1000000;
    return 'Rp ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} jt';
  }
  if (amount >= 1000) return 'Rp ${(amount / 1000).round()} rb';
  return 'Rp $amount';
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String formatMonthYear(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
