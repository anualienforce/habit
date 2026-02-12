import 'package:flutter/material.dart';
import '../services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = false;
  String? _loadingProductId;

  Future<void> _buyProduct(String productId) async {
    final product = _purchaseService.getProductById(productId);
    if (product == null) return;
    setState(() {
      _isLoading = true;
      _loadingProductId = productId;
    });
    try {
      final started = await _purchaseService.buyProduct(product);
      if (mounted) {
        if (started) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete your purchase in the dialog.'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not start purchase. Try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProductId = null;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final success = await _purchaseService.restorePurchases();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Restore completed. If you had a subscription, it should be active now.'
                  : 'Restore failed. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _purchaseService,
        builder: (context, _) {
          final isPremium = _purchaseService.isPremium;
          final monthly = _purchaseService.monthlyProduct;
          final yearly = _purchaseService.yearlyProduct;
          final lifetime = _purchaseService.lifetimeProduct;
          final hasProducts =
              monthly != null || yearly != null || lifetime != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Habit Tracker Pro',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPremium
                              ? 'You have full access to premium features'
                              : 'Monthly, yearly, or lifetime — your choice',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Premium Features',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  Icons.block,
                  'Remove All Ads',
                  'Enjoy a clean, ad-free experience while tracking your habits',
                ),
                _buildFeatureItem(
                  context,
                  Icons.priority_high,
                  'Priority Support',
                  'Get faster support and feature requests',
                ),
                _buildFeatureItem(
                  context,
                  Icons.update,
                  'Early Access',
                  'Get new features before they\'re available to everyone',
                ),
                _buildFeatureItem(
                  context,
                  Icons.favorite,
                  'Support Development',
                  'Help us continue improving the app',
                ),
                const SizedBox(height: 32),
                if (isPremium) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You're Pro!",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thank you for supporting Habit Tracker. Manage your subscription in the App Store.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _restorePurchases,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Restore purchases'),
                    ),
                  ),
                ] else ...[
                  if (hasProducts) ...[
                    if (monthly != null)
                      _buildPlanCard(
                        context,
                        title: 'Monthly',
                        price: monthly.price,
                        subtitle: 'Billed monthly',
                        productId: monthly.id,
                      ),
                    if (yearly != null)
                      _buildPlanCard(
                        context,
                        title: 'Yearly',
                        price: yearly.price,
                        subtitle: 'Best value — billed yearly',
                        productId: yearly.id,
                      ),
                    if (lifetime != null)
                      _buildPlanCard(
                        context,
                        title: 'Lifetime',
                        price: lifetime.price,
                        subtitle: 'One-time purchase',
                        productId: lifetime.id,
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : _purchaseService.isInitialized
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _purchaseService.productLoadDiagnostic.isNotEmpty
                                            ? _purchaseService.productLoadDiagnostic
                                            : 'No plans available',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          await _purchaseService.refresh();
                                          if (mounted) setState(() => _isLoading = false);
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Loading plans...',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _restorePurchases,
                      child: const Text('Restore Purchases'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'By subscribing, you agree to our Terms of Service and Privacy Policy. '
                  'Subscriptions auto-renew unless cancelled. Manage in App Store.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required String productId,
  }) {
    final theme = Theme.of(context);
    final isLoading = _isLoading && _loadingProductId == productId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _buyProduct(productId),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(price),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
