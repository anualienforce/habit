import 'package:flutter/material.dart';
import '../services/purchase_service.dart';

/// Screen to choose a plan. Uses Apple in-app purchase (no RevenueCat).
class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen> {
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
        setState(() {
          _isLoading = false;
          _loadingProductId = null;
        });
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
        if (_purchaseService.isPremium) Navigator.of(context).pop(true);
      }
    } catch (_) {
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
        if (success && _purchaseService.isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Restore completed. No previous purchases found.'
                    : 'Restore failed. Please try again.',
              ),
              backgroundColor: success ? Colors.orange : Colors.red,
            ),
          );
        }
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
        title: const Text('Choose Your Plan'),
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

          if (isPremium) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You're already Pro!",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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
                ],
              ),
            );
          }

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
                          'Monthly, yearly, or lifetime — choose below',
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
                if (hasProducts) ...[
                  if (monthly != null)
                    _buildPlanCard(context, 'Monthly', monthly.price,
                        'Billed monthly', monthly.id),
                  if (yearly != null)
                    _buildPlanCard(context, 'Yearly', yearly.price,
                        'Best value — billed yearly', yearly.id),
                  if (lifetime != null)
                    _buildPlanCard(context, 'Lifetime', lifetime.price,
                        'One-time purchase', lifetime.id),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              'Loading plans...',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
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
                const SizedBox(height: 24),
                Text(
                  'By subscribing, you agree to our Terms of Service and Privacy Policy. '
                  'Subscriptions auto-renew unless cancelled.',
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
    BuildContext context,
    String title,
    String price,
    String subtitle,
    String productId,
  ) {
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
}
