import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';

class CustomerWidget extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerWidget({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: customer.x * CafeProvider.cellSize, // Dynamic cellSize
      top: customer.y * CafeProvider.cellSize,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, // Reduced from 50 to match smaller furniture
          height: 40, // Reduced from 50 to match smaller furniture
          child: Stack(
            children: [
              // Customer character - enhanced design
              Center(
                child: Container(
                  width: 36, // Reduced from 45 to match smaller scale
                  height: 36, // Reduced from 45 to match smaller scale
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        customer.color.withOpacity(0.4),
                        customer.color.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStateColor(),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStateColor().withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      customer.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              ),
              
              // State indicator - enhanced with animation
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStateColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getStateColor().withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStateIcon(),
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Order indicator - enhanced
              if (customer.state == CustomerState.ordering && customer.orderLevel != null)
                Positioned(
                  bottom: -6,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show the dessert they want
                        Text(
                          Dessert.getDessertByLevel(customer.orderLevel!).emoji,
                          style: const TextStyle(fontSize: 8),
                        ),
                        // Show level
                        Text(
                          'Lv.${customer.orderLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              
              
              // Time countdown until customer leaves
              if (customer.state == CustomerState.ordering || customer.state == CustomerState.waiting)
                Positioned(
                  bottom: -14,
                  left: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: customer.patienceColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: customer.patienceColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 1,
                          offset: Offset(0, 0.5),
                        ),
                      ],
                    ),
                    child: Text(
                      '${customer.currentPatience}s',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 1,
                            offset: Offset(0, 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Movement animation indicator
              if (customer.x != customer.targetX || customer.y != customer.targetY)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_walk,
                      size: 6,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Seating indicator (when customer is seated) - enhanced
              if (customer.state == CustomerState.eating && customer.isSeated)
                Positioned(
                  bottom: -10,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chair,
                          size: 8,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Seated',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Table connection line (when customer is assigned to a table)
              if (customer.assignedTableId != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.4),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.table_restaurant,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStateColor() {
    switch (customer.state) {
      case CustomerState.entering:
        return Colors.blue;
      case CustomerState.browsing:
        return Colors.green;
      case CustomerState.ordering:
        return Colors.orange;
      case CustomerState.waiting:
        return Colors.yellow;
      case CustomerState.eating:
        return Colors.purple;
      case CustomerState.leaving:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  
  IconData _getStateIcon() {
    switch (customer.state) {
      case CustomerState.entering:
        return Icons.login;
      case CustomerState.browsing:
        return Icons.visibility;
      case CustomerState.ordering:
        return Icons.shopping_cart;
      case CustomerState.waiting:
        return Icons.hourglass_empty;
      case CustomerState.eating:
        return Icons.restaurant;
      case CustomerState.leaving:
        return Icons.logout;
      default:
        return Icons.person;
    }
  }
}