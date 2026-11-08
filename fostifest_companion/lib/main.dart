import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'inventory_page.dart';
import 'mock_data.dart';
import 'laras_operations_page.dart';
import 'manage_cerdas_page.dart';
import 'laras_design.dart';
import 'laras_components.dart';
import 'laras_forms.dart';
import 'laras_fintech_widgets.dart';
import 'supplier_page.dart';
import 'price_simulation_page.dart';
import 'legalitas_page.dart' as legal_v2;
import 'laras_api.dart';

void main() => runApp(const FostifestApp());

// Palet LARAS UMKM: hijau-putih, bersih, dan mudah dibaca di layar ponsel.
const _brandYellow = LarasDesign.green;
const _gold = Color(0xFF35A565);
const _cream = Color(0xFFEAF7EE);
const _divider = Color(0xFFE7ECEF);
const _ink = Color(0xFF22313A);
const _muted = Color(0xFF65747E);
// Semantic accents distinguish errors and financial actions.
const _error = Color(0xFFBA3C3C);
const _deepGold = Color(0xFF0B5D3B);

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
    await prefs.setString(
      'account_identifier',
      identifier.trim().toLowerCase(),
    );
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
  int _ledgerInitialTab = 0;
  final List<TransactionItem> _transactions = [];
  List<Map<String, dynamic>> _expenses = [], _sales = [];

  int get _revenue => _transactions.fold(0, (sum, item) => sum + item.amount);
  bool _thisMonth(DateTime? date) {
    final now = DateTime.now();
    return date != null && date.year == now.year && date.month == now.month;
  }

  int get _monthlyRevenue => _transactions
      .where((e) => _thisMonth(e.date))
      .fold(0, (sum, e) => sum + e.amount);
  int get _monthlyExpense => _expenses
      .where((e) => _thisMonth(DateTime.tryParse('${e['createdAt']}')))
      .fold(0, (sum, e) => sum + (e['amount'] as int));
  int get _monthlyCost =>
      _sales.where((e) => _thisMonth(DateTime.tryParse('${e['date']}'))).fold(
            0,
            (sum, sale) =>
                sum +
                ((sale['items'] as List?) ?? []).fold<int>(
                  0,
                  (v, item) =>
                      v +
                      ((item['cost'] as int?) ?? 0) *
                          ((item['quantity'] as int?) ?? 0),
                ),
          );

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
    final saved = prefs.getString('laras_transactions_v1');
    final restored = <TransactionItem>[];
    List<Map<String, dynamic>> readRecords(String key) =>
        (jsonDecode(prefs.getString(key) ?? '[]') as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    var expenses = <Map<String, dynamic>>[], sales = <Map<String, dynamic>>[];
    try {
      expenses = readRecords('laras_expenses_v1');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data laporan tidak dapat dibaca.')),
        );
      }
    }
    if (saved != null) {
      try {
        for (final value in jsonDecode(saved) as List) {
          final item = Map<String, dynamic>.from(value as Map);
          final source = item['source'] as String;
          restored.add(
            TransactionItem(
              name: item['name'] as String,
              amount: item['amount'] as int,
              date: DateTime.parse(item['date'] as String),
              source: source,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data transaksi tidak dapat dibaca.')),
          );
        }
      }
    }
    if (mounted) {
      setState(() {
        _transactions
          ..clear()
          ..addAll(restored);
        _profile = profile;
        _expenses = expenses;
        _sales = sales;
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

  Future<void> _logout() async {
    if (LarasApi.enabled) {
      try {
        await LarasApi().logout();
      } catch (_) {
        /* Local session is cleared even when offline. */
      }
    }
    if (mounted) {
      setState(() {
        _signedIn = false;
        _tab = 0;
      });
    }
  }

  Future<String?> _login(String identifier, String password) async {
    if (LarasApi.enabled) {
      try {
        await LarasApi().login(identifier, password);
        if (mounted) setState(() => _signedIn = true);
        return null;
      } on LarasApiException catch (e) {
        return e.message;
      } catch (_) {
        return 'Belum bisa masuk. Coba lagi.';
      }
    }
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
    if (LarasApi.enabled) {
      await LarasApi().register(
        account.fullName,
        account.identifier,
        account.password,
      );
    } else {
      await account.save();
    }
    if (mounted) {
      setState(() {
        _account = account;
        _signedIn = true;
      });
    }
  }

  Future<void> _saveProfile(BusinessProfile profile) async {
    if (mounted) setState(() => _profile = profile);
    await profile.save();
  }

  Future<void> _addTransaction(TransactionItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [item, ..._transactions];
    final saved = await prefs.setString(
      'laras_transactions_v1',
      jsonEncode(
        updated
            .map(
              (e) => {
                'name': e.name,
                'amount': e.amount,
                'date': e.date.toIso8601String(),
                'source': e.source,
              },
            )
            .toList(),
      ),
    );
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi gagal disimpan.')),
      );
      return;
    }
    setState(() {
      _transactions.insert(0, item);
      _tab = 1;
    });
  }

  void _openAdd() => _openFeature('catat');

  Future<void> _openFeature(String feature) async {
    FocusManager.instance.primaryFocus?.unfocus();
    switch (feature) {
      case 'catat':
        await _navigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (pageContext) => Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Catat transaksi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              body: SafeArea(
                child: AddTransactionPage(
                  onSave: (item) async {
                    await _addTransaction(item);
                    if (pageContext.mounted) Navigator.of(pageContext).pop();
                  },
                ),
              ),
            ),
          ),
        );
        return;
      case 'laporan':
        setState(() {
          _ledgerInitialTab = 2;
          _tab = 1;
        });
        return;
      case 'riwayat':
        setState(() {
          _ledgerInitialTab = 0;
          _tab = 1;
        });
        return;
      case 'supplier':
        setState(() => _tab = 3);
        return;
      case 'legalitas':
        await _navigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => const legal_v2.LegalitasPage(),
          ),
        );
        return;
      case 'profil':
        setState(() => _tab = 4);
        return;
      case 'asisten':
        _openFosti();
        return;
    }
    Widget? page;
    switch (feature) {
      case 'produk':
        page = const InventoryPage();
        break;
      case 'pelanggan':
        page = const LarasOperationsPage(section: 'pelanggan');
        break;
      case 'keuangan':
      case 'pengeluaran':
        page = const LarasOperationsPage(section: 'keuangan');
        break;
      case 'margin':
        page = const LarasOperationsPage(section: 'margin');
        break;
      case 'simulasi':
        page = const PriceSimulationPage();
        break;
    }
    if (page == null) return;
    await _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => page!),
    );
    await _loadProfile();
  }

  void _openFosti() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Laras',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            child: FostiPage(
              revenue: _revenue,
              transactionCount: _transactions.length,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        profile: _profile,
        items: _transactions,
        revenue: _revenue,
        monthlyRevenue: _monthlyRevenue,
        monthlyProfit: _monthlyRevenue - _monthlyExpense - _monthlyCost,
        transactionCount: _transactions.length,
        onAdd: _openAdd,
        onFeature: _openFeature,
        onInsight: () => _openFeature('legalitas'),
        onProfile: () => setState(() => _tab = 4),
      ),
      LedgerPage(
        key: ValueKey('ledger-$_ledgerInitialTab'),
        initialTab: _ledgerInitialTab,
        profile: _profile,
        items: _transactions,
        expenses: _expenses,
        sales: _sales,
        onAdd: _openAdd,
      ),
      ManageCerdasPage(onOpen: _openFeature),
      const SupplierPage(),
      ProfilePage(
        profile: _profile,
        onSave: _saveProfile,
        onCashierClosed: _loadProfile,
        darkMode: _darkMode,
        onDarkModeChanged: _setDarkMode,
        onLogout: _logout,
      ),
    ];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 500;
            final width = compact
                ? constraints.maxWidth
                : math.min(414.0, constraints.maxWidth - 32);
            final height = compact
                ? constraints.maxHeight
                : math.min(852.0, constraints.maxHeight - 32);
            return ColoredBox(
              color: const Color(0xFFE9EEF1),
              child: Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 0 : 24),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(width, height),
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      title: 'LARAS UMKM',
      debugShowCheckedModeBanner: false,
      theme: LarasDesign.theme(),
      darkTheme: LarasDesign.theme(dark: true),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: _showSplash
          ? const FostifestSplashScreen()
          : !_signedIn
              ? FostifestLoginScreen(
                  onEnter: () async {
                    if (LarasApi.enabled) await LarasApi().enterGuest();
                    await seedBatikDemoData();
                    await _loadProfile();
                    if (mounted) setState(() => _signedIn = true);
                  },
                  onLogin: _login,
                  onRegister: _register,
                )
              : Builder(
                  builder: (context) => Scaffold(
                    appBar: _tab == 0
                        ? null
                        : AppBar(
                            title: Text(
                                _tab == 2 ? 'Manage Cerdas' : 'LARAS UMKM'),
                            actions: [
                              IconButton(
                                tooltip: 'Laras',
                                onPressed: _openFosti,
                                icon: Icon(
                                  Icons.auto_awesome_outlined,
                                  color: LarasDesign.accent(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                    drawer: LarasSidebar(
                      profile: _profile,
                      onFeature: _openFeature,
                    ),
                    body: SafeArea(top: _tab == 0, child: pages[_tab]),
                    bottomNavigationBar: FostifestBottomBar(
                      selectedIndex: _tab,
                      onSelected: (index) => setState(() => _tab = index),
                    ),
                  ),
                ),
    );
  }
}

class FostifestSplashScreen extends StatelessWidget {
  const FostifestSplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LarasDesign.heroGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .2),
                        ),
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'LARAS UMKM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tumbuhkan arah usahamu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFFE3F4EC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  final Future<void> Function() onEnter;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi email/nomor WhatsApp dan kata sandi.'),
        ),
      );
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FostifestRegistrationScreen(onRegister: widget.onRegister),
      ),
    );
  }

  Future<void> _enterDemo() async {
    setState(() => _submitting = true);
    try {
      await widget.onEnter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LarasApiException
                  ? e.message
                  : 'Belum bisa membuka demo. Coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: LarasEntrance(
                  child: LarasWelcomePanel(
                    eyebrow: 'LARAS UMKM',
                    title: 'Usaha rapi.\nMimpi besar.',
                    description: 'Kelola usahamu dengan lebih tenang.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang kembali',
                      style: TextStyle(
                        fontSize: 21,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk untuk melanjutkan kelola usahamu.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: LarasDesign.secondary(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Email atau nomor WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _identifier,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'contoh@usaha.id',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Kata sandi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Minimal 6 karakter',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(color: _ink),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: _brandYellow,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _submitting ? 'Memeriksa…' : 'Masuk',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: _openRegistration,
                        child: const Text(
                          'Belum punya akun? Daftar',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: _divider)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('atau', style: TextStyle(color: _muted)),
                        ),
                        Expanded(child: Divider(color: _divider)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _enterDemo,
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('Lihat sebagai tamu'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: _ink,
                        side: const BorderSide(color: _gold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _enterDemo,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Masuk ke akun demo LARAS UMKM'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: _ink,
                        side: const BorderSide(color: _ink),
                      ),
                    ),
                  ],
                ),
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

class _FostifestRegistrationScreenState
    extends State<FostifestRegistrationScreen> {
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
    try {
      await widget.onRegister(
        FostifestAccount(
          fullName: _name.text.trim(),
          identifier: _identifier.text.trim(),
          password: _password.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LarasApiException
                  ? e.message
                  : 'Akun belum terdaftar. Coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: _ink,
          title: const Text(
            'Daftar akun LARAS UMKM',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                const Text(
                  'Mulai kelola usahamu',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buat akun untuk menyimpan akses LARAS UMKM di perangkat ini.',
                  style: TextStyle(color: _muted, height: 1.4),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nama lengkap',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: _required,
                  decoration:
                      const InputDecoration(hintText: 'Nama sesuai KTP'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nomor WhatsApp atau email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_identifier'),
                  controller: _identifier,
                  keyboardType: TextInputType.emailAddress,
                  validator: _required,
                  decoration: const InputDecoration(
                    hintText: '08xx atau nama@usaha.id',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kata sandi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ulangi kata sandi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('register_confirmation'),
                  controller: _confirmation,
                  obscureText: _obscure,
                  validator: (value) =>
                      value != _password.text ? 'Kata sandi belum sama.' : null,
                  decoration: const InputDecoration(
                    hintText: 'Ketik ulang kata sandi',
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _brandYellow,
                        child:
                            Icon(Icons.storefront_rounded, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemilik UMKM',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Kelola transaksi, laporan, dan arah usaha.',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: _deepGold),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('register_submit'),
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _brandYellow,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _submitting ? 'Menyimpan…' : 'Daftar & masuk',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Sudah punya akun? Masuk'),
                ),
              ],
            ),
          ),
        ),
      );
}

class FostifestBottomBar extends StatelessWidget {
  const FostifestBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  static const _items = [
    ('Beranda', Icons.home_outlined, Icons.home_rounded),
    ('Catatan', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    (
      'Manage Cerdas',
      Icons.dashboard_customize_outlined,
      Icons.dashboard_customize_rounded,
    ),
    ('Supplier', Icons.local_shipping_outlined, Icons.local_shipping_rounded),
    ('Profil', Icons.person_outline_rounded, Icons.person_rounded),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: selectedIndex == i,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onSelected(i),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 3,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: MediaQuery.disableAnimationsOf(
                                              context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      width: 44,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: i == selectedIndex
                                            ? LarasDesign.soft(context)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ExcludeSemantics(
                                        child: Icon(
                                          i == selectedIndex
                                              ? _items[i].$3
                                              : _items[i].$2,
                                          key: i == 2
                                              ? const Key('smart_record_icon')
                                              : null,
                                          size: 22,
                                          color: i == selectedIndex
                                              ? LarasDesign.accent(context)
                                              : LarasDesign.secondary(context),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _items[i].$1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.3,
                                        fontWeight: i == selectedIndex
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: i == selectedIndex
                                            ? LarasDesign.accent(context)
                                            : LarasDesign.secondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    required this.profile,
    this.onOpenProfile,
    this.onAssistant,
  });
  final BusinessProfile profile;
  final VoidCallback? onOpenProfile, onAssistant;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Profil usaha',
              child: Tooltip(
                message: 'Profil usaha',
                child: InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    key: const Key('home_avatar'),
                    width: 48,
                    height: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: LarasDesign.soft(context),
                    ),
                    child: Image(
                      image: _businessPhoto(profile),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LARAS UMKM',
                    key: const Key('home_brand'),
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w500,
                      color: LarasDesign.secondary(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: LarasDesign.text(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Laras',
              onPressed: onAssistant,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: Icon(
                Icons.auto_awesome_outlined,
                size: 23,
                color: LarasDesign.accent(context),
              ),
            ),
            IconButton(
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: Icon(
                Icons.menu_rounded,
                size: 24,
                color: LarasDesign.text(context),
              ),
            ),
          ],
        ),
      );
}

/// Sidebar fitur: semua fitur LARAS UMKM tersimpan di sini.
class LarasSidebar extends StatelessWidget {
  const LarasSidebar({
    super.key,
    required this.profile,
    required this.onFeature,
  });
  final BusinessProfile profile;
  final ValueChanged<String> onFeature;

  static const _sections = <(String, List<(String, String, IconData)>)>[
    (
      'Kelola usaha',
      [
        ('produk', 'Produk dan stok', Icons.inventory_2_outlined),
        ('pelanggan', 'Pelanggan', Icons.groups_2_outlined),
        ('keuangan', 'Keuangan', Icons.account_balance_wallet_outlined),
      ],
    ),
    (
      'Manajemen usaha',
      [
        ('margin', 'Harga & margin', Icons.price_change_outlined),
        ('simulasi', 'Simulasi harga', Icons.tune_rounded),
        ('laporan', 'Laporan & analitik', Icons.bar_chart_rounded),
        ('supplier', 'Supplier', Icons.local_shipping_outlined),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => Drawer(
        key: const Key('laras_sidebar'),
        width: 300,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LarasDesign.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image(
                        image: _businessPhoto(profile),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            profile.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('close_sidebar'),
                      tooltip: 'Tutup menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(10, 4, 10, 16),
                  children: [
                    for (final section in _sections) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, 14, 12, 6),
                        child: Text(
                          section.$1.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: LarasDesign.secondary(context),
                          ),
                        ),
                      ),
                      for (final item in section.$2)
                        ListTile(
                          key: Key('sidebar_${item.$1}'),
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _cream,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(item.$3, size: 20, color: _deepGold),
                          ),
                          title: Text(
                            item.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: LarasDesign.text(context),
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: LarasDesign.secondary(context),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            onFeature(item.$1);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.profile,
    required this.onProfile,
    required this.onAdd,
    required this.onFeature,
  });
  final BusinessProfile profile;
  final VoidCallback onProfile, onAdd;
  final ValueChanged<String> onFeature;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileHeader(
              profile: profile,
              onOpenProfile: onProfile,
              onAssistant: () => onFeature('asisten'),
            ),
            const SizedBox(height: 18),
            _FeatureSearch(onSelect: onFeature),
          ],
        ),
      );
}

class _FeatureSearch extends StatefulWidget {
  const _FeatureSearch({required this.onSelect});
  final ValueChanged<String> onSelect;
  @override
  State<_FeatureSearch> createState() => _FeatureSearchState();
}

class _FeatureSearchState extends State<_FeatureSearch> {
  final controller = TextEditingController();
  static const features = <({
    String id,
    String title,
    String subtitle,
    String words,
    IconData icon,
  })>[
    (
      id: 'simulasi',
      title: 'Simulasi harga produk',
      subtitle: 'Coba harga, biaya bahan, dan perkiraan untung / rugi',
      words: 'simulasi harga hpp untung rugi supplier modal biaya produksi',
      icon: Icons.tune_rounded,
    ),
    (
      id: 'margin',
      title: 'Harga & margin produk',
      subtitle: 'Cek margin tiap produk dan atur harga jual',
      words: 'harga margin laba untung modal hpp atur harga produk',
      icon: Icons.price_change_outlined,
    ),
    (
      id: 'catat',
      title: 'Catat transaksi',
      subtitle: 'Input manual, chat, dan foto catatan',
      words: 'pemasukan tambah transaksi ocr foto catatan chat',
      icon: Icons.edit_note_rounded,
    ),
    (
      id: 'supplier',
      title: 'Supplier',
      subtitle: 'Pemasok bahan baku, kontak, dan harga bahan',
      words: 'supplier pemasok bahan baku mori malam pewarna harga beli kontak',
      icon: Icons.local_shipping_outlined,
    ),
    (
      id: 'produk',
      title: 'Produk dan stok',
      subtitle: 'Kelola katalog dan persediaan',
      words: 'barang stok inventaris kategori sku tambah produk',
      icon: Icons.inventory_2_outlined,
    ),
    (
      id: 'pelanggan',
      title: 'Pelanggan',
      subtitle: 'Kontak dan catatan pelanggan',
      words: 'pelanggan customer kontak catatan',
      icon: Icons.people_outline_rounded,
    ),
    (
      id: 'pengeluaran',
      title: 'Pengeluaran',
      subtitle: 'Catat biaya usaha',
      words: 'biaya beban expense keluar operasional',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      id: 'laporan',
      title: 'Laporan keuangan',
      subtitle: 'Laba rugi, omzet, dan PDF',
      words: 'laporan laba rugi pendapatan pengeluaran omzet pdf cetak',
      icon: Icons.bar_chart_rounded,
    ),
    (
      id: 'riwayat',
      title: 'Riwayat transaksi',
      subtitle: 'Lihat catatan transaksi usaha',
      words: 'transaksi riwayat kalender catatan pembukuan',
      icon: Icons.receipt_long_outlined,
    ),
    (
      id: 'legalitas',
      title: 'Legalitas usaha',
      subtitle: 'Catat status dokumen usaha',
      words: 'legalitas nib pirt merek halal dokumen izin usaha',
      icon: Icons.verified_user_outlined,
    ),
    (
      id: 'profil',
      title: 'Profil usaha',
      subtitle: 'Identitas dan pengaturan usaha',
      words: 'profil pengaturan nama usaha alamat',
      icon: Icons.storefront_outlined,
    ),
    (
      id: 'asisten',
      title: 'Asisten Laras',
      subtitle: 'Tanyakan hal tentang usahamu',
      words: 'chat tanya bantuan asisten laras',
      icon: Icons.auto_awesome_outlined,
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim().toLowerCase();
    final terms = query.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final matches = features.where((f) {
      final text = '${f.title} ${f.subtitle} ${f.words}'.toLowerCase();
      return terms.every(text.contains);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: Key('feature_search'),
          controller: controller,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            if (query.isNotEmpty && matches.isNotEmpty) {
              final id = matches.first.id;
              controller.clear();
              setState(() {});
              widget.onSelect(id);
            }
          },
          decoration: InputDecoration(
            hintText: 'Cari fitur atau layanan usaha',
            hintStyle: TextStyle(
              fontSize: 14,
              color: LarasDesign.secondary(context),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: LarasDesign.secondary(context),
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () => setState(controller.clear),
                    icon: Icon(Icons.close_rounded, size: 20),
                  ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (query.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            key: Key('feature_search_results'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _divider),
            ),
            child: matches.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Fitur tidak ditemukan. Coba kata lain.',
                      style: TextStyle(color: LarasDesign.secondary(context)),
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: Column(
                      children: matches
                          .map(
                            (f) => ListTile(
                              dense: true,
                              leading: Icon(f.icon, color: _brandYellow),
                              title: Text(
                                f.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                f.subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: LarasDesign.secondary(context),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              onTap: () {
                                controller.clear();
                                setState(() {});
                                widget.onSelect(f.id);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.items,
    required this.revenue,
    required this.monthlyRevenue,
    required this.monthlyProfit,
    required this.transactionCount,
    required this.onAdd,
    required this.onFeature,
    required this.onInsight,
    required this.onProfile,
  });
  final int revenue;
  final int monthlyRevenue, monthlyProfit;
  final BusinessProfile profile;
  final List<TransactionItem> items;
  final int transactionCount;
  final VoidCallback onAdd;
  final ValueChanged<String> onFeature;
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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HomeHero(
            profile: widget.profile,
            onProfile: widget.onProfile,
            onAdd: widget.onAdd,
            onFeature: widget.onFeature,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LarasEntrance(
              child: LarasBusinessOverview(
                key: const Key('home_summary_card'),
                revenue: formatRupiah(widget.monthlyRevenue),
                profit: formatRupiah(widget.monthlyProfit),
                transactions: widget.transactionCount,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('Catat transaksi sekarang'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SectionTitle(title: 'Akses cepat'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LarasShortcutGrid(
              children: [
                LarasQuickAction(
                  label: 'Keuangan',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => widget.onFeature('keuangan'),
                ),
                LarasQuickAction(
                  label: 'Produk & Stok',
                  icon: Icons.inventory_2_outlined,
                  tone: 1,
                  onTap: () => widget.onFeature('produk'),
                ),
                LarasQuickAction(
                  label: 'Laporan',
                  icon: Icons.insert_chart_outlined_rounded,
                  tone: 2,
                  onTap: () => widget.onFeature('laporan'),
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LarasRecordCard(
              title: 'Legalitas usaha',
              subtitle: 'Catat dokumen usaha yang sudah dimiliki.',
              icon: Icons.verified_user_outlined,
              onTap: widget.onInsight,
            ),
          ),
        ],
      );
}

class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({
    required this.items,
    required this.selectedDays,
    required this.onChanged,
  });
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: const {
                7: '1 Minggu',
                21: '3 Minggu',
                30: '1 Bulan',
                90: '3 Bulan',
              }
                  .entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      selected: selectedDays == entry.key,
                      onSelected: (_) => onChanged(entry.key),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            LarasTrendPlot(
              values: buckets,
              labels: List.generate(
                4,
                (i) => 'P${i + 1} · ${formatCompactRupiah(buckets[i])}',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${items.length} transaksi dalam periode ini',
              style: TextStyle(
                color: LarasDesign.secondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
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
            ? Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Belum ada transaksi pada periode ini.',
                  style: TextStyle(color: LarasDesign.secondary(context)),
                ),
              )
            : Column(
                children: List.generate(products.length, (index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: LarasDesign.tileTone(context, index),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: LarasDesign.accent(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.key,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: LarasDesign.text(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatRupiah(product.value),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: LarasDesign.accent(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < products.length - 1)
                          Divider(height: 1, color: LarasDesign.line(context)),
                      ],
                    ),
                  );
                }),
              ),
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onCashierClosed,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
  });

  final BusinessProfile profile;
  final Future<void> Function(BusinessProfile) onSave;
  final Future<void> Function() onCashierClosed;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push<BusinessProfile>(
      MaterialPageRoute(
        builder: (_) => EditBusinessProfilePage(profile: profile),
      ),
    );
    if (updated == null) return;
    await onSave(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil usaha berhasil disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        key: ValueKey('profile-${profile.name}'),
        padding: EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            'Profil usaha',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Kelola identitas dan informasi usahamu.',
            style: TextStyle(color: LarasDesign.secondary(context)),
          ),
          SizedBox(height: 22),
          LarasEntrance(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image(
                        image: _businessPhoto(profile),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROFIL USAHA',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500,
                              color: LarasDesign.accent(context),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: LarasDesign.text(context),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            profile.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: LarasDesign.secondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  _ProfileRow(
                    icon: Icons.storefront_outlined,
                    label: 'Nama usaha',
                    value: profile.name,
                  ),
                  Divider(color: _divider, height: 26),
                  _ProfileRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi usaha',
                    value: profile.location,
                  ),
                  Divider(color: _divider, height: 26),
                  _ProfileRow(
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: profile.category,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _edit(context),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(52),
              backgroundColor: _brandYellow,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.edit_outlined),
            label: Text('Edit profil usaha'),
          ),
          SizedBox(height: 20),
          Text(
            'PENGATURAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LarasDesign.secondary(context),
              letterSpacing: .7,
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(
                      builder: (_) => LarasGuidePage())),
                  leading: Icon(Icons.help_outline_rounded),
                  title: Text('Panduan LARAS UMKM'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                Divider(color: _divider, height: 1),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => PrivacyDataPage()),
                  ),
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privasi dan data usaha'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                Divider(color: _divider, height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.dark_mode_outlined),
                  title: Text('Mode gelap'),
                  value: darkMode,
                  activeThumbColor: _brandYellow,
                  onChanged: onDarkModeChanged,
                ),
                Divider(color: _divider, height: 1),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => AboutFostifestPage()),
                  ),
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Tentang LARAS UMKM'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                Divider(color: _divider, height: 1),
                ListTile(
                  onTap: onLogout,
                  leading: Icon(Icons.logout_rounded, color: _error),
                  title: Text(
                    'Keluar',
                    style:
                        TextStyle(color: _error, fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      );
}

class LarasGuidePage extends StatelessWidget {
  const LarasGuidePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Panduan LARAS UMKM')),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              Text(
                'Mulai mengelola usaha',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Gunakan LARAS untuk memahami arus kas, stok, margin, dan arah usaha.',
                style: TextStyle(
                  color: LarasDesign.secondary(context),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              _GuideStep(
                number: '1',
                icon: Icons.edit_note_rounded,
                title: 'Catat keuangan',
                text:
                    'Buka Catatan atau Manage Cerdas untuk mencatat pemasukan dan pengeluaran. Gunakan kategori agar laporan lebih mudah dibaca.',
              ),
              _GuideStep(
                number: '2',
                icon: Icons.inventory_2_outlined,
                title: 'Perbarui produk dan stok',
                text:
                    'Tambahkan produk, harga modal, harga jual, jumlah stok, dan batas stok minimum. Periksa produk yang perlu diisi ulang.',
              ),
              _GuideStep(
                number: '3',
                icon: Icons.auto_graph_rounded,
                title: 'Evaluasi harga dan margin',
                text:
                    'Di Manage Cerdas, lihat Harga & Margin untuk membandingkan harga jual dengan modal dan menentukan produk yang perlu dievaluasi.',
              ),
              _GuideStep(
                number: '4',
                icon: Icons.bar_chart_rounded,
                title: 'Baca laporan usaha',
                text:
                    'Buka Catatan untuk melihat ringkasan pemasukan, pengeluaran, laba-rugi, dan laporan periode usaha.',
              ),
              _GuideStep(
                number: '5',
                icon: Icons.verified_user_outlined,
                title: 'Lengkapi legalitas',
                text:
                    'Catat status NIB, merek/P-IRT, serta sertifikasi halal sebagai pengingat dokumen usaha.',
              ),
              SizedBox(height: 12),
              Card(
                color: _cream,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tips: catat transaksi pada hari yang sama supaya ringkasan usaha tetap akurat.',
                    style: TextStyle(height: 1.4, color: _ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });
  final String number, title, text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _brandYellow,
                  foregroundColor: Colors.white,
                  child: Text(
                    number,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 19, color: _deepGold),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: LarasDesign.secondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class PrivacyDataPage extends StatelessWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Privasi dan data usaha')),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              Text(
                'Data usaha tetap milikmu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'LARAS membantu mengelola catatan usaha tanpa memproses pembayaran atau mengakses rekening bank.',
                style: TextStyle(
                  color: LarasDesign.secondary(context),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              _PrivacyPoint(
                icon: Icons.phone_android_outlined,
                title: 'Penyimpanan lokal',
                text:
                    'Profil usaha, produk, pelanggan, transaksi, dan legalitas disimpan pada perangkat atau browser yang sedang digunakan.',
              ),
              _PrivacyPoint(
                icon: Icons.cloud_off_outlined,
                title: 'Belum ada sinkronisasi server',
                text:
                    'Versi ini belum mengirim data usaha ke server. Jika browser dibersihkan atau perangkat hilang, data lokal dapat ikut hilang.',
              ),
              _PrivacyPoint(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Bukan layanan pembayaran',
                text:
                    'LARAS tidak membuat QRIS, payment link, rekening virtual, atau verifikasi transfer otomatis.',
              ),
              _PrivacyPoint(
                icon: Icons.photo_outlined,
                title: 'Foto catatan',
                text:
                    'Foto yang dipilih untuk pembacaan teks dipakai untuk membantu mengisi catatan transaksi. Periksa hasilnya sebelum menyimpan.',
              ),
              _PrivacyPoint(
                icon: Icons.lock_outline_rounded,
                title: 'Saran keamanan',
                text:
                    'Gunakan kunci layar perangkat dan jangan membagikan akses browser atau perangkat kepada pihak yang tidak dipercaya.',
              ),
              SizedBox(height: 10),
              Card(
                color: _cream,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Jangan menyimpan kata sandi, PIN, nomor rekening, atau data sensitif lain di catatan transaksi.',
                    style: TextStyle(color: _ink, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Card(
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: _deepGold),
            ),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(text, style: TextStyle(height: 1.35)),
            ),
          ),
        ),
      );
}

class AboutFostifestPage extends StatelessWidget {
  const AboutFostifestPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Tentang LARAS UMKM')),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Text(
                'LARAS UMKM',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: _deepGold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kenali usahamu, tentukan arah.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: LarasDesign.secondary(context),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'LARAS UMKM membantu pelaku UMKM mencatat transaksi, memantau penjualan, dan memahami hasil usaha melalui laporan keuangan.',
                style: TextStyle(height: 1.55),
              ),
              SizedBox(height: 18),
              Card(
                color: _cream,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Hasil pembacaan struk dan laporan merupakan alat bantu. Periksa kembali data sebelum digunakan.',
                    style: TextStyle(height: 1.45, color: _ink),
                  ),
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Yang LARAS UMKM lakukan:',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              _AboutPoint(
                text:
                    'Mencatat penjualan manual, dari chat, atau foto bukti transaksi.',
              ),
              _AboutPoint(text: 'Membaca tren omzet dan produk terlaris.'),
              _AboutPoint(text: 'Mencatat status dokumen legalitas usaha.'),
              _AboutPoint(
                text: 'Menyusun laporan laba rugi dan paket dokumen PDF.',
              ),
              SizedBox(height: 20),
              Text(
                'Versi 1.5.0',
                style: TextStyle(color: LarasDesign.secondary(context)),
              ),
            ],
          ),
        ),
      );
}

class _AboutPoint extends StatelessWidget {
  const _AboutPoint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.circle, size: 7, color: _deepGold),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(height: 1.4))),
          ],
        ),
      );
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
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penggantian foto usaha tersedia di aplikasi Android.'),
        ),
      );
      return;
    }
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
    Navigator.of(context).pop(
      BusinessProfile(
        name: _name.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        category: _category.text.trim(),
        photoPath: _photoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit profil usaha')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 51,
                    backgroundImage: _businessPhoto(
                      BusinessProfile(photoPath: _photoPath),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickingPhoto ? null : _choosePhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _pickingPhoto ? 'Memilih foto…' : 'Ganti foto usaha',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama usaha'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama usaha wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi singkat'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Lokasi usaha'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _category,
                  decoration:
                      const InputDecoration(labelText: 'Kategori usaha'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan profil'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandYellow,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                const BoxDecoration(color: _cream, shape: BoxShape.circle),
            child: Icon(icon, color: _ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: LarasDesign.secondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
}

class LedgerPage extends StatefulWidget {
  const LedgerPage({
    super.key,
    this.initialTab = 0,
    required this.profile,
    required this.items,
    required this.expenses,
    required this.sales,
    required this.onAdd,
  });
  final BusinessProfile profile;
  final int initialTab;
  final List<TransactionItem> items;
  final List<Map<String, dynamic>> expenses, sales;
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
    _tab = widget.initialTab;
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  List<TransactionItem> get _monthlyItems => widget.items
      .where(
        (item) =>
            item.date.year == _month.year && item.date.month == _month.month,
      )
      .toList();
  int get _income => _monthlyItems.fold(0, (sum, item) => sum + item.amount);
  List<Map<String, dynamic>> get _monthlyExpenses => widget.expenses.where((e) {
        final date = DateTime.tryParse('${e['createdAt']}');
        return date != null &&
            date.year == _month.year &&
            date.month == _month.month;
      }).toList();
  int get _operatingExpense =>
      _monthlyExpenses.fold(0, (sum, e) => sum + (e['amount'] as int));
  int get _costOfGoods => widget.sales.where((e) {
        final date = DateTime.tryParse('${e['date']}');
        return date != null &&
            date.year == _month.year &&
            date.month == _month.month;
      }).fold(
        0,
        (sum, sale) =>
            sum +
            ((sale['items'] as List?) ?? []).fold<int>(
              0,
              (v, item) =>
                  v +
                  ((item['cost'] as int?) ?? 0) *
                      ((item['quantity'] as int?) ?? 0),
            ),
      );
  int get _expense => _operatingExpense + _costOfGoods;
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
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('LARAS UMKM - Laporan Laba Rugi')),
          pw.Paragraph(text: 'Usaha: ${widget.profile.name}'),
          pw.Paragraph(text: 'Periode: ${formatMonthYear(_month)}'),
          pw.SizedBox(height: 8),
          pw.Text(
            'Rincian pendapatan',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (_monthlyItems.isEmpty)
            pw.Paragraph(text: 'Belum ada transaksi tercatat pada periode ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Produk', 'Sumber', 'Nominal'],
              data: _monthlyItems
                  .map(
                    (item) => [
                      formatDate(item.date),
                      item.name,
                      item.source,
                      formatRupiah(item.amount),
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Ringkasan laba rugi',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(text: 'Total pendapatan: ${formatRupiah(_income)}'),
          pw.Bullet(text: 'Total beban: ${formatRupiah(_expense)}'),
          pw.Bullet(text: 'Laba bersih: ${formatRupiah(_income - _expense)}'),
          pw.Bullet(text: 'Estimasi PPh final 0,5%: ${formatRupiah(_tax)}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Laporan ini merupakan rangkuman internal dan bukan laporan yang diaudit. Lengkapi harga modal produk dan seluruh biaya usaha agar evaluasi margin semakin akurat.',
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename:
          'laporan-laba-rugi-${_month.year}-${_month.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan keuangan',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Transaksi dan laporan usaha dalam satu tempat.',
                        style: TextStyle(
                          color: LarasDesign.secondary(context),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onAdd,
                  tooltip: 'Catat transaksi',
                  style: IconButton.styleFrom(
                    backgroundColor: LarasDesign.soft(context),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: Icon(
                    Icons.add_rounded,
                    color: LarasDesign.accent(context),
                    size: 27,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LarasSegmentedTabs(
              labels: const ['Transaksi', 'Kalender', 'Laporan'],
              selected: _tab,
              onSelected: (index) => setState(() => _tab = index),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_tab) {
              0 => _buildTransactions(),
              1 => _buildCalendar(),
              _ => _buildReport(),
            },
          ),
        ],
      );

  Widget _buildTransactions() => ListView(
        key: const Key('finance_transactions_page'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          _MonthPicker(
            month: _month,
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          const SizedBox(height: 14),
          if (_monthlyItems.isEmpty)
            const _EmptyMonth(message: 'Belum ada transaksi pada bulan ini.')
          else
            ..._monthlyItems.map(
              (item) => LarasAmountRow(
                title: item.name,
                subtitle: '${formatDate(item.date)} · ${item.source}',
                amount: formatRupiah(item.amount),
                icon: item.source == 'Scan struk'
                    ? Icons.document_scanner_outlined
                    : Icons.shopping_bag_outlined,
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Catat transaksi baru'),
            style: FilledButton.styleFrom(
              backgroundColor: _brandYellow,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      );

  Widget _buildCalendar() {
    final selectedItems = _monthlyItems
        .where(
          (item) =>
              item.date.year == _selectedDate.year &&
              item.date.month == _selectedDate.month &&
              item.date.day == _selectedDate.day,
        )
        .toList();
    final selectedIncome = selectedItems.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final selectedExpense = _monthlyExpenses.where((item) {
      final date = DateTime.tryParse('${item['createdAt']}');
      return date != null && date.day == _selectedDate.day;
    }).fold<int>(0, (sum, item) => sum + (item['amount'] as int));

    return ListView(
      key: const Key('finance_calendar_page'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        _MonthPicker(
          month: _month,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: 10),
        _FinanceCalendar(
          month: _month,
          items: _monthlyItems,
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 16),
        Text(
          'Catatan ${formatDate(_selectedDate)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _CalendarTotal(
                    label: 'Pemasukan',
                    value: selectedIncome,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Container(width: 1, height: 42, color: _divider),
                Expanded(
                  child: _CalendarTotal(
                    label: 'Pengeluaran',
                    value: selectedExpense,
                    color: _error,
                  ),
                ),
                Container(width: 1, height: 42, color: _divider),
                Expanded(
                  child: _CalendarTotal(
                    label: 'Saldo',
                    value: selectedIncome - selectedExpense,
                    color: _deepGold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedItems.isEmpty)
          const _EmptyMonth(message: 'Belum ada transaksi pada tanggal ini.')
        else
          ...selectedItems.map(
            (item) => LarasAmountRow(
              title: item.name,
              subtitle: item.source,
              amount: '+${formatRupiah(item.amount)}',
              icon: Icons.south_west_rounded,
            ),
          ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Catat transaksi pada tanggal ini'),
          style: FilledButton.styleFrom(
            backgroundColor: _brandYellow,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
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
            onNext: () => _changeMonth(1),
          ),
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
            Text(
              'Rincian beban usaha',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_monthlyExpenses.isEmpty)
              const _EmptyMonth(
                  message: 'Belum ada pengeluaran pada bulan ini.')
            else
              ..._monthlyExpenses.map(
                (e) => LarasAmountRow(
                  title: '${e['name']}',
                  subtitle: '${e['detail']}',
                  amount: formatRupiah(e['amount'] as int),
                  outgoing: true,
                  icon: Icons.north_east_rounded,
                ),
              ),
            const SizedBox(height: 10),
            _ReportTotal(label: 'Total beban', value: _expense, negative: true),
          ] else ...[
            Text(
              'Rincian pendapatan (penjualan)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_monthlyItems.isEmpty)
              const _EmptyMonth(message: 'Belum ada penjualan pada bulan ini.')
            else
              ..._monthlyItems.map(
                (item) => LarasAmountRow(
                  title: item.name,
                  subtitle: '${formatDate(item.date)} · ${item.source}',
                  amount: formatRupiah(item.amount),
                  icon: Icons.south_west_rounded,
                ),
              ),
            _ReportTotal(label: 'Total pendapatan', value: _income),
            const SizedBox(height: 18),
            Text(
              'Rincian beban usaha',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_monthlyExpenses.isEmpty)
              const _EmptyMonth(
                  message: 'Belum ada pengeluaran pada bulan ini.')
            else
              ..._monthlyExpenses.map(
                (e) => LarasAmountRow(
                  title: '${e['name']}',
                  subtitle: '${e['detail'] ?? ''}',
                  amount: formatRupiah(e['amount'] as int),
                  outgoing: true,
                  icon: Icons.north_east_rounded,
                ),
              ),
            _ReportTotal(
              label: 'Modal produk terjual',
              value: _costOfGoods,
              negative: true,
            ),
            _ReportTotal(label: 'Total beban', value: _expense, negative: true),
            const SizedBox(height: 18),
            Text(
              'Ringkasan laba rugi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _ProfitSummary(income: _income, expense: _expense),
            const SizedBox(height: 8),
            Text(
              'Laba adalah estimasi. Modal transaksi manual dan penjualan lama yang tidak menyimpan harga modal belum dihitung.',
              style: TextStyle(
                  fontSize: 12, color: LarasDesign.secondary(context)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LarasDesign.soft(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: LarasDesign.accent(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi PPh Final (0,5%)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatRupiah(_tax),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: LarasDesign.accent(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Estimasi dari omzet bulan ini untuk UMKM. Bukan pengganti perhitungan pajak atau pelaporan resmi.',
              style: TextStyle(
                fontSize: 12,
                color: LarasDesign.secondary(context),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _shareFinancePdf,
            icon: Icon(Icons.picture_as_pdf_outlined),
            label: Text('Unduh / bagikan PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: _brandYellow,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Format merangkum pendapatan, beban, laba rugi, dan estimasi pajak dari catatan LARAS UMKM.',
            style: TextStyle(
              fontSize: 12,
              color: LarasDesign.secondary(context),
              height: 1.35,
            ),
          ),
        ],
      );
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime month;
  final VoidCallback onPrevious, onNext;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Bulan sebelumnya',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                formatMonthYear(month),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      );
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
        child: Column(
          children: [
            Row(
              children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: .82,
              ),
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
                                    ? const Color(0xFF123D2B)
                                    : const Color(0xFFE4F4E9))
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _gold : _divider,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: selected || total > 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected ? _ink : null,
                            ),
                          ),
                          const Spacer(),
                          if (total > 0)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
                SizedBox(width: 6),
                Text(
                  'Tanggal dengan transaksi',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTotal extends StatelessWidget {
  const _CalendarTotal({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 11, color: LarasDesign.secondary(context)),
          ),
          const SizedBox(height: 5),
          Text(
            formatCompactRupiah(value),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: LarasDesign.isDark(context)
                  ? (color == _error
                      ? Theme.of(context).colorScheme.error
                      : LarasDesign.accent(context))
                  : color,
            ),
          ),
        ],
      );
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider),
        ),
        child: Text(
          message,
          style: TextStyle(color: LarasDesign.secondary(context)),
        ),
      );
}

class _ReportTotal extends StatelessWidget {
  const _ReportTotal({
    required this.label,
    required this.value,
    this.negative = false,
  });
  final String label;
  final int value;
  final bool negative;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                negative ? '(${formatRupiah(value)})' : formatRupiah(value),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: negative
                      ? Theme.of(context).colorScheme.error
                      : LarasDesign.accent(context),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProfitSummary extends StatelessWidget {
  const _ProfitSummary({required this.income, required this.expense});
  final int income, expense;
  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: [
            _SummaryRow(label: 'Total pendapatan', value: formatRupiah(income)),
            const Divider(height: 1, color: _divider),
            _SummaryRow(
                label: 'Total beban', value: '(${formatRupiah(expense)})'),
            const Divider(height: 1, color: _divider),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LarasDesign.soft(context),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'LABA BERSIH',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatRupiah(income - expense),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: LarasDesign.accent(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(label),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
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
  XFile? _receipt;
  String? _ocrRawText;
  bool _readingReceipt = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _customer.dispose();
    _quantity.dispose();
    // Text recognizer is released by the platform lifecycle. Calling close in
    // widget tests would require a native ML Kit channel that is unavailable.
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemindaian foto tersedia di aplikasi Android.'),
        ),
      );
      return;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera atau galeri belum bisa dibuka. Coba lagi.'),
          ),
        );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih foto catatan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _cream,
                  child: Icon(Icons.camera_alt_outlined, color: _ink),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto catatan transaksi'),
                onTap: () {
                  Navigator.pop(context);
                  _pickReceipt(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _cream,
                  child: Icon(Icons.photo_library_outlined, color: _ink),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih foto yang sudah ada'),
                onTap: () {
                  Navigator.pop(context);
                  _pickReceipt(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _readReceipt() async {
    if (_receipt == null) return;
    setState(() => _readingReceipt = true);
    try {
      final result = await _ocr.processImage(
        InputImage.fromFilePath(_receipt!.path),
      );
      final raw = result.text.trim();
      final lines = raw
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final numericValues = RegExp(
        r'(?<!\d)(?:Rp\.?\s*)?\d{1,3}(?:[.,]\d{3})+(?!\d)|(?<!\d)\d{4,}(?!\d)',
        caseSensitive: false,
      )
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Teks pada foto belum bisa dibaca. Kamu tetap bisa mengisi data manual.',
            ),
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama produk dan nominal transaksi.')),
      );
      return;
    }
    widget.onSave(
      TransactionItem(
        name: _name.text.trim(),
        amount: amount,
        date: _date,
        source: _mode == 0
            ? 'Manual'
            : _mode == 1
                ? 'Tempel chat'
                : 'Scan foto',
      ),
    );
    _name.clear();
    _amount.clear();
    _customer.clear();
    _quantity.text = '1';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi tersimpan ke pembukuan.')),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('transaction_form_scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  'Pilih cara mencatat transaksi.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: LarasDesign.secondary(context),
                  ),
                ),
                const SizedBox(height: 12),
                LarasSegmentedTabs(
                  labels: const ['Manual', 'Chat', 'Foto'],
                  selected: _mode,
                  onSelected: (value) => setState(() => _mode = value),
                ),
                const SizedBox(height: 24),
                if (_mode == 1) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LarasDesign.soft(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 20,
                            color: LarasDesign.accent(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tempel chat penjualan, lalu periksa nama produk dan nominal di bawah sebelum menyimpan.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.65,
                              color: LarasDesign.text(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_mode == 2) ...[
                  const _ReceiptScanIntro(),
                  const SizedBox(height: 20),
                  _ReceiptPicker(
                    receipt: _receipt,
                    reading: _readingReceipt,
                    onPick: _showReceiptSource,
                    onRead: _readReceipt,
                  ),
                  if (_ocrRawText != null) ...[
                    const SizedBox(height: 20),
                    _OcrResultHeader(rawText: _ocrRawText!),
                  ],
                  const SizedBox(height: 24),
                ],
                LarasFormSection(
                  title: 'Detail transaksi',
                  filled: true,
                  children: [
                    LarasLabeledField(
                      label: 'Tanggal',
                      child: Semantics(
                        button: true,
                        label: 'Pilih tanggal transaksi',
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: larasEntryDecoration(),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    formatDate(_date),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: LarasDesign.secondary(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    LarasLabeledField(
                      label: 'Nama produk atau keterangan',
                      child: TextField(
                        key: const Key('transaction_name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: larasEntryDecoration(
                          hint: 'Contoh: Batik motif Sekar',
                        ),
                      ),
                    ),
                    LarasAdaptivePair(
                      children: [
                        LarasLabeledField(
                          label: 'Jumlah',
                          child: TextField(
                            key: const Key('transaction_quantity'),
                            controller: _quantity,
                            keyboardType: TextInputType.number,
                            decoration: larasEntryDecoration(),
                          ),
                        ),
                        LarasLabeledField(
                          label: 'Satuan',
                          child: DropdownButtonFormField<String>(
                            initialValue: _unit,
                            isExpanded: true,
                            decoration: larasEntryDecoration(),
                            items: const ['pcs', 'set', 'meter', 'kg']
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _unit = value ?? 'pcs'),
                          ),
                        ),
                      ],
                    ),
                    LarasLabeledField(
                      label: 'Total transaksi',
                      child: TextField(
                        key: const Key('transaction_amount'),
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: larasEntryDecoration(
                          prefix: 'Rp ',
                          hint: 'Contoh: 480000',
                        ),
                      ),
                    ),
                    LarasLabeledField(
                      label: 'Nama pelanggan',
                      optional: true,
                      child: TextField(
                        key: const Key('transaction_customer'),
                        controller: _customer,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            larasEntryDecoration(hint: 'Nama pelanggan'),
                      ),
                    ),
                  ],
                ),
                if (_ocrRawText != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Teks hasil OCR'),
                        content:
                            SingleChildScrollView(child: Text(_ocrRawText!)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.text_snippet_outlined),
                    label: const Text('Lihat teks hasil OCR mentah'),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: LarasDesign.line(context))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('Simpan transaksi'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _ReceiptScanIntro extends StatelessWidget {
  const _ReceiptScanIntro();

  @override
  Widget build(BuildContext context) => Card(
        color: LarasDesign.soft(context),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: LarasDesign.text(context)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unggah foto catatan transaksi. Periksa hasil pembacaan sebelum menyimpan transaksi.',
                  style: TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({
    required this.receipt,
    required this.reading,
    required this.onPick,
    required this.onRead,
  });
  final XFile? receipt;
  final bool reading;
  final VoidCallback onPick;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) => Column(
        children: [
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
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: _muted,
                        ),
                        SizedBox(height: 8),
                        Text('Pilih foto catatan',
                            style: TextStyle(color: _muted)),
                      ],
                    )
                  : Image.file(File(receipt!.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: Icon(
                    receipt == null
                        ? Icons.camera_alt_outlined
                        : Icons.refresh_rounded,
                  ),
                  label:
                      Text(receipt == null ? 'Kamera / Galeri' : 'Ganti foto'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.document_scanner_outlined),
                    label: Text(reading ? 'Membaca…' : 'Proses OCR'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: _brandYellow,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
}

class _OcrResultHeader extends StatelessWidget {
  const _OcrResultHeader({required this.rawText});
  final String rawText;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: LarasDesign.accent(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rawText.startsWith('Teks tidak')
                      ? 'OCR belum menemukan teks. Lengkapi form secara manual.'
                      : 'Hasil OCR sudah dimasukkan ke form. Periksa kembali sebelum menyimpan.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
}

class FostiPage extends StatefulWidget {
  const FostiPage({
    super.key,
    required this.revenue,
    required this.transactionCount,
  });
  final int revenue;
  final int transactionCount;
  @override
  State<FostiPage> createState() => _FostiPageState();
}

class _FostiPageState extends State<FostiPage> {
  final _input = TextEditingController();
  final List<_Chat> _messages = [
    _Chat(
      false,
      'Halo, aku Laras. Aku bisa membantu membaca catatan usahamu. Kamu mau bahas penjualan, biaya, atau langkah berikutnya?',
    ),
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
      _messages.add(
        _Chat(
          false,
          'Dari ${widget.transactionCount} transaksi yang tercatat, penjualanmu saat ini ${formatRupiah(widget.revenue)}. Periksa pengeluaran dan modal produk untuk memahami hasil usahamu.',
        ),
      );
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _brandYellow,
                  child: Icon(Icons.auto_awesome, color: Colors.white),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laras',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      Text(
                        'Asisten usaha LARAS UMKM',
                        style: TextStyle(
                          fontSize: 12,
                          color: LarasDesign.secondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                      color: message.mine
                          ? _brandYellow
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.mine
                            ? Colors.white
                            : LarasDesign.text(context),
                        height: 1.4,
                      ),
                    ),
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
                'Bagaimana pengeluaranku?',
                'Apa langkah berikutnya?',
              ]
                  .map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(text),
                        onPressed: () => _ask(text),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _ask(),
                    decoration: InputDecoration(
                      hintText: 'Tanya Laras...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Kirim pesan',
                  onPressed: _ask,
                  style: IconButton.styleFrom(backgroundColor: _brandYellow),
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });
  final String label, value, note;
  final Color accent;
  @override
  Widget build(BuildContext context) => LarasDataCard(
        label: label,
        value: value,
        note: note,
        icon: label.contains('OMZET')
            ? Icons.south_west_rounded
            : Icons.auto_graph_rounded,
        highlight: label.contains('OMZET'),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            letterSpacing: -.4,
            fontWeight: FontWeight.w600,
            color: LarasDesign.text(context),
          ),
        ),
      );
}

class _Chat {
  _Chat(this.mine, this.text);
  final bool mine;
  final String text;
}

String formatRupiah(int amount) {
  if (amount < 0) return '-${formatRupiah(-amount)}';
  final digits = amount.toString();
  final reversed = digits.split('').reversed.toList();
  final chunks = <String>[];
  for (var i = 0; i < reversed.length; i += 3) {
    chunks.add(reversed.skip(i).take(3).toList().reversed.join());
  }
  return 'Rp${chunks.reversed.join('.')}';
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
