
import 'package:flutter/material.dart';

import 'models/product.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';

void main() {
  runApp(const VintonStoreApp());
}

class VintonStoreApp extends StatelessWidget {
  const VintonStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VintonStore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFC),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171D2B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const StoreHomePage(),
    );
  }
}

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  static const Color accent = Color(0xFFB6A5FF);
  static const Color cardColor = Color(0xFF141B29);

  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  final Set<int> _cart = {};
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Product>> _productsFuture;

  List<Product> _products = [];
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final amount = price.toStringAsFixed(
      price == price.roundToDouble() ? 0 : 2,
    );
    final parts = amount.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  String _price(double amount) => 'KSh ${_formatPrice(amount)}';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _reloadProducts() {
    setState(() {
      _productsFuture = _productService.fetchProducts();
    });
  }

  void _toggleCart(Product product) {
    final inCart = _cart.contains(product.id);

    if (!inCart && product.stockQuantity <= 0) {
      _showMessage('This product is out of stock.');
      return;
    }

    setState(() {
      if (inCart) {
        _cart.remove(product.id);
      } else {
        _cart.add(product.id);
      }
    });

    _showMessage(
      inCart
          ? '${product.name} removed from cart'
          : '${product.name} added to cart',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: accent),
            SizedBox(width: 9),
            Text(
              'VintonStore',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            onPressed: _reloadProducts,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Shopping cart',
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: Badge(
              label: Text('${_cart.length}'),
              isLabelVisible: _cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(),
            _buildCart(),
            AccountScreen(authService: _authService),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111725),
        indicatorColor: const Color(0xFF302653),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        _products = products;

        final filtered = products.where((product) {
          final query = _searchQuery.toLowerCase();
          return product.name.toLowerCase().contains(query) ||
              product.categoryName.toLowerCase().contains(query);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF30245D), Color(0xFF171D36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF494078)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR NEXT FAVOURITE',
                    style: TextStyle(
                      color: Color(0xFFC3B7FF),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Shopping made\nsimple.',
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Discover products you will love.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFFC3B7FF),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Convenient shopping, anywhere',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? 'Loading...'
                      : '${filtered.length} items',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            else if (snapshot.hasError)
              _messagePanel(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load products',
                message: 'Check your connection and try again.',
                action: FilledButton(
                  onPressed: _reloadProducts,
                  child: const Text('Retry'),
                ),
              )
            else if (filtered.isEmpty)
              _messagePanel(
                icon: Icons.inventory_2_outlined,
                title: 'No products found',
                message: 'Try another search or check again later.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 260,
                ),
                itemBuilder: (context, index) => _buildProductCard(filtered[index]),
              ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'VintonStore · Shopping made simple',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _messagePanel({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: accent),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final inCart = _cart.contains(product.id);
    final outOfStock = product.stockQuantity <= 0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF252D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF20243A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: product.primaryImageUrl == null
                  ? const Center(
                      child: Icon(Icons.devices_rounded, size: 56, color: accent),
                    )
                  : Image.network(
                      product.primaryImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 46,
                          color: accent,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              product.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
            child: Text(
              outOfStock ? 'Out of stock' : '${product.stockQuantity} in stock',
              style: TextStyle(
                fontSize: 11,
                color: outOfStock ? Colors.redAccent : Colors.white54,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _price(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: inCart ? 'Remove from cart' : 'Add to cart',
                  onPressed: outOfStock && !inCart ? null : () => _toggleCart(product),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    inCart ? Icons.check_rounded : Icons.add_rounded,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    final items = _products.where((p) => _cart.contains(p.id)).toList();
    final total = items.fold<double>(0, (sum, p) => sum + p.price);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Your Cart',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white38),
                SizedBox(height: 16),
                Text('Your cart is empty'),
                SizedBox(height: 8),
                Text(
                  'Add products to start shopping.',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          )
        else ...[
          for (final product in items)
            Card(
              color: cardColor,
              child: ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: product.primaryImageUrl == null
                      ? const Icon(Icons.devices_rounded, color: accent)
                      : Image.network(
                          product.primaryImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.devices_rounded, color: accent),
                        ),
                ),
                title: Text(product.name),
                subtitle: Text(_price(product.price)),
                trailing: IconButton(
                  onPressed: () => setState(() => _cart.remove(product.id)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Total: ${_price(total)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Checkout and M-Pesa payment will be connected next.',
            style: TextStyle(color: Colors.white60),
          ),
          OutlinedButton(
            onPressed: () => setState(() => _cart.clear()),
            child: const Text('Clear cart'),
          ),
        ],
      ],
    );
  }
}

class AccountScreen extends StatefulWidget {
  final AuthService authService;

  const AccountScreen({super.key, required this.authService});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _busy = false;
  bool _signedIn = false;
  String? _error;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    try {
      if (!await widget.authService.isLoggedIn()) return;
      await _loadProfile();
    } catch (_) {
      // The login form remains available if session restoration fails.
    }
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _loadProfile() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final profile = await widget.authService.getCurrentUser();
      if (!mounted) return;

      setState(() {
        _user = profile;
        _signedIn = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _error = _readableError(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await widget.authService.register(
          username: _username.text,
          email: _email.text,
          password: _password.text,
          passwordConfirm: _confirmPassword.text,
          firstName: _firstName.text,
          lastName: _lastName.text,
        );

        if (!mounted) return;

        setState(() {
          _isRegister = false;
          _password.clear();
          _confirmPassword.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please sign in.'),
          ),
        );
      } else {
        await widget.authService.login(
          username: _username.text,
          password: _password.text,
        );

        await _loadProfile();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _readableError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    await widget.authService.logout();

    if (!mounted) return;

    setState(() {
      _signedIn = false;
      _user = null;
      _error = null;
      _password.clear();
      _confirmPassword.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have signed out.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy && _user == null && !_isRegister && _error == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFB6A5FF)));
    }

    if (_signedIn && _user != null) {
      return _buildProfile();
    }

    return _buildAuthForm();
  }

  Widget _buildAuthForm() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const CircleAvatar(
          radius: 38,
          backgroundColor: Color(0xFF302653),
          child: Icon(Icons.person_rounded, size: 42),
        ),
        const SizedBox(height: 18),
        Text(
          _isRegister ? 'Create your account' : 'Welcome back',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _isRegister
              ? 'Join VintonStore and start shopping.'
              : 'Sign in to your VintonStore account.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                controller: _username,
                label: 'Username',
                icon: Icons.person_outline,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your username'
                    : null,
              ),
              if (_isRegister) ...[
                const SizedBox(height: 14),
                _field(
                  controller: _email,
                  label: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email address';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _firstName,
                  label: 'First name (optional)',
                  icon: Icons.badge_outlined,
                  requiredField: false,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _lastName,
                  label: 'Last name (optional)',
                  icon: Icons.badge_outlined,
                  requiredField: false,
                ),
              ],
              const SizedBox(height: 14),
              _field(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  if (_isRegister && value.length < 8) {
                    return 'Password must contain at least 8 characters';
                  }
                  return null;
                },
              ),
              if (_isRegister) ...[
                const SizedBox(height: 14),
                _field(
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  icon: Icons.lock_reset_rounded,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (value != _password.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isRegister ? 'Create account' : 'Sign in'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() {
                    _isRegister = !_isRegister;
                    _error = null;
                  });
                },
          child: Text(
            _isRegister
                ? 'Already have an account? Sign in'
                : 'New to VintonStore? Create an account',
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    bool requiredField = true,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
      validator: validator ??
          (requiredField
              ? (value) => value == null || value.trim().isEmpty
                  ? 'This field is required'
                  : null
              : null),
    );
  }

  Widget _buildProfile() {
    final displayName = [
      _user?['first_name']?.toString() ?? '',
      _user?['last_name']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');

    final username = _user?['username']?.toString() ?? _username.text;
    final email = _user?['email']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFF302653),
          child: Icon(Icons.person_rounded, size: 46),
        ),
        const SizedBox(height: 18),
        Text(
          displayName.isEmpty ? username : displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          email.isEmpty ? '@$username' : email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 30),
        Card(
          color: const Color(0xFF141B29),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Username'),
                subtitle: Text(username),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(email.isEmpty ? 'Not provided' : email),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
