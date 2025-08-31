import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';

class FloatingOrdersWidget extends StatelessWidget {
  final List<Customer> orderingCustomers;
  final Function(Customer)? onCustomerTap;
  final Function(Customer, Map<String, dynamic>)? onItemDropped;
  final Map<String, List<int>> customerIngredients;

  const FloatingOrdersWidget({
    super.key,
    required this.orderingCustomers,
    this.onCustomerTap,
    this.onItemDropped,
    required this.customerIngredients,
  });

  @override
  Widget build(BuildContext context) {
    if (orderingCustomers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsiveMargin(context), 
        vertical: AppTheme.responsiveSpacing(context)
      ), // Responsive spacing system
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: orderingCustomers.map((customer) {
            return Container(
              margin: EdgeInsets.only(right: AppTheme.responsiveMargin(context)), // Responsive spacing between cards
              child: _OrderCardWidget(
                key: ValueKey(customer.id),
                customer: customer,
                onCustomerTap: onCustomerTap,
                onItemDropped: onItemDropped,
                customerIngredients: customerIngredients,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

}

// Separate widget for order cards to prevent unnecessary rebuilds
class _OrderCardWidget extends StatelessWidget {
  final Customer customer;
  final Function(Customer)? onCustomerTap;
  final Function(Customer, Map<String, dynamic>)? onItemDropped;
  final Map<String, List<int>> customerIngredients;

  const _OrderCardWidget({
    super.key,
    required this.customer,
    this.onCustomerTap,
    this.onItemDropped,
    required this.customerIngredients,
  });
  
  // Cache expensive decoration calculations
  static final Map<String, BoxDecoration> _decorationCache = {};
  static final Map<String, List<BoxShadow>> _shadowCache = {};
  
  static BoxDecoration _getCardDecoration(bool isHovering) {
    final key = isHovering ? 'hovering' : 'normal';
    return _decorationCache[key] ??= BoxDecoration(
      gradient: isHovering 
          ? const LinearGradient(
              colors: [
                Color(0xCC4CAF50), // AppTheme.accentGreen.withOpacity(0.8)
                Color(0x664CAF50), // AppTheme.accentGreen.withOpacity(0.4)
              ],
            )
          : AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isHovering 
            ? const Color(0xFF4CAF50) // AppTheme.accentGreen
            : const Color(0x80FFB6C1), // AppTheme.primaryPink.withOpacity(0.5)
        width: isHovering ? 3 : 2,
      ),
      boxShadow: [
        BoxShadow(
          color: isHovering 
              ? const Color(0x804CAF50) // AppTheme.accentGreen.withOpacity(0.5)
              : const Color(0x4DFFB6C1), // AppTheme.primaryPink.withOpacity(0.3)
          blurRadius: isHovering ? 12 : 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'grid_dessert') {
          onItemDropped?.call(customer, data);
        }
      },
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != 'grid_dessert') return false;
        
        // Check if the dragged item matches the customer's order
        final draggedLevel = data['level'] as int;
        
        if (customer.orderType == OrderType.mergedDessert && customer.orderLevel != null) {
          return draggedLevel == customer.orderLevel;
        }
        
        // For crafted desserts, we'd need more complex logic
        // For now, let's allow any item to be dragged to crafted orders
        return customer.orderType == OrderType.craftedDessert;
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isHovering ? 1.1 : 1.0),
          child: GestureDetector(
            onTap: () => onCustomerTap?.call(customer),
            child: Container(
                width: AppTheme.responsiveCardWidth(context) * 1.5, // Increased width by 50% for better ingredient display
                height: MediaQuery.of(context).size.height * 0.08, // Fixed height for consistent layout
                padding: EdgeInsets.all(AppTheme.responsiveMargin(context)), // Responsive padding inside cards
                decoration: _getCardDecoration(isHovering),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Customer animal with thought bubble - compact left side
                  SizedBox(
                    width: 60, // Fixed width for consistency
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          customer.emoji,
                          style: TextStyle(
                            fontSize: AppTheme.responsiveFontSize(context, 28), // Slightly smaller for better proportion
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppTheme.responsiveSpacing(context, base: 4)), // Responsive spacing
                        // Heart to show they're waiting
                        const Text(
                          '💭',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  // Vertical divider
                  Container(
                    width: 2,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x4DFFB6C1), Color(0x4DFFAB91)], // Static colors for better performance
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  
                  SizedBox(width: AppTheme.responsiveMargin(context)), // Responsive spacing between customer and order details
                  
                  // Order details - optimized layout
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order header with icon and type
                        Row(
                          children: [
                            _OrderCardWidget._buildOrderIcon(context, customer),
                            SizedBox(width: AppTheme.responsiveSpacing(context)), // Responsive spacing between icon and badge
                            _OrderCardWidget._buildOrderType(context, customer),
                            const Spacer(),
                            // Progress indicator for crafted items
                            if (customer.orderType == OrderType.craftedDessert)
                              _OrderCardWidget._buildProgressIndicator(context, customer, customerIngredients),
                          ],
                        ),
                        SizedBox(height: AppTheme.responsiveSpacing(context, base: 4)), // Responsive spacing between header and ingredients
                        // Ingredients display for crafted desserts
                        if (customer.orderType == OrderType.craftedDessert)
                          _OrderCardWidget._buildEnhancedIngredientsDisplay(context, customer, customerIngredients),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildOrderIcon(BuildContext context, Customer customer) {
    if (customer.orderType == OrderType.mergedDessert && customer.orderLevel != null) {
      // Show the dessert emoji for merged dessert orders
      final dessert = Dessert.getDessertByLevel(customer.orderLevel!);
      return Text(
        dessert.emoji,
        style: TextStyle(
          fontSize: AppTheme.responsiveFontSize(context, 24), // Increased from 16 to 24
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 1,
              offset: Offset(0.5, 0.5),
            ),
          ],
        ),
      );
    } else if (customer.orderType == OrderType.craftedDessert && customer.orderCraftedDessertId != null) {
      // Show the crafted dessert emoji
      final craftedDessert = CraftableDessert.getDessertById(customer.orderCraftedDessertId!);
      if (craftedDessert != null) {
        return Text(
          craftedDessert.emoji,
          style: TextStyle(
            fontSize: AppTheme.responsiveFontSize(context, 24), // Increased from 16 to 24
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 1,
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
        );
      }
    }
    
    // Fallback
    return const Text(
      '❓',
      style: TextStyle(fontSize: 16),
    );
  }

  static Widget _buildOrderType(BuildContext context, Customer customer) {
    if (customer.orderType == OrderType.mergedDessert && customer.orderLevel != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.accentGold,
          borderRadius: BorderRadius.circular(12), // More rounded for kawaii theme
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000), // Simplified shadow
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Lv${customer.orderLevel}',
            style: TextStyle(
              fontSize: AppTheme.responsiveFontSize(context, 14), // Increased from 10 to 14
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (customer.orderType == OrderType.craftedDessert) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.accentPurple,
          borderRadius: BorderRadius.circular(12), // More rounded for kawaii theme
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000), // Simplified shadow
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Craft',
            style: TextStyle(
              fontSize: AppTheme.responsiveFontSize(context, 14), // Increased from 10 to 14
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  static Widget _buildProgressIndicator(BuildContext context, Customer customer, Map<String, List<int>> customerIngredients) {
    if (customer.orderCraftedDessertId == null) return const SizedBox.shrink();
    
    final craftedDessert = CraftableDessert.getDessertById(customer.orderCraftedDessertId!);
    if (craftedDessert == null) return const SizedBox.shrink();
    
    final requiredCount = craftedDessert.requiredIngredients.length;
    final collectedCount = (customerIngredients[customer.id] ?? []).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: collectedCount == requiredCount 
            ? AppTheme.accentGreen.withOpacity(0.8)
            : AppTheme.primaryPeach.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15), // More rounded
        border: Border.all(
          color: collectedCount == requiredCount 
              ? AppTheme.accentGreen
              : AppTheme.primaryPeach,
          width: 2, // Thicker border for kawaii feel
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // Simplified shadow
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$collectedCount/$requiredCount',
          style: TextStyle(
            fontSize: AppTheme.responsiveFontSize(context, 11),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static Widget _buildEnhancedIngredientsDisplay(BuildContext context, Customer customer, Map<String, List<int>> customerIngredients) {
    if (customer.orderCraftedDessertId == null) return const SizedBox.shrink();
    
    final craftedDessert = CraftableDessert.getDessertById(customer.orderCraftedDessertId!);
    if (craftedDessert == null) return const SizedBox.shrink();
    
    final requiredIngredients = craftedDessert.requiredIngredients;
    final collectedIngredients = customerIngredients[customer.id] ?? [];
    
    // Sort ingredients: uncollected first, collected at the back
    final sortedIngredients = List<int>.from(requiredIngredients);
    sortedIngredients.sort((a, b) {
      final aCollected = collectedIngredients.contains(a);
      final bCollected = collectedIngredients.contains(b);
      // If both have same collection status, maintain original order
      if (aCollected == bCollected) return 0;
      // Uncollected (false) comes before collected (true)
      return aCollected ? 1 : -1;
    });
    
    return SizedBox(
      height: 24, // Fixed height to prevent overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedIngredients.length,
        itemBuilder: (context, index) {
          final ingredientLevel = sortedIngredients[index];
          final dessert = Dessert.getDessertByLevel(ingredientLevel);
          final isCollected = collectedIngredients.contains(ingredientLevel);
          
          return Container(
            margin: EdgeInsets.only(right: AppTheme.responsiveSpacing(context, base: 6)), // Responsive spacing between ingredients
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCollected 
                  ? AppTheme.accentGreen.withOpacity(0.9)
                  : AppTheme.primaryCream.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14), // Much more rounded for kawaii
              border: Border.all(
                color: isCollected 
                    ? AppTheme.accentGreen
                    : AppTheme.primaryPink.withOpacity(0.6),
                width: 2, // Thicker border
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000), // Simplified shadow
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dessert.emoji,
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFontSize(context, 14),
                  ),
                ),
                if (isCollected) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.check_circle,
                    size: AppTheme.responsiveFontSize(context, 12),
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildIngredientsDisplay(BuildContext context, Customer customer, Map<String, List<int>> customerIngredients) {
    if (customer.orderCraftedDessertId == null) return const SizedBox.shrink();
    
    final craftedDessert = CraftableDessert.getDessertById(customer.orderCraftedDessertId!);
    if (craftedDessert == null) return const SizedBox.shrink();
    
    final requiredIngredients = craftedDessert.requiredIngredients;
    final collectedIngredients = customerIngredients[customer.id] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: requiredIngredients.map((ingredientLevel) {
          final dessert = Dessert.getDessertByLevel(ingredientLevel);
          final isCollected = collectedIngredients.contains(ingredientLevel);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Increased padding
            decoration: BoxDecoration(
              color: isCollected 
                  ? AppTheme.accentGreen.withOpacity(0.8)
                  : AppTheme.primaryCream.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCollected 
                    ? AppTheme.accentGreen
                    : AppTheme.primaryPink.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dessert.emoji,
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFontSize(context, 16), // Increased from 10 to 16
                  ),
                ),
                if (isCollected)
                  Text(
                    '✓',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFontSize(context, 12), // Increased from 8 to 12
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}